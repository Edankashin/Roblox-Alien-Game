# GatherStation prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Picnic table: top at 1.5, two seat planks each side at 0.7, A-frame legs
- Footprint (W x D x H, studs): 6.00 x 3.00 x 1.50 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 1.50; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 668 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Top #FFC83D, Legs #A0722C
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: GatherStation.glb (32480 bytes), GatherStation.fbx (22684 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `GatherStation`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
