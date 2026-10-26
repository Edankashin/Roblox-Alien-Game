---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Panpipe
name: Syrinx
world: 1
tier: Secret
status: review
element: Shadow
height: 3.5
blocks: 206
tris: 2666
bevel_width: 0.0625
bevel_segments: 2
palette: ["#4A4166", "#1E1A2E", "#8E6BFF", "#B08A3E", "#9B5CFF", "#0B0812"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#9B5CFF", "#6A2BE8", "#C9A8FF"]
arcs: ["PipeMouth>PipeMouth4", "PipeMouth2>PipeMouth5"]
hero: Pipe
vfx: "the Cosmic set in shadow (Secret), eight layers in Effects.luau: every 4 s the pipes trill and five violet notes drift from them and fall instead of rising; a deep violet light breathes on its body; violet notes drift off the ring of satellites below its face; a violet ring rolls slowly backwards under its hooves every 3.5 s; dark smoke falls at its feet; a held aura of deep violet glow; and on the flourish it vanishes in a puff of dark smoke and returns under a violet column of light. The flourish (every 16 s) is that vanish-and-return: a hop, a sink into the smoke, a full turn, the pipes popping on the trill, the ears flared and the satellites leaping"
ride: "Stride; mount form only (Decide-Now 44 a): it grows to riding size while ridden, the rider on the saddle blanket between the head and the pipes"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Panpipe_sheet.svg]]"
render: "[[Panpipe_tq_cells.jpg]]"
glb: ""
overlap: [0.992, 0.998, 0.996, 0.992]
vfx_render: "[[Panpipe_vfx_cells.jpg]]"
cells_render: "[[Panpipe_tq_cells.jpg]]"
idle_render: "[[Panpipe_idle.png]]"
bar_world: Verdant
bar_kit: 13
bar_pieces: [bark_band, blossom_bud, moss_cells, sap_drop, vine_wrap]
bar_stance: "an ibex in mid-stride: the head turned 25 degrees to its right, the right foreleg swung forward 45 degrees off the ground, the tail cocked, a dark eclipse behind it"
bar_satellites: 7
bar_orbit: shards
bar_backdrop: eclipse
bar_aura: aura
---
# Panpipe (Syrinx), Secret, World 1 Verdant

