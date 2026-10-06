# IceSpire prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Faceted ice crystal cluster: a 10 tall shard and two leaning shards
- Footprint (W x D x H, studs): 6.68 x 5.40 x 10.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 10.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 358 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Ice #A9D8EA, IceTip #E8F7FD
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: IceSpire.glb (21624 bytes), IceSpire.fbx (23244 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `IceSpire`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
