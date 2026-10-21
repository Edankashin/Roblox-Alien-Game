# MoonPoolRing block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/MoonPoolRing.md (Moon pool ring, World 1, status build)
- Footprint (W x D x H, studs): 14.5 x 14.75 x 3; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 34
- Triangles: 374 (budget 900)
- Collision: Precise (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 8 texels a cell, atlas MoonPoolRing_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `Accessory` (cells); `Trim` (cells); `Glow` (Neon, no map)
- Files: MoonPoolRing.glb (52864 bytes), MoonPoolRing.fbx (61692 bytes, texture embedded), MoonPoolRing_atlas.png, materials.json, MoonPoolRing.png and MoonPoolRing_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props MoonPoolRing`; check with `python3 -I tools/blocky/export_models.py --check --props MoonPoolRing`.
