# Puffpuff blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Puffpuff (Common)
- Concept: dandelion puff, face
- Body: Ball, placeholder colour #F7F7F7, placeholder scale 1
- Accessory: the dandelion puff: radiating wisps with yellow seed tips (silhouette pass; #FFD84A)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1640 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.20 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F7F7F7, BodyDark #8FC96A, EyeWhite, Pupil, Mouth, Accessory #FFD84A
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Puffpuff.glb (45616 bytes), Puffpuff.fbx (42412 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a starburst: a small ball ringed by about twenty wisps in even rings, each ending in a seed dot, standing on two leaf feet. Hero: the dandelion puff: radiating wisps with yellow seed tips.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
