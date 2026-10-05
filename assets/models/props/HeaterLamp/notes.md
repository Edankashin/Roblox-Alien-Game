# HeaterLamp prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Brazier on three legs with three emissive flame cones
- Footprint (W x D x H, studs): 3.00 x 3.00 x 2.60 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 2.60; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 212 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Metal #3A4049, Glow #FF8C42 (emissive 2.0)
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: HeaterLamp.glb (12728 bytes), HeaterLamp.fbx (18892 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `HeaterLamp`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
