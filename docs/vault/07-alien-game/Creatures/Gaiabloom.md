---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Gaiabloom
name: Gaira
world: 1
tier: Legendary
status: review
element: Bloom
height: 3.5
blocks: 245
tris: 3134
bevel_width: 0.1
bevel_segments: 2
palette: ["#F0E6CE", "#6B4A2E", "#4FB84E", "#F5B83D", "#F0287E", "#1F1A17"]
roles: [body, second, accent, trim, glow, ink]
hero: Antler
vfx: "touches the ground (Legendary), six layers in Effects.luau: four pink petals orbit the crown half a stud out, a little flower of four yellow petals pops in each footprint every 2.4 s, a warm gold light pulses over the antlers, a green leaf drifts off its back every so often, and on the flourish the antlers shed a burst of eighteen pink petals while a pink ring rolls out over the ground from its hooves. The flourish (every 12 s) is a spring blessing: a hop and a full turn, the flower crown popping, the antler trees shaking, the ears flared and the butterfly leaping"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Gaiabloom_sheet.svg]]"
render: "[[Gaiabloom_tq_cells.jpg]]"
glb: ""
overlap: [0.992, 0.994, 0.996, 0.993]
vfx_render: "[[Gaiabloom_vfx_cells.jpg]]"
cells_render: "[[Gaiabloom_tq_cells.jpg]]"
idle_render: "[[Gaiabloom_idle.png]]"
bar_world: Verdant
bar_kit: 10
bar_pieces: [bark_band, blossom_bud, moss_cells, sap_drop]
bar_stance: "a prancing stag: the head lifted 8 degrees as it scents the breeze, the right foreleg raised mid-step, the tail cocked, a great bloom opening behind it and tulips and gilded seeds circling"
bar_satellites: 7
bar_orbit: blooms
bar_backdrop: bloom
---
# Gaiabloom (Gaira), Legendary, World 1 Verdant

A small ivory fawn-stag, 3.45 studs to the top of its antler trees (B45: it was 6, the size of the player; a slender deer stands tall in the band by its antlers and legs, not its tier). A big square head with a snout (a muzzle block proud of the lower face, a dark nose on its tip and a smile in sixteenth-stud ink cells), drooping ears, slim legs on gold hooves, a moss ruff under the chin with one blossom in it, a moss mane stepping down from the back of its head to a moss saddle-blanket that drapes half down each flank with a gold hem and lit blossoms on it (the forest has grown over its back), and lit pink dapples along its flanks under the blanket like a fawn's spots. On its head the antlers are two little trees in bloom, each leaning out 15 degrees, a bark trunk in a gold band with a branch out and a tine up, three moss leaf clumps and four lit pink blossoms; between them a crown of moss and blossoms floats a sixteenth of a stud over the head and turns slowly, and a pink butterfly flutters round the antlers. Its tail is a white tuft with a leaf on it. Concept row in `src/shared/data/Species.luau`: "stag, tree antlers, flowers bloom where it steps". Element: Bloom (`Effects.luau`); [[Roster-Redesign]] section 2 gives the footprint flowers, the orbiting petals and the ground ring. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** Not its size any more: it stands at the avatar's chest like the Rares do. What makes it Legendary is everything at that height: 78 blocks, most of them sixteenth-stud cells (the blossoms, the crown, the smile, the dapples, the butterfly); its own `bloom` eyes on a 32-pixel face plate no Epic has, a flower of six petals in pink and pale gold turning slowly round a gold heart inside a moss-green ring, with star cheeks; eight moving things (the turning crown, two swaying antler trees, two ears, the tail, the butterfly, the blink); and its light reaches the ground, with a flourish every 12 s that reads from across the meadow: it springs and turns, the crown pops, the trees shake out a burst of petals and a pink ring rolls over the grass. Cuter, never fiercer: a fawn with flowers for antlers and a flower in each eye.

**Hero block.** The `Antler` pair, two blossoming trees on a fawn's head, unique in Verdant.

**Moving parts (seven objects and the blink).** `halo` (the floating flower crown: it turns once in 12 s), `antlerR` and `antlerL` (each tree, band to blossoms: they sway like trees in a breeze), `earR` and `earL` (they droop and lift), `tail` (the tuft and its leaf: it flicks), `butterfly` (it circles the antlers and flutters); the face plate blinks, glints and turns its petals. Rare pass w1: `cape` (the glass-petal mantle over the back: it lifts and settles, flares on the flourish) and `butterfly2L` (a second butterfly, smaller, circling the other way) make nine objects and the blink.

**Alien anatomy.** Antlers that are living trees, a crown of flowers that floats and turns on its own, a body that lights up in a pattern, and a butterfly that keeps it company.

