# Rocklobber blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Rocklobber (Rare)
- Concept: crab, boulder claws
- Body: Block, placeholder colour #C0392B, placeholder scale 1.1
- Accessory: claws (keyword match on the concept; colour rule: complement, #2BC083, metallic)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1422 (look pass 2026-10-05 over the 892-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 2.42 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C0392B, BodyDark #7D251C, EyeWhite, Pupil, Mouth, Accessory #2BC083
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Rocklobber.glb (42880 bytes), Rocklobber.fbx (38460 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
