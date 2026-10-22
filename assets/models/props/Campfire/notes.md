# Campfire block-cell prop

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/Campfire.md (Campfire, World 1, status build)
- Footprint (W x D x H, studs): 3 x 3 x 3.125; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 18
- Triangles: 212 (budget 400)
- Collision: Box (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas Campfire_atlas.png 256x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Trim` (cells); `Glow` (Neon, no map)
- Files: Campfire.glb (23620 bytes), Campfire.fbx (40748 bytes, texture embedded), Campfire_atlas.png, materials.json, Campfire.png and Campfire_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props Campfire`; check with `python3 -I tools/blocky/export_models.py --check --props Campfire`.
