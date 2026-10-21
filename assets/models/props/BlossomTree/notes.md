# BlossomTree block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/BlossomTree.md (Blossom tree, World 1, status build)
- Footprint (W x D x H, studs): 9 x 6.625 x 11.25; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 20
- Triangles: 228 (budget 600)
- Collision: Box (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas BlossomTree_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells)
- Files: BlossomTree.glb (41688 bytes), BlossomTree.fbx (54252 bytes, texture embedded), BlossomTree_atlas.png, materials.json, BlossomTree.png and BlossomTree_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props BlossomTree`; check with `python3 -I tools/blocky/export_models.py --check --props BlossomTree`.
