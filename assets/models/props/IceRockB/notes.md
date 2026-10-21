# IceRockB block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/IceRockB.md (Frost standing rock, World 2, status build)
- Footprint (W x D x H, studs): 3.375 x 2.75 x 4.25; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 9
- Triangles: 90 (budget 320)
- Collision: Hull (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas IceRockB_atlas.png 256x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `Accessory` (cells); `Trim` (cells); `Glow` (Neon, no map)
- Files: IceRockB.glb (16904 bytes), IceRockB.fbx (40876 bytes, texture embedded), IceRockB_atlas.png, materials.json, IceRockB.png and IceRockB_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props IceRockB`; check with `python3 -I tools/blocky/export_models.py --check --props IceRockB`.
