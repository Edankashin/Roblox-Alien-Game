# MeadowRock prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Lumpy grey boulder
- Footprint (W x D x H, studs): 4.00 x 4.00 x 2.80 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 2.80; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 80 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Rock #8E8E8E
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: MeadowRock.glb (6432 bytes), MeadowRock.fbx (17004 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `MeadowRock`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
