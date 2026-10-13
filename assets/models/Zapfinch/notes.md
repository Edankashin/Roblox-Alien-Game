# Zapfinch blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Zapfinch (Rare)
- Concept: bird, antenna crest
- Body: Ball, placeholder colour #5DADE2, placeholder scale 0.9
- Accessory: the antenna crest: three glowing rods ending in round tips (silhouette pass; #FFE45C, emissive 1.5)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1440 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.86 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #5DADE2, BodyDark #2F5F8F, EyeWhite, Pupil, Mouth, Accessory #FFE45C
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Zapfinch.glb (38352 bytes), Zapfinch.fbx (39436 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a plump bird balanced on two thin legs with a fan of three tail feathers behind, stubby wings out to the sides and a three-pronged antenna crest rising from the head. Hero: the antenna crest: three glowing rods ending in round tips.
