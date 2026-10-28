--!strict
-- Shared.RadarMath and data/Radar (Decision B52): the radar column lists the wild aliens within the tier's range, nearest first,
-- up to the tier's slot count (Mk1 5, Mk2 7, Mk3 9); each is the black shadow of its species until the player has caught one;
-- a Secret is never listed; a Scanner Pulse lifts the range to the whole biome and works without a radar. The widget itself
-- (Client.UI.RadarColumn) needs Roblox; the choices it makes are these functions.
local Shared = game:GetService("ReplicatedStorage").Shared
local RadarMath = require(Shared.RadarMath)
local Radar = require(Shared.data.Radar)
local Look = require(Shared.data.RadarScroll)

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

describe("RadarMath: the scroll's layout (Decision B57, data/RadarScroll)", function()
	local roller, pad, pitch = Look.RollerHeight, Look.Pad, Look.SlotPitch
	-- The chip stack (place, event, Friend: data/Hud Chips) ends at 0.025 + 0.075 + 0.008 + 0.048 + 0.008 + 0.055 = 0.219; the Catch
	-- button's top is at 0.96 - 0.13 = 0.83 (Hud.luau).
	local CHIPS_BOTTOM, CATCH_TOP = 0.219, 0.96 - 0.13
	local SE, IPAD = { w = 667, h = 375 }, { w = 1080, h = 810 }
	it("is as tall as its slots need: two rollers, two pads and a pitch per slot, nothing for none", function()
		expect(RadarMath.ScrollHeight(0, roller, pad, pitch)).toEqual(0)
		expect(RadarMath.ScrollHeight(-2, roller, pad, pitch)).toEqual(0)
		local five = RadarMath.ScrollHeight(5, roller, pad, pitch)
		assert(math.abs(five - (2 * roller + 2 * pad + 5 * pitch)) < 1e-9, "five slots are " .. five)
		assert(RadarMath.ScrollHeight(9, roller, pad, pitch) > five, "nine slots are not taller than five")
	end)
	it("stands under the chip stack and clear of the Catch button with the most slots a tier or the pulse can show", function()
		local most = math.max(Radar[3].slots, Radar.Pulse.slots)
		local bottom = Look.Top + RadarMath.ScrollHeight(most, roller, pad, pitch)
		assert(Look.Top >= CHIPS_BOTTOM, "the scroll starts at " .. Look.Top .. ", over the chip stack")
		assert(bottom <= CATCH_TOP - 0.01, "the scroll ends at " .. bottom .. ", too near the Catch button at " .. CATCH_TOP)
		assert(Look.X <= 1 and Look.X - Look.Width > 0.5, "the scroll leaves the right edge")
	end)
	it("gives slots equal spacing, the first under the top roller and its pad, the last inside the bottom pad", function()
		local first = RadarMath.SlotTop(1, Look.Top, roller, pad, pitch)
		assert(math.abs(first - (Look.Top + roller + pad)) < 1e-9, "first slot is at " .. first)
		for index = 2, 9 do
			local gap = RadarMath.SlotTop(index, Look.Top, roller, pad, pitch) - RadarMath.SlotTop(index - 1, Look.Top, roller, pad, pitch)
			assert(math.abs(gap - pitch) < 1e-9, "slot " .. index .. " is " .. gap .. " from the one above")
		end
		local last = RadarMath.SlotTop(5, Look.Top, roller, pad, pitch) + pitch
		local bottom = Look.Top + RadarMath.ScrollHeight(5, roller, pad, pitch)
		assert(math.abs(last + pad + roller - bottom) < 1e-9, "the last slot does not end at the bottom pad")
	end)
	it("keeps the picture inside its slot and the roll as wide as the sheet or wider", function()
		assert(Look.ArtHeight <= pitch, "the art box is taller than its slot")
		assert(Look.RollerOverhang >= 1, "the roller is narrower than the paper")
		assert(Look.CornerScale > 0 and Look.CornerScale <= 0.5, "corner scale " .. Look.CornerScale)
		assert(Look.GroundCentre + Look.GroundHeight / 2 <= 1, "the ground shadow leaves its slot")
	end)
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		it(label .. ": a picture is 19 px or more and fits the sheet's width, and a slot has room for the picture", function()
			local art = Look.ArtHeight * screen.h
			assert(art >= 19, "the picture is " .. art .. " px")
			assert(art <= Look.Width * screen.w, "the picture is wider than the sheet")
			assert(pitch * screen.h >= art, "the slot is shorter than the picture")
		end)
	end
	it("has a short unroll and a short fade (the brief: 0.35 s and 0.2 s)", function()
		expect(Look.UnrollSeconds).toEqual(0.35)
		expect(Look.FadeSeconds).toEqual(0.2)
	end)
end)

