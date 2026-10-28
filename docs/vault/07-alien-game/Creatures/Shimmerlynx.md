---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Shimmerlynx
name: Aurelyx
world: 2
tier: Epic
status: review
element: Aurora
height: 3.42
blocks: 105
tris: 1638
bevel_width: 0.1
bevel_segments: 2
palette: ["#9B97C9", "#4B4470", "#FFF4E6", "#B4C4DC", "#9D7CFF", "#1A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#9D7CFF", "#7CFFC4", "#FF8FD8"]
hero: AuroraC
fx_hooks: {Top: AuroraC, Tail: PlumeC, Eyes: Gem, Plume: PlumeC, Halo: Mote}
vfx: "kept on the body (Epic, Effects.luau): a mint aurora trail waves off its crest back to its tail (the Trail from Top to Tail), violet motes rise off the crest at 4 a second (the Emitter at Top), a mint light on the crest pulses every 3 s, every 6 s it purrs in colours, a burst of twelve pink twinkles off the crest (the flourish Burst at Top), and a catchlight winks in its eyes every 5 s (the Sparkle at Eyes); the crest, the ear tufts and the tail tip glow and step through violet, mint and pink every 6 s (the glow cycle); it bobs gently; in the rig the crest ribbons wave, the ears flick, the whiskers twitch and the tail sways, and every 12 s it hops into a full turn with the crest swished"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Shimmerlynx_sheet.svg]]"
render: "[[Shimmerlynx_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.996, 0.996, 0.997]
vfx_render: "[[Shimmerlynx_vfx_cells.jpg]]"
cells_render: "[[Shimmerlynx_tq_cells.jpg]]"
idle_render: "[[Shimmerlynx_idle.png]]"
bar_world: Frostbyte
bar_kit: 6
bar_pieces: [ice_shard, silver_band, snowflake_stud]
bar_stance: "a cat that has decided you may approach: the head turned 14 degrees and rolled 6, the right paw reaching toward you 55 degrees, the tail up, a ring of six outlined violet stars round it"
bar_satellites: 6
bar_orbit: sparks
---
# Shimmerlynx (Aurelyx), Epic, World 2 Frostbyte

