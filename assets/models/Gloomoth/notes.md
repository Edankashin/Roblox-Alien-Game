# Gloomoth blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Gloomoth (Epic)
- Concept: moth, crystal wings
- Body: Ball, placeholder colour #A569BD, placeholder scale 1.2
- Accessory: the crystal wings: five flat shards a side, glowing teal (silhouette pass; #5CF0D0, emissive 1.5)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1264 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #A569BD, BodyDark #6B447B, EyeWhite, Pupil, Mouth, Accessory #5CF0D0, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Gloomoth.glb (44824 bytes), Gloomoth.fbx (45292 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a plump fuzzy moth on stubby legs with a ruff, two huge V-spread wings made of ten glowing crystal blades and two feathery antennae, a magenta gem on its chest. Hero: the crystal wings: five flat shards a side, glowing teal.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
