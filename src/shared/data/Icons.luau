--!strict
-- Icon and particle image asset ids (Look plan L5). The PNGs live in assets/icons and assets/particles
-- (rendered by tools/blender/icons.py); tools/upload_assets.py --images uploads them as Decal assets and
-- --emit-icons-luau prints this table body with the ids filled in. These must be the IMAGE ids behind the Decals
-- (an ImageLabel shows nothing for a Decal id): resolved in Studio with InsertService:LoadAsset(decalId).Decal.Texture. An id of 0 means not uploaded yet:
-- Builder.icon returns nil and the UI keeps its text glyph, so the game runs with or without the pack.
-- Keys are the icon file names; Aliases map data ids that differ (Gear "Boots") to their icon key.

local Icons: { [string]: number } = {
	Aliens = 138611523414380,
	Blizzard = 90172285148207,
	BlizzardShard = 106768990615268,
	CaveCrystal = 117451543402867,
	Codex = 103918141306599,
	Common = 82429088370679,
	Cosmic = 113150651913867,
	DoubleShift = 112272811465253,
	Epic = 115860742476361,
	Fog = 78770233674721,
	FrostCore = 138374768434008,
	GeyserPearl = 97695405026389,
	Gifts = 121715877699096,
	Glowroot = 88465465840530,
	Heater = 99740335306413,
	Hoverboard = 127351315476895,
	IcePlate = 125476019444463,
	Legendary = 97541916357816,
	LuckyCharm = 108931192017785,
	Lure1 = 76693782253836,
	Lure2 = 75418084467033,
	Lure3 = 127190110243013,
	Peddler = 93827149183006,
	Quests = 126146649874828,
	Radar1 = 128751989028592,
	Radar2 = 87295793406107,
	Radar3 = 116830707231128,
	Rain = 133431474059967,
	Ranks = 110417877683323,
	Rare = 97253683358738,
	ScannerPulse = 140387204750678,
	Scrap = 86868662569591,
	ScrapMagnet = 98847989905166,
	Secret = 109107399070527,
	Settings = 91327552934982,
	Ship = 96900829787002,
	Shop = 121353948620197,
	Shower = 88028764487473,
	SkaddleCore = 105177737282698,
	Snow = 135434907260107,
	SpeedBoots = 85675100585028,
	SpeedBurst = 110661603197037,
	StarChart = 134164087277813,
	SteadyHands = 133811902398442,
	StormShard = 106557104263302,
	Uncommon = 121826858488417,
	WardenCore = 138873756558960,
	WreckPlate = 121511498021953,
}

local Particles: { [string]: number } = {
	Confetti = 0,
	Ember = 0,
	Flake = 129925381033863,
	Glow = 0,
	Raindrop = 98219801826407,
	Ring = 0,
	Shine = 0,
	Sparkle = 0,
	Star = 0,
	Wisp = 130427934240873,
}

-- data ids whose icon has another key
local Aliases: { [string]: string } = {
	Boots = "SpeedBoots",
}

return { Icons = Icons, Particles = Particles, Aliases = Aliases }
