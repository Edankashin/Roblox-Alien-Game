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
	ClockTweenSeconds = 3, -- Lighting.ClockTime eases between day (12) and night (0) over this
	DayClockTime = 12,
	NightClockTime = 0,

	-- Meteor Shower (server clock)
	ShowerIntervalSeconds = 7200,
	ShowerDurationSeconds = 180,
	ShowerLuckBonus = 2.0, -- +200%

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
	WildBobStuds = 0.3, -- client-side idle bob amplitude
	WildBobHz = 0.6,
	WildHoverStuds = 1, -- wild aliens float this far above the ground

	-- luck
	LuckCap = 8.0,
	PityStepPerCatch = 0.05, -- added to luck for each catch without a Rare+
	PityMax = 1.0,

	-- Peddler
	PeddlerIntervalSeconds = 300,
}
