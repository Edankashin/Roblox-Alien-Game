# Sparkfox blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Sparkfox (Rare)
- Concept: fox, glowing paintbrush tail
- Body: Ball, placeholder colour #FF6B35, placeholder scale 1.1
- Accessory: the paintbrush tail: a tapering handle, a ferrule ring and glowing bristles (silhouette pass; #FFE066, emissive 2)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1734 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.50 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF6B35, BodyDark #A8431C, EyeWhite, Pupil, Mouth, Accessory #FFE066
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Sparkfox.glb (40172 bytes), Sparkfox.fbx (40540 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a sitting fox with a round head, two tall pointed ears and cheek tufts, and a thick tail rising behind like a paintbrush with a glowing tip above the ears. Hero: the paintbrush tail: a tapering handle, a ferrule ring and glowing bristles.
