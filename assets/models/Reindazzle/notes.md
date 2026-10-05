# Reindazzle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Reindazzle (Rare)
- Concept: reindeer, icicle antlers, nose blinks
- Body: Ball, placeholder colour #C9D6E8, placeholder scale 1.1
- Accessory: antlers (keyword match on the concept; colour rule: sky, #33B6FF, metallic)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1450 (look pass 2026-10-05 over the 1120-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 3.65 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C9D6E8, BodyDark #838B97, EyeWhite, Pupil, Mouth, Accessory #33B6FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Reindazzle.glb (43384 bytes), Reindazzle.fbx (41804 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
