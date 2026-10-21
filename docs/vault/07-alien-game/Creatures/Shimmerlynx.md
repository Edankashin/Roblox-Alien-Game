---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Shimmerlynx
name: Aurelyx
world: 2
tier: Epic
status: review
element: Aurora
height: 3.5
blocks: 49
tris: 928
bevel_width: 0.1
bevel_segments: 2
palette: ["#C8C2F0", "#4B4470", "#FFF4E6", "#8FA6C4", "#9D7CFF", "#1A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#9D7CFF", "#7CFFC4", "#FF8FD8"]
hero: AuroraC
vfx: "kept on the body (Epic, Effects.luau): a mint aurora trail waves off its crest back to its tail (the Trail from Top to Tail), violet motes rise off the crest at 4 a second (the Emitter at Top), a mint light on the crest pulses every 3 s, every 6 s it purrs in colours, a burst of twelve pink twinkles off the crest (the flourish Burst at Top), and a catchlight winks in its eyes every 5 s (the Sparkle at Eyes); the crest, the ear tufts and the tail tip glow and step through violet, mint and pink every 6 s (the glow cycle); it bobs gently; in the rig the crest ribbons wave, the ears flick, the whiskers twitch and the tail sways, and every 12 s it hops into a full turn with the crest swished"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Shimmerlynx_sheet.svg]]"
render: "[[Shimmerlynx_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.996, 0.996, 0.997]
vfx_render: "[[Shimmerlynx_vfx_cells.jpg]]"
cells_render: "[[Shimmerlynx_tq_cells.jpg]]"
idle_render: "[[Shimmerlynx_idle.png]]"
---
# Shimmerlynx (Aurelyx), Epic, World 2 Frostbyte

