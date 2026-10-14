--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.EggMath)
local SeasonMath = require(Shared.SeasonMath)
local SeasonsData = require(Shared.data.Seasons)
local Species = require(Shared.data.Species)
local F = require(script.Parent.Fixtures)
local season = SeasonsData.List[F.one]
local running = SeasonMath.Current(season.startsAt + F.tick)
local event = Species.ById[season.species[F.one]]
local function has(pool: { string }, id: string): boolean
	return table.find(pool, id) ~= nil
end
-- A species of the event's tier and world that no season lists and an egg may hatch: the pool's plain member.
local function plain(): string
	for _, def in ipairs(Species.List) do
		if def.tier == event.tier and def.world == event.world and not SeasonMath.IsLimited(def.id) and def.condition ~= "Quest" and def.condition ~= "Shower" then
			return def.id
		end
	end
	return ""
end
describe("EggMath", function()
	it("an event species out of season is excluded", function()
		expect(running ~= nil).toEqual(true)
		expect(has(Math.Pool(event.tier, event.world, nil), event.id)).toEqual(false)
		expect(Math.InSeason(event.id, nil)).toEqual(false)
		-- every season's event species, whichever season is asked about
		for _, other in ipairs(SeasonsData.List) do
			for _, id in ipairs(other.species) do
				local def = Species.ById[id]
				expect(has(Math.Pool(def.tier, def.world, nil), id)).toEqual(false)
			end
		end
	end)
	it("in season it is included", function()
		expect(has(Math.Pool(event.tier, event.world, running), event.id)).toEqual(true)
		expect(Math.InSeason(event.id, running)).toEqual(true)
	end)
	it("a season that does not list the species does not admit it", function()
		local other = table.clone(season)
		other.species = {}
		local elsewhere: SeasonMath.Current = { season = other, secondsLeft = F.one }
		expect(has(Math.Pool(event.tier, event.world, elsewhere), event.id)).toEqual(false)
	end)
	it("a non-seasonal species is unaffected", function()
		local id = plain()
		expect(id ~= "").toEqual(true)
		expect(has(Math.Pool(event.tier, event.world, nil), id)).toEqual(true)
		expect(has(Math.Pool(event.tier, event.world, running), id)).toEqual(true)
		expect(Math.InSeason(id, nil)).toEqual(true)
		expect(#Math.Pool(event.tier, event.world, running)).toEqual(#Math.Pool(event.tier, event.world, nil) + F.one)
	end)
	it("quest and Shower species never hatch, in season or not", function()
		for _, def in ipairs(Species.List) do
			if def.condition == "Quest" or def.condition == "Shower" then
				expect(has(Math.Pool(def.tier, def.world, nil), def.id)).toEqual(false)
				expect(has(Math.Pool(def.tier, def.world, running), def.id)).toEqual(false)
			end
		end
	end)
	it("a missing tier or a tier with nothing in it is an empty pool", function()
		expect(#Math.Pool(nil, event.world, running)).toEqual(F.zero)
		expect(#Math.Pool("NoSuchTier", event.world, running)).toEqual(F.zero)
	end)
end)
return true
