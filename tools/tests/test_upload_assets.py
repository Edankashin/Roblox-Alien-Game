"""Tests for tools/upload_assets.py: the Decal -> Image id step and the Icons.luau emitter.

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
        self.rfile.read(int(self.headers.get("Content-Length", "0")))
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


if __name__ == "__main__":
    unittest.main()
