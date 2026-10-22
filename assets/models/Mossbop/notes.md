# Mossbop block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Mossbop.md (Moop, World 1, Common, status review)
- Height: 2.475 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 10
- Triangles: 214 (cap 2500)
- Cells: 0.125 studs a cell, atlas Mossbop_atlas.png 512x512, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `floatR` (moves, cells, pivot 0.75, 2.25, -0.8125); `sprout` (moves, cells, pivot 0, 2.25, 0.0625); `FacePlate` (the face sheet, frame 0)
- Eyes: `bean`; the face plate is 224x128 px a frame, 3 frames (open, half, closed) in Mossbop_face.png, 3 a row (Rigs face.columns)
- Rig: 2 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Mossbop.glb (26816 bytes), Mossbop.fbx (45116 bytes, texture embedded), Mossbop_atlas.png, Mossbop_face.png, materials.json, Mossbop.png and Mossbop_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Mossbop`; check with `python3 -I tools/blocky/export_models.py --check --species Mossbop`.
