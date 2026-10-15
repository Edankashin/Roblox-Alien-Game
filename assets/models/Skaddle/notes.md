# Skaddle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Skaddle (Legendary)
- Concept: snow owl, tiny skis, frosty crest; echo of Skadi
- Body: Ball, placeholder colour #F7F9FC, placeholder scale 1.25
- Accessory: the tiny skis and the frosty crest (silhouette pass; #8FD8FF)
- Tier dressing: tier size 125% (carried by placeholder.scale), halo torus, ground ring torus
- Triangles: 1422 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F7F9FC, BodyDark #A9C5E0, EyeWhite, Pupil, Mouth, Accessory #8FD8FF, Trim #F59E0B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Skaddle.glb (49176 bytes), Skaddle.fbx (46956 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: an upright round snow owl on two tiny skis, frosty ice tufts on its head under a floating gold halo, and long wings held out and down like a pair of ski poles with baskets. Hero: the tiny skis and the frosty crest.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
