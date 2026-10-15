# Snailbyte blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Snailbyte (Uncommon)
- Concept: snail, metal shell
- Body: Ball, placeholder colour #7FB3D5, placeholder scale 1
- Accessory: the metal shell: a stepped spiral of five discs, silver and dark in turn (silhouette pass; #C8CDD3, metallic)
- Tier dressing: none (Common/Uncommon: the accessory is the prop)
- Triangles: 1676 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.51 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #7FB3D5, BodyDark #4F7390, EyeWhite, Pupil, Mouth, Accessory #C8CDD3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Snailbyte.glb (40072 bytes), Snailbyte.fbx (42204 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a long flat foot with the head raised on a neck like a periscope and a huge coiled disc shell standing up on its back, two eyestalk nubs. Hero: the metal shell: a stepped spiral of five discs, silver and dark in turn.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
