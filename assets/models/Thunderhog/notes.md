# Thunderhog blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Thunderhog (Epic)
- Concept: hedgehog, lightning quills
- Body: Ball, placeholder colour #8E44AD, placeholder scale 1.2
- Accessory: quills (keyword match on the concept; colour rule: complement, #A7BF4B)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1450 (look pass 2026-10-05 over the 1250-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 3.37 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #8E44AD, BodyDark #5C2C70, EyeWhite, Pupil, Mouth, Accessory #A7BF4B, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Thunderhog.glb (46676 bytes), Thunderhog.fbx (45180 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
