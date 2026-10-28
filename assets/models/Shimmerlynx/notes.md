# Shimmerlynx block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Shimmerlynx.md (Aurelyx, World 2, Epic, status review)
- Height: 3.425 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 105
- Triangles: 1598 (cap 4000)
- Cells: 0.125 studs a cell, atlas Shimmerlynx_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `crestL` (moves, Neon, pivot -0.0675, 2.5998, 0.2367); `earL` (moves, cells, pivot -0.9568, 2.5063, 0.0088); `earR` (moves, cells, pivot 0.6113, 2.6711, -0.3843); `moteL` (moves, Neon, pivot -0.0936, 2.8484, 0.2367); `pendant` (moves, cells, pivot 0, 1.125, -0.3492); `sparks` (moves, cells, pivot 0, 1.8, 0.282); `tailR` (moves, Neon, pivot 1.4375, 0.25, 1.057); `whiskerL` (moves, cells, pivot -1.1813, 1.3829, -0.5826); `whiskerR` (moves, cells, pivot 0.7487, 1.5858, -1.0665); `FacePlate` (the face sheet, frame 0)
- Eyes: `starry`; the face plate is 224x112 px a frame, 5 frames (open, half, closed, glint1, glint2) in Shimmerlynx_face.png, 4 a row (Rigs face.columns)
- Rig: 9 moving parts, root clips 1, flourish every 12s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Shimmerlynx.glb (141824 bytes), Shimmerlynx.fbx (120700 bytes, texture embedded), Shimmerlynx_atlas.png, Shimmerlynx_face.png, materials.json, Shimmerlynx.png and Shimmerlynx_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Shimmerlynx`; check with `python3 -I tools/blocky/export_models.py --check --species Shimmerlynx`.
