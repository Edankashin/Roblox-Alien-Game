# Rocklobber block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Rocklobber.md (Boulden, World 1, Rare, status review)
- Height: 3.125 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 48
- Triangles: 628 (cap 2500)
- Cells: 0.125 studs a cell, atlas Rocklobber_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `antennaR` (moves, cells, pivot 0.4375, 2.125, 0.625); `clawL` (moves, cells, pivot -1.25, 1.25, -0.3125); `clawR` (moves, cells, pivot 1.25, 1.25, -0.3125); `geodeL` (moves, Neon, pivot -0.375, 2.25, -0.0625); `legL` (moves, cells, pivot -1, 0.5, -0.1875); `legR` (moves, cells, pivot 1, 0.5, -0.1875); `FacePlate` (the face sheet, frame 0)
- Eyes: `crescent`; the face plate is 224x128 px a frame, 5 frames (open, half, closed, glint1, glint2) in Rocklobber_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 9s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Rocklobber.glb (72048 bytes), Rocklobber.fbx (80732 bytes, texture embedded), Rocklobber_atlas.png, Rocklobber_face.png, materials.json, Rocklobber.png and Rocklobber_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Rocklobber`; check with `python3 -I tools/blocky/export_models.py --check --species Rocklobber`.
