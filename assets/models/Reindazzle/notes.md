# Reindazzle block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Reindazzle.md (Blinkar, World 2, Rare, status review)
- Height: 3.422 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 65
- Triangles: 928 (cap 2500)
- Cells: 0.125 studs a cell, atlas Reindazzle_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `chimeL` (moves, cells, pivot -1.7377, 2.2167, -0.75); `chimeR` (moves, cells, pivot 1.2167, 2.7377, -0.75); `earL` (moves, cells, pivot -1.115, 1.565, -1.25); `earR` (moves, cells, pivot 0.8546, 1.9123, -1.25); `lanterns` (moves, cells, pivot 0, 1.3, 0.375); `noseL` (moves, Neon, pivot -0.0217, 1.1231, -2); `tail` (moves, cells, pivot 0, 1.375, 1.625); `FacePlate` (the face sheet, frame 0)
- Eyes: `glimmer`; the face plate is 224x96 px a frame, 5 frames (open, half, closed, glint1, glint2) in Reindazzle_face.png, 4 a row (Rigs face.columns)
- Rig: 7 moving parts, root clips 1, flourish every 10s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Reindazzle.glb (89752 bytes), Reindazzle.fbx (90700 bytes, texture embedded), Reindazzle_atlas.png, Reindazzle_face.png, materials.json, Reindazzle.png and Reindazzle_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Reindazzle`; check with `python3 -I tools/blocky/export_models.py --check --species Reindazzle`.
