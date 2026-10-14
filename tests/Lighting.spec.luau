--!strict
-- The Moonlit Forest night (data/Lighting WorldConditions and BiomeConditions): the colour goes indigo, violet and
-- teal, and nothing becomes harder to see than the plain Night row it refines (the catch bar and the wild aliens stay
-- readable). The merge itself is LightingDirector's; these tests read the data rows it merges.
local Shared = game:GetService("ReplicatedStorage").Shared
local Lighting = require(Shared.data.Lighting)
local Worlds = require(Shared.data.Worlds)

local plain = Lighting.Conditions.Night
local meadow = Lighting.WorldConditions[1].Night
local forest = Lighting.BiomeConditions.Forest.Night

-- The value a row ends with for a field the plain Night may leave to the Base look.
local function effective(look, field)
	if look[field] ~= nil then
		return look[field]
	end
	if plain[field] ~= nil then
		return plain[field]
	end
	return Lighting.Base[field]
end

describe("Moonlit Forest night looks", function()
	for label, look in pairs({ ["World 1 night (the Meadow)"] = meadow, ["Forest night"] = forest }) do
		describe(label, function()
			it("keeps brightness and exposure at or above the plain Night", function()
				expect(effective(look, "Brightness") >= effective(plain, "Brightness")).toEqual(true)
				expect(effective(look, "ExposureCompensation") >= effective(plain, "ExposureCompensation")).toEqual(true)
			end)

			it("keeps every channel of the ambient light at or above the plain Night", function()
				for _, field in ipairs({ "Ambient", "OutdoorAmbient" }) do
					for channel = 1, 3 do
						expect(look[field][channel] >= plain[field][channel]).toEqual(true)
					end
				end
			end)

			it("reads blue-violet: blue over red over green in the fog, blue over the rest in the ambient light", function()
				local fog = look.Atmosphere.Color
				expect(fog[3] > fog[1] and fog[1] > fog[2]).toEqual(true)
				for _, field in ipairs({ "Ambient", "OutdoorAmbient" }) do
					expect(look[field][3] > look[field][1] and look[field][3] > look[field][2]).toEqual(true)
				end
			end)

			it("is more saturated than the plain Night, with a warmer tint and bloom on", function()
				expect(look.ColorCorrection.Saturation > plain.ColorCorrection.Saturation).toEqual(true)
				-- warmer: the red share of the tint (against blue) is higher than the plain row's
				local tint, was = look.ColorCorrection.TintColor, plain.ColorCorrection.TintColor
				expect(tint[1] / tint[3] > was[1] / was[3]).toEqual(true)
				expect(look.Bloom.Intensity > 0).toEqual(true)
			end)
		end)
	end

	it("gives the Forest the stronger version of the Meadow's", function()
		expect(forest.Atmosphere.Density > meadow.Atmosphere.Density).toEqual(true)
		expect(forest.Atmosphere.Offset > meadow.Atmosphere.Offset).toEqual(true)
		expect(forest.Atmosphere.Haze > meadow.Atmosphere.Haze).toEqual(true)
		expect(forest.Bloom.Intensity > meadow.Bloom.Intensity).toEqual(true)
		expect(forest.Bloom.Threshold < meadow.Bloom.Threshold).toEqual(true)
		expect(forest.ColorCorrection.Saturation > meadow.ColorCorrection.Saturation).toEqual(true)
		expect(forest.OutdoorAmbient[3] > meadow.OutdoorAmbient[3]).toEqual(true)
	end)

	it("names only real conditions, worlds and biomes", function()
		for worldId, rows in pairs(Lighting.WorldConditions) do
			expect(Worlds[worldId] ~= nil).toEqual(true)
			for name in pairs(rows) do
				expect(Lighting.Conditions[name] ~= nil).toEqual(true)
			end
		end
		for biome, rows in pairs(Lighting.BiomeConditions) do
			local known = false
			for _, world in pairs(Worlds) do
				if table.find(world.biomes, biome) ~= nil then
					known = true
				end
			end
			expect(known).toEqual(true)
			for name in pairs(rows) do
				expect(Lighting.Conditions[name] ~= nil).toEqual(true)
			end
		end
	end)
end)
return true
