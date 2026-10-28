--!strict
-- Shared/ArrivalTitleMath: the speed lines (count, rows, lengths, flights, thirds, determinism), the timeline with and without Reduced
-- Motion, the name's size at the width limit (iPhone SE and iPad), and which joins play a card.
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.ArrivalTitleMath)
local Cinematics = require(Shared.data.Cinematics)

local Title = Cinematics.Title

describe("ArrivalTitleMath Lines", function()
	local lines = Math.Lines()
	it("draws the configured number of lines, in start order", function()
		expect(#lines).toEqual(Title.Lines.Count)
		for index = 2, #lines do
			expect(lines[index].delay >= lines[index - 1].delay).toEqual(true)
		end
	end)
	it("keeps every length, flight and start inside its range", function()
		local d = Title.Lines
		for _, line in ipairs(lines) do
			expect(line.cells >= d.MinCells and line.cells <= d.MaxCells).toEqual(true)
			expect(line.cells).toEqual(math.floor(line.cells))
			expect(line.seconds >= d.MinSeconds and line.seconds <= d.MaxSeconds).toEqual(true)
			expect(line.delay >= 0 and line.delay <= d.StaggerSeconds).toEqual(true)
			expect(line.row >= d.RowMin and line.row <= d.RowMax).toEqual(true)
			expect(line.side == -1 or line.side == 1).toEqual(true)
		end
	end)
	it("finishes inside the card: the last line lands before the hold ends", function()
		for _, line in ipairs(lines) do
			expect(line.delay + line.seconds <= Title.TotalSeconds).toEqual(true)
		end
	end)
	it("sends two thirds to the outer thirds and the rest to the middle, far from the title's rows", function()
		local inner = 0
		for _, line in ipairs(lines) do
			if line.inner then
				inner += 1
				expect(line.travel).toEqual(Title.Lines.InnerTravel)
				expect(math.abs(line.row - 0.5) >= 0.3).toEqual(true)
			else
				expect(line.travel).toEqual(Title.Lines.OuterTravel)
				expect(line.travel <= 1 / 3).toEqual(true)
			end
		end
		expect(inner).toEqual(Title.Lines.InnerCount)
		expect((#lines - inner) / #lines >= 2 / 3 - 1e-9).toEqual(true)
	end)
	it("alternates the edges and gives every row to one line", function()
		local left, right = 0, 0
		local rows: { [number]: boolean } = {}
		for _, line in ipairs(lines) do
			if line.side < 0 then
				left += 1
			else
				right += 1
			end
			expect(rows[line.row]).toEqual(nil)
			rows[line.row] = true
		end
		expect(left).toEqual(right)
	end)
	it("is the same every time", function()
		local again = Math.Lines()
		for index, line in ipairs(lines) do
			expect(again[index].cells).toEqual(line.cells)
			expect(again[index].row).toEqual(line.row)
			expect(again[index].delay).toEqual(line.delay)
		end
	end)
end)

describe("ArrivalTitleMath Timeline", function()
	it("is in, hold, out, and its total is the data's total (the quiet window)", function()
		local t = Math.Timeline(false)
		expect(math.abs(t.total - (t.inSeconds + t.holdSeconds + t.outSeconds)) < 1e-9).toEqual(true)
		expect(math.abs(t.total - Title.TotalSeconds) < 1e-9).toEqual(true)
		expect(t.scale and t.lines).toEqual(true)
	end)
	it("ends a first-visit card before the rise of the arrival moment", function()
		local fly = Cinematics.Moments.Arrival_1.shots
		local rise = fly[1].seconds + fly[2].seconds -- the rise starts when the open and fly shots are done
		expect(Title.AtSeconds + Title.TotalSeconds <= rise).toEqual(true)
	end)
	it("fades under Reduced Motion: no lines, no scale, a 1.6 s card", function()
		local t = Math.Timeline(true)
		expect(t.lines).toEqual(false)
		expect(t.scale).toEqual(false)
		expect(math.abs(t.total - 1.6) < 1e-9).toEqual(true)
		expect(t.inSeconds).toEqual(Title.ReducedFadeSeconds)
	end)
end)

describe("ArrivalTitleMath NameSize", function()
	it("keeps the full size when the name fits", function()
		expect(Math.NameSize(300, 533, 48, 14)).toEqual(48) -- 0.8 of an iPhone SE's 667
		expect(Math.NameSize(0, 533, 48, 14)).toEqual(48)
	end)
	it("shrinks a long name to the width limit, never under the floor", function()
		expect(Math.NameSize(1066, 533, 48, 14)).toEqual(24) -- twice as wide as the limit: half the size
		expect(Math.NameSize(100000, 533, 48, 14)).toEqual(14)
	end)
	it("fits the longest world name on one line at iPhone SE and iPad widths", function()
		local widthAt48 = 0.55 * 48 * #"Verdant Crash Site" -- a generous estimate of Fredoka's advance, in px
		for _, screen in ipairs({ 667, 1024 }) do
			local limit = Title.NameWidthShare * screen
			local size = Math.NameSize(widthAt48, limit, Title.NameSize, 14)
			expect(widthAt48 * size / Title.NameSize <= limit + 1).toEqual(true)
		end
	end)
end)

describe("ArrivalTitleMath PlaysOnLaterArrival", function()
	it("plays after a flight and never after a rejoin or a website join", function()
		expect(Math.PlaysOnLaterArrival(93842567264184)).toEqual(true)
		expect(Math.PlaysOnLaterArrival(nil)).toEqual(false)
		expect(Math.PlaysOnLaterArrival(0)).toEqual(false)
	end)
end)

return true
