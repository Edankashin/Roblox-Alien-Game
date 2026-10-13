# Gaiabloom blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Gaiabloom (Legendary)
- Concept: stag, tree antlers, flowers bloom where it steps
- Body: Ball, placeholder colour #2ECC71, placeholder scale 1.25
- Accessory: the tree antlers: bark branches with blossoms, wider than the head (silhouette pass; #FF8FB3)
- Tier dressing: tier size 125% (carried by placeholder.scale), halo torus, ground ring torus
- Triangles: 2024 (silhouette pass, tools/blender/species_bodies.py)
- Height: 4.14 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #2ECC71, BodyDark #8A5A2F, EyeWhite, Pupil, Mouth, Accessory #FF8FB3, Trim #F59E0B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Gaiabloom.glb (38136 bytes), Gaiabloom.fbx (39484 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a long-legged stag with its head high on a curved neck, a branching tree for antlers blossoming pink, a gold halo ring behind the head and a gold ring on the ground round its feet. Hero: the tree antlers: bark branches with blossoms, wider than the head.
