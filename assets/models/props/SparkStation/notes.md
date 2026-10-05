# SparkStation prop

- Date: 2026-10-05
- Tool: tools/blender/props_base.py, bpy 5.0.1
- What: Glow flower: green stem, six purple petals, emissive centre ball
- Footprint (W x D x H, studs): 2.09 x 1.84 x 4.00 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 4.00; pivot at the bottom centre (origin), the model stands on z = 0
- Triangles: 240 (budget 40 to 600)
- Colours / materials (one per colour, flat, no textures): Stem #3F9B3A, Petal #A855F7, Glow #FFC83D (emissive 2.0)
- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file
- Files: SparkStation.glb (18556 bytes), SparkStation.fbx (21628 bytes)
- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `SparkStation`, parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md.

Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.
