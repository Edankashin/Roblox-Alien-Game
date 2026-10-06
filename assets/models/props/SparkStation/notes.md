# SparkStation prop

- Date: 2026-10-06
- Tool: tools/blender/props_base.py, bpy 5.2.2 LTS
- What: Glow flower: green stem, six purple petals, emissive centre ball
- Footprint (W x D x H, studs): 2.12 x 1.95 x 4.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 4.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 716 (budget 300 to 900)
- Colours / materials (one per colour, flat, no textures): Stem #3F9B3A, Petal #A855F7, Glow #FFC83D (emissive 2.0)
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: SparkStation.glb (50512 bytes), SparkStation.fbx (31788 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `SparkStation`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
