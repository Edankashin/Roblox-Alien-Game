---
tags: [art-pipelines, species, design]
aliases: [Design pass, Design pass 1, Per-species design]
up: "[[Art-Pipelines]]"
---
# Design pass, batch 1: eight species get a base design of their own (prototypes, 2026-10-15)

The owner's bar for the creatures, 2026-10-15: "seamless, fluid, complete, not a bunch of shapes mashed together"; keep the goofy big eyes and the open mouth; no two aliens share a base design; each species names its world; references are inspiration, never copies. The sculpt passes ([[Sculpt-Pass]]) fixed the skin but not the shapes: eight species still read as the same round body with one prop. This note is the first batch of the per-species design pass: a new base design and a feature set of its world for each of the eight whose shape barely changed, as **`<Id>V2` prototype recipes** built with the hybrid sculpt and rendered for review.

Nothing under `assets/models/` changed, no `Species.luau` row changed, `species_sculpt.py` is untouched (every override is on the command line, listed below), and the shipped recipe keys stay. The eight new keys are `"prototype": True` in `tools/blender/species_recipes.py`, so the roster commands (`all`, `world1`, `world2`, `batchN`) skip them and the tests do not hold them to the shipped files ([[Hero-Aliens]] introduced the flag). Background: [[Silhouette-Pass]] (the rules a recipe is judged by), [[Surface-Pass]], [[Character-Pipeline]], [[Roster-Redesign]] (each species' element and signature effect, section 2, and the temperament ladder: these eight are the cute end, Common to Rare).

![Eight species: the current body, the V2 front, three-quarter and side, the 64 px shapes, triangles, overlap with the old body and with the closest other species of the world](refs/sculpt-pass/design_pass_1.jpg)

## The result in one table

Triangles from the GLB (budget 2,400, cap 2,500). Overlap is the intersection over union of the black shapes at 64 px, "plain" as `preview.py` frames them (30 degree view, `<Id>_grey.png`), "boxed" each shape cropped to its bounding box and stretched to 48 x 48 (the [[Silhouette-Pass]] check, aspect ignored). The bars: under 0.85 against the species' own old body, under 0.7 against every other species of its world (the batch's other V2s stand in for their old bodies). For scale, the hybrid rebuild of an unchanged body scored 0.85 to 0.98 against the old one (mean 0.94, [[Sculpt-Pass]], pass 2): this batch is a different shape, not a smoother one.

| Species (display name, tier, world) | What it became | Triangles (now) | Size x y z, studs | vs its old body, plain / boxed | Closest in its world, plain / boxed |
|---|---|---|---|---|---|
| `Mossbop` (Moop, Common, 1) | a crouching moss tuft with a sprout crest | 2,364 (1,680) | 3.2 x 3.4 x 2.6 | 0.64 / 0.59 | Snailbyte 0.66 / 0.65 |
| `Glimmo` (Glim, Common, 1) | a jelly firefly with a lantern abdomen and wings | 2,344 (1,256) | 2.6 x 1.9 x 2.7 | 0.39 / 0.30 | Gloomoth 0.64 / 0.55 |
| `Puffpuff` (Dandel, Common, 1) | a cloud puff with seed-ray wings and a stem tail | 2,328 (1,640) | 3.1 x 1.5 x 2.2 | 0.42 / 0.55 | Gloomoth 0.61 / 0.59 |
| `Drippo` (Dreep, Common, 2) | an icicle imp with a drip crown and mitt hands | 2,332 (1,350) | 2.9 x 2.2 x 2.1 | 0.50 / 0.44 | Kettlepuff V2 0.55 / 0.53 |
| `Kettlepuff` (Kettlet, Common, 2) | a pear-bellied steam critter with a spout snout and a lid hat | 2,362 (1,476) | 2.7 x 3.5 x 2.2 | 0.49 / 0.51 | Shellberg 0.62 / 0.57 |
| `Flufflet` (Mitt, Common, 2) | a mitten-eared snow pup with a scarf | 2,328 (1,564) | 3.1 x 3.0 x 2.6 | 0.53 / 0.52 | Pengoo V2 0.57 / 0.63 |
| `Capybubble` (Snorzo, Rare, 2) | a loafing capybara with a bubble crown | 2,346 (1,762) | 1.9 x 4.1 x 3.0 | 0.48 / 0.45 | Shellberg 0.58 / 0.61 |
| `Pengoo` (Pengoo, Uncommon, 2) | an upright tux penguin with flipper arms and a tiny backpack | 2,336 (1,486) | 3.2 x 2.1 x 2.0 | 0.59 / 0.56 | Shimmerlynx 0.47 / 0.65 |

