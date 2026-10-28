#!/usr/bin/env python3
"""The character bar across World 2's Rare-and-up aliens (Decisions B54, B55, B56): the plans for Reindazzle, Shellberg, Capybubble, Shimmerlynx,
Frostfang and Skaddle, on the machinery of tools/blocky/kits.py and tools/blocky/pilots.py.

Same contract as pilots.py: each note keeps its body by hand and one generated region of its parts block, between `# pilot bar: begin` and
`# pilot bar: end`; this tool rewrites that region and the note's `bar_*` frontmatter from the plans below.

  python3 -I tools/blocky/bar_w2.py             # rewrite the region and the bar_* keys of every World 2 bar note
  python3 -I tools/blocky/bar_w2.py --check     # exit 1 when a note is out of date (tools/tests/test_bar_w2.py runs it)

Mass clarity (Blocky-Style 10, rule 8): on Frostbyte's white snow the body is a clear step darker than the ground, the kit and trim a step lighter or
darker than the body, the backdrop a third value with a dark outline, and the satellites one lit colour that is not the body's; fewer, bigger,
clearer. Rare-grade pieces are the Epic kit pieces drawn at scale 2 (their sixteenth-stud cells become eighth-stud cells), on the 0.125 grid.

Standard library only.
"""
from __future__ import annotations

import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import kits as K  # noqa: E402
import pilots as P  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
_box = K._box


def own(name, what, build, tier_from="Rare"):
    """A satellite piece of one alien's own theme (not in the world kit: `bar_pieces` never names it)."""
    return K.Piece(name, "own", what, ("orbit",), build, tier_from)


def arc(pieces, name, centre, radius, y, angles, moves, pivot, g=0.125, lift=0.0, tilt=0.0, drops=None, scales=None):
    """Pieces strung on part of a circle (kits.orbit strings them on all of it): `angles` in degrees, 0 the front (-z), 90 the creature's left
    (-x seen from behind, +x here: x = r sin a), 180 the back. Each flat piece faces the viewer (the back ones face back). The roster bar leaves the
    face's arc empty (nothing crosses the face), so the set stands at the sides and behind, the back of the ring higher by `lift`."""
    cx, cz = centre
    out = []
    for i, (pc, a) in enumerate(zip(pieces, angles)):
        a = math.radians(a)
        px, pz = cx + radius * math.sin(a), cz - radius * math.cos(a)
        py = y + tilt * math.sin(a) - lift * math.cos(a) - (drops[i] if drops else 0.0)
        normal = "-z" if math.cos(a) > -0.5 else "+z"
        out += K.place(pc, "%s%d" % (name, i), (K.snap(px, g / 2), K.snap(py, g / 2), K.snap(pz, g / 2)), normal, g, moves=moves, pivot=pivot,
                       scale=(scales[i] if scales else 1.0))
    return out


# ------------------------------------------------------------------------------------------------ Reindazzle (Blinkar), Rare
def _lantern(g, lite=False):
    # a sleigh lantern three quarters of a stud wide and seven eighths tall (round 2: round 1's was a red cube with a lid and read as an apple, and the
    # first redraw's dark posts made a dark clump): a handle, a wide dark roof, a lit red window half a stud across and half a stud tall, a dark base;
    # it echoes the lantern nose, and from 16 studs the lit window is the mass
    z0, z1 = -0.125, 0.125
    return [_box(-0.125, 0.125, 0.75, 0.875, z0, z1, "BodyDark", None),
            _box(-0.375, 0.375, 0.625, 0.75, z0, z1, "BodyDark", None),
            _box(-0.25, 0.25, 0.125, 0.625, z0, z1, "Glow", "glow"),
            _box(-0.25, 0.25, 0, 0.125, z0, z1, "BodyDark", None)]


