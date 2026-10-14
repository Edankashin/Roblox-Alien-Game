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
  export ROBLOX_OPEN_CLOUD_KEY=...            # or ROBLOX_API_KEY (the first one set wins); never put the key in the repo
  export ROBLOX_CREATOR_USER_ID=1234567       # or ROBLOX_CREATOR_GROUP_ID=7654321
  python3 tools/upload_assets.py --dry-run                      # list what would upload (format, file)
  python3 tools/upload_assets.py                                # every .glb not yet in the JSON
  python3 tools/upload_assets.py --format fbx                   # the .fbx files instead
  python3 tools/upload_assets.py --redo                         # upload again, overwrite the JSON entries
  python3 tools/upload_assets.py --props                        # only the 16 props
  python3 tools/upload_assets.py --species                      # only the 32 aliens
  python3 tools/upload_assets.py --only Mossbop,MeadowTree      # only these names
  python3 tools/upload_assets.py --emit-luau | pbcopy           # ASSET_IDS, PROP_NAMES, MATERIALS for Studio
  python3 tools/upload_assets.py --images --dry-run              # the icon and particle PNGs that would upload
  python3 tools/upload_assets.py --images                        # upload assets/icons/*.png and assets/particles/*.png as Decals, then resolve their Image ids
  python3 tools/upload_assets.py --resolve-images                # only the resolve step (no key needed); --redo resolves every entry again
  python3 tools/upload_assets.py --images --emit-icons-luau     # the Icons and Particles tables (Image ids) for src/shared/data/Icons.luau
  python3 tools/upload_assets.py --textures --dry-run            # the 15 texture PNGs (5 keys x color, normal, roughness) that would upload
  python3 tools/upload_assets.py --textures                      # upload assets/textures/<key>/<key>_<map>.png as Decals, then resolve their Image ids
  python3 tools/upload_assets.py --textures --only fur,ice/color # whole keys, or single maps written <key>/<map>; --redo uploads again
  python3 tools/upload_assets.py --emit-textures-luau            # the Textures table (Image ids) for src/shared/data/Textures.luau
  python3 tools/upload_assets.py --emit-decals-luau | pbcopy     # the Decal ids that have no Image id yet, for tools/studio/resolve_decals.luau
  python3 tools/upload_assets.py --from-studio decals.txt        # fill imageId from the lines that snippet printed in Studio

Images (--images): every PNG under assets/icons (the UI icon pack) and assets/particles (the weather
sprites) is uploaded as a Decal asset (assetType "Decal", image/png). A Decal id is NOT what an
ImageLabel or a ParticleEmitter draws (found in Studio on 2026-10-14: every menu button was an empty
square, loaded=false): they need the Image asset behind the Decal, whose id is in the Decal's Texture
(InsertService:LoadAsset(decalId) gives a Decal with Texture rbxassetid://<imageId>). So each entry in
assets/icons/asset_ids.json ({ key: { assetId, imageId, uploadedAt, file, kind } }, kind "icon" or
"particle") keeps both: assetId is the Decal, imageId the Image. --resolve-images fills the missing
imageId values by fetching https://assetdelivery.roblox.com/v1/asset/?id=<decalId> (a public, approved
Decal needs no key; none is sent to that host) and reading the id out of the returned Decal XML, and
--images runs the same step after its uploads, so a fresh upload lands with both ids. If a Decal is
still in moderation the fetch fails: re-run --resolve-images later. --emit-icons-luau prints the two
tables for src/shared/data/Icons.luau with the IMAGE ids, for every key the data file knows (0 when not
uploaded), and refuses (exit 2, naming the keys) while any uploaded entry has no imageId.

Textures (--textures): the five tileable sets of the Surface pass, assets/textures/<key>/<key>_color.png,
<key>_normal.png and <key>_roughness.png (keys fur, moss, stone, ice, scales), go up the same way as the icons: each PNG
is a Decal asset, recorded in assets/textures/asset_ids.json under the key "<key>/<map>" ({ assetId, imageId,
uploadedAt, file, format, kind "texture" }), and the Image id behind it is resolved the same way (a SurfaceAppearance map
wants the Image, not the Decal). --only takes a key (all three maps) or "<key>/<map>". --resolve-images --textures is
the resolve step alone for that file. --emit-textures-luau prints the Textures table for
src/shared/data/Textures.luau (the tiling of each row is kept from the file) and refuses (exit 2) while any of the
three maps of any row has no Image id, naming the ones not uploaded and the ones not resolved: the game adds a
SurfaceAppearance only when all three ids are non-zero, so a half-filled set is no use. --only limits the rows.

