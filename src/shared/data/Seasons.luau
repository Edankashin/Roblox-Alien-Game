--!strict
-- Seasonal events (docs/GAME_DESIGN.md section 12, "Monthly"): a theme laid over the existing worlds for a dated
-- window. Event aliens are limited (they spawn only in the window and read Vaulted in the Codex the rest of the
-- year), an event overlay rolls on wild spawns in the event's worlds whatever the weather, nights run longer, limited
-- species of past weeks spawn again (the Vault Rotation), and a free quest track pays through the gifts' reward path,
-- its last step the event's rarest alien (a track-only species). The season is a pure function of the clock
-- (Shared/SeasonMath); only the track's progress is saved (profile.seasons). Every number here.
-- Rules for a young audience: the end is on the banner from day one, nothing event-exclusive is sold, event aliens
-- are prestige, never power.

export type Reward = { kind: "scrap" | "lure" | "spin" | "powerUp" | "alien", id: string?, amount: number }
-- catchEvent: a catch of one of the season's event species; catchOverlay: a catch carrying the season's overlay;
-- catchCount: any catch; showerCount: a Meteor Shower that ended while the player was online
export type Objective = { kind: "catchEvent" | "catchOverlay" | "catchCount" | "showerCount", count: number }
export type Quest = { id: string, objective: Objective, rewards: { Reward } }
export type Season = {
	id: string, -- strings SEASON_<id> names it
	startsAt: number, -- unix seconds UTC; the window is [startsAt, endsAt)
	endsAt: number,
	worldIds: { number }, -- the worlds the event species spawn in and the overlay rolls in
	species: { string }, -- the event aliens that spawn (Species rows listed in no Spawns table), any biome of those worlds
	spawnChance: number, -- fraction of wild spawns in the event's worlds that are an event species
	overlay: string?, -- Overlays row that rolls on wild spawns in the event's worlds; nil for none
	overlayChance: number, -- percent of wild spawns that carry it
	nightScale: number, -- Config.NightSeconds is multiplied by this while the season runs (1 = usual)
	returns: { string }, -- the Vault Rotation: limited species (weekly drops, past seasons) that spawn again, each in its own world
	returnChance: number, -- fraction of wild spawns in a returning species' world that are it
	track: { Quest }, -- the event quest track, in display order; each claimable once
}

local List: { Season } = {
	{
		id = "HauntedNebula",
		startsAt = 1792166400, -- Friday 2026-10-16 16:00 UTC (a weekly flip)
		endsAt = 1793376000, -- Friday 2026-10-30 16:00 UTC, two weeks on
		worldIds = { 1 },
		species = { "Wisplet", "Spookum" },
		spawnChance = 0.12,
		overlay = "Spectral",
		overlayChance = 3,
		nightScale = 2,
		returns = { "Panpipe" },
		returnChance = 0.03,
		track = {
			{ id = "S_catch5", objective = { kind = "catchEvent", count = 5 }, rewards = { { kind = "scrap", amount = 500 } } },
			{ id = "S_catch12", objective = { kind = "catchEvent", count = 12 }, rewards = { { kind = "lure", id = "Lure2", amount = 2 }, { kind = "spin", amount = 1 } } },
			{ id = "S_overlay1", objective = { kind = "catchOverlay", count = 1 }, rewards = { { kind = "scrap", amount = 1500 } } },
			{ id = "S_shower3", objective = { kind = "showerCount", count = 3 }, rewards = { { kind = "spin", amount = 2 } } },
			{ id = "S_catch25", objective = { kind = "catchEvent", count = 25 }, rewards = { { kind = "alien", id = "Nebulyn", amount = 1 } } },
		},
	},
}

local ById: { [string]: Season } = {}
for _, season in ipairs(List) do
	ById[season.id] = season
end

return {
	List = List,
	ById = ById,
	PushSeconds = 30, -- how often the server re-reads the clock (a start or an end is announced within this)
}
