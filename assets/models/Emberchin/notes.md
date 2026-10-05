# Emberchin blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Emberchin (Uncommon)
- Concept: sea urchin, ember quills, hops between pools
- Body: Ball, placeholder colour #FF9E4A, placeholder scale 0.8
- Accessory: quills (keyword match on the concept; colour rule: complement, #4AFFF9)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1416 (look pass 2026-10-05 over the 1058-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.24 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF9E4A, BodyDark #A66730, EyeWhite, Pupil, Mouth, Accessory #4AFFF9
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Emberchin.glb (40792 bytes), Emberchin.fbx (40396 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
