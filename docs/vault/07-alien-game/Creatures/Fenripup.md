---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Fenripup
name: Fenrir
world: 2
tier: Cosmic
status: review
element: Moon
height: 3.5
blocks: 138
tris: 1714
bevel_width: 0.0625
bevel_segments: 2
palette: ["#4B3D8F", "#1E1A47", "#B9C6E0", "#D9E2F5", "#AEB8FF", "#0E0B1E"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#AEB8FF", "#E6ECFF", "#7F74E6"]
hero: MoonC
vfx: "to the sky (Cosmic, Effects.luau): a moonlight glow over its head pulses every 6 s (the Light at Top), four moon-dust motes orbit its body (the Orbit at Body), a ground ring of runes rolls out every 3 s and turns as it goes (the RingPulse at Feet), a held aura of pale moonlight (the Aura at Body), a low indigo mist breathes off its paws (the Emitter at Feet) and a violet trail streams from its tail while it moves (the Trail); every 20 s the howl (the flourish): a column of moonlight straight up from its head and a flare of twenty-four twinkles (the Pillar and Burst at Top); the floating moon, the tufts' and ears' tips, the flank runes, the leg marks, the tail's core, the mane's caught stars and the chain's broken ends glow and step through periwinkle, full-moon white and deep violet (the glow cycle); it breathes 3 percent; in the rig the moon bobs and rocks over its brow, the silver crescent rocks behind its mane, two lit motes circle its shoulders, the broken chain swings, the ears flick and the forked tail wags, and the howl is a crouch, a hop into a full turn, a rear back with the ears up, the moon and the crescent flaring and the motes leaping"
ride: "Sprint (mount form, Decide-Now 44 a: it grows to riding size only while ridden); the rider sits on the mane behind the head"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Fenripup_sheet.svg]]"
render: "[[Fenripup_tq_cells.jpg]]"
glb: ""
overlap: [0.998, 0.995, 0.997, 0.998]
vfx_render: "[[Fenripup_vfx_cells.jpg]]"
cells_render: "[[Fenripup_tq_cells.jpg]]"
idle_render: "[[Fenripup_idle.png]]"
---
# Fenripup (Fenrir), Cosmic, World 2 Frostbyte

