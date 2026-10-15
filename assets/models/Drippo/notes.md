# Drippo blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Drippo (Common)
- Concept: icicle drop, stubby legs, drips when nervous
- Body: Cylinder, placeholder colour #A9D6F5, placeholder scale 0.8
- Accessory: the drip-drop body with its falling droplet (silhouette pass; #FF8E5B)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1350 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.11 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #A9D6F5, BodyDark #6FA9D6, EyeWhite, Pupil, Mouth, Accessory #FF8E5B
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Drippo.glb (47404 bytes), Drippo.fbx (38636 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a tall drop with a round belly and a long pointed top wearing a tiny knitted cap with a pompom, two stubby legs and a small droplet floating beside it. Hero: the drip-drop body with its falling droplet.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
