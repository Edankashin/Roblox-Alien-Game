# Rocklobber blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Rocklobber (Rare)
- Concept: crab, boulder claws
- Body: Block, placeholder colour #C0392B, placeholder scale 1.1
- Accessory: the boulder claws, the raised one sprouting a tall crown of glowing amber crystals (silhouette pass; #FFA928, emissive 1.5)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1196 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.42 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C0392B, BodyDark #8A857D, EyeWhite, Pupil, Mouth, Accessory #FFA928
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Rocklobber.glb (42880 bytes), Rocklobber.fbx (38460 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a crab standing tall on six thin legs with its body lifted clear of the ground: one huge boulder fist raised beside it under a tall crown of amber crystals, the other fist small and low, so it leans like a boxer. Hero: the boulder claws, the raised one sprouting a tall crown of glowing amber crystals.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
