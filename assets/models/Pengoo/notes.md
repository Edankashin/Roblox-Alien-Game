# Pengoo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Pengoo (Uncommon)
- Concept: round penguin, tiny backpack, belly-slides everywhere
- Body: Ball, placeholder colour #2B3F5C, placeholder scale 0.9
- Accessory: the tiny backpack and the belly-slide pose (silhouette pass; #FF8A3D)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1486 (silhouette pass, tools/blender/species_bodies.py)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #2B3F5C, BodyDark #1C293C, EyeWhite, Pupil, Mouth, Accessory #FF8A3D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Pengoo.glb (41460 bytes), Pengoo.fbx (41548 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a plump penguin lying flat on its belly mid-slide, head up in front, flippers swept back, orange feet kicked up behind, a tiny box backpack on its back. Hero: the tiny backpack and the belly-slide pose.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
