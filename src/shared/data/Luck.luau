--!strict
-- Luck multiplies every tier share above Common; Common absorbs the difference. Capped at Config.LuckCap.
return {
	Sources = {
		CompanionPerk = { min = 0.10, max = 0.25 },
		LuckyCharm = 0.50,
		NightForNightSpecies = 0.25,
		WeeklyWeather = 1.00,
		MeteorShower = 2.00,
		CodexPagePermanent = 0.05,
		ServerLuck2x = 1.00,
		ServerLuck4x = 3.00,
	},
}
