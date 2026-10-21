"""Tests for the block-cell route of tools/upload_assets.py (--blocky, --fill-blocky; Decision B47) and the two generators it
fills through (tools/blocky/export_models.py --emit-luau, tools/blocky/rigs.py).

Standard library only, no network: the plan and the fill are pure functions over a temporary folder, and the one upload flow
talks to the local mock server of test_upload_assets. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
"""
from __future__ import annotations

import contextlib
import io
import json
import os
import pathlib
import sys
import tempfile
import unittest
import unittest.mock

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "blocky"))
import test_upload_assets as T  # noqa: E402  (the mock Open Cloud server and the loaded tool)
import export_models as X  # noqa: E402
import rigs as RG  # noqa: E402

ua = T.ua
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def write(path: pathlib.Path, data: "bytes | str") -> pathlib.Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, str):
        path.write_text(data, encoding="utf-8")
    else:
        path.write_bytes(data)
    return path


def cell_rows(name: str, sheets: "list[str]") -> str:
    rows = [{"slot": 1, "name": "Body", "hex": "FFC83D", "roughness": 0.55, "metallic": 0, "emission": 0,
             "colorMap": "%s_%s.png" % (name, sheets[0]), "pixelated": True}]
    for i, sheet in enumerate(sheets[1:], start=2):
        rows.append({"slot": i, "name": "FacePlate" if sheet == "face" else sheet, "hex": "FFC83D", "roughness": 0.4,
                     "metallic": 0, "emission": 0, "colorMap": "%s_%s.png" % (name, sheet), "pixelated": True})
    rows.append({"slot": len(rows) + 1, "name": "Glow", "hex": "FFFFFF", "roughness": 0.55, "metallic": 0, "emission": 1.5})
    return json.dumps(rows)


class Tree:
    """A temporary repo slice: species and props under models/, sprites, tiles, the ids files and a data folder."""

    def __init__(self, root: pathlib.Path) -> None:
        self.root = root
        self.paths = ua.BlockyPaths(root / "models", root / "sprites", root / "tiles", root / "models/asset_ids.json",
                                    root / "models/image_ids.json", root / "icons_ids.json", root / "tiles/asset_ids.json",
                                    root / "Icons.luau", root / "data")
        (root / "models").mkdir()
        (root / "data").mkdir()

    def species(self, name: str, sheets: "tuple[str, ...]" = ("atlas", "face"), prop: bool = False,
                skip: str = "") -> None:
        folder = self.root / "models" / ("props/" + name if prop else name)
        write(folder / "materials.json", cell_rows(name, list(sheets)))
        for f in [name + ".glb"] + ["%s_%s.png" % (name, s) for s in sheets]:
            if f != skip:
                write(folder / f, PNG)

    def old_prop(self, name: str) -> None:
        folder = self.root / "models/props" / name
        write(folder / "materials.json", json.dumps([{"slot": 1, "name": "Rock", "hex": "8E8E8E", "roughness": 0.8,
                                                      "metallic": 0, "emission": 0}]))
        write(folder / (name + ".glb"), PNG)

    def sprite(self, key: str) -> None:
        write(self.root / "sprites" / (key + ".png"), PNG)

    def tile(self, key: str) -> None:
        write(self.root / "tiles" / (key + ".png"), PNG)

    def plan(self, ids: "dict | None" = None, only: "list[str] | None" = None, redo: bool = False):
        folders, sprites, tiles, problems = ua.discover_blocky(self.paths)
        books = {"model": {}, "image": {}, "sprite": {}, "tile": {}}
        books.update(ids or {})
        items, unknown = ua.plan_blocky(folders, sprites, tiles, books, self.paths, only, redo)
        return items, unknown, problems, folders


class TreeCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tree = Tree(pathlib.Path(tmp.name))


