# Snowbun block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Snowbun.md (Flurra, World 2, Common, status review)
- Height: 2.471 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 11
- Triangles: 226 (cap 2500)
- Cells: 0.125 studs a cell, atlas Snowbun_atlas.png 512x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `earL` (moves, cells, pivot -0.091, 1.5, -0.8125); `earR` (moves, cells, pivot 0.909, 1.5, -0.8125); `nose` (moves, cells, pivot 0.409, 1.0625, -1.4375); `tail` (moves, cells, pivot 0.409, 0, 0.8125); `FacePlate` (the face sheet, frame 0)
- Eyes: `dot`; the face plate is 28x10 px a frame, 3 frames (open, half, closed) in Snowbun_face.png, 3 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Snowbun.glb (29724 bytes), Snowbun.fbx (51740 bytes, texture embedded), Snowbun_atlas.png, Snowbun_face.png, materials.json, Snowbun.png and Snowbun_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Snowbun`; check with `python3 -I tools/blocky/export_models.py --check --species Snowbun`.
