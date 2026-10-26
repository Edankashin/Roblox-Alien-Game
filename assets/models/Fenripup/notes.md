# Fenripup block-cell model

- Date: 2026-10-26
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Fenripup.md (Fenrir, World 2, Cosmic, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 189
- Triangles: 2324 (cap 2500)
- Cells: 0.0625 studs a cell, atlas Fenripup_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `aura` (moves, cells, pivot 0, 0.0312, 0.0125); `chain` (moves, cells, pivot 0, 1.25, -1.1562); `earL` (moves, cells, pivot -0.6875, 2.875, -0.9375); `earR` (moves, cells, pivot 0.6875, 2.875, -0.9375); `halo` (moves, cells, pivot 0, 1.875, 1.25); `mane` (moves, cells, pivot 0, 1.25, 0.5625); `moon` (moves, Neon, pivot 0, 3.2188, -1.875); `phases` (moves, cells, pivot 0, 0.95, 0.0125); `shade` (moves, cells, pivot 0, 3.2188, -1.875); `stars` (moves, Neon, pivot 0, 1.25, 0.5625); `tail` (moves, cells, pivot 0, 1.1875, 0.9375); `FacePlate` (the face sheet, frame 0)
- Eyes: `lunar`; the face plate is 224x112 px a frame, 13 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5, cycle6, cycle7) in Fenripup_face.png, 4 a row (Rigs face.columns)
- Rig: 11 moving parts, root clips 1, flourish every 20s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Fenripup.glb (246992 bytes), Fenripup.fbx (180252 bytes, texture embedded), Fenripup_atlas.png, Fenripup_face.png, materials.json, Fenripup.png and Fenripup_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Fenripup`; check with `python3 -I tools/blocky/export_models.py --check --species Fenripup`.
