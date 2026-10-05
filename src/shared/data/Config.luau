--!strict
-- Every tunable timer and cap. Nothing in logic hard-codes these.
return {
	WorkingTitle = "AlienGame",

	-- world clock
	DaySeconds = 180,
	NightSeconds = 90,
	WeatherMinSeconds = 120,
	WeatherMaxSeconds = 300,
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
	OfflineCapSecondsPass = 10800, -- the cap with the Longer Offline pass (180 min)

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
	RadarRefreshSeconds = 0.1, -- the minimap re-places its blips this often
	RadarWaypointArriveStuds = 8, -- a blip's waypoint clears once the player is this close

	-- juice: presentation timings and sizes (client only; nothing here decides an outcome)
	CameraPanSeconds = 2.5, -- the camera glides to a finished module over this
	CameraPanHoldSeconds = 1.2, -- and rests on it this long before gliding back
	CameraPanDistance = 26, -- studs the pan looks at the ship from
	CameraPanHeight = 14, -- studs above the ship the pan looks down from
	CrashCinematicSeconds = 4, -- the opening drop from the sky to the character
	CrashStartHeight = 140, -- studs above the camp the opening starts at
	CrashShakeStuds = 0.6, -- camera shake amplitude at touchdown
	CrashLineSeconds = 2.2, -- each crash line stays this long
	AmbienceFadeSeconds = 2, -- ambience loops crossfade over this
	VfxCatchBurstSeconds = 0.8, -- the burst where a caught alien stood
	VfxModuleBurstSeconds = 1.5, -- the burst over a finished module
	VfxShowerStreaksPerSecond = 6, -- meteor streaks over the camp during a shower
	GainFlySeconds = 0.6, -- a "+25" flies from the action button to the Scrap pill over this
	ReducedMotionFactor = 0.5, -- tween lengths shrink by this when the player's reduced-motion setting is on
	AnalyticsEnabled = true, -- AnalyticsService events (funnel, custom, economy); off in Studio by default below
	AnalyticsInStudio = false, -- Studio sessions only print what they would send
	ReceiptMemory = 100, -- receipt ids remembered per profile so a repeated ProcessReceipt never grants twice
	ServerLuckPushSeconds = 10, -- how often the server-luck countdown is refreshed on clients
	PassCheckRetries = 3, -- UserOwnsGamePassAsync attempts on join before giving up for this session
	-- launch: the complete ship lifts off and the player moves to the next world's place
	LaunchLiftSeconds = 4, -- the ship rises over this (client animation)
	LaunchLiftStuds = 80, -- and this high before the screen fades
	LaunchFadeSeconds = 1.2, -- the fade to black at the end of the lift
	LaunchTeleportDelaySeconds = 5.5, -- the server teleports this long after Launch is accepted (lift + fade)
	LaunchHoldSeconds = 2, -- without a live place id the fade holds this long, then the camp returns
	-- the Heater rule (worlds whose rule is "Blizzard"): the special weather hides wild aliens beyond a short
	-- distance; a Heater placed for Scrap reveals everything inside its radius for a while
	BlizzardHideStuds = 25, -- wild aliens farther than this from the player are hidden during the blizzard
	HeaterScrap = 150,
	HeaterRadius = 40,
	HeaterSeconds = 60,
	HeaterMaxActive = 2, -- heaters one player may have burning at once
	HeaterPlaceStuds = 6, -- placed this far in front of the player
	NearbyRefreshSeconds = 1, -- the Nearby panel re-reads the biome, condition and codex this often
	WildBobStuds = 0.3, -- client-side idle bob amplitude
	WildBobHz = 0.6,
	WildHoverStuds = 1, -- wild aliens float this far above the ground

	-- Star Chart and outposts (data/Outposts has the production numbers)
	TeleportGraceSeconds = 10, -- with a live place, how long the black screen waits for a launch or fly teleport before lifting as a safety net
	FlyTeleportDelaySeconds = 1.5, -- the client fades for this long before the server teleports a Fly
	StarChartPulseSeconds = 1.2, -- the current world's card pulses with this period (off under Reduced Motion)
	StarChartTickSeconds = 1, -- the pending numbers on the chart refresh this often while it is open
	NotifyRetrySeconds = 5, -- a notifications card waiting for a clear screen (no catch, reveal, launch, fly or panel) re-checks this often
	NotifyRetryCount = 12, -- and gives up after this many re-checks (the server asks again on a later session)

	-- models (ReplicatedStorage.Models.<SpeciesId>, imported by hand: .claude/skills/import-model; the client falls back to placeholders)
	ModelFolderName = "Models",
	PropsFolderName = "Props", -- ReplicatedStorage.<ModelFolderName>.<PropsFolderName>.<Name>: imported scenery Models (trees, rocks, ship hull, station and heater meshes), by hand; builders fall back to part-built placeholders
	HeaterPropName = "HeaterLamp", -- the Props entry the Heaters service stands on its disc, when imported
	PropScaleJitter = 0.1, -- scattered props (trees, rocks, geyser cones) are scaled 1 +- this
	ModelFacesPlusZ = false, -- true when the imported meshes face +Z: clones turn 180 degrees so the eyes face -Z, the Roblox front
	ModelWildScale = 1, -- multiplier on the mesh's own size for wild aliens
	ModelWorkerScale = 1, -- multiplier on the mesh's own size for station workers, on top of Camp.WorkerScale
	ModelViewportScale = 1, -- multiplier on the mesh's own size in the Reveal card and the Codex pedestal

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