Resolving through Studio (--emit-decals-luau, --from-studio): the anonymous asset-delivery call now answers 401 and
the Open Cloud route needs a scope the key lacks (Mac job 19, docs/vault/08-log/2026-10-14.md), so --resolve-images
prints this route as the next step on a 401 or 403. --emit-decals-luau prints the Decal ids without an Image id (icons
and textures together; --images or --textures picks one file; --redo lists every uploaded one) as a Luau table for the
PASTE block of tools/studio/resolve_decals.luau. That snippet runs in Studio (Edit mode), loads each Decal with
game:GetObjects, and prints {"decal": <id>, "image": <id>} per id. The Mac saves the Output to a file and
--from-studio <file> reads those lines (anything else in the file, such as Studio's timestamps, warnings and the
summary, is ignored), then fills imageId in both ids files wherever assetId is that Decal (--redo replaces an Image id
that differs; --dry-run writes nothing). It exits 1 on a Decal that no ids file knows, a Decal given two different
Image ids, or an Image id equal to its Decal id.

Exit status: 0 all done (or nothing to do), 1 at least one model failed (or one Image id could not be
resolved, or --from-studio found a problem), 2 bad usage or setup (or --emit-icons-luau or --emit-textures-luau
while Image ids are missing).
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
- Auth: header `x-api-key: <key>` on every call (the key is never printed or written). The key needs the Assets API with Read and Write
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
import re
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
ICONS_DIR = REPO / "assets" / "icons"
PARTICLES_DIR = REPO / "assets" / "particles"
IMAGE_IDS_FILE = ICONS_DIR / "asset_ids.json"
ICONS_LUAU = REPO / "src" / "shared" / "data" / "Icons.luau"
TEXTURES_DIR = REPO / "assets" / "textures"
TEXTURE_IDS_FILE = TEXTURES_DIR / "asset_ids.json"
TEXTURES_LUAU = REPO / "src" / "shared" / "data" / "Textures.luau"
# (file suffix <key>_<suffix>.png, Textures.luau field) in the order the table lists them.
TEXTURE_MAPS = (("color", "colorMap"), ("normal", "normalMap"), ("roughness", "roughnessMap"))
KEY_NAMES = ("ROBLOX_OPEN_CLOUD_KEY", "ROBLOX_API_KEY")   # the first one set is the key
IMAGE_CONTENT_TYPE = "image/png"
IMAGE_ASSET_TYPE = "Decal"
# Resolves a Decal to the Image asset behind it. Test hook like API_BASE: point at a local mock.
ASSET_DELIVERY_BASE = os.environ.get("ROBLOX_ASSET_DELIVERY_BASE",
                                     "https://assetdelivery.roblox.com/v1/asset").rstrip("/")

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
RESOLVE_ATTEMPTS = 4       # tries for one Decal fetch on 429 / 5xx / network errors
RESOLVE_MAX_CONSECUTIVE_FAILS = 3   # stop a resolve run after this many failures in a row (offline, not approved)


class UploadError(Exception):
    """One model failed; the message is printed on its FAIL line.

    fatal=True (bad key, no permission) stops the whole run: every other model would fail the same way.
    status is the HTTP status when the failure was an error response, else None.
    """

    def __init__(self, message: str, fatal: bool = False, status: "int | None" = None) -> None:
        super().__init__(message)
        self.fatal = fatal
        self.status = status


def log(msg: str) -> None:
    print(msg, flush=True)


def die(msg: str, code: int = 2) -> "typing.NoReturn":
    print("upload_assets: " + msg, file=sys.stderr)
    sys.exit(code)


def api_key() -> str:
    """The Open Cloud key from the environment (ROBLOX_OPEN_CLOUD_KEY, else ROBLOX_API_KEY), '' when neither is set.
    The key is only ever put in the x-api-key header: it is never printed, logged or written."""
    for name in KEY_NAMES:
        value = os.environ.get(name, "").strip()
        if value:
            return value
    return ""


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


def discover_images() -> "dict[str, tuple[pathlib.Path, str]]":
    """key -> (png path, kind) for every PNG under assets/icons ("icon") and assets/particles ("particle")."""
    out: "dict[str, tuple[pathlib.Path, str]]" = {}
    for folder, kind in ((ICONS_DIR, "icon"), (PARTICLES_DIR, "particle")):
        if folder.is_dir():
            for f in sorted(folder.glob("*.png")):
                if f.stem in out:
                    die("image key %s exists in both assets/icons and assets/particles" % f.stem)
                out[f.stem] = (f, kind)
    return out


def discover_textures() -> "dict[str, tuple[pathlib.Path, str]]":
    """'<key>/<map>' -> (png path, "texture") for assets/textures/<key>/<key>_<map>.png, the three maps of each key."""
    out: "dict[str, tuple[pathlib.Path, str]]" = {}
    if TEXTURES_DIR.is_dir():
        for folder in sorted(TEXTURES_DIR.iterdir()):
            if not folder.is_dir():
                continue
            for suffix, _ in TEXTURE_MAPS:
                png = folder / ("%s_%s.png" % (folder.name, suffix))
                if png.is_file():
                    out["%s/%s" % (folder.name, suffix)] = (png, "texture")
    return out


