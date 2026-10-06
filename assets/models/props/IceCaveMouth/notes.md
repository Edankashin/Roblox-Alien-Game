# IceCaveMouth hero piece

- Date: 2026-10-06
- Tool: tools/blender/heroes_base.py, bpy 5.2.2 LTS
- What: World 2 ice cave mouth: an icy arch with a snow cap, an icicle fringe and a dark interior
- Footprint (W x D x H, studs): 15.20 x 7.80 x 12.20 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 12.20; pivot at the bottom centre (origin), the piece stands on z = 0
- Triangles: 2462 (hero budget 1500 to 3000)
- Colours / materials (one per colour, flat, no textures): Ice #CFEAF7, IceBlue #6EC6F0, Snow #F7FBFF, Dark #0E1A26
- Read distance: built to read at 60 studs (big shapes, no small detail)
- Files: IceCaveMouth.glb (184584 bytes), IceCaveMouth.fbx (85612 bytes), materials.json
- Review render: docs/vault/05-ui-design/refs/look-l3/IceCaveMouth.png
- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `IceCaveMouth`, parent under ReplicatedStorage.Models.Props, Anchored on.
