# Wisplet blockout

- Date: 2026-10-13
- Tool: tools/blender/alien_base.py, bpy 5.2.2 LTS
- Name: Wisplet (Rare)
- Concept: will-o'-the-wisp, a floating lantern flame with a shy face
- Body: Ball, placeholder colour #9BE7FF, placeholder scale 0.8
- Accessory: tuft (keyword match on the concept; colour rule: complement, #FF7397, metallic)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 946 (budget 500 to 1500, detail level 0)
- Height: 2.11 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #9BE7FF, BodyDark #6596A6, EyeWhite, Pupil, Mouth, Accessory #FF7397
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Wisplet.glb (35744 bytes), Wisplet.fbx (37932 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
