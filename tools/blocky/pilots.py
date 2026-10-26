#!/usr/bin/env python3
"""The character bar pilots (Decision B54): the four plans that apply the world kits (tools/blocky/kits.py) to Moop, Raddis, Syrinx and Fenrir.

Each pilot's spec note keeps its body by hand and one generated region of the parts block, between the lines
`# pilot bar: begin` and `# pilot bar: end`: the kit pieces, the backdrop, the satellite set, the aura ring. This tool rewrites that region and the
note's `bar_*` frontmatter (what the alien wears, counted from the plan; tools/blocky/spec.py checks it against the tier) from the plans below, so a
change to a kit piece or a plan is one command:

  python3 -I tools/blocky/pilots.py             # rewrite the region and the bar_* keys of every pilot note
  python3 -I tools/blocky/pilots.py --check     # exit 1 when a note is out of date (tools/tests/test_pilots.py runs it)

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
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
BEGIN = "  # pilot bar: begin"
END = "  # pilot bar: end"


class Plan:
    """What one pilot wears: the generated regions (a comment and the parts under it), and the counts the note's frontmatter records."""

    def __init__(self, world, stance):
        self.world, self.stance = world, stance
        self.regions = []       # [(comment, [part])]
        self.kit = []           # the piece names worn, a mirrored pair twice
        self.satellites = 0
        self.orbit = ""
        self.backdrop = ""
        self.aura = ""

    def wear(self, comment, parts, names):
        self.regions.append((comment, parts))
        self.kit += names
        return self

    def front(self):
        out = {"bar_world": self.world, "bar_kit": len(self.kit), "bar_pieces": sorted(set(self.kit)), "bar_stance": self.stance}
        if self.satellites:
            out["bar_satellites"] = self.satellites
            out["bar_orbit"] = self.orbit
        if self.backdrop:
            out["bar_backdrop"] = self.backdrop
        if self.aura:
            out["bar_aura"] = self.aura
        return out


def moop():
    """Common, Verdant (PILOT-2): one kit piece, a half-stud run of amber sap down the head's right side from under the cap (two blocks, no glow). The
    whole ball leans in the `lean` rest pose (14 degrees), one leaf stands straight up and the other droops."""
    p = Plan("Verdant", "a clear slump: the whole ball rolled 14 degrees about its feet to its right, the tripod caught mid-step, one leaf standing straight up like an ear and the other drooping")
    drop = [K.part("Sapa", "Accessory", (0.125, 0.125, 0.25), (1.0625, 1.6875, -0.25), material="metal", pose="lean"),
            K.part("Sapb", "Accessory", (0.125, 0.375, 0.25), (1.0625, 1.4375, -0.25), material="metal", pose="lean")]
    return p.wear("# the Verdant kit's one piece (a Common wears one): amber sap, half a stud long, running down the head's right side from under the cap", drop, ["sap_run"])


