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
blocks: 172
tris: 2082
bevel_width: 0.0625
bevel_segments: 2
palette: ["#4A4166", "#1E1A2E", "#8E6BFF", "#B08A3E", "#9B5CFF", "#0B0812"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#9B5CFF", "#6A2BE8", "#C9A8FF"]
arcs: ["PipeMouth>PipeMouth4", "PipeMouth2>PipeMouth5"]
hero: Pipe
vfx: "the Cosmic set in shadow (Secret), eight layers in Effects.luau: every 4 s the pipes trill and five violet notes drift from them and fall instead of rising; a deep violet light breathes on its body; three violet notes orbit over its head; a violet ring rolls slowly backwards under its hooves every 3.5 s; dark smoke falls at its feet; a held aura of deep violet glow; and on the flourish it vanishes in a puff of dark smoke and returns under a violet column of light. The flourish (every 16 s) is that vanish-and-return: a hop, a sink into the smoke, a full turn, the pipes popping on the trill, the ears flared and the note leaping"
ride: "Stride; mount form only (Decide-Now 44 a): it grows to riding size while ridden, the rider on the saddle blanket between the head and the pipes"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Panpipe_sheet.svg]]"
render: "[[Panpipe_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.997, 0.998, 0.996]
vfx_render: "[[Panpipe_vfx_cells.jpg]]"
cells_render: "[[Panpipe_tq_cells.jpg]]"
idle_render: "[[Panpipe_idle.png]]"
bar_world: Verdant
bar_kit: 10
bar_pieces: [bark_band, blossom_bud, moss_cells, sap_drop, vine_wrap]
bar_stance: "an ibex about to step: the right foreleg lifted a quarter stud, the left planted, the tail cocked up"
bar_satellites: 8
bar_orbit: shards
bar_backdrop: eclipse
bar_aura: aura
---
# Panpipe (Syrinx), Secret, World 1 Verdant

