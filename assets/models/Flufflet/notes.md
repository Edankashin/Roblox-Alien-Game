# Flufflet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Flufflet (Common)
- Concept: snowball, knitted scarf, mitten ears
- Body: Ball, placeholder colour #F2F6FA, placeholder scale 1
- Accessory: the knitted scarf: a ring round the neck and one streamer flicking out with tassels (silhouette pass; #FF7A59)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1564 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F2F6FA, BodyDark #9DB7D5, EyeWhite, Pupil, Mouth, Accessory #FF7A59
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Flufflet.glb (35780 bytes), Flufflet.fbx (38364 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a tall snowball with a knitted coral scarf round its neck, one long streamer whipping out behind and to the side, and two blue mitten-shaped ears. Hero: the knitted scarf: a ring round the neck and one streamer flicking out with tassels.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
