# Shellberg blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Shellberg (Rare)
- Concept: tortoise, iceberg shell, nine-tenths hidden
- Body: Block, placeholder colour #3FBFB0, placeholder scale 1.1
- Accessory: the iceberg shell with its glowing crystal peaks and vein (silhouette pass; #CFF1FF, emissive 1.2)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1760 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.76 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #3FBFB0, BodyDark #E8785A, EyeWhite, Pupil, Mouth, Accessory #CFF1FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Shellberg.glb (43976 bytes), Shellberg.fbx (40780 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a tortoise under a huge jagged iceberg shell crowned with six glowing crystal peaks, its head peeking out of the front in a little knitted cap with a pompom. Hero: the iceberg shell with its glowing crystal peaks and vein.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
