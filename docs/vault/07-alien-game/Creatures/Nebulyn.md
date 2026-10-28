---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Nebulyn
name: Cosmoo
world: 1
tier: Legendary
status: review
element: Star
height: 3.5
blocks: 165
tris: 2118
bevel_width: 0.125
bevel_segments: 2
palette: ["#6B4EC2", "#2E2166", "#E66BD2", "#FFD98A", "#FFF3B0", "#100A26"]
roles: [body, second, accent, trim, glow, ink]
hero: Tail
vfx: "touches the ground (Legendary): Effects.luau's four white stars orbiting the Body (radius 0.6, a lap in 6 s), a violet trail (B79CFF) from the Tail, cream twinkles (FFF6D8) streaming back off the Tail at 6 a second, a violet light (8F6BFF) on the Body pulsing every 3.4 s, violet puffs (9D7BFF) round the Body at 4 a second, and the flourish every 12 s, a burst of 24 white twinkles, with the tier's gold ground ring and orbit in its pale gold accent (FFE9A8); a Hover idle of 0.45 studs over 3.2 s. On the model the stars, the sparkle crosses and the tail's tip are cream glow cells. The rig adds the motion and the flourish: the tail swishes, the top puff breathes, the shoulder stars bob and turn, the ringed planet circles, the fallen star twinkles, and every 12 s it hops and turns once round with its tail swishing, the stars leaping and the planet popping"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Nebulyn_sheet.svg]]"
render: "[[Nebulyn_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.996, 0.996, 0.995]
vfx_render: "[[Nebulyn_vfx_cells.jpg]]"
cells_render: "[[Nebulyn_tq_cells.jpg]]"
idle_render: "[[Nebulyn_idle.png]]"
bar_world: Verdant
bar_kit: 7
bar_pieces: [bark_band, blossom_bud, moss_cells]
bar_stance: "a drift: the whole cloud leaning 8 degrees to its right, its tail swept 20 degrees sideways behind, a planet rising behind it and stars and ringed planets circling"
bar_satellites: 6
bar_orbit: orbiters
bar_backdrop: rings
---
# Nebulyn (Cosmoo), Legendary, World 1 Verdant, the Haunted Nebula event