All eight are under 0.85 against the old body (0.30 to 0.64) and under 0.7 against every neighbour (the highest pair that involves a V2, plain or boxed, is Mossbop and Snailbyte at 0.66 / 0.65, then Pengoo and Shimmerlynx at 0.47 / 0.65). The heights are the heights in each species' `notes.md` (the builder fits the mesh, a scale of 0.78 to 1.05), every model rests on z = 0, and every one has all of its slots (Body, BodyDark, Accessory, Belly for Pengoo, and the four face slots). Black pixels at 64 px (of 4,096): 703 to 1,216. Build time 5 to 20 s a species on a busy shared machine.

## The eight: brief, recipe, what is left for the effect

Each recipe keeps its species' height, slot list, palette and glow (the tests check this, so a later swap into `assets/models/` changes the shape and nothing else) and gives it a new silhouette line and hero line in its recipe. Facing -Y, feet on z = 0, as everywhere in the recipe file. The face stays the owner's: `eye_scale` 1.15 to 1.6 (the hybrid grows it by 1.35), an open mouth (`o` or `wide`), a pupil look and a tilt that make it goofy and never fierce. A pose with life means asymmetry: a raised arm or paw, a lean, a tail off the centre line.

**Mossbop (Moop), World 1 Verdant, Bloom: "one sprout on the top of its head unfurls over 1 s every 6 s".** Was: a round mound with seven moss clumps and a sprout. Now: a crouching moss tuft. A pale face sits low in front of an arched back, a dark moss mat lies over the ridge of the back with a crest of three sprouts growing out of it (a stalk and two round seed leaves each), the middle one the tallest and carrying the orange bud; one stubby arm planted, one raised in a wave, a tail tuft, two dark feet. The head and the body are two overlapping balls the hybrid fuses into one skin, the mat a flat ellipsoid, the sprouts crisp. Effect room: the tallest sprout is the unfurl target; it is part of the fused mesh, so the effect either tweens the whole crest or the sprout is split out as its own part in the import step.

**Glimmo (Glim), World 1 Verdant, Light: "its belly blinks brighter for 0.5 s every 3 s like a firefly".** Was: a drooping bell on a skirt of tendrils with a lamp on a stalk. Now: a jelly firefly hovering and leaning: a big glassy head over a small thorax, two long amber wings swept out and back (one longer: asymmetry), two long antennae with bobbles that curl outward, and the lantern abdomen hanging under it, swung to one side, with a cap, a bottom cap and a tassel. The lantern is the only `Accessory` (glow 3.0), so the belly blink is one material emission tween. The wings are flat ellipsoids 0.05 thick (the first version at 0.4 wide read as horns from the front; 0.52 to 0.56 reads as wings).

**Puffpuff (Dandel), World 1 Verdant, Wind: "one seed lifts off the puff and floats away every 5 s".** Was: a ball ringed by twenty wisps. Now: a fluffy cloud of a ball (eight overlapping fluff balls on the body) on two leaf feet, a green stem curling out to one side as a tail with a pair of seedling leaves at its tip, and two wings raised in a V that are fans of five white rays each, every ray tipped with a yellow seed (ten seeds, the `Accessory`). A starburst became a bird-like silhouette with a tail. Effect room: the seeds are the lift-off candidates; the tail tip is clear for a second effect.

