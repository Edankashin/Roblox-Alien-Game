# Spookum block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Spookum.md (Grin, World 1, Epic, status review)
- Height: 3.319 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 49
- Triangles: 638 (cap 2500)
- Cells: 0.125 studs a cell, atlas Spookum_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `armL` (moves, cells, pivot -1, 1.75, -0.2812); `armR` (moves, cells, pivot 1, 1.75, -0.2812); `hem` (moves, cells, pivot 0, 0.75, -0.0312); `lanternL` (moves, Neon, pivot -1.375, 2.375, -0.2812); `stem` (moves, cells, pivot 0, 2.75, -0.0312); `FacePlate` (the face sheet, frame 0)
- Eyes: `hearty`; the face plate is 28x14 px a frame, 5 frames (open, half, closed, glint1, glint2) in Spookum_face.png, 4 a row (Rigs face.columns)
- Rig: 5 moving parts, root clips 1, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Spookum.glb (64560 bytes), Spookum.fbx (71484 bytes, texture embedded), Spookum_atlas.png, Spookum_face.png, materials.json, Spookum.png and Spookum_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Spookum`; check with `python3 -I tools/blocky/export_models.py --check --species Spookum`.
