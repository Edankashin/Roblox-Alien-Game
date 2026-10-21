--!strict
-- Install the uploaded models into the open place. Run it in Studio's command bar (View > Command Bar,
-- paste the whole file, press Enter) or through the Studio MCP execute_luau tool. Studio must be signed
-- in as the user (or a member of the group) that owns the assets.
--
-- 1. python3 tools/upload_assets.py            (once; GLB by default; fills assets/models/asset_ids.json;
--                                               add --redo to replace ids from an earlier FBX run)
-- 2. python3 tools/upload_assets.py --emit-luau | pbcopy
-- 3. Replace the three tables between the PASTE markers below with the output, then run this file.
--
-- For each entry: InsertService:LoadAsset(assetId) inside a pcall, take the Model inside, name it
-- exactly the key, and parent it under ReplicatedStorage.Models (aliens) or ReplicatedStorage.Models.Props
-- (names in PROP_NAMES). An existing child of the same name is replaced only after the new one loaded,
-- so a failed or still-moderated asset leaves the old model alone. Safe to run again.
--
-- Colours (found in Studio 2026-10-05): a GLB upload arrives as one MeshPart per material slot, named
-- <Name>, <Name>2, <Name>3... in slot order, all grey with no TextureID. MATERIALS (from each model's
-- materials.json, slot order) restores them: the parts are sorted by the numeric suffix of their name
-- (no suffix = 1, Name2 = 2, ...) and part i gets entry i: Color from the hex; Material Neon when
-- emission > 0, Metal when metallic >= 0.5, else SmoothPlastic; and the part is renamed to the material
-- name (Body, EyeWhite, Glow...) so name-based rules keep working (a part named Glow, Props.Tint
-- skipping Neon). When the counts differ, the parts that exist are coloured and a warn names the model
-- and both counts. Roughness is in the table but Roblox has no per-part roughness, so it is not applied.
-- A model without a MATERIALS entry keeps the old rule: a prop MeshPart named "Glow" gets Neon.
-- Folder names match Config.ModelFolderName and Config.PropsFolderName in src/shared/data/Config.luau.
--
-- Block-cell aliens (Decision B46; assets/models/<Id>/ from tools/blocky/export_models.py): a species in BLOCK_CELL is installed by
-- name, never by slot, and never from its ASSET_IDS entry (that id is the retired blockout until the new GLB is uploaded):
--   * the source is BLOCK_CELL[name].assetId when it is not 0 (the new upload), else a Model of that name that you imported with
--     File > Import 3D (assets/models/<Id>/<Id>.fbx or .glb, scale 1) and selected before running this, else one already under
--     ReplicatedStorage.Models that has a FacePlate (a re-run). A species with none of these is listed as waiting, not as a failure.
--   * every part keeps its name: Body (the cell blocks), Glow, the moving parts World.RigAnimator finds by name (data/Rigs) and FacePlate.
--     A part the import renamed or merged is warned about by name (that part will not animate). No part is renamed or recoloured by slot.
--   * the texture: a cell part's SurfaceAppearance ColorMap is the atlas (cellMap) and the plate's the face sheet (faceMap, AlphaMode
--     Transparency) once those image ids are typed in; while they are 0 a texture the importer brought in (TextureID) moves into the
--     SurfaceAppearance, and either way ResampleMode = Pixelated (Blocky-Style "In the game"). A Glow part is Neon in its colour, no map.
--   * every part Anchored, CanCollide and CanQuery off; the Model's WorldPivot at the bottom centre; the Model under ReplicatedStorage.Models.
-- BLOCK_CELL is generated: `python3 -I tools/blocky/export_models.py --emit-luau` (paste it between the BLOCK-CELL PASTE markers).

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local MODELS_FOLDER = "Models"
local PROPS_FOLDER = "Props"
-- Same fix-ups the by-hand import steps ask for (Map-Dressing.md, import-model skill): every part
-- Anchored; creatures also CanCollide and CanQuery off; a prop's MeshPart named "Glow" gets Neon
-- (only for a model with no MATERIALS entry; with one, the material rules above decide).
local NORMALISE = true
local NEON_EMISSION_ABOVE = 0 -- emission > this: Neon
local METAL_METALLIC_FROM = 0.5 -- metallic >= this: Metal

