# Fenripup blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Fenripup (Cosmic)
- Concept: puppy, glowing moon on its forehead; echo of Fenrir
- Body: Ball, placeholder colour #3B2E6B, placeholder scale 1.2
- Accessory: glow_bulb (keyword match on the concept; colour rule: gold, #FFC83D, emissive)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory
- Triangles: 1342 (look pass 2026-10-05 over the 1012-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 4.05 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #3B2E6B, BodyDark #261E46, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Fenripup.glb (37856 bytes), Fenripup.fbx (39452 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