**Drippo (Dreep), World 2 Frostbyte, Water: "one drop falls from its tip every 3 s and lands with a tiny ring".** Was: a pear with a pointed top in a knitted cap (the cap is gone) and a drop beside it. Now: an icicle imp. A round head tapers into a long hanging icicle that ends in a fat drop about to fall (the resting drop is the spawn point of the falling-drop effect: the first version ended in a point on the ground, with nowhere for a drop to fall from), a coral crown (a circlet with six ice drips tipped with beads) on the head, pointed ice ears, two big mitts floating at its sides at different heights (one raised, with thumbs) and a pointed imp tail. The icicle and the tail are `sweep` tubes in the core, so the head runs into the icicle as one skin.

**Kettlepuff (Kettlet), World 2 Frostbyte, Steam: "a steam puff from the spout every 4 s".** Was: a squat kettle on its side with a long spout, a handle ring and a ring of six steam puffs. Now: a round-bellied steam critter: a pear of a body (a broad belly under a narrower chest that carries the face) on two stubby feet, a stout copper spout for a snout curling up from the right cheek, clear of the eyes and the open mouth, two puffs of steam above it, a tilted grey lid for a hat with a knob and a rim, one stubby arm waving, and a smaller handle looped behind like a tail. The first version (a long pipe in the middle of the face, a handle ring twice the size of the body) read as a pipe in a mouth and a hula hoop; the cheek spout and the small handle fixed both. Effect room: the spout tip. The two static steam puffs are `EyeWhite`-slot spheres in the mesh; drop them when the particle exists.

**Flufflet (Mitt), World 2 Frostbyte, Frost: "a snowflake lands on its head every 6 s and melts away over 1 s".** Was: a tall snowball with a scarf, one streamer and two mitten ears. Now: a snow pup. A snowball head on a snowball body (a snowman stack with puppy legs), two big knitted mitten ears held out sideways with their thumbs up, a coral scarf round the neck (a ring across the join of head and body, so it is a scarf and not a belt) with its streamer whipping back to the left as one ribbon, one front paw raised, a curled tail, four paws. The top of the head, between the mittens, is free for the snowflake.

**Capybubble (Snorzo), World 2 Frostbyte, Water: "snore bubbles rise from its nose, three every 4 s".** Was: a barrel-shaped lump with a tangerine and a string of bubbles. Now: a capybara loafing flat as a loaf: a long low barrel (1.9 wide, 4.1 long, 3.0 high with the crown), a heavy head with a blunt boxy muzzle and a dark nose, small round ears, four stubby feet, and a crown of seven soap bubbles round a tangerine on its head with a column of three bubbles growing as they rise. The nose is free for the snore bubbles; the crown column is static (the effect bubbles come from the nose).

**Pengoo, World 2 Frostbyte, Frost: "a snow spray behind it while it belly-slides".** Was: a plump penguin lying flat on its belly mid-slide. Now: an upright round tux penguin leaning to one side: an egg of a body with a white belly shield, a small orange beak above the open mouth, two paddle flipper arms (one up in a wave), orange webbed feet, a tail wedge and a tiny orange backpack with a flap. It stands where the old one lay, which is the point of the redesign; the slide is still an animation. The goggles glint of the roster row is not modelled (no goggles on this body); the spray comes from behind the tail.

## How it is built

From the repo root; `$S` is any scratch folder; the interpreter is a Python with the `bpy` 5.0 module. `species_sculpt.py` refuses `assets/models`, so each species is copied to `$S/models/<Id>V2` with its `materials.json` and `notes.md` (the builder rewrites the Triangles, Height and Sculpt-pass lines of the notes) and a base GLB with one flat material per slot of the `materials.json` (the `base_glb.py` snippet of [[Hero-Aliens]], "How it is built").

