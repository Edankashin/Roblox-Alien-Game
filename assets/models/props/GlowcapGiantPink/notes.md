# GlowcapGiantPink block-cell prop

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py --props (tools/blender/blocky_build.py, bpy 5.0.1); Decision B44. Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Props/GlowcapGiantPink.md (Giant glowcap, dusk pink, World 1, status build)
- Footprint (W x D x H, studs): 11 x 11 x 19.5; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike
- Blocks: 18
- Triangles: 184 (budget 600)
- Collision: Box (src/shared/data/Props.luau)
- Cells: 0.25 studs a cell (the world cell), 4 texels a cell, atlas GlowcapGiantPink_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart a colour slot, in GLB order): `Body` (cells); `BodyDark` (cells); `Accessory` (cells); `Trim` (cells); `Glow` (Neon, no map)
- Files: GlowcapGiantPink.glb (41580 bytes), GlowcapGiantPink.fbx (64540 bytes, texture embedded), GlowcapGiantPink_atlas.png, materials.json, GlowcapGiantPink.png and GlowcapGiantPink_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route

Regenerate with `$BPY tools/blocky/export_models.py --props GlowcapGiantPink`; check with `python3 -I tools/blocky/export_models.py --check --props GlowcapGiantPink`.
