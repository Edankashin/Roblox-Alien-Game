# Spookum blockout

- Date: 2026-10-13
- Tool: tools/blender/alien_base.py, bpy 5.2.2 LTS
- Name: Spookum (Epic)
- Concept: round ghost, pumpkin grin, drifts an inch off the ground
- Body: Ball, placeholder colour #F2F2FF, placeholder scale 1.2
- Accessory: tuft (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1138 (budget 500 to 1500, detail level 0)
- Height: 3.17 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F2F2FF, BodyDark #9D9DA6, EyeWhite, Pupil, Mouth, Accessory #33B6FF, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Spookum.glb (41624 bytes), Spookum.fbx (42908 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
