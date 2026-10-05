# Blender through MCP (Claude builds and edits models in Blender)

Claude Code drives Blender the same way it drives Studio: through an MCP server. The server is the community project "MCP for Blender" (PyPI `mcp-for-blender`, formerly `blender-mcp`, MIT, 30K stars, not affiliated with the Blender Foundation). It exposes scene inspection, object and material edits, arbitrary Python inside Blender, viewport screenshots, FBX/GLB export, and asset pulls from Poly Haven, Poly Pizza and Sketchfab, plus AI mesh generation through Hyper3D Rodin and Hunyuan3D. Verified against the project README on 2026-10-05.

## Setup (Mac, once)

1. `brew install uv` and `brew install --cask blender` (Blender 3.0 or newer; Python 3.10 or newer comes with it).
2. `uvx mcp-for-blender install-addon` installs the add-on. Then in Blender: Edit → Preferences → Add-ons, enable "Interface: MCP for Blender".
3. In Blender's 3D viewport press `N`, open the "MCP for Blender" tab, click "Start MCP Server" (default port 9876). The add-on and the server talk over a local TCP socket with JSON messages.
4. The repo's `.mcp.json` already registers the server (`uvx mcp-for-blender`), the same single project-scope registration rule as Studio: never also add it with `claude mcp add` in user or local scope.
5. Start Claude Code in the repo. `/mcp` should list `blender` as connected while Blender's server is running. Say "what is in the Blender scene" to confirm.

## How we use it

- **Save first.** The `execute_blender_code` tool runs arbitrary Python in Blender. Save the .blend before any session that edits it.
- **Round trip to Studio.** Claude builds or edits the model in Blender, exports with the `export_scene` tool (FBX, named objects only) into `assets/models/<SpeciesId>/<SpeciesId>.fbx`, and the model is imported into Studio with File → Import 3D (or Avatar → 3D Importer). Keep "1 Blender unit = 1 stud" and model aliens 2 to 3 units tall so they drop in at the scale the placeholders use. Open Cloud asset upload can replace the manual import later.
- **Style rules travel with the prompt.** Every creature prompt carries the recipe in `Creature-Generation.md`: round compact body, big eyes, short limbs, one accessory, one bold colour, 500 to 1,500 triangles, flat colours (vertex colours or one small palette texture), no transparency tricks. Phones are the target.
- **Reference-in, model-out.** Feed Claude the species row from `src/shared/data/Species.luau` and a reference image (a Gemini sheet or a sketch); ask for a greyscale silhouette check at thumbnail size before colouring.
- **Rigging and animation stay in Blender or in Studio's animation editor.** The MCP build is for meshes, materials and quick iterations; export rigged FBX when the rig exists.
- **Free assets.** Poly Haven textures and HDRIs are CC0 and fine for reference renders; do not ship Sketchfab or Poly Pizza models without checking the licence and the Roblox UGC rules. Hyper3D and Hunyuan3D generation need their own API keys (set once through the add-on panel; the README has a "Persistent API Credentials" section).

## Known limits

Complex operations take several steps; Poly Haven downloads block Blender's UI while they run; Poly Pizza can fail behind Cloudflare on data-centre IPs. If a command times out, simplify it. If the connection drops, restart both Blender's server (the N panel button) and Claude Code.

## Record what works

Add a dated line per creature here: tool used, prompt, triangle count, export settings, Studio import notes.

- 2026-10-05, blockout tier, all 16 World 1 species: `tools/blender/alien_base.py` run with the `bpy` 5.0.1 Python module (no Blender UI and no MCP connection needed; the same script runs under `blender -b -P ... -- --all`). No prompt: body, face, limbs, accessory and tier dressing come from the Species and Tiers tables. 774 to 1,256 triangles per alien, one mesh with 6 or 7 material slots. Export settings that worked: glTF `export_format='GLB'`, `export_apply=True`, `export_animations=False`, default Y-up; FBX defaults plus `apply_scale_options='FBX_SCALE_ALL'`, `mesh_smooth_type='FACE'`, `bake_anim=False`, `add_leaf_bones=False`. Both land in `assets/models/<SpeciesId>/`. Thumbnails: `tools/blender/preview.py`; Workbench needs libEGL, which the headless container lacks, so it fell back to Cycles CPU with emission-only materials (16 samples, about 0.1 s per 256 px image). Studio import (File -> Import 3D, scale 1, one MeshPart per material) is the expected result and still has to be confirmed in Studio.
- 2026-10-05, Mac install: Blender 5.2.2 LTS via Homebrew cask, uv 0.12.23. `uvx mcp-for-blender install-addon` fails on a machine where Blender has never been opened ("Could not find a Blender user addons directory"); creating `~/Library/Application Support/Blender/5.2/scripts/addons` and re-running with `BLENDERMCP_ADDONS_DIR` set installs `blender_mcp.py` (the setup script now does this). `claude mcp list` shows blender connected through uvx. Still by hand once: enable the add-on in Preferences and press Start MCP Server in the N panel.
