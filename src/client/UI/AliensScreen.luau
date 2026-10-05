--!strict
-- StarterPlayerScripts.Client.UI.AliensScreen: the Aliens panel. A strip of station cards across
-- the top (one per unlocked job: name, slots, rate and a row of slot squares), the owned count, a
-- scrolling grid of one square card per alien (rarity gradient, placeholder shape, name, speed chip,
-- overlay badge, where it is working), and an Optimize button. Every value is read from the profile
-- mirror in State and the shared Economy math; the only tap that leaves the client asks the server
-- (StationOptimize). Nothing here decides an outcome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Economy = require(Shared:WaitForChild("Economy"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Jobs = require(Shared:WaitForChild("data"):WaitForChild("Jobs"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)

local AliensScreen = {}

type JobDef = { name: string, station: string, verb: string, commonsOnly: boolean, unlockWorld: number }
local jobDefs: { [string]: JobDef } = Jobs.Jobs
local jobOrder: { string } = Jobs.Order

-- One grid entry, sorted before the cards are built.
type Entry = { record: Types.AlienRecord, def: Types.SpeciesDef?, speed: number, name: string }

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close
-- button reaches down to 0.155, so the body starts under it.
local STRIP_Y = 0.17
local STRIP_H = 0.27
local STRIP_GAP = 0.02 -- between station cards, of the strip width
local COUNT_Y = 0.455
local COUNT_H = 0.05
local GRID_Y = 0.515
local GRID_H = 0.345
local FOOTER_H = 0.1

-- Grid: four square cards per row; the cell width is a fraction of the grid's canvas width and the
-- cell height is derived from it so the cells come out square (see layoutGrid).
local COLUMNS = 4
local CELL_W = 0.22
local CELL_GAP = 0.02
local SCROLLBAR_PX = 6 -- thickness, not a Size: a thin dark bar on the right

local gui: ScreenGui? = nil
local panel: Frame? = nil
local strip: Frame? = nil
local countLabel: TextLabel? = nil
local grid: ScrollingFrame? = nil
local gridLayout: UIGridLayout? = nil
local emptyLabel: TextLabel? = nil
local cardCount = 0
local open = false
local pending = false -- one server request in flight at a time

-- Helpers ----------------------------------------------------------------

local function speciesColor(def: Types.SpeciesDef?): Color3
	return if def then Color3.fromHex(def.placeholder.color) else Theme.Rarity.Common
end

local function speciesName(def: Types.SpeciesDef?, id: string): string
	return if def then def.name else id
end

local function shapeName(def: Types.SpeciesDef?): string
	return Builder.text("SHAPE_" .. (if def then def.placeholder.shape else "Ball"))
end

-- The server creates one station per job with StationStartSlots; until its first push lands, show the same shape.
local function stationOf(profile: Types.Profile, job: string): Types.StationState
	return profile.stations[job] or { slots = Config.StationStartSlots, assigned = {} }
end

-- Jobs the current world has unlocked, in Jobs.Order.
local function unlockedJobs(profile: Types.Profile): { string }
	local out: { string } = {}
	for _, job in ipairs(jobOrder) do
		local def = jobDefs[job]
		if def and def.unlockWorld <= profile.world.current then
			table.insert(out, job)
		end
	end
	return out
end

local function clearChildren(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Server calls -------------------------------------------------------------

-- Invokes a RemoteFunction that answers (ok, reason). Runs in its own thread: callers are taps.
local function ask(name: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func(name):InvokeServer()
		pending = false
		if ok ~= true then
			print(("[%s] %s refused: %s"):format(Config.WorkingTitle, name, tostring(reason)))
		end
	end)
end

-- Station strip ------------------------------------------------------------

-- One slot square: filled (species colour, tier stroke, name beneath), open (outlined, "Open"
-- beneath) or locked (darker, no label) for slots the station has not grown into yet.
local function buildSlot(parent: Frame, index: number, width: number, profile: Types.Profile, station: Types.StationState)
	local cell = Builder.frame({
		parent = parent,
		name = "Slot" .. index,
		size = UDim2.fromScale(width, 1),
		zIndex = 4,
	})
	cell.LayoutOrder = index

	local uid = station.assigned[index]
	local record = if uid then profile.aliens[uid] else nil
	local square: Builder.FrameProps = {
		parent = cell,
		name = "Square",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, 0.62),
		anchor = Vector2.new(0.5, 0),
		corner = Theme.Corner.Card,
		aspect = 1,
		zIndex = 4,
	}
	local label: string? = nil
	if index > station.slots then
		square.color = Builder.darker(Theme.Rarity.Common)
		square.stroke = Theme.Stroke.Text
		square.strokeColor = Theme.Colors.Outline
	elseif record then
		local def = Species.ById[record.species]
		square.color = speciesColor(def)
		square.stroke = Theme.Stroke.Button
		square.strokeColor = Builder.tierColor(if def then def.tier else "Common")
		label = speciesName(def, record.species)
	else
		square.color = Theme.Colors.Panel
		square.stroke = Theme.Stroke.Button
		square.strokeColor = Theme.Colors.Outline
		label = Strings.STATION_EMPTY_SLOT
	end
	Builder.frame(square)
	if label then
		Builder.label({
			parent = cell,
			name = "Name",
			text = label,
			textSize = Theme.TextSize.Min,
			position = UDim2.fromScale(0.5, 0.66),
			size = UDim2.fromScale(1, 0.34),
			anchor = Vector2.new(0.5, 0),
			zIndex = 5,
		})
	end
end

local function buildStationCard(parent: Frame, index: number, width: number, job: string, profile: Types.Profile)
	local station = stationOf(profile, job)
	local assigned = #station.assigned
	local card = Builder.frame({
		parent = parent,
		name = "Station" .. job,
		size = UDim2.fromScale(width, 1),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = if assigned > 0 then Theme.Colors.Featured else Theme.Rarity.Common,
		zIndex = 3,
	})
	card.LayoutOrder = index

	Builder.label({
		parent = card,
		name = "Name",
		text = Builder.text("STATION_" .. job),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.04, 0.05),
		size = UDim2.fromScale(0.6, 0.25),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Slots",
		text = Strings.STATION_SLOTS:format(assigned, station.slots),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.96, 0.05),
		size = UDim2.fromScale(0.3, 0.25),
		anchor = Vector2.new(1, 0),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Job",
		text = Builder.text("JOB_" .. job),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.04, 0.3),
		size = UDim2.fromScale(0.46, 0.18),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Rate",
		text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(Economy.stationRate(profile, job) * 60)),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.96, 0.3),
		size = UDim2.fromScale(0.46, 0.18),
		anchor = Vector2.new(1, 0),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})

	local slots = Builder.frame({
		parent = card,
		name = "Slots",
		position = UDim2.fromScale(0.04, 0.52),
		size = UDim2.fromScale(0.92, 0.44),
		zIndex = 4,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(STRIP_GAP, 0)
	layout.Parent = slots
	local max = Config.StationMaxSlots
	local slotWidth = (1 - STRIP_GAP * (max - 1)) / max
	for slot = 1, max do
		buildSlot(slots, slot, slotWidth, profile, station)
	end
end

local function rebuildStrip(profile: Types.Profile)
	local parent = strip
	if not parent then
		return
	end
	clearChildren(parent)
	local jobs = unlockedJobs(profile)
	if #jobs == 0 then
		return
	end
	local width = (1 - STRIP_GAP * (#jobs - 1)) / #jobs
	for index, job in ipairs(jobs) do
		buildStationCard(parent, index, width, job, profile)
	end
end

-- Grid -----------------------------------------------------------------------

-- Sizes the cells and the canvas so every card is square and the canvas is exactly as tall as the
-- rows need. Children of a ScrollingFrame scale against the canvas, so the cell height is divided by
-- the page count. Everything set here is a Scale value; pixels are only read to find the ratio.
local function layoutGrid()
	local frame, layout = grid, gridLayout
	if not frame or not layout then
		return
	end
	local abs = frame.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return
	end
	local cellPx = CELL_W * abs.X
	local gapPx = CELL_GAP * abs.X
	-- With pixel cell heights the canvas can follow the content exactly (no feedback), so the page maths
	-- that ran against a not-yet-final frame height (a 1020 px canvas for 336 px of cards) is gone.
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.fromScale(0, 0)
	-- The cell height is the cell width in pixels, derived from the frame on every resize. A Scale height
	-- inside a ScrollingFrame resolves against the canvas, and the canvas grows to hold the grid's content,
	-- so a Scale cell fed back into a taller canvas until one card sat 150 px down a 565 px canvas (Studio,
	-- 2026-10-05). Width and padding stay Scale.
	layout.CellSize = UDim2.new(CELL_W, 0, 0, cellPx)
	layout.CellPadding = UDim2.new(CELL_GAP, 0, 0, gapPx)
end

local function buildCard(parent: ScrollingFrame, index: number, entry: Entry)
	local record, def = entry.record, entry.def
	local tierColor = Builder.tierColor(if def then def.tier else "Common")
	local card = Builder.frame({
		parent = parent,
		name = record.uid,
		color = tierColor,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(tierColor),
		aspect = 1,
		zIndex = 3,
	})
	card.LayoutOrder = index
	Builder.gradient(card, tierColor)

	-- The placeholder stand-in until art exists: a square in the species colour with the shape name.
	local shape = Builder.frame({
		parent = card,
		name = "Shape",
		position = UDim2.fromScale(0.5, 0.4),
		size = UDim2.fromScale(0.44, 0.44),
		anchor = Vector2.new(0.5, 0.5),
		color = speciesColor(def),
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 4,
	})
	Builder.label({
		parent = shape,
		name = "ShapeName",
		text = shapeName(def),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	Builder.label({
		parent = card,
		name = "Name",
		text = entry.name,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.64),
		size = UDim2.fromScale(0.92, 0.16),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})

	local chip = Builder.pill({
		parent = card,
		name = "Speed",
		position = UDim2.fromScale(0.96, 0.04),
		size = UDim2.fromScale(0.36, 0.17),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})
	Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.ALIENS_SPEED:format(("%.1f"):format(entry.speed)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 6,
	})

	if record.overlay ~= "None" then
		local badge = Builder.pill({
			parent = card,
			name = "Overlay",
			position = UDim2.fromScale(0.04, 0.04),
			size = UDim2.fromScale(0.5, 0.17),
			color = Theme.Colors.Codex,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 5,
		})
		Builder.gradient(badge, Theme.Colors.Codex)
		Builder.label({
			parent = badge,
			name = "Text",
			text = Builder.text("OVERLAY_" .. record.overlay),
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 6,
		})
	end

	-- A band that names itself (Tiny, Big, HUGE: data/Sizes label) gets a small gold chip under the top
	-- row, over the shape's corner; Normal and Small show nothing.
	local band = Sizes.ById[record.size] or Sizes.ById[Sizes.Default]
	if band.label then
		local sizeChip = Builder.pill({
			parent = card,
			name = "Size",
			position = UDim2.fromScale(0.02, 0.42),
			size = UDim2.fromScale(0.26, 0.14), -- mid-left, clear of the shape in the centre and the chips in the top row
			anchor = Vector2.new(0, 0.5),
			color = Theme.Colors.Trough,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 6,
		})
		Builder.label({
			parent = sizeChip,
			name = "Text",
			text = Builder.text("SIZE_" .. band.id),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 7,
		})
	end

	local job = record.station
	Builder.label({
		parent = card,
		name = "Status",
		text = if job
			then Strings.ALIENS_WORKING:format(Builder.text("VERB_" .. job), Builder.text("STATION_" .. job))
			else Strings.ALIENS_RESTING,
		textSize = Theme.TextSize.Body,
		color = if job then Theme.Colors.White else Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, 0.97),
		size = UDim2.fromScale(0.94, 0.17),
		anchor = Vector2.new(0.5, 1),
		zIndex = 4,
	})
end

-- Owned aliens, fastest first, then by name, then by uid so the order is stable between refreshes.
local function sortedEntries(profile: Types.Profile): { Entry }
	local entries: { Entry } = {}
	for _, record in pairs(profile.aliens) do
		local def = Species.ById[record.species]
		table.insert(entries, {
			record = record,
			def = def,
			speed = Economy.workSpeed(record),
			name = speciesName(def, record.species),
		})
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		if a.speed ~= b.speed then
			return a.speed > b.speed
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.record.uid < b.record.uid
	end)
	return entries
end

local function rebuildGrid(profile: Types.Profile)
	local frame = grid
	if not frame then
		return
	end
	local entries = sortedEntries(profile)
	cardCount = #entries
	clearChildren(frame)
	for index, entry in ipairs(entries) do
		buildCard(frame, index, entry)
	end
	layoutGrid()
	if emptyLabel then
		emptyLabel.Visible = cardCount == 0
	end
	if countLabel then
		countLabel.Text = Strings.ALIENS_COUNT:format(cardCount)
	end
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	rebuildStrip(profile)
	rebuildGrid(profile)
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("AliensScreen", 20)
	root.Enabled = false
	gui = root

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		AliensScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.35,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.ALIENS_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(0.985, 0.015),
		size = UDim2.fromScale(0.11, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		AliensScreen.Close()
	end)

	-- 1. Station strip: one card per unlocked job, rebuilt on refresh.
	local stripFrame = Builder.frame({
		parent = body,
		name = "Stations",
		position = UDim2.fromScale(Theme.Margin, STRIP_Y),
		size = UDim2.fromScale(1 - Theme.Margin * 2, STRIP_H),
		zIndex = 3,
	})
	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Padding = UDim.new(STRIP_GAP, 0)
	stripLayout.Parent = stripFrame
	strip = stripFrame

	-- 2. Count line.
	countLabel = Builder.label({
		parent = body,
		name = "Count",
		text = Strings.ALIENS_COUNT:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(Theme.Margin, COUNT_Y),
		size = UDim2.fromScale(0.5, COUNT_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})

	-- 3. The grid: a ScrollingFrame with a thin dark bar; cards are rebuilt on refresh.
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Theme.Margin, GRID_Y)
	scroller.Size = UDim2.fromScale(1 - Theme.Margin * 2, GRID_H)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.fromScale(0, 0)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = body
	local cells = Instance.new("UIGridLayout")
	cells.FillDirection = Enum.FillDirection.Horizontal
	cells.FillDirectionMaxCells = COLUMNS
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cells.VerticalAlignment = Enum.VerticalAlignment.Top
	cells.StartCorner = Enum.StartCorner.TopLeft
	cells.CellSize = UDim2.fromScale(CELL_W, CELL_W)
	cells.CellPadding = UDim2.fromScale(CELL_GAP, CELL_GAP)
	cells.Parent = scroller
	grid = scroller
	gridLayout = cells
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGrid)

	local empty = Builder.label({
		parent = body,
		name = "Empty",
		text = Strings.ALIENS_EMPTY,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, GRID_Y + GRID_H / 2),
		size = UDim2.fromScale(0.7, 0.1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	empty.Visible = false
	emptyLabel = empty

	-- 4. Footer: Optimize asks the server to reseat the crew.
	Builder.button({
		parent = body,
		name = "Optimize",
		text = Strings.OPTIMIZE,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - Theme.Margin, 1 - Theme.Margin),
		size = UDim2.fromScale(0.24, FOOTER_H),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		ask("StationOptimize")
	end)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "stations", "rate" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

-- Public API -------------------------------------------------------------

function AliensScreen.IsOpen(): boolean
	return open
end

function AliensScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function AliensScreen.Close()
	if not open then
		return
	end
	open = false
	local root, body = gui, panel
	if root and body then
		Builder.close(body, function()
			if not open then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

function AliensScreen.Toggle()
	if open then
		AliensScreen.Close()
	else
		AliensScreen.Open()
	end
end

return AliensScreen
