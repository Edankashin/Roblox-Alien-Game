# Bush block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/Bush.md (Berry bush, World 1, status build)
- Footprint (W x D x H, studs): 5.125 x 2.75 x 2.5; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 10
- Triangles: 104 (budget 300)
- Collision: Hull (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas Bush_atlas.png 256x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `Accessory` (cells)
- Files: Bush.glb (15052 bytes), Bush.fbx (30540 bytes, texture embedded), Bush_atlas.png, materials.json, Bush.png and Bush_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props Bush`; check with `python3 -I tools/blocky/export_models.py --check --props Bush`.
