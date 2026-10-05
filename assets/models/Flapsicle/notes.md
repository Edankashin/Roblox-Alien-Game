# Flapsicle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Flapsicle (Uncommon)
- Concept: bat, icicle wings, hangs upside down from nothing
- Body: Ball, placeholder colour #4A5A9C, placeholder scale 0.8
- Accessory: wings (keyword match on the concept; colour rule: complement, #BF7656)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1064 (budget 500 to 1500, detail level 0)
- Height: 1.76 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #4A5A9C, BodyDark #303B65, EyeWhite, Pupil, Mouth, Accessory #BF7656
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Flapsicle.glb (38960 bytes), Flapsicle.fbx (40476 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
