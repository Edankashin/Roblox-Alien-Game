# Nebulyn block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Nebulyn.md (Cosmoo, World 1, Legendary, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 165
- Triangles: 2118 (cap 6000)
- Cells: 0.0625 studs a cell, atlas Nebulyn_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `comet` (moves, Neon, pivot 0, 3.25, -0.2188); `fallenR` (moves, Neon, pivot 0.75, 0.125, 1.5312); `orbiters` (moves, cells, pivot 0, 1.6, -0.4188); `planetL` (moves, cells, pivot -1.5771, 2.7398, -0.4688); `puffL` (moves, cells, pivot -0.3305, 2.8519, -0.1562); `rings` (moves, cells, pivot 0, 2.25, 2.7188); `starL` (moves, Neon, pivot -1.8169, 2.2012, 0.0938); `starR` (moves, Neon, pivot 1.181, 2.875, -0.7188); `tailR` (moves, cells, pivot 0.25, 1.375, 0.6562); `twinkleR` (moves, Neon, pivot 0.269, 2.1788, -1.3438); `twinkle2R` (moves, Neon, pivot 0.2884, 2.9389, -0.5938); `FacePlate` (the face sheet, frame 0)
- Eyes: `starlit`; the face plate is 224x128 px a frame, 11 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5) in Nebulyn_face.png, 4 a row (Rigs face.columns)
- Rig: 11 moving parts, root clips 2, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Nebulyn.glb (258244 bytes), Nebulyn.fbx (204076 bytes, texture embedded), Nebulyn_atlas.png, Nebulyn_face.png, materials.json, Nebulyn.png and Nebulyn_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Nebulyn`; check with `python3 -I tools/blocky/export_models.py --check --species Nebulyn`.
