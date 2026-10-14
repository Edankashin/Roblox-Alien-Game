--!strict
-- ReplicatedStorage.Shared.EggMath: which species an egg of a tier can hatch, as one pure rule shared by every egg the
-- server grants (the Welcome Week egg, the playtime egg and the Peddler's eggs all draw from it) and by a headless test.
-- The pool is the species of the tier that belong to the world the egg hatches in, minus the ones that are not for an egg:
-- a Quest species (a milestone reward), a Shower species (the Meteor Shower's Cosmic stays a shower catch), and an event
-- species (data/Seasons `species`: the Haunted Nebula's Wisplet and Spookum) unless the season that lists it is running.
-- An egg is a random draw from the pool, so the pool is also the list any odds shown for an egg must come from: nothing
-- outside it can hatch. `running` is the season the server's Seasons service reports for this moment (SeasonMath.Current,
-- Dev's /season included), nil when none runs.

local Species = require(script.Parent.data.Species)
local SeasonMath = require(script.Parent.SeasonMath)

local EggMath = {}

-- Whether an egg may hatch `speciesId` while `running` is the running season: any species no season lists as its event
-- alien, and a listed one only when the running season is a season that lists it.
function EggMath.InSeason(speciesId: string, running: SeasonMath.Current?): boolean
	if not SeasonMath.IsLimited(speciesId) then
		return true
	end
	return running ~= nil and table.find(running.season.species, speciesId) ~= nil
end

-- The ids of the species an egg of `tier` can hatch in `world`, in the order of the Species table. Empty for a nil tier
-- or a tier with nothing to hatch (the caller refuses the claim and grants nothing).
function EggMath.Pool(tier: string?, world: number, running: SeasonMath.Current?): { string }
	local pool: { string } = {}
	if not tier then
		return pool
	end
	for _, def in ipairs(Species.List) do
		if def.tier == tier and def.world == world and def.condition ~= "Quest" and def.condition ~= "Shower" and EggMath.InSeason(def.id, running) then
			table.insert(pool, def.id)
		end
	end
	return pool
end

return EggMath
