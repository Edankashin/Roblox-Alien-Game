# Mossbop blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Mossbop (Common)
- Concept: moss ball, eyes
- Body: Ball, placeholder colour #6BCB3F, placeholder scale 1
- Accessory: tuft (keyword match on the concept; colour rule: complement, #593FCB)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 946 (budget 500 to 1500, detail level 0)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #6BCB3F, BodyDark #468429, EyeWhite, Pupil, Mouth, Accessory #593FCB
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Mossbop.glb (35800 bytes), Mossbop.fbx (38396 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
