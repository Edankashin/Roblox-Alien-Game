# IceSignArmLow block-cell prop

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/IceSignArmLow.md (Sights signpost arm: Ice Cave, World 2, status build)
- Footprint (W x D x H, studs): 3.75 x 0.5 x 1.375; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 6
- Triangles: 66 (budget 200)
- Collision: None (src/shared/data/Props.luau)
- Origin: the layout places the note's (0, 0, 0), -2.125, -2.125, 0 studs from the bottom centre in the note's axes (data/Props `origin`)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas IceSignArmLow_atlas.png 128x256, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells); `Trim` (cells)
- Files: IceSignArmLow.glb (10576 bytes), IceSignArmLow.fbx (35740 bytes, texture embedded), IceSignArmLow_atlas.png, materials.json, IceSignArmLow.png and IceSignArmLow_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props IceSignArmLow`; check with `python3 -I tools/blocky/export_models.py --check --props IceSignArmLow`.
