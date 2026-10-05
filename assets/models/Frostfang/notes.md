# Frostfang blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Frostfang (Epic)
- Concept: sabre-tooth cub, icicle fangs, quill ruff, sneezes snowflakes
- Body: Ball, placeholder colour #6FB7E9, placeholder scale 1.2
- Accessory: quills (keyword match on the concept; colour rule: complement, #E96974)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1250 (budget 500 to 1500, detail level 0)
- Height: 3.37 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #6FB7E9, BodyDark #487797, EyeWhite, Pupil, Mouth, Accessory #E96974, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Frostfang.glb (46688 bytes), Frostfang.fbx (45196 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
