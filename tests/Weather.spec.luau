--!strict
-- The weather sheets and the ambient layers (data/Weather): the Moonlit Forest's fireflies and light drips stay inside
-- the phone budget, name a real world and biome, and wear sprites that already exist (no new upload).
local Shared = game:GetService("ReplicatedStorage").Shared
local Weather = require(Shared.data.Weather)
local Worlds = require(Shared.data.Worlds)
local Config = require(Shared.data.Config)
local Icons = require(Shared.data.Icons)

-- Particles alive at once from a sheet: rate x its longest lifetime.
local function alive(sheet)
	return sheet.rate * sheet.lifetime[2]
end

describe("ambient layers", function()
	it("exist for World 1's Forest at night", function()
		for _, name in ipairs({ "Fireflies", "LightDrips" }) do
			local layer = Weather.Layers[name]
			expect(layer ~= nil).toEqual(true)
			expect(layer.night).toEqual(true)
			expect(layer.world).toEqual(1)
			expect(layer.biome).toEqual("Forest")
		end
	end)

	it("name a real world and one of its biomes", function()
		for _, layer in pairs(Weather.Layers) do
			local world = Worlds[layer.world]
			expect(world ~= nil).toEqual(true)
			if layer.biome ~= nil then
				expect(table.find(world.biomes, layer.biome) ~= nil).toEqual(true)
			end
		end
	end)

	it("keep each world's layers together under LayerParticleMax", function()
		for worldId in pairs(Worlds) do
			local total = 0
			for _, layer in pairs(Weather.Layers) do
				if layer.world == worldId then
					total += alive(layer.sheet)
				end
			end
			expect(total <= Weather.LayerParticleMax).toEqual(true)
		end
	end)

	it("leave room for the heaviest weather sheet of the world under WeatherParticleMax", function()
		for worldId, world in pairs(Worlds) do
			local heaviest = 0
			local ids = { table.unpack(world.weather.normal) }
			table.insert(ids, world.weather.special.id)
			for _, id in ipairs(ids) do
				local sheet = Weather.Sheets[id]
				if sheet ~= nil then
					heaviest = math.max(heaviest, alive(sheet))
				end
			end
			local layered = false
			for _, layer in pairs(Weather.Layers) do
				if layer.world == worldId then
					layered = true
				end
			end
			if layered then
				expect(heaviest + Weather.LayerParticleMax <= Config.WeatherParticleMax).toEqual(true)
			end
		end
	end)

	it("are sheets the renderer can build: a real sprite id, a colour, a rising lifetime, a depth above zero", function()
		local sprites = {}
		for _, id in pairs(Icons.Particles) do
			sprites[id] = true
		end
		for _, layer in pairs(Weather.Layers) do
			local sheet = layer.sheet
			expect(sprites[sheet.texture]).toEqual(true)
			expect(#sheet.color).toEqual(6)
			expect(sheet.rate > 0 and sheet.lifetime[1] <= sheet.lifetime[2]).toEqual(true)
			expect(sheet.thickness == nil or sheet.thickness > 0).toEqual(true)
		end
	end)
end)
return true
