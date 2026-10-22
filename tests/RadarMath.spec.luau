--!strict
-- Shared.RadarMath and data/Radar (Decision B52): the radar column lists the wild aliens within the tier's range, nearest first,
-- up to the tier's slot count (Mk1 5, Mk2 7, Mk3 9); each is the black shadow of its species until the player has caught one;
-- a Secret is never listed; a Scanner Pulse lifts the range to the whole biome and works without a radar. The widget itself
-- (Client.UI.RadarColumn) needs Roblox; the choices it makes are these functions.
local Shared = game:GetService("ReplicatedStorage").Shared
local RadarMath = require(Shared.RadarMath)
local Radar = require(Shared.data.Radar)

local function offerAll(limit: number, distances: { number }): ({ number }, { string }, number)
	local ds: { number } = {}
	local names: { string } = {}
	local count = 0
	for index, distance in ipairs(distances) do
		count = RadarMath.Offer(ds, names, count, limit, distance, "a" .. index)
	end
	return ds, names, count
end

describe("data/Radar", function()
	it("gives Mk1 5 slots, Mk2 7 and Mk3 9, nothing at tier 0", function()
		expect(Radar[0].slots).toEqual(0)
		expect(Radar[1].slots).toEqual(5)
		expect(Radar[2].slots).toEqual(7)
		expect(Radar[3].slots).toEqual(9)
	end)
	it("widens range and slots with every tier", function()
		for tier = 1, 3 do
			assert(Radar[tier].range > Radar[tier - 1].range, "range does not grow at tier " .. tier)
			assert(Radar[tier].slots > Radar[tier - 1].slots, "slots do not grow at tier " .. tier)
			assert(Radar[tier].scrap > Radar[tier - 1].scrap, "price does not grow at tier " .. tier)
		end
	end)
	it("keeps Mk1's price and unlock (1,500 Scrap after Field Notes 2)", function()
		expect(Radar[1].scrap).toEqual(1500)
		expect(Radar[1].unlock).toEqual("FieldNotes2")
		expect(Radar[1].range).toEqual(120)
	end)
	it("lets a Scanner Pulse list at least as many aliens as the best tier", function()
		assert(Radar.Pulse.slots >= Radar[3].slots, "the pulse column is shorter than Mk3's")
	end)
end)

describe("RadarMath.Offer", function()
	it("sorts nearest first", function()
		local ds, names, count = offerAll(5, { 40, 10, 30, 20 })
		expect(count).toEqual(4)
		expect(ds[1]).toEqual(10)
		expect(ds[2]).toEqual(20)
		expect(ds[3]).toEqual(30)
		expect(ds[4]).toEqual(40)
		expect(names[1]).toEqual("a2")
		expect(names[4]).toEqual("a1")
	end)
	it("keeps only the nearest `limit` when more arrive", function()
		local ds, names, count = offerAll(3, { 50, 10, 90, 30, 20, 70 })
		expect(count).toEqual(3)
		expect(ds[1]).toEqual(10)
		expect(ds[2]).toEqual(20)
		expect(ds[3]).toEqual(30)
		expect(names[1]).toEqual("a2")
		expect(names[2]).toEqual("a5")
		expect(names[3]).toEqual("a4")
	end)
	it("drops a farther alien once the list is full and lets a nearer one in", function()
		local ds: { number } = {}
		local names: { string } = {}
		local count = 0
		for index = 1, 5 do
			count = RadarMath.Offer(ds, names, count, 5, index * 10, "n" .. index)
		end
		count = RadarMath.Offer(ds, names, count, 5, 60, "far")
		expect(count).toEqual(5)
		expect(names[5]).toEqual("n5")
		count = RadarMath.Offer(ds, names, count, 5, 5, "near")
		expect(count).toEqual(5)
		expect(names[1]).toEqual("near")
		expect(names[2]).toEqual("n1")
		expect(names[5]).toEqual("n4")
	end)
	it("keeps the earlier of two equal distances first", function()
		local _, names, count = offerAll(5, { 25, 25, 25 })
		expect(count).toEqual(3)
		expect(names[1]).toEqual("a1")
		expect(names[2]).toEqual("a2")
		expect(names[3]).toEqual("a3")
	end)
	it("lists nothing with no slots", function()
		local _, _, count = offerAll(0, { 1, 2, 3 })
		expect(count).toEqual(0)
	end)
	it("ends with the same order whatever order the aliens arrive in", function()
		local forward = { 12, 80, 33, 5, 61, 47, 90, 21, 70 }
		local backward: { number } = {}
		for index = #forward, 1, -1 do
			table.insert(backward, forward[index])
		end
		local a = offerAll(7, forward)
		local b = offerAll(7, backward)
		for index = 1, 7 do
			expect(a[index]).toEqual(b[index])
		end
		for index = 2, 7 do
			assert(a[index - 1] <= a[index], "not ascending at " .. index)
		end
	end)
end)

