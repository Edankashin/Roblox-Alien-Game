# Pengoo block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Pengoo.md (Pengoo, World 2, Uncommon, status review)
- Height: 3.114 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 20
- Triangles: 406 (cap 2500)
- Cells: 0.125 studs a cell, atlas Pengoo_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `pack` (moves, cells, pivot 0, 0.875, 1); `tuft` (moves, cells, pivot 0, 2.75, 0.1875); `wingL` (moves, cells, pivot -1, 1.5, 0); `wingR` (moves, cells, pivot 1, 1.5, 0); `FacePlate` (the face sheet, frame 0)
- Eyes: `twotone`; the face plate is 224x96 px a frame, 3 frames (open, half, closed) in Pengoo_face.png, 3 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Pengoo.glb (42932 bytes), Pengoo.fbx (59324 bytes, texture embedded), Pengoo_atlas.png, Pengoo_face.png, materials.json, Pengoo.png and Pengoo_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Pengoo`; check with `python3 -I tools/blocky/export_models.py --check --species Pengoo`.
