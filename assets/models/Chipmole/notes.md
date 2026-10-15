# Chipmole blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Chipmole (Common)
- Concept: mole, ice-pick claws, chips the floor
- Body: Block, placeholder colour #5B6B85, placeholder scale 0.9
- Accessory: the ice-pick claws, raised like a cheer (silhouette pass; #9CD3F0)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1458 (silhouette pass, tools/blender/species_bodies.py)
- Height: 1.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #5B6B85, BodyDark #3B4656, EyeWhite, Pupil, Mouth, Accessory #9CD3F0
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Chipmole.glb (42884 bytes), Chipmole.fbx (38172 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a squat mole with a pointed snout and both arms raised, each fist gripping a tall pickaxe with a double-ended ice head, ice chips scattered round its feet. Hero: the ice-pick claws, raised like a cheer.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
