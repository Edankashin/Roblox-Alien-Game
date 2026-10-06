# IceRock prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Angular ice boulder with two small chunks
- Footprint (W x D x H, studs): 4.00 x 4.00 x 3.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 3.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 480 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): IceRock #A9B7C0
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: IceRock.glb (26052 bytes), IceRock.fbx (27020 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `IceRock`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
