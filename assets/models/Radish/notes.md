# Radish blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Ra-dish (Cosmic)
- Concept: radiant radish, sun disk; echo of Ra
- Body: Ball, placeholder colour #FFB347, placeholder scale 1.2
- Accessory: the sun disk: a glowing disc with rays behind the whole body, wider than it (silhouette pass; #FFC83D, emissive 3)
- Tier dressing: tier size 150% (carried by placeholder.scale), emissive accessory
- Triangles: 1528 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.64 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FFB347, BodyDark #5DBB3A, EyeWhite, Pupil, Mouth, Accessory #FFC83D
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Radish.glb (42136 bytes), Radish.fbx (42732 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a round radish with four broad leaves curling out of its crown in front of a huge rising sun disk, wider than the body and fanned with nine rays, a tilted gold orbit ring round its waist and a root-tip tail. Hero: the sun disk: a glowing disc with rays behind the whole body, wider than it.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
