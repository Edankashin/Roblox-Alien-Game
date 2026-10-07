--!strict
-- The music rows (docs/vault/06-art-pipelines/Music-Plan.md, Codex C21): one row per state the music director
-- (StarterPlayerScripts.Client.World.MusicDirector) can play, and the numbers that decide which one wins and how
-- they blend. Every number lives here. The director and Shared/MusicMath only read it.
--
-- WHO FILLS THE IDS: every `assetId` is 0 on purpose. The Mac session picks the tracks from the Creator Store
-- (Studio Toolbox > Audio, filter to Roblox-provided licensed music), auditions them on phone speakers and
-- headphones, checks each asset's usage terms and the experience permission, then pastes the plain number (the
-- digits of rbxassetid://<number>) into the row's `assetId` and notes title, creator and licence in Music-Plan.md.
-- Nothing else changes: a row at 0 is silent but the director still tracks it (the Studio Output line
-- "[AlienGame] Music: <state>" prints either way), a row with an id starts playing the moment a build carries it.
-- While a higher-priority row is still at 0 the next row down with an id keeps playing, so tracks can land one
-- at a time. Sounds.luau owns the one-shots and stingers (the Reveal tiers, the launch hit); this file owns the
-- beds and layers.
--
-- ROW FIELDS
--   assetId   0 = not chosen yet.
--   volume    0..1, the base gain before the player's Music preference, the menu layer and a stinger's duck. For a
--             "layer" row it is the gain MULTIPLIER the layer puts on the active bed (Menus), not a Sound volume.
--   loop      beds loop; the launch cue plays once.
--   layer     "bed" (one at a time, crossfaded by priority) or "layer" (a modifier over the active bed).
--   fadeIn / fadeOut   seconds to fade in as the winning bed and out when another wins (a layer: seconds to apply
--             and to lift).
--   priority  the highest-priority bed that applies wins. Launch beats everything; the intense capture beats the
--             events (a Legendary catch during a Meteor Shower is still the Legendary moment); the events beat
--             the plain capture bed, resting and the world beds (the order the owner set). The launch bed owns the
--             mix while it runs: a stinger does not duck it.

export type Row = {
	assetId: number,
	volume: number,
	loop: boolean,
	layer: "bed" | "layer",
	fadeIn: number,
	fadeOut: number,
	priority: number,
}

export type WorldBeds = { day: string, night: string }

local Rows: { [string]: Row } = {
	-- World 1 and World 2, day and night (64 to 96 s loops, a 3 s crossfade at the clock edge).
	VerdantDay = { assetId = 0, volume = 0.20, loop = true, layer = "bed", fadeIn = 3, fadeOut = 3, priority = 10 },
	VerdantNight = { assetId = 0, volume = 0.20, loop = true, layer = "bed", fadeIn = 3, fadeOut = 3, priority = 10 },
	FrostbyteDay = { assetId = 0, volume = 0.20, loop = true, layer = "bed", fadeIn = 3, fadeOut = 3, priority = 10 },
	FrostbyteNight = { assetId = 0, volume = 0.20, loop = true, layer = "bed", fadeIn = 3, fadeOut = 3, priority = 10 },
	-- The home planet (day and night share one cozy track): 3 s in, 2 s out.
	Home = { assetId = 0, volume = 0.18, loop = true, layer = "bed", fadeIn = 3, fadeOut = 2, priority = 10 },
	-- Resting: 4 s in, 1.5 s back to the world on waking; never a rhythm.
	Resting = { assetId = 0, volume = 0.12, loop = true, layer = "bed", fadeIn = 4, fadeOut = 1.5, priority = 40 },
	-- The catch bar: a muted pluck loop, and the matching intense bed for Legendary and above.
	CatchBase = { assetId = 0, volume = 0.22, loop = true, layer = "bed", fadeIn = 0.3, fadeOut = 0.25, priority = 50 },
	CatchIntense = { assetId = 0, volume = 0.12, loop = true, layer = "bed", fadeIn = 0.3, fadeOut = 0.25, priority = 90 },
	-- Events: a Meteor Shower (1 s in, 2 s out), a Catch Rush round (0.5 s in, 1 s out; no restart per score update)
	-- and the Haunted Nebula season (3 s in and out; keyed by its data/Seasons id).
	MeteorShower = { assetId = 0, volume = 0.22, loop = true, layer = "bed", fadeIn = 1, fadeOut = 2, priority = 80 },
	CatchRush = { assetId = 0, volume = 0.22, loop = true, layer = "bed", fadeIn = 0.5, fadeOut = 1, priority = 70 },
	HauntedNebula = { assetId = 0, volume = 0.18, loop = true, layer = "bed", fadeIn = 3, fadeOut = 3, priority = 60 },
	-- The launch cue (8 to 12 s, once): 0.15 s attack at the lift, a 1 s fade out on the teleport or a failure.
	Launch = { assetId = 0, volume = 0.28, loop = false, layer = "bed", fadeIn = 0.15, fadeOut = 1, priority = 100 },
	-- A menu or panel open: the active bed's gain x0.65 in 0.25 s, restored over 0.4 s. It plays no sound of its own.
	Menus = { assetId = 0, volume = 0.65, loop = false, layer = "layer", fadeIn = 0.25, fadeOut = 0.4, priority = 0 },
}

-- The world bed for each world id (0 is the home planet). A world with no entry has no music yet (the built worlds
-- are 0 to 2; later worlds add their rows above and one line here).
local Worlds: { [number]: WorldBeds } = {
	[0] = { day = "Home", night = "Home" },
	[1] = { day = "VerdantDay", night = "VerdantNight" },
	[2] = { day = "FrostbyteDay", night = "FrostbyteNight" },
}

return {
	Rows = Rows,
	Worlds = Worlds,
	-- Which row each running event plays (the season event's row is its data/Seasons id), and the row the
	-- director plays during the launch sequence.
	Events = { Shower = "MeteorShower", Rush = "CatchRush", Launch = "Launch" },
	-- The catch bar: the bed for a plain catch and for the intense one, and the tier from which a catch is intense
	-- (and opens with the rumble, Config.LegendaryRumbleSeconds).
	Capture = { base = "CatchBase", intense = "CatchIntense", intenseFromTier = "Legendary" },
	-- The modifier row a menu or panel open applies to the active bed, and the bed resting plays.
	MenuLayer = "Menus",
	Resting = "Resting",
	-- A stinger (Sounds.luau) dips the bed: to Gain times its volume in AttackSeconds, held for the stinger's length
	-- (StingerSeconds, keyed by the Sounds path; DefaultStingerSeconds for a key not listed), then back over
	-- RestoreSeconds. The Reveal lengths are C21's, the launch hit is the middle of its 8 to 12 s.
	Ducking = {
		Gain = 0.10,
		AttackSeconds = 0.05,
		RestoreSeconds = 0.8,
		DefaultStingerSeconds = 1.0,
		StingerSeconds = {
			["Reveal.Common"] = 1.0,
			["Reveal.Uncommon"] = 1.6,
			["Reveal.Rare"] = 2.2,
			["Reveal.Epic"] = 2.8,
			["Reveal.Legendary"] = 3.4,
			["Reveal.Cosmic"] = 4.0,
			["Reveal.Secret"] = 4.6,
			Launch = 10,
		} :: { [string]: number },
	},
}