A small nebula with a face, 3.5 studs to the sparkle at its tail's tip (B45: it was 5.63): a violet cloud a little under the avatar's shoulder, built round a 2-stud soft core with puffs stepping off it on every side at different heights, so from the front it reads as a cloud and never a cube: three bumps on its top (the middle one tallest, with a puff on it that breathes, the right one magenta), a bulge low on its right with a magenta puff beyond it, a higher one on its left, a magenta puff low on the left and a narrower step underneath trailing three wisps of indigo mist. An indigo dust lane drifts across its top. Star cells lit cream are sunk into the cloud all over, four of them sparkle crosses of a cell and four sixteenth-stud arms; a gold constellation of three stars steps across its right puffs. Its tail of cloud curls up and back behind it in five tapering steps (the middle one magenta) with five stars along it and a sparkle cross at its tip. A star floats at each shoulder, a tiny ringed planet circles its left ear, and one star has fallen to the grass behind it. Concept row in `src/shared/data/Species.luau`: "a small nebula cloud with two bright eyes and a trailing tail of stars". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`: the event track's last reward, through the quest only). Element and effect: [[Roster-Redesign]] section 2 (Star; a tail of stars trails behind it, small stars orbit, a ground ring of starlight; `Effects.luau` calls the element Nebula). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the event's prize and the one that cannot be caught, only earned: 25 event catches for a piece of the night sky that follows you home. B45 took its size (it no longer stands taller than you); B46 gives back more than it took: 78 blocks in eighth- and sixteenth-stud cells, a 32-column face set in a hollow of the cloud, its own big `starlit` eyes (rings of indigo, magenta and cream that breathe outward like a planetary nebula round a four-point star pupil, three stars twinkling in turn in each iris, on a face plate twice as fine as any lower rung's), star cheeks, seven moving things and a flourish every 12 s that reads from across the meadow. The Legendary rung: accessories (the planet, the floating stars), emissive cells (the stars and crosses), the effects touching the ground (the ring, and the star that fell).

**Hero block.** The `Tail`, a tail of cloud curling up behind it in five steps with stars along it and a sparkle at its tip, unique in Verdant (Vixa's tail is a brush, Glim's bulb curls up in two steps).

**Moving parts (six objects and the blink).** `tail` (its five steps, their stars and the tip sparkle swish), `puff` (the top puff and its star breathe), `starR` and `starL` (the shoulder stars bob, turn and drift), `planetL` (the ringed planet circles and spins), `fallenR` (the fallen star twinkles); the plate blinks, glints and its irises breathe. Rare pass w1: `comet` (a pet comet that circles the cloud above its brow, always trailing its tail), `twinkleR` and `twinkle2R` (the front and top sparkle crosses: they pulse) make nine objects and the blink.

**Alien anatomy.** A cloud that has eyes and a tail, lit from inside by stars, with a constellation on its skin and a planet for a pet.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the puffs and the tail.

**Event palette (Haunted Nebula).** Deep violet over indigo with a magenta accent, pale gold trim and a star-cream glow: the deep end of the event's range (Wispkin the cold blue, Grin the ghost white and pumpkin orange).

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`nebulyn()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A small nebula drifting in its own sky: a violet cloud with a planet rising behind it and a court of stars. Kept: name, anatomy (a cloud round a 2-stud core, the curling tail with its star tip, the pet comet, the shoulder stars, the ringed planet and the fallen star), the `starlit` eyes and the constellation, height 3.5.
- **Gains (visible parts).** (1) The backdrop: a planet rising behind the cloud, 2.5 studs across (a magenta rim round an indigo face) with a gold ring 4 studs wide across it, under a third of a stud deep, rocking slowly on the `rings` object; only the planet's cap and the ring's two ends show, which is the point (a planet behind a cloud). (2) Six satellites on a wide low ring in front of it (the `orbiters` object, clear of the tail): three four-point stars (long gold points round a lit cream core) and three little ringed planets (a magenta orb, a gold ring, a lit highlight), seven eighths of a stud across. (3) Verdant kit, seven pieces: gold blossom buds on both top bumps and on the tail, magenta stardust moss pads with a lit tuft on the left puff and the back puff, gold bands round the core's waist and the tail's root. (4) The stance below.
- **Stance (rest groups `lean`, `sweep`).** The whole cloud above the grass (core, puffs, stars, the comet's orbit excepted) leans 8 degrees to its right while the tail is swept 20 degrees sideways behind: a nebula drifting through a turn, not a cube with a tail.
- **Face intent.** Its own `starlit` eyes kept (layered rings of indigo, magenta and cream round a four-point star pupil, three stars twinkling in turn), a small smile and star cheeks: wide-eyed wonder, the night sky looking back at you. The face is not changed and nothing crosses the plate (the satellites' front arc is low and out at the sides).
- **Three values (rule 8).** Body violet; the dust lanes, the under steps and the planet's face a step darker (indigo); the planet's rim and the mini planets magenta, the ring, stars and bands gold, the cores lit cream. The backdrop is darker than the sky and has a lit rim and a bright ring, so it separates from the violet cloud by value and colour.
- **Must-nots.** No fierce face; no solid backdrop bigger than the cloud's silhouette that would hide the planet entirely (the planet sits high so its cap shows); nothing over the face; the comet keeps its own orbit (leaning it pushed its tail to 3.54); height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # the core of the cloud: a 2-stud soft block in nebula cells, the face plate on its front; puffs step off it on every side at different
  # heights (two of them magenta), so from the front it reads as a cloud: three bumps on top, a bulge low on the right, a higher one on the
  # left, a narrower step underneath, never a square
  - {name: Core, slot: Body, size: [2, 1.5, 1.75], at: [0, 1.5, 0], bevel: true, material: nebula, pose: lean}
  - {name: TopL, slot: Body, size: [0.6875, 0.375, 1.25], at: [-0.59375, 2.4375, 0.0625], material: nebula, pose: lean}
  - {name: TopM, slot: Body, size: [1, 0.625, 1.375], at: [0.25, 2.5625, 0.0625], material: nebula, pose: lean}
  - {name: TopR, slot: Accessory, size: [0.5, 0.375, 1], at: [0.8125, 2.4375, 0.125], material: nebula, pose: lean}
  - {name: SideR, slot: Body, size: [0.375, 0.875, 1.25], at: [1.1875, 1.4375, 0.0625], material: nebula, pose: lean}
  - {name: SideR2, slot: Accessory, size: [0.25, 0.5, 0.75], at: [1.5, 1.25, 0.0625], material: nebula, pose: lean}
  - {name: SideL, slot: Body, size: [0.3125, 0.625, 1], at: [-1.15625, 1.8125, 0.0625], material: nebula, pose: lean}
  - {name: SideL2, slot: Body, size: [0.25, 0.375, 0.625], at: [-1.4375, 1.75, 0.0625], material: nebula, pose: lean}
  - {name: PinkL, slot: Accessory, size: [0.25, 0.375, 0.75], at: [-1.0625, 0.9375, 0.125], material: nebula, pose: lean}
  - {name: Under, slot: Body, size: [1.625, 0.375, 1.375], at: [0.0625, 0.5625, 0.0625], material: nebula, pose: lean}
  - {name: Under2, slot: BodyDark, size: [1, 0.25, 0.875], at: [-0.125, 0.25, 0.125], material: nebula, pose: lean}
  - {name: BackPuff, slot: Body, size: [0.75, 0.875, 0.375], at: [-0.5, 1.5625, 1.0625], material: nebula, pose: lean}
  # Polish w1: the face sat on one flat panel; a puff of cloud proud of the front over the eyes (a sparkle cross on it) and a smaller one
  # under the smile, off-centre, so the face sits in a hollow of the cloud
  - {name: BrowPuff, slot: Body, size: [1.5, 0.25, 0.25], at: [-0.125, 2.125, -1], material: nebula, pose: lean}
  - {name: ChinPuff, slot: Body, size: [1, 0.25, 0.25], at: [0.375, 0.875, -1], material: nebula, pose: lean}
  # a dust lane of indigo cells drifting across the top bumps, and three wisps of mist trailing under the cloud
  - {name: Dust, slot: BodyDark, size: [0.25, 0.0625, 0.25], at: [-0.5, 2.65625, -0.375], pose: lean}
  - {name: Dust2, slot: BodyDark, size: [0.25, 0.0625, 0.25], at: [0.0625, 2.90625, 0.375], pose: lean}
  - {name: Dust3, slot: BodyDark, size: [0.1875, 0.0625, 0.25], at: [0.65625, 2.65625, 0.25], pose: lean}
  - {name: Wisp, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [0.6875, 0.3125, -0.375], pose: lean}
  - {name: Wisp2, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [-0.75, 0.3125, -0.25], pose: lean}
  - {name: Wisp3, slot: BodyDark, size: [0.25, 0.125, 0.375], at: [0.5, 0.3125, 0.6875], pose: lean}
  # the top puff breathes (a moving part) with a star on it
  - {name: TopM2, slot: Body, size: [0.625, 0.25, 0.875], at: [0.1875, 3, 0.0625], material: nebula, moves: puff, pivot: [0, 2.875, 0.0625], pose: lean}
  - {name: PuffStar, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 3.125, -0.125], moves: puff, pivot: [0, 2.875, 0.0625], pose: lean}
  # star cells: lit eighth-stud cells half sunk into the cloud's faces, and four sparkle crosses (a cell and four sixteenth-stud arms)
  - {name: Star1, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.6875, 2.625, -0.25], pose: lean}
  - {name: Star2, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.3125, 2.625, 0.4375], pose: lean}
  - {name: Star3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.875, 2.625, 0.375], pose: lean}
  - {name: Star4, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.375, 1.6875, -0.3125], pose: lean}
  - {name: Star5, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.9375, 2.125, -0.875], pose: lean}
  - {name: Star6, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.5, 0.9375, -0.875], pose: lean}
  - {name: Star7, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5, 0.5625, -0.625], pose: lean}
  - {name: Star8, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.5625, 1.75, -0.125], pose: lean}
  - {name: Star9, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.5, 1.75, 1.25], pose: lean}
  - {name: Sparkle, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.625, 2.875, -0.375], moves: twinkle2, pivot: [0.625, 2.875, -0.375], pose: lean}
  - {name: SparkleArm1, slot: Glow, size: [0.0625, 0.125, 0.125], at: [0.71875, 2.875, -0.375], moves: twinkle2, pivot: [0.625, 2.875, -0.375], pose: lean}
  - {name: SparkleArm2, slot: Glow, size: [0.0625, 0.125, 0.125], at: [0.53125, 2.875, -0.375], moves: twinkle2, pivot: [0.625, 2.875, -0.375], pose: lean}
  - {name: SparkleArm3, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.625, 2.875, -0.28125], moves: twinkle2, pivot: [0.625, 2.875, -0.375], pose: lean}
  - {name: SparkleArm4, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.625, 2.875, -0.46875], moves: twinkle2, pivot: [0.625, 2.875, -0.375], pose: lean}
  - {name: SparkleF, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5, 2.125, -1.125], moves: twinkle, pivot: [0.5, 2.125, -1.125], pose: lean}
  - {name: SparkleFArm1, slot: Glow, size: [0.0625, 0.125, 0.125], at: [0.59375, 2.125, -1.125], moves: twinkle, pivot: [0.5, 2.125, -1.125], pose: lean}
  - {name: SparkleFArm2, slot: Glow, size: [0.0625, 0.125, 0.125], at: [0.40625, 2.125, -1.125], moves: twinkle, pivot: [0.5, 2.125, -1.125], pose: lean}
  - {name: SparkleFArm3, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.5, 2.21875, -1.125], moves: twinkle, pivot: [0.5, 2.125, -1.125], pose: lean}
  - {name: SparkleFArm4, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.5, 2.03125, -1.125], moves: twinkle, pivot: [0.5, 2.125, -1.125], pose: lean}
  - {name: SparkleB, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.5, 1.375, 1.25], pose: lean}
  - {name: SparkleBArm1, slot: Glow, size: [0.0625, 0.125, 0.125], at: [-0.40625, 1.375, 1.25], pose: lean}
  - {name: SparkleBArm2, slot: Glow, size: [0.0625, 0.125, 0.125], at: [-0.59375, 1.375, 1.25], pose: lean}
  - {name: SparkleBArm3, slot: Glow, size: [0.125, 0.0625, 0.125], at: [-0.5, 1.46875, 1.25], pose: lean}
  - {name: SparkleBArm4, slot: Glow, size: [0.125, 0.0625, 0.125], at: [-0.5, 1.28125, 1.25], pose: lean}
  - {name: SparkleR, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.375, 1.25, 0.5], pose: lean}
  - {name: SparkleRArm1, slot: Glow, size: [0.125, 0.0625, 0.125], at: [1.375, 1.34375, 0.5], pose: lean}
  - {name: SparkleRArm2, slot: Glow, size: [0.125, 0.0625, 0.125], at: [1.375, 1.15625, 0.5], pose: lean}
  - {name: SparkleRArm3, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.375, 1.25, 0.59375], pose: lean}
  - {name: SparkleRArm4, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.375, 1.25, 0.40625], pose: lean}
  # a constellation on the right puffs: three stars joined by thin gold lines stepping across the cloud
  - {name: ConStar, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 1.375, -0.125], pose: lean}
  - {name: ConStar2, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 1.125, 0.3125], pose: lean}
  - {name: ConStar3, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.375, 1.8125, 0.375], pose: lean}
  - {name: ConLine, slot: Trim, size: [0.0625, 0.125, 0.125], at: [1.65625, 1.25, -0.125], pose: lean}
  - {name: ConLine2, slot: Trim, size: [0.0625, 0.125, 0.3125], at: [1.65625, 1.125, 0.09375], pose: lean}
  - {name: ConLine3, slot: Trim, size: [0.0625, 0.1875, 0.125], at: [1.40625, 1.59375, 0.375], pose: lean}
  - {name: ConLine4, slot: Trim, size: [0.25, 0.0625, 0.125], at: [1.5, 1.53125, 0.375], pose: lean}
  # the hero: a tail of cloud curling up and back in five tapering steps (the middle one magenta), stars along it and a sparkle cross at its
  # tip (one moving part)
  - {name: Tail, slot: Body, size: [1, 0.75, 0.625], at: [0.25, 1.375, 1.1875], material: nebula, moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: Tail2, slot: Body, size: [0.75, 0.625, 0.5], at: [0.5, 1.8125, 1.6875], material: nebula, moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: Tail3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.6875, 2.3125, 2.0625], material: nebula, moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: Tail4, slot: Body, size: [0.375, 0.375, 0.375], at: [0.875, 2.75, 2.3125], material: nebula, moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: Tail5, slot: Body, size: [0.25, 0.25, 0.25], at: [1, 3.0625, 2.4375], material: nebula, moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TailStar1, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5, 1.75, 1.3125], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TailStar2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.875, 1.875, 1.6875], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TailStar3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.8125, 2.5625, 1.9375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TailStar4, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.0625, 2.6875, 2.3125], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TailStar5, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 2.125, 1.5625], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TipStar, slot: Glow, size: [0.25, 0.25, 0.25], at: [1, 3.3125, 2.4375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TipStarArm1, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.125, 3.3125, 2.4375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TipStarArm2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.875, 3.3125, 2.4375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TipStarArm3, slot: Glow, size: [0.125, 0.125, 0.125], at: [1, 3.4375, 2.4375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: TipStarArm4, slot: Glow, size: [0.125, 0.125, 0.125], at: [1, 3.1875, 2.4375], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  # floating: a star at each shoulder, a ringed planet circling, and a star fallen to the grass behind it
  - {name: FloatStar, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 2.6875, -0.5], shape: ico1, moves: star, pivot: [1.5, 2.6875, -0.5], pose: lean}
  - {name: FloatStarL, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.5625, 2.4375, 0.3125], shape: ico1, moves: star, pivot: [-1.5625, 2.4375, 0.3125], pose: lean}
  - {name: Planet, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.25, 2.9375, -0.25], shape: ico1, moves: planet, pivot: [-1.25, 2.9375, -0.25], pose: lean}
  - {name: PlanetRing, slot: Trim, size: [0.5, 0.0625, 0.25], at: [-1.25, 2.9375, -0.25], rot: [0, 0, 15], moves: planet, pivot: [-1.25, 2.9375, -0.25], pose: lean}
  - {name: Fallen, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.75, 0.125, 1.75], shape: ico1, moves: fallen, pivot: [0.75, 0.125, 1.75]}
  # Rare pass w1, the signature piece: a pet comet that circles the cloud above its brow (at rest over the face's top, flying to its left), a lit head with a magenta spark and a tail of
  # gold and lit glass cells streaming behind it; the whole object turns about the cloud's centre, so the comet flies round it and
  # always trails its tail (`comet`)
  - {name: Comet, slot: Glow, size: [0.375, 0.375, 0.375], at: [-0.5, 3.25, -2], shape: ico1, moves: comet, pivot: [0, 3.25, 0]}
  - {name: CometSpark, slot: Accessory, size: [0.125, 0.125, 0.125], at: [-0.75, 3.25, -2], moves: comet, pivot: [0, 3.25, 0]}
  - {name: CometTail, slot: Trim, size: [0.375, 0.25, 0.25], at: [-0.125, 3.25, -2], moves: comet, pivot: [0, 3.25, 0], material: metal}
  - {name: CometTail2, slot: Glow, size: [0.375, 0.125, 0.125], at: [0.25, 3.3125, -2], moves: comet, pivot: [0, 3.25, 0], material: crystal}
  - {name: CometTail3, slot: Trim, size: [0.25, 0.125, 0.125], at: [0.5625, 3.375, -2], moves: comet, pivot: [0, 3.25, 0], material: metal}
  - {name: CometTail4, slot: Glow, size: [0.25, 0.0625, 0.0625], at: [0.8125, 3.40625, -1.96875], moves: comet, pivot: [0, 3.25, 0], material: crystal}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # gold blossom buds on the left and right top bumps (they lean with the cloud)
  - {name: BudAa, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [-0.4375, 2.75, 0], pose: lean, material: wood}
  - {name: BudAb, slot: Trim, size: [0.375, 0.125, 0.125], at: [-0.4375, 2.9375, 0], pose: lean}
  - {name: BudAc, slot: Trim, size: [0.125, 0.125, 0.125], at: [-0.4375, 3.0625, 0], pose: lean}
  - {name: BudBa, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.875, 2.75, 0.0625], pose: lean, material: wood}
  - {name: BudBb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.875, 2.9375, 0.0625], pose: lean}
  - {name: BudBc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.875, 3.0625, 0.0625], pose: lean}
  # a gold blossom bud on the tail's middle step (it rides the tail)
  - {name: BudCa, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.75, 2.6875, 2], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep, material: wood}
  - {name: BudCb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.75, 2.875, 2], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  - {name: BudCc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.75, 3, 2], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep}
  # stardust moss: magenta pads with a lit tuft on the left side puff and on the back puff
  - {name: MossLa, slot: Accessory, size: [0.125, 0.5, 0.5], at: [-1.625, 1.75, 0.3125], pose: lean, material: moss}
  - {name: MossLb, slot: Accessory, size: [0.125, 0.25, 0.375], at: [-1.75, 1.75, 0.25], pose: lean, material: moss}
  - {name: MossLc, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.875, 1.8125, 0.375], pose: lean, material: moss}
  - {name: MossBa, slot: Accessory, size: [0.5, 0.5, 0.125], at: [-0.5, 1.75, 1.3125], pose: lean, material: moss}
  - {name: MossBb, slot: Accessory, size: [0.375, 0.25, 0.125], at: [-0.5625, 1.75, 1.4375], pose: lean, material: moss}
  - {name: MossBc, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.4375, 1.8125, 1.5625], pose: lean, material: moss}
  # a gold band: a quarter stud tall and an eighth proud, round the core's waist (the face stays clear)
  - {name: GirthR, slot: Trim, size: [0.125, 0.25, 1.75], at: [1.0625, 0.875, 0], pose: lean, material: metal}
  - {name: GirthL, slot: Trim, size: [0.125, 0.25, 1.75], at: [-1.0625, 0.875, 0], pose: lean, material: metal}
  - {name: GirthB, slot: Trim, size: [2.25, 0.25, 0.125], at: [0, 0.875, 0.9375], pose: lean, material: metal}
  # a gold band round the tail's root (it rides the tail)
  - {name: TailRingR, slot: Trim, size: [0.125, 0.25, 0.625], at: [0.8125, 1.375, 1.1875], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep, material: metal}
  - {name: TailRingL, slot: Trim, size: [0.125, 0.25, 0.625], at: [-0.3125, 1.375, 1.1875], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep, material: metal}
  - {name: TailRingB, slot: Trim, size: [1.25, 0.25, 0.125], at: [0.25, 1.375, 1.5625], moves: tail, pivot: [0.25, 1.375, 0.875], pose: sweep, material: metal}
  # the backdrop (`rings`, it rocks slowly): a planet rising behind the cloud, 2.5 studs across with a magenta rim round an indigo face, and a gold ring across it 4 studs wide, under a third of a stud deep
  - {name: Planet0, slot: Accessory, size: [1, 0.25, 0.25], at: [0, 1.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet1, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-0.75, 1.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet2, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 1.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet3, slot: Accessory, size: [0.5, 0.25, 0.25], at: [0.75, 1.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet4, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-0.875, 1.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet5, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet6, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.875, 1.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet7, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 1.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet8, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 1.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet9, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 1.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet10, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 2.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet11, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet12, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 2.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet13, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 2.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet14, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet15, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 2.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet16, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 2.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet17, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet18, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 2.625, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet19, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-0.875, 2.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet20, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 2.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet21, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.875, 2.875, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet22, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-0.75, 3.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet23, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 3.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375]}
  - {name: Planet24, slot: Accessory, size: [0.5, 0.25, 0.25], at: [0.75, 3.125, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: Planet25, slot: Accessory, size: [1, 0.25, 0.25], at: [0, 3.375, 2.9375], moves: rings, pivot: [0, 2.25, 2.9375], material: nebula}
  - {name: RingA, slot: Trim, size: [3, 0.125, 0.125], at: [0, 2.0625, 2.75], moves: rings, pivot: [0, 2.25, 2.9375], material: metal}
  - {name: RingB, slot: Trim, size: [4, 0.125, 0.125], at: [0, 2.1875, 2.75], moves: rings, pivot: [0, 2.25, 2.9375], material: metal}
  - {name: RingC, slot: Trim, size: [4, 0.125, 0.125], at: [0, 2.3125, 2.75], moves: rings, pivot: [0, 2.25, 2.9375], material: metal}
  - {name: RingD, slot: Trim, size: [3, 0.125, 0.125], at: [0, 2.4375, 2.75], moves: rings, pivot: [0, 2.25, 2.9375], material: metal}
  # the satellite set (`orbiters`, one wide ring in front of the planet, the front low, clear of the tail): three four-point stars and three little ringed planets, gold, magenta and lit cream
  - {name: Sat0a, slot: Trim, size: [0.125, 0.875, 0.125], at: [0.625, 0.875, -2.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat0b, slot: Trim, size: [0.875, 0.125, 0.125], at: [0.625, 0.875, -2.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat0c, slot: Trim, size: [0.375, 0.375, 0.25], at: [0.625, 0.875, -2.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat0d, slot: Glow, size: [0.25, 0.25, 0.0625], at: [0.625, 0.875, -2.59375], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat0e, slot: Glow, size: [0.25, 0.25, 0.0625], at: [0.625, 0.875, -2.28125], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat1a, slot: Accessory, size: [0.5, 0.25, 0.25], at: [2.25, 1.5625, -0.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat1b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [2.25, 1.5625, -0.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat1c, slot: Trim, size: [0.875, 0.125, 0.375], at: [2.25, 1.5625, -0.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat1d, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.1875, 1.75, -0.96875], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat1e, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.1875, 1.75, -0.65625], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat2a, slot: Trim, size: [0.125, 0.875, 0.125], at: [1.625, 2.3125, 1.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat2b, slot: Trim, size: [0.875, 0.125, 0.125], at: [1.625, 2.3125, 1.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat2c, slot: Trim, size: [0.375, 0.375, 0.25], at: [1.625, 2.3125, 1.4375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat2d, slot: Glow, size: [0.25, 0.25, 0.0625], at: [1.625, 2.3125, 1.59375], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat2e, slot: Glow, size: [0.25, 0.25, 0.0625], at: [1.625, 2.3125, 1.28125], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat3a, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-0.625, 2.3125, 2], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat3b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [-0.625, 2.3125, 2], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat3c, slot: Trim, size: [0.875, 0.125, 0.375], at: [-0.625, 2.3125, 2], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat3d, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-0.5625, 2.5, 2.15625], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat3e, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-0.5625, 2.5, 1.84375], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat4a, slot: Trim, size: [0.125, 0.875, 0.125], at: [-2.25, 1.625, 0.375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat4b, slot: Trim, size: [0.875, 0.125, 0.125], at: [-2.25, 1.625, 0.375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat4c, slot: Trim, size: [0.375, 0.375, 0.25], at: [-2.25, 1.625, 0.375], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat4d, slot: Glow, size: [0.25, 0.25, 0.0625], at: [-2.25, 1.625, 0.21875], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat4e, slot: Glow, size: [0.25, 0.25, 0.0625], at: [-2.25, 1.625, 0.53125], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat5a, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1.625, 0.875, -1.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat5b, slot: Accessory, size: [0.25, 0.5, 0.25], at: [-1.625, 0.875, -1.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: nebula}
  - {name: Sat5c, slot: Trim, size: [0.875, 0.125, 0.375], at: [-1.625, 0.875, -1.8125], moves: orbiters, pivot: [0, 1.6, -0.2], material: metal}
  - {name: Sat5d, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.6875, 1.0625, -1.96875], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  - {name: Sat5e, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-1.6875, 1.0625, -1.65625], moves: orbiters, pivot: [0, 1.6, -0.2], material: crystal}
  # pilot bar: end
```

## Face

The core's front is the body cell grid ([[Blocky-Style]] C1): 32 columns across the 2-stud core, so the cell is 0.0625 studs (16 a stud, painted at 4 texels a cell) and the 1.5-stud front is 24 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Core
  cols: 32
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `starlit`, a Legendary design added by Polish w1, layered glowing rings that breathe outward round a four-point star pupil, here indigo (the second colour), magenta (the accent) and star cream (the glow), with three stars twinkling in turn in each iris; a planetary nebula with a star at its heart. It is 22 x 24 pixels where the library's big eyes are 16 x 18, so each eye is a third of the head's width (it wore `halo` until Polish w1, and on the cloud those read small). At 32 pixels a stud (Legendary up: eyes no lower species has, on a finer grid) on a 1.75 x 1 stud plate (56 x 32 pixels, 11 frames: open, half, closed, two glints, six ring frames), the eyes a little closer together (spread 0.4375). A small smile and star cheeks. In World 1 only Cosmoo wears `starlit`.

```yaml
eyes:
  key: starlit
  colours: {deep: second, mid: accent, bright: glow}
  mouth: smile
  cheeks: stars
  plate: [1.75, 1]
  at: [0, 1.5]
  spread: 0.4375
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them and calls `SpeciesFx.Flourish` on each flourish, the moment `Effects.luau`'s burst of 24 twinkles fires): the tail swishes from side to side and lifts, the top puff breathes, the shoulder stars bob and turn out of step, the ringed planet circles and spins, the fallen star twinkles, the cloud breathes, the face blinks. Six objects and the blink (a Legendary needs six). The flourish, every 12 s: a hop and one full turn with the tail swishing, then the stars leap one after the other, the planet pops and the fallen star jumps back up.

```yaml
rig:
  rest:
    lean: {rot: [0, 0, 8], pivot: [0, 0.5, 0]}
    sweep: {rot: [0, -20, 0], pivot: [0.25, 1.375, 0.875]}
  clips:
    tail: [{kind: sway, amp: 8, period: 3.2, axis: y}, {kind: sway, amp: 5, period: 4.8, axis: x, phase: 0.3}]
    puff: [{kind: bob, amp: 0.06, period: 3.2, phase: 0.5}]
    comet: [{kind: spin, amp: 360, period: 9, axis: y}, {kind: bob, amp: 0.1, period: 2.7}]
    twinkle: [{kind: pulse, amp: 0.25, period: 1.4}]
    twinkle2: [{kind: pulse, amp: 0.25, period: 1.9, phase: 0.5}]
    starR: [{kind: bob, amp: 0.12, period: 2.4}, {kind: spin, amp: 360, period: 6, axis: y}]
    starL: [{kind: bob, amp: 0.1, period: 2, phase: 0.5}, {kind: orbit, amp: 0.1, period: 5}]
    planetL: [{kind: orbit, amp: 0.15, period: 7}, {kind: spin, amp: 360, period: 4, axis: y}]
    fallenR: [{kind: pulse, amp: 0.25, period: 1.6}]
    root: [{kind: squash, amp: 0.04, period: 3.2}, {kind: bob, amp: 0.05, period: 4, phase: 0.25}]
    rings: [{kind: sway, amp: 4, period: 6, axis: z}, {kind: bob, amp: 0.05, period: 4.4}]
    orbiters: [{kind: spin, amp: 360, period: 18, axis: y}, {kind: bob, amp: 0.05, period: 3.4}]
    face: [{kind: blink, period: 4.4}]
  flourish:
    every: 12
    length: 4.2
    moves:
      - {part: root, kind: hop, amp: 0.45, at: 0, for: 1}
      - {part: comet, kind: turn, amp: 720, axis: y, at: 0, for: 2.4}
      - {part: comet, kind: hop, amp: 0.25, at: 0.2, for: 1.2}
      - {part: root, kind: turn, amp: 360, at: 0.2, for: 1.8}
      - {part: tail, kind: swish, amp: 25, at: 0.4, for: 1.6}
      - {part: twinkle, kind: pop, amp: 0.6, at: 0.8, for: 0.6}
      - {part: starR, kind: hop, amp: 0.3, at: 1, for: 1}
      - {part: twinkle2, kind: pop, amp: 0.6, at: 1.2, for: 0.6}
      - {part: starL, kind: hop, amp: 0.3, at: 1.3, for: 1}
      - {part: planetL, kind: pop, amp: 0.3, at: 1.6, for: 1}
      - {part: fallenR, kind: hop, amp: 0.4, at: 2, for: 1}
      - {part: puff, kind: pop, amp: 0.2, at: 2.2, for: 0.8}
      - {part: root, kind: squash, amp: 0.12, axis: y, at: 3.2, for: 0.8}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Comet | `Comet` (comet) | -0.15, 0.93, -0.46 | a trail of star motes behind the comet, the flourish's burst | Halo |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Nebulyn.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Nebulyn.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Nebulyn_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Nebulyn_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Nebulyn_idle.png]]

The concept sheet, drawn from the parts table above: [[Nebulyn_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Nebulyn_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): a 32-column face, so the cell is 0.0625 studs (16 a stud, painted at 4 texels a cell), 56 cells tall. Materials: `nebula` on the core, every puff and the tail (billows of light and shade, a dust lane drifting on the diagonal, a star cell in forty in the cream glow with a twinkle round one in three), glossy pale gold trim on the constellation lines and the planet's ring; the stars and the crosses are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, one round. Built as drawn: a core with puffs stepping off it on the nebula motif, sixteen star cells, two gold constellations on the side puffs, and the tail of five steps curling up behind with eight stars along it, a big one at its tip, two floating past it and one fallen to the grass. The VFX preview is the Legendary set: the tail's stars lit, ten stars orbiting a stud out, a gold ring of starlight on the ground. Overlap 0.994 to 0.997, 752 triangles, 60 blocks (the floor of the Legendary band), 5.63 studs; the boxed silhouette's worst pair is Buzzik at 0.67. Wanted for: the event's prize, a piece of the night sky with a tail. Still cheap: the core still reads as a cube from the front (the puffs are on its top, sides and underside); the constellations are small gold marks at the review size; the tail's eight studs of depth make the body a third of the frame. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 rebuild, one round. Redesigned at 3.5 studs from 5.63, not scaled: a 2-stud core with a 32-column face (0.0625 body cells, 56 cells tall) and puffs breaking all four edges of the front at different heights (three bumps on top, the middle tallest; a bulge low on the right and higher on the left; a narrower step underneath with three wisps of mist), so the front reads as a cloud and no longer as a cube (the open item of 2026-10-20). 76 blocks in eighth- and sixteenth-stud cells (the Legendary band is 60 to 120): a dust lane, nine star cells, four sparkle crosses, a gold constellation, a magenta band in the tail and a sparkle at its tip, a star at each shoulder, a ringed planet and a fallen star. Its own `halo` eyes (rings of indigo, magenta and cream breathing outward round a dark pupil, a sparkle circling, six ring frames at 32 pixels a stud) with star cheeks; six moving objects and the blink, and a flourish every 12 s: a hop and one full turn with the tail swishing, the stars leaping, the planet popping and the fallen star jumping up. Overlap 0.995 to 0.997, 854 triangles; worst silhouette pair 0.672 (Wispkin). Wanted for: the event's prize, a piece of the night sky with a planet for a pet, now plainly the rarest of the three at the same size. Still weak: the core's front is still one flat panel round the face (the lumps are all at its edges), and the halo eyes read small at the review distance. Status review.
- 2026-10-21, Polish w1, one round. The face sat on one flat panel and the eyes read small: a new Legendary eye, `starlit` (appended to the eye library under Polish w1), 22 x 24 pixels to the library's 16 x 18, so each eye is a third of the head's width instead of a quarter, with a four-point star for a pupil inside the breathing nebula rings and three stars that twinkle in turn; the plate grew to 1 stud tall and the eyes moved a sixteenth closer. A puff of cloud now stands a quarter proud of the front over the eyes (the front sparkle cross moved onto it) and a smaller one under the smile, off-centre, so the face sits in a hollow of the cloud. 78 blocks (Legendary 60 to 120). Overlap 0.995 to 0.997. Honest read: the eyes now read first, as a Legendary's should, and the face is framed; the core's corners still show as a block behind the puffs from the three-quarter view. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: a pet comet circling its brow, a lit head with a magenta spark and a tail of gold and lit glass cells; the whole object turns about the cloud's centre, so the comet flies round it nose first, and on the flourish it loops twice and rises. The front and top sparkle crosses twinkle. Round 1 put the comet at its right shoulder (hidden by the tail), round 2 over the face in magenta (lost against the violet puffs); gold at 3.25 studs reads. 84 blocks, ten moving things. Honest read: the comet makes it a little universe; it is small in the three-quarter view and lives in motion. Status review.
