# Lanternewt blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Lanternewt (Uncommon)
- Concept: newt, glowing tail
- Body: Cylinder, placeholder colour #FF8C42, placeholder scale 1
- Accessory: the glowing tail lantern, with a cage ring and a cap (silhouette pass; #FFD84A, emissive 2.5)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1698 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.27 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF8C42, BodyDark #8C3F1C, EyeWhite, Pupil, Mouth, Accessory #FFD84A
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Lanternewt.glb (51768 bytes), Lanternewt.fbx (41180 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-13: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a long low newt on four splayed legs, chin near the ground, with its tail curling up and out to one side in a tall hook and a caged lantern hanging from the tip. Hero: the glowing tail lantern, with a cage ring and a cap.
