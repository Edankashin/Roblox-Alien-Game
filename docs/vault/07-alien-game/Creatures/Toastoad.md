---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Toastoad
name: Soakum
world: 2
tier: Uncommon
status: review
element: Hot spring
height: 2.75
blocks: 15
tris: 280
bevel_width: 0.1
bevel_segments: 2
palette: ["#E8713A", "#6E4A3C", "#FFC94D", "#2A1810"]
roles: [body, second, accent, ink]
hero: PebblePack
vfx: "one touch (Uncommon): steam wisps rise off the hot pebbles on its back at 2 a second (Effects.luau, the Wisp emitter at Back); a bubble pops on its nose when it blinks every 5 s; it breathes 4 percent (the belly); no moving parts, no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Toastoad_sheet.svg]]"
render: "[[Toastoad_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.995, 0.997, 0.997]
cells_render: "[[Toastoad_tq_cells.jpg]]"
---
# Toastoad (Soakum), Uncommon, World 2 Frostbyte

A squat orange toad, wide and low, with two eye bumps on top of its head, a wide flat smile, an amber belly sagging under it, two small front legs and two big folded hind legs on dark feet, and on its back a pack of hot-spring pebbles: a block of warm dark stone held on by two amber straps over its shoulders, with two loose pebbles stacked on top. Concept row in `src/shared/data/Species.luau`: "toad, pebble backpack, soaks till it wrinkles". Element and effect: [[Roster-Redesign]] section 2 (steam off its back; a bubble pops on its nose when it blinks). Rules: [[Blocky-Style]].

**What makes a player want it.** The Geyser Field's toad carries its hot spring with it: a pack of pebbles still warm from the pool, steaming, so it can soak anywhere. Orange on the snow, the warmest Uncommon on the world. The Uncommon rung exactly: a two-tone body (orange over umber), one secondary block (the pack) and a second colour in the touch (the white steam), at 2.75 studs.

**Hero block.** The `PebblePack`, a block of warm stone with two pebbles on top, strapped to its back: unique in Frostbyte (Pengoo's pack is cloth and orange; this is stone, and it steams).

**Alien anatomy.** The eye bumps are on top of the head while the eyes are on the front; the pack is a shell it was not born with but grew the straps for; it has no neck and no tail, and its belly hangs under the head like a second chin.

**World motif (Frostbyte).** The ice facet as steps: the eye bumps and the pack step off the head block; the stone of the Geyser Field in `stone` cells.

## Parts

```yaml
parts:
  # small front legs, big folded hind legs on dark feet
  - {name: FrontLeg, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.875, 0.1875, -0.625], mirror: x}
  - {name: HindThigh, slot: Body, size: [0.75, 0.75, 0.75], at: [1.375, 0.625, 0.625], mirror: x}
  - {name: HindFoot, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [1.375, 0.125, 0.875], mirror: x}
  # the head is the toad: wide and low, bevelled; an amber belly sagging under it
  - {name: Head, slot: Body, size: [2, 1.25, 2], at: [0, 1, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1.5, 0.25, 1.25], at: [0, 0.25, -0.125]}
  # two eye bumps on top of the head
  - {name: EyeBump, slot: Body, size: [0.5, 0.375, 0.5], at: [0.375, 1.8125, -0.5], mirror: x}
  # the hero: a pack of hot pebbles on its back, two loose pebbles on top, two amber straps over the shoulders
  - {name: PebblePack, slot: BodyDark, size: [1.25, 0.75, 0.75], at: [0, 2, 0.5], material: stone}
  - {name: Pebble, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.25, 2.5625, 0.5], shape: ico1, material: stone}
  - {name: Pebble2, slot: BodyDark, size: [0.375, 0.375, 0.375], at: [-0.3125, 2.5625, 0.4375], shape: ico1, material: stone}
  - {name: Strap, slot: Accessory, size: [0.25, 0.125, 1], at: [0.625, 1.6875, 0.375], mirror: x}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. A wide flat toad smile of six cells; the lit crescent is the accent amber (an Uncommon has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9C8A"
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg......gg..."
    - "..pp.kkkkkk.pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Toastoad.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Toastoad.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Toastoad_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Toastoad_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: `stone` on the pack and the pebbles (cobbles and cracks), skin on the orange toad, the belly and the straps.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a wide low box with two bumps on top overlapped Dreep, Eekle and Floe at 0.74 to 0.79 in the boxed test, so the hind legs splay out past the head and the eye bumps pulled in to the crown's middle, which empties the box's top corners. Overlap 0.995 to 0.997, 280 triangles, 15 blocks, 2.75 studs, no moving parts (it breathes). Wanted for: the Geyser Field's toad carrying its hot spring on its back. Still cheap: the eye bumps carry no eyes (the eyes are on the front, rule 3) and read as nubs; the straps are mostly under the pack. Status review.