**World motif (Verdant).** The moss cell, here as the leaf clumps of the antlers, the crown and the ruff, in sixteenth-stud steps.

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`gaiabloom()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A blossoming fawn-stag, spring itself in a gilded frame. Kept: name, anatomy (blossom-tree antlers, the floating flower crown, the glass-petal mantle on its back, the gilded medallion, a butterfly or two), the `bloom` eyes on a 32-pixel plate, height 3.5.
- **Gains (visible parts).** (1) The backdrop: a flower 3 studs across behind the rump (a gold rim, a moss wreath round a dark bark heart so the ivory fawn stands out against it) with eight stepped lit pink petals, a quarter stud deep, turning once in 20 s on the `bloom` object. (2) Seven satellites on a ring in front of it (the `blooms` object, the front low): four tulips of lit pink glass (a green stem, a gold stamen on both faces) and three gilded seeds (a gold diamond with a lit pink core), three quarters of a stud and more. (3) Verdant kit, ten pieces: green moss pads on the ground beside the hind hooves, lit pink blossom buds on the head's top front corners, amber sap drops under the ruff, gold cuffs (a quarter stud tall, an eighth proud) round all four legs. (4) The stance below.
- **Stance (rest groups `head`, `foreR`, `tail`).** A prancing stag: the head (antlers, crown, ears, ruff, medallion and the face) lifted 8 degrees and set a tenth lower as it scents the breeze, the right foreleg raised 55 degrees mid-step, the tail cocked up 20 degrees.
- **Face intent.** Its own `bloom` eyes kept (a flower of six lit petals turning round a gold heart in a moss ring), star cheeks and the smile on the muzzle: a gentle, wide-eyed spring spirit; the Legendary eye already has the most light of the world and the face is not changed. Nothing crosses it (the satellite ring's front is low, at the chin's level and below).
- **Three values (rule 8).** Body ivory; the bark brown (the backdrop's heart, antlers, legs' shadows) a step darker; the moss green wreath and the gold rim a mid value; the lit pink (cape, petals, tulips, seeds' cores) the one light. The backdrop is a third value with a dark centre against the ivory body.
- **Must-nots.** No fierce brow; no satellite in the face's arc; the ring stays in front of the backdrop (a ring behind a solid disc is hidden); no piece under a quarter stud added for its own sake; height stays in 2 to 3.5 studs (the lifted head needed its 0.1 move).

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 1.75, -0.875], bevel: true, pose: head}
  - {name: Torso, slot: Body, size: [1.5, 1, 2.25], at: [0, 1.25, 0.75], bevel: true}
  # slim deer legs on gold hooves
  - {name: FrontLeg, slot: Body, size: [0.375, 0.625, 0.375], at: [0.5, 0.4375, -0.125], pose: foreR}
  - {name: FrontLegL, slot: Body, size: [0.375, 0.625, 0.375], at: [-0.5, 0.4375, -0.125]}
  - {name: HindLeg, slot: Body, size: [0.375, 0.625, 0.375], at: [0.5, 0.4375, 1.5], mirror: x}
  - {name: Hoof, slot: Trim, size: [0.375, 0.125, 0.375], at: [0.5, 0.0625, -0.125], material: metal, pose: foreR}
  - {name: HoofL, slot: Trim, size: [0.375, 0.125, 0.375], at: [-0.5, 0.0625, -0.125], material: metal}
  - {name: HindHoof, slot: Trim, size: [0.375, 0.125, 0.375], at: [0.5, 0.0625, 1.5], mirror: x, material: metal}
  # drooping ears (they lift and droop), a white tuft of a tail with a leaf on it (it flicks)
  - {name: Ear, slot: Body, size: [0.5, 0.25, 0.125], at: [1.1875, 2.25, -0.625], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [1, 2.3125, -0.625], pose: head}
  - {name: Tail, slot: Body, size: [0.375, 0.375, 0.25], at: [0, 1.625, 2], moves: tail, pivot: [0, 1.625, 1.875], pose: tail}
  - {name: TailLeaf, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0, 1.875, 2], moves: tail, pivot: [0, 1.625, 1.875], material: moss, pose: tail}
  # the snout: a muzzle block proud of the lower face, a dark nose on its tip, a smile of sixteenth-stud ink cells under it
  - {name: Muzzle, slot: Body, size: [1, 0.5, 0.375], at: [0, 1.3125, -1.9375], pose: head}
  - {name: Nose, slot: Eye, size: [0.25, 0.125, 0.0625], at: [0, 1.5, -2.15625], pose: head}
  - {name: Smile, slot: Eye, size: [0.25, 0.0625, 0.0625], at: [0, 1.21875, -2.15625], pose: head}
  - {name: SmileCorner, slot: Eye, size: [0.0625, 0.0625, 0.0625], at: [0.15625, 1.28125, -2.15625], mirror: x, pose: head}
  # a ruff of moss cells under the chin (Verdant's motif), one blossom in it
  - {name: Ruff, slot: Accessory, size: [1.25, 0.25, 0.5], at: [0, 0.875, -1.25], material: moss, pose: head}
  - {name: Ruff2, slot: Accessory, size: [0.625, 0.125, 0.375], at: [0, 0.6875, -1.25], material: moss, pose: head}
  - {name: RuffBloom, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 0.8125, -1.5625], pose: head}
  # the hero: tree antlers in bloom: a bark trunk in a gold band, a branch out and a tine up, three moss leaf clumps, four lit blossoms;
  # each tree leans out 15 degrees and sways on its band
  - {name: AntlerBand, slot: Trim, size: [0.25, 0.0625, 0.25], at: [0.5, 2.53125, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: metal, pose: head}
  - {name: Antler, slot: BodyDark, size: [0.125, 0.5625, 0.125], at: [0.59375, 2.84375, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: wood, pose: head}
  - {name: AntlerBranch, slot: BodyDark, size: [0.375, 0.125, 0.125], at: [0.84375, 2.84375, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: wood, pose: head}
  - {name: AntlerTine, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [1.03125, 3, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: wood, pose: head}
  - {name: LeafTop, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0.6875, 3.21875, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: moss, pose: head}
  - {name: LeafOut, slot: Accessory, size: [0.375, 0.25, 0.375], at: [1.15625, 3.21875, -0.875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: moss, pose: head}
  - {name: LeafBack, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.59375, 3.0625, -0.5], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], material: moss, pose: head}
  - {name: Blossom, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.65625, 3.375, -1.0625], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], pose: head}
  - {name: Blossom2, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.21875, 3.21875, -1.125], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], pose: head}
  - {name: Blossom3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 3.21875, -0.4375], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], pose: head}
  - {name: Blossom4, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.90625, 3.25, -1.1875], rot: [0, 0, -15], mirror: x, moves: antler, pivot: [0.5, 2.5, -0.875], pose: head}
  # the floating flower crown: a ring of moss cells with cut corners a sixteenth over the head, four lit blossoms on it; it turns (the `halo`)
  - {name: Crown, slot: Accessory, size: [0.75, 0.125, 0.125], at: [0, 2.625, -1.5625], moves: halo, pivot: [0, 2.625, -0.875], material: moss, pose: head}
  - {name: CrownBack, slot: Accessory, size: [0.75, 0.125, 0.125], at: [0, 2.625, -0.1875], moves: halo, pivot: [0, 2.625, -0.875], material: moss, pose: head}
  - {name: CrownSide, slot: Accessory, size: [0.125, 0.125, 0.75], at: [0.6875, 2.625, -0.875], mirror: x, moves: halo, pivot: [0, 2.625, -0.875], material: moss, pose: head}
  - {name: CrownCorner, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.5625, 2.625, -1.4375], mirror: x, moves: halo, pivot: [0, 2.625, -0.875], material: moss, pose: head}
  - {name: CrownCorner2, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.5625, 2.625, -0.3125], mirror: x, moves: halo, pivot: [0, 2.625, -0.875], material: moss, pose: head}
  - {name: CrownBloom, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.75, -1.5625], moves: halo, pivot: [0, 2.625, -0.875], pose: head}
  - {name: CrownBloom2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.75, -0.1875], moves: halo, pivot: [0, 2.625, -0.875], pose: head}
  - {name: CrownBloom3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 2.75, -0.875], mirror: x, moves: halo, pivot: [0, 2.625, -0.875], pose: head}
  # Polish w1: a mossy saddle so the torso is not a plain box from the side: a moss mane stepping down from the head's back, a moss
  # blanket over the back that drapes half down each flank, a gold hem along its edge and lit blossoms on it; lit dapples below it
  - {name: Mane, slot: Accessory, size: [0.75, 0.5, 0.25], at: [0, 2, 0.125], material: moss}
  - {name: Mane2, slot: Accessory, size: [0.5, 0.25, 0.25], at: [0, 1.875, 0.375], material: moss}
  - {name: Saddle, slot: Accessory, size: [1.375, 0.125, 1.375], at: [0, 1.8125, 0.875], material: moss}
  # Rare pass w1: the drape is a stained-glass panel down each flank, moss and lit pink glass in quarter-stud strips under the gold hem
  - {name: Drape0, slot: Accessory, size: [0.0625, 0.5, 0.25], at: [0.78125, 1.5, 0.3125], mirror: x, material: moss}
  - {name: Drape1, slot: Glow, size: [0.0625, 0.5, 0.25], at: [0.78125, 1.5, 0.5625], mirror: x, material: crystal}
  - {name: Drape2, slot: Accessory, size: [0.0625, 0.5, 0.25], at: [0.78125, 1.5, 0.8125], mirror: x, material: moss}
  - {name: Drape3, slot: Glow, size: [0.0625, 0.5, 0.25], at: [0.78125, 1.5, 1.0625], mirror: x, material: crystal}
  - {name: Drape4, slot: Accessory, size: [0.0625, 0.5, 0.25], at: [0.78125, 1.5, 1.3125], mirror: x, material: moss}
  - {name: Drape5, slot: Accessory, size: [0.0625, 0.5, 0.125], at: [0.78125, 1.5, 1.5], mirror: x, material: moss}
  - {name: DrapeHem, slot: Trim, size: [0.0625, 0.0625, 1.375], at: [0.84375, 1.28125, 0.875], mirror: x, material: metal}
  # Rare pass w1, the signature piece: a mantle of glass petals over the back, six rows from the mane to the rump, pink lit glass
  # between moss rows like a stained-glass window, every row edged in gold (Legendary gilding); it lifts and settles like a breeze
  # under it and flares up on the flourish (`cape`)
  - {name: Petal0, slot: Accessory, size: [0.5, 0.0625, 0.25], at: [0, 1.90625, 0.5], moves: cape, pivot: [0, 1.90625, 0.375], material: moss}
  - {name: PetalGild0, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.3125, 1.90625, 0.5], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  - {name: Petal1, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0, 1.90625, 0.75], moves: cape, pivot: [0, 1.90625, 0.375], material: crystal}
  - {name: PetalGild1, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.4375, 1.90625, 0.75], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  - {name: Petal2, slot: Accessory, size: [1, 0.0625, 0.25], at: [0, 1.90625, 1], moves: cape, pivot: [0, 1.90625, 0.375], material: moss}
  - {name: PetalGild2, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.5625, 1.90625, 1], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  - {name: Petal3, slot: Glow, size: [1, 0.0625, 0.25], at: [0, 1.90625, 1.25], moves: cape, pivot: [0, 1.90625, 0.375], material: crystal}
  - {name: PetalGild3, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.5625, 1.90625, 1.25], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  - {name: Petal4, slot: Accessory, size: [1.25, 0.0625, 0.25], at: [0, 1.90625, 1.5], moves: cape, pivot: [0, 1.90625, 0.375], material: moss}
  - {name: PetalGild4, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.6875, 1.90625, 1.5], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  - {name: Petal5, slot: Glow, size: [1.25, 0.0625, 0.25], at: [0, 1.90625, 1.75], moves: cape, pivot: [0, 1.90625, 0.375], material: crystal}
  - {name: PetalGild5, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0.6875, 1.90625, 1.75], mirror: x, moves: cape, pivot: [0, 1.90625, 0.375], material: metal}
  # Rare pass w1: a gilded leaf medallion with a lit heart on the ruff (Legendary gilding at the sixteenth grid)
  - {name: Medallion, slot: Trim, size: [0.25, 0.25, 0.0625], at: [0, 0.8125, -1.53125], material: metal, pose: head}
  - {name: MedallionTip, slot: Trim, size: [0.125, 0.0625, 0.0625], at: [0, 0.65625, -1.53125], material: metal, pose: head}
  - {name: MedallionHeart, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0, 0.8125, -1.59375], material: crystal, pose: head}
  # Rare pass w1: a second butterfly, smaller, circling the other way behind the left antler
  - {name: Moth, slot: BodyDark, size: [0.125, 0.0625, 0.125], at: [-1.1875, 2.84375, 0.25], moves: butterfly2, pivot: [-1.1875, 2.8125, 0.25]}
  - {name: MothWing, slot: Glow, size: [0.125, 0.0625, 0.25], at: [-1.3125, 2.90625, 0.25], moves: butterfly2, pivot: [-1.1875, 2.8125, 0.25]}
  - {name: MothWing2, slot: Glow, size: [0.125, 0.0625, 0.25], at: [-1.0625, 2.90625, 0.25], moves: butterfly2, pivot: [-1.1875, 2.8125, 0.25]}
  - {name: Dapple, slot: Glow, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.0625, 0.375], mirror: x}
  - {name: Dapple2, slot: Glow, size: [0.0625, 0.125, 0.25], at: [0.78125, 0.9375, 1], mirror: x}
  - {name: Dapple4, slot: Glow, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, 1.6875], mirror: x}
  # alien anatomy: a pink butterfly that keeps it company, circling the antlers
  - {name: Butterfly, slot: BodyDark, size: [0.125, 0.0625, 0.25], at: [1.25, 3.03125, -2], moves: butterfly, pivot: [1.25, 3, -2]}
  - {name: ButterflyWing, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.0625, 3.09375, -2], moves: butterfly, pivot: [1.25, 3, -2]}
  - {name: ButterflyWing2, slot: Glow, size: [0.25, 0.0625, 0.25], at: [1.4375, 3.09375, -2], moves: butterfly, pivot: [1.25, 3, -2]}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: moss pads on the ground beside the hind hooves
  - {name: Mossa, slot: Body, size: [0.5, 0.125, 0.5], at: [1, 0.0625, 1.5], mirror: x, material: moss}
  - {name: Mossb, slot: Body, size: [0.375, 0.125, 0.25], at: [1.0625, 0.1875, 1.5], mirror: x, material: moss}
  - {name: Mossc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.9375, 0.3125, 1.4375], mirror: x, material: moss}
  # lit pink blossom buds on the head's top front corners (they turn with the lifted head)
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.9375, 2.625, -1.4375], mirror: x, pose: head, material: wood}
  - {name: Budb, slot: Glow, size: [0.375, 0.125, 0.125], at: [0.9375, 2.8125, -1.4375], mirror: x, pose: head}
  - {name: Budc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.9375, 2.9375, -1.4375], mirror: x, pose: head}
  # amber sap drops hanging from under the ruff (they go with the head)
  - {name: Sapa, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.5625, 0.6875, -1.1875], mirror: x, pose: head, material: metal}
  - {name: Sapb, slot: Trim, size: [0.25, 0.125, 0.25], at: [0.5, 0.5625, -1.25], mirror: x, pose: head, material: metal}
  - {name: Sapc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5625, 0.4375, -1.1875], mirror: x, pose: head, material: crystal}
  # gold cuffs, a quarter stud tall and an eighth proud, round all four legs (the raised foreleg's goes with it)
  - {name: CuffH, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.5, 0.4375, 1.5], mirror: x, material: metal}
  - {name: CuffFL, slot: Trim, size: [0.5, 0.25, 0.5], at: [-0.5, 0.4375, -0.125], material: metal}
  - {name: CuffFR, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.5, 0.4375, -0.125], pose: foreR, material: metal}
  # the backdrop (`bloom`, it turns once in 20 s): a flower 3 studs across behind the rump, a gold rim, a moss wreath round a dark bark heart (so the ivory fawn stands out against it), eight stepped lit pink petals round it, a quarter stud deep
  - {name: Bloom0, slot: Trim, size: [1, 0.25, 0.25], at: [0, 0.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom1, slot: Trim, size: [0.5, 0.25, 0.25], at: [-0.75, 0.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom2, slot: Accessory, size: [1, 0.25, 0.25], at: [0, 0.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom3, slot: Trim, size: [0.5, 0.25, 0.25], at: [0.75, 0.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom4, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.125, 0.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom5, slot: Accessory, size: [2, 0.25, 0.25], at: [0, 0.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom6, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 0.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom7, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.125, 1.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom8, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-0.75, 1.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom9, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 1.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom10, slot: Accessory, size: [0.5, 0.25, 0.25], at: [0.75, 1.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom11, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 1.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom12, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.375, 1.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom13, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1, 1.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom14, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom15, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1, 1.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom16, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 1.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom17, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.375, 1.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom18, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1, 1.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom19, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom20, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1, 1.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom21, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 1.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom22, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.375, 1.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom23, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1, 1.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom24, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom25, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1, 1.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom26, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 1.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom27, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.375, 2.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom28, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1, 2.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom29, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 2.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom30, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1, 2.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom31, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.375, 2.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom32, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.125, 2.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom33, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-0.75, 2.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom34, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 2.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625]}
  - {name: Bloom35, slot: Accessory, size: [0.5, 0.25, 0.25], at: [0.75, 2.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom36, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 2.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom37, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.125, 2.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom38, slot: Accessory, size: [2, 0.25, 0.25], at: [0, 2.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom39, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.125, 2.625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom40, slot: Trim, size: [0.5, 0.25, 0.25], at: [-0.75, 2.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom41, slot: Accessory, size: [1, 0.25, 0.25], at: [0, 2.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: moss}
  - {name: Bloom42, slot: Trim, size: [0.5, 0.25, 0.25], at: [0.75, 2.875, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Bloom43, slot: Trim, size: [1, 0.25, 0.25], at: [0, 3.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: metal}
  - {name: Ray0, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 3.375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray1, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.1875, 2.9375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray2, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.3125, 3.0625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray3, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.5, 3.25, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray4, slot: Glow, size: [0.25, 0.5, 0.25], at: [1.625, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray5, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.875, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray6, slot: Glow, size: [0.25, 0.25, 0.25], at: [2.125, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray7, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.1875, 0.5625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray8, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.3125, 0.4375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray9, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.5, 0.25, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray10, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 0.125, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray11, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.1875, 0.5625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray12, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.3125, 0.4375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray13, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.5, 0.25, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray14, slot: Glow, size: [0.25, 0.5, 0.25], at: [-1.625, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray15, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.875, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray16, slot: Glow, size: [0.25, 0.25, 0.25], at: [-2.125, 1.75, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray17, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.1875, 2.9375, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray18, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.3125, 3.0625, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  - {name: Ray19, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.5, 3.25, 2.625], moves: bloom, pivot: [0, 1.75, 2.625], material: crystal}
  # the satellite set (`blooms`, one wide ring in front of the backdrop, the front low): four glass tulips and three gilded seeds, all lit pink and gold
  - {name: Sat0a, slot: Accessory, size: [0.125, 0.25, 0.125], at: [1, 0.8125, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat0b, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [1.15625, 0.75, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat0c, slot: Glow, size: [0.5, 0.25, 0.25], at: [1, 1.0625, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat0d, slot: Glow, size: [0.75, 0.25, 0.25], at: [1, 1.3125, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat0e, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.75, 1.5, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat0f, slot: Glow, size: [0.25, 0.125, 0.25], at: [1.25, 1.5, -2], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat0g, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [1, 1.21875, -2.15625], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat0h, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [1, 1.21875, -1.84375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1a, slot: Trim, size: [0.25, 0.125, 0.25], at: [2.25, 1.875, -0.4375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1b, slot: Trim, size: [0.5, 0.125, 0.25], at: [2.25, 1.75, -0.4375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1c, slot: Trim, size: [0.75, 0.25, 0.25], at: [2.25, 1.5625, -0.4375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1d, slot: Trim, size: [0.5, 0.125, 0.25], at: [2.25, 1.375, -0.4375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1e, slot: Trim, size: [0.25, 0.125, 0.25], at: [2.25, 1.25, -0.4375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat1f, slot: Glow, size: [0.25, 0.25, 0.0625], at: [2.25, 1.5625, -0.59375], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat1g, slot: Glow, size: [0.25, 0.25, 0.0625], at: [2.25, 1.5625, -0.28125], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat2a, slot: Accessory, size: [0.125, 0.25, 0.125], at: [1.8125, 2.0625, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat2b, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [1.65625, 2, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat2c, slot: Glow, size: [0.5, 0.25, 0.25], at: [1.8125, 2.3125, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat2d, slot: Glow, size: [0.75, 0.25, 0.25], at: [1.8125, 2.5625, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat2e, slot: Glow, size: [0.25, 0.125, 0.25], at: [2.0625, 2.75, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat2f, slot: Glow, size: [0.25, 0.125, 0.25], at: [1.5625, 2.75, 1.5], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat2g, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [1.8125, 2.46875, 1.65625], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat2h, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [1.8125, 2.46875, 1.34375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3a, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 2.6875, 2.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3b, slot: Trim, size: [0.5, 0.125, 0.25], at: [0, 2.5625, 2.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3c, slot: Trim, size: [0.75, 0.25, 0.25], at: [0, 2.375, 2.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3d, slot: Trim, size: [0.5, 0.125, 0.25], at: [0, 2.1875, 2.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3e, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 2.0625, 2.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat3f, slot: Glow, size: [0.25, 0.25, 0.0625], at: [0, 2.375, 2.53125], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat3g, slot: Glow, size: [0.25, 0.25, 0.0625], at: [0, 2.375, 2.21875], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat4a, slot: Accessory, size: [0.125, 0.25, 0.125], at: [-1.75, 1.875, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat4b, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [-1.90625, 1.8125, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat4c, slot: Glow, size: [0.5, 0.25, 0.25], at: [-1.75, 2.125, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat4d, slot: Glow, size: [0.75, 0.25, 0.25], at: [-1.75, 2.375, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat4e, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.5, 2.5625, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat4f, slot: Glow, size: [0.25, 0.125, 0.25], at: [-2, 2.5625, 1.5625], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat4g, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [-1.75, 2.28125, 1.71875], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat4h, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [-1.75, 2.28125, 1.40625], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5a, slot: Trim, size: [0.25, 0.125, 0.25], at: [-2.25, 1.625, -0.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5b, slot: Trim, size: [0.5, 0.125, 0.25], at: [-2.25, 1.5, -0.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5c, slot: Trim, size: [0.75, 0.25, 0.25], at: [-2.25, 1.3125, -0.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5d, slot: Trim, size: [0.5, 0.125, 0.25], at: [-2.25, 1.125, -0.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5e, slot: Trim, size: [0.25, 0.125, 0.25], at: [-2.25, 1, -0.375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat5f, slot: Glow, size: [0.25, 0.25, 0.0625], at: [-2.25, 1.3125, -0.53125], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat5g, slot: Glow, size: [0.25, 0.25, 0.0625], at: [-2.25, 1.3125, -0.21875], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat6a, slot: Accessory, size: [0.125, 0.25, 0.125], at: [-1, 0.6875, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat6b, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [-0.84375, 0.625, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: moss}
  - {name: Sat6c, slot: Glow, size: [0.5, 0.25, 0.25], at: [-1, 0.9375, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat6d, slot: Glow, size: [0.75, 0.25, 0.25], at: [-1, 1.1875, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat6e, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.25, 1.375, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat6f, slot: Glow, size: [0.25, 0.125, 0.25], at: [-0.75, 1.375, -1.9375], moves: blooms, pivot: [0, 1.6, 0.1], material: crystal}
  - {name: Sat6g, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [-1, 1.09375, -2.09375], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  - {name: Sat6h, slot: Trim, size: [0.125, 0.3125, 0.0625], at: [-1, 1.09375, -1.78125], moves: blooms, pivot: [0, 1.6, 0.1], material: metal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and the cheeks are on the face plate at 32 pixels a stud, the nose and the smile are on the muzzle block under it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `bloom`, a Legendary design, a flower of six glowing petals (blossom pink and pale gold) turning slowly round a gold heart inside a moss-green ring, a sparkle circling it, at 32 pixels a stud on a 1.75 x 0.75 stud plate (56 x 24 pixels, eleven frames: open, half, closed, two glints, six petal frames). Star cheeks; the smile is on the muzzle.

```yaml
eyes:
  key: bloom
  colours: {deep: "#2E6B2C", mid: glow, bright: "#FFE7A3", pupil: trim}
  mouth: none
  cheeks: stars
  plate: [1.75, 0.75]
  at: [0, 1.84375]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the crown turns, the antler trees sway, the ears lift and droop, the tail flicks, the butterfly circles and flutters, the fawn breathes, the face blinks, glints and turns its petals. Eight moving things (seven objects and the blink; a Legendary needs six). The flourish, every 12 s: a spring blessing, a hop and a full turn, the crown popping, the trees shaking, the ears flared and the butterfly leaping.