class DiscoverAndPlanTest(TreeCase):
    def test_nothing_present_plans_nothing(self) -> None:
        items, unknown, problems, folders = self.tree.plan()
        self.assertEqual((items, unknown, problems, folders), ([], [], [], {}))
        self.assertEqual(ua.plan_counts(items), "nothing found")

    def test_a_block_cell_folder_is_found_by_its_materials_not_by_a_list(self) -> None:
        self.tree.species("Mossbop")
        self.tree.species("Hut", sheets=("atlas",), prop=True)
        self.tree.old_prop("MeadowRock")                           # an old prop: no pixelated entry, not a block-cell folder
        _, _, problems, folders = self.tree.plan()
        self.assertEqual(problems, [])
        self.assertEqual(sorted(folders), ["Hut", "Mossbop"])
        self.assertTrue(folders["Hut"].prop)
        self.assertFalse(folders["Mossbop"].prop)
        self.assertEqual(sorted(folders["Mossbop"].sheets), ["atlas", "face"])

    def test_a_missing_file_is_a_problem_named_by_folder(self) -> None:
        self.tree.species("Radish", skip="Radish_face.png")
        _, _, problems, folders = self.tree.plan()
        self.assertEqual(folders, {})
        self.assertEqual(problems, ["Radish: missing Radish_face.png"])

    def test_order_counts_and_where_each_id_lands(self) -> None:
        self.tree.species("Mossbop")
        self.tree.species("Hut", sheets=("atlas",), prop=True)
        self.tree.sprite("PixelStar")
        self.tree.tile("MeadowGrass")
        write(self.tree.root / "data/Tiles.luau", "return {\n\tMeadowGrass = { id = 0, tiling = 4 },\n}\n")
        items, _, _, _ = self.tree.plan()
        self.assertEqual([(i.kind, i.key) for i in items],
                         [("model", "Hut"), ("model", "Mossbop"), ("atlas", "Hut/atlas"), ("atlas", "Mossbop/atlas"),
                          ("face", "Mossbop/face"), ("sprite", "PixelStar"), ("tile", "MeadowGrass")])
        self.assertTrue(all(i.todo for i in items))
        by = {i.key: i for i in items}
        self.assertIn("BLOCK_CELL.Mossbop.assetId", by["Mossbop"].lands)
        self.assertNotIn("BLOCK_CELL", by["Hut"].lands)            # props have no BLOCK_CELL row
        self.assertIn("BLOCK_CELL.Mossbop.cellMap", by["Mossbop/atlas"].lands)
        self.assertIn("Rigs.luau Mossbop.face.image", by["Mossbop/face"].lands)
        self.assertNotIn("BLOCK_CELL", by["Hut/atlas"].lands)
        self.assertIn("Icons.luau Particles.PixelStar", by["PixelStar"].lands)
        self.assertIn("Tiles.luau line 2", by["MeadowGrass"].lands)
        self.assertEqual(by["Mossbop"].ids_file, self.tree.paths.model_ids)
        self.assertEqual(by["Mossbop/face"].ids_file, self.tree.paths.image_ids)
        self.assertEqual(by["PixelStar"].ids_file, self.tree.paths.sprite_ids)
        self.assertEqual(by["MeadowGrass"].ids_file, self.tree.paths.tile_ids)
        self.assertEqual(ua.plan_counts(items), "2 models (0 done), 2 atlases (0 done), 1 face sheets (0 done), "
                                                "1 sprites (0 done), 1 tiles (0 done)")

    def test_an_old_blockout_id_is_replaced_and_a_block_cell_upload_is_done(self) -> None:
        self.tree.species("Mossbop")
        self.tree.species("Radish")
        ids = {"model": {"Mossbop": {"assetId": 111, "pendingUpload": {"uploaded": False}},
                         "Radish": {"assetId": 222, "blockCell": True}},
               "image": {"Radish/atlas": {"assetId": 5, "imageId": 6}}}
        items, _, _, _ = self.tree.plan(ids)
        by = {i.key: i for i in items}
        self.assertEqual((by["Mossbop"].todo, by["Mossbop"].replaces), (True, 111))
        self.assertEqual((by["Radish"].todo, by["Radish"].replaces), (False, None))
        self.assertFalse(by["Radish/atlas"].todo)
        self.assertTrue(by["Radish/face"].todo)
        redo = {i.key: i for i in self.tree.plan(ids, redo=True)[0]}
        self.assertTrue(all(i.todo for i in redo.values()))

    def test_an_old_prop_id_without_block_cell_mark_is_not_done(self) -> None:
        self.tree.species("Hut", sheets=("atlas",), prop=True)
        items, _, _, _ = self.tree.plan({"model": {"Hut": {"assetId": 9, "file": "x.glb"}}})
        self.assertEqual((items[0].todo, items[0].replaces), (True, 9))

    def test_only_takes_folders_sprites_and_tiles_and_names_the_unknown(self) -> None:
        self.tree.species("Mossbop")
        self.tree.species("Radish")
        self.tree.sprite("PixelStar")
        self.tree.tile("MeadowGrass")
        items, unknown, _, _ = self.tree.plan(only=["Radish", "PixelStar", "MeadowGrass", "Nope"])
        self.assertEqual([i.key for i in items], ["Radish", "Radish/atlas", "Radish/face", "PixelStar", "MeadowGrass"])
        self.assertEqual(unknown, ["Nope"])

    def test_sheet_names(self) -> None:
        self.assertEqual(ua.sheet_name("Mossbop", "Mossbop_atlas.png"), "atlas")
        self.assertEqual(ua.sheet_name("Mossbop", "shared_cells.png"), "shared_cells")
        self.assertEqual(ua.sheet_name("Hut", "Hut_.png"), "Hut_")

    def test_tile_rows_convention(self) -> None:
        write(self.tree.root / "data/A.luau", 'local T = {\n\tGrass = { id = 0, tiling = 4 },\n\t["Snow"] = { tiling = 2, id = 7 },\n}\n')
        write(self.tree.root / "data/B.luau", "return {\n\tSnow = { id = 0 },\n\tGrassy = { id = 0 },\n}\n")
        rows = ua.tile_rows(self.tree.root / "data", ["Grass", "Snow", "Ice"])
        self.assertEqual([(p.name, n) for p, n in rows["Grass"]], [("A.luau", 2)])
        self.assertEqual([(p.name, n) for p, n in rows["Snow"]], [("A.luau", 3), ("B.luau", 2)])
        self.assertEqual(rows["Ice"], [])
        self.assertIn("no data row yet", ua.tile_lands("Ice", rows["Ice"]))
        self.assertIn("2 data rows match, so none is filled", ua.tile_lands("Snow", rows["Snow"]))

    def test_particles_without_png(self) -> None:
        write(self.tree.paths.icons_luau, "local Icons: { [string]: number } = {\n\tShop = 5,\n}\n\n"
                                          "local Particles: { [string]: number } = {\n\tPixelStar = 0,\n\tShine = 0,\n"
                                          "\tWisp = 0,\n\tFlake = 12,\n}\n\nreturn {}\n")
        self.tree.sprite("PixelStar")
        with unittest.mock.patch.object(ua, "PARTICLES_DIR", self.tree.root / "particles"), \
                unittest.mock.patch.object(ua, "ICONS_DIR", self.tree.root / "icons"):
            write(self.tree.root / "particles/Wisp.png", PNG)
            self.assertEqual(ua.particles_without_png(self.tree.paths), ["Shine"])


