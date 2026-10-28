--!strict
-- Shared.ArrivalTitleMath: the arithmetic of the arrival title card (UI richness pass, package B,
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 6). The speed lines (12 flat blocks that streak inward from both edges: their
-- rows, lengths, flights and starts, the same every time), the timeline (in, hold, out; or a plain fade under Reduced Motion), the
-- size the name shrinks to so it fits one line, and when a card plays at all (a flight, never a rejoin or a website join).
-- Pure numbers, no Roblox types: tests/ArrivalTitleMath.spec.luau runs it headless. UI/ArrivalTitle draws it.

local BlockMath = require(script.Parent.BlockMath)
local Cinematics = require(script.Parent.data.Cinematics)

local ArrivalTitleMath = {}

export type Line = {
	side: number, -- -1 streaks in from the left edge, 1 from the right
	row: number, -- the line's centre, of the screen's height
	cells: number, -- its length in whole cells
	travel: number, -- how far it streaks inward, of the screen's width
	delay: number, -- seconds after the card starts
	seconds: number, -- how long its flight takes
	inner: boolean, -- it reaches the middle third
}

export type Timeline = { inSeconds: number, holdSeconds: number, outSeconds: number, total: number, scale: boolean, lines: boolean }

-- The speed lines, in start order. Rows are Count evenly spaced between RowMin and RowMax; the InnerCount rows farthest from the middle
-- belong to the lines that reach the middle third (so they never cross the title), the rest to the outer ones; sides alternate down
-- the screen. A line's length runs MinCells to MaxCells by a fixed pattern a hash level moves a cell either way, its flight takes
-- MinSeconds to MaxSeconds, and the starts spread over StaggerSeconds.
function ArrivalTitleMath.Lines(): { Line }
	local d = Cinematics.Title.Lines
	local count = d.Count
	local rows: { number } = {}
	for index = 1, count do
		table.insert(rows, d.RowMin + (d.RowMax - d.RowMin) * (index - 1) / math.max(1, count - 1))
	end
	local byDistance: { number } = {}
	for index = 1, count do
		table.insert(byDistance, index)
	end
	table.sort(byDistance, function(a: number, b: number): boolean
		local da, db = math.abs(rows[a] - 0.5), math.abs(rows[b] - 0.5)
		if da ~= db then
			return da > db
		end
		return a < b
	end)
	local inner: { [number]: boolean } = {}
	for rank = 1, math.min(d.InnerCount, count) do
		inner[byDistance[rank]] = true
	end
	local out: { Line } = {}
	local span = d.MaxCells - d.MinCells + 1
	for index = 1, count do
		local cells = d.MinCells + (index * 7) % span + BlockMath.Level(index, 1, d.Seed)
		local flight = d.MinSeconds + (d.MaxSeconds - d.MinSeconds) * ((index * 5) % 4) / 3
		table.insert(out, {
			side = if index % 2 == 1 then -1 else 1,
			row = rows[index],
			cells = math.clamp(cells, d.MinCells, d.MaxCells),
			travel = if inner[index] then d.InnerTravel else d.OuterTravel,
			delay = d.StaggerSeconds * (index - 1) / math.max(1, count - 1),
			seconds = flight,
			inner = inner[index] == true,
		})
	end
	table.sort(out, function(a: Line, b: Line): boolean
		return a.delay < b.delay
	end)
	return out
end

-- The card's timeline: in, hold, out (the name grows from ScaleFrom as it fades in, the lines run), or under Reduced Motion a fade in,
-- a hold and a fade out with no scale and no lines.
function ArrivalTitleMath.Timeline(reduced: boolean): Timeline
	local t = Cinematics.Title
	if reduced then
		return {
			inSeconds = t.ReducedFadeSeconds,
			holdSeconds = t.ReducedHoldSeconds,
			outSeconds = t.ReducedFadeSeconds,
			total = t.ReducedHoldSeconds + 2 * t.ReducedFadeSeconds,
			scale = false,
			lines = false,
		}
	end
	return { inSeconds = t.InSeconds, holdSeconds = t.HoldSeconds, outSeconds = t.OutSeconds, total = t.InSeconds + t.HoldSeconds + t.OutSeconds, scale = true, lines = true }
end

-- The text size the name takes so it fits `limitPx` on one line: `maxSize` when `textPx` (its width at maxSize) fits, else shrunk in
-- proportion, never under `minSize` (a name that still does not fit at the floor is clipped by the label, never wrapped).
function ArrivalTitleMath.NameSize(textPx: number, limitPx: number, maxSize: number, minSize: number): number
	if textPx <= 0 or limitPx <= 0 or textPx <= limitPx then
		return maxSize
	end
	return math.max(minSize, math.floor(maxSize * limitPx / textPx))
end

-- Whether a card plays when the client starts on a world it has seen the arrival of (no cinematic): only when the join came from
-- another place of this game (`sourcePlaceId` is the join data's SourcePlaceId: a flight), so a rejoin or a website join never says
-- "now arriving". A first visit (the Arrival moment plays) takes the card at Title.AtSeconds instead; the caller decides that.
function ArrivalTitleMath.PlaysOnLaterArrival(sourcePlaceId: number?): boolean
	return sourcePlaceId ~= nil and sourcePlaceId > 0
end

return ArrivalTitleMath
