# Shimmerlynx blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Shimmerlynx (Epic)
- Concept: lynx, glowing aurora crest, purrs in colours
- Body: Ball, placeholder colour #C8C2F0, placeholder scale 1.2
- Accessory: the aurora crest: five glowing ribbons of glass (silhouette pass; #5CF0D0, emissive 1.5)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1674 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.82 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C8C2F0, BodyDark #827E9C, EyeWhite, Pupil, Mouth, Accessory #5CF0D0, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Shimmerlynx.glb (44232 bytes), Shimmerlynx.fbx (43948 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a sleek lynx sitting bolt upright on long front legs, tall tufted ears, a pink cheek ruff, and five waving aurora ribbons of different heights rising from between its ears. Hero: the aurora crest: five glowing ribbons of glass.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
