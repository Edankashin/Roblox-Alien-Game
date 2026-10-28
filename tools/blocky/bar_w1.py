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


# ------------------------------------------------------------------------------------------------ Zirrit (Zapfinch)
def _bolt_zig(g, lite=False):
    # a stepped lightning bolt, seven eighths of a stud tall, the same from both sides: gold steps with a lit storm-yellow head and tip
    z0, z1 = -0.125, 0.125
    return [_box(-0.125, 0.25, 0.625, 0.875, z0, z1, "Glow", "crystal"), _box(-0.25, 0.125, 0.375, 0.625, z0, z1, "Trim", "metal"),
            _box(-0.25, 0.375, 0.25, 0.375, z0, z1, "Trim", "metal"), _box(0.0, 0.25, 0.125, 0.25, z0, z1, "Trim", "metal"),
            _box(0.0, 0.125, 0.0, 0.125, z0, z1, "Glow", "crystal")]


def _spark_ring(g, lite=False):
    # a square ring of gold five eighths of a stud across with a lit heart: a held spark
    z0, z1 = -0.125, 0.125
    return [_box(-0.25, 0.375, 0.25, 0.375, z0, z1, "Trim", "metal"), _box(-0.25, 0.375, -0.375, -0.25, z0, z1, "Trim", "metal"),
            _box(-0.375, -0.25, -0.25, 0.25, z0, z1, "Trim", "metal"), _box(0.25, 0.375, -0.25, 0.25, z0, z1, "Trim", "metal"),
            _box(-0.125, 0.125, -0.125, 0.125, z0, z1, "Glow", "crystal")]


own("bolt_zig", "Zirrit", "a seven-eighths-stud stepped lightning bolt, gold with a lit head and tip (a satellite)", _bolt_zig)
own("spark_ring", "Zirrit", "a three-quarter-stud gold square ring round a lit heart (a satellite)", _spark_ring)


