# GeyserCone prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Tapered vent cone with a crater dish sunk 1 stud into the top
- Footprint (W x D x H, studs): 6.00 x 6.00 x 7.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 7.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 106 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Cone #8C5A3C, Rim #B07A55, Crater #4A2E1E
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: GeyserCone.glb (7352 bytes), GeyserCone.fbx (18476 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `GeyserCone`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
