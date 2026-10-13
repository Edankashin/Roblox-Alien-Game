# Pebblet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Pebblet (Common)
- Concept: pebble with legs
- Body: Block, placeholder colour #9A9A9A, placeholder scale 0.9
- Accessory: the legs: a pebble with real legs, daylight under its belly (silhouette pass; #78C850)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1108 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.36 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #9A9A9A, BodyDark #6B6760, EyeWhite, Pupil, Mouth, Accessory #78C850
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Pebblet.glb (39704 bytes), Pebblet.fbx (36476 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a faceted egg-shaped stone lifted on two long legs with big flat feet, stone-chip fists out to the sides and a mossy patch on top. Hero: the legs: a pebble with real legs, daylight under its belly.
