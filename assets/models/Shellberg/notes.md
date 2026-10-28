# Shellberg block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Shellberg.md (Floe, World 2, Rare, status review)
- Height: 3 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 73
- Triangles: 934 (cap 2500)
- Cells: 0.125 studs a cell, atlas Shellberg_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `dripL` (moves, cells, pivot -1.75, 1.875, 0.3461); `flagL` (moves, Neon, pivot -1.0625, 2.5, 0.5336); `flags` (moves, cells, pivot 0, 1.3, 0.5961); `footL` (moves, cells, pivot -0.9375, 0.375, -0.4039); `footR` (moves, cells, pivot 0.9375, 0.375, -0.4039); `shardsR` (moves, Neon, pivot 0.875, 2.875, 0.7211); `tail` (moves, cells, pivot 0, 0.8125, 2.0961); `FacePlate` (the face sheet, frame 0)
- Eyes: `crescent`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Shellberg_face.png, 4 a row (Rigs face.columns)
- Rig: 7 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Shellberg.glb (107212 bytes), Shellberg.fbx (102668 bytes, texture embedded), Shellberg_atlas.png, Shellberg_face.png, materials.json, Shellberg.png and Shellberg_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Shellberg`; check with `python3 -I tools/blocky/export_models.py --check --species Shellberg`.
