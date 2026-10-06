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

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	Buzzlebee = 93289897027487,
	Capybubble = 91020613872676,
	CaveMouth = 139357272098761,
	Chipmole = 113544770104398,
	CrashWreck = 128799758462514,
	Drippo = 121517821056634,
	Emberchin = 116168141451244,
	Fenripup = 106502871344181,
	Flapsicle = 97331820420094,
	Flufflet = 89419220122225,
	Frostfang = 98224524799523,
	Gaiabloom = 126155954713066,
	GatherStation = 71653599018169,
	GeyserCone = 105526893549220,
	GeyserVent = 116657722898068,
	Glimmo = 117109944435105,
	Gloomoth = 108889147995169,
	HeaterLamp = 97262154954837,
	IceCaveMouth = 130501861307704,
	IceRock = 78265443687401,
	IceRockB = 77643303762233,
	IceSpire = 140159828144638,
	Kettlepuff = 73183285856938,
	Lanternewt = 75678718938040,
	MeadowRock = 126312792013094,
	MeadowRockB = 85324815639574,
	MeadowTree = 132093254516280,
	MeadowTreeB = 107521506795657,
	Mossbop = 109610812891190,
	Panpipe = 107790361036773,
	Pebblet = 128856924167302,
	Pedestal = 84066445173923,
	Pengoo = 107941440215053,
	Puffpuff = 79276822839330,
	Radish = 112682099542089,
	Reindazzle = 112493062576105,
	Rocklobber = 85738974385619,
	Shellberg = 95689979583978,
	Shimmerlynx = 98529028939594,
	ShipHull = 123730962666508,
	Shrine = 85357251439418,
	ShrineStone = 119263598508312,
	Skaddle = 94143662774874,
	Snailbyte = 116686239921179,
	SnowPine = 97187940926297,
	Snowbun = 136695184273344,
	SparkStation = 71629414883882,
	Sparkfox = 79808205927193,
	Thunderhog = 123300168621633,
	Toastoad = 91758095099133,
	Twiglet = 83597806195142,
	Zapfinch = 131886607786861,
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
	Buzzlebee = { { "Body", "F4C542", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9F802B", 0.8, 0, 0 }, { "Accessory", "42CAF4", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Capybubble = { { "Body", "E0C3A0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "927F68", 0.8, 0, 0 }, { "Accessory", "65DAE0", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	CaveMouth = { { "Rock", "6E6A64", 0.8, 0, 0 }, { "Dark", "15120F", 0.8, 0, 0 }, { "Crystal", "7FE3FF", 0.8, 0, 2 }, { "CrystalB", "C084FC", 0.8, 0, 2 } },
	Chipmole = { { "Body", "5B6B85", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "3B4656", 0.8, 0, 0 }, { "Accessory", "BF6356", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	CrashWreck = { { "Scorch", "2E2620", 0.8, 0, 0 }, { "Hull", "8A93A0", 0.5, 0.4, 0 }, { "Plate", "4A5160", 0.6, 0.3, 0 }, { "Ember", "FF7A1A", 0.8, 0, 2 }, { "EmberB", "FFC83D", 0.8, 0, 2 } },
	Drippo = { { "Body", "A9D6F5", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6E8B9F", 0.8, 0, 0 }, { "Accessory", "F56E7B", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Emberchin = { { "Body", "FF9E4A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A66730", 0.8, 0, 0 }, { "Accessory", "4AFFF8", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Fenripup = { { "Body", "3B2E6B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "261E46", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Flapsicle = { { "Body", "4A5A9C", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "303B65", 0.8, 0, 0 }, { "Accessory", "BF7656", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Flufflet = { { "Body", "F2F6FA", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9DA0A2", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Frostfang = { { "Body", "6FB7E9", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "487797", 0.8, 0, 0 }, { "Accessory", "E96974", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Gaiabloom = { { "Body", "2ECC71", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "1E8549", 0.8, 0, 0 }, { "Accessory", "C02ECC", 0.8, 0, 0 }, { "Trim", "F59E0B", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	GatherStation = { { "Top", "FFC83D", 0.8, 0, 0 }, { "Legs", "A0722C", 0.8, 0, 0 } },
	GeyserCone = { { "Cone", "8C5A3C", 0.8, 0, 0 }, { "Rim", "D9A066", 0.8, 0, 0 }, { "Crater", "4A2E1E", 0.8, 0, 0 } },
	GeyserVent = { { "Rock", "6B4A36", 0.8, 0, 0 }, { "Crack", "2A1A12", 0.8, 0, 0 }, { "Rim", "D98A4E", 0.8, 0, 0 }, { "Water", "4FB3D9", 0.8, 0, 0 }, { "Glow", "F2FBFF", 0.8, 0, 2 } },
	Glimmo = { { "Body", "FFE066", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A69242", 0.8, 0, 0 }, { "Accessory", "66D1FF", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Gloomoth = { { "Body", "A569BD", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "6B447B", 0.8, 0, 0 }, { "Accessory", "A9BF56", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	HeaterLamp = { { "Metal", "3A4049", 0.5, 0.4, 0 }, { "Glow", "FF8C42", 0.8, 0, 2 } },
	IceCaveMouth = { { "Ice", "CFEAF7", 0.3, 0, 0 }, { "IceBlue", "6EC6F0", 0.25, 0, 0 }, { "Snow", "F7FBFF", 0.8, 0, 0 }, { "Dark", "0E1A26", 0.8, 0, 0 } },
	IceRock = { { "IceRock", "A9B7C0", 0.8, 0, 0 } },
	IceRockB = { { "IceRock", "A9B7C0", 0.8, 0, 0 } },
	IceSpire = { { "Ice", "A9D8EA", 0.8, 0, 0 }, { "IceTip", "E8F7FD", 0.8, 0, 0 } },
	Kettlepuff = { { "Body", "F5EDE0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9F9A92", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Lanternewt = { { "Body", "FF8C42", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A65B2B", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	MeadowRock = { { "Rock", "8E8E8E", 0.8, 0, 0 } },
	MeadowRockB = { { "Rock", "8E8E8E", 0.8, 0, 0 }, { "Moss", "3F9B3A", 0.8, 0, 0 } },
	MeadowTree = { { "Trunk", "7B4A2D", 0.8, 0, 0 }, { "Leaves", "3F9B3A", 0.8, 0, 0 } },
	MeadowTreeB = { { "Trunk", "7B4A2D", 0.8, 0, 0 }, { "Leaves", "3F9B3A", 0.8, 0, 0 } },
	Mossbop = { { "Body", "6BCB3F", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "468429", 0.8, 0, 0 }, { "Accessory", "593FCB", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Panpipe = { { "Body", "1A1A1A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "525252", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Pebblet = { { "Body", "9A9A9A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "646464", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Pedestal = { { "Stone", "C8C4A8", 0.8, 0, 0 } },
	Pengoo = { { "Body", "2B3F5C", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "1C293C", 0.8, 0, 0 }, { "Accessory", "BF6056", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 }, { "Belly", "DDE6F0", 0.7, 0, 0 } },
	Puffpuff = { { "Body", "F7F7F7", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A1A1A1", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Radish = { { "Body", "FFB347", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A6742E", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 3 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Reindazzle = { { "Body", "C9D6E8", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "838B97", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Rocklobber = { { "Body", "C0392B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "7D251C", 0.8, 0, 0 }, { "Accessory", "2BC083", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Shellberg = { { "Body", "3FBFB0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "297C72", 0.8, 0, 0 }, { "Accessory", "BF3F8E", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Shimmerlynx = { { "Body", "C8C2F0", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "827E9C", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	ShipHull = { { "Plate", "5B6472", 0.8, 0, 0 }, { "Lip", "8A93A0", 0.8, 0, 0 }, { "Feet", "3A4049", 0.8, 0, 0 } },
	Shrine = { { "Paving", "B9B29A", 0.8, 0, 0 }, { "Stone", "8E8E80", 0.8, 0, 0 }, { "Moss", "5E9E3A", 0.8, 0, 0 }, { "Glow", "9BE7FF", 0.8, 0, 2 } },
	ShrineStone = { { "Stone", "9E9E8E", 0.8, 0, 0 } },
	Skaddle = { { "Body", "F7F9FC", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A1A2A4", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "Trim", "F59E0B", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Snailbyte = { { "Body", "7FB3D5", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "53748A", 0.8, 0, 0 }, { "Accessory", "C8CDD3", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	SnowPine = { { "Trunk", "7A8C96", 0.8, 0, 0 }, { "Snow", "DDEFF5", 0.8, 0, 0 } },
	Snowbun = { { "Body", "DDEBF7", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "9099A1", 0.8, 0, 0 }, { "Accessory", "33B6FF", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	SparkStation = { { "Stem", "3F9B3A", 0.8, 0, 0 }, { "Petal", "A855F7", 0.8, 0, 0 }, { "Glow", "FFC83D", 0.8, 0, 2 } },
	Sparkfox = { { "Body", "FF6B35", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "A64622", 0.8, 0, 0 }, { "Accessory", "FFC83D", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Thunderhog = { { "Body", "8E44AD", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "5C2C70", 0.8, 0, 0 }, { "Accessory", "A7BF4B", 0.8, 0, 0 }, { "Trim", "C026D3", 0.3, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Toastoad = { { "Body", "E8713A", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "974926", 0.8, 0, 0 }, { "Accessory", "3AE8C8", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Twiglet = { { "Body", "8B5A2B", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "5A3B1C", 0.8, 0, 0 }, { "Accessory", "3BBFBE", 0.8, 0, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
	Zapfinch = { { "Body", "5DADE2", 0.8, 0, 0 }, { "EyeWhite", "FFFFFF", 0.5, 0, 0 }, { "Pupil", "08080A", 0.4, 0, 0 }, { "Mouth", "2E0D14", 0.8, 0, 0 }, { "BodyDark", "3C7093", 0.8, 0, 0 }, { "Accessory", "E25D6B", 0.35, 1, 0 }, { "EyeHighlight", "FFFFFF", 0.3, 0, 0 } },
}
-- END PASTE

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

local function main()
	local names: { string } = {}
	for name in ASSET_IDS do
		table.insert(names, name)
	end
	table.sort(names)
	if #names == 0 then
		print("install_models: ASSET_IDS is empty; paste the output of `python3 tools/upload_assets.py --emit-luau`")
		return
	end

	local models = ensureFolder(ReplicatedStorage, MODELS_FOLDER)
	local props = ensureFolder(models, PROPS_FOLDER)

	local installed = 0
	local failed = 0
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
	print(("install_models: %d installed, %d failed, %d total"):format(installed, failed, #names))
	if failed > 0 then
		print("A failure right after upload usually means the asset is still in moderation (up to a few hours); run again later.")
	end
end

main()
