# Rocklobber blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Rocklobber (Rare)
- Concept: crab, boulder claws
- Body: Block, placeholder colour #C0392B, placeholder scale 1.1
- Accessory: the boulder claws, the raised one sprouting glowing amber crystals (silhouette pass; #FFA928, emissive 1.5)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1188 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.42 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #C0392B, BodyDark #8A857D, EyeWhite, Pupil, Mouth, Accessory #FFA928
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Rocklobber.glb (42880 bytes), Rocklobber.fbx (38460 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a wide flat crab on six thin legs: one huge boulder fist raised high with crystal spikes, the other fist small and low, so it leans like a boxer. Hero: the boulder claws, the raised one sprouting glowing amber crystals.