A moon wolf pup, 3.5 studs to its ear tips (B45; it was a 14-stud mount, redesigned at a pup's size, not scaled; it grows to riding size only while ridden, Decide-Now 44 a): an indigo wolf on four sturdy legs with silver ankle bands and silver claws, a square head with a 32-column face (sixteenth-stud cells, a finer body than anything else in Frostbyte), a pale snout block with a dark nose and a small ink smile, two little ice fangs under it, pale cheek tufts, a tall right ear and a puppy's left ear flopped over sideways, both with pale insides and lit tips, and in front of its brow, floating on nothing, a moon of stepped light with two craters, rocking gently. Behind the head stands its mane, four near-black slabs stepping down the neck, each end of the top three slabs ending in a tuft tipped with moonlight, three ridge tufts lit at their tips running down the back, and six stars caught in the mane's front. A silver collar with three studs holds a chain of two links down its pale chest, the third link broken, its two ends lit (the echo of the bound Fenrir, worn as a trophy). Silver plates on its shoulders, a lit rune on each flank, three moon marks on each foreleg, and a tail held low and stiff in a silver band that forks round a core of light. Behind the mane on its left stands a silver crescent moon in sixteenth-stud rows, horns to the right, rocking slowly, and two moon-dust motes circle it, one high at its right ear and one low at its left shoulder. Concept row in `src/shared/data/Species.luau`: "puppy, glowing moon on its forehead; echo of Fenrir". Element: Moon (`Effects.luau`); [[Roster-Redesign]] section 2 and the Fenrir brief in section 3. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** Ethan on the old Fenrir: it "looks too cute, and not really something that would appeal to people who worked so hard to find him"; and since: rarer means more exclusive and cooler or cuter, never bigger (B45) or fiercer. So Fenrir is World 2's hero by everything but size: 138 blocks at the same height as the Rares, most of them sixteenth-grid cells (claws, bands, chain links, runes, marks, caught stars) on a 32-column body no other Frostbyte alien has; eyes of its own, the `lunar` design new in the library for it, a moon that waxes and wanes across a starry iris over eight frames on a 32-pixel-a-stud plate, with star cheeks; nine moving things including a moon that floats over its brow and a crescent that rocks behind it; and every 20 s the howl, a crouch, a hop into a full turn and a rear back with the ears up while a column of moonlight stands from its head into the sky. A pup, cute and cooler: the fangs are small and lit, the face a soft smile under lunar eyes.

**Hero block.** The floating moon (`MoonC`, the widest of its six stepped rows), a disc of moonlight over the brow with two craters, unique in Frostbyte.

**Moving parts (eight objects and the blink).** `moon` (it bobs and rocks), `halo` (the crescent rocks), `earR`, `earL` (the standing ear and the flopped one flick), `chain` (it swings), `tail` (it wags), `moteR`, `moteL` (they circle); the face plate blinks, glints and its moons wax and wane.

**Alien anatomy.** Fangs of ice outside the mouth, a mane that is a stack of slabs with stars caught in it, a chain that is part of its body (the broken ends glow), a moon that floats on nothing, and a tail that forks round a core of light.

**World motif (Frostbyte).** Icicles (the fangs) and the ice facet as steps: the moon is a stepped disc, the mane a stepped stack, the tufts stepped points.

## Parts

```yaml
parts:
  # four sturdy legs: dark paws with three silver claws each, a silver band at each ankle; three moon marks on each foreleg
  - {name: FrontPaw, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, -0.75], mirror: x, material: fur}
  - {name: FrontLeg, slot: Body, size: [0.375, 0.5, 0.375], at: [0.5, 0.5, -0.625], mirror: x, material: fur}
  - {name: FrontBand, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, -0.625], mirror: x, material: metal}
  - {name: Claw, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.3125, 0.03125, -1.125], mirror: x, material: metal}
  - {name: Claw2, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.5, 0.03125, -1.125], mirror: x, material: metal}
  - {name: Claw3, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.6875, 0.03125, -1.125], mirror: x, material: metal}
  - {name: HindPaw, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, 1], mirror: x, material: fur}
  - {name: HindLeg, slot: Body, size: [0.375, 0.5, 0.375], at: [0.5, 0.5, 0.875], mirror: x, material: fur}
  - {name: HindBand, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, 0.875], mirror: x, material: metal}
  - {name: HindClaw, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.3125, 0.03125, 0.625], mirror: x, material: metal}
  - {name: HindClaw2, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.5, 0.03125, 0.625], mirror: x, material: metal}
  - {name: HindClaw3, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.6875, 0.03125, 0.625], mirror: x, material: metal}
  - {name: Mark, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [0.71875, 0.5625, -0.71875], mirror: x}
  - {name: Mark2, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [0.71875, 0.625, -0.59375], mirror: x}
  - {name: Mark3, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [0.71875, 0.5625, -0.46875], mirror: x}
  # the masses: the torso and the square head (a 32-column face)
  - {name: Torso, slot: Body, size: [1.5, 0.75, 2], at: [0, 1.125, 0.125], bevel: true, material: fur}
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 2.125, -0.625], bevel: true}
  # the face's blocks: a pale snout with a dark nose and a small ink smile, two little ice fangs under it, pale cheek tufts
  - {name: Snout, slot: Accessory, size: [0.875, 0.5, 0.375], at: [0, 1.625, -1.6875]}
  - {name: Nose, slot: Eye, size: [0.375, 0.1875, 0.125], at: [0, 1.78125, -1.9375]}
  - {name: Philtrum, slot: Eye, size: [0.125, 0.0625, 0.0625], at: [0, 1.65625, -1.90625]}
  - {name: MouthCurl, slot: Eye, size: [0.125, 0.0625, 0.0625], at: [0.125, 1.59375, -1.90625], mirror: x}
  - {name: Fang, slot: Trim, size: [0.125, 0.1875, 0.125], at: [0.3125, 1.28125, -1.75], mirror: x, material: ice}
  - {name: FangTip, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.3125, 1.125, -1.75], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  - {name: CheekTuft, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1.5, -1.25], mirror: x, material: fur}
  # the hero: a moon of stepped light floating over the brow, two craters on its face; it bobs and rocks
  - {name: MoonA, slot: Glow, size: [0.25, 0.0625, 0.125], at: [0, 2.78125, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: MoonB, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 2.84375, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: MoonC, slot: Glow, size: [0.625, 0.0625, 0.125], at: [0, 2.90625, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: MoonD, slot: Glow, size: [0.625, 0.0625, 0.125], at: [0, 2.96875, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: MoonE, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 3.03125, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: MoonF, slot: Glow, size: [0.25, 0.0625, 0.125], at: [0, 3.09375, -1.6875], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: Crater, slot: Accessory, size: [0.125, 0.125, 0.0625], at: [-0.125, 3, -1.78125], moves: moon, pivot: [0, 2.9375, -1.6875]}
  - {name: Crater2, slot: Accessory, size: [0.125, 0.0625, 0.0625], at: [0.1875, 2.84375, -1.78125], moves: moon, pivot: [0, 2.9375, -1.6875]}
  # tall ears with pale insides and lit tips, each one moving part
  - {name: Ear, slot: Body, size: [0.375, 0.5, 0.25], at: [0.6875, 3.125, -0.75], moves: ear, pivot: [0.6875, 2.875, -0.75], material: fur}
  - {name: InnerEar, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.6875, 3.0625, -0.90625], moves: ear, pivot: [0.6875, 2.875, -0.75]}
  - {name: EarTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 3.4375, -0.75], moves: ear, pivot: [0.6875, 2.875, -0.75]}
  # its left ear is a puppy's, flopped over sideways
  - {name: FlopEar, slot: Body, size: [0.375, 0.5, 0.25], at: [-0.9375, 2.78125, -0.75], rot: [0, 0, 110], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: fur}
  - {name: FlopTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.21875, 2.6875, -0.75], rot: [0, 0, 110], moves: ear, pivot: [-0.6875, 2.875, -0.75]}
  # the mane: four near-black slabs stepping down the neck behind the head, a tuft tipped with moonlight out of each end of the top three,
  # three ridge tufts lit at their tips down the back, and six stars caught in the slabs' fronts
  - {name: ManeA, slot: BodyDark, size: [2.5, 0.375, 0.5], at: [0, 2.5625, 0.375], material: fur}
  - {name: ManeB, slot: BodyDark, size: [2.75, 0.375, 0.5], at: [0, 2.1875, 0.5], material: fur}
  - {name: ManeC, slot: BodyDark, size: [2.5, 0.375, 0.5], at: [0, 1.8125, 0.625], material: fur}
  - {name: ManeD, slot: BodyDark, size: [2, 0.375, 0.5], at: [0, 1.4375, 0.75], material: fur}
  - {name: Tuft, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.4375, 2.5, 0.375], rot: [0, 0, -110], shape: cone6, mirror: x, material: fur}
  - {name: Tuft2, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.5625, 2.125, 0.5], rot: [0, 0, -110], shape: cone6, mirror: x, material: fur}
  - {name: Tuft3, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.4375, 1.75, 0.625], rot: [0, 0, -110], shape: cone6, mirror: x, material: fur}
  - {name: TuftLight, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 2.4375, 0.375], mirror: x}
  - {name: TuftLight2, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.75, 2.0625, 0.5], mirror: x}
  - {name: TuftLight3, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 1.6875, 0.625], mirror: x}
  - {name: Ridge, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.9375, 0.375], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Ridge2, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.5625, 0.6875], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Ridge3, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.1875, 0.8125], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: RidgeLight, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 3.125, 0.4375]}
  - {name: RidgeLight2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.75, 0.75]}
  - {name: RidgeLight3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.375, 0.875]}
  - {name: Star, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.15625, 2.59375, 0.09375], mirror: x}
  - {name: Star2, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.21875, 2.15625, 0.21875], mirror: x}
  - {name: Star3, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.09375, 1.84375, 0.34375], mirror: x}
  # a pale bib on the chest, the silver collar with three studs, and the chain: two links down the chest, the third broken, its ends lit; it swings
  - {name: Bib, slot: Accessory, size: [1, 0.375, 0.0625], at: [0, 1.0625, -0.90625], material: fur}
  - {name: Collar, slot: Trim, size: [1.625, 0.125, 1.125], at: [0, 1.3125, -0.375], material: metal}
  - {name: Stud, slot: Trim, size: [0.125, 0.125, 0.0625], at: [0, 1.3125, -0.96875], material: metal}
  - {name: Stud2, slot: Trim, size: [0.125, 0.125, 0.0625], at: [0.375, 1.3125, -0.96875], mirror: x, material: metal}
  - {name: Link1Top, slot: Trim, size: [0.25, 0.0625, 0.0625], at: [0, 1.21875, -0.96875], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link1Side, slot: Trim, size: [0.0625, 0.1875, 0.0625], at: [0.09375, 1.09375, -0.96875], mirror: x, material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link1Bot, slot: Trim, size: [0.25, 0.0625, 0.0625], at: [0, 0.96875, -0.96875], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link2Top, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0, 0.90625, -1.0625], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link2Front, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [0, 0.78125, -1.15625], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link2Back, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [0, 0.78125, -0.96875], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: Link2Bot, slot: Trim, size: [0.125, 0.0625, 0.25], at: [0, 0.65625, -1.0625], material: metal, moves: chain, pivot: [0, 1.25, -0.96875]}
  - {name: LinkEnd, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [0.09375, 0.5625, -1.03125], mirror: x, moves: chain, pivot: [0, 1.25, -0.96875]}
  # silver plates on the shoulders and a lit moon rune on each flank
  - {name: ShoulderPlate, slot: Trim, size: [0.0625, 0.25, 0.5], at: [0.78125, 1.125, -0.5], mirror: x, material: metal}
  - {name: Rune, slot: Glow, size: [0.0625, 0.375, 0.0625], at: [0.78125, 1, 0.53125], mirror: x}
  - {name: Rune2, slot: Glow, size: [0.0625, 0.0625, 0.1875], at: [0.78125, 1.15625, 0.40625], mirror: x}
  - {name: Rune3, slot: Glow, size: [0.0625, 0.0625, 0.1875], at: [0.78125, 0.84375, 0.65625], mirror: x}
  # the tail, held low and stiff in a silver band, forked at the tip round a core of light; one moving part
  - {name: Tail, slot: Body, size: [0.375, 0.375, 0.875], at: [0, 1.1875, 1.5], moves: tail, pivot: [0, 1.1875, 1.125], material: fur}
  - {name: TailBand, slot: Trim, size: [0.5, 0.5, 0.0625], at: [0, 1.1875, 1.53125], moves: tail, pivot: [0, 1.1875, 1.125], material: metal}
  - {name: TailFork, slot: BodyDark, size: [0.125, 0.375, 0.375], at: [0.125, 1.1875, 2.125], mirror: x, moves: tail, pivot: [0, 1.1875, 1.125], material: fur}
  - {name: TailCore, slot: Glow, size: [0.125, 0.25, 0.25], at: [0, 1.1875, 2.0625], moves: tail, pivot: [0, 1.1875, 1.125]}
  # a silver crescent moon standing behind the mane on its left (in glow cells it vanished against the pale backdrop), horns to the right, rocking slowly (the halo); its rows are sixteenth-grid cells
  - {name: Crescent0, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.3125, 0.5625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent1, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.625, 0.6875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent2, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.8125, 0.8125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent3, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.9375, 0.9375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent4, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.0625, 1.0625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent5, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.125, 1.1875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent6, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.1875, 1.3125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent7, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.25, 1.4375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent8, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.3125, 1.5625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent9, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.3125, 1.6875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent10, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.375, 1.8125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent11, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.375, 1.9375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent12, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.375, 2.0625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent13, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.375, 2.1875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent14, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.3125, 2.3125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent15, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.3125, 2.4375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent16, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.25, 2.5625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent17, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.1875, 2.6875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent18, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.125, 2.8125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent19, slot: Trim, size: [0.75, 0.125, 0.125], at: [-1.0625, 2.9375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent20, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.9375, 3.0625, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent21, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.8125, 3.1875, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent22, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.625, 3.3125, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  - {name: Crescent23, slot: Trim, size: [0.75, 0.125, 0.125], at: [-0.3125, 3.4375, 1.4375], material: metal, moves: halo, pivot: [0, 2, 1.4375]}
  # two moon-dust motes circling it, one high at its right ear, one low at its left shoulder
  - {name: Mote, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.5, 2.875, -0.75], shape: ico1, moves: mote, pivot: [1.5, 2.875, -0.75]}
  - {name: Mote2, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.5, 1.625, -0.5], shape: ico1, moves: mote, pivot: [-1.5, 1.625, -0.5]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 32 columns across the 2-stud head, so the cell is 0.0625 studs (16 a stud) and the 1.5-stud front is 24 rows; the eyes and the cheeks are on the face plate, the nose and the smile on the snout block under it.

```yaml
face:
  host: Head
  cols: 32
```

## Eyes

Its own eyes, new in the eye library for it ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`, Roster w2_high): `lunar`, a Cosmic design, a moon that waxes and wanes across a starry iris over eight frames with a lit periwinkle rim, here a full-moon white moon on deep indigo with a violet dark side, at 32 pixels a stud on a 1.75 x 0.875 stud plate (56 x 28 pixels, thirteen frames: open, half, closed, two glints, eight phases). Star cheeks; the smile is on the snout.

