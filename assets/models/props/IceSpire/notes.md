# IceSpire prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Faceted ice crystal cluster: a 10 tall shard and two leaning shards
- Footprint (W x D x H, studs): 6.64 x 3.63 x 10.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 10.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 66 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Ice #A9D8EA, IceTip #E8F7FD
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: IceSpire.glb (5660 bytes), IceSpire.fbx (17260 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `IceSpire`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
