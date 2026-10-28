--!strict
-- Shared.WorldCardMath: the arithmetic of the Star Chart's world cards (UI richness pass, package B,
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 3). Which species a card's row shows and in which order, how many chips fit,
-- what a chip says (a caught species is its colour, an uncaught or Secret one a "?"), how many a world has found, the cell
-- diorama's skyline and sun (the same on every build: heights come from BlockMath.Level), which world is the next stop on the chart
-- and on the Ship's strip, the card order and the grid row a world sits in. Pure numbers and tables, no Roblox types:
-- tests/WorldCardMath.spec.luau runs it headless. UI/WorldCard and UI/StarChartScreen call it and decide nothing.

local BlockMath = require(script.Parent.BlockMath)
local Data = require(script.Parent.data.WorldCards)
local Tiers = require(script.Parent.data.Tiers)
local Types = require(script.Parent.types.Types)
local Worlds = require(script.Parent.data.Worlds)

local WorldCardMath = {}

type Species = Types.SpeciesDef
export type Tower = { col: number, width: number, height: number } -- cell columns from the left, cell width, cell height above the far band
export type Block = { col: number, row: number, cells: number } -- the sun, moon or planet

local tierRank: { [string]: number } = {}
for index, tier in ipairs(Tiers.Order) do
	tierRank[tier] = index
end

