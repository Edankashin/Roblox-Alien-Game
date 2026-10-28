---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Spookum
name: Grin
world: 1
tier: Epic
status: review
element: Shadow
height: 3.46
blocks: 130
tris: 1658
bevel_width: 0.125
bevel_segments: 2
palette: ["#E9E6FF", "#5B4A8A", "#FF9F1C", "#B89B5A", "#9D6BFF", "#1B1430"]
roles: [body, second, accent, trim, glow, ink]
hero: Stem
vfx: "kept on the body (Epic): Effects.luau's pumpkin-orange Light (FF9F1C) at the Mouth pulsing every 2.4 s, so the grin glows from inside; a ghost-white mist (E9E2FF) pooling at the Feet at 3 a second; ember flickers (FFB347) rising off the Top at 2.5 a second; its signature Burst, a ring of twelve violet wisps (C77DFF) every 5 s and on the flourish (the boo); a violet Sparkle at the Tail every 3 s; a Hover idle of 0.35 studs over 3 s. On the model the tatter tips, the little lantern's face, the lock's keyhole and the back emblem's eyes are violet glow cells. The rig adds the motion and the flourish: the arms wave, the hem and tatters stir, the stem sways, a little jack-o'-lantern floats and turns at its side, and every 10 s it says boo (a squash, a hop and a full turn, the arms flung wide)"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Spookum_sheet.svg]]"
render: "[[Spookum_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.993, 0.998, 0.994]
vfx_render: "[[Spookum_vfx_cells.jpg]]"
cells_render: "[[Spookum_tq_cells.jpg]]"
idle_render: "[[Spookum_idle.png]]"
bar_world: Verdant
bar_kit: 5
bar_pieces: [bark_band, blossom_bud, moss_cells]
bar_stance: "a drift: the whole sheet leaning 8 degrees to its right as it floats, the ragged hem twisted 25 degrees behind it, a ring of haunted candles and jack-o'-lanterns circling"
bar_satellites: 6
bar_orbit: candles
---
# Spookum (Grin), Epic, World 1 Verdant, the Haunted Nebula event

