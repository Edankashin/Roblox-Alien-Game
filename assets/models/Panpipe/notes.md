# Panpipe blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Panpipe (Secret)
- Concept: goat, reed pipes
- Body: Ball, placeholder colour #1A1A1A, placeholder scale 1.3
- Accessory: horns (keyword match on the concept; colour rule: sky, #33B6FF, emissive)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory, black body
- Triangles: 960 (budget 500 to 1500, detail level 0)
- Height: 3.40 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #1A1A1A, BodyDark #525252, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Panpipe.glb (36580 bytes), Panpipe.fbx (38684 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
