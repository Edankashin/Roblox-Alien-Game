---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Mossbop
name: Moop
world: 1
tier: Common
status: review
element: Bloom
height: 2.47
blocks: 10
tris: 312
bevel_width: 0.05
bevel_segments: 2
palette: ["#6CCB5F", "#2F7A4B", "#D9F36B", "#142019"]
roles: [body, second, accent, ink]
hero: Leaf
vfx: "none (Common): the sprout's two leaves unfurl and fold every 6 s, a procedural move of the sprout part; no particles, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Mossbop_sheet.svg]]"
render: "[[Mossbop_tq.jpg]]"
glb: ""
overlap: [0.998, 0.998, 0.999, 0.998]
---
# Mossbop (Moop), Common, World 1 Verdant

A moss cube that stands on three stubby feet, two in front and one behind (a tripod: no pet animal stands like that), with a two-leaf sprout growing out of the top of its head. Concept row in `src/shared/data/Species.luau`: "moss ball, eyes". Element and effect: [[Roster-Redesign]] section 2 (Bloom; the sprout unfurls every 6 s). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is the first thing they catch, so it has to be the cutest thing on the meadow: a wide, soft-cornered head that is half its height, the house face low on it, and one idea (the sprout) that moves. It stays plain on purpose: two greens, one lime accent, no glow and no light, so everything above it in the ladder reads as more.

**Hero block.** The `Leaf` pair on its dark `Stem`, lime against the moss green, tilted up 25 degrees; together they are the sprout part the game turns to unfurl them.

**World motif (Verdant).** Moss cells: a dark square plate proud on each side of the head, the same half-stud cell every Verdant species carries somewhere.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.375, 0], bevel: true}
  - {name: Belly, slot: BodyDark, size: [1.5, 0.5, 1.25], at: [0, 0.5, 0.125], bevel: true}
  - {name: Foot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.5, 0.125, -0.25], mirror: x}
  - {name: HindFoot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0, 0.125, 0.5]}
  - {name: Cell, slot: BodyDark, size: [0.125, 0.5, 0.5], at: [1.0625, 1.375, 0.375], mirror: x}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 2.125, 0]}
  - {name: Leaf, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.375, 2.3125, 0], rot: [0, 0, 25], mirror: x, moves: sprout, pivot: [0, 2.25, 0]}
```

## Face

The house face ([[Blocky-Style]] rule 3) on the head's front, 16 cells across the 2-stud head, so one cell is 0.125 studs and the 1.25-stud front is 10 rows.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8FA3"
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

`python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` draws the sheet and the view masks; `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` builds the GLB into that scratch folder (never `assets/models`; `glb` stays empty until Ethan approves the sheet) and renders the views (commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Mossbop_tq.jpg]]

The concept sheet, drawn from the parts table above: [[Mossbop_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Mossbop_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Mossbop_views.png]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: the first house eye read as a white eyeball with a pupil, and the leaves lay flat on the head, so the sprout did not read. Round 2: the house eye v2 (shine bar, lit crescent, sparkle) and a stemmed sprout at 25 degrees; the belly dropped to half a stud so the sprout fits under 2.5 studs. Round 3: no change after the side-by-side. Overlap with the sheet 0.998 to 0.999, 312 triangles. Wanted for: the cutest thing on the meadow, a face that is all eyes and a sprout that moves. Still cheap: the belly is a plain dark box, and the side moss cells read as headphones. Next: try the cell as a moss tuft on the belly, and an idle squash of the head. Status review, waiting for Ethan's look at the board.
