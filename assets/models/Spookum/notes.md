# Spookum block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Spookum.md (Grin, World 1, Epic, status review)
- Height: 3.455 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 130
- Triangles: 1658 (cap 4000)
- Cells: 0.125 studs a cell, atlas Spookum_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `armL` (moves, cells, pivot -1.1294, 1.6011, -0.25); `armR` (moves, cells, pivot 0.8511, 1.8794, -0.25); `candles` (moves, cells, pivot 0, 1.65, 0); `hem` (moves, cells, pivot 0, 0.75, 0); `lanternL` (moves, Neon, pivot -1.5878, 2.1678, -0.25); `stemL` (moves, cells, pivot -0.2957, 2.8543, 0); `wispL` (moves, Neon, pivot -0.174, 1.9878, 1.1875); `FacePlate` (the face sheet, frame 0)
- Eyes: `hearty`; the face plate is 224x96 px a frame, 5 frames (open, half, closed, glint1, glint2) in Spookum_face.png, 4 a row (Rigs face.columns)
- Rig: 7 moving parts, root clips 2, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Spookum.glb (159668 bytes), Spookum.fbx (121260 bytes, texture embedded), Spookum_atlas.png, Spookum_face.png, materials.json, Spookum.png and Spookum_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Spookum`; check with `python3 -I tools/blocky/export_models.py --check --species Spookum`.
