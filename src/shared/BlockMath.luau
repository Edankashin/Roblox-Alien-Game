--!strict
-- Shared.BlockMath: the arithmetic of a block-cell UI plate (UI Playbook "Block cells", Decisions B44, Blocky-Style C1 to C6).
-- A plate is a whole number of square cells (`rows` by `cols`) with its four corner cells cut away (the stepped pixel corner),
-- framed by an ink border `ink` cells thick. Everything comes out as fractions of the plate (Scale), so Builder.blockPlate
-- places frames with no Offset, and the cells stay square because the plate keeps its aspect (a UIAspectRatioConstraint).
-- Pure numbers, no Roblox types: tests/BlockMath.spec.luau runs it headless, including the HUD's fit at iPhone SE and iPad.

local BlockMath = {}

-- A plate's cell grid, as fractions of the plate. cellX and cellY are one cell's width and height; inkX and inkY the border's.
export type Grid = {
	rows: number,
	cols: number,
	ink: number, -- the border, in cells
	cellX: number,
	cellY: number,
	inkX: number,
	inkY: number,
}

-- A rectangle as fractions of the plate (x, y its top-left corner).
export type Rect = { x: number, y: number, w: number, h: number }

-- One jittered cell: its column and row (0-based) and its level, -1 a shade darker, 1 a shade lighter.
export type Jitter = { col: number, row: number, level: number }

-- The four lit and shaded border bands of C3: the top row a step lighter, the other border cells a step darker.
export type Bands = { top: Rect?, bottom: Rect?, left: Rect?, right: Rect? }

local JITTER_BUCKETS = 8 -- 1 : 6 : 1, as C2 says: one bucket a shade down, six level, one a shade up
local TWO32 = 4294967296

-- How many cell rows a plate `height` tall (a fraction of the screen height) gets, so a cell is about `cell` of the screen
-- height whatever the plate: round(height / cell - 2 * ink), at least `minRows` (three, so the corner cells can go and a face
-- is left: a two-row plate would lose its whole left and right columns).
function BlockMath.Rows(height: number, cell: number, ink: number, minRows: number): number
	if cell <= 0 then
		return minRows
	end
	return math.max(minRows, math.floor(height / cell - 2 * ink + 0.5))
end

