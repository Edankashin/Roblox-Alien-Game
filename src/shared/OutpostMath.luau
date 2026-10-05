--!strict
-- The outpost arithmetic both sides share: what an outpost has produced since its last collect, which key
-- materials a world's outpost yields and in what order, and the cost of the next level. Pure functions of
-- the profile's outpost state and a clock; the server grants from them, the client only shows them.

local Outposts = require(script.Parent.data.Outposts)
local KeyMaterials = require(script.Parent.data.KeyMaterials)
local Types = require(script.Parent.types.Types)

local OutpostMath = {}

export type Pending = {
	scrap: number,
	materials: { [string]: number }, -- key material id -> count
	materialCount: number, -- the sum of materials
	seconds: number, -- the capped time the amounts cover
}

local yieldCache: { [number]: { string } } = {}

-- The key material ids a world's outpost yields, sorted, so unit k always lands on the same material:
-- the world's materials with nodes in the field, minus Outposts.ExcludedConditions.
function OutpostMath.Yield(worldId: number): { string }
	local cached = yieldCache[worldId]
	if cached then
		return cached
	end
	local ids: { string } = {}
	for id, def in pairs(KeyMaterials) do
		if def.world == worldId and def.nodes > 0 and not table.find(Outposts.ExcludedConditions, def.condition) then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	yieldCache[worldId] = ids
	return ids
end

-- The level's rates, clamped to the table.
function OutpostMath.Level(level: number): Outposts.Level
	return Outposts.Levels[math.clamp(level, 1, #Outposts.Levels)]
end

function OutpostMath.MaxLevel(): number
	return #Outposts.Levels
end

-- Scrap to reach the next level, or nil at the top.
function OutpostMath.UpgradeCost(level: number): number?
	return OutpostMath.Level(level).upgradeScrap
end

-- What the outpost has produced between its lastCollect and `now`, capped at Outposts.CollectCapSeconds.
-- Whole units only; materials are dealt round-robin over Yield(worldId) starting at an offset taken from
-- lastCollect so many small collects do not all favour the first material.
function OutpostMath.Pending(state: Types.OutpostState, worldId: number, now: number): Pending
	local seconds = math.clamp(now - state.lastCollect, 0, Outposts.CollectCapSeconds)
	local level = OutpostMath.Level(state.level)
	local scrap = math.floor(seconds * level.scrapPerHour / 3600)
	local count = math.floor(seconds * level.materialsPerHour / 3600)
	local materials: { [string]: number } = {}
	local ids = OutpostMath.Yield(worldId)
	if #ids > 0 then
		local start = state.lastCollect % #ids
		for k = 1, count do
			local id = ids[((start + k - 1) % #ids) + 1]
			materials[id] = (materials[id] or 0) + 1
		end
	else
		count = 0
	end
	return { scrap = scrap, materials = materials, materialCount = count, seconds = seconds }
end

return OutpostMath
