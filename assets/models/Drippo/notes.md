# Drippo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Drippo (Common)
- Concept: icicle drop, stubby legs, drips when nervous
- Body: Cylinder, placeholder colour #A9D6F5, placeholder scale 0.8
- Accessory: tuft (keyword match on the concept; colour rule: complement, #F56E7B)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 902 (budget 500 to 1500, detail level 0)
- Height: 2.11 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #A9D6F5, BodyDark #6E8B9F, EyeWhite, Pupil, Mouth, Accessory #F56E7B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Drippo.glb (47404 bytes), Drippo.fbx (38636 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
