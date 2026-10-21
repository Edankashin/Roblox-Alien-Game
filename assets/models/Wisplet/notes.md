# Wisplet block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Wisplet.md (Wispkin, World 1, Rare, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 43
- Triangles: 584 (cap 2500)
- Cells: 0.125 studs a cell, atlas Wisplet_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `floatL` (moves, cells, pivot -1.4375, 0.9375, 0.4375); `floatR` (moves, cells, pivot 1.4375, 1.9375, 0.4375); `glass` (moves, cells, pivot 0, 1.875, 0); `halo` (moves, cells, pivot 0, 1.5, 0.875); `tipR` (moves, Neon, pivot 0.5, 3, 0); `tongueL` (moves, cells, pivot -0.5625, 2.4375, 0); `FacePlate` (the face sheet, frame 0)
- Eyes: `crescent`; the face plate is 28x18 px a frame, 5 frames (open, half, closed, glint1, glint2) in Wisplet_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 9s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Wisplet.glb (60772 bytes), Wisplet.fbx (70844 bytes, texture embedded), Wisplet_atlas.png, Wisplet_face.png, materials.json, Wisplet.png and Wisplet_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Wisplet`; check with `python3 -I tools/blocky/export_models.py --check --species Wisplet`.