-- BEGIN PASTE: output of `python3 tools/upload_assets.py --emit-luau`
local ASSET_IDS: { [string]: number } = {
	BuildStation = 116557614446597,
	Buzzlebee = 116603587874487,
	Capybubble = 100133210702748,
	CaveMouth = 139357272098761,
	Chipmole = 97070960829780,
	CrashWreck = 128799758462514,
	Drippo = 139160640965072,
	Emberchin = 75128789895079,
	Fenripup = 111992346440272,
	Flapsicle = 93200790567617,
	Flufflet = 132093842366384,
	Frostfang = 89121370968974,
	Gaiabloom = 129783775931423,
	GatherStation = 71653599018169,
	GeyserCone = 105526893549220,
	GeyserVent = 116657722898068,
	Glimmo = 92428034867797,
	Gloomoth = 98177790783891,
	HeaterLamp = 97262154954837,
	IceCaveMouth = 130501861307704,
	IceRock = 78265443687401,
	IceRockB = 77643303762233,
	IceSpire = 140159828144638,
	Kettlepuff = 136039795415171,
	Lanternewt = 77764118304137,
	MeadowRock = 126312792013094,
	MeadowRockB = 85324815639574,
	MeadowTree = 132093254516280,
	MeadowTreeB = 107521506795657,
	Mossbop = 80168609957155,
	Nebulyn = 132111130182547,
	Panpipe = 101992628838997,
	Pebblet = 140009239774106,
	Pedestal = 84066445173923,
	Pengoo = 84930553516849,
	Puffpuff = 108775875525202,
	Radish = 75467711544687,
	Reindazzle = 86110280099855,
	Rocklobber = 129196086483452,
	Shellberg = 132568103336467,
	Shimmerlynx = 89901200352693,
	ShipHull = 123730962666508,
	Shrine = 85357251439418,
	ShrineStone = 119263598508312,
	Skaddle = 88220194343720,
	Snailbyte = 76807008771184,
	SnowPine = 97187940926297,
	Snowbun = 97283882148528,
	SparkStation = 71629414883882,
	Sparkfox = 118664559072176,
	Spookum = 110636694482164,
	Thunderhog = 89950802531319,
	Toastoad = 96561583720852,
	Twiglet = 93090404448607,
	Wisplet = 98470407282023,
	Zapfinch = 105877852533381,
}
local PROP_NAMES: { [string]: boolean } = {
	BuildStation = true,
	CaveMouth = true,
	CrashWreck = true,
	GatherStation = true,
	GeyserCone = true,
	GeyserVent = true,
	HeaterLamp = true,
	IceCaveMouth = true,
	IceRock = true,
	IceRockB = true,
	IceSpire = true,
	MeadowRock = true,
	MeadowRockB = true,
	MeadowTree = true,
	MeadowTreeB = true,
	Pedestal = true,
	ShipHull = true,
	Shrine = true,
	ShrineStone = true,
	SnowPine = true,
	SparkStation = true,
}
local MATERIALS: { [string]: { { string | number } } } = {
	BuildStation = { { "Wood", "8B5A2B", 0.8, 0, 0 }, { "Plank", "C99A5B", 0.8, 0, 0 }, { "Metal", "8A93A0", 0.5, 0.4, 0 } },
	Buzzlebee = { { "Body", "F4C542", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6B4423", 0.8, 0, 0 }, { "Accessory", "A8E6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Capybubble = { { "Body", "E0C3A0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "927F68", 0.8, 0, 0 }, { "Accessory", "FF8A1F", 0.35, 0, 1 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	CaveMouth = { { "Rock", "6E6A64", 0.8, 0, 0 }, { "Dark", "15120F", 0.8, 0, 0 }, { "Crystal", "7FE3FF", 0.8, 0, 2 }, { "CrystalB", "C084FC", 0.8, 0, 2 } },
	Chipmole = { { "Body", "5B6B85", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "E8685A", 0.8, 0, 0 }, { "BodyDark", "3B4656", 0.8, 0, 0 }, { "Accessory", "9CD3F0", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	CrashWreck = { { "Scorch", "2E2620", 0.8, 0, 0 }, { "Hull", "8A93A0", 0.5, 0.4, 0 }, { "Plate", "4A5160", 0.6, 0.3, 0 }, { "Ember", "FF7A1A", 0.8, 0, 2 }, { "EmberB", "FFC83D", 0.8, 0, 2 } },
	Drippo = { { "Body", "A9D6F5", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6FA9D6", 0.8, 0, 0 }, { "Accessory", "FF8E5B", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Emberchin = { { "Body", "FF9E4A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A66730", 0.8, 0, 0 }, { "Accessory", "FFD23F", 0.8, 0, 2.5 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Fenripup = { { "Body", "3B2E6B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "261E46", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Flapsicle = { { "Body", "4A5A9C", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "F28DA6", 0.8, 0, 0 }, { "Accessory", "9FE3FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Flufflet = { { "Body", "F2F6FA", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9DB7D5", 0.8, 0, 0 }, { "Accessory", "FF7A59", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Frostfang = { { "Body", "6FB7E9", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "C94F3D", 0.8, 0, 0 }, { "BodyDark", "487797", 0.8, 0, 0 }, { "Accessory", "E8F7FF", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Gaiabloom = { { "Body", "2ECC71", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "8A5A2F", 0.8, 0, 0 }, { "Accessory", "FF8FB3", 0.8, 0, 0 }, { "Trim", "F59E0B", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	GatherStation = { { "Top", "FFC83D", 0.8, 0, 0 }, { "Legs", "A0722C", 0.8, 0, 0 } },
	GeyserCone = { { "Cone", "8C5A3C", 0.8, 0, 0 }, { "Rim", "D9A066", 0.8, 0, 0 }, { "Crater", "4A2E1E", 0.8, 0, 0 } },
	GeyserVent = { { "Rock", "6B4A36", 0.8, 0, 0 }, { "Crack", "2A1A12", 0.8, 0, 0 }, { "Rim", "D98A4E", 0.8, 0, 0 }, { "Water", "4FB3D9", 0.8, 0, 0 }, { "Glow", "F2FBFF", 0.8, 0, 2 } },
	Glimmo = { { "Body", "FFE066", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "E4A83A", 0.8, 0, 0 }, { "Accessory", "B8FF4F", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Gloomoth = { { "Body", "A569BD", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6B447B", 0.8, 0, 0 }, { "Accessory", "5CF0D0", 0.8, 0, 1.5 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	HeaterLamp = { { "Metal", "3A4049", 0.5, 0.4, 0 }, { "Glow", "FF8C42", 0.8, 0, 2 } },
	IceCaveMouth = { { "Ice", "CFEAF7", 0.3, 0, 0 }, { "IceBlue", "6EC6F0", 0.25, 0, 0 }, { "Snow", "F7FBFF", 0.8, 0, 0 }, { "Dark", "0E1A26", 0.8, 0, 0 } },
	IceRock = { { "IceRock", "A9B7C0", 0.8, 0, 0 } },
	IceRockB = { { "IceRock", "A9B7C0", 0.8, 0, 0 } },
	IceSpire = { { "Ice", "A9D8EA", 0.8, 0, 0 }, { "IceTip", "E8F7FD", 0.8, 0, 0 } },
	Kettlepuff = { { "Body", "F5EDE0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9F9A92", 0.8, 0, 0 }, { "Accessory", "E8793A", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Lanternewt = { { "Body", "FF8C42", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "8C3F1C", 0.8, 0, 0 }, { "Accessory", "FFD84A", 0.8, 0, 2.5 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	MeadowRock = { { "Rock", "8E8E8E", 0.8, 0, 0 } },
	MeadowRockB = { { "Rock", "8E8E8E", 0.8, 0, 0 }, { "Moss", "3F9B3A", 0.8, 0, 0 } },
	MeadowTree = { { "Trunk", "7B4A2D", 0.8, 0, 0 }, { "Leaves", "3F9B3A", 0.8, 0, 0 } },
	MeadowTreeB = { { "Trunk", "7B4A2D", 0.8, 0, 0 }, { "Leaves", "3F9B3A", 0.8, 0, 0 } },
	Mossbop = { { "Body", "6BCB3F", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "3F8F2E", 0.8, 0, 0 }, { "Accessory", "FF8A3D", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Nebulyn = { { "Body", "7B5CFF", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "503CA6", 0.8, 0, 0 }, { "Accessory", "FFCC5C", 0.8, 0, 1.5 }, { "Trim", "F59E0B", 0.3, 1, 0 } },
	Panpipe = { { "Body", "1A1A1A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "7A1F3D", 0.8, 0, 0 }, { "BodyDark", "E9DDBA", 0.8, 0, 0 }, { "Accessory", "4FD8FF", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Pebblet = { { "Body", "9A9A9A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6B6760", 0.8, 0, 0 }, { "Accessory", "78C850", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Pedestal = { { "Stone", "C8C4A8", 0.8, 0, 0 } },
	Pengoo = { { "Body", "2B3F5C", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "1C293C", 0.8, 0, 0 }, { "Accessory", "FF8A3D", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 }, { "Belly", "DDE6F0", 0.7, 0, 0 } },
	Puffpuff = { { "Body", "F7F7F7", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "8FC96A", 0.8, 0, 0 }, { "Accessory", "FFD84A", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Radish = { { "Body", "FFB347", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "5DBB3A", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Reindazzle = { { "Body", "C9D6E8", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "8795AD", 0.8, 0, 0 }, { "Accessory", "FF6B4A", 0.35, 0, 2 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Rocklobber = { { "Body", "C0392B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "8A857D", 0.8, 0, 0 }, { "Accessory", "FFA928", 0.35, 0, 1.5 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Shellberg = { { "Body", "3FBFB0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "E8785A", 0.8, 0, 0 }, { "Accessory", "CFF1FF", 0.35, 0, 1.2 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Shimmerlynx = { { "Body", "C8C2F0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "827E9C", 0.8, 0, 0 }, { "Accessory", "5CF0D0", 0.8, 0, 1.5 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	ShipHull = { { "Plate", "5B6472", 0.8, 0, 0 }, { "Lip", "8A93A0", 0.8, 0, 0 }, { "Feet", "3A4049", 0.8, 0, 0 } },
	Shrine = { { "Paving", "B9B29A", 0.8, 0, 0 }, { "Stone", "8E8E80", 0.8, 0, 0 }, { "Moss", "5E9E3A", 0.8, 0, 0 }, { "Glow", "9BE7FF", 0.8, 0, 2 } },
	ShrineStone = { { "Stone", "9E9E8E", 0.8, 0, 0 } },
	Skaddle = { { "Body", "F7F9FC", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A9C5E0", 0.8, 0, 0 }, { "Accessory", "8FD8FF", 0.8, 0, 0 }, { "Trim", "F59E0B", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Snailbyte = { { "Body", "7FB3D5", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "4F7390", 0.8, 0, 0 }, { "Accessory", "C8CDD3", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	SnowPine = { { "Trunk", "7A8C96", 0.8, 0, 0 }, { "Snow", "DDEFF5", 0.8, 0, 0 } },
	Snowbun = { { "Body", "DDEBF7", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A9C3DD", 0.8, 0, 0 }, { "Accessory", "FF9EB5", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	SparkStation = { { "Stem", "3F9B3A", 0.8, 0, 0 }, { "Petal", "A855F7", 0.8, 0, 0 }, { "Glow", "FFC83D", 0.8, 0, 2 } },
	Sparkfox = { { "Body", "FF6B35", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A8431C", 0.8, 0, 0 }, { "Accessory", "FFE066", 0.35, 0, 2 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Spookum = { { "Body", "F2F2FF", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9D9DA6", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 } },
	Thunderhog = { { "Body", "8E44AD", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "5C2C70", 0.8, 0, 0 }, { "Accessory", "FFE23B", 0.8, 0, 2 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Toastoad = { { "Body", "E8713A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "974926", 0.8, 0, 0 }, { "Accessory", "9FB3C8", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Twiglet = { { "Body", "8B5A2B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "5C3A1C", 0.8, 0, 0 }, { "Accessory", "6FBF3F", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Wisplet = { { "Body", "9BE7FF", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6596A6", 0.8, 0, 0 }, { "Accessory", "FF7397", 0.35, 1, 1.5 } },
	Zapfinch = { { "Body", "5DADE2", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "2F5F8F", 0.8, 0, 0 }, { "Accessory", "FFE45C", 0.35, 0, 1.5 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
}
-- END PASTE

-- One part of a block-cell model: its name (the GLB node), its colour, Neon or not, and the map it samples ("cell", "face" or "").
type BlockCellPart = { name: string, hex: string, neon: boolean, map: string }
-- assetId: the new Model upload (0 until uploaded); cellMap, faceMap: the Image ids of <Id>_atlas.png and <Id>_face.png (0 until uploaded).
type BlockCellRow = { assetId: number, cellMap: number, faceMap: number, parts: { BlockCellPart } }
-- BEGIN BLOCK-CELL PASTE: output of `python3 -I tools/blocky/export_models.py --emit-luau`
local BLOCK_CELL: { [string]: BlockCellRow } = {
	Buzzlebee = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "antenna", hex = "FF6B9A", neon = false, map = "cell" },
			{ name = "stinger", hex = "4A2F1F", neon = false, map = "cell" },
			{ name = "wingL", hex = "FF6B9A", neon = false, map = "cell" },
			{ name = "wingR", hex = "FF6B9A", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "FFC83D", neon = false, map = "face" },
		},
	},
	Capybubble = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E0C3A0", neon = false, map = "cell" },
			{ name = "earL", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "earR", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "floatR", hex = "5FDCFF", neon = true, map = "" },
			{ name = "leafR", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "E0C3A0", neon = false, map = "face" },
		},
	},
	Chipmole = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "5B6B85", neon = false, map = "cell" },
			{ name = "pickL", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "pickR", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "tailR", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "5B6B85", neon = false, map = "face" },
		},
	},
	Drippo = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A9D6F5", neon = false, map = "cell" },
			{ name = "armR", hex = "2F5F9F", neon = false, map = "cell" },
			{ name = "beadL", hex = "0FB4E0", neon = false, map = "cell" },
			{ name = "dripL", hex = "0FB4E0", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "A9D6F5", neon = false, map = "face" },
		},
	},
	Emberchin = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "73365A", neon = false, map = "cell" },
			{ name = "cinderR", hex = "FF8C2E", neon = false, map = "cell" },
			{ name = "ember", hex = "FF8C2E", neon = false, map = "cell" },
			{ name = "pool", hex = "C8DCE4", neon = false, map = "cell" },
			{ name = "quillL", hex = "FF8C2E", neon = false, map = "cell" },
			{ name = "quillR", hex = "FF8C2E", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "73365A", neon = false, map = "face" },
		},
	},
	Fenripup = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "Glow", hex = "AEB8FF", neon = true, map = "" },
			{ name = "chain", hex = "D9E2F5", neon = false, map = "cell" },
			{ name = "earL", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "earR", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "halo", hex = "D9E2F5", neon = false, map = "cell" },
			{ name = "moon", hex = "AEB8FF", neon = true, map = "" },
			{ name = "moteL", hex = "AEB8FF", neon = true, map = "" },
			{ name = "moteR", hex = "AEB8FF", neon = true, map = "" },
			{ name = "tail", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4B3D8F", neon = false, map = "face" },
		},
	},
	Flapsicle = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "3F4C8C", neon = false, map = "cell" },
			{ name = "earL", hex = "3F4C8C", neon = false, map = "cell" },
			{ name = "earR", hex = "3F4C8C", neon = false, map = "cell" },
			{ name = "perch", hex = "8FC9F0", neon = false, map = "cell" },
			{ name = "wingL", hex = "8FC9F0", neon = false, map = "cell" },
			{ name = "wingR", hex = "8FC9F0", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "3F4C8C", neon = false, map = "face" },
		},
	},
	Flufflet = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "ball", hex = "9CC3E0", neon = false, map = "cell" },
			{ name = "earL", hex = "F0614A", neon = false, map = "cell" },
			{ name = "earR", hex = "F0614A", neon = false, map = "cell" },
			{ name = "scarfR", hex = "9CC3E0", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F2F6FA", neon = false, map = "face" },
		},
	},
	Frostfang = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4F9BD8", neon = false, map = "cell" },
			{ name = "Glow", hex = "2ED3F7", neon = true, map = "" },
			{ name = "earL", hex = "4F9BD8", neon = false, map = "cell" },
			{ name = "earR", hex = "4F9BD8", neon = false, map = "cell" },
			{ name = "pawL", hex = "F2F7FB", neon = false, map = "cell" },
			{ name = "pawR", hex = "F2F7FB", neon = false, map = "cell" },
			{ name = "ruff", hex = "22406B", neon = false, map = "cell" },
			{ name = "tailR", hex = "4F9BD8", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4F9BD8", neon = false, map = "face" },
		},
	},
	Gaiabloom = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "Glow", hex = "FF6FAE", neon = true, map = "" },
			{ name = "antlerL", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "antlerR", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "butterflyR", hex = "FF6FAE", neon = true, map = "" },
			{ name = "earL", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "earR", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "halo", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "tail", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F0E6CE", neon = false, map = "face" },
		},
	},
	Glimmo = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4FCFC0", neon = false, map = "cell" },
			{ name = "bulb", hex = "FFE566", neon = false, map = "cell" },
			{ name = "tendril", hex = "2E7F78", neon = false, map = "cell" },
			{ name = "wingL", hex = "2E7F78", neon = false, map = "cell" },
			{ name = "wingR", hex = "2E7F78", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4FCFC0", neon = false, map = "face" },
		},
	},
	Gloomoth = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "8C6FB5", neon = false, map = "cell" },
			{ name = "antennaL", hex = "E08CFF", neon = true, map = "" },
			{ name = "antennaR", hex = "E08CFF", neon = true, map = "" },
			{ name = "hindwingL", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "hindwingR", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "shard", hex = "E8C45A", neon = false, map = "cell" },
			{ name = "wingL", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "wingR", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8C6FB5", neon = false, map = "face" },
		},
	},
	Kettlepuff = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F5EDE0", neon = false, map = "cell" },
			{ name = "floatR", hex = "F5EDE0", neon = false, map = "cell" },
			{ name = "handle", hex = "C8743A", neon = false, map = "cell" },
			{ name = "lid", hex = "C8743A", neon = false, map = "cell" },
			{ name = "wispR", hex = "F5EDE0", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F5EDE0", neon = false, map = "face" },
		},
	},
	Lanternewt = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F26B3A", neon = false, map = "cell" },
			{ name = "gillL", hex = "4A2638", neon = false, map = "cell" },
			{ name = "gillR", hex = "4A2638", neon = false, map = "cell" },
			{ name = "tail", hex = "F26B3A", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F26B3A", neon = false, map = "face" },
		},
	},
	Mossbop = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6CCB5F", neon = false, map = "cell" },
			{ name = "floatR", hex = "D9F36B", neon = false, map = "cell" },
			{ name = "sprout", hex = "D9F36B", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "6CCB5F", neon = false, map = "face" },
		},
	},
	Nebulyn = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6B4EC2", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFF3B0", neon = true, map = "" },
			{ name = "fallenR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "planetL", hex = "E66BD2", neon = false, map = "cell" },
			{ name = "puff", hex = "6B4EC2", neon = false, map = "cell" },
			{ name = "starL", hex = "FFF3B0", neon = true, map = "" },
			{ name = "starR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "tailR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "FacePlate", hex = "6B4EC2", neon = false, map = "face" },
		},
	},
	Panpipe = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4A4166", neon = false, map = "cell" },
			{ name = "Glow", hex = "B28CFF", neon = true, map = "" },
			{ name = "beard", hex = "1E1A2E", neon = false, map = "cell" },
			{ name = "bellR", hex = "8C86A6", neon = false, map = "cell" },
			{ name = "earL", hex = "4A4166", neon = false, map = "cell" },
			{ name = "earR", hex = "4A4166", neon = false, map = "cell" },
			{ name = "noteL", hex = "B28CFF", neon = true, map = "" },
			{ name = "note2R", hex = "B28CFF", neon = true, map = "" },
			{ name = "pipesR", hex = "B28CFF", neon = true, map = "" },
			{ name = "tail", hex = "1E1A2E", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4A4166", neon = false, map = "face" },
		},
	},
	Pebblet = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C4B9A6", neon = false, map = "cell" },
			{ name = "cairnR", hex = "5A5048", neon = false, map = "cell" },
			{ name = "legL", hex = "5A5048", neon = false, map = "cell" },
			{ name = "legR", hex = "5A5048", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C4B9A6", neon = false, map = "face" },
		},
	},
	Pengoo = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2B3F5C", neon = false, map = "cell" },
			{ name = "pack", hex = "FFA63D", neon = false, map = "cell" },
			{ name = "tuft", hex = "2B3F5C", neon = false, map = "cell" },
			{ name = "wingL", hex = "2B3F5C", neon = false, map = "cell" },
			{ name = "wingR", hex = "2B3F5C", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F4F7FA", neon = false, map = "face" },
		},
	},
	Puffpuff = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F4F1E8", neon = false, map = "cell" },
			{ name = "floatR", hex = "F4F1E8", neon = false, map = "cell" },
			{ name = "leafL", hex = "4E9E3C", neon = false, map = "cell" },
			{ name = "leafR", hex = "4E9E3C", neon = false, map = "cell" },
			{ name = "seeds", hex = "F4F1E8", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F4F1E8", neon = false, map = "face" },
		},
	},
	Radish = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D7265C", neon = false, map = "cell" },
			{ name = "frondL", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "frondR", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "gem", hex = "FFE36B", neon = true, map = "" },
			{ name = "halo", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "leaf", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "moteL", hex = "FFE36B", neon = true, map = "" },
			{ name = "moteR", hex = "FFE36B", neon = true, map = "" },
			{ name = "orb", hex = "FFE36B", neon = true, map = "" },
			{ name = "pendant", hex = "FFE36B", neon = true, map = "" },
			{ name = "wingL", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "wingR", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "D7265C", neon = false, map = "face" },
		},
	},
	Reindazzle = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A8805A", neon = false, map = "cell" },
			{ name = "Glow", hex = "E0202C", neon = true, map = "" },
			{ name = "chimeL", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "chimeR", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "earL", hex = "A8805A", neon = false, map = "cell" },
			{ name = "earR", hex = "A8805A", neon = false, map = "cell" },
			{ name = "tail", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "A8805A", neon = false, map = "face" },
		},
	},
	Rocklobber = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C8553D", neon = false, map = "cell" },
			{ name = "antennaR", hex = "A39E94", neon = false, map = "cell" },
			{ name = "clawL", hex = "A39E94", neon = false, map = "cell" },
			{ name = "clawR", hex = "A39E94", neon = false, map = "cell" },
			{ name = "legL", hex = "3A3238", neon = false, map = "cell" },
			{ name = "legR", hex = "3A3238", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C8553D", neon = false, map = "face" },
		},
	},
	Shellberg = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "3FBFB0", neon = false, map = "cell" },
			{ name = "flagL", hex = "2ED3F7", neon = false, map = "cell" },
			{ name = "footL", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "footR", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "tail", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "3FBFB0", neon = false, map = "face" },
		},
	},
	Shimmerlynx = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "crest", hex = "9D7CFF", neon = true, map = "" },
			{ name = "earL", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "earR", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "tailR", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "whiskerL", hex = "4B4470", neon = false, map = "cell" },
			{ name = "whiskerR", hex = "4B4470", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C8C2F0", neon = false, map = "face" },
		},
	},
	Skaddle = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "crest", hex = "4A55E8", neon = true, map = "" },
			{ name = "hindwingL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "hindwingR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "scarfR", hex = "8FD3F4", neon = false, map = "cell" },
			{ name = "tuftL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "tuftR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "wingL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "wingR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F4F7FA", neon = false, map = "face" },
		},
	},
	Snailbyte = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "dishR", hex = "C9803E", neon = false, map = "cell" },
			{ name = "feelerL", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "feelerR", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "9FD9A6", neon = false, map = "face" },
		},
	},
	Snowbun = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "B4A9E6", neon = false, map = "cell" },
			{ name = "earL", hex = "B4A9E6", neon = false, map = "cell" },
			{ name = "earR", hex = "B4A9E6", neon = false, map = "cell" },
			{ name = "nose", hex = "F0407F", neon = false, map = "cell" },
			{ name = "tail", hex = "CFE2F3", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "B4A9E6", neon = false, map = "face" },
		},
	},
	Sparkfox = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "earL", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "earR", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "floatR", hex = "FFA53D", neon = true, map = "" },
			{ name = "tailR", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "FF7A30", neon = false, map = "face" },
		},
	},
	Spookum = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "Glow", hex = "9D6BFF", neon = true, map = "" },
			{ name = "armL", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "armR", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "hem", hex = "5B4A8A", neon = false, map = "cell" },
			{ name = "lanternL", hex = "9D6BFF", neon = true, map = "" },
			{ name = "stem", hex = "B89B5A", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "E9E6FF", neon = false, map = "face" },
		},
	},
	Thunderhog = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "8B5CF6", neon = false, map = "cell" },
			{ name = "antennaL", hex = "FFF27A", neon = true, map = "" },
			{ name = "antennaR", hex = "FFF27A", neon = true, map = "" },
			{ name = "crest", hex = "FFC233", neon = false, map = "cell" },
			{ name = "sparkR", hex = "FFF27A", neon = true, map = "" },
			{ name = "tail", hex = "2E1F66", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8B5CF6", neon = false, map = "face" },
		},
	},
	Toastoad = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E8713A", neon = false, map = "cell" },
			{ name = "belly", hex = "FFC94D", neon = false, map = "cell" },
			{ name = "bumpL", hex = "E8713A", neon = false, map = "cell" },
			{ name = "bumpR", hex = "E8713A", neon = false, map = "cell" },
			{ name = "pebbleR", hex = "6E4A3C", neon = false, map = "cell" },
			{ name = "stoneL", hex = "6E4A3C", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "E8713A", neon = false, map = "face" },
		},
	},
	Twiglet = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9C6B3F", neon = false, map = "cell" },
			{ name = "antenna", hex = "4A2E1A", neon = false, map = "cell" },
			{ name = "hat", hex = "7FC94A", neon = false, map = "cell" },
			{ name = "twig", hex = "9C6B3F", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "9C6B3F", neon = false, map = "face" },
		},
	},
	Wisplet = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "floatL", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "floatR", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "halo", hex = "6E6A85", neon = false, map = "cell" },
			{ name = "tipR", hex = "B48CFF", neon = true, map = "" },
			{ name = "tongueL", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8FDCFF", neon = false, map = "face" },
		},
	},
	Zapfinch = {
		assetId = 0, cellMap = 0, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4FA8E8", neon = false, map = "cell" },
			{ name = "crestL", hex = "FFEE55", neon = true, map = "" },
			{ name = "crestR", hex = "FFEE55", neon = true, map = "" },
			{ name = "tail", hex = "23386B", neon = false, map = "cell" },
			{ name = "wingL", hex = "23386B", neon = false, map = "cell" },
			{ name = "wingR", hex = "23386B", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4FA8E8", neon = false, map = "face" },
		},
	},
}
-- END BLOCK-CELL PASTE
local FACE_PART = "FacePlate"

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end
		error(("%s.%s exists but is a %s, not a Folder"):format(parent:GetFullName(), name, existing.ClassName))
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- LoadAsset returns a container Model. The imported Model is normally its only child; when the
-- parts sit directly in the container, the container is the model.
local function pickModel(container: Instance): Model?
	for _, child in container:GetChildren() do
		if child:IsA("Model") then
			return child
		end
	end
	if container:IsA("Model") and container:FindFirstChildWhichIsA("BasePart", true) then
		return container
	end
	return nil
