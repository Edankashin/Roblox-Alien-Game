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
    """Common, Verdant: one kit piece, amber sap running down the head's right side from under the cap (two blocks, no glow)."""
    p = Plan("Verdant", "slumped: the cap leans a quarter stud right and the base an eighth left, the tripod caught mid-step, one leaf up and one drooping")
    drop = K.place(K.PIECES["sap_run"], "Sap", (1.125, 1.625, -0.25), "+x", g=0.125, lite=True, slots={"Trim": "Accessory"})
    return p.wear("# the Verdant kit's one piece (a Common wears one): amber sap running down the head's right side from under the cap", drop, ["sap_run"])


def radish():
    """Cosmic, Verdant: seven kit pieces (moss pads, buds, a vine, sap drops), eight satellites on the sunstone orbit (suns, leaves, drops), and a
    ground aura of twelve gold dashes. The sun disk behind the head is its backdrop."""
    P = K.PIECES
    p = Plan("Verdant", "a hover tilt: the root swoops to the right in six steps, the right wing raised 20 degrees and the left one drooping 10")
    kit = K.place(P["moss_cells"], "Moss", (0.875, 2.75, 0.0), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Trim"})
    p.wear("# the Verdant kit: turquoise moss pads on the head's top corners", kit, ["moss_cells"] * 2)
    kit = K.place(P["blossom_bud"], "Bud", (0.5625, 2.875, -0.4375), "+y", mirror=True, slots={"BodyDark": "Accessory", "Accessory": "Trim"})
    p.wear("# golden blossom buds flanking the flame on the crown", kit, ["blossom_bud"] * 2)
    kit = K.vine_wrap("Vine", (0, 1.5, 0), (2, 1.75), 0.375, steps=3, t=0.0625, faces=("+x", "+z", "-x"))
    p.wear("# a vine winding round the head's sides and back (the face stays clear)", kit, ["vine_wrap"])
    kit = K.place(P["sap_drop"], "Sap", (0.875, 1.25, -0.5), "-y", mirror=True)
    p.wear("# amber sap drops hanging from under the cheeks", kit, ["sap_drop"] * 2)
    sats = K.orbit([P["sun_cross"], P["leaf_blade"], P["sun_cross"], (P["sap_drop"], "-y"), P["leaf_blade"], P["sun_cross"], P["leaf_blade"],
                    (P["sap_drop"], "-y")], "Sat", (0, 0), 1.8, 1.2, tilt=0.25, moves="sunstone", pivot=[0, 1.2, 0])
    p.regions.append(("# the satellite set (`sunstone`, one orbit turning against the disk): three pixel suns, three leaf blades and two sap drops on a ring tilted a quarter stud", sats))
    p.satellites, p.orbit, p.backdrop = 8, "sunstone", "halo"
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve gold dashes in a circle round the root", K.aura_dashes("Aura", (0, 0), 1.75, n=12, long=0.5)))
    p.aura = "aura"
    return p


def panpipe():
    """Secret, Verdant: ten kit pieces (dark moss pads, buds, a vine on the lifted foreleg, brass sap drops, brass bands on the hind legs), eight
    satellites on the `shards` orbit (eclipse shards, wool tufts, music notes) below the face, and a ground aura of twelve violet dashes. The
    eclipse behind the horns is its backdrop."""
    P = K.PIECES
    p = Plan("Verdant", "an ibex about to step: the right foreleg lifted a quarter stud, the left planted, the tail cocked up")
    kit = []
    kit += K.place(P["moss_cells"], "MossA", (-0.5, 1.625, 1.25), "+y", slots={"Body": "BodyDark"})
    kit += K.place(P["moss_cells"], "MossB", (-0.5, 1.625, 1.75), "+y", slots={"Body": "BodyDark"})
    kit += K.place(P["moss_cells"], "MossC", (0.0, 1.625, 1.75), "+y", slots={"Body": "BodyDark"})
    p.wear("# the Verdant kit in shadow: dark moss pads on the haunch", kit, ["moss_cells"] * 3)
    p.wear("# violet blossom buds on the head's top corners", K.place(P["blossom_bud"], "Bud", (0.875, 2.5, -0.25), "+y", mirror=True), ["blossom_bud"] * 2)
    p.wear("# a vine winding up the lifted foreleg", K.vine_wrap("Vine", (0.5, 0.5, -0.125), (0.25, 0.25), 0.375, steps=3, t=0.0625), ["vine_wrap"])
    p.wear("# brass sap drops hanging from the blanket's hem", K.place(P["sap_drop"], "Sap", (0.875, 1.1875, 0.25), "-y", mirror=True), ["sap_drop"] * 2)
    bands = K.band("BandR", (0.5, 0.4375, 1.625), (0.25, 0.25), t=0.0625, h=0.125, slot="Trim", material="wood")
    bands += K.band("BandL", (-0.5, 0.4375, 1.625), (0.25, 0.25), t=0.0625, h=0.125, slot="Trim", material="wood")
    p.wear("# brass bark bands round the hind legs", bands, ["bark_band"] * 2)
    sats = K.orbit([P["note_glyph"], P["eclipse_shard"], P["wool_tuft"], P["eclipse_shard"], P["note_glyph"], P["wool_tuft"], P["eclipse_shard"],
                    P["wool_tuft"]], "Sat", (0, 0.25), 1.9, 1.0, tilt=0.2, moves="shards")
    p.regions.append(("# the satellite set (`shards`, one orbit below the face): three eclipse shards, three wool tufts and two music notes", sats))
    p.satellites, p.orbit, p.backdrop = 8, "shards", "eclipse"
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve violet dashes in a circle round the hooves", K.aura_dashes("Aura", (0, 0.4), 2.0, n=12, long=0.5)))
    p.aura = "aura"
    return p


def fenripup():
    """Cosmic, Frostbyte: eleven kit pieces (frost rims, ice shards on the mane, snowflake studs, a silver ear band, aurora wisps), the crescent
    backdrop centred behind the body, eight satellites on the `phases` orbit (moon phases and frost shards) below the face, and a ground aura of
    twelve alternating dashes."""
    P = K.PIECES
    mane = {"moves": "mane", "pivot": [0, 1.25, 0.75]}
    p = Plan("Frostbyte", "a pup braced to howl: the paws split front and back, the tail cocked up over the rump, a crescent moon standing behind it")
    p.wear("# the Frostbyte kit: frost rims on the head's top front", K.place(P["frost_rim"], "Rim", (0.5, 2.875, -1.25), "+y", mirror=True), ["frost_rim"] * 2)
    kit = K.place(P["ice_shard"], "ShardA", (0.875, 2.75, 0.375), "+y", mirror=True, **mane)
    kit += K.place(P["ice_shard"], "ShardB", (1.125, 2.375, 0.5), "+y", mirror=True, **mane)
    p.wear("# ice shards standing on the mane's top two slabs (they ride the mane)", kit, ["ice_shard"] * 4)
    p.wear("# snowflake studs on the shoulder plates", K.place(P["snowflake_stud"], "Flake", (0.8125, 1.125, -0.5), "+x", mirror=True, lite=True), ["snowflake_stud"] * 2)
    p.wear("# a silver band at the left ear's root (it rides the ear)",
           K.band("EarBand", (-0.6875, 2.9375, -0.75), (0.375, 0.25), t=0.0625, h=0.125, slot="Trim", material="metal", moves="ear", pivot=[-0.6875, 2.875, -0.75]),
           ["silver_band"])
    kit = K.place(P["aurora_wisp"], "Wisp", (0.5, 2.75, 0.375), "+y", mirror=True, **mane)
    p.wear("# aurora wisps rising off the mane's top slab (they ride the mane)", kit, ["aurora_wisp"] * 2)
    p.regions.append(("# the backdrop: a crescent moon thirteen cells tall standing behind the whole alien, thick on its right, its horns to the left, rocking slowly (the halo)",
                      K.crescent_backdrop("Crescent", (0, 1.875), 1.625, 1.4, 0.55, 1.4375, moves="halo", pivot=[0, 1.875, 1.4375])))
    sats = K.orbit([P["moon_full"], (P["frost_shard"], "+y"), P["moon_half"], (P["frost_shard"], "+y"), P["moon_crescent"], P["moon_new"],
                    (P["frost_shard"], "+y"), P["moon_half"]], "Sat", (0, 0.2), 1.95, 0.95, tilt=0.2, moves="phases")
    p.regions.append(("# the satellite set (`phases`, one orbit turning against the mane): the moon in four phases (one twice) and three frost shards, below the face", sats))
    p.satellites, p.orbit, p.backdrop = 8, "phases", "halo"
    p.regions.append(("# the ground aura (`aura`, it breathes): twelve dashes, lit and dark in turn so the ring reads on snow",
                      K.aura_dashes("Aura", (0, 0.2), 2.15, n=12, long=0.5, alt=("BodyDark", "nebula"))))
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
