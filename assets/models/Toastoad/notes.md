# Toastoad block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Toastoad.md (Soakum, World 2, Uncommon, status review)
- Height: 2.75 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 20
- Triangles: 338 (cap 2500)
- Cells: 0.125 studs a cell, atlas Toastoad_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `belly` (moves, cells, pivot 0, 0.375, -0.1875); `bumpL` (moves, cells, pivot -0.375, 1.625, -0.5625); `bumpR` (moves, cells, pivot 0.375, 1.625, -0.5625); `pebbleR` (moves, cells, pivot 0.25, 2.375, 0.4375); `stoneL` (moves, cells, pivot -0.3125, 2.375, 0.375); `FacePlate` (the face sheet, frame 0)
- Eyes: `droplet`; the face plate is 224x96 px a frame, 3 frames (open, half, closed) in Toastoad_face.png, 3 a row (Rigs face.columns)
- Rig: 5 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Toastoad.glb (42308 bytes), Toastoad.fbx (60252 bytes, texture embedded), Toastoad_atlas.png, Toastoad_face.png, materials.json, Toastoad.png and Toastoad_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Toastoad`; check with `python3 -I tools/blocky/export_models.py --check --species Toastoad`.
