# Thunderhog blockout

- Date: 2026-10-05
- Tool: tools/blender/alien_base.py, bpy 5.0.1
- Name: Thunderhog (Epic)
- Concept: hedgehog, lightning quills
- Body: Ball, placeholder colour #8E44AD, placeholder scale 1.2
- Accessory: the lightning quills: zigzag bolts that glow (silhouette pass; #FFE23B, emissive 2)
- Tier dressing: tier size 120% (carried by placeholder.scale), collar torus
- Triangles: 1856 (silhouette pass, tools/blender/species_bodies.py)
- Height: 3.37 units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up
- Materials (one per colour, flat, no textures): Body #8E44AD, BodyDark #5C2C70, EyeWhite, Pupil, Mouth, Accessory #FFE23B, Trim #C026D3
- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.
- Files: Thunderhog.glb (46676 bytes), Thunderhog.fbx (45180 bytes)
- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).

Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.
- Silhouette pass 2026-10-15: rebuilt from primitives by tools/blender/species_bodies.py from tools/blender/species_recipes.py. Silhouette: a low pear-shaped hedgehog nosing forward, a magenta collar behind the face and a mane of thirteen jagged lightning-bolt quills fanned over its back. Hero: the lightning quills: zigzag bolts that glow.
- Surface pass 2026-10-15: smooth by angle (55 degrees), a 0.05-stud bevel with 2 segments on thick cubes and cylinders, a greyscale vertex gradient exported in the GLB (crown 1, belly 0.7, 0.18 more facing down); per-slot material, texture and glossy live in materials.json (docs/vault/06-art-pipelines/Surface-Pass.md).