def expand_only(tokens: "list[str]", universe: "typing.Iterable[str]",
                grouped: bool = False) -> "tuple[list[str], list[str]]":
    """Resolve --only tokens against the known names: (names in the order given without repeats, unknown tokens).
    grouped=True (textures): a token without a map, such as 'fur', stands for every '<token>/<map>'."""
    known = list(universe)
    names: "list[str]" = []
    unknown: "list[str]" = []
    for token in tokens:
        hits = [n for n in known if n == token]
        if not hits and grouped:
            hits = [n for n in known if n.startswith(token + "/")]
        if hits:
            names.extend(hits)
        else:
            unknown.append(token)
    return list(dict.fromkeys(names)), unknown


def icons_luau_keys() -> "tuple[list[str], list[str]]":
    """The keys src/shared/data/Icons.luau lists in its Icons and Particles tables, in file order."""
    icons: "list[str]" = []
    particles: "list[str]" = []
    if not ICONS_LUAU.is_file():
        return icons, particles
    current: "list[str] | None" = None
    for line in ICONS_LUAU.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("local Icons"):
            current = icons
        elif stripped.startswith("local Particles"):
            current = particles
        elif stripped.startswith("local Aliases") or stripped.startswith("return"):
            current = None
        elif current is not None and "=" in stripped and not stripped.startswith("--"):
            current.append(stripped.split("=")[0].strip())
    return icons, particles


def image_id(entry: dict) -> int:
    """The Image id of an ids-file entry (what an ImageLabel or ParticleEmitter draws), 0 when not resolved."""
    value = entry.get("imageId")
    return value if isinstance(value, int) and not isinstance(value, bool) and value > 0 else 0


def missing_image_ids(ids: "dict[str, dict]") -> "list[str]":
    """Sorted keys of uploaded entries (they have a Decal assetId) that have no Image id yet."""
    return sorted(k for k, e in ids.items() if isinstance(e, dict) and e.get("assetId") and not image_id(e))


def emit_icons_luau(ids: "dict[str, dict]") -> str:
    """The Icons and Particles tables for src/shared/data/Icons.luau: every key the data file lists, plus
    any uploaded key it does not list yet, with 0 for a key without an id. The ids are the IMAGE ids
    (imageId), never the Decal ids (assetId): an ImageLabel shows nothing for a Decal id."""
    icons, particles = icons_luau_keys()
    images = discover_images()
    for key, (_, kind) in images.items():
        target = icons if kind == "icon" else particles
        if key not in target:
            target.append(key)
    lines = ["local Icons: { [string]: number } = {"]
    for key in icons:
        lines.append("\t%s = %d," % (key, image_id(ids.get(key, {}))))
    lines.append("}")
    lines.append("")
    lines.append("local Particles: { [string]: number } = {")
    for key in particles:
        lines.append("\t%s = %d," % (key, image_id(ids.get(key, {}))))
    lines.append("}")
    return "\n".join(lines)


_TEXTURE_ROW = re.compile(r"^\t(\w+) = \{ colorMap = \d+, normalMap = \d+, roughnessMap = \d+((?:, .*?)?) \},\s*$")
TEXTURES_HEAD = "local Textures: { [string]: Types.TextureRow } = {"
DEFAULT_TEXTURE_TAIL = ", tiling = { 1, 1 }"


def textures_luau_rows() -> "list[tuple[str, str]]":
    """(key, tail) for each row of the Textures table in src/shared/data/Textures.luau, in file order. The tail is
    what follows roughnessMap in the row (', tiling = { 3, 3 }'), kept so an emitted row keeps its tiling."""
    rows: "list[tuple[str, str]]" = []
    if not TEXTURES_LUAU.is_file():
        return rows
    inside = False
    for line in TEXTURES_LUAU.read_text(encoding="utf-8").splitlines():
        if line.startswith("local Textures"):
            inside = True
        elif inside and line.startswith("}"):
            break
        elif inside:
            match = _TEXTURE_ROW.match(line)
            if match:
                rows.append((match.group(1), match.group(2)))
    return rows


def texture_rows(keys: "typing.Iterable[str] | None" = None) -> "list[tuple[str, str]]":
    """The rows to emit: the data file's rows, then any uploadable key it does not list yet (tiling 1 x 1).
    keys limits the rows to those texture keys."""
    rows = textures_luau_rows()
    listed = {key for key, _ in rows}
    for name in discover_textures():
        key = name.split("/")[0]
        if key not in listed:
            rows.append((key, DEFAULT_TEXTURE_TAIL))
            listed.add(key)
    wanted = None if keys is None else set(keys)
    return [(k, t) for k, t in rows if wanted is None or k in wanted]


def unresolved_textures(ids: "dict[str, dict]", rows: "list[tuple[str, str]]") -> "tuple[list[str], list[str]]":
    """(not uploaded, uploaded without an Image id): the '<key>/<map>' names of the rows' maps with no Image id."""
    not_uploaded: "list[str]" = []
    unresolved: "list[str]" = []
    for key, _ in rows:
        for suffix, _ in TEXTURE_MAPS:
            name = "%s/%s" % (key, suffix)
            entry = ids.get(name)
            if not isinstance(entry, dict) or not entry.get("assetId"):
                not_uploaded.append(name)
            elif not image_id(entry):
                unresolved.append(name)
    return not_uploaded, unresolved


