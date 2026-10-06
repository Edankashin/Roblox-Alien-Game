# GeyserVent hero piece

- Date: 2026-10-06
- Tool: tools/blender/heroes_base.py, bpy 5.2.2 LTS
- What: World 2 geyser vent: a cracked rock cone, a hot rim, a blue pool and a glowing steam column
- Footprint (W x D x H, studs): 14.19 x 14.00 x 10.65 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 10.65; pivot at the bottom centre (origin), the piece stands on z = 0
- Triangles: 1940 (hero budget 1500 to 3000)
- Colours / materials (one per colour, flat, no textures): Rock #6B4A36, Crack #2A1A12, Rim #D98A4E, Water #4FB3D9, Glow #F2FBFF (emissive 2.0, Neon in Studio)
- Read distance: built to read at 60 studs (big shapes, no small detail)
- Files: GeyserVent.glb (142424 bytes), GeyserVent.fbx (71660 bytes), materials.json
- Review render: docs/vault/05-ui-design/refs/look-l3/GeyserVent.png
- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `GeyserVent`, parent under ReplicatedStorage.Models.Props, Anchored on.
