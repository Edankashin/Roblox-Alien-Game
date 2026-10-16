---
tags: [art-pipelines, species, design]
aliases: [Design pass, Design pass 1, Design pass 2, Per-species design]
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

The review views are the scratch wrapper described in [[Hero-Aliens]] ("The review views"): `preview.py`'s own `lit_scene`, `surface_variant` and lights, the model turned about z under an empty so the camera and the sun stay put (front = the camera at yaw 0, three-quarter = the 30 degree view `preview.py --lit` writes, side = 90 degrees), 420 px, 40 samples, the slot colours of `materials.json`, the blue backdrop `A9C7E6` under white and pale species (and the cream default under the green and yellow ones), every view of one species framed by the same length (the longer of its two bodies' longest sides) so the old body and the V2 are to scale. The overlaps come from a 60-line scratch script that reads `preview.py`'s `<Id>_grey.png` (64 x 64 by box filter, black under 153 of 255) and takes the intersection over union, plain and boxed; the sheet is a 150-line scratch Pillow script (Liberation Sans; 1,752 x 2,086 px, 325 KB: the JPEG quality is lowered until the file is under 450 KB). Neither script was in the repo for batch 1; batch 2 promoted them (`review_views.py`, `overlap.py`, `design_sheet.py`, below).

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

- **Batch 2, the middle of the ladder (Uncommon to Epic, cool with a goofy face)** (run instead on the rare end, see batch 2 below; the species not taken there moved to its batch 3 and 4): Pebblet, Zapfinch, Snailbyte, Radish and Thunderhog (World 1), Shimmerlynx, Frostfang and Flapsicle (World 2).
- **Batch 3:** Buzzlebee, Gloomoth, Lanternewt and Twiglet (World 1), Shellberg, Emberchin, Toastoad and Chipmole (World 2).
- **Batch 4, the rest:** Sparkfox, Rocklobber, Gaiabloom and Panpipe (World 1), Snowbun, Reindazzle and Skaddle (World 2); Fenripup is taken by the hero Fenrir ([[Hero-Aliens]]).
- **Before either:** (the review tools are in the repo now, see batch 2); decide the triangle band per tier (the ladder's or the pass's 2,400); take the owner's look at the sheet (which of the eight to take as is, which to redo, which feature to keep); then swap the chosen V2s into `assets/models/` (a recipe replaces its shipped key, the model folder is rebuilt, `model_assets.py --write`, the import skill) and split the effect parts out where the signature effect needs them.

## What changed in the repo

