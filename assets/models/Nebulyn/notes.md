# Nebulyn blockout

- Date: 2026-10-13
- Tool: tools/blender/alien_base.py, bpy 5.2.2 LTS
- Name: Nebulyn (Legendary)
- Concept: a small nebula cloud with two bright eyes and a trailing tail of stars
- Body: Ball, placeholder colour #7B5CFF, placeholder scale 1.3
- Accessory: tail (keyword match on the concept; colour rule: complement, #FFCD5C)
- Tier dressing: tier size 125% (carried by placeholder.scale), halo torus, ground ring torus
- Triangles: 1452 (budget 500 to 1500, detail level 0)
- Height: 3.52 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #7B5CFF, BodyDark #503CA6, EyeWhite, Pupil, Mouth, Accessory #FFCD5C, Trim #F59E0B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Nebulyn.glb (50992 bytes), Nebulyn.fbx (48076 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
