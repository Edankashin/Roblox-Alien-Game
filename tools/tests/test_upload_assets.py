"""Tests for tools/upload_assets.py: the Decal -> Image id step, the Icons.luau and Textures.luau emitters, the
textures upload route and the Studio resolve (--emit-decals-luau, --from-studio).

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). No test talks to Roblox: the Decal fetch and the Open Cloud create call go to a
local mock server on 127.0.0.1, so the live assetdelivery.roblox.com call is covered only by these fixtures.
"""
from __future__ import annotations

import contextlib
import http.server
import importlib.util
import io
import json
import os
import pathlib
import sys
import tempfile
import threading
import unittest
import unittest.mock
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"
_SPEC = importlib.util.spec_from_file_location("upload_assets", HERE.parent / "upload_assets.py")
ua = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(ua)  # type: ignore[union-attr]

SHOP_IMAGE = 121353948620197


def entry(decal: int, image: "int | None" = None, kind: str = "icon") -> dict:
    out = {"assetId": decal, "file": "assets/icons/X.png", "format": "png", "kind": kind,
           "uploadedAt": "2026-10-13T05:42:24Z"}
    if image is not None:
        out["imageId"] = image
    return out


def run_main(argv: "list[str]", env: "dict[str, str] | None" = None) -> "tuple[int, str, str]":
    """Run upload_assets.main() with argv; returns (exit code, stdout, stderr)."""
    out, err = io.StringIO(), io.StringIO()
    code = 0
    with unittest.mock.patch.object(sys, "argv", ["upload_assets.py"] + argv), \
            unittest.mock.patch.dict(os.environ, env or {}), \
            contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        try:
            code = ua.main()
        except SystemExit as exc:
            code = exc.code if isinstance(exc.code, int) else 1
    return code, out.getvalue(), err.getvalue()


class ParseImageIdTest(unittest.TestCase):
    def test_http_url_form(self) -> None:
        self.assertEqual(ua.parse_image_id((FIXTURES / "decal_url.xml").read_bytes()), SHOP_IMAGE)

    def test_rbxassetid_form(self) -> None:
        self.assertEqual(ua.parse_image_id((FIXTURES / "decal_rbxassetid.xml").read_bytes()), SHOP_IMAGE)

    def test_escaped_query_with_more_parameters(self) -> None:
        xml = b'<Content name="Texture"><url>https://www.roblox.com/asset/?assetversionid=5&amp;id=4242</url></Content>'
        self.assertEqual(ua.parse_image_id(xml), 4242)

    def test_texture_content_wins_over_other_urls(self) -> None:
        xml = (b'<Item><Content name="Other"><url>rbxassetid://111</url></Content>'
               b'<Content name="Texture"><url>rbxassetid://222</url></Content></Item>')
        self.assertEqual(ua.parse_image_id(xml), 222)

    def test_no_texture_block_falls_back_to_the_first_reference(self) -> None:
        self.assertEqual(ua.parse_image_id(b"<roblox><url>rbxassetid://333</url></roblox>"), 333)

    def test_no_id_is_an_error(self) -> None:
        with self.assertRaises(ua.UploadError):
            ua.parse_image_id(b'<Content name="Texture"><url></url></Content>')

    def test_a_png_is_not_a_decal(self) -> None:
        with self.assertRaises(ua.UploadError) as ctx:
            ua.parse_image_id(b"\x89PNG\r\n\x1a\n" + b"\x00" * 16)
        self.assertIn("image file", str(ctx.exception))


class EmitTest(unittest.TestCase):
    def test_emit_uses_the_image_id_not_the_decal_id(self) -> None:
        ids = {"Shop": entry(110715054641399, SHOP_IMAGE), "Flake": entry(555, 666, "particle")}
        with unittest.mock.patch.object(ua, "icons_luau_keys", return_value=(["Shop", "Ship"], ["Flake", "Glow"])), \
                unittest.mock.patch.object(ua, "discover_images", return_value={}):
            text = ua.emit_icons_luau(ids)
        self.assertIn("\tShop = %d," % SHOP_IMAGE, text)
        self.assertIn("\tFlake = 666,", text)
        self.assertIn("\tShip = 0,", text)       # a key the data file lists but nothing uploaded: 0
        self.assertIn("\tGlow = 0,", text)
        self.assertNotIn("110715054641399", text)
        self.assertNotIn("555", text)

    def test_missing_image_ids_names_uploaded_entries_without_one(self) -> None:
        ids = {"B": entry(2), "A": entry(1), "C": entry(3, 30), "D": entry(4, 0), "E": {"file": "x"}}
        self.assertEqual(ua.missing_image_ids(ids), ["A", "B", "D"])

    def test_emit_refuses_while_an_image_id_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "asset_ids.json"
            ua.save_ids(path, {"Shop": entry(1, SHOP_IMAGE), "Ship": entry(2), "Codex": entry(3)})
            code, out, err = run_main(["--emit-icons-luau", "--ids-file", str(path)])
        self.assertNotEqual(code, 0)
        self.assertEqual(out, "")
        self.assertIn("Codex, Ship", err)
        self.assertIn("--resolve-images", err)

    def test_emit_prints_when_every_entry_has_an_image_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "asset_ids.json"
            ua.save_ids(path, {"Shop": entry(1, SHOP_IMAGE)})
            code, out, _ = run_main(["--emit-icons-luau", "--ids-file", str(path)])
        self.assertEqual(code, 0)
        self.assertIn("\tShop = %d," % SHOP_IMAGE, out)

    def test_the_committed_ids_file_is_resolved_and_matches_icons_luau(self) -> None:
        """Every recorded Decal has its Image id, and the emitted tables equal the committed Icons.luau tables."""
        ids = ua.load_ids(ua.IMAGE_IDS_FILE)
        self.assertEqual(ua.missing_image_ids(ids), [])
        for key, e in ids.items():
            self.assertNotEqual(e["imageId"], e["assetId"], key)
        icons, particles = ua.icons_luau_keys()
        emitted = ua.emit_icons_luau(ids)
        committed = ua.ICONS_LUAU.read_text(encoding="utf-8")
        for line in emitted.splitlines():
            if line.startswith("\t"):
                self.assertIn(line, committed)
        self.assertEqual(sorted(k for k in ids if ids[k]["kind"] == "icon"), sorted(icons))
        self.assertEqual(sorted(k for k in ids if ids[k]["kind"] == "particle"), sorted(set(ids) - set(icons)))
        self.assertTrue(set(particles) >= set(k for k in ids if ids[k]["kind"] == "particle"))


class RunResolveTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = pathlib.Path(self.tmp.name) / "asset_ids.json"

    def test_fills_missing_ids_and_saves(self) -> None:
        ids = {"A": entry(1), "B": entry(2, 20), "C": entry(3, kind="particle")}
        calls: "list[int]" = []

        def fetch(decal: int) -> int:
            calls.append(decal)
            return decal * 100

        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ua.run_resolve(ids, self.path, fetch=fetch), 0)
        self.assertEqual(calls, [1, 3])                      # B already had one
        saved = json.loads(self.path.read_text(encoding="utf-8"))
        self.assertEqual((saved["A"]["imageId"], saved["B"]["imageId"], saved["C"]["imageId"]), (100, 20, 300))
        self.assertEqual(saved["A"]["assetId"], 1)           # the Decal id stays

    def test_redo_resolves_every_entry_again(self) -> None:
        ids = {"A": entry(1, 10), "B": entry(2, 20)}
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ua.run_resolve(ids, self.path, redo=True, fetch=lambda d: d + 1000), 0)
        self.assertEqual((ids["A"]["imageId"], ids["B"]["imageId"]), (1001, 1002))

    def test_names_limit_the_run(self) -> None:
        ids = {"A": entry(1), "B": entry(2)}
        with contextlib.redirect_stdout(io.StringIO()):
            ua.run_resolve(ids, self.path, names=["B"], fetch=lambda d: d + 1000)
        self.assertNotIn("imageId", ids["A"])
        self.assertEqual(ids["B"]["imageId"], 1002)

    def test_dry_run_fetches_and_writes_nothing(self) -> None:
        ids = {"A": entry(1)}

        def fetch(decal: int) -> int:
            raise AssertionError("dry run must not fetch")

        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ua.run_resolve(ids, self.path, dry_run=True, fetch=fetch), 0)
        self.assertIn("would  A", out.getvalue())
        self.assertFalse(self.path.exists())

    def test_one_failure_is_reported_and_the_rest_continue(self) -> None:
        ids = {"A": entry(1), "B": entry(2), "C": entry(3)}

        def fetch(decal: int) -> int:
            if decal == 2:
                raise ua.UploadError("HTTP 403 not approved")
            return decal + 1000

        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ua.run_resolve(ids, self.path, fetch=fetch), 1)
        self.assertEqual((ids["A"]["imageId"], ids["C"]["imageId"]), (1001, 1003))
        self.assertNotIn("imageId", ids["B"])
        self.assertIn("no Image id yet: B", out.getvalue())
        self.assertIn("--resolve-images", out.getvalue())

    def test_a_401_or_403_prints_the_studio_route(self) -> None:
        for status in (401, 403):
            ids = {"A": entry(1)}

            def fetch(decal: int) -> int:
                raise ua.UploadError("HTTP %d denied" % status, status=status)

            with contextlib.redirect_stdout(io.StringIO()) as out:
                self.assertEqual(ua.run_resolve(ids, self.path, fetch=fetch), 1)
            text = out.getvalue()
            self.assertIn("--emit-decals-luau", text, status)
            self.assertIn("tools/studio/resolve_decals.luau", text, status)
            self.assertIn("--from-studio", text, status)

    def test_other_failures_do_not_print_the_studio_route(self) -> None:
        ids = {"A": entry(1)}

        def fetch(decal: int) -> int:
            raise ua.UploadError("HTTP 500 oops", status=500)

        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ua.run_resolve(ids, self.path, fetch=fetch), 1)
        self.assertNotIn("resolve_decals", out.getvalue())

    def test_stops_after_consecutive_failures(self) -> None:
        ids = {k: entry(i) for i, k in enumerate("ABCDEF", start=1)}
        tried: "list[int]" = []

        def fetch(decal: int) -> int:
            tried.append(decal)
            raise ua.UploadError("network error")

        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ua.run_resolve(ids, self.path, fetch=fetch), 1)
        self.assertEqual(len(tried), ua.RESOLVE_MAX_CONSECUTIVE_FAILS)
        self.assertIn("stopping", out.getvalue())


