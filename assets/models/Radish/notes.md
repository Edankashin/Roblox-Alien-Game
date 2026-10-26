# Radish block-cell model

- Date: 2026-10-26
- Tool: tools/blocky/export_models.py (tools/blender/blocky_build.py, bpy 5.0.1); Decision B46, "Then finalize". Not uploaded (B27): every texture and image id is 0
- Spec note: docs/vault/07-alien-game/Creatures/Radish.md (Raddis, World 1, Cosmic, status review)
- Height: 3.5 studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike
- Blocks: 184
- Triangles: 2266 (cap 6000)
- Cells: 0.0625 studs a cell, atlas Radish_atlas.png 1024x1024, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)
- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): `Body` (every static block, the cell atlas); `Glow` (the static glow blocks, Neon); `aura` (moves, Neon, pivot 0, 0.0312, 0); `flame` (moves, cells, pivot 0, 2.875, -0.4); `frondL` (moves, cells, pivot -0.25, 2.875, 0.3125); `frondR` (moves, cells, pivot 0.25, 2.875, 0.3125); `gem` (moves, Neon, pivot 0, 2.6875, -0.9688); `halo` (moves, cells, pivot 0, 1.875, 1.1875); `pendant` (moves, Neon, pivot 0, 0.9375, -0.9375); `sunstone` (moves, cells, pivot 0, 1.6, 0); `wingL` (moves, cells, pivot -1.4375, 2, 1.375); `wingR` (moves, cells, pivot 1.4375, 2, 1.375); `FacePlate` (the face sheet, frame 0)
- Eyes: `solar`; the face plate is 224x112 px a frame, 13 frames (open, half, closed, glint1, glint2, cycle0, cycle1, cycle2, cycle3, cycle4, cycle5, cycle6, cycle7) in Radish_face.png, 4 a row (Rigs face.columns)
- Rig: 10 moving parts, root clips 2, flourish every 14s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)
- Files: Radish.glb (246916 bytes), Radish.fbx (184188 bytes, texture embedded), Radish_atlas.png, Radish_face.png, materials.json, Radish.png and Radish_grey.png (256 px previews)
- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model

Regenerate with `$BPY tools/blocky/export_models.py --species Radish`; check with `python3 -I tools/blocky/export_models.py --check --species Radish`.
