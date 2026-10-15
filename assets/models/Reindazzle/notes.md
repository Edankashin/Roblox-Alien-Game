# Reindazzle blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Reindazzle (Rare)
- Concept: reindeer, icicle antlers, nose blinks
- Body: Ball, placeholder colour #C9D6E8, placeholder scale 1.1
- Accessory: the icicle antlers and the glowing nose (silhouette pass; #FF6B4A, emissive 2)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1444 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.65 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C9D6E8, BodyDark #8795AD, EyeWhite, Pupil, Mouth, Accessory #FF6B4A
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Reindazzle.glb (43384 bytes), Reindazzle.fbx (41804 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a slender reindeer prancing, body tilted up, front legs folded in the air, back legs trailing, a long neck, a tall fan of ten icicle spikes for antlers and a big round glowing nose. Hero: the icicle antlers and the glowing nose.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