A lilac-grey lynx sitting up, the Ice Cave's night Epic, 3.5 studs to its ear tufts (B45; it was 4.25: a sitting cat is as tall as its ears): a square head with a lynx's dark M of three streaks on its brow, dark indigo whiskers, three a side fanned out past its cheeks, that twitch, cream cheek ruffs flaring down from the jaw, tall ears with cream insides and lit tufts, and between the ears the aurora crest: five ribbons of light in a stepped skyline, the centre tallest, in violet, mint and pink. It sits on two furred haunches with its front legs straight on cream paws above silver cuffs (the right one reaching out toward you), a cream chest between them, dark lynx spots and a silver snowflake stud on each haunch with a dark ice shard standing on top, and its tail held straight up beside its right haunch in two dark rings, ending in a block of light; a ring of six outlined violet stars round it, the star in its eyes grown. Concept row in `src/shared/data/Species.luau`: "lynx, glowing aurora crest, purrs in colours". Element: Aurora (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The one you see at night from across the cave: a curtain of aurora standing on a cat's head between its tufted ears, changing colour as it purrs, sitting the way a cat sits when it has decided you may approach. At the same height as the Rares it carries 49 blocks, much of it sixteenth-grid detail (the brow M, the whiskers, the spots, the emblem steps, the tail rings, the ankle bands), its own `starry` eyes (a pink star pupil in a mint and violet iris under violet lashes) with a cat's mouth and heart cheeks, seven moving things and a hop into a full turn every 12 s with the crest swished. Cuter and cooler, never fiercer.

**Hero block.** `AuroraC`, the centre ribbon of the crest, with two shorter ribbons each side: unique in Frostbyte.

**Moving parts (eight objects and the blink).** `crest` (the five ribbons wave as one), `earR`, `earL` (they flick), `whiskerR`, `whiskerL` (they twitch), `tail` (it sways, the aurora plume with it), `mote` (two aurora motes circle the crest), `pendant` (the gem on the collar swings); the face plate blinks and glints.

**Alien anatomy.** The crest is an aurora it grew, not fur; its ear tufts and its tail end in light, and the tail stands straight up like a lantern it carries.

**World motif (Frostbyte).** The ice facet as steps: the crest is a stepped skyline of ribbons, the haunch emblem a stepped diagonal.

## Character bar (B54), prompt list

BAR-W2, 2026-10-28 ([[Blocky-Style]] section 10, [[Character-References]]; the plan is `tools/blocky/bar_w2.py` `shimmerlynx()`).

- **Theme.** The night cat: an aurora lynx that has decided you may approach, with the star from its eyes orbiting it.
- **Parts gained.** (1) Six four-point stars (a lit cross, an eighth proud, over a dark indigo outline a sixteenth wider; 0.75 across) on a ring in two rows of three, back higher, nothing in front of the face (one lit colour, the crest's violet). (2) Six kit pieces: silver snowflake studs on the haunches (they replace the stepped emblem), silver cuffs a quarter stud tall on the front legs (they replace the thin ankle bands), dark ice shards on the haunches' tops. (3) The aurora crest and the tail plume stay as the shaped energy.
- **Value and colour (rule 8).** The body is a mid lilac-grey (`#9B97C9`, L* 63; was `#C8C2F0`, L* 80, a pale cat on white snow), the second a dark indigo (L* 31), the cream chest and paws the light step, the silver a pale blue-grey (`#B4C4DC`) so it reads on the body and on the cream paws; the stars carry a dark outline so the lit cross has an edge on snow.
- **Stance.** The head turned 14 degrees and rolled 6, set 0.15 lower on its shoulders so the ear tufts stay at the height limit (`rig.rest.head`, with the crest, ears, whiskers and motes); the right paw reaching out toward you 55 degrees about the shoulder (`rig.rest.reach`, with its cuff); the tail stays up. The star ring sways 22 degrees about it.
- **Face intent.** Unchanged: the `starry` eyes (a pink star in mint over deep violet under violet lashes), a cat's mouth and heart cheeks: a cat that has decided you may approach. The turn makes it look like it is looking you over.
- **Must-nots.** No star in front of the face; no pale shard or ring on snow (the shards are the dark indigo); no second lit colour; no fangs.

## Parts

```yaml
parts:
  # it sits: two furred haunches on cream hind paws, the upright torso with a cream chest, the head on it
  - {name: HindPaw, slot: Accessory, size: [0.625, 0.375, 0.75], at: [0.75, 0.1875, -0.1875], mirror: x}
  - {name: Haunch, slot: Body, size: [1, 1, 1.25], at: [0.75, 0.875, 0.375], bevel: true, mirror: x, material: fur}
  - {name: Torso, slot: Body, size: [1.5, 1.25, 1.25], at: [0, 1, 0.25], bevel: true, material: fur}
  - {name: Chest, slot: Accessory, size: [1, 0.75, 0.0625], at: [0, 0.875, -0.40625]}
  # a silver collar under the chin and a pendant on it, a lit aurora gem in a silver bezel that swings (Rare pass w2: chest detail)
  - {name: Collar, slot: Trim, size: [1.25, 0.125, 0.0625], at: [0, 1.1875, -0.46875], material: metal}
  - {name: Bezel, slot: Trim, size: [0.25, 0.25, 0.0625], at: [0, 1, -0.53125], material: metal, moves: pendant, pivot: [0, 1.125, -0.53125]}
  - {name: Gem, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0, 1, -0.59375], moves: pendant, pivot: [0, 1.125, -0.53125]}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 2, -0.375], bevel: true, pose: head}
  # two straight front legs on cream paws (the silver cuffs are the kit's, below); the right one reaches out toward you (a rest pose)
  - {name: LegL, slot: Body, size: [0.375, 0.875, 0.375], at: [-0.5, 0.8125, -0.8125]}
  - {name: LegR, slot: Body, size: [0.375, 0.875, 0.375], at: [0.5, 0.8125, -0.8125], pose: reach}
  - {name: PawL, slot: Accessory, size: [0.5, 0.375, 0.625], at: [-0.5, 0.1875, -0.875]}
  - {name: PawR, slot: Accessory, size: [0.5, 0.375, 0.625], at: [0.5, 0.1875, -0.875], pose: reach}
  # the face: a lynx's dark M of three streaks on the brow, cream cheek ruffs flaring from the jaw
  - {name: Streak, slot: BodyDark, size: [0.125, 0.375, 0.0625], at: [0, 2.5625, -1.15625], pose: head}
  - {name: Streak2, slot: BodyDark, size: [0.125, 0.25, 0.0625], at: [0.3125, 2.5, -1.15625], mirror: x, pose: head}
  - {name: CheekRuff, slot: Accessory, size: [0.25, 0.5, 0.375], at: [1.0625, 1.5, -0.75], rot: [0, 0, 20], mirror: x, pose: head}
  # whiskers: three a side in the dark indigo, half a stud long and fanned 15 degrees (two short cream ones on the lavender barely read)
  - {name: Whisker, slot: BodyDark, size: [0.5, 0.0625, 0.0625], at: [1.25, 1.65625, -1.03125], mirror: x, moves: whisker, pivot: [1, 1.65625, -1.03125], pose: head}
  - {name: Whisker2, slot: BodyDark, size: [0.5, 0.0625, 0.0625], at: [1.25, 1.8125, -1.03125], rot: [0, 0, 15], mirror: x, moves: whisker, pivot: [1, 1.65625, -1.03125], pose: head}
  - {name: Whisker3, slot: BodyDark, size: [0.5, 0.0625, 0.0625], at: [1.25, 1.5, -1.03125], rot: [0, 0, -15], mirror: x, moves: whisker, pivot: [1, 1.65625, -1.03125], pose: head}
  # tall ears with cream insides and lit tufts, each one moving part
  - {name: Ear, slot: Body, size: [0.375, 0.5, 0.25], at: [0.8125, 3, -0.375], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375], pose: head}
  - {name: InnerEar, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.8125, 2.9375, -0.53125], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375], pose: head}
  - {name: EarTip, slot: Glow, size: [0.125, 0.25, 0.125], at: [0.8125, 3.375, -0.375], mirror: x, moves: ear, pivot: [0.8125, 2.75, -0.375], pose: head}
  # the hero: the aurora crest between the ears, five ribbons of light in a stepped skyline, the centre tallest; they wave as one
  - {name: AuroraC, slot: Glow, size: [0.125, 0.75, 0.375], at: [0, 3.125, 0.0625], moves: crest, pivot: [0, 2.75, 0.0625], pose: head}
  - {name: Aurora2, slot: Glow, size: [0.125, 0.625, 0.375], at: [0.1875, 3.0625, 0.0625], mirror: x, moves: crest, pivot: [0, 2.75, 0.0625], pose: head}
  - {name: Aurora3, slot: Glow, size: [0.125, 0.5, 0.375], at: [0.375, 3, 0.0625], mirror: x, moves: crest, pivot: [0, 2.75, 0.0625], pose: head}
  # two aurora motes circling the crest (Rare pass w2), one high and one low, turning about the crest once every 5 s
  - {name: Mote, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5625, 3.25, 0.0625], moves: mote, pivot: [0, 3, 0.0625], pose: head}
  - {name: Mote2, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.5625, 2.9375, 0.0625], moves: mote, pivot: [0, 3, 0.0625], pose: head}
  # the tail held straight up beside its right haunch in two dark rings, ending in a block of light; one moving part
  - {name: Tail, slot: Body, size: [0.375, 1.5, 0.375], at: [1.4375, 1, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailRing, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [1.4375, 1.25, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailRing2, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [1.4375, 1.5625, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: TailTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [1.4375, 1.9375, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  # the aurora plume (Rare pass w2): three ribbons of light fanning up out of the tail's lit tip like a comet's tail, the middle tallest; they
  # step through violet, mint and pink with the crest, so the cat carries a second aurora on its tail
  - {name: PlumeC, slot: Glow, size: [0.125, 0.625, 0.25], at: [1.4375, 2.4375, 0.875], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: Plume2, slot: Glow, size: [0.125, 0.5, 0.25], at: [1.59375, 2.34375, 0.875], rot: [0, 0, -20], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  - {name: Plume3, slot: Glow, size: [0.125, 0.5, 0.25], at: [1.28125, 2.34375, 0.875], rot: [0, 0, 20], moves: tail, pivot: [1.4375, 0.25, 0.875]}
  # lynx spots high on each haunch (the stepped silver emblem under them is replaced by the kit's snowflake studs)
  - {name: Spot, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.0625, -0.0625], mirror: x}
  - {name: Spot2, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.1875, 0.1875], mirror: x}
  - {name: Spot3, slot: BodyDark, size: [0.0625, 0.125, 0.125], at: [1.28125, 1.0625, 0.4375], mirror: x}
  # pilot bar: begin (tools/blocky/bar_w2.py writes this region: the Frostbyte kit, the cuffs and the star ring)
  # the Frostbyte kit: a silver snowflake stud (a plus of sixteenth-stud bars with a lit heart) on each haunch, where the stepped emblem was
  - {name: Flakea, slot: Trim, size: [0.125, 0.125, 0.5], at: [1.3125, 0.8125, 0.25], mirror: x, material: metal}
  - {name: Flakeb, slot: Trim, size: [0.125, 0.5, 0.125], at: [1.3125, 0.75, 0.3125], mirror: x, material: metal}
  - {name: Flakec, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.4375, 0.8125, 0.3125], mirror: x, material: crystal}
  # silver cuffs: a band a quarter stud tall and an eighth proud round each front leg above the paw (the right one reaches with its leg)
  - {name: CuffLF, slot: Trim, size: [0.625, 0.25, 0.125], at: [-0.5, 0.5, -1.0625], material: metal}
  - {name: CuffLB, slot: Trim, size: [0.625, 0.25, 0.125], at: [-0.5, 0.5, -0.5625], material: metal}
  - {name: CuffLR, slot: Trim, size: [0.125, 0.25, 0.375], at: [-0.25, 0.5, -0.8125], material: metal}
  - {name: CuffLL, slot: Trim, size: [0.125, 0.25, 0.375], at: [-0.75, 0.5, -0.8125], material: metal}
  - {name: CuffRF, slot: Trim, size: [0.625, 0.25, 0.125], at: [0.5, 0.5, -1.0625], pose: reach, material: metal}
  - {name: CuffRB, slot: Trim, size: [0.625, 0.25, 0.125], at: [0.5, 0.5, -0.5625], pose: reach, material: metal}
  - {name: CuffRR, slot: Trim, size: [0.125, 0.25, 0.375], at: [0.75, 0.5, -0.8125], pose: reach, material: metal}
  - {name: CuffRL, slot: Trim, size: [0.125, 0.25, 0.375], at: [0.25, 0.5, -0.8125], pose: reach, material: metal}
  # dark ice shards, half again as big, standing on the haunches' tops like spines (the dark indigo, so they stand off the snow)
  - {name: Sharda, slot: BodyDark, size: [0.375, 0.75, 0.375], at: [0.75, 1.75, 0.5], rot: [14, 0, 0], shape: cone6, mirror: x, material: ice}
  - {name: Shardb, slot: BodyDark, size: [0.1875, 0.375, 0.1875], at: [0.9375, 1.5625, 0.5], rot: [0, -16, 0], shape: cone6, mirror: x, material: ice}
  # the satellite set (`sparks`, two rows of three standing out to its sides, the back higher, nothing in front of the face): six four-point stars, a lit violet cross in a dark outline, three quarters of a stud across, facing the viewer
  - {name: Sat0a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat0b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat0c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat0d, slot: Glow, size: [0.125, 0.75, 0.25], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat0e, slot: Glow, size: [0.75, 0.125, 0.25], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat0f, slot: Glow, size: [0.375, 0.375, 0.25], at: [1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat1a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat1b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat1c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat1d, slot: Glow, size: [0.125, 0.75, 0.25], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat1e, slot: Glow, size: [0.75, 0.125, 0.25], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat1f, slot: Glow, size: [0.375, 0.375, 0.25], at: [2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat2a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat2b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat2c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat2d, slot: Glow, size: [0.125, 0.75, 0.25], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat2e, slot: Glow, size: [0.75, 0.125, 0.25], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat2f, slot: Glow, size: [0.375, 0.375, 0.25], at: [2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat3a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat3b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat3c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat3d, slot: Glow, size: [0.125, 0.75, 0.25], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat3e, slot: Glow, size: [0.75, 0.125, 0.25], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat3f, slot: Glow, size: [0.375, 0.375, 0.25], at: [-2.0625, 2.0625, 1.5625], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat4a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat4b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat4c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat4d, slot: Glow, size: [0.125, 0.75, 0.25], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat4e, slot: Glow, size: [0.75, 0.125, 0.25], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat4f, slot: Glow, size: [0.375, 0.375, 0.25], at: [-2.5, 1.5625, -0.125], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat5a, slot: BodyDark, size: [0.25, 0.875, 0.125], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat5b, slot: BodyDark, size: [0.875, 0.25, 0.125], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat5c, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1]}
  - {name: Sat5d, slot: Glow, size: [0.125, 0.75, 0.25], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat5e, slot: Glow, size: [0.75, 0.125, 0.25], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  - {name: Sat5f, slot: Glow, size: [0.375, 0.375, 0.25], at: [-1.75, 1.125, -1.6875], moves: sparks, pivot: [0, 1.8, 0.1], material: glow}
  # pilot bar: end
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
  rest:
    head: {rot: [0, 14, 6], pivot: [0, 1.5, -0.2], move: [0, -0.15, 0]}
    reach: {rot: [55, 0, 0], pivot: [0.5, 1.25, -0.8125]}
  clips:
    sparks: [{kind: wag, amp: 22, period: 6.5, axis: y}, {kind: bob, amp: 0.06, period: 2.3}]
    crest: [{kind: sway, amp: 8, period: 3, axis: x}]
    ear: [{kind: wag, amp: 15, period: 3.4, axis: z}]
    whisker: [{kind: wag, amp: 10, period: 1.6, axis: y}]
    tail: [{kind: sway, amp: 10, period: 2.6, axis: z}]
    mote: [{kind: spin, amp: 360, period: 5}, {kind: bob, amp: 0.08, period: 1.7}]
    pendant: [{kind: sway, amp: 12, period: 2.1, axis: x}]
    root: [{kind: squash, amp: 0.03, period: 2.8}]
    face: [{kind: blink, period: 5}]
  flourish:
    every: 12
    length: 2.4
    moves:
      - {part: root, kind: hop, amp: 0.35, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.4}
      - {part: crest, kind: swish, amp: 20, at: 0.3, for: 1.4}
      - {part: ear, kind: flare, amp: 20, at: 0.2, for: 0.8}
      - {part: tail, kind: swish, amp: 20, at: 0.5, for: 1.2}
      - {part: mote, kind: turn, amp: 720, at: 0.2, for: 1.6}
      - {part: crest, kind: pop, amp: 0.25, at: 1.4, for: 0.9}
      - {part: pendant, kind: swish, amp: 25, at: 0.6, for: 1.2}
      - {part: sparks, kind: pop, amp: 0.3, at: 0.5, for: 1}
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
- 2026-10-21, Polish w2 worker: the whiskers barely read (two quarter-stud cream bars on a lavender head against a pale sky). They are now three a side in the dark indigo `second`, half a stud long from the head's front edge, the top one fanned up 15 degrees and the bottom one down 15, all on the one `whisker` mover each side (no new moving object). 51 blocks, 952 triangles, overlap 0.996; silhouette worst pair with Aurelyx 0.66 (Soakum). Honest read: the whiskers are now the first thing after the eyes from every angle and make it plainly a cat; dark on pale is the lesson (the cream ones vanished).
- 2026-10-21, Rare pass w2: the signature is an **aurora comet tail**: three ribbons of light fan up out of the tail's lit tip (the middle tallest, the outer two at 20 degrees) and step through violet, mint and pink with the crest, so the cat carries a second aurora; two aurora motes circle the crest every 5 s (they whirl twice in the flourish), and a silver collar holds a lit gem pendant that swings (sixteenth-grid chest detail). 59 blocks, nine moving things (from seven), the flourish 2.4 s with eight moves (the crest swells). New attach point: `Plume` (PlumeC). Honest read: the plume doubles the aurora and reads as a comet's tail from the three-quarter camera; the pendant sits under the chin, where the head hides it from the high camera, and the pale glow washes toward pink in daylight (it reads at night).