A small shadow goat kid, 3.5 studs to the tips of its horns (B45: it was 13, a church organ on legs; a goat kid stands top of the band by its horns, not its tier), slate and near-black with one accent, violet. Six dark reeds rise off its right haunch, tallest at the outside, stepping down toward its spine, their mouths and lips lit and bound in two brass bands over a brass foot; four brass horns crown its head (a big pair stepping up and back like an ibex's, each with a dark ridge, two lit violet bands and a lit tip, and a small pair in front with lit tips), and a brass circlet with a lit violet gem crosses its brow on a fringe of dark wool that frames the face, curled at its top corners and hanging in a lock beside each eye. A stepped dark beard, a brass bell with a lit clapper, long droopy wool ears with violet tips, cloven brass hooves under wool fetlocks, a dark saddle blanket with violet hems, one lit sound bar on each drape, lit sound glyphs on the sides of its head, and a ring of satellites (eclipse shards, wool tufts and two lit music notes) that turns below its face over a ground aura of violet dashes. Since the character bar pilot its right foreleg is lifted, a vine winds up it, dark moss lies on its haunch, buds sit on its head and brass bark bands ring its hind legs. Concept row in `src/shared/data/Species.luau`: "goat, reed pipes". Element: Shadow (`Effects.luau`); [[Roster-Redesign]] section 2 gives the drifting notes, the falling shadow, the turning ring and the vanish-and-return. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is the one dark thing in a bright meadow, no bigger than a Rare, and the most secret thing in it: 189 blocks, most of them sixteenth-stud cells (the reeds, the horn bands, the sound bars, the circlet); a 32-column face (0.0625 body cells, the finest grid, shared only with Raddis); its own `echo` eyes, which no other species wears: a dark iris where rings of violet ripple out from a lit core and fade, like a note heard from far away; nine moving things; and a flourish every 16 s that is a vanishing trick: it hops, sinks into dark smoke, turns and comes back as its pipes trill under a violet column. Where Raddis is a blaze of gold, Syrinx is a rumour: it beats the Cosmic for mystery, not size. Gentle, never a boss: a kid goat with a small smile.

**Hero block.** The `Pipe` set, six reeds of a panpipe grown into a goat's back, unique in Verdant.

**Moving parts (eight objects and the blink).** `pipes` (the six reeds, their mouths and lips, the bands and the foot: they breathe and pop on the trill), `earR` and `earL` (they droop and lift), `beard` (it sways), `bell` (strap, bell and clapper: it swings), `tail` (with its lit tip: it flicks), `shards` (the satellite ring below its face, which also carries the two music notes: it turns and bobs), `aura` (the ground ring: it breathes); the face plate blinks, glints and ripples. Rare pass w1: `eclipse` (the dark moon in its lit corona behind the horns: it turns slowly, bobs, pops and turns on the flourish), `echoR` (the echo ring over the pipes: it swells) and `gem` (the circlet's gem: the one accent that pulses) make eleven objects and the blink; the bar pilot swaps the two notes for `shards` and `aura`, so it is still eleven.

**Alien anatomy.** Four horns, notes that follow it and an instrument grown into its back.

**World motif (Verdant).** The moss cell in shadow: the sixteenth-stud steps of the horns, the beard and the hanging wool.

## The character bar (B54, pilot 2026-10-26)

[[Blocky-Style]] section 10 and "Pilot bar notes"; the plan is `tools/blocky/pilots.py` (`panpipe()`), the pieces `tools/blocky/kits.py`. A Secret in its shadow palette, the Verdant kit in the dark:

- **Kit (10 pieces).** Three `moss_cells` pads of dark moss on the haunch (violet lit tufts), two `blossom_bud`s (violet petals) on the head's top corners, a `vine_wrap` of violet strips up the lifted foreleg, two brass `sap_drop`s hanging from the saddle blanket's hem (a lit tip each), two brass `bark_band`s round the hind legs. The tassels, knee tufts, cheek tufts, fleece, horn ridges, reed lips and two sound bars per drape (all under a quarter stud) are cut.
- **Satellites (8, `shards`).** Three `eclipse_shard`s (dark chips with a lit violet rim), three `wool_tuft`s and two `note_glyph`s on a ring of radius 1.9 round the body at a stud above the ground, tilted a fifth of a stud: the ring sits below the face so nothing crosses it. It replaces the two floating notes (`note`, `note2`); `Effects.Pieces` Shards hangs a falling-note emitter on it.
- **Backdrop.** The eclipse behind the horns (`eclipse`, z 0.19, 0.125 deep): the dark moon rows and the corona merged in pairs (12 rows to 7, 30 parts to 15, the same shape).
- **Aura.** `aura`: twelve violet dashes on a circle of radius 2 on the ground, breathing every 3.6 s, popping on the flourish.
- **Stance, an ibex about to step.** The right foreleg is lifted a quarter stud (leg, fetlock and both hooves), the left planted; the tail is cocked up behind it. The head and face do not move.
- **Colours.** Slate and near-black (the two-tone base), violet (emissive accent), and the metal accent is now brass `#B08A3E` (it was pewter): the Verdant metal, against the violet.
- Blocks 172 to 189, triangles 2082 to 2246 (Blender), 12 moving things to 12, height 3.5 (unchanged).

## Parts

```yaml
parts:
  # four legs on cloven hooves under wool fetlocks (the hind pair mirrored)
  # the stance: an ibex in mid-stride. The right foreleg is built planted like the left and stands in the `fore` rest pose (swung forward 35
  # degrees at the shoulder, so its hoof is off the ground), the head in the `head` rest pose (turned 22 degrees to its right), the tail cocked
  - {name: FrontLegR, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.5, 0.4375, -0.125], pose: fore}
  - {name: FrontFetlockR, slot: Body, size: [0.375, 0.125, 0.375], at: [0.5, 0.1875, -0.125], material: wool, pose: fore}
  - {name: FrontHoofR, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.4375, 0.0625, -0.125], material: metal, pose: fore}
  - {name: FrontHoof2R, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.5625, 0.0625, -0.125], material: metal, pose: fore}
  - {name: FrontLegL, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [-0.5, 0.4375, -0.125]}
  - {name: FrontFetlockL, slot: Body, size: [0.375, 0.125, 0.375], at: [-0.5, 0.1875, -0.125], material: wool}
  - {name: FrontHoofL, slot: Trim, size: [0.125, 0.125, 0.25], at: [-0.5625, 0.0625, -0.125], material: metal}
  - {name: FrontHoof2L, slot: Trim, size: [0.125, 0.125, 0.25], at: [-0.4375, 0.0625, -0.125], material: metal}
  - {name: HindLeg, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.5, 0.4375, 1.625], mirror: x}
  - {name: HindFetlock, slot: Body, size: [0.375, 0.125, 0.375], at: [0.5, 0.1875, 1.625], mirror: x, material: wool}
  - {name: HindHoof, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.4375, 0.0625, 1.625], mirror: x, material: metal}
  - {name: HindHoof2, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.5625, 0.0625, 1.625], mirror: x, material: metal}
  # the body and the big head, both wool; a dark wool mane behind the head, a forelock and a topknot between the horns, tufts on the cheeks
  - {name: Torso, slot: Body, size: [1.5, 1, 2.25], at: [0, 1.125, 0.875], bevel: true, material: wool}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -0.75], bevel: true, material: wool, pose: head}
  - {name: Mane, slot: BodyDark, size: [1.75, 0.5, 0.25], at: [0, 1.875, 0.125], material: wool}
  - {name: Forelock, slot: BodyDark, size: [0.75, 0.125, 0.5], at: [0, 2.5625, -1], material: wool, pose: head}
  - {name: Topknot, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [0, 2.6875, -1], material: wool, pose: head}
  # Polish w1: a fringe of dark wool proud of the forehead by an eighth, a curl on each end of its top edge and a lock hanging from each end
  # beside the eyes, and on it the brass circlet with its lit violet gem, so the face steps back in three layers from the gem to the eyes
  # and the dark fringe frames it; lit sound glyphs (two bars) on the head's sides
  - {name: Brow, slot: BodyDark, size: [1.75, 0.25, 0.125], at: [0, 2.375, -1.5625], material: wool, pose: head}
  - {name: BrowCurl, slot: BodyDark, size: [0.375, 0.125, 0.1875], at: [0.5625, 2.5625, -1.53125], mirror: x, material: wool, pose: head}
  - {name: BrowLock, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.8125, 2.125, -1.5625], mirror: x, material: wool, pose: head}
  - {name: Circlet, slot: Trim, size: [2.125, 0.25, 0.125], at: [0, 2.3125, -1.6875], material: metal, pose: head}
  - {name: CircletGem, slot: Glow, size: [0.25, 0.25, 0.0625], at: [0, 2.3125, -1.78125], moves: gem, pivot: [0, 2.3125, -1.78125], pose: head}
  - {name: Rune, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [1.03125, 1.4375, -0.34375], mirror: x, pose: head}
  - {name: Rune2, slot: Glow, size: [0.0625, 0.25, 0.0625], at: [1.03125, 1.5, -0.21875], mirror: x, pose: head}
  # a stepped dark beard under the chin (it sways), a brass bell with a lit clapper beside it (it swings)
  - {name: Beard, slot: BodyDark, size: [0.5, 0.25, 0.25], at: [0, 0.875, -1.25], moves: beard, pivot: [0, 1, -1.25], material: wool, pose: head}
  - {name: Beard2, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 0.625, -1.25], moves: beard, pivot: [0, 1, -1.25], material: wool, pose: head}
  - {name: BellStrap, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.5625, 0.9375, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625]}
  - {name: Bell, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.5625, 0.75, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625], material: metal}
  - {name: Clapper, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.5625, 0.59375, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625]}
  # long droopy wool ears with violet tips (they droop and lift)
  - {name: Ear, slot: Body, size: [0.625, 0.125, 0.25], at: [1.28125, 2.0625, -0.75], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [1, 2.1875, -0.75], material: wool, pose: head}
  - {name: EarTip, slot: Accessory, size: [0.125, 0.125, 0.25], at: [1.625, 1.90625, -0.75], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [1, 2.1875, -0.75], pose: head}
  # alien anatomy: four horns; the big pair steps up and back like an ibex's, a dark ridge and two lit violet bands on each, lit tips; a
  # small pair in front
  - {name: Horn, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.5625, 2.625, -0.8125], mirror: x, material: metal, pose: head}
  - {name: HornRing, slot: Glow, size: [0.25, 0.0625, 0.25], at: [0.5625, 2.78125, -0.8125], mirror: x, pose: head}
  - {name: Horn2, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.625, 2.9375, -0.6875], mirror: x, material: metal, pose: head}
  - {name: Horn3, slot: Trim, size: [0.1875, 0.25, 0.25], at: [0.65625, 3.1875, -0.5], mirror: x, material: metal, pose: head}
  - {name: HornRing2, slot: Glow, size: [0.1875, 0.0625, 0.25], at: [0.65625, 3.34375, -0.4375], mirror: x, pose: head}
  - {name: Horn4, slot: Trim, size: [0.1875, 0.125, 0.25], at: [0.65625, 3.4375, -0.25], mirror: x, material: metal, pose: head}
  - {name: HornTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 3.4375, -0.0625], mirror: x, pose: head}
  - {name: SmallHorn, slot: Trim, size: [0.125, 0.25, 0.125], at: [0.3125, 2.625, -1.25], mirror: x, material: metal, pose: head}
  - {name: SmallHornTip, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.3125, 2.78125, -1.25], mirror: x, pose: head}
  # the saddle: a dark blanket with a brass pommel, drapes with violet hems, brass tassels and lit sound bars
  - {name: Blanket, slot: BodyDark, size: [1.625, 0.0625, 1], at: [0, 1.65625, 0.5]}
  - {name: Pommel, slot: Trim, size: [0.25, 0.125, 0.125], at: [0, 1.75, 0.3125], material: metal}
  - {name: Drape, slot: BodyDark, size: [0.0625, 0.5, 1], at: [0.84375, 1.4375, 0.5], mirror: x}
  - {name: Hem, slot: Accessory, size: [0.0625, 0.0625, 1], at: [0.90625, 1.21875, 0.5], mirror: x}
  - {name: SoundBar3, slot: Glow, size: [0.0625, 0.375, 0.125], at: [0.90625, 1.4375, 0.75], mirror: x}
  # wool: tufts along the spine between the saddle and the pipes, fringes hanging from the flanks and the rump, fleece on the haunches
  - {name: Fringe, slot: BodyDark, size: [0.0625, 0.25, 0.25], at: [0.78125, 0.625, 1.25], mirror: x, material: wool}
  - {name: Fringe2, slot: BodyDark, size: [0.0625, 0.375, 0.25], at: [0.78125, 0.6875, 1.75], mirror: x, material: wool}
  - {name: RumpFringe, slot: BodyDark, size: [0.75, 0.25, 0.0625], at: [0, 0.875, 2.03125], material: wool}
  # a short tail with a lit tip (it flicks)
  - {name: Tail, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0, 1.8125, 2.125], moves: tail, pivot: [0, 1.625, 2.0625]}
  - {name: TailTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 2.0625, 2.125], moves: tail, pivot: [0, 1.625, 2.0625]}
  # alien anatomy: two lit notes that drift round it (each circles and bobs)
  # the hero: the reed pipes, six dark reeds rising off the right haunch, tallest at the outside and stepping down toward the spine (the
  # asymmetry is the silhouette), mouths and front lips lit, bound by two brass bands over a brass foot (they breathe and pop on the trill)
  - {name: PipeFoot, slot: Trim, size: [1.0625, 0.0625, 0.375], at: [1.15625, 1.65625, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: metal}
  - {name: Pipe, slot: BodyDark, size: [0.125, 1.5, 0.25], at: [1.625, 2.375, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth, slot: Glow, size: [0.125, 0.0625, 0.25], at: [1.625, 3.15625, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: Pipe2, slot: BodyDark, size: [0.125, 1.3125, 0.25], at: [1.4375, 2.28125, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth2, slot: Glow, size: [0.125, 0.0625, 0.25], at: [1.4375, 2.96875, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: Pipe3, slot: BodyDark, size: [0.125, 1.125, 0.25], at: [1.25, 2.1875, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth3, slot: Glow, size: [0.125, 0.0625, 0.25], at: [1.25, 2.78125, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: Pipe4, slot: BodyDark, size: [0.125, 0.9375, 0.25], at: [1.0625, 2.09375, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth4, slot: Glow, size: [0.125, 0.0625, 0.25], at: [1.0625, 2.59375, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: Pipe5, slot: BodyDark, size: [0.125, 0.75, 0.25], at: [0.875, 2, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth5, slot: Glow, size: [0.125, 0.0625, 0.25], at: [0.875, 2.40625, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: Pipe6, slot: BodyDark, size: [0.125, 0.5625, 0.25], at: [0.6875, 1.90625, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: wood}
  - {name: PipeMouth6, slot: Glow, size: [0.125, 0.0625, 0.25], at: [0.6875, 2.21875, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625]}
  - {name: PipeBand, slot: Trim, size: [1.0625, 0.0625, 0.375], at: [1.15625, 1.84375, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: metal}
  - {name: PipeBand2, slot: Trim, size: [1.0625, 0.0625, 0.375], at: [1.15625, 2.09375, 1.625], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: metal}
  # Rare pass w1: an echo ring, a hollow square of lit sixteenth-stud bars floating over the pipes' mouths, that swells and fades like a
  # note heard from far away (`echo`); and a lit finger hole of violet glass on each reed
  - {name: Echo, slot: Glow, size: [0.625, 0.0625, 0.0625], at: [1.25, 3.40625, 1.34375], moves: echo, pivot: [1.25, 3.375, 1.625]}
  - {name: Echo2, slot: Glow, size: [0.625, 0.0625, 0.0625], at: [1.25, 3.40625, 1.90625], moves: echo, pivot: [1.25, 3.375, 1.625]}
  - {name: Echo3, slot: Glow, size: [0.0625, 0.0625, 0.5], at: [0.96875, 3.40625, 1.625], moves: echo, pivot: [1.25, 3.375, 1.625]}
  - {name: Echo4, slot: Glow, size: [0.0625, 0.0625, 0.5], at: [1.53125, 3.40625, 1.625], moves: echo, pivot: [1.25, 3.375, 1.625]}
  - {name: Hole0, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.625, 2.375, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  - {name: Hole1, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.4375, 2.3125, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  - {name: Hole2, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.25, 2.1875, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  - {name: Hole3, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.0625, 2.125, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  - {name: Hole4, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.875, 2.0625, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  - {name: Hole5, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.6875, 1.9375, 1.46875], moves: pipes, pivot: [1.15625, 1.625, 1.625], material: crystal}
  # pilot bar: begin (tools/blocky/pilots.py writes this region: the Verdant kit, the satellite set and the aura)
  # the Verdant kit in shadow: dark moss pads on the haunch
  - {name: MossAa, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [-0.5, 1.6875, 1.25], material: moss}
  - {name: MossAb, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [-0.4375, 1.8125, 1.25], material: moss}
  - {name: MossAc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [-0.5625, 1.9375, 1.1875], material: moss}
  - {name: MossBa, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [-0.5, 1.6875, 1.75], material: moss}
  - {name: MossBb, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [-0.4375, 1.8125, 1.75], material: moss}
  - {name: MossBc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [-0.5625, 1.9375, 1.6875], material: moss}
  - {name: MossCa, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [0, 1.6875, 1.75], material: moss}
  - {name: MossCb, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [0.0625, 1.8125, 1.75], material: moss}
  - {name: MossCc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [-0.0625, 1.9375, 1.6875], material: moss}
  # violet blossom buds on the turned head's top corners (they turn with it)
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.9375, 2.625, -0.3125], mirror: x, pose: head, material: wood}
  - {name: Budb, slot: Accessory, size: [0.375, 0.125, 0.125], at: [0.9375, 2.8125, -0.3125], mirror: x, pose: head}
  - {name: Budc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.9375, 2.9375, -0.3125], mirror: x, pose: head}
  # a vine winding up the lifted foreleg in three strips, an eighth proud (it swings with the leg)
  - {name: Vine0, slot: Accessory, size: [0.5, 0.125, 0.125], at: [0.5, 0.3125, -0.3125], pose: fore, material: moss}
  - {name: Vine1, slot: Accessory, size: [0.125, 0.125, 0.5], at: [0.6875, 0.4375, -0.125], pose: fore, material: moss}
  - {name: Vine2, slot: Accessory, size: [0.5, 0.125, 0.125], at: [0.5, 0.5625, 0.0625], pose: fore, material: moss}
  # brass sap drops, half a stud long, hanging from the blanket's hem
  - {name: Sapa, slot: Trim, size: [0.1875, 0.1875, 0.1875], at: [1.03125, 1.09375, 0.40625], mirror: x, material: metal}
  - {name: Sapb, slot: Trim, size: [0.375, 0.1875, 0.375], at: [0.9375, 0.90625, 0.3125], mirror: x, material: metal}
  - {name: Sapc, slot: Glow, size: [0.1875, 0.1875, 0.1875], at: [1.03125, 0.71875, 0.40625], mirror: x, material: crystal}
  # brass cuffs, a quarter stud tall and an eighth proud, round all four legs (the right foreleg's swings with it)
  - {name: CuffH, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.5, 0.4375, 1.625], mirror: x, material: metal}
  - {name: CuffFL, slot: Trim, size: [0.5, 0.25, 0.5], at: [-0.5, 0.4375, -0.125], material: metal}
  - {name: CuffFR, slot: Trim, size: [0.5, 0.25, 0.5], at: [0.5, 0.4375, -0.125], pose: fore, material: metal}
  # the brass girth: a quarter stud wide, an eighth proud, right round the barrel behind the saddle blanket
  - {name: Girth, slot: Trim, size: [1.75, 1.25, 0.25], at: [0, 1.125, 0.875], material: metal}
  # the backdrop (`eclipse`, it turns once in 20 s): a dark moon 2.8 studs across behind the rump, a lit violet rim a cell thick and seven stepped rays round it, a quarter stud deep
  - {name: Moon0, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 0.375, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon1, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.625, 0.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon2, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 0.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon3, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.625, 0.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon4, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.875, 0.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon5, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 0.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon6, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.875, 0.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon7, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.125, 1.125, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon8, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 1.125, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon9, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.125, 1.125, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon10, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 1.375, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon11, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.375, 1.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon12, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 1.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon13, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.375, 1.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon14, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.375, 1.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon15, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 1.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon16, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.375, 1.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon17, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 2.125, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon18, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.125, 2.375, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon19, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.375, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon20, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.125, 2.375, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon21, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.875, 2.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon22, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 2.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon23, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.875, 2.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon24, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.625, 2.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon25, slot: BodyDark, size: [1, 0.25, 0.25], at: [0, 2.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125]}
  - {name: Moon26, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.625, 2.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Moon27, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 3.125, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray0, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.125, 2.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray1, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.25, 3, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray2, slot: Glow, size: [0.25, 0.5, 0.25], at: [1.5, 1.75, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.75, 1.75, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray4, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.125, 0.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray5, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.25, 0.5, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray6, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 0.25, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray7, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.125, 0.625, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray8, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.25, 0.5, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray9, slot: Glow, size: [0.25, 0.5, 0.25], at: [-1.5, 1.75, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray10, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.75, 1.75, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray11, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.125, 2.875, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  - {name: Ray12, slot: Glow, size: [0.125, 0.125, 0.25], at: [-1.25, 3, 2.3125], moves: eclipse, pivot: [0, 1.75, 2.3125], material: glow}
  # the satellite set (`shards`, one wide ring, the front low): four eclipse shards wrapped in violet light and three wool tufts, seven eighths of a stud each
  - {name: Sat0a, slot: Body, size: [0.75, 0.625, 0.125], at: [0.75, 0.9375, -2.0625], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat0b, slot: Accessory, size: [0.25, 0.25, 0.0625], at: [0.625, 0.875, -2.15625], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat0c, slot: Glow, size: [0.875, 0.125, 0.125], at: [0.8125, 1.3125, -2.0625], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat0d, slot: Glow, size: [0.125, 0.625, 0.125], at: [1.1875, 0.9375, -2.0625], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat1a, slot: BodyDark, size: [0.75, 0.625, 0.1875], at: [2.25, 1.4375, -0.59375], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat1b, slot: Body, size: [0.5625, 0.5625, 0.125], at: [2.21875, 1.53125, -0.75], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat1c, slot: Accessory, size: [0.1875, 0.1875, 0.125], at: [2.40625, 1.53125, -0.875], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat2a, slot: Body, size: [0.75, 0.625, 0.125], at: [2.0625, 1.75, 1.625], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat2b, slot: Accessory, size: [0.25, 0.25, 0.0625], at: [2.1875, 1.6875, 1.71875], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat2c, slot: Glow, size: [0.875, 0.125, 0.125], at: [2, 2.125, 1.625], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat2d, slot: Glow, size: [0.125, 0.625, 0.125], at: [1.625, 1.75, 1.625], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat3a, slot: BodyDark, size: [0.75, 0.625, 0.1875], at: [0.25, 1.9375, 2.71875], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat3b, slot: Body, size: [0.5625, 0.5625, 0.125], at: [0.28125, 2.03125, 2.875], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat3c, slot: Accessory, size: [0.1875, 0.1875, 0.125], at: [0.09375, 2.03125, 3], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat4a, slot: Body, size: [0.75, 0.625, 0.125], at: [-1.625, 1.625, 2], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat4b, slot: Accessory, size: [0.25, 0.25, 0.0625], at: [-1.5, 1.5625, 2.09375], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat4c, slot: Glow, size: [0.875, 0.125, 0.125], at: [-1.6875, 2, 2], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat4d, slot: Glow, size: [0.125, 0.625, 0.125], at: [-2.0625, 1.625, 2], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat5a, slot: BodyDark, size: [0.75, 0.625, 0.1875], at: [-2.375, 1.25, -0.15625], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat5b, slot: Body, size: [0.5625, 0.5625, 0.125], at: [-2.40625, 1.34375, -0.3125], moves: shards, pivot: [0, 1.5, 0.25], material: wool}
  - {name: Sat5c, slot: Accessory, size: [0.1875, 0.1875, 0.125], at: [-2.21875, 1.34375, -0.4375], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat6a, slot: Body, size: [0.75, 0.625, 0.125], at: [-1.3125, 0.875, -1.875], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat6b, slot: Accessory, size: [0.25, 0.25, 0.0625], at: [-1.4375, 0.8125, -1.96875], moves: shards, pivot: [0, 1.5, 0.25]}
  - {name: Sat6c, slot: Glow, size: [0.875, 0.125, 0.125], at: [-1.25, 1.25, -1.875], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  - {name: Sat6d, slot: Glow, size: [0.125, 0.625, 0.125], at: [-0.875, 0.875, -1.875], moves: shards, pivot: [0, 1.5, 0.25], material: glow}
  # the ground aura (`aura`, it breathes): twelve violet runes, three quarters of a stud long, in a circle round the hooves
  - {name: Aura0, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0, 0.03125, -1.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura1, slot: Glow, size: [0.75, 0.0625, 0.25], at: [1, 0.03125, -1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura2, slot: Glow, size: [0.25, 0.0625, 0.75], at: [1.75, 0.03125, -0.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura3, slot: Glow, size: [0.25, 0.0625, 0.75], at: [2, 0.03125, 0.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura4, slot: Glow, size: [0.25, 0.0625, 0.75], at: [1.75, 0.03125, 1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura5, slot: Glow, size: [0.75, 0.0625, 0.25], at: [1, 0.03125, 2.125], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura6, slot: Glow, size: [0.75, 0.0625, 0.25], at: [0, 0.03125, 2.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura7, slot: Glow, size: [0.75, 0.0625, 0.25], at: [-1, 0.03125, 2.125], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura8, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-1.75, 0.03125, 1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura9, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-2, 0.03125, 0.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura10, slot: Glow, size: [0.25, 0.0625, 0.75], at: [-1.75, 0.03125, -0.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura11, slot: Glow, size: [0.75, 0.0625, 0.25], at: [-1, 0.03125, -1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 32 columns across the 2-stud head, so the cell is 0.0625 studs (16 a stud) and the 1.5-stud front is 24 rows, the finest body grid with Raddis's; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 32
```

## Eyes

Its own eyes, a new Secret design added to the eye library by this batch ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `echo`, a dark violet iris where rings of the one accent ripple outward from a lit core and fade as they go, like a note heard from far away, at 32 pixels a stud on a 1.75 x 0.75 stud plate (56 x 24 pixels, thirteen frames: open, half, closed, two glints, eight ripple frames). No other species wears it. A small smile and dim violet star cheeks.

```yaml
eyes:
  key: echo
  colours: {deep: "#221C38", mid: "#5B3FA8", rim: glow, sparkle: "#E2D6FF", cheek: "#7A5CD6"}
  mouth: smile
  cheeks: stars
  plate: [1.75, 0.75]
  at: [0, 1.84375]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the pipes breathe, the ears droop and lift, the beard sways, the bell swings, the tail flicks, two notes drift round it, the goat breathes, the face blinks, glints and ripples. Nine moving things (eight objects and the blink; a Secret needs eight). The flourish, every 16 s: the vanish-and-return, a hop, a sink into the smoke, a full turn, the pipes popping on the trill, the ears flared and the note leaping.

```yaml
rig:
  rest:
    head: {rot: [0, -25, 0], pivot: [0, 1.5, -0.125]}
    fore: {rot: [45, 0, 0], pivot: [0.5, 1.0, -0.125]}
  clips:
    pipes: [{kind: pulse, amp: 0.03, period: 4}]
    eclipse: [{kind: spin, amp: 360, period: 20, axis: z}, {kind: bob, amp: 0.05, period: 4.4}, {kind: sway, amp: 6, period: 6.6, axis: y, phase: 0.3}]
    echo: [{kind: pulse, amp: 0.25, period: 1.6}, {kind: bob, amp: 0.06, period: 1.6, phase: 0.25}]
    gem: [{kind: pulse, amp: 0.25, period: 2.2}]
    ear: [{kind: sway, amp: 8, period: 3.4, axis: z}]
    beard: [{kind: sway, amp: 5, period: 3, axis: x}]
    bell: [{kind: sway, amp: 12, period: 1.9, axis: x, phase: 0.2}]
    tail: [{kind: wag, amp: 14, period: 2.8, axis: y}]
    shards: [{kind: spin, amp: 360, period: 16, axis: y}, {kind: bob, amp: 0.05, period: 3.6}]
    aura: [{kind: pulse, amp: 0.1, period: 3.6}]
    root: [{kind: squash, amp: 0.025, period: 3.4}]
    face: [{kind: blink, period: 6}]
  flourish:
    every: 16
    length: 4.6
    moves:
      - {part: root, kind: hop, amp: 0.4, at: 0, for: 0.9}
      - {part: eclipse, kind: pop, amp: 0.25, at: 0, for: 1.2}
      - {part: root, kind: squash, amp: 0.2, axis: y, at: 0.9, for: 0.7}
      - {part: root, kind: turn, amp: 360, axis: y, at: 1.4, for: 1.6}
      - {part: eclipse, kind: turn, amp: -180, axis: z, at: 1.4, for: 1.8}
      - {part: gem, kind: pop, amp: 0.5, at: 2.4, for: 0.6}
      - {part: pipes, kind: pop, amp: 0.2, at: 2.6, for: 0.8}
      - {part: echo, kind: pop, amp: 0.6, at: 2.6, for: 1.2}
      - {part: ear, kind: flare, amp: 25, axis: z, at: 2.6, for: 1}
      - {part: shards, kind: hop, amp: 0.4, at: 2.8, for: 1}
      - {part: aura, kind: pop, amp: 0.25, at: 0.2, for: 1.4}
      - {part: bell, kind: swish, amp: 20, axis: x, at: 3, for: 1.4}
      - {part: tail, kind: flare, amp: 30, axis: x, at: 3.2, for: 1}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Eclipse | `Diamond` (eclipse) | 0.15, 0.89, 0.00 | the violet column's foot on the flourish, a slow dark mote rain | Halo |
| Echo | `Echo` (echo) | 0.37, 0.97, 0.30 | the trill's notes rising from the ring | BackR |

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Panpipe.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Panpipe.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Panpipe_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Panpipe_vfx.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Panpipe_idle.png]]

