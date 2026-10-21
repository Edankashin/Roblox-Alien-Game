# Flapsicle block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Flapsicle.md (Eekle, World 2, Uncommon, status review)
- Height: 2.75 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 19
- Triangles: 402 (cap 2500)
- Cells: 0.125 studs a cell, atlas Flapsicle_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `earL` (moves, cells, pivot -0.75, 0.875, -0.0625); `earR` (moves, cells, pivot 0.75, 0.875, -0.0625); `perch` (moves, cells, pivot 0, 2.625, 0.0625); `wingL` (moves, cells, pivot -0.75, 2.25, 0.0625); `wingR` (moves, cells, pivot 0.75, 2.25, 0.0625); `FacePlate` (the face sheet, frame 0)
- Eyes: `moonlet`; the face plate is 28x12 px a frame, 3 frames (open, half, closed) in Flapsicle_face.png, 3 a row (Rigs face.columns)
- Rig: 5 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Flapsicle.glb (42160 bytes), Flapsicle.fbx (60812 bytes, texture embedded), Flapsicle_atlas.png, Flapsicle_face.png, materials.json, Flapsicle.png and Flapsicle_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Flapsicle`; check with `python3 -I tools/blocky/export_models.py --check --species Flapsicle`.
