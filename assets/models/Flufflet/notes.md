# Flufflet block-cell model

- Date: 2026-10-22
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Flufflet.md (Mitt, World 2, Common, status review)
- Height: 2.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 12
- Triangles: 246 (cap 2500)
- Cells: 0.125 studs a cell, atlas Flufflet_atlas.png 512x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `ball` (moves, cells, pivot 0, 0.375, 0.1875); `earL` (moves, cells, pivot -0.875, 1.75, 0.1875); `earR` (moves, cells, pivot 0.875, 1.75, 0.1875); `scarfR` (moves, cells, pivot 0.75, 0.875, -0.9375); `FacePlate` (the face sheet, frame 0)
- Eyes: `beam`; the face plate is 224x72 px a frame, 3 frames (open, half, closed) in Flufflet_face.png, 3 a row (Rigs face.columns)
- Rig: 4 moving parts, root clips 1, flourish none; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Flufflet.glb (35664 bytes), Flufflet.fbx (56444 bytes, texture embedded), Flufflet_atlas.png, Flufflet_face.png, materials.json, Flufflet.png and Flufflet_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Flufflet`; check with `python3 -I tools/blocky/export_models.py --check --species Flufflet`.
