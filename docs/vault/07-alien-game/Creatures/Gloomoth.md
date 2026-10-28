---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Gloomoth
name: Iridia
world: 1
tier: Epic
status: review
element: Crystal
height: 3.46
blocks: 120
tris: 1658
bevel_width: 0.125
bevel_segments: 2
palette: ["#8C6FB5", "#3B2454", "#D9C8FF", "#E8C45A", "#B832E8", "#140C21"]
roles: [body, second, accent, trim, glow, ink]
hero: ForeWing
vfx: "kept on the body (Epic), five layers in Effects.luau: a lilac glint twinkles on the left wing (BackL) and a pale blue one on the right (BackR) every 3 s, a slow lilac dust drifts down from the back at 4 a second, a violet light pulses on the back, and the signature: every 7 s and on the flourish the wings shake out a burst of fourteen pink prism sparkles. The flourish (every 10 s) is a wing-shake: a hop, the fore and hind wings flared, the antennae swishing and the gold shard leaping"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Gloomoth_sheet.svg]]"
render: "[[Gloomoth_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.995, 0.998, 0.995]
vfx_render: "[[Gloomoth_vfx_cells.jpg]]"
cells_render: "[[Gloomoth_tq_cells.jpg]]"
idle_render: "[[Gloomoth_idle.png]]"
bar_world: Verdant
bar_kit: 5
bar_pieces: [bark_band, blossom_bud, moss_cells]
bar_stance: "a night flutter: the crystal fore wings raised 12 degrees higher, the head cocked 6 degrees, the abdomen curled up 12 degrees behind it, three little moths and three moonflowers circling"
bar_satellites: 6
bar_orbit: swarm
---
# Gloomoth (Iridia), Epic, World 1 Verdant

A night moth in mauve and pale lilac whose wings are crystal, 3.44 studs to its antenna tips (B45: it was 3.64; a moth is tall only by its feelers): a big square head in a shaggy lilac ruff that steps out wide at the top with a tuft at each shoulder and a wool tuft on the crown, a stepped gold crystal diamond on its forehead over the face plate, two slender feathered antennae leaning apart (a stalk, two stepped feather plates on its outer side and a lit orchid tip), a fuzzy banded abdomen behind on six thin legs, and four pale crystal wings spread off its back: the big fore pair lifted and pitched toward the front so their faces show, each with a rear lobe stepped out behind, a plum edge and a gold-ringed orchid eyespot, the hind pair low behind with plum edges. A small gold crystal shard circles over its back. Concept row in `src/shared/data/Species.luau`: "moth, crystal wings". Element and effect: [[Roster-Redesign]] section 2 (Crystal; a glint sweeps the wings and light dust falls). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** At the height of a Rare it is plainly a step up: 45 blocks to the Rares' 30 to 35, most of them sixteenth-stud plates (the antennae's feathers, the wing lobes and edges, the forehead diamond); its own `gem` eyes (an amethyst iris with an orchid diamond pupil inside a lit gold rim, and heart cheeks, the first in Verdant below the Legendary); seven moving objects and the blink (fore wings, hind wings, antennae, the circling shard); and a flourish every 10 s that reads across the meadow: it hops and shakes out all four wings while the effects throw a burst of prism sparkles. Exclusive by its jewellery and its light, never by size or a fierce face.