A lavender lynx sitting up, the Ice Cave's night Epic, 3.5 studs to its ear tufts (B45; it was 4.25: a sitting cat is as tall as its ears): a square head with a lynx's dark M of three streaks on its brow, cream whiskers that twitch, cream cheek ruffs flaring down from the jaw, tall ears with cream insides and lit tufts, and between the ears the aurora crest: five ribbons of light in a stepped skyline, the centre tallest, in violet, mint and pink. It sits on two furred haunches with its front legs straight on cream paws in silver ankle bands, a cream chest between them, dark lynx spots and a stepped aurora emblem in silver on each haunch, and its tail held straight up beside its right haunch in two dark rings, ending in a block of light. Concept row in `src/shared/data/Species.luau`: "lynx, glowing aurora crest, purrs in colours". Element: Aurora (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The one you see at night from across the cave: a curtain of aurora standing on a cat's head between its tufted ears, changing colour as it purrs, sitting the way a cat sits when it has decided you may approach. At the same height as the Rares it carries 49 blocks, much of it sixteenth-grid detail (the brow M, the whiskers, the spots, the emblem steps, the tail rings, the ankle bands), its own `starry` eyes (a pink star pupil in a mint and violet iris under violet lashes) with a cat's mouth and heart cheeks, seven moving things and a hop into a full turn every 12 s with the crest swished. Cuter and cooler, never fiercer.

**Hero block.** `AuroraC`, the centre ribbon of the crest, with two shorter ribbons each side: unique in Frostbyte.

**Moving parts (six objects and the blink).** `crest` (the five ribbons wave as one), `earR`, `earL` (they flick), `whiskerR`, `whiskerL` (they twitch), `tail` (it sways); the face plate blinks and glints.

**Alien anatomy.** The crest is an aurora it grew, not fur; its ear tufts and its tail end in light, and the tail stands straight up like a lantern it carries.

**World motif (Frostbyte).** The ice facet as steps: the crest is a stepped skyline of ribbons, the haunch emblem a stepped diagonal.

## Parts

```yaml
parts:
  # it sits: two furred haunches on cream hind paws, the upright torso with a cream chest, the head on it
  - {name: HindPaw, slot: Accessory, size: [0.625, 0.375, 0.75], at: [0.75, 0.1875, -0.1875], mirror: x}
  - {name: Haunch, slot: Body, size: [1, 1, 1.25], at: [0.75, 0.875, 0.375], bevel: true, mirror: x, material: fur}
  - {name: Torso, slot: Body, size: [1.5, 1.25, 1.25], at: [0, 1, 0.25], bevel: true, material: fur}
  - {name: Chest, slot: Accessory, size: [1, 0.75, 0.0625], at: [0, 0.875, -0.40625]}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 2, -0.375], bevel: true}
  # two straight front legs on cream paws in silver bands
  - {name: Leg, slot: Body, size: [0.375, 0.875, 0.375], at: [0.5, 0.8125, -0.8125], mirror: x}
  - {name: Paw, slot: Accessory, size: [0.5, 0.375, 0.625], at: [0.5, 0.1875, -0.875], mirror: x}
  - {name: Band, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.40625, -0.8125], mirror: x, material: metal}
  # the face: a lynx's dark M of three streaks on the brow, cream cheek ruffs flaring from the jaw, cream whiskers that twitch
  - {name: Streak, slot: BodyDark, size: [0.125, 0.375, 0.0625], at: [0, 2.5625, -1.15625]}
  - {name: Streak2, slot: BodyDark, size: [0.125, 0.25, 0.0625], at: [0.3125, 2.5, -1.15625], mirror: x}
  - {name: CheekRuff, slot: Accessory, size: [0.25, 0.5, 0.375], at: [1.0625, 1.5, -0.75], rot: [0, 0, 20], mirror: x}
  - {name: Whisker, slot: Accessory, size: [0.25, 0.0625, 0.0625], at: [1.125, 1.71875, -1.03125], mirror: x, moves: whisker, pivot: [1, 1.65625, -1.03125]}
  - {name: Whisker2, slot: Accessory, size: [0.25, 0.0625, 0.0625], at: [1.125, 1.59375, -1.03125], mirror: x, moves: whisker, pivot: [1, 1.65625, -1.03125]}
  # tall ears with cream insides and lit tufts, each one moving part
  - {name: Ear, slot: Body, size: [0.375, 0.5, 0.25], at: [0.8125, 3, -0.375], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375]}
  - {name: InnerEar, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.8125, 2.9375, -0.53125], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375]}
  - {name: EarTip, slot: Glow, size: [0.125, 0.25, 0.125], at: [0.8125, 3.375, -0.375], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375]}
  # the hero: the aurora crest between the ears, five ribbons of light in a stepped skyline, the centre tallest; they wave as one
  - {name: AuroraC, slot: Glow, size: [0.125, 0.75, 0.375], at: [0, 3.125, 0.0625], moves: crest, pivot: [0, 2.75, 0.0625]}
  - {name: Aurora2, slot: Glow, size: [0.125, 0.625, 0.375], at: [0.1875, 3.0625, 0.0625], mirror: x, moves: crest, pivot: [0, 2.75, 0.0625]}
  - {name: Aurora3, slot: Glow, size: [0.125, 0.5, 0.375], at: [0.375, 3, 0.0625], mirror: x, moves: crest, pivot: [0, 2.75, 0.0625]}
  # the tail held straight up beside its right haunch in two dark rings, ending in a block of light; one moving part
  - {name: Tail, slot: Body, size: [0.375, 1.5, 0.375], at: [1.4375, 1, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailRing, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [1.4375, 1.25, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailRing2, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [1.4375, 1.5625, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [1.4375, 1.9375, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  # lynx spots high on each haunch, and the stepped emblem under them: an aurora wave of three silver steps
  - {name: Spot, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.0625, -0.0625], mirror: x}
  - {name: Spot2, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.1875, 0.1875], mirror: x}
  - {name: Spot3, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.0625, 0.4375], mirror: x}
  - {name: Emblem, slot: Trim, size: [0.0625, 0.125, 0.25], at: [1.28125, 0.5625, -0.125], mirror: x, material: metal}
  - {name: Emblem2, slot: Trim, size: [0.0625, 0.125, 0.25], at: [1.28125, 0.6875, 0.125], mirror: x, material: metal}
  - {name: Emblem3, slot: Trim, size: [0.0625, 0.125, 0.25], at: [1.28125, 0.8125, 0.375], mirror: x, material: metal}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes, the mouth and the cheeks are on the face plate, the brow streaks proud above it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `starry`, an Epic design, a star pupil in a two-tone iris under coloured lashes, here a pink star in mint over deep violet under violet lashes, at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, five frames). A cat's mouth and heart cheeks (Epic up).

```yaml
eyes:
  key: starry
  colours: {iris: "#8FE3D0", iris2: second, pupil: "#FF8FD8", lash: glow}
  mouth: cat
  cheeks: hearts
  plate: [1.75, 0.875]
  at: [0, 1.8125]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`).

```yaml
rig:
  clips:
    crest: [{kind: sway, amp: 8, period: 3, axis: x}]
    ear: [{kind: wag, amp: 15, period: 3.4, axis: z}]
    whisker: [{kind: wag, amp: 10, period: 1.6, axis: y}]
    tail: [{kind: sway, amp: 10, period: 2.6, axis: z}]
    root: [{kind: squash, amp: 0.03, period: 2.8}]
    face: [{kind: blink, period: 5}]
  flourish:
    every: 12
    length: 2.2
    moves:
      - {part: root, kind: hop, amp: 0.3, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.4}
      - {part: crest, kind: swish, amp: 20, at: 0.3, for: 1.4}
      - {part: ear, kind: flare, amp: 20, at: 0.2, for: 0.8}
      - {part: tail, kind: swish, amp: 20, at: 0.5, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Shimmerlynx.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Shimmerlynx.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Shimmerlynx_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads; the glow parts take the three colours of the cycle in turn):

![[Shimmerlynx_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Shimmerlynx_idle.png]]

The concept sheet, drawn from the parts table above: [[Shimmerlynx_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/roster_w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: `fur` on the torso and haunches (the 2-stud head stays skin so the tufts never crowd the face), `metal` on the silver bands and the emblem, the crest, ear tufts and tail tip in glow cells, skin elsewhere.

## Reviews

- 2026-10-20, World 2 roster worker, three rounds. Round 1: standing on four legs it was Sabrek to the boxed test (0.83), so it sits: two bevelled haunches, straight front legs, the head on the chest, four masses, bevel 0.1. Round 2: the lower torso made it a wide box like Soakum (0.71) and the crest's 0.75-stud blocks behind the ears read as a pink crown, so the tail stands straight up beside the right haunch with its lit tip at shoulder height (0.68), the ribbons grew to a stud, a quarter wide and three eighths deep, and the cheek ruffs shrank. Overlap 0.989 to 0.996, 812 triangles, 38 blocks, 4.25 studs, four moving objects (the crest, the ears, the tail); three glow extremities. Wanted for: a curtain of aurora on a sitting cat, changing colour as it purrs. Still cheap: the emblem and spots sit on the haunch's outer face and the front view never sees them; the torso is mostly behind the head. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, one round. Redesigned at 3.5 studs from 4.25, not scaled: the head lowered onto the chest, the stud-tall crest became five eighth-wide ribbons in a stepped skyline between ears moved out to the head's edges (the ears now carry the lit tufts at the top of the band), the front legs straight on banded paws, the tail up beside the right haunch in two dark rings; a lynx's dark M on the brow, twitching cream whiskers, spots and the stepped emblem in sixteenth-grid cells: 49 blocks. Its own `starry` eyes (a pink star in mint over deep violet under violet lashes), a cat's mouth and heart cheeks on the plate. Rig: the crest waves, the ears flick, the whiskers twitch, the tail sways, it breathes and blinks (seven moving things), and every 12 s it hops into a full turn with the crest swished. Overlap 0.996 to 0.997, 928 triangles. Wanted for: a sitting cat with a skyline of aurora between its ears and a star in each eye. Still cheap: the cream whiskers barely read on lavender; the white-hot render washes the crest towards pink white, so its three cycle colours show only in the game's glow cycle. Status review.
