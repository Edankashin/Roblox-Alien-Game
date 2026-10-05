# Skaddle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Skaddle (Legendary)
- Concept: snow owl, tiny skis, frosty crest; echo of Skadi
- Body: Ball, placeholder colour #F7F9FC, placeholder scale 1.25
- Accessory: crest (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: tier size 125% (carried by placeholder.scale), halo torus, ground ring torus
- Triangles: 1392 (budget 500 to 1500, detail level 0)
- Height: 3.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F7F9FC, BodyDark #A1A2A4, EyeWhite, Pupil, Mouth, Accessory #33B6FF, Trim #F59E0B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Skaddle.glb (49176 bytes), Skaddle.fbx (46956 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
