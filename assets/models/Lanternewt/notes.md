# Lanternewt blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Lanternewt (Uncommon)
- Concept: newt, glowing tail
- Body: Cylinder, placeholder colour #FF8C42, placeholder scale 1
- Accessory: tail (keyword match on the concept; colour rule: gold, #FFC83D)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1342 (look pass 2026-10-05 over the 1024-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.27 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF8C42, BodyDark #A65B2B, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Lanternewt.glb (51768 bytes), Lanternewt.fbx (41180 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
