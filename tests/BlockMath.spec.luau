--!strict
-- Shared.BlockMath: the block-cell plate (UI Playbook "Block cells", Blocky-Style C1 to C6) and the HUD's fit in it at iPhone SE
-- (667x375) and iPad (1080x810). The parameters are Theme.Block's (Theme needs the Roblox runtime, so
-- tools/tests/test_block_theme.py reads them out of src/shared/Theme.luau and checks they are these), and the HUD rows mirror
-- the sizes and aspects in src/client/UI/Hud.luau: change one, change the other.
local Shared = game:GetService("ReplicatedStorage").Shared
local BlockMath = require(Shared.BlockMath)
local HudData = require(Shared.data.Hud)
local HudStages = require(Shared.HudStages)
local Panels = require(Shared.data.Panels)
local FeaturedMath = require(Shared.FeaturedMath)

local CELL, INK, MIN_ROWS, GROUT, SEED = 0.02, 0.4, 3, 0.125, 44
local PANEL_CELL = 0.04 -- Theme.Block.PanelCell: a modal panel's cell, twice CELL (tools/tests/test_block_theme.py checks both)
local TAP_MIN = 44 -- Theme.TapMin
local TEXT_MIN = 14 -- Theme.TextSize.Min
local EPS = 1e-9

local SE = { w = 667, h = 375 }
local IPAD = { w = 1080, h = 810 }

type Plate = {
	name: string,
	sizeX: number, -- Size bounds, Scale of the parent's px (sizeX of `parentW`, sizeY of `parentH` when nested)
	sizeY: number,
	aspect: number,
	height: number, -- the screen-height Scale its rows are picked from
	button: boolean?, -- a Builder.blockButton (a one-cell lip under the face)
	hit: boolean?, -- carries the 44 px hit area
	text: boolean?, -- carries one centred line of text at the 14 px floor or more
}

-- Hud.luau (the quiet HUD, data/Hud Chips): the Scrap plate, the place chip (two lines), the event chip, the Friend chip, a top button,
-- a menu button (its size is 0.095 of the screen height inside a 0.12 x 0.13 slot at aspect 0.8) and the action button. The ship bar
-- is a fitted plate, not an aspect plate: its own describe below ("BlockMath HUD goal plate").
local HUD: { Plate } = {
	{ name = "ScrapPill", sizeX = 0.3, sizeY = 0.085, aspect = 3.6, height = 0.085, text = true },
	{ name = "PlaceChip", sizeX = 0.4, sizeY = 0.075, aspect = 4.2, height = 0.075, text = true },
	{ name = "EventChip", sizeX = 0.4, sizeY = 0.048, aspect = 6, height = 0.048, text = true },
	{ name = "FriendChip", sizeX = 0.4, sizeY = 0.055, aspect = 5.5, height = 0.055, text = true },
	{ name = "TopButton", sizeX = 0.3, sizeY = 0.075, aspect = 1, height = 0.075, button = true, hit = true },
	{ name = "MenuButton", sizeX = 0.12, sizeY = 0.095, aspect = 1, height = 0.095, button = true, hit = true },
	{ name = "Action", sizeX = 0.3, sizeY = 0.13, aspect = 2.3, height = 0.13, button = true, hit = true, text = true },
}

local function rowsOf(plate: Plate): number
	local height = if plate.button then plate.height - CELL else plate.height
	return BlockMath.Rows(height, CELL, INK, MIN_ROWS)
end

-- The plate's face box in px (the whole plate for a plate, the face above the lip for a button), and its grid.
local function measure(plate: Plate, screen: { w: number, h: number }): (number, number, BlockMath.Grid)
	local w, h = BlockMath.FitPx(plate.sizeX, plate.sizeY, plate.aspect, screen.w, screen.h)
	local rows = rowsOf(plate)
	if plate.button then
		local lip, faceAspect = BlockMath.Lip(plate.aspect, rows, INK)
		return w, h * (1 - lip), BlockMath.Grid(faceAspect, rows, INK)
	end
	return w, h, BlockMath.Grid(plate.aspect, rows, INK)
end

describe("BlockMath grid", function()
	it("picks rows from the height so a cell is about Theme.Block.Cell of the screen, never under three", function()
		expect(BlockMath.Rows(0.085, CELL, INK, MIN_ROWS)).toEqual(3)
		expect(BlockMath.Rows(0.05, CELL, INK, MIN_ROWS)).toEqual(3)
		expect(BlockMath.Rows(0.2, CELL, INK, MIN_ROWS)).toEqual(9)
		expect(BlockMath.Rows(0.1, 0, INK, MIN_ROWS)).toEqual(MIN_ROWS)
	end)
	it("spans the plate exactly with whole cells and the ink both sides", function()
		local grid = BlockMath.Grid(3.6, 3, INK)
		expect(grid.cols).toEqual(13)
		expect(grid.cols * grid.cellX + 2 * grid.inkX).toBeClose(1, EPS)
		expect(grid.rows * grid.cellY + 2 * grid.inkY).toBeClose(1, EPS)
		expect(grid.inkX).toBeClose(INK * grid.cellX, EPS)
	end)
	it("keeps the cells within 6% of square on every HUD plate", function()
		for _, plate in ipairs(HUD) do
			local w, h, grid = measure(plate, SE)
			local skew = (w * grid.cellX) / (h * grid.cellY) - 1
			assert(math.abs(skew) <= 0.06, plate.name .. " cells are " .. skew .. " off square")
		end
	end)
	it("never makes fewer than three columns", function()
		expect(BlockMath.Grid(0.2, 3, INK).cols).toEqual(3)
	end)
end)

