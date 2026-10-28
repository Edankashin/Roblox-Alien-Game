# Thunderhog block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Thunderhog.md (Voltus, World 1, Epic, status review)
- Height: 3.449 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 120
- Triangles: 1582 (cap 4000)
- Cells: 0.125 studs a cell, atlas Thunderhog_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `antennaL` (moves, Neon, pivot -1.1516, 2.0148, -1.375); `antennaR` (moves, Neon, pivot 0.5814, 2.2584, -1.375); `charge` (moves, Neon, pivot -0.0938, 1.875, 0.875); `cloudR` (moves, cells, pivot 0.3438, 3.0625, 1.5); `crest` (moves, cells, pivot -0.0938, 2.125, 0.375); `sparkR` (moves, Neon, pivot 0.5312, 2.875, 0.25); `storm` (moves, cells, pivot -0.0938, 1.6, -0.025); `tail` (moves, cells, pivot -0.0938, 1.625, 1.875); `FacePlate` (the face sheet, frame 0)
- Eyes: `starry`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Thunderhog_face.png, 4 a row (Rigs face.columns)
- Rig: 8 moving parts, root clips 1, flourish every 8s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Thunderhog.glb (155936 bytes), Thunderhog.fbx (123868 bytes, texture embedded), Thunderhog_atlas.png, Thunderhog_face.png, materials.json, Thunderhog.png and Thunderhog_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Thunderhog`; check with `python3 -I tools/blocky/export_models.py --check --species Thunderhog`.
