"""Tests for the face moods of tools/blender/species_sculpt.py (the temperament ladder), with no Blender.

Standard library only. The script imports `bpy` at the top, so it is read as source: the MOODS and DEFAULTS tables are parsed with `ast` (which
also proves a preset is literals only, every number named), and the `face` dict of each SPECIES entry is read the same way. Run:
  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
What is checked: the four presets carry the same named keys as DEFAULTS["face"]; they climb the ladder in the right direction (a thicker brow,
a narrower eye, a wider socket, never a smaller eye from fierce to spectacular); `cute` is the pass 2 face; every species' mood sits inside the
band its tier allows (docs/vault/01-game-design/Roster-Redesign.md, section 1); and the Temperament column of section 2 says what SPECIES says.
"""
from __future__ import annotations

import ast
import pathlib
import re
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SCULPT = ROOT / "tools/blender/species_sculpt.py"
SPECIES_LUAU = ROOT / "src/shared/data/Species.luau"
ROSTER_NOTE = ROOT / "docs/vault/01-game-design/Roster-Redesign.md"

LADDER = ("cute", "cool", "fierce", "spectacular")
# the temperaments each tier may have (Roster-Redesign.md section 1): the Rare band is mixed, the Epic is cool at the least
ALLOWED = {
    "Common": {"cute"},
    "Uncommon": {"cute"},
    "Rare": {"cute", "cool", "fierce"},
    "Epic": {"cool", "fierce", "spectacular"},
    "Legendary": {"fierce", "spectacular"},
    "Cosmic": {"spectacular"},
    "Secret": {"spectacular"},
}


def _module_assign(name: str):
    tree = ast.parse(SCULPT.read_text())
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in node.targets):
            return node.value
    raise AssertionError("no top-level %s in species_sculpt.py" % name)


def _dict_get(node: ast.Dict, key: str):
    for k, v in zip(node.keys, node.values):
        if isinstance(k, ast.Constant) and k.value == key:
            return v
    return None


def moods():
    """MOODS as plain data: ast.literal_eval fails on anything but literals, which is the test that a preset holds no logic."""
    return ast.literal_eval(_module_assign("MOODS"))


def default_face():
    face = _dict_get(_module_assign("DEFAULTS"), "face")
    return {k.value: v for k, v in zip(face.keys, face.values)}


def species_moods():
    """{species id: mood name} for every SPECIES entry that names one in its `face` dict."""
    out = {}
    table = _module_assign("SPECIES")
    for k, v in zip(table.keys, table.values):
        if not isinstance(v, ast.Dict):
            continue
        face = _dict_get(v, "face")
        mood = _dict_get(face, "mood") if isinstance(face, ast.Dict) else None
        if isinstance(mood, ast.Constant):
            out[k.value] = mood.value
    return out


def tiers():
    text = SPECIES_LUAU.read_text()
    return dict(re.findall(r'\{ id = "(\w+)".*?tier = "(\w+)"', text))


def temperaments_in_note():
    """{species id: temperament} from the Temperament column of the section 2 tables of Roster-Redesign.md."""
    out = {}
    cols = None
    in_section = False
    for line in ROSTER_NOTE.read_text().splitlines():
        if line.startswith("## "):
            in_section = line.startswith("## 2.")
            cols = None
            continue
        if not in_section or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells[0] == "Id":
            cols = cells
        elif cols and "Temperament" in cols and re.fullmatch(r"[A-Z]\w+", cells[0]):
            out[cells[0]] = re.match(r"\w+", cells[cols.index("Temperament")]).group(0).lower()
    return out


