# Buzzlebee blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Buzzlebee (Uncommon)
- Concept: bee, tiny backpack
- Body: Ball, placeholder colour #F4C542, placeholder scale 0.8
- Accessory: the tiny backpack: a brown box with a flap, bigger than it should be, and a bright buckle (silhouette pass; #A8E6FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1498 (silhouette pass, tools/blender/species_bodies.py)
- Height: 1.76 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F4C542, BodyDark #6B4423, EyeWhite, Pupil, Mouth, Accessory #A8E6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Buzzlebee.glb (41472 bytes), Buzzlebee.fbx (41132 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a low round bee hovering on four dot feet, a head with huge eyes in front, a striped abdomen ending in a stinger, two wings up and out and a big box backpack. Hero: the tiny backpack: a brown box with a flap, bigger than it should be, and a bright buckle.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
