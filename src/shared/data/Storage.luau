--!strict
-- Alien storage (milestones 50 and 50b; PRE_PRODUCTION section 5c item 7, Codex C17, decision B16). Why a cap: a save is
-- ONE DataStore value and Roblox refuses a value past 4,194,304 bytes (docs/vault/04-roblox-engine/Save-Budget.md). Each
-- alien record costs about 193 bytes, so a player who keeps every catch passes the limit around day 25 at 3 hours a day
-- without fusion (day 8 at 10 hours a day); past it the save fails and progress is lost. A profile therefore holds a
-- limited number of alien records, and the limit is something the player develops (the top simulators do the same: Grow
-- a Garden starts pets at 60 and raises it through passes, crafted pouches and a currency shop; the original Bubble Gum
-- Simulator starts at 125 with +30, +100, +500 and +1000 slot passes). The cap is
--   min(HardCap, BaseCap + the ModuleBonus of every ship module finished + Bay.PerLevel x the Storage Bay level
--                 + PassBonus while the StorageBoost pass is owned)
-- (Shared/StorageMath.CapFor). A new player starts at BaseCap; finishing the ship's modules grows it (World 1 ends at
-- 180, World 2 at 340); the Storage Bay is bought with Scrap, five levels open in World 1 and five more in World 2; the
-- pass sells storage SPACE for Robux, never Scrap. HardCap is the save-size safety and stays absolute whatever the sum:
-- 1,500 records are about 290 KB, well under the limit with room for everything else.
-- The rule at the cap (Economy.GrantAlien, the one door every alien enters through): a new alien adds no record, yet
-- everything else a catch does still happens (the codex entry and its first-catch Scrap, the quests, the weekly board,
-- analytics), and the alien turns into ReleaseScrap[tier] Scrap, reported to the client as GrantResult.overflowScrap.
-- The player makes room by releasing aliens (Economy.Release, ReleaseAliens and ReleaseAllOfTier remotes), which pays
-- the same Scrap, by fusing, or by growing the cap. An alien that is working, following, ridden or on display is never
-- released. A Robux-bought alien is exempt from the cap. Every number here, never in code.
local ReleaseScrap: { [string]: number } = {
	Common = 5,
	Uncommon = 12,
	Rare = 40,
	Epic = 150,
	Legendary = 500,
	Cosmic = 1500,
	Secret = 1500,
}

local BulkReleaseTiers: { string } = { "Common", "Uncommon" }

-- Storage added when a ship module completes, by module id (data/Modules). A module with no row adds nothing. World 1's
-- five add 120 (180 in all with BaseCap), World 2's five add 160 more (340). Worlds 3 to 7 get rows when they are built.
local ModuleBonus: { [string]: number } = {
	HullFrame = 10,
	Thrusters = 20,
	LifePod = 20,
	NavArray = 30,
	EngineCore = 40,
	HeatShield = 20,
	IceDrill = 25,
	CryoPod = 30,
	BeaconArray = 40,
	FrostEngine = 45,
}

-- The Storage Bay, bought one level at a time with Scrap. `scrap` is the price of that level and `world` the world the
-- player must have unlocked to buy it (World 1 opens five levels, +100; World 2 the other five, +200 in all).
export type BayLevel = { scrap: number, world: number }
local BayLevels: { BayLevel } = {
	{ scrap = 2500, world = 1 },
	{ scrap = 7500, world = 1 },
	{ scrap = 20000, world = 1 },
	{ scrap = 45000, world = 1 },
	{ scrap = 90000, world = 1 },
	{ scrap = 160000, world = 2 },
	{ scrap = 280000, world = 2 },
	{ scrap = 450000, world = 2 },
	{ scrap = 700000, world = 2 },
	{ scrap = 1000000, world = 2 },
}

return {
	BaseCap = 60, -- records a new profile holds
	ModuleBonus = ModuleBonus, -- storage added by each finished ship module, by module id
	Bay = { PerLevel = 20, Levels = BayLevels }, -- storage each Storage Bay level adds, and the levels' prices
	PassBonus = 100, -- storage the pass adds while it is owned
	PassItem = "StorageBoost", -- the data/Shop pass row that sells it (Robux buys space, never Scrap)
	HardCap = 1500, -- the ceiling whatever the sum: the save-size safety of milestone 50
	WarnFraction = 0.9, -- the Aliens count turns to the warning colour from this fraction of the cap
	ReleaseScrap = ReleaseScrap, -- Scrap for releasing one alien of a tier; also what an overflow catch turns into
	BulkReleaseTiers = BulkReleaseTiers, -- tiers "Release all unused" may sweep in one tap
	MaxReleasePerCall = 200, -- uids one ReleaseAliens call may name
	ConfirmSeconds = 3, -- the second tap on the Release button must come within this many seconds
	HoldSeconds = 0.45, -- holding an alien card this long opens its Release panel
	HoldMovePixels = 12, -- a held finger that drifts further than this is scrolling, not holding
}
