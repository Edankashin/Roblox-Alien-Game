---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Thunderhog
name: Voltus
world: 1
tier: Epic
status: review
element: Lightning
height: 3.75
blocks: 47
tris: 732
bevel_width: 0.125
bevel_segments: 2
palette: ["#8B5CF6", "#2E1F66", "#FFC233", "#FFF27A", "#160F2E"]
roles: [body, second, trim, glow, ink]
hero: Crest
arcs: ["Crest>QuillR", "Crest>QuillL", "Crest>Quill2R"]
vfx: "kept on the body: the crest's lit tip and the tail tip glow; an arc jumps from the crest tip to a quill tip every 2 s (a Beam, three flickers); sparks leave the tips at 6 a second; a violet light; in Rain the arcs come every 1 s"
artboard: ""
sheet: "[[Thunderhog_sheet.svg]]"
render: "[[Thunderhog_tq.jpg]]"
glb: ""
overlap: [0.997, 0.995, 0.997, 0.997]
vfx_render: "[[Thunderhog_vfx.jpg]]"
---
# Thunderhog (Voltus), Epic, World 1 Verdant

A storm hedgehog on six stubby legs (an alien hexapod), with one big stepped lightning bolt standing on its back and leaning forward over its head, lit at the tip, dark hedgehog quills either side of it, a gold collar and anklets, a dark stripe, a stepped gold bolt on each flank and a lit bolt for a tail. Concept row: "hedgehog, lightning quills". Element and effect: [[Roster-Redesign]] section 2 (Lightning: arcs between quills, sparks off the tips, a violet light). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first creature in Verdant whose silhouette has a crown: a lightning bolt rising a stud and a half over its back, lit at the tip, so it reads as "charged" from across the meadow while the face under them stays the same soft house face. Gold trim and the flank emblem are the Epic rung's detail (bands, stripes, a stepped emblem); the glow stays on the body, as the ladder says an Epic's effects do.

**Hero block.** The `Crest`: a seven-row pixel lightning bolt (a stroke up from the back, a jog, a stroke on to the tip) half a stud thick, gold below and lit in its top three rows.

**World motif (Verdant).** The moss cell, here as the quarter-stud steps of the crest and the flank bolt.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.75, 1.75], at: [0, 1.375, -0.75], bevel: true}
  - {name: Torso, slot: Body, size: [1.75, 1.5, 2.5], at: [0, 1.25, 1.125], bevel: true}
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, -0.875], mirror: x}
  - {name: MidLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, 0.75], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, 1.875], mirror: x}
  - {name: Anklet, slot: Trim, size: [0.75, 0.125, 0.75], at: [0.5, 0.1875, -0.875], mirror: x}
  - {name: MidAnklet, slot: Trim, size: [0.75, 0.125, 0.75], at: [0.5, 0.1875, 0.75], mirror: x}
  - {name: HindAnklet, slot: Trim, size: [0.75, 0.125, 0.75], at: [0.5, 0.1875, 1.875], mirror: x}
  - {name: Collar, slot: Trim, size: [2, 1.75, 0.25], at: [0, 1.25, 0.375]}
  - {name: Stripe, slot: BodyDark, size: [2, 1.75, 0.25], at: [0, 1.25, 1.875]}
  # the hero: one stepped lightning bolt standing on the back, leaning forward over the head, lit at its tip (rows top to bottom)
  - {name: Crest, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 3.625, 0.125]}
  - {name: Crest2, slot: Glow, size: [0.5, 0.25, 0.5], at: [0, 3.375, 0.25]}
  - {name: Crest3, slot: Glow, size: [0.5, 0.25, 0.5], at: [0, 3.125, 0.5]}
  - {name: Crest4, slot: Trim, size: [0.5, 0.25, 1], at: [0, 2.875, 0.75]}
  - {name: Crest5, slot: Trim, size: [0.5, 0.25, 0.5], at: [0, 2.625, 1]}
  - {name: Crest6, slot: Trim, size: [0.5, 0.25, 0.5], at: [0, 2.375, 1.25]}
  - {name: Crest7, slot: Trim, size: [0.5, 0.25, 0.75], at: [0, 2.125, 1.375]}
  # hedgehog quills down both sides of the bolt, leaning out 20 degrees
  - {name: Quill, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [0.5, 2.375, 0.375], shape: cone6, rot: [0, 0, -20], mirror: x}
  - {name: Quill2, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [0.5, 2.375, 1.125], shape: cone6, rot: [0, 0, -20], mirror: x}
  - {name: Quill3, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [0.5, 2.375, 1.875], shape: cone6, rot: [0, 0, -20], mirror: x}
  # cheek quills: two dark spikes out of each side of the head, the hedgehog's ruff
  - {name: Cheek, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1.125, 1, -1], shape: cone6, rot: [0, 0, -70], mirror: x}
  - {name: Cheek2, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1.125, 1.5, -0.75], shape: cone6, rot: [0, 0, -70], mirror: x}
  - {name: Ear, slot: BodyDark, size: [0.5, 0.625, 0.25], at: [0.625, 2.5625, -0.75], shape: cone6, mirror: x, moves: ear, pivot: [0.625, 2.25, -0.75]}
  # the flank emblem: a five-row pixel bolt in gold, proud of the torso side by an eighth
  - {name: Emblem, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 1.75, 1.375], mirror: x}
  - {name: Emblem2, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 1.5, 1.125], mirror: x}
  - {name: Emblem3, slot: Trim, size: [0.125, 0.25, 1], at: [0.9375, 1.25, 1.125], mirror: x}
  - {name: Emblem4, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 1, 1.125], mirror: x}
  - {name: Emblem5, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 0.75, 0.875], mirror: x}
  - {name: Tail, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 1.5, 2.625], moves: tail, pivot: [0, 1.5, 2.375]}
  - {name: TailTip, slot: Glow, size: [0.25, 0.5, 0.25], at: [0, 2, 2.75], moves: tail, pivot: [0, 1.5, 2.375]}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 14 rows for the 1.75-stud front. The eye's lit crescent is the storm yellow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF7AC8"
  rows:
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Thunderhog.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Thunderhog.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Thunderhog_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Thunderhog_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Thunderhog_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Thunderhog_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Thunderhog_views.png]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: three zigzag stacks read as a dark mohawk, and the gold bands merged with the flank emblem into one gold blob. Round 2: one stepped lightning bolt as the crest, lit in its top three rows, dark cone quills either side, the rear band made a dark stripe, two cheek quills a side. Round 3: the VFX preview (jagged arcs from the crest tip to two quill tips, sparks a third of a stud out, the violet light; colours read from Effects.luau). Overlap 0.995 to 0.997, 732 triangles. Wanted for: the first Verdant creature with a lit crown, readable as storm from across the meadow. Still cheap: the long violet torso is flat between the bands, the gold anklets read as sandals, and from straight ahead the crest is a thin post. Next: a lighter belly plate or groove pattern on the torso, toe caps instead of anklets, a second bolt edge so the crest reads from the front. Status review.
