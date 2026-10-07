--!strict
-- ReplicatedStorage.Shared.StorageMath: the alien storage cap's rules (data/Storage), shared so the server's grant,
-- release and Storage Bay checks and the client's count colour, release value, bulk preview and Bay button agree. Pure
-- functions of the data tables and the values passed in; nothing here reads a clock or a profile, and the server
-- re-checks every call. The cap is not a constant (milestone 50b): CapFor builds it from the ship modules finished, the
-- Storage Bay level and the StorageBoost pass, under the absolute HardCap, and IsFull and IsWarning take that cap.
-- "In use" means the alien cannot be released: it works at a station, follows the player (a ridden mount is always a
-- follower) or is on display in a home habitat.

local Types = require(script.Parent.types.Types)
local Species = require(script.Parent.data.Species)
local Storage = require(script.Parent.data.Storage)

local StorageMath = {}

export type InUseReason = "Seated" | "Following" | "Displayed"

-- How many alien records a profile's map holds.
function StorageMath.CountOf(aliens: { [string]: Types.AlienRecord }): number
	local count = 0
	for _ in pairs(aliens) do
		count += 1
	end
	return count
end

-- Whether a profile holding `count` records takes no more under `cap`.
function StorageMath.IsFull(count: number, cap: number): boolean
	return count >= cap
end

-- Whether `count` records reach WarnFraction of `cap` (a full store is also a warning). Divides rather than
-- multiplying the cap so the boundary count is exact.
function StorageMath.IsWarning(count: number, cap: number): boolean
	return cap <= 0 or count / cap >= Storage.WarnFraction
end

-- The ids of the ship modules a profile has finished, across every world (`modules` is Profile.modules: world id
-- string -> module id -> progress; a module counts once completedAt is set), in ascending order.
function StorageMath.CompletedIds(modules: { [string]: { [string]: Types.ModuleProgress } }): { string }
	local ids: { string } = {}
	for _, world in pairs(modules) do
		for id, state in pairs(world) do
			if state.completedAt ~= nil then
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids)
	return ids
end

-- The cap and where it comes from. `completedModuleIds` are the modules finished (a repeated id counts once, an id with
-- no data/Storage row adds nothing); `bayLevel` is the Storage Bay levels bought (a fraction rounds down, a level past
-- the last or below 0 counts as the last or 0); `hasPass` is whether the StorageBoost pass is owned. `sum` is the three
-- parts on top of the base; `cap` is the sum under HardCap.
export type Parts = { base: number, modules: number, bay: number, pass: number, sum: number, cap: number }

function StorageMath.Parts(completedModuleIds: { string }, bayLevel: number, hasPass: boolean): Parts
	local modules = 0
	local counted: { [string]: boolean } = {}
	for _, id in ipairs(completedModuleIds) do
		if not counted[id] then
			counted[id] = true
			modules += Storage.ModuleBonus[id] or 0
		end
	end
	local levels = if bayLevel == bayLevel then math.clamp(math.floor(bayLevel), 0, #Storage.Bay.Levels) else 0
	local bay = levels * Storage.Bay.PerLevel
	local pass = if hasPass then Storage.PassBonus else 0
	local sum = Storage.BaseCap + modules + bay + pass
	return { base = Storage.BaseCap, modules = modules, bay = bay, pass = pass, sum = sum, cap = math.min(Storage.HardCap, sum) }
end

-- How many alien records a profile may hold: Parts(...).cap.
function StorageMath.CapFor(completedModuleIds: { string }, bayLevel: number, hasPass: boolean): number
	return StorageMath.Parts(completedModuleIds, bayLevel, hasPass).cap
end

-- The next Storage Bay level for a player who has bought `bayLevel` of them and has unlocked `unlockedWorlds`
-- (Profile.world.unlocked): its data row, and why it cannot be bought yet. (nil, "Max") when every level is bought;
-- (row, "NeedsWorld") when the row's world is not unlocked (the row says which); (row, nil) when it is open. The Scrap
-- is the caller's to check.
export type BayRefusal = "Max" | "NeedsWorld"

function StorageMath.NextBayLevel(bayLevel: number, unlockedWorlds: { number }): (Storage.BayLevel?, BayRefusal?)
	local owned = if bayLevel == bayLevel then math.clamp(math.floor(bayLevel), 0, #Storage.Bay.Levels) else 0
	local row = Storage.Bay.Levels[owned + 1]
	if not row then
		return nil, "Max"
	end
	local highest = 0
	for _, world in ipairs(unlockedWorlds) do
		highest = math.max(highest, world)
	end
	if row.world > highest then
		return row, "NeedsWorld"
	end
	return row, nil
end

-- Scrap for releasing one alien of this tier, and what an overflow catch of the tier turns into; 0 for a tier the
-- data does not list.
function StorageMath.ReleaseValue(tier: Types.Tier): number
	return Storage.ReleaseScrap[tier] or 0
end

-- Whether "Release all unused" may sweep this tier.
function StorageMath.IsBulkTier(tier: string): boolean
	return table.find(Storage.BulkReleaseTiers, tier) ~= nil
end

-- Why this record cannot be released, or nil when it is free: Seated (works at a station), Following (in
-- `companions`, so also any mount) or Displayed (in a habitat).
function StorageMath.InUse(record: Types.AlienRecord, companions: { string }): InUseReason?
	if record.station ~= nil then
		return "Seated"
	end
	if table.find(companions, record.uid) ~= nil then
		return "Following"
	end
	if record.habitat ~= nil then
		return "Displayed"
	end
	return nil
end

-- Every record of `tier` that is free, as uids in ascending order (so a result is the same on every call), and the
-- Scrap releasing them all pays. A species the data no longer lists is not of any tier and is left alone.
function StorageMath.Releasable(aliens: { [string]: Types.AlienRecord }, companions: { string }, tier: Types.Tier): ({ string }, number)
	local uids: { string } = {}
	local scrap = 0
	for uid, record in pairs(aliens) do
		local def = Species.ById[record.species]
		if def and def.tier == tier and StorageMath.InUse(record, companions) == nil then
			table.insert(uids, uid)
			scrap += StorageMath.ReleaseValue(tier)
		end
	end
	table.sort(uids)
	return uids, scrap
end

return StorageMath
