# Glimmo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Glimmo (Common)
- Concept: jelly firefly
- Body: Ball, placeholder colour #FFE066, placeholder scale 0.8
- Accessory: the glowing firefly lamp hanging off its back (silhouette pass; #B8FF4F, emissive 3)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1216 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.70 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FFE066, BodyDark #E4A83A, EyeWhite, Pupil, Mouth, Accessory #B8FF4F
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Glimmo.glb (37840 bytes), Glimmo.fbx (39084 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a drooping bell on a flared skirt with a fringe of dangling tendrils, a fat round lamp swinging out behind and two bobble antennae. Hero: the glowing firefly lamp hanging off its back.