-- The rows of a fitted plate measured at `boxY` px on a screen `screenY` px tall (Builder's fitPlate), or `fallback` when the
-- measurement cannot be a screen's: no screen yet, or a plate taller than its screen. At start the camera's viewport can read
-- 1 px while the GUI is already laid out, and 300 px of plate over 1 px of screen asked for some fifteen thousand rows, a grid
-- whose jitter pass ran past the script timeout (Studio 2026-10-22, `UI.Builder` "Script timeout: exhausted allowed execution
-- time" in fitPlate's measure). The plate keeps its first guess until a real measurement comes.
function BlockMath.ScreenRows(boxY: number, screenY: number, cell: number, ink: number, minRows: number, fallback: number): number
	if screenY <= 0 or boxY <= 0 or boxY > screenY then
		return fallback
	end
	return BlockMath.Rows(boxY / screenY, cell, ink, minRows)
end

-- The grid of a plate whose box is `aspect` (width over height, in px) with `rows` rows: the columns are the whole number that
-- comes closest to square cells, round(aspect * (rows + 2 ink) - 2 ink), never under 3.
function BlockMath.Grid(aspect: number, rows: number, ink: number): Grid
	local safeRows = math.max(1, math.floor(rows + 0.5))
	local tall = safeRows + 2 * ink
	local cols = math.max(3, math.floor(aspect * tall - 2 * ink + 0.5))
	local wide = cols + 2 * ink
	return {
		rows = safeRows,
		cols = cols,
		ink = ink,
		cellX = 1 / wide,
		cellY = 1 / tall,
		inkX = ink / wide,
		inkY = ink / tall,
	}
end

-- How far a grid's cells are from square on a box of `aspect`: the cell's px width over its px height, minus 1.
function BlockMath.Skew(grid: Grid, aspect: number): number
	return (grid.cellX * aspect) / grid.cellY - 1
end

-- The notched shape (a rectangle with its corner cells cut) as two overlapping bars, inset by `insetX`, `insetY` (0 for the ink
-- outline, the ink for the face). The cut is one cell, so the ink keeps one thickness round the step.
function BlockMath.Shape(grid: Grid, insetX: number, insetY: number): { Rect }
	local wide: Rect = { x = insetX, y = insetY + grid.cellY, w = 1 - 2 * insetX, h = 1 - 2 * (insetY + grid.cellY) }
	local tall: Rect = { x = insetX + grid.cellX, y = insetY, w = 1 - 2 * (insetX + grid.cellX), h = 1 - 2 * insetY }
	return { wide, tall }
end

-- The face (inside the ink): the shape inset by the border.
function BlockMath.Face(grid: Grid): { Rect }
	return BlockMath.Shape(grid, grid.inkX, grid.inkY)
end

-- The face's inner box (corners and all), where content and a bar's span are measured.
function BlockMath.Inner(grid: Grid): Rect
	return { x = grid.inkX, y = grid.inkY, w = 1 - 2 * grid.inkX, h = 1 - 2 * grid.inkY }
end

-- A progress fill `p` (0 to 1) of the face from the left: the face's two bars cut at the fill's right edge, so the fill keeps the
-- stepped corners. A bar the fill has not reached comes back with no width.
function BlockMath.Fill(grid: Grid, p: number): { Rect }
	local inner = BlockMath.Inner(grid)
	local edge = inner.x + math.clamp(p, 0, 1) * inner.w
	local out: { Rect } = {}
	for _, bar in ipairs(BlockMath.Face(grid)) do
		local right = math.min(edge, bar.x + bar.w)
		table.insert(out, { x = bar.x, y = bar.y, w = math.max(0, right - bar.x), h = bar.h })
	end
	return out
end

-- Where a point `p` (0 to 1 along a bar, as Fill measures it) sits across the plate: the inner box's left plus p of its width.
-- The capture bar's marker and zones use it, so the marker and the zones are measured on one span (what is seen is what scores).
function BlockMath.Along(grid: Grid, p: number): number
	local inner = BlockMath.Inner(grid)
	return inner.x + math.clamp(p, 0, 1) * inner.w
end

-- A band of the face from `left` to `left + width` (fractions of the bar, as Along measures them), cut to the face's two bars so
-- it keeps the stepped corners. Its edges are exact, never snapped to a cell: a timing zone shows exactly the span the server
-- scores. A bar the band misses comes back with no width.
function BlockMath.Span(grid: Grid, left: number, width: number): { Rect }
	local a = BlockMath.Along(grid, left)
	local b = BlockMath.Along(grid, left + width)
	local out: { Rect } = {}
	for _, bar in ipairs(BlockMath.Face(grid)) do
		local l = math.max(a, bar.x)
		local r = math.min(b, bar.x + bar.w)
		table.insert(out, { x = l, y = bar.y, w = math.max(0, r - l), h = bar.h })
	end
	return out
end

-- A fill that steps a whole cell at a time: the share of a `cols`-column bar lit when a sweep stands at `p` (0 to 1), the whole
-- cells behind it. The capture bar's trail fills with it, cell by cell.
function BlockMath.CellStep(cols: number, p: number): number
	local share = math.clamp(p, 0, 1)
	if cols <= 0 then
		return share
	end
	return math.floor(share * cols + 1e-9) / cols
end

-- The C3 bands: the top row lighter, the bottom row and the two side columns darker, each without the cut corner cells. Only on
-- a plate with three cells or more both ways (a smaller block stays one flat colour).
function BlockMath.Bands(grid: Grid): Bands
	if grid.rows < 3 or grid.cols < 3 then
		return {}
	end
	local x0, y0 = grid.inkX, grid.inkY
	local span = (grid.cols - 2) * grid.cellX
	local depth = (grid.rows - 2) * grid.cellY
	return {
		top = { x = x0 + grid.cellX, y = y0, w = span, h = grid.cellY },
		bottom = { x = x0 + grid.cellX, y = y0 + (grid.rows - 1) * grid.cellY, w = span, h = grid.cellY },
		left = { x = x0, y = y0 + grid.cellY, w = grid.cellX, h = depth },
		right = { x = x0 + (grid.cols - 1) * grid.cellX, y = y0 + grid.cellY, w = grid.cellX, h = depth },
	}
end

-- The grout of C3: a line `width` of a cell thick on each cell's right and bottom edge, except where that edge is the ink. The
-- line on the first column's right edge and the one on the first row's bottom edge skip the cut corner cells.
function BlockMath.Grout(grid: Grid, width: number): { Rect }
	local out: { Rect } = {}
	local gx, gy = width * grid.cellX, width * grid.cellY
	local x0, y0 = grid.inkX, grid.inkY
	local faceH = grid.rows * grid.cellY
	local faceW = grid.cols * grid.cellX
	for k = 1, grid.cols - 1 do
		local x = x0 + k * grid.cellX - gx
		if k == 1 then
			table.insert(out, { x = x, y = y0 + grid.cellY, w = gx, h = faceH - 2 * grid.cellY })
		else
			table.insert(out, { x = x, y = y0, w = gx, h = faceH })
		end
	end
	for k = 1, grid.rows - 1 do
		local y = y0 + k * grid.cellY - gy
		if k == 1 then
			table.insert(out, { x = x0 + grid.cellX, y = y, w = faceW - 2 * grid.cellX, h = gy })
		else
			table.insert(out, { x = x0, y = y, w = faceW, h = gy })
		end
	end
	return out
end

-- (a * b) mod 2^32 without losing precision in a double.
local function mul32(a: number, b: number): number
	local high, low = a // 65536, a % 65536
	return ((high * b % 65536) * 65536 + low * b) % TWO32
end

-- A cell's jitter level, -1, 0 or 1, from a hash of its grid position and the seed (C2: deterministic, 1 : 6 : 1).
function BlockMath.Level(col: number, row: number, seed: number): number
	local h = (col * 374761393 + row * 668265263 + seed * 2246822519) % TWO32
	h = mul32((h + h // 8192) % TWO32, 3266489917)
	h = (h + h // 65536) % TWO32
	local bucket = h % JITTER_BUCKETS
	if bucket == 0 then
		return -1
	elseif bucket == JITTER_BUCKETS - 1 then
		return 1
	end
	return 0
end

-- Every cell of the face that is not level, in reading order (the cut corner cells are skipped).
function BlockMath.Jittered(grid: Grid, seed: number): { Jitter }
	local out: { Jitter } = {}
	for row = 0, grid.rows - 1 do
		for col = 0, grid.cols - 1 do
			local corner = (row == 0 or row == grid.rows - 1) and (col == 0 or col == grid.cols - 1)
			if not corner then
				local level = BlockMath.Level(col, row, seed)
				if level ~= 0 then
					table.insert(out, { col = col, row = row, level = level })
				end
			end
		end
	end
	return out
end

-- A cell as a rect of the plate.
function BlockMath.Cell(grid: Grid, col: number, row: number): Rect
	return { x = grid.inkX + col * grid.cellX, y = grid.inkY + row * grid.cellY, w = grid.cellX, h = grid.cellY }
end

-- How many frames Builder.blockPlate draws for a grid: two ink bars and two face bars, and with `cells` the C3 bands, the grout
-- lines and the jittered cells (seed `seed`); an edged block (`edges`, no cells) the bands alone. The UI Playbook's frame budget
-- ("Frames") counts with it.
function BlockMath.Frames(grid: Grid, cells: boolean, seed: number, edges: boolean?): number
	local count = 4
	if not cells and not edges then
		return count
	end
	local bands = BlockMath.Bands(grid)
	for _, band in ipairs({ bands.top, bands.bottom, bands.left, bands.right }) do
		if band then
			count += 1
		end
	end
	if not cells then
		return count
	end
	return count + #BlockMath.Grout(grid, 1) + #BlockMath.Jittered(grid, seed)
end

-- Whether a grid is small enough to draw in full cells: `maxCells` (Theme.Block.MaxCells) or fewer. A grid over it draws as an
-- edged block (eight frames) instead, whatever asked for it: the last guard against a measurement no screen makes. The largest
-- real grid is the Playtime panel's 39 by 19 (tests/BlockMath.spec.luau "Block budget").
function BlockMath.WithinBudget(grid: Grid, maxCells: number): boolean
	return grid.rows * grid.cols <= maxCells
end

-- Cached grout and jitter (Builder's drawGrid): a plate's grout lines and jittered cells depend only on its rows, columns, ink
-- and the grout width or the seed, and the screens draw many plates of one size (the HUD's buttons, a list's rows, every redraw
-- of a fitted plate at the same columns), so each grid is worked out once. The answers are shared: callers only read them. The
-- cache forgets everything past CACHE_LIMIT entries, so a resize sweep cannot grow it without bound.
local CACHE_LIMIT = 256
local groutCache: { [string]: { Rect } } = {}
local jitterCache: { [string]: { Jitter } } = {}
local groutCount, jitterCount = 0, 0

function BlockMath.GroutCached(grid: Grid, width: number): { Rect }
	local key = grid.rows .. ":" .. grid.cols .. ":" .. grid.ink .. ":" .. width
	local hit = groutCache[key]
	if hit then
		return hit
	end
	if groutCount >= CACHE_LIMIT then
		table.clear(groutCache)
		groutCount = 0
	end
	local made = BlockMath.Grout(grid, width)
	groutCache[key] = made
	groutCount += 1
	return made
end

function BlockMath.JitteredCached(grid: Grid, seed: number): { Jitter }
	local key = grid.rows .. ":" .. grid.cols .. ":" .. seed
	local hit = jitterCache[key]
	if hit then
		return hit
	end
	if jitterCount >= CACHE_LIMIT then
		table.clear(jitterCache)
		jitterCount = 0
	end
	local made = BlockMath.Jittered(grid, seed)
	jitterCache[key] = made
	jitterCount += 1
	return made
end

-- How many grids each cache holds now (the spec checks the bound).
function BlockMath.CacheSize(): (number, number)
	return groutCount, jitterCount
end

-- A block button is its face plate over a lip one cell deep: the face is `rows` + 2 ink cells tall and the whole button one
-- cell more. Answers the lip's share of the button's height (the press sinks the face by exactly this) and the face's aspect
-- on a button box of `aspect`.
function BlockMath.Lip(aspect: number, rows: number, ink: number): (number, number)
	local face = rows + 2 * ink
	local lip = 1 / (face + 1)
	return lip, aspect / (1 - lip)
end

-- The px box a GuiObject of Scale `sizeX` by `sizeY` gets on a `screenW` by `screenH` screen under a UIAspectRatioConstraint of
-- `aspect` (FitWithinMaxSize: the largest box of that shape inside the Size). Answers width and height in px.
function BlockMath.FitPx(sizeX: number, sizeY: number, aspect: number, screenW: number, screenH: number): (number, number)
	local w, h = sizeX * screenW, sizeY * screenH
	if w / h > aspect then
		return h * aspect, h
	end
	return w, w / aspect
end

return BlockMath
