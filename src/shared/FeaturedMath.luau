--!strict
-- Shared.FeaturedMath: the pure rules of the featured card and its grid (UI richness pass, package C;
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 4). The Aliens and Codex screens draw and ask the server; every decision they
-- make from state is here, so tests/FeaturedMath.spec.luau runs it headless: which mode a panel shows, which alien is selected on
-- open, which buttons a context gets, the flavour line's key, the order of the Aliens grid, the Codex's tier sections and counts, the
-- card's layout in both modes and the sectioned grid's positions. Numbers come from data/Panels.Featured; nothing here touches
-- Roblox types.

local Panels = require(script.Parent.data.Panels)
local Tiers = require(script.Parent.data.Tiers)

local FeaturedMath = {}

export type Mode = "side" | "strip"

-- Mode ---------------------------------------------------------------------

-- Which shape the panel takes at `panelPxW` by `panelPxH` px (its own size with any open tween's scale taken out): the side mode
-- (card left, grid right) from Featured.MinPanelW by MinPanelH, else the strip mode (card as a strip across the top).
function FeaturedMath.Mode(panelPxW: number, panelPxH: number): Mode
	local f = Panels.Featured
	if panelPxW >= f.MinPanelW and panelPxH >= f.MinPanelH then
		return "side"
	end
	return "strip"
end

-- Aliens ---------------------------------------------------------------------

-- The grid's columns, the cell's width and the gap (of the grid's canvas width) in `mode`.
function FeaturedMath.AliensGrid(mode: Mode): (number, number, number)
	local a = Panels.Featured.Aliens
	if mode == "side" then
		return a.Columns.side, a.Cell.side, a.Gap.side
	end
	return a.Columns.strip, a.Cell.strip, a.Gap.strip
end

-- The alien selected when the Aliens panel opens: the mount you ride, else the first companion, else the newest alien. `caughtAt`
-- maps every owned alien's uid to when it was caught (an id that is not in it is gone: a stale ride or companion is skipped); the
-- newest wins and a tie goes to the greater uid, so the answer is the same every time. Nil only when nothing is owned.
function FeaturedMath.AliensDefault(riding: string?, companions: { string }, caughtAt: { [string]: number }): string?
	if riding ~= nil and caughtAt[riding] ~= nil then
		return riding
	end
	for _, uid in ipairs(companions) do
		if caughtAt[uid] ~= nil then
			return uid
		end
	end
	local best: string? = nil
	local bestAt = -math.huge
	for uid, at in pairs(caughtAt) do
		if at > bestAt or (at == bestAt and best ~= nil and uid > best) then
			best, bestAt = uid, at
		end
	end
	return best
end

-- A tier's place on the ladder, 1 for Common up to 7 for Secret (0 for a tier the data does not know).
function FeaturedMath.TierRank(tier: string): number
	return table.find(Tiers.Order, tier) or 0
end

export type SortItem = {
	riding: boolean,
	following: boolean,
	tierRank: number,
	speed: number,
	name: string,
	uid: string,
}

-- The Aliens grid's order, as a sort comparator: the ridden one, then the companions, then the rarer tier first, then the faster, then
-- by name, then by uid so the order is the same between refreshes.
function FeaturedMath.Before(a: SortItem, b: SortItem): boolean
	if a.riding ~= b.riding then
		return a.riding
	end
	if a.following ~= b.following then
		return a.following
	end
	if a.tierRank ~= b.tierRank then
		return a.tierRank > b.tierRank
	end
	if a.speed ~= b.speed then
		return a.speed > b.speed
	end
	if a.name ~= b.name then
		return a.name < b.name
	end
	return a.uid < b.uid
end

-- Buttons ----------------------------------------------------------------------

export type Context = {
	screen: "Aliens" | "Codex",
	-- Aliens: the selected alien's state
	visiting: boolean?, -- at another player's home: a guest never changes it
	riding: boolean?, -- the local player rides it
	following: boolean?, -- it is a companion
	displayed: boolean?, -- it stands in a habitat at home
	seated: boolean?, -- it works at a station (a seated alien cannot follow)
	slotFree: boolean?, -- a companion slot is free
	canRide: boolean?, -- its species has a ride
	canDisplay: boolean?, -- at home, a resting alien whose world has a habitat
	canBringBack: boolean?, -- at home, a displayed alien
	-- Codex
	caught: boolean?,
}

-- One button: `id` the action the screen runs (Follow, Unfollow, Ride, HopOff, Display, BringBack, SeeInAliens), `word` the strings key
-- of its label, `role` a data/Panels.Roles key (Builder.roleColor): main green, current grey, select blue.
export type Action = { id: string, word: string, role: string }
export type Buttons = { main: Action?, side: Action? }

-- The buttons of a featured card (section 4's table): one main action by context, and at most one beside it.
--   Aliens, riding: Hop off (blue).          Aliens, following: Stop following (grey), Ride (blue) when the species has one.
--   Aliens, on display: Bring back (grey) at home.   Aliens, resting: Follow (green; grey while the slots are full or it works at a
--   station, where a tap still toasts the reason), Display (blue) beside it at home with a habitat.   A guest: none.
--   Codex, caught: See in Aliens (green).   Codex, not caught: none (the hint line takes the room).
function FeaturedMath.Button(context: Context): Buttons
	if context.screen == "Codex" then
		if context.caught == true then
			return { main = { id = "SeeInAliens", word = "FEATURED_SEE_IN_ALIENS", role = "main" } }
		end
		return {}
	end
	if context.visiting == true then
		return {}
	end
	if context.riding == true then
		return { main = { id = "HopOff", word = "ALIENS_HOP_OFF", role = "select" } }
	end
	if context.displayed == true then
		if context.canBringBack == true then
			return { main = { id = "BringBack", word = "ALIENS_BRING_BACK", role = "current" } }
		end
		return {}
	end
	if context.following == true then
		local out: Buttons = { main = { id = "Unfollow", word = "FEATURED_STOP", role = "current" } }
		if context.canRide == true then
			out.side = { id = "Ride", word = "ALIENS_RIDE", role = "select" }
		end
		return out
	end
	local free = context.slotFree == true and context.seated ~= true
	local out: Buttons = { main = { id = "Follow", word = "FEATURED_FOLLOW", role = if free then "main" else "current" } }
	if context.canDisplay == true then
		out.side = { id = "Display", word = "ALIENS_DISPLAY", role = "select" }
	end
	return out
end

-- Flavour ----------------------------------------------------------------------

-- The strings key of a species' flavour line: FLAVOUR_<id> when the strings have it (`has` asks), else FLAVOUR_TIER_<tier>, so a new
-- species never prints a blank.
function FeaturedMath.FlavourKey(speciesId: string, tier: string, has: (string) -> boolean): string
	local own = "FLAVOUR_" .. speciesId
	if has(own) then
		return own
	end
	return "FLAVOUR_TIER_" .. tier
end

-- Codex ------------------------------------------------------------------------

export type Section = { tier: string, from: number, to: number, found: number, total: number }

-- The page's tier sections: runs of the same tier in `tiers` (the page's species in display order, already sorted by tier), each with
-- how many of its members are caught in `caught` (same order). A section's count and the pills' counts come from the same list, so
-- they always agree.
function FeaturedMath.Sections(tiers: { string }, caught: { boolean }): { Section }
	local out: { Section } = {}
	for index, tier in ipairs(tiers) do
		local last = out[#out]
		if last and last.tier == tier then
			last.to = index
			last.total += 1
			if caught[index] then
				last.found += 1
			end
		else
			table.insert(out, { tier = tier, from = index, to = index, found = if caught[index] then 1 else 0, total = 1 })
		end
	end
	return out
end

export type CodexEntry = { id: string, world: number }

-- The Codex pills' numbers: found and total over the species of every built world (the first pill), and found and total of `page`
-- (the second). `caught` is the set of species ids with a codex entry; `built` the set of built worlds.
function FeaturedMath.CodexCounts(
	list: { CodexEntry },
	caught: { [string]: boolean },
	built: { [number]: boolean },
	page: number
): (number, number, number, number)
	local found, total, pageFound, pageTotal = 0, 0, 0, 0
	for _, entry in ipairs(list) do
		local isCaught = caught[entry.id] == true
		if built[entry.world] == true then
			total += 1
			if isCaught then
				found += 1
			end
		end
		if entry.world == page then
			pageTotal += 1
			if isCaught then
				pageFound += 1
			end
		end
	end
	return found, total, pageFound, pageTotal
end

-- The Codex grid's columns from its window's width: as many tiles of at least Codex.MinCellPx as fit, within the column limits.
function FeaturedMath.CodexColumns(widthPx: number): number
	local c = Panels.Featured.Codex
	if widthPx <= 0 then
		return c.MaxColumns
	end
	return math.clamp(math.floor(widthPx / c.MinCellPx), c.MinColumns, c.MaxColumns)
end

export type GridItem = { x: number, y: number }
export type GridSection = { stripY: number, items: { GridItem } }
export type GridPlan = { cell: number, height: number, sections: { GridSection } }

-- The Codex's sectioned grid in px: `counts[i]` tiles in section i, `cols` across in a `widthPx` canvas with `gapPx` between tiles; each
-- section opens with a strip `stripPx` tall (when `strips`) and a gap, and sections are `gapPx` apart. Every tile is square, `cell`
-- px. The screen turns these into Scale values of the canvas (px over the canvas's px); nothing is positioned in px.
function FeaturedMath.GridPlan(widthPx: number, cols: number, gapPx: number, stripPx: number, strips: boolean, counts: { number }): GridPlan
	local columns = math.max(1, cols)
	local cell = math.max(0, (widthPx - gapPx * (columns - 1)) / columns)
	local y = 0
	local sections: { GridSection } = {}
	for index, count in ipairs(counts) do
		local section: GridSection = { stripY = y, items = {} }
		if strips then
			y += stripPx + gapPx
		end
		for item = 0, count - 1 do
			local col = item % columns
			local row = item // columns
			table.insert(section.items, { x = col * (cell + gapPx), y = y + row * (cell + gapPx) })
		end
		local rows = math.ceil(count / columns)
		if rows > 0 then
			y += rows * cell + (rows - 1) * gapPx
		end
		if index < #counts then
			y += gapPx
		end
		table.insert(sections, section)
	end
	return { cell = cell, height = y, sections = sections }
end

-- Layout -----------------------------------------------------------------------

export type Box = { y: number, h: number }

export type SideLayout = {
	view: Box,
	tag: Box,
	name: Box,
	flavour: Box,
	facts: { Box },
	main: Box?,
	side: Box?,
}

-- The side card's rows top to bottom as fractions of its height: the model view takes what the others leave, then the tag, the name,
-- the flavour, `facts` fact lines (0 to 3) and the buttons (the second one under the main one). `hasMain` false leaves no button (a
-- Codex species not yet caught: the hint line is the flavour row). Nothing overlaps and the view never drops under Card.ViewMin for
-- the contexts the screens use (the spec walks them).
function FeaturedMath.SideLayout(hasMain: boolean, hasSide: boolean, facts: number): SideLayout
	local c = Panels.Featured.Card
	-- The blocks under the view in order, each with the gap before it (the fact lines of one card sit tight together).
	type Block = { h: number, gap: number }
	local blocks: { Block } = {
		{ h = c.Tag, gap = c.Gap },
		{ h = c.Name, gap = c.Gap },
		{ h = c.Flavour, gap = c.Gap },
	}
	for index = 1, facts do
		table.insert(blocks, { h = c.Fact, gap = if index == 1 then c.Gap else 0 })
	end
	local mainAt, sideAt = 0, 0
	if hasMain then
		table.insert(blocks, { h = c.Button, gap = c.Gap })
		mainAt = #blocks
	end
	if hasSide then
		table.insert(blocks, { h = c.Button, gap = if hasMain then c.ButtonGap else c.Gap })
		sideAt = #blocks
	end
	local used = 0
	for _, block in ipairs(blocks) do
		used += block.h + block.gap
	end
	local viewH = 1 - 2 * c.Pad - used
	local y = c.Pad + viewH
	local boxes: { Box } = {}
	for index, block in ipairs(blocks) do
		y += block.gap
		boxes[index] = { y = y, h = block.h }
		y += block.h
	end
	local layout: SideLayout = {
		view = { y = c.Pad, h = viewH },
		tag = boxes[1],
		name = boxes[2],
		flavour = boxes[3],
		facts = {},
		main = if mainAt > 0 then boxes[mainAt] else nil,
		side = if sideAt > 0 then boxes[sideAt] else nil,
	}
	for index = 1, facts do
		layout.facts[index] = boxes[3 + index]
	end
	return layout
end

export type Rect = { x: number, y: number, w: number, h: number }

export type StripLayout = {
	plinth: Rect,
	column: Rect, -- the text column: x and width; its y and h are 0 and 1
	main: Rect?,
	side: Rect?,
}

-- The strip card (iPhone SE) as fractions of its width and height, for a strip `aspect` (width over height in px): the square plinth
-- on the left, the buttons on the right (the main one last), the text column between. The plinth's width is its height over the
-- aspect, so it stays square at any strip shape.
function FeaturedMath.StripLayout(aspect: number, hasMain: boolean, hasSide: boolean): StripLayout
	local c = Panels.Featured.StripCard
	local ratio = math.max(aspect, 0.1)
	local plinthW = c.PlinthH / ratio
	local layout: StripLayout = {
		plinth = { x = c.Pad, y = (1 - c.PlinthH) / 2, w = plinthW, h = c.PlinthH },
		column = { x = 0, y = 0, w = 0, h = 1 },
		main = nil,
		side = nil,
	}
	local right = 1 - c.Pad
	if hasMain then
		layout.main = { x = right - c.MainW, y = (1 - c.ButtonH) / 2, w = c.MainW, h = c.ButtonH }
		right -= c.MainW + c.Gap
	end
	if hasSide then
		layout.side = { x = right - c.SideW, y = (1 - c.ButtonH) / 2, w = c.SideW, h = c.ButtonH }
		right -= c.SideW + c.Gap
	end
	local left = c.Pad + plinthW + c.Gap
	layout.column = { x = left, y = 0, w = math.max(0, right - left), h = 1 }
	return layout
end

return FeaturedMath
