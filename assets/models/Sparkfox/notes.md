# Sparkfox block-cell model

- Date: 2026-10-28
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Sparkfox.md (Vixa, World 1, Rare, status review)
- Height: 3.1 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 84
- Triangles: 1166 (cap 2500)
- Cells: 0.125 studs a cell, atlas Sparkfox_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `earL` (moves, cells, pivot -0.8951, 2.1225, -1.125); `earR` (moves, cells, pivot 0.3359, 2.3395, -1.125); `floatR` (moves, Neon, pivot 1.4375, 2.1875, 2.5); `paints` (moves, cells, pivot -0.0625, 1.5, 0); `paletteL` (moves, cells, pivot -1.5625, 2.625, -1.75); `tailR` (moves, cells, pivot 0.3125, 1.125, 1.5); `FacePlate` (the face sheet, frame 0)
- Eyes: `glimmer`; the face plate is 224x96 px a frame, 5 frames (open, half, closed, glint1, glint2) in Sparkfox_face.png, 4 a row (Rigs face.columns)
- Rig: 6 moving parts, root clips 1, flourish every 8s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Sparkfox.glb (109192 bytes), Sparkfox.fbx (94748 bytes, texture embedded), Sparkfox_atlas.png, Sparkfox_face.png, materials.json, Sparkfox.png and Sparkfox_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Sparkfox`; check with `python3 -I tools/blocky/export_models.py --check --species Sparkfox`.
