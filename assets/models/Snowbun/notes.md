# Snowbun blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Snowbun (Common)
- Concept: snow bunny, snowball tail that keeps growing
- Body: Ball, placeholder colour #DDEBF7, placeholder scale 0.9
- Accessory: the tail that keeps growing: three snowballs in a rising curl (silhouette pass; #FF9EB5)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1684 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.04 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #DDEBF7, BodyDark #A9C3DD, EyeWhite, Pupil, Mouth, Accessory #FF9EB5
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Snowbun.glb (40184 bytes), Snowbun.fbx (40636 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a pear-shaped bunny sitting up with two long upright ears and a tail of three snowballs growing in a curl behind it, bigger than its head. Hero: the tail that keeps growing: three snowballs in a rising curl.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