```
S=/tmp/design1
for id in Mossbop Glimmo Puffpuff Drippo Kettlepuff Flufflet Capybubble Pengoo; do
  mkdir -p $S/models/${id}V2
  cp assets/models/$id/materials.json $S/models/${id}V2/materials.json
  sed "s/$id/${id}V2/g" assets/models/$id/notes.md > $S/models/${id}V2/notes.md
done
python3 base_glb.py $S/models MossbopV2,GlimmoV2,PuffpuffV2,DrippoV2,KettlepuffV2,FluffletV2,CapybubbleV2,PengooV2
SC="python3 tools/blender/species_sculpt.py --models $S/models --method hybrid"
COMMON="--set stiff=4 --set stiff_thin=4 --set crisp_detail=1.0"
$SC --species MossbopV2 $COMMON --set bevel_segments=0
$SC --species GlimmoV2 $COMMON --set bevel_segments=0 --set 'crisp=["lantern","cap","tassel","wing","antenna","antennatip"]'
$SC --species PuffpuffV2 $COMMON --set bevel_segments=0 --set res=0.03
$SC --species DrippoV2 $COMMON --set bevel_segments=0 --set res=0.03 --set 'crisp=["mitt","thumb","band","drip","bead","ear","tailtip"]'
$SC --species KettlepuffV2 $COMMON --set bevel_segments=0 --set 'crisp=["spout","lip","puff","rim","knob","handle"]'
RIB=$(python3 -c 'import importlib.util as u, json; s = u.spec_from_file_location("r", "tools/blender/species_recipes.py"); m = u.module_from_spec(s); s.loader.exec_module(m); print(json.dumps(m.RECIPES["FluffletV2"]["ribbons"], separators=(",", ":")))')
$SC --species FluffletV2 --set stiff=3.5 --set stiff_thin=4 --set crisp_detail=1.0 --set res=0.03 --set bevel_segments=0 \
  --set 'crisp=["scarf","knot","mitten","thumb"]' --set 'no_fillet=["scarf","knot"]' --set "ribbons=$RIB"
$SC --species CapybubbleV2 $COMMON --set bevel_segments=0 --set 'crisp=["tangerine","calyx","bubble"]'
$SC --species PengooV2 $COMMON --set bevel_segments=2
python3 tools/blender/preview.py --models $S/models --species MossbopV2,GlimmoV2,PuffpuffV2,DrippoV2,KettlepuffV2,FluffletV2,CapybubbleV2,PengooV2   # the 64 px shapes
python3 tools/blender/preview.py --lit --models $S/models --species DrippoV2 --backdrop A9C7E6 --out $S/lit                                       # one lit view, 30 degrees
```

These command lines were run from a clean scratch folder after the last recipe edit and gave the triangle counts in the table above, to the triangle (the build is deterministic). The overrides, and why each was needed:

- **`stiff=4`, `stiff_thin=4`** (Flufflet 3.5): the metaball stiffness of the body volumes and of the chains (rods, cones, `sweep` tubes); both default to 3.0, and a higher number is a tighter blend, so the head stays a head on its body and a stem stays a stem. **`res=0.03`** (Puffpuff, Drippo, Flufflet): a finer polygonizer cell (the default is 0.04, the smallest feature about two cells) for the species with thin core tubes (the stem, the icicle's neck of 0.08 radius, the pup's tail); the build takes 5 to 20 s. **`crisp_detail=1.0`**: a crisp cone gets the recipe's own side count and not 1.5 times it. **`bevel_segments=0`**: no bevel on crisp cubes and cylinders (the default is 3 segments, which put 84 to 92 triangles on a 0.2 stud part in the hero builds); Pengoo keeps a 2-segment bevel for its backpack and flap, the only cubes of the batch.
- **`crisp=[...]`** names the parts the hybrid builds as crisp shapes on top of the skin (a part whose name is not listed and is not an `Accessory` or `Trim` is core and fuses into the skin). The lists are what the recipe calls its parts: the lantern, its caps, tassel, wings and antennae (Glimmo); the mitts, thumbs, the crown band, the drips and beads, the ears and the tail tip (Drippo; the head, icicle and tail tube are core); the spout, its lip, the steam, the lid rim, the knob and the handle (Kettlepuff); the scarf, the knot, the mittens and thumbs (Flufflet); the tangerine, its calyx and the bubbles (Capybubble). Mossbop, Puffpuff and Pengoo need no list (their accessories are the default crisp set).
- **`no_fillet=["scarf","knot"]`**: clothing sits on the skin with a line, not a swelling (the same choice as in [[Sculpt-Pass]]).
- **`ribbons=<json>`**: the scarf streamer is one continuous band (`ribbon_object` in the sculpt). The band's data (`pts`, `widths`, `thick`, `slot`, `name`) lives in the recipe next to the steps as `"ribbons"` (so it is versioned with the shape, and `expand` ignores it), and the build command passes it as the JSON above.

