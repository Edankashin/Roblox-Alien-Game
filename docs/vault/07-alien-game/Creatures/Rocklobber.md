---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Rocklobber
name: Boulden
world: 1
tier: Rare
status: review
element: Stone
height: 3.12
blocks: 109
tris: 1404
bevel_width: 0.1
bevel_segments: 2
palette: ["#C8553D", "#3A3238", "#A39E94", "#E0B04A", "#FF8C1A", "#1C1418"]
roles: [body, second, accent, trim, glow, ink]
hero: Claw
vfx: "a soft light (Rare), three layers in Effects.luau: a warm amber light pulsing on its left claw (FrontL) where the gem sits; every 5 s the claws clack and a puff of six grey grit chips falls from that claw; a gold sparkle on the right claw's gem (FrontR) every 3 s. The flourish (every 9 s) raises both boulders overhead, hops and clacks them twice"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Rocklobber_sheet.svg]]"
render: "[[Rocklobber_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.996, 0.999, 0.996]
vfx_render: "[[Rocklobber_vfx_cells.jpg]]"
cells_render: "[[Rocklobber_tq_cells.jpg]]"
idle_render: "[[Rocklobber_idle.png]]"
bar_world: Verdant
bar_kit: 4
bar_pieces: [bark_band, moss_cells, vine_wrap]
bar_stance: "a champion's pose: the right boulder hoisted high, the left swung low and out, the shell square between them, a gold belt round its waist"
bar_satellites: 6
bar_orbit: trophies
---
# Rocklobber (Boulden), Rare, World 1 Verdant

A rust-red crab whose claws are boulders, 3.125 studs to the tip of its antenna (B45: a squat crab, so its shell sits low in the band; it was 3): a wide low shell (the head, with the face plate) under a dark carapace rim and a rust dome step with a gold cairn glyph, six dark jointed legs splayed out like a crab's (each a thigh rising out from under the shell to a knee and a thin shin dropping to a point), two short arms ending in grey boulders built in two steps, each with a stone thumb over it, a stone nip under it and an amber gem set in a dark iron socket on its face. One antenna carries a stepped pebble. Concept row in `src/shared/data/Species.luau`: "crab, boulder claws". Element and effect: [[Roster-Redesign]] section 2 (Stone; the claws clack with a dust puff). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The claws are absurd: two boulders on a crab the size of a shoe, held up like trophies, and they clack. Next to the Uncommons at the same height it carries more and smaller blocks (35 to Buzzik's 15): the stepped boulders with thumbs and nips, the gems in gold bezels, the jointed legs, the dome and its glyph; its own `crescent` eyes (an ink drop over a gold band and an amber crescent that matches its gems, with a glint) where the Commons wear plain ink; six moving things (both boulders, both front legs, the antenna and the blink); and a flourish every 9 s that reads across the meadow: it hops with both boulders raised overhead and clacks them twice.

**Hero block.** The `Claw` pair, boulders of grey stone with an amber gem in a dark iron socket each, unique in Verdant (Polish w1: a gold bezel round an amber gem was one warm blob; the dark socket makes the gem the brightest thing on the boulder).

**Moving parts (five objects and the blink).** `clawR` and `clawL` (the boulder, its top step, thumb, nip, bezel and gem, turning on the shoulder: they lift and clack), `legR` and `legL` (the front legs scuttle), `antenna` (with its pebble, it sways); the face plate blinks and glints. Rare pass w1: `geode` (the three lit amber crystals in the open geode on the carapace: they throb and pop) makes six objects and the blink.

**Alien anatomy.** Claws of rock it did not grow, six jointed legs splayed like a crab's, and a single antenna with a pebble on it.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the cairn glyph and the gem sockets, and the cobbles of the stone motif on the boulders.

## Character bar (B54)

