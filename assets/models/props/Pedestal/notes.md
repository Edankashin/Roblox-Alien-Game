# Pedestal prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Two stacked discs, radius 2.5 and 2.0 (one Stone material)
- Footprint (W x D x H, studs): 5.00 x 5.00 x 1.50 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 1.50; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 238 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Stone #C8C4A8
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: Pedestal.glb (12796 bytes), Pedestal.fbx (17340 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `Pedestal`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