def emit_textures_luau(ids: "dict[str, dict]", keys: "typing.Iterable[str] | None" = None) -> str:
    """The Textures table for src/shared/data/Textures.luau with the IMAGE ids (imageId), never the Decal ids.
    A map without an id prints 0 (callers refuse before that: see unresolved_textures)."""
    lines = [TEXTURES_HEAD]
    for key, tail in texture_rows(keys):
        parts = ["%s = %d" % (field, image_id(ids.get("%s/%s" % (key, suffix), {}))) for suffix, field in TEXTURE_MAPS]
        lines.append("\t%s = { %s%s }," % (key, ", ".join(parts), tail))
    lines.append("}")
    return "\n".join(lines)


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


def request_bytes(method: str, url: str, headers: "dict[str, str]", body: "bytes | None" = None,
                  retry_on: "tuple[int, ...]" = (), attempts: int = 1,
                  fatal_codes: "tuple[int, ...]" = (401, 403), denied_hint: str = "") -> bytes:
    """One HTTP call with bounded retries (Retry-After, else exponential backoff). Returns the body bytes.

    A status in retry_on (or a network error) is retried up to `attempts` tries; any other error status
    raises UploadError, fatal when it is in fatal_codes (denied_hint is appended to those). Only the status
    and the first 300 characters of the error body are ever put in a message, never the headers.
    """
    last = "no attempt made"
    for attempt in range(1, attempts + 1):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        err = None
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            err = exc
            text = exc.read().decode("utf-8", "replace").strip()[:300]
            last = "HTTP %d %s" % (exc.code, text)
            if exc.code not in retry_on:
                raise UploadError(last + (denied_hint if exc.code in (401, 403) else ""),
                                  fatal=exc.code in fatal_codes, status=exc.code)
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


def http(method: str, url: str, key: str, body: "bytes | None" = None,
         content_type: "str | None" = None, retry_on: "tuple[int, ...]" = (),
         attempts: int = 1) -> dict:
    """One Open Cloud API call (x-api-key) with bounded retries. Returns the parsed JSON object."""
    headers = {"x-api-key": key, "User-Agent": USER_AGENT, "Accept": "application/json"}
    if content_type:
        headers["Content-Type"] = content_type
    raw = request_bytes(method, url, headers, body, retry_on, attempts,
                        denied_hint=" (check the key: Assets API with Read and Write, the creator it may act "
                                    "for, and the IP allowlist)")
    try:
        return json.loads(raw.decode("utf-8")) if raw else {}
    except ValueError:
        raise UploadError("HTTP 2xx returned non-JSON: %r" % (raw[:200],))


# --------------------------------------------------------------------------- Decal -> Image id

_TEXTURE_BLOCK = re.compile(r'<Content\s+name="Texture"\s*>(.*?)</Content>', re.S | re.I)
_ASSET_REF = re.compile(r'(?:rbxassetid://|[?&;]id=)(\d+)', re.I)


def parse_image_id(body: bytes) -> int:
    """The Image id out of a Decal's asset XML: its Texture content, either
    <url>http://www.roblox.com/asset/?id=IMAGEID</url> or <url>rbxassetid://IMAGEID</url>."""
    if body[:8] == b"\x89PNG\r\n\x1a\n":
        raise UploadError("the asset is an image file itself, not a Decal; use its id as it is")
    text = body.decode("utf-8", "replace")
    block = _TEXTURE_BLOCK.search(text)
    found = _ASSET_REF.findall(block.group(1) if block else text)
    if not found or int(found[0]) <= 0:
        raise UploadError("no Image id in the Decal XML (first 120 bytes: %r)" % (body[:120],))
    return int(found[0])


def fetch_image_id(decal_id: int) -> int:
    """Ask the asset delivery service for the Decal and read the Image id from its XML.

    A public, approved Decal needs no login, so no API key is sent to this host. A Decal that is still in
    moderation, or a rejected one, is refused (403 or 404): resolve again later.
    """
    url = "%s/?id=%d" % (ASSET_DELIVERY_BASE, decal_id)
    headers = {"User-Agent": USER_AGENT, "Accept": "*/*"}
    body = request_bytes("GET", url, headers, retry_on=RETRYABLE_POLL, attempts=RESOLVE_ATTEMPTS,
                         fatal_codes=(),
                         denied_hint=" (a Decal still in moderation is not served yet; try again later)")
    resolved = parse_image_id(body)
    if resolved == decal_id:
        raise UploadError("the Decal XML points at its own id, not at an Image")
    return resolved