A small shadow goat kid, 3.5 studs to the tips of its horns (B45: it was 13, a church organ on legs; a goat kid stands top of the band by its horns, not its tier), slate and near-black with one accent, violet. Six dark reeds rise off its right haunch, tallest at the outside, stepping down toward its spine, their mouths and lips lit and bound in two pewter bands over a pewter foot; four pewter horns crown its head (a big pair stepping up and back like an ibex's, each with a dark ridge, two lit violet bands and a lit tip, and a small pair in front with lit tips), and a pewter circlet with a lit violet gem crosses its brow on a fringe of dark wool that frames the face, curled at its top corners and hanging in a lock beside each eye. A stepped dark beard, a pewter bell with a lit clapper, long droopy wool ears with violet tips, wool tufts on its cheeks, cloven pewter hooves under wool fetlocks, a dark saddle blanket with violet hems, pewter tassels and lit sound bars on its drapes, lit sound glyphs on the sides of its head, and two lit music notes that drift round it. Concept row in `src/shared/data/Species.luau`: "goat, reed pipes". Element: Shadow (`Effects.luau`); [[Roster-Redesign]] section 2 gives the drifting notes, the falling shadow, the turning ring and the vanish-and-return. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is the one dark thing in a bright meadow, no bigger than a Rare, and the most secret thing in it: 119 blocks, most of them sixteenth-stud cells (the reeds, the horn bands, the sound bars, the circlet); a 32-column face (0.0625 body cells, the finest grid, shared only with Raddis); its own `echo` eyes, which no other species wears: a dark iris where rings of violet ripple out from a lit core and fade, like a note heard from far away; nine moving things; and a flourish every 16 s that is a vanishing trick: it hops, sinks into dark smoke, turns and comes back as its pipes trill under a violet column. Where Raddis is a blaze of gold, Syrinx is a rumour: it beats the Cosmic for mystery, not size. Gentle, never a boss: a kid goat with a small smile.

**Hero block.** The `Pipe` set, six reeds of a panpipe grown into a goat's back, unique in Verdant.

**Moving parts (eight objects and the blink).** `pipes` (the six reeds, their mouths and lips, the bands and the foot: they breathe and pop on the trill), `earR` and `earL` (they droop and lift), `beard` (it sways), `bell` (strap, bell and clapper: it swings), `tail` (with its lit tip: it flicks), `note` and `note2` (the two floating notes: they circle and bob); the face plate blinks, glints and ripples. Rare pass w1: `eclipse` (the dark moon in its lit corona behind the horns: it turns slowly, bobs, pops and turns on the flourish), `echoR` (the echo ring over the pipes: it swells) and `gem` (the circlet's gem: the one accent that pulses) make eleven objects and the blink.

**Alien anatomy.** Four horns, notes that follow it and an instrument grown into its back.

**World motif (Verdant).** The moss cell in shadow: the sixteenth-stud steps of the horns, the beard and the hanging wool.

## Parts

```yaml
parts:
  # four legs on cloven hooves under wool fetlocks (the hind pair mirrored)
  # the stance: an ibex about to step: the right foreleg is lifted a quarter stud (hooves, fetlock and leg together), the left one planted, the
  # tail cocked up behind it
  - {name: FrontLegR, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.5, 0.6875, -0.125]}
  - {name: FrontFetlockR, slot: Body, size: [0.375, 0.125, 0.375], at: [0.5, 0.4375, -0.125], material: wool}
  - {name: FrontHoofR, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.4375, 0.3125, -0.125], material: metal}
  - {name: FrontHoof2R, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.5625, 0.3125, -0.125], material: metal}
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
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -0.75], bevel: true, material: wool}
  - {name: Mane, slot: BodyDark, size: [1.75, 0.5, 0.25], at: [0, 1.875, 0.125], material: wool}
  - {name: Forelock, slot: BodyDark, size: [0.75, 0.125, 0.5], at: [0, 2.5625, -1], material: wool}
  - {name: Topknot, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [0, 2.6875, -1], material: wool}
  # Polish w1: a fringe of dark wool proud of the forehead by an eighth, a curl on each end of its top edge and a lock hanging from each end
  # beside the eyes, and on it the pewter circlet with its lit violet gem, so the face steps back in three layers from the gem to the eyes
  # and the dark fringe frames it; lit sound glyphs (two bars) on the head's sides
  - {name: Brow, slot: BodyDark, size: [1.75, 0.25, 0.125], at: [0, 2.375, -1.5625], material: wool}
  - {name: BrowCurl, slot: BodyDark, size: [0.375, 0.125, 0.1875], at: [0.5625, 2.5625, -1.53125], mirror: x, material: wool}
  - {name: BrowLock, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.8125, 2.125, -1.5625], mirror: x, material: wool}
  - {name: Circlet, slot: Trim, size: [1, 0.125, 0.0625], at: [0, 2.3125, -1.65625], material: metal}
  - {name: CircletGem, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0, 2.3125, -1.71875], moves: gem, pivot: [0, 2.3125, -1.71875]}
  - {name: Rune, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [1.03125, 1.4375, -0.34375], mirror: x}
  - {name: Rune2, slot: Glow, size: [0.0625, 0.25, 0.0625], at: [1.03125, 1.5, -0.21875], mirror: x}
  # a stepped dark beard under the chin (it sways), a pewter bell with a lit clapper beside it (it swings)
  - {name: Beard, slot: BodyDark, size: [0.5, 0.25, 0.25], at: [0, 0.875, -1.25], moves: beard, pivot: [0, 1, -1.25], material: wool}
  - {name: Beard2, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 0.625, -1.25], moves: beard, pivot: [0, 1, -1.25], material: wool}
  - {name: BellStrap, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.5625, 0.9375, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625]}
  - {name: Bell, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.5625, 0.75, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625], material: metal}
  - {name: Clapper, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.5625, 0.59375, -1.0625], moves: bell, pivot: [0.5625, 1, -1.0625]}
  # long droopy wool ears with violet tips (they droop and lift)
  - {name: Ear, slot: Body, size: [0.625, 0.125, 0.25], at: [1.28125, 2.0625, -0.75], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [1, 2.1875, -0.75], material: wool}
  - {name: EarTip, slot: Accessory, size: [0.125, 0.125, 0.25], at: [1.625, 1.90625, -0.75], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [1, 2.1875, -0.75]}
  # alien anatomy: four horns; the big pair steps up and back like an ibex's, a dark ridge and two lit violet bands on each, lit tips; a
  # small pair in front
  - {name: Horn, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.5625, 2.625, -0.8125], mirror: x, material: metal}
  - {name: HornRing, slot: Glow, size: [0.25, 0.0625, 0.25], at: [0.5625, 2.78125, -0.8125], mirror: x}
  - {name: Horn2, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.625, 2.9375, -0.6875], mirror: x, material: metal}
  - {name: Horn3, slot: Trim, size: [0.1875, 0.25, 0.25], at: [0.65625, 3.1875, -0.5], mirror: x, material: metal}
  - {name: HornRing2, slot: Glow, size: [0.1875, 0.0625, 0.25], at: [0.65625, 3.34375, -0.4375], mirror: x}
  - {name: Horn4, slot: Trim, size: [0.1875, 0.125, 0.25], at: [0.65625, 3.4375, -0.25], mirror: x, material: metal}
  - {name: HornTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.6875, 3.4375, -0.0625], mirror: x}
  - {name: SmallHorn, slot: Trim, size: [0.125, 0.25, 0.125], at: [0.3125, 2.625, -1.25], mirror: x, material: metal}
  - {name: SmallHornTip, slot: Glow, size: [0.125, 0.0625, 0.125], at: [0.3125, 2.78125, -1.25], mirror: x}
  # the saddle: a dark blanket with a pewter pommel, drapes with violet hems, pewter tassels and lit sound bars
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
  # asymmetry is the silhouette), mouths and front lips lit, bound by two pewter bands over a pewter foot (they breathe and pop on the trill)
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
  # Rare pass w1, the signature piece: an eclipse rising behind the horns, a dark moon disc (rows of quarter-stud cells) inside a lit
  # violet corona of glass cells with four rays, Raddis's sun disk in shadow; it turns slowly, bobs and flares on the flourish (`eclipse`)
  - {name: Moon0, slot: BodyDark, size: [0.5, 0.125, 0.125], at: [0, 1.9375, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona0, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 1.9375, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon1, slot: BodyDark, size: [1, 0.125, 0.125], at: [0, 2.0625, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona1, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5625, 2.0625, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon2, slot: BodyDark, size: [1.25, 0.25, 0.125], at: [0, 2.25, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona2, slot: Glow, size: [0.125, 0.25, 0.125], at: [0.6875, 2.25, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon4, slot: BodyDark, size: [1.5, 0.5, 0.125], at: [0, 2.625, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona4, slot: Glow, size: [0.125, 0.5, 0.125], at: [0.8125, 2.625, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon8, slot: BodyDark, size: [1.25, 0.25, 0.125], at: [0, 3, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona8, slot: Glow, size: [0.125, 0.25, 0.125], at: [0.6875, 3, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon10, slot: BodyDark, size: [1, 0.125, 0.125], at: [0, 3.1875, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona10, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.5625, 3.1875, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Moon11, slot: BodyDark, size: [0.5, 0.125, 0.125], at: [0, 3.3125, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: Corona11, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 3.3125, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: CoronaTop, slot: Glow, size: [0.5, 0.125, 0.125], at: [0, 3.4375, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: CoronaBottom, slot: Glow, size: [0.5, 0.125, 0.125], at: [0, 1.8125, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875], material: crystal}
  - {name: Diamond, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 3.125, 0.1875], moves: eclipse, pivot: [0, 2.625, 0.1875], shape: ico1}
  - {name: CoronaRay0, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.75, 3.375, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875]}
  - {name: CoronaRay1, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.75, 1.875, 0.1875], mirror: x, moves: eclipse, pivot: [0, 2.625, 0.1875]}
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
  # violet blossom buds on the head's top corners
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.9375, 2.625, -0.3125], mirror: x, material: wood}
  - {name: Budb, slot: Accessory, size: [0.375, 0.125, 0.125], at: [0.9375, 2.8125, -0.3125], mirror: x}
  - {name: Budc, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.9375, 2.9375, -0.3125], mirror: x}
  # a vine winding up the lifted foreleg
  - {name: Vine0, slot: Accessory, size: [0.375, 0.125, 0.0625], at: [0.5, 0.5625, -0.28125], material: moss}
  - {name: Vine1, slot: Accessory, size: [0.0625, 0.125, 0.375], at: [0.65625, 0.6875, -0.125], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.375, 0.125, 0.0625], at: [0.5, 0.8125, 0.03125], material: moss}
  # brass sap drops hanging from the blanket's hem
  - {name: Sapa, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.9375, 1.125, 0.3125], mirror: x, material: metal}
  - {name: Sapb, slot: Trim, size: [0.25, 0.125, 0.25], at: [0.875, 1, 0.25], mirror: x, material: metal}
  - {name: Sapc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.9375, 0.875, 0.3125], mirror: x, material: crystal}
  # brass bark bands round the hind legs
  - {name: BandRF, slot: Trim, size: [0.375, 0.125, 0.0625], at: [0.5, 0.4375, 1.46875], material: wood}
  - {name: BandRB, slot: Trim, size: [0.375, 0.125, 0.0625], at: [0.5, 0.4375, 1.78125], material: wood}
  - {name: BandRR, slot: Trim, size: [0.0625, 0.125, 0.25], at: [0.65625, 0.4375, 1.625], material: wood}
  - {name: BandRL, slot: Trim, size: [0.0625, 0.125, 0.25], at: [0.34375, 0.4375, 1.625], material: wood}
  - {name: BandLF, slot: Trim, size: [0.375, 0.125, 0.0625], at: [-0.5, 0.4375, 1.46875], material: wood}
  - {name: BandLB, slot: Trim, size: [0.375, 0.125, 0.0625], at: [-0.5, 0.4375, 1.78125], material: wood}
  - {name: BandLR, slot: Trim, size: [0.0625, 0.125, 0.25], at: [-0.34375, 0.4375, 1.625], material: wood}
  - {name: BandLL, slot: Trim, size: [0.0625, 0.125, 0.25], at: [-0.65625, 0.4375, 1.625], material: wood}
  # the satellite set (`shards`, one orbit below the face): three eclipse shards, three wool tufts and two music notes
  - {name: Sat0a, slot: Glow, size: [0.25, 0.125, 0.0625], at: [0, 0.8125, -1.65625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat0b, slot: Glow, size: [0.125, 0.375, 0.0625], at: [0.0625, 1.0625, -1.65625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat0c, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.1875, 1.1875, -1.65625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat1a, slot: BodyDark, size: [0.375, 0.3125, 0.0625], at: [1.3125, 1.09375, -1.09375], rot: [0, 0, -15], moves: shards, pivot: [0, 1, 0.25]}
  - {name: Sat1b, slot: Glow, size: [0.375, 0.0625, 0.0625], at: [1.3125, 1.28125, -1.09375], rot: [0, 0, -15], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat2a, slot: BodyDark, size: [0.125, 0.375, 0.375], at: [1.9375, 1.1875, 0.25], moves: shards, pivot: [0, 1, 0.25], material: wool}
  - {name: Sat2b, slot: BodyDark, size: [0.0625, 0.375, 0.375], at: [2.03125, 1.25, 0.3125], moves: shards, pivot: [0, 1, 0.25], material: wool}
  - {name: Sat3a, slot: BodyDark, size: [0.0625, 0.3125, 0.375], at: [1.34375, 1.09375, 1.5625], rot: [15, 0, 0], moves: shards, pivot: [0, 1, 0.25]}
  - {name: Sat3b, slot: Glow, size: [0.0625, 0.0625, 0.375], at: [1.34375, 1.28125, 1.5625], rot: [15, 0, 0], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat4a, slot: Glow, size: [0.25, 0.125, 0.0625], at: [0, 0.8125, 2.15625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat4b, slot: Glow, size: [0.125, 0.375, 0.0625], at: [-0.0625, 1.0625, 2.15625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat4c, slot: Glow, size: [0.125, 0.125, 0.0625], at: [-0.1875, 1.1875, 2.15625], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat5a, slot: BodyDark, size: [0.375, 0.375, 0.125], at: [-1.3125, 0.875, 1.625], moves: shards, pivot: [0, 1, 0.25], material: wool}
  - {name: Sat5b, slot: BodyDark, size: [0.375, 0.375, 0.0625], at: [-1.375, 0.9375, 1.71875], moves: shards, pivot: [0, 1, 0.25], material: wool}
  - {name: Sat6a, slot: BodyDark, size: [0.0625, 0.3125, 0.375], at: [-1.90625, 0.78125, 0.25], rot: [-15, 0, 0], moves: shards, pivot: [0, 1, 0.25]}
  - {name: Sat6b, slot: Glow, size: [0.0625, 0.0625, 0.375], at: [-1.90625, 0.96875, 0.25], rot: [-15, 0, 0], moves: shards, pivot: [0, 1, 0.25], material: crystal}
  - {name: Sat7a, slot: BodyDark, size: [0.125, 0.375, 0.375], at: [-1.375, 0.875, -1.0625], moves: shards, pivot: [0, 1, 0.25], material: wool}
  - {name: Sat7b, slot: BodyDark, size: [0.0625, 0.375, 0.375], at: [-1.46875, 0.9375, -1.125], moves: shards, pivot: [0, 1, 0.25], material: wool}
  # the ground aura (`aura`, it breathes): twelve violet dashes in a circle round the hooves
  - {name: Aura0, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 0.03125, -1.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura1, slot: Glow, size: [0.5, 0.0625, 0.125], at: [1, 0.03125, -1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura2, slot: Glow, size: [0.125, 0.0625, 0.5], at: [1.75, 0.03125, -0.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura3, slot: Glow, size: [0.125, 0.0625, 0.5], at: [2, 0.03125, 0.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura4, slot: Glow, size: [0.125, 0.0625, 0.5], at: [1.75, 0.03125, 1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura5, slot: Glow, size: [0.5, 0.0625, 0.125], at: [1, 0.03125, 2.125], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura6, slot: Glow, size: [0.5, 0.0625, 0.125], at: [0, 0.03125, 2.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura7, slot: Glow, size: [0.5, 0.0625, 0.125], at: [-1, 0.03125, 2.125], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura8, slot: Glow, size: [0.125, 0.0625, 0.5], at: [-1.75, 0.03125, 1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura9, slot: Glow, size: [0.125, 0.0625, 0.5], at: [-2, 0.03125, 0.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura10, slot: Glow, size: [0.125, 0.0625, 0.5], at: [-1.75, 0.03125, -0.625], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
  - {name: Aura11, slot: Glow, size: [0.5, 0.0625, 0.125], at: [-1, 0.03125, -1.375], moves: aura, pivot: [0, 0.03125, 0.4], material: crystal}
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
- 2026-10-17, loop 2 worker, three rounds. Round 1: small pewter horns read as stubs and pewter pipes as a grey chimney behind the head. Round 2: bigger horns sweeping up, out and down read as branches. Round 3: ibex horns that arch back (a chain of tilted segments with a lit band, a dark ridge and lit tips), the pipes dark reeds with lit mouths and lit lips in pewter bands, the ears drooped; the preview gives it a violet ring and falling shadow smoke. Overlap 0.996 to 0.998, 1,504 triangles, 108 blocks, 13 studs. Wanted for: the one dark thing in a bright meadow, a gentle giant that plays its own organ and that you can ride. Still cheap: in daylight it is a muted purple box with a face; the beard and bell are small; the shadow wool reads as stripes on the legs from the side. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The violet flecks and the grout lift the dark coat in daylight (the open item of loop 2, partly: it is still the darkest thing on the meadow, as a Secret should be); the reeds read as reeds. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, two rounds. Round 1: rebuilt from 13 studs to 3.5 by redesign: a goat kid with a 2-stud head on a 32-column face (0.0625 cells, 56 cells tall), the ibex horns as sixteenth-stud steps with two lit bands each, a pewter circlet with a lit gem, a stepped beard and a swinging bell, a saddle with sound bars and tassels, two drifting notes, six reeds in sixteenth-stud cells; its own eyes, `echo`, a new Secret design added to the library (rings of violet rippling out of a lit core over eight frames), a smile, dim violet star cheeks. 114 blocks. The reeds across the rump, behind the head, made it a box with two horns: 0.720 against Gaira and 0.718 against Buzzik in the silhouette test. Round 2: the reeds moved a stud to the right so they rise off the right haunch, tallest at the outside (a stepped ramp beside the head from the front), and the ears grew a quarter stud: 0.675 and 0.64. Eight moving objects and the blink; a flourish every 16 s (the vanish-and-return: a hop, a sink, a full turn, the pipes popping on the trill). Overlap 0.994 to 0.998, 1,386 triangles. Wanted for: the one dark thing on the meadow, the size of a Rare, with eyes that ripple like a note from far off; a rumour beside Raddis's blaze. Still weak: the slate head is a flat plane between the circlet and the eyes; the horns read as stacked blocks more than an arch from the three-quarter view. Status review.
- 2026-10-21, Polish w1, two rounds. The flat forehead between the circlet and the eyes: a fringe of dark wool now stands an eighth proud of the forehead across the head's width, curled at its top corners and hanging in a lock beside each eye, and the pewter circlet and its lit gem sit on it, so the face steps back in three layers (gem, circlet, fringe) to the eyes and the dark fringe frames the slate face. Round 1 made the ridge in the slate body colour and it vanished; the dark wool reads. 119 blocks (Secret 110 to 200). Overlap 0.995 to 0.998. Honest read: the face now has a brow and a frame, the circlet reads as jewellery on a forelock; below the eyes the face is still one slate plane, which keeps the face calm. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: an eclipse rising behind the horns, a dark moon disc in twelve sixteenth-stud rows inside a corona of lit violet glass cells with four rays and a diamond-ring bead, Raddis's sun disk in shadow (it turns once in 20 s and turns half round on the flourish); an echo ring of lit bars over the pipes' mouths that swells like a note far away; a lit glass finger hole on each reed; the circlet's gem pulses (the Secret's one accent); the glow is a deeper violet `#9B5CFF` and the cycle with it (the lilac `#B28CFF` read pale). Round 1's disc in quarter-stud rows read as a dark slab; eighth-stud rows read round. The flourish is 4.6 s. 172 blocks, twelve moving things. Honest read: the shadow goat with an eclipse behind its horns is the Secret's answer to Raddis's sun; at a distance the dark disc can read as a chair back without its corona lit. Status review.
