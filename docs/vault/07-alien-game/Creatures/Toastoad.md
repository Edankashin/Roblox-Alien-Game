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
blocks: 20
tris: 338
bevel_width: 0.1
bevel_segments: 2
palette: ["#E8713A", "#6E4A3C", "#FFC94D", "#2A1810"]
roles: [body, second, accent, ink]
hero: PebblePack
vfx: "Uncommon, two layers (Effects.luau): an Emitter of white pixel puffs rises off the Back at 2 a second (the steaming pack), and a Burst of one pale blue bubble (A8E6FF) pops forward at the Mouth every 5 s, the second colour; the idle breathes 3 percent every 2.2 s; no light; the throat sac swells, the eye bumps lift, the pebbles jiggle and it rocks in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Toastoad_sheet.svg]]"
render: "[[Toastoad_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.996, 0.994, 0.994]
cells_render: "[[Toastoad_tq_cells.jpg]]"
idle_render: "[[Toastoad_idle.png]]"
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
  # B46 detail: an amber spot on the outside of each haunch
  - {name: Spot, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.8125, 0.75, 0.625], mirror: x}
  # the head is the toad: wide and low, bevelled; an amber belly sagging under it
  - {name: Head, slot: Body, size: [2, 1.25, 2], at: [0, 1, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1.5, 0.25, 1.25], at: [0, 0.25, -0.125], moves: belly, pivot: [0, 0.375, -0.125]}
  # a toad's wide smile across the face under the plate: an ink line a stud and a quarter wide, its corners turned up (the plate's small open mouth
  # was a dot on a 2-stud toad)
  - {name: Mouth, slot: Eye, size: [1.25, 0.125, 0.125], at: [0, 0.5625, -1.0625]}
  - {name: MouthCorner, slot: Eye, size: [0.125, 0.125, 0.125], at: [0.6875, 0.6875, -1.0625], mirror: x}
  # two eye bumps on top of the head
  - {name: EyeBump, slot: Body, size: [0.5, 0.375, 0.5], at: [0.375, 1.8125, -0.5], mirror: x, moves: bump, pivot: [0.375, 1.625, -0.5]}
  # the hero: a pack of hot pebbles on its back, two loose pebbles on top, two amber straps over the shoulders
  - {name: PebblePack, slot: BodyDark, size: [1.25, 0.75, 0.75], at: [0, 2, 0.5], material: stone}
  - {name: Pebble, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.25, 2.5625, 0.5], shape: ico1, material: stone, moves: pebble, pivot: [0.25, 2.375, 0.5]}
  - {name: Pebble2, slot: BodyDark, size: [0.375, 0.375, 0.375], at: [-0.3125, 2.5625, 0.4375], shape: ico1, material: stone, moves: stone, pivot: [-0.3125, 2.375, 0.4375]}
  - {name: Strap, slot: Accessory, size: [0.25, 0.125, 1], at: [0.625, 1.6875, 0.375], mirror: x}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `droplet`, an Uncommon design, a dewdrop with a light band at its foot, here a hot-spring aqua iris with an amber band (the colour of its straps and belly), a toad's wet, glossy eye, at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, three frames). No mouth on the plate (`mouth: none`): a toad's wide smile is geometry under it, an ink line a stud and a quarter wide with its corners turned up; blush cheeks.

```yaml
eyes:
  key: droplet
  colours: {iris: "#3CC4D8", iris2: accent}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 0.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the amber belly under its chin swells and settles like a throat sac (on the 2.2 s breath of Effects.luau), the two eye bumps lift in a burst, the two loose pebbles on the pack jiggle out of step in the steam, the toad rocks and the face blinks. Six moving things (five objects, the Uncommon cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    belly: [{kind: pulse, amp: 0.12, period: 2.2}]
    bump: [{kind: bob, amp: 0.06, period: 5}]
    pebble: [{kind: bob, amp: 0.05, period: 0.9}]
    stone: [{kind: bob, amp: 0.05, period: 1.1, phase: 0.5}]
    root: [{kind: sway, amp: 3, period: 2.6, axis: x}]
    face: [{kind: blink, period: 5}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Toastoad.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Toastoad.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Toastoad_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Toastoad_idle.png]]

The concept sheet, drawn from the parts table above: [[Toastoad_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: `stone` on the pack and the pebbles (cobbles and cracks), skin on the orange toad, the belly and the straps.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a wide low box with two bumps on top overlapped Dreep, Eekle and Floe at 0.74 to 0.79 in the boxed test, so the hind legs splay out past the head and the eye bumps pulled in to the crown's middle, which empties the box's top corners. Overlap 0.995 to 0.997, 280 triangles, 15 blocks, 2.75 studs, no moving parts (it breathes). Wanted for: the Geyser Field's toad carrying its hot spring on its back. Still cheap: the eye bumps carry no eyes (the eyes are on the front, rule 3) and read as nubs; the straps are mostly under the pack. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), one round. The house face became the library's `droplet`, a hot-spring aqua dewdrop with an amber band at its foot, on a 28 x 12 plate with an `open` mouth showing its tongue and blush; amber `Spot`s mark the outside of each haunch. It had no moving part: the belly under its chin is now the `belly` that swells like a throat sac on the 2.2 s breath, the eye bumps lift in a burst, the two loose pebbles on the pack jiggle out of step (`pebble`, `stone`), it rocks and blinks. Six moving things (five objects, the Uncommon cap, and the blink). Height 2.75 (in band, unchanged), 17 blocks, 308 triangles, overlap 0.994 to 0.996. Wanted for: the toad that carries its hot spring, glossy aqua eyes, a tongue and a throat that puffs. Still weak: the open mouth is four pixels on a two-stud head and reads small for a toad's wide smile (the library has no wide mouth), and the throat sac's swell is mostly hidden under the head from the high camera. Status review.
- 2026-10-21, Polish w2 worker: the mouth was small for a toad (the plate's four-pixel `open`). The plate's mouth is `none` and the smile is geometry under it: an ink line 1.25 studs wide, an eighth proud of the face, with two corner blocks turned up; 20 blocks (the Uncommon cap), 338 triangles, overlap 0.994 to 0.996; silhouette unchanged. Honest read: a toad's wide grin, much more character; the line is heavy at close range, but it is what reads at the game camera's distance.