describe("RadarMath.Reaches", function()
	it("lists an alien inside the range and not one outside", function()
		expect(RadarMath.Reaches(100, 120, false, true)).toEqual(true)
		expect(RadarMath.Reaches(120, 120, false, true)).toEqual(true)
		expect(RadarMath.Reaches(121, 120, false, true)).toEqual(false)
	end)
	it("lists nothing with no radar", function()
		expect(RadarMath.Reaches(0, 0, false, true)).toEqual(false)
		expect(RadarMath.Reaches(5, 0, false, true)).toEqual(false)
	end)
	it("lets a Scanner Pulse list the whole biome and only the biome, even with no radar", function()
		expect(RadarMath.Reaches(900, 0, true, true)).toEqual(true)
		expect(RadarMath.Reaches(900, 120, true, true)).toEqual(true)
		expect(RadarMath.Reaches(900, 0, true, false)).toEqual(false)
		expect(RadarMath.Reaches(50, 120, true, false)).toEqual(true) -- the ordinary range still holds in another biome
	end)
end)

describe("RadarMath.Slots", function()
	it("is the tier's slot count", function()
		expect(RadarMath.Slots(Radar[0].slots, false, Radar.Pulse.slots)).toEqual(0)
		expect(RadarMath.Slots(Radar[1].slots, false, Radar.Pulse.slots)).toEqual(5)
		expect(RadarMath.Slots(Radar[2].slots, false, Radar.Pulse.slots)).toEqual(7)
		expect(RadarMath.Slots(Radar[3].slots, false, Radar.Pulse.slots)).toEqual(9)
	end)
	it("gives a Scanner Pulse its own slots with no radar and never fewer than the tier's", function()
		expect(RadarMath.Slots(0, true, Radar.Pulse.slots)).toEqual(Radar.Pulse.slots)
		expect(RadarMath.Slots(9, true, 6)).toEqual(9)
	end)
	it("is never negative", function()
		expect(RadarMath.Slots(-3, false, 9)).toEqual(0)
	end)
end)

describe("RadarMath.Shadowed", function()
	it("is a shadow for a species the player has not caught", function()
		expect(RadarMath.Shadowed(nil)).toEqual(true)
		expect(RadarMath.Shadowed(0)).toEqual(true)
	end)
	it("is the real model once one is caught", function()
		expect(RadarMath.Shadowed(1)).toEqual(false)
		expect(RadarMath.Shadowed(14)).toEqual(false)
	end)
end)

describe("RadarMath.TierListed", function()
	it("never lists a Secret, however near", function()
		expect(RadarMath.TierListed("Secret")).toEqual(false)
	end)
	it("lists every other tier", function()
		for _, name in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic" }) do
			expect(RadarMath.TierListed(name)).toEqual(true)
		end
	end)
end)

describe("RadarMath.Flat", function()
	it("ignores height: it is the XZ distance of an offset", function()
		expect(RadarMath.Flat(3, 4)).toEqual(5)
		expect(RadarMath.Flat(-6, 8)).toEqual(10)
		expect(RadarMath.Flat(0, 0)).toEqual(0)
	end)
end)

return true
