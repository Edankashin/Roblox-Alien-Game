# Sparkfox blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Sparkfox (Rare)
- Concept: fox, glowing paintbrush tail
- Body: Ball, placeholder colour #FF6B35, placeholder scale 1.1
- Accessory: tail (keyword match on the concept; colour rule: gold, #FFC83D, metallic)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1342 (look pass 2026-10-05 over the 1068-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.50 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF6B35, BodyDark #A64622, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Sparkfox.glb (40172 bytes), Sparkfox.fbx (40540 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