def pending_images(ids: "dict[str, dict]", names: "typing.Iterable[str] | None" = None,
                   redo: bool = False) -> "list[str]":
    """Sorted keys with a Decal id that need an Image id: none yet, or all of them when redo.
    names limits the keys considered (None: every entry)."""
    keys = sorted(ids) if names is None else sorted(set(names) & set(ids))
    return [k for k in keys if isinstance(ids[k], dict) and ids[k].get("assetId") and (redo or not image_id(ids[k]))]


def run_resolve(ids: "dict[str, dict]", ids_file: pathlib.Path, names: "typing.Iterable[str] | None" = None,
                redo: bool = False, dry_run: bool = False,
                fetch: "typing.Callable[[int], int] | None" = None) -> int:
    """Fill imageId for every pending entry; the file is rewritten after each success.

    Returns 0 all resolved (or nothing to do), 1 at least one failed, 130 interrupted. A run stops after
    RESOLVE_MAX_CONSECUTIVE_FAILS failures in a row (no network, or the Decals are not approved yet).
    """
    fetch = fetch or fetch_image_id
    pending = pending_images(ids, names, redo)
    if not pending:
        log("nothing to resolve (every uploaded image already has an Image id; --redo resolves them again)")
        return 0
    if dry_run:
        for key in pending:
            log("would  %-14s resolve the Image id behind Decal %s" % (key, ids[key]["assetId"]))
        log("dry run: %d Image id(s) to resolve" % len(pending))
        return 0
    log("resolving the Image id behind %d Decal(s) through %s" % (len(pending), ASSET_DELIVERY_BASE))
    resolved_keys: "list[str]" = []
    failed: "list[str]" = []
    streak = 0
    denied = False
    try:
        for key in pending:
            decal = int(ids[key]["assetId"])
            try:
                resolved = fetch(decal)
            except UploadError as exc:
                failed.append(key)
                streak += 1
                denied = denied or exc.status in (401, 403)
                log("FAIL   %-14s Decal %d: %s" % (key, decal, exc))
                if streak >= RESOLVE_MAX_CONSECUTIVE_FAILS:
                    log("stopping: %d failures in a row; check the network, or wait until the Decals are "
                        "approved" % streak)
                    break
                continue
            streak = 0
            ids[key]["imageId"] = resolved
            save_ids(ids_file, ids)
            resolved_keys.append(key)
            log("ok     %-14s Decal %d -> Image %d" % (key, decal, resolved))
    except KeyboardInterrupt:
        log("interrupted; %d resolved this run are saved in %s" % (len(resolved_keys), ids_file.name))
        return 130
    left = [k for k in pending if k not in resolved_keys]
    log("resolved: %d ok, %d failed, %d not tried" % (len(resolved_keys), len(failed),
                                                      len(left) - len(failed)))
    if left:
        log("no Image id yet: " + ", ".join(left) + "  (re-run: python3 -I tools/upload_assets.py --resolve-images)")
        if denied:
            log(STUDIO_ROUTE)
        return 1
    return 0


STUDIO_ROUTE = """the asset delivery service refused (HTTP 401 or 403): its anonymous route wants a login now, and a Decal
still in moderation is refused the same way. Next step, resolve the Image ids through Studio:
  1. python3 -I tools/upload_assets.py --emit-decals-luau | pbcopy          (the Decal ids without an Image id)
  2. paste it between the PASTE markers of tools/studio/resolve_decals.luau and run that file in Studio (Edit
     mode, command bar or the MCP execute_luau); save the Output to a file
  3. python3 -I tools/upload_assets.py --from-studio <that file>"""


# --------------------------------------------------------------------------- Decal -> Image id through Studio

