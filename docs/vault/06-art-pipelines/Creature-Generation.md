# Creature generation

Pipeline from the reference videos, adapted to our roster. Tools seen working in 2026: Claude Design (models with VFX and animation sets plus a Lua installer), 3D AI Studio (meshes with a target polygon count, preferred for phones), Meshy (rigged and animated GLBs), an image model such as Gemini for icon sets and model reference sheets, and Studio MCP `generate_mesh` as the free fallback. Pick one tool per asset type and record the settings that worked here.

## Prompt template (one per species)

> Generate a Roblox-ready creature called [name]: [three-word concept]. Round compact body, big eyes, tiny mouth, short limbs, one bold [colour], stylized low-poly, drawable by a child. One accessory: [attribute]. Animations: idle (looping, job-tied: [job]), walk, work-at-station ([job] loop), catch-reveal (shake, pop, pose), ride ([traversal] if rideable), flee. Tier [tier]: [overlay notes]. Low particle count, mobile-safe. Import 1:1 with an installer .lua. Ask me every question you need before generating.

## Steps
1. Generate commons first, in batches; review silhouettes in greyscale at thumbnail size.
2. Keep one goofy element at every tier.
3. Paste the installer .lua into Studio's command bar, or hand it to Claude through MCP. It rigs the model and imports the animations.
4. Ask Claude Code to wire the species into `src/shared/data/species` and the client renderer.
5. Record what worked and what did not here.

Budget note from the reference: about ten creatures used roughly 30% of a usage allowance.

## Blockout tier (procedural, free)

Every species gets a blockout mesh now, so spawning, the capture reveal, the codex and the stations can be tested with real MeshParts at the right height before any paid or hand-made model exists. The AI tools above (or hand modelling) then replace blockouts one species at a time: keep the folder, the file names and the height, drop in the new mesh, update `notes.md`. A blockout is a stand-in, not a final look; do not polish it.

**Command** (needs the `bpy` Python module, Blender 5.0, or a Blender binary):

```
python3 tools/blender/alien_base.py --all                 # every row in src/shared/data/Species.luau
python3 tools/blender/alien_base.py --species Mossbop,Radish
blender -b -P tools/blender/alien_base.py -- --all        # the same script inside Blender
python3 tools/blender/preview.py                         # 256x256 thumbnails, colour and greyscale silhouette
```

Output: `assets/models/<SpeciesId>/<SpeciesId>.glb`, `.fbx`, `notes.md` (date, tool, concept, accessory, tier dressing, triangle count, height), and after `preview.py` also `<SpeciesId>.png` and `<SpeciesId>_grey.png`. The generator exits non-zero when any species is over 1,500 triangles. Both scripts read `Species.luau` and `Tiers.luau` through `tools/luau_tables.py`, so a new species row is picked up with no code change.

**What the generator builds** (the recipe above, mechanised):

- Body from `placeholder.shape`: Ball is a UV sphere squashed to 90% height, Block a bevelled cube, Cylinder a bevelled cylinder. Body height is 2.2 units x `placeholder.scale`, standing on the origin, built Z-up; the exporters write Y-up.
- Two eyes at 22% of body height on the front upper half, pupils, a highlight each, a tiny flattened mouth, four stubby limbs in a 35% darker body colour.
- One accessory from the concept string, first keyword that matches wins: antler/stag -> antlers; wing -> wings; quill/lightning -> back spikes; shell -> half-sphere shell with a rim; tail -> tapered tail with a ball tip; crest/antenna -> two stalks with ball tips; hat/leaf -> leaf on the head; radish/sun -> sun disk behind the head plus a leaf tuft; pipe/goat -> horns; backpack -> cube on the back; claw/crab -> two ball claws; puff/dandelion -> ring of balls around the head; firefly/jelly/glow -> emissive bulb on a stalk; otherwise a three-cone tuft. Edit `ACCESSORY_RULES` in the script to add one.
- Tier dressing from `docs/GAME_DESIGN.md` section 15: Common and Uncommon nothing extra (the accessory is the prop); Rare 110% and a metallic accessory; Epic 120% and a collar torus; Legendary 125% with a halo torus and a ground ring; Cosmic 150% with an emissive accessory; Secret as Cosmic with a black body. Trim parts use the tier colour from `Tiers.luau`.
- Materials: one flat Principled material per colour (Body, BodyDark, EyeWhite, Pupil, Mouth, Accessory, Trim), roughness 0.8, no textures. The accessory colour is the body hue rotated 150 degrees; gold `#FFC83D` when the concept says gold, glow or radiant; silver when it says metal; sky blue for grey, white or black bodies. All parts are joined into one mesh object named `<SpeciesId>` with the material slots kept, so Studio's Import 3D yields one MeshPart per material and each part takes its Color.
- Budget: 500 to 1,500 triangles. If a species is over, the script rebuilds it one detail level lower (fewer sphere segments) and says so in the output and in `notes.md`.

**Studio import:** File -> Import 3D, keep scale 1, one MeshPart per material. Check the height against the placeholder part before wiring the model into the client renderer.

**Review:** open the `_grey.png` files at their native 256 px, or smaller; that is the greyscale-at-thumbnail check from the design. The silhouette must say what the alien is without colour.

**Known limits (2026-10-05):** the top tiers come out tall because `placeholder.scale` already grows with tier and the tier scale multiplies it again (Thunderhog 4.0, Gaiabloom 5.1, Radish 5.5, Panpipe 5.1 units); decide whether the tier scale or the placeholder scale is the one source of size before the final models are made. `preview.py` uses Workbench when a GPU/EGL is available and otherwise falls back to Cycles on the CPU with emission-only materials, which gives the same flat look.