def radish():
    """Cosmic, Verdant (PILOT-2, bold): eight kit pieces (moss pads, buds, a vine round the head, sap drops of half a stud, a brass band round the
    bulb), a teardrop flame crown of three layers, the sun disc and its stepped corona behind the body (the backdrop, 2.5 studs across), two
    wings spread in a rest pose, six satellites (three sunstones and three broad leaves, three quarters of a stud each) on a wide ring, and a
    ground aura of twelve gold runes."""
    P = K.PIECES
    p = Plan("Verdant", "a hover swoop: the root sweeps out to the right and hooks up, both wings spread 22 degrees up behind a sun disc, a flame crown over the brow")
    kit = K.place(P["moss_cells"], "Moss", (1.0, 2.75, 0.0), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Trim"})
    p.wear("# the Verdant kit: turquoise moss pads on the head's top corners, hanging over the edge", kit, ["moss_cells"] * 2)
    kit = K.place(P["blossom_bud"], "Bud", (0.5625, 2.875, -0.4375), "+y", mirror=True, slots={"BodyDark": "Accessory", "Accessory": "Trim"})
    p.wear("# golden blossom buds flanking the flame on the crown", kit, ["blossom_bud"] * 2)
    kit = K.vine_wrap("Vine", (0, 1.5, 0), (2, 1.75), 0.75, steps=3, t=0.125, faces=("+x", "+z", "-x"))
    p.wear("# a vine winding up the head's sides and back in three strips (the face and the disc stay clear)", kit, ["vine_wrap"])
    kit = K.place(P["sap_drop"], "Sap", (0.875, 1.25, -0.5), "-y", g=0.1875, mirror=True)
    p.wear("# amber sap drops, half a stud long, hanging from under the cheeks", kit, ["sap_drop"] * 2)
    kit = [K.part("BrassBand", "Trim", (1.75, 0.25, 1.75), (0, 1.0, 0), material="metal"),
           K.part("CollarStud", "Accessory", (0.25, 0.125, 0.0625), (0, 1.0, -0.90625)),
           K.part("CollarStud2", "Accessory", (0.25, 0.125, 0.0625), (0.5, 1.0, -0.90625), mirror=True)]
    p.wear("# the brass collar: a quarter stud tall, an eighth proud, round the bulb under the chin, with three turquoise studs on its front", kit, ["bark_band"])
    flame = K.teardrop("FlameO", (0, 2.875), [0.75, 0.875, 0.625, 0.375, 0.125], 0.125, 0.25, -0.3125, "Trim", "ember", moves="flame", pivot=[0, 2.875, -0.4])
    flame += K.teardrop("FlameM", (0, 2.875), [0.5, 0.625, 0.375, 0.125], 0.125, 0.125, -0.5, "Glow", "crystal", moves="flame", pivot=[0, 2.875, -0.4])
    flame += K.teardrop("FlameI", (0, 2.875), [0.25, 0.25, 0.125], 0.125, 0.0625, -0.59375, "BodyDark", None, moves="flame", pivot=[0, 2.875, -0.4])
    p.regions.append(("# the flame crown (shaped energy, `flame`): three layered teardrops on the crown, amber over yellow over white-hot, half a stud wide and five eighths tall", flame))
    disc = K.disc("Sun", (0, 1.875), [(1.5, "Accessory", "moss"), (1.375, "Trim", "metal")], 1.125, moves="halo", pivot=[0, 1.875, 1.1875])
    disc += K.corona("Ray", (0, 1.875), 1.5, 1.125, angles=(45, 90, 135, 180, 225, 270, 315), moves="halo", pivot=[0, 1.875, 1.1875], cut=0.0)
    p.regions.append(("# the backdrop (`halo`, it turns once in 12 s): a full sun disc 3 studs across, gold with a turquoise rim, seven stepped rays round it, a quarter of a stud deep, behind the body", disc))
    wings = []
    rows = [("WingA", "Trim", 1.25, 2.28125, "metal"), ("WingB", "Accessory", 1.125, 2.09375, None), ("WingC", "Body", 0.875, 1.90625, None),
            ("WingD", "Accessory", 0.625, 1.71875, None), ("WingE", "Trim", 0.375, 1.53125, "metal")]
    pivot = [1.4375, 2.0, 1.375]
    for name, slot, length, y, mat in rows:
        wings.append(K.part(name, slot, (length, 0.1875, 0.125), (1.4375 + length / 2, y, 1.375), material=mat, mirror=True, moves="wing", pivot=pivot, pose="wing"))
    for i, (name, slot, length, y, mat) in enumerate(rows[:3]):
        wings.append(K.part("WingTip%d" % i, "Glow", (0.1875, 0.1875, 0.125), (1.4375 + length + 0.09375, y, 1.375), material="glow", mirror=True, moves="wing", pivot=pivot, pose="wing"))
    p.regions.append(("# the wings, spread (`wing`, a rest pose of 22 degrees up about the root at the disc's rim: `rig.rest.wing`): five feather rows and three lit tips a side, behind the disc", wings))
    sats = K.orbit([P["sun_cross"], P["leaf_blade"], P["sun_cross"], P["leaf_blade"], P["sun_cross"], P["leaf_blade"]], "Sat", (0, 0), 2.1, 1.6, tilt=0.2,
                   moves="sunstone", pivot=[0, 1.6, 0], start=math.pi / 6, lift=0.45, facing="front", drops=[0, 0.375, 0, 0.375, 0, 0.375])
    p.regions.append(("# the satellite set (`sunstone`, one wide ring, the front low): three pixel suns and three broad leaves, three quarters of a stud each, facing the viewer", sats))
    p.satellites, p.orbit, p.backdrop = 6, "sunstone", "halo"
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve gold runes, three quarters of a stud long, in a circle round the root", K.aura_dashes("Aura", (0, 0), 1.75, n=12, long=0.75, wide=0.25)))
    p.aura = "aura"
    return p


def panpipe():
    """Secret, Verdant (PILOT-2, bold): kit pieces (dark moss pads, buds on the turned head, a vine round the lifted foreleg, brass sap drops of half
    a stud, brass cuffs on all four legs, a brass girth round the barrel), the eclipse (a big dark disc with a lit violet rim and seven stepped rays)
    behind the body, seven satellites (four eclipse shards, three wool tufts, each seven eighths of a stud) on a wide ring, and a ground aura."""
    P = K.PIECES
    p = Plan("Verdant", "an ibex in mid-stride: the head turned 25 degrees to its right, the right foreleg swung forward 45 degrees off the ground, the tail cocked, a dark eclipse behind it")
    kit = []
    kit += K.place(P["moss_cells"], "MossA", (-0.5, 1.625, 1.25), "+y", slots={"Body": "BodyDark"})
    kit += K.place(P["moss_cells"], "MossB", (-0.5, 1.625, 1.75), "+y", slots={"Body": "BodyDark"})
    kit += K.place(P["moss_cells"], "MossC", (0.0, 1.625, 1.75), "+y", slots={"Body": "BodyDark"})
    p.wear("# the Verdant kit in shadow: dark moss pads on the haunch", kit, ["moss_cells"] * 3)
    p.wear("# violet blossom buds on the turned head's top corners (they turn with it)", K.place(P["blossom_bud"], "Bud", (0.875, 2.5, -0.25), "+y", mirror=True, pose="head"), ["blossom_bud"] * 2)
    p.wear("# a vine winding up the lifted foreleg in three strips, an eighth proud (it swings with the leg)",
           K.vine_wrap("Vine", (0.5, 0.25, -0.125), (0.25, 0.25), 0.375, steps=3, t=0.125, pose="fore"), ["vine_wrap"])
    p.wear("# brass sap drops, half a stud long, hanging from the blanket's hem", K.place(P["sap_drop"], "Sap", (0.9375, 1.1875, 0.3125), "-y", g=0.1875, mirror=True), ["sap_drop"] * 2)
    cuffs = [K.part("CuffH", "Trim", (0.5, 0.25, 0.5), (0.5, 0.4375, 1.625), material="metal", mirror=True),
             K.part("CuffFL", "Trim", (0.5, 0.25, 0.5), (-0.5, 0.4375, -0.125), material="metal"),
             K.part("CuffFR", "Trim", (0.5, 0.25, 0.5), (0.5, 0.4375, -0.125), material="metal", pose="fore")]
    p.wear("# brass cuffs, a quarter stud tall and an eighth proud, round all four legs (the right foreleg's swings with it)", cuffs, ["bark_band"] * 4)
    p.wear("# the brass girth: a quarter stud wide, an eighth proud, right round the barrel behind the saddle blanket",
           [K.part("Girth", "Trim", (1.75, 1.25, 0.25), (0, 1.125, 0.875), material="metal")], ["bark_band"])
    disc = K.disc("Moon", (0, 1.75), [(1.4, "Glow", "glow"), (1.2, "BodyDark", None)], 2.1875, thick=0.25, moves="eclipse", pivot=[0, 1.75, 2.3125])
    disc += K.corona("Ray", (0, 1.75), 1.4, 2.1875, angles=(45, 90, 135, 180, 225, 270, 315), thick=0.25, material="glow", moves="eclipse", pivot=[0, 1.75, 2.3125], cut=0.0)
    p.regions.append(("# the backdrop (`eclipse`, it turns once in 20 s): a dark moon 2.8 studs across behind the rump, a lit violet rim a cell thick and seven stepped rays round it, a quarter stud deep", disc))
    sats = K.orbit([P["eclipse_shard"], P["wool_tuft"], P["eclipse_shard"], P["wool_tuft"], P["eclipse_shard"], P["wool_tuft"], P["eclipse_shard"]], "Sat", (0, 0.25), 2.4, 1.5,
                   tilt=0.15, moves="shards", pivot=[0, 1.5, 0.25], start=math.radians(20), lift=0.5, facing="front")
    p.regions.append(("# the satellite set (`shards`, one wide ring, the front low): four eclipse shards wrapped in violet light and three wool tufts, seven eighths of a stud each", sats))
    p.satellites, p.orbit, p.backdrop = 7, "shards", "eclipse"
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve violet runes, three quarters of a stud long, in a circle round the hooves", K.aura_dashes("Aura", (0, 0.4), 2.0, n=12, long=0.75, wide=0.25)))
    p.aura = "aura"
    return p


def fenripup():
    """Cosmic, Frostbyte (PILOT-2, bold): frost rims on the turned-up head, ice shards on the mane, a bright frost edge down the mane's steps, a
    silver ear band (silver cuffs on the legs and tail are in the note's own parts), aurora wisps; a full crescent moon standing behind the pup,
    taller than its body; seven satellites (four moon phases, three frost shards, seven eighths of a stud each) on a wide ring; a breath of three
    frost rings from the muzzle; and a ground aura. The head stands in the `head` rest pose (up 25 degrees, mid-howl), the tail in the `tail` one."""
    P = K.PIECES
    mane = {"moves": "mane", "pivot": [0, 1.25, 0.75]}
    head_rest = {"rot": [25, 0, 0], "pivot": [0, 1.5, 0.1], "move": [0, -0.45, 0]}
    p = Plan("Frostbyte", "a pup mid-howl: the head turned up 25 degrees, the tail cocked up 55 degrees over the back, a full crescent moon standing taller than it behind, a breath of frost rings")
    p.wear("# the Frostbyte kit: frost rims on the head's top front (they turn up with the head)", K.place(P["frost_rim"], "Rim", (0.5, 2.875, -1.25), "+y", mirror=True, pose="head"), ["frost_rim"] * 2)
    kit = K.place(P["ice_shard"], "ShardA", (0.875, 2.5625, 0.5), "+y", mirror=True, scale=1.5, **mane)
    kit += K.place(P["ice_shard"], "ShardB", (1.125, 2.1875, 0.625), "+y", mirror=True, scale=1.5, **mane)
    p.wear("# ice shards, half again as big, standing on the mane's second and third slabs (they ride the mane)", kit, ["ice_shard"] * 4)
    steps = [("RimA", 2.75, 2.5, 0.375), ("RimB", 2.375, 2.75, 0.5), ("RimC", 2.0, 2.5, 0.625), ("RimD", 1.625, 2.0, 0.75)]
    edge = [K.part(n, "Accessory", (w, 0.1875, 0.5), (0, y + 0.09375, z), material="ice", **mane) for n, y, w, z in steps]
    p.wear("# a bright frost edge along the back: a pale cap, three sixteenths tall, on each step of the mane (they ride it)", edge, ["frost_rim"])
    p.wear("# snowflake studs on the shoulder plates", K.place(P["snowflake_stud"], "Flake", (0.8125, 1.125, -0.5), "+x", mirror=True, lite=True), ["snowflake_stud"] * 2)
    p.wear("# a silver band, a quarter stud tall and an eighth proud, at the left ear's root (it rides the ear and the head)",
           K.band("EarBand", (-0.6875, 2.9375, -0.75), (0.375, 0.25), t=0.125, h=0.25, slot="Trim", material="metal", moves="ear", pivot=[-0.6875, 2.875, -0.75], pose="head"),
           ["silver_band"] + ["silver_band"] * 5)   # the ear band, the four silver leg cuffs and the tail cuff
    kit = K.place(P["aurora_wisp"], "Wisp", (0.5, 2.5625, 0.5), "+y", mirror=True, **mane)
    p.wear("# aurora wisps rising off the mane's second slab (they ride the mane)", kit, ["aurora_wisp"] * 2)
    # the crescent in two layers, so it reads on white snow: a pale silver moon in front and a dark indigo one a little bigger behind it, an eighth of a
    # stud of outline all round (the pale one alone vanished against the snow)
    cres = K.crescent_backdrop("Crescent", (0, 1.75), 1.625, 1.4, 0.65, 2.0625, row=0.25, cell=0.125, thick=0.125, moves="halo", pivot=[0, 1.75, 2.125])
    cres += K.crescent_backdrop("CrescentO", (0, 1.75), 1.75, 1.275, 0.65, 2.1875, row=0.25, cell=0.125, thick=0.125, slot="BodyDark", material="nebula",
                                moves="halo", pivot=[0, 1.75, 2.125])
    p.regions.append(("# the backdrop: a full crescent moon 3.5 studs tall (taller than the pup), a quarter stud deep, standing behind the tail: a silver moon with a dark indigo outline behind it, thick on its right, its horns to the left, rocking slowly (the halo)", cres))
    sats = K.orbit([P["moon_full"], (P["frost_shard"], None), P["moon_half"], (P["frost_shard"], None), P["moon_crescent"], P["moon_new"], (P["frost_shard"], None)], "Sat",
                   (0, 0.1), 2.3, 1.55, tilt=0.15, moves="phases", pivot=[0, 1.55, 0.1], start=math.radians(25), lift=0.5, facing="front",
                   drops=[0, 0.4, 0, 0.4, 0, 0, 0.4])
    p.regions.append(("# the satellite set (`phases`, one wide ring, the front low): the moon in four phases and three frost shards, seven eighths of a stud each", sats))
    p.satellites, p.orbit, p.backdrop = 7, "phases", "halo"
    # the breath: three square rings of lit frost drifting up and out to the creature's left (the viewer's right, away from the camera's side) from the muzzle, each bigger than the
    # last (shaped energy); beside the face, never over it
    nose = S.apply_rest({"at": [0, 1.78125, -1.9375], "rot": [0, 0, 0], "pivot": None, "rest": head_rest})["at"]
    breath = []
    bz = None
    for i, outer in enumerate((0.5, 0.625, 0.75)):
        cx = round((nose[0] - 0.8 - 0.55 * i) / 0.0625) * 0.0625
        cy = round((nose[1] + 0.15 + 0.3 * i) / 0.0625) * 0.0625
        zc = round((nose[2] - 0.2 - 0.3 * i) / 0.0625) * 0.0625
        bz = bz if bz is not None else [cx, cy, zc]   # one moving object: the rings share the first one's pivot
        breath += K.square_ring("Breath%d" % i, (cx, cy), outer, 0.125, zc, 0.125, "Glow", "crystal", moves="breath", pivot=bz)
    p.regions.append(("# the frost breath (`breath`, shaped energy): three square rings of lit frost in the air along the muzzle's line, 0.5, 0.625 and 0.75 across, drifting up", breath))
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve runes, lit and dark in turn so the ring reads on snow, three quarters of a stud long",
                      K.aura_dashes("Aura", (0, 0.2), 2.15, n=12, long=0.75, wide=0.25, alt=("BodyDark", "nebula"))))
    p.aura = "aura"
    return p


