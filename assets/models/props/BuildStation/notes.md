# BuildStation prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Workbench with a plank stack on one end and an anvil block on the other
- Footprint (W x D x H, studs): 5.00 x 3.00 x 2.50 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 2.50; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 168 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Wood #8B5A2B, Plank #C99A5B, Metal #8A93A0
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: BuildStation.glb (11612 bytes), BuildStation.fbx (18652 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `BuildStation`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
