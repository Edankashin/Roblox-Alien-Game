---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Gaiabloom
name: Gaira
world: 1
tier: Legendary
status: review
element: Bloom
height: 6
blocks: 79
tris: 1140
bevel_width: 0.125
bevel_segments: 2
palette: ["#F0E6CE", "#6B4A2E", "#4FB84E", "#F5B83D", "#FF6FAE", "#1F1A17"]
roles: [body, second, accent, trim, glow, ink]
hero: Antler
vfx: "touches the ground (Legendary): the blossoms, the dapples and the nimbus's top and sides glow pink; the nimbus turns once in 12 s; petals orbit the antlers a stud out; a ground ring of light in the tier gold; a flower pops in each footprint; a warm light over the antlers (Effects.luau)"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Gaiabloom_sheet.svg]]"
render: "[[Gaiabloom_tq.jpg]]"
glb: ""
overlap: [0.996, 0.996, 0.995, 0.996]
vfx_render: "[[Gaiabloom_vfx.jpg]]"
---
# Gaiabloom (Gaira), Legendary, World 1 Verdant

An ivory stag with a big square head, long legs on gold hooves and drooping ears, crowned with antlers that are two little trees in bloom: bark trunks in gold bands, a branch out and a tine up, three leaf clumps each and pink blossoms that glow. A gold nimbus, a pixel ring lit at its top and sides, stands behind the head and frames the antlers; lit pink dapples run along its flanks and back like a fawn's spots, and a ruff of moss cells hangs under its chin. Concept row in `src/shared/data/Species.luau`: "stag, tree antlers, flowers bloom where it steps". Element: Bloom (`Effects.luau`); [[Roster-Redesign]] section 2 gives the footprint flowers, the orbiting petals and the ground ring. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the size of the player (6 studs to the avatar's 5) and it is the first creature whose light reaches the ground: the gold ring under its hooves and the petals circling its antlers say "Legendary" from across the meadow before the face does. The face stays the soft house face; the awe is the antlers, the nimbus and the glowing spots.

**Hero block.** The `Antler` pair, two blossoming trees on a stag's head, unique in Verdant.

**Alien anatomy.** Antlers that are living trees, a floating nimbus that turns on its own (the `halo` part) and a body that lights up in a pattern; four moving objects: the nimbus, the two ears and the tail.

