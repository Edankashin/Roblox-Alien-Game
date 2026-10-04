--!strict
-- Every tunable timer and cap. Nothing in logic hard-codes these.
return {
	WorkingTitle = "AlienGame",

	-- world clock
	DaySeconds = 180,
	NightSeconds = 90,
	WeatherMinSeconds = 120,
	WeatherMaxSeconds = 300,
	WeatherStates = { "Clear", "Rain", "Fog" },

	-- Meteor Shower (server clock)
	ShowerIntervalSeconds = 7200,
	ShowerDurationSeconds = 180,
	ShowerLuckBonus = 2.0, -- +200%

	-- economy
	BaseScrapPerSecond = 1, -- a Common at level 1 in a station
	LevelSpeedStep = 0.35, -- each level above 1 adds this fraction of work speed
	StationMaxSlots = 3,
	StationStartSlots = 1,

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
	HiddenKindnessZoneBonus = 0.20,
	LatencyAllowanceSeconds = 0.10,

	-- spawning
	SpawnDensityTarget = 14,
	SpawnRespawnMinSeconds = 60,
	SpawnRespawnMaxSeconds = 90,
	SpawnRadius = 90, -- studs around each player
	ShadowRevealDistance = 40,

	-- luck
	LuckCap = 8.0,
	PityStepPerCatch = 0.05, -- added to luck for each catch without a Rare+
	PityMax = 1.0,

	-- Peddler
	PeddlerIntervalSeconds = 300,
}
