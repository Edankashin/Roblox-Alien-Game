# Panpipe blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Panpipe (Secret)
- Concept: goat, reed pipes
- Body: Ball, placeholder colour #1A1A1A, placeholder scale 1.3
- Accessory: the reed-pipe fan: seven glowing pipes in a half circle behind the head (silhouette pass; #4FD8FF, emissive 3)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory, black body
- Triangles: 1522 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.40 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #1A1A1A, BodyDark #E9DDBA, EyeWhite, Pupil, Mouth, Accessory #4FD8FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Panpipe.glb (36580 bytes), Panpipe.fbx (38684 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a round black goat on two stubby hooves with curling bone horns, a little beard and a fan of seven reed pipes spread behind its head like a peacock. Hero: the reed-pipe fan: seven glowing pipes in a half circle behind the head.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
