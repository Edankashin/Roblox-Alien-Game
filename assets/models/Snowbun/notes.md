# Snowbun blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Snowbun (Common)
- Concept: snow bunny, snowball tail that keeps growing
- Body: Ball, placeholder colour #DDEBF7, placeholder scale 0.9
- Accessory: tail (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1068 (budget 500 to 1500, detail level 0)
- Height: 2.04 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #DDEBF7, BodyDark #9099A1, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Snowbun.glb (40184 bytes), Snowbun.fbx (40636 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
