# Snailbyte blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Snailbyte (Uncommon)
- Concept: snail, metal shell
- Body: Ball, placeholder colour #7FB3D5, placeholder scale 1
- Accessory: shell (keyword match on the concept; colour rule: silver, #C8CDD3, metallic)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1126 (budget 500 to 1500, detail level 0)
- Height: 2.51 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #7FB3D5, BodyDark #53748A, EyeWhite, Pupil, Mouth, Accessory #C8CDD3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Snailbyte.glb (40072 bytes), Snailbyte.fbx (42204 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
