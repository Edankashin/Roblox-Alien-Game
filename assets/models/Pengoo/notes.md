# Pengoo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Pengoo (Uncommon)
- Concept: round penguin, tiny backpack, belly-slides everywhere
- Body: Ball, placeholder colour #2B3F5C, placeholder scale 0.9
- Accessory: backpack (keyword match on the concept; colour rule: complement, #BF6056)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1012 (budget 500 to 1500, detail level 0)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #2B3F5C, BodyDark #1C293C, EyeWhite, Pupil, Mouth, Accessory #BF6056
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Pengoo.glb (41460 bytes), Pengoo.fbx (41548 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
