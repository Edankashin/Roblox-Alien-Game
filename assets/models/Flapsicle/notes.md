# Flapsicle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Flapsicle (Uncommon)
- Concept: bat, icicle wings, hangs upside down from nothing
- Body: Ball, placeholder colour #4A5A9C, placeholder scale 0.8
- Accessory: the icicle wings and the hanging pose (silhouette pass; #9FE3FF)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1104 (silhouette pass, tools/blender/species_bodies.py)
- Height: 1.76 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #4A5A9C, BodyDark #F28DA6, EyeWhite, Pupil, Mouth, Accessory #9FE3FF
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Flapsicle.glb (38960 bytes), Flapsicle.fbx (40476 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: an upside-down bat hanging by two tiny pink toes with nothing above them, wings folded round it as four hanging icicle blades, big pink ears, the head at the bottom. Hero: the icicle wings and the hanging pose.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
