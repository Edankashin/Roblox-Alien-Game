# Toastoad blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Toastoad (Uncommon)
- Concept: toad, pebble backpack, soaks till it wrinkles
- Body: Ball, placeholder colour #E8713A, placeholder scale 0.9
- Accessory: the pebble backpack (silhouette pass; #9FB3C8)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1596 (silhouette pass, tools/blender/species_bodies.py)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #E8713A, BodyDark #974926, EyeWhite, Pupil, Mouth, Accessory #9FB3C8
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Toastoad.glb (41472 bytes), Toastoad.fbx (41580 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a very wide squat toad with two eye bumps under heavy lids, three wrinkle ridges across its back, bent hind legs and a lumpy cluster of blue pebbles on its back. Hero: the pebble backpack.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
