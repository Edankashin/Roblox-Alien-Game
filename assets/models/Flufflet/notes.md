# Flufflet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Flufflet (Common)
- Concept: snowball, knitted scarf, mitten ears
- Body: Ball, placeholder colour #F2F6FA, placeholder scale 1
- Accessory: tuft (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1304 (look pass 2026-10-05 over the 946-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F2F6FA, BodyDark #9DA0A2, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Flufflet.glb (35780 bytes), Flufflet.fbx (38364 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
