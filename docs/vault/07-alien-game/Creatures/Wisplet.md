---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Wisplet
name: Wispkin
world: 1
tier: Rare
status: review
element: Shadow
height: 3.49
blocks: 71
tris: 950
bevel_width: 0.1
bevel_segments: 2
palette: ["#8FDCFF", "#2D5C9E", "#7B5CFF", "#6E6A85", "#9466FF", "#141B33"]
roles: [body, second, accent, trim, glow, ink]
hero: Bail
vfx: "a soft light (Rare): Effects.luau's cold blue Light (9BE7FF, brightness 1.2, range 2.6) on the Body pulsing every 1.4 s, a faint wisp mote of the same blue rising off the Body at 0.7 a second, and a lilac Sparkle (C9A8FF) at the Top every 2.5 s; a Hover idle of 0.5 studs over 2.8 s. On the model the flame tip, the tongue tip and the flamelet tips are lilac glow cells. The rig adds the motion and the flourish: the tip flickers, the tongue licks, the bail swings, the flamelets bob and circle, and every 9 s it ducks, hops and spins with the bail swishing"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Wisplet_sheet.svg]]"
render: "[[Wisplet_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.994, 1, 0.996]
vfx_render: "[[Wisplet_vfx_cells.jpg]]"
cells_render: "[[Wisplet_tq_cells.jpg]]"
idle_render: "[[Wisplet_idle.png]]"
bar_world: Verdant
bar_kit: 3
bar_pieces: [moss_cells, vine_wrap]
bar_stance: "a drift: the flame leaning 14 degrees to its right with its tongue licking the other way, the trail swept out to its left, the lantern glass and little lanterns circling"
bar_satellites: 6
bar_orbit: glass
---
# Wisplet (Wispkin), Rare, World 1 Verdant, the Haunted Nebula event

