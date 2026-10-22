--!strict
-- The Moonlit Forest night (data/Lighting WorldConditions and BiomeConditions): the colour goes teal and violet (lifted
-- 2026-10-22 so it is never one flat navy), and nothing becomes harder to see than the plain Night row it refines (the catch bar
-- and the wild aliens stay readable). The merge itself is LightingDirector's; these tests read the data rows it merges.
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

			it("reads cool, not navy: blue is the strongest channel of the fog and the ambient light, and no channel of the ambient is dark", function()
				local fog = look.Atmosphere.Color
				expect(fog[3] > fog[1] and fog[3] > fog[2]).toEqual(true)
				for _, field in ipairs({ "Ambient", "OutdoorAmbient" }) do
					expect(look[field][3] > look[field][1] and look[field][3] > look[field][2]).toEqual(true)
					-- the 2026-10-22 night pass (job 53 step 5): a surface is its colour times the ambient, so none of the three channels
					-- may sit near zero (the old rows had a red of 46 and a green of 46 against a blue of 84)
					for channel = 1, 3 do
						expect(look[field][channel] >= 70).toEqual(true)
					end
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

	describe("night ground tint (the grass joins the teal)", function()
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

		it("is cool teal or violet (blue over red and over green) and stronger in the Forest than in the Meadow", function()
			for _, look in ipairs({ meadow, forest }) do
				local color = look.groundTint.color
				expect(color[3] > color[1] and color[3] > color[2]).toEqual(true)
			end
			expect(forest.groundTint.strength > meadow.groundTint.strength).toEqual(true)
		end)

		it("keeps the Forest patch a colour with some light in it, never the old navy (job 53 step 5: 36486B)", function()
			local night = lerp(forestPatch, forest.groundTint.color, forest.groundTint.strength)
			expect(luma(night) >= 60).toEqual(true)
			-- teal-green: green over red, and the blue not above the green by more than a third
			expect(night[2] > night[1] and night[3] < night[2] * 1.34).toEqual(true)
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

-- The lamp cap and the night lift (data/Lighting Lamps, client World/LampDirector): a phone never lights every lamp, and a lamp at
-- night is stronger than by day (2026-10-22, Mac job 53 step 5: the lanterns were unlit white blocks).
describe("Lamps", function()
	local Lamps = Lighting.Lamps
	local Kit = require(Shared.data.WorldKit)

	it("caps the lit lamps, fewer on a phone, inside the lights each world builds", function()
		expect(Lamps.MaxLit >= 1 and Lamps.MaxLitTouch >= 1).toEqual(true)
		expect(Lamps.MaxLitTouch <= Lamps.MaxLit).toEqual(true)
		expect(Lamps.MaxLit <= 16).toEqual(true)
		expect(Lamps.MaxLit < Kit.Budget.lights).toEqual(true)
	end)

	it("lifts a lamp at night and fades the pick over a moment", function()
		expect(Lamps.NightBrightnessScale > 1 and Lamps.NightRangeScale > 1).toEqual(true)
		expect(Lamps.FadeSeconds > 0 and Lamps.CheckSeconds > 0 and Lamps.Radius > 0).toEqual(true)
		expect(type(Lamps.Tag) == "string" and #Lamps.Tag > 0).toEqual(true)
	end)

	it("lights the lanterns warm: the lamp cell and the light are yellow-orange, red over green over blue", function()
		local function rgb(hex: string): { number }
			return { tonumber(hex:sub(1, 2), 16) :: number, tonumber(hex:sub(3, 4), 16) :: number, tonumber(hex:sub(5, 6), 16) :: number }
		end
		for _, name in ipairs({ "PathLantern", "Lantern" }) do
			local recipe = Kit.Recipes[name]
			local light = rgb(recipe.light.color)
			expect(light[1] > light[2] and light[2] > light[3]).toEqual(true)
			local lamp = nil
			for _, box in ipairs(recipe.boxes) do
				if box.neon then
					lamp = rgb(box.color)
				end
			end
			expect(lamp ~= nil).toEqual(true)
			expect(lamp[1] > lamp[2] and lamp[2] > lamp[3]).toEqual(true)
			-- not white: the blue channel is well under the red
			expect(lamp[3] < lamp[1] * 0.6).toEqual(true)
		end
	end)
end)

-- Frostbyte's aurora night (2026-10-21 worlds pass): teal from above, never darker than the plain Night.
describe("Frostbyte aurora night", function()
	local aurora = Lighting.WorldConditions[2].Night
	it("keeps every ambient channel at or above the plain Night and leaves brightness alone", function()
		for _, field in ipairs({ "Ambient", "OutdoorAmbient" }) do
			for channel = 1, 3 do
				expect(aurora[field][channel] >= plain[field][channel]).toEqual(true)
			end
		end
		expect(aurora.Brightness == nil and aurora.ExposureCompensation == nil).toEqual(true)
	end)
	it("lights the tops green-teal, not white", function()
		local top = aurora.ColorShift_Top
		expect(top[2] > top[1] and top[2] > top[3]).toEqual(true)
	end)
end)
return true
