--!strict
-- Icon and particle image asset ids (Look plan L5). The PNGs live in assets/icons and assets/particles
-- (rendered by tools/blender/icons.py); tools/upload_assets.py --images uploads them as Decal assets and
-- --emit-icons-luau prints this table body with the ids filled in. An id of 0 means not uploaded yet:
-- Builder.icon returns nil and the UI keeps its text glyph, so the game runs with or without the pack.
-- Keys are the icon file names; Aliases map data ids that differ (Gear "Boots") to their icon key.

local Icons: { [string]: number } = {
	Aliens = 86206605731098,
	Blizzard = 80987708887566,
	BlizzardShard = 103199825733469,
	CaveCrystal = 83639307842762,
	Codex = 71085996990101,
	Common = 82914960786853,
	Cosmic = 106170818678329,
	DoubleShift = 104022853280347,
	Epic = 100002212809338,
	Fog = 123705562394132,
	FrostCore = 76684892334551,
	GeyserPearl = 114755087249284,
	Gifts = 133137886183087,
	Glowroot = 95808152636665,
	Heater = 121173311224496,
	Hoverboard = 120981739885046,
	IcePlate = 85837278079864,
	Legendary = 71636681636923,
	LuckyCharm = 117502628770253,
	Lure1 = 82706617936607,
	Lure2 = 109090919158117,
	Lure3 = 72803073148989,
	Peddler = 72004735984086,
	Quests = 139334842946197,
	Radar1 = 73738961694483,
	Radar2 = 105875385396641,
	Radar3 = 128950577868524,
	Rain = 99390758865387,
	Ranks = 130648629034939,
	Rare = 83604941151969,
	ScannerPulse = 138234243387972,
	Scrap = 121436495447359,
	ScrapMagnet = 96913057195941,
	Secret = 136426745026784,
	Settings = 122376667571779,
	Ship = 134462239656007,
	Shop = 110715054641399,
	Shower = 136247973355847,
	SkaddleCore = 107769810791136,
	Snow = 117951927108940,
	SpeedBoots = 99460384411858,
	SpeedBurst = 99725744016683,
	StarChart = 87750813793176,
	SteadyHands = 137888999287668,
	StormShard = 103136476596973,
	Uncommon = 104804744880068,
	WardenCore = 93921334125796,
	WreckPlate = 84661673055610,
}

local Particles: { [string]: number } = {
	Confetti = 0,
	Ember = 0,
	Flake = 99527899309782,
	Glow = 0,
	Raindrop = 124667363416815,
	Ring = 0,
	Shine = 0,
	Sparkle = 0,
	Star = 0,
	Wisp = 139124372116872,
}

-- data ids whose icon has another key
local Aliases: { [string]: string } = {
	Boots = "SpeedBoots",
}

return { Icons = Icons, Particles = Particles, Aliases = Aliases }
