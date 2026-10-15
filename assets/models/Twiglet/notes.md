# Twiglet blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Twiglet (Common)
- Concept: stick bug, leaf hat
- Body: Cylinder, placeholder colour #8B5A2B, placeholder scale 1
- Accessory: the leaf hat, wider than the head, with its midrib (silhouette pass; #6FBF3F)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1292 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.71 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #8B5A2B, BodyDark #5C3A1C, EyeWhite, Pupil, Mouth, Accessory #6FBF3F
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Twiglet.glb (49272 bytes), Twiglet.fbx (40524 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a big round head on a thin stick body with four long bent legs like a spider, and a huge tilted leaf for a hat. Hero: the leaf hat, wider than the head, with its midrib.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
