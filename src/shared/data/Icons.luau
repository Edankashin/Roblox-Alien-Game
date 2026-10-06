--!strict
-- Icon and particle image asset ids (Look plan L5). The PNGs live in assets/icons and assets/particles
-- (rendered by tools/blender/icons.py); tools/upload_assets.py --images uploads them as Decal assets and
-- --emit-icons-luau prints this table body with the ids filled in. An id of 0 means not uploaded yet:
-- Builder.icon returns nil and the UI keeps its text glyph, so the game runs with or without the pack.
-- Keys are the icon file names; Aliases map data ids that differ (Gear "Boots") to their icon key.

local Icons: { [string]: number } = {
	Aliens = 0,
	Blizzard = 0,
	BlizzardShard = 0,
	CaveCrystal = 0,
	Codex = 0,
	Common = 0,
	Cosmic = 0,
	DoubleShift = 0,
	Epic = 0,
	Fog = 0,
	FrostCore = 0,
	GeyserPearl = 0,
	Gifts = 0,
	Glowroot = 0,
	Heater = 0,
	Hoverboard = 0,
	IcePlate = 0,
	Legendary = 0,
	LuckyCharm = 0,
	Lure1 = 0,
	Lure2 = 0,
	Lure3 = 0,
	Peddler = 0,
	Quests = 0,
	Radar1 = 0,
	Radar2 = 0,
	Radar3 = 0,
	Rain = 0,
	Ranks = 0,
	Rare = 0,
	ScannerPulse = 0,
	Scrap = 0,
	ScrapMagnet = 0,
	Secret = 0,
	Settings = 0,
	Ship = 0,
	Shop = 0,
	Shower = 0,
	SkaddleCore = 0,
	Snow = 0,
	SpeedBoots = 0,
	SpeedBurst = 0,
	StarChart = 0,
	SteadyHands = 0,
	StormShard = 0,
	Uncommon = 0,
	WardenCore = 0,
	WreckPlate = 0,
}

local Particles: { [string]: number } = {
	Confetti = 0,
	Ember = 0,
	Flake = 0,
	Glow = 0,
	Raindrop = 0,
	Ring = 0,
	Shine = 0,
	Sparkle = 0,
	Star = 0,
	Wisp = 0,
}

-- data ids whose icon has another key
local Aliases: { [string]: string } = {
	Boots = "SpeedBoots",
}

return { Icons = Icons, Particles = Particles, Aliases = Aliases }