def _is_asset_id(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def parse_studio_output(text: str) -> "tuple[dict[int, int], list[int], int]":
    """Read what tools/studio/resolve_decals.luau printed: (Decal id -> Image id, Decal ids given two different
    Image ids, number of lines ignored). A line counts when it holds a JSON object {"decal": N, "image": M} with
    both positive integers; text around the object (Studio's timestamp, the "- Edit" suffix) is dropped. Blank
    lines are not counted; FAIL lines, warnings and the summary are ignored."""
    pairs: "dict[int, int]" = {}
    conflicts: "set[int]" = set()
    ignored = 0
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        obj: object = None
        start, end = line.find("{"), line.rfind("}")
        if 0 <= start < end:
            try:
                obj = json.loads(line[start:end + 1])
            except ValueError:
                obj = None
        decal = obj.get("decal") if isinstance(obj, dict) else None
        image = obj.get("image") if isinstance(obj, dict) else None
        if not (isinstance(decal, int) and _is_asset_id(decal) and isinstance(image, int) and _is_asset_id(image)):
            ignored += 1
            continue
        if pairs.get(decal, image) != image:
            conflicts.add(decal)
        pairs[decal] = image
    for decal in conflicts:
        del pairs[decal]
    return pairs, sorted(conflicts), ignored


def pending_decals(files: "list[pathlib.Path]", redo: bool = False) -> "list[tuple[int, str]]":
    """(Decal id, key) of every uploaded entry in the ids files that needs an Image id (all of them when redo),
    in file order, one row per Decal id."""
    out: "list[tuple[int, str]]" = []
    seen: "set[int]" = set()
    for path in files:
        ids = load_ids(path)
        for key in pending_images(ids, redo=redo):
            decal = int(ids[key]["assetId"])
            if decal not in seen:
                seen.add(decal)
                out.append((decal, key))
    return out


def emit_decals_luau(rows: "list[tuple[int, str]]") -> str:
    """The DECAL_IDS table for the PASTE block of tools/studio/resolve_decals.luau (a comment names each key)."""
    lines = ["local DECAL_IDS: { number } = {"]
    lines += ["\t%d, -- %s" % (decal, key) for decal, key in rows]
    lines.append("}")
    return "\n".join(lines)


def run_from_studio(files: "list[pathlib.Path]", text: str, redo: bool = False, dry_run: bool = False) -> int:
    """Fill imageId in the ids files from the lines resolve_decals.luau printed. Returns 0 when every line was
    used (or was already recorded), 1 on a problem: no usable line, a Decal no file knows, a Decal with two
    Image ids, an Image id equal to its Decal id, or a recorded Image id that differs (kept unless redo)."""
    pairs, conflicts, ignored = parse_studio_output(text)
    problems = 0
    for decal in conflicts:
        problems += 1
        log("FAIL   Decal %d: the file gives it two different Image ids, skipped (run the snippet again)" % decal)
    if not pairs and not conflicts:
        log("no {\"decal\": N, \"image\": M} line found (%d line(s) ignored); is this the Output of "
            "tools/studio/resolve_decals.luau?" % ignored)
        return 1
    used: "set[int]" = set()
    filled = 0
    already = 0
    still: "list[str]" = []
    for path in files:
        ids = load_ids(path)
        changed = False
        for key in sorted(ids):
            entry = ids[key]
            decal = entry.get("assetId") if isinstance(entry, dict) else None
            if not isinstance(decal, int) or decal not in pairs:
                continue
            used.add(decal)
            new = pairs[decal]
            current = image_id(entry)
            if new == decal:
                problems += 1
                log("FAIL   %-14s Decal %d: Studio gave the Decal's own id as the Image id, skipped" % (key, decal))
            elif current == new:
                already += 1
            elif current and not redo:
                problems += 1
                log("keep   %-14s has Image %d, Studio says %d (--redo replaces it)" % (key, current, new))
            else:
                filled += 1
                changed = True
                entry["imageId"] = new
                log("%s %-14s Decal %d -> Image %d" % ("would " if dry_run else "ok    ", key, decal, new))
        if changed and not dry_run:
            save_ids(path, ids)
        still += missing_image_ids(ids)
    unknown = sorted(d for d in pairs if d not in used)
    if unknown:
        problems += 1
        log("not in any ids file (%s): Decal %s" % (", ".join(f.parent.name + "/" + f.name for f in files),
                                                    ", ".join(str(d) for d in unknown)))
    log("from-studio: %d %s, %d already recorded, %d line(s) ignored%s" % (
        filled, "to fill" if dry_run else "filled", already, ignored, "; dry run, nothing written" if dry_run else ""))
    if still and not dry_run:
        log("still no Image id: " + ", ".join(still))
    return 1 if problems else 0


# --------------------------------------------------------------------------- upload

def upload_one(name: str, model: pathlib.Path, key: str, creator: "dict[str, str]",
               poll_interval: float, fmt: str = DEFAULT_FORMAT, asset_type: str = "Model",
               content_type: "str | None" = None) -> "tuple[int, str]":
    """Create the asset, poll its operation. Returns (assetId, moderation state or '').

    asset_type "Model" with a .glb or .fbx (content type from fmt), or "Decal" with a PNG (content_type
    image/png) for the icon and particle images.
    """
    data = model.read_bytes()
    if len(data) > MAX_FILE_BYTES:
        raise UploadError("%s is %.1f MB, over the 20 MB limit" % (model.name, len(data) / 1048576.0))
    today = datetime.date.today().isoformat()
    what = "model" if asset_type == "Model" else "image"
    meta = {
        "assetType": asset_type,
        "displayName": name,
        "description": "%s %s %s, uploaded %s from the repo's generated assets." % (GAME_NAME, what, name, today),
        "creationContext": {"creator": creator},
    }
    body, ctype = multipart([
        ("request", None, None, json.dumps(meta).encode("utf-8")),
        ("fileContent", model.name, content_type or CONTENT_TYPES[fmt], data),
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
    ap.add_argument("--images", action="store_true",
                    help="upload the PNGs under assets/icons and assets/particles as Decal assets instead of models "
                         "(ids in assets/icons/asset_ids.json), then resolve the Image id behind each Decal")
    ap.add_argument("--textures", action="store_true",
                    help="upload the PNGs under assets/textures (<key>/<key>_color, _normal, _roughness) as Decal "
                         "assets (ids in assets/textures/asset_ids.json under <key>/<map>), then resolve the Image "
                         "id behind each; --only takes keys (fur,ice) or single maps (fur/color)")
    ap.add_argument("--resolve-images", action="store_true",
                    help="only fetch the Image id behind every uploaded Decal that has none yet and record it as "
                         "imageId in assets/icons/asset_ids.json (assets/textures/asset_ids.json with --textures; "
                         "no key needed; --redo does every entry; --only limits it; --dry-run lists them). On a 401 "
                         "or 403 it prints the Studio route (--emit-decals-luau, --from-studio)")
    ap.add_argument("--emit-icons-luau", action="store_true",
                    help="print the Icons and Particles tables (Image ids) for src/shared/data/Icons.luau and exit "
                         "(implies --images); refuses while an uploaded image has no Image id")
    ap.add_argument("--emit-textures-luau", action="store_true",
                    help="print the Textures table (Image ids) for src/shared/data/Textures.luau and exit (implies "
                         "--textures); refuses while any map of a row has no Image id; --only limits the rows")
    ap.add_argument("--emit-decals-luau", action="store_true",
                    help="print the Decal ids that have no Image id yet (icons and textures; --images or --textures "
                         "picks one; --redo lists every uploaded one) as the DECAL_IDS table for the PASTE block of "
                         "tools/studio/resolve_decals.luau and exit")
    ap.add_argument("--from-studio", metavar="FILE", type=pathlib.Path,
                    help="read the {\"decal\": N, \"image\": M} lines that tools/studio/resolve_decals.luau printed "
                         "in Studio (the Output saved to FILE) and fill imageId for icons and textures alike "
                         "(--redo replaces a differing one; --dry-run writes nothing)")
    ap.add_argument("--ids-file", type=pathlib.Path, default=DEFAULT_IDS_FILE, help=argparse.SUPPRESS)
    ap.add_argument("--poll-interval", type=float, default=1.0, help=argparse.SUPPRESS)
    args = ap.parse_args()
    textures_mode = args.textures or args.emit_textures_luau
    images_mode = args.images or args.emit_icons_luau or args.resolve_images or textures_mode
    explicit_ids_file = args.ids_file != DEFAULT_IDS_FILE
    if images_mode and not explicit_ids_file:
        args.ids_file = TEXTURE_IDS_FILE if textures_mode else IMAGE_IDS_FILE
    if images_mode and (args.props or args.species or args.emit_luau):
        die("--images and --textures cannot be combined with --props, --species or --emit-luau")
    if textures_mode and (args.images or args.emit_icons_luau):
        die("--textures cannot be combined with --images or --emit-icons-luau; icons and textures have their own ids files")
    if args.emit_icons_luau and args.resolve_images:
        die("--emit-icons-luau cannot be combined with --resolve-images; run --resolve-images first, then emit")
    if args.emit_textures_luau and args.resolve_images:
        die("--emit-textures-luau cannot be combined with --resolve-images; run --resolve-images --textures first, then emit")
    if args.from_studio and (images_mode or args.emit_decals_luau or args.props or args.species or args.emit_luau
                             or args.only):
        die("--from-studio stands alone (only --redo and --dry-run go with it); it fills both ids files")

    # Studio route: the Decal ids go out as a Luau table, the ids it prints come back from a file. The files are
    # both ids files unless --images or --textures (or --ids-file) picks one.
    studio_files = ([args.ids_file] if explicit_ids_file or images_mode
                    else [IMAGE_IDS_FILE, TEXTURE_IDS_FILE])
    if args.emit_decals_luau:
        rows = pending_decals(studio_files, redo=args.redo)
        if not rows:
            print("upload_assets: no uploaded image in %s is waiting for an Image id (--redo lists them all)"
                  % ", ".join(f.parent.name + "/" + f.name for f in studio_files), file=sys.stderr)
        print(emit_decals_luau(rows))
        return 0
    if args.from_studio:
        try:
            studio_text = args.from_studio.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            die("cannot read %s (%s)" % (args.from_studio, exc))
        return run_from_studio(studio_files, studio_text, redo=args.redo, dry_run=args.dry_run)

    ids = load_ids(args.ids_file)

    if args.emit_luau:
        if not ids:
            print("upload_assets: %s has no ids yet; run the upload first" % args.ids_file, file=sys.stderr)
        print(emit_luau(ids))
        return 0
    if args.emit_icons_luau:
        if not ids:
            print("upload_assets: %s has no ids yet; run --images first" % args.ids_file, file=sys.stderr)
        missing = missing_image_ids(ids)
        if missing:
            die("%d uploaded image(s) have no Image id yet (only the Decal id is known, and an ImageLabel shows "
                "nothing for a Decal id): %s. Run: python3 -I tools/upload_assets.py --resolve-images, then emit "
                "again" % (len(missing), ", ".join(missing)))
        print(emit_icons_luau(ids))
        return 0
    if args.emit_textures_luau:
        only_keys = None
        if args.only:
            tokens = [n.strip() for n in args.only.split(",") if n.strip()]
            known = {name.split("/")[0] for name in discover_textures()} | {k for k, _ in textures_luau_rows()}
            unknown = [t for t in tokens if t not in known]
            if unknown:
                die("unknown texture key(s): %s (keys are the rows of Textures.luau: %s)"
                    % (", ".join(unknown), ", ".join(sorted(known))))
            only_keys = tokens
        rows = texture_rows(only_keys)
        not_uploaded, unresolved = unresolved_textures(ids, rows)
        if not_uploaded or unresolved:
            parts = []
            if not_uploaded:
                parts.append("not uploaded: " + ", ".join(not_uploaded))
            if unresolved:
                parts.append("uploaded but no Image id (a SurfaceAppearance shows nothing for a Decal id): "
                             + ", ".join(unresolved))
            die("%d texture map(s) have no Image id yet; %s. Run: python3 -I tools/upload_assets.py --textures "
                "(uploads and resolves), then --emit-decals-luau and --from-studio if the resolve was refused, then "
                "emit again" % (len(not_uploaded) + len(unresolved), "; ".join(parts)))
        print(emit_textures_luau(ids, only_keys))
        return 0
    if args.resolve_images and not args.images:
        names = None
        if args.only:
            names, unknown = expand_only([n.strip() for n in args.only.split(",") if n.strip()], ids,
                                         grouped=textures_mode)
            if unknown:
                die("not in %s: %s (nothing uploaded under that key yet)" % (args.ids_file.name, ", ".join(unknown)))
        return run_resolve(ids, args.ids_file, names, redo=args.redo, dry_run=args.dry_run)

    fmt = args.format
    kinds: "dict[str, str]" = {}
    wanted: "dict[str, pathlib.Path]" = {}
    if images_mode:
        images = discover_textures() if textures_mode else discover_images()
        if not images:
            die("no .png files found under %s" % (TEXTURES_DIR if textures_mode
                                                    else "%s or %s" % (ICONS_DIR, PARTICLES_DIR)))
        for key, (path, kind) in images.items():
            wanted[key] = path
            kinds[key] = kind
        fmt = "png"
        if args.only:
            names, unknown = expand_only([n.strip() for n in args.only.split(",") if n.strip()], wanted,
                                         grouped=textures_mode)
            if unknown:
                die("unknown %s(s): %s (%s)" % (
                    "texture key" if textures_mode else "image key", ", ".join(unknown),
                    "keys are the folders under assets/textures, or <key>/<map> with map color, normal or roughness"
                    if textures_mode else "keys are the file names under assets/icons and assets/particles"))
            wanted = {n: wanted[n] for n in names}
    else:
        species, props = discover(fmt)
        if not species and not props:
            die("no .%s files found under %s" % (fmt, MODELS_DIR))
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
        if images_mode and pending_images(ids, wanted):
            run_resolve(ids, args.ids_file, wanted, dry_run=True)
        return 0

    if not todo:
        log("nothing to upload (%d already in %s; --redo uploads them again)" % (len(wanted), args.ids_file.name))
        # An earlier upload may have stopped before its Image ids were fetched: finish that now (no key needed).
        return run_resolve(ids, args.ids_file, wanted) if images_mode and pending_images(ids, wanted) else 0

    key = api_key()
    if not key:
        die("ROBLOX_OPEN_CLOUD_KEY (or ROBLOX_API_KEY) is not set. Make a key (Creator Dashboard > Open Cloud > API "
            "Keys, Assets API, Read and Write) and run: export ROBLOX_OPEN_CLOUD_KEY=...  (never put it in the repo)")
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
                if images_mode:
                    # A texture key is "<key>/<map>"; the asset's display name is "<key>_<map>".
                    asset_id, state = upload_one(name.replace("/", "_"), model, key, creator, args.poll_interval, fmt,
                                                 IMAGE_ASSET_TYPE, IMAGE_CONTENT_TYPE)
                else:
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
            if images_mode:
                ids[name]["kind"] = kinds[name]
            save_ids(args.ids_file, ids)
            done += 1
            log("ok     %-14s %-4s asset %d%s" % (name, fmt, asset_id, "  moderation: " + state if state else ""))
    except KeyboardInterrupt:
        log("interrupted; %d uploaded this run are saved in %s" % (done, args.ids_file.name))
        return 130

    log("done: %d uploaded, %d failed, %d skipped" % (done, len(failed), len(wanted) - len(todo)))
    if failed:
        log("failed: " + ", ".join(failed) + "  (re-run to retry only these)")
    resolve_status = 0
    if images_mode and pending_images(ids, wanted):
        # An ImageLabel needs the Image behind each Decal: fetch it now so the entry lands with both ids.
        resolve_status = run_resolve(ids, args.ids_file, wanted)
    return max(1 if failed else 0, resolve_status)


if __name__ == "__main__":
    sys.exit(main())