class EntryTest(unittest.TestCase):
    item = ua.BlockyItem("model", "Mossbop", ua.REPO / "assets/models/Mossbop/Mossbop.glb", ua.DEFAULT_IDS_FILE, True, 111, "")

    def test_a_model_entry_replaces_the_blockout_and_drops_pending(self) -> None:
        out = ua.blocky_entry(self.item, 900, {"assetId": 111, "pendingUpload": {"uploaded": False}})
        self.assertEqual((out["assetId"], out["blockCell"], out["replacedAssetId"]), (900, True, 111))
        self.assertNotIn("pendingUpload", out)
        self.assertEqual(out["file"], "assets/models/Mossbop/Mossbop.glb")
        self.assertTrue(ua.is_blockcell_upload(out))

    def test_a_redo_keeps_the_blockout_it_first_replaced(self) -> None:
        out = ua.blocky_entry(self.item, 901, {"assetId": 900, "blockCell": True, "replacedAssetId": 111})
        self.assertEqual(out["replacedAssetId"], 111)

    def test_a_sheet_and_a_sprite_record_their_kind(self) -> None:
        sheet = self.item._replace(kind="face", key="Mossbop/face")
        sprite = self.item._replace(kind="sprite", key="PixelStar")
        self.assertEqual(ua.blocky_entry(sheet, 5, None)["kind"], "face")
        self.assertEqual(ua.blocky_entry(sprite, 5, None)["kind"], "particle")
        self.assertNotIn("blockCell", ua.blocky_entry(sheet, 5, None))

    def test_pending_or_unmarked_entries_are_not_block_cell_uploads(self) -> None:
        self.assertFalse(ua.is_blockcell_upload({"assetId": 5, "blockCell": True, "pendingUpload": {}}))
        self.assertFalse(ua.is_blockcell_upload({"assetId": 5}))
        self.assertFalse(ua.is_blockcell_upload({"assetId": 0, "blockCell": True}))
        self.assertFalse(ua.is_blockcell_upload(None))


