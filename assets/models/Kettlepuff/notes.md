# Kettlepuff blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Kettlepuff (Common)
- Concept: kettle, steam puff ring, whistles when excited
- Body: Cylinder, placeholder colour #F5EDE0, placeholder scale 1
- Accessory: puff_ring (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1450 (look pass 2026-10-05 over the 1148-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.20 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F5EDE0, BodyDark #9F9A92, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Kettlepuff.glb (57204 bytes), Kettlepuff.fbx (43020 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
