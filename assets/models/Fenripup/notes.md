# Fenripup blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Fenripup (Cosmic)
- Concept: puppy, glowing moon on its forehead; echo of Fenrir
- Body: Ball, placeholder colour #3B2E6B, placeholder scale 1.2
- Accessory: the forehead moon (silhouette pass; #FFC83D, emissive 3)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory
- Triangles: 2148 (silhouette pass, tools/blender/species_bodies.py)
- Height: 4.05 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #3B2E6B, BodyDark #261E46, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Fenripup.glb (37856 bytes), Fenripup.fbx (39452 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a big floppy-eared puppy sitting with a huge head, a thick tail curling up behind it, a glowing crescent moon on its forehead and four star shapes orbiting round it. Hero: the forehead moon.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