INSTALLER = """-- header mentions the PASTE markers
-- BEGIN PASTE: output of `python3 tools/upload_assets.py --emit-luau`
local ASSET_IDS: { [string]: number } = {
\tMossbop = 111,
}
local MATERIALS: { [string]: { { string | number } } } = {
\tMossbop = { { "Body", "6BCB3F", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 } },
}
-- END PASTE
-- BEGIN BLOCK-CELL PASTE: output of export_models
local BLOCK_CELL = {}
-- END BLOCK-CELL PASTE
"""

NEW_EMIT = """local ASSET_IDS: { [string]: number } = {
\tMossbop = %d,
}
local MATERIALS: { [string]: { { string | number } } } = {
\tMossbop = { { "Body", "FFC83D", 0.55, 0, 0 }, { "FacePlate", "FFC83D", 0.4, 0, 0 } },
}"""


class FillTest(TreeCase):
    def test_installer_keeps_the_blockout_rows_until_the_block_cell_model_is_uploaded(self) -> None:
        pending = {"Mossbop": {"assetId": 111, "pendingUpload": {"uploaded": False}}}
        with unittest.mock.patch.object(ua, "emit_luau", return_value=NEW_EMIT % 111):
            body = ua.installer_paste_body(pending, INSTALLER, ["Mossbop"])
        self.assertIn('"EyeWhite"', body)
        self.assertNotIn('"FacePlate"', body)
        uploaded = {"Mossbop": {"assetId": 900, "blockCell": True}}
        with unittest.mock.patch.object(ua, "emit_luau", return_value=NEW_EMIT % 900):
            body = ua.installer_paste_body(uploaded, INSTALLER, ["Mossbop"])
        self.assertIn('"FacePlate"', body)
        self.assertIn("Mossbop = 900,", body)

    def test_replace_block_touches_only_its_markers(self) -> None:
        out = ua.replace_block(INSTALLER, ua.PASTE_BEGIN, ua.PASTE_END, "X = 1\n")
        self.assertIn("-- BEGIN PASTE: output", out)
        self.assertIn("-- BEGIN PASTE: output of `python3 tools/upload_assets.py --emit-luau`\nX = 1\n-- END PASTE\n", out)
        self.assertIn("local BLOCK_CELL = {}", out)
        out = ua.replace_block(INSTALLER, ua.BLOCK_CELL_BEGIN, ua.BLOCK_CELL_END, "local BLOCK_CELL = { A = 1 }")
        self.assertIn("-- BEGIN BLOCK-CELL PASTE: output of export_models\nlocal BLOCK_CELL = { A = 1 }\n-- END", out)
        self.assertIn('"EyeWhite"', out)
        with self.assertRaises(ValueError):
            ua.replace_block("no markers", ua.PASTE_BEGIN, ua.PASTE_END, "")

    def test_icons_fill_raises_ids_and_never_sets_one_back_to_zero(self) -> None:
        source = ("local Icons: { [string]: number } = {\n\tShop = 5,\n}\n\nlocal Particles: { [string]: number } = {\n"
                  "\tPixelStar = 0,\n\tFlake = 12,\n\tGlow = 0,\n}\n\nlocal Aliases: { [string]: string } = {\n"
                  "\tBoots = \"SpeedBoots\",\n}\n")
        ids = {"PixelStar": {"assetId": 70, "imageId": 71}, "Flake": {"assetId": 3}, "Glow": {"assetId": 8, "imageId": 9},
               "Shop": {"assetId": 4, "imageId": 5}}
        text, changed = ua.fill_icons_text(source, ids)
        self.assertEqual(changed, ["PixelStar", "Glow"])
        self.assertIn("\tPixelStar = 71,", text)
        self.assertIn("\tFlake = 12,", text)                       # no Image id in the file: kept, never 0
        self.assertIn("\tBoots = \"SpeedBoots\",", text)
        self.assertEqual(ua.fill_icons_text(text, ids), (text, []))
        self.assertEqual(ua.icons_luau_values(write(self.tree.paths.icons_luau, text))[1],
                         {"PixelStar": 71, "Flake": 12, "Glow": 9})

    def test_tile_fill_writes_the_one_matching_row_only(self) -> None:
        a = write(self.tree.root / "data/Tiles.luau", "return {\n\tGrass = { id = 0, tiling = 4 },\n\tSnow = { id = 0 },\n"
                                                      "\tIce = { id = 0 },\n}\n")
        write(self.tree.root / "data/Other.luau", "return {\n\tSnow = { id = 0 },\n}\n")
        ids = {"Grass": {"assetId": 1, "imageId": 41}, "Snow": {"assetId": 2, "imageId": 42}, "Ice": {"assetId": 3}}
        out = ua.fill_tile_rows(self.tree.root / "data", ids, ["Grass", "Snow", "Ice"])
        self.assertEqual(list(out), [a])
        text, keys = out[a]
        self.assertEqual(keys, ["Grass"])
        self.assertIn("\tGrass = { id = 41, tiling = 4 },", text)
        self.assertIn("\tSnow = { id = 0 },", text)                # two rows match: left alone
        self.assertIn("\tIce = { id = 0 },", text)                 # not resolved: left alone
        a.write_text(text, encoding="utf-8")
        self.assertEqual(ua.fill_tile_rows(self.tree.root / "data", ids, ["Grass"]), {})


