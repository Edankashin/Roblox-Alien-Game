--!strict
-- Landmark plates (World/LandmarkRenderer). Playtest 1 (2026-11-05, docs/playtests/2026-11-05-tester-1.md): "Shrine of Gar and
-- similar named locations are unclickable and unexplained". Every landmark under Workspace.World.Landmarks wears its name and, near
-- enough, a legend line that says what it is for; a landmark with `opens` offers that screen on the action button from LookDistance
-- (the Shrine opens the Field Notes, whose last step is the horn). Strings are keys in strings/en: LANDMARK_<id> for the name and
-- LANDMARK_LEGEND_<id> for the legend, unless a row names its own; ByWorld overrides a row where a world's landmark has its own
-- story (World 2's shrine is Skadra's, not Gaira's). Every number here, never in code.
export type Entry = {
	legend: string, -- strings key of the legend line
	name: string?, -- strings key of the name when it is not LANDMARK_<id>
	opens: string?, -- the UI/Screens name the action button opens from within LookDistance; nil for a plate alone
}

local ById: { [string]: Entry } = {
	Shrine = { legend = "LANDMARK_LEGEND_Shrine", opens = "Quests" },
	CrashSite = { legend = "LANDMARK_LEGEND_CrashSite" },
	CaveMouth = { legend = "LANDMARK_LEGEND_CaveMouth" },
	GreatVent = { legend = "LANDMARK_LEGEND_GreatVent" },
	IceCaveMouth = { legend = "LANDMARK_LEGEND_IceCaveMouth" },
}

-- Per world: a row here replaces the ById row for that landmark id in that world.
local ByWorld: { [number]: { [string]: Entry } } = {
	[2] = {
		Shrine = { name = "LANDMARK_Shrine_W2", legend = "LANDMARK_LEGEND_Shrine_W2", opens = "Quests" },
	},
}

return {
	ById = ById,
	ByWorld = ByWorld,
	LookDistance = 14, -- studs from the landmark's centre to offer its screen on the action button (the horn's ShrineInteractDistance)
	LegendStuds = 40, -- the legend line shows within this; farther, the name alone (the plate itself within Config.NameplateDistance)
	PollSeconds = 0.25, -- how often each legend judges its distance
	PlateStuds = { width = 10, height = 3 }, -- the billboard in studs: the name on the top part, the legend under it
	NameShare = 0.45, -- the name's share of the plate's height; the legend takes the rest
	LiftStuds = 7, -- the plate stands this far above the landmark's primary part: clear of the shrine's standing stones from every side
}
