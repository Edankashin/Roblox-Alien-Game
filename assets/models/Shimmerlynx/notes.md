# Shimmerlynx block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Shimmerlynx.md (Aurelyx, World 2, Epic, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 59
- Triangles: 1046 (cap 2500)
- Cells: 0.125 studs a cell, atlas Shimmerlynx_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `crest` (moves, Neon, pivot -0.119, 2.75, 0.0938); `earL` (moves, cells, pivot -0.9315, 2.75, -0.3438); `earR` (moves, cells, pivot 0.6935, 2.75, -0.3438); `mote` (moves, Neon, pivot -0.119, 3, 0.0938); `pendant` (moves, cells, pivot -0.119, 1.125, -0.5); `tailR` (moves, Neon, pivot 1.3185, 0.25, 0.9062); `whiskerL` (moves, cells, pivot -1.119, 1.6562, -1); `whiskerR` (moves, cells, pivot 0.881, 1.6562, -1); `FacePlate` (the face sheet, frame 0)
- Eyes: `starry`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Shimmerlynx_face.png, 4 a row (Rigs face.columns)
- Rig: 8 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Shimmerlynx.glb (91324 bytes), Shimmerlynx.fbx (92252 bytes, texture embedded), Shimmerlynx_atlas.png, Shimmerlynx_face.png, materials.json, Shimmerlynx.png and Shimmerlynx_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Shimmerlynx`; check with `python3 -I tools/blocky/export_models.py --check --species Shimmerlynx`.