def zapfinch():
    """Rare, Verdant, Lightning: a songbird mid-song. Four kit pieces (moss pads on its back, cream blossom buds on the crown behind the antennae), six
    satellites in one lit gold and yellow (three stepped bolts, three held sparks) on a wide low ring clear of the wings; wings flicked up, head cocked,
    tail cocked."""
    P_ = K.PIECES
    p = Plan("Verdant", "a songbird mid-song: the head cocked to its right, both wings flicked up, the tail cocked high, a ring of lit bolts and sparks round it")
    kit = K.place(P_["moss_cells"], "Moss", (0.375, 1.5, 0.75), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"})
    p.wear("# the Verdant kit: cream moss pads with a lit tuft on its back behind the wings' roots", kit, ["moss_cells"] * 2)
    kit = K.place(P_["blossom_bud"], "Bud", (0.75, 2.5, 0.0), "+y", mirror=True, slots={"BodyDark": "BodyDark", "Accessory": "Trim"}, pose="head")
    p.wear("# gold blossom buds on the crown's back corners (they turn with the cocked head)", kit, ["blossom_bud"] * 2)
    sats = K.orbit([P_["bolt_zig"], P_["spark_ring"]] * 3, "Sat", (0, 0.25), 2.4, 1.55, tilt=0.15, moves="bolts", pivot=[0, 1.55, 0.25], start=math.radians(30),
                   lift=0.9, facing="front", drops=[0.375, 0, 0.375, 0, 0.375, 0], g=0.25)
    p.regions.append(("# the satellite set (`bolts`, one wide ring clear of the wings, the front low): three stepped bolts and three held sparks, all gold with a lit heart", sats))
    p.satellites, p.orbit = 6, "bolts"
    return p


# ------------------------------------------------------------------------------------------------ Vixa (Sparkfox)
def _paint_splat(g, lite=False):
    # a splat of cream paint seven eighths of a stud across, the same from both sides: a stepped blob with gold ends and a lit amber dab on both faces
    z0, z1 = -0.125, 0.125
    return [_box(-0.25, 0.25, 0.125, 0.375, z0, z1, "BodyDark", None), _box(-0.25, 0.25, -0.125, 0.125, z0, z1, "BodyDark", None),
            _box(-0.375, -0.25, -0.125, 0.125, z0, z1, "Trim", "metal"), _box(0.25, 0.375, -0.125, 0.125, z0, z1, "Trim", "metal"),
            _box(-0.25, 0.125, -0.375, -0.125, z0, z1, "BodyDark", None), _box(0.125, 0.375, -0.5, -0.25, z0, z1, "Trim", "metal"),
            _box(-0.125, 0.125, -0.125, 0.125, 0.125, 0.25, "Glow", "crystal"), _box(-0.125, 0.125, -0.125, 0.125, -0.25, -0.125, "Glow", "crystal")]


def _paint_pot(g, lite=False):
    # a paint tin three quarters of a stud across and five eighths tall, the same from both sides (a straight-sided cream tin with a gold lid ring over it, so it
    # is not a mushroom): lit amber paint domed on top and one lit drip down its side
    return [_box(-0.375, 0.375, 0.0, 0.375, -0.375, 0.375, "BodyDark", None), _box(-0.375, 0.375, 0.375, 0.5, -0.375, 0.375, "Trim", "metal"),
            _box(-0.25, 0.25, 0.5, 0.625, -0.25, 0.25, "Glow", "crystal"), _box(0.375, 0.5, 0.125, 0.5, -0.125, 0.125, "Glow", "crystal")]


own("paint_splat", "Vixa", "a seven-eighths-stud splat of cream paint with gold ends and a lit amber dab (a satellite)", _paint_splat)
own("paint_pot", "Vixa", "a three-quarter-stud cream paint pot with a gold rim and lit amber paint (a satellite)", _paint_pot)


def sparkfox():
    """Rare, Verdant, Ember: a fox painter mid-flourish. Three kit pieces (a gold girth round the barrel, gold blossom buds on the beret), six
    satellites in one lit cream, gold and amber (three paint splats, three paint pots) on a wide ring clear of the palette and the brush; head cocked toward the
    palette, the right foreleg lifted, the brush tail raised."""
    P_ = K.PIECES
    p = Plan("Verdant", "a painter's flourish: the head cocked toward its palette, the right forepaw lifted like a brush mid-stroke, the brush tail raised, a ring of paint splats and pots round it")
    p.wear("# a gold girth: a quarter stud wide, an eighth proud, right round the barrel behind the front legs (the painter's strap)",
           [K.part("Girth", "Trim", (1.75, 1.25, 0.25), (0, 1.0, 0.5), material="metal")], ["bark_band"])
    kit = K.place(P_["blossom_bud"], "Bud", (0.625, 2.25, -0.25), "+y", mirror=True, slots={"BodyDark": "BodyDark", "Accessory": "Trim"}, pose="head")
    p.wear("# gold blossom buds on the head's top behind the ears (they turn with the cocked head)", kit, ["blossom_bud"] * 2)
    sats = K.orbit([P_["paint_splat"], P_["paint_pot"]] * 3, "Sat", (0, 0.25), 2.6, 1.5, tilt=0.15, moves="paints", pivot=[0, 1.5, 0.25], start=math.radians(30),
                   lift=0.8, facing="front", drops=[0.125, 0.375, 0.125, 0.375, 0.125, 0.375], g=0.25)
    p.regions.append(("# the satellite set (`paints`, one wide ring clear of the palette and the brush, the front low): three paint splats and three paint pots, all cream, gold and lit amber", sats))
    p.satellites, p.orbit = 6, "paints"
    return p


# ------------------------------------------------------------------------------------------------ Wispkin (Wisplet)
def _lantern_pane(g, lite=False):
    # a pane of the lantern's lost glass, three quarters of a stud wide and seven eighths tall, the same from both sides: an iron frame round a lit lilac pane
    z0, z1 = -0.125, 0.125
    return [_box(-0.375, 0.375, 0.375, 0.5, z0, z1, "Trim", "metal"), _box(-0.375, 0.375, -0.375, -0.25, z0, z1, "Trim", "metal"),
            _box(-0.375, -0.25, -0.25, 0.375, z0, z1, "Trim", "metal"), _box(0.25, 0.375, -0.25, 0.375, z0, z1, "Trim", "metal"),
            _box(-0.25, 0.25, -0.25, 0.375, z0, z1, "Glow", "crystal")]


def _wisp_orb(g, lite=False):
    # a little hanging lantern seven eighths of a stud tall, the same from both sides: an iron ring and cap over a lit lilac octagon of light (a round orb, so it is not
    # read as a pane; the first try, a flame on a blue base, read as a cupcake)
    z0, z1 = -0.125, 0.125
    return [_box(-0.125, 0.125, 0.5, 0.625, z0, z1, "Trim", "metal"), _box(-0.25, 0.25, 0.375, 0.5, z0, z1, "Trim", "metal"),
            _box(-0.25, 0.25, -0.25, 0.375, z0, z1, "Glow", "crystal"), _box(-0.375, 0.375, -0.125, 0.25, z0, z1, "Glow", "crystal")]


own("lantern_pane", "Wispkin", "a three-quarter-stud iron-framed pane of the lantern's lost glass, lit lilac (a satellite)", _lantern_pane)
own("wisp_orb", "Wispkin", "a three-quarter-stud hanging lantern: an iron ring and cap over a lit lilac octagon (a satellite)", _wisp_orb)


def wisplet():
    """Rare, Verdant, Spirit (the Haunted Nebula event): a will-o'-the-wisp in a lantern's cage. Three kit pieces (violet moss pads with a lit tuft on the
    cage's top corners, a violet vine round the belly's back and sides), six satellites in one lit lilac (three iron-framed panes of the lost glass and
    three little flames) on the ring `glass` (it replaces the four old panes), the flame leaning into a drift and the trail swept out behind."""
    P_ = K.PIECES
    p = Plan("Verdant", "a drift: the flame leaning 14 degrees to its right with its tongue licking the other way, the trail swept out to its left, the lantern glass and little lanterns circling")
    kit = K.place(P_["moss_cells"], "Moss", (0.75, 2.25, 0.25), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"})
    p.wear("# the Verdant kit: violet moss pads with a lit tuft on the cage's top corners, either side of the flame's root", kit, ["moss_cells"] * 2)
    kit = K.vine_wrap("Vine", (0, 0.75, 0), (2, 1.5), 1.5, steps=3, t=0.125, slot="Accessory", faces=("+x", "+z", "-x"))
    p.wear("# a violet vine winding up the belly's sides and back in three strips (the face stays clear)", kit, ["vine_wrap"])
    sats = K.orbit([P_["lantern_pane"], P_["wisp_orb"]] * 3, "Sat", (0, 0), 2.4, 1.65, tilt=0.2, moves="glass", pivot=[0, 1.875, 0], start=math.radians(30),
                   lift=0.7, facing="front", drops=[0.0, 0.125, 0.0, 0.125, 0.0, 0.125], g=0.25)
    p.regions.append(("# the satellite set (`glass`, one wide ring clear of the bail and the wisps, the front low): three iron-framed panes of the lantern's lost glass and three little hanging lanterns, all lit lilac", sats))
    p.satellites, p.orbit = 6, "glass"
    return p


# ------------------------------------------------------------------------------------------------ Voltus (Thunderhog)
def _charge_cell(g, lite=False):
    # a storm battery five eighths of a stud across and three quarters tall, the same from both sides: a gold case, two gold terminals and a lit yellow core on both faces
    z0, z1 = -0.125, 0.125
    return [_box(-0.25, 0.25, -0.375, 0.25, z0, z1, "Trim", "metal"), _box(-0.125, 0.125, 0.25, 0.375, z0, z1, "Trim", "metal"),
            _box(-0.125, 0.125, -0.25, 0.125, 0.125, 0.1875, "Glow", "crystal"), _box(-0.125, 0.125, -0.25, 0.125, -0.1875, -0.125, "Glow", "crystal")]


def _thunder_puff(g, lite=False):
    # a pocket thundercloud seven eighths of a stud across, the same from both sides: a lavender storm cloud with a dark underside and two puffs, and a fat lit yellow bolt of two
    # quarter-stud steps hanging under it (the first try, a lavender puff on a thin stem, read as a mushroom)
    z0, z1 = -0.125, 0.125
    return [_box(-0.4375, 0.4375, 0.0, 0.125, z0, z1, "BodyDark", None), _box(-0.4375, 0.4375, 0.125, 0.25, z0, z1, "Accessory", None),
            _box(-0.3125, -0.0625, 0.25, 0.375, z0, z1, "Accessory", None), _box(0.0625, 0.3125, 0.25, 0.375, z0, z1, "Accessory", None),
            _box(0.0, 0.25, -0.25, 0.0, z0, z1, "Glow", "crystal"), _box(-0.125, 0.125, -0.5, -0.25, z0, z1, "Glow", "crystal")]


own("charge_cell", "Voltus", "a five-eighths-stud storm battery: a gold case, terminals and a lit yellow core (a satellite)", _charge_cell, "Epic")
own("thunder_puff", "Voltus", "a seven-eighths-stud lavender thundercloud with a dark underside, two puffs and a fat lit yellow bolt hanging under it (a satellite)", _thunder_puff, "Epic")


def thunderhog():
    """Epic, Verdant, Lightning: a storm hog charging. Six kit pieces (lavender moss pads with a lit tuft on the head top, gold blossom buds behind them, a lavender vine round the head,
    a gold girth on the rump), six satellites in one lit yellow and gold (three storm batteries, three pocket thunderclouds) on a wide
    ring; the head cocked, the right foreleg pawing, the tail up."""
    P_ = K.PIECES
    p = Plan("Verdant", "a charge: the head cocked 12 degrees as it eyes the sky, the right foreleg pawing the ground, the tail cocked up, a ring of storm batteries and thunderclouds round it")
    kit = K.place(P_["moss_cells"], "Moss", (0.375, 2.25, -0.625), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"}, pose="head")
    p.wear("# the Verdant kit: lavender moss pads with a lit tuft on the head's top, between the rods (they turn with the cocked head)", kit, ["moss_cells"] * 2)
    kit = K.vine_wrap("Vine", (0, 0.625, -0.75), (2, 1.75), 1.5, steps=3, t=0.125, slot="Accessory", faces=("+x", "+z", "-x"), pose="head")
    p.wear("# a lavender vine winding up the head's sides and back in three strips (the face stays clear; it turns with the head)", kit, ["vine_wrap"])
    kit = K.place(P_["blossom_bud"], "Bud", (0.75, 2.25, -0.25), "+y", mirror=True, slots={"BodyDark": "BodyDark", "Accessory": "Trim"}, pose="head")
    p.wear("# gold blossom buds on the head's back corners, behind the moss (they turn with the head)", kit, ["blossom_bud"] * 2)
    p.wear("# a gold girth: a quarter stud wide, an eighth proud, round the rump behind the coat's last quill (the collar's twin)",
           [K.part("Girth", "Trim", (2.0, 1.75, 0.25), (0, 1.25, 2.25), material="metal")], ["bark_band"])
    sats = K.orbit([P_["charge_cell"], P_["thunder_puff"]] * 3, "Sat", (0, 0.6), 3.1, 1.6, tilt=0.2, moves="storm", pivot=[0, 1.6, 0.6], start=math.radians(30),
                   lift=0.8, facing="front", drops=[0.0, 0.125, 0.0, 0.125, 0.0, 0.125], g=0.125)
    p.regions.append(("# the satellite set (`storm`, one wide ring clear of the cloud and the antennae, the front low): three storm batteries and three pocket thunderclouds, all gold, lavender and lit yellow", sats))
    p.satellites, p.orbit = 6, "storm"
    return p


# ------------------------------------------------------------------------------------------------ Iridia (Gloomoth)
def _mini_moth(g, lite=False):
    # a little moth seven eighths of a stud across, the same from both sides: a gold body and feelers, lit orchid upper wings over pale lilac lower wings
    z0, z1 = -0.0625, 0.0625
    out = [_box(-0.0625, 0.0625, -0.25, 0.25, -0.125, 0.125, "Trim", "metal"), _box(-0.1875, -0.0625, 0.25, 0.375, -0.125, 0.125, "Trim", "metal"),
           _box(0.0625, 0.1875, 0.25, 0.375, -0.125, 0.125, "Trim", "metal")]
    for sx in (-1, 1):
        lo, hi = (-0.4375, -0.0625) if sx < 0 else (0.0625, 0.4375)
        out.append(_box(lo, hi, 0.0, 0.25, z0, z1, "Glow", "crystal"))
        lo2, hi2 = (-0.3125, -0.0625) if sx < 0 else (0.0625, 0.3125)
        out.append(_box(lo2, hi2, -0.25, 0.0, z0, z1, "Accessory", None))
    return out


def _moonflower(g, lite=False):
    # a night-blooming moonflower three quarters of a stud across, the same from both sides: pale lilac petals round a gold heart with a lit orchid dot on both faces
    z0, z1 = -0.125, 0.125
    return [_box(-0.125, 0.125, -0.125, 0.125, z0, z1, "Trim", "metal"),
            _box(-0.125, 0.125, 0.125, 0.375, z0, z1, "Accessory", None), _box(-0.125, 0.125, -0.375, -0.125, z0, z1, "Accessory", None),
            _box(-0.375, -0.125, -0.125, 0.125, z0, z1, "Accessory", None), _box(0.125, 0.375, -0.125, 0.125, z0, z1, "Accessory", None),
            _box(-0.0625, 0.0625, -0.0625, 0.0625, 0.125, 0.1875, "Glow", "crystal"), _box(-0.0625, 0.0625, -0.0625, 0.0625, -0.1875, -0.125, "Glow", "crystal")]


own("mini_moth", "Iridia", "a seven-eighths-stud little moth: gold body and feelers, lit orchid wings over a pale lilac base (a satellite)", _mini_moth, "Epic")
own("moonflower", "Iridia", "a three-quarter-stud moonflower: pale lilac petals round a gold heart with a lit orchid dot (a satellite)", _moonflower, "Epic")


def gloomoth():
    """Epic, Verdant, Spirit: a night moth mid-flutter. Five kit pieces (lilac moss pads with a lit tuft on the abdomen, gold blossom buds on the crown, a gold girth
    between the head and abdomen), six satellites in one lit orchid, gold and lilac (three little moths and three moonflowers) on a wide ring clear of the wings; the
    fore wings raised, the head cocked, the abdomen curled up."""
    P_ = K.PIECES
    p = Plan("Verdant", "a night flutter: the crystal fore wings raised 12 degrees higher, the head cocked 6 degrees, the abdomen curled up 12 degrees behind it, three little moths and three moonflowers circling")
    kit = K.place(P_["moss_cells"], "Moss", (0.375, 1.75, 1.375), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"}, pose="abd")
    p.wear("# the Verdant kit: lilac moss pads with a lit tuft on the abdomen's top (they curl up with it)", kit, ["moss_cells"] * 2)
    kit = K.place(P_["blossom_bud"], "Bud", (0.375, 2.75, -0.125), "+y", mirror=True, slots={"BodyDark": "BodyDark", "Accessory": "Trim"}, pose="head")
    p.wear("# gold blossom buds on the crown's step, between the feelers (they turn with the head)", kit, ["blossom_bud"] * 2)
    p.wear("# a gold girth: a quarter stud wide, an eighth proud, round the waist between the head and the abdomen",
           [K.part("Girth", "Trim", (1.75, 1.5, 0.25), (0, 1.125, 0.375), material="metal")], ["bark_band"])
    sats = K.orbit([P_["mini_moth"], P_["moonflower"]] * 3, "Sat", (0, 0.5), 3.2, 1.6, tilt=0.2, moves="swarm", pivot=[0, 1.6, 0.5], start=math.radians(30),
                   lift=0.8, facing="front", drops=[0.125, 0.0, 0.125, 0.0, 0.125, 0.0], g=0.125)
    p.regions.append(("# the satellite set (`swarm`, one wide ring clear of the wings, the front low): three little moths and three moonflowers, in lit orchid, gold and pale lilac", sats))
    p.satellites, p.orbit = 6, "swarm"
    return p


# ------------------------------------------------------------------------------------------------ Grin (Spookum)
def _candle_stick(g, lite=False):
    # a haunted candle seven eighths of a stud tall, the same from both sides: a brass dish, a pumpkin-orange candle with a cream drip down each face and a lit violet flame
    z0, z1 = -0.125, 0.125
    return [_box(-0.375, 0.375, -0.375, -0.25, -0.25, 0.25, "Trim", "metal"), _box(-0.125, 0.125, -0.25, 0.25, -0.125, 0.125, "Accessory", None),
            _box(-0.125, 0.0, 0.0, 0.25, -0.1875, -0.125, "Body", None), _box(0.0, 0.125, -0.125, 0.125, 0.125, 0.1875, "Body", None),
            _box(-0.0625, 0.0625, 0.25, 0.5, -0.0625, 0.0625, "Glow", "crystal")]


def _grin_pumpkin(g, lite=False):
    # a little jack-o'-lantern three quarters of a stud across, the same from both sides: an orange pumpkin of two steps, a brass stem and a lit violet grin and eyes on both faces
    return [_box(-0.375, 0.375, -0.25, 0.25, -0.25, 0.25, "Accessory", None), _box(-0.25, 0.25, 0.25, 0.375, -0.25, 0.25, "Accessory", None),
            _box(-0.0625, 0.0625, 0.375, 0.5, -0.0625, 0.0625, "Trim", "metal"),
            _box(-0.25, 0.25, -0.125, 0.0, 0.25, 0.3125, "Glow", "crystal"), _box(-0.25, 0.25, -0.125, 0.0, -0.3125, -0.25, "Glow", "crystal"),
            _box(-0.25, -0.125, 0.0625, 0.1875, 0.25, 0.3125, "Glow", "crystal"), _box(0.125, 0.25, 0.0625, 0.1875, 0.25, 0.3125, "Glow", "crystal"),
            _box(-0.25, -0.125, 0.0625, 0.1875, -0.3125, -0.25, "Glow", "crystal"), _box(0.125, 0.25, 0.0625, 0.1875, -0.3125, -0.25, "Glow", "crystal")]


own("candle_stick", "Grin", "a seven-eighths-stud haunted candle: a brass dish, an orange candle with cream drips and a lit violet flame (a satellite)", _candle_stick, "Epic")
own("grin_pumpkin", "Grin", "a three-quarter-stud jack-o'-lantern: an orange pumpkin, a brass stem, a lit violet grin and eyes (a satellite)", _grin_pumpkin, "Epic")


def spookum():
    """Epic, Verdant, Spirit (the Haunted Nebula event): a pumpkin ghost drifting in a lean. Five kit pieces (orange moss pads with a lit tuft and brass blossom buds on the dome, a
    brass belt round the sheet's waist), six satellites in one lit violet over orange and brass (three haunted candles, three jack-o'-lanterns) on the ring `candles` (it replaces the
    three old candles), the whole sheet leaning 8 degrees with its hem twisted behind it."""
    P_ = K.PIECES
    p = Plan("Verdant", "a drift: the whole sheet leaning 8 degrees to its right as it floats, the ragged hem twisted 25 degrees behind it, a ring of haunted candles and jack-o'-lanterns circling")
    kit = K.place(P_["moss_cells"], "Moss", (0.8125, 2.5, 0.375), "+y", mirror=True, slots={"Body": "Accessory", "Accessory": "Glow"}, pose="lean")
    p.wear("# the Verdant kit: pumpkin-orange moss pads with a lit tuft on the dome's back corners (they lean with the sheet)", kit, ["moss_cells"] * 2)
    kit = K.place(P_["blossom_bud"], "Bud", (0.5, 2.5, -0.5), "+y", mirror=True, slots={"BodyDark": "BodyDark", "Accessory": "Trim"}, pose="lean")
    p.wear("# brass blossom buds on the dome's front corners, either side of the crown (they lean with the sheet)", kit, ["blossom_bud"] * 2)
    belt = K.band("Belt", (0, 1.0, 0), (2, 2), t=0.1875, h=0.25, slot="Trim", material="metal", faces=("+x", "-x", "+z"), pose="lean")
    p.wear("# a brass belt: a quarter stud tall and three sixteenths proud, round the sheet's waist over the lit band (the grin stays clear)", belt, ["bark_band"])
    sats = K.orbit([P_["candle_stick"], P_["grin_pumpkin"]] * 3, "Sat", (0, 0), 2.5, 1.65, tilt=0.2, moves="candles", pivot=[0, 1.65, 0], start=math.radians(30),
                   lift=0.7, facing="front", drops=[0.125, 0.0, 0.125, 0.0, 0.125, 0.0], g=0.125)
    p.regions.append(("# the satellite set (`candles`, one wide ring clear of the arms and the lantern, the front low): three haunted candles and three jack-o'-lanterns, orange and brass with lit violet", sats))
    p.satellites, p.orbit = 6, "candles"
    return p


PLANS = {"Rocklobber": rocklobber, "Zapfinch": zapfinch, "Sparkfox": sparkfox, "Wisplet": wisplet, "Thunderhog": thunderhog, "Gloomoth": gloomoth, "Spookum": spookum}
