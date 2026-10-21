---
name: import-model
description: Import a species or prop model from assets/models into Roblox Studio and wire it to its data row. Use when asked to import, place or test a GLB/FBX model, or to replace a placeholder shape with a mesh.
---

# Import a model into Studio

The repo keeps one folder per asset under `assets/models/<Id>/` with `<Id>.glb`, `<Id>.fbx`, a `notes.md` and thumbnails. Since 2026-10-21 every species folder holds a **block-cell model** from `tools/blocky/export_models.py` (Decision B46; the old `alien_base.py` blockouts are retired); the props are still `props_base.py` builds. Nothing here is loaded by Rojo: Studio imports it.

## Block-cell aliens (the 35 species)

Each folder has `<Id>.glb` and `<Id>.fbx` (the same model: 1 unit = 1 stud, 2 to 3.5 studs tall, facing -Z with its right on +X, origin at the bottom centre, so `Config.ModelFacesPlusZ` stays false), `<Id>_atlas.png` (the cell atlas), `<Id>_face.png` (the face plate's flipbook), `materials.json` (one entry a MeshPart: name, colour, Neon by `emission`, the `colorMap` it samples) and `notes.md` (height, triangles, parts, eyes, frames). The meshes are named: `Body` (every static cell block), `Glow` (static glow, Neon), each moving part by its name in `src/shared/data/Rigs.luau` with its origin on its pivot, and `FacePlate`.

1. `python3 -I tools/blocky/export_models.py --check --species <Id>` prints `ok` (the files match the note and Rigs.luau).
2. In Studio: File > Import 3D, pick `<Id>.fbx` (or the `.glb`), scale 1. Keep the textures the importer offers. Leave the Model selected.
3. Paste `tools/studio/install_models.luau` into the command bar (its BLOCK_CELL table is current: `python3 -I tools/blocky/export_models.py --emit-luau` regenerates it) and press Enter. For a block-cell species it never loads the old blockout id; it takes the selected Model, keeps every part's name (warns by name if the importer renamed or merged one: that part will not animate), puts the imported texture on a SurfaceAppearance with `ResampleMode = Pixelated` (the plate with `AlphaMode = Transparency`), makes `Glow` parts Neon, anchors everything with collisions and queries off, sets the pivot at the feet and moves it to `ReplicatedStorage.Models.<Id>`.
4. Check: height beside a 5-stud avatar matches `notes.md`; the cells are crisp squares, not blurred; Play, and the moving parts animate (World.RigAnimator finds them by name) and the eyes blink by squashing the plate (the flipbook takes over once `<Id>_face.png` is uploaded and its id is in Rigs.luau `face.image`).
5. Ids stay 0 until Ethan uploads (B27): the model through `python3 tools/upload_assets.py --redo --only <Id>` (drops the `pendingUpload` marker in `asset_ids.json`; then `--emit-luau` for the installer's tables and `export_models.py --emit-luau` for BLOCK_CELL), the atlas and face sheet as images whose ids go into BLOCK_CELL's `cellMap` and `faceMap` and Rigs `face.image` by hand. Never invent an id.

## Steps (props and any other hand-made model)

1. Read `assets/models/<Id>/notes.md` for the triangle count, the height in studs and the material list. Aliens are 2 to 3.5 studs tall at 1 unit = 1 stud (B45).
2. In Studio: File > Import 3D, pick `<Id>.fbx` (the FBX faces -Z, Roblox's front; the GLB faces +Z and needs `Config.ModelFacesPlusZ = true`), keep scale 1, uncheck "Anchor" only if the model is a creature. One MeshPart per material comes in as a Model named `<Id>`.
3. Check the import: the Model's bounding box height matches `notes.md`, the MeshParts carry their Color from the material, nothing is transparent, the pivot sits at the feet (`Model.WorldPivot` at the bottom centre; set it if not).
4. Move the Model to `ReplicatedStorage.Models.<Id>` (create the folder once). Anchored true, CanCollide false, CanQuery false on every part: the client renderer positions it.
5. Wire the data row: `src/shared/data/Species.luau` (or the prop's table) gets `model = "<Id>"` on that row; the client renderer looks up `ReplicatedStorage.Models[model]` and falls back to the placeholder shape when it is missing. Never put an asset id in logic.
6. Play once: the species spawns with the mesh, the nameplate sits above it, the silhouette (shadow) rule still applies to uncaught species, and `./tools/analyze.sh` prints `analyze: clean`.
7. Record the import in `assets/models/<Id>/notes.md` (date, Studio version, anything adjusted) and in `docs/vault/06-art-pipelines/Blender-MCP.md` under "Record what works".

## Rules

- Do not upload to the Creator Store or change any asset id in the place from this skill; Open Cloud upload is a later, separate step.
- A rigged FBX with animations: import with "Rig type: Custom" and keep the AnimationController; the animation ids are added to the data row, not to code.
- Never commit `.rbxm` exports; the GLB/FBX in `assets/models` is the source.

## Props

Scenery and camp props (`assets/models/props/<Name>/`, from `tools/blender/props_base.py`) follow the same steps with these differences:

- Destination: `ReplicatedStorage.Models.Props.<Name>` (create `Models` and `Props` if missing), never `Models.<Name>`.
- Name rule: the Model's name is exactly the prop name in the layout's `Props` table, `Camp.Props` or `Config.HeaterPropName` (name = file name = instance name); a missing or misspelt name silently keeps the part placeholder.
- Keep scale 1, Anchored on for every part; set the `Glow` MeshPart's Material to Neon. No wiring step: the data tables already hold the names. Footprints must match `notes.md` (the placeholders use the same sizes).
- Test by pressing Play and checking Output for nothing red. Full workflow: `docs/vault/06-art-pipelines/Map-Dressing.md`.