**World motif (Verdant).** The moss cell, here as the leaf clumps of the antlers and the moss ruff under the chin.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2.5, 2.5, 2.25], at: [0, 3, -1.25], bevel: true}
  - {name: Torso, slot: Body, size: [2, 1.5, 3.25], at: [0, 2, 0.875], bevel: true}
  # long deer legs on gold hooves
  - {name: FrontLeg, slot: Body, size: [0.5, 1, 0.5], at: [0.625, 0.75, -0.25], mirror: x}
  - {name: HindLeg, slot: Body, size: [0.5, 1, 0.5], at: [0.625, 0.75, 2.25], mirror: x}
  - {name: Hoof, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.625, 0.125, -0.25], mirror: x}
  - {name: HindHoof, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.625, 0.125, 2.25], mirror: x}
  - {name: Ear, slot: Body, size: [0.75, 0.375, 0.25], at: [1.625, 3.625, -1], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [1.25, 3.75, -1]}
  - {name: Tail, slot: Body, size: [0.5, 0.5, 0.25], at: [0, 2.5, 2.625], moves: tail, pivot: [0, 2.5, 2.5]}
  # a ruff of moss cells under the chin (Verdant's motif), one blossom in it
  - {name: Ruff, slot: Accessory, size: [1.5, 0.5, 0.75], at: [0, 1.5, -1.5]}
  - {name: Ruff2, slot: Accessory, size: [0.75, 0.25, 0.5], at: [0, 1.125, -1.5]}
  - {name: RuffBloom, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.375, 1.375, -1.875]}
  # the hero: tree antlers in bloom: a bark trunk in a gold band, a branch out and a tine up, a branch back, three leaf clumps, four lit blossoms
  - {name: Antler, slot: BodyDark, size: [0.25, 1.25, 0.25], at: [0.5, 4.875, -1.25], mirror: x}
  - {name: AntlerBand, slot: Trim, size: [0.5, 0.125, 0.5], at: [0.5, 4.3125, -1.25], mirror: x}
  - {name: AntlerBranch, slot: BodyDark, size: [0.75, 0.25, 0.25], at: [0.875, 4.875, -1.25], mirror: x}
  - {name: AntlerTine, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1.125, 5.25, -1.25], mirror: x}
  - {name: AntlerBack, slot: BodyDark, size: [0.25, 0.25, 0.5], at: [0.5, 5.125, -0.875], mirror: x}
  - {name: LeafOut, slot: Accessory, size: [0.75, 0.5, 0.75], at: [1.25, 5.625, -1.25], mirror: x}
  - {name: LeafTop, slot: Accessory, size: [0.75, 0.5, 0.75], at: [0.5, 5.75, -1.25], mirror: x}
  - {name: LeafBack, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 5.5, -0.5], mirror: x}
  - {name: Blossom, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.375, 5.75, -1.75], mirror: x}
  - {name: Blossom2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.625, 5.875, -1.75], mirror: x}
  - {name: Blossom3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.75, 5.5, -1], mirror: x}
  - {name: Blossom4, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 5.875, -0.5], mirror: x}
  # emissive cells drawn into the pattern: lit fawn dapples on the flanks and the back
  - {name: Dapple, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.0625, 2.375, -0.25], mirror: x}
  - {name: Dapple2, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.0625, 2, 0.375], mirror: x}
  - {name: Dapple3, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.0625, 2.5, 1], mirror: x}
  - {name: Dapple4, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.0625, 1.875, 1.5], mirror: x}
  - {name: Dapple5, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.0625, 2.375, 2], mirror: x}
  - {name: BackDapple, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.375, 2.8125, 0.375]}
  - {name: BackDapple2, slot: Glow, size: [0.25, 0.125, 0.25], at: [-0.25, 2.8125, 1.125]}
  - {name: BackDapple3, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.25, 2.8125, 1.875]}
  # the gold nimbus: a pixel ring behind the head that frames the antlers, lit at its top and sides; it turns slowly (one moving part)
  - {name: Nimbus, slot: Trim, size: [1.5, 0.25, 0.25], at: [0, 2.625, 0.125], moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus1, slot: Trim, size: [0.5, 0.25, 0.25], at: [0.75, 2.875, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus2, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 3.125, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus3, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 3.375, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus4, slot: Trim, size: [0.5, 0.25, 0.25], at: [1.5, 3.625, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus5, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.625, 3.875, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus6, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.625, 4.125, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus7, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.625, 4.375, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus8, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.625, 4.625, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus9, slot: Trim, size: [0.5, 0.25, 0.25], at: [1.5, 4.875, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus10, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 5.125, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus11, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 5.375, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus12, slot: Trim, size: [0.5, 0.25, 0.25], at: [0.75, 5.625, 0.125], mirror: x, moves: halo, pivot: [0, 4.25, 0.125]}
  - {name: Nimbus13, slot: Glow, size: [1.5, 0.25, 0.25], at: [0, 5.875, 0.125], moves: halo, pivot: [0, 4.25, 0.125]}
```

## Face

The house face on the head's front: 16 cells across the 2.5-stud head (0.15625 a cell), 16 rows for the square front. The eye's lit crescent is the blossom pink.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF8FB0"
  rows:
    - "................"
    - "................"
    - "................"
    - "................"
    - "................"
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
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Gaiabloom.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Gaiabloom.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Gaiabloom_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Gaiabloom_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Gaiabloom_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Gaiabloom_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Gaiabloom_views.png]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: built as drawn; the antlers read at once as two trees in bloom and the moss ruff as a green bib, but the pastel pink glow washed to white in the light. Round 2: a saturated pink, so the blossoms, dapples and orbiting petals read as pink. Round 3: no change after the side-by-side. Overlap 0.995 to 0.996, 1,140 triangles, 79 blocks, 6 studs (1.2 avatars). Wanted for: one avatar tall, blossoming antlers, glowing spots and the first light that touches the ground (the gold ring, the orbiting petals). Still cheap: the ivory body loses its edges against a pale sky; the head is a plain cube with no snout, so the stag rests on the antlers and the legs; the nimbus shows only as an arc behind the head. Status review.
