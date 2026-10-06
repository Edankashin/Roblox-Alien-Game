# GeyserCone prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Tapered vent cone with a crater dish sunk 1 stud into the top
- Footprint (W x D x H, studs): 6.00 x 6.00 x 7.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 7.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 406 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Cone #8C5A3C, Rim #D9A066, Crater #4A2E1E
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: GeyserCone.glb (22744 bytes), GeyserCone.fbx (23420 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `GeyserCone`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
