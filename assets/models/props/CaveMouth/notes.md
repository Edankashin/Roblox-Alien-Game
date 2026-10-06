# CaveMouth hero piece

- Date: 2026-10-06
- Tool: tools/blender/heroes_base.py, bpy 5.2.2 LTS
- What: World 1 cave mouth: an arch of three boulders, a dark interior, two glowing crystal clusters
- Footprint (W x D x H, studs): 15.40 x 7.39 x 12.30 (Blender X x Y x Z; Y becomes Roblox Z on export)
- Vertical extent: z 0.00 to 12.30; pivot at the bottom centre (origin), the piece stands on z = 0
- Triangles: 2236 (hero budget 1500 to 3000)
- Colours / materials (one per colour, flat, no textures): Rock #6E6A64, Dark #15120F, Crystal #7FE3FF (emissive 2.0, Neon in Studio), CrystalB #C084FC (emissive 2.0, Neon in Studio)
- Read distance: built to read at 60 studs (big shapes, no small detail)
- Files: CaveMouth.glb (169084 bytes), CaveMouth.fbx (80076 bytes), materials.json
- Review render: docs/vault/05-ui-design/refs/look-l3/CaveMouth.png
- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `CaveMouth`, parent under ReplicatedStorage.Models.Props, Anchored on.
