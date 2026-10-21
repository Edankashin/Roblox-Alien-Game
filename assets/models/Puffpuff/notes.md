# Puffpuff block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Puffpuff.md (Dandel, World 1, Common, status review)
- Height: 2.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 12
- Triangles: 228 (cap 2500)
- Cells: 0.125 studs a cell, atlas Puffpuff_atlas.png 512x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `floatR` (moves, cells, pivot 1.125, 2.25, -0.5); `leafL` (moves, cells, pivot -0.125, 0.25, 0); `leafR` (moves, cells, pivot 0.125, 0.25, 0); `seeds` (moves, cells, pivot 0, 2.125, 0); `FacePlate` (the face sheet, frame 0)
- Eyes: `dot`; the face plate is 28x14 px a frame, 3 frames (open, half, closed) in Puffpuff_face.png, 3 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Puffpuff.glb (29088 bytes), Puffpuff.fbx (51052 bytes, texture embedded), Puffpuff_atlas.png, Puffpuff_face.png, materials.json, Puffpuff.png and Puffpuff_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Puffpuff`; check with `python3 -I tools/blocky/export_models.py --check --species Puffpuff`.