- `tools/blender/species_recipes.py`: between the `DESIGN PASS 1 BEGIN` and `DESIGN PASS 1 END` markers, the eight `<Id>V2` recipes (all `"prototype": True`, `"batch": 0`), the helper `_leaf` (a flat ellipsoid: a wing, a mitten, a flipper, a sprout leaf) and the optional `"ribbons"` key; the docstring says so.
- `tools/tests/test_species_recipes.py`: a `DesignPassPrototypes` class (the eight exist and are prototypes of real species; each keeps its species' tier, world, height, slots, palette and glow; the group ids skip them and a name picks them; they pass the checker apart from its notes; the face host is on the centre line, the mouth is open and the eyes are at least the base size; a sweep stays in a core slot and a ribbon carries a width per point; only the `Accessory` glows) and a narrower `HeroPrototypes` filter.
- `docs/vault/06-art-pipelines/refs/sculpt-pass/design_pass_1.jpg` (the sheet) with a copy in `media/studio/2026-10-15/`; this note, linked from [[Art-Pipelines]] and [[Character-Pipeline]].


# Design pass, batch 2: the rarer bodies (prototypes, 2026-10-15)

Ethan's direction for this batch: rarer aliens are fiercer or more spectacular, not cute, and nothing has grain. Batch 1 (above) was the cute end of the ladder. The temperament ladder of [[Roster-Redesign]] had already given the Rare to Legendary species a fierce, cool or spectacular face ([[Sculpt-Pass]], "Temperament moods"), but under those faces eight of them were still the round cute body. This batch gives those eight a body that carries the mood: Thunderhog (Voltus), Frostfang (Sabrek), Skaddle (Skadra), Gloomoth (Iridia), Shimmerlynx (Aurelyx), Reindazzle (Blinkar), Rocklobber (Boulden) and Gaiabloom (Gaira). It takes the second slot of the plan in batch 1's "Next batch" above, which had the middle of the ladder second: the direction put the rare end first, and the middle moves down.

The rules are batch 1's. Nothing under `assets/models/` changed, no `Species.luau` row changed, `species_sculpt.py` is untouched, the eight `<Id>V2` keys are `"prototype": True` recipes (between the `DESIGN PASS 2 BEGIN` and `END` markers in `tools/blender/species_recipes.py`) and the roster commands skip them. One difference: the V2 keys are not in the sculpt's `SPECIES` table, so the mood comes from the command line (`--set face.mood=<mood>`), and the recipe's own face dict sits at the mood's floor (tilt, lid, big eyes) so the V2 reads the same without the flag; a test holds that.

No grain: every body is the flat colour of its `materials.json` slot, built with `--method hybrid` and the smooth defaults of [[Surface-Pass]] ("No grain"). The review views load no texture maps at all. Three species keep the `ice` map on a slot (Frostfang, Skaddle, Reindazzle: large smooth cells with frost lines, on the allowlist), which the sheet does not show and an import would.

![Eight rarer species: the current body, the V2 front, three-quarter and side, the 64 px shapes, triangles, overlap with the old body and with the closest other species of the world](refs/sculpt-pass/design_pass_2.jpg)

## The result in one table (batch 2)

The verdicts are the builder's, for Ethan's look: **take** = ready to swap into `assets/models/` once Ethan has seen it; **fix** = the shape is right and one part needs redoing; **redo** = keep the idea, start the body again. The effect column is the species' signature effect from [[Roster-Redesign]], section 2, and what the V2 gives it to hang on.

| Species (name, tier, world) | Was | Now | Verdict | What the effect layer will add |
|---|---|---|---|---|
| `Thunderhog` (Voltus, Epic, 1) | a violet ball in a dark collar ring with a yellow quill crest (the hedgehog of the concept) | a low forward-leaning storm boar: heavy shoulders with magenta spikes, a head carried low between two curved tusks, thick forelegs on clawed paws, a mane of eighteen zigzag gold quills swept back, a bolt for a tail | **take**: a storm beast from every side; the best crest of the batch | arcs between two quills every 2 s and sparks off the tips (the quills are the gold `Accessory`, glow 2.0), a violet glow and light, the crest bristling at each arc |
| `Frostfang` (Sabrek, Epic, 2) | a round blue cub in a purple scarf, a few ice spikes, two small fangs | a sabre-tooth cat: high heavy shoulders, a slung chest, a back sloping to short hind legs, a big low head with two long icicle fangs over a grin, a frost mane of 22 ice spikes in two rings, purple claws, a tufted tail | **take**: the clearest read of the batch, in all three views; the cub is gone | frost breath from between the fangs every 3 s, a sneeze burst of 20 snowflakes every 12 s, the fangs glow ice-blue (the fangs and the mane share the `Accessory` slot, so the mane glows with them), a blue glow and light |
| `Skaddle` (Skadra, Legendary, 2) | a white owl ball with a gold halo ring, tiny skis and poles | a lean winter hunter mid-glide on two gold skate blades (one leg bent under, one trailing), leaning forward under a narrow head with swept ear tufts, one wing-arm forward and one swept back in ice-blade feathers, a blade-ring halo (a gold ring with fourteen ice blades) behind the head, a long scarf whipping back | **fix**: keep the glide, the halo and the scarf, rebuild the body; the pose is the most alive of the batch but the body is a thin pale humanoid on stick limbs and the owl is gone | a flurry round it, two frost trails from the skate blades, a ground ring, the halo turning (it has to be split out), the gust flourish that lifts it 0.5 studs |
| `Gloomoth` (Iridia, Epic, 1) | a plump purple fuzzball with a bun head and two small crystal wings | a slender night moth on four thin legs: a small head, a tall thorax in a fuzzy collar, a tapering abdomen with jewels, four wings spread wide (two big fore-wings, two smaller hind-wings, each a dark membrane under a fan of glass panes), plumed antennae, a jewel on its chest | **fix**: the moth reads at once from the front; the wings are sheets a few hundredths of a stud thick, so the side view is a sliver, and the small head carries a small face | a rainbow glint sweeping the wing panes every 3 s (the panes are the glowing `Accessory`), dust falling at 8 a second, a hover of 0.3 studs with a 12 degree flap (the wings have to be split out) |
| `Shimmerlynx` (Aurelyx, Epic, 2) | a seated lavender cat in a purple ruff with a cyan crest | a long lean lynx on four legs, the head high on a neck between tall dark-tufted ears, a magenta cheek ruff, a bobbed tail, one front paw raised, an aurora crest of three waving glass ribbons streaming back from a crown gem | **redo** the pose, keep the crest: the plainest body of the batch (a lavender quadruped), the raised paw reads as a ball held up, and from the front the crest is three slivers; from the side it is the best thing here | the aurora ribbon waving and the light cycling the aurora colours over 6 s (the ribbons are already modelled, 4 to 5 studs long, so the effect colours and sways them and the 2 stud Beam of the roster is not needed), motes rising at 5 a second from the crown gem |
| `Reindazzle` (Blinkar, Rare, 2) | a round pale pony shape with a grey spiky crest and a glowing nose | a lean stately reindeer on four long slim legs, a long neck, a high head with the big glowing nose, a very wide crown of icicle antlers (a main beam with a brow tine and three rising tines on each side, growing out of the skull as one skin) | **take**: an unmistakable silhouette (0.44 / 0.41 against the old body); the body under the antlers is the plainest part | the nose blinking red every 2 s (the nose is the only `Accessory`, so it is one emission tween), a glint on the antler tips every 4 s (the antlers are `BodyDark` and do not glow: a sparkle, not a tween), soft white light |
| `Rocklobber` (Boulden, Rare, 1) | a red ball of a crab with one big boulder fist and a small one | a wide low cave crab: a scowl and four teeth on its body, a faceted stone shell crowned with amber crystals, six jointed legs planted wide with the knees up, two faceted boulder fists held high on thick bent arms, each with a smaller stone for the other jaw and amber crystals on the knuckles | **take**: a crab at a glance from the front, and fierce; the legs are thin rods and from the side it reads as a spider under a rock pile | the claws clacking together every 5 s with a dust puff and two pebble chips (the fists are held apart, so the puff sits between them or the fists are split out), a soft stone-grey light, a side shuffle |
| `Gaiabloom` (Gaira, Legendary, 1) | a short green deer with branch antlers, a gold halo ring and a gold ground ring | a tall proud stag on long slim legs (one forefoot lifted), a deep chest under a bark-brown ruff, a long swan neck, a gold nimbus behind the head, tree antlers in pink bloom (a trunk with a brow tine, two side branches and an inner branch), on a patch of lawn ringed with twelve pink flowers | **take** as the spectacular one; also the most assembled of the eight | a flower blooming in each footprint, petals orbiting the antlers at 1 stud, a ground ring of grass and light (it doubles the lawn's flower ring: drop the static ring when the particle exists), the flourish shaking the antlers |

Triangles from the GLB (budget 2,400, cap 2,500), size x y z in studs, and the overlaps as in batch 1 (intersection over union of the 64 px black shapes, plain and boxed; the bars are under 0.85 against the old body and under 0.7 against every other species of the world, with batch 1's V2s standing in for their old bodies).

| Species | Mood | Triangles (now) | Size x y z, studs | vs its old body, plain / boxed | Closest in its world, plain / boxed |
|---|---|---|---|---|---|
| `Thunderhog` | fierce | 2,368 (1,856) | 2.8 x 5.2 x 3.4 | 0.69 / 0.67 | Spookum 0.35 / 0.68 |
| `Frostfang` | fierce | 2,184 (1,548) | 3.1 x 5.4 x 3.4 | 0.39 / 0.58 | Shellberg 0.55 / 0.69 |
| `Skaddle` | fierce | 2,339 (1,422) | 3.6 x 4.4 x 4.0 | 0.38 / 0.41 | Pengoo V2 0.43 / 0.49 |
| `Gloomoth` | cool | 2,364 (1,264) | 3.7 x 1.7 x 2.6 | 0.57 / 0.70 | Sparkfox 0.51 / 0.64 |
| `Shimmerlynx` | cool | 2,356 (1,674) | 2.0 x 4.4 x 3.8 | 0.53 / 0.59 | Toastoad 0.50 / 0.62 |
| `Reindazzle` | cool | 2,326 (1,444) | 3.3 x 3.7 x 3.7 | 0.44 / 0.41 | Pengoo V2 0.51 / 0.45 |
| `Rocklobber` | fierce | 2,192 (1,196) | 3.9 x 2.2 x 2.4 | 0.58 / 0.63 | Gloomoth V2 0.58 / 0.56 |
| `Gaiabloom` | spectacular | 2,384 (2,136) | 2.8 x 3.3 x 4.2 | 0.38 / 0.46 | Sparkfox 0.38 / 0.51 |

All eight are under 0.85 against the old body (0.38 to 0.70) and under 0.7 against every neighbour. The two closest pairs are Frostfang with Shellberg (0.55 / 0.69) and Thunderhog with Spookum, the Haunted Nebula pumpkin (0.35 / 0.68); The highest against an old body are Gloomoth (0.57 / 0.70) and Thunderhog (0.69 / 0.67), the two whose new body keeps the plan of the old one (a body with a wing out each side, a long low body with a crest along the back); both are far under the 0.85 bar. Heights are the heights in each species' `notes.md`, every model rests on z = 0 (read from the GLB), and every one has all its slots (no `Trim` on Reindazzle and Rocklobber, which have none; the test checks this). Build time 3 to 10 s a species on a busy shared machine.

The triangles are over the tier's ladder band ([[Roster-Redesign]]: Rare 1,400 to 1,900, Epic 1,700 to 2,200, Legendary 2,000 to 2,500) for five of the eight, by 156 to 426: Thunderhog, Gloomoth and Shimmerlynx (Epic), Reindazzle and Rocklobber (Rare). Frostfang, Skaddle and Gaiabloom are inside their band. The pass builds at the sculpt's 2,400, as batch 1 did; whether a Rare gets 1,900 is the same open decision, and the lower-band test of batch 1 (`--set tris=1800`) was not repeated for this batch.

## The eight: what the recipe does (batch 2)

Facing -Y, feet on z = 0, the species' height, slot list, palette and glow kept (the tests check them). The face stays the owner's: big eyes (`eye_scale` 1.15 to 1.7, which the hybrid grows by 1.35), the mood's brow, narrowed socket and teeth made as geometry by the sculpt.

- **Thunderhog**: a chest, a waist and a rump ball with a pair of shoulder balls make a wedge that is high at the shoulders and falls away to the rump, and a head ball is carried low; thick forelegs with dark paws and six blade claws a side (three a paw), two spikes on each shoulder, a dark mane ellipsoid along the back and, out of it, eighteen quills, each a three-cone zigzag (`_zig`, a flat-shaded bolt) that sweeps back and lies flatter toward the rump. The tusks are a rod and a spike. The quills, the claws and the tail bolt are joined as shells (`shell`, no union with the skin).
- **Frostfang**: the same wedge: the withers are the high point (2.35 studs before the build's fit) and the hips drop to 1.6. The mane is two rings of eleven flat-shaded spikes round the neck, swept back and out, wider than the shoulders; the fangs are two long spikes from the upper jaw; three dark stripes on each flank, claws, a tail sweep with two tufts.
- **Skaddle**: the torso is a tilted ellipsoid under a hawk head with two ear tufts, the legs are rod pairs ending in boots on flat gold blades (the skate is a thin cube and a rod for the curled tip), the wing-arms are two `sweep` tubes with nine blade feathers along them, the halo is a tilted `Trim` torus with fourteen ice blades on it, and the scarf is one ribbon (`ribbons`) leaving a knot at the neck.
- **Gloomoth**: a thin standing moth: head ball, tall thorax, a `sweep` abdomen, four legs, two antennae as `sweep` tubes with eight plume blades each, three jewels in `Trim`. Each wing is a flat faceted membrane (`BodyDark`) with a fan of five (fore) or four (hind) glass panes on it, mirrored, the panes reaching past the rim so the edge is a row of crystal points.
- **Shimmerlynx**: a three-ball trunk on four tube legs with the head on a neck rod, ears with dark tufts, a cheek ruff of four magenta spikes, one front paw raised on a bent two-rod arm, and three aurora ribbons (`ribbons`, 18 points each, of different lengths and phases) leaving a glowing crown gem between the ears.
- **Reindazzle**: a narrow three-ball body on four rod legs, a neck rod and a small head with a nose sphere (the `Accessory`); the antlers are ten `sweep` tubes in `BodyDark` (core, so they grow out of the skull as one skin), mirrored. It has the largest eye of the batch (`eye_scale` 1.7).
- **Rocklobber**: a flat ball for a body with the face on it (`"on": "body"`), a faceted `ico` shell on the back with three amber crystals, two thick arms bent up to faceted boulder fists with a thumb stone each and three crystals on each knuckle, six legs of two rods and a foot (hip, high knee, foot out wide).
- **Gaiabloom**: a three-ball trunk with a ruff, a `sweep` neck, a head on top, the right forefoot lifted, a `Trim` nimbus torus behind the head, tree antlers (a trunk, a brow tine, two side branches and an inner branch, mirrored, all core), ten blossom nuggets on the branch tips (five a side), and a flat lawn disc with twelve flower nuggets round its rim. The lawn is part of the body: a disc 3.5 studs across before the build's fit, about three times the width of the stag's trunk.

## For Ethan's look

- **Concept drift.** Three rows would change their concept line if their V2 is taken: Thunderhog "hedgehog" becomes a boar that keeps the quills, Frostfang "sabre-tooth cub" becomes a grown cat, Skaddle "snow owl" becomes a hunter that keeps the owl's ear tufts and feather blades. The `concept` text of `Species.luau` and the effect text of [[Roster-Redesign]] say the old words; a swap changes them in the same step.
- **Cool is elegant, not fierce.** Gloomoth, Shimmerlynx and Reindazzle follow the ladder (cool), and their V2s are poised and spare. If rarer means fiercer for these too, they need a bite (mandibles, a snarl, a heavier brow), which is a change of mood in [[Roster-Redesign]] and not of body.
- **Take, fix, redo** as in the table: take Thunderhog, Frostfang, Rocklobber, Reindazzle and Gaiabloom; fix Gloomoth (the wings) and Skaddle (the body); redo Shimmerlynx (the pose).

## What still reads as assembled (batch 2)

- **Thunderhog**: the quills are cones in a zigzag standing on a dark slab, so the crest reads as a row of flames stuck on the back from the three-quarter view; the shoulder spikes are cones on balls; the claws are small blades under a ball paw; the head is a ball under the hump.
- **Frostfang**: the mane is two rings of identical spikes (a pin-cushion, or an ice porcupine from the side); the fangs are straight cones; the stripes are small ellipsoids and the ears tiny; the legs are rods with ball paws.
- **Skaddle**: the limbs are thin tube chains with a kink at each joint; the skates are thin boxes (a sled, not a blade); the halo is a ring with a crown of blades (from the front it looks like a radiant crown); the scarf is a flat wall of ribbon that vanishes edge-on; the head is a ball with two cones.
- **Gloomoth**: the wings are two big flat sheets with glass blades laid on them (a diorama of a butterfly); the body is small and thin; the legs are the thinnest rods in the batch.
- **Shimmerlynx**: the trunk is three balls in a line; the raised paw is a ball on two rods; the cheek spikes read as horns; the ribbons are upright walls, three slivers from the front.
- **Reindazzle**: the antlers are twig-straight tubes (the tines meet the beam at hard angles); the body is three balls and four rods with no chest or haunch; the head is small against the crown.
- **Rocklobber**: the legs are rods with a visible knee kink and no claw on the foot; the crystals are cones standing on the shell and the fists; the thumb stones touch the fists at a point; the face is flat on the body.
- **Gaiabloom**: the most assembled: the legs are rod pairs with ball hooves, the nimbus is a ring floating behind the head with nothing holding it, the blossoms and flowers are six-sided nuggets (boxes at 64 px), the lawn is a flat disc, the antlers are straight chains.

## What the recipe system could not do (batch 2)

Batch 1's list holds (a curved crisp tube, a hollow shape, a ribbon that turns, a part that moves, a face placed where the design wants it). New in this batch:

- **A thin part that survives edge-on.** Wings, ribbons and blades are flat shells a few hundredths of a stud thick (0.04 to 0.06 in the recipe, before the build's fit of 0.7 to 0.85): Gloomoth's membranes and panes, the Shimmerlynx aurora, the Skaddle scarf and feathers. They read face-on and disappear edge-on; there is no "give this a rib" or a bent sheet in a recipe, only the flat ellipsoid, the blade and the upright ribbon.
- **A coloured part that bends, or a joint.** A leg is two rods and a ball for a foot; `sweep` bends but only in `Body` or `BodyDark`. Rocklobber's, Reindazzle's, Gaiabloom's and Skaddle's legs show a knee kink and no joint shape (a knee cap, a hock, a hoof with a cleft).
- **A crest that grows out of the skin.** Quills, mane spikes and halo blades are hand-listed cones. They are built as `shell` parts: separate shells that touch the skin with no union and no seam triangles, so each cone keeps its own points and edges, and they read as stuck on.
- **Parts that turn, flap or clack.** Five of the eight need a part split out for their effect: the halo (Skaddle, Gaiabloom), the wings (Gloomoth), the claws (Rocklobber), the antlers (Gaiabloom) and the crest (Thunderhog). The part names are in the recipe (`halo`, `membrane` and `pane`, `fist` and `thumb`, `antler`, `quill`), so a split is a name filter, but no recipe key records it yet; the import step has to be told.
- **A ground that is not part of the body.** Gaiabloom carries its lawn and flowers inside the one mesh, a disc about three times the width of the stag's trunk, and the Legendary ground ring of [[Roster-Redesign]] lands on top of it. A prop slot (a part the import step places on the ground) would fix it; today the lawn is a body part.
- **A face in proportion to a small head.** Gloomoth and Reindazzle have small heads (a moth, a deer under antlers), so the face, which is a fraction of the head, is small on screen even at `eye_scale` 1.25 to 1.7. There is no "enlarge the head" in a recipe except by redrawing it.
- **A tier's triangle band** (as batch 1): five of the eight are over it.

## How it is built (batch 2)

From the repo root; `$S` is a scratch folder, `$S1` the scratch folder of batch 1 (its V2 shapes stand in for the old bodies of batch 1 when the closest species is looked up), `$PY` a Python with the `bpy` 5.0 module. Each species is copied to `$S/models/<Id>V2` with its `materials.json` (the smoothed one of the shipped species) and `notes.md`, and a base GLB with one flat material per slot (the `base_glb.py` snippet of [[Hero-Aliens]], "How it is built").

```
S=/tmp/design2
IDS="Thunderhog Frostfang Skaddle Gloomoth Shimmerlynx Reindazzle Rocklobber Gaiabloom"
for id in $IDS; do
  mkdir -p $S/models/${id}V2
  cp assets/models/$id/materials.json $S/models/${id}V2/materials.json
  sed "s/$id/${id}V2/g" assets/models/$id/notes.md > $S/models/${id}V2/notes.md
done
$PY base_glb.py $S/models ThunderhogV2,FrostfangV2,SkaddleV2,GloomothV2,ShimmerlynxV2,ReindazzleV2,RocklobberV2,GaiabloomV2
SC="$PY tools/blender/species_sculpt.py --models $S/models --method hybrid"
COMMON="--set stiff=4 --set stiff_thin=4 --set bevel_segments=0 --set crisp_detail=1.0"
rib() { python3 -c 'import importlib.util as u, json, sys; s = u.spec_from_file_location("r", "tools/blender/species_recipes.py"); m = u.module_from_spec(s); s.loader.exec_module(m); print(json.dumps(m.RECIPES[sys.argv[1]]["ribbons"], separators=(",", ":")))' $1; }
$SC --species ThunderhogV2 --set face.mood=fierce $COMMON --set 'shell=["quill","claw"]'
$SC --species FrostfangV2 --set face.mood=fierce $COMMON --set 'shell=["mane","claw"]'
$SC --species SkaddleV2 --set face.mood=fierce $COMMON --set res=0.03 --set 'shell=["feather","halo"]' --set 'no_fillet=["scarf","knot"]' --set "ribbons=$(rib SkaddleV2)"
$SC --species GloomothV2 --set face.mood=cool $COMMON --set res=0.03 --set 'crisp=["membrane","pane","plume","jewel"]' --set 'shell=["membrane","pane","plume"]'
$SC --species ShimmerlynxV2 --set face.mood=cool $COMMON --set res=0.03 --set 'no_fillet=["aurora"]' --set "ribbons=$(rib ShimmerlynxV2)"
$SC --species ReindazzleV2 --set face.mood=cool $COMMON --set res=0.03 --set core_share=0.82
$SC --species RocklobberV2 --set face.mood=fierce $COMMON --set 'crisp=["shell","fist","thumb","crystal"]' --set 'shell=["shell","fist","thumb","crystal"]'
$SC --species GaiabloomV2 --set face.mood=spectacular $COMMON --set res=0.03 --set 'shell=["blossom","flower","halo"]' --set 'crest=["blossom","flower","halo"]' --set core_share=0.75 --set face.detail=0.25 --set face.jaw_scale=2.8
$PY tools/blender/preview.py --models $S/models --species ThunderhogV2,FrostfangV2,SkaddleV2,GloomothV2,ShimmerlynxV2,ReindazzleV2,RocklobberV2,GaiabloomV2   # the 64 px shapes
rv() { $PY tools/blender/review_views.py --models $S/models --old assets/models --species ${1}V2 --out $S/final --views front,tq,side --size 420 --samples 40 ${2:+--backdrop $2}; }
rv Thunderhog D9CCE8; rv Frostfang A9C7E6; rv Skaddle A9C7E6; rv Gloomoth D9CCE8; rv Shimmerlynx A9C7E6; rv Reindazzle A9C7E6; rv Rocklobber; rv Gaiabloom
python3 tools/blender/design_sheet.py --batch 2 --renders $S/final --models $S/models --models $S1/models --out $S/design_pass_2.jpg
python3 tools/blender/overlap.py --models $S/models --models $S1/models --pairs     # the roster pairs by overlap, highest first
```

These command lines were run from a clean scratch folder against the committed recipes and gave the triangle counts of the table to the triangle (the build is deterministic); the sheet was then rendered from those models with the three review commands. The overrides:

- **`face.mood=<mood>`**: the V2 keys are not in the sculpt's table, so the mood is a command-line override (`fierce`, `cool` or `spectacular`).
- **`stiff=4`, `stiff_thin=4`, `crisp_detail=1.0`, `bevel_segments=0`, `res=0.03`**: as in batch 1 (a tighter blend of the body volumes and chains, a crisp cone keeps the recipe's own side count, no bevel on crisp cubes, a finer polygonizer cell for the species with thin core tubes: Skaddle, Gloomoth, Shimmerlynx, Reindazzle and Gaiabloom).
- **`shell=[...]`**: the parts the hybrid joins as shells even where they touch the core (no union, no seam triangles): the quills and claws (Thunderhog), the mane and claws (Frostfang), the feather blades and the halo (Skaddle), the membranes, panes and plumes (Gloomoth), the shell, fists, thumbs and crystals (Rocklobber), the blossoms, flowers and halo (Gaiabloom). **`crisp=[...]`** names parts the hybrid builds as crisp shapes on top of the skin (Gloomoth's wings and jewels, Rocklobber's shell and fists, which are `BodyDark` and would otherwise fuse into the skin).
- **`core_share`**: Reindazzle 0.82 and Gaiabloom 0.75 (the default is 0.65): their antlers, legs and neck are core tubes, so the skin takes more of the budget and the crisp parts less.
- **`crest=[...]`, `face.detail=0.25`, `face.jaw_scale=2.8`** (Gaiabloom only): the parts the spectacular mood makes 30 percent larger (the blossoms, the flower ring and the nimbus, not the antlers), more triangles in the face zones, and the size of the set jaw's mouth.
- **`no_fillet=[...]`, `ribbons=<json>`**: as in batch 1: the scarf, its knot and the aurora lie on the skin with a line and not a swelling; the ribbon data (`pts`, `widths`, `thick`, `slot`, `name`) lives in the recipe and the command passes it as JSON.

The review tools of batch 1's scratch folder are in the repo now:

- `tools/blender/review_views.py`: the lit renders (`preview.py`'s own scene, lights and surface variant, the model turned about z under an empty so the camera and the sun stay put: front, three-quarter `tq`, `side`, `back`). `--old assets/models` also renders each `<Id>` next to its `<Id>V2` and frames both by the longer of their two longest sides, so the old body and the new one are to scale; `--backdrop` takes the blue `A9C7E6` or lilac `D9CCE8` under white and pale species, none under the green and yellow ones. It needs `bpy`.
- `tools/blender/overlap.py`: the 64 px black-shape overlap, plain and boxed, of a V2 against its old body and the closest species of its world (`--species`), or every pair of a world (`--pairs`). Plain Python with numpy and Pillow, no Blender.
- `tools/blender/design_sheet.py`: the review sheet of a batch (`BATCHES` in the file holds the rows of batch 1 and batch 2): the current body, the V2 front, three-quarter and side, the two shapes, triangles, tier and mood, the overlaps; the JPEG quality is lowered until the file is under 450 KB. Plain Python with numpy and Pillow, no Blender.

Rerunning `design_sheet.py` against these renders and the rebuilt models reproduces every number of the tables to the digit.

## Next batch (after batch 2)

The roster pairs by overlap with both batches' V2s standing in for their old bodies (`overlap.py --pairs`): Pebblet with Zapfinch (0.64 plain, 0.78 boxed), Snailbyte with Buzzlebee (0.61 / 0.72), Flapsicle with Emberchin (0.68 / 0.70) and with Shellberg (0.60 / 0.70), Shellberg with Toastoad (0.59 / 0.69), Zapfinch with Radish (0.59 / 0.69), Chipmole with Emberchin (0.59 / 0.67). Every V2 pair of the two batches is under 0.7. The event species (Spookum, Wisplet, Nebulyn) sit in the highest pairs with Snailbyte and Radish (Spookum 0.49 / 0.77 with Snailbyte, 0.66 / 0.75 with Radish) but are built by `event_species.py` and are left for their own pass.

Fifteen species have no V2 yet. The first two are the top of the ladder, which Ethan's direction puts first:

- **Batch 3, the rest of the rare end and the worst pairs:** Radish (Cosmic) and Panpipe (Secret) (the spectacular ones: the highest tiers and the biggest feature sets, and Radish is in seven of the top 25 pairs), Zapfinch and Sparkfox (Rare, cool), Shellberg (Rare, World 2), Snailbyte, Pebblet and Flapsicle (the species in the worst pairs).
- **Batch 4, the rest:** Buzzlebee, Lanternewt and Twiglet (World 1), Toastoad, Emberchin, Snowbun and Chipmole (World 2); Fenripup is taken by the hero Fenrir ([[Hero-Aliens]]).
- **Before the swap:** Ethan's look at both sheets; the rebuild of Gloomoth's wings, Skaddle's body and Shimmerlynx's pose; the triangle band per tier; then swap the chosen V2s into `assets/models/` (a recipe replaces its shipped key, the model folder is rebuilt with `tools/model_assets.py --write`, the import skill) and split the effect parts out where the signature effect needs them (the halo, the wings, the claws, the antlers, the crest).

## What changed in the repo (batch 2)

- `tools/blender/species_recipes.py`: between the `DESIGN PASS 2 BEGIN` and `DESIGN PASS 2 END` markers, the eight `<Id>V2` recipes (all `"prototype": True`, `"batch": 0`) and the helpers `_msweep` (a sweep and its mirror image) and `_zig` (a lightning-bolt quill of flat-shaded cones).
- `tools/blender/review_views.py`, `tools/blender/overlap.py`, `tools/blender/design_sheet.py`: the review tools promoted from scratch scripts (above).
- `tools/tests/test_species_recipes.py`: the batch checks shared by both batches (`_DesignPassChecks`), a `DesignPassBatch2` class (each species named with its mood, the recipe's face at the mood's floor, the mood the sculpt gives the species, the big eyes, the `Trim` slot where the species has one) and a `PrototypeRoster` class (every prototype is a hero or a V2 of a batch, no species in two batches).
- `docs/vault/06-art-pipelines/refs/sculpt-pass/design_pass_2.jpg` (the sheet) with a copy in `media/studio/2026-10-15/`; this section.
