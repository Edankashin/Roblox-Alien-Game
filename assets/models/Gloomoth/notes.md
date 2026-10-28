# Gloomoth block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Gloomoth.md (Iridia, World 1, Epic, status review)
- Height: 3.46 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 120
- Triangles: 1658 (cap 4000)
- Cells: 0.125 studs a cell, atlas Gloomoth_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `antennaL` (moves, Neon, pivot -0.6333, 2.389, -1.0625); `antennaR` (moves, Neon, pivot 0.3613, 2.4935, -1.0625); `hindwingL` (moves, Neon, pivot -0.7188, 1.5, 1.125); `hindwingR` (moves, Neon, pivot 0.7812, 1.5, 1.125); `shard` (moves, cells, pivot 0.0312, 3, 0.25); `swarm` (moves, cells, pivot 0.0312, 1.6, 0); `wingL` (moves, cells, pivot -0.7188, 1.75, -0.125); `wingR` (moves, cells, pivot 0.7812, 1.75, -0.125); `FacePlate` (the face sheet, frame 0)
- Eyes: `gem`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Gloomoth_face.png, 4 a row (Rigs face.columns)
- Rig: 8 moving parts, root clips 2, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Gloomoth.glb (163196 bytes), Gloomoth.fbx (130668 bytes, texture embedded), Gloomoth_atlas.png, Gloomoth_face.png, materials.json, Gloomoth.png and Gloomoth_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Gloomoth`; check with `python3 -I tools/blocky/export_models.py --check --species Gloomoth`.
