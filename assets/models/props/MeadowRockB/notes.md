# MeadowRockB prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Wider, flatter boulder with a moss cap
- Footprint (W x D x H, studs): 5.00 x 4.00 x 2.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 2.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 400 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Rock #8E8E8E, Moss #3F9B3A
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: MeadowRockB.glb (27088 bytes), MeadowRockB.fbx (26828 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `MeadowRockB`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
