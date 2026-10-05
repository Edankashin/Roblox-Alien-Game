# Gaiabloom blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Gaiabloom (Legendary)
- Concept: stag, tree antlers, flowers bloom where it steps
- Body: Ball, placeholder colour #2ECC71, placeholder scale 1.25
- Accessory: antlers (keyword match on the concept; colour rule: complement, #C02ECC)
- Tier dressing: tier size 125% (carried by placeholder.scale), halo torus, ground ring torus
- Triangles: 1450 (look pass 2026-10-05 over the 920-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 1)
- Height: 4.14 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #2ECC71, BodyDark #1E8549, EyeWhite, Pupil, Mouth, Accessory #C02ECC, Trim #F59E0B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Gaiabloom.glb (38136 bytes), Gaiabloom.fbx (39484 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
