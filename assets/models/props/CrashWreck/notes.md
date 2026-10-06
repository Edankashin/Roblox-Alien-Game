# CrashWreck hero piece

- Date: 2026-10-06
- Tool: tools/blender/heroes_base.py, bpy 5.2.2 LTS
- What: World 1 crash site: the hull split in two and half buried on a scorched disc, one bent fin, glowing embers
- Footprint (W x D x H, studs): 24.00 x 18.77 x 7.70 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 7.70; pivot at the bottom centre (origin), the piece stands on z = 0
- Triangles: 2044 (hero budget 1500 to 3000)
- Colours / materials (one per colour, flat, no textures): Scorch #2E2620, Hull #8A93A0, Plate #4A5160, Ember #FF7A1A (emissive 2.0, Neon in Studio), EmberB #FFC83D (emissive 2.0, Neon in Studio)
- Read distance: built to read at 60 studs (big shapes, no small detail)
- Files: CrashWreck.glb (120868 bytes), CrashWreck.fbx (63628 bytes), materials.json
- Review render: docs/vault/05-ui-design/refs/look-l3/CrashWreck.png
- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `CrashWreck`, parent under ReplicatedStorage.Models.Props, Anchored on.
