# Panpipe block-cell model

- Date: 2026-10-26
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Panpipe.md (Syrinx, World 1, Secret, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 206
- Triangles: 2568 (cap 6000)
- Cells: 0.0625 studs a cell, atlas Panpipe_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `aura` (moves, Neon, pivot 0.0625, 0.0312, -0.0375); `beardR` (moves, cells, pivot 0.5379, 1, -1.5821); `bellR` (moves, cells, pivot 0.625, 1, -1.5); `earL` (moves, cells, pivot -0.5797, 2.1875, -1.5516); `earR` (moves, cells, pivot 1.2329, 2.1875, -0.7063); `echoR` (moves, Neon, pivot 1.3125, 3.375, 1.1875); `eclipse` (moves, Neon, pivot 0.0625, 1.75, 1.875); `gemR` (moves, Neon, pivot 0.7625, 2.3125, -2.0636); `pipesR` (moves, Neon, pivot 1.2188, 1.625, 1.1875); `shards` (moves, cells, pivot 0.0625, 1.5, -0.1875); `tail` (moves, cells, pivot 0.0625, 1.625, 1.625); `FacePlate` (the face sheet, frame 0)
- Eyes: `echo`; the face plate is 224x96 px a frame, 13 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5, cycle6, cycle7) in Panpipe_face.png, 4 a row (Rigs face.columns)
- Rig: 11 moving parts, root clips 1, flourish every 16s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Panpipe.glb (283040 bytes), Panpipe.fbx (205980 bytes, texture embedded), Panpipe_atlas.png, Panpipe_face.png, materials.json, Panpipe.png and Panpipe_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Panpipe`; check with `python3 -I tools/blocky/export_models.py --check --species Panpipe`.
