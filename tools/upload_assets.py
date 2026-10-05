#!/usr/bin/env python3
"""Upload the repo's generated models to Roblox through the Open Cloud Assets API.

Replaces File > Import 3D, one file at a time, for the 48 models (--format glb, the default,
picks the .glb files; --format fbx picks the .fbx files):
  assets/models/<SpeciesId>/<SpeciesId>.glb          (32 aliens)
  assets/models/props/<Name>/<Name>.glb              (16 props)
Each upload becomes a Model asset owned by your user or group. The asset ids are kept in
assets/models/asset_ids.json ({ name: { assetId, uploadedAt, file, format } }) and a Studio
script (tools/studio/install_models.luau) turns them into instances. Workflow and Dashboard
steps: docs/vault/06-art-pipelines/Map-Dressing.md, section "Bulk import through Open Cloud".

Why GLB (found in Studio on 2026-10-05): an FBX upload arrives as ONE grey MeshPart (the
materials are merged). A GLB upload arrives as one MeshPart per material slot, named <Name>,
<Name>2, <Name>3... in slot order, but every part is grey (163,162,165) with no TextureID.
So each model folder also holds materials.json, a list in slot order of
{ "slot", "name", "hex", "roughness", "metallic", "emission" }; --emit-luau turns every
materials.json into the MATERIALS table that the installer uses to colour the parts.

Usage:
  export ROBLOX_OPEN_CLOUD_KEY=...            # never put the key in the repo
  export ROBLOX_CREATOR_USER_ID=1234567       # or ROBLOX_CREATOR_GROUP_ID=7654321
  python3 tools/upload_assets.py --dry-run                      # list what would upload (format, file)
  python3 tools/upload_assets.py                                # every .glb not yet in the JSON
  python3 tools/upload_assets.py --format fbx                   # the .fbx files instead
  python3 tools/upload_assets.py --redo                         # upload again, overwrite the JSON entries
  python3 tools/upload_assets.py --props                        # only the 16 props
  python3 tools/upload_assets.py --species                      # only the 32 aliens
  python3 tools/upload_assets.py --only Mossbop,MeadowTree      # only these names
  python3 tools/upload_assets.py --emit-luau | pbcopy           # ASSET_IDS, PROP_NAMES, MATERIALS for Studio

Exit status: 0 all done (or nothing to do), 1 at least one model failed, 2 bad usage or setup.
Names already in the JSON are skipped, so a re-run after a failure retries only the failures.
--redo ignores those names and overwrites their entries (the old assets stay on the account,
harmless; this is how the FBX ids of the first run are replaced by GLB ids).
The JSON is rewritten after every success, so a crash or Ctrl+C loses nothing.
Only the Python standard library is used (urllib), so the stock Python 3 on a Mac runs it.

API facts, checked against Roblox's creator docs (GitHub mirror github.com/Roblox/creator-docs)
on 2026-10-05:
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud/guides/usage-assets.md
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/cloud/assets/v1.json
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud/reference/rate-limits.md
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud/auth/api-keys.md
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/projects/assets/index.md
- Create: POST https://apis.roblox.com/assets/v1/assets, multipart/form-data with two parts:
  `request` (JSON text: assetType, displayName, description <= 1000 chars, creationContext.creator
  with userId or groupId) and `fileContent` (the file, with its content type). One asset per call,
  file up to 20 MB.
- assetType `Model` accepts .fbx (model/fbx), .gltf (model/gltf+json), .glb (model/gltf-binary),
  .rbxm and .rbxmx (model/x-rbxm). The model arrives as a Model containing one or more MeshParts
  and "will be uploaded as packages". The docs recommend the Studio Importer for its preview and
  import settings; the API applies defaults (scale 1) with no preview.
- Response: { "path": "operations/<id>" }. Poll GET https://apis.roblox.com/assets/v1/operations/<id>
  until "done": true; then "response" holds the Asset (assetId, moderationResult) or "error"
  holds { code, message }.
- Auth: header `x-api-key: <key>` on every call. The key needs the Assets API with Read and Write
  (scopes asset:read and asset:write; polling only needs asset:read). The key acts as its owning
  user; for a group-owned asset that user needs the group permission to create assets.
- Rate limits: the Assets API reference documents no numeric limit for Create (only audio and
  video quotas). Roblox says to expect HTTP 429 at any time, to honour the `retry-after` header
  and otherwise back off exponentially; this tool does both.
- Moderation: assets are moderated after upload ("generally within a few hours"); an asset that
  is still reviewing cannot be seen or used in published games until it is approved.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import pathlib
import ssl
import sys
import time
import typing
import urllib.error
import urllib.request
import uuid

REPO = pathlib.Path(__file__).resolve().parent.parent
MODELS_DIR = REPO / "assets" / "models"
PROPS_DIR = MODELS_DIR / "props"
DEFAULT_IDS_FILE = MODELS_DIR / "asset_ids.json"

GAME_NAME = "Roblox Alien Game"
# Test hook: point the tool at a local mock instead of Roblox. Leave unset for real uploads.
API_BASE = os.environ.get("ROBLOX_ASSETS_API_BASE", "https://apis.roblox.com/assets/v1").rstrip("/")
USER_AGENT = "alien-game-upload-assets/1.0"
MAX_FILE_BYTES = 20 * 1024 * 1024  # documented per-call limit
CONTENT_TYPES = {"glb": "model/gltf-binary", "fbx": "model/fbx"}
DEFAULT_FORMAT = "glb"
MATERIALS_FILE = "materials.json"

CREATE_ATTEMPTS = 6        # tries for the create call on 429 / gateway errors
POLL_MAX_SECONDS = 300     # give up on one operation after this long
BACKOFF_CAP = 30.0         # longest single wait between retries, seconds
RETRYABLE_CREATE = (429, 502, 503, 504)   # not 500: the asset may already exist, re-run instead
RETRYABLE_POLL = (429, 500, 502, 503, 504)


class UploadError(Exception):
    """One model failed; the message is printed on its FAIL line.

    fatal=True (bad key, no permission) stops the whole run: every other model would fail the same way.
    """

    def __init__(self, message: str, fatal: bool = False) -> None:
        super().__init__(message)
        self.fatal = fatal


def log(msg: str) -> None:
    print(msg, flush=True)


def die(msg: str, code: int = 2) -> "typing.NoReturn":
    print("upload_assets: " + msg, file=sys.stderr)
    sys.exit(code)


# --------------------------------------------------------------------------- discovery

def discover(fmt: str = DEFAULT_FORMAT) -> "tuple[dict[str, pathlib.Path], dict[str, pathlib.Path]]":
    """Return (species, props), each name -> <Name>.<fmt> path, from assets/models."""
    species: "dict[str, pathlib.Path]" = {}
    props: "dict[str, pathlib.Path]" = {}
    if MODELS_DIR.is_dir():
        for d in sorted(MODELS_DIR.iterdir()):
            if d.is_dir() and d.name != "props" and (d / (d.name + "." + fmt)).is_file():
                species[d.name] = d / (d.name + "." + fmt)
    if PROPS_DIR.is_dir():
        for d in sorted(PROPS_DIR.iterdir()):
            if d.is_dir() and (d / (d.name + "." + fmt)).is_file():
                props[d.name] = d / (d.name + "." + fmt)
    clash = sorted(set(species) & set(props))
    if clash:
        die("a name is both a species and a prop: " + ", ".join(clash))
    return species, props


def prop_names() -> "list[str]":
    """Names of the folders under assets/models/props (every prop that has a .glb or an .fbx)."""
    found: "set[str]" = set()
    for fmt in CONTENT_TYPES:
        found.update(discover(fmt)[1])
    return sorted(found)


def entry_format(entry: dict) -> str:
    """Format of an ids-file entry: its "format" field, else the suffix of its "file" (old FBX runs)."""
    fmt = entry.get("format")
    if isinstance(fmt, str) and fmt:
        return fmt
    return pathlib.Path(str(entry.get("file", ""))).suffix.lstrip(".") or "?"


# --------------------------------------------------------------------------- ids file

def load_ids(path: pathlib.Path) -> "dict[str, dict]":
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        die("cannot read %s (%s); fix or delete it, nothing was uploaded" % (path, exc))
    if not isinstance(data, dict):
        die("%s must hold a JSON object of name -> { assetId, uploadedAt, file }" % path)
    return data


def save_ids(path: pathlib.Path, ids: "dict[str, dict]") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(ids, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(str(tmp), str(path))


def load_materials() -> "dict[str, list[tuple[str, str, float, float, float]]]":
    """name -> [(material name, hex, roughness, metallic, emission)] in slot order.

    Read from <model folder>/materials.json for every species and prop folder that has one;
    a model without the file gets no entry.
    """
    out: "dict[str, list[tuple[str, str, float, float, float]]]" = {}
    folders: "list[pathlib.Path]" = []
    if MODELS_DIR.is_dir():
        folders += [d for d in sorted(MODELS_DIR.iterdir()) if d.is_dir() and d.name != "props"]
    if PROPS_DIR.is_dir():
        folders += [d for d in sorted(PROPS_DIR.iterdir()) if d.is_dir()]
    for d in folders:
        path = d / MATERIALS_FILE
        if not path.is_file():
            continue
        try:
            rows = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            die("cannot read %s (%s)" % (path, exc))
        if not isinstance(rows, list) or not rows or not all(isinstance(r, dict) for r in rows):
            die("%s must be a non-empty JSON list of { slot, name, hex, roughness, metallic, emission }" % path)
        ordered = sorted(enumerate(rows), key=lambda ir: (ir[1].get("slot", ir[0] + 1), ir[0]))
        entries = []
        for i, (_, row) in enumerate(ordered, start=1):
            hex_ = str(row.get("hex", "")).lstrip("#")
            if len(hex_) != 6 or any(c not in "0123456789abcdefABCDEF" for c in hex_):
                die("%s slot %d: hex must be 6 hex digits, got %r" % (path, i, row.get("hex")))
            try:
                rough, metal, emit = (float(row.get(k, 0)) for k in ("roughness", "metallic", "emission"))
            except (TypeError, ValueError):
                die("%s slot %d: roughness, metallic and emission must be numbers" % (path, i))
            entries.append((str(row.get("name") or "Part%d" % i), hex_.upper(), rough, metal, emit))
        out[d.name] = entries
    return out


def luau_num(value: float) -> str:
    """0.8 -> '0.8', 0.0 -> '0', 1.0 -> '1' (no trailing zeros)."""
    return ("%.4f" % value).rstrip("0").rstrip(".") or "0"


def emit_luau(ids: "dict[str, dict]") -> str:
    """Luau literals for the top of tools/studio/install_models.luau."""
    lines = ["local ASSET_IDS: { [string]: number } = {"]
    for name in sorted(ids):
        lines.append("\t%s = %d," % (name, int(ids[name]["assetId"])))
    lines.append("}")
    lines.append("local PROP_NAMES: { [string]: boolean } = {")
    for name in prop_names():
        lines.append("\t%s = true," % name)
    lines.append("}")
    lines.append("local MATERIALS: { [string]: { { string | number } } } = {")
    materials = load_materials()
    for name in sorted(materials):
        rows = ", ".join('{ %s, "%s", %s, %s, %s }' % (json.dumps(n), h, luau_num(r), luau_num(m), luau_num(e))
                         for n, h, r, m, e in materials[name])
        lines.append("\t%s = { %s }," % (name, rows))
    lines.append("}")
    return "\n".join(lines)


# --------------------------------------------------------------------------- HTTP

def multipart(fields: "list[tuple[str, str | None, str | None, bytes]]") -> "tuple[bytes, str]":
    """fields: (name, filename, content_type, data). Returns (body, content-type header)."""
    boundary = "----alienupload" + uuid.uuid4().hex
    out = []
    for name, filename, ctype, data in fields:
        head = 'Content-Disposition: form-data; name="%s"' % name
        if filename:
            head += '; filename="%s"' % filename
        out.append(("--%s\r\n%s\r\n" % (boundary, head)).encode("utf-8"))
        if ctype:
            out.append(("Content-Type: %s\r\n" % ctype).encode("utf-8"))
        out.append(b"\r\n" + data + b"\r\n")
    out.append(("--%s--\r\n" % boundary).encode("utf-8"))
    return b"".join(out), "multipart/form-data; boundary=" + boundary


def retry_wait(err: "urllib.error.HTTPError | None", attempt: int) -> float:
    """Seconds to wait: the Retry-After header when given (429), else exponential backoff."""
    if err is not None:
        value = err.headers.get("Retry-After") or err.headers.get("retry-after")
        if value:
            try:
                return min(max(float(value), 0.0), 120.0)
            except ValueError:
                pass  # an HTTP date: fall back to backoff
    return min(BACKOFF_CAP, 2.0 ** attempt)


def http(method: str, url: str, key: str, body: "bytes | None" = None,
         content_type: "str | None" = None, retry_on: "tuple[int, ...]" = (),
         attempts: int = 1) -> dict:
    """One API call with bounded retries. Returns the parsed JSON object."""
    headers = {"x-api-key": key, "User-Agent": USER_AGENT, "Accept": "application/json"}
    if content_type:
        headers["Content-Type"] = content_type
    last = "no attempt made"
    for attempt in range(1, attempts + 1):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        err = None
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                raw = resp.read()
            try:
                return json.loads(raw.decode("utf-8")) if raw else {}
            except ValueError:
                raise UploadError("HTTP %s returned non-JSON: %r" % (resp.status, raw[:200]))
        except urllib.error.HTTPError as exc:
            err = exc
            text = exc.read().decode("utf-8", "replace").strip()[:300]
            last = "HTTP %d %s" % (exc.code, text)
            if exc.code not in retry_on:
                hint = ""
                if exc.code in (401, 403):
                    hint = (" (check the key: Assets API with Read and Write, the creator it may act for, "
                            "and the IP allowlist)")
                raise UploadError(last + hint, fatal=exc.code in (401, 403))
        except ssl.SSLError as exc:
            raise UploadError("TLS error: %s (on a python.org Mac install, run "
                              "'Install Certificates.command' once)" % exc)
        except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
            last = "network error: %s" % getattr(exc, "reason", exc)
        if attempt == attempts:
            break
        wait = retry_wait(err, attempt)
        log("      retry %d/%d in %.0fs (%s)" % (attempt, attempts - 1, wait, last))
        time.sleep(wait)
    raise UploadError("gave up after %d tries: %s" % (attempts, last))


# --------------------------------------------------------------------------- upload

def upload_one(name: str, model: pathlib.Path, key: str, creator: "dict[str, str]",
               poll_interval: float, fmt: str = DEFAULT_FORMAT) -> "tuple[int, str]":
    """Create the asset, poll its operation. Returns (assetId, moderation state or '')."""
    data = model.read_bytes()
    if len(data) > MAX_FILE_BYTES:
        raise UploadError("%s is %.1f MB, over the 20 MB limit" % (model.name, len(data) / 1048576.0))
    today = datetime.date.today().isoformat()
    meta = {
        "assetType": "Model",
        "displayName": name,
        "description": "%s model %s, uploaded %s from the repo's generated meshes." % (GAME_NAME, name, today),
        "creationContext": {"creator": creator},
    }
    body, ctype = multipart([
        ("request", None, None, json.dumps(meta).encode("utf-8")),
        ("fileContent", model.name, CONTENT_TYPES[fmt], data),
    ])
    op = http("POST", API_BASE + "/assets", key, body, ctype, RETRYABLE_CREATE, CREATE_ATTEMPTS)
    path = op.get("path")
    if not isinstance(path, str) or "/" not in path:
        raise UploadError("create returned no operation path: %r" % (op,))
    op_id = path.split("/")[-1]

    deadline = time.monotonic() + POLL_MAX_SECONDS
    wait = poll_interval
    while True:
        if op.get("done"):
            break
        if time.monotonic() > deadline:
            raise UploadError("operation %s still running after %ds; re-run later "
                              "(it may still finish, check the Creator Dashboard)" % (op_id, POLL_MAX_SECONDS))
        time.sleep(wait)
        wait = min(wait * 1.5, 8.0)
        op = http("GET", API_BASE + "/operations/" + op_id, key, retry_on=RETRYABLE_POLL, attempts=5)
    if op.get("error"):
        err = op["error"]
        raise UploadError("Roblox rejected it: %s %s" % (err.get("code", ""), err.get("message", "")))
    resp = op.get("response") or {}
    asset_id = resp.get("assetId")
    if asset_id is None and isinstance(resp.get("path"), str):
        asset_id = resp["path"].split("/")[-1]
    try:
        asset_id = int(asset_id)
    except (TypeError, ValueError):
        raise UploadError("operation finished without an assetId: %r" % (op,))
    state = (resp.get("moderationResult") or {}).get("moderationState", "")
    return asset_id, str(state).replace("MODERATION_STATE_", "").title()



# --------------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description="Upload generated .glb (or .fbx) models through the Open Cloud Assets API.")
    ap.add_argument("--props", action="store_true", help="only the props under assets/models/props")
    ap.add_argument("--species", action="store_true", help="only the species (aliens)")
    ap.add_argument("--only", metavar="A,B", help="comma-separated names to upload (others are ignored)")
    ap.add_argument("--format", choices=sorted(CONTENT_TYPES), default=DEFAULT_FORMAT,
                    help="which model files to upload: <Name>.glb (default; one MeshPart per material slot) "
                         "or <Name>.fbx (one merged grey MeshPart)")
    ap.add_argument("--redo", action="store_true",
                    help="ignore names already in asset_ids.json and overwrite their entries "
                         "(the old assets stay on the account)")
    ap.add_argument("--dry-run", action="store_true", help="list what would upload; send nothing")
    ap.add_argument("--emit-luau", action="store_true",
                    help="print the ASSET_IDS, PROP_NAMES and MATERIALS tables for "
                         "tools/studio/install_models.luau and exit")
    ap.add_argument("--ids-file", type=pathlib.Path, default=DEFAULT_IDS_FILE, help=argparse.SUPPRESS)
    ap.add_argument("--poll-interval", type=float, default=1.0, help=argparse.SUPPRESS)
    args = ap.parse_args()

    ids = load_ids(args.ids_file)

    if args.emit_luau:
        if not ids:
            print("upload_assets: %s has no ids yet; run the upload first" % args.ids_file, file=sys.stderr)
        print(emit_luau(ids))
        return 0

    fmt = args.format
    species, props = discover(fmt)
    if not species and not props:
        die("no .%s files found under %s" % (fmt, MODELS_DIR))
    wanted: "dict[str, pathlib.Path]" = {}
    if args.species or not args.props:
        wanted.update(species)
    if args.props or not args.species:
        wanted.update(props)
    if args.only:
        names = [n.strip() for n in args.only.split(",") if n.strip()]
        known = dict(species)
        known.update(props)
        unknown = [n for n in names if n not in known]
        if unknown:
            die("unknown model name(s): %s (names are the folder names under assets/models)" % ", ".join(unknown))
        wanted = {n: known[n] for n in names}

    todo = dict(wanted) if args.redo else {n: p for n, p in wanted.items() if n not in ids}
    if not args.redo:
        for name in sorted(wanted):
            if name in ids:
                old_fmt = entry_format(ids[name])
                log("skip   %-14s already uploaded (asset %s, %s)%s" % (
                    name, ids[name].get("assetId"), old_fmt,
                    "  use --redo to replace it with the " + fmt if old_fmt != fmt else ""))

    if args.dry_run:
        for name in sorted(todo):
            replaces = "  (replaces asset %s, %s)" % (ids[name].get("assetId"), entry_format(ids[name])) \
                if name in ids else ""
            log("would  %-14s %-4s %s%s" % (name, fmt, todo[name].relative_to(REPO), replaces))
        log("dry run: %d to upload as %s, %d already done" % (len(todo), fmt, len(wanted) - len(todo)))
        return 0

    if not todo:
        log("nothing to upload (%d already in %s; --redo uploads them again)" % (len(wanted), args.ids_file.name))
        return 0

    key = os.environ.get("ROBLOX_OPEN_CLOUD_KEY", "").strip()
    if not key:
        die("ROBLOX_OPEN_CLOUD_KEY is not set. Make a key (Creator Dashboard > Open Cloud > API Keys, Assets "
            "API, Read and Write) and run: export ROBLOX_OPEN_CLOUD_KEY=...  (never put it in the repo)")
    user = os.environ.get("ROBLOX_CREATOR_USER_ID", "").strip()
    group = os.environ.get("ROBLOX_CREATOR_GROUP_ID", "").strip()
    if bool(user) == bool(group):
        die("set exactly one of ROBLOX_CREATOR_USER_ID (your Roblox user id) or ROBLOX_CREATOR_GROUP_ID "
            "(the group that will own the assets)")
    if not (user or group).isdigit():
        die("the creator id must be digits only")
    creator = {"userId": user} if user else {"groupId": group}

    failed = []
    done = 0
    try:
        for name in sorted(todo):
            model = todo[name]
            try:
                asset_id, state = upload_one(name, model, key, creator, args.poll_interval, fmt)
            except UploadError as exc:
                failed.append(name)
                log("FAIL   %-14s %s" % (name, exc))
                if exc.fatal:
                    log("stopping: this will fail for every model; fix the key or creator and re-run")
                    break
                continue
            ids[name] = {
                "assetId": asset_id,
                "uploadedAt": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "file": str(model.relative_to(REPO)),
                "format": fmt,
            }
            save_ids(args.ids_file, ids)
            done += 1
            log("ok     %-14s %-4s asset %d%s" % (name, fmt, asset_id, "  moderation: " + state if state else ""))
    except KeyboardInterrupt:
        log("interrupted; %d uploaded this run are saved in %s" % (done, args.ids_file.name))
        return 130

    log("done: %d uploaded, %d failed, %d skipped" % (done, len(failed), len(wanted) - len(todo)))
    if failed:
        log("failed: " + ", ".join(failed) + "  (re-run to retry only these)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
