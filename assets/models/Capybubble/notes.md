# Capybubble blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Capybubble (Rare)
- Concept: capybara, tangerine hat, snores bubbles
- Body: Ball, placeholder colour #E0C3A0, placeholder scale 1.1
- Accessory: the tangerine hat and the snore bubbles (silhouette pass; #FF8A1F, emissive 1)
- Tier dressing: tier size 110% (carried by placeholder.scale), metallic accessory
- Triangles: 1762 (silhouette pass, tools/blender/species_bodies.py)
- Height: 2.98 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #E0C3A0, BodyDark #927F68, EyeWhite, Pupil, Mouth, Accessory #FF8A1F
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Capybubble.glb (37696 bytes), Capybubble.fbx (40140 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a long barrel-shaped capybara loafing low with a tangerine on its head and a string of growing bubbles rising up and to the side from its snoring mouth. Hero: the tangerine hat and the snore bubbles.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