-- The ids of the species a world's card row shows, in order: the world's Warden first, the special-weather species second, then the
-- rest by tier from the rarest down, ties by name (then id, so the order is total). Only species of `worldId` count; a Warden or
-- weather species the list does not hold (a home planet's empty ones, a world not built) is skipped; a world with none answers an
-- empty list. `world` is the data/Worlds row (it defaults to Worlds[worldId]).
function WorldCardMath.Roster(worldId: number, species: { Species }, world: Worlds.WorldDef?): { string }
	local row = world or Worlds[worldId]
	local mine: { Species } = {}
	local byId: { [string]: Species } = {}
	for _, def in ipairs(species) do
		if def.world == worldId then
			table.insert(mine, def)
			byId[def.id] = def
		end
	end
	local out: { string } = {}
	local placed: { [string]: boolean } = {}
	local function place(id: string?)
		if id and id ~= "" and byId[id] and not placed[id] then
			placed[id] = true
			table.insert(out, id)
		end
	end
	if row then
		place(row.warden)
		place(row.weather.special.speciesId)
	end
	table.sort(mine, function(a: Species, b: Species): boolean
		local rankA, rankB = tierRank[a.tier] or 0, tierRank[b.tier] or 0
		if rankA ~= rankB then
			return rankA > rankB
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.id < b.id
	end)
	for _, def in ipairs(mine) do
		place(def.id)
	end
	return out
end

-- How many of a world's species the codex holds, and how many it has: (found, total). `codex` is the profile's codex table
-- (a species id keyed to its entry); caught means an entry exists (spec: profile.codex[id] ~= nil).
function WorldCardMath.Counts(worldId: number, species: { Species }, codex: { [string]: any }): (number, number)
	local found, total = 0, 0
	for _, def in ipairs(species) do
		if def.world == worldId then
			total += 1
			if codex[def.id] ~= nil then
				found += 1
			end
		end
	end
	return found, total
end

-- What a species chip shows: "Caught" (its colour in its tier's ink) or "Unknown" (a dark chip with a "?"). A Secret is always
-- Unknown, caught or not (its surprise stays), though it still counts as found.
function WorldCardMath.ChipState(tier: string, caught: boolean): string
	if tier == "Secret" then
		return "Unknown"
	end
	return if caught then "Caught" else "Unknown"
end

-- The species chips a card shows for a panel `panelPx` wide: Row, or RowNarrow under NarrowPanelPx (iPhone SE).
function WorldCardMath.ChipCount(panelPx: number): number
	if panelPx > 0 and panelPx < Data.NarrowPanelPx then
		return Data.RowNarrow
	end
	return Data.Row
end

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

-- The cell diorama's skyline for a world on a box of `columns` by `rows` cells: Towers.Min to Towers.Max flat towers, evenly spread,
-- each moved a cell or two by the hash, each BaseCells plus a hash level tall but never above the two sky bands. Deterministic:
-- BlockMath.Level of the world and the tower's index, so the same world draws the same skyline on every build.
function WorldCardMath.Towers(worldId: number, columns: number, rows: number): { Tower }
	local t = Data.Diorama.Towers
	local count = clamp(t.Min + 1 + BlockMath.Level(worldId, 1, t.Seed), t.Min, t.Max)
	local skyRows = math.floor(rows * (Data.Diorama.SkyShare + Data.Diorama.SkyLowShare))
	local out: { Tower } = {}
	local slot = columns / count
	for index = 1, count do
		local width = t.WidthCells
		local centre = slot * (index - 1) + slot / 2
		local col = clamp(math.floor(centre - width / 2) + 2 * BlockMath.Level(worldId, index + 1, t.Seed), 0, columns - width)
		local height = clamp(t.BaseCells + BlockMath.Level(worldId, index + 20, t.Seed), 1, math.max(1, skyRows - 1))
		table.insert(out, { col = col, width = width, height = height })
	end
	return out
end

-- The sun, moon or planet: a square block of Accent.Cells cells near AtShare of the width, a hash cell either way, a row or so down
-- from the top, always inside the box.
function WorldCardMath.Accent(worldId: number, columns: number, rows: number): Block
	local a = Data.Diorama.Accent
	local col = clamp(math.floor(columns * a.AtShare) + 2 * BlockMath.Level(worldId, 3, a.Seed), 0, columns - a.Cells)
	local row = clamp(a.TopRows + BlockMath.Level(worldId, 5, a.Seed) + 1, 0, math.max(0, rows - a.Cells))
	return { col = col, row = row, cells = a.Cells }
end

-- The diorama's rows for a box `aspect` wide over tall at `columns` columns: the nearest whole number that keeps a cell square.
function WorldCardMath.DioramaRows(columns: number, aspect: number): number
	if aspect <= 0 then
		return columns
	end
	return math.max(1, math.floor(columns / aspect + 0.5))
end

-- The card order on the Star Chart: the Home planet (0) first, then worlds 1 to `count` in order.
function WorldCardMath.Order(count: number): { number }
	local out: { number } = { 0 }
	for id = 1, count do
		table.insert(out, id)
	end
	return out
end

-- The next stop on the Star Chart: the first world in `ids` past the highest unlocked one that is not unlocked itself (the Home
-- planet, id 0, is never the next stop). Nil when every world past it is open or there is none.
function WorldCardMath.NextLocked(ids: { number }, unlocked: { [number]: boolean }, highest: number): number?
	for _, id in ipairs(ids) do
		if id > highest and id > 0 and not unlocked[id] then
			return id
		end
	end
	return nil
end

-- The Ship's next-stop strip: the first world past the one the ship stands on (the Home planet is never a destination there); with
-- none past it, the first one before it (the way back). Nil when there is only the current world.
function WorldCardMath.NextStop(ids: { number }, current: number): number?
	local before: number? = nil
	for _, id in ipairs(ids) do
		if id > 0 and id ~= current then
			if id > current then
				return id
			elseif before == nil then
				before = id
			end
		end
	end
	return before
end

-- The grid row (0 from the top) a card at `index` (1 from the first) sits in with `columns` columns: where the chart scrolls to.
function WorldCardMath.Row(index: number, columns: number): number
	return math.max(0, index - 1) // math.max(1, columns)
end

-- Whether a card spanning `top` to `bottom` px of the canvas is within `screens` window heights of the viewport that shows
-- `scrollY` to `scrollY + windowPx`: its picture should be loaded.
function WorldCardMath.Near(top: number, bottom: number, scrollY: number, windowPx: number, screens: number): boolean
	local margin = windowPx * screens
	return bottom >= scrollY - margin and top <= scrollY + windowPx + margin
end

return WorldCardMath
