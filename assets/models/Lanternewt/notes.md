# Lanternewt block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Lanternewt.md (Lantrin, World 1, Uncommon, status review)
- Height: 2.75 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 19
- Triangles: 412 (cap 2500)
- Cells: 0.125 studs a cell, atlas Lanternewt_atlas.png 512x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `gillL` (moves, cells, pivot -1, 1.5, -1.125); `gillR` (moves, cells, pivot 1, 1.5, -1.125); `tail` (moves, cells, pivot 0, 1.125, 0.9375); `FacePlate` (the face sheet, frame 0)
- Eyes: `moonlet`; the face plate is 224x128 px a frame, 3 frames (open, half, closed) in Lanternewt_face.png, 3 a row (Rigs face.columns)
- Rig: 3 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Lanternewt.glb (38504 bytes), Lanternewt.fbx (52604 bytes, texture embedded), Lanternewt_atlas.png, Lanternewt_face.png, materials.json, Lanternewt.png and Lanternewt_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Lanternewt`; check with `python3 -I tools/blocky/export_models.py --check --species Lanternewt`.