describe("BlockMath shape", function()
	local grid = BlockMath.Grid(4.2, 3, INK)
	it("cuts one cell from each corner of the ink and keeps the ink one thickness round the step", function()
		local ink = BlockMath.Shape(grid, 0, 0)
		local face = BlockMath.Face(grid)
		expect(ink[1].y).toBeClose(grid.cellY, EPS)
		expect(ink[2].x).toBeClose(grid.cellX, EPS)
		expect(face[1].x - ink[1].x).toBeClose(grid.inkX, EPS)
		expect(face[1].y - ink[1].y).toBeClose(grid.inkY, EPS)
		expect(face[2].x - ink[2].x).toBeClose(grid.inkX, EPS)
		expect(face[2].y - ink[2].y).toBeClose(grid.inkY, EPS)
		expect(face[1].w).toBeClose(grid.cols * grid.cellX, EPS)
		expect(face[2].h).toBeClose(grid.rows * grid.cellY, EPS)
	end)
	it("fills a bar from nothing to the whole face, inside the stepped corners", function()
		for _, bar in ipairs(BlockMath.Fill(grid, 0)) do
			expect(bar.w).toEqual(0)
		end
		local full, face = BlockMath.Fill(grid, 1), BlockMath.Face(grid)
		for index, bar in ipairs(full) do
			expect(bar.w).toBeClose(face[index].w, EPS)
		end
		-- half way: the wide bar reaches the middle, the narrow one too, and neither starts before its own left edge
		local half = BlockMath.Fill(grid, 0.5)
		expect(half[1].x + half[1].w).toBeClose(0.5, EPS)
		expect(half[2].x + half[2].w).toBeClose(0.5, EPS)
		-- a sliver under one cell lights only the wide bar (the corner cell stays cut)
		local sliver = BlockMath.Fill(grid, 0.5 / grid.cols)
		expect(sliver[2].w).toEqual(0)
		assert(sliver[1].w > 0, "the wide bar starts at once")
	end)
	it("lights the top row and shades the other border cells, without the cut corners, only from three cells", function()
		local bands = BlockMath.Bands(grid)
		local top = bands.top :: BlockMath.Rect
		expect(top.x).toBeClose(grid.inkX + grid.cellX, EPS)
		expect(top.w).toBeClose((grid.cols - 2) * grid.cellX, EPS)
		expect(top.h).toBeClose(grid.cellY, EPS)
		local left = bands.left :: BlockMath.Rect
		expect(left.h).toBeClose((grid.rows - 2) * grid.cellY, EPS)
		expect(BlockMath.Bands(BlockMath.Grid(4.2, 2, INK)).top).toEqual(nil)
	end)
	it("draws a grout line on each inner cell edge, the first ones clear of the cut corners", function()
		local lines = BlockMath.Grout(grid, GROUT)
		expect(#lines).toEqual(grid.cols - 1 + grid.rows - 1)
		local firstColumn = lines[1]
		expect(firstColumn.y).toBeClose(grid.inkY + grid.cellY, EPS)
		expect(firstColumn.w).toBeClose(GROUT * grid.cellX, EPS)
		local firstRow = lines[grid.cols]
		expect(firstRow.x).toBeClose(grid.inkX + grid.cellX, EPS)
		expect(firstRow.h).toBeClose(GROUT * grid.cellY, EPS)
		local secondColumn = lines[2]
		expect(secondColumn.y).toBeClose(grid.inkY, EPS)
	end)
end)

describe("BlockMath jitter", function()
	it("is deterministic and only -1, 0 or 1", function()
		for col = 0, 20 do
			for row = 0, 5 do
				local level = BlockMath.Level(col, row, SEED)
				expect(BlockMath.Level(col, row, SEED)).toEqual(level)
				assert(level == -1 or level == 0 or level == 1, "level " .. level)
			end
		end
	end)
	it("keeps 1 : 6 : 1 over a large field (C2)", function()
		local down, up, total = 0, 0, 0
		for col = 0, 99 do
			for row = 0, 99 do
				local level = BlockMath.Level(col, row, SEED)
				total += 1
				if level < 0 then
					down += 1
				elseif level > 0 then
					up += 1
				end
			end
		end
		expect(down / total).toBeClose(0.125, 0.02)
		expect(up / total).toBeClose(0.125, 0.02)
	end)
	it("skips the cut corner cells and a different seed gives a different plate", function()
		local grid = BlockMath.Grid(4.2, 3, INK)
		local a, b = BlockMath.Jittered(grid, SEED), BlockMath.Jittered(grid, SEED + 1)
		for _, cell in ipairs(a) do
			local corner = (cell.row == 0 or cell.row == grid.rows - 1) and (cell.col == 0 or cell.col == grid.cols - 1)
			assert(not corner, "a corner cell was jittered")
		end
		local same = #a == #b
		if same then
			for index, cell in ipairs(a) do
				same = same and cell.col == b[index].col and cell.row == b[index].row and cell.level == b[index].level
			end
		end
		assert(not same, "two seeds gave the same plate")
	end)
end)

describe("BlockMath button", function()
	it("puts a lip one cell deep under the face", function()
		local lip, faceAspect = BlockMath.Lip(1, 3, INK)
		expect(lip).toBeClose(1 / (3 + 2 * INK + 1), EPS)
		expect(faceAspect).toBeClose(1 / (1 - lip), EPS)
	end)
	it("fits the box like UIAspectRatioConstraint FitWithinMaxSize", function()
		local w, h = BlockMath.FitPx(0.3, 0.085, 3.6, SE.w, SE.h)
		expect(h).toBeClose(0.085 * SE.h, EPS)
		expect(w).toBeClose(h * 3.6, EPS)
		local w2, h2 = BlockMath.FitPx(0.12, 0.13, 0.8, 300, 800) -- a tall narrow window: the width binds
		expect(w2).toBeClose(36, EPS)
		expect(h2).toBeClose(45, EPS)
	end)
end)

describe("BlockMath HUD fit", function()
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		it(label .. ": every plate has three rows or more, cells of 4.5 px or more and ink of 1.8 px or more", function()
			for _, plate in ipairs(HUD) do
				local _, h, grid = measure(plate, screen)
				local cell = h * grid.cellY
				assert(grid.rows >= 3, plate.name .. " has " .. grid.rows .. " rows")
				assert(cell >= 4.5, plate.name .. " cell is " .. cell .. " px")
				assert(INK * cell >= 1.8, plate.name .. " ink is " .. INK * cell .. " px")
			end
		end)
		it(label .. ": the grout is half a pixel or more, so it draws as a line", function()
			for _, plate in ipairs(HUD) do
				local _, h, grid = measure(plate, screen)
				local grout = GROUT * h * grid.cellY
				assert(grout >= 0.5, plate.name .. " grout is " .. grout .. " px")
			end
		end)
		it(label .. ": a line of text at the 14 px floor fits inside each plate's face", function()
			for _, plate in ipairs(HUD) do
				if plate.text then
					local _, h, grid = measure(plate, screen)
					local inner = h * (1 - 2 * grid.inkY)
					assert(inner >= TEXT_MIN, plate.name .. " face is " .. inner .. " px tall")
				end
			end
		end)
		it(label .. ": every button's face or hit area is 44 px or more both ways", function()
			for _, plate in ipairs(HUD) do
				if plate.button then
					local w, h = measure(plate, screen)
					local ok = plate.hit or (w >= TAP_MIN and h >= TAP_MIN)
					assert(ok, plate.name .. " face is " .. w .. " x " .. h .. " px with no hit area")
				end
			end
		end)
	end
	it("iPhone SE: the cells are 4.7 to 8.4 px, near the board's 8 px at 390 tall", function()
		local small, large = math.huge, 0
		for _, plate in ipairs(HUD) do
			local _, h, grid = measure(plate, SE)
			local cell = h * grid.cellY
			small, large = math.min(small, cell), math.max(large, cell)
		end
		expect(small).toBeClose(4.74, 0.01) -- the event chip at its nominal height (layoutRight floors it taller on a phone)
		expect(large).toBeClose(8.39, 0.01) -- the Scrap plate
	end)
end)

describe("BlockMath HUD chips on a short screen", function()
	-- Hud.luau layoutRight: a chip is the data's height share, or its pixel floor when that is taller (HudStages.AtLeast); it keeps its
	-- aspect, so the width follows. The place chip holds two lines (0.44 and 0.36 of it), the event chip one (0.7), the Friend chip one.
	local chips = HudData.Chips
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local place = HudStages.AtLeast(chips.PlaceHeight, chips.PlaceMinPx, screen.h) * screen.h
		local event = HudStages.AtLeast(chips.EventHeight, chips.EventMinPx, screen.h) * screen.h
		local friend = HudStages.AtLeast(chips.FriendHeight, chips.FriendMinPx, screen.h) * screen.h
		it(label .. ": every line the place chip shows is 14 px or more, and the event and Friend chips' one line too", function()
			assert(place * 0.36 >= TEXT_MIN, "the place chip's time line is " .. place * 0.36 .. " px")
			assert(place * 0.44 >= TEXT_MIN, "the place chip's name line is " .. place * 0.44 .. " px")
			assert(event * 0.7 >= TEXT_MIN, "the event chip's line is " .. event * 0.7 .. " px")
			assert(friend * 0.7 >= TEXT_MIN, "the Friend chip's line is " .. friend * 0.7 .. " px")
		end)
		it(label .. ": the chips' widths (their aspects) stay inside the screen and the size bound", function()
			for _, row in ipairs({ { 4.2, place }, { 6, event }, { 5.5, friend } }) do
				local width = row[1] * row[2]
				assert(width <= chips.MaxWidth * screen.w + 1e-6, "a chip is " .. width .. " px wide, past its bound")
				assert(width <= 0.4 * screen.w, "a chip takes " .. width / screen.w .. " of the width")
			end
		end)
	end
	it("the three chips and the radar column's top (0.228) fit on a wide screen, and on an iPad", function()
		for _, screen in ipairs({ { w = 1600, h = 900 }, IPAD }) do
			local total = chips.Top
			for _, row in ipairs({ { chips.PlaceHeight, chips.PlaceMinPx }, { chips.EventHeight, chips.EventMinPx }, { chips.FriendHeight, chips.FriendMinPx } }) do
				total += HudStages.AtLeast(row[1], row[2], screen.h) + chips.Gap
			end
			assert(total - chips.Gap <= 0.228, screen.w .. "x" .. screen.h .. ": the chips end at " .. total - chips.Gap)
		end
	end)
end)

describe("BlockMath HUD goal plate", function()
	-- Hud.luau layoutGoal and UI/TutorialHint layout: the ship bar is a fitted plate of data/Hud Goal.Width by ShipHeight (taller on a
	-- short screen, never narrower than a 4.2 chip of its height), its rows picked from its real box (Builder fitPlate); the objective
	-- line under it is the same kind of plate, as tall as its lines need.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local slots = HudStages.GoalSlots(screen.w, screen.h, 4.2)
		local w, h = slots.shipWidth * screen.w, slots.shipHeight * screen.h
		it(label .. ": the ship bar holds a 14 px line inside its ink, with cells of 4.5 px or more", function()
			local rows = BlockMath.ScreenRows(h, screen.h, CELL, INK, MIN_ROWS, 0)
			local grid = BlockMath.Grid(w / h, rows, INK)
			local cell = h * grid.cellY
			assert(cell >= 4.5, "the cell is " .. cell .. " px")
			assert(h * (1 - 2 * grid.inkY) >= TEXT_MIN, "the face is " .. h * (1 - 2 * grid.inkY) .. " px tall")
			assert(GROUT * cell >= 0.5, "the grout is " .. GROUT * cell .. " px")
		end)
		it(label .. ": the objective line holds 14 px lines and its cells stay near square", function()
			local o = HudStages.Objective(60, true, screen.w, screen.h, TEXT_MIN)
			local ow, oh = o.width * screen.w, o.height * screen.h
			local rows = BlockMath.ScreenRows(oh, screen.h, CELL, INK, MIN_ROWS, 0)
			local grid = BlockMath.Grid(ow / oh, rows, INK)
			assert(oh * (1 - 2 * grid.inkY) >= o.lines * TEXT_MIN, "the face is " .. oh * (1 - 2 * grid.inkY) .. " px for " .. o.lines .. " lines")
			local skew = (ow * grid.cellX) / (oh * grid.cellY) - 1
			assert(math.abs(skew) <= 0.12, "the cells are " .. skew .. " off square")
		end)
	end
end)

-- The screens after the HUD (UI Playbook "Block cells", "Screens after the HUD"). A fitted plate (Builder.blockPlate with no
-- aspect) takes the px box its Size gives and the whole number of columns nearest square cells for it: `fit` is that grid.
local function fit(wPx: number, hPx: number, rows: number): BlockMath.Grid
	return BlockMath.Grid(wPx / hPx, rows, INK)
end

describe("BlockMath frames", function()
	it("counts four frames for a flat block and adds the bands, grout and jitter for cells", function()
		local grid = BlockMath.Grid(4.2, 3, INK)
		expect(BlockMath.Frames(grid, false, SEED)).toEqual(4)
		local cells = 4 + 4 + (grid.cols - 1 + grid.rows - 1) + #BlockMath.Jittered(grid, SEED)
		expect(BlockMath.Frames(grid, true, SEED)).toEqual(cells)
	end)
	it("a fitted plate's cells are within 6% of square once it is nine columns or more wide", function()
		for _, box in ipairs({ { 226.8, 15 }, { 367.2, 32.4 }, { 300, 40 }, { 90, 30 } }) do
			local grid = fit(box[1], box[2], 3)
			local skew = BlockMath.Skew(grid, box[1] / box[2])
			if grid.cols >= 9 then
				assert(math.abs(skew) <= 0.06, box[1] .. "x" .. box[2] .. " cells are " .. skew .. " off square")
			end
		end
	end)
end)

describe("Block screens: Compass", function()
	-- Compass.luau: the strip is CompassData.StripWidth (0.34) of the width by 0.04 of the height, a fitted flat block of three
	-- rows; the heading block is 0.3 x 0.8 of the strip at aspect 2.4, flat, three rows; a diamond is 0.78 of the strip square.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local stripW, stripH = 0.34 * screen.w, 0.04 * screen.h
		it(label .. ": the strip is three rows of whole cells, its ink a px and a half or more, flat (four frames)", function()
			local grid = fit(stripW, stripH, MIN_ROWS)
			expect(grid.rows).toEqual(3)
			local cell = stripH * grid.cellY
			assert(cell >= 3.5, "strip cell is " .. cell .. " px")
			assert(INK * cell >= 1.5, "strip ink is " .. INK * cell .. " px")
			expect(BlockMath.Frames(grid, false, SEED)).toEqual(4)
		end)
		it(label .. ": the heading block keeps a px of ink and the letters' caps fit the strip's face", function()
			local _, h = BlockMath.FitPx(0.3 * stripW, 0.8 * stripH, 2.4, stripW, stripH)
			local cell = h / (3 + 2 * INK)
			assert(INK * cell >= 1, "heading ink is " .. INK * cell .. " px")
			local grid = fit(stripW, stripH, MIN_ROWS)
			local face = stripH * (1 - 2 * grid.inkY)
			assert(face >= 0.7 * TEXT_MIN, "strip face is " .. face .. " px, under a 14 px line's cap height")
		end)
		it(label .. ": a diamond's pixel is a px or more", function()
			local unit = 0.78 * stripH / 8
			assert(unit >= 1, "diamond pixel is " .. unit .. " px")
		end)
	end
end)

-- A modal panel: Size (sizeX, height) of the screen at `aspect`, rows from its height at the panel cell. Answers its px box and grid.
local function panel(screen: { w: number, h: number }, sizeX: number, height: number, aspect: number): (number, number, BlockMath.Grid)
	local w, h = BlockMath.FitPx(sizeX, height, aspect, screen.w, screen.h)
	return w, h, BlockMath.Grid(aspect, BlockMath.Rows(height, PANEL_CELL, INK, MIN_ROWS), INK)
end

-- The header tab (0.42 x 0.11 of the panel, three rows) and the close button (0.11 x 0.14, square, rows from 0.14 of the panel's
-- height share) every modal shares (Builder.blockHeader, Builder.blockClose).
local function shell(screen: { w: number, h: number }, panelW: number, panelH: number, height: number)
	local headerGrid = BlockMath.Grid(0.42 * panelW / (0.11 * panelH), 3, INK)
	local headerCell = 0.11 * panelH * headerGrid.cellY
	assert(headerCell >= 4.5, "header cell is " .. headerCell .. " px")
	assert(0.11 * panelH * (1 - 2 * headerGrid.inkY) >= TEXT_MIN, "the title's 14 px line does not fit the header face")
	local closeRows = BlockMath.Rows(0.14 * height - CELL, CELL, INK, MIN_ROWS)
	local lip = BlockMath.Lip(1, closeRows, INK)
	local face = 0.14 * panelH * (1 - lip)
	assert(face >= 0.6 * TAP_MIN, "the close face is " .. face .. " px (the hit area makes 44)")
end

describe("Block screens: Aliens", function()
	-- AliensScreen.luau: the panel 0.8 x 0.84 at 1.35; a card is 0.18 of the grid (the panel less its margins and a 6 px bar),
	-- square, an edged block of ten rows; a chip is 0.19 of the card tall, a fitted flat block of three rows.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local w, h, grid = panel(screen, 0.8, 0.84, 1.35)
		it(label .. ": the panel is 27 by 20 panel cells, square, under 200 frames, and its shell fits", function()
			expect(grid.rows).toEqual(20)
			expect(grid.cols).toEqual(27)
			assert(math.abs(BlockMath.Skew(grid, 1.35)) <= 0.06, "panel cells off square")
			local cell = h * grid.cellY
			assert(cell >= 2 * 7 and cell <= 2 * 17, "panel cell is " .. cell .. " px")
			assert(BlockMath.Frames(grid, true, SEED) <= 200, "panel draws " .. BlockMath.Frames(grid, true, SEED) .. " frames")
			shell(screen, w, h, 0.84)
		end)
		it(label .. ": an alien card is ten rows of cells near the HUD's, eight frames, its chips a px of ink or more", function()
			-- the grid is 0.64 of the panel beside the featured card (three columns of 0.31) or the whole 0.96 under a strip (five of 0.18)
			local mode = FeaturedMath.Mode(w, h)
			local cols, cellW = FeaturedMath.AliensGrid(mode)
			local gridW = if mode == "side" then Panels.Featured.Side.GridW else Panels.Featured.Wide.W
			assert(cols == (if mode == "side" then 3 else 5), "the columns follow the mode")
			local card = cellW * (gridW * w - 6)
			local cardGrid = BlockMath.Grid(1, 10, INK)
			local cell = card * cardGrid.cellY
			assert(cell >= 6 and cell <= 17, "card cell is " .. cell .. " px")
			expect(BlockMath.Frames(cardGrid, false, SEED, true)).toEqual(8)
			local chip = 0.19 * card
			assert(INK * chip / (3 + 2 * INK) >= 1.4, "chip ink is " .. INK * chip / (3 + 2 * INK) .. " px")
		end)
	end
end)

describe("Aliens header and grid", function()
	-- AliensScreen.luau "Panel layout" and data/Panels.Featured.Aliens. The panel 0.8 x 0.84 at 1.35 (the band fills its top 0.16);
	-- down it the station strip, then the featured card beside the grid (the side mode, a panel of 620 by 330 px or more) or the card as a
	-- strip over the grid (the strip mode), the footer's button row and the info line, none over another and the last clear of the
	-- panel's edge.
	local A = Panels.Featured.Aliens
	local W = Panels.Featured.Wide
	local FOOTER_Y, FOOTER_H, INFO_Y, INFO_H = 0.864, 0.072, 0.939, 0.041
	local BAY_W, TOKEN_W, FUSE_W, OPTIMIZE_W, FOOTER_GAP, MARGIN = 0.38, 0.21, 0.165, 0.175, 0.01, 0.02
	-- Widths at the 14 px floor in Fredoka One: "+20 storage: 2,500 Scrap", "Use Token (1)", "Optimize".
	local BAY_PX, TOKEN_PX, OPTIMIZE_PX = 156, 86, 57
	local screens = {
		{ name = "iPhone SE", w = 667, h = 375 },
		{ name = "iPad", w = 1080, h = 810 },
		{ name = "default window", w = 1154, h = 663 },
		{ name = "1280x720", w = 1280, h = 720 },
		{ name = "844x390", w = 844, h = 390 },
		{ name = "1920x1080", w = 1920, h = 1080 },
	}
	it("the strip, the card, the grid, the buttons and the info line stand one under another inside the panel, in both modes", function()
		assert(A.StationY >= 0.16, "the strip starts under the band")
		assert(A.StationY + A.StationH <= A.SideTop, "side mode: strip over the card and the grid")
		assert(A.Bottom <= FOOTER_Y, "side mode: the grid over the buttons")
		assert(A.StationY + A.StationH <= A.StripTop, "strip mode: stations over the card")
		assert(A.StripTop + A.StripH <= A.StripGridTop, "strip mode: card over the grid")
		assert(A.StripGridTop < A.Bottom, "strip mode: the grid has a window")
		assert(FOOTER_Y + FOOTER_H <= INFO_Y, "buttons over info line")
		assert(INFO_Y + INFO_H <= 1 - MARGIN + EPS, "the info line is clear of the panel's edge")
		assert(MARGIN + BAY_W + FOOTER_GAP <= 1 - MARGIN - OPTIMIZE_W - FOOTER_GAP - FUSE_W - FOOTER_GAP - TOKEN_W + EPS, "Bay under the token button")
	end)
	for _, screen in ipairs(screens) do
		local w, h = BlockMath.FitPx(0.8, 0.84, 1.35, screen.w, screen.h)
		local mode = FeaturedMath.Mode(w, h)
		it(screen.name .. " (" .. mode .. " mode): the grid shows the tiles it promises and each is 70 px or more wide", function()
			local cols, cellW, gapW = FeaturedMath.AliensGrid(mode)
			local gridW = (if mode == "side" then Panels.Featured.Side.GridW else W.W) * w
			local gridTop = if mode == "side" then A.SideTop else A.StripGridTop
			local window = (A.Bottom - gridTop) * h
			local cell = cellW * gridW -- layoutGrid: the cell's height is its width of the grid's whole width
			local gap = gapW * gridW
			assert(cellW * (gridW - 6) >= 70, "a tile is " .. cellW * (gridW - 6) .. " px wide")
			assert(cols * cellW + (cols - 1) * gapW <= 1 + EPS, "the columns fit the canvas")
			if mode == "side" then
				assert(window >= 1.5 * cell + gap, "the side grid shows " .. window .. " px, a row and a half is " .. 1.5 * cell + gap)
			else
				assert(window >= cell + gap + 0.3 * cell, "the strip grid shows " .. window .. " px: one row and a peek is " .. cell + gap + 0.3 * cell)
			end
		end)
		it(screen.name .. ": the station strip holds its three lines, the info line a 14 px line, and the buttons their words", function()
			assert(A.StationH * h >= 3 * 14 + 12, "strip is " .. A.StationH * h .. " px")
			assert(INFO_H * h >= 12.5, "info line is " .. INFO_H * h .. " px")
			assert(BAY_W * w >= BAY_PX and TOKEN_W * w >= TOKEN_PX and OPTIMIZE_W * w >= OPTIMIZE_PX + 12, "a footer button is too narrow")
			assert(FUSE_W * w >= 60, "Fuse is " .. FUSE_W * w .. " px")
		end)
		it(screen.name .. ": a footer button's 44 px hit area grows only up and down, never into its neighbour or far into the grid", function()
			-- The hit area is the face's width (every button is 44 px or wider, so it stays that wide) and 44 px tall, centred on the face
			-- (Builder.blockButton `hit`, Theme.TapMin): it reaches (44 - face) / 2 px above and below the face.
			local face = FOOTER_H * h
			local reach = math.max(0, (44 - face) / 2)
			assert(FUSE_W * w >= 44 and OPTIMIZE_W * w >= 44 and TOKEN_W * w >= 44 and BAY_W * w >= 44, "a footer button is under 44 px wide")
			assert(reach <= 12, "the hit area reaches " .. reach .. " px past the face")
			assert(reach - (FOOTER_Y - A.Bottom) * h <= 10, "it overlaps the grid's last row by " .. reach .. " px")
		end)
		it(screen.name .. ": the featured card's lines fit their boxes at the 14 px floor and its buttons are reachable", function()
			local c = Panels.Featured.Card
			if mode == "side" then
				local cardH = (A.Bottom - A.SideTop) * h
				assert(c.Flavour * cardH >= 2 * 14, "the flavour box is " .. c.Flavour * cardH .. " px, two lines need 28")
				assert(c.Tag * cardH >= 17, "the tag is " .. c.Tag * cardH .. " px, its 14 px word needs about 17")
				assert(c.Name * cardH >= 20, "the name is " .. c.Name * cardH .. " px")
				assert(c.Button * cardH >= 0.6 * TAP_MIN, "the button face is " .. c.Button * cardH .. " px (the hit area makes 44)")
			else
				local stripH = A.StripH * h
				local s2 = Panels.Featured.StripCard
				assert(stripH >= 44, "the strip is " .. stripH .. " px tall")
				assert(s2.NameH * stripH >= 20, "the name row is " .. s2.NameH * stripH .. " px")
				assert(s2.FlavourH * stripH >= 14, "the flavour row is " .. s2.FlavourH * stripH .. " px")
				assert(s2.TagH * stripH >= 17, "the tag is " .. s2.TagH * stripH .. " px")
				assert(s2.ButtonH * stripH >= 0.6 * TAP_MIN, "the button face is " .. s2.ButtonH * stripH .. " px (the hit area makes 44)")
			end
		end)
	end
end)

describe("Aliens slot names", function()
	-- AliensScreen.luau buildStationCard / buildSlot (Studio 2026-10-22: "Moo" for Moop, "Ope" for Open). The strip is the panel
	-- less two 0.02 margins and 0.195 of its height; a station card (1 - 0.02 (jobs - 1)) / jobs of it; the slot row SLOTS_W 0.96
	-- of the card and 0.44 of its height; a slot (1 - 0.02 (n - 1)) / n of the row, its name one line across the slot's pitch
	-- (its own width, no wider: the gap stays a gap between names) on the row's lower 1 - SLOT_SQUARE_H (0.54). Widths at the 14 px floor in Fredoka One
	-- (assets/fonts/FredokaOne.ttf): the open slot's "Open" (Strings.STATION_EMPTY_SLOT), the Moop, and Boulden, the longest
	-- species name in data/Species. A name wider than its label ends in an ellipsis (TextTruncate), never a cut second line.
	local OPEN_PX, MOOP_PX, LONGEST_PX = 35.5, 37.1, 55.4
	local GAP, SLOTS_W, SQUARE_H = 0.02, 0.96, 0.46
	local function slotLabel(screen: { w: number, h: number }, jobs: number, slots: number): (number, number)
		local w, h = BlockMath.FitPx(0.8, 0.84, 1.35, screen.w, screen.h)
		local strip = (1 - 2 * 0.02) * w
		local card = (1 - GAP * (jobs - 1)) / jobs * strip
		local row = SLOTS_W * card
		local slot = (1 - GAP * (slots - 1)) / slots
		return slot * row, (1 - SQUARE_H) * 0.44 * 0.195 * h
	end
	it("iPhone SE, three stations of three slots: Open and Moop fit whole on one line at the floor", function()
		local width, height = slotLabel(SE, 3, 3)
		assert(width >= MOOP_PX + 2 and width >= OPEN_PX + 2, "slot label is " .. width .. " px")
		assert(height >= TEXT_MIN, "slot label is " .. height .. " px tall")
	end)
	it("iPad: every species name fits whole, three slots or the bonus fourth", function()
		for _, slots in ipairs({ 3, 4 }) do
			local width, height = slotLabel(IPAD, 3, slots)
			assert(width >= LONGEST_PX + 2, slots .. " slots: label is " .. width .. " px")
			assert(height >= TEXT_MIN, "slot label is " .. height .. " px tall")
		end
	end)
	it("the label is as wide as the slot and keeps a gap to its neighbour", function()
		-- the label is the slot (1 - 0.02 (n - 1)) / n of the row; the pitch to the next slot is the slot and the gap, so a gap of
		-- 0.02 of the row (about 2 px at SE) lies between two names and they never meet
		local width = slotLabel(SE, 3, 3)
		local w = BlockMath.FitPx(0.8, 0.84, 1.35, SE.w, SE.h)
		local row = SLOTS_W * (1 - GAP * 2) / 3 * (1 - 2 * 0.02) * w
		assert(row - 3 * width > 0 and (row - 3 * width) / 2 >= 0.019 * row, "no gap between names: " .. width .. " in " .. row)
	end)
end)

describe("Block screens: Quests", function()
	-- QuestsScreen.luau: the Aliens panel's shell (0.8 x 0.78 at 1.35); the What's on band 0.96 x 0.106 of the panel, a fitted plate
	-- in cells, rows from its screen height; a tab 0.12 of the panel tall, a fitted block button.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local w, h = panel(screen, 0.8, 0.78, 1.35)
		it(label .. ": the What's on band is HUD cells, square, under 100 frames, and a 14 px line fits each half", function()
			local bandW, bandH = 0.96 * w, 0.106 * h
			local grid = fit(bandW, bandH, BlockMath.Rows(0.106 * 0.78, CELL, INK, MIN_ROWS))
			local cell = bandH * grid.cellY
			assert(cell >= 4.5, "band cell is " .. cell .. " px")
			assert(math.abs(BlockMath.Skew(grid, bandW / bandH)) <= 0.06, "band cells off square")
			assert(BlockMath.Frames(grid, true, SEED) <= 100, "band draws " .. BlockMath.Frames(grid, true, SEED) .. " frames")
		end)
		it(label .. ": a tab is three rows or more with a 14 px face", function()
			local rows = BlockMath.Rows(0.12 * 0.78 - CELL, CELL, INK, MIN_ROWS)
			local lip = BlockMath.Lip(1, rows, INK)
			local face = 0.12 * h * (1 - lip)
			assert(face * (1 - 2 * INK / (rows + 2 * INK)) >= TEXT_MIN, "the tab face is " .. face .. " px")
		end)
	end
end)

-- "Block screens: Settings" moved to tests/PanelQuiet.spec.luau (Clean UI pass, package C): the Settings panel is now
-- 0.64 x 0.84 with headings and six-row cards, and that spec measures it with every data/Settings row, Announcements included.

describe("Block screens: Toast and NotifyCard", function()
	-- Toast.luau: a one-line toast is 0.42 of the width at 7, a banner 0.7 at 9, each an edged block whose rows come from its
	-- height; NotifyCard.luau: the card 0.5 x 0.6 at 1.5 at the panel cell, its buttons 0.22 of it tall.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		it(label .. ": a toast and a banner are the HUD's cell and eight frames", function()
			for _, shape in ipairs({ { 0.42, 7 }, { 0.7, 9 } }) do
				local h = shape[1] * screen.w / shape[2]
				local grid = BlockMath.Grid(shape[2], BlockMath.Rows(h / screen.h, CELL, INK, MIN_ROWS), INK)
				local cell = h * grid.cellY
				assert(cell >= 6 and cell <= 18, "toast cell is " .. cell .. " px")
				expect(BlockMath.Frames(grid, false, SEED, true)).toEqual(8)
			end
		end)
		it(label .. ": the notify card is panel cells and its buttons carry a 24 px label line", function()
			local _, h, grid = panel(screen, 0.5, 0.6, 1.5)
			assert(math.abs(BlockMath.Skew(grid, 1.5)) <= 0.06, "card cells off square")
			local rows = BlockMath.Rows(0.22 * 0.6 - CELL, CELL, INK, MIN_ROWS)
			local face = 0.22 * h * (1 - BlockMath.Lip(1, rows, INK))
			assert(face * (1 - (2 * INK + 0.5) / (rows + 2 * INK)) >= TEXT_MIN, "a button face is " .. face .. " px")
		end)
	end
end)

-- Every other modal in block cells: its panel's Size (of the screen) and aspect, as in its file. Each keeps square panel cells,
-- stays under 260 frames (a 1.6 panel is 31 by 19 cells, 209; the 2:1 Playtime panel 39 by 19, 256) and carries the shared
-- header tab and close button (Builder.blockHeader, Builder.blockClose).
local MODALS: { { name: string, w: number, h: number, aspect: number } } = {
	{ name = "Codex", w = 0.8, h = 0.78, aspect = 1.35 },
	{ name = "Release", w = 0.54, h = 0.7, aspect = 1.25 },
	{ name = "Afk", w = 0.5, h = 0.7, aspect = 1.4 },
	{ name = "Ship", w = 0.8, h = 0.78, aspect = 1.35 },
	{ name = "Gifts", w = 0.86, h = 0.78, aspect = 1.8 },
	{ name = "StarChart", w = 0.84, h = 0.78, aspect = 1.75 },
	{ name = "Visit", w = 0.8, h = 0.78, aspect = 1.6 },
	{ name = "Playtime", w = 0.92, h = 0.78, aspect = 2 },
	{ name = "Peddler", w = 0.8, h = 0.78, aspect = 1.35 },
	{ name = "Leaderboard", w = 0.62, h = 0.8, aspect = 1.15 },
	{ name = "Mail", w = 0.8, h = 0.78, aspect = 1.6 },
}

describe("Block screens: modal panels", function()
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		it(label .. ": every modal's panel is square panel cells under 260 frames, and its shell fits", function()
			for _, modal in ipairs(MODALS) do
				local w, h, grid = panel(screen, modal.w, modal.h, modal.aspect)
				local skew = BlockMath.Skew(grid, modal.aspect)
				assert(math.abs(skew) <= 0.06, modal.name .. " panel cells are " .. skew .. " off square")
				local frames = BlockMath.Frames(grid, true, SEED)
				assert(frames <= 260, modal.name .. " panel draws " .. frames .. " frames")
				shell(screen, w, h, modal.h)
			end
		end)
	end
	it("a Star Chart planet's pixel and an orbit dot are two px or more at iPhone SE", function()
		-- StarChartScreen.luau: the map square is the smaller of 0.58 of the panel's width and 0.8 of its height; a planet is 0.12
		-- of it, an 8 by 8 pixel octagon; an orbit dot 0.012 of it.
		local w, h = BlockMath.FitPx(0.84, 0.78, 1.75, SE.w, SE.h)
		local map = math.min(0.58 * w, 0.8 * h)
		assert(0.12 * map / 8 >= 2, "a planet pixel is " .. 0.12 * map / 8 .. " px")
		assert(0.012 * map >= 2, "an orbit dot is " .. 0.012 * map .. " px")
	end)
	it("a Codex card of 81 px (iPhone SE's narrowest) is ten rows of the HUD's cell", function()
		local cell = 81 / (10 + 2 * INK)
		assert(cell >= 7 and cell <= 8.5, "Codex card cell is " .. cell .. " px")
	end)
end)

describe("Block screens: Shop", function()
	-- ShopScreen.luau with data/Shop.Shelf: a card is 0.78 of the screen tall at 0.41 (fitted, edged, rows from its height); its
	-- price a fitted flat block button 0.123 of the card tall; the ribbon 0.095 of the card (a flat plate 1 - 0.7 / 4 of it); the
	-- seal a pixel octagon 0.64 of the card's width; the scrollbar 0.026 of the screen, flat; the Scrap plate 0.2 x 0.095 at 3.6.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local cardH = 0.78 * screen.h
		local cardW = 0.41 * cardH
		it(label .. ": a card is the HUD's cell, eight frames, and its price and ribbon carry a 14 px line", function()
			local grid = fit(cardW, cardH, BlockMath.Rows(0.78, CELL, INK, MIN_ROWS))
			local cell = cardH * grid.cellY
			assert(cell >= 7 and cell <= 17, "card cell is " .. cell .. " px")
			assert(math.abs(BlockMath.Skew(grid, cardW / cardH)) <= 0.06, "card cells off square")
			expect(BlockMath.Frames(grid, false, SEED, true)).toEqual(8)
			local pill = 0.123 * cardH
			local lip = BlockMath.Lip(1, 3, INK)
			local face = pill * (1 - lip)
			local inner = face * (1 - (2 * INK + 0.5) / (3 + 2 * INK)) -- inside the ink and the quarter-cell text padding
			assert(inner >= TEXT_MIN, "the price face holds " .. inner .. " px of text")
			local ribbon = 0.095 * cardH * (1 - 0.7 / 4)
			assert(ribbon * (1 - 2 * INK / (3 + 2 * INK)) >= TEXT_MIN, "the ribbon face is " .. ribbon .. " px")
			assert(0.64 * cardW / 8 >= 1, "a seal pixel is under a px")
		end)
		it(label .. ": the scrollbar is a thin flat band with a px of ink, the Scrap plate the HUD's", function()
			local barH = 0.026 * screen.h
			assert(INK * barH / (3 + 2 * INK) >= 1, "scrollbar ink is " .. INK * barH / (3 + 2 * INK) .. " px")
			local _, h = BlockMath.FitPx(0.2, 0.095, 3.6, screen.w, screen.h)
			local grid = BlockMath.Grid(3.6, BlockMath.Rows(0.095, CELL, INK, MIN_ROWS), INK)
			local cell = h * grid.cellY
			assert(cell >= 4.5, "Scrap plate cell is " .. cell .. " px")
		end)
	end
end)

describe("Block screens: Capture bar", function()
	-- CaptureBar.luau: the trough a fitted plate in cells, 0.6 x 0.06 of the screen, rows from its height; the zones exact bands of
	-- its face (BlockMath.Span), the trail a whole cell at a time (CellStep), the marker a 7 by 11 pixel arrow, a pixel a sixth of
	-- the bar's height; the lure and countdown chips 0.2 x 0.05, edged blocks.
	local Tiers = require(Shared.data.Tiers)
	local narrowest = math.huge
	for _, tier in pairs(Tiers.Tiers) do
		narrowest = math.min(narrowest, tier.perfectZone)
	end
	it("measures the marker and the zones on one span, with exact edges", function()
		local grid = BlockMath.Grid(17.8, 3, INK)
		local inner = BlockMath.Inner(grid)
		expect(BlockMath.Along(grid, 0)).toBeClose(inner.x, EPS)
		expect(BlockMath.Along(grid, 1)).toBeClose(inner.x + inner.w, EPS)
		expect(BlockMath.Along(grid, 2)).toBeClose(inner.x + inner.w, EPS)
		local span = BlockMath.Span(grid, 0.44, 0.12)
		expect(#span).toEqual(2)
		for _, rect in ipairs(span) do
			expect(rect.x).toBeClose(BlockMath.Along(grid, 0.44), EPS)
			expect(rect.w).toBeClose(0.12 * inner.w, EPS)
		end
		-- At the bar's end the band keeps the stepped corner: the tall bar stops a cell short of the ink.
		local edge = BlockMath.Span(grid, 0.98, 0.02)
		local tall = edge[2]
		expect(tall.x + tall.w).toBeClose(1 - grid.inkX - grid.cellX, EPS)
		expect(BlockMath.Span(grid, 0.5, 0)[1].w).toEqual(0)
	end)
	it("steps the trail a whole cell at a time and never past the bar", function()
		expect(BlockMath.CellStep(10, 0.34)).toBeClose(0.3, EPS)
		expect(BlockMath.CellStep(10, 0.3)).toBeClose(0.3, EPS)
		expect(BlockMath.CellStep(10, 1.4)).toEqual(1)
		expect(BlockMath.CellStep(10, -1)).toEqual(0)
		expect(BlockMath.CellStep(0, 0.37)).toBeClose(0.37, EPS)
	end)
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local barW, barH = 0.6 * screen.w, 0.06 * screen.h
		local grid = fit(barW, barH, BlockMath.Rows(0.06, CELL, INK, MIN_ROWS))
		it(label .. ": the trough is three rows of square cells near the HUD's, under 160 frames", function()
			expect(grid.rows).toEqual(3)
			local cell = barH * grid.cellY
			assert(cell >= 5 and cell <= 14, "trough cell is " .. cell .. " px")
			assert(math.abs(BlockMath.Skew(grid, barW / barH)) <= 0.06, "trough cells off square")
			local frames = BlockMath.Frames(grid, true, SEED)
			assert(frames <= 160, "trough draws " .. frames .. " frames")
		end)
		it(label .. ": the narrowest Perfect zone is a cell wide or more, and the arrow's pixel 3 px or more", function()
			local cellPx = barW * grid.cellX
			local zonePx = narrowest * barW * (1 - 2 * grid.inkX)
			assert(zonePx >= cellPx, "the narrowest Perfect zone is " .. zonePx .. " px, under a " .. cellPx .. " px cell")
			assert(barH / 6 >= 3, "an arrow pixel is " .. barH / 6 .. " px")
		end)
		it(label .. ": a chip's face holds a 14 px line", function()
			local chipH = 0.05 * screen.h
			local rows = BlockMath.Rows(0.05, CELL, INK, MIN_ROWS)
			local face = chipH * (1 - 2 * INK / (rows + 2 * INK))
			assert(0.75 * chipH >= TEXT_MIN and face >= TEXT_MIN, "a chip holds " .. 0.75 * chipH .. " px of text")
		end)
	end
end)
describe("Block screens: Reveal", function()
	-- Reveal.luau with data/Reveal: the card 0.6 x 0.56 of the screen at 0.8, rows from its height at CardCell; the buttons
	-- ButtonHeightPx at the reference height (375) by ButtonWidth, fitted block buttons of ButtonRows; the chance plate OddsWidth x
	-- OddsHeight of the card, a flat block of OddsRows; the pixel egg EggHeight of the screen on EggRows pixels; a shard a flat
	-- block of 7 rows ShardHeight tall.
	local RevealData = require(Shared.data.Reveal)
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local cardW, cardH = BlockMath.FitPx(0.6, 0.56, 0.8, screen.w, screen.h)
		local cardGrid = BlockMath.Grid(0.8, BlockMath.Rows(0.56, RevealData.CardCell, INK, MIN_ROWS), INK)
		it(label .. ": the card is the panel cell, square, under 100 frames", function()
			local cell = cardH * cardGrid.cellY
			assert(cell >= 12 and cell <= 34, "card cell is " .. cell .. " px")
			assert(math.abs(BlockMath.Skew(cardGrid, cardW / cardH)) <= 0.06, "card cells off square")
			local frames = BlockMath.Frames(cardGrid, true, SEED)
			assert(frames <= 100, "card draws " .. frames .. " frames")
		end)
		it(label .. ": a button's padded text box holds the 24 px label, and its face clears the 44 px hit floor with the hit area", function()
			local h = RevealData.ButtonHeightPx / RevealData.ReferenceHeight * screen.h
			local rows = RevealData.ButtonRows
			local face = h * (1 - BlockMath.Lip(1, rows, INK))
			local text = face * (1 - (2 * INK + 0.5) / (rows + 2 * INK))
			assert(text >= TEXT_MIN, "a button's text box is " .. text .. " px")
			local cell = face / (rows + 2 * INK)
			assert(cell >= 4.5, "a button cell is " .. cell .. " px")
			assert(h >= TAP_MIN, "a button is " .. h .. " px tall")
		end)
		it(label .. ": the chance plate's face holds a 14 px line", function()
			local plateH = RevealData.OddsHeight * cardH
			local face = plateH * (1 - 2 * INK / (RevealData.OddsRows + 2 * INK))
			assert(face >= TEXT_MIN, "the chance plate's face is " .. face .. " px")
		end)
		it(label .. ": an egg pixel and a shard cell are 3 px or more", function()
			local pixel = RevealData.EggHeight * screen.h / RevealData.EggRows
			assert(pixel >= 3, "an egg pixel is " .. pixel .. " px")
			local shard = RevealData.ShardHeight * screen.h / (7 + 2 * INK)
			assert(shard >= 3, "a shard cell is " .. shard .. " px")
		end)
	end
end)

describe("Block budget", function()
	-- Studio 2026-10-22: "UI.Builder Script timeout: exhausted allowed execution time" once at each start, in fitPlate's measure
	-- then draw, while the server loads. A 1 px camera viewport under a laid-out GUI asked for thousands of rows. Builder now
	-- picks a fitted plate's rows with BlockMath.ScreenRows (no screen yet: keep the guess), draws a grid over MAX_CELLS as an
	-- edged block, caches grout and jitter per grid, and runs the measures in batches of Theme.Block.FitBudget a frame.
	local MAX_CELLS = 6000 -- Theme.Block.MaxCells (tools/tests/test_block_theme.py checks it)
	it("a real measurement picks the rows as before; one no screen makes keeps the fallback", function()
		expect(BlockMath.ScreenRows(0.085 * SE.h, SE.h, CELL, INK, MIN_ROWS, 0)).toEqual(BlockMath.Rows(0.085, CELL, INK, MIN_ROWS))
		expect(BlockMath.ScreenRows(300, 1, CELL, INK, MIN_ROWS, 0)).toEqual(0) -- the 1 px viewport at start
		expect(BlockMath.ScreenRows(300, 0, CELL, INK, MIN_ROWS, 7)).toEqual(7)
		expect(BlockMath.ScreenRows(0, 375, CELL, INK, MIN_ROWS, 7)).toEqual(7)
		-- the most rows a real plate can ask for is a whole screen's
		expect(BlockMath.ScreenRows(SE.h, SE.h, CELL, INK, MIN_ROWS, 0)).toEqual(BlockMath.Rows(1, CELL, INK, MIN_ROWS))
	end)
	it("every real grid is within the budget; the start-up one was not", function()
		local playtime = BlockMath.Grid(2, BlockMath.Rows(0.78, PANEL_CELL, INK, MIN_ROWS), INK) -- the widest panel, 39 by 19
		expect(playtime.cols * playtime.rows).toEqual(741)
		assert(BlockMath.WithinBudget(playtime, MAX_CELLS), "the Playtime panel is over the budget")
		-- a fitted plate the size of the whole screen, its rows picked at the HUD's cell, on a phone and a 21:9 monitor
		for _, aspect in ipairs({ SE.w / SE.h, 21 / 9 }) do
			local wholeScreen = BlockMath.Grid(aspect, BlockMath.Rows(1, CELL, INK, MIN_ROWS), INK)
			assert(BlockMath.WithinBudget(wholeScreen, MAX_CELLS), "a full-screen plate at the HUD cell is " .. wholeScreen.rows * wholeScreen.cols)
		end
		local captureBar = BlockMath.Grid(0.6 * SE.w / (0.06 * SE.h), 3, INK)
		assert(BlockMath.WithinBudget(captureBar, MAX_CELLS), "the capture bar is over the budget")
		local startup = BlockMath.Grid(1.5, BlockMath.Rows(300 / 1, CELL, INK, MIN_ROWS), INK)
		expect(BlockMath.WithinBudget(startup, MAX_CELLS)).toEqual(false)
		-- and its frames, had it drawn, against an edged block's eight
		assert(startup.rows * startup.cols > 1e7, "the start-up grid is " .. startup.rows * startup.cols .. " cells")
		expect(BlockMath.Frames(startup, false, SEED, true)).toEqual(8)
	end)
	it("the cached grout and jitter are the uncached ones, worked out once per grid", function()
		for _, aspect in ipairs({ 1, 3.6, 4.2, 6, 1.35 }) do
			for _, rows in ipairs({ 3, 5, 10, 19 }) do
				local grid = BlockMath.Grid(aspect, rows, INK)
				local grout, jitter = BlockMath.Grout(grid, GROUT), BlockMath.Jittered(grid, SEED)
				local cachedGrout, cachedJitter = BlockMath.GroutCached(grid, GROUT), BlockMath.JitteredCached(grid, SEED)
				expect(#cachedGrout).toEqual(#grout)
				expect(#cachedJitter).toEqual(#jitter)
				for index, rect in ipairs(grout) do
					local other = cachedGrout[index]
					expect(other.x).toBeClose(rect.x, EPS)
					expect(other.y).toBeClose(rect.y, EPS)
					expect(other.w).toBeClose(rect.w, EPS)
					expect(other.h).toBeClose(rect.h, EPS)
				end
				for index, cell in ipairs(jitter) do
					local other = cachedJitter[index]
					expect(other.col).toEqual(cell.col)
					expect(other.row).toEqual(cell.row)
					expect(other.level).toEqual(cell.level)
				end
				-- the same grid again is the same answer, not a new one
				expect(BlockMath.GroutCached(BlockMath.Grid(aspect, rows, INK), GROUT) == cachedGrout).toEqual(true)
				expect(BlockMath.JitteredCached(BlockMath.Grid(aspect, rows, INK), SEED) == cachedJitter).toEqual(true)
			end
		end
		-- another seed is another answer
		local grid = BlockMath.Grid(3.6, 5, INK)
		expect(BlockMath.JitteredCached(grid, SEED) == BlockMath.JitteredCached(grid, SEED + 1)).toEqual(false)
	end)
	it("the caches stay bounded through a resize sweep", function()
		for cols = 3, 400 do
			local grid = BlockMath.Grid(cols / 3.8, 3, INK)
			BlockMath.GroutCached(grid, GROUT)
			BlockMath.JitteredCached(grid, SEED)
		end
		local grouts, jitters = BlockMath.CacheSize()
		assert(grouts <= 256 and jitters <= 256, "the caches hold " .. grouts .. " and " .. jitters)
	end)
end)

return true
