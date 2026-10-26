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
blocks: 151
tris: 1882
bevel_width: 0.0625
bevel_segments: 2
palette: ["#4B3D8F", "#1E1A47", "#B9C6E0", "#D9E2F5", "#AEB8FF", "#0E0B1E"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#AEB8FF", "#E6ECFF", "#7F74E6"]
hero: MoonC
fx_hooks: {Top: MoonD, Halo: MoonStar3, Mouth: Nose, Body: Rune, Tail: TailCore, Feet: FrontPaw, Moon: MoonD, Mane: ManeA}
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
bar_world: Frostbyte
bar_kit: 11
bar_pieces: [aurora_wisp, frost_rim, ice_shard, silver_band, snowflake_stud]
bar_stance: "a pup braced to howl: the paws split front and back, the tail cocked up over the rump, a crescent moon standing behind it"
bar_satellites: 8
bar_orbit: phases
bar_backdrop: halo
bar_aura: aura
---
# Fenripup (Fenrir), Cosmic, World 2 Frostbyte

A moon wolf pup, 3.5 studs to its ear tips (B45; it was a 14-stud mount, redesigned at a pup's size, not scaled; it grows to riding size only while ridden, Decide-Now 44 a): an indigo wolf on four sturdy legs with silver ankle bands and silver claws, a square head with a 32-column face (sixteenth-stud cells, a finer body than anything else in Frostbyte), a pale snout block with a dark nose and a small ink smile, two little ice fangs under it, pale cheek tufts, a tall left ear and a puppy's right ear flopped over sideways (on the side the three-quarter camera sees), both with pale insides and lit tips, and over its brow, floating on nothing, a gibbous moon a stud wide, lit on one side and indigo on the other, with three attendant stars, rocking gently. Behind the head stands its mane, four slabs of star-field cells (the nebula motif) stepping down the neck, each end of the top three slabs ending in a tuft tipped with moonlight, three ridge tufts lit at their tips running down the back, and six stars caught in the mane's front. A silver collar with three studs holds a chain of two links down its pale chest, the third link broken, its two ends lit (the echo of the bound Fenrir, worn as a trophy). Silver plates on its shoulders, a lit rune on each flank, three moon marks on each foreleg, and a tail held low and stiff in a silver band that forks round a core of light. Behind the mane on its right stands a silver crescent moon in sixteenth-stud rows, a quarter stud thin at its horns and seven eighths at its middle, horns to its left, rocking slowly, and two moon-dust motes circle it, one high at its left ear and one low at its right shoulder. Concept row in `src/shared/data/Species.luau`: "puppy, glowing moon on its forehead; echo of Fenrir". Element: Moon (`Effects.luau`); [[Roster-Redesign]] section 2 and the Fenrir brief in section 3. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** Ethan on the old Fenrir: it "looks too cute, and not really something that would appeal to people who worked so hard to find him"; and since: rarer means more exclusive and cooler or cuter, never bigger (B45) or fiercer. So Fenrir is World 2's hero by everything but size: 138 blocks at the same height as the Rares, most of them sixteenth-grid cells (claws, bands, chain links, runes, marks, caught stars) on a 32-column body no other Frostbyte alien has; eyes of its own, the `lunar` design new in the library for it, a moon that waxes and wanes across a starry iris over eight frames on a 32-pixel-a-stud plate, with star cheeks; nine moving things including a moon that floats over its brow and a crescent that rocks behind it; and every 20 s the howl, a crouch, a hop into a full turn and a rear back with the ears up while a column of moonlight stands from its head into the sky. A pup, cute and cooler: the fangs are small and lit, the face a soft smile under lunar eyes.

**Hero block.** The floating moon (`MoonC`, the widest of its nine stepped rows), a gibbous moon in phase over the brow with attendant stars, unique in Frostbyte.

**Moving parts (eleven objects and the blink).** `moon` (it bobs and rocks, and flips on the howl), `halo` (the crescent rocks), `earR`, `earL` (the standing ear and the flopped one flick), `chain` (it swings), `tail` (it wags), `moteR`, `moteL` (they circle), `shade` (the moon's dark limb, moving with it), `mane` (the nebula mane breathes and lifts on the howl), `stars` (the mane's lit tips and caught stars, moving with it); the face plate blinks, glints and its moons wax and wane.

**Alien anatomy.** Fangs of ice outside the mouth, a mane that is a stack of slabs with stars caught in it, a chain that is part of its body (the broken ends glow), a moon that floats on nothing, and a tail that forks round a core of light.

**World motif (Frostbyte).** Icicles (the fangs) and the ice facet as steps: the moon is a stepped disc, the mane a stepped stack, the tufts stepped points.

## Parts

```yaml
parts:
  # the stance, a pup braced to howl: the right forepaw planted a quarter stud forward, the left one back, the hind pair split the same way
  # (the right hind back, the left hind forward); a silver band at each ankle and one moon mark on each foreleg (the claws were under a
  # quarter stud, so they are cut)
  - {name: FrontPawR, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, -1], material: fur}
  - {name: FrontLegR, slot: Body, size: [0.375, 0.5, 0.375], at: [0.5, 0.5, -0.875], material: fur}
  - {name: FrontBandR, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, -0.875], material: metal}
  - {name: FrontPawL, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [-0.5, 0.125, -0.625], material: fur}
  - {name: FrontLegL, slot: Body, size: [0.375, 0.5, 0.375], at: [-0.5, 0.5, -0.5], material: fur}
  - {name: FrontBandL, slot: Trim, size: [0.5, 0.0625, 0.5], at: [-0.5, 0.28125, -0.5], material: metal}
  - {name: HindPawR, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, 1.125], material: fur}
  - {name: HindLegR, slot: Body, size: [0.375, 0.5, 0.375], at: [0.5, 0.5, 1], material: fur}
  - {name: HindBandR, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, 1], material: metal}
  - {name: HindPawL, slot: BodyDark, size: [0.5, 0.25, 0.625], at: [-0.5, 0.125, 0.875], material: fur}
  - {name: HindLegL, slot: Body, size: [0.375, 0.5, 0.375], at: [-0.5, 0.5, 0.75], material: fur}
  - {name: HindBandL, slot: Trim, size: [0.5, 0.0625, 0.5], at: [-0.5, 0.28125, 0.75], material: metal}
  - {name: MarkR, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [0.71875, 0.625, -0.84375]}
  - {name: MarkL, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [-0.71875, 0.625, -0.46875]}
  # the masses: the torso and the square head (a 32-column face)
  - {name: Torso, slot: Body, size: [1.5, 0.75, 2], at: [0, 1.125, 0.125], bevel: true, material: fur}
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 2.125, -0.625], bevel: true}
  # the face's blocks: a pale snout with a dark nose and a small ink smile, pale cheek tufts (the two little ice fangs are gone: the face stays calm at every tier, Decide-Now 51 option b)
  - {name: Snout, slot: Accessory, size: [0.875, 0.5, 0.375], at: [0, 1.625, -1.6875]}
  - {name: Nose, slot: Eye, size: [0.375, 0.1875, 0.125], at: [0, 1.78125, -1.9375]}
  - {name: Philtrum, slot: Eye, size: [0.125, 0.0625, 0.0625], at: [0, 1.65625, -1.90625]}
  - {name: MouthCurl, slot: Eye, size: [0.125, 0.0625, 0.0625], at: [0.125, 1.59375, -1.90625], mirror: x}
  - {name: CheekTuft, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1.5, -1.25], mirror: x, material: fur}
  # the hero: a full moon of stepped light rising over the brow, a stud wide (Rare pass w2: the 0.625 disc in front of the forehead read as a
  # small white disc), nine sixteenth rows from just over the face plate to 0.375 above the crown, so half of it breaks the head's top edge
  # against the sky; no craters (pale ones on a pale glow vanished, indigo ones read as spots, silver ones at night as a skull or a 9:
  # the phase alone says moon); it bobs, rocks and, on the howl, flips
  - {name: MoonA, slot: Glow, size: [0.25, 0.0625, 0.125], at: [0.0625, 2.96875, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonADark, slot: Body, size: [0.125, 0.0625, 0.125], at: [-0.125, 2.96875, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonB, slot: Glow, size: [0.375, 0.0625, 0.125], at: [0.125, 3.03125, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonBDark, slot: Body, size: [0.25, 0.0625, 0.125], at: [-0.1875, 3.03125, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonC0, slot: Glow, size: [0.4375, 0.0625, 0.125], at: [0.15625, 3.09375, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonC0Dark, slot: Body, size: [0.3125, 0.0625, 0.125], at: [-0.21875, 3.09375, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonC, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0.1875, 3.15625, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonCDark, slot: Body, size: [0.375, 0.0625, 0.125], at: [-0.25, 3.15625, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonD, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0.1875, 3.21875, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonDDark, slot: Body, size: [0.375, 0.0625, 0.125], at: [-0.25, 3.21875, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonD2, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0.1875, 3.28125, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonD2Dark, slot: Body, size: [0.375, 0.0625, 0.125], at: [-0.25, 3.28125, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonE, slot: Glow, size: [0.4375, 0.0625, 0.125], at: [0.15625, 3.34375, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonEDark, slot: Body, size: [0.3125, 0.0625, 0.125], at: [-0.21875, 3.34375, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonF, slot: Glow, size: [0.375, 0.0625, 0.125], at: [0.125, 3.40625, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonFDark, slot: Body, size: [0.25, 0.0625, 0.125], at: [-0.1875, 3.40625, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonG, slot: Glow, size: [0.25, 0.0625, 0.125], at: [0.0625, 3.46875, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonGDark, slot: Body, size: [0.125, 0.0625, 0.125], at: [-0.125, 3.46875, -1.6875], moves: shade, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonStar, slot: Glow, size: [0.0625, 0.0625, 0.125], at: [0.59375, 3.34375, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonStar2, slot: Glow, size: [0.0625, 0.0625, 0.125], at: [0.53125, 3.03125, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  - {name: MoonStar3, slot: Glow, size: [0.0625, 0.0625, 0.125], at: [-0.40625, 3.40625, -1.6875], moves: moon, pivot: [0, 3.21875, -1.6875]}
  # tall ears with pale insides and lit tips, each one moving part
  - {name: Ear, slot: Body, size: [0.375, 0.5, 0.25], at: [-0.6875, 3.125, -0.75], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: fur}
  - {name: InnerEar, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [-0.6875, 3.0625, -0.90625], moves: ear, pivot: [-0.6875, 2.875, -0.75]}
  - {name: EarTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.6875, 3.4375, -0.75], moves: ear, pivot: [-0.6875, 2.875, -0.75]}
  # its right ear is a puppy's, flopped over sideways (the side the three-quarter camera sees)
  - {name: FlopEar, slot: Body, size: [0.375, 0.5, 0.25], at: [0.9375, 2.78125, -0.75], rot: [0, 0, -110], moves: ear, pivot: [0.6875, 2.875, -0.75], material: fur}
  - {name: FlopTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.21875, 2.6875, -0.75], rot: [0, 0, -110], moves: ear, pivot: [0.6875, 2.875, -0.75]}
  # the nebula mane (Rare pass w2): four near-black slabs of star-field cells (the nebula motif, Cosmic only) stepping down the neck behind
  # the head, a tuft tipped with moonlight out of each end of the top three, three ridge tufts lit at their tips down the back, and six stars
  # caught in the slabs' fronts; the whole mane is one moving part that breathes and lifts on the howl
  - {name: ManeA, slot: BodyDark, size: [2.5, 0.375, 0.5], at: [0, 2.5625, 0.375], material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: ManeB, slot: BodyDark, size: [2.75, 0.375, 0.5], at: [0, 2.1875, 0.5], material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: ManeC, slot: BodyDark, size: [2.5, 0.375, 0.5], at: [0, 1.8125, 0.625], material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: ManeD, slot: BodyDark, size: [2, 0.375, 0.5], at: [0, 1.4375, 0.75], material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: Tuft, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.4375, 2.5, 0.375], rot: [0, 0, -110], shape: cone6, mirror: x, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: Tuft2, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.5625, 2.125, 0.5], rot: [0, 0, -110], shape: cone6, mirror: x, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: Tuft3, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [1.4375, 1.75, 0.625], rot: [0, 0, -110], shape: cone6, mirror: x, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: TuftLight, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 2.4375, 0.375], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: TuftLight2, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.75, 2.0625, 0.5], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: TuftLight3, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.625, 1.6875, 0.625], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: Ridge, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.9375, 0.375], rot: [20, 0, 0], shape: cone6, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: Ridge2, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.5625, 0.6875], rot: [20, 0, 0], shape: cone6, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: Ridge3, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 2.1875, 0.8125], rot: [20, 0, 0], shape: cone6, material: nebula, moves: mane, pivot: [0, 1.25, 0.75]}
  - {name: RidgeLight, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 3.125, 0.4375], moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: RidgeLight2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.75, 0.75], moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: RidgeLight3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.375, 0.875], moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: Star, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.15625, 2.59375, 0.09375], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: Star2, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.21875, 2.15625, 0.21875], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  - {name: Star3, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [1.09375, 1.84375, 0.34375], mirror: x, moves: stars, pivot: [0, 1.25, 0.75]}
  # a pale bib on the chest, the silver collar with three studs, and the chain: two links down the chest, the third broken, its ends lit; it swings
  - {name: Bib, slot: Accessory, size: [1, 0.375, 0.0625], at: [0, 1.0625, -0.90625], material: fur}
  - {name: Collar, slot: Trim, size: [1.625, 0.125, 1.125], at: [0, 1.3125, -0.375], material: metal}
  - {name: Stud, slot: Trim, size: [0.125, 0.125, 0.0625], at: [0, 1.3125, -0.96875], material: metal}
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
  # the tail, cocked up over the rump in two steps (it was held low and stiff): a silver band at the joint, forked at the tip round a core of
  # light; one moving part
  - {name: Tail, slot: Body, size: [0.375, 0.375, 0.625], at: [0, 1.3125, 1.4375], moves: tail, pivot: [0, 1.1875, 1.125], material: fur}
  - {name: TailMid, slot: Body, size: [0.375, 0.5, 0.375], at: [0, 1.75, 1.5625], moves: tail, pivot: [0, 1.1875, 1.125], material: fur}
  - {name: TailBand, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0, 1.53125, 1.5625], moves: tail, pivot: [0, 1.1875, 1.125], material: metal}
  - {name: TailFork, slot: BodyDark, size: [0.125, 0.375, 0.375], at: [0.125, 2.1875, 1.5625], mirror: x, moves: tail, pivot: [0, 1.1875, 1.125], material: nebula}
  - {name: TailCore, slot: Glow, size: [0.125, 0.25, 0.25], at: [0, 2.125, 1.5625], moves: tail, pivot: [0, 1.1875, 1.125]}
  # pilot bar: begin (tools/blocky/pilots.py writes this region: the Frostbyte kit, the crescent backdrop, the satellite set and the aura)
  # the Frostbyte kit: frost rims on the head's top front
  - {name: Rima, slot: Accessory, size: [0.5, 0.0625, 0.125], at: [0.5, 2.90625, -1.3125], mirror: x, material: ice}
  - {name: Rimb, slot: Accessory, size: [0.0625, 0.125, 0.125], at: [0.34375, 3, -1.3125], mirror: x, material: ice}
  - {name: Rimc, slot: Accessory, size: [0.0625, 0.125, 0.125], at: [0.53125, 3, -1.3125], mirror: x, material: ice}
  - {name: Rimd, slot: Accessory, size: [0.0625, 0.125, 0.125], at: [0.71875, 3, -1.3125], mirror: x, material: ice}
  # ice shards standing on the mane's top two slabs (they ride the mane)
  - {name: ShardAa, slot: Accessory, size: [0.25, 0.5, 0.25], at: [0.875, 3, 0.375], rot: [14, 0, 0], shape: cone6, mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: ice}
  - {name: ShardAb, slot: Accessory, size: [0.125, 0.25, 0.125], at: [1, 2.875, 0.375], rot: [0, -16, 0], shape: cone6, mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: ice}
  - {name: ShardBa, slot: Accessory, size: [0.25, 0.5, 0.25], at: [1.125, 2.625, 0.5], rot: [14, 0, 0], shape: cone6, mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: ice}
  - {name: ShardBb, slot: Accessory, size: [0.125, 0.25, 0.125], at: [1.25, 2.5, 0.5], rot: [0, -16, 0], shape: cone6, mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: ice}
  # snowflake studs on the shoulder plates
  - {name: Flakea, slot: Trim, size: [0.0625, 0.0625, 0.25], at: [0.84375, 1.15625, -0.5], mirror: x, material: metal}
  - {name: Flakeb, slot: Trim, size: [0.0625, 0.25, 0.0625], at: [0.84375, 1.125, -0.46875], mirror: x, material: metal}
  - {name: Flakec, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [0.90625, 1.15625, -0.46875], mirror: x, material: crystal}
  # a silver band at the left ear's root (it rides the ear)
  - {name: EarBandF, slot: Trim, size: [0.5, 0.125, 0.0625], at: [-0.6875, 2.9375, -0.90625], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: metal}
  - {name: EarBandB, slot: Trim, size: [0.5, 0.125, 0.0625], at: [-0.6875, 2.9375, -0.59375], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: metal}
  - {name: EarBandR, slot: Trim, size: [0.0625, 0.125, 0.25], at: [-0.46875, 2.9375, -0.75], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: metal}
  - {name: EarBandL, slot: Trim, size: [0.0625, 0.125, 0.25], at: [-0.90625, 2.9375, -0.75], moves: ear, pivot: [-0.6875, 2.875, -0.75], material: metal}
  # aurora wisps rising off the mane's top slab (they ride the mane)
  - {name: Wispa, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.5, 2.8125, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  - {name: Wispb, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.5625, 2.9375, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  - {name: Wispc, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.625, 3.0625, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  - {name: Wispd, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.5625, 3.1875, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  - {name: Wispe, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.5, 3.3125, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  - {name: Wispf, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.4375, 3.4375, 0.34375], mirror: x, moves: mane, pivot: [0, 1.25, 0.75], material: crystal}
  # the backdrop: a crescent moon thirteen cells tall standing behind the whole alien, thick on its right, its horns to the left, rocking slowly (the halo)
  - {name: Crescent0, slot: Trim, size: [1.75, 0.25, 0.125], at: [0, 0.375, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent1, slot: Trim, size: [1.375, 0.25, 0.125], at: [0.4375, 0.625, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent2, slot: Trim, size: [1.125, 0.25, 0.125], at: [0.8125, 0.875, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent3, slot: Trim, size: [1, 0.25, 0.125], at: [1, 1.125, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent4, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.1875, 1.375, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent5, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.1875, 1.625, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent6, slot: Trim, size: [0.75, 0.25, 0.125], at: [1.25, 1.875, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent7, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.1875, 2.125, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent8, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.1875, 2.375, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent9, slot: Trim, size: [1, 0.25, 0.125], at: [1, 2.625, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent10, slot: Trim, size: [1.125, 0.25, 0.125], at: [0.8125, 2.875, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent11, slot: Trim, size: [1.375, 0.25, 0.125], at: [0.4375, 3.125, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  - {name: Crescent12, slot: Trim, size: [1.75, 0.25, 0.125], at: [0, 3.375, 1.4375], moves: halo, pivot: [0, 1.875, 1.4375], material: metal}
  # the satellite set (`phases`, one orbit turning against the mane): the moon in four phases (one twice) and three frost shards, below the face
  - {name: Sat0a, slot: Glow, size: [0.375, 0.25, 0.0625], at: [-0.0625, 0.9375, -1.78125], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat0b, slot: Glow, size: [0.25, 0.5, 0.0625], at: [0, 0.9375, -1.78125], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat0c, slot: Body, size: [0.125, 0.25, 0.0625], at: [0.1875, 0.9375, -1.78125], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat1a, slot: Accessory, size: [0.25, 0.5, 0.25], at: [1.375, 1.3125, -1.1875], rot: [18, 0, 0], shape: cone6, moves: phases, pivot: [0, 0.95, 0.2], material: ice}
  - {name: Sat2a, slot: Glow, size: [0.0625, 0.25, 0.25], at: [1.96875, 1.125, 0.3125], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat2b, slot: Glow, size: [0.0625, 0.5, 0.125], at: [1.96875, 1.125, 0.25], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat2c, slot: Body, size: [0.0625, 0.25, 0.25], at: [1.96875, 1.125, 0.0625], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat2d, slot: Body, size: [0.0625, 0.5, 0.125], at: [1.96875, 1.125, 0.125], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat3a, slot: Accessory, size: [0.25, 0.5, 0.25], at: [1.375, 1.3125, 1.5625], rot: [18, 0, 0], shape: cone6, moves: phases, pivot: [0, 0.95, 0.2], material: ice}
  - {name: Sat4a, slot: Body, size: [0.375, 0.25, 0.0625], at: [0.0625, 0.9375, 2.15625], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat4b, slot: Body, size: [0.125, 0.5, 0.0625], at: [0.0625, 0.9375, 2.15625], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat4c, slot: Glow, size: [0.125, 0.25, 0.0625], at: [-0.1875, 0.9375, 2.15625], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat4d, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-0.0625, 1.125, 2.15625], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat4e, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-0.0625, 0.75, 2.15625], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat5a, slot: Body, size: [0.5, 0.25, 0.0625], at: [-1.375, 0.8125, 1.59375], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat5b, slot: Body, size: [0.25, 0.5, 0.0625], at: [-1.375, 0.8125, 1.59375], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat5c, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [-1.53125, 0.84375, 1.65625], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat6a, slot: Accessory, size: [0.25, 0.5, 0.25], at: [-1.9375, 1, 0.1875], rot: [18, 0, 0], shape: cone6, moves: phases, pivot: [0, 0.95, 0.2], material: ice}
  - {name: Sat7a, slot: Glow, size: [0.0625, 0.25, 0.25], at: [-1.40625, 0.8125, -1.3125], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat7b, slot: Glow, size: [0.0625, 0.5, 0.125], at: [-1.40625, 0.8125, -1.25], moves: phases, pivot: [0, 0.95, 0.2], material: crystal}
  - {name: Sat7c, slot: Body, size: [0.0625, 0.25, 0.25], at: [-1.40625, 0.8125, -1.0625], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  - {name: Sat7d, slot: Body, size: [0.0625, 0.5, 0.125], at: [-1.40625, 0.8125, -1.125], moves: phases, pivot: [0, 0.95, 0.2], material: fur}
  # the ground aura (`aura`, it breathes): twelve dashes, lit and dark in turn so the ring reads on snow
  - {name: Aura0, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 0.03125, -2], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura1, slot: BodyDark, size: [0.5, 0.0625, 0.125], at: [1.125, 0.03125, -1.625], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  - {name: Aura2, slot: Glow, size: [0.125, 0.0625, 0.5], at: [1.875, 0.03125, -0.875], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura3, slot: BodyDark, size: [0.125, 0.0625, 0.5], at: [2.125, 0.03125, 0.25], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  - {name: Aura4, slot: Glow, size: [0.125, 0.0625, 0.5], at: [1.875, 0.03125, 1.25], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura5, slot: BodyDark, size: [0.5, 0.0625, 0.125], at: [1.125, 0.03125, 2], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  - {name: Aura6, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 0.03125, 2.375], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura7, slot: BodyDark, size: [0.5, 0.0625, 0.125], at: [-1.125, 0.03125, 2], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  - {name: Aura8, slot: Glow, size: [0.125, 0.0625, 0.5], at: [-1.875, 0.03125, 1.25], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura9, slot: BodyDark, size: [0.125, 0.0625, 0.5], at: [-2.125, 0.03125, 0.25], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  - {name: Aura10, slot: Glow, size: [0.125, 0.0625, 0.5], at: [-1.875, 0.03125, -0.875], moves: aura, pivot: [0, 0.03125, 0.2], material: crystal}
  - {name: Aura11, slot: BodyDark, size: [0.5, 0.0625, 0.125], at: [-1.125, 0.03125, -1.625], moves: aura, pivot: [0, 0.03125, 0.2], material: nebula}
  # pilot bar: end
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
    phases: [{kind: spin, amp: -360, period: 18, axis: y}, {kind: bob, amp: 0.05, period: 3.2}]
    aura: [{kind: pulse, amp: 0.1, period: 3.4}]
    mane: [{kind: sway, amp: 3, period: 3.6, axis: x}, {kind: pulse, amp: 0.02, period: 2.4}]
    shade: [{kind: bob, amp: 0.06, period: 2.6}, {kind: sway, amp: 8, period: 5.2, axis: z}]
    stars: [{kind: sway, amp: 3, period: 3.6, axis: x}, {kind: pulse, amp: 0.02, period: 2.4}]
    root: [{kind: squash, amp: 0.03, period: 2.4}]
    face: [{kind: blink, period: 4.8}]
  flourish:
    every: 20
    length: 3.8
    moves:
      - {part: root, kind: squash, amp: 0.12, at: 0, for: 0.5}
      - {part: root, kind: hop, amp: 0.5, at: 0.5, for: 0.9}
      - {part: root, kind: turn, amp: 360, at: 0.6, for: 1.6}
      - {part: ear, kind: flare, amp: 25, at: 0.4, for: 1.2}
      - {part: moon, kind: turn, amp: 360, axis: y, at: 0.8, for: 1.4}
      - {part: shade, kind: turn, amp: 360, axis: y, at: 0.8, for: 1.4}
      - {part: tail, kind: swish, amp: 30, at: 1, for: 1.4}
      - {part: phases, kind: hop, amp: 0.3, at: 1.6, for: 1}
      - {part: aura, kind: pop, amp: 0.25, at: 0.2, for: 1.4}
      - {part: root, kind: flare, amp: 12, axis: x, at: 2.2, for: 1.4}
      - {part: mane, kind: flare, amp: -15, axis: x, at: 2.2, for: 1.4}
      - {part: stars, kind: flare, amp: -15, axis: x, at: 2.2, for: 1.4}
      - {part: moon, kind: pop, amp: 0.35, at: 2.2, for: 1.4}
      - {part: shade, kind: pop, amp: 0.35, at: 2.2, for: 1.4}
      - {part: halo, kind: pop, amp: 0.15, at: 2.0, for: 1.6}
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

The concept sheet, drawn from the parts table above: [[Fenripup_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/roster_w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.0625 studs (16 a stud, the 32-column face). Materials: `fur` on the coat (the legs, the torso, the mane, the tufts, the tail, the cheek tufts and the bib), skin on the head so the tufts never crowd the face, `ice` on the fangs, `metal` on the bands, claws, plates, collar, studs, chain and crescent, glow cells on the moon, the marks, the runes, the tuft and ridge lights, the caught stars, the chain ends, the tail core and the motes.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: a 5.5-stud head on a 14-stud wolf fell under rule 2's 40 percent, so the head is 6 studs (16 cells of 0.375, Raddis's cell) and the ears and tufts shortened to keep 14; a fifth moon row touched the eyes' top row, so the moon is four rows with a quarter stud of brow between. The chain's interlocking links shared faces where they crossed (they would shimmer), so each link hangs from the one above, touching. Round 2: the first build's mane read as a dark staircase behind the head, so each of the top three slabs got a tuft pointing out of each end (the mane is now 10 studs across and ragged, a ruff rather than a stack) and the ears grew from nubs to a stud and a half, set into the head's top so the height stays 14; the cheek ruffs and the chin tufts close the ring. Overlap 0.996 to 0.999, 1,436 triangles, 110 blocks, 14 studs, four moving objects (the ears, the tail, the orb). Wanted for: the most impressive thing in Frostbyte, a mount with a moon on its brow and a chain it broke. Still cheap: from the side the torso is a long box between the mane and the haunches; the leg marks are thin; 16 face cells over 6 studs are big pixels in a close-up (the Cosmic close-up question open in [[Blocky-Style]]). Status review, two face options on the sheet for Ethan.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, three rounds. Round 1: redesigned at 3.5 studs from 14, not scaled: a pup on four banded, clawed legs, a 2-stud head with a 32-column face (sixteenth-stud body cells), a pale snout block with a dark nose and ink smile, two small ice fangs, a floating moon of six stepped rows with two craters, a four-slab mane with lit tuft and ridge tips and six caught stars, the collar and a two-link chain whose broken ends glow, flank runes, leg marks, the forked tail round a core of light, two motes: 138 blocks. Its own eyes, `lunar`, added to the library for it (a moon waxing and waning across a starry iris over eight frames, 32 px a stud), star cheeks. Round 2 (the silhouette test): it sat at 0.70 with Sabrek, so a silver crescent of sixteenth-stud rows stands behind its mane on its left, its left ear flops like a puppy's and the motes sit high right and low left (0.66). Round 3: the crescent in glow cells vanished against the pale backdrop, so it is silver; the moon moved from lying over the crown to floating in front of the brow. Rig: the moon bobs and rocks, the crescent rocks, the ears flick, the chain swings, the tail wags, two motes circle, it breathes and blinks (nine moving things); every 20 s the howl: a crouch, a hop into a full turn, a rear back with the ears up, the moon and the crescent flaring, under the Effects.luau pillar of moonlight. Overlap 0.995 to 0.998, 1,714 triangles. Wanted for: World 2's hero by detail, eyes, light and motion at a Rare's height, a moon pup with a moon over its brow and a crescent at its back. Still cheap: from the three-quarter camera the crescent rises behind the head like a single pale horn before it reads as a moon; the floating moon is small and reads as a white disc; the flopped ear is on the side the camera does not see. Status review.
- 2026-10-21, Polish w2 worker: the crescent read as a pale horn from three-quarter because the head hid all but its top. The whole asymmetry is mirrored (every unmirrored part across x): the crescent now stands behind the mane on its right, where the three-quarter and high cameras see all of it beside the head against the dark mane, the flopped puppy ear is on the camera's side, the motes swap shoulders; and the crescent's rows taper from a quarter stud at each horn to seven eighths at its middle, so both thin tips read and it is a moon, not a horn (a horn is thick at one end). 138 blocks, 1,714 triangles, overlap 0.995 to 0.998; silhouette worst pair Fenrir and Sabrek 0.67. Honest read: from three-quarter it is now a moon pup with a crescent at its back at first glance, and the flopped ear finally shows; from the front the crescent sits on the other side and still frames the head. Left as it was: the floating moon is still a small white disc (not on this pass's list).
- 2026-10-21, Rare pass w2 (also the open item: the floating moon read as a small white disc): the moon is now **a moon in phase**, a stud wide in nine sixteenth rows floating clear over the crown from just above the face plate to the 3.5-stud top, gibbous: each row lit on one side and dark indigo on the other (the dark limb disappears into the head and shows against the sky, so the disc reads as a moon, like the lunar eyes), no maria (dark cells on a lit disc read as a face or a glyph at night: four as a skull, two as a 9; the phase alone says moon) and three attendant stars; it flips a full turn in the howl. The signature is the **nebula star mane**: the mane's slabs, tufts and ridge in the Cosmic-only nebula motif (star cells in the glow colour on near-black) and the tail's fork too; the whole mane is one moving part that breathes and lifts on the howl. The moon's dark limb (`shade`) and the mane's lit cells (`stars`) are their own objects on the same pivots and clips, because the game makes a moving part Neon only when most of its faces are glow: split, the lit moon and the mane's stars still glow. 151 blocks, twelve moving things (from nine), the howl 3.8 s with twelve moves. New attach points: `Moon` (MoonD), `Mane` (ManeA). Honest read: from the front the moon reads as a moon in phase over its head and the mane as a slice of night sky; from three-quarter the moon is still small at the game camera's distance and the height band (3.5) caps it.
