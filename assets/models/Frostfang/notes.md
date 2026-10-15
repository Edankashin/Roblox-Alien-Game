# Frostfang blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Frostfang (Epic)
- Concept: sabre-tooth cub, icicle fangs, quill ruff, sneezes snowflakes
- Body: Ball, placeholder colour #6FB7E9, placeholder scale 1.2
- Accessory: the icicle fangs (silhouette pass; #E8F7FF)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1548 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.37 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #6FB7E9, BodyDark #487797, EyeWhite, Pupil, Mouth, Accessory #E8F7FF, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Frostfang.glb (46688 bytes), Frostfang.fbx (45196 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a stocky sabre-tooth cub on all fours with an oversized head, two long icicle fangs hanging far below its open mouth and a spiked collar of nine ice quills round its neck. Hero: the icicle fangs.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
