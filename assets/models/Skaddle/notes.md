# Skaddle block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Skaddle.md (Skadra, World 2, Legendary, status review)
- Height: 3.426 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 207
- Triangles: 2530 (cap 6000)
- Cells: 0.125 studs a cell, atlas Skaddle_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `crestL` (moves, Neon, pivot -0.4001, 2.9095, -1.0686); `frost` (moves, cells, pivot 0, 1.75, 2.0312); `halo` (moves, cells, pivot 0, 2.2, -0.4688); `hindwingL` (moves, cells, pivot -0.9375, 1.5, 0.6562); `hindwingR` (moves, cells, pivot 0.9375, 1.5, 0.6562); `quiverL` (moves, cells, pivot -0.5, 1.25, 0.8438); `scarfR` (moves, cells, pivot 0.625, 1.3125, -1.375); `tuftL` (moves, cells, pivot -0.9007, 2.7129, -0.3984); `tuftR` (moves, cells, pivot 0.4082, 2.8969, -0.7774); `wingL` (moves, cells, pivot -1, 1.3125, -0.2188); `wingR` (moves, cells, pivot 1, 1.3125, -0.2188); `FacePlate` (the face sheet, frame 0)
- Eyes: `halo`; the face plate is 224x112 px a frame, 11 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5) in Skaddle_face.png, 4 a row (Rigs face.columns)
- Rig: 11 moving parts, root clips 1, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Skaddle.glb (228908 bytes), Skaddle.fbx (157948 bytes, texture embedded), Skaddle_atlas.png, Skaddle_face.png, materials.json, Skaddle.png and Skaddle_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Skaddle`; check with `python3 -I tools/blocky/export_models.py --check --species Skaddle`.
