# Gloomoth blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Gloomoth (Epic)
- Concept: moth, crystal wings
- Body: Ball, placeholder colour #A569BD, placeholder scale 1.2
- Accessory: wings (keyword match on the concept; colour rule: complement, #A9BF56)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1256 (budget 500 to 1500, detail level 0)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #A569BD, BodyDark #6B447B, EyeWhite, Pupil, Mouth, Accessory #A9BF56, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Gloomoth.glb (44824 bytes), Gloomoth.fbx (45292 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
