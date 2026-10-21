# Gaiabloom block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Gaiabloom.md (Gaira, World 1, Legendary, status review)
- Height: 3.452 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 106
- Triangles: 1336 (cap 2500)
- Cells: 0.125 studs a cell, atlas Gaiabloom_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `antlerL` (moves, cells, pivot -0.5506, 2.5, -0.8438); `antlerR` (moves, cells, pivot 0.4494, 2.5, -0.8438); `butterflyR` (moves, Neon, pivot 1.1994, 3, -1.9688); `butterfly2L` (moves, Neon, pivot -1.2381, 2.8125, 0.2812); `cape` (moves, cells, pivot -0.0506, 1.9062, 0.4062); `earL` (moves, cells, pivot -1.0506, 2.3125, -0.5938); `earR` (moves, cells, pivot 0.9494, 2.3125, -0.5938); `halo` (moves, cells, pivot -0.0506, 2.625, -0.8438); `tail` (moves, cells, pivot -0.0506, 1.625, 1.9062); `FacePlate` (the face sheet, frame 0)
- Eyes: `bloom`; the face plate is 56x24 px a frame, 11 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5) in Gaiabloom_face.png, 4 a row (Rigs face.columns)
- Rig: 9 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Gaiabloom.glb (119724 bytes), Gaiabloom.fbx (103196 bytes, texture embedded), Gaiabloom_atlas.png, Gaiabloom_face.png, materials.json, Gaiabloom.png and Gaiabloom_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Gaiabloom`; check with `python3 -I tools/blocky/export_models.py --check --species Gaiabloom`.
