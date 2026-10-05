# Glimmo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Glimmo (Common)
- Concept: jelly firefly
- Body: Ball, placeholder colour #FFE066, placeholder scale 0.8
- Accessory: glow_bulb (keyword match on the concept; colour rule: complement, #66D2FF, emissive)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1012 (budget 500 to 1500, detail level 0)
- Height: 2.70 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FFE066, BodyDark #A69242, EyeWhite, Pupil, Mouth, Accessory #66D2FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Glimmo.glb (37840 bytes), Glimmo.fbx (39084 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