PLANS = {"Mossbop": moop, "Radish": radish, "Panpipe": panpipe, "Fenripup": fenripup}


def region(plan):
    out = []
    for comment, parts in plan.regions:
        out.append("  " + comment)
        out += [K.line(p) for p in parts]
    return "\n".join(out)


def apply(sid, write=True):
    """Rewrite one note's generated region and bar_* keys; True when it was already up to date."""
    path = CREATURES / ("%s.md" % sid)
    text = path.read_text(encoding="utf-8")
    plan = PLANS[sid]()
    a, b = text.index(BEGIN), text.index(END)
    head = text[a:text.index("\n", a) + 1]
    new = text[:a] + head + region(plan) + "\n" + text[b:]
    new = S.set_front(new, plan.front())
    c = S.counts(S.load_text(new, str(path)))   # blocks, triangles and height follow the parts (the build measures the real triangles)
    new = S.set_front(new, {"blocks": c["blocks"], "tris": c["tris"], "height": round(c["height"], 2)})
    if write and new != text:
        path.write_text(new, encoding="utf-8")
    return new == text


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    stale = [sid for sid in PLANS if not apply(sid, write="--check" not in argv)]
    if "--check" in argv:
        if stale:
            print("pilots: out of date: %s (run python3 -I tools/blocky/pilots.py)" % ", ".join(stale))
            return 1
        print("pilots: up to date")
        return 0
    print("pilots: wrote %s" % ", ".join(PLANS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