BAR-W1, 2026-10-26, [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10, [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`rocklobber()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A champion crab of the stone shore: a trophy-holder. Kept: name, anatomy (six jointed legs, boulder claws with amber gems, one pebble antenna), the geode on its back, height 3.125.
- **Gains (visible parts).** (1) Six satellites on a wide low ring clear of the claws, all in one lit amber and gold: three open geodes (dark stone frame, three amber crystals, the same from both sides) and three gold cairns with a lit pebble, each three quarters of a stud and more. (2) A gold championship belt a quarter stud tall round the shell's waist with a lit buckle on its back. (3) Verdant kit, four pieces: stone-grey moss pads with a lit tuft on the carapace's back corners, a dark vine up the shell's right side. (4) A posed stance.
- **Stance (rest groups `clawR`, `clawL`).** The right boulder hoisted high and out, the left swung low, a see-saw across the shell: the outline is a stepped diagonal, not a box with two ears.
- **Face intent.** Its own `crescent` face kept: a cheeky, proud crab; gold-banded eyes with an amber crescent that match its gems, a cat smile and blush cheeks. Friendly and a little smug, never fierce; the face is the brightest-contrast spot of the red shell and nothing crosses it (the belt skips the front).
- **Three values (coordinator rule, section 10 rule 8).** Body rust red; kit and trim in one step lighter (gold, stone grey) or darker (the dark second); the satellites one lit colour (amber and gold) that is not the body's. No backdrop (a Rare has none).
- **Must-nots.** No fierce brow or teeth; no loose grey boxes in the ring (the first ring was grey stone on grey and read as noise: cut); nothing over the face; no piece under a quarter stud added for its own sake; height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # six jointed crab legs (Polish w1: the posts read as table legs): a thigh rising 20 degrees out from under the shell's edge to a knee
  # past its side, and a thin shin dropping from the knee to a point on the grass, so each leg is a bent V splayed outward
  - {name: Leg, slot: BodyDark, size: [0.125, 0.625, 0.25], at: [1.3125, 0.3125, -0.625], mirror: x, moves: leg, pivot: [1, 0.5, -0.625]}
  - {name: Knee, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [1.125, 0.5625, -0.625], rot: [0, 0, 20], mirror: x, moves: leg, pivot: [1, 0.5, -0.625]}
  - {name: MidLeg, slot: BodyDark, size: [0.125, 0.625, 0.25], at: [1.3125, 0.3125, 0], mirror: x}
  - {name: MidKnee, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [1.125, 0.5625, 0], rot: [0, 0, 20], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.125, 0.625, 0.25], at: [1.3125, 0.3125, 0.625], mirror: x}
  - {name: HindKnee, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [1.125, 0.5625, 0.625], rot: [0, 0, 20], mirror: x}
  # the shell: a wide low block with the face plate, a dark carapace rim proud over it, a rust dome step on top
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true}
  - {name: Carapace, slot: BodyDark, size: [2.25, 0.25, 2], at: [0, 1.875, 0]}
  - {name: Dome, slot: Body, size: [1.5, 0.125, 1.25], at: [0, 2.0625, 0.125]}
  # the stamped element glyph: a gold cairn of three stepped cells on the dome, where the game camera sees it
  - {name: Glyph, slot: Trim, size: [0.75, 0.125, 0.25], at: [-0.25, 2.1875, 0.5], material: metal}
  - {name: Glyph2, slot: Trim, size: [0.5, 0.125, 0.25], at: [-0.25, 2.1875, 0.25], material: metal}
  - {name: Glyph3, slot: Trim, size: [0.25, 0.125, 0.25], at: [-0.25, 2.1875, 0], material: metal}
  # the hero: two short arms, a boulder in two steps on each with a stone thumb over it, a stone nip under it and an amber gem in a dark socket (the pair that clacks)
  - {name: Arm, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.25, 1.25, -0.75], pose: clawR}
  - {name: ArmL, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [-1.25, 1.25, -0.75], pose: clawL}
  - {name: Claw, slot: Accessory, size: [1.25, 1, 1.25], at: [1.875, 1.5, -1], moves: claw, pivot: [1.25, 1.25, -0.75], material: stone, pose: clawR}
  - {name: ClawL, slot: Accessory, size: [1.25, 1, 1.25], at: [-1.875, 1.5, -1], moves: claw, pivot: [-1.25, 1.25, -0.75], material: stone, pose: clawL}
  - {name: ClawTop, slot: Accessory, size: [0.875, 0.25, 0.875], at: [1.9375, 2.125, -0.9375], moves: claw, pivot: [1.25, 1.25, -0.75], material: stone, pose: clawR}
  - {name: ClawTopL, slot: Accessory, size: [0.875, 0.25, 0.875], at: [-1.9375, 2.125, -0.9375], moves: claw, pivot: [-1.25, 1.25, -0.75], material: stone, pose: clawL}
  - {name: Thumb, slot: Accessory, size: [0.5, 0.375, 0.625], at: [1.875, 2.4375, -1.3125], moves: claw, pivot: [1.25, 1.25, -0.75], material: stone, pose: clawR}
  - {name: ThumbL, slot: Accessory, size: [0.5, 0.375, 0.625], at: [-1.875, 2.4375, -1.3125], moves: claw, pivot: [-1.25, 1.25, -0.75], material: stone, pose: clawL}
  - {name: Nip, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1.875, 1.125, -1.75], moves: claw, pivot: [1.25, 1.25, -0.75], material: stone, pose: clawR}
  - {name: NipL, slot: Accessory, size: [0.5, 0.25, 0.25], at: [-1.875, 1.125, -1.75], moves: claw, pivot: [-1.25, 1.25, -0.75], material: stone, pose: clawL}
  - {name: Bezel, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [1.875, 1.625, -1.6875], moves: claw, pivot: [1.25, 1.25, -0.75], pose: clawR}
  - {name: BezelL, slot: BodyDark, size: [0.5, 0.5, 0.125], at: [-1.875, 1.625, -1.6875], moves: claw, pivot: [-1.25, 1.25, -0.75], pose: clawL}
  - {name: Gem, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.875, 1.625, -1.8125], moves: claw, pivot: [1.25, 1.25, -0.75], pose: clawR}
  - {name: GemL, slot: Glow, size: [0.25, 0.25, 0.125], at: [-1.875, 1.625, -1.8125], moves: claw, pivot: [-1.25, 1.25, -0.75], pose: clawL}
  # one antenna with a stepped pebble on its tip (it sways)
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.625, 0.125], at: [0.4375, 2.4375, 0.1875], moves: antenna, pivot: [0.4375, 2.125, 0.1875]}
  - {name: AntennaPebble, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.4375, 2.875, 0.1875], moves: antenna, pivot: [0.4375, 2.125, 0.1875], material: stone}
  - {name: PebbleCap, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.375, 3.0625, 0.25], moves: antenna, pivot: [0.4375, 2.125, 0.1875], material: stone}
  # Rare pass w1, the signature piece: a cracked-open geode on the carapace's front left, where the three-quarter camera sees it, a stone cup lined in gold with three lit amber crystals
  # growing out of it (the crystals throb and pop on the flourish, `geode`)
  - {name: GeodeBase, slot: Accessory, size: [0.75, 0.125, 0.75], at: [-0.375, 2.0625, -0.5], material: stone}
  - {name: GeodeWall, slot: Accessory, size: [0.75, 0.25, 0.125], at: [-0.375, 2.25, -0.8125], material: stone}
  - {name: GeodeWall2, slot: Accessory, size: [0.75, 0.375, 0.125], at: [-0.375, 2.3125, -0.1875], material: stone}
  - {name: GeodeSide, slot: Accessory, size: [0.125, 0.375, 0.5], at: [-0.6875, 2.3125, -0.5], material: stone}
  - {name: GeodeSide2, slot: Accessory, size: [0.125, 0.125, 0.5], at: [-0.0625, 2.1875, -0.5], material: stone}
  - {name: GeodeLining, slot: Trim, size: [0.5, 0.125, 0.5], at: [-0.375, 2.1875, -0.5], material: metal}
  - {name: Crystal, slot: Glow, size: [0.25, 0.875, 0.25], at: [-0.375, 2.6875, -0.5], shape: cone6, moves: geode, pivot: [-0.375, 2.25, -0.5], material: crystal}
  - {name: Crystal2, slot: Glow, size: [0.125, 0.5, 0.125], at: [-0.1875, 2.5, -0.6875], moves: geode, pivot: [-0.375, 2.25, -0.5], material: crystal}
  - {name: Crystal3, slot: Glow, size: [0.125, 0.375, 0.125], at: [-0.5625, 2.4375, -0.3125], moves: geode, pivot: [-0.375, 2.25, -0.5], material: crystal}
  # Rare pass w1: a lit amber crack across the top of each boulder, the same light as the geode
  - {name: Crack, slot: Glow, size: [0.375, 0.125, 0.125], at: [1.8125, 2.3125, -0.8125], moves: claw, pivot: [1.25, 1.25, -0.75], pose: clawR}
  - {name: CrackL, slot: Glow, size: [0.375, 0.125, 0.125], at: [-1.8125, 2.3125, -0.8125], moves: claw, pivot: [-1.25, 1.25, -0.75], pose: clawL}
  - {name: Crack2, slot: Glow, size: [0.125, 0.125, 0.25], at: [2.0625, 2.3125, -0.625], moves: claw, pivot: [1.25, 1.25, -0.75], pose: clawR}
  - {name: Crack2L, slot: Glow, size: [0.125, 0.125, 0.25], at: [-2.0625, 2.3125, -0.625], moves: claw, pivot: [-1.25, 1.25, -0.75], pose: clawL}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: stone-grey moss pads with a lit tuft on the carapace's back corners
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.75, 2.0625, 0.625], mirror: x, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [0.8125, 2.1875, 0.625], mirror: x, material: moss}
  - {name: Mossc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 2.3125, 0.5625], mirror: x, material: moss}
  # a dark vine winding up the shell's sides and back in three strips (the face stays clear)
  - {name: Vine0, slot: BodyDark, size: [0.125, 0.25, 2], at: [1.0625, 0.875, 0], material: moss}
  - {name: Vine1, slot: BodyDark, size: [2.25, 0.25, 0.125], at: [0, 1.125, 0.9375], material: moss}
  - {name: Vine2, slot: BodyDark, size: [0.125, 0.25, 2], at: [-1.0625, 1.375, 0], material: moss}
  # the champion's belt: a gold band a quarter stud tall round the shell's waist (the face stays clear) with a lit amber buckle on its back
  - {name: BeltR, slot: Trim, size: [0.125, 0.25, 1.75], at: [1.0625, 0.625, 0], material: metal}
  - {name: BeltL, slot: Trim, size: [0.125, 0.25, 1.75], at: [-1.0625, 0.625, 0], material: metal}
  - {name: BeltB, slot: Trim, size: [2.25, 0.25, 0.125], at: [0, 0.625, 0.9375], material: metal}
  - {name: BeltBuckle, slot: Glow, size: [0.25, 0.25, 0.125], at: [0, 0.625, 1.0625], material: crystal}
  # the satellite set (`trophies`, one wide ring clear of the claws, the front low): three open geodes and three cairns, three quarters of a stud and more
  - {name: Sat0a, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [1.5, 0.5625, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat0b, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.1875, 0.875, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat0c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.8125, 0.875, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat0d, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [1.5, 1.1875, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat0e, slot: BodyDark, size: [0.5, 0.5, 0.25], at: [1.5, 0.875, -2.5], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat0f, slot: Glow, size: [0.25, 0.5, 0.125], at: [1.5, 0.875, -2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat0g, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.3125, 0.75, -2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat0h, slot: Glow, size: [0.125, 0.375, 0.125], at: [1.6875, 0.8125, -2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat0i, slot: Glow, size: [0.25, 0.5, 0.125], at: [1.5, 0.875, -2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat0j, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.3125, 0.75, -2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat0k, slot: Glow, size: [0.125, 0.375, 0.125], at: [1.6875, 0.8125, -2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat1a, slot: Trim, size: [0.75, 0.25, 0.25], at: [2.875, 1.625, 0], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat1b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [2.875, 1.8125, 0], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat1c, slot: Trim, size: [0.5, 0.25, 0.25], at: [2.875, 2, 0], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat1d, slot: Trim, size: [0.25, 0.125, 0.25], at: [2.875, 2.1875, 0], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat1e, slot: Glow, size: [0.25, 0.125, 0.25], at: [2.875, 2.3125, 0], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2a, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [1.5, 2.3125, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat2b, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.8125, 2.625, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat2c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.1875, 2.625, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat2d, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [1.5, 2.9375, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat2e, slot: BodyDark, size: [0.5, 0.5, 0.25], at: [1.5, 2.625, 2.5], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat2f, slot: Glow, size: [0.25, 0.5, 0.125], at: [1.5, 2.625, 2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2g, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.6875, 2.5, 2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2h, slot: Glow, size: [0.125, 0.375, 0.125], at: [1.3125, 2.5625, 2.6875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2i, slot: Glow, size: [0.25, 0.5, 0.125], at: [1.5, 2.625, 2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2j, slot: Glow, size: [0.125, 0.25, 0.125], at: [1.6875, 2.5, 2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat2k, slot: Glow, size: [0.125, 0.375, 0.125], at: [1.3125, 2.5625, 2.3125], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat3a, slot: Trim, size: [0.75, 0.25, 0.25], at: [-1.5, 2.25, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat3b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-1.5, 2.4375, 2.5], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat3c, slot: Trim, size: [0.5, 0.25, 0.25], at: [-1.5, 2.625, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat3d, slot: Trim, size: [0.25, 0.125, 0.25], at: [-1.5, 2.8125, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat3e, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.5, 2.9375, 2.5], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4a, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [-2.875, 1.1875, 0], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat4b, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-3.1875, 1.5, 0], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat4c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-2.5625, 1.5, 0], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat4d, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [-2.875, 1.8125, 0], moves: trophies, pivot: [0, 1.7, 0], material: stone}
  - {name: Sat4e, slot: BodyDark, size: [0.5, 0.5, 0.25], at: [-2.875, 1.5, 0], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat4f, slot: Glow, size: [0.25, 0.5, 0.125], at: [-2.875, 1.5, -0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4g, slot: Glow, size: [0.125, 0.25, 0.125], at: [-3.0625, 1.375, -0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4h, slot: Glow, size: [0.125, 0.375, 0.125], at: [-2.6875, 1.4375, -0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4i, slot: Glow, size: [0.25, 0.5, 0.125], at: [-2.875, 1.5, 0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4j, slot: Glow, size: [0.125, 0.25, 0.125], at: [-3.0625, 1.375, 0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat4k, slot: Glow, size: [0.125, 0.375, 0.125], at: [-2.6875, 1.4375, 0.1875], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  - {name: Sat5a, slot: Trim, size: [0.75, 0.25, 0.25], at: [-1.5, 0.5, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat5b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-1.5, 0.6875, -2.5], moves: trophies, pivot: [0, 1.7, 0]}
  - {name: Sat5c, slot: Trim, size: [0.5, 0.25, 0.25], at: [-1.5, 0.875, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat5d, slot: Trim, size: [0.25, 0.125, 0.25], at: [-1.5, 1.0625, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: metal}
  - {name: Sat5e, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.5, 1.1875, -2.5], moves: trophies, pivot: [0, 1.7, 0], material: crystal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `crescent`, a Rare design, an ink drop over a band of gold iris and a lit amber crescent that matches the gems in its claws, at 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, five frames: open, half, closed, two glints). A cat mouth and blush cheeks.

```yaml
eyes:
  key: crescent
  colours: {iris: trim, glint: glow}
  mouth: cat
  cheeks: blush
  plate: [1.75, 1]
  at: [0, 1.0625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the boulders lift a little and clack in bursts, the front legs scuttle, the antenna sways, the shell rocks side to side, the face blinks and glints. Six moving things (five objects and the blink; a Rare needs four). The flourish, every 9 s: a hop with both boulders raised overhead, then two clacks and the antenna whipping.

```yaml
rig:
  rest:
    clawR: {rot: [0, 0, 30], pivot: [1.25, 1.25, -0.75], move: [0.3, 0.1, 0]}
    clawL: {rot: [0, 0, 15], pivot: [-1.25, 1.25, -0.75], move: [-0.1, -0.15, 0]}
  clips:
    claw: [{kind: flap, amp: 8, period: 2.6, axis: z}, {kind: wag, amp: 10, period: 5, axis: y, phase: 0.2}]
    leg: [{kind: sway, amp: 10, period: 0.9, axis: x}]
    antenna: [{kind: sway, amp: 14, period: 1.8, axis: x}, {kind: sway, amp: 8, period: 2.7, axis: z, phase: 0.3}]
    geode: [{kind: pulse, amp: 0.08, period: 2.2}]
    root: [{kind: sway, amp: 3, period: 2.8, axis: z}]
    trophies: [{kind: spin, amp: 360, period: 20, axis: y}, {kind: bob, amp: 0.05, period: 3.2}]
    face: [{kind: blink, period: 4.8}]
  flourish:
    every: 9
    length: 2.4
    moves:
      - {part: claw, kind: flare, amp: 35, axis: z, at: 0, for: 1.2}
      - {part: root, kind: hop, amp: 0.35, at: 0.2, for: 0.7}
      - {part: geode, kind: pop, amp: 0.3, at: 0.3, for: 0.6}
      - {part: root, kind: turn, amp: 360, axis: y, at: 0.4, for: 1.4}
      - {part: claw, kind: swish, amp: 18, axis: y, at: 1.1, for: 1}
      - {part: antenna, kind: swish, amp: 25, axis: x, at: 0.9, for: 1.2}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Geode | `Crystal` (geode) | -0.07, 0.86, -0.02 | a few amber motes rising, a sparkle on the flourish | Top |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Rocklobber_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Rocklobber_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Rocklobber_idle.png]]

The concept sheet, drawn from the parts table above: [[Rocklobber_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud). Materials: stone on the boulders, the thumbs, the nips and the pebble (cobbles and cracks), metal on the gold glyph and studs, skin elsewhere (the dark gem sockets too); the gems are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the boulder claws read at once and the amber gems carry the Rare's light, but the gold cairn glyph on the flanks sat behind the claws where no camera saw it, and a bevelled claw could not move. Round 2: the claws plain stone boxes on the `jaw` pair, the glyph moved to the carapace. Wanted for: two boulders on a crab the size of a shoe that clack. Still cheap: the shell between the claws is small and flat; the legs are thin posts. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, one round. Kept at 3.125 studs (a squat crab, in the band already) and rebuilt to 35 blocks with smaller detail: each boulder in two steps with a thumb over it and a nip under it (a pincer at last), the gem in a gold bezel, knees on the front and hind legs, a rust dome step under the glyph, stone nubs on the back corners, a stepped pebble on the antenna. Its own `crescent` eyes in gold over an amber crescent that matches the gems, a cat mouth, blush cheeks; five moving objects and the blink (the boulders lift and clack, the front legs scuttle, the antenna sways); a flourish every 9 s (a hop with both boulders raised overhead, two clacks). Overlap 0.996 to 1, 502 triangles. Wanted for: two boulders held up like trophies, and the flourish reads across the meadow. Still weak: the gold bezel and the lit gem are close in value, so the frame reads only up close; the legs are still posts from the front. Status review.
- 2026-10-21, Polish w1, one round. Two weak spots. The gem and its gold bezel were close in value (amber in gold, one warm blob): the bezel is now a dark iron socket (the second colour), so the amber gem is the brightest thing on each boulder. The legs read as posts: each is now a bent crab leg, a thigh rising 20 degrees out from under the shell's edge to a knee past its side and a thin eighth-stud shin dropping to the grass, all six splayed; the two stone nubs on the shell's back corners went to keep the Rare cap (35 blocks of 36). Overlap 0.996 to 0.999. Honest read: the gems now glow out of the boulders and the legs read as a crab's; the shins are thin enough to read as spindly at distance, which suits a crab. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: an open amber geode on the carapace's front left (a stone cup lined in gold, three lit glass crystals that throb and pop on the flourish), and a lit amber crack across each boulder; the glow is a deeper amber `#FF8C1A` (the pale `#FFB347` rendered yellow-white). The flourish gained a full turn. 48 blocks (the Rare band now 18 to 56), seven moving things. Round 1 put the geode at the carapace's back right, where the claw hid it from the three-quarter camera. Honest read: a crab with a glowing geode on its back reads at once and the lit cracks tie the boulders to it; the crystals are still small at the game camera's distance. Status review.
