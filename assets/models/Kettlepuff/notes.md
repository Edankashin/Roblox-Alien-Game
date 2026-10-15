# Kettlepuff blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Kettlepuff (Common)
- Concept: kettle, steam puff ring, whistles when excited
- Body: Cylinder, placeholder colour #F5EDE0, placeholder scale 1
- Accessory: the spout and the steam ring (silhouette pass; #E8793A)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1476 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.20 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #F5EDE0, BodyDark #9F9A92, EyeWhite, Pupil, Mouth, Accessory #E8793A
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Kettlepuff.glb (57204 bytes), Kettlepuff.fbx (43020 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a squat round kettle with a long upswept copper spout on one side, a looped handle on the other, a domed lid with a knob and a ring of six steam puffs floating above. Hero: the spout and the steam ring.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
