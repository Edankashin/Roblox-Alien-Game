--!strict
-- Shared.BlockMath: the block-cell plate (UI Playbook "Block cells", Blocky-Style C1 to C6) and the HUD's fit in it at iPhone SE
-- (667x375) and iPad (1080x810). The parameters are Theme.Block's (Theme needs the Roblox runtime, so
-- tools/tests/test_block_theme.py reads them out of src/shared/Theme.luau and checks they are these), and the HUD rows mirror
-- the sizes and aspects in src/client/UI/Hud.luau: change one, change the other.
local Shared = game:GetService("ReplicatedStorage").Shared
local BlockMath = require(Shared.BlockMath)

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

-- Hud.luau: the Scrap plate, the clock, biome and shower chips, the ship bar, the event banner, the Friend chip, a top button,
-- a menu button (its size is 0.095 of the screen height inside a 0.12 x 0.13 slot at aspect 0.8) and the action button.
local HUD: { Plate } = {
	{ name = "ScrapPill", sizeX = 0.3, sizeY = 0.085, aspect = 3.6, height = 0.085, text = true },
	{ name = "ClockChip", sizeX = 0.3, sizeY = 0.075, aspect = 4.2, height = 0.075, text = true },
	{ name = "BiomeChip", sizeX = 0.2, sizeY = 0.05, aspect = 4.2, height = 0.05, text = true },
	{ name = "ShowerChip", sizeX = 0.2, sizeY = 0.05, aspect = 4.2, height = 0.05, text = true },
	{ name = "ShipBar", sizeX = 0.3, sizeY = 0.075, aspect = 4.2, height = 0.075, text = true },
	{ name = "EventBanner", sizeX = 0.4, sizeY = 0.07, aspect = 6, height = 0.07 },
	{ name = "FriendChip", sizeX = 0.3, sizeY = 0.055, aspect = 5.5, height = 0.055, text = true },
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
	it("iPhone SE: the cells are 4.9 to 8.4 px, near the board's 8 px at 390 tall", function()
		local small, large = math.huge, 0
		for _, plate in ipairs(HUD) do
			local _, h, grid = measure(plate, SE)
			local cell = h * grid.cellY
			small, large = math.min(small, cell), math.max(large, cell)
		end
		expect(small).toBeClose(4.93, 0.01) -- the biome and shower chips
		expect(large).toBeClose(8.39, 0.01) -- the Scrap plate
	end)
end)

-- The screens after the HUD (UI Playbook "Block cells", "Screens in block cells"). A fitted plate (Builder.blockPlate with no
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

describe("Block screens: Nearby", function()
	-- NearbyPanel.luau: the column is 0.1 of the width by 0.405 of the height (at its default top), a fitted plate in cells whose
	-- rows come from its height; the list is 0.86 of it and 0.9 wide; a row is at most 0.24 of the list, its icon 0.62 of the row,
	-- a flat block of three rows with the tier's ink; eight rows share the list with 0.015 gaps.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local colW, colH = 0.1 * screen.w, 0.405 * screen.h
		local rows = BlockMath.Rows(0.405, CELL, INK, MIN_ROWS)
		it(label .. ": the column's cells are near the HUD's, square within 6%, and under 90 frames", function()
			local grid = fit(colW, colH, rows)
			local cell = colH * grid.cellY
			assert(cell >= 7 and cell <= 17, "column cell is " .. cell .. " px")
			local skew = BlockMath.Skew(grid, colW / colH)
			assert(math.abs(skew) <= 0.06, "column cells are " .. skew .. " off square")
			local frames = BlockMath.Frames(grid, true, SEED)
			assert(frames <= 90, "column draws " .. frames .. " frames")
		end)
		it(label .. ": a tall row's icon keeps a 2 px tier ink, a row of eight still a px", function()
			local listH = 0.86 * colH
			local tall = 0.24 * listH * 0.62
			local short = (1 - 0.015 * 7) / 8 * listH * 0.62
			assert(INK * tall / (3 + 2 * INK) >= 1.9, "tall icon ink is " .. INK * tall / (3 + 2 * INK) .. " px")
			assert(INK * short / (3 + 2 * INK) >= 0.9, "short icon ink is " .. INK * short / (3 + 2 * INK) .. " px")
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
	-- AliensScreen.luau: the panel 0.8 x 0.78 at 1.35; a card is 0.22 of the grid (the panel less its margins and a 6 px bar),
	-- square, an edged block of ten rows; a chip is 0.17 of the card tall, a fitted flat block of three rows.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local w, h, grid = panel(screen, 0.8, 0.78, 1.35)
		it(label .. ": the panel is 26 by 19 panel cells, square, under 200 frames, and its shell fits", function()
			expect(grid.rows).toEqual(19)
			expect(grid.cols).toEqual(26)
			assert(math.abs(BlockMath.Skew(grid, 1.35)) <= 0.06, "panel cells off square")
			local cell = h * grid.cellY
			assert(cell >= 2 * 7 and cell <= 2 * 17, "panel cell is " .. cell .. " px")
			assert(BlockMath.Frames(grid, true, SEED) <= 200, "panel draws " .. BlockMath.Frames(grid, true, SEED) .. " frames")
			shell(screen, w, h, 0.78)
		end)
		it(label .. ": an alien card is ten rows of cells near the HUD's, eight frames, its chips a px of ink or more", function()
			local card = 0.22 * ((1 - 2 * 0.02) * w - 6)
			local cardGrid = BlockMath.Grid(1, 10, INK)
			local cell = card * cardGrid.cellY
			assert(cell >= 6 and cell <= 17, "card cell is " .. cell .. " px")
			expect(BlockMath.Frames(cardGrid, false, SEED, true)).toEqual(8)
			local chip = 0.17 * card
			assert(INK * chip / (3 + 2 * INK) >= 1.4, "chip ink is " .. INK * chip / (3 + 2 * INK) .. " px")
		end)
	end
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

describe("Block screens: Settings", function()
	-- SettingsScreen.luau: the panel 0.6 x 0.78 at 1.3; six rows share 0.68 of it with 0.03 gaps, each an edged block of three rows;
	-- a control is 0.78 of a row, a flat block button of three rows over its one-cell lip.
	for _, screen in ipairs({ SE, IPAD }) do
		local label = screen.w .. "x" .. screen.h
		local w, h, grid = panel(screen, 0.6, 0.78, 1.3)
		it(label .. ": the panel is panel cells, under 200 frames, and its shell fits", function()
			assert(math.abs(BlockMath.Skew(grid, 1.3)) <= 0.06, "panel cells off square")
			assert(BlockMath.Frames(grid, true, SEED) <= 200, "panel draws " .. BlockMath.Frames(grid, true, SEED) .. " frames")
			shell(screen, w, h, 0.78)
		end)
		it(label .. ": a row's cells are near the HUD's, and a control's face inside its ink is near the 14 px floor", function()
			local share = (1 - 0.03 * 5) / 6
			local row = 0.68 * share * h
			local cell = row / (3 + 2 * INK)
			assert(cell >= 6, "row cell is " .. cell .. " px")
			local control = 0.78 * row
			local face = control * (1 - BlockMath.Lip(1, 3, INK))
			local inner = face * (1 - 2 * INK / (3 + 2 * INK))
			-- 13.7 px at iPhone SE: the 14 px line touches the ink there (a known squeeze, UI Playbook "Settings"); 29.7 on the iPad
			assert(inner >= 13.5, "a control's face is " .. inner .. " px inside its ink")
		end)
	end
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
return true
