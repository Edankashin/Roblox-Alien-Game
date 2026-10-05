# Pebblet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Pebblet (Common)
- Concept: pebble with legs
- Body: Block, placeholder colour #9A9A9A, placeholder scale 0.9
- Accessory: tuft (keyword match on the concept; colour rule: sky, #33B6FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1304 (look pass 2026-10-05 over the 774-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.37 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #9A9A9A, BodyDark #646464, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Pebblet.glb (39704 bytes), Pebblet.fbx (36476 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
