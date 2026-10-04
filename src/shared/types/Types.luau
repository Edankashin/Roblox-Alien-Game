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

return {}
