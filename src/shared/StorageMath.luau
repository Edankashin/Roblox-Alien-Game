--!strict
-- ReplicatedStorage.Shared.StorageMath: the alien storage cap's rules (data/Storage), shared so the server's grant and
-- release checks and the client's count colour, release value and bulk preview agree. Pure functions of the data
-- tables and the records passed in; nothing here reads a clock or a profile, and the server re-checks every call.
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

-- Whether a profile holding `count` records takes no more.
function StorageMath.IsFull(count: number): boolean
	return count >= Storage.StorageCap
end

-- Whether `count` records reach WarnFraction of the cap (a full store is also a warning). Divides rather than
-- multiplying the cap so the boundary count is exact.
function StorageMath.IsWarning(count: number): boolean
	return count / Storage.StorageCap >= Storage.WarnFraction
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