The concept sheet, drawn from the parts table above: [[Panpipe_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Panpipe_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Panpipe_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.0625 studs (16 a stud) on the 32-column face since the B45 resize (it was 0.344 on a 5.5-stud head), 56 cells tall, painted at 4 texels a cell. Materials: wool on the head, torso, ears, mane, beard, fringes, tufts and fleece (shag blobs with a violet fleck in thirty), wood on the six reeds, metal on the horns, hooves, bell, circlet, tassels, bands and pommel.

![[Panpipe_tq_cells.jpg]]

![[Panpipe_vfx_cells.jpg]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: small brass horns read as stubs and brass pipes as a grey chimney behind the head. Round 2: bigger horns sweeping up, out and down read as branches. Round 3: ibex horns that arch back (a chain of tilted segments with a lit band, a dark ridge and lit tips), the pipes dark reeds with lit mouths and lit lips in brass bands, the ears drooped; the preview gives it a violet ring and falling shadow smoke. Overlap 0.996 to 0.998, 1,504 triangles, 108 blocks, 13 studs. Wanted for: the one dark thing in a bright meadow, a gentle giant that plays its own organ and that you can ride. Still cheap: in daylight it is a muted purple box with a face; the beard and bell are small; the shadow wool reads as stripes on the legs from the side. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The violet flecks and the grout lift the dark coat in daylight (the open item of loop 2, partly: it is still the darkest thing on the meadow, as a Secret should be); the reeds read as reeds. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, two rounds. Round 1: rebuilt from 13 studs to 3.5 by redesign: a goat kid with a 2-stud head on a 32-column face (0.0625 cells, 56 cells tall), the ibex horns as sixteenth-stud steps with two lit bands each, a brass circlet with a lit gem, a stepped beard and a swinging bell, a saddle with sound bars and tassels, two drifting notes, six reeds in sixteenth-stud cells; its own eyes, `echo`, a new Secret design added to the library (rings of violet rippling out of a lit core over eight frames), a smile, dim violet star cheeks. 114 blocks. The reeds across the rump, behind the head, made it a box with two horns: 0.720 against Gaira and 0.718 against Buzzik in the silhouette test. Round 2: the reeds moved a stud to the right so they rise off the right haunch, tallest at the outside (a stepped ramp beside the head from the front), and the ears grew a quarter stud: 0.675 and 0.64. Eight moving objects and the blink; a flourish every 16 s (the vanish-and-return: a hop, a sink, a full turn, the pipes popping on the trill). Overlap 0.994 to 0.998, 1,386 triangles. Wanted for: the one dark thing on the meadow, the size of a Rare, with eyes that ripple like a note from far off; a rumour beside Raddis's blaze. Still weak: the slate head is a flat plane between the circlet and the eyes; the horns read as stacked blocks more than an arch from the three-quarter view. Status review.
- 2026-10-21, Polish w1, two rounds. The flat forehead between the circlet and the eyes: a fringe of dark wool now stands an eighth proud of the forehead across the head's width, curled at its top corners and hanging in a lock beside each eye, and the brass circlet and its lit gem sit on it, so the face steps back in three layers (gem, circlet, fringe) to the eyes and the dark fringe frames the slate face. Round 1 made the ridge in the slate body colour and it vanished; the dark wool reads. 119 blocks (Secret 110 to 200). Overlap 0.995 to 0.998. Honest read: the face now has a brow and a frame, the circlet reads as jewellery on a forelock; below the eyes the face is still one slate plane, which keeps the face calm. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: an eclipse rising behind the horns, a dark moon disc in twelve sixteenth-stud rows inside a corona of lit violet glass cells with four rays and a diamond-ring bead, Raddis's sun disk in shadow (it turns once in 20 s and turns half round on the flourish); an echo ring of lit bars over the pipes' mouths that swells like a note far away; a lit glass finger hole on each reed; the circlet's gem pulses (the Secret's one accent); the glow is a deeper violet `#9B5CFF` and the cycle with it (the lilac `#B28CFF` read pale). Round 1's disc in quarter-stud rows read as a dark slab; eighth-stud rows read round. The flourish is 4.6 s. 172 blocks, twelve moving things. Honest read: the shadow goat with an eclipse behind its horns is the Secret's answer to Raddis's sun; at a distance the dark disc can read as a chair back without its corona lit. Status review.
- 2026-10-26, character bar pilot worker, three rounds. Round 1: the sub-quarter detail cut, the eclipse rows merged in pairs, the right foreleg lifted and the tail cocked, the kit and a satellite ring written by `pilots.py`. Round 2: the pewter trim became brass (the Verdant metal) and the horns, bell and hooves read gold against the violet; the satellites moved from the head's height to a stud above the ground, because a ring at the head's height crossed the face from the front; the ring grew from 0.25 to 0.4 studs a piece. Round 3: the aura ring cut from a ring of 38 cells to twelve dashes (a ring of cells would have been 20 blocks). Overlap 0.992 to 0.998, 189 blocks, 2,246 triangles (Blender; the estimate in the spec is 2,470 of the 2,500 cap), eleven objects and the blink. Wanted for: the shadow goat stepping out under its eclipse, ringed by chips of the moon, tufts of its wool and its notes. Still weak: the dark satellites read as debris against dark ground; the lifted foreleg reads as a floating block from the side.
