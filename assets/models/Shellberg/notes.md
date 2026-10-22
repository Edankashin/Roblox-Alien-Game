# Shellberg block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Shellberg.md (Floe, World 2, Rare, status review)
- Height: 3 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 35
- Triangles: 488 (cap 2500)
- Cells: 0.125 studs a cell, atlas Shellberg_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `dripL` (moves, cells, pivot -1.6875, 1.875, 0.125); `flagL` (moves, Neon, pivot -1, 2.5, 0.3125); `footL` (moves, cells, pivot -0.875, 0.375, -0.625); `footR` (moves, cells, pivot 1, 0.375, -0.625); `shardsR` (moves, Neon, pivot 0.9375, 2.875, 0.5); `tail` (moves, cells, pivot 0.0625, 0.8125, 1.875); `FacePlate` (the face sheet, frame 0)
- Eyes: `crescent`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Shellberg_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Shellberg.glb (69460 bytes), Shellberg.fbx (85804 bytes, texture embedded), Shellberg_atlas.png, Shellberg_face.png, materials.json, Shellberg.png and Shellberg_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Shellberg`; check with `python3 -I tools/blocky/export_models.py --check --species Shellberg`.
