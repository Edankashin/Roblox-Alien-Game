# Emberchin blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Emberchin (Uncommon)
- Concept: sea urchin, ember quills, hops between pools
- Body: Ball, placeholder colour #FF9E4A, placeholder scale 0.8
- Accessory: the ember-tipped quill brim (silhouette pass; #FFD23F, emissive 2.5)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1468 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.24 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #FF9E4A, BodyDark #A66730, EyeWhite, Pupil, Mouth, Accessory #FFD23F
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Emberchin.glb (40792 bytes), Emberchin.fbx (40396 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a round urchin mid-hop wearing a cocked sun-hat: a small crown and a wide brim of twelve horizontal quills ending in glowing embers, one leg lifted. Hero: the ember-tipped quill brim.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
