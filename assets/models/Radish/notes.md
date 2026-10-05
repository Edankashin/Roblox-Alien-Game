# Radish blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Ra-dish (Cosmic)
- Concept: radiant radish, sun disk; echo of Ra
- Body: Ball, placeholder colour #FFB347, placeholder scale 1.2
- Accessory: sun_disk (keyword match on the concept; colour rule: gold, #FFC83D, emissive)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory
- Triangles: 1068 (budget 500 to 1500, detail level 0)
- Height: 3.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FFB347, BodyDark #A6742E, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Radish.glb (42136 bytes), Radish.fbx (42732 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
