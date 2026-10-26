---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Radish
name: Raddis
world: 1
tier: Cosmic
status: review
element: Sun
height: 3.5
blocks: 184
tris: 2402
bevel_width: 0.03125
bevel_segments: 2
palette: ["#D7265C", "#FFF0D9", "#2CC5B2", "#FFB21E", "#FFC21A", "#2A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#FFC21A", "#FF8A1F", "#FFE9A8"]
hero: Sun0
vfx: "to the sky: the rays, the orb, the motes, the forehead gem, the pendant and the wing tips glow and step through gold, amber and white every 2 s; the halo turns once in 12 s; eight satellites orbit the root; a ground ring of light; a sunlight trail while it hovers; the flourish (every 12 s) is a hop and a full turn with the wings flared, the disk popping and the orb leaping, the moment Effects.luau can hang a flare and a column of light on (World.RigAnimator.OnFlourish)"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Radish_sheet.svg]]"
render: "[[Radish_tq_cells.jpg]]"
glb: ""
overlap: [0.991, 0.998, 0.994, 0.99]
vfx_render: "[[Radish_vfx_cells.jpg]]"
cells_render: "[[Radish_tq_cells.jpg]]"
idle_render: "[[Radish_idle.png]]"
bar_world: Verdant
bar_kit: 8
bar_pieces: [bark_band, blossom_bud, moss_cells, sap_drop, vine_wrap]
bar_stance: "a hover swoop: the root sweeps out to the right and hooks up, both wings spread 22 degrees up behind a sun disc, a flame crown over the brow"
bar_satellites: 6
bar_orbit: sunstone
bar_backdrop: halo
bar_aura: aura
---
# Radish (Raddis), Cosmic, World 1 Verdant

