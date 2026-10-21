# SparkStation block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/SparkStation.md (Glow flower, World 0, status build)
- Footprint (W x D x H, studs): 2.275 x 1.75 x 4.5; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 12
- Triangles: 122 (budget 260)
- Collision: None (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas SparkStation_atlas.png 256x256, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells); `Glow` (Neon, no map)
- Files: SparkStation.glb (15888 bytes), SparkStation.fbx (38348 bytes, texture embedded), SparkStation_atlas.png, materials.json, SparkStation.png and SparkStation_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props SparkStation`; check with `python3 -I tools/blocky/export_models.py --check --props SparkStation`.
