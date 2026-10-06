--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.FusionMath)
local Data = require(Shared.data.Fusion)
local Species = require(Shared.data.Species)
local Sizes = require(Shared.data.Sizes)
local F = require(script.Parent.Fixtures)
local cap = F.one + Data.MaxFusionLevels
local function copies(count, level)
	local result = {}
	for index = F.one, count do
		table.insert(result, { uid = tostring(index), species = Species.List[F.one].id,
			level = level or F.one, overlay = "None", size = Sizes.Default,
			workedSeconds = F.zero, caughtAt = F.zero })
	end
	return result
end
describe("FusionMath", function()
	it("NotEnough precedes MaxLevel when total copies are short", function()
		local kept, consumed, reason = Math.Select(copies(Data.DuplicatesPerLevel, cap), {}, cap)
		expect(kept).toEqual(nil)
		expect(#consumed).toEqual(F.zero)
		expect(reason).toEqual("NotEnough")
	end)
	it("MaxLevel when all copies are capped", function()
		local kept, _, reason = Math.Select(copies(Data.DuplicatesPerLevel + F.one, cap), {}, cap)
		expect(kept).toEqual(nil)
		expect(reason).toEqual("MaxLevel")
	end)
	it("capped copy above four plain copies refuses without mutation", function()
		local rows = copies(Data.DuplicatesPerLevel + F.one)
		rows[F.one].level = cap
		local kept, consumed, reason = Math.Select(rows, {}, cap)
		expect(kept).toEqual(nil)
		expect(reason).toEqual("NotEnough")
		expect(#consumed).toEqual(F.zero)
		expect(#rows).toEqual(Data.DuplicatesPerLevel + F.one)
		expect(rows[F.one].level).toEqual(cap)
	end)
	it("five plain copies under a capped copy keep the first eligible", function()
		local rows = copies(Data.DuplicatesPerLevel + F.two)
		rows[F.one].level = cap
		local kept, consumed, reason = Math.Select(rows, {}, cap)
		expect(kept).toEqual(rows[F.two])
		expect(reason).toEqual(nil)
		expect(#consumed).toEqual(Data.DuplicatesPerLevel)
		for index, row in ipairs(consumed) do
			expect(row).toEqual(rows[#rows - index + F.one])
			expect(row.level).toEqual(F.one)
		end
		expect(kept.level).toEqual(F.one)
	end)
	for _, kind in ipairs({ "seated", "companion", "habitat" }) do
		it("resting before " .. kind .. ", then second pass", function()
			local rows = copies(Data.DuplicatesPerLevel + F.two)
			local last = rows[#rows]
			local companions = {}
			if kind == "seated" then last.station = "Builder"
			elseif kind == "habitat" then last.habitat = "display"
			else table.insert(companions, last.uid) end
			local kept, consumed = Math.Select(rows, companions, cap)
			expect(kept).toEqual(rows[F.one])
			expect(table.find(consumed, last)).toEqual(nil)
			table.remove(rows, F.two)
			local _, second = Math.Select(rows, companions, cap)
			expect(second[#second]).toEqual(last)
			expect(#second).toEqual(Data.DuplicatesPerLevel)
		end)
	end
	it("ConsumeRestingFirst false follows reverse rank without duplicates", function()
		local rows = copies(Data.DuplicatesPerLevel + F.two)
		rows[#rows].station = "Builder"
		local previous = Data.ConsumeRestingFirst
		Data.ConsumeRestingFirst = false
		local kept, consumed = Math.Select(rows, {}, cap)
		Data.ConsumeRestingFirst = previous
		expect(kept).toEqual(rows[F.one])
		for index, row in ipairs(consumed) do
			expect(row).toEqual(rows[#rows - index + F.one])
		end
	end)
end)
return true