**Hero block.** The `ForeWing` pair, two broad crystal wings with rear lobes, plum edges and lit eyespots, unique in Verdant (Buzzik's wings are small membranes; Raddis's are the sun's).

**Moving parts (seven objects and the blink).** `wingR` and `wingL` (the fore wings with their lobe, edge, ring and eyespot: they beat), `hindwingR` and `hindwingL` (they beat a little behind), `antennaR` and `antennaL` (stalk, feathers and lit tip: they tilt), `shard` (it circles and spins); the face plate blinks and glints. Rare pass w1: the four wings carry stained-glass panes (lit orchid glass and gold glass), so the objects stay seven and the blink at the Epic cap.

**Alien anatomy.** Wings of crystal that look back with eyespots, six legs under a moth that stands, feathered antennae that light at the tip, and a shard of its own crystal that orbits it.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the ruff and the sixteenth-stud steps of the feathers, the lobes and the diamond.

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`gloomoth()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A night moth mid-flutter, the keeper of the dusk garden. Kept: name, anatomy (crystal fore and hind wings with lit eyespots and stained-glass panes, feathered antennae with lit tips, the gold crown diamond, a shard of its own crystal), height 3.46.
- **Gains (visible parts).** (1) Six satellites on a wide low ring clear of the wings, in lit orchid, gold and pale lilac: three little moths (gold body and feelers, lit orchid upper wings over pale lilac lower wings) and three moonflowers (pale lilac petals round a gold heart with a lit dot on both faces), each three quarters of a stud and more. (2) Verdant kit, five pieces: lilac moss pads with a lit tuft on the abdomen, gold blossom buds on the crown between the feelers, a gold girth round the waist. (3) The stance below.
- **Stance (rest groups `wing`, `head`, `abd`).** The fore wings lifted 12 degrees higher (a mirrored group: both rise), the head cocked 6 degrees, the abdomen curled up 12 degrees behind it with its tuft: the outline is an open V of wings over a curled tail, not a box with panels.
- **Face intent.** Its own `gem` eyes kept (an amethyst iris with an orchid diamond pupil in a lit gold rim), a small smile and heart cheeks: a gentle, dreamy night creature. The face is not changed and nothing crosses it; the forehead diamond above it is the crown's.
- **Three values (rule 8).** Body mauve; the plum bands, legs and feelers a step darker; the lilac ruff, wings, petals and moss a step lighter; the lit orchid (eyespots, panes, moth wings) and one gold metal. The satellites are never the body's mauve.
- **Must-nots.** No fierce brow; nothing over the face; no loose boxes in the ring; the wings stay under the 3.5-stud ceiling (an 18-degree raise reached 3.53: 12); height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # six thin legs
  - {name: Leg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, -0.4375], mirror: x}
  - {name: MidLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, 0.1875], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, 0.8125], mirror: x}
  # the abdomen behind, banded in plum, a dark tuft at its end; the big head in front
  - {name: Abdomen, slot: Body, size: [1.5, 1.25, 2.25], at: [0, 1.125, 1.125], bevel: true, pose: abd}
  - {name: Band, slot: BodyDark, size: [1.75, 1.5, 0.25], at: [0, 1.125, 1], pose: abd}
  - {name: Band2, slot: BodyDark, size: [1.75, 1.5, 0.25], at: [0, 1.125, 1.75], pose: abd}
  - {name: Tuft, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 1, 2.5], pose: abd}
  - {name: Head, slot: Body, size: [2, 1.75, 1.5], at: [0, 1.625, -0.75], bevel: true, pose: head}
  # a shaggy lilac ruff round the neck: three steps of wool, widest at the top and proud of the head's sides, a tuft rising at each
  # shoulder, and one step of it on the crown
  - {name: Ruff, slot: Accessory, size: [2.5, 0.25, 0.75], at: [0, 2, 0.125], material: wool, pose: head}
  - {name: Ruff2, slot: Accessory, size: [2.25, 0.375, 0.75], at: [0, 1.6875, 0.125], material: wool, pose: head}
  - {name: Ruff3, slot: Accessory, size: [1.75, 0.25, 0.75], at: [0, 1.375, 0.125], material: wool, pose: head}
  - {name: RuffTuft, slot: Accessory, size: [0.25, 0.5, 0.5], at: [1.375, 2.25, 0.125], mirror: x, material: wool, pose: head}
  - {name: Crest, slot: Accessory, size: [1.25, 0.25, 0.5], at: [0, 2.625, -0.25], material: wool, pose: head}
  # the stepped crystal diamond on the forehead, over the face plate, in sixteenth-stud plates
  - {name: Emblem, slot: Trim, size: [0.125, 0.0625, 0.0625], at: [0, 2.40625, -1.53125], material: crystal, pose: head}
  - {name: Emblem2, slot: Trim, size: [0.25, 0.0625, 0.0625], at: [0, 2.34375, -1.53125], material: crystal, pose: head}
  - {name: Emblem3, slot: Trim, size: [0.375, 0.0625, 0.0625], at: [0, 2.28125, -1.53125], material: crystal, pose: head}
  - {name: Emblem4, slot: Trim, size: [0.25, 0.0625, 0.0625], at: [0, 2.21875, -1.53125], material: crystal, pose: head}
  - {name: Emblem5, slot: Trim, size: [0.125, 0.0625, 0.0625], at: [0, 2.15625, -1.53125], material: crystal, pose: head}
  # two slender feathered antennae leaning apart 20 degrees: a stalk, two stepped feather plates on its outer side and a lit tip (they tilt)
  - {name: Stalk, slot: BodyDark, size: [0.125, 0.75, 0.0625], at: [0.625, 2.875, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.5, 2.5, -0.5625], pose: head}
  - {name: Feather, slot: BodyDark, size: [0.25, 0.5, 0.0625], at: [0.8125, 2.875, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.5, 2.5, -0.5625], pose: head}
  - {name: Feather2, slot: BodyDark, size: [0.1875, 0.25, 0.0625], at: [1.03125, 2.8125, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.5, 2.5, -0.5625], pose: head}
  - {name: AntennaTip, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.75, 3.3125, -0.5625], shape: ico1, mirror: x, moves: antenna, pivot: [0.5, 2.5, -0.5625], pose: head}
  # the hero: the crystal fore wings spread wide and lifted 25 degrees, and (Polish w1) pitched 25 degrees about their own span, leading
  # edge down and trailing edge up, so their faces turn to the front and the three-quarter camera sees the eyespots, not an edge; a lobe
  # stepped out behind, a plum edge along the outer rim, a gold-ringed orchid eyespot on each (they beat)
  - {name: ForeWing, slot: Accessory, size: [2, 0.125, 1.75], at: [1.6875, 2.1875, 0.375], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: WingLobe, slot: Accessory, size: [1, 0.125, 0.5], at: [1.84375, 2.78125, 1.40625], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: WingEdge, slot: BodyDark, size: [0.125, 0.25, 1.75], at: [2.5, 2.625, 0.34375], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], pose: wing}
  - {name: EyeRing, slot: Trim, size: [0.625, 0.125, 0.625], at: [1.75, 2.375, 0.3125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: metal, pose: wing}
  - {name: Eyespot, slot: Glow, size: [0.375, 0.125, 0.375], at: [1.75, 2.40625, 0.28125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], pose: wing}
  # the smaller hind wings, low behind, 15 degrees up and pitched 15 degrees the same way, a plum edge on each (they beat a little behind)
  - {name: HindWing, slot: Accessory, size: [1.25, 0.125, 1.5], at: [1.375, 1.6875, 1.625], rot: [-15, 0, 15], mirror: x, moves: hindwing, pivot: [0.75, 1.5, 1.625], material: crystal}
  - {name: HindEdge, slot: BodyDark, size: [0.125, 0.1875, 1.5], at: [1.96875, 1.84375, 1.625], rot: [-15, 0, 15], mirror: x, moves: hindwing, pivot: [0.75, 1.5, 1.625]}
  # Rare pass w1, the signature piece: stained-glass wings, panes of lit orchid glass and gold glass laid on each fore wing round its
  # eyespot and on each hind wing, the lilac wing between them the leading; they beat with the wing and flash on the flourish
  - {name: Pane0, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.1875, 1.8125, -0.125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane1, slot: Trim, size: [0.25, 0.0625, 0.25], at: [1.09375, 2, 0.34375], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane2, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1, 2.1875, 0.78125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane3, slot: Trim, size: [0.25, 0.0625, 0.25], at: [2.3125, 2.34375, -0.125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane4, slot: Glow, size: [0.25, 0.0625, 0.25], at: [2.125, 2.71875, 0.78125], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane5, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.875, 2.0625, -0.21875], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: Pane6, slot: Trim, size: [0.25, 0.0625, 0.25], at: [1.65625, 2.5625, 0.90625], rot: [-25, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.375], material: crystal, pose: wing}
  - {name: HindPane0, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.625, 1.75, 1.25], rot: [-15, 0, 15], mirror: x, moves: hindwing, pivot: [0.75, 1.5, 1.625], material: crystal}
  - {name: HindPane1, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.5625, 1.9375, 1.96875], rot: [-15, 0, 15], mirror: x, moves: hindwing, pivot: [0.75, 1.5, 1.625], material: crystal}
  - {name: HindPane2, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.125, 1.71875, 1.59375], rot: [-15, 0, 15], mirror: x, moves: hindwing, pivot: [0.75, 1.5, 1.625], material: crystal}
  # alien anatomy: a shard of gold crystal circling over its back
  - {name: Shard, slot: Trim, size: [0.25, 0.375, 0.25], at: [0, 3, 0.75], shape: ico1, moves: shard, pivot: [0, 3, 0.75], material: crystal}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: lilac moss pads with a lit tuft on the abdomen's top (they curl up with it)
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.375, 1.8125, 1.375], mirror: x, pose: abd, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [0.4375, 1.9375, 1.375], mirror: x, pose: abd, material: moss}
  - {name: Mossc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 2.0625, 1.3125], mirror: x, pose: abd, material: moss}
  # gold blossom buds on the crown's step, between the feelers (they turn with the head)
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.4375, 2.875, -0.1875], mirror: x, pose: head, material: wood}
  - {name: Budb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.4375, 3.0625, -0.1875], mirror: x, pose: head}
  - {name: Budc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.4375, 3.1875, -0.1875], mirror: x, pose: head}
  # a gold girth: a quarter stud wide, an eighth proud, round the waist between the head and the abdomen
  - {name: Girth, slot: Trim, size: [1.75, 1.5, 0.25], at: [0, 1.125, 0.375], material: metal}
  # the satellite set (`swarm`, one wide ring clear of the wings, the front low): three little moths and three moonflowers, in lit orchid, gold and pale lilac
  - {name: Sat0a, slot: Trim, size: [0.125, 0.5, 0.25], at: [1.625, 0.875, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat0b, slot: Trim, size: [0.125, 0.125, 0.25], at: [1.5, 1.1875, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat0c, slot: Trim, size: [0.125, 0.125, 0.25], at: [1.75, 1.1875, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat0d, slot: Glow, size: [0.375, 0.25, 0.125], at: [1.375, 1, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat0e, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.4375, 0.75, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat0f, slot: Glow, size: [0.375, 0.25, 0.125], at: [1.875, 1, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat0g, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.8125, 0.75, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat1a, slot: Trim, size: [0.25, 0.25, 0.25], at: [3.1875, 1.8125, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat1b, slot: Accessory, size: [0.25, 0.25, 0.25], at: [3.1875, 2.0625, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat1c, slot: Accessory, size: [0.25, 0.25, 0.25], at: [3.1875, 1.5625, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat1d, slot: Accessory, size: [0.25, 0.25, 0.25], at: [2.9375, 1.8125, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat1e, slot: Accessory, size: [0.25, 0.25, 0.25], at: [3.4375, 1.8125, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat1f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [3.1875, 1.8125, 0.34375], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat1g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [3.1875, 1.8125, 0.65625], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat2a, slot: Trim, size: [0.125, 0.5, 0.25], at: [1.625, 2.25, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat2b, slot: Trim, size: [0.125, 0.125, 0.25], at: [1.75, 2.5625, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat2c, slot: Trim, size: [0.125, 0.125, 0.25], at: [1.5, 2.5625, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat2d, slot: Glow, size: [0.375, 0.25, 0.125], at: [1.875, 2.375, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat2e, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.8125, 2.125, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat2f, slot: Glow, size: [0.375, 0.25, 0.125], at: [1.375, 2.375, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat2g, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.4375, 2.125, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat3a, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.625, 2.1875, 3.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat3b, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.625, 2.4375, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat3c, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.625, 1.9375, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat3d, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.375, 2.1875, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat3e, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.875, 2.1875, 3.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat3f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.625, 2.1875, 3.40625], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat3g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.625, 2.1875, 3.09375], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat4a, slot: Trim, size: [0.125, 0.5, 0.25], at: [-3.1875, 1.25, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat4b, slot: Trim, size: [0.125, 0.125, 0.25], at: [-3.3125, 1.5625, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat4c, slot: Trim, size: [0.125, 0.125, 0.25], at: [-3.0625, 1.5625, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat4d, slot: Glow, size: [0.375, 0.25, 0.125], at: [-3.4375, 1.375, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat4e, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-3.375, 1.125, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat4f, slot: Glow, size: [0.375, 0.25, 0.125], at: [-2.9375, 1.375, 0.5], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat4g, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-3, 1.125, 0.5], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat5a, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.625, 0.8125, -2.25], moves: swarm, pivot: [0, 1.6, 0.5], material: metal}
  - {name: Sat5b, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.625, 1.0625, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat5c, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.625, 0.5625, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat5d, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.875, 0.8125, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat5e, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.375, 0.8125, -2.25], moves: swarm, pivot: [0, 1.6, 0.5]}
  - {name: Sat5f, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.625, 0.8125, -2.40625], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  - {name: Sat5g, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.625, 0.8125, -2.09375], moves: swarm, pivot: [0, 1.6, 0.5], material: crystal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.75-stud front is 14 rows; the eyes, the mouth and the cheeks are on the face plate, the crystal diamond on the forehead over it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `gem`, an Epic design, a deep amethyst iris with an orchid diamond pupil, pale lilac facets and a lit gold rim, at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, five frames). A small smile and heart cheeks.

```yaml
eyes:
  key: gem
  colours: {iris: "#5B2E91", pupil: glow, iris2: "#C9B3FF", rim: trim}
  mouth: smile
  cheeks: hearts
  plate: [1.75, 0.875]
  at: [0, 1.4375]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the fore wings beat, the hind wings beat a little behind them, the antennae tilt, the gold shard circles and spins, the moth breathes, the face blinks and glints. Eight moving things (seven objects and the blink; an Epic needs five). The flourish, every 10 s: a wing-shake, a hop with all four wings flared, the antennae swishing and the shard leaping.

```yaml
rig:
  rest:
    head: {rot: [0, 0, 6], pivot: [0, 0.9, -0.2], move: [0, -0.05, 0]}
    wing: {rot: [0, 0, 12], pivot: [0.75, 1.75, 0.375], mirror: true}
    abd: {rot: [-12, 0, 0], pivot: [0, 1.125, 0.1]}
  clips:
    wing: [{kind: flap, amp: 18, period: 1.8, axis: z}, {kind: sway, amp: 4, period: 3.6, axis: x, phase: 0.2}]
    hindwing: [{kind: flap, amp: 12, period: 1.8, axis: z, phase: 0.2}]
    antenna: [{kind: sway, amp: 9, period: 2.8, axis: z}, {kind: sway, amp: 6, period: 3.7, axis: x, phase: 0.35}]
    shard: [{kind: orbit, amp: 0.3, period: 5}, {kind: spin, amp: 360, period: 3, axis: y}, {kind: bob, amp: 0.08, period: 2.5}]
    root: [{kind: squash, amp: 0.03, period: 3}, {kind: bob, amp: 0.05, period: 1.8, phase: 0.3}]
    swarm: [{kind: spin, amp: 360, period: 20, axis: y}, {kind: bob, amp: 0.05, period: 3}]
    face: [{kind: blink, period: 5}]
  flourish:
    every: 10
    length: 2.5
    moves:
      - {part: root, kind: hop, amp: 0.3, at: 0, for: 0.7}
      - {part: wing, kind: flare, amp: 35, axis: z, at: 0, for: 1.2}
      - {part: hindwing, kind: flare, amp: 25, axis: z, at: 0.15, for: 1.1}
      - {part: root, kind: turn, amp: 360, axis: y, at: 0.3, for: 1.6}
      - {part: antenna, kind: swish, amp: 15, axis: z, at: 0.6, for: 1.2}
      - {part: shard, kind: hop, amp: 0.35, at: 0.9, for: 0.9}
      - {part: shard, kind: pop, amp: 0.3, at: 1.2, for: 0.6}
      - {part: wing, kind: swish, amp: 12, axis: z, at: 1.4, for: 1}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Panes | `Pane0` (wing) | 0.21, 0.53, -0.17 | a burst of orchid motes off the wings on the flourish | BackR |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Gloomoth.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Gloomoth.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Gloomoth_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Gloomoth_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Gloomoth_idle.png]]

The concept sheet, drawn from the parts table above: [[Gloomoth_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud). Materials: crystal on the four wings, the lobes, the forehead diamond and the shard (light diagonals), wool on the ruff (shag with lilac flecks), metal on the eye rings, skin elsewhere; the eyespots and antenna tips are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's busy antennae and collar-block ruff). Each antenna is one flat blade 0.625 x 1.125 with a narrower feather plate stepped along its outer edge and the lit tip (3 blocks a side for the old 5: a stalk and three teeth read as a rake). The ruff is three steps of wool, 2.5 wide at the top and proud of the head's sides, narrowing under, with a tuft rising at each shoulder, and the crown tuft is two steps. Status review.

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the fore wings stood up 65 degrees like sails and read as two white boards behind the head, and the eyespots faced sideways where the game's high camera would not see them. Round 2: the fore wings 2 studs square spread wide at 25 degrees (a 6-stud span) with the eyespots and gold rings on their tops, the hind pair low at 15; the silhouette against Syrinx fell from 0.69 to 0.50. Wanted for: the first wings in Verdant that catch the light. Still cheap: the comb antennae are busy (two stalks and six teeth), the ruff reads as a white collar block, the emblem on the crown is small. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, three rounds. Round 1: from 3.64 studs to 3.44 by slimming the antennae (a 0.125 stalk with two sixteenth-stud feather plates and the lit tip, for the old 0.625 blades), the fore wings each with a rear lobe, the hind wings with plum edges and moving, a gold crystal shard circling over the back, a crystal emblem on the forehead; its own `gem` eyes (amethyst iris, orchid diamond pupil, lit gold rim) with a smile and heart cheeks. Round 2: the moon-cream wings vanished against the pale backdrop and the three-cell emblem read as a plus (the medical-cross lesson of World 2), so the accent went to a pale lilac crystal `#D9C8FF` (wings and ruff) and the emblem is a five-row stepped diamond in sixteenth-stud plates. Seven moving objects and the blink; a flourish every 10 s (a hop shaking out all four wings, antennae swishing, the shard leaping). Overlap 0.992 to 0.998, 45 blocks. Wanted for: jewelled eyes and lit eyespots on a soft moth, a step up from every Rare at the same height. Still weak: from the three-quarter camera the fore wings are near edge-on (the game's high camera sees their tops); the six legs are still thin posts. Status review.
- 2026-10-21, Polish w1, one round. The fore wings were spread flat and lifted 25 degrees, so the three-quarter camera saw them almost edge-on and the eyespots were slivers: each wing and everything on it now also pitches 25 degrees about its own span (rot [-25, 0, 25], every centre turned about the wing's pivot), leading edge down and trailing edge up, so the faces turn toward the front and the gold-ringed eyespots read from the review angle; the hind wings pitch 15 the same way. Not the 65-degree sails of the 2026-10-19 round 1 (two white boards behind the head): the wings still spread wide and low. 45 blocks. Overlap 0.995 to 0.998. Honest read: the wings now read as a moth's wings showing their eyespots, the first thing seen from the review angle. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: stained-glass wings, seven panes on each fore wing (lit orchid glass and gold glass, laid round the eyespot in the wing's own pitched frame) and three on each hind wing; the glow is a deep orchid `#B832E8` (the pale `#E08CFF` washed to white). The flourish snaps the wings open wider (35 degrees) with a full turn and a shard pop. 65 blocks, eight moving things. Honest read: the moth's wings read as stained glass from the three-quarter view; the body is unchanged. Status review.
