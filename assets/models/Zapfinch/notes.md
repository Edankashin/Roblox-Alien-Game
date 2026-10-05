# Zapfinch blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Zapfinch (Rare)
- Concept: bird, antenna crest
- Body: Ball, placeholder colour #5DADE2, placeholder scale 0.9
- Accessory: crest (keyword match on the concept; colour rule: complement, #E25D6B, metallic)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1008 (budget 500 to 1500, detail level 0)
- Height: 2.86 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #5DADE2, BodyDark #3C7093, EyeWhite, Pupil, Mouth, Accessory #E25D6B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Zapfinch.glb (38352 bytes), Zapfinch.fbx (39436 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