```yaml
eyes:
  key: lunar
  colours: {deep: second, mid: "#5B4FB0", bright: "#E6ECFF", rim: glow, sparkle: "#FFFFFF"}
  mouth: none
  cheeks: stars
  plate: [1.75, 0.875]
  at: [0, 2.1875]
  spread: 0.4375
  eye_top: 3
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`). The flourish is the howl, on the 20 s beat of the Effects.luau pillar of moonlight.

```yaml
rig:
  clips:
    moon: [{kind: bob, amp: 0.06, period: 2.6}, {kind: sway, amp: 8, period: 5.2, axis: z}]
    ear: [{kind: wag, amp: 15, period: 3.2, axis: z}]
    chain: [{kind: sway, amp: 10, period: 1.9, axis: x}]
    halo: [{kind: sway, amp: 6, period: 6, axis: z}]
    tail: [{kind: wag, amp: 18, period: 2.4, axis: y}]
    mote: [{kind: orbit, amp: 0.15, period: 3.6}, {kind: bob, amp: 0.05, period: 1.8, phase: 0.5}]
    root: [{kind: squash, amp: 0.03, period: 2.4}]
    face: [{kind: blink, period: 4.8}]
  flourish:
    every: 20
    length: 3.2
    moves:
      - {part: root, kind: squash, amp: 0.12, at: 0, for: 0.5}
      - {part: root, kind: hop, amp: 0.45, at: 0.5, for: 0.9}
      - {part: root, kind: turn, amp: 360, at: 0.6, for: 1.6}
      - {part: ear, kind: flare, amp: 25, at: 0.4, for: 1.2}
      - {part: root, kind: flare, amp: 12, axis: x, at: 2.2, for: 0.9}
      - {part: moon, kind: pop, amp: 0.3, at: 1.2, for: 1.4}
      - {part: tail, kind: swish, amp: 30, at: 1, for: 1.4}
      - {part: mote, kind: hop, amp: 0.3, at: 1.6, for: 1}
      - {part: halo, kind: pop, amp: 0.12, at: 1.4, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Fenripup.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Fenripup.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Fenripup_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Fenripup_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Fenripup_idle.png]]

The concept sheet, drawn from the parts table above: [[Fenripup_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/Roster w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.0625 studs (16 a stud, the 32-column face). Materials: `fur` on the coat (the legs, the torso, the mane, the tufts, the tail, the cheek tufts and the bib), skin on the head so the tufts never crowd the face, `ice` on the fangs, `metal` on the bands, claws, plates, collar, studs, chain and crescent, glow cells on the moon, the marks, the runes, the tuft and ridge lights, the caught stars, the chain ends, the tail core and the motes.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: a 5.5-stud head on a 14-stud wolf fell under rule 2's 40 percent, so the head is 6 studs (16 cells of 0.375, Raddis's cell) and the ears and tufts shortened to keep 14; a fifth moon row touched the eyes' top row, so the moon is four rows with a quarter stud of brow between. The chain's interlocking links shared faces where they crossed (they would shimmer), so each link hangs from the one above, touching. Round 2: the first build's mane read as a dark staircase behind the head, so each of the top three slabs got a tuft pointing out of each end (the mane is now 10 studs across and ragged, a ruff rather than a stack) and the ears grew from nubs to a stud and a half, set into the head's top so the height stays 14; the cheek ruffs and the chin tufts close the ring. Overlap 0.996 to 0.999, 1,436 triangles, 110 blocks, 14 studs, four moving objects (the ears, the tail, the orb). Wanted for: the most impressive thing in Frostbyte, a mount with a moon on its brow and a chain it broke. Still cheap: from the side the torso is a long box between the mane and the haunches; the leg marks are thin; 16 face cells over 6 studs are big pixels in a close-up (the Cosmic close-up question open in [[Blocky-Style]]). Status review, two face options on the sheet for Ethan.
