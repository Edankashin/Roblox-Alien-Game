# Thunderhog block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Thunderhog.md (Voltus, World 1, Epic, status review)
- Height: 3.375 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 74
- Triangles: 1026 (cap 2500)
- Cells: 0.125 studs a cell, atlas Thunderhog_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `antennaL` (moves, Neon, pivot -0.875, 2.25, -1.4375); `antennaR` (moves, Neon, pivot 0.875, 2.25, -1.4375); `charge` (moves, Neon, pivot 0, 1.875, 0.8125); `cloudR` (moves, cells, pivot 0.4375, 3.0625, 1.4375); `crest` (moves, cells, pivot 0, 2.125, 0.3125); `sparkR` (moves, Neon, pivot 0.625, 2.875, 0.1875); `tail` (moves, cells, pivot 0, 1.625, 1.8125); `FacePlate` (the face sheet, frame 0)
- Eyes: `starry`; the face plate is 28x14 px a frame, 5 frames (open, half, closed, glint1, glint2) in Thunderhog_face.png, 4 a row (Rigs face.columns)
- Rig: 7 moving parts, root clips 1, flourish every 8s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Thunderhog.glb (102900 bytes), Thunderhog.fbx (94220 bytes, texture embedded), Thunderhog_atlas.png, Thunderhog_face.png, materials.json, Thunderhog.png and Thunderhog_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Thunderhog`; check with `python3 -I tools/blocky/export_models.py --check --species Thunderhog`.
