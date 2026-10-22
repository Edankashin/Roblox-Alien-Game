--!strict
-- The weather sheets and the ambient layers (data/Weather): the Moonlit Forest's fireflies and spore motes stay inside
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
		for _, name in ipairs({ "Fireflies", "SporeMotes" }) do
			local layer = Weather.Layers[name]
			expect(layer ~= nil).toEqual(true)
			expect(layer.night).toEqual(true)
			expect(layer.world).toEqual(1)
			expect(layer.biome).toEqual("Forest")
		end
		-- the falling pale streaks read as rain over the navy forest (Mac job 53 step 5): no night layer falls or streaks
		expect(Weather.Layers.LightDrips == nil).toEqual(true)
	end)

	it("keeps the Forest's night motes small, slow, few and drifting, not falling streaks", function()
		for _, name in ipairs({ "Fireflies", "SporeMotes" }) do
			local sheet = Weather.Layers[name].sheet
			expect(sheet.mode).toEqual("drift")
			expect(sheet.velocityParallel).toEqual(false)
			expect(sheet.squash).toEqual(1)
			expect(sheet.sizeStart <= 0.35 and sheet.sizeEnd <= 0.35).toEqual(true)
			expect(sheet.speed[2] <= 0.6).toEqual(true)
			expect(sheet.rate <= 2.5).toEqual(true)
			expect(sheet.spread >= 90).toEqual(true)
			expect(sheet.texture ~= 0).toEqual(true)
		end
		-- warm and teal
		local warm, teal = Weather.Layers.Fireflies.sheet.color, Weather.Layers.SporeMotes.sheet.color
		expect(tonumber(warm:sub(1, 2), 16) > tonumber(warm:sub(5, 6), 16)).toEqual(true)
		expect(tonumber(teal:sub(3, 4), 16) > tonumber(teal:sub(1, 2), 16)).toEqual(true)
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
