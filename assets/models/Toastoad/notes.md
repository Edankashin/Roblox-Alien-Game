# Toastoad blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Toastoad (Uncommon)
- Concept: toad, pebble backpack, soaks till it wrinkles
- Body: Ball, placeholder colour #E8713A, placeholder scale 0.9
- Accessory: backpack (keyword match on the concept; colour rule: complement, #3AE8C8)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1370 (look pass 2026-10-05 over the 1012-triangle blockout; see docs/vault/06-art-pipelines/Blender-MCP.md) (budget 500 to 1500, detail level 0)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #E8713A, BodyDark #974926, EyeWhite, Pupil, Mouth, Accessory #3AE8C8
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Toastoad.glb (41472 bytes), Toastoad.fbx (41580 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