```yaml
rig:
  rest:
    head: {rot: [8, 0, 0], pivot: [0, 1.25, -0.3], move: [0, -0.1, 0]}
    foreR: {rot: [55, 0, 0], pivot: [0.5, 0.75, -0.125]}
    tail: {rot: [-20, 0, 0], pivot: [0, 1.625, 1.875]}
  clips:
    halo: [{kind: spin, amp: 360, period: 12, axis: y}, {kind: bob, amp: 0.04, period: 3}]
    antler: [{kind: sway, amp: 4, period: 4.2, axis: z, phase: 0.2}, {kind: sway, amp: 2, period: 2.9, axis: x, phase: 0.6}]
    cape: [{kind: sway, amp: 5, period: 3.8, axis: x}, {kind: sway, amp: 2, period: 5.1, axis: z, phase: 0.4}]
    ear: [{kind: sway, amp: 10, period: 3, axis: z}, {kind: wag, amp: 8, period: 5.5, axis: y, phase: 0.3}]
    tail: [{kind: wag, amp: 18, period: 2.5, axis: y}]
    butterfly: [{kind: orbit, amp: 0.3, period: 6}, {kind: bob, amp: 0.12, period: 1.5}, {kind: squash, amp: 0.25, period: 0.5, axis: x}]
    butterfly2: [{kind: orbit, amp: 0.25, period: 4.6, phase: 0.5}, {kind: bob, amp: 0.1, period: 1.3, phase: 0.2}, {kind: squash, amp: 0.25, period: 0.4, axis: x}]
    root: [{kind: squash, amp: 0.025, period: 3.6}]
    bloom: [{kind: spin, amp: 360, period: 20, axis: z}, {kind: bob, amp: 0.05, period: 4.4}]
    blooms: [{kind: spin, amp: 360, period: 18, axis: y}, {kind: bob, amp: 0.05, period: 3.4}]
    face: [{kind: blink, period: 5.2}]
  flourish:
    every: 12
    length: 4.2
    moves:
      - {part: root, kind: hop, amp: 0.35, at: 0, for: 0.8}
      - {part: cape, kind: flare, amp: -25, axis: x, at: 0, for: 1.4}
      - {part: ear, kind: flare, amp: 25, axis: z, at: 0.3, for: 1}
      - {part: antler, kind: swish, amp: 12, axis: z, at: 0.4, for: 1.6}
      - {part: halo, kind: pop, amp: 0.25, at: 0.6, for: 1.2}
      - {part: halo, kind: hop, amp: 0.25, at: 0.6, for: 1.4}
      - {part: root, kind: turn, amp: 360, axis: y, at: 1.2, for: 2}
      - {part: butterfly, kind: hop, amp: 0.4, at: 1.5, for: 1.2}
      - {part: butterfly2, kind: hop, amp: 0.35, at: 1.9, for: 1.2}
      - {part: cape, kind: swish, amp: 10, axis: x, at: 2.6, for: 1.4}
      - {part: tail, kind: flare, amp: 25, axis: x, at: 3, for: 0.8}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Mantle | `Petal3` (cape) | -0.02, 0.55, 0.30 | petals shed off the mantle on the flourish | Back |
| Medallion | `MedallionHeart` (static) | -0.02, 0.24, -0.36 | a pink sparkle | Mouth |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Gaiabloom.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Gaiabloom.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Gaiabloom_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Gaiabloom_vfx.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Gaiabloom_idle.png]]

The concept sheet, drawn from the parts table above: [[Gaiabloom_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Gaiabloom_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Gaiabloom_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8 a stud) on the 2-stud head since the B45 resize (it was 0.156 on a 2.5-stud head), 28 cells tall. Materials: wood on the antler trunks and branches, moss on the leaf clumps, the crown, the tail leaf and the ruff, metal on the hooves and the antler bands; the blossoms, dapples and butterfly wings are glow cells.

![[Gaiabloom_tq_cells.jpg]]

![[Gaiabloom_vfx_cells.jpg]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: built as drawn; the antlers read at once as two trees in bloom and the moss ruff as a green bib, but the pastel pink glow washed to white in the light. Round 2: a saturated pink, so the blossoms, dapples and orbiting petals read as pink. Round 3: no change after the side-by-side. Overlap 0.995 to 0.996, 1,140 triangles, 79 blocks, 6 studs (1.2 avatars). Wanted for: one avatar tall, blossoming antlers, glowing spots and the first light that touches the ground (the gold ring, the orbiting petals). Still cheap: the ivory body loses its edges against a pale sky; the head is a plain cube with no snout, so the stag rests on the antlers and the legs; the nimbus shows only as an arc behind the head. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The ivory body gains value: the grout and the darker edge cells draw every block of it (the open item of loop 2, partly: against a pale sky the head still wants a snout). The antlers now read as bark and leaves. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-19, World 1 roster worker (the snout). The eyes moved up a row block (rows 5 to 10 of 16, still in the lower half), and a muzzle block 1.5 by 0.625 by 0.5 is proud of the lower face with the nose and the smile on it as ink cells, so the head reads as a stag's against the pale sky. 84 blocks; the rest unchanged. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, three rounds. Round 1: rebuilt from 6 studs to 3.45 by redesign, not by scale: a 2-stud head (it was 2.5) on slim legs, the antler trees in sixteenth-stud parts (trunk, band, branch, tine, three leaf clumps, four blossoms a tree), the old 2.5-stud nimbus (a ring behind the head, too close to Raddis's sun disk at this size) replaced by a floating crown of moss and blossoms that turns over the head, a pink butterfly circling the antlers, a sixteenth-stud smile on the muzzle; its own `bloom` eyes at 32 pixels a stud (six pink and pale-gold petals turning round a gold heart in a moss-green ring), star cheeks. 70 blocks. Round 2: the trees stood straight up and read as two bushes on a box; leaned out 15 degrees and grown a sixteenth they read as antlers; the nose shrank to a quarter stud and the butterfly moved in front of the face's corner. Seven moving objects and the blink; a flourish every 12 s (a hop and a full turn, the crown popping, the trees shaking, the ears flared, the butterfly leaping). Overlap 0.992 to 0.996. Wanted for: a fawn with flowering trees for antlers and a flower turning in each eye, the first light that reaches the ground. Still weak: the body is a plain ivory box from the side (the dapples help only up close); the crown is thin from the three-quarter view; the butterfly is small at distance. Status review.
- 2026-10-21, Polish w1, one round. The plain ivory box from the side: a moss mane now steps down from the back of the head, and a moss saddle-blanket covers the back and drapes half down each flank with a gold hem and four lit blossoms on it (two on top, one each side); the three back dapples went under the blanket and the side dapples moved below its hem. From the side the torso is now three bands (green moss, a gold line, ivory with pink dapples) and the head-to-back corner steps down instead of dropping. 78 blocks (Legendary 60 to 120). Overlap 0.992 to 0.995. Honest read: from the side it now reads as a fawn the forest has grown over, and the blanket ties the antler trees to the body; the legs are still four plain ivory posts, which is right for a fawn. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: a mantle of glass petals over the back (six rows from the mane to the rump, pink lit glass between moss rows like a stained-glass window, every row edged in gold), the flank drapes rebuilt as stained-glass panels (moss and lit pink glass strips under the gold hem), a gilded leaf medallion with a lit heart on the ruff, and a second butterfly; the glow is a saturated pink `#F0287E` (the `#FF6FAE` washed to near white). 106 blocks, ten moving things. Honest read: from the side and the game's high camera the stained glass makes it a Legendary; from the three-quarter view the big ivory head still dominates and the mantle is a strip over the back. Status review.
