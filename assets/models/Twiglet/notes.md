# Twiglet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Twiglet (Common)
- Concept: stick bug, leaf hat
- Body: Cylinder, placeholder colour #8B5A2B, placeholder scale 1
- Accessory: leaf_hat (keyword match on the concept; colour rule: complement, #3BBFBE)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 968 (budget 500 to 1500, detail level 0)
- Height: 2.71 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #8B5A2B, BodyDark #5A3B1C, EyeWhite, Pupil, Mouth, Accessory #3BBFBE
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Twiglet.glb (49272 bytes), Twiglet.fbx (40524 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
