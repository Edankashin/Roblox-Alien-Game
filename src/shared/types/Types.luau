--!strict
-- Shared types for the whole game. Every data table and service imports from here.

export type Tier = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Cosmic" | "Secret"
export type Job = "Gather" | "Build" | "Spark" | "Tinker"
export type Overlay = "None" | "Shiny" | "Gold" | "Crystal" | "Rainbow"
export type Biome = "Meadow" | "Forest" | "Cave"
export type Condition = "Any" | "Day" | "Night" | "Rain" | "Shower" | "Quest"
export type Traversal = "Sprint" | "Hover" | "Glide" | "Swim" | "Climb"

export type JobLevel = { job: Job, level: number }

export type SpeciesDef = {
	id: string,
	name: string,
	concept: string,
	tier: Tier,
	jobs: { JobLevel },
	biome: Biome,
	condition: Condition,
	world: number,
	ride: Traversal?,
	-- placeholder rendering until real meshes exist
	placeholder: { shape: "Ball" | "Block" | "Cylinder", color: string, scale: number },
	voiceLine: string,
}

export type TierDef = {
	share: number, -- share of wild spawns, percent (Cosmic and Secret are 0: event or quest only)
	workSpeed: number, -- multiplier versus Common
	passive: number, -- camp-wide bonus, fraction (0.10 = +10%)
	catchChance: number, -- chance a Good hit catches, 0..1
	tickerSpeed: number, -- bar sweeps per second
	goodZone: number, -- fraction of bar width
	perfectZone: number,
	rounds: number,
	codexScrap: number, -- first-catch payout
	color: string,
}

export type AlienRecord = {
	uid: string,
	species: string,
	level: number, -- 1..7 (base level plus fusion)
	overlay: Overlay,
	caughtAt: number,
	station: Job?, -- which station it is assigned to, if any
	slot: number?,
}

export type StationState = { slots: number, assigned: { string } }

export type ModuleProgress = {
	scrapPaid: number,
	keyPaid: number,
	progress: number, -- 0..1 assembly progress
	started: boolean,
	completedAt: number?,
	updatedAt: number, -- os.time() of the last progress write; both sides extrapolate from here
}

export type OutpostState = { level: number, lastCollect: number }

export type Profile = {
	version: number,
	scrap: number,
	aliens: { [string]: AlienRecord },
	stations: { [string]: StationState },
	modules: { [string]: { [string]: ModuleProgress } }, -- modules[worldId][moduleId]
	world: { current: number, unlocked: { number }, outposts: { [string]: OutpostState } },
	codex: { [string]: { count: number, bestOverlay: Overlay, firstCaughtAt: number } },
	gear: { boots: boolean, hoverboard: boolean, glider: boolean, radar: number },
	companions: { string },
	quests: { daily: { [string]: number }, weekly: { [string]: number }, fieldNotes: { [string]: number } },
	gifts: { daysPlayed: number, claimed: { [string]: boolean }, lastPlayDay: number },
	spins: { free: number, banked: number, lastFree: number },
	luck: { pity: number },
	purchases: { [string]: number },
	inventory: { keyMaterials: { [string]: number }, lures: { [string]: number }, powerUps: { [string]: number } },
	stats: { catches: number, perfects: number, playSeconds: number },
	tutorialStep: number,
	lastSeen: number,
	firstSeen: number,
	lock: { jobId: string, time: number }?,
}

-- Net payloads ------------------------------------------------------------

-- WorldClock -> clients on every day/night or weather change, and from GetClock.
export type ClockState = { isNight: boolean, weather: string, secondsLeft: number }

-- One sweep set of the capture bar. The client draws from these; the server judges from these.
export type SweepParams = {
	tickerSpeed: number, -- full left-right-left cycles per second
	goodZone: number, -- fraction of bar width
	perfectZone: number,
	zoneCenter: number, -- 0..1 along the bar
	roundsTotal: number,
	round: number, -- 1-based
	sweepsLeft: number,
	startClock: number, -- workspace:GetServerTimeNow() when this sweep's ticker leaves 0
}

export type CaptureStartResult = {
	token: string,
	species: string,
	tier: Tier,
	tickerSpeed: number,
	goodZone: number,
	perfectZone: number,
	zoneCenter: number,
	roundsTotal: number,
	round: number,
	sweepsLeft: number,
	startClock: number,
}

export type HitOutcome = "Perfect" | "Good" | "Miss"

-- "Round": a multi-round catch won this round; the next sweep set follows.
export type CaptureOutcome = "Caught" | "Fled" | "Wiggle" | "Miss" | "Round"

export type CaptureHitResult = {
	outcome: CaptureOutcome,
	hit: HitOutcome?, -- what the tap scored, present on every outcome but Fled-by-timeout
	pos: number?, -- where the server placed the ticker for that tap
	-- continued sweeps (Wiggle, Miss, Round)
	sweepsLeft: number?,
	round: number?,
	roundsTotal: number?,
	nextStartClock: number?,
	zoneCenter: number?,
	goodZone: number?,
	perfectZone: number?,
	-- Caught
	perfect: boolean?,
	species: string?,
	tier: Tier?,
	overlay: Overlay?,
	isNew: boolean?,
	scrapGained: number?,
	scrap: number?,
}

-- Camp -------------------------------------------------------------------

-- Economy -> client whenever an assignment or a work speed changes (RateChanged). assemblySpeed is by job.
export type CampState = { ratePerSecond: number, assemblySpeed: { [string]: number } }

-- Economy -> client once on join when the player was away long enough (OfflineSummary).
export type OfflineSummary = { awaySeconds: number, scrap: number, completedModules: { string } }

return {}
