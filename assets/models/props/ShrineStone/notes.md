# ShrineStone prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Standing stone, tapered and bevelled (one Stone material, tinted per world)
- Footprint (W x D x H, studs): 2.00 x 1.25 x 5.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 5.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 398 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Stone #9E9E8E
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: ShrineStone.glb (22208 bytes), ShrineStone.fbx (19820 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `ShrineStone`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
