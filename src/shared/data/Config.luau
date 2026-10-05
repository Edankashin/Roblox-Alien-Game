--!strict
-- Every tunable timer and cap. Nothing in logic hard-codes these.
return {
	WorkingTitle = "AlienGame",

	-- world clock
	DaySeconds = 180,
	NightSeconds = 90,
	WeatherMinSeconds = 120,
	WeatherMaxSeconds = 300,
	CurrentWorld = 1, -- the world this place runs; its weather list and special weather come from data/Worlds.luau
	ClockTweenSeconds = 3, -- Lighting.ClockTime eases between day (12) and night (0) over this
	DayClockTime = 12,
	NightClockTime = 0,

	-- Meteor Shower (server clock)
	ShowerIntervalSeconds = 7200, -- fixed server clock: showers start at multiples of this since the epoch
	ShowerDurationSeconds = 180,
	ShowerLuckBonus = 2.0, -- +200% luck for everyone on the server while it runs
	ShowerCosmicShare = 0.2, -- percent of spawns that roll Cosmic during a shower (0 outside one)
	ShowerWarnSeconds = 300, -- the countdown chip appears this long before a shower
	ShowerPushSeconds = 10, -- how often the server refreshes the shower clock on clients
	GiftDaySeconds = 86400, -- a "day played" ticks over every this many seconds of wall clock (UTC days)

	-- economy
	BaseScrapPerSecond = 1, -- a Common at level 1 in a station
	LevelSpeedStep = 0.35, -- each level above 1 adds this fraction of work speed
	StationMaxSlots = 3,
	StationStartSlots = 1,

	-- camp (stations and ship assembly)
	IncomeTickSeconds = 1, -- the server accrues station Scrap this often
	AssemblyPlayerSpeed = 1, -- the player's own crew assembles at this work speed even with no aliens at the station
	CampInteractDistance = 14, -- studs from the ship to show the Build button
	MaterialInteractDistance = 8, -- studs from a material node to show Collect
	MaterialDistanceSlack = 3, -- extra studs the server allows for movement between the tap and the check
	OfflineMinSeconds = 60, -- absences shorter than this show no welcome-back

	-- offline
	OfflineRate = 0.5,
	OfflineCapSeconds = 3600, -- cap on accrued income time (about 60 min of income)

	-- companions and gear
	CompanionSlots = 3,

	-- saves
	AutosaveSeconds = 180,
	SessionLockSeconds = 600,
	UseDataStoreInStudio = false, -- flip to true after enabling Studio API access

	-- servers
	MaxPlayers = 8,
	PreferredPlayers = 6,

	-- capture
	CaptureSweepsPerEncounter = 3,
	HiddenKindnessAfterMisses = 2,
	HiddenKindnessZoneBonus = 0.20, -- both zones grow by this fraction of their width (x1.20)
	LatencyAllowanceSeconds = 0.10, -- a tap may be stamped this far ahead of the server clock
	CaptureMaxTapLagSeconds = 0.35, -- a tap may be stamped this far behind the server clock (network delay)
	CaptureInteractDistance = 12, -- studs from the alien to start a catch; the Catch! button shows inside this
	CaptureDistanceSlack = 3, -- extra studs the server allows for movement between the tap and the check
	CaptureZoneCenterMin = 0.25,
	CaptureZoneCenterMax = 0.75,
	CaptureSweepLeadSeconds = 0.45, -- pause between a result and the next sweep so feedback can land
	CaptureEncounterTimeoutSeconds = 30, -- an idle encounter is dropped after this
	CaptureNearMissWidth = 0.05, -- a miss within this fraction of the Good zone edge flashes the zone
	PerfectScrapMultiplier = 2, -- a Perfect hit multiplies the catch Scrap by this
	LureAutoUse = true, -- the best lure held is spent automatically when a catch starts

	-- spawning
	SpawnDensityTarget = 14,
	SpawnRespawnMinSeconds = 60,
	SpawnRespawnMaxSeconds = 90,
	SpawnRadius = 90, -- studs around each player
	SpawnMinDistanceFromPlayer = 10, -- never spawn right on top of someone
	SpawnMinSeparation = 5, -- studs between wild aliens
	SpawnCampClearance = 20, -- studs beyond the camp pad edge kept free of spawns (the ship and stations sit here)
	SpawnCullDistance = 180, -- spawns farther than this from every player are removed
	SpawnTickSeconds = 1,
	ShadowRevealDistance = 40,
	NameplateDistance = 60, -- nameplates render inside this
	NearbyRefreshSeconds = 1, -- the Nearby panel re-reads the biome, condition and codex this often
	WildBobStuds = 0.3, -- client-side idle bob amplitude
	WildBobHz = 0.6,
	WildHoverStuds = 1, -- wild aliens float this far above the ground

	-- Field Notes and the Warden
	ShrineInteractDistance = 14, -- studs from the shrine centre to offer "Sound the horn"
	ShrineScatterClearance = 6, -- rocks and trees keep this far outside the shrine ring
	WardenSummonOffset = 6, -- the summoned Warden appears this far from the shrine centre, toward the camp
	WardenEncounterSeconds = 180, -- a summoned Warden waits this long before it retreats
	WardenRetreatSeconds = 900, -- after a failed or expired encounter the horn works again after this
	WardenZoneShrinkPerRound = 0.85, -- a multi-round capture multiplies both zones by this each round after the first

	-- tutorial
	TutorialPollSeconds = 1, -- the server checks position-based steps (the Forest walk) this often
	TutorialSpawnRespawnSeconds = 20, -- a guaranteed trainee alien that fled comes back after this

	-- announcements
	AnnounceMinTier = "Rare", -- catches of this tier and above are announced to the whole server
	AnnounceSeconds = 4, -- how long the server-wide banner stays up

	-- luck
	LuckCap = 8.0,
	PityStepPerCatch = 0.05, -- added to luck for each catch without a Rare+
	PityMax = 1.0,
	PityResetMinTier = "Rare", -- a catch of this tier or above resets the pity bonus to 0

	-- Peddler
	PeddlerIntervalSeconds = 300, -- a visit starts this often, measured from the previous visit's start
	PeddlerFirstVisitSeconds = 20, -- the first visit after a server boots lands this soon
	PeddlerVisitSeconds = 90, -- how long the ship stays
	PeddlerInteractDistance = 12, -- studs from the ship to show Trade
	PeddlerDescendSeconds = 2.5, -- client landing and take-off tween
	PeddlerHoverHeight = 60, -- where the ship waits in the sky between visits

	-- power-ups
	BuffTickSeconds = 1, -- the server counts active power-ups down this often, only while the player is online
	BuffPushSeconds = 5, -- and tells the client the remaining seconds this often (the client counts between pushes)
	LuckNightBonus = 0.25, -- luck bonus while it is night (design: night, for night-conditional species)
}