class _MockRoblox(http.server.BaseHTTPRequestHandler):
    """Open Cloud create (POST /assets/v1/assets) and asset delivery (GET /v1/asset/?id=) on one port."""
    server_version = "mock"
    log: "list[tuple[str, str, dict[str, str]]]" = []
    bodies: "list[bytes]" = []                           # the bodies of the POSTs, in order
    delivery_failures: "dict[str, list[int]]" = {}      # path -> statuses to answer before the real one

    def log_message(self, *args: object) -> None:
        pass

    def _reply(self, status: int, body: bytes, ctype: str = "application/json") -> None:
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        self.bodies.append(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        self.log.append(("POST", self.path, {k.lower(): v for k, v in self.headers.items()}))
        self._reply(200, json.dumps({"path": "operations/1", "done": True,
                                     "response": {"assetId": "555",
                                                  "moderationResult": {"moderationState": "MODERATION_STATE_APPROVED"}}}).encode())

    def do_GET(self) -> None:
        self.log.append(("GET", self.path, {k.lower(): v for k, v in self.headers.items()}))
        pending = self.delivery_failures.get(self.path, [])
        if pending:
            self._reply(pending.pop(0), b"busy", "text/plain")
        elif self.path == "/v1/asset/?id=555":
            self._reply(200, (FIXTURES / "decal_url.xml").read_bytes(), "text/xml")
        elif self.path == "/v1/asset/?id=556":
            self._reply(200, (FIXTURES / "decal_rbxassetid.xml").read_bytes(), "text/xml")
        else:
            self._reply(403, b"not approved", "text/plain")


class MockServerCase(unittest.TestCase):
    def setUp(self) -> None:
        _MockRoblox.log = []
        _MockRoblox.bodies = []
        _MockRoblox.delivery_failures = {}
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), _MockRoblox)
        threading.Thread(target=self.server.serve_forever, args=(0.01,), daemon=True).start()
        self.base = "http://127.0.0.1:%d" % self.server.server_address[1]
        # Ignore any proxy in the environment: the mock is local.
        urllib.request.install_opener(urllib.request.build_opener(urllib.request.ProxyHandler({})))
        patches = [unittest.mock.patch.object(ua, "ASSET_DELIVERY_BASE", self.base + "/v1/asset"),
                   unittest.mock.patch.object(ua, "API_BASE", self.base + "/assets/v1"),
                   unittest.mock.patch.object(ua.time, "sleep", lambda s: None)]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)
        self.addCleanup(urllib.request.install_opener, None)
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)


class FetchImageIdTest(MockServerCase):
    def test_resolves_a_decal_and_sends_no_api_key(self) -> None:
        self.assertEqual(ua.fetch_image_id(555), SHOP_IMAGE)
        method, path, headers = _MockRoblox.log[0]
        self.assertEqual((method, path), ("GET", "/v1/asset/?id=555"))
        self.assertNotIn("x-api-key", headers)

    def test_other_xml_form(self) -> None:
        self.assertEqual(ua.fetch_image_id(556), SHOP_IMAGE)

    def test_retries_a_gateway_error_then_succeeds(self) -> None:
        _MockRoblox.delivery_failures["/v1/asset/?id=555"] = [503, 429]
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ua.fetch_image_id(555), SHOP_IMAGE)
        self.assertEqual(len(_MockRoblox.log), 3)

    def test_a_refused_decal_is_a_plain_failure_not_fatal(self) -> None:
        with self.assertRaises(ua.UploadError) as ctx:
            ua.fetch_image_id(999)
        self.assertFalse(ctx.exception.fatal)
        self.assertIn("HTTP 403", str(ctx.exception))
        self.assertIn("moderation", str(ctx.exception))
        self.assertEqual(len(_MockRoblox.log), 1)            # 403 is not retried