A small radish that hovers, 3.44 studs tall (B45: every alien stands 2 to 3.5 studs; it was 13.96): a deep radish-red head 2 studs wide with the face plate low on it, a crown step over it and a bulb under it with a gold and turquoise collar, then a root that swoops to the right in six steps from red to cream to a curled tip (the bulb's girdle and the cream lenticel dashes were under a quarter stud and are cut). A centre leaf, a pair of fronds and four drooping blades fan out of the back of the crown. The face wears the pharaoh's brow in eighth-stud cells: a band of gold and turquoise over the eyes with a lit gem in a gold frame, striped lappets down both sides and a gold stud on the crown's front edge flanked by two golden buds. A broad collar of gold and turquoise cells stands out under the chin, narrowing to a lit pendant that swings. Behind it turns a ring of gold cells, wide enough to frame the head from the front, with eight lit rays and a pair of feathered wings, the winged sun of Ra; a teardrop flame of three cells floats over its crown, and eight satellites (pixel suns, leaf blades and sap drops) turn round its root above a ground aura of gold dashes. Concept row: "radiant radish, sun disk; echo of Ra". Element: Sun (`Effects.luau`; [[Roster-Redesign]] section 2). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** Not its size any more: it stands a little under the avatar's shoulder like everyone else. What sets it apart from Moop is everything else: 180 blocks to Moop's 12, most of them eighth-stud cells of gold, turquoise and light (Moop has none); its own solar eyes, a sun in each eye whose pinwheel rays swirl round a white-hot core over a lit turquoise rim, with star cheeks (Moop has ink beans); twelve moving things to Moop's three (the turning disk, two beating wings, the bobbing flame, the orbit of satellites, the breathing aura, a nodding leaf, two swaying fronds, the pulsing gem, the swinging pendant, and the blink); and every 12 seconds a flourish: a hop and a full turn with the wings flared, the disk popping and the orb leaping. Rarer means more exclusive and cuter, never fiercer: the face is a soft smile and starry cheeks under sun eyes.

**Hero block.** The sun disk (`RingT` and the ring cells and rays round it): one moving part, the `halo`, that the game turns once in 12 s, unique in Verdant.

**Moving parts (eleven objects and the blink).** `halo` (the ring and its rays), `wingR` and `wingL` (they beat and sway), `orb` (the teardrop flame: it bobs and spins), `leaf` (it nods), `frondR` and `frondL` (they sway), `gem` (it pulses), `pendant` (it swings); the face plate blinks, glints and swirls. Rare pass w1: `sunstone` (the orbit, now eight satellites on a ring tilted a quarter stud: it circles the other way to the disk, wobbles and rises with the flourish). The bar pilot: `aura` (twelve gold dashes on the ground that breathe) replaces the two motes, so the count stays eleven objects and the blink.

**Alien anatomy.** A root that hovers instead of standing, and a sun that turns behind it on nothing.

**World motif (Verdant).** The moss cell, here as the eighth-stud cells of the brow, the lappets, the collar and the ring.

## The character bar (B54, pilot 2026-10-26; second pass, bolder)

[[Blocky-Style]] section 10 and "Pilot bar notes (v2)"; the plan is `tools/blocky/pilots.py` (`radish()`), the pieces `tools/blocky/kits.py`. A Cosmic, so everything the bar has, at the size a child sees at 16 studs:

- **Backdrop (`halo`).** A full sun disc 3 studs across (gold with a turquoise rim, stepped in quarter-stud cells) and seven stepped rays round it, a quarter stud deep, behind the head; it turns once in 12 s. It replaces the thin ring and the eight-cell corona.
- **Shaped energy (`flame`).** A flame crown of three layered teardrops on the crown: amber outer (0.75 wide at the belly, five eighths tall), yellow glow, white-hot cream inside, each a quarter or an eighth proud of the one behind it. It squashes and sways.
- **Satellites (6, `sunstone`).** Three pixel suns (an amber plus, four nubs, a lit heart, seven eighths of a stud across) and three broad leaves (seven eighths long) on a ring of radius 2.1 with its front low and its back high, every piece facing the viewer, so none is edge-on from the front or crosses the face.
- **Metal.** A brass collar round the bulb (1.75 x 0.25 x 1.75, an eighth proud, three turquoise studs on its front); the pendant under it is a lit quarter-stud block.
- **Kit (8 pieces).** Moss pads hanging over the head's top corners, golden buds beside the flame, a vine of three strips round the head's sides and back, sap drops half a stud long under the cheeks, the brass collar (`bark_band`).
- **Stance.** The root swoops out to the right in five steps, along the ground and up in a hook 1.9 studs off the middle; both wings spread: five feather rows and three lit tips a side, turned 22 degrees up about their roots in a mirrored rest pose (`rig.rest.wing`), behind the disc.
- **Aura.** Twelve gold runes three quarters of a stud long on a circle of radius 1.75.
- Blocks 181 to 184, triangles 2182 to 2266 (Blender, v1 2154), moving things 11 (v1 12: the centre leaf went, the orb became the flame), height 3.5 (v1 3.44).

## Parts

```yaml
parts:
  # the radish: a bevelled head with the face plate, a bulb under it, a crown step over it, and a root that SWOOPS (PILOT-2): five steps down
  # and out to the right, along the ground and up in a hook, so the hovering radish leans into a curl instead of hanging straight
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 2, 0], bevel: true}
  - {name: Bulb, slot: Body, size: [1.5, 0.5, 1.5], at: [0, 1, 0], bevel: true, material: nebula}
  - {name: Crown, slot: Body, size: [1.5, 0.125, 1.25], at: [0, 2.8125, 0.0625]}
  - {name: Root, slot: Body, size: [1.125, 0.125, 1.125], at: [0, 0.6875, 0], material: nebula}
  - {name: Root2, slot: BodyDark, size: [0.875, 0.125, 0.875], at: [0.125, 0.5625, 0]}
  - {name: Root3, slot: BodyDark, size: [0.625, 0.25, 0.625], at: [0.4375, 0.4375, 0], material: wood}
  - {name: RootTip, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.8125, 0.25, 0], material: wood}
  - {name: RootTail, slot: BodyDark, size: [0.5, 0.1875, 0.25], at: [1.25, 0.09375, 0]}
  - {name: RootCurl, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [1.6875, 0.0625, 0]}
  - {name: RootHook, slot: BodyDark, size: [0.25, 0.4375, 0.25], at: [1.8125, 0.34375, 0]}
  # the pharaoh's brow: a band of gold and turquoise cells over the face plate, a lit gem in a gold frame, striped lappets down the sides
  - {name: Band, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0, 2.5625, -0.90625], material: metal}
  - {name: Band1, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.25, 2.5625, -0.90625], mirror: x}
  - {name: Band2, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0.5, 2.5625, -0.90625], mirror: x, material: metal}
  - {name: Band3, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.75, 2.5625, -0.90625], mirror: x}
  - {name: GemFrame, slot: Trim, size: [0.375, 0.125, 0.0625], at: [0, 2.6875, -0.90625], material: metal}
  - {name: Gem, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0, 2.6875, -0.96875], moves: gem, pivot: [0, 2.6875, -0.96875]}
  - {name: Lappet, slot: Trim, size: [0.125, 0.25, 0.0625], at: [0.9375, 2.375, -0.90625], mirror: x}
  - {name: Lappet2, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.9375, 2.125, -0.90625], mirror: x}
  - {name: Lappet3, slot: Trim, size: [0.125, 0.25, 0.0625], at: [0.9375, 1.875, -0.90625], mirror: x}
  - {name: Lappet4, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.9375, 1.625, -0.90625], mirror: x}
  # the lit pendant under the brass collar (the collar itself is in the generated region): it swings
  - {name: Pendant, slot: Glow, size: [0.25, 0.3125, 0.125], at: [0, 0.78125, -0.9375], moves: pendant, pivot: [0, 0.9375, -0.9375]}
  # the radish greens behind the flame: a pair of fronds that sway, drooping outer leaves and back leaves (all broad turquoise blades)
  - {name: FrondStem, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.28125, 2.9375, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: Frond, slot: Accessory, size: [0.3125, 0.25, 0.125], at: [0.375, 3.125, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: FrondTip, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [0.4375, 3.3125, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: OuterLeaf, slot: Accessory, size: [0.375, 0.1875, 0.125], at: [0.65625, 2.90625, 0.1875], rot: [0, 0, -65], mirror: x}
  - {name: OuterLeaf2, slot: Accessory, size: [0.25, 0.1875, 0.125], at: [0.8125, 3.0625, 0.1875], rot: [0, 0, -65], mirror: x}
  - {name: BackLeaf, slot: Accessory, size: [0.3125, 0.25, 0.125], at: [0.21875, 3, 0.5625], rot: [15, 0, -15], mirror: x}
  - {name: BackLeaf2, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [0.28125, 3.1875, 0.59375], rot: [15, 0, -15], mirror: x}
  # pilot bar: begin (tools/blocky/pilots.py writes this region: the Verdant kit, the satellite set and the aura)
  # the Verdant kit: turquoise moss pads on the head's top corners, hanging over the edge
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [1, 2.8125, 0], mirror: x, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [1.0625, 2.9375, 0], mirror: x, material: moss}
  - {name: Mossc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.9375, 3.0625, -0.0625], mirror: x, material: moss}
  # golden blossom buds flanking the flame on the crown
  - {name: Buda, slot: Accessory, size: [0.125, 0.25, 0.125], at: [0.625, 3, -0.5], mirror: x, material: wood}
  - {name: Budb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.625, 3.1875, -0.5], mirror: x}
  - {name: Budc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.625, 3.3125, -0.5], mirror: x}
  # a vine winding up the head's sides and back in three strips (the face and the disc stay clear)
  - {name: Vine0, slot: Accessory, size: [0.125, 0.25, 2], at: [1.0625, 1.625, 0], material: moss}
  - {name: Vine1, slot: Accessory, size: [2.25, 0.25, 0.125], at: [0, 1.875, 0.9375], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.125, 0.25, 2], at: [-1.0625, 2.125, 0], material: moss}
  # amber sap drops, half a stud long, hanging from under the cheeks
  - {name: Sapa, slot: Trim, size: [0.1875, 0.1875, 0.1875], at: [0.96875, 1.15625, -0.40625], mirror: x, material: metal}
  - {name: Sapb, slot: Trim, size: [0.375, 0.1875, 0.375], at: [0.875, 0.96875, -0.5], mirror: x, material: metal}
  - {name: Sapc, slot: Glow, size: [0.1875, 0.1875, 0.1875], at: [0.96875, 0.78125, -0.40625], mirror: x, material: crystal}
  # the brass collar: a quarter stud tall, an eighth proud, round the bulb under the chin, with three turquoise studs on its front
  - {name: BrassBand, slot: Trim, size: [1.75, 0.25, 1.75], at: [0, 1, 0], material: metal}
  - {name: CollarStud, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0, 1, -0.90625]}
  - {name: CollarStud2, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.5, 1, -0.90625], mirror: x}
  # the flame crown (shaped energy, `flame`): three layered teardrops on the crown, amber over yellow over white-hot, half a stud wide and five eighths tall
  - {name: FlameO0, slot: Trim, size: [0.75, 0.125, 0.25], at: [0, 2.9375, -0.3125], moves: flame, pivot: [0, 2.875, -0.4], material: ember}
  - {name: FlameO1, slot: Trim, size: [0.875, 0.125, 0.25], at: [0, 3.0625, -0.3125], moves: flame, pivot: [0, 2.875, -0.4], material: ember}
  - {name: FlameO2, slot: Trim, size: [0.625, 0.125, 0.25], at: [0, 3.1875, -0.3125], moves: flame, pivot: [0, 2.875, -0.4], material: ember}
  - {name: FlameO3, slot: Trim, size: [0.375, 0.125, 0.25], at: [0, 3.3125, -0.3125], moves: flame, pivot: [0, 2.875, -0.4], material: ember}
  - {name: FlameO4, slot: Trim, size: [0.125, 0.125, 0.25], at: [0, 3.4375, -0.3125], moves: flame, pivot: [0, 2.875, -0.4], material: ember}
  - {name: FlameM0, slot: Glow, size: [0.5, 0.125, 0.125], at: [0, 2.9375, -0.5], moves: flame, pivot: [0, 2.875, -0.4], material: crystal}
  - {name: FlameM1, slot: Glow, size: [0.625, 0.125, 0.125], at: [0, 3.0625, -0.5], moves: flame, pivot: [0, 2.875, -0.4], material: crystal}
  - {name: FlameM2, slot: Glow, size: [0.375, 0.125, 0.125], at: [0, 3.1875, -0.5], moves: flame, pivot: [0, 2.875, -0.4], material: crystal}
  - {name: FlameM3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 3.3125, -0.5], moves: flame, pivot: [0, 2.875, -0.4], material: crystal}
  - {name: FlameI0, slot: BodyDark, size: [0.25, 0.125, 0.0625], at: [0, 2.9375, -0.59375], moves: flame, pivot: [0, 2.875, -0.4]}
  - {name: FlameI1, slot: BodyDark, size: [0.25, 0.125, 0.0625], at: [0, 3.0625, -0.59375], moves: flame, pivot: [0, 2.875, -0.4]}
  - {name: FlameI2, slot: BodyDark, size: [0.125, 0.125, 0.0625], at: [0, 3.1875, -0.59375], moves: flame, pivot: [0, 2.875, -0.4]}
  # the backdrop (`halo`, it turns once in 12 s): a full sun disc 3 studs across, gold with a turquoise rim, seven stepped rays round it, a quarter of a stud deep, behind the body
  - {name: Sun0, slot: Accessory, size: [1, 0.25, 0.125], at: [0, 0.5, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun1, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-0.875, 0.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun2, slot: Trim, size: [1.5, 0.25, 0.125], at: [0, 0.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun3, slot: Accessory, size: [0.25, 0.25, 0.125], at: [0.875, 0.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun4, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.125, 1, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun5, slot: Trim, size: [2, 0.25, 0.125], at: [0, 1, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun6, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.125, 1, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun7, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 1.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun8, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.375, 1.5, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun9, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 1.5, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun10, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.375, 1.5, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun11, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.375, 1.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun12, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 1.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun13, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.375, 1.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun14, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.375, 2, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun15, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 2, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun16, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.375, 2, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun17, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.375, 2.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun18, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 2.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun19, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.375, 2.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun20, slot: Trim, size: [2.5, 0.25, 0.125], at: [0, 2.5, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun21, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-1.125, 2.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun22, slot: Trim, size: [2, 0.25, 0.125], at: [0, 2.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun23, slot: Accessory, size: [0.25, 0.25, 0.125], at: [1.125, 2.75, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun24, slot: Accessory, size: [0.25, 0.25, 0.125], at: [-0.875, 3, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun25, slot: Trim, size: [1.5, 0.25, 0.125], at: [0, 3, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: metal}
  - {name: Sun26, slot: Accessory, size: [0.25, 0.25, 0.125], at: [0.875, 3, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Sun27, slot: Accessory, size: [1, 0.25, 0.125], at: [0, 3.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: moss}
  - {name: Ray0, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.1875, 3.0625, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray1, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 3.1875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray2, slot: Glow, size: [0.25, 0.5, 0.125], at: [1.625, 1.875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray3, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.875, 1.875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray4, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.1875, 0.6875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray5, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 0.5625, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray6, slot: Glow, size: [0.5, 0.25, 0.125], at: [0, 0.25, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray7, slot: Glow, size: [0.25, 0.25, 0.125], at: [-1.1875, 0.6875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray8, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.3125, 0.5625, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray9, slot: Glow, size: [0.25, 0.5, 0.125], at: [-1.625, 1.875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray10, slot: Glow, size: [0.25, 0.25, 0.125], at: [-1.875, 1.875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray11, slot: Glow, size: [0.25, 0.25, 0.125], at: [-1.1875, 3.0625, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  - {name: Ray12, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.3125, 3.1875, 1.1875], moves: halo, pivot: [0, 1.875, 1.1875], material: crystal}
  # the wings, spread (`wing`, a rest pose of 22 degrees up about the root at the disc's rim: `rig.rest.wing`): five feather rows and three lit tips a side, behind the disc
  - {name: WingA, slot: Trim, size: [1.25, 0.1875, 0.125], at: [2.0625, 2.28125, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing, material: metal}
  - {name: WingB, slot: Accessory, size: [1.125, 0.1875, 0.125], at: [2, 2.09375, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing}
  - {name: WingC, slot: Body, size: [0.875, 0.1875, 0.125], at: [1.875, 1.90625, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing}
  - {name: WingD, slot: Accessory, size: [0.625, 0.1875, 0.125], at: [1.75, 1.71875, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing}
  - {name: WingE, slot: Trim, size: [0.375, 0.1875, 0.125], at: [1.625, 1.53125, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing, material: metal}
  - {name: WingTip0, slot: Glow, size: [0.1875, 0.1875, 0.125], at: [2.78125, 2.28125, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing, material: glow}
  - {name: WingTip1, slot: Glow, size: [0.1875, 0.1875, 0.125], at: [2.65625, 2.09375, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing, material: glow}
  - {name: WingTip2, slot: Glow, size: [0.1875, 0.1875, 0.125], at: [2.40625, 1.90625, 1.375], mirror: x, moves: wing, pivot: [1.4375, 2, 1.375], pose: wing, material: glow}
  # the satellite set (`sunstone`, one wide ring, the front low): three pixel suns and three broad leaves, three quarters of a stud each, facing the viewer
  - {name: Sat0a, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.0625, 1.3125, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0b, slot: Trim, size: [0.25, 0.875, 0.125], at: [1.0625, 1.3125, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0c, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [0.78125, 1.03125, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0d, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [0.78125, 1.59375, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0e, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [1.34375, 1.03125, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0f, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [1.34375, 1.59375, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat0g, slot: Glow, size: [0.375, 0.375, 0.125], at: [1.0625, 1.3125, -2], moves: sunstone, pivot: [0, 1.6, 0], material: crystal}
  - {name: Sat1a, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [2.125, 1.5, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: wood}
  - {name: Sat1b, slot: Accessory, size: [0.375, 0.25, 0.125], at: [2.125, 1.6875, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat1c, slot: Accessory, size: [0.625, 0.25, 0.125], at: [2.125, 1.9375, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat1d, slot: Accessory, size: [0.375, 0.1875, 0.125], at: [2.125, 2.15625, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat1e, slot: Accessory, size: [0.125, 0.0625, 0.125], at: [2.125, 2.28125, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat2a, slot: Trim, size: [0.875, 0.25, 0.125], at: [1.0625, 2.0625, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2b, slot: Trim, size: [0.25, 0.875, 0.125], at: [1.0625, 2.0625, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2c, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [1.34375, 1.78125, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2d, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [1.34375, 2.34375, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2e, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [0.78125, 1.78125, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2f, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [0.78125, 2.34375, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat2g, slot: Glow, size: [0.375, 0.375, 0.125], at: [1.0625, 2.0625, 2], moves: sunstone, pivot: [0, 1.6, 0], material: crystal}
  - {name: Sat3a, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [-1.0625, 1.5625, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: wood}
  - {name: Sat3b, slot: Accessory, size: [0.375, 0.25, 0.125], at: [-1.0625, 1.75, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat3c, slot: Accessory, size: [0.625, 0.25, 0.125], at: [-1.0625, 2, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat3d, slot: Accessory, size: [0.375, 0.1875, 0.125], at: [-1.0625, 2.21875, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat3e, slot: Accessory, size: [0.125, 0.0625, 0.125], at: [-1.0625, 2.34375, 1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat4a, slot: Trim, size: [0.875, 0.25, 0.125], at: [-2.125, 1.375, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4b, slot: Trim, size: [0.25, 0.875, 0.125], at: [-2.125, 1.375, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4c, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [-2.40625, 1.09375, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4d, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [-2.40625, 1.65625, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4e, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [-1.84375, 1.09375, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4f, slot: Trim, size: [0.1875, 0.1875, 0.125], at: [-1.84375, 1.65625, -0.0625], moves: sunstone, pivot: [0, 1.6, 0], material: metal}
  - {name: Sat4g, slot: Glow, size: [0.375, 0.375, 0.125], at: [-2.125, 1.375, -0.1875], moves: sunstone, pivot: [0, 1.6, 0], material: crystal}
  - {name: Sat5a, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [-1.0625, 0.8125, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: wood}
  - {name: Sat5b, slot: Accessory, size: [0.375, 0.25, 0.125], at: [-1.0625, 1, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat5c, slot: Accessory, size: [0.625, 0.25, 0.125], at: [-1.0625, 1.25, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat5d, slot: Accessory, size: [0.375, 0.1875, 0.125], at: [-1.0625, 1.46875, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  - {name: Sat5e, slot: Accessory, size: [0.125, 0.0625, 0.125], at: [-1.0625, 1.59375, -1.875], moves: sunstone, pivot: [0, 1.6, 0], material: moss}
  # the ground aura (`aura`, it breathes): twelve gold runes, three quarters of a stud long, in a circle round the root
  - {name: Aura0, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0, 0.03125, -1.75], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura1, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0.875, 0.03125, -1.5], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura2, slot: Glow, size: [0.25, 0.0625, 0.75], at: [1.5, 0.03125, -0.875], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura3, slot: Glow, size: [0.25, 0.0625, 0.75], at: [1.75, 0.03125, 0], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura4, slot: Glow, size: [0.25, 0.0625, 0.75], at: [1.5, 0.03125, 0.875], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura5, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0.875, 0.03125, 1.5], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura6, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0, 0.03125, 1.75], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura7, slot: Glow, size: [0.75, 0.0625, 0.25], at: [-0.875, 0.03125, 1.5], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura8, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-1.5, 0.03125, 0.875], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura9, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-1.75, 0.03125, 0], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura10, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-1.5, 0.03125, -0.875], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  - {name: Aura11, slot: Glow, size: [0.75, 0.0625, 0.25], at: [-0.875, 0.03125, -1.5], moves: aura, pivot: [0, 0.03125, 0], material: crystal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 32 columns across the 2-stud head, so the cell is 0.0625 studs (16 a stud) and the 1.5-stud front is 24 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 32
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `solar`, a Cosmic design, a sun in each eye whose pinwheel rays swirl round a white-hot core over a lit turquoise rim, at 32 pixels a stud on a 1.75 x 0.875 stud plate (56 x 28 pixels, 13 frames: open, half, closed, two glints, eight swirl frames). A small smile and star cheeks.

```yaml
eyes:
  key: solar
  colours: {deep: "#C2410C", mid: trim, bright: glow, rim: accent, sparkle: "#FFFFFF"}
  mouth: smile
  cheeks: stars
  plate: [1.75, 0.875]
  at: [0, 1.96875]
  spread: 0.4375
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them). A key names a moving object, or the base name of a mirrored pair (both twins, the left mirrored); `root` is the whole body about its feet, `face` the plate.

