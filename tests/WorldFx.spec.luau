--!strict
-- The ambient effects at places in the generated worlds (data/WorldFx, read by World.WorldFx): every place names a known kind, every
-- particle row stays under the per-place phone budget, the running places together stay under ParticleBudget, and that budget plus
-- the world's layers (data/Weather) plus its heaviest weather sheet that does not pause them stays under Config.WeatherParticleMax.
local Shared = game:GetService("ReplicatedStorage").Shared
local FxData = require(Shared.data.WorldFx)
local Weather = require(Shared.data.Weather)
local Worlds = require(Shared.data.Worlds)
local Config = require(Shared.data.Config)
local Icons = require(Shared.data.Icons)
local WorldGrid = require(Shared.WorldGrid)

local function alive(rate: number, lifetime: { number }): number
	return rate * lifetime[2]
end

describe("WorldFx", function()
	it("names a known kind at every place of both worlds", function()
		for _, worldId in ipairs({ 1, 2 }) do
			local grid = WorldGrid.For(worldId)
			assert(grid, "no grid")
			expect(#grid.gen.Fx > 0).toEqual(true)
			for _, spot in ipairs(grid.gen.Fx) do
				expect(FxData.Kinds[spot.kind] ~= nil).toEqual(true)
				expect(spot.size > 0).toEqual(true)
			end
		end
	end)

	it("keeps every particle row under the per-place budget with a real sprite", function()
		local sprites: { [number]: boolean } = { [0] = true }
		for _, id in pairs(Icons.Particles) do
			sprites[id] = true
		end
		for _, row in pairs(FxData.Kinds) do
			if row.sort == "particles" then
				expect(alive(row.rate, row.lifetime) <= FxData.PerEmitterMax).toEqual(true)
				expect(row.lifetime[1] <= row.lifetime[2]).toEqual(true)
				expect(sprites[row.texture]).toEqual(true)
			end
		end
		expect(FxData.MaxActive * FxData.PerEmitterMax <= FxData.ParticleBudget).toEqual(true)
	end)

	it("leaves room for the world's layers and its heaviest unpaused weather", function()
		for _, worldId in ipairs({ 1, 2 }) do
			local world = Worlds[worldId]
			local heaviest = 0
			local ids = { table.unpack(world.weather.normal) }
			table.insert(ids, world.weather.special.id)
			for _, id in ipairs(ids) do
				local sheet = Weather.Sheets[id]
				if sheet ~= nil and not FxData.PauseIn[id] then
					heaviest = math.max(heaviest, alive(sheet.rate, sheet.lifetime))
				end
			end
			local layers = 0
			for _, layer in pairs(Weather.Layers) do
				if layer.world == worldId then
					layers += alive(layer.sheet.rate, layer.sheet.lifetime)
				end
			end
			expect(heaviest + layers + FxData.ParticleBudget <= Config.WeatherParticleMax).toEqual(true)
		end
	end)

	it("gives World 2 its aurora by night and World 1 its butterflies by day", function()
		local function kinds(worldId: number): { [string]: boolean }
			local grid = WorldGrid.For(worldId)
			assert(grid, "no grid")
			local out: { [string]: boolean } = {}
			for _, spot in ipairs(grid.gen.Fx) do
				out[spot.kind] = true
			end
			return out
		end
		expect(kinds(2).Aurora).toEqual(true)
		expect(FxData.Kinds.Aurora.when).toEqual("night")
		expect(kinds(1).Butterflies).toEqual(true)
		expect(FxData.Kinds.Butterflies.when).toEqual("day")
		expect(kinds(1).FallMist).toEqual(true)
		expect(kinds(2).LakeMist).toEqual(true)
	end)
end)

return true
