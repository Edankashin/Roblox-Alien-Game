---
name: import-model
description: Import a species or prop model from assets/models into Roblox Studio and wire it to its data row. Use when asked to import, place or test a GLB/FBX model, or to replace a placeholder shape with a mesh.
---

# Import a model into Studio

The repo keeps one folder per asset under `assets/models/<Id>/` with `<Id>.glb`, `<Id>.fbx`, a `notes.md` and thumbnails. Models are built by `tools/blender/alien_base.py` (blockouts) or by an external generator (Claude Design, Meshy, Tripo) and are never loaded by Rojo: Studio imports them.

## Steps

1. Read `assets/models/<Id>/notes.md` for the triangle count, the height in studs and the material list. Aliens are 2 to 3 studs tall at 1 unit = 1 stud.
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
