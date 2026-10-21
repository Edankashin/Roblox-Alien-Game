# IceSpire block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/IceSpire.md (Ice spire, World 2, status build)
- Footprint (W x D x H, studs): 5.58 x 4.444 x 11.25; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 12
- Triangles: 120 (budget 600)
- Collision: Box (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas IceSpire_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells); `Glow` (Neon, no map)
- Files: IceSpire.glb (28720 bytes), IceSpire.fbx (51612 bytes, texture embedded), IceSpire_atlas.png, materials.json, IceSpire.png and IceSpire_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props IceSpire`; check with `python3 -I tools/blocky/export_models.py --check --props IceSpire`.