def reindazzle():
    """Rare, Frostbyte: a lantern keeper. Silver snowflake studs on the shoulders, a silver harness girth, a little ice tiara between the antlers
    (3 kit pieces and the stance), the head cocked and one hoof lifted (rest poses), and six red sleigh lanterns in two garlands up its sides (one lit colour, the
    nose's, in a dark frame that reads on snow)."""
    Pz = K.PIECES
    p = P.Plan("Frostbyte", "a prance: the head cocked 10 degrees as if listening to its antlers chime, the right foreleg lifted 50 degrees mid-step, two garlands of three red lanterns rising up its sides")
    p.wear("# the Frostbyte kit: a silver snowflake stud (a plus of eighth-stud bars on a lit heart) on each shoulder, where the old flank flake was",
           K.place(Pz["snowflake_stud"], "Flake", (0.75, 1.125, 0.375), "+x", mirror=True, lite=True, scale=2), ["snowflake_stud"] * 2)
    girth = [K.part("GirthT", "Trim", (1.75, 0.125, 0.25), (0, 1.6875, -0.125), material="metal"),
             K.part("GirthS", "Trim", (0.125, 1.0, 0.25), (0.8125, 1.125, -0.125), material="metal", mirror=True)]
    p.wear("# the harness girth: a silver strap a quarter stud wide and an eighth proud over its back and down both sides behind the front legs", girth, ["silver_band"])
    p.wear("# a little ice tiara between the antler posts (a lip of pale ice with two icicle teeth standing up; it rides the head)",
           K.place(Pz["frost_rim"], "Tiara", (0, 2.5, -1.0), "+y", scale=2, pose="head"), ["frost_rim"])
    sats = arc([own("lantern", "a red sleigh lantern", _lantern)] * 6, "Sat", (0, 0.25), 2.6, 0.95, [55, 90, 125, 235, 270, 305], "lanterns", [0, 1.3, 0.25], g=0.25,
               lift=0.5)
    p.regions.append(("# the satellite set (`lanterns`, two garlands of three rising up the sides and behind the shoulders, nothing in front of the face or over the head): six sleigh lanterns, a dark frame round a lit red heart, three quarters of a stud wide, facing the viewer", sats))
    p.satellites, p.orbit = 6, "lanterns"
    return p


# ------------------------------------------------------------------------------------------------ Shellberg (Floe), Rare
def _pennant(flip):
    def build(g, lite=False):
        # an explorer's flag seven eighths of a stud across and seven eighths tall (the pennant on its own summit, planted six times round it): a dark
        # pole on a dark foot, a lit cyan pennant between a dark top edge and a dark hem so the light has an outline on snow, and a one-step swallow-tail
        # point; the same from both sides
        z0, z1 = -0.125, 0.125
        s = -1 if flip else 1

        def bx(x0, x1, y0, y1, slot, mat=None):
            a, b = sorted((s * x0, s * x1))
            return _box(a, b, y0, y1, z0, z1, slot, mat)
        return [bx(-0.125, 0, 0.125, 0.875, "BodyDark"), bx(-0.125, 0.125, 0, 0.125, "BodyDark"),
                bx(0, 0.5, 0.75, 0.875, "BodyDark"), bx(0, 0.5, 0.5, 0.75, "Glow", "glow"), bx(0.5, 0.75, 0.5, 0.625, "Glow", "glow"),
                bx(0, 0.5, 0.375, 0.5, "BodyDark")]
    return build


def shellberg():
    """Rare, Frostbyte: an explorer on a summit. Silver snowflake studs on the dark flanks of its berg and a silver skirt round the berg's foot
    (3 kit pieces and the stance), the head stretched out, tipped and turned to look at its own flag (a rest pose), and six cyan pennants on dark
    poles in two rows up its sides (the flag it planted on its own summit, six times over; one lit colour, the sea line's)."""
    Pz = K.PIECES
    p = P.Plan("Frostbyte", "a proud lookout: the neck stretched, the head tipped up 10 degrees and turned 18 to look at its own flag, six cyan pennants on dark poles standing out to its sides")
    p.wear("# the Frostbyte kit: a silver snowflake stud (a plus of eighth-stud bars on a lit heart) on each dark flank of the berg",
           K.place(Pz["snowflake_stud"], "Flake", (1.25, 0.875, 0.625), "+x", mirror=True, lite=True, scale=2), ["snowflake_stud"] * 2)
    p.wear("# a silver skirt: a band a quarter stud tall and an eighth proud round the foot of the berg, over the flippers",
           K.band("Skirt", (0, 0.5, 0.625), (2.5, 2.75), t=0.125, h=0.25, slot="Trim", material="metal"), ["silver_band"])
    fr = own("pennant_r", "a cyan pennant on a dark pole, flying to its right", _pennant(False))
    fl = own("pennant_l", "a cyan pennant on a dark pole, flying to its left", _pennant(True))
    sats = arc([fr, fr, fr, fl, fl, fl], "Sat", (0, 0.5), 2.7, 0.95, [50, 90, 130, 230, 270, 310], "flags", [0, 1.3, 0.5], g=0.25, lift=0.4)
    p.regions.append(("# the satellite set (`flags`, two rows of three standing out to its sides, the back higher, nothing in front of the face): six pennants, a lit cyan flag in a dark frame on a dark pole and foot, seven eighths of a stud across, facing the viewer", sats))
    p.satellites, p.orbit = 6, "flags"
    return p


