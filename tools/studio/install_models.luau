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
--
-- Block-cell props (Decision B44; assets/models/props/<Name>/ from `export_models.py --props`): a prop in BLOCK_CELL_PROPS is installed the
-- same way into ReplicatedStorage.Models.Props, never from its old blockout id: the source is its new upload, else the selected imported Model,
-- else one already under Models.Props with a part named Body, BodyDark, Accessory or Trim (a re-run). Its MeshParts are its colour slots
-- (Body, BodyDark, Accessory, Trim on the atlas; Glow Neon); every part Anchored and collision left on (Shared/Props.Place sets CanCollide
-- and the fidelity from data/Props). BLOCK_CELL_PROPS is `export_models.py --emit-luau --props` (between the BLOCK-CELL PROPS PASTE markers).

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
	ArchBridge = 100866168947335,
	Bench = 129578936462861,
	BlossomTree = 86047383661807,
	Boulder = 116759392207271,
	BuildStation = 102869559733997,
	Bush = 131412714992852,
	Buzzlebee = 90983073121915,
	CampCrate = 70497878511393,
	CampFlag = 95659454055737,
	Campfire = 122461350675998,
	Capybubble = 107898420617031,
	CaveMouth = 132103896359941,
	Chipmole = 99728350452516,
	CrashWreck = 74817192673896,
	Drippo = 85644366482246,
	Emberchin = 121001466165205,
	Fence = 102938140774553,
	Fenripup = 75070069889969,
	Flag = 90062331463442,
	Flapsicle = 101851912195987,
	FlowerPatch = 135752098587893,
	Flufflet = 83783025796871,
	Fountain = 83951227918407,
	Frostfang = 106945588536399,
	FrozenLog = 85556402993990,
	Gaiabloom = 98176134122001,
	GatherStation = 109164418132495,
	GeyserCone = 105425785899723,
	GeyserVent = 112138566520848,
	Glimmo = 86858457841953,
	Gloomoth = 118890551905521,
	GlowFern = 125072432310618,
	GlowcapGiant = 117920330924486,
	GlowcapGiantBlue = 89013956645212,
	GlowcapGiantPink = 113989154132526,
	GlowcapSmall = 94355790262720,
	GrottoCrystal = 135279166472081,
	HabitatFrostbyte = 89002985688787,
	HabitatVerdant = 115551193652891,
	HeaterLamp = 90164225940384,
	IceCaveMouth = 73067765487784,
	IceCrystalCluster = 121312349675975,
	IceLantern = 121933457814748,
	IceRock = 76857079544887,
	IceRockB = 134221683669516,
	IceSignArmHigh = 110560294652685,
	IceSignArmLow = 84897250093660,
	IceSignArmMid = 123109088414678,
	IceSpire = 87856482527354,
	Icicles = 116751160175551,
	Kettlepuff = 89382463269455,
	Lantern = 113167192482454,
	Lanternewt = 115058641916832,
	LilyPad = 122673551171714,
	Log = 131627870594501,
	MeadowRock = 88678220176697,
	MeadowRockB = 132263048949650,
	MeadowTree = 121178738911533,
	MeadowTreeB = 93870949713381,
	MoonPoolRing = 112182609320789,
	MoonTree = 132229763849776,
	MoonTreeB = 135628295699646,
	MossStone = 72806329723798,
	Mossbop = 76286989342632,
	Mushroom = 72020219398485,
	Nebulyn = 112291898528534,
	Panpipe = 93548551011238,
	PathLantern = 130101963365955,
	Pebblet = 120711912140485,
	Pedestal = 98463678388823,
	Pengoo = 75587289427504,
	Planter = 114986346522730,
	Puffpuff = 128760821641478,
	Radish = 118232011556551,
	Reeds = 122578038240807,
	Reindazzle = 81819705890422,
	Rocklobber = 91046356996222,
	RoomCabin = 105761041582148,
	RoomDome = 117777283592193,
	RoomTower = 108272738122563,
	Shellberg = 98400901055778,
	Shimmerlynx = 97482261000062,
	ShipHull = 81470422409500,
	Shrine = 76438506078117,
	ShrineStone = 78669584933977,
	SightPost = 93919081600426,
	SignArmHigh = 137349550790300,
	SignArmLow = 129431571109068,
	SignArmMid = 71757621384434,
	Signpost = 74047329484786,
	Skaddle = 138821009662968,
	Snailbyte = 127624587145029,
	SnowBush = 121498439469799,
	SnowDrift = 81110116382095,
	SnowPine = 113692517294473,
	SnowPineB = 140047894378836,
	Snowbun = 112987344531192,
	SparkStation = 132831465418886,
	Sparkfox = 129902686231899,
	Spookum = 107247366211382,
	StarIsland = 94576361220525,
	SteppingStone = 129219870310799,
	Thunderhog = 138702894272903,
	Toastoad = 76456734696236,
	Twiglet = 137645911740591,
	Wisplet = 110004797552628,
	Zapfinch = 102395774185067,
}
local PROP_NAMES: { [string]: boolean } = {
	ArchBridge = true,
	Bench = true,
	BlossomTree = true,
	Boulder = true,
	BuildStation = true,
	Bush = true,
	CampCrate = true,
	CampFlag = true,
	Campfire = true,
	CaveMouth = true,
	CrashWreck = true,
	Fence = true,
	Flag = true,
	FlowerPatch = true,
	Fountain = true,
	FrozenLog = true,
	GatherStation = true,
	GeyserCone = true,
	GeyserVent = true,
	GlowFern = true,
	GlowcapGiant = true,
	GlowcapGiantBlue = true,
	GlowcapGiantPink = true,
	GlowcapSmall = true,
	GrottoCrystal = true,
	HabitatFrostbyte = true,
	HabitatVerdant = true,
	HeaterLamp = true,
	IceCaveMouth = true,
	IceCrystalCluster = true,
	IceLantern = true,
	IceRock = true,
	IceRockB = true,
	IceSignArmHigh = true,
	IceSignArmLow = true,
	IceSignArmMid = true,
	IceSpire = true,
	Icicles = true,
	Lantern = true,
	LilyPad = true,
	Log = true,
	MeadowRock = true,
	MeadowRockB = true,
	MeadowTree = true,
	MeadowTreeB = true,
	MoonPoolRing = true,
	MoonTree = true,
	MoonTreeB = true,
	MossStone = true,
	Mushroom = true,
	PathLantern = true,
	Pedestal = true,
	Planter = true,
	Reeds = true,
	RoomCabin = true,
	RoomDome = true,
	RoomTower = true,
	ShipHull = true,
	Shrine = true,
	ShrineStone = true,
	SightPost = true,
	SignArmHigh = true,
	SignArmLow = true,
	SignArmMid = true,
	Signpost = true,
	SnowBush = true,
	SnowDrift = true,
	SnowPine = true,
	SnowPineB = true,
	SparkStation = true,
	StarIsland = true,
	SteppingStone = true,
}
local MATERIALS: { [string]: { { string | number } } } = {
	ArchBridge = { { "Body", "B07A56", 0.55, 0, 0 }, { "BodyDark", "6A4636", 0.55, 0, 0 }, { "Accessory", "3C3564", 0.55, 0, 0 }, { "Trim", "2C7F72", 0.55, 0, 0 }, { "Glow", "FFE7B0", 0.55, 0, 1.5 } },
	Bench = { { "Body", "C08A55", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "8FD9B6", 0.55, 0, 0 }, { "Trim", "9E9E8E", 0.55, 0, 0 } },
	BlossomTree = { { "Body", "FF9EC4", 0.55, 0, 0 }, { "BodyDark", "6B3F2A", 0.55, 0, 0 }, { "Accessory", "FFE3EE", 0.55, 0, 0 } },
	Boulder = { { "Body", "9E9E8E", 0.55, 0, 0 }, { "BodyDark", "7C7C6E", 0.55, 0, 0 }, { "Accessory", "6CB04A", 0.55, 0, 0 }, { "Trim", "F2E6D0", 0.55, 0, 0 }, { "Glow", "FFB86B", 0.55, 0, 1.5 } },
	BuildStation = { { "Body", "C99A5B", 0.55, 0, 0 }, { "BodyDark", "8B5A2B", 0.55, 0, 0 }, { "Accessory", "8FD3FF", 0.55, 0, 0 }, { "Trim", "8A93A0", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	Bush = { { "Body", "57B04A", 0.55, 0, 0 }, { "Accessory", "FF5C8A", 0.55, 0, 0 } },
	Buzzlebee = { { "Body", "FFC83D", 0.55, 0, 0 }, { "antenna", "FF6B9A", 0.55, 0, 0 }, { "stinger", "4A2F1F", 0.55, 0, 0 }, { "wingL", "FF6B9A", 0.55, 0, 0 }, { "wingR", "FF6B9A", 0.55, 0, 0 }, { "FacePlate", "FFC83D", 0.4, 0, 0 } },
	CampCrate = { { "Body", "C08A55", 0.55, 0, 0 }, { "BodyDark", "8C5E32", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "68C9FE", 0.55, 0, 0 } },
	CampFlag = { { "Body", "FFC83D", 0.55, 0, 0 }, { "BodyDark", "6E7690", 0.55, 0, 0 }, { "Accessory", "68C9FE", 0.55, 0, 0 }, { "Trim", "8E8E86", 0.55, 0, 0 }, { "Glow", "FFE36B", 0.55, 0, 1.5 } },
	Campfire = { { "Body", "FF8A2A", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Trim", "8E8E86", 0.55, 0, 0 }, { "Glow", "FFD34D", 0.55, 0, 1.5 } },
	Capybubble = { { "Body", "E0C3A0", 0.55, 0, 0 }, { "earL", "5C4A2A", 0.55, 0, 0 }, { "earR", "5C4A2A", 0.55, 0, 0 }, { "floatR", "5FDCFF", 0.55, 0, 1.5 }, { "leafR", "5C4A2A", 0.55, 0, 0 }, { "ring", "5FDCFF", 0.55, 0, 1.5 }, { "FacePlate", "E0C3A0", 0.4, 0, 0 } },
	CaveMouth = { { "Body", "7A756E", 0.55, 0, 0 }, { "BodyDark", "15120F", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Trim", "C084FC", 0.55, 0, 0 }, { "Glow", "7FE3FF", 0.55, 0, 1.5 } },
	Chipmole = { { "Body", "5B6B85", 0.55, 0, 0 }, { "pickL", "3FD3F7", 0.55, 0, 0 }, { "pickR", "3FD3F7", 0.55, 0, 0 }, { "tailR", "3FD3F7", 0.55, 0, 0 }, { "FacePlate", "5B6B85", 0.4, 0, 0 } },
	CrashWreck = { { "Body", "A4AEBC", 0.55, 0, 0 }, { "BodyDark", "463A31", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "8FE3F5", 0.55, 0, 0 }, { "Glow", "FF8A3D", 0.55, 0, 1.5 } },
	Drippo = { { "Body", "A9D6F5", 0.55, 0, 0 }, { "armR", "2F5F9F", 0.55, 0, 0 }, { "beadL", "0FB4E0", 0.55, 0, 0 }, { "dripL", "0FB4E0", 0.55, 0, 0 }, { "FacePlate", "A9D6F5", 0.4, 0, 0 } },
	Emberchin = { { "Body", "73365A", 0.55, 0, 0 }, { "cinderR", "FF8C2E", 0.55, 0, 0 }, { "ember", "FF8C2E", 0.55, 0, 0 }, { "pool", "C8DCE4", 0.55, 0, 0 }, { "quillL", "FF8C2E", 0.55, 0, 0 }, { "quillR", "FF8C2E", 0.55, 0, 0 }, { "FacePlate", "73365A", 0.4, 0, 0 } },
	Fence = { { "Body", "B98552", 0.55, 0, 0 }, { "BodyDark", "8A5A35", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Trim", "FF8FB0", 0.55, 0, 0 } },
	Fenripup = { { "Body", "4B3D8F", 0.55, 0, 0 }, { "Glow", "AEB8FF", 0.55, 0, 1.5 }, { "chain", "D9E2F5", 0.55, 0, 0 }, { "earL", "4B3D8F", 0.55, 0, 0 }, { "earR", "4B3D8F", 0.55, 0, 0 }, { "halo", "D9E2F5", 0.55, 0, 0 }, { "mane", "1E1A47", 0.55, 0, 0 }, { "moon", "AEB8FF", 0.55, 0, 1.5 }, { "moteL", "AEB8FF", 0.55, 0, 1.5 }, { "moteR", "AEB8FF", 0.55, 0, 1.5 }, { "shade", "4B3D8F", 0.55, 0, 0 }, { "stars", "AEB8FF", 0.55, 0, 1.5 }, { "tail", "4B3D8F", 0.55, 0, 0 }, { "FacePlate", "4B3D8F", 0.4, 0, 0 } },
	Flag = { { "Body", "FF8AD8", 0.55, 0, 0 }, { "BodyDark", "6E7690", 0.55, 0, 0 }, { "Accessory", "6BCB3F", 0.55, 0, 0 }, { "Trim", "9E9E8E", 0.55, 0, 0 }, { "Glow", "FFEF4A", 0.55, 0, 1.5 } },
	Flapsicle = { { "Body", "3F4C8C", 0.55, 0, 0 }, { "earL", "3F4C8C", 0.55, 0, 0 }, { "earR", "3F4C8C", 0.55, 0, 0 }, { "perch", "8FC9F0", 0.55, 0, 0 }, { "wingL", "8FC9F0", 0.55, 0, 0 }, { "wingR", "8FC9F0", 0.55, 0, 0 }, { "FacePlate", "3F4C8C", 0.4, 0, 0 } },
	FlowerPatch = { { "Body", "FF8FB0", 0.55, 0, 0 }, { "BodyDark", "3F8F2E", 0.55, 0, 0 }, { "Accessory", "FFD34D", 0.55, 0, 0 }, { "Trim", "F7F3EA", 0.55, 0, 0 } },
	Flufflet = { { "Body", "F2F6FA", 0.55, 0, 0 }, { "ball", "9CC3E0", 0.55, 0, 0 }, { "earL", "F0614A", 0.55, 0, 0 }, { "earR", "F0614A", 0.55, 0, 0 }, { "scarfR", "9CC3E0", 0.55, 0, 0 }, { "FacePlate", "F2F6FA", 0.4, 0, 0 } },
	Fountain = { { "Body", "CFC8B6", 0.55, 0, 0 }, { "BodyDark", "948C7A", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Trim", "3FA2E6", 0.55, 0, 0 }, { "Glow", "BFF3FF", 0.55, 0, 1.5 } },
	Frostfang = { { "Body", "4F9BD8", 0.55, 0, 0 }, { "Glow", "2ED3F7", 0.55, 0, 1.5 }, { "crown", "2ED3F7", 0.55, 0, 1.5 }, { "earL", "4F9BD8", 0.55, 0, 0 }, { "earR", "4F9BD8", 0.55, 0, 0 }, { "pawL", "F2F7FB", 0.55, 0, 0 }, { "pawR", "F2F7FB", 0.55, 0, 0 }, { "ruff", "22406B", 0.55, 0, 0 }, { "tailR", "4F9BD8", 0.55, 0, 0 }, { "FacePlate", "4F9BD8", 0.4, 0, 0 } },
	FrozenLog = { { "BodyDark", "4A3A2E", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 } },
	Gaiabloom = { { "Body", "F0E6CE", 0.55, 0, 0 }, { "Glow", "F0287E", 0.55, 0, 1.5 }, { "antlerL", "4FB84E", 0.55, 0, 0 }, { "antlerR", "4FB84E", 0.55, 0, 0 }, { "butterflyR", "F0287E", 0.55, 0, 1.5 }, { "butterfly2L", "F0287E", 0.55, 0, 1.5 }, { "cape", "4FB84E", 0.55, 0, 0 }, { "earL", "F0E6CE", 0.55, 0, 0 }, { "earR", "F0E6CE", 0.55, 0, 0 }, { "halo", "4FB84E", 0.55, 0, 0 }, { "tail", "F0E6CE", 0.55, 0, 0 }, { "FacePlate", "F0E6CE", 0.4, 0, 0 } },
	GatherStation = { { "Body", "C99A5B", 0.55, 0, 0 }, { "BodyDark", "8B5A2B", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "E8483D", 0.55, 0, 0 }, { "Glow", "FFD98A", 0.55, 0, 1.5 } },
	GeyserCone = { { "Body", "8C5A3C", 0.55, 0, 0 }, { "BodyDark", "4A2E1E", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "D9A066", 0.55, 0, 0 }, { "Glow", "BFF3FF", 0.55, 0, 1.5 } },
	GeyserVent = { { "Body", "6B4A36", 0.55, 0, 0 }, { "BodyDark", "2A1A12", 0.55, 0, 0 }, { "Accessory", "F2FBFF", 0.55, 0, 0 }, { "Trim", "D98A4E", 0.55, 0, 0 }, { "Glow", "9FE8FF", 0.55, 0, 1.5 } },
	Glimmo = { { "Body", "4FCFC0", 0.55, 0, 0 }, { "bulb", "FFE566", 0.55, 0, 0 }, { "tendril", "2E7F78", 0.55, 0, 0 }, { "wingL", "2E7F78", 0.55, 0, 0 }, { "wingR", "2E7F78", 0.55, 0, 0 }, { "FacePlate", "4FCFC0", 0.4, 0, 0 } },
	Gloomoth = { { "Body", "8C6FB5", 0.55, 0, 0 }, { "antennaL", "B832E8", 0.55, 0, 1.5 }, { "antennaR", "B832E8", 0.55, 0, 1.5 }, { "hindwingL", "B832E8", 0.55, 0, 1.5 }, { "hindwingR", "B832E8", 0.55, 0, 1.5 }, { "shard", "E8C45A", 0.55, 0, 0 }, { "wingL", "D9C8FF", 0.55, 0, 0 }, { "wingR", "D9C8FF", 0.55, 0, 0 }, { "FacePlate", "8C6FB5", 0.4, 0, 0 } },
	GlowFern = { { "Body", "2F9A8A", 0.55, 0, 0 }, { "BodyDark", "1F6670", 0.55, 0, 0 }, { "Glow", "A6E8FF", 0.55, 0, 1.5 } },
	GlowcapGiant = { { "Body", "ECE6FF", 0.55, 0, 0 }, { "BodyDark", "D6CCEE", 0.55, 0, 0 }, { "Accessory", "9C8FD0", 0.55, 0, 0 }, { "Trim", "2C7F72", 0.55, 0, 0 }, { "Glow", "EEF6FF", 0.55, 0, 1.5 } },
	GlowcapGiantBlue = { { "Body", "86C8F5", 0.55, 0, 0 }, { "BodyDark", "DCD6F2", 0.55, 0, 0 }, { "Accessory", "4A78C0", 0.55, 0, 0 }, { "Trim", "2C7F72", 0.55, 0, 0 }, { "Glow", "A6E8FF", 0.55, 0, 1.5 } },
	GlowcapGiantPink = { { "Body", "F49AD8", 0.55, 0, 0 }, { "BodyDark", "E4DAF4", 0.55, 0, 0 }, { "Accessory", "B85CA6", 0.55, 0, 0 }, { "Trim", "2C7F72", 0.55, 0, 0 }, { "Glow", "FFB3E6", 0.55, 0, 1.5 } },
	GlowcapSmall = { { "Body", "F5A6DC", 0.55, 0, 0 }, { "BodyDark", "E6DEF6", 0.55, 0, 0 }, { "Accessory", "FFF4FB", 0.55, 0, 0 }, { "Trim", "2C7F72", 0.55, 0, 0 }, { "Glow", "D2B0FF", 0.55, 0, 1.5 } },
	GrottoCrystal = { { "Body", "A8F0FA", 0.55, 0, 0 }, { "BodyDark", "6E6A78", 0.55, 0, 0 }, { "Accessory", "B49CFF", 0.55, 0, 0 }, { "Trim", "6CB04A", 0.55, 0, 0 }, { "Glow", "7FE3F0", 0.55, 0, 1.5 } },
	HabitatFrostbyte = { { "Body", "F2F6FA", 0.55, 0, 0 }, { "BodyDark", "4A3A2E", 0.55, 0, 0 }, { "Accessory", "2F6B5E", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 }, { "Glow", "7FE3F0", 0.55, 0, 1.5 } },
	HabitatVerdant = { { "Body", "6FBF4A", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "F49AD8", 0.55, 0, 0 }, { "Trim", "3FA2E6", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	HeaterLamp = { { "Body", "6B7580", 0.55, 0, 0 }, { "BodyDark", "3D4556", 0.55, 0, 0 }, { "Trim", "C9CFD8", 0.55, 0, 0 }, { "Glow", "FFB347", 0.55, 0, 1.5 } },
	IceCaveMouth = { { "Body", "CFEAF7", 0.55, 0, 0 }, { "BodyDark", "0E1A26", 0.55, 0, 0 }, { "Accessory", "F7FBFF", 0.55, 0, 0 }, { "Trim", "6EC6F0", 0.55, 0, 0 }, { "Glow", "68C9FE", 0.55, 0, 1.5 } },
	IceCrystalCluster = { { "Body", "BFEBFA", 0.55, 0, 0 }, { "BodyDark", "7F8E99", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Glow", "68C9FE", 0.55, 0, 1.5 } },
	IceLantern = { { "Body", "BFEBFA", 0.55, 0, 0 }, { "BodyDark", "7F8E99", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Glow", "FFB347", 0.55, 0, 1.5 } },
	IceRock = { { "Body", "A9B7C0", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 }, { "Glow", "BFF3FF", 0.55, 0, 1.5 } },
	IceRockB = { { "Body", "A9B7C0", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 }, { "Glow", "BFF3FF", 0.55, 0, 1.5 } },
	IceSignArmHigh = { { "Body", "D4B483", 0.55, 0, 0 }, { "BodyDark", "F2F6FA", 0.55, 0, 0 }, { "Accessory", "5CE0B8", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	IceSignArmLow = { { "Body", "D4B483", 0.55, 0, 0 }, { "BodyDark", "F2F6FA", 0.55, 0, 0 }, { "Accessory", "B49CFF", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	IceSignArmMid = { { "Body", "D4B483", 0.55, 0, 0 }, { "BodyDark", "F2F6FA", 0.55, 0, 0 }, { "Accessory", "68C9FE", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	IceSpire = { { "Body", "BFEBFA", 0.55, 0, 0 }, { "BodyDark", "7F8E99", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Glow", "7FE6FF", 0.55, 0, 1.5 } },
	Icicles = { { "Body", "BFEBFA", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "9FE3FF", 0.55, 0, 0 }, { "Glow", "E8FAFF", 0.55, 0, 1.5 } },
	Kettlepuff = { { "Body", "F5EDE0", 0.55, 0, 0 }, { "floatR", "F5EDE0", 0.55, 0, 0 }, { "handle", "C8743A", 0.55, 0, 0 }, { "lid", "C8743A", 0.55, 0, 0 }, { "wispR", "F5EDE0", 0.55, 0, 0 }, { "FacePlate", "F5EDE0", 0.4, 0, 0 } },
	Lantern = { { "Body", "4A3B2E", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Trim", "C9A15B", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	Lanternewt = { { "Body", "F26B3A", 0.55, 0, 0 }, { "gillL", "4A2638", 0.55, 0, 0 }, { "gillR", "4A2638", 0.55, 0, 0 }, { "tail", "F26B3A", 0.55, 0, 0 }, { "FacePlate", "F26B3A", 0.4, 0, 0 } },
	LilyPad = { { "Body", "4FAF4A", 0.55, 0, 0 }, { "BodyDark", "3F8F2E", 0.55, 0, 0 }, { "Accessory", "FFB3CC", 0.55, 0, 0 }, { "Trim", "FFD34D", 0.55, 0, 0 } },
	Log = { { "Body", "6CB04A", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "E8843D", 0.55, 0, 0 }, { "Trim", "F2E6D0", 0.55, 0, 0 } },
	MeadowRock = { { "Body", "9E9E8E", 0.55, 0, 0 }, { "BodyDark", "7C7C6E", 0.55, 0, 0 }, { "Accessory", "6CB04A", 0.55, 0, 0 } },
	MeadowRockB = { { "Body", "9E9E8E", 0.55, 0, 0 }, { "BodyDark", "7C7C6E", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Trim", "F7F3EA", 0.55, 0, 0 } },
	MeadowTree = { { "Body", "4CAF46", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "FFD34D", 0.55, 0, 0 } },
	MeadowTreeB = { { "Body", "3F9B3A", 0.55, 0, 0 }, { "BodyDark", "6B3F26", 0.55, 0, 0 }, { "Accessory", "FFF3F7", 0.55, 0, 0 } },
	MoonPoolRing = { { "Body", "6E69AE", 0.55, 0, 0 }, { "Accessory", "2E8A78", 0.55, 0, 0 }, { "Trim", "3BA88A", 0.55, 0, 0 }, { "Glow", "FFB3E6", 0.55, 0, 1.5 } },
	MoonTree = { { "Body", "4752C4", 0.55, 0, 0 }, { "BodyDark", "3F2878", 0.55, 0, 0 }, { "Accessory", "2A8A94", 0.55, 0, 0 }, { "Trim", "CDC3F2", 0.55, 0, 0 }, { "Glow", "1B9C94", 0.55, 0, 1.5 } },
	MoonTreeB = { { "Body", "2A8A94", 0.55, 0, 0 }, { "BodyDark", "4A2F86", 0.55, 0, 0 }, { "Accessory", "5560D0", 0.55, 0, 0 }, { "Trim", "D2B0FF", 0.55, 0, 0 }, { "Glow", "9B3FD0", 0.55, 0, 1.5 } },
	MossStone = { { "Body", "5D5BA0", 0.55, 0, 0 }, { "Accessory", "2E8A70", 0.55, 0, 0 }, { "Glow", "D2B0FF", 0.55, 0, 1.5 } },
	Mossbop = { { "Body", "6CCB5F", 0.55, 0, 0 }, { "floatR", "D9F36B", 0.55, 0, 0 }, { "sprout", "D9F36B", 0.55, 0, 0 }, { "FacePlate", "6CCB5F", 0.4, 0, 0 } },
	Mushroom = { { "Body", "E8483D", 0.55, 0, 0 }, { "BodyDark", "F2E6D0", 0.55, 0, 0 }, { "Accessory", "FFF8EE", 0.55, 0, 0 }, { "Trim", "5E9E3A", 0.55, 0, 0 } },
	Nebulyn = { { "Body", "6B4EC2", 0.55, 0, 0 }, { "Glow", "FFF3B0", 0.55, 0, 1.5 }, { "comet", "FFF3B0", 0.55, 0, 1.5 }, { "fallenR", "FFF3B0", 0.55, 0, 1.5 }, { "planetL", "E66BD2", 0.55, 0, 0 }, { "puff", "6B4EC2", 0.55, 0, 0 }, { "starL", "FFF3B0", 0.55, 0, 1.5 }, { "starR", "FFF3B0", 0.55, 0, 1.5 }, { "tailR", "FFF3B0", 0.55, 0, 1.5 }, { "twinkleR", "FFF3B0", 0.55, 0, 1.5 }, { "twinkle2R", "FFF3B0", 0.55, 0, 1.5 }, { "FacePlate", "6B4EC2", 0.4, 0, 0 } },
	Panpipe = { { "Body", "4A4166", 0.55, 0, 0 }, { "Glow", "9B5CFF", 0.55, 0, 1.5 }, { "beard", "1E1A2E", 0.55, 0, 0 }, { "bellR", "8C86A6", 0.55, 0, 0 }, { "earL", "4A4166", 0.55, 0, 0 }, { "earR", "4A4166", 0.55, 0, 0 }, { "echoR", "9B5CFF", 0.55, 0, 1.5 }, { "eclipse", "9B5CFF", 0.55, 0, 1.5 }, { "gem", "9B5CFF", 0.55, 0, 1.5 }, { "noteL", "9B5CFF", 0.55, 0, 1.5 }, { "note2R", "9B5CFF", 0.55, 0, 1.5 }, { "pipesR", "9B5CFF", 0.55, 0, 1.5 }, { "tail", "1E1A2E", 0.55, 0, 0 }, { "FacePlate", "4A4166", 0.4, 0, 0 } },
	PathLantern = { { "Body", "3A3562", 0.55, 0, 0 }, { "BodyDark", "272340", 0.55, 0, 0 }, { "Accessory", "2C7F72", 0.55, 0, 0 }, { "Trim", "A891E6", 0.55, 0, 0 }, { "Glow", "FFB84D", 0.55, 0, 1.5 } },
	Pebblet = { { "Body", "C4B9A6", 0.55, 0, 0 }, { "cairnR", "5A5048", 0.55, 0, 0 }, { "legL", "5A5048", 0.55, 0, 0 }, { "legR", "5A5048", 0.55, 0, 0 }, { "FacePlate", "C4B9A6", 0.4, 0, 0 } },
	Pedestal = { { "Body", "D8D2BC", 0.55, 0, 0 }, { "BodyDark", "B9B29A", 0.55, 0, 0 }, { "Glow", "9BE7FF", 0.55, 0, 1.5 } },
	Pengoo = { { "Body", "2B3F5C", 0.55, 0, 0 }, { "pack", "FFA63D", 0.55, 0, 0 }, { "tuft", "2B3F5C", 0.55, 0, 0 }, { "wingL", "2B3F5C", 0.55, 0, 0 }, { "wingR", "2B3F5C", 0.55, 0, 0 }, { "FacePlate", "F4F7FA", 0.4, 0, 0 } },
	Planter = { { "Body", "C08A55", 0.55, 0, 0 }, { "BodyDark", "6B4630", 0.55, 0, 0 }, { "Accessory", "3F9B3A", 0.55, 0, 0 }, { "Trim", "FF8AD8", 0.55, 0, 0 }, { "Glow", "FFEF4A", 0.55, 0, 1.5 } },
	Puffpuff = { { "Body", "F4F1E8", 0.55, 0, 0 }, { "floatR", "F4F1E8", 0.55, 0, 0 }, { "leafL", "4E9E3C", 0.55, 0, 0 }, { "leafR", "4E9E3C", 0.55, 0, 0 }, { "seeds", "F4F1E8", 0.55, 0, 0 }, { "FacePlate", "F4F1E8", 0.4, 0, 0 } },
	Radish = { { "Body", "D7265C", 0.55, 0, 0 }, { "frondL", "2CC5B2", 0.55, 0, 0 }, { "frondR", "2CC5B2", 0.55, 0, 0 }, { "gem", "FFC21A", 0.55, 0, 1.5 }, { "halo", "FFB21E", 0.55, 0, 0 }, { "leaf", "2CC5B2", 0.55, 0, 0 }, { "moteL", "FFC21A", 0.55, 0, 1.5 }, { "moteR", "FFC21A", 0.55, 0, 1.5 }, { "orb", "FFC21A", 0.55, 0, 1.5 }, { "pendant", "FFC21A", 0.55, 0, 1.5 }, { "sunstone", "FFC21A", 0.55, 0, 1.5 }, { "wingL", "FFB21E", 0.55, 0, 0 }, { "wingR", "FFB21E", 0.55, 0, 0 }, { "FacePlate", "D7265C", 0.4, 0, 0 } },
	Reeds = { { "Body", "7DB04A", 0.55, 0, 0 }, { "BodyDark", "4F7F3A", 0.55, 0, 0 }, { "Accessory", "7B4A2D", 0.55, 0, 0 } },
	Reindazzle = { { "Body", "A8805A", 0.55, 0, 0 }, { "chimeL", "A8E4FF", 0.55, 0, 0 }, { "chimeR", "A8E4FF", 0.55, 0, 0 }, { "earL", "A8805A", 0.55, 0, 0 }, { "earR", "A8805A", 0.55, 0, 0 }, { "nose", "E0202C", 0.55, 0, 1.5 }, { "tail", "A8E4FF", 0.55, 0, 0 }, { "FacePlate", "A8805A", 0.4, 0, 0 } },
	Rocklobber = { { "Body", "C8553D", 0.55, 0, 0 }, { "antennaR", "A39E94", 0.55, 0, 0 }, { "clawL", "A39E94", 0.55, 0, 0 }, { "clawR", "A39E94", 0.55, 0, 0 }, { "geodeL", "FF8C1A", 0.55, 0, 1.5 }, { "legL", "3A3238", 0.55, 0, 0 }, { "legR", "3A3238", 0.55, 0, 0 }, { "FacePlate", "C8553D", 0.4, 0, 0 } },
	RoomCabin = { { "Body", "B57A45", 0.55, 0, 0 }, { "BodyDark", "8E3A30", 0.55, 0, 0 }, { "Accessory", "A3A096", 0.55, 0, 0 }, { "Trim", "5A3A24", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	RoomDome = { { "Body", "EEF0F7", 0.55, 0, 0 }, { "BodyDark", "6E7690", 0.55, 0, 0 }, { "Accessory", "FF9A3D", 0.55, 0, 0 }, { "Trim", "7FD3F0", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	RoomTower = { { "Body", "D3C7AC", 0.55, 0, 0 }, { "BodyDark", "4A5BC4", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "7B4A2D", 0.55, 0, 0 }, { "Glow", "FFC86B", 0.55, 0, 1.5 } },
	Shellberg = { { "Body", "3FBFB0", 0.55, 0, 0 }, { "Glow", "2ED3F7", 0.55, 0, 1.5 }, { "dripL", "8CC8F0", 0.55, 0, 0 }, { "flagL", "2ED3F7", 0.55, 0, 1.5 }, { "footL", "1F6F68", 0.55, 0, 0 }, { "footR", "1F6F68", 0.55, 0, 0 }, { "shardsR", "2ED3F7", 0.55, 0, 1.5 }, { "tail", "1F6F68", 0.55, 0, 0 }, { "FacePlate", "3FBFB0", 0.4, 0, 0 } },
	Shimmerlynx = { { "Body", "C8C2F0", 0.55, 0, 0 }, { "crest", "9D7CFF", 0.55, 0, 1.5 }, { "earL", "C8C2F0", 0.55, 0, 0 }, { "earR", "C8C2F0", 0.55, 0, 0 }, { "mote", "9D7CFF", 0.55, 0, 1.5 }, { "pendant", "8FA6C4", 0.55, 0, 0 }, { "tailR", "9D7CFF", 0.55, 0, 1.5 }, { "whiskerL", "4B4470", 0.55, 0, 0 }, { "whiskerR", "4B4470", 0.55, 0, 0 }, { "FacePlate", "C8C2F0", 0.4, 0, 0 } },
	ShipHull = { { "Body", "7A8494", 0.55, 0, 0 }, { "BodyDark", "3A4049", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "B8C2CF", 0.55, 0, 0 }, { "Glow", "68C9FE", 0.55, 0, 1.5 } },
	Shrine = { { "Body", "9E9E8E", 0.55, 0, 0 }, { "BodyDark", "C8C0A6", 0.55, 0, 0 }, { "Accessory", "5E9E3A", 0.55, 0, 0 }, { "Glow", "2ECC71", 0.55, 0, 1.5 } },
	ShrineStone = { { "Body", "9E9E8E", 0.55, 0, 0 }, { "BodyDark", "7C7C6E", 0.55, 0, 0 }, { "Accessory", "6CB04A", 0.55, 0, 0 }, { "Glow", "9BE7FF", 0.55, 0, 1.5 } },
	SightPost = { { "Body", "A8794A", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Trim", "8E8E86", 0.55, 0, 0 }, { "Glow", "FFE36B", 0.55, 0, 1.5 } },
	SignArmHigh = { { "Body", "E8D4A8", 0.55, 0, 0 }, { "Accessory", "CBC2EE", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	SignArmLow = { { "Body", "E8D4A8", 0.55, 0, 0 }, { "Accessory", "FFC83D", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	SignArmMid = { { "Body", "E8D4A8", 0.55, 0, 0 }, { "Accessory", "3FA2E6", 0.55, 0, 0 }, { "Trim", "5A5A66", 0.55, 0, 0 } },
	Signpost = { { "Body", "C08A55", 0.55, 0, 0 }, { "BodyDark", "7B4A2D", 0.55, 0, 0 }, { "Accessory", "FFF4DC", 0.55, 0, 0 }, { "Trim", "9E9E8E", 0.55, 0, 0 } },
	Skaddle = { { "Body", "F4F7FA", 0.55, 0, 0 }, { "Glow", "4A55E8", 0.55, 0, 1.5 }, { "crest", "4A55E8", 0.55, 0, 1.5 }, { "halo", "4A55E8", 0.55, 0, 1.5 }, { "hindwingL", "F4F7FA", 0.55, 0, 0 }, { "hindwingR", "F4F7FA", 0.55, 0, 0 }, { "quiverL", "5C708A", 0.55, 0, 0 }, { "scarfR", "8FD3F4", 0.55, 0, 0 }, { "tuftL", "F4F7FA", 0.55, 0, 0 }, { "tuftR", "F4F7FA", 0.55, 0, 0 }, { "wingL", "F4F7FA", 0.55, 0, 0 }, { "wingR", "F4F7FA", 0.55, 0, 0 }, { "FacePlate", "F4F7FA", 0.4, 0, 0 } },
	Snailbyte = { { "Body", "9FD9A6", 0.55, 0, 0 }, { "dishR", "C9803E", 0.55, 0, 0 }, { "feelerL", "9FD9A6", 0.55, 0, 0 }, { "feelerR", "9FD9A6", 0.55, 0, 0 }, { "FacePlate", "9FD9A6", 0.4, 0, 0 } },
	SnowBush = { { "Body", "2F6B5E", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Glow", "9FE8FF", 0.55, 0, 1.5 } },
	SnowDrift = { { "Body", "F2F6FA", 0.55, 0, 0 }, { "Glow", "FFFFFF", 0.55, 0, 1.5 } },
	SnowPine = { { "Body", "2F6B5E", 0.55, 0, 0 }, { "BodyDark", "4A3A2E", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 }, { "Glow", "BFF3FF", 0.55, 0, 1.5 } },
	SnowPineB = { { "Body", "2A5F54", 0.55, 0, 0 }, { "BodyDark", "4A3A2E", 0.55, 0, 0 }, { "Accessory", "F2F6FA", 0.55, 0, 0 }, { "Trim", "BFEBFA", 0.55, 0, 0 } },
	Snowbun = { { "Body", "B4A9E6", 0.55, 0, 0 }, { "earL", "B4A9E6", 0.55, 0, 0 }, { "earR", "B4A9E6", 0.55, 0, 0 }, { "nose", "F0407F", 0.55, 0, 0 }, { "tail", "CFE2F3", 0.55, 0, 0 }, { "FacePlate", "B4A9E6", 0.4, 0, 0 } },
	SparkStation = { { "Body", "A855F7", 0.55, 0, 0 }, { "BodyDark", "3F9B3A", 0.55, 0, 0 }, { "Accessory", "5DBB3A", 0.55, 0, 0 }, { "Glow", "FFC83D", 0.55, 0, 1.5 } },
	Sparkfox = { { "Body", "FF7A30", 0.55, 0, 0 }, { "earL", "FF7A30", 0.55, 0, 0 }, { "earR", "FF7A30", 0.55, 0, 0 }, { "floatR", "FFA53D", 0.55, 0, 1.5 }, { "paletteL", "4A2433", 0.55, 0, 0 }, { "tailR", "FF7A30", 0.55, 0, 0 }, { "FacePlate", "FF7A30", 0.4, 0, 0 } },
	Spookum = { { "Body", "E9E6FF", 0.55, 0, 0 }, { "Glow", "9D6BFF", 0.55, 0, 1.5 }, { "armL", "E9E6FF", 0.55, 0, 0 }, { "armR", "E9E6FF", 0.55, 0, 0 }, { "candles", "FF9F1C", 0.55, 0, 0 }, { "hem", "5B4A8A", 0.55, 0, 0 }, { "lanternL", "9D6BFF", 0.55, 0, 1.5 }, { "stem", "B89B5A", 0.55, 0, 0 }, { "wisp", "9D6BFF", 0.55, 0, 1.5 }, { "FacePlate", "E9E6FF", 0.4, 0, 0 } },
	StarIsland = { { "Body", "2E7F76", 0.55, 0, 0 }, { "BodyDark", "4C4894", 0.55, 0, 0 }, { "Accessory", "7FD2FF", 0.55, 0, 0 }, { "Trim", "CDC3F2", 0.55, 0, 0 }, { "Glow", "EEF6FF", 0.55, 0, 1.5 } },
	SteppingStone = { { "Body", "8E88C6", 0.55, 0, 0 }, { "Accessory", "2E8A78", 0.55, 0, 0 } },
	Thunderhog = { { "Body", "8B5CF6", 0.55, 0, 0 }, { "antennaL", "FFF27A", 0.55, 0, 1.5 }, { "antennaR", "FFF27A", 0.55, 0, 1.5 }, { "charge", "FFF27A", 0.55, 0, 1.5 }, { "cloudR", "D4C6FF", 0.55, 0, 0 }, { "crest", "FFC233", 0.55, 0, 0 }, { "sparkR", "FFF27A", 0.55, 0, 1.5 }, { "tail", "2E1F66", 0.55, 0, 0 }, { "FacePlate", "8B5CF6", 0.4, 0, 0 } },
	Toastoad = { { "Body", "E8713A", 0.55, 0, 0 }, { "belly", "FFC94D", 0.55, 0, 0 }, { "bumpL", "E8713A", 0.55, 0, 0 }, { "bumpR", "E8713A", 0.55, 0, 0 }, { "pebbleR", "6E4A3C", 0.55, 0, 0 }, { "stoneL", "6E4A3C", 0.55, 0, 0 }, { "FacePlate", "E8713A", 0.4, 0, 0 } },
	Twiglet = { { "Body", "9C6B3F", 0.55, 0, 0 }, { "antenna", "4A2E1A", 0.55, 0, 0 }, { "hat", "7FC94A", 0.55, 0, 0 }, { "twig", "9C6B3F", 0.55, 0, 0 }, { "FacePlate", "9C6B3F", 0.4, 0, 0 } },
	Wisplet = { { "Body", "8FDCFF", 0.55, 0, 0 }, { "floatL", "8FDCFF", 0.55, 0, 0 }, { "floatR", "8FDCFF", 0.55, 0, 0 }, { "glass", "9466FF", 0.55, 0, 0 }, { "halo", "6E6A85", 0.55, 0, 0 }, { "tipR", "9466FF", 0.55, 0, 1.5 }, { "tongueL", "8FDCFF", 0.55, 0, 0 }, { "FacePlate", "8FDCFF", 0.4, 0, 0 } },
	Zapfinch = { { "Body", "4FA8E8", 0.55, 0, 0 }, { "arc", "FFEE55", 0.55, 0, 1.5 }, { "crestL", "FFEE55", 0.55, 0, 1.5 }, { "crestR", "FFEE55", 0.55, 0, 1.5 }, { "tail", "23386B", 0.55, 0, 0 }, { "wingL", "FFEE55", 0.55, 0, 1.5 }, { "wingR", "FFEE55", 0.55, 0, 1.5 }, { "FacePlate", "4FA8E8", 0.4, 0, 0 } },
}
-- END PASTE

-- One part of a block-cell model: its name (the GLB node), its colour, Neon or not, and the map it samples ("cell", "face" or "").
type BlockCellPart = { name: string, hex: string, neon: boolean, map: string }
-- assetId: the new Model upload (0 until uploaded); cellMap, faceMap: the Image ids of <Id>_atlas.png and <Id>_face.png (0 until uploaded).
type BlockCellRow = { assetId: number, cellMap: number, faceMap: number, parts: { BlockCellPart } }
-- BEGIN BLOCK-CELL PASTE: output of `python3 -I tools/blocky/export_models.py --emit-luau`
local BLOCK_CELL: { [string]: BlockCellRow } = {
	Buzzlebee = {
		assetId = 90983073121915, cellMap = 128693248108922, faceMap = 137311837248040,
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
		assetId = 107898420617031, cellMap = 101294572473565, faceMap = 82136169363124,
		parts = {
			{ name = "Body", hex = "E0C3A0", neon = false, map = "cell" },
			{ name = "earL", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "earR", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "floatR", hex = "5FDCFF", neon = true, map = "" },
			{ name = "leafR", hex = "5C4A2A", neon = false, map = "cell" },
			{ name = "ring", hex = "5FDCFF", neon = true, map = "" },
			{ name = "FacePlate", hex = "E0C3A0", neon = false, map = "face" },
		},
	},
	Chipmole = {
		assetId = 99728350452516, cellMap = 77446403761312, faceMap = 95913860129053,
		parts = {
			{ name = "Body", hex = "5B6B85", neon = false, map = "cell" },
			{ name = "pickL", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "pickR", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "tailR", hex = "3FD3F7", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "5B6B85", neon = false, map = "face" },
		},
	},
	Drippo = {
		assetId = 85644366482246, cellMap = 91255509702154, faceMap = 101118448833680,
		parts = {
			{ name = "Body", hex = "A9D6F5", neon = false, map = "cell" },
			{ name = "armR", hex = "2F5F9F", neon = false, map = "cell" },
			{ name = "beadL", hex = "0FB4E0", neon = false, map = "cell" },
			{ name = "dripL", hex = "0FB4E0", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "A9D6F5", neon = false, map = "face" },
		},
	},
	Emberchin = {
		assetId = 121001466165205, cellMap = 81940390116779, faceMap = 130015865753912,
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
		assetId = 75070069889969, cellMap = 88604149153432, faceMap = 73195796678331,
		parts = {
			{ name = "Body", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "Glow", hex = "AEB8FF", neon = true, map = "" },
			{ name = "chain", hex = "D9E2F5", neon = false, map = "cell" },
			{ name = "earL", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "earR", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "halo", hex = "D9E2F5", neon = false, map = "cell" },
			{ name = "mane", hex = "1E1A47", neon = false, map = "cell" },
			{ name = "moon", hex = "AEB8FF", neon = true, map = "" },
			{ name = "moteL", hex = "AEB8FF", neon = true, map = "" },
			{ name = "moteR", hex = "AEB8FF", neon = true, map = "" },
			{ name = "shade", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "stars", hex = "AEB8FF", neon = true, map = "" },
			{ name = "tail", hex = "4B3D8F", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4B3D8F", neon = false, map = "face" },
		},
	},
	Flapsicle = {
		assetId = 101851912195987, cellMap = 133671891939282, faceMap = 112842277122541,
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
		assetId = 83783025796871, cellMap = 132824877532578, faceMap = 136415585203846,
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
		assetId = 106945588536399, cellMap = 122483013101607, faceMap = 78193673813294,
		parts = {
			{ name = "Body", hex = "4F9BD8", neon = false, map = "cell" },
			{ name = "Glow", hex = "2ED3F7", neon = true, map = "" },
			{ name = "crown", hex = "2ED3F7", neon = true, map = "" },
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
		assetId = 98176134122001, cellMap = 127928382075210, faceMap = 132302858833968,
		parts = {
			{ name = "Body", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "Glow", hex = "F0287E", neon = true, map = "" },
			{ name = "antlerL", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "antlerR", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "butterflyR", hex = "F0287E", neon = true, map = "" },
			{ name = "butterfly2L", hex = "F0287E", neon = true, map = "" },
			{ name = "cape", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "earL", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "earR", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "halo", hex = "4FB84E", neon = false, map = "cell" },
			{ name = "tail", hex = "F0E6CE", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F0E6CE", neon = false, map = "face" },
		},
	},
	Glimmo = {
		assetId = 86858457841953, cellMap = 74579049135613, faceMap = 90393874594798,
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
		assetId = 118890551905521, cellMap = 116034763012203, faceMap = 72706783678772,
		parts = {
			{ name = "Body", hex = "8C6FB5", neon = false, map = "cell" },
			{ name = "antennaL", hex = "B832E8", neon = true, map = "" },
			{ name = "antennaR", hex = "B832E8", neon = true, map = "" },
			{ name = "hindwingL", hex = "B832E8", neon = true, map = "" },
			{ name = "hindwingR", hex = "B832E8", neon = true, map = "" },
			{ name = "shard", hex = "E8C45A", neon = false, map = "cell" },
			{ name = "wingL", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "wingR", hex = "D9C8FF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8C6FB5", neon = false, map = "face" },
		},
	},
	Kettlepuff = {
		assetId = 89382463269455, cellMap = 110248563118243, faceMap = 129085282846385,
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
		assetId = 115058641916832, cellMap = 128733646857953, faceMap = 136408703590879,
		parts = {
			{ name = "Body", hex = "F26B3A", neon = false, map = "cell" },
			{ name = "gillL", hex = "4A2638", neon = false, map = "cell" },
			{ name = "gillR", hex = "4A2638", neon = false, map = "cell" },
			{ name = "tail", hex = "F26B3A", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F26B3A", neon = false, map = "face" },
		},
	},
	Mossbop = {
		assetId = 76286989342632, cellMap = 87836738289077, faceMap = 89438306939577,
		parts = {
			{ name = "Body", hex = "6CCB5F", neon = false, map = "cell" },
			{ name = "floatR", hex = "D9F36B", neon = false, map = "cell" },
			{ name = "sprout", hex = "D9F36B", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "6CCB5F", neon = false, map = "face" },
		},
	},
	Nebulyn = {
		assetId = 112291898528534, cellMap = 124863958086054, faceMap = 78605573120182,
		parts = {
			{ name = "Body", hex = "6B4EC2", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFF3B0", neon = true, map = "" },
			{ name = "comet", hex = "FFF3B0", neon = true, map = "" },
			{ name = "fallenR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "planetL", hex = "E66BD2", neon = false, map = "cell" },
			{ name = "puff", hex = "6B4EC2", neon = false, map = "cell" },
			{ name = "starL", hex = "FFF3B0", neon = true, map = "" },
			{ name = "starR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "tailR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "twinkleR", hex = "FFF3B0", neon = true, map = "" },
			{ name = "twinkle2R", hex = "FFF3B0", neon = true, map = "" },
			{ name = "FacePlate", hex = "6B4EC2", neon = false, map = "face" },
		},
	},
	Panpipe = {
		assetId = 93548551011238, cellMap = 132372087186562, faceMap = 95813780358437,
		parts = {
			{ name = "Body", hex = "4A4166", neon = false, map = "cell" },
			{ name = "Glow", hex = "9B5CFF", neon = true, map = "" },
			{ name = "beard", hex = "1E1A2E", neon = false, map = "cell" },
			{ name = "bellR", hex = "8C86A6", neon = false, map = "cell" },
			{ name = "earL", hex = "4A4166", neon = false, map = "cell" },
			{ name = "earR", hex = "4A4166", neon = false, map = "cell" },
			{ name = "echoR", hex = "9B5CFF", neon = true, map = "" },
			{ name = "eclipse", hex = "9B5CFF", neon = true, map = "" },
			{ name = "gem", hex = "9B5CFF", neon = true, map = "" },
			{ name = "noteL", hex = "9B5CFF", neon = true, map = "" },
			{ name = "note2R", hex = "9B5CFF", neon = true, map = "" },
			{ name = "pipesR", hex = "9B5CFF", neon = true, map = "" },
			{ name = "tail", hex = "1E1A2E", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "4A4166", neon = false, map = "face" },
		},
	},
	Pebblet = {
		assetId = 120711912140485, cellMap = 110562673033118, faceMap = 74579668010165,
		parts = {
			{ name = "Body", hex = "C4B9A6", neon = false, map = "cell" },
			{ name = "cairnR", hex = "5A5048", neon = false, map = "cell" },
			{ name = "legL", hex = "5A5048", neon = false, map = "cell" },
			{ name = "legR", hex = "5A5048", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C4B9A6", neon = false, map = "face" },
		},
	},
	Pengoo = {
		assetId = 75587289427504, cellMap = 75649084888199, faceMap = 106375707270260,
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
		assetId = 128760821641478, cellMap = 73394681523898, faceMap = 94739602351822,
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
		assetId = 118232011556551, cellMap = 111532604962185, faceMap = 131372874937049,
		parts = {
			{ name = "Body", hex = "D7265C", neon = false, map = "cell" },
			{ name = "frondL", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "frondR", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "gem", hex = "FFC21A", neon = true, map = "" },
			{ name = "halo", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "leaf", hex = "2CC5B2", neon = false, map = "cell" },
			{ name = "moteL", hex = "FFC21A", neon = true, map = "" },
			{ name = "moteR", hex = "FFC21A", neon = true, map = "" },
			{ name = "orb", hex = "FFC21A", neon = true, map = "" },
			{ name = "pendant", hex = "FFC21A", neon = true, map = "" },
			{ name = "sunstone", hex = "FFC21A", neon = true, map = "" },
			{ name = "wingL", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "wingR", hex = "FFB21E", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "D7265C", neon = false, map = "face" },
		},
	},
	Reindazzle = {
		assetId = 81819705890422, cellMap = 106765933193978, faceMap = 111147116820289,
		parts = {
			{ name = "Body", hex = "A8805A", neon = false, map = "cell" },
			{ name = "chimeL", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "chimeR", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "earL", hex = "A8805A", neon = false, map = "cell" },
			{ name = "earR", hex = "A8805A", neon = false, map = "cell" },
			{ name = "nose", hex = "E0202C", neon = true, map = "" },
			{ name = "tail", hex = "A8E4FF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "A8805A", neon = false, map = "face" },
		},
	},
	Rocklobber = {
		assetId = 91046356996222, cellMap = 100652787863233, faceMap = 91599993746426,
		parts = {
			{ name = "Body", hex = "C8553D", neon = false, map = "cell" },
			{ name = "antennaR", hex = "A39E94", neon = false, map = "cell" },
			{ name = "clawL", hex = "A39E94", neon = false, map = "cell" },
			{ name = "clawR", hex = "A39E94", neon = false, map = "cell" },
			{ name = "geodeL", hex = "FF8C1A", neon = true, map = "" },
			{ name = "legL", hex = "3A3238", neon = false, map = "cell" },
			{ name = "legR", hex = "3A3238", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C8553D", neon = false, map = "face" },
		},
	},
	Shellberg = {
		assetId = 98400901055778, cellMap = 103486202857780, faceMap = 106242584652958,
		parts = {
			{ name = "Body", hex = "3FBFB0", neon = false, map = "cell" },
			{ name = "Glow", hex = "2ED3F7", neon = true, map = "" },
			{ name = "dripL", hex = "8CC8F0", neon = false, map = "cell" },
			{ name = "flagL", hex = "2ED3F7", neon = true, map = "" },
			{ name = "footL", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "footR", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "shardsR", hex = "2ED3F7", neon = true, map = "" },
			{ name = "tail", hex = "1F6F68", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "3FBFB0", neon = false, map = "face" },
		},
	},
	Shimmerlynx = {
		assetId = 97482261000062, cellMap = 100995364175378, faceMap = 138781625479543,
		parts = {
			{ name = "Body", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "crest", hex = "9D7CFF", neon = true, map = "" },
			{ name = "earL", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "earR", hex = "C8C2F0", neon = false, map = "cell" },
			{ name = "mote", hex = "9D7CFF", neon = true, map = "" },
			{ name = "pendant", hex = "8FA6C4", neon = false, map = "cell" },
			{ name = "tailR", hex = "9D7CFF", neon = true, map = "" },
			{ name = "whiskerL", hex = "4B4470", neon = false, map = "cell" },
			{ name = "whiskerR", hex = "4B4470", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "C8C2F0", neon = false, map = "face" },
		},
	},
	Skaddle = {
		assetId = 138821009662968, cellMap = 89516848138318, faceMap = 116741755641603,
		parts = {
			{ name = "Body", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "4A55E8", neon = true, map = "" },
			{ name = "crest", hex = "4A55E8", neon = true, map = "" },
			{ name = "halo", hex = "4A55E8", neon = true, map = "" },
			{ name = "hindwingL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "hindwingR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "quiverL", hex = "5C708A", neon = false, map = "cell" },
			{ name = "scarfR", hex = "8FD3F4", neon = false, map = "cell" },
			{ name = "tuftL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "tuftR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "wingL", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "wingR", hex = "F4F7FA", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "F4F7FA", neon = false, map = "face" },
		},
	},
	Snailbyte = {
		assetId = 127624587145029, cellMap = 133509775708088, faceMap = 81584769439486,
		parts = {
			{ name = "Body", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "dishR", hex = "C9803E", neon = false, map = "cell" },
			{ name = "feelerL", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "feelerR", hex = "9FD9A6", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "9FD9A6", neon = false, map = "face" },
		},
	},
	Snowbun = {
		assetId = 112987344531192, cellMap = 116823320284144, faceMap = 88833999114939,
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
		assetId = 129902686231899, cellMap = 92155920456472, faceMap = 86129235005522,
		parts = {
			{ name = "Body", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "earL", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "earR", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "floatR", hex = "FFA53D", neon = true, map = "" },
			{ name = "paletteL", hex = "4A2433", neon = false, map = "cell" },
			{ name = "tailR", hex = "FF7A30", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "FF7A30", neon = false, map = "face" },
		},
	},
	Spookum = {
		assetId = 107247366211382, cellMap = 102578211007674, faceMap = 106928205674360,
		parts = {
			{ name = "Body", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "Glow", hex = "9D6BFF", neon = true, map = "" },
			{ name = "armL", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "armR", hex = "E9E6FF", neon = false, map = "cell" },
			{ name = "candles", hex = "FF9F1C", neon = false, map = "cell" },
			{ name = "hem", hex = "5B4A8A", neon = false, map = "cell" },
			{ name = "lanternL", hex = "9D6BFF", neon = true, map = "" },
			{ name = "stem", hex = "B89B5A", neon = false, map = "cell" },
			{ name = "wisp", hex = "9D6BFF", neon = true, map = "" },
			{ name = "FacePlate", hex = "E9E6FF", neon = false, map = "face" },
		},
	},
	Thunderhog = {
		assetId = 138702894272903, cellMap = 79789189923150, faceMap = 80992519326881,
		parts = {
			{ name = "Body", hex = "8B5CF6", neon = false, map = "cell" },
			{ name = "antennaL", hex = "FFF27A", neon = true, map = "" },
			{ name = "antennaR", hex = "FFF27A", neon = true, map = "" },
			{ name = "charge", hex = "FFF27A", neon = true, map = "" },
			{ name = "cloudR", hex = "D4C6FF", neon = false, map = "cell" },
			{ name = "crest", hex = "FFC233", neon = false, map = "cell" },
			{ name = "sparkR", hex = "FFF27A", neon = true, map = "" },
			{ name = "tail", hex = "2E1F66", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8B5CF6", neon = false, map = "face" },
		},
	},
	Toastoad = {
		assetId = 76456734696236, cellMap = 75160205052760, faceMap = 132068667511975,
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
		assetId = 137645911740591, cellMap = 81835984508717, faceMap = 125849274342039,
		parts = {
			{ name = "Body", hex = "9C6B3F", neon = false, map = "cell" },
			{ name = "antenna", hex = "4A2E1A", neon = false, map = "cell" },
			{ name = "hat", hex = "7FC94A", neon = false, map = "cell" },
			{ name = "twig", hex = "9C6B3F", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "9C6B3F", neon = false, map = "face" },
		},
	},
	Wisplet = {
		assetId = 110004797552628, cellMap = 86748887022809, faceMap = 123249151171223,
		parts = {
			{ name = "Body", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "floatL", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "floatR", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "glass", hex = "9466FF", neon = false, map = "cell" },
			{ name = "halo", hex = "6E6A85", neon = false, map = "cell" },
			{ name = "tipR", hex = "9466FF", neon = true, map = "" },
			{ name = "tongueL", hex = "8FDCFF", neon = false, map = "cell" },
			{ name = "FacePlate", hex = "8FDCFF", neon = false, map = "face" },
		},
	},
	Zapfinch = {
		assetId = 102395774185067, cellMap = 120674569637136, faceMap = 140081956415430,
		parts = {
			{ name = "Body", hex = "4FA8E8", neon = false, map = "cell" },
			{ name = "arc", hex = "FFEE55", neon = true, map = "" },
			{ name = "crestL", hex = "FFEE55", neon = true, map = "" },
			{ name = "crestR", hex = "FFEE55", neon = true, map = "" },
			{ name = "tail", hex = "23386B", neon = false, map = "cell" },
			{ name = "wingL", hex = "FFEE55", neon = true, map = "" },
			{ name = "wingR", hex = "FFEE55", neon = true, map = "" },
			{ name = "FacePlate", hex = "4FA8E8", neon = false, map = "face" },
		},
	},
}
-- END BLOCK-CELL PASTE
-- BEGIN BLOCK-CELL PROPS PASTE: output of `python3 -I tools/blocky/export_models.py --emit-luau --props`
local BLOCK_CELL_PROPS: { [string]: BlockCellRow } = {
	ArchBridge = {
		assetId = 100866168947335, cellMap = 92291236496429, faceMap = 0,
		parts = {
			{ name = "Body", hex = "B07A56", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6A4636", neon = false, map = "cell" },
			{ name = "Accessory", hex = "3C3564", neon = false, map = "cell" },
			{ name = "Trim", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFE7B0", neon = true, map = "" },
		},
	},
	Bench = {
		assetId = 129578936462861, cellMap = 73333503463121, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C08A55", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "8FD9B6", neon = false, map = "cell" },
			{ name = "Trim", hex = "9E9E8E", neon = false, map = "cell" },
		},
	},
	BlossomTree = {
		assetId = 86047383661807, cellMap = 93083394033124, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FF9EC4", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6B3F2A", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFE3EE", neon = false, map = "cell" },
		},
	},
	Boulder = {
		assetId = 116759392207271, cellMap = 72053344137984, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7C7C6E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "6CB04A", neon = false, map = "cell" },
			{ name = "Trim", hex = "F2E6D0", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB86B", neon = true, map = "" },
		},
	},
	BuildStation = {
		assetId = 102869559733997, cellMap = 105652272873652, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C99A5B", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "8B5A2B", neon = false, map = "cell" },
			{ name = "Accessory", hex = "8FD3FF", neon = false, map = "cell" },
			{ name = "Trim", hex = "8A93A0", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	Bush = {
		assetId = 131412714992852, cellMap = 118137568752478, faceMap = 0,
		parts = {
			{ name = "Body", hex = "57B04A", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FF5C8A", neon = false, map = "cell" },
		},
	},
	CampCrate = {
		assetId = 70497878511393, cellMap = 71193549662506, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C08A55", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "8C5E32", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "68C9FE", neon = false, map = "cell" },
		},
	},
	CampFlag = {
		assetId = 95659454055737, cellMap = 91648705460230, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6E7690", neon = false, map = "cell" },
			{ name = "Accessory", hex = "68C9FE", neon = false, map = "cell" },
			{ name = "Trim", hex = "8E8E86", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFE36B", neon = true, map = "" },
		},
	},
	Campfire = {
		assetId = 122461350675998, cellMap = 95366736176150, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FF8A2A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Trim", hex = "8E8E86", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFD34D", neon = true, map = "" },
		},
	},
	CaveMouth = {
		assetId = 132103896359941, cellMap = 103210189633036, faceMap = 0,
		parts = {
			{ name = "Body", hex = "7A756E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "15120F", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "C084FC", neon = false, map = "cell" },
			{ name = "Glow", hex = "7FE3FF", neon = true, map = "" },
		},
	},
	CrashWreck = {
		assetId = 74817192673896, cellMap = 98121367730346, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A4AEBC", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "463A31", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "8FE3F5", neon = false, map = "cell" },
			{ name = "Glow", hex = "FF8A3D", neon = true, map = "" },
		},
	},
	Fence = {
		assetId = 102938140774553, cellMap = 100529419895370, faceMap = 0,
		parts = {
			{ name = "Body", hex = "B98552", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "8A5A35", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "FF8FB0", neon = false, map = "cell" },
		},
	},
	Flag = {
		assetId = 90062331463442, cellMap = 105747140609714, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FF8AD8", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6E7690", neon = false, map = "cell" },
			{ name = "Accessory", hex = "6BCB3F", neon = false, map = "cell" },
			{ name = "Trim", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFEF4A", neon = true, map = "" },
		},
	},
	FlowerPatch = {
		assetId = 135752098587893, cellMap = 128522852451313, faceMap = 0,
		parts = {
			{ name = "Body", hex = "FF8FB0", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3F8F2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFD34D", neon = false, map = "cell" },
			{ name = "Trim", hex = "F7F3EA", neon = false, map = "cell" },
		},
	},
	Fountain = {
		assetId = 83951227918407, cellMap = 127620707908497, faceMap = 0,
		parts = {
			{ name = "Body", hex = "CFC8B6", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "948C7A", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "3FA2E6", neon = false, map = "cell" },
			{ name = "Glow", hex = "BFF3FF", neon = true, map = "" },
		},
	},
	FrozenLog = {
		assetId = 85556402993990, cellMap = 129322880755846, faceMap = 0,
		parts = {
			{ name = "BodyDark", hex = "4A3A2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
		},
	},
	GatherStation = {
		assetId = 109164418132495, cellMap = 70946105999617, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C99A5B", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "8B5A2B", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "E8483D", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFD98A", neon = true, map = "" },
		},
	},
	GeyserCone = {
		assetId = 105425785899723, cellMap = 138392313694177, faceMap = 0,
		parts = {
			{ name = "Body", hex = "8C5A3C", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A2E1E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "D9A066", neon = false, map = "cell" },
			{ name = "Glow", hex = "BFF3FF", neon = true, map = "" },
		},
	},
	GeyserVent = {
		assetId = 112138566520848, cellMap = 88441990498177, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6B4A36", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "2A1A12", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2FBFF", neon = false, map = "cell" },
			{ name = "Trim", hex = "D98A4E", neon = false, map = "cell" },
			{ name = "Glow", hex = "9FE8FF", neon = true, map = "" },
		},
	},
	GlowFern = {
		assetId = 125072432310618, cellMap = 105256630455078, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2F9A8A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "1F6670", neon = false, map = "cell" },
			{ name = "Glow", hex = "A6E8FF", neon = true, map = "" },
		},
	},
	GlowcapGiant = {
		assetId = 117920330924486, cellMap = 134277612201137, faceMap = 0,
		parts = {
			{ name = "Body", hex = "ECE6FF", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "D6CCEE", neon = false, map = "cell" },
			{ name = "Accessory", hex = "9C8FD0", neon = false, map = "cell" },
			{ name = "Trim", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Glow", hex = "EEF6FF", neon = true, map = "" },
		},
	},
	GlowcapGiantBlue = {
		assetId = 89013956645212, cellMap = 130292944840007, faceMap = 0,
		parts = {
			{ name = "Body", hex = "86C8F5", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "DCD6F2", neon = false, map = "cell" },
			{ name = "Accessory", hex = "4A78C0", neon = false, map = "cell" },
			{ name = "Trim", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Glow", hex = "A6E8FF", neon = true, map = "" },
		},
	},
	GlowcapGiantPink = {
		assetId = 113989154132526, cellMap = 124063371417008, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F49AD8", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "E4DAF4", neon = false, map = "cell" },
			{ name = "Accessory", hex = "B85CA6", neon = false, map = "cell" },
			{ name = "Trim", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB3E6", neon = true, map = "" },
		},
	},
	GlowcapSmall = {
		assetId = 94355790262720, cellMap = 127192553837506, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F5A6DC", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "E6DEF6", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFF4FB", neon = false, map = "cell" },
			{ name = "Trim", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Glow", hex = "D2B0FF", neon = true, map = "" },
		},
	},
	GrottoCrystal = {
		assetId = 135279166472081, cellMap = 74073549986650, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A8F0FA", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6E6A78", neon = false, map = "cell" },
			{ name = "Accessory", hex = "B49CFF", neon = false, map = "cell" },
			{ name = "Trim", hex = "6CB04A", neon = false, map = "cell" },
			{ name = "Glow", hex = "7FE3F0", neon = true, map = "" },
		},
	},
	HabitatFrostbyte = {
		assetId = 89002985688787, cellMap = 71741076207941, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A3A2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2F6B5E", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "Glow", hex = "7FE3F0", neon = true, map = "" },
		},
	},
	HabitatVerdant = {
		assetId = 115551193652891, cellMap = 137002355021451, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6FBF4A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F49AD8", neon = false, map = "cell" },
			{ name = "Trim", hex = "3FA2E6", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	HeaterLamp = {
		assetId = 90164225940384, cellMap = 121628048975357, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6B7580", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3D4556", neon = false, map = "cell" },
			{ name = "Trim", hex = "C9CFD8", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB347", neon = true, map = "" },
		},
	},
	IceCaveMouth = {
		assetId = 73067765487784, cellMap = 136744248674581, faceMap = 0,
		parts = {
			{ name = "Body", hex = "CFEAF7", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "0E1A26", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F7FBFF", neon = false, map = "cell" },
			{ name = "Trim", hex = "6EC6F0", neon = false, map = "cell" },
			{ name = "Glow", hex = "68C9FE", neon = true, map = "" },
		},
	},
	IceCrystalCluster = {
		assetId = 121312349675975, cellMap = 137889921014335, faceMap = 0,
		parts = {
			{ name = "Body", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7F8E99", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "68C9FE", neon = true, map = "" },
		},
	},
	IceLantern = {
		assetId = 121933457814748, cellMap = 82678382422171, faceMap = 0,
		parts = {
			{ name = "Body", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7F8E99", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB347", neon = true, map = "" },
		},
	},
	IceRock = {
		assetId = 76857079544887, cellMap = 104286189059218, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A9B7C0", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "Glow", hex = "BFF3FF", neon = true, map = "" },
		},
	},
	IceRockB = {
		assetId = 134221683669516, cellMap = 109033647305129, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A9B7C0", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "Glow", hex = "BFF3FF", neon = true, map = "" },
		},
	},
	IceSignArmHigh = {
		assetId = 110560294652685, cellMap = 106459290073453, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D4B483", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5CE0B8", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	IceSignArmLow = {
		assetId = 84897250093660, cellMap = 134033316780958, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D4B483", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Accessory", hex = "B49CFF", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	IceSignArmMid = {
		assetId = 123109088414678, cellMap = 136256810815922, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D4B483", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Accessory", hex = "68C9FE", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	IceSpire = {
		assetId = 87856482527354, cellMap = 128219618708031, faceMap = 0,
		parts = {
			{ name = "Body", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7F8E99", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "7FE6FF", neon = true, map = "" },
		},
	},
	Icicles = {
		assetId = 116751160175551, cellMap = 138188218433850, faceMap = 0,
		parts = {
			{ name = "Body", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "9FE3FF", neon = false, map = "cell" },
			{ name = "Glow", hex = "E8FAFF", neon = true, map = "" },
		},
	},
	Lantern = {
		assetId = 113167192482454, cellMap = 119443664234115, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4A3B2E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "C9A15B", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	LilyPad = {
		assetId = 122673551171714, cellMap = 86636055274635, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4FAF4A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3F8F2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFB3CC", neon = false, map = "cell" },
			{ name = "Trim", hex = "FFD34D", neon = false, map = "cell" },
		},
	},
	Log = {
		assetId = 131627870594501, cellMap = 90001432855848, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6CB04A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "E8843D", neon = false, map = "cell" },
			{ name = "Trim", hex = "F2E6D0", neon = false, map = "cell" },
		},
	},
	MeadowRock = {
		assetId = 88678220176697, cellMap = 130100122998009, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7C7C6E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "6CB04A", neon = false, map = "cell" },
		},
	},
	MeadowRockB = {
		assetId = 132263048949650, cellMap = 131797695559288, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7C7C6E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "F7F3EA", neon = false, map = "cell" },
		},
	},
	MeadowTree = {
		assetId = 121178738911533, cellMap = 103656832373289, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4CAF46", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFD34D", neon = false, map = "cell" },
		},
	},
	MeadowTreeB = {
		assetId = 93870949713381, cellMap = 130450492060616, faceMap = 0,
		parts = {
			{ name = "Body", hex = "3F9B3A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6B3F26", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFF3F7", neon = false, map = "cell" },
		},
	},
	MoonPoolRing = {
		assetId = 112182609320789, cellMap = 113793427500436, faceMap = 0,
		parts = {
			{ name = "Body", hex = "6E69AE", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2E8A78", neon = false, map = "cell" },
			{ name = "Trim", hex = "3BA88A", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB3E6", neon = true, map = "" },
		},
	},
	MoonTree = {
		assetId = 132229763849776, cellMap = 77458391923166, faceMap = 0,
		parts = {
			{ name = "Body", hex = "4752C4", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3F2878", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2A8A94", neon = false, map = "cell" },
			{ name = "Trim", hex = "CDC3F2", neon = false, map = "cell" },
			{ name = "Glow", hex = "1B9C94", neon = true, map = "" },
		},
	},
	MoonTreeB = {
		assetId = 135628295699646, cellMap = 105991136000875, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2A8A94", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A2F86", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5560D0", neon = false, map = "cell" },
			{ name = "Trim", hex = "D2B0FF", neon = false, map = "cell" },
			{ name = "Glow", hex = "9B3FD0", neon = true, map = "" },
		},
	},
	MossStone = {
		assetId = 72806329723798, cellMap = 126956910798760, faceMap = 0,
		parts = {
			{ name = "Body", hex = "5D5BA0", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2E8A70", neon = false, map = "cell" },
			{ name = "Glow", hex = "D2B0FF", neon = true, map = "" },
		},
	},
	Mushroom = {
		assetId = 72020219398485, cellMap = 114561735024346, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E8483D", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "F2E6D0", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFF8EE", neon = false, map = "cell" },
			{ name = "Trim", hex = "5E9E3A", neon = false, map = "cell" },
		},
	},
	PathLantern = {
		assetId = 130101963365955, cellMap = 136263522515792, faceMap = 0,
		parts = {
			{ name = "Body", hex = "3A3562", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "272340", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2C7F72", neon = false, map = "cell" },
			{ name = "Trim", hex = "A891E6", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFB84D", neon = true, map = "" },
		},
	},
	Pedestal = {
		assetId = 98463678388823, cellMap = 95890387415359, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D8D2BC", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "B9B29A", neon = false, map = "cell" },
			{ name = "Glow", hex = "9BE7FF", neon = true, map = "" },
		},
	},
	Planter = {
		assetId = 114986346522730, cellMap = 140576542155311, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C08A55", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6B4630", neon = false, map = "cell" },
			{ name = "Accessory", hex = "3F9B3A", neon = false, map = "cell" },
			{ name = "Trim", hex = "FF8AD8", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFEF4A", neon = true, map = "" },
		},
	},
	Reeds = {
		assetId = 122578038240807, cellMap = 83002950635384, faceMap = 0,
		parts = {
			{ name = "Body", hex = "7DB04A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4F7F3A", neon = false, map = "cell" },
			{ name = "Accessory", hex = "7B4A2D", neon = false, map = "cell" },
		},
	},
	RoomCabin = {
		assetId = 105761041582148, cellMap = 119552657880104, faceMap = 0,
		parts = {
			{ name = "Body", hex = "B57A45", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "8E3A30", neon = false, map = "cell" },
			{ name = "Accessory", hex = "A3A096", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A3A24", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	RoomDome = {
		assetId = 117777283592193, cellMap = 114040860855839, faceMap = 0,
		parts = {
			{ name = "Body", hex = "EEF0F7", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "6E7690", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FF9A3D", neon = false, map = "cell" },
			{ name = "Trim", hex = "7FD3F0", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	RoomTower = {
		assetId = 108272738122563, cellMap = 81436483327802, faceMap = 0,
		parts = {
			{ name = "Body", hex = "D3C7AC", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A5BC4", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC86B", neon = true, map = "" },
		},
	},
	ShipHull = {
		assetId = 81470422409500, cellMap = 86597252898165, faceMap = 0,
		parts = {
			{ name = "Body", hex = "7A8494", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3A4049", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "B8C2CF", neon = false, map = "cell" },
			{ name = "Glow", hex = "68C9FE", neon = true, map = "" },
		},
	},
	Shrine = {
		assetId = 76438506078117, cellMap = 138713171520395, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "C8C0A6", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5E9E3A", neon = false, map = "cell" },
			{ name = "Glow", hex = "2ECC71", neon = true, map = "" },
		},
	},
	ShrineStone = {
		assetId = 78669584933977, cellMap = 93389247643309, faceMap = 0,
		parts = {
			{ name = "Body", hex = "9E9E8E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7C7C6E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "6CB04A", neon = false, map = "cell" },
			{ name = "Glow", hex = "9BE7FF", neon = true, map = "" },
		},
	},
	SightPost = {
		assetId = 93919081600426, cellMap = 132801105576507, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A8794A", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Trim", hex = "8E8E86", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFE36B", neon = true, map = "" },
		},
	},
	SignArmHigh = {
		assetId = 137349550790300, cellMap = 117532531498029, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E8D4A8", neon = false, map = "cell" },
			{ name = "Accessory", hex = "CBC2EE", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	SignArmLow = {
		assetId = 129431571109068, cellMap = 127243664653672, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E8D4A8", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFC83D", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	SignArmMid = {
		assetId = 71757621384434, cellMap = 125395846811798, faceMap = 0,
		parts = {
			{ name = "Body", hex = "E8D4A8", neon = false, map = "cell" },
			{ name = "Accessory", hex = "3FA2E6", neon = false, map = "cell" },
			{ name = "Trim", hex = "5A5A66", neon = false, map = "cell" },
		},
	},
	Signpost = {
		assetId = 74047329484786, cellMap = 112413724280332, faceMap = 0,
		parts = {
			{ name = "Body", hex = "C08A55", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "7B4A2D", neon = false, map = "cell" },
			{ name = "Accessory", hex = "FFF4DC", neon = false, map = "cell" },
			{ name = "Trim", hex = "9E9E8E", neon = false, map = "cell" },
		},
	},
	SnowBush = {
		assetId = 121498439469799, cellMap = 92875806554430, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2F6B5E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "9FE8FF", neon = true, map = "" },
		},
	},
	SnowDrift = {
		assetId = 81110116382095, cellMap = 116606671268588, faceMap = 0,
		parts = {
			{ name = "Body", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFFFFF", neon = true, map = "" },
		},
	},
	SnowPine = {
		assetId = 113692517294473, cellMap = 123573179376692, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2F6B5E", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A3A2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
			{ name = "Glow", hex = "BFF3FF", neon = true, map = "" },
		},
	},
	SnowPineB = {
		assetId = 140047894378836, cellMap = 129186643127704, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2A5F54", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4A3A2E", neon = false, map = "cell" },
			{ name = "Accessory", hex = "F2F6FA", neon = false, map = "cell" },
			{ name = "Trim", hex = "BFEBFA", neon = false, map = "cell" },
		},
	},
	SparkStation = {
		assetId = 132831465418886, cellMap = 122269085621329, faceMap = 0,
		parts = {
			{ name = "Body", hex = "A855F7", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "3F9B3A", neon = false, map = "cell" },
			{ name = "Accessory", hex = "5DBB3A", neon = false, map = "cell" },
			{ name = "Glow", hex = "FFC83D", neon = true, map = "" },
		},
	},
	StarIsland = {
		assetId = 94576361220525, cellMap = 110499624197311, faceMap = 0,
		parts = {
			{ name = "Body", hex = "2E7F76", neon = false, map = "cell" },
			{ name = "BodyDark", hex = "4C4894", neon = false, map = "cell" },
			{ name = "Accessory", hex = "7FD2FF", neon = false, map = "cell" },
			{ name = "Trim", hex = "CDC3F2", neon = false, map = "cell" },
			{ name = "Glow", hex = "EEF6FF", neon = true, map = "" },
		},
	},
	SteppingStone = {
		assetId = 129219870310799, cellMap = 81498537110369, faceMap = 0,
		parts = {
			{ name = "Body", hex = "8E88C6", neon = false, map = "cell" },
			{ name = "Accessory", hex = "2E8A78", neon = false, map = "cell" },
		},
	},
}
-- END BLOCK-CELL PROPS PASTE
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
local function fixBlockCell(model: Model, row: BlockCellRow, isProp: boolean): (string, { string })
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
	normalise(model, isProp, true)
	local box, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	return ("%d textured, %d Neon, %d waiting for a texture"):format(textured, neon, waiting), missing
end

-- The part names that mark an already-installed block-cell prop (its colour slots); no retired blockout prop used them.
local PROP_SLOT_PARTS = { "Body", "BodyDark", "Accessory", "Trim" }

-- A block-cell model imported by hand: the selected Model named `name`, else one already installed that has a FacePlate (a species) or a
-- colour-slot part (a prop).
local function importedBlockCell(name: string, models: Folder, isProp: boolean): Model?
	for _, item in Selection:Get() do
		if item:IsA("Model") and item.Name == name then
			return item
		end
	end
	local existing = models:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		if not isProp and findPart(existing, FACE_PART) then
			return existing
		end
		if isProp then
			for _, slot in PROP_SLOT_PARTS do
				if findPart(existing, slot) then
					return existing
				end
			end
		end
	end
	return nil
end

-- Installs one block-cell species into `models` (or, with isProp, one block-cell prop into Models.Props). Returns ("ok" | "fail" | "wait", detail).
local function installBlockCell(name: string, row: BlockCellRow, models: Folder, isProp: boolean): (string, string)
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
		model = importedBlockCell(name, models, isProp)
		if not model then
			return "wait",
				("not uploaded (assetId 0): File > Import 3D assets/models/%s%s/%s.fbx, select the Model, run again"):format(
					if isProp then "props/" else "",
					name,
					name
				)
		end
	end
	local target = model :: Model
	target.Name = name
	local summary, missing = fixBlockCell(target, row, isProp)
	if #missing > 0 then
		warn(("install_models: %s has no part named %s; the import renamed or merged it, so it will not animate or colour"):format(
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
		if not BLOCK_CELL[name] and not BLOCK_CELL_PROPS[name] then -- a block-cell species or prop never loads its old blockout id
			table.insert(names, name)
		end
	end
	table.sort(names)
	local cellNames: { string } = {}
	for name in BLOCK_CELL do
		table.insert(cellNames, name)
	end
	table.sort(cellNames)
	local propNames: { string } = {}
	for name in BLOCK_CELL_PROPS do
		table.insert(propNames, name)
	end
	table.sort(propNames)
	if #names == 0 and #cellNames == 0 and #propNames == 0 then
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
	local function installCells(list: { string }, rows: { [string]: BlockCellRow }, target: Folder, isProp: boolean)
		for _, name in list do
			local status, detail = installBlockCell(name, rows[name], target, isProp)
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
	end
	installCells(cellNames, BLOCK_CELL, models, false)
	installCells(propNames, BLOCK_CELL_PROPS, props, true)
	print(("install_models: %d installed, %d failed, %d block-cell species and props waiting for an import or upload, %d total"):format(
		installed,
		failed,
		waiting,
		#names + #cellNames + #propNames
	))
	if #waitNames > 0 then
		print(("waiting (not uploaded, not imported or selected): %s"):format(table.concat(waitNames, ", ")))
		print("Import one with File > Import 3D (assets/models/<Id>/<Id>.fbx, or assets/models/props/<Name>/<Name>.fbx), select the Model it makes, and run this again.")
	end
	if failed > 0 then
		print("A failure right after upload usually means the asset is still in moderation (up to a few hours); run again later.")
	end
end

main()
