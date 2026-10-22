# Gloomoth block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Gloomoth.md (Iridia, World 1, Epic, status review)
- Height: 3.438 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 65
- Triangles: 970 (cap 2500)
- Cells: 0.125 studs a cell, atlas Gloomoth_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `antennaL` (moves, Neon, pivot -0.5, 2.5, -1.1562); `antennaR` (moves, Neon, pivot 0.5, 2.5, -1.1562); `hindwingL` (moves, Neon, pivot -0.75, 1.5, 1.0312); `hindwingR` (moves, Neon, pivot 0.75, 1.5, 1.0312); `shard` (moves, cells, pivot 0, 3, 0.1562); `wingL` (moves, cells, pivot -0.75, 1.75, -0.2188); `wingR` (moves, cells, pivot 0.75, 1.75, -0.2188); `FacePlate` (the face sheet, frame 0)
- Eyes: `gem`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Gloomoth_face.png, 4 a row (Rigs face.columns)
- Rig: 7 moving parts, root clips 2, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Gloomoth.glb (105360 bytes), Gloomoth.fbx (103100 bytes, texture embedded), Gloomoth_atlas.png, Gloomoth_face.png, materials.json, Gloomoth.png and Gloomoth_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Gloomoth`; check with `python3 -I tools/blocky/export_models.py --check --species Gloomoth`.
