--!strict
-- The shared tileable surface textures (docs/vault/06-art-pipelines/Surface-Pass.md, layer C). Five sets, each a
-- colour, a normal and a roughness map baked by tools/blender/bake_textures.py into assets/textures/<key>/ as
-- 512 x 512 PNGs, uploaded once as images (the Mac session) and assigned to a model slot by the slot's `texture`
-- key in its materials.json (tools/model_assets.py puts it in data/ModelAssets.Surfaces). The ids are Image ids, not
-- Decal ids. An id of 0 means not uploaded yet: Services/Models adds a SurfaceAppearance only when all three ids are
-- non-zero, so the game runs with or without the sets. The colour maps are near-white detail (a grey-green weave, a
-- moss pattern): the slot's own colour tints them through SurfaceAppearance.Color, so one set serves every species.
-- tiling = { u, v }: repeats of the map across each mesh primitive's 0..1 UV square, applied to the slot's UVs in
-- Blender (species_bodies.py), because SurfaceAppearance has no tiling property of its own.

local Types = require(script.Parent.Parent.types.Types)

local Textures: { [string]: Types.TextureRow } = {
	fur = { colorMap = 81542123953025, normalMap = 82032317264163, roughnessMap = 92091060720353, tiling = { 3, 3 } },
	moss = { colorMap = 101381556091341, normalMap = 125675504853929, roughnessMap = 95968636443629, tiling = { 2, 2 } },
	stone = { colorMap = 77466695846380, normalMap = 80308377364761, roughnessMap = 127030676099014, tiling = { 2, 2 } },
	ice = { colorMap = 131936249602071, normalMap = 133596022076904, roughnessMap = 119917132216231, tiling = { 1, 1 } },
	scales = { colorMap = 93715744299809, normalMap = 123806177602186, roughnessMap = 97218810485464, tiling = { 4, 4 } },
}

return Textures
