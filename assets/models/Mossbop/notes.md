# Mossbop blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Mossbop (Common)
- Concept: moss ball, eyes
- Body: Ball, placeholder colour #6BCB3F, placeholder scale 1
- Accessory: the moss: lumpy clumps over a smooth ball, and the sprout with an orange bud (silhouette pass; #FF8A3D)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1676 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #6BCB3F, BodyDark #3F8F2E, EyeWhite, Pupil, Mouth, Accessory #FF8A3D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Mossbop.glb (35800 bytes), Mossbop.fbx (38396 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a wide squat mound with a bumpy skyline of seven moss clumps, two big feet and one thin sprout with a bud leaning off the top. Hero: the moss: lumpy clumps over a smooth ball, and the sprout with an orange bud.
