# MeadowTreeB prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Oak with a 10 tall trunk and a two-lobed crown
- Footprint (W x D x H, studs): 9.20 x 7.00 x 16.10 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 16.10; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 416 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Trunk #7B4A2D, Leaves #3F9B3A
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: MeadowTreeB.glb (33864 bytes), MeadowTreeB.fbx (28316 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `MeadowTreeB`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
