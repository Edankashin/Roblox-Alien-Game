# Zapfinch block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Zapfinch.md (Zirrit, World 1, Rare, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 43
- Triangles: 688 (cap 2500)
- Cells: 0.125 studs a cell, atlas Zapfinch_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `arc` (moves, Neon, pivot 0, 3.375, -0.8125); `crestL` (moves, Neon, pivot -0.375, 2.625, -0.8125); `crestR` (moves, Neon, pivot 0.375, 2.625, -0.8125); `tail` (moves, cells, pivot 0, 1.1875, 0.75); `wingL` (moves, Neon, pivot -0.75, 1.25, 0); `wingR` (moves, Neon, pivot 0.75, 1.25, 0); `FacePlate` (the face sheet, frame 0)
- Eyes: `bubble`; the face plate is 224x96 px a frame, 5 frames (open, half, closed, glint1, glint2) in Zapfinch_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 7s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Zapfinch.glb (67540 bytes), Zapfinch.fbx (75420 bytes, texture embedded), Zapfinch_atlas.png, Zapfinch_face.png, materials.json, Zapfinch.png and Zapfinch_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Zapfinch`; check with `python3 -I tools/blocky/export_models.py --check --species Zapfinch`.
