# Chipmole blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Chipmole (Common)
- Concept: mole, ice-pick claws, chips the floor
- Body: Block, placeholder colour #5B6B85, placeholder scale 0.9
- Accessory: claws (keyword match on the concept; colour rule: complement, #BF6356)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1422 (look pass 2026-10-05 over the 892-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #5B6B85, BodyDark #3B4656, EyeWhite, Pupil, Mouth, Accessory #BF6356
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Chipmole.glb (42884 bytes), Chipmole.fbx (38172 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