# ------------------------------------------------------------------------------------------------ Capybubble (Snorzo), Rare
def _bubble(big):
    def build(g, lite=False):
        # a soap bubble in pixel art, the same from both sides: a dark umber outline round a lit aqua rim (half a stud across, or three quarters for the
        # big one, which has a hollow middle), so the lit ring has an edge against snow
        z0, z1 = -0.125, 0.125
        if not big:
            return [_box(-0.125, 0.125, 0.375, 0.5, z0, z1, "BodyDark", None), _box(-0.125, 0.125, 0, 0.125, z0, z1, "BodyDark", None),
                    _box(-0.25, -0.125, 0.125, 0.375, z0, z1, "BodyDark", None), _box(0.125, 0.25, 0.125, 0.375, z0, z1, "BodyDark", None),
                    _box(-0.125, 0.125, 0.125, 0.375, z0, z1, "Glow", "glow")]
        return [_box(-0.25, 0.25, 0.625, 0.75, z0, z1, "BodyDark", None), _box(-0.25, 0.25, 0, 0.125, z0, z1, "BodyDark", None),
                _box(-0.375, -0.25, 0.125, 0.625, z0, z1, "BodyDark", None), _box(0.25, 0.375, 0.125, 0.625, z0, z1, "BodyDark", None),
                _box(-0.25, 0.25, 0.5, 0.625, z0, z1, "Glow", "glow"), _box(-0.25, 0.25, 0.125, 0.25, z0, z1, "Glow", "glow"),
                _box(-0.25, -0.125, 0.25, 0.5, z0, z1, "Glow", "glow"), _box(0.125, 0.25, 0.25, 0.5, z0, z1, "Glow", "glow")]
    return build


def capybubble():
    """Rare, Frostbyte: the bath-time capybara. A silver bathrobe belt round its barrel and silver snowflake studs on its flanks (3 kit pieces and the
    stance), the head nodding and rolled as it dozes, the tangerine tipping with it (a rest pose), and a stream of six outlined aqua bubbles curling up
    its sides and over its back, small ones low and big ones high (the snores it blows, grown; one lit colour, the aqua of its eyes)."""
    Pz = K.PIECES
    p = P.Plan("Frostbyte", "a doze: the head nodding 10 degrees and rolled 8, the tangerine tipped with it, a stream of six outlined bubbles curling up its right side, over its back and down its left")
    p.wear("# the Frostbyte kit: a silver snowflake stud (a plus of eighth-stud bars on a lit heart) on each flank, above the belt, where the old bubble-ring stamp was",
           K.place(Pz["snowflake_stud"], "Flake", (1.0, 1.375, 1.0), "+x", mirror=True, lite=True, scale=2, slots={"Trim": "Accessory"}), ["snowflake_stud"] * 2)
    p.wear("# a silver bathrobe belt: a band a quarter stud tall and an eighth proud round the barrel (the head hides its front)",
           K.band("Belt", (0, 0.875, 0.875), (2, 2.25), t=0.125, h=0.25, slot="Accessory", material="metal", faces=("+x", "-x", "+z")), ["silver_band"])
    small, big = own("bubble_s", "a half-stud soap bubble: a lit aqua heart in a dark umber outline", _bubble(False)), own("bubble_b", "a three-quarter-stud soap bubble: a lit aqua ring in a dark umber outline", _bubble(True))
    heights = [0.5, 0.875, 1.25, 1.625, 2.0, 2.5]
    sats = arc([small, small, big, big, big, big], "Sat", (0, 0.4), 2.6, 0.0, [50, 95, 140, 220, 265, 310], "ring", [0, 1.3, 0.4], g=0.25, drops=[-h for h in heights])
    p.regions.append(("# the satellite set (`ring`, one stream climbing from low on its right round the back to high on its left, nothing in front of the face): two half-stud bubbles and four three-quarter ones, each a lit aqua rim in a dark outline, facing the viewer", sats))
    p.satellites, p.orbit = 6, "ring"
    return p


