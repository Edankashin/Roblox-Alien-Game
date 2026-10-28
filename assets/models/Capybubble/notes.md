# Capybubble block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Capybubble.md (Snorzo, World 2, Rare, status review)
- Height: 3.253 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 71
- Triangles: 1114 (cap 2500)
- Cells: 0.125 studs a cell, atlas Capybubble_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `earL` (moves, cells, pivot -0.8669, 1.6748, -1.6808); `earR` (moves, cells, pivot 0.7423, 1.901, -1.6808); `leafL` (moves, cells, pivot -0.0876, 2.8665, -1.3621); `ring` (moves, cells, pivot 0.0625, 1.3, 0.2689); `FacePlate` (the face sheet, frame 0)
- Eyes: `bubble`; the face plate is 224x96 px a frame, 5 frames (open, half, closed, glint1, glint2) in Capybubble_face.png, 4 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish every 9s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Capybubble.glb (97608 bytes), Capybubble.fbx (86620 bytes, texture embedded), Capybubble_atlas.png, Capybubble_face.png, materials.json, Capybubble.png and Capybubble_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Capybubble`; check with `python3 -I tools/blocky/export_models.py --check --species Capybubble`.