```yaml
rig:
  rest:
    wing: {rot: [0, 0, 22], pivot: [1.4375, 2.0, 1.375], mirror: true}
  clips:
    halo: [{kind: spin, amp: 360, period: 12, axis: z}]
    wing: [{kind: flap, amp: 14, period: 2.8, axis: z}, {kind: sway, amp: 6, period: 5.6, axis: y, phase: 0.25}]
    flame: [{kind: squash, amp: 0.1, period: 1.6, axis: y}, {kind: sway, amp: 5, period: 2.4, axis: z}]
    aura: [{kind: pulse, amp: 0.1, period: 3.2}]
    sunstone: [{kind: spin, amp: -360, period: 9, axis: y}, {kind: sway, amp: 7, period: 4.5, axis: x}, {kind: bob, amp: 0.06, period: 3, phase: 0.5}]
    frond: [{kind: sway, amp: 10, period: 2.6, axis: z, phase: 0.3}]
    gem: [{kind: pulse, amp: 0.2, period: 2}]
    pendant: [{kind: sway, amp: 12, period: 1.9, axis: x}]
    root: [{kind: bob, amp: 0.08, period: 3}, {kind: sway, amp: 2, period: 6, axis: z, phase: 0.2}]
    face: [{kind: blink, period: 4.6}]
  flourish:
    every: 14
    length: 4.4
    moves:
      - {part: root, kind: hop, amp: 0.4, at: 0, for: 0.9}
      - {part: sunstone, kind: hop, amp: 0.3, at: 0, for: 1.6}
      - {part: sunstone, kind: turn, amp: -720, axis: y, at: 0, for: 2.2}
      - {part: root, kind: turn, amp: 360, at: 0.15, for: 1.5}
      - {part: wing, kind: flare, amp: 25, at: 0.3, for: 1.6}
      - {part: halo, kind: pop, amp: 0.1, at: 1.4, for: 1}
      - {part: halo, kind: turn, amp: 180, axis: z, at: 1.4, for: 1.6}
      - {part: gem, kind: pop, amp: 0.4, at: 1.6, for: 0.6}
      - {part: aura, kind: pop, amp: 0.25, at: 0.2, for: 1.4}
      - {part: flame, kind: hop, amp: 0.25, at: 1.8, for: 1}
      - {part: frond, kind: swish, amp: 18, at: 2, for: 1.2}
      - {part: pendant, kind: swish, amp: 20, axis: x, at: 2.6, for: 1.4}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Sunstones | `Sunstone12` (sunstone) | 0.00, 0.22, -0.46 | a sun-mote trail round the ring, the pillar's foot on the flourish | Feet |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Radish.md --out <scratch> --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with cells (Blender, Cycles):

![[Radish_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Radish_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Radish_idle.png]]

The concept sheet, drawn from the parts table above: [[Radish_sheet.svg]] and [[Radish_sheet.png]]. The build's four orthographic views against the sheet's masks score the `overlap` in the frontmatter (the silhouette check). Before and after B45 and B46, beside Moop: `media/studio/2026-10-21/pilots_v1.jpg`.

## Reviews

- 2026-10-17, worker, three rounds. Round 1: it read as a red box with wings (a short root, leaves like little antlers, an opaque white light column). Round 2: a four-step root taper to a thin tail with root hairs, three tall leaf blades, the upper body raised half a stud (13.75 studs, head 40 percent). Round 3: the preview's turning disk lit, a corona light, a wider translucent column. Overlap 0.996 to 0.997, 1,424 triangles, four moving objects. Wanted for: 2.8 avatars tall and 16.5 studs across the wings, a turning winged sun, a mount. Still cheap: the head front is a big flat red plane above the face, the collar hides under the head's overhang from above, and the wing rows read as flags from the side. Next: a stepped brow band or headdress edge across the top of the face, feather tips stepped at the wing ends, and the face at 32 cells for close-ups. Status review.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the brow band, the gem and the striped lappets frame the face and break up the red plane; the collar stands out past the chin so it shows from above; the striped head sides (they read as lantern ribs) are gone. Round 2: the leaves read as celery sticks (a cream midrib split each one), and the box still read as a lantern; the root was shortened so the leaves could grow. Round 3: a 6-stud head between a crown step and a bulb, a five-step root from red to cream to a curled tip, seven broad leaves with the outer pair drooping; the preview drops a spark that sat on its cheek. Overlap 0.995 to 0.997, 1,892 triangles, 141 blocks, 13.96 studs. Wanted for: nearly three avatars of radish behind a turning winged sun, a mount. Still cheap: from the side the head is still a tall box; the cream dashes are faint; 16 face cells over 6 studs are big pixels in a close-up. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). At the face cell (0.375 studs) the 6-stud head is 16 cells across, chunky up close and one surface with the face; the root's grain reads as a radish's fibres. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, eyes and rigs worker, the B45 and B46 pilot, three rounds. Round 1: rebuilt from 13.96 studs to 3.44 by redesign, not by scale: a 2-stud head with a 32-column face (0.0625 body cells, 55 cells tall), the brow, lappets, collar and sun ring in eighth-stud cells, 132 blocks. Round 2: its own `solar` eyes on a 56 x 28 face plate (a sun in each eye whose rays swirl over 8 frames round a white-hot core, a lit turquoise rim, star cheeks), eleven moving objects and the blink, a flourish every 12 s (a hop and a full turn, wings flared, the disk popping, the orb leaping). Round 3: the VFX preview's light column scaled to the new height (1.6 studs wide read as a pillar block on a 3.4-stud alien). Overlap 0.991 to 0.993, 1,616 triangles. Wanted for: next to Moop it is plainly the rarer one at the same size, by its cells, its eyes, its light and its motion. Still cheap: the bulb under the face is a plain red block, and the sun ring hides behind the head from the front (it reads from the side and the back). Status review.
- 2026-10-21, Roster w1_high worker, the two weak spots the pilot left, one round. The bulb under the face was a plain red block: it now carries a girdle of gold and turquoise cells round its sides and back (the collar's pattern carried round, the collar still covers the front) and cream lenticel dashes under it. The sun ring hid behind the head from the front: regenerated at 1.31 studs outer radius (it was 1.06) round a centre an eighth lower, so its sides stand a quarter stud past the head and its top over the crown, with the eight rays outside it and the top ray still under 3.5 studs; its top bar keeps the name `RingT` (the hero), the halo pivot moved with it. Overlap 0.991 to 0.994, 155 blocks, 1,806 triangles; height 3.44 and the motion unchanged. Wanted for: from the front it is now a radish framed by a turning sun. Still weak: the ring overlaps the wing roots from the side; the lower half of the ring reads behind the bulb as a gold U. Status review.
- 2026-10-21, Polish w1, one round. From the side the sun ring overlapped the wing roots: the wings sat a sixteenth behind the ring's plane with their roots at x 1, inside the ring's rim, so from the side and the three-quarter view ring and wings were one tangle. The roots now start just outside the rim (x 1.3125, the rim is at 1.25) and the wings sit a quarter stud behind the ring's plane (z 1.28 against 1.0), each feather row an eighth shorter so the span grows only a little (to 2.44 from the centre). Same 155 blocks. Overlap 0.993 to 0.997. Honest read: from the side the ring and the wings are two clean layers, and from the front the wings spring from the disk's edge as the winged sun's do; the far wing still passes behind the head, as it should. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: a ring of orbiting sunstones round the root (eight lit suns strung with gold beads on a ring tilted 14 degrees; it turns the other way to the disk and rises with the flourish), a corona of eight lit glass cells between the disk's rays, a fifth feather row of lit glass under each wing, star-field `nebula` cells on the bulb and the root's top step; the glow is a deeper gold `#FFC21A` and the glow cycle gold, orange, pale gold (the pale `#FFE36B` rendered white). The flourish is longer (4.4 s every 14 s): the ring spins twice and rises, the disk turns half round and pops, the gem pops, the pendant swings. 181 blocks, thirteen moving things, 2,182 triangles. Honest read: the sun radish now has a solar system round its root and reads gold rather than white; the ring of suns is busy from the front and best in motion. Status review.
- 2026-10-26, character bar pilot worker, three rounds. Round 1: the girdle, the dashes, the motes, the orb and the old sunstone ring cut (the quarter-stud rule), the root and the wings posed, the kit, a satellite orbit and the aura written by `pilots.py`. Round 2: the buds went from red (read as horns) to amber on turquoise stalks, the vine moved from the bulb (hidden under the head) to the head's sides, the moss pads turned turquoise, the satellites grew to 0.4 to 0.5 studs, the root steps grew. Round 3: the halo's straight run was merged to four blocks instead of one, because a single block tipped the object past half glow and the export made the whole ring Neon (no cells). Overlap 0.990 to 0.998, 180 blocks, 2,154 triangles (Blender), eleven objects and the blink. Wanted for: the winged sun radish now hovering in a tilt over a ring of its own suns and leaves. Still weak: the head is still the biggest block of the silhouette; the satellites are small at 16 studs and read as sparks of gold.
- 2026-10-26, PILOT-2 (the second pass, bolder), one round after the coordinator's verdict that v1 was too timid (nothing new read at 16 studs): the caps lifted (Epic 4,000, Legendary and up 6,000), rest-pose groups so a head, a leg, a tail or a whole body can turn without a mass leaving its axis, and every addition made big (a body-sized backdrop, satellites of 0.5 to 0.9 stud, metal a quarter stud thick, a stance that changes the outline). See "The character bar" above; sheet `media/studio/2026-10-26/pilot_bar_v2.jpg`.