describe("RadarMath.Reveal", function()
	local roller, pad, pitch = Look.RollerHeight, Look.Pad, Look.SlotPitch
	local top = RadarMath.SlotTop(2, Look.Top, roller, pad, pitch)
	it("uncovers a slot as the paper's lower edge passes it, top-down", function()
		-- Paper ending at or above the slot's top (plus the bottom roller and pad) shows none of it.
		assert(math.abs(RadarMath.Reveal(top, pitch, top + roller + pad, roller, pad)) < 1e-9, "paper at the slot's top reveals some")
		expect(RadarMath.Reveal(top, pitch, top - 1, roller, pad)).toEqual(0)
		-- Half a pitch of paper past that shows half the slot; a full pitch (or more) all of it.
		local half = RadarMath.Reveal(top, pitch, top + roller + pad + pitch / 2, roller, pad)
		assert(math.abs(half - 0.5) < 1e-9, "half is " .. half)
		local whole = RadarMath.Reveal(top, pitch, top + roller + pad + pitch, roller, pad)
		assert(math.abs(whole - 1) < 1e-9, "a full pitch of paper reveals " .. whole)
		expect(RadarMath.Reveal(top, pitch, 5, roller, pad)).toEqual(1)
	end)
	it("shows the lower slots later than the upper ones", function()
		local bottom = Look.Top + 0.2
		local a = RadarMath.Reveal(RadarMath.SlotTop(1, Look.Top, roller, pad, pitch), pitch, bottom, roller, pad)
		local b = RadarMath.Reveal(RadarMath.SlotTop(4, Look.Top, roller, pad, pitch), pitch, bottom, roller, pad)
		assert(a >= b, "the first slot is less revealed than the fourth")
	end)
end)

describe("RadarMath.Approach and FadeStep", function()
	it("moves toward the target by at most the step and never past it", function()
		expect(RadarMath.Approach(0, 1, 0.25)).toEqual(0.25)
		expect(RadarMath.Approach(0.9, 1, 0.25)).toEqual(1)
		expect(RadarMath.Approach(1, 0, 0.4)).toEqual(0.6)
		expect(RadarMath.Approach(0.1, 0, 0.4)).toEqual(0)
		expect(RadarMath.Approach(0.5, 0.5, 0.4)).toEqual(0.5)
	end)
	it("takes the whole fade length to cross 0 to 1 and jumps when there is no time to spend", function()
		local alpha, frames = 0, 0
		while alpha < 1 and frames < 100 do
			alpha = RadarMath.Approach(alpha, 1, RadarMath.FadeStep(1 / 60, Look.FadeSeconds))
			frames += 1
		end
		assert(frames >= 11 and frames <= 13, "a 0.2 s fade took " .. frames .. " frames at 60 fps")
		expect(RadarMath.FadeStep(0.016, 0)).toEqual(1)
		expect(RadarMath.FadeStep(-1, 0.2)).toEqual(0)
	end)
end)

describe("RadarMath.SlotPlan", function()
	it("fades a new alien in at once on an empty slot", function()
		local goal, swap = RadarMath.SlotPlan(nil, true, "Mossbop", true, 0)
		expect(goal).toEqual(1)
		expect(swap).toEqual(true)
	end)
	it("leaves a slot alone while it already shows what is wanted, fully visible", function()
		local goal, swap = RadarMath.SlotPlan("Mossbop", true, "Mossbop", true, 1)
		expect(goal).toEqual(1)
		expect(swap).toEqual(false)
	end)
	it("fades the old picture out first when another alien takes the place, and swaps only once it is invisible", function()
		local goal, swap = RadarMath.SlotPlan("Mossbop", true, "Puffpuff", true, 1)
		expect(goal).toEqual(0)
		expect(swap).toEqual(false)
		goal, swap = RadarMath.SlotPlan("Mossbop", true, "Puffpuff", true, 0.3)
		expect(goal).toEqual(0)
		expect(swap).toEqual(false)
		goal, swap = RadarMath.SlotPlan("Mossbop", true, "Puffpuff", true, 0)
		expect(goal).toEqual(1)
		expect(swap).toEqual(true)
	end)
	it("treats the shadow turning into the face (the same species caught) as a change", function()
		local goal, swap = RadarMath.SlotPlan("Mossbop", true, "Mossbop", false, 1)
		expect(goal).toEqual(0)
		expect(swap).toEqual(false)
	end)
	it("fades a picture out when nothing is wanted any more, and then rests empty", function()
		local goal, swap = RadarMath.SlotPlan("Mossbop", true, nil, true, 1)
		expect(goal).toEqual(0)
		expect(swap).toEqual(false)
		goal, swap = RadarMath.SlotPlan("Mossbop", true, nil, true, 0)
		expect(goal).toEqual(0)
		expect(swap).toEqual(true) -- the picture is emptied while invisible
		goal, swap = RadarMath.SlotPlan(nil, true, nil, true, 0)
		expect(goal).toEqual(0)
		expect(swap).toEqual(false)
	end)
end)

return true
