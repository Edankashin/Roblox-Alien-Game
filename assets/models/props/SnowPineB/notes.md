# SnowPineB block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/SnowPineB.md (Slender snow pine, World 2, status build)
- Footprint (W x D x H, studs): 5.75 x 5 x 11.25; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 16
- Triangles: 160 (budget 500)
- Collision: Box (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas SnowPineB_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells); `Trim` (cells)
- Files: SnowPineB.glb (34596 bytes), SnowPineB.fbx (54252 bytes, texture embedded), SnowPineB_atlas.png, materials.json, SnowPineB.png and SnowPineB_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props SnowPineB`; check with `python3 -I tools/blocky/export_models.py --check --props SnowPineB`.