The review views are the scratch wrapper described in [[Hero-Aliens]] ("The review views"): `preview.py`'s own `lit_scene`, `surface_variant` and lights, the model turned about z under an empty so the camera and the sun stay put (front = the camera at yaw 0, three-quarter = the 30 degree view `preview.py --lit` writes, side = 90 degrees), 420 px, 40 samples, the slot colours of `materials.json`, the blue backdrop `A9C7E6` under white and pale species (and the cream default under the green and yellow ones), every view of one species framed by the same length (the longer of its two bodies' longest sides) so the old body and the V2 are to scale. The overlaps come from a 60-line scratch script that reads `preview.py`'s `<Id>_grey.png` (64 x 64 by box filter, black under 153 of 255) and takes the intersection over union, plain and boxed; the sheet is a 150-line scratch Pillow script (Liberation Sans; 1,752 x 2,086 px, 325 KB: the JPEG quality is lowered until the file is under 450 KB). Neither script is in the repo; promoting them with a `--yaw` option on `preview.py` is the first item of "Next" below.

## What still reads as assembled

The V2s are better single skins than the old bodies (the head, body, tail, icicle, stem and loaf are one fused surface; the ears, the crown, the lid and the scarf grow out of a swelling or sit on a clean line), but the recipe route still builds a creature out of parts:

- **Mossbop**: the moss mat is a flat slab on the back and the sprouts are crisp shells standing on it, a plant on a plinth more than moss growing out of the skin; the paws on the arms are balls on tubes.
- **Glimmo**: the lantern is a crisp ball hung under the thorax (a bulb glued on); the three-rod antennae show their kinks; the wings are flat shells, thin from the front.
- **Puffpuff**: ten rods and ten yellow nuggets (6-sided spheres look like boxes at 64 px) in two fans; the fluff balls make a lumpy cloud, not feathers; the seed wings are rigid.
- **Drippo**: the mitts float with no arms (a Rayman convention, but they read detached when still); the crown sits on the head as a ring with a crease; the hanging drop at the icicle tip is small and almost invisible below 200 px.
- **Kettlepuff**: the spout is three straight rods and a ring (visible kinks), the handle a torus clipped through the back, the lid a flat ball and a ring; the steam puffs are static spheres. The most assembled of the eight; its charm is the silhouette.
- **Flufflet**: the mittens and thumbs are flat shells on the head, the scarf ring and knot are crisp (a garment line, deliberate), the streamer is a ribbon shell with a flat end; the mitten ears can still read as horns from the front.
- **Capybubble**: the bubbles are 6-sided crisp spheres (little boxes), the ears are tiny stubs, the loaf is a stretched ball (a sausage) with a head; the bubble crown hides the top of the head from the front.
- **Pengoo**: the backpack is a box with a flap standing above the back like a chimney, the most assembled part of the batch; the flippers are flat ellipsoids set on the shoulder (a paddle, with no joint); the beak is a small cone.

## What the recipe system could not do

