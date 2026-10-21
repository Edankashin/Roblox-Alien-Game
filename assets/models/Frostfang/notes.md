# Frostfang block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Frostfang.md (Sabrek, World 2, Epic, status review)
- Height: 3.397 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 56
- Triangles: 882 (cap 2500)
- Cells: 0.125 studs a cell, atlas Frostfang_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `earL` (moves, cells, pivot -0.625, 2.375, -1.0625); `earR` (moves, cells, pivot 0.625, 2.375, -1.0625); `pawL` (moves, cells, pivot -0.5, 0.25, -0.125); `pawR` (moves, cells, pivot 0.5, 0.25, -0.125); `ruff` (moves, cells, pivot 0, 1.625, 0); `tailR` (moves, cells, pivot 0.125, 2.25, 1.6875); `FacePlate` (the face sheet, frame 0)
- Eyes: `frost`; the face plate is 28x12 px a frame, 5 frames (open, half, closed, glint1, glint2) in Frostfang_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Frostfang.glb (80496 bytes), Frostfang.fbx (83660 bytes, texture embedded), Frostfang_atlas.png, Frostfang_face.png, materials.json, Frostfang.png and Frostfang_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Frostfang`; check with `python3 -I tools/blocky/export_models.py --check --species Frostfang`.
