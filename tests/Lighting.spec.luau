--!strict
-- The Moonlit Forest night (data/Lighting WorldConditions and BiomeConditions): the colour goes indigo, violet and
-- teal, and nothing becomes harder to see than the plain Night row it refines (the catch bar and the wild aliens stay
-- readable). The merge itself is LightingDirector's; these tests read the data rows it merges.
local Shared = game:GetService("ReplicatedStorage").Shared
local Lighting = require(Shared.data.Lighting)
local Worlds = require(Shared.data.Worlds)
local Meadow = require(Shared.data.Meadow)

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

	describe("night ground tint (the grass joins the indigo)", function()
		-- A part colour from its hex, and the lerp the director does (Color3:Lerp) on whole 0..255 channels.
		local function rgb(hex: string): { number }
			return { tonumber(hex:sub(1, 2), 16) :: number, tonumber(hex:sub(3, 4), 16) :: number, tonumber(hex:sub(5, 6), 16) :: number }
		end
		local function lerp(from: { number }, to: { number }, strength: number): { number }
			return { from[1] + (to[1] - from[1]) * strength, from[2] + (to[2] - from[2]) * strength, from[3] + (to[3] - from[3]) * strength }
		end
		local function luma(c: { number }): number
			return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
		end
		local function greenShare(c: { number }): number
			return c[2] / (c[1] + c[2] + c[3])
		end
		local meadowFloor = rgb(Meadow.FloorColor)
		local forestPatch = rgb(Meadow.Regions.Forest.floorColor)

		it("is named by the two World 1 night rows and nowhere else, so day and World 2 keep their ground", function()
			expect(meadow.groundTint ~= nil).toEqual(true)
			expect(forest.groundTint ~= nil).toEqual(true)
			for _, look in pairs(Lighting.Conditions) do
				expect(look.groundTint == nil).toEqual(true)
			end
			for _, look in pairs(Lighting.Worlds) do
				expect(look.groundTint == nil).toEqual(true)
			end
			expect(Lighting.Base.groundTint == nil).toEqual(true)
			expect(type(Lighting.GroundTag) == "string" and #Lighting.GroundTag > 0).toEqual(true)
		end)

		it("is a whole tint: a triple of whole 0..255 channels and a strength above 0 and at most 1", function()
			for _, look in ipairs({ meadow, forest }) do
				local tint = look.groundTint
				for channel = 1, 3 do
					expect(tint.color[channel] >= 0 and tint.color[channel] <= 255 and tint.color[channel] % 1 == 0).toEqual(true)
				end
				expect(tint.strength > 0 and tint.strength <= 1).toEqual(true)
			end
		end)

		it("is indigo (blue over red, blue over green) and stronger in the Forest than in the Meadow", function()
			for _, look in ipairs({ meadow, forest }) do
				local color = look.groundTint.color
				expect(color[3] > color[1] and color[3] > color[2]).toEqual(true)
			end
			expect(forest.groundTint.strength > meadow.groundTint.strength).toEqual(true)
		end)

		it("turns the Meadow floor and the Forest patch less green, bluer and no lighter than by day", function()
			for _, case in ipairs({ { meadowFloor, meadow.groundTint }, { forestPatch, forest.groundTint }, { meadowFloor, forest.groundTint } }) do
				local day, tint = case[1], case[2]
				local night = lerp(day, tint.color, tint.strength)
				expect(greenShare(night) < greenShare(day)).toEqual(true)
				expect(night[3] > day[3]).toEqual(true)
				expect(luma(night) < luma(day)).toEqual(true)
			end
		end)
	end)

	describe("place-level engine settings (LightingStyle supersedes Technology)", function()
		it("names a real LightingStyle item, Realistic by default", function()
			expect(Lighting.Style == "Realistic" or Lighting.Style == "Soft").toEqual(true)
			expect(Lighting.Style).toEqual("Realistic")
		end)

		it("prioritizes lighting quality with a real boolean", function()
			expect(type(Lighting.PrioritizeLightingQuality)).toEqual("boolean")
			expect(Lighting.PrioritizeLightingQuality).toEqual(true)
		end)

		it("keeps Technology as the fallback for older clients, and keeps these out of the tweened looks", function()
			expect(Lighting.Technology).toEqual("Future")
			for _, field in ipairs({ "Style", "PrioritizeLightingQuality", "Technology" }) do
				expect(Lighting.Base[field] == nil).toEqual(true)
			end
		end)
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
