--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.OverlayMath)
local Data = require(Shared.data.Overlays)
local F = require(script.Parent.Fixtures)
local window = Data.LaunchWindow
local day = window.endsAt - window.startsAt
describe("OverlayMath launch window", function()
	it("opens at startsAt and closes at endsAt, both on UTC dates", function()
		expect(os.date("!%Y-%m-%d %H:%M", window.startsAt)).toEqual("2026-10-16 00:00")
		expect(os.date("!%Y-%m-%d %H:%M", window.endsAt)).toEqual("2026-10-26 00:00")
		expect(Math.LaunchActive(window.startsAt - F.one)).toEqual(false)
		expect(Math.LaunchActive(window.startsAt)).toEqual(true)
		expect(Math.LaunchActive(window.endsAt - F.one)).toEqual(true)
		expect(Math.LaunchActive(window.endsAt)).toEqual(false)
		expect(Math.LaunchActive(F.zero)).toEqual(false)
		expect(Math.LaunchActive(window.endsAt + day * F.two)).toEqual(false)
	end)
	it("rolls LaunchGold inside the window only, below the chance", function()
		local middle = window.startsAt + (window.endsAt - window.startsAt) // F.two
		expect(Math.LaunchPick(middle, F.zero)).toEqual("LaunchGold")
		expect(Math.LaunchPick(middle, window.chance - F.half)).toEqual("LaunchGold")
		expect(Math.LaunchPick(middle, window.chance)).toEqual(nil)
		expect(Math.LaunchPick(middle, window.chance * F.two)).toEqual(nil)
		-- a winning roll before the window or at and after its end rolls nothing: the overlay never exists outside it
		expect(Math.LaunchPick(window.startsAt - F.one, F.zero)).toEqual(nil)
		expect(Math.LaunchPick(window.endsAt, F.zero)).toEqual(nil)
		expect(Math.LaunchPick(window.endsAt + day, F.zero)).toEqual(nil)
		expect(Math.LaunchPick(F.zero, F.zero)).toEqual(nil)
	end)
	it("is a visible but uncommon share, named in the data, and never part of the usual roll", function()
		expect(window.chance > F.two and window.chance < F.two * F.two * F.two).toEqual(true) -- about 1 in 25
		expect(Data.Overlays[window.overlay] ~= nil).toEqual(true)
		expect(table.find(Data.Order, window.overlay) ~= nil).toEqual(true)
		expect(Data.Overlays[window.overlay].chance).toEqual(F.zero)
		expect(Data.Overlays[window.overlay].multiplier).toEqual(Data.Overlays.Gold.multiplier)
		local total = F.zero
		for _, name in ipairs(Data.Order) do
			total += Data.Overlays[name].chance
		end
		expect(total + window.chance < 100).toEqual(true) -- the usual odds and the launch share both fit under 100 percent
	end)
	it("ranks LaunchGold above every other overlay", function()
		local rank = table.find(Data.Order, window.overlay)
		expect(rank).toEqual(#Data.Order)
	end)
end)
describe("OverlayMath usual roll", function()
	it("walks the Order chances end to end and never returns the launch overlay", function()
		local acc = F.zero
		for _, name in ipairs(Data.Order) do
			local chance = Data.Overlays[name].chance
			if chance > F.zero then
				expect(Math.Pick(acc)).toEqual(name)
				expect(Math.Pick(acc + chance / F.two)).toEqual(name)
			end
			acc += chance
		end
		expect(Math.Pick(acc)).toEqual("None")
		expect(Math.Pick(99.99)).toEqual("None")
		for roll = F.zero, 99 do
			expect(Math.Pick(roll) ~= window.overlay).toEqual(true)
		end
	end)
	it("matches the shipped odds at the edges", function()
		expect(Math.Pick(F.zero)).toEqual("Shiny")
		expect(Math.Pick(Data.Overlays.Shiny.chance)).toEqual("Gold")
		expect(Math.Pick(Data.Overlays.Shiny.chance + Data.Overlays.Gold.chance)).toEqual("Crystal")
	end)
end)
return true