- **A curved crisp tube.** A crisp part is a straight rod, a cone, a torus or a ball. A spout, an antenna or a handle is a chain of rods with kinks. `sweep` bends, but only in `Body` or `BodyDark` (the core), so a coloured `Accessory` tube (the copper spout, a gold horn) cannot be smooth.
- **A hollow shape or a cut.** There is no cylinder with a hole or a boolean cut in a recipe: the Drippo crown is a torus ring plus cones, the kettle lid a flat ball plus a ring.
- **A ribbon that turns or lies flat.** `ribbon_object` always stands the broad face upright, so a scarf streamer is a vertical wall, edge-on from the wrong side, and it only reaches the build through `--set ribbons=<json>` (no step type). The ring that wraps the neck is a torus tilted by hand to the head-body axis.
- **A part that moves.** The sprout, the seed, the drop, the steam and the lantern are fused into one MeshPart. An effect that moves or hides a part needs the part split out in the import step (or a bone); there is no "detach" flag in a recipe.
- **A face placed where the design wants it.** The mouth lands where the face host's normal meets the skin; a spout or a muzzle in front of the face covers it. Kettlepuff's first spout hid the mouth, and the fix was moving the spout, not the mouth ([[Hero-Aliens]] has the same finding).
- **Triangle bands per tier.** The sculpt's own budget is 2,400 to 2,500 with the crisp parts costing 540 to 830 of it (a Common's ladder band in [[Roster-Redesign]] is 1,000 to 1,400, the checker's guide 1,800). Each V2 is 2,330 to 2,360. A test build of the eight at `--set tris=1800` (the same overrides) gave 1,750 to 1,910 triangles by halving the skin (700 to 800 triangles) and raising the mean faceting (the build log's first number) by 3 to 5 degrees; side by side with the 2,400 builds at 300 px in the three-quarter view the shapes, faces and crisp parts hold and only the mouth outline and the body's silhouette turn slightly more angular, so the lower band is a decision, not a limit. Left for the coordinator and the owner.

## Next batch

The pairs of the roster by 64 px overlap, with the batch's V2s standing in for their old bodies (`pairs.py`, a scratch script over the same shapes), say which species are still alike: Pebblet and Zapfinch (0.64 plain, 0.78 boxed), Snailbyte and Thunderhog (0.73 plain), Snailbyte and Buzzlebee (0.61 / 0.72), Radish with Gloomoth and Thunderhog, Shimmerlynx with Frostfang (0.54 / 0.72), Flapsicle with Emberchin (0.68 / 0.70), Shellberg with Toastoad and Shimmerlynx. The Haunted Nebula event species (Spookum, Wisplet, Nebulyn) sit close to Thunderhog, Snailbyte and Radish but are built by `event_species.py` and are left for their own pass.

- **Batch 2, the middle of the ladder (Uncommon to Epic, cool with a goofy face):** Pebblet, Zapfinch, Snailbyte, Radish and Thunderhog (World 1), Shimmerlynx, Frostfang and Flapsicle (World 2).
- **Batch 3:** Buzzlebee, Gloomoth, Lanternewt and Twiglet (World 1), Shellberg, Emberchin, Toastoad and Chipmole (World 2).
- **Batch 4, the rest:** Sparkfox, Rocklobber, Gaiabloom and Panpipe (World 1), Snowbun, Reindazzle and Skaddle (World 2); Fenripup is taken by the hero Fenrir ([[Hero-Aliens]]).
- **Before either:** promote the scratch review tools to the repo (a `--yaw` option on `preview.py` for the three views and a `design_sheet.py` with the overlap and the sheet), so a batch is one command and not a re-write of three scripts; decide the triangle band per tier (the ladder's or the pass's 2,400); take the owner's look at the sheet (which of the eight to take as is, which to redo, which feature to keep); then swap the chosen V2s into `assets/models/` (a recipe replaces its shipped key, the model folder is rebuilt, `model_assets.py --write`, the import skill) and split the effect parts out where the signature effect needs them.

## What changed in the repo

- `tools/blender/species_recipes.py`: between the `DESIGN PASS 1 BEGIN` and `DESIGN PASS 1 END` markers, the eight `<Id>V2` recipes (all `"prototype": True`, `"batch": 0`), the helper `_leaf` (a flat ellipsoid: a wing, a mitten, a flipper, a sprout leaf) and the optional `"ribbons"` key; the docstring says so.
- `tools/tests/test_species_recipes.py`: a `DesignPassPrototypes` class (the eight exist and are prototypes of real species; each keeps its species' tier, world, height, slots, palette and glow; the group ids skip them and a name picks them; they pass the checker apart from its notes; the face host is on the centre line, the mouth is open and the eyes are at least the base size; a sweep stays in a core slot and a ribbon carries a width per point; only the `Accessory` glows) and a narrower `HeroPrototypes` filter.
- `docs/vault/06-art-pipelines/refs/sculpt-pass/design_pass_1.jpg` (the sheet) with a copy in `media/studio/2026-10-15/`; this note, linked from [[Art-Pipelines]] and [[Character-Pipeline]].
