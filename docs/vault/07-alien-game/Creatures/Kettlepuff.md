---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Kettlepuff
name: Kettlet
world: 2
tier: Common
status: review
element: Steam
height: 2.5
blocks: 12
tris: 254
bevel_width: 0.1
bevel_segments: 2
palette: ["#F5EDE0", "#C8743A", "#FFB347", "#2B1F1A"]
roles: [body, second, accent, ink]
hero: Spout
vfx: "Common, one layer (Effects.luau): a Burst of three white pixel puffs rises from the Top every 4 s; the idle breathes 3 percent every 2 s; no light; the lid rattles, the handle swings, the puff and the wisp bob over the spout in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Kettlepuff_sheet.svg]]"
render: "[[Kettlepuff_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.998, 0.996, 0.995]
cells_render: "[[Kettlepuff_tq_cells.jpg]]"
idle_render: "[[Kettlepuff_idle.png]]"
---
# Kettlepuff (Kettlet), Common, World 2 Frostbyte

A cream enamel kettle with the face on its belly: a copper base ring it stands on, a copper lid with an amber knob, a copper bail handle arching over the top, a copper spout out of its right side that turns up at the tip, and a puff of steam that floats above the spout's mouth. Its mouth is a round whistle. Concept row in `src/shared/data/Species.luau`: "kettle, steam puff ring, whistles when excited". Element and effect: [[Roster-Redesign]] section 2 (a steam puff from the spout every 4 s; a whistle). Rules: [[Blocky-Style]].

**What makes a player want it.** The camp's kettle got up and walked: the one warm thing on the Geyser Field, cream and copper against the snow, whistling when it sees you. Plain on purpose: cream, copper, amber, no glow and no light.

**Hero block.** The `Spout`, copper, out of its right side and turning up at the tip with its steam puff above it: unique in Frostbyte.

**Alien anatomy.** It has no legs (it rocks on its base ring), its handle is a bone it was born with, and the steam puff is part of it: a cloud that floats above the spout and never quite blows away (the `float` part the game bobs).

**World motif (Frostbyte).** The ice facet as steps: the lid, knob and base ring step in from the body like a cut gem; the warm accent (copper in `metal` cells) is the Geyser Field's answer to the ice.

## Parts

```yaml
parts:
  # no legs: a copper base ring it rocks on
  - {name: Base, slot: BodyDark, size: [1.5, 0.25, 1.25], at: [0, 0.125, 0], material: metal}
  # the kettle is the head: cream enamel, bevelled
  - {name: Kettle, slot: Body, size: [2, 1.5, 1.75], at: [0, 1, 0], bevel: true}
  # the copper lid with an amber knob
  - {name: Lid, slot: BodyDark, size: [1.5, 0.25, 1.25], at: [0, 1.875, 0], material: metal, moves: lid, pivot: [0, 1.75, 0]}
  - {name: Knob, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0, 2.125, 0], moves: lid, pivot: [0, 1.75, 0]}
  # the bail handle: two copper posts and a bar arching over the lid
  - {name: Post, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [0.875, 2, 0], mirror: x, material: metal, moves: handle, pivot: [0, 1.75, 0]}
  - {name: Bar, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.375, 0], material: metal, moves: handle, pivot: [0, 1.75, 0]}
  # the hero: the copper spout out of the right side, its tip turned up
  - {name: Spout, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.25, 1, -0.25], material: metal}
  - {name: SpoutTip, slot: BodyDark, size: [0.375, 0.75, 0.375], at: [1.5625, 1.5, -0.25], rot: [0, 0, -20], material: metal}
  # the steam puff floating over the spout's mouth, one moving part
  - {name: Puff, slot: Body, size: [0.5, 0.5, 0.5], at: [1.75, 2.25, -0.25], shape: ico1, moves: float, pivot: [1.75, 2.25, -0.25]}
  # B46 detail: a smaller puff drifting off beside the first, and a copper foot band round the enamel over the base ring
  - {name: Wisp, slot: Body, size: [0.25, 0.25, 0.25], at: [2.25, 2.375, -0.25], shape: ico1, moves: wisp, pivot: [2.25, 2.375, -0.25]}
  - {name: Band, slot: BodyDark, size: [2.25, 0.125, 2], at: [0, 0.3125, 0], material: metal}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud kettle (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate, above the copper foot band.

```yaml
face:
  host: Kettle
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `button`, a Common design, round copper buttons with two thread holes and a shine (the iris is the copper of the lid and spout), the eyes of a toy kettle, at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, three frames). Its mouth is the round whistle, `o`, and blush cheeks. The only `button` in Frostbyte.

```yaml
eyes:
  key: button
  colours: {iris: second}
  mouth: o
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the lid with its knob rattles (a quick lift and a burst of tilt every 4 s, the steam's beat), the bail handle swings, the puff bobs and circles over the spout while the smaller wisp rises and swells half a beat behind it, the kettle rocks on its base ring and the face blinks. Five moving things (four objects, the Common cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    lid: [{kind: bob, amp: 0.04, period: 0.5}, {kind: wag, amp: 6, period: 4, axis: z}]
    handle: [{kind: sway, amp: 15, period: 2.4, axis: x}]
    float: [{kind: bob, amp: 0.1, period: 2}, {kind: orbit, amp: 0.08, period: 4}]
    wisp: [{kind: bob, amp: 0.15, period: 2.6, phase: 0.5}, {kind: pulse, amp: 0.2, period: 2.6}]
    root: [{kind: sway, amp: 3, period: 3, axis: z}]
    face: [{kind: blink, period: 4}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Kettlepuff.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Kettlepuff.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Kettlepuff_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Kettlepuff_idle.png]]

The concept sheet, drawn from the parts table above: [[Kettlepuff_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 20 cells tall. Materials: `metal` on every copper part (panels, a seam, a rivet in each panel's corner: base, lid, handle, spout), skin on the cream enamel, the amber knob and the steam puff.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: the handle's posts ran a quarter stud up into the bar and the merged copper mesh's recalculated normals turned both ends inside out, black in the lit view and invisible in the flat orthographic views (0.998), so the posts now end where the bar begins (a lesson in [[Blocky-Style]]). Overlap 0.996 to 0.998, 208 triangles, 10 blocks, 2.5 studs, one moving object (the steam puff). Wanted for: the camp's kettle, cream and copper on the snow, whistling. Still cheap: the puff is one white icosahedron; the spout's turn is a single tilted block. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), two rounds. Round 1: the house face became the library's `button` with the accent amber iris; the amber squares with their two holes read as dice, so round 2 took the iris to the copper of the lid and spout, which reads as sewn-on toy buttons. The round whistle is the `o` mouth. A smaller `Wisp` puff drifts beside the first (above it, it took the height to 2.75 and the legs to 9 percent, so it stays beside), and a copper foot `Band` rings the enamel over the base. Rig: the lid and knob rattle on the steam's 4 s beat, the bail `handle` swings, the puff bobs and circles, the wisp swells half a beat behind, the kettle rocks 3 degrees and blinks. Five moving things (four objects, the Common cap, and the blink). Height 2.5 (in band, unchanged), 12 blocks, 254 triangles, overlap 0.995 to 0.998. Wanted for: the camp's kettle got up and walked, button-eyed and rattling its lid. Still weak: the button eyes are a toy's and less alive than the other Commons', and the white puffs vanish on a pale backdrop (the Effects puffs carry the steam in the game). Status review.
