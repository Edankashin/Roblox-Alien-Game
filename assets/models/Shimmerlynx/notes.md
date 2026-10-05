# Shimmerlynx blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Shimmerlynx (Epic)
- Concept: lynx, glowing aurora crest, purrs in colours
- Body: Ball, placeholder colour #C8C2F0, placeholder scale 1.2
- Accessory: crest (keyword match on the concept; colour rule: gold, #FFC83D)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1200 (budget 500 to 1500, detail level 0)
- Height: 3.82 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C8C2F0, BodyDark #827E9C, EyeWhite, Pupil, Mouth, Accessory #FFC83D, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Shimmerlynx.glb (44232 bytes), Shimmerlynx.fbx (43948 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