class ImagesFlowTest(MockServerCase):
    """main() --images uploads, then resolves, so a fresh upload lands with both ids."""

    def setUp(self) -> None:
        super().setUp()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        (self.root / "assets" / "icons").mkdir(parents=True)
        self.png = self.root / "assets" / "icons" / "Shop.png"
        self.png.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 32)
        self.ids = self.root / "asset_ids.json"
        for p in (unittest.mock.patch.object(ua, "REPO", self.root),
                  unittest.mock.patch.object(ua, "discover_images", return_value={"Shop": (self.png, "icon")})):
            p.start()
            self.addCleanup(p.stop)
        self.env = {"ROBLOX_OPEN_CLOUD_KEY": "test-key-not-real", "ROBLOX_CREATOR_USER_ID": "1",
                    "ROBLOX_CREATOR_GROUP_ID": ""}

    def test_images_uploads_then_resolves(self) -> None:
        code, out, err = run_main(["--images", "--ids-file", str(self.ids), "--poll-interval", "0"], self.env)
        self.assertEqual(code, 0, out + err)
        saved = json.loads(self.ids.read_text(encoding="utf-8"))
        self.assertEqual((saved["Shop"]["assetId"], saved["Shop"]["imageId"]), (555, SHOP_IMAGE))
        self.assertIn("Decal 555 -> Image %d" % SHOP_IMAGE, out)
        gets = [h for m, _, h in _MockRoblox.log if m == "GET"]
        posts = [h for m, _, h in _MockRoblox.log if m == "POST"]
        self.assertEqual((len(posts), len(gets)), (1, 1))
        self.assertEqual(posts[0].get("x-api-key"), "test-key-not-real")   # the Open Cloud call has the key
        self.assertNotIn("x-api-key", gets[0])                              # the asset delivery call never does
        self.assertNotIn("test-key-not-real", out + err)

    def test_a_failed_resolve_after_a_good_upload_exits_1_and_says_how_to_finish(self) -> None:
        _MockRoblox.delivery_failures["/v1/asset/?id=555"] = [403, 403, 403, 403]
        code, out, _ = run_main(["--images", "--ids-file", str(self.ids), "--poll-interval", "0"], self.env)
        self.assertEqual(code, 1)
        saved = json.loads(self.ids.read_text(encoding="utf-8"))
        self.assertEqual(saved["Shop"]["assetId"], 555)
        self.assertNotIn("imageId", saved["Shop"])
        self.assertIn("--resolve-images", out)

    def test_second_run_with_everything_done_uploads_and_fetches_nothing(self) -> None:
        run_main(["--images", "--ids-file", str(self.ids), "--poll-interval", "0"], self.env)
        _MockRoblox.log.clear()
        code, out, _ = run_main(["--images", "--ids-file", str(self.ids)], self.env)
        self.assertEqual(code, 0)
        self.assertEqual(_MockRoblox.log, [])

    def test_resolve_images_alone_needs_no_key(self) -> None:
        ua.save_ids(self.ids, {"Shop": entry(555)})
        code, out, err = run_main(["--resolve-images", "--ids-file", str(self.ids)],
                                  {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_CREATOR_USER_ID": ""})
        self.assertEqual(code, 0, out + err)
        self.assertEqual(json.loads(self.ids.read_text(encoding="utf-8"))["Shop"]["imageId"], SHOP_IMAGE)
        self.assertEqual([m for m, _, _ in _MockRoblox.log], ["GET"])

    def test_images_dry_run_needs_no_key_and_lists_unresolved_entries(self) -> None:
        ua.save_ids(self.ids, {"Shop": entry(555)})
        code, out, _ = run_main(["--images", "--dry-run", "--ids-file", str(self.ids)],
                                {"ROBLOX_OPEN_CLOUD_KEY": ""})
        self.assertEqual(code, 0)
        self.assertIn("would  Shop", out)
        self.assertEqual(_MockRoblox.log, [])


def texture_ids(**decals: "tuple[int, int | None]") -> "dict[str, dict]":
    """{'fur/color': entry} from fur_color=(decal, image) keyword pairs."""
    out = {}
    for name, (decal, image) in decals.items():
        e = entry(decal, image, "texture")
        e["file"] = "assets/textures/%s/%s.png" % (name.split("_")[0], name)
        out[name.replace("_", "/", 1)] = e
    return out


def full_texture_ids(keys: "list[str]", base: int = 1000) -> "dict[str, dict]":
    """Every map of the keys uploaded (Decal id base + n) and resolved (Image id base + 500 + n)."""
    ids = {}
    n = 0
    for key in keys:
        for suffix, _ in ua.TEXTURE_MAPS:
            n += 1
            ids["%s/%s" % (key, suffix)] = entry(base + n, base + 500 + n, "texture")
    return ids


class ExpandOnlyTest(unittest.TestCase):
    NAMES = ["fur/color", "fur/normal", "fur/roughness", "ice/color", "Shop"]

    def test_exact_names(self) -> None:
        self.assertEqual(ua.expand_only(["Shop", "fur/normal"], self.NAMES), (["Shop", "fur/normal"], []))

    def test_a_key_stands_for_its_maps_only_when_grouped(self) -> None:
        self.assertEqual(ua.expand_only(["fur"], self.NAMES, grouped=True),
                         (["fur/color", "fur/normal", "fur/roughness"], []))
        self.assertEqual(ua.expand_only(["fur"], self.NAMES), ([], ["fur"]))

    def test_unknown_tokens_and_repeats(self) -> None:
        self.assertEqual(ua.expand_only(["ice", "ice/color", "nope"], self.NAMES, grouped=True),
                         (["ice/color"], ["nope"]))


class ApiKeyTest(unittest.TestCase):
    def test_open_cloud_name_first_then_api_key_name(self) -> None:
        with unittest.mock.patch.dict(os.environ, {"ROBLOX_OPEN_CLOUD_KEY": " one ", "ROBLOX_API_KEY": "two"}):
            self.assertEqual(ua.api_key(), "one")
        with unittest.mock.patch.dict(os.environ, {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": "two"}):
            self.assertEqual(ua.api_key(), "two")
        with unittest.mock.patch.dict(os.environ, {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": ""}):
            self.assertEqual(ua.api_key(), "")


class TexturesDiscoveryTest(unittest.TestCase):
    def test_finds_the_three_maps_of_each_key(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            for key, maps in (("fur", ("color", "normal", "roughness")), ("ice", ("color",))):
                (root / key).mkdir()
                for suffix in maps:
                    (root / key / ("%s_%s.png" % (key, suffix))).write_bytes(b"x")
            (root / "fur" / "notes.txt").write_bytes(b"x")
            (root / "fur" / "fur_height.png").write_bytes(b"x")          # not one of the three maps
            (root / "README.md").write_bytes(b"x")
            with unittest.mock.patch.object(ua, "TEXTURES_DIR", root):
                found = ua.discover_textures()
        self.assertEqual(list(found), ["fur/color", "fur/normal", "fur/roughness", "ice/color"])
        self.assertTrue(all(kind == "texture" for _, kind in found.values()))

    def test_the_committed_folders_match_textures_luau(self) -> None:
        found = ua.discover_textures()
        keys = [k for k, _ in ua.textures_luau_rows()]
        self.assertEqual(len(keys), 5)
        self.assertEqual(sorted(found), sorted("%s/%s" % (k, m) for k in keys for m, _ in ua.TEXTURE_MAPS))
        for name, (path, _) in found.items():
            self.assertTrue(path.is_file(), name)


class EmitTexturesTest(unittest.TestCase):
    ROWS = ("local Textures: { [string]: Types.TextureRow } = {\n"
            "\tfur = { colorMap = 0, normalMap = 0, roughnessMap = 0, tiling = { 3, 3 } },\n"
            "\tice = { colorMap = 0, normalMap = 0, roughnessMap = 0, tiling = { 1, 1 } },\n"
            "}\n\nreturn Textures\n")

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.luau = pathlib.Path(self.tmp.name) / "Textures.luau"
        self.luau.write_text("--!strict\n-- header\n" + self.ROWS, encoding="utf-8")
        for p in (unittest.mock.patch.object(ua, "TEXTURES_LUAU", self.luau),
                  unittest.mock.patch.object(ua, "discover_textures", return_value={})):
            p.start()
            self.addCleanup(p.stop)

    def test_rows_keep_their_tiling(self) -> None:
        self.assertEqual(ua.textures_luau_rows(), [("fur", ", tiling = { 3, 3 }"), ("ice", ", tiling = { 1, 1 }")])

    def test_emit_uses_the_image_ids_not_the_decal_ids(self) -> None:
        ids = full_texture_ids(["fur", "ice"])
        text = ua.emit_textures_luau(ids)
        self.assertEqual(text.splitlines(), [
            "local Textures: { [string]: Types.TextureRow } = {",
            "\tfur = { colorMap = 1501, normalMap = 1502, roughnessMap = 1503, tiling = { 3, 3 } },",
            "\tice = { colorMap = 1504, normalMap = 1505, roughnessMap = 1506, tiling = { 1, 1 } },",
            "}"])
        for n in range(1, 7):
            self.assertNotIn(str(1000 + n), text)

    def test_emit_limits_the_rows_to_the_keys(self) -> None:
        text = ua.emit_textures_luau(full_texture_ids(["fur", "ice"]), ["ice"])
        self.assertEqual(len(text.splitlines()), 3)
        self.assertIn("\tice = ", text)
        self.assertNotIn("\tfur = ", text)

    def test_a_key_the_data_file_lacks_is_added_with_a_1x1_tiling(self) -> None:
        with unittest.mock.patch.object(ua, "discover_textures", return_value={"scales/color": (self.luau, "texture")}):
            rows = ua.texture_rows()
        self.assertEqual(rows[-1], ("scales", ", tiling = { 1, 1 }"))

    def test_unresolved_names_what_is_missing(self) -> None:
        ids = full_texture_ids(["fur"])
        del ids["fur/normal"]                                  # never uploaded
        del ids["fur/color"]["imageId"]                        # uploaded, Image id not known yet
        rows = ua.texture_rows()
        not_uploaded, unresolved = ua.unresolved_textures(ids, rows)
        self.assertEqual(unresolved, ["fur/color"])
        self.assertEqual(not_uploaded, ["fur/normal", "ice/color", "ice/normal", "ice/roughness"])

    def test_main_refuses_while_an_id_is_missing_and_prints_nothing(self) -> None:
        ids = full_texture_ids(["fur"])
        del ids["fur/color"]["imageId"]
        path = pathlib.Path(self.tmp.name) / "asset_ids.json"
        ua.save_ids(path, ids)
        code, out, err = run_main(["--emit-textures-luau", "--ids-file", str(path)])
        self.assertEqual(code, 2)
        self.assertEqual(out, "")
        self.assertIn("fur/color", err)                        # uploaded, no Image id
        self.assertIn("ice/color", err)                        # not uploaded
        self.assertIn("--textures", err)
        self.assertIn("--from-studio", err)

    def test_main_prints_the_table_when_every_id_is_in(self) -> None:
        path = pathlib.Path(self.tmp.name) / "asset_ids.json"
        ua.save_ids(path, full_texture_ids(["fur", "ice"]))
        code, out, err = run_main(["--emit-textures-luau", "--ids-file", str(path)])
        self.assertEqual((code, err), (0, ""))
        self.assertIn("\tfur = { colorMap = 1501, normalMap = 1502, roughnessMap = 1503, tiling = { 3, 3 } },", out)
        self.assertTrue(out.startswith("local Textures: "))

    def test_main_only_emits_and_checks_just_those_keys(self) -> None:
        path = pathlib.Path(self.tmp.name) / "asset_ids.json"
        ua.save_ids(path, full_texture_ids(["fur"]))           # ice not uploaded
        code, out, _ = run_main(["--emit-textures-luau", "--only", "fur", "--ids-file", str(path)])
        self.assertEqual(code, 0)
        self.assertNotIn("ice", out)
        code, _, err = run_main(["--emit-textures-luau", "--only", "bogus", "--ids-file", str(path)])
        self.assertEqual(code, 2)
        self.assertIn("bogus", err)

    def test_the_committed_table_round_trips(self) -> None:
        """The real Textures.luau rows survive an emit: same keys, same tiling, only the ids change."""
        with unittest.mock.patch.object(ua, "TEXTURES_LUAU", ua.REPO / "src" / "shared" / "data" / "Textures.luau"):
            real = ua.textures_luau_rows()
            text = ua.emit_textures_luau(full_texture_ids([k for k, _ in real]))
        self.assertEqual(len(real), 5)
        self.assertEqual([k for k, _ in real], [line.split()[0] for line in text.splitlines()[1:-1]])
        for (key, tail), line in zip(real, text.splitlines()[1:-1]):
            self.assertTrue(line.endswith(tail + " },"), line)


class TexturesFlowTest(MockServerCase):
    """main() --textures uploads each map as a Decal, records it under <key>/<map>, resolves the Image ids."""

    def setUp(self) -> None:
        super().setUp()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        folder = self.root / "assets" / "textures" / "fur"
        folder.mkdir(parents=True)
        self.found = {}
        for suffix in ("color", "normal"):
            png = folder / ("fur_%s.png" % suffix)
            png.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 32)
            self.found["fur/" + suffix] = (png, "texture")
        other = self.root / "assets" / "textures" / "ice"
        other.mkdir()
        (other / "ice_color.png").write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 32)
        self.found["ice/color"] = (other / "ice_color.png", "texture")
        self.ids = self.root / "asset_ids.json"
        for p in (unittest.mock.patch.object(ua, "REPO", self.root),
                  unittest.mock.patch.object(ua, "discover_textures", return_value=self.found)):
            p.start()
            self.addCleanup(p.stop)
        # The key comes from ROBLOX_API_KEY alone here: the other name is empty.
        self.env = {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": "test-key-not-real",
                    "ROBLOX_CREATOR_USER_ID": "1", "ROBLOX_CREATOR_GROUP_ID": ""}

    def run_textures(self, extra: "list[str]") -> "tuple[int, str, str]":
        return run_main(["--textures", "--ids-file", str(self.ids), "--poll-interval", "0"] + extra, self.env)

    def test_dry_run_lists_the_maps_and_needs_no_key(self) -> None:
        code, out, _ = run_main(["--textures", "--dry-run", "--ids-file", str(self.ids)],
                                {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": ""})
        self.assertEqual(code, 0)
        for name in ("fur/color", "fur/normal", "ice/color"):
            self.assertIn("would  " + name, out)
        self.assertEqual(_MockRoblox.log, [])
        self.assertFalse(self.ids.exists())

    def test_uploads_as_decals_records_both_ids_and_never_shows_the_key(self) -> None:
        code, out, err = self.run_textures(["--only", "fur"])
        self.assertEqual(code, 0, out + err)
        saved = json.loads(self.ids.read_text(encoding="utf-8"))
        self.assertEqual(sorted(saved), ["fur/color", "fur/normal"])       # --only fur: the key, not the other set
        for name, e in saved.items():
            self.assertEqual((e["assetId"], e["imageId"], e["kind"], e["format"]), (555, SHOP_IMAGE, "texture", "png"), name)
        self.assertEqual(saved["fur/color"]["file"], "assets/textures/fur/fur_color.png")
        posts = [b for b in _MockRoblox.bodies]
        self.assertEqual(len(posts), 2)
        self.assertIn(b'"assetType": "Decal"', posts[0])
        self.assertIn(b'"displayName": "fur_color"', posts[0])                # no slash in the display name
        self.assertIn(b"image/png", posts[0])
        keyed = [h for m, _, h in _MockRoblox.log if m == "POST"]
        self.assertTrue(all(h.get("x-api-key") == "test-key-not-real" for h in keyed))
        gets = [h for m, _, h in _MockRoblox.log if m == "GET"]
        self.assertTrue(gets and all("x-api-key" not in h for h in gets))
        self.assertNotIn("test-key-not-real", out + err + self.ids.read_text(encoding="utf-8"))

    def test_only_takes_a_single_map_and_rejects_unknown_names(self) -> None:
        code, out, _ = self.run_textures(["--only", "ice/color"])
        self.assertEqual(code, 0)
        self.assertEqual(sorted(json.loads(self.ids.read_text(encoding="utf-8"))), ["ice/color"])
        code, _, err = self.run_textures(["--only", "fur/height"])
        self.assertEqual(code, 2)
        self.assertIn("fur/height", err)

    def test_second_run_skips_and_redo_uploads_again(self) -> None:
        self.run_textures([])
        _MockRoblox.log.clear()
        code, out, _ = self.run_textures([])
        self.assertEqual(code, 0)
        self.assertEqual(_MockRoblox.log, [])
        self.assertIn("skip   fur/color", out)
        code, out, _ = self.run_textures(["--redo", "--only", "ice/color"])
        self.assertEqual(code, 0)
        self.assertEqual([m for m, _, _ in _MockRoblox.log if m == "POST"], ["POST"])

    def test_resolve_only_for_textures_needs_no_key(self) -> None:
        ua.save_ids(self.ids, {"fur/color": entry(555, None, "texture")})
        code, out, err = run_main(["--textures", "--resolve-images", "--ids-file", str(self.ids)],
                                  {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": ""})
        self.assertEqual(code, 0, out + err)
        self.assertEqual(json.loads(self.ids.read_text(encoding="utf-8"))["fur/color"]["imageId"], SHOP_IMAGE)
        code, _, err = run_main(["--textures", "--resolve-images", "--only", "moss", "--ids-file", str(self.ids)])
        self.assertEqual(code, 2)

    def test_the_default_ids_file_for_textures_is_the_textures_one(self) -> None:
        with unittest.mock.patch.object(ua, "TEXTURE_IDS_FILE", self.ids):
            code, out, _ = run_main(["--textures", "--only", "ice", "--poll-interval", "0"], self.env)
        self.assertEqual(code, 0, out)
        self.assertEqual(sorted(json.loads(self.ids.read_text(encoding="utf-8"))), ["ice/color"])

    def test_a_refused_resolve_prints_the_studio_route(self) -> None:
        _MockRoblox.delivery_failures["/v1/asset/?id=555"] = [401]
        code, out, _ = self.run_textures(["--only", "ice/color"])
        self.assertEqual(code, 1)
        saved = json.loads(self.ids.read_text(encoding="utf-8"))
        self.assertEqual(saved["ice/color"]["assetId"], 555)
        self.assertNotIn("imageId", saved["ice/color"])
        self.assertIn("--emit-decals-luau", out)
        self.assertIn("--from-studio", out)

    def test_icons_and_textures_cannot_be_mixed(self) -> None:
        code, _, err = run_main(["--textures", "--images", "--dry-run"])
        self.assertEqual(code, 2)
        self.assertIn("--textures", err)


class ParseStudioOutputTest(unittest.TestCase):
    def test_fixture_three_json_lines_and_one_junk_line(self) -> None:
        text = (FIXTURES / "studio_output.txt").read_text(encoding="utf-8")
        pairs, conflicts, ignored = ua.parse_studio_output(text)
        self.assertEqual(pairs, {1001: 2001, 1002: 2002, 1003: 2003})   # the middle line has Studio's timestamp
        self.assertEqual((conflicts, ignored), ([], 1))

    def test_ignores_everything_that_is_not_a_positive_integer_pair(self) -> None:
        text = "\n".join([
            "",
            "resolve_decals: 1 ok, 4 failed, 5 total",
            '{"decal": 1, "image": 2',                       # cut off
            '{"decal": "3", "image": 4}',                    # strings
            '{"decal": 5, "image": 0}',                      # zero
            '{"decal": -6, "image": 7}',                     # negative
            '{"decal": true, "image": 8}',                   # bool
            '{"decal": 9}',                                  # no image
            '{"decal": 12, "image": 13}',                    # the one good line
            "   ",
        ])
        pairs, conflicts, ignored = ua.parse_studio_output(text)
        self.assertEqual((pairs, conflicts, ignored), ({12: 13}, [], 7))

    def test_repeat_is_fine_but_two_different_images_is_a_conflict(self) -> None:
        text = ('{"decal": 1, "image": 2}\n{"decal": 1, "image": 2}\n'
                '{"decal": 3, "image": 4}\n{"decal": 3, "image": 5}\n')
        pairs, conflicts, ignored = ua.parse_studio_output(text)
        self.assertEqual((pairs, conflicts, ignored), ({1: 2}, [3], 0))


class RunFromStudioTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = pathlib.Path(self.tmp.name)
        self.icons = root / "icons.json"
        self.textures = root / "textures.json"
        self.text = (FIXTURES / "studio_output.txt").read_text(encoding="utf-8")
        ua.save_ids(self.icons, {"Shop": entry(1001), "Ship": entry(7777), "Codex": entry(1003, 30)})
        ua.save_ids(self.textures, texture_ids(fur_color=(1002, None), fur_normal=(8888, None)))

    def load(self, path: pathlib.Path) -> dict:
        return json.loads(path.read_text(encoding="utf-8"))

    def run_studio(self, text: "str | None" = None, **kw: bool) -> "tuple[int, str]":
        with contextlib.redirect_stdout(io.StringIO()) as out:
            code = ua.run_from_studio([self.icons, self.textures], self.text if text is None else text, **kw)
        return code, out.getvalue()

    def test_fills_icons_and_textures_by_decal_id(self) -> None:
        code, out = self.run_studio()
        self.assertEqual(self.load(self.icons)["Shop"]["imageId"], 2001)
        self.assertEqual(self.load(self.textures)["fur/color"]["imageId"], 2002)
        self.assertEqual(self.load(self.icons)["Shop"]["assetId"], 1001)       # the Decal id stays
        self.assertNotIn("imageId", self.load(self.icons)["Ship"])             # not in the Studio output
        self.assertIn("Decal 1001 -> Image 2001", out)
        self.assertIn("still no Image id: Ship, fur/normal", out)
        self.assertIn("2 filled", out)

    def test_a_recorded_image_id_that_differs_is_kept_and_reported(self) -> None:
        code, out = self.run_studio()
        self.assertEqual(code, 1)                              # Codex: recorded 30, Studio says 2003
        self.assertEqual(self.load(self.icons)["Codex"]["imageId"], 30)
        self.assertIn("--redo", out)
        code, out = self.run_studio(redo=True)
        self.assertEqual(code, 0, out)
        self.assertEqual(self.load(self.icons)["Codex"]["imageId"], 2003)

    def test_a_rerun_changes_nothing(self) -> None:
        self.run_studio(redo=True)
        before = (self.icons.read_text(encoding="utf-8"), self.textures.read_text(encoding="utf-8"))
        code, out = self.run_studio()
        self.assertEqual(code, 0, out)
        self.assertEqual(before, (self.icons.read_text(encoding="utf-8"), self.textures.read_text(encoding="utf-8")))
        self.assertIn("0 filled, 3 already recorded", out)

    def test_dry_run_writes_nothing(self) -> None:
        before = (self.icons.read_text(encoding="utf-8"), self.textures.read_text(encoding="utf-8"))
        code, out = self.run_studio(dry_run=True)
        self.assertEqual(before, (self.icons.read_text(encoding="utf-8"), self.textures.read_text(encoding="utf-8")))
        self.assertIn("would  Shop", out)

    def test_a_decal_no_file_knows_is_a_problem(self) -> None:
        code, out = self.run_studio('{"decal": 1001, "image": 2001}\n{"decal": 4242, "image": 4243}\n')
        self.assertEqual(code, 1)
        self.assertIn("Decal 4242", out)
        self.assertEqual(self.load(self.icons)["Shop"]["imageId"], 2001)       # the known one is still filled

    def test_the_decals_own_id_is_not_an_image_id(self) -> None:
        code, out = self.run_studio('{"decal": 1001, "image": 1001}\n')
        self.assertEqual(code, 1)
        self.assertNotIn("imageId", self.load(self.icons)["Shop"])

    def test_a_conflicting_decal_is_skipped(self) -> None:
        code, out = self.run_studio('{"decal": 1001, "image": 5}\n{"decal": 1001, "image": 6}\n')
        self.assertEqual(code, 1)
        self.assertNotIn("imageId", self.load(self.icons)["Shop"])
        self.assertIn("two different Image ids", out)

    def test_no_usable_line_is_a_problem(self) -> None:
        code, out = self.run_studio("FAIL 1: HTTP 403\nresolve_decals: 0 ok, 1 failed, 1 total\n")
        self.assertEqual(code, 1)
        self.assertIn("resolve_decals.luau", out)

    def test_main_reads_the_file_and_fills_both_default_files(self) -> None:
        with unittest.mock.patch.object(ua, "IMAGE_IDS_FILE", self.icons), \
                unittest.mock.patch.object(ua, "TEXTURE_IDS_FILE", self.textures):
            code, out, err = run_main(["--from-studio", str(FIXTURES / "studio_output.txt"), "--redo"])
        self.assertEqual(code, 0, out + err)
        self.assertEqual(self.load(self.icons)["Shop"]["imageId"], 2001)
        self.assertEqual(self.load(self.textures)["fur/color"]["imageId"], 2002)

    def test_main_stands_alone_and_reports_a_missing_file(self) -> None:
        code, _, err = run_main(["--from-studio", str(FIXTURES / "studio_output.txt"), "--images"])
        self.assertEqual(code, 2)
        code, _, err = run_main(["--from-studio", str(FIXTURES / "no_such_file.txt")])
        self.assertEqual(code, 2)
        self.assertIn("no_such_file.txt", err)


class EmitDecalsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = pathlib.Path(self.tmp.name)
        self.icons = root / "icons.json"
        self.textures = root / "textures.json"
        ua.save_ids(self.icons, {"Shop": entry(11), "Ship": entry(12, 120), "Dup": entry(11)})
        ua.save_ids(self.textures, texture_ids(fur_color=(21, None), fur_normal=(22, 220)))

    def test_lists_decals_without_an_image_id_once_each(self) -> None:
        self.assertEqual(ua.pending_decals([self.icons, self.textures]), [(11, "Dup"), (21, "fur/color")])
        self.assertEqual([d for d, _ in ua.pending_decals([self.icons, self.textures], redo=True)],
                         [11, 12, 21, 22])

    def test_table_text(self) -> None:
        text = ua.emit_decals_luau([(11, "Shop"), (21, "fur/color")])
        self.assertEqual(text.splitlines(), ["local DECAL_IDS: { number } = {", "\t11, -- Shop", "\t21, -- fur/color", "}"])

    def test_main_prints_the_table_for_both_files_or_one(self) -> None:
        with unittest.mock.patch.object(ua, "IMAGE_IDS_FILE", self.icons), \
                unittest.mock.patch.object(ua, "TEXTURE_IDS_FILE", self.textures):
            code, out, _ = run_main(["--emit-decals-luau"])
            self.assertEqual(code, 0)
            self.assertIn("21, -- fur/color", out)
            self.assertIn("11, -- Dup", out)
            code, out, _ = run_main(["--emit-decals-luau", "--textures"])
            self.assertIn("21, -- fur/color", out)
            self.assertNotIn("Dup", out)

    def test_main_with_nothing_pending_prints_an_empty_table_and_says_so(self) -> None:
        ua.save_ids(self.icons, {"Ship": entry(12, 120)})
        ua.save_ids(self.textures, {})
        code, out, err = run_main(["--emit-decals-luau", "--ids-file", str(self.icons)])
        self.assertEqual((code, out), (0, "local DECAL_IDS: { number } = {\n}\n"))
        self.assertIn("no uploaded image", err)

    def test_the_studio_snippet_has_the_paste_block_this_table_replaces(self) -> None:
        snippet = (HERE.parent / "studio" / "resolve_decals.luau").read_text(encoding="utf-8")
        block = snippet.split("-- BEGIN PASTE", 1)[1].split("-- END PASTE", 1)[0]
        self.assertIn("local DECAL_IDS: { number } =", block)
        self.assertIn("GetObjects", snippet)
        self.assertIn('{"decal": %d, "image": %d}', snippet)


if __name__ == "__main__":
    unittest.main()