end

type PartSlot = { part: MeshPart, slot: number, order: number }

-- Slot number of a GLB part from its name: no suffix = 1, "<Name>2" = 2. The model's own name is
-- stripped first, so a model whose name ends in a digit still reads right.
local function slotOf(partName: string, modelName: string): number
	local rest = partName
	if rest:sub(1, #modelName) == modelName then
		rest = rest:sub(#modelName + 1)
	end
	local digits = rest:match("(%d+)$")
	if digits then
		return tonumber(digits) or 1
	end
	return 1
end

-- Colours the model's MeshParts from its MATERIALS rows. Returns how many parts were coloured.
local function applyMaterials(model: Model, name: string, rows: { { string | number } }): number
	local slots: { PartSlot } = {}
	for order, descendant in model:GetDescendants() do
		if descendant:IsA("MeshPart") then
			table.insert(slots, { part = descendant, slot = slotOf(descendant.Name, name), order = order })
		end
	end
	table.sort(slots, function(a: PartSlot, b: PartSlot): boolean
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		return a.order < b.order
	end)
	if #slots ~= #rows then
		warn(("install_models: %s has %d MeshParts but MATERIALS lists %d; colouring the parts that exist"):format(
			name,
			#slots,
			#rows
		))
	end
	local coloured = 0
	for index, slot in slots do
		local row = rows[index]
		if not row then
			break
		end
		local materialName = row[1] :: string
		local hex = row[2] :: string
		local metallic = row[4] :: number
		local emission = row[5] :: number
		local part = slot.part
		part.Color = Color3.fromHex(hex)
		if emission > NEON_EMISSION_ABOVE then
			part.Material = Enum.Material.Neon
		elseif metallic >= METAL_METALLIC_FROM then
			part.Material = Enum.Material.Metal
		else
			part.Material = Enum.Material.SmoothPlastic
		end
		part.Name = materialName
		coloured += 1
	end
	return coloured
end

local function normalise(model: Model, isProp: boolean, hasMaterials: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if not isProp then
				descendant.CanCollide = false
				descendant.CanQuery = false
			end
			if
				isProp
				and not hasMaterials
				and descendant:IsA("MeshPart")
				and descendant.Name:lower():find("glow", 1, true)
			then
				descendant.Material = Enum.Material.Neon
			end
		end
	end
end

local function install(name: string, assetId: number, models: Folder, props: Folder): (boolean, string)
	local ok, loaded = pcall(function(): Instance
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		return false, tostring(loaded)
	end
	local container = loaded :: Instance
	local model = pickModel(container)
	if not model then
		container:Destroy()
		return false, "asset loaded but holds no Model with parts"
	end
	local isProp = PROP_NAMES[name] == true
	local target = if isProp then props else models
	model.Parent = nil
	model.Name = name
	if container ~= model then
		container:Destroy()
	end
	local rows = MATERIALS[name]
	local note = ""
	if rows then
		note = (", %d parts coloured"):format(applyMaterials(model, name, rows))
	end
	if NORMALISE then
		normalise(model, isProp, rows ~= nil)
	end
	local old = target:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = target
	return true, target:GetFullName() .. note
end

-- The first BasePart of `model` named `name`, or under a descendant named `name` (an import may wrap a mesh in a Model).
local function findPart(model: Instance, name: string): BasePart?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local node: Instance? = descendant
			while node and node ~= model do
				if node.Name == name then
					return descendant
				end
				node = node.Parent
			end
		end
	end
	return nil
end

-- Puts `imageId` (or, at 0, the texture the importer brought in) on the part's SurfaceAppearance with Pixelated resampling. Returns a note.
local function applyMap(part: BasePart, imageId: number, transparent: boolean): string
	if not part:IsA("MeshPart") then
		return "not a MeshPart"
	end
	local mesh = part :: MeshPart
	local content = if imageId ~= 0 then "rbxassetid://" .. tostring(imageId) else mesh.TextureID
	local appearance = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if not appearance and content == "" then
		return "no texture yet"
	end
	if not appearance then
		local ok, made = pcall(function(): SurfaceAppearance
			local created = Instance.new("SurfaceAppearance")
			created.Parent = mesh
			return created
		end)
		if not ok then
			mesh.TextureID = content
			return "TextureID only (no SurfaceAppearance here)"
		end
		appearance = made
	end
	local surface = appearance :: SurfaceAppearance
	if content ~= "" then
		surface.ColorMap = content
		mesh.TextureID = ""
	end
	if transparent then
		surface.AlphaMode = Enum.AlphaMode.Transparency
	end
	local pixelated = pcall(function()
		surface.ResampleMode = Enum.ResamplerMode.Pixelated
	end)
	return if pixelated then "pixelated" else "textured (ResampleMode unavailable)"
end

-- The block-cell fix-ups on one model (see the header). Returns a summary and the names of the parts it could not find.
local function fixBlockCell(model: Model, row: BlockCellRow): (string, { string })
	local missing: { string } = {}
	local textured, waiting, neon = 0, 0, 0
	for _, def in row.parts do
		local part = findPart(model, def.name)
		if not part then
			table.insert(missing, def.name)
			continue
		end
		part.Color = Color3.fromHex(def.hex)
		if def.neon then
			part.Material = Enum.Material.Neon
			local appearance = part:FindFirstChildOfClass("SurfaceAppearance")
			if appearance then
				appearance:Destroy()
			end
			if part:IsA("MeshPart") then
				(part :: MeshPart).TextureID = ""
			end
			neon += 1
		else
			part.Material = Enum.Material.SmoothPlastic
			local id = if def.map == "face" then row.faceMap else row.cellMap
			local note = applyMap(part, id, def.name == FACE_PART)
			if note == "no texture yet" then
				waiting += 1
			else
				textured += 1
			end
		end
	end
	normalise(model, false, true)
	local box, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	return ("%d textured, %d Neon, %d waiting for a texture"):format(textured, neon, waiting), missing
end

-- A block-cell model imported by hand: the selected Model named `name`, else one already installed that has a FacePlate.
local function importedBlockCell(name: string, models: Folder): Model?
	for _, item in Selection:Get() do
		if item:IsA("Model") and item.Name == name then
			return item
		end
	end
	local existing = models:FindFirstChild(name)
	if existing and existing:IsA("Model") and findPart(existing, FACE_PART) then
		return existing
	end
	return nil
end

-- Installs one block-cell species. Returns ("ok" | "fail" | "wait", detail).
local function installBlockCell(name: string, row: BlockCellRow, models: Folder): (string, string)
	local model: Model? = nil
	if row.assetId ~= 0 then
		local ok, loaded = pcall(function(): Instance
			return InsertService:LoadAsset(row.assetId)
		end)
		if not ok then
			return "fail", tostring(loaded)
		end
		local container = loaded :: Instance
		model = pickModel(container)
		if not model then
			container:Destroy()
			return "fail", "asset loaded but holds no Model with parts"
		end
		model.Parent = nil
		if container ~= model then
			container:Destroy()
		end
	else
		model = importedBlockCell(name, models)
		if not model then
			return "wait", ("not uploaded (assetId 0): File > Import 3D assets/models/%s/%s.fbx, select the Model, run again"):format(name, name)
		end
	end
	local target = model :: Model
	target.Name = name
	local summary, missing = fixBlockCell(target, row)
	if #missing > 0 then
		warn(("install_models: %s has no part named %s; the import renamed or merged it, so it will not animate"):format(
			name,
			table.concat(missing, ", ")
		))
	end
	if target.Parent ~= models then
		local old = models:FindFirstChild(name)
		if old and old ~= target then
			old:Destroy()
		end
		target.Parent = models
	end
	return "ok", ("%s (block-cell: %s)"):format(models:GetFullName(), summary)
end

local function main()
	local names: { string } = {}
	for name in ASSET_IDS do
		if not BLOCK_CELL[name] then -- a block-cell species never loads its old blockout id
			table.insert(names, name)
		end
	end
	table.sort(names)
	local cellNames: { string } = {}
	for name in BLOCK_CELL do
		table.insert(cellNames, name)
	end
	table.sort(cellNames)
	if #names == 0 and #cellNames == 0 then
		print("install_models: ASSET_IDS is empty; paste the output of `python3 tools/upload_assets.py --emit-luau`")
		return
	end

	local models = ensureFolder(ReplicatedStorage, MODELS_FOLDER)
	local props = ensureFolder(models, PROPS_FOLDER)

	local installed = 0
	local failed = 0
	local waiting = 0
	local waitNames: { string } = {}
	for _, name in names do
		local assetId = ASSET_IDS[name]
		local ok, detail = install(name, assetId, models, props)
		if ok then
			installed += 1
			print(("ok    %s <- %d  (%s)"):format(name, assetId, detail))
		else
			failed += 1
			warn(("FAIL  %s <- %d  %s"):format(name, assetId, detail))
		end
	end
	for _, name in cellNames do
		local status, detail = installBlockCell(name, BLOCK_CELL[name], models)
		if status == "ok" then
			installed += 1
			print(("ok    %s  (%s)"):format(name, detail))
		elseif status == "wait" then
			waiting += 1
			table.insert(waitNames, name)
		else
			failed += 1
			warn(("FAIL  %s  %s"):format(name, detail))
		end
	end
	print(("install_models: %d installed, %d failed, %d block-cell species waiting for an import or upload, %d total"):format(
		installed,
		failed,
		waiting,
		#names + #cellNames
	))
	if #waitNames > 0 then
		print(("waiting (not uploaded, not imported or selected): %s"):format(table.concat(waitNames, ", ")))
		print("Import one with File > Import 3D (assets/models/<Id>/<Id>.fbx), select the Model it makes, and run this again.")
	end
	if failed > 0 then
		print("A failure right after upload usually means the asset is still in moderation (up to a few hours); run again later.")
	end
end

main()
