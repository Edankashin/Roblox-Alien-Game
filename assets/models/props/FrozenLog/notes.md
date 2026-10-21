# FrozenLog block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/FrozenLog.md (Frozen log, World 2, status build)
- Footprint (W x D x H, studs): 4.625 x 2.25 x 1.75; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 8
- Triangles: 74 (budget 300)
- Collision: Hull (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas FrozenLog_atlas.png 256x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `BodyDark` (cells); `Accessory` (cells); `Trim` (cells)
- Files: FrozenLog.glb (12972 bytes), FrozenLog.fbx (33692 bytes, texture embedded), FrozenLog_atlas.png, materials.json, FrozenLog.png and FrozenLog_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props FrozenLog`; check with `python3 -I tools/blocky/export_models.py --check --props FrozenLog`.