class GeneratorTest(TreeCase):
    def test_rigs_reads_the_resolved_face_ids_only(self) -> None:
        path = write(self.tree.root / "image_ids.json", json.dumps({
            "Mossbop/face": {"assetId": 1, "imageId": 77}, "Mossbop/atlas": {"assetId": 2, "imageId": 78},
            "Radish/face": {"assetId": 3}}))
        self.assertEqual(RG.uploaded_face_images(path), {"Mossbop": 77})
        self.assertEqual(RG.uploaded_face_images(self.tree.root / "none.json"), {})

    def test_block_cell_emit_takes_the_new_model_and_sheet_ids(self) -> None:
        self.tree.species("Mossbop")
        self.tree.species("Radish")
        ids = write(self.tree.root / "asset_ids.json", json.dumps({
            "Mossbop": {"assetId": 900, "blockCell": True},
            "Radish": {"assetId": 222, "pendingUpload": {"uploaded": False}}}))
        images = write(self.tree.root / "image_ids.json", json.dumps({
            "Mossbop/atlas": {"assetId": 1, "imageId": 31}, "Mossbop/face": {"assetId": 2, "imageId": 32},
            "Radish/atlas": {"assetId": 3}}))
        text = X.emit_luau(self.tree.root / "models", ids, images)
        self.assertIn("\tMossbop = {\n\t\tassetId = 900, cellMap = 31, faceMap = 32,", text)
        self.assertIn("\tRadish = {\n\t\tassetId = 0, cellMap = 0, faceMap = 0,", text)


def run_main(argv: "list[str]", env: "dict[str, str]") -> "tuple[int, str, str]":
    return T.run_main(argv, env)


NO_KEY = {"ROBLOX_OPEN_CLOUD_KEY": "", "ROBLOX_API_KEY": ""}


class RepoTest(unittest.TestCase):
    """The real repo: the dry run plans with no key, the real run refuses with no key, and the fill is a no-op."""

    def test_dry_run_plans_without_a_key(self) -> None:
        code, out, err = run_main(["--blocky", "--dry-run"], NO_KEY)
        self.assertEqual(code, 0, out + err)
        self.assertIn("blocky dry run:", out)
        self.assertIn("block-cell folders:", out)

    def test_the_real_run_refuses_without_a_key_and_writes_nothing(self) -> None:
        _, plan, _ = run_main(["--blocky", "--dry-run"], NO_KEY)
        if " 0 upload call(s)" in plan:   # after the upload the real run would resolve and fill, not refuse
            self.skipTest("everything is uploaded in this checkout")
        files = [ua.DEFAULT_IDS_FILE, ua.BLOCKY_IMAGE_IDS_FILE, ua.IMAGE_IDS_FILE, ua.BLOCKY_TILE_IDS_FILE]
        before = [f.read_bytes() if f.exists() else None for f in files]
        code, out, err = run_main(["--blocky"], NO_KEY)
        self.assertEqual(code, 2)
        self.assertIn("is not set, so nothing was uploaded", err)
        self.assertEqual([f.read_bytes() if f.exists() else None for f in files], before)

    def test_blocky_stands_alone(self) -> None:
        code, _, err = run_main(["--blocky", "--images"], NO_KEY)
        self.assertEqual(code, 2)
        self.assertIn("stand alone", err)
        code, _, err = run_main(["--fill-blocky", "--redo"], NO_KEY)
        self.assertEqual(code, 2)

    def test_the_fill_has_nothing_to_change_in_a_clean_checkout(self) -> None:
        code, out, err = run_main(["--fill-blocky", "--dry-run"], NO_KEY)
        self.assertEqual(code, 0, out + err)
        self.assertIn("every file is up to date", out)