A will-o'-the-wisp, 3.5 studs to the tip of its flame: a cold blue flame the size of a lantern, floating a little off the grass with a shy face on its belly. The belly is a soft sky-blue block in flame cells (the lit tongues of the `ember` motif rising from its base), the flame narrows above it in three steps that lean to its right and end in a lilac-lit tip that flickers, with a second tongue licking up to the left with its own lit tip, and tapers below it through two deep-blue steps swept to the left to a wisp of flame that brushes the ground. Round its waist sits a lantern's iron rim with two rivets and four iron corner struts rising from it up the belly's corners, the bottom of the cage it escaped, all that is left of the glass; an iron bail handle, hinged to pins on the belly's sides with a hanging ring at its top, arches over the flame. Two small flamelets with lit tips float beside it at different heights, and a violet flame glyph of four steps is stamped on its right flank. Concept row in `src/shared/data/Species.luau`: "will-o'-the-wisp, a floating lantern flame with a shy face". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`: two weeks from 2026-10-16, World 1, nights twice as long, a Spectral overlay). Element and effect: [[Roster-Redesign]] section 2 (Shadow; a cold blue flame that flickers, one faint ember rising, a soft blue light; `Effects.luau` calls the element Spirit). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the night's own light in the two weeks of the event: a blue flame that drifts over the meadow at dusk, shy when you get near, and the first Rare that is itself a light rather than carrying one. B46: its own `crescent` eyes (a violet band of iris under an ink drop over a lilac-lit crescent, two glint frames), 31 blocks to the Uncommons' 16 to 19, six moving things, and a flourish every 9 s that reads from across the meadow: it ducks, hops and spins round once while the bail swishes and the tip flares. The Rare rung exactly: a stamped element glyph, one glossy trim slot (the iron bail and rim), a soft light, four flat colours and lilac glow at the tips.

**Hero block.** The `Bail`, a lantern's iron handle arched over a flame with no lantern, hinged to pins on the belly, unique in Verdant (Lantrin's lamp is a caged ball on a tail; Gaira's nimbus is a closed ring behind its head).

**Moving parts (five objects and the blink).** `halo` (the bail and its ring swing), `floatR` and `floatL` (the flamelets bob and circle), `tip` (the lit tip flickers), `tongue` (the left tongue licks); the plate blinks and glints. Rare pass w1: `glass` (the lantern's lost glass, four lit panes under iron bars on one slow orbit: it turns, bobs and leaps) makes six objects and the blink.

**Alien anatomy.** A flame with a face that carries its own lantern handle and sheds flamelets that float beside it.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the flame above and below the belly.

**Event palette (Haunted Nebula).** Sky blue over deep blue, with the event's violet as the accent and a lilac glow: the cold end of the event's purple-and-orange range (Grin carries the warm end, Cosmoo the deep violet).

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`wisplet()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A will-o'-the-wisp that lives in a lantern's cage, drifting at dusk: the night's own light. Kept: name, anatomy (a flame with a face on its belly, an iron cage, a bail with no lantern), the lilac tip, height 3.49.
- **Gains (visible parts).** (1) Six satellites on a wide low ring (the `glass` object, replacing the four old panes, so the Effects pieces `Glass` and `GlassB` still hang on it): three iron-framed panes of the lantern's lost glass and three little hanging lanterns, all lit lilac, three quarters of a stud and more. (2) Verdant kit: violet moss pads with a lit tuft on the cage's top corners, a violet vine up the belly's sides and back. (3) The stance below.
- **Stance (rest groups `flame`, `trail`).** A drift: the flame (its two steps, the lit tip and the licking tongue) leans 14 degrees to its right, and the tapering trail is swept 35 degrees out behind it: the outline is a leaning flame with a tail, not a lantern standing on a plinth. The belly (and its face) stays square to the camera.
- **Face intent.** Its own `crescent` eyes kept (a violet iris band under an ink drop over a lilac-lit crescent, two glint frames), a small shy smile and blush cheeks: a shy light that peeks out. The face is not changed; it is the brightest-contrast spot of the pale belly and nothing crosses it.
- **Three values (rule 8).** Body pale blue; the trail, rim and struts a step darker (deep blue and iron grey); the lit lilac (moss tufts, panes, lanterns) one colour and not the body's. No backdrop (a Rare has none).
- **Must-nots.** No flame satellites (the first try, a flame on a deep-blue base, read as a cupcake: replaced by hanging lanterns); nothing over the face; no piece under a quarter stud added for its own sake; height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # the belly of the flame: a soft sky-blue block in flame cells, the face on its front; a lantern's iron rim round its waist, two rivets
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.5, 0], bevel: true, material: ember}
  - {name: Rim, slot: Trim, size: [2.25, 0.125, 1.75], at: [0, 0.8125, 0], material: metal}
  - {name: Rivet, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.6875, 0.8125, -0.9375], mirror: x}
  # Polish w1: the rim alone read as a belt; four iron corner struts rise from it up the belly's corners to the bail's pins, so rim and
  # struts read as the bottom of a lantern's cage with the flame living in it
  - {name: Strut, slot: Trim, size: [0.125, 0.75, 0.125], at: [1.0625, 1.25, -0.8125], mirror: x, material: metal}
  - {name: StrutBack, slot: Trim, size: [0.125, 0.75, 0.125], at: [1.0625, 1.25, 0.8125], mirror: x, material: metal}
  # the flame narrows above the belly in three steps leaning to its right, the top one lit with a flickering tip, and a second tongue
  # licks up to the left with its own lit tip
  - {name: Flame, slot: Body, size: [1.5, 0.375, 1], at: [0.125, 2.4375, 0], material: ember, pose: flame}
  - {name: Flame2, slot: Body, size: [1, 0.375, 0.75], at: [0.375, 2.8125, 0], material: ember, pose: flame}
  - {name: Flame3, slot: Glow, size: [0.5, 0.25, 0.5], at: [0.5, 3.125, 0], moves: tip, pivot: [0.5, 3, 0], pose: flame}
  - {name: Tip, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.625, 3.375, 0], moves: tip, pivot: [0.5, 3, 0], pose: flame}
  - {name: FlameL, slot: Body, size: [0.5, 0.625, 0.5], at: [-0.6875, 2.75, 0], rot: [0, 0, 20], material: ember, moves: tongue, pivot: [-0.5625, 2.4375, 0], pose: flame}
  - {name: TongueTip, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.8125, 3.1875, 0], rot: [0, 0, 20], moves: tongue, pivot: [-0.5625, 2.4375, 0], pose: flame}
  # and tapers below it through two deep-blue steps to a wisp that brushes the grass
  - {name: Base, slot: Body, size: [1.5, 0.375, 1], at: [0, 0.5625, 0], material: ember}
  - {name: Base2, slot: BodyDark, size: [1, 0.25, 0.75], at: [-0.375, 0.25, 0.125], material: ember, pose: trail}
  - {name: Trail, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [-0.75, 0.0625, 0.25], material: ember, pose: trail}
  # the hero: a lantern's iron bail, a quarter stud thick so it reads across the meadow, hinged to a pin on each side of the belly and
  # stepping up behind the flame to a bar over its tip with a hanging ring (it swings)
  - {name: BailPin, slot: Trim, size: [0.5, 0.25, 0.25], at: [1.25, 1.5, 0.75], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail, slot: Trim, size: [0.25, 0.75, 0.25], at: [1.375, 2, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail2, slot: Trim, size: [0.75, 0.25, 0.25], at: [1, 2.5, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail3, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.625, 2.75, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: BailTop, slot: Trim, size: [1.5, 0.25, 0.25], at: [0, 3, 0.875], material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: BailRing, slot: Trim, size: [0.25, 0.25, 0.25], at: [0, 3.25, 0.875], material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  # two flamelets floating beside the belly at different heights, leaning out 15 degrees, each with a lit tip (each one moving part)
  - {name: Wisp, slot: Body, size: [0.375, 0.5, 0.375], at: [1.4375, 1.9375, 0.4375], rot: [0, 0, -15], material: ember, moves: float, pivot: [1.4375, 1.9375, 0.4375]}
  - {name: WispTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.5, 2.25, 0.4375], rot: [0, 0, -15], moves: float, pivot: [1.4375, 1.9375, 0.4375]}
  - {name: WispL, slot: Body, size: [0.375, 0.5, 0.375], at: [-1.4375, 0.9375, 0.4375], rot: [0, 0, 15], material: ember, moves: float, pivot: [-1.4375, 0.9375, 0.4375]}
  - {name: WispTipL, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.5, 1.25, 0.4375], rot: [0, 0, 15], moves: float, pivot: [-1.4375, 0.9375, 0.4375]}
  # the stamped element glyph: a violet flame of four steps on the right flank, proud by an eighth
  - {name: Glyph, slot: Accessory, size: [0.125, 0.125, 0.5], at: [1.0625, 1.0625, 0.25]}
  - {name: Glyph2, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1.25, 0.25]}
  - {name: Glyph3, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 1.4375, 0.1875]}
  - {name: Glyph4, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 1.5625, 0.0625]}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: violet moss pads with a lit tuft on the cage's top corners, either side of the flame's root
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.75, 2.3125, 0.25], mirror: x, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [0.8125, 2.4375, 0.25], mirror: x, material: moss}
  - {name: Mossc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 2.5625, 0.1875], mirror: x, material: moss}
  # a violet vine winding up the belly's sides and back in three strips (the face stays clear)
  - {name: Vine0, slot: Accessory, size: [0.125, 0.5, 1.75], at: [1.0625, 1, 0], material: moss}
  - {name: Vine1, slot: Accessory, size: [2.25, 0.5, 0.125], at: [0, 1.5, 0.8125], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.125, 0.5, 1.75], at: [-1.0625, 2, 0], material: moss}
  # the satellite set (`glass`, one wide ring clear of the bail and the wisps, the front low): three iron-framed panes of the lantern's lost glass and three little hanging lanterns, all lit lilac
  - {name: Sat0a, slot: Trim, size: [0.75, 0.125, 0.25], at: [1.25, 1.5625, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat0b, slot: Trim, size: [0.75, 0.125, 0.25], at: [1.25, 0.8125, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat0c, slot: Trim, size: [0.125, 0.625, 0.25], at: [0.9375, 1.1875, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat0d, slot: Trim, size: [0.125, 0.625, 0.25], at: [1.5625, 1.1875, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat0e, slot: Glow, size: [0.5, 0.625, 0.25], at: [1.25, 1.1875, -2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat1a, slot: Trim, size: [0.25, 0.125, 0.25], at: [2.375, 2.3125, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat1b, slot: Trim, size: [0.5, 0.125, 0.25], at: [2.375, 2.1875, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat1c, slot: Glow, size: [0.5, 0.625, 0.25], at: [2.375, 1.8125, 0], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat1d, slot: Glow, size: [0.75, 0.375, 0.25], at: [2.375, 1.8125, 0], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat2a, slot: Trim, size: [0.75, 0.125, 0.25], at: [1.25, 2.8125, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat2b, slot: Trim, size: [0.75, 0.125, 0.25], at: [1.25, 2.0625, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat2c, slot: Trim, size: [0.125, 0.625, 0.25], at: [1.5625, 2.4375, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat2d, slot: Trim, size: [0.125, 0.625, 0.25], at: [0.9375, 2.4375, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat2e, slot: Glow, size: [0.5, 0.625, 0.25], at: [1.25, 2.4375, 2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat3a, slot: Trim, size: [0.25, 0.125, 0.25], at: [-1.25, 2.5625, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat3b, slot: Trim, size: [0.5, 0.125, 0.25], at: [-1.25, 2.4375, 2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat3c, slot: Glow, size: [0.5, 0.625, 0.25], at: [-1.25, 2.0625, 2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat3d, slot: Glow, size: [0.75, 0.375, 0.25], at: [-1.25, 2.0625, 2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat4a, slot: Trim, size: [0.75, 0.125, 0.25], at: [-2.375, 1.9375, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat4b, slot: Trim, size: [0.75, 0.125, 0.25], at: [-2.375, 1.1875, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat4c, slot: Trim, size: [0.125, 0.625, 0.25], at: [-2.6875, 1.5625, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat4d, slot: Trim, size: [0.125, 0.625, 0.25], at: [-2.0625, 1.5625, 0], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat4e, slot: Glow, size: [0.5, 0.625, 0.25], at: [-2.375, 1.5625, 0], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat5a, slot: Trim, size: [0.25, 0.125, 0.25], at: [-1.25, 1.4375, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat5b, slot: Trim, size: [0.5, 0.125, 0.25], at: [-1.25, 1.3125, -2.125], moves: glass, pivot: [0, 1.875, 0], material: metal}
  - {name: Sat5c, slot: Glow, size: [0.5, 0.625, 0.25], at: [-1.25, 0.9375, -2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  - {name: Sat5d, slot: Glow, size: [0.75, 0.375, 0.25], at: [-1.25, 0.9375, -2.125], moves: glass, pivot: [0, 1.875, 0], material: crystal}
  # pilot bar: end
```

## Face

The belly's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud block, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `crescent`, a Rare design, an ink drop over a band of violet iris (the event accent) and a lit lilac crescent (the glow: a pale blue crescent on a blue face would read as tears), with two glint frames. At 16 pixels a stud on a 1.75 x 1.125 stud plate (28 x 18 pixels, five frames). A small shy smile and blush cheeks. In World 1 only Wispkin wears `crescent` in these colours.

```yaml
eyes:
  key: crescent
  colours: {iris: accent, glint: glow}
  mouth: smile
  cheeks: blush
  plate: [1.75, 1.125]
  at: [0, 1.4375]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them and calls `SpeciesFx.Flourish` on each flourish): the lit tip flickers (a quick sway and pulse), the left tongue licks, the bail swings with the hover, the flamelets bob and circle, the flame wobbles, the face blinks. Five objects and the blink (a Rare needs four). The flourish, every 9 s: it ducks and hops, spins round once, the bail swishes, the tip flares and the flamelets leap.

```yaml
rig:
  rest:
    flame: {rot: [0, 0, -14], pivot: [0, 2.25, 0]}
    trail: {rot: [0, 35, 0], pivot: [0, 0.5, 0]}
  clips:
    tip: [{kind: sway, amp: 10, period: 0.9, axis: z}, {kind: pulse, amp: 0.15, period: 0.7}]
    tongue: [{kind: sway, amp: 12, period: 1.1, axis: z, phase: 0.4}]
    halo: [{kind: sway, amp: 8, period: 2.8, axis: x}]
    float: [{kind: bob, amp: 0.15, period: 2.2}, {kind: orbit, amp: 0.1, period: 4.4}]
    glass: [{kind: spin, amp: 360, period: 11, axis: y}, {kind: bob, amp: 0.08, period: 2.9, phase: 0.3}, {kind: sway, amp: 5, period: 4.7, axis: x}]
    root: [{kind: squash, amp: 0.06, period: 1.4}]
    face: [{kind: blink, period: 3.4}]
  flourish:
    every: 9
    length: 2.4
    moves:
      - {part: root, kind: squash, amp: 0.12, at: 0, for: 0.4}
      - {part: root, kind: hop, amp: 0.5, at: 0.3, for: 0.9}
      - {part: glass, kind: hop, amp: 0.3, at: 0.3, for: 1}
      - {part: root, kind: turn, amp: 360, at: 0.4, for: 1.4}
      - {part: glass, kind: turn, amp: -360, axis: y, at: 0.4, for: 1.6}
      - {part: halo, kind: swish, amp: 20, at: 0.4, for: 1.2}
      - {part: tip, kind: pop, amp: 0.3, at: 0.7, for: 0.8}
      - {part: float, kind: hop, amp: 0.3, at: 0.9, for: 1}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Glass | `Sat0a` (glass) | 0.00, 0.71, -0.48 | a lilac sparkle on each pane in turn, a soft light | Body |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Wisplet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Wisplet.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Wisplet_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Wisplet_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Wisplet_idle.png]]

The concept sheet, drawn from the parts table above: [[Wisplet_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Wisplet_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 26 cells tall; one atlas of 512 x 512 at 8 texels a cell (123 islands). Materials: `ember` on the belly, the flame steps, the base steps, the trail and the flamelets (lit tongues rising from each block's bottom edge with a ragged crest, a white spark cell above them now and then), metal on the bail (glossy), skin on the glyph; the tip is glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, two rounds. Round 1: a belly block with a three-step flame leaning right, a thin bail and two flamelets by the base: it built and read as a flame, but the boxed silhouette sat at 0.74 against Moop (a block with a sprout on top and a spore beside it), and an eighth-stud bail vanished at distance. Round 2: a second tongue licking up to the left, the flamelets moved wide of the belly at different heights, the bail a quarter stud thick and widened past its pins, the base steps swept left: 0.64 at worst (Syrinx). Overlap 0.996 to 0.997, 342 triangles, 22 blocks, 3.25 studs (the Rare cap). Wanted for: the night's own light in the event's two weeks. Still cheap: the ember tongues are subtle on the pale body in daylight (the VFX preview's cold light brings them up); the bail is half hidden behind the flame from the three-quarter view. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band (3.5 studs to its flickering tip, from 3.25); detail at the same size with smaller blocks, 31 blocks to the Uncommons' 16 to 19 (the Rare band is 18 to 36): a lit tip on the flame and on the left tongue, lit tips on both flamelets, a hanging ring on the bail, a fourth step on the glyph, and a lantern's iron rim with two rivets round its waist, all that is left of the glass it escaped. Its own `crescent` eyes: an ink drop over a violet band and a lilac-lit crescent, two glint frames, a shy smile and blush. Five moving objects and the blink: the tip flickers, the tongue licks, the bail swings, the flamelets bob and circle; and every 9 s a flourish that reads from across the meadow: it ducks, hops and spins round once while the bail swishes, the tip flares and the flamelets leap. Overlap 0.995 to 1.0, 448 triangles; worst silhouette pair 0.672 (Cosmoo). Wanted for: the event's shy blue flame, now visibly a step above the Uncommons in cells, light and motion. Still weak: the iron rim reads as a belt or a saucer under the belly more than as a lantern's rim, and the lilac tips are pale on the sky-blue flame in daylight (the VFX preview's dusk is where it shines). Status review.
- 2026-10-21, Polish w1, one round. The iron rim round the waist read as a belt: four iron corner struts now rise from it up the belly's corners toward the bail's pins (an eighth proud of each corner, three quarters of a stud tall), so the rim reads as the bottom of a lantern's cage with the flame still in it, and the bail above finishes the lantern. 35 blocks (Rare 18 to 36). Overlap 0.995 to 1.000. Honest read: a lantern at once, the flame living in its broken cage; the struts frame the face without crossing it. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: the lantern's lost glass, four lit violet panes, each under an iron bar, drifting round the flame at four heights on one slow orbit (11 s a turn; on the flourish they leap and spin the other way); the glow is a deeper violet `#9466FF`. 43 blocks, seven moving things. Honest read: the escaped flame with its lantern's glass circling it tells the story at a glance; the panes read pale lilac in daylight and come into their own at night. Status review.
