--!strict
-- ReplicatedFirst.LoadingScreen: the game's own loading screen, in place of Roblox's grey one, in block cells (Decisions B44, UI
-- Playbook "Block cells" and "The loading screen in block cells"). A cold server loads the creature and prop meshes at boot
-- (ServerScriptService.Server.Services.Models, up to Config.ModelLoadTimeoutSeconds) and the client bootstrap then waits for the
-- profile, so a joining player used to sit on the default screen for several seconds. This shows a night-sky screen with
-- twinkling pixel stars, a little pixel alien hopping on a floating grass island built of block cells, the game's title, and a
-- block-cell progress bar that fills cell by cell as the models arrive with one outlined line under it ("Loading aliens...
-- N / M"); while the count is unknown a four-cell block sweeps the bar instead. It fades out (0.4 s) when the client bootstrap
-- starts (StarterPlayerScripts.Client sets the player attribute ClientStarted in its start(), right after State.Set). It also
-- removes itself after Config.LoadingScreenMaxSeconds whatever happens, so a broken boot never traps the player behind it. Pure
-- presentation: it decides nothing.
--
-- ReplicatedFirst runs before ReplicatedStorage is guaranteed to exist, so this script depends on nothing in it: the screen is
-- built at once from the hardcoded locals below (the block-cell rules mirror Theme.Block and Shared/BlockMath, which it cannot
-- require), and the title, the expected model count, the cap and the strings are read from ReplicatedStorage.Shared only if it
-- arrives in time (a background wait, never blocking the first frame). Without it the screen shows no title, "Loading
-- aliens..." in the English fallback below and the built-in cap, and still works. Scale only for every Position and Size: each
-- plate keeps its aspect with a UIAspectRatioConstraint so its cells stay square, and every rectangle inside it is a fraction of
-- it (UIStrokes on text and the text size cap are pixels). No UICorner, no gradient, no image: nothing waits on an upload.
-- tools/tests/test_loading_screen.py checks the fit at iPhone SE and iPad from the numbers below.

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- The look. These mirror src/shared/Theme.luau (Colors, Stroke, TextSize, Block) and the World 1 ground palette (Blocky-Style
-- E3) because this script cannot require them; change them there and here together.
local FONT = Font.fromEnum(Enum.Font.FredokaOne) -- Theme.Font
local NAVY = Color3.fromHex("1B1F3B") -- Theme.Colors.Outline: the ink
local SPACE = Color3.fromHex("2A2F55") -- Theme.Block.Trough: the night sky behind everything
local TROUGH = Color3.fromHex("151933") -- the progress bar's empty face, a step under the sky
local WHITE = Color3.new(1, 1, 1) -- Theme.Colors.White
local BLACK = Color3.new(0, 0, 0) -- Theme.Colors.Black
local HEADING = Color3.fromHex("FFEF4A") -- Theme.Colors.Heading
local GRASS = Color3.fromHex("6FBF4A") -- World 1 grass (Blocky-Style E3)
local DIRT = Color3.fromHex("8A5A3B") -- World 1 dirt
local DEEP_DIRT = Color3.fromHex("6E4630") -- the island's hanging rock, a step under the dirt
local ALIEN_GREEN = Color3.fromHex("6BCB3F") -- Species Mossbop placeholder.color (the Moop)
local ALIEN_LIGHT = Color3.fromHex("A6E86E") -- its lit top row and belly
local ALIEN_DARK = Color3.fromHex("4A9A2A") -- its feet
local CHEEK = Color3.fromHex("FF8AD8") -- the blush
local GLOW = Color3.fromHex("FFEF4A") -- the antenna tip (Theme.Colors.Heading)
local STAR = Color3.fromHex("FFF4DC") -- Theme.Colors.Panel: a warm white star
local FILL = Color3.fromHex("6BCB3F") -- the progress fill: the alien's green
local TEXT_STROKE = 2.5 -- Theme.Stroke.Text
local PANEL_STROKE = 4 -- Theme.Stroke.Panel (the title's outline)
local STROKE_REFERENCE = 1080 -- Theme.Stroke.ReferenceHeight: the strokes above are pixels at this screen height
local STROKE_MIN, STROKE_MAX = 0.8, 1.2 -- Theme.Stroke.MinScale and MaxScale
local TEXT_JOIN = Enum.LineJoinMode.Bevel -- Theme.Stroke.TextJoin
local MIN_TEXT = 14 -- Theme.TextSize.Min
local LABEL_TEXT = 30 -- a little over Theme.TextSize.Label (24): this is the one line on the screen
local TITLE_TEXT = 48 -- Theme.TextSize.Reveal

-- The block-cell rules (Theme.Block; Shared/BlockMath does the same arithmetic for Builder.blockPlate).
local INK = 0.4 -- Theme.Block.Ink: the border, in cells
local GROUT = 0.125 -- Theme.Block.Grout: a grout line, in cells
local GROUT_ALPHA = 0.9 -- Theme.Block.GroutAlpha
local TOP_ALPHA = 0.7 -- Theme.Block.TopAlpha: the lit top row
local EDGE_ALPHA = 0.8 -- Theme.Block.EdgeAlpha: the shaded bottom row and side columns
local JITTER_ALPHA = 0.9 -- Theme.Block.JitterAlpha
local SEED = 44 -- Theme.Block.Seed

-- The layout, every number a Scale (tools/tests/test_loading_screen.py reads these lines; keep the names).
local TITLE_Y, TITLE_H = 0.11, 0.12 -- the title's centre and box height, of the screen height
local STAGE_Y = 0.47 -- the stage's centre
local STAGE_W, STAGE_H = 0.6, 0.48 -- its bounds; it is square, so on a landscape screen its side is STAGE_H of the height
local ISLAND_COLS, ISLAND_ROWS = 11, 4 -- the floating grass island: one row of grass over three of dirt
local ISLAND_W, ISLAND_TOP = 0.84, 0.62 -- its width and its top edge, of the stage
local ROCK_COLS, ROCK_ROWS = 7, 3 -- the rock hanging under the island
local ROCK_W, ROCK_TOP = 0.44, 0.9 -- of the stage
local ALIEN_SIDE = 0.36 -- the alien's square, of the stage
local ALIEN_REST, ALIEN_PEAK = 0.64, 0.45 -- where its feet stand (the island's grass) and the top of a hop, of the stage
local BAR_COLS, BAR_ROWS = 24, 3 -- the progress bar's cells
local BAR_Y, BAR_W, BAR_H = 0.83, 0.5, 0.07 -- its centre and bounds, of the screen
local STATUS_Y, STATUS_H = 0.92, 0.07 -- the line under it
local SWEEP_CELLS = 4 -- the block that sweeps the bar while the count is unknown
local PIXELS = 16 -- the alien is drawn on a 16 x 16 pixel grid

-- Timings and fallbacks that cannot live in data/Config because Config may not have arrived.
local FADE_SECONDS = 0.4 -- the fade-out
local POLL_SECONDS = 0.25 -- how often the model count, the cap and the started flag are checked
local SWEEP_STEP_SECONDS = 0.08 -- the sweep moves one cell this often
local HOP_SECONDS = 0.42 -- one way up (the alien comes back down in the same time)
local BLINK_SECONDS = 0.12 -- how long the eyes stay shut
local BLINK_MIN, BLINK_MAX = 2.2, 4.2 -- seconds between blinks
local TWINKLE_MIN, TWINKLE_MAX = 0.9, 2.1 -- one star's fade one way
local SHARED_WAIT_SECONDS = 5 -- how long to wait for ReplicatedStorage.Shared before giving up on title and count
local CHILD_WAIT_SECONDS = 2 -- and for each module below it, once Shared is there
local FALLBACK_MAX_SECONDS = 25 -- the cap until Config.LoadingScreenMaxSeconds is read
local FALLBACK_MODELS_FOLDER = "Models" -- Config.ModelFolderName
local FALLBACK_PROPS_FOLDER = "Props" -- Config.PropsFolderName
local FALLBACK_ALIENS_LINE = "Loading aliens... %d / %d" -- strings.LOADING_ALIENS
local FALLBACK_PLAIN_LINE = "Loading aliens..." -- strings.LOADING_PLAIN
local STARTED_ATTRIBUTE = "ClientStarted" -- set on the LocalPlayer by StarterPlayerScripts.Client

local startedAt = os.clock()
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Whether the system's reduced-motion switch is on (false when it cannot be read: it is missing on some clients).
local function reducedMotion(): boolean
	local ok, value = pcall(function(): boolean
		return UserSettings():GetService("UserGameSettings").ReducedMotion
	end)
	return ok and value == true
end
local still = reducedMotion()

-- Block cells (a copy of the Shared/BlockMath arithmetic) ------------------------------------------------

type Grid = { rows: number, cols: number, cellX: number, cellY: number, inkX: number, inkY: number }

local function gridOf(cols: number, rows: number): Grid
	local wide, tall = cols + 2 * INK, rows + 2 * INK
	return { rows = rows, cols = cols, cellX = 1 / wide, cellY = 1 / tall, inkX = INK / wide, inkY = INK / tall }
end

-- A plate's width over its height, so its cells are square.
local function aspectOf(cols: number, rows: number): number
	return (cols + 2 * INK) / (rows + 2 * INK)
end

local TWO32 = 4294967296
local function mul32(a: number, b: number): number
	local high, low = a // 65536, a % 65536
	return ((high * b % 65536) * 65536 + low * b) % TWO32
end

-- BlockMath.Level: a cell's jitter, -1, 0 or 1 (one in eight a shade down, one in eight a shade up; the same every build).
local function level(col: number, row: number, seed: number): number
	local h = (col * 374761393 + row * 668265263 + seed * 2246822519) % TWO32
	h = mul32((h + h // 8192) % TWO32, 3266489917)
	h = (h + h // 65536) % TWO32
	local bucket = h % 8
	if bucket == 0 then
		return -1
	elseif bucket == 7 then
		return 1
	end
	return 0
end

local function rect(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3, alpha: number, z: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = UDim2.fromScale(x, y)
	frame.Size = UDim2.fromScale(w, h)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = alpha
	frame.BorderSizePixel = 0
	frame.ZIndex = z
	frame.Parent = parent
	return frame
end

-- The notched shape (corner cells cut) as two overlapping bars, inset by the ink or by nothing (BlockMath.Shape).
local function shapeBars(g: Grid, insetX: number, insetY: number): { { number } }
	return {
		{ insetX, insetY + g.cellY, 1 - 2 * insetX, 1 - 2 * (insetY + g.cellY) },
		{ insetX + g.cellX, insetY, 1 - 2 * (insetX + g.cellX), 1 - 2 * insetY },
	}
end

-- A band of whole rows `from` to `to` (0-based) across the face in `color`, the corner cells left out on the first and last row.
local function rowBand(holder: Frame, g: Grid, from: number, to: number, color: Color3, z: number)
	for row = from, to do
		local corner = row == 0 or row == g.rows - 1
		local x = g.inkX + (if corner then g.cellX else 0)
		local w = (if corner then g.cols - 2 else g.cols) * g.cellX
		rect(holder, "Band", x, g.inkY + row * g.cellY, w, g.cellY, color, 0, z)
	end
end

type Plate = { holder: Frame, grid: Grid, base: number }
type Band = { from: number, to: number, color: Color3 }

-- A block-cell plate (Builder.blockPlate's look): navy ink round the stepped corner, the face, then over it the lit top row, the
-- shaded edges, the grout and the jittered cells. `bands` paints whole rows another colour first (the island's grass row).
local function plate(parent: Instance, name: string, cols: number, rows: number, face: Color3, base: number, bands: { Band }?): Plate
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.ZIndex = base
	local keep = Instance.new("UIAspectRatioConstraint")
	keep.AspectRatio = aspectOf(cols, rows)
	keep.Parent = holder
	local g = gridOf(cols, rows)
	for _, bar in shapeBars(g, 0, 0) do
		rect(holder, "Ink", bar[1], bar[2], bar[3], bar[4], NAVY, 0, base)
	end
	for _, bar in shapeBars(g, g.inkX, g.inkY) do
		rect(holder, "Fill", bar[1], bar[2], bar[3], bar[4], face, 0, base + 1)
	end
	if bands then
		for _, band in bands do
			rowBand(holder, g, band.from, band.to, band.color, base + 1)
		end
	end
	local cells = base + 3 -- base + 2 is a bar's fill, under the cells so it reads in cells too
	local span, depth = (cols - 2) * g.cellX, (rows - 2) * g.cellY
	rect(holder, "Lit", g.inkX + g.cellX, g.inkY, span, g.cellY, WHITE, TOP_ALPHA, cells)
	rect(holder, "Shade", g.inkX + g.cellX, g.inkY + (rows - 1) * g.cellY, span, g.cellY, BLACK, EDGE_ALPHA, cells)
	rect(holder, "Shade", g.inkX, g.inkY + g.cellY, g.cellX, depth, BLACK, EDGE_ALPHA, cells)
	rect(holder, "Shade", g.inkX + (cols - 1) * g.cellX, g.inkY + g.cellY, g.cellX, depth, BLACK, EDGE_ALPHA, cells)
	local gx, gy = GROUT * g.cellX, GROUT * g.cellY
	for k = 1, cols - 1 do
		local x = g.inkX + k * g.cellX - gx
		local first = k == 1
		rect(holder, "Grout", x, g.inkY + (if first then g.cellY else 0), gx, (if first then rows - 2 else rows) * g.cellY, BLACK, GROUT_ALPHA, cells)
	end
	for k = 1, rows - 1 do
		local y = g.inkY + k * g.cellY - gy
		local first = k == 1
		rect(holder, "Grout", g.inkX + (if first then g.cellX else 0), y, (if first then cols - 2 else cols) * g.cellX, gy, BLACK, GROUT_ALPHA, cells)
	end
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local corner = (row == 0 or row == rows - 1) and (col == 0 or col == cols - 1)
			local shade = if corner then 0 else level(col, row, SEED)
			if shade ~= 0 then
				rect(holder, "Jitter", g.inkX + col * g.cellX, g.inkY + row * g.cellY, g.cellX, g.cellY, if shade > 0 then WHITE else BLACK, JITTER_ALPHA, cells)
			end
		end
	end
	holder.Parent = parent
	return { holder = holder, grid = g, base = base }
end

-- Build -------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100 -- over every game screen (the HUD is 10, panels 20, toasts 40, the launch fade 50)
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local background = Instance.new("Frame")
background.Name = "Background"
background.Position = UDim2.fromScale(0, 0)
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = SPACE
background.BorderSizePixel = 0
background.Active = true -- swallows taps while it shows
background.Parent = gui

-- The pixel stars: x, y (of the screen) and a side (of the screen height); square by their aspect constraint. They stay out of
-- the title's and the bar's middle third so text never sits on one.
local STARS: { { number } } = {
	{ 0.06, 0.08, 0.012 }, { 0.14, 0.3, 0.008 }, { 0.09, 0.55, 0.014 }, { 0.2, 0.72, 0.008 }, { 0.05, 0.88, 0.01 },
	{ 0.27, 0.18, 0.01 }, { 0.31, 0.62, 0.008 }, { 0.72, 0.22, 0.012 }, { 0.68, 0.64, 0.008 }, { 0.8, 0.08, 0.008 },
	{ 0.86, 0.38, 0.014 }, { 0.93, 0.6, 0.01 }, { 0.82, 0.8, 0.008 }, { 0.95, 0.9, 0.012 }, { 0.24, 0.42, 0.006 },
	{ 0.76, 0.48, 0.006 },
}
local starFrames: { Frame } = {}
for index, star in STARS do
	local frame = rect(background, "Star" .. index, star[1], star[2], star[3], star[3], STAR, 0, 1)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.SizeConstraint = Enum.SizeConstraint.RelativeYY -- the side is a share of the screen height on both axes: square
	table.insert(starFrames, frame)
end

local strokes: { { stroke: UIStroke, px: number } } = {}
local function textLabel(name: string, y: number, height: number, color: Color3, maxText: number, strokePx: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, y)
	label.Size = UDim2.fromScale(0.9, height)
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextColor3 = color
	label.TextScaled = true
	label.Text = ""
	label.ZIndex = 20
	local sizes = Instance.new("UITextSizeConstraint")
	sizes.MinTextSize = MIN_TEXT
	sizes.MaxTextSize = maxText
	sizes.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokePx
	stroke.Color = NAVY
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = TEXT_JOIN
	stroke.Parent = label
	table.insert(strokes, { stroke = stroke, px = strokePx })
	label.Parent = background
	return label
end

local title = textLabel("Title", TITLE_Y, TITLE_H, HEADING, TITLE_TEXT, PANEL_STROKE)
local status = textLabel("Status", STATUS_Y, STATUS_H, WHITE, LABEL_TEXT, TEXT_STROKE)

-- The stage is a square (whatever the screen's shape) holding the island and the alien, so everything inside it is plain Scale.
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.AnchorPoint = Vector2.new(0.5, 0.5)
stage.Position = UDim2.fromScale(0.5, STAGE_Y)
stage.Size = UDim2.fromScale(STAGE_W, STAGE_H)
stage.BackgroundTransparency = 1
stage.ZIndex = 2
stage.Parent = background
local square = Instance.new("UIAspectRatioConstraint")
square.AspectRatio = 1
square.Parent = stage

-- The floating island: a grass row over dirt, and a darker rock hanging under it (drawn first, so the island sits over its top).
local rock = plate(stage, "Rock", ROCK_COLS, ROCK_ROWS, DEEP_DIRT, 2)
rock.holder.AnchorPoint = Vector2.new(0.5, 0)
rock.holder.Position = UDim2.fromScale(0.5, ROCK_TOP)
rock.holder.Size = UDim2.fromScale(ROCK_W, 1)
local island = plate(stage, "Island", ISLAND_COLS, ISLAND_ROWS, DIRT, 7, { { from = 0, to = 0, color = GRASS } })
island.holder.AnchorPoint = Vector2.new(0.5, 0)
island.holder.Position = UDim2.fromScale(0.5, ISLAND_TOP)
island.holder.Size = UDim2.fromScale(ISLAND_W, 1)

-- The alien's shadow on the grass: a flat navy block that shrinks and fades while the alien is in the air.
local SHADOW_REST_SIZE = UDim2.fromScale(0.26, 0.025)
local SHADOW_AIR_SIZE = UDim2.fromScale(0.16, 0.02)
local SHADOW_REST_ALPHA = 0.55
local SHADOW_AIR_ALPHA = 0.8
local shadow = rect(stage, "Shadow", 0.5, ALIEN_REST + 0.005, 0, 0, NAVY, SHADOW_REST_ALPHA, 12)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Size = SHADOW_REST_SIZE

-- The alien: a Moop-green block alien on a 16 x 16 pixel grid, painted in layers (the ink silhouette, the colours, the face).
-- Each row is x, y, w, h in pixels and a colour. Anchored at its bottom centre so the hop is a height.
local alien = Instance.new("Frame")
alien.Name = "Alien"
alien.AnchorPoint = Vector2.new(0.5, 1)
alien.Position = UDim2.fromScale(0.5, ALIEN_REST)
alien.Size = UDim2.fromScale(ALIEN_SIDE, ALIEN_SIDE)
alien.BackgroundTransparency = 1
alien.ZIndex = 13
alien.Parent = stage

type Pixel = { number | Color3 }
local function paint(parent: Frame, name: string, pixels: { Pixel }, z: number): { Frame }
	local out: { Frame } = {}
	for _, p in pixels do
		local x, y, w, h = p[1] :: number, p[2] :: number, p[3] :: number, p[4] :: number
		table.insert(out, rect(parent, name, x / PIXELS, y / PIXELS, w / PIXELS, h / PIXELS, p[5] :: Color3, 0, z))
	end
	return out
end

paint(alien, "Ink", {
	{ 6, 0, 4, 4, NAVY }, -- the antenna's tip
	{ 7, 4, 2, 2, NAVY }, -- its stalk
	{ 3, 5, 10, 10, NAVY }, -- the body, stepped twice at each corner
	{ 2, 6, 12, 8, NAVY },
	{ 1, 7, 14, 6, NAVY },
	{ 3, 13, 4, 3, NAVY }, -- the feet
	{ 9, 13, 4, 3, NAVY },
}, 13)
local tip = paint(alien, "Glow", { { 7, 1, 2, 2, GLOW } }, 14)[1]
paint(alien, "Body", {
	{ 4, 6, 8, 8, ALIEN_GREEN },
	{ 3, 7, 10, 6, ALIEN_GREEN },
	{ 2, 8, 12, 4, ALIEN_GREEN },
	{ 4, 14, 2, 1, ALIEN_DARK },
	{ 10, 14, 2, 1, ALIEN_DARK },
	{ 4, 6, 8, 1, ALIEN_LIGHT }, -- the lit top row (Blocky-Style C3)
	{ 6, 11, 4, 2, ALIEN_LIGHT }, -- the belly
	{ 3, 11, 2, 1, CHEEK },
	{ 11, 11, 2, 1, CHEEK },
	{ 7, 12, 2, 1, NAVY }, -- the mouth
}, 14)
local openEyes = paint(alien, "Eye", {
	{ 4, 8, 3, 3, WHITE },
	{ 9, 8, 3, 3, WHITE },
	{ 5, 9, 2, 2, NAVY },
	{ 10, 9, 2, 2, NAVY },
	{ 5, 9, 1, 1, WHITE }, -- the shine
	{ 10, 9, 1, 1, WHITE },
}, 15)
local shutEyes = paint(alien, "Shut", { { 4, 10, 3, 1, NAVY }, { 9, 10, 3, 1, NAVY } }, 15)
for _, frame in shutEyes do
	frame.Visible = false
end

-- The progress bar: a dark trough plate whose face fills in the alien's green, a whole cell at a time, under the cell overlays.
local bar = plate(background, "Bar", BAR_COLS, BAR_ROWS, TROUGH, 3)
bar.holder.AnchorPoint = Vector2.new(0.5, 0.5)
bar.holder.Position = UDim2.fromScale(0.5, BAR_Y)
bar.holder.Size = UDim2.fromScale(BAR_W, BAR_H)
local barGrid = bar.grid
local fillBars: { Frame } = {}
for _, shape in shapeBars(barGrid, barGrid.inkX, barGrid.inkY) do
	table.insert(fillBars, rect(bar.holder, "Progress", shape[1], shape[2], 0, shape[4], FILL, 0, bar.base + 2))
end

-- Lights the face from `left` to `right` (shares of the face's inner width, 0 to 1), cut to the face's two bars so the fill keeps
-- the stepped corners (BlockMath.Span).
local function lightSpan(left: number, right: number)
	local innerW = 1 - 2 * barGrid.inkX
	local a = barGrid.inkX + math.clamp(left, 0, 1) * innerW
	local b = barGrid.inkX + math.clamp(right, 0, 1) * innerW
	for index, shape in shapeBars(barGrid, barGrid.inkX, barGrid.inkY) do
		local l = math.max(a, shape[1])
		local r = math.min(b, shape[1] + shape[3])
		local frame = fillBars[index]
		frame.Position = UDim2.fromScale(l, shape[2])
		frame.Size = UDim2.fromScale(math.max(0, r - l), shape[4])
	end
end
lightSpan(0, 0)

gui.Parent = playerGui

-- The text outlines scale with the screen height as Builder.stroke does (Shared/StrokeMath), inside [STROKE_MIN, STROKE_MAX].
local function scaleStrokes()
	local height = background.AbsoluteSize.Y
	if height <= 0 then
		return
	end
	local factor = math.clamp(height / STROKE_REFERENCE, STROKE_MIN, STROKE_MAX)
	for _, entry in strokes do
		entry.stroke.Thickness = entry.px * factor
	end
end
scaleStrokes()
background:GetPropertyChangedSignal("AbsoluteSize"):Connect(scaleStrokes)

-- Motion (none with Reduced Motion: the alien stands still, the stars stay lit, the eyes stay open) ------------------

local removing = false

if not still then
	-- The hop: up with a quad ease out and, reversed, down with the matching ease in, forever. Blocks do not squash.
	local hop = TweenInfo.new(HOP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true)
	TweenService:Create(alien, hop, { Position = UDim2.fromScale(0.5, ALIEN_PEAK) }):Play()
	TweenService:Create(shadow, hop, { Size = SHADOW_AIR_SIZE, BackgroundTransparency = SHADOW_AIR_ALPHA }):Play()
	-- The antenna tip pulses between gold and white with the hop.
	TweenService:Create(tip, TweenInfo.new(HOP_SECONDS * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundColor3 = WHITE }):Play()
	-- Every other star twinkles, each at its own pace (a fixed spread, so every client sees the same sky).
	for index, frame in starFrames do
		if index % 2 == 0 then
			local seconds = TWINKLE_MIN + (TWINKLE_MAX - TWINKLE_MIN) * ((index * 7) % 10) / 10
			TweenService:Create(frame, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.75 }):Play()
		end
	end
	-- The blink: the eyes shut for a moment every few seconds.
	task.spawn(function()
		local rng = Random.new()
		while not removing do
			task.wait(rng:NextNumber(BLINK_MIN, BLINK_MAX))
			if removing then
				break
			end
			for _, frame in openEyes do
				frame.Visible = false
			end
			for _, frame in shutEyes do
				frame.Visible = true
			end
			task.wait(BLINK_SECONDS)
			for _, frame in openEyes do
				frame.Visible = true
			end
			for _, frame in shutEyes do
				frame.Visible = false
			end
		end
	end)
end

-- Shared data (arrives in the background) -----------------------------------

local maxSeconds = FALLBACK_MAX_SECONDS
local modelsFolderName = FALLBACK_MODELS_FOLDER
local propsFolderName = FALLBACK_PROPS_FOLDER
local alienLine = FALLBACK_ALIENS_LINE
local plainLine = FALLBACK_PLAIN_LINE
local expectedModels: number? = nil -- M: how many models the server will load; nil until known (or when it loads none)

-- The ModuleScript Shared.<path...>, waited for briefly, required under pcall; nil when it is missing or errors.
local function requireShared(shared: Instance, path: { string }): { [string]: any }?
	local node: Instance? = shared
	for _, name in path do
		node = if node then node:WaitForChild(name, CHILD_WAIT_SECONDS) else nil
	end
	if node and node:IsA("ModuleScript") then
		local ok, result = pcall(require, node)
		if ok and type(result) == "table" then
			return result :: { [string]: any }
		end
	end
	return nil
end

local function countKeys(map: any): number
	local count = 0
	if type(map) == "table" then
		for _ in pairs(map :: { [any]: any }) do
			count += 1
		end
	end
	return count
end

-- The models that have arrived: every non-Folder child of ReplicatedStorage.<Models> plus the non-Folder children of
-- <Models>.<Props> (the Props folder itself is not a model, so it never counts).
local function countModels(): number
	local models = ReplicatedStorage:FindFirstChild(modelsFolderName)
	if not models then
		return 0
	end
	local count = 0
	for _, child in models:GetChildren() do
		if not child:IsA("Folder") then
			count += 1
		end
	end
	local props = models:FindFirstChild(propsFolderName)
	if props then
		for _, child in props:GetChildren() do
			if not child:IsA("Folder") then
				count += 1
			end
		end
	end
	return count
end

-- The line and the bar: with a known count the bar lights the arrived share in whole cells; without one the line is plain and
-- the sweep (below) runs.
local function refreshStatus()
	local total = expectedModels
	local text = if total and total > 0 then alienLine:format(math.min(countModels(), total), total) else plainLine
	if status.Text ~= text then
		status.Text = text
	end
	if total and total > 0 then
		local share = math.min(countModels(), total) / total
		lightSpan(0, math.floor(share * BAR_COLS + 1e-9) / BAR_COLS)
	end
end

-- The sweep: a SWEEP_CELLS block running across the bar a cell at a time while the count is unknown (it shows the screen is
-- alive without claiming a share it does not know).
task.spawn(function()
	local step = -SWEEP_CELLS
	while not removing and not expectedModels do
		lightSpan(step / BAR_COLS, (step + SWEEP_CELLS) / BAR_COLS)
		step += 1
		if step > BAR_COLS then
			step = -SWEEP_CELLS
		end
		task.wait(SWEEP_STEP_SECONDS)
	end
end)

task.spawn(function()
	local shared = ReplicatedStorage:WaitForChild("Shared", SHARED_WAIT_SECONDS)
	if not shared or removing then
		return
	end
	local config = requireShared(shared, { "data", "Config" })
	if config then
		if type(config.GameTitle) == "string" then
			title.Text = config.GameTitle
		end
		if type(config.LoadingScreenMaxSeconds) == "number" then
			maxSeconds = config.LoadingScreenMaxSeconds
		end
		if type(config.ModelFolderName) == "string" then
			modelsFolderName = config.ModelFolderName
		end
		if type(config.PropsFolderName) == "string" then
			propsFolderName = config.PropsFolderName
		end
	end
	-- The count only means something when the server loads models at boot (Config.LoadModelsAtBoot); otherwise the line
	-- stays plain.
	if not config or config.LoadModelsAtBoot ~= false then
		local assets = requireShared(shared, { "data", "ModelAssets" })
		local total = if assets then countKeys(assets.AssetIds) else 0
		if total > 0 then
			expectedModels = total
		end
	end
	local strings = requireShared(shared, { "strings", "en" })
	if strings then
		if type(strings.LOADING_ALIENS) == "string" then
			alienLine = strings.LOADING_ALIENS
		end
		if type(strings.LOADING_PLAIN) == "string" then
			plainLine = strings.LOADING_PLAIN
		end
	end
	if not removing then
		refreshStatus()
	end
end)

-- Remove ---------------------------------------------------------------------

-- Lights the whole bar, fades everything out over FADE_SECONDS and destroys the screen. Runs once.
local function remove()
	if removing then
		return
	end
	removing = true
	lightSpan(0, 1)
	local info = TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function fade(instance: Instance, goal: { [string]: any })
		TweenService:Create(instance, info, goal):Play()
	end
	fade(background, { BackgroundTransparency = 1 })
	for _, node in background:GetDescendants() do
		if node:IsA("TextLabel") then
			fade(node, { TextTransparency = 1 })
		elseif node:IsA("Frame") then
			fade(node, { BackgroundTransparency = 1 })
		elseif node:IsA("UIStroke") then
			fade(node, { Transparency = 1 })
		end
	end
	background.Active = false
	task.delay(FADE_SECONDS, function()
		gui:Destroy()
	end)
end

player:GetAttributeChangedSignal(STARTED_ATTRIBUTE):Connect(function()
	if player:GetAttribute(STARTED_ATTRIBUTE) == true then
		remove()
	end
end)

-- The count, the cap and the started flag, polled (the folders fill in whatever order the loads finish).
refreshStatus()
while not removing do
	if player:GetAttribute(STARTED_ATTRIBUTE) == true or os.clock() - startedAt >= maxSeconds then
		remove()
		break
	end
	refreshStatus()
	task.wait(POLL_SECONDS)
end