class BlockyFlowTest(T.MockServerCase):
    """run_blocky against the local mock: uploads, records, resolves; a second run does nothing."""

    def setUp(self) -> None:
        super().setUp()
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tree = Tree(pathlib.Path(tmp.name))
        self.tree.species("Mossbop")
        self.tree.sprite("PixelStar")
        self.tree.tile("MeadowGrass")
        write(self.tree.paths.icons_luau, "local Particles: { [string]: number } = {\n\tPixelStar = 0,\n}\n")
        ua.save_ids(self.tree.paths.model_ids, {"Mossbop": {"assetId": 111, "pendingUpload": {"uploaded": False}}})
        self.fills: "list[bool]" = []
        self.env = {"ROBLOX_OPEN_CLOUD_KEY": "test-key-not-real", "ROBLOX_CREATOR_USER_ID": "1",
                    "ROBLOX_CREATOR_GROUP_ID": ""}

    def run_blocky(self) -> "tuple[int, str]":
        out = io.StringIO()
        with unittest.mock.patch.dict(os.environ, self.env), contextlib.redirect_stdout(out):
            code = ua.run_blocky(self.tree.paths, None, False, False, 0, fill=lambda dry: self.fills.append(dry) or 0)
        return code, out.getvalue()

    def test_uploads_records_resolves_and_fills_then_does_nothing(self) -> None:
        code, out = self.run_blocky()
        self.assertEqual(code, 0, out)
        models = ua.load_ids(self.tree.paths.model_ids)
        self.assertEqual((models["Mossbop"]["assetId"], models["Mossbop"]["replacedAssetId"]), (555, 111))
        self.assertNotIn("pendingUpload", models["Mossbop"])
        images = ua.load_ids(self.tree.paths.image_ids)
        self.assertEqual(sorted(images), ["Mossbop/atlas", "Mossbop/face"])
        self.assertEqual(images["Mossbop/face"]["imageId"], T.SHOP_IMAGE)
        self.assertEqual(ua.load_ids(self.tree.paths.sprite_ids)["PixelStar"]["imageId"], T.SHOP_IMAGE)
        self.assertEqual(ua.load_ids(self.tree.paths.tile_ids)["MeadowGrass"]["kind"], "tile")
        self.assertEqual(self.fills, [False])
        posts = [h for m, _, h in T._MockRoblox.log if m == "POST"]
        self.assertEqual(len(posts), 5)                            # model, atlas, face, sprite, tile
        self.assertNotIn("test-key-not-real", out)
        T._MockRoblox.log.clear()
        code, out = self.run_blocky()
        self.assertEqual(code, 0, out)
        self.assertIn("nothing to upload", out)
        self.assertEqual(T._MockRoblox.log, [])

    def test_unresolved_image_ids_exit_3_after_the_fill(self) -> None:
        for path in ("/v1/asset/?id=555",):
            T._MockRoblox.delivery_failures[path] = [403] * 40
        code, out = self.run_blocky()
        self.assertEqual(code, 3, out)
        self.assertEqual(self.fills, [False])
        self.assertIn("Studio route", out)

    def test_no_key_uploads_nothing(self) -> None:
        self.env = dict(NO_KEY)
        with self.assertRaises(SystemExit) as ctx, contextlib.redirect_stderr(io.StringIO()):
            self.run_blocky()
        self.assertEqual(ctx.exception.code, 2)
        self.assertEqual(T._MockRoblox.log, [])
        self.assertEqual(self.fills, [])


if __name__ == "__main__":
    unittest.main()
