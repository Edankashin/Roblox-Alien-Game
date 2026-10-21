# Kettlepuff block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Kettlepuff.md (Kettlet, World 2, Common, status review)
- Height: 2.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 12
- Triangles: 254 (cap 2500)
- Cells: 0.125 studs a cell, atlas Kettlepuff_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `floatR` (moves, cells, pivot 1.125, 2.25, -0.25); `handle` (moves, cells, pivot -0.625, 1.75, 0); `lid` (moves, cells, pivot -0.625, 1.75, 0); `wispR` (moves, cells, pivot 1.625, 2.375, -0.25); `FacePlate` (the face sheet, frame 0)
- Eyes: `button`; the face plate is 28x12 px a frame, 3 frames (open, half, closed) in Kettlepuff_face.png, 3 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Kettlepuff.glb (34296 bytes), Kettlepuff.fbx (54172 bytes, texture embedded), Kettlepuff_atlas.png, Kettlepuff_face.png, materials.json, Kettlepuff.png and Kettlepuff_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Kettlepuff`; check with `python3 -I tools/blocky/export_models.py --check --species Kettlepuff`.
