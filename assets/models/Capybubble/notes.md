# Capybubble block-cell model

- Date: 2026-10-21
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Capybubble.md (Snorzo, World 2, Rare, status review)
- Height: 3.289 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 32
- Triangles: 634 (cap 2500)
- Cells: 0.125 studs a cell, atlas Capybubble_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `earL` (moves, cells, pivot -1.125, 2, -1.25); `earR` (moves, cells, pivot 0.5, 2, -1.25); `floatR` (moves, Neon, pivot 0.9375, 1, -1.625); `leafR` (moves, cells, pivot -0.1875, 3, -0.75); `FacePlate` (the face sheet, frame 0)
- Eyes: `bubble`; the face plate is 28x12 px a frame, 5 frames (open, half, closed, glint1, glint2) in Capybubble_face.png, 4 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish every 9s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Capybubble.glb (59268 bytes), Capybubble.fbx (68412 bytes, texture embedded), Capybubble_atlas.png, Capybubble_face.png, materials.json, Capybubble.png and Capybubble_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Capybubble`; check with `python3 -I tools/blocky/export_models.py --check --species Capybubble`.