A round ghost with a pumpkin's grin, 3.44 studs (B45: it was 3.91): a soft lilac-white block body with a bulge proud of each flank and three narrowing steps on top (a dome, a crown in a thin brass band, a cap), so it reads as a ghost's dome rather than a cube, a brass pumpkin stem with a drooping curl and a dusk-violet leaf on its crown, and its own starry eyes over a wide jack-o'-lantern grin built proud of its front in sixteenth-stud cells, an orange slit lit from inside with two white teeth hanging from its top and one rising from the bottom. Under the body a violet hem flares wider than the body like a sheet's skirt, and a ragged fringe of fifteen narrow points of different lengths hangs from its edge all round to the grass, three of them lit violet at their tips; two stubby arms rise out at its sides in a "boo", and a brass chain of five links hangs from the right hand to a little brass lock with a lit keyhole. A tiny jack-o'-lantern with a lit face floats at its left shoulder. Dusk-violet ribs run up its back and sides like a pumpkin's, and a stepped orange pumpkin emblem with two lit eyes sits between the back ribs. Concept row in `src/shared/data/Species.luau`: "round ghost, pumpkin grin, drifts an inch off the ground". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`). Element and effect: [[Roster-Redesign]] section 2 (Shadow; the grin glows orange from inside, a pool of purple mist spreads under it, it fades and returns every 5 s; `Effects.luau` calls the element Ghost). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the event's face: a ghost whose grin is a jack-o'-lantern's, drifting an inch off the ground at night with its tatters brushing the grass, a chain swinging from one hand and a little lantern friend bobbing at its shoulder. B46: smaller than before and much more detailed, 62 blocks in sixteenth-stud cells; its own `hearty` eyes (violet irises with a pumpkin-orange heart for a pupil, a shine on its lobe and orange lashes) and blush cheeks, the cutest face of the event; six moving things and a boo every 10 s. The Epic rung's detail: trim (the brass stem, band, chain and lock), stripes (the ribs), a stepped emblem (the pumpkin on its back), glow on its extremities (the tatter tips, the lantern's face), the light kept on the body.

**Hero block.** The `Stem`, a brass pumpkin stem with a curl and a leaf on a ghost's crown: the one block that says this ghost is a pumpkin, unique in Verdant (Moop's sprout is a lime leaf).

**Moving parts (five objects and the blink).** `armR` and `armL` (the arms wave; the chain and lock swing with the right one), `hem` (the hem and its tatters stir), `stem` (the stem, its curl and leaf sway), `lanternL` (the little jack-o'-lantern bobs, circles and turns); the plate blinks and glints. Rare pass w1: `candles` (three floating candles circling the dome: they turn, bob and leap) and `wisp` (a spectral wisp off the back: it sways) make seven objects and the blink.

**Alien anatomy.** A ghost that is also a pumpkin: a stem on its crown, ribs on its body, a grin that glows from inside, a hem of tatters it floats on, and a pumpkin of its own that follows it like a pet.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the crown, the hem, the tatters and the emblem.

**Event palette (Haunted Nebula).** Ghost white over dusk violet with the event's pumpkin orange as the accent, old brass trim and a violet glow: the warm end of the event's range (Wispkin is the cold blue end, Cosmoo the deep violet).

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`spookum()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** The pumpkin ghost of the Haunted Nebula, drifting in a lean with its own little haunt around it. Kept: name, anatomy (a sheet with a jack-o'-lantern's grin, a brass pumpkin stem, a chain and lock from one hand, a lantern friend at its shoulder, ragged tatters), the hearty eyes, height 3.46.
- **Gains (visible parts).** (1) Six satellites on a wide low ring (the `candles` object, replacing the three old candles, so the Effects pieces `Candles`, `CandlesB` and `CandlesC` still hang on it): three haunted candles (a brass dish, an orange candle with cream drips, a lit violet flame) and three little jack-o'-lanterns (orange, a brass stem, a lit violet grin and eyes on both faces), three quarters of a stud and more. (2) Verdant kit, five pieces: pumpkin-orange moss pads with a lit tuft on the dome's back corners, brass blossom buds on its front corners, a brass belt a quarter stud tall round the waist. (3) The stance below.
- **Stance (rest groups `lean`, `trail`).** The whole sheet above the hem leans 8 degrees to its right (the face, the arms, the chain, the crown all together) while the ragged hem is twisted 25 degrees behind it: a ghost drifting through a turn, not a block on a skirt.
- **Face intent.** Its own `hearty` eyes kept (a lit violet iris with a pumpkin-orange heart pupil, orange lashes) over the built jack-o'-lantern grin: mischievous but warm, a friendly trick-or-treater. The face is not changed; the grin is the only thing under the plate and nothing crosses it.
- **Three values (rule 8).** Body lilac-white; the hem, tatters, ribs and folds a step darker (dusk violet); the pumpkin orange and brass the warm accents and metal; lit violet the one light. The satellites are never the body's white.
- **Must-nots.** No fierce teeth beyond the grin that exists; no loose boxes in the ring; nothing over the face; a hem rolled under its pivot dips below the ground (roll 10 sank 0.18: yawed instead); height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # the body: one soft lilac-white block, the face plate and the grin on its front; a sheet's round from blocks (Polish w1): a flank bulge
  # proud of each side and three narrowing steps on top (the dome, the crown in its brass band, the cap), so it reads as a ghost's dome
  - {name: Body, slot: Body, size: [2, 1.5, 2], at: [0, 1.5, 0], bevel: true, material: nebula, pose: lean}
  - {name: Flank, slot: Body, size: [0.125, 1, 1.5], at: [1.0625, 1.5, 0], mirror: x, material: nebula, pose: lean}
  - {name: Dome, slot: Body, size: [1.625, 0.25, 1.625], at: [0, 2.375, 0], material: nebula, pose: lean}
  - {name: CrownBand, slot: Trim, size: [1.25, 0.0625, 1.25], at: [0, 2.53125, 0], material: metal, pose: lean}
  - {name: Crown, slot: Body, size: [1.125, 0.25, 1.125], at: [0, 2.625, 0], material: nebula, pose: lean}
  - {name: Cap, slot: Body, size: [0.625, 0.125, 0.625], at: [0, 2.8125, 0], pose: lean}
  # the hero: a brass pumpkin stem with a drooping curl and a dusk-violet leaf on the crown (they sway)
  - {name: Stem, slot: Trim, size: [0.375, 0.375, 0.375], at: [0.1875, 3.0625, 0], moves: stem, pivot: [0, 2.875, 0], pose: lean}
  - {name: StemCurl, slot: Trim, size: [0.4375, 0.1875, 0.1875], at: [0.4375, 3.28125, 0], rot: [0, 0, -20], moves: stem, pivot: [0, 2.875, 0], pose: lean}
  - {name: Leaf, slot: BodyDark, size: [0.375, 0.0625, 0.25], at: [-0.15625, 2.96875, 0.0625], rot: [0, 0, 15], moves: stem, pivot: [0, 2.875, 0], pose: lean}
  # the jack-o'-lantern grin, built proud of the front under the face plate in sixteenth-stud cells: an orange slit lit from inside with
  # upturned corners, an ink line under it, two white teeth hanging from its top edge and one rising from the bottom
  - {name: Grin, slot: Accessory, size: [1.25, 0.25, 0.0625], at: [0, 0.9375, -1.03125], material: glow, pose: lean}
  - {name: GrinCorner, slot: Accessory, size: [0.125, 0.125, 0.0625], at: [0.6875, 1.125, -1.03125], mirror: x, material: glow, pose: lean}
  - {name: GrinLine, slot: Eye, size: [1.25, 0.0625, 0.0625], at: [0, 0.78125, -1.03125], pose: lean}
  - {name: Tooth, slot: Body, size: [0.125, 0.125, 0.0625], at: [0.25, 1, -1.09375], mirror: x, pose: lean}
  - {name: Tooth2, slot: Body, size: [0.125, 0.125, 0.0625], at: [0, 0.875, -1.09375], pose: lean}
  # the violet hem flares wider than the body like a sheet's skirt, and a ragged fringe of fifteen narrow points of different lengths hangs
  # from its edge all round (Polish w1: no gap under it as wide as a leg), three of them lit violet at the tip; they stir together
  - {name: Hem, slot: BodyDark, size: [2.25, 0.375, 2.25], at: [0, 0.5625, 0], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-1, 0.3125, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter2, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [-0.5, 0.25, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter3, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [0, 0.28125, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter4, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0.5, 0.25, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter5, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [1, 0.28125, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter6, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [-0.875, 0.25, 1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter7, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [-0.25, 0.28125, 1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter8, slot: BodyDark, size: [0.25, 0.3125, 0.125], at: [0.375, 0.21875, 1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter9, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [0.875, 0.3125, 1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter10, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.0625, 0.25, -0.5], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter11, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.0625, 0.25, 0], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter12, slot: BodyDark, size: [0.125, 0.125, 0.25], at: [1.0625, 0.3125, 0.5], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter13, slot: BodyDark, size: [0.125, 0.3125, 0.25], at: [-1.0625, 0.21875, -0.5], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter14, slot: BodyDark, size: [0.125, 0.1875, 0.25], at: [-1.0625, 0.28125, 0], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter15, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [-1.0625, 0.25, 0.5], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter4Tip, slot: Glow, size: [0.25, 0.125, 0.125], at: [0.5, 0.0625, -1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter6Tip, slot: Glow, size: [0.25, 0.125, 0.125], at: [-0.875, 0.0625, 1.0625], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  - {name: Tatter11Tip, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.0625, 0.0625, 0], moves: hem, pivot: [0, 0.75, 0], pose: trail}
  # two stubby arms rising out 20 degrees, a hand on each (they wave); the brass chain of five links hangs from the right hand to a little
  # brass lock with a lit keyhole, and swings with it
  - {name: Arm, slot: Body, size: [0.625, 0.3125, 0.4375], at: [1.28125, 1.84375, -0.25], rot: [0, 0, 20], mirror: x, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Hand, slot: Body, size: [0.3125, 0.3125, 0.4375], at: [1.71875, 2.03125, -0.25], rot: [0, 0, 20], mirror: x, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Chain, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 1.71875, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Chain2, slot: Trim, size: [0.0625, 0.1875, 0.125], at: [1.78125, 1.53125, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Chain3, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 1.34375, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Chain4, slot: Trim, size: [0.0625, 0.1875, 0.125], at: [1.78125, 1.15625, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Chain5, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 0.96875, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Lock, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.75, 0.75, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  - {name: Keyhole, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [1.78125, 0.75, -0.34375], moves: arm, pivot: [1, 1.75, -0.25], pose: lean}
  # a tiny jack-o'-lantern floating at its left shoulder, its face lit violet (it bobs, circles and turns)
  - {name: Lantern, slot: Accessory, size: [0.375, 0.375, 0.375], at: [-1.375, 2.375, -0.25], moves: lantern, pivot: [-1.375, 2.375, -0.25], pose: lean}
  - {name: LanternStem, slot: Trim, size: [0.125, 0.125, 0.125], at: [-1.375, 2.625, -0.25], moves: lantern, pivot: [-1.375, 2.375, -0.25], pose: lean}
  - {name: LanternGrin, slot: Glow, size: [0.25, 0.0625, 0.0625], at: [-1.375, 2.28125, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25], pose: lean}
  - {name: LanternEye, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [-1.46875, 2.40625, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25], pose: lean}
  - {name: LanternEye2, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [-1.28125, 2.40625, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25], pose: lean}
  # pumpkin ribs: dusk-violet strips proud of the back and the sides by an eighth
  - {name: Rib, slot: BodyDark, size: [0.25, 1.25, 0.125], at: [0.625, 1.5, 1.0625], mirror: x, pose: lean}
  - {name: SideRib, slot: BodyDark, size: [0.125, 1.25, 0.25], at: [1.1875, 1.5, 0.375], mirror: x, pose: lean}
  # the stepped emblem: an orange pumpkin of three steps with a violet stem and two lit eyes, between the back ribs
  - {name: Emblem, slot: Accessory, size: [0.5, 0.1875, 0.125], at: [0, 1.28125, 1.0625], pose: lean}
  - {name: Emblem2, slot: Accessory, size: [0.75, 0.3125, 0.125], at: [0, 1.53125, 1.0625], pose: lean}
  - {name: Emblem3, slot: Accessory, size: [0.5, 0.1875, 0.125], at: [0, 1.78125, 1.0625], pose: lean}
  - {name: EmblemStem, slot: BodyDark, size: [0.125, 0.1875, 0.125], at: [0, 1.96875, 1.0625], pose: lean}
  - {name: EmblemEye, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [0.15625, 1.59375, 1.15625], mirror: x, pose: lean}
  # Rare pass w1: a spectral wisp curling up off the back between the ribs, lit violet glass (it sways like a sheet in a draught)
  - {name: Wisp, slot: Glow, size: [0.25, 0.25, 0.125], at: [0, 2.125, 1.1875], moves: wisp, pivot: [0, 2, 1.1875], material: crystal, pose: lean}
  - {name: Wisp2, slot: Glow, size: [0.1875, 0.25, 0.125], at: [0.03125, 2.375, 1.3125], moves: wisp, pivot: [0, 2, 1.1875], material: crystal, pose: lean}
  - {name: Wisp3, slot: Glow, size: [0.125, 0.1875, 0.125], at: [0.0625, 2.59375, 1.4375], moves: wisp, pivot: [0, 2, 1.1875], material: crystal, pose: lean}
  - {name: WispTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.125, 2.75, 1.5625], moves: wisp, pivot: [0, 2, 1.1875], pose: lean}
  # Rare pass w1: a band of lit violet glass cells round the sheet's waist over the hem, where the ghost fades into its glow
  - {name: Waist, slot: Glow, size: [0.0625, 0.125, 1.75], at: [1.03125, 0.8125, 0], mirror: x, material: crystal, pose: lean}
  - {name: WaistBack, slot: Glow, size: [1.75, 0.125, 0.0625], at: [0, 0.8125, 1.03125], material: crystal, pose: lean}
  # Rare pass w1: two dusk-violet folds down each flank bulge, so the sheet reads as draped cloth from the three-quarter view
  - {name: Fold, slot: BodyDark, size: [0.0625, 0.75, 0.125], at: [1.15625, 1.375, -0.375], mirror: x, pose: lean}
  - {name: Fold2, slot: BodyDark, size: [0.0625, 0.5, 0.125], at: [1.15625, 1.25, 0.375], mirror: x, pose: lean}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: pumpkin-orange moss pads with a lit tuft on the dome's back corners (they lean with the sheet)
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.8125, 2.5625, 0.375], mirror: x, pose: lean, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [0.875, 2.6875, 0.375], mirror: x, pose: lean, material: moss}
  - {name: Mossc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.75, 2.8125, 0.3125], mirror: x, pose: lean, material: moss}
  # brass blossom buds on the dome's front corners, either side of the crown (they lean with the sheet)
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.5625, 2.625, -0.5625], mirror: x, pose: lean, material: wood}
  - {name: Budb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.5625, 2.8125, -0.5625], mirror: x, pose: lean}
  - {name: Budc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.5625, 2.9375, -0.5625], mirror: x, pose: lean}
  # a brass belt: a quarter stud tall and three sixteenths proud, round the sheet's waist over the lit band (the grin stays clear)
  - {name: BeltR, slot: Trim, size: [0.1875, 0.25, 2], at: [1.09375, 1, 0], pose: lean, material: metal}
  - {name: BeltL, slot: Trim, size: [0.1875, 0.25, 2], at: [-1.09375, 1, 0], pose: lean, material: metal}
  - {name: BeltB, slot: Trim, size: [2.375, 0.25, 0.1875], at: [0, 1, 1.09375], pose: lean, material: metal}
  # the satellite set (`candles`, one wide ring clear of the arms and the lantern, the front low): three haunted candles and three jack-o'-lanterns, orange and brass with lit violet
  - {name: Sat0a, slot: Trim, size: [0.75, 0.125, 0.5], at: [1.25, 0.6875, -2.1875], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat0b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [1.25, 1, -2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat0c, slot: Body, size: [0.125, 0.25, 0.0625], at: [1.1875, 1.125, -2.03125], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat0d, slot: Body, size: [0.125, 0.25, 0.0625], at: [1.3125, 1, -2.34375], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat0e, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.25, 1.375, -2.1875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1a, slot: Accessory, size: [0.75, 0.5, 0.5], at: [2.5, 1.875, 0], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat1b, slot: Accessory, size: [0.5, 0.125, 0.5], at: [2.5, 2.1875, 0], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat1c, slot: Trim, size: [0.125, 0.125, 0.125], at: [2.5, 2.3125, 0], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat1d, slot: Glow, size: [0.5, 0.125, 0.0625], at: [2.5, 1.8125, -0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1e, slot: Glow, size: [0.5, 0.125, 0.0625], at: [2.5, 1.8125, 0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.3125, 2, -0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.6875, 2, -0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1h, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.3125, 2, 0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat1i, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.6875, 2, 0.28125], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat2a, slot: Trim, size: [0.75, 0.125, 0.5], at: [1.25, 1.9375, 2.1875], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat2b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [1.25, 2.25, 2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat2c, slot: Body, size: [0.125, 0.25, 0.0625], at: [1.3125, 2.375, 2.03125], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat2d, slot: Body, size: [0.125, 0.25, 0.0625], at: [1.1875, 2.25, 2.34375], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat2e, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.25, 2.625, 2.1875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3a, slot: Accessory, size: [0.75, 0.5, 0.5], at: [-1.25, 2.125, 2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat3b, slot: Accessory, size: [0.5, 0.125, 0.5], at: [-1.25, 2.4375, 2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat3c, slot: Trim, size: [0.125, 0.125, 0.125], at: [-1.25, 2.5625, 2.1875], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat3d, slot: Glow, size: [0.5, 0.125, 0.0625], at: [-1.25, 2.0625, 2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3e, slot: Glow, size: [0.5, 0.125, 0.0625], at: [-1.25, 2.0625, 1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.0625, 2.25, 2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.4375, 2.25, 2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3h, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.0625, 2.25, 1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat3i, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.4375, 2.25, 1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat4a, slot: Trim, size: [0.75, 0.125, 0.5], at: [-2.5, 1, 0], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat4b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [-2.5, 1.3125, 0], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat4c, slot: Body, size: [0.125, 0.25, 0.0625], at: [-2.5625, 1.4375, 0.15625], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat4d, slot: Body, size: [0.125, 0.25, 0.0625], at: [-2.4375, 1.3125, -0.15625], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat4e, slot: Glow, size: [0.125, 0.25, 0.125], at: [-2.5, 1.6875, 0], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5a, slot: Accessory, size: [0.75, 0.5, 0.5], at: [-1.25, 0.9375, -2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat5b, slot: Accessory, size: [0.5, 0.125, 0.5], at: [-1.25, 1.25, -2.1875], moves: candles, pivot: [0, 1.65, 0]}
  - {name: Sat5c, slot: Trim, size: [0.125, 0.125, 0.125], at: [-1.25, 1.375, -2.1875], moves: candles, pivot: [0, 1.65, 0], material: metal}
  - {name: Sat5d, slot: Glow, size: [0.5, 0.125, 0.0625], at: [-1.25, 0.875, -2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5e, slot: Glow, size: [0.5, 0.125, 0.0625], at: [-1.25, 0.875, -1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.4375, 1.0625, -2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.0625, 1.0625, -2.46875], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5h, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.4375, 1.0625, -1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  - {name: Sat5i, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.0625, 1.0625, -1.90625], moves: candles, pivot: [0, 1.65, 0], material: crystal}
  # pilot bar: end
```

## Face

The body's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud block, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and the cheeks are on the face plate, and the jack-o'-lantern grin is geometry proud of the front under it (the plate's own mouths are too small to carry a pumpkin's grin, and the grin has to be a place `Effects.luau` lights from within).

```yaml
face:
  host: Body
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `hearty`, an Epic design, a two-tone iris (the lit violet over dusk violet) with a heart for a pupil in pumpkin orange, a shine on its lobe and orange lashes at the outer corner, two glint frames. At 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, five frames). No mouth on the plate (the grin is built under it) and blush cheeks. Round one wore `starry`: at 16 pixels a stud its orange star read as a plus, a crosshair in each eye. In World 1 only Grin wears `hearty` in these colours.

```yaml
eyes:
  key: hearty
  colours: {iris: glow, iris2: second, pupil: accent, lash: accent}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.5625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them and calls `SpeciesFx.Flourish` on each flourish, the moment `Effects.luau`'s ring of violet wisps fires): the arms wave out of step (the chain and lock swing with the right), the hem and tatters stir, the stem sways, the little jack-o'-lantern bobs, circles and turns, the body breathes, the face blinks. Five objects and the blink (an Epic needs five). The flourish, every 10 s, the boo: a squash, a hop and a full turn with the arms flung wide, the hem swishing and the lantern leaping.

```yaml
rig:
  rest:
    lean: {rot: [0, 0, 8], pivot: [0, 0.75, 0]}
    trail: {rot: [0, 25, 0], pivot: [0, 0.75, 0]}
  clips:
    arm: [{kind: flap, amp: 15, period: 1.6, axis: z}]
    hem: [{kind: sway, amp: 5, period: 2, axis: x}, {kind: sway, amp: 4, period: 2.6, axis: z, phase: 0.25}]
    stem: [{kind: sway, amp: 8, period: 2.4, axis: z}]
    lanternL: [{kind: bob, amp: 0.15, period: 2}, {kind: orbit, amp: 0.12, period: 6}, {kind: spin, amp: 360, period: 5, axis: y}]
    candles: [{kind: spin, amp: 360, period: 14, axis: y}, {kind: bob, amp: 0.06, period: 2.2}]
    wisp: [{kind: sway, amp: 12, period: 2.8, axis: z}, {kind: sway, amp: 8, period: 3.7, axis: x, phase: 0.4}]
    root: [{kind: squash, amp: 0.04, period: 3}, {kind: bob, amp: 0.06, period: 3.6, phase: 0.3}]
    face: [{kind: blink, period: 4}]
  flourish:
    every: 10
    length: 2.4
    moves:
      - {part: root, kind: squash, amp: 0.15, at: 0, for: 0.4}
      - {part: root, kind: hop, amp: 0.6, at: 0.3, for: 0.8}
      - {part: candles, kind: hop, amp: 0.25, at: 0.3, for: 1}
      - {part: root, kind: turn, amp: 360, at: 0.4, for: 1.6}
      - {part: candles, kind: turn, amp: -360, axis: y, at: 0.4, for: 1.8}
      - {part: arm, kind: flare, amp: 30, at: 0.3, for: 1.2}
      - {part: hem, kind: swish, amp: 15, at: 0.5, for: 1}
      - {part: wisp, kind: swish, amp: 20, axis: z, at: 0.6, for: 1.2}
      - {part: lanternL, kind: hop, amp: 0.3, at: 0.8, for: 0.9}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Candles | `Sat0e` (candles) | 0.31, 0.89, -0.34 | a violet flicker on each flame, a puff on the flourish | Halo |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Spookum_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Spookum_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Spookum_idle.png]]

The concept sheet, drawn from the parts table above: [[Spookum_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Spookum_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 28 cells tall; one atlas of 512 x 1024 at 8 texels a cell. Materials: skin on the body, the crown, the hem, the tatters, the arms, the ribs and the emblem (a sheet has no motif; the cells and the grout are what make it read as built), metal on the chain (glossy); the stem is glossy trim; the tatter tips are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, one round. Built as drawn: the jack-o'-lantern grin under the house eyes reads at once, the brass stem says pumpkin, the chain swings from the right hand on the camera's side, the three lit tatter tips put the Epic's glow at the hem where the mist pools in the game. Overlap 0.994 to 0.996, 416 triangles, 31 blocks, 3.91 studs; the boxed silhouette's worst pair is Zirrit at 0.65. Wanted for: the event's face, a ghost whose grin is a pumpkin's. Still cheap: the arms are two plain white bars; the back emblem and ribs are behind the three-quarter camera (the game's high camera sees the ribs on the sides). Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, two rounds. Brought to 3.32 studs from 3.91 by a shorter body (1.75 studs, the head 53 percent), not a scale; 49 blocks in sixteenth-stud detail (the Epic band is 32 to 64): a brass band round the crown, a leaf and a drooping curl on the stem, the jack-o'-lantern grin rebuilt as geometry proud of the front under the plate (an orange slit on the glow material, upturned corners, an ink line, three white teeth), a five-link chain to a brass lock with a lit keyhole, a tiny floating jack-o'-lantern with a lit face, two lit eyes on the back emblem. Round 1 wore `starry`: at 16 pixels a stud the orange star read as a plus, a crosshair in each eye; round 2 `hearty`, an orange heart pupil in a violet iris with orange lashes, and blush cheeks. Five moving objects and the blink (the arms wave with the chain, the hem and tatters stir, the stem sways, the lantern bobs, circles and turns) and the boo every 10 s: a squash, a hop and a full turn with the arms flung wide. Overlap 0.994 to 0.995, 638 triangles; worst silhouette pair 0.669 (Dandel). Wanted for: the event's face, a pumpkin ghost with heart eyes and a lantern of its own. Still weak: the body is still a cube, and the three white tatters read as legs from the three-quarter view (as before). Status review.
- 2026-10-21, Polish w1, four rounds. The cube and the leg-like tatters. The body is 1.5 studs tall now with a bulge proud of each flank and three narrowing steps on top (a dome 1.625, the crown 1.125 in its brass band, a cap 0.625), so the front and side outlines step in like a dome; the plate and the grin moved down a sixteenth to stay in the lower half. The hem flares to 2.25 studs and the six tatters (three white ones with lit tips read as two legs and feet) became a ragged fringe of fifteen narrow violet points from an eighth to three eighths long all round, three of them lit and none at a corner (a lit corner point read as a foot). A white hem was tried and read as a table on legs. 62 blocks (Epic 32 to 64), 3.44 studs. Overlap 0.994 to 0.997. Honest read: the hem now reads as a ghost's ragged skirt and nothing reads as legs; from the three-quarter view the white body is still mostly a block with a domed top (white on white hides the steps; the front view shows them clearly). Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: a ring of three floating candles circling the dome, pumpkin-orange wax with cream drips on brass dishes and lit violet glass flames (a haunted candelabra; it turns once in 14 s and spins the other way on the flourish), and a spectral wisp of lit violet glass curling off the back. The white block: the body, dome, crown and flank bulges take the `nebula` cells (star-mist: violet star cells on the ghost white), two dusk-violet folds hang down each flank bulge and a band of lit violet glass runs round the waist over the hem. Round 1 made the candles cream (white on white, invisible). 85 blocks, eight moving things. Honest read: the candles and the starry sheet make it a haunted thing at last; from the three-quarter view the body is still mostly one pale block, now a speckled one with folds, and the folds read only at the side. Status review.