class MoodTable(unittest.TestCase):
    def test_the_ladder_is_there_and_literal(self):
        self.assertEqual(tuple(moods()), LADDER)

    def test_each_preset_names_every_number(self):
        keys = {tuple(sorted(m["face"])) for m in moods().values()}
        self.assertEqual(len(keys), 1, "the four presets carry different keys")
        for name, m in moods().items():
            with self.subTest(name):
                self.assertEqual(sorted(m["recipe"]), ["lid_min", "mouth_o", "tilt_max", "tilt_min"])
                for k in m["face"]:
                    self.assertIn(k, default_face(), "MOODS[%r] sets %r, which DEFAULTS['face'] does not have" % (name, k))

    def test_the_defaults_of_the_mood_keys_change_nothing(self):
        d = default_face()
        for k, want in (("mood", None), ("brow_thick", 1.0), ("brow_long", 1.0), ("eye_wide", 1.0), ("eye_squash", 1.0), ("eye_slant", 0.0),
                        ("pupil_scale", 1.0), ("mouth_flat", 1.0), ("mouth_roll", 0.0), ("mouth_shift", 0.0), ("teeth", False),
                        ("tooth_scale", 1.0), ("tooth_out", 0.0), ("crest_scale", 1.0)):
            with self.subTest(k):
                self.assertEqual(ast.literal_eval(d[k]), want)

    def test_cute_is_the_pass_2_face(self):
        cute = moods()["cute"]["face"]
        self.assertEqual((cute["lid_grow"], cute["eye_boost"], cute["mouth_scale"]), (0.5, 1.35, 1.9))
        self.assertEqual((cute["eye_squash"], cute["eye_wide"], cute["brow_thick"]), (1.0, 1.0, 1.0))
        self.assertFalse(cute["teeth"])
        self.assertEqual(moods()["cute"]["recipe"], {"tilt_min": None, "tilt_max": None, "lid_min": 0.0, "mouth_o": None})

    def test_a_cool_brow_is_slight_and_a_fierce_one_is_not(self):
        cool, fierce = moods()["cool"]["recipe"], moods()["fierce"]["recipe"]
        self.assertLess(cool["tilt_max"], fierce["tilt_min"])
        self.assertLessEqual(cool["tilt_min"], cool["tilt_max"])
        self.assertIsNone(fierce["tilt_max"])

    def test_the_brow_gets_heavier_and_the_eye_narrower_up_the_ladder(self):
        m = [moods()[n]["face"] for n in LADDER]
        for a, b in zip(m, m[1:]):
            self.assertLessEqual(a["lid_grow"], b["lid_grow"])
            self.assertLessEqual(a["brow_thick"], b["brow_thick"])
            self.assertLessEqual(a["eye_slant"], b["eye_slant"])
        for a, b in zip(m[:3], m[1:3]):  # cute, cool, fierce: each eye is no taller than the one below (a spectacular eye is not narrower than a fierce one)
            self.assertGreaterEqual(a["eye_squash"], b["eye_squash"])
            self.assertGreaterEqual(a["socket_reach"][2], b["socket_reach"][2])
        for n in ("cool", "fierce", "spectacular"):
            f = moods()[n]["face"]
            self.assertLess(f["socket_reach"][2], f["socket_reach"][0], "%s: the socket must be wider than tall" % n)
            self.assertLess(f["eye_squash"], 1.0, "%s: the eye is narrowed" % n)
            self.assertGreaterEqual(f["lid_grow"], 0.7)
        self.assertGreaterEqual(moods()["fierce"]["face"]["lid_grow"], 0.9)
        self.assertLessEqual(moods()["fierce"]["face"]["lid_grow"], 1.0)

    def test_a_spectacular_eye_is_never_smaller_than_a_fierce_one(self):
        def area(f):
            return f["eye_boost"] * f["eye_wide"] * f["eye_squash"] * f["eye_boost"]
        fierce, spec = moods()["fierce"]["face"], moods()["spectacular"]["face"]
        self.assertGreaterEqual(spec["eye_boost"], fierce["eye_boost"])
        self.assertGreaterEqual(spec["eye_wide"], fierce["eye_wide"])
        self.assertGreaterEqual(spec["eye_squash"], fierce["eye_squash"])
        self.assertGreaterEqual(area(spec), area(fierce))

    def test_eyes_stay_big_the_faces_stay_ours(self):
        # the pass 2 eye is 1.35 times the recipe's; narrowed, the eye's height stays at 0.7 of that or more, and none is below 1.1 times
        for n, m in moods().items():
            f = m["face"]
            with self.subTest(n):
                self.assertGreaterEqual(f["eye_boost"], 1.1)
                self.assertGreaterEqual(f["eye_boost"] * f["eye_squash"], 0.8)
                self.assertGreaterEqual(f["pupil_scale"], 0.8)

    def test_only_the_spectacular_grows_the_crest_and_only_fierce_up_has_teeth(self):
        for n, m in moods().items():
            with self.subTest(n):
                self.assertEqual(m["face"]["crest_scale"] > 1.0, n == "spectacular")
                self.assertEqual(m["face"]["teeth"], n in ("fierce", "spectacular"))
        self.assertGreater(moods()["spectacular"]["face"]["crest_scale"], 1.0)


class MoodsPerSpecies(unittest.TestCase):
    def test_every_named_mood_exists_and_belongs_to_a_species(self):
        t = tiers()
        for sid, mood in species_moods().items():
            with self.subTest(sid):
                self.assertIn(mood, LADDER)
                self.assertIn(sid, t)

    def test_each_mood_sits_inside_its_tiers_band(self):
        t, sm = tiers(), species_moods()
        for sid, tier in t.items():
            with self.subTest(sid):
                self.assertIn(sm.get(sid, "cute"), ALLOWED[tier], "%s (%s) is %s" % (sid, tier, sm.get(sid, "cute")))

    def test_most_of_the_rarer_species_are_fierce_or_spectacular(self):
        t, sm = tiers(), species_moods()
        rarer = [s for s, tier in t.items() if tier in ("Epic", "Legendary", "Cosmic", "Secret")]
        strong = [s for s in rarer if sm.get(s) in ("fierce", "spectacular")]
        self.assertGreater(len(strong) * 2, len(rarer), "%d of %d" % (len(strong), len(rarer)))

    def test_a_common_or_uncommon_is_never_given_a_hard_face(self):
        t, sm = tiers(), species_moods()
        for sid, tier in t.items():
            if tier in ("Common", "Uncommon"):
                self.assertIn(sm.get(sid), (None, "cute"), sid)

    def test_the_vault_note_says_what_the_sculpt_does(self):
        t, sm, note = tiers(), species_moods(), temperaments_in_note()
        self.assertEqual(sorted(note), sorted(t), "Roster-Redesign.md section 2 needs a Temperament cell for every species")
        for sid in t:
            with self.subTest(sid):
                self.assertEqual(note[sid], sm.get(sid, "cute"))


if __name__ == "__main__":
    unittest.main()
