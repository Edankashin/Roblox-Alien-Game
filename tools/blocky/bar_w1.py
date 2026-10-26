#!/usr/bin/env python3
"""The character bar across World 1's Rare and up (Decisions B54, B55, B56; worker BAR-W1, 2026-10-26).

The plans of nine Verdant aliens, in tier order, each its own function: the generated region of its spec note (the kit pieces, the satellite
set, the trim, the backdrop, the shaped energy) and the counts its `bar_*` frontmatter records. `tools/blocky/pilots.py` imports PLANS from
here (`pilots.all_plans`) and writes the regions, so one command rewrites them all:

  python3 -I tools/blocky/pilots.py             # every pilot and every roster plan
  python3 -I tools/blocky/pilots.py Rocklobber  # one note
  python3 -I tools/blocky/pilots.py --check

The kit, the satellite builder `K.orbit`, the backdrop builders `K.disc` and `K.corona`, the shaped-energy builders `K.teardrop` and
`K.square_ring`, the aura and the rest-pose machinery are the pilots' (tools/blocky/kits.py, spec.py); this module adds the aliens' own satellite
pieces (registered into `K.PIECES` on import, so `bar_pieces` and the checks know them) and the plans. What a note keeps by hand: its body,
its `pose:` keys and `rig.rest` groups, its clips and its face. Standard library only.
"""
from __future__ import annotations

import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import kits as K  # noqa: E402
import pilots as P  # noqa: E402

_box = K._box
Plan = P.Plan
OWN = {}


def own(name, who, what, build, tier_from="Rare"):
    """Register one of the aliens' own satellite pieces (a flat cell figure facing out of its ring)."""
    OWN[name] = K.Piece(name, who, what, ("orbit",), build, tier_from)
    K.PIECES[name] = OWN[name]
    return OWN[name]


# ------------------------------------------------------------------------------------------------ Boulden (Rocklobber)
def _geode_half(g, lite=False):
    # three quarters of a stud on the Rare grid (an eighth), the same from both sides (the ring turns): a dark frame round a geode, lit amber crystals standing
    # out of it front and back, so what reads at 16 studs is one amber light in a dark ring
    out = [_box(-0.375, 0.375, -0.375, -0.25, -0.125, 0.125, "BodyDark", "stone"), _box(-0.375, -0.25, -0.25, 0.25, -0.125, 0.125, "BodyDark", "stone"),
           _box(0.25, 0.375, -0.25, 0.25, -0.125, 0.125, "BodyDark", "stone"), _box(-0.375, 0.375, 0.25, 0.375, -0.125, 0.125, "BodyDark", "stone"),
           _box(-0.25, 0.25, -0.25, 0.25, -0.125, 0.125, "BodyDark", None)]
    for z0, z1 in ((0.125, 0.25), (-0.25, -0.125)):
        out += [_box(-0.125, 0.125, -0.25, 0.25, z0, z1, "Glow", "crystal"), _box(-0.25, -0.125, -0.25, 0.0, z0, z1, "Glow", "crystal"),
                _box(0.125, 0.25, -0.25, 0.125, z0, z1, "Glow", "crystal")]
    return out


def _cairn_stack(g, lite=False):
    # a gold cairn, seven eighths of a stud tall, on both sides alike: three gold stones, a darker course and a lit pebble; the crab's glyph made a thing it carries
    return [_box(-0.375, 0.375, 0, 0.25, -0.125, 0.125, "Trim", "metal"), _box(-0.25, 0.25, 0.25, 0.375, -0.125, 0.125, "BodyDark", None),
            _box(-0.25, 0.25, 0.375, 0.625, -0.125, 0.125, "Trim", "metal"), _box(-0.125, 0.125, 0.625, 0.75, -0.125, 0.125, "Trim", "metal"),
            _box(-0.125, 0.125, 0.75, 0.875, -0.125, 0.125, "Glow", "crystal")]


own("geode_half", "Boulden", "a three-quarter-stud open geode: a stone frame round three lit amber crystals (a satellite)", _geode_half)
own("cairn_stack", "Boulden", "a seven-eighths-stud cairn of three stones with a gold course and a lit pebble (a satellite)", _cairn_stack)


def rocklobber():
    """Rare, Verdant, Stone: a champion crab. Four kit pieces (moss pads on the carapace's back corners, a dark vine up the shell's right side, a gold
    championship belt), six satellites (three open geodes and three cairns) on a wide low ring that clears the claws. The right boulder is held high
    and the left swung low and out (rest groups `clawR` and `clawL`), the pair of them a see-saw against the shell."""
    P_ = K.PIECES
    p = Plan("Verdant", "a champion's pose: the right boulder hoisted high, the left swung low and out, the shell square between them, a gold belt round its waist")
    kit = K.place(P_["moss_cells"], "Moss", (0.75, 2.0, 0.625), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"})
    p.wear("# the Verdant kit: stone-grey moss pads with a lit tuft on the carapace's back corners", kit, ["moss_cells"] * 2)
    kit = K.vine_wrap("Vine", (0, 0.75, 0), (2, 1.75), 0.75, steps=3, t=0.125, slot="BodyDark", faces=("+x", "+z", "-x"))
    p.wear("# a dark vine winding up the shell's sides and back in three strips (the face stays clear)", kit, ["vine_wrap"])
    belt = K.band("Belt", (0, 0.625, 0), (2, 1.75), t=0.125, h=0.25, slot="Trim", material="metal", faces=("+x", "-x", "+z"))
    belt.append(K.part("BeltBuckle", "Glow", (0.25, 0.25, 0.125), (0, 0.625, 1.0625), material="crystal"))
    p.wear("# the champion's belt: a gold band a quarter stud tall round the shell's waist (the face stays clear) with a lit amber buckle on its back", belt, ["bark_band"])
    sats = K.orbit([P_["geode_half"], P_["cairn_stack"]] * 3, "Sat", (0, 0), 2.9, 1.7, tilt=0.2, moves="trophies", pivot=[0, 1.7, 0], start=math.radians(30),
                   lift=1.0, facing="front", drops=[0, 0.375, 0, 0.375, 0, 0.375], g=0.25)
    p.regions.append(("# the satellite set (`trophies`, one wide ring clear of the claws, the front low): three open geodes and three cairns, three quarters of a stud and more", sats))
    p.satellites, p.orbit = 6, "trophies"
    return p


PLANS = {"Rocklobber": rocklobber}
