# Shrine hero piece

- Date: 2026-10-06
- Tool: tools/blender/heroes_base.py, bpy 5.2.2 LTS
- What: World 1 Warden shrine: a ring of twelve mossy stones, three leaning monoliths, a glowing orb on a plinth
- Footprint (W x D x H, studs): 18.40 x 17.80 x 8.43 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 8.43; pivot at the bottom centre (origin), the piece stands on z = 0
- Triangles: 2398 (hero budget 1500 to 3000)
- Colours / materials (one per colour, flat, no textures): Paving #B9B29A, Stone #8E8E80, Moss #5E9E3A, Glow #9BE7FF (emissive 2.0, Neon in Studio)
- Read distance: built to read at 60 studs (big shapes, no small detail)
- Files: Shrine.glb (182456 bytes), Shrine.fbx (84732 bytes), materials.json
- Review render: docs/vault/05-ui-design/refs/look-l3/Shrine.png
- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `Shrine`, parent under ReplicatedStorage.Models.Props, Anchored on.