# ------------------------------------------------------------------------------------------------ Shimmerlynx (Aurelyx), Epic
def _star(g, lite=False):
    # a four-point star three quarters of a stud across (the shape of the star in its eyes), the same from both sides: a lit cross (a thin upright bar,
    # a thin crossbar and a fat middle, an eighth proud) over a dark indigo outline a sixteenth wider all round, so the light has an edge on snow
    lit, dark = 0.125, 0.0625
    return [_box(-0.125, 0.125, 0, 0.875, -dark, dark, "BodyDark", None), _box(-0.4375, 0.4375, 0.3125, 0.5625, -dark, dark, "BodyDark", None),
            _box(-0.25, 0.25, 0.1875, 0.6875, -dark, dark, "BodyDark", None),
            _box(-0.0625, 0.0625, 0.0625, 0.8125, -lit, lit, "Glow", "glow"), _box(-0.375, 0.375, 0.375, 0.5, -lit, lit, "Glow", "glow"),
            _box(-0.1875, 0.1875, 0.25, 0.625, -lit, lit, "Glow", "glow")]


def shimmerlynx():
    """Epic, Frostbyte: the night cat. Six kit pieces (silver snowflake studs on the haunches, silver cuffs on the front legs, dark ice shards standing on
    the haunches), the head turned and rolled and the right paw reaching out to you (rest poses), and a ring of six outlined violet stars (the star in its
    eyes, grown: one lit colour, the crest's). The body is a mid lilac-grey (L* 63) so it stands off the snow, with a cream chest and paws, dark indigo
    streaks and whiskers and a pale silver for the metal."""
    Pz = K.PIECES
    p = P.Plan("Frostbyte", "a cat that has decided you may approach: the head turned 14 degrees and rolled 6, the right paw reaching toward you 55 degrees, the tail up, a ring of six outlined violet stars round it")
    p.wear("# the Frostbyte kit: a silver snowflake stud (a plus of sixteenth-stud bars with a lit heart) on each haunch, where the stepped emblem was",
           K.place(Pz["snowflake_stud"], "Flake", (1.25, 0.75, 0.25), "+x", mirror=True, lite=True, scale=2), ["snowflake_stud"] * 2)
    cuffs = K.band("CuffL", (-0.5, 0.5, -0.8125), (0.375, 0.375), t=0.125, h=0.25, slot="Trim", material="metal")
    cuffs += K.band("CuffR", (0.5, 0.5, -0.8125), (0.375, 0.375), t=0.125, h=0.25, slot="Trim", material="metal", pose="reach")
    p.wear("# silver cuffs: a band a quarter stud tall and an eighth proud round each front leg above the paw (the right one reaches with its leg)", cuffs, ["silver_band"] * 2)
    p.wear("# dark ice shards, half again as big, standing on the haunches' tops like spines (the dark indigo, so they stand off the snow)",
           K.place(Pz["ice_shard"], "Shard", (0.75, 1.375, 0.5), "+y", mirror=True, scale=1.5, slots={"Accessory": "BodyDark"}), ["ice_shard"] * 2)
    star = own("aurora_star", "a three-quarter-stud four-point star: a lit cross in a dark indigo outline (a satellite)", _star, "Epic")
    sats = arc([star] * 6, "Sat", (0, 0.1), 2.5, 1.2, [45, 85, 125, 235, 275, 315], "sparks", [0, 1.8, 0.1], g=0.125, lift=0.7)
    p.regions.append(("# the satellite set (`sparks`, two rows of three standing out to its sides, the back higher, nothing in front of the face): six four-point stars, a lit violet cross in a dark outline, three quarters of a stud across, facing the viewer", sats))
    p.satellites, p.orbit = 6, "sparks"
    return p


# ------------------------------------------------------------------------------------------------ Frostfang (Sabrek), Epic
def _flake_big(g, lite=False):
    # a snowflake seven eighths of a stud across, the same from both sides (the flake in its eyes, on its flanks and over its head, grown to fly round it): a
    # lit cyan plus of bars an eighth thick and four diagonal dots, an eighth proud, over a dark navy plus and dots a sixteenth wider all round
    lit, dark = 0.125, 0.0625
    out = [_box(-0.4375, 0.4375, -0.125, 0.125, -dark, dark, "BodyDark", None), _box(-0.125, 0.125, -0.4375, 0.4375, -dark, dark, "BodyDark", None)]
    out += [_box(x - 0.125, x + 0.125, y - 0.125, y + 0.125, -dark, dark, "BodyDark", None) for x in (-0.25, 0.25) for y in (-0.25, 0.25)]
    out += [_box(-0.375, 0.375, -0.0625, 0.0625, -lit, lit, "Glow", "glow"), _box(-0.0625, 0.0625, -0.375, 0.375, -lit, lit, "Glow", "glow")]
    out += [_box(x - 0.0625, x + 0.0625, y - 0.0625, y + 0.0625, -lit, lit, "Glow", "glow") for x in (-0.25, 0.25) for y in (-0.25, 0.25)]
    return out


