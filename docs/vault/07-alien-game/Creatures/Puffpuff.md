---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Puffpuff
name: Dandel
world: 1
tier: Common
status: review
element: Wind
height: 2.5
blocks: 10
tris: 202
bevel_width: 0.1
bevel_segments: 2
palette: ["#F4F1E8", "#4E9E3C", "#F5C542", "#1D2418"]
roles: [body, second, accent, ink]
hero: Parachute
vfx: "none (Common): one seed lifts off the puff and floats away every 5 s (Effects.luau's white Top emitter, a wisp sprite); it turns slowly on the spot; no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Puffpuff_sheet.svg]]"
render: "[[Puffpuff_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.996, 0.998, 0.994]
cells_render: "[[Puffpuff_tq_cells.jpg]]"
---
# Puffpuff (Dandel), Common, World 1 Verdant

A dandelion clock with a face: a soft white seed-head (the head, in woolly cells, stepped narrower above and below so it reads as a round puff) on a yellow calyx and a short green stem, standing on two broad green leaves that rise out from its foot like a rosette. Three seeds still stand on the puff, each an upturned cone with its parachute open, and one more has just let go and floats beside it. Concept row in `src/shared/data/Species.luau`: "dandelion puff, face". Element and effect: [[Roster-Redesign]] section 2 (Wind; a seed lifts off every 5 s). Rules: [[Blocky-Style]].

**What makes a player want it.** Everyone has blown one. It is the softest thing on the meadow (white wool cells, a round face) and it is slowly coming apart in the wind, which is the kind of small sadness a player wants to look after. The Common rung on purpose: white, green and one yellow, no glow and no light, a seed every 5 s.

**Hero block.** The `Parachute`, a seed that has just let go and floats beside the head (the `float` part the game lifts away), unique in Verdant (Moop's spore is a lime ball; this is a white upturned cone, the stalk at its point and the open canopy at its top).

**Alien anatomy.** A flower that stands on its own leaves and sheds pieces of itself on purpose.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the puff and the calyx.

## Parts

```yaml
parts:
  # the seed-head: a soft white cube in woolly cells, the face on its front, a narrower woolly step on top so it reads as a round puff
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.25, 0], bevel: true, material: wool}
  - {name: Puff, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 2, 0], material: wool}
  # the yellow calyx under it (the lower step of the round) and the short green stem to the ground
  - {name: Collar, slot: Accessory, size: [1.5, 0.25, 1.25], at: [0, 0.5, 0]}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.1875, 0]}
  # two broad leaves rising out from the foot, 25 degrees up
  - {name: Leaf, slot: BodyDark, size: [1.5, 0.125, 0.5], at: [0.8125, 0.375, 0], rot: [0, 0, 25], mirror: x}
  # three seeds still standing on the puff, each an upturned cone: the stalk at the point, the open parachute at the top
  - {name: Seed, slot: Body, size: [0.5, 0.375, 0.5], at: [-0.5, 2.3125, 0.25], shape: cone6, rot: [180, 0, 0]}
  - {name: Seed2, slot: Body, size: [0.5, 0.375, 0.5], at: [0.375, 2.3125, -0.375], shape: cone6, rot: [180, 0, 0]}
  - {name: Seed3, slot: Body, size: [0.5, 0.25, 0.5], at: [0.25, 2.25, 0.5], shape: cone6, rot: [180, 0, 0]}
  # the hero: a seed that has just let go, floating beside the head (one moving part)
  - {name: Parachute, slot: Body, size: [0.75, 0.5, 0.75], at: [1.125, 2.25, -0.5], shape: cone6, rot: [180, 0, 0], moves: float, pivot: [1.125, 2.25, -0.5]}
```

## Face

The house face on the seed-head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on a Common, the eye's lit crescent is the accent, the dandelion yellow. The two top rows keep the wool motif; below them the front is plain cells so the fluff never crowds the eyes.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FFA5B8"
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Puffpuff.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Puffpuff.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Puffpuff_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Puffpuff_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (57 islands). Materials: wool on the seed-head and its top step (shag blobs, a yellow fleck in thirty), skin elsewhere; the seeds are plain white cones.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "still a cube underneath"). The puff is a voxel round now: a woolly step 1.5 x 1.25 on top of the head and the yellow calyx widened to the same under it, so the outline steps in above and below; the seeds are upturned cones (cone6 turned over, 10 triangles each): three standing on the puff at different heights and the floating hero, so a few seeds stand out of the round instead of one stalk. Still 10 blocks and 2.5 studs (the cap of the Common band). Status review.

- 2026-10-19, World 1 roster worker, three rounds. Round 1: the seed stalks and the floating parachute were an eighth of a stud thick and did not read, and the leaves at 20 degrees sat at 0.70 against Twiglo. Round 2: the leaves 1.5 studs long rising 25 degrees from the foot, the stem a quarter taller so there is air under the head. Round 3: the seed stalks a quarter thick and the canopies 0.75 across, so the standing seed and the one floating off read as parachutes. Wanted for: the softest thing on the meadow, slowly coming apart. Still cheap: the wool's yellow flecks read as confetti more than seeds (the lit sprig of the motif is the accent); the puff is a cube. Status review.