def frostfang():
    """Epic, Frostbyte: the sneezing cub in its play bow. Six kit pieces (silver cuffs a quarter stud tall on all four legs, silver snowflake studs on the
    flanks), the head up and turned to look at you and the right paw batting (rest poses on top of the bow it already holds), and a flurry of six
    snowflakes (the flake in its eyes, on its flanks and over its head, grown) in lit cyan over a dark navy outline, on a wide ring round it."""
    Pz = K.PIECES
    p = P.Plan("Frostbyte", "a play bow with attitude: the chest down and the rump up, the head up 8 degrees and turned 14 to look you over, the right paw batting, a flurry of six snowflakes round it")
    p.wear("# the Frostbyte kit: a silver snowflake stud on each flank, where the stamped flake was",
           K.place(Pz["snowflake_stud"], "Flake", (0.75, 1.0, 0.25), "+x", mirror=True, lite=True, scale=2), ["snowflake_stud"] * 2)
    cuffs = K.band("CuffL", (-0.5, 0.375, -0.5), (0.375, 0.375), t=0.125, h=0.25, slot="Trim", material="metal")
    cuffs += K.band("CuffR", (0.5, 0.375, -0.5), (0.375, 0.375), t=0.125, h=0.25, slot="Trim", material="metal", pose="bat")
    p.wear("# silver cuffs on the front legs, a quarter stud tall and an eighth proud above the paws (the right one bats with its paw)", cuffs, ["silver_band"] * 2)
    hind = K.band("HindCuff", (0.5, 0.5, 1.25), (0.375, 0.375), t=0.125, h=0.25, slot="Trim", material="metal")
    for q in hind:
        q["mirror"] = "x"
    p.wear("# silver cuffs on the hind ankles, the same size", hind, ["silver_band"] * 2)
    flake = own("flake_big", "a seven-eighths-stud snowflake: a lit cyan plus and four dots over a dark navy outline (a satellite)", _flake_big, "Epic")
    sats = arc([flake] * 6, "Sat", (0, 0.0), 2.7, 1.3, [45, 85, 125, 235, 275, 315], "flurry", [0, 1.4, 0.0], g=0.125, lift=0.6)
    p.regions.append(("# the satellite set (`flurry`, two rows of three standing out to its sides, the back higher, nothing in front of the face): six snowflakes, a lit cyan plus and four dots over a dark navy outline, seven eighths of a stud across, facing the viewer", sats))
    p.satellites, p.orbit = 6, "flurry"
    return p


PLANS = {"Reindazzle": reindazzle, "Shellberg": shellberg, "Capybubble": capybubble, "Shimmerlynx": shimmerlynx, "Frostfang": frostfang}


def apply(sid, write=True):
    """Rewrite one note's generated region and bar_* keys; True when it was already up to date."""
    path = CREATURES / ("%s.md" % sid)
    text = path.read_text(encoding="utf-8")
    plan = PLANS[sid]()
    a, b = text.index(P.BEGIN), text.index(P.END)
    head = text[a:text.index("\n", a) + 1]
    new = text[:a] + head + P.region(plan) + "\n" + text[b:]
    new = S.set_front(new, plan.front())
    c = S.counts(S.load_text(new, str(path)))
    new = S.set_front(new, {"blocks": c["blocks"], "tris": c["tris"], "height": round(c["height"], 2)})
    if write and new != text:
        path.write_text(new, encoding="utf-8")
    return new == text


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    ids = [a for a in argv if not a.startswith("--")] or list(PLANS)
    stale = [sid for sid in ids if not apply(sid, write="--check" not in argv)]
    if "--check" in argv:
        if stale:
            print("bar_w2: out of date: %s (run python3 -I tools/blocky/bar_w2.py)" % ", ".join(stale))
            return 1
        print("bar_w2: up to date")
        return 0
    print("bar_w2: wrote %s" % ", ".join(ids))
    return 0


if __name__ == "__main__":
    sys.exit(main())
