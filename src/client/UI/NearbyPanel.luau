--!strict
-- StarterPlayerScripts.Client.UI.NearbyPanel: the free radar (tier 0). A narrow dark column on the
-- right edge under the HUD's biome chip that lists the species that can appear where the player stands
-- right now: Spawns.Biomes[biome].Any plus the list for the current condition, nothing else. Caught
-- species show their placeholder colour with a tier-coloured stroke; uncaught ones are dark silhouettes
-- with the unknown mark, named unless Secret. It re-reads the biome, the condition and the codex from
-- State on every change and every Config.NearbyRefreshSeconds while visible. No interaction yet: a
-- later milestone adds the compass direction. Pure presentation of State and the data tables.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Spawns = require(Shared:WaitForChild("data"):WaitForChild("Spawns"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)

local NearbyPanel = {}

type Row = {
	frame: Frame,
	icon: Frame,
	stroke: UIStroke,
	mark: TextLabel,
	name: TextLabel,
}

-- The mark on a silhouette. CODEX_UNKNOWN ("???") until a single-glyph key exists in the strings table.
local UNKNOWN_MARK = Strings.UI_UNKNOWN_GLYPH

-- Right edge, between the HUD's shower chip (ends near y 0.215) and the action button (starts near y 0.83).
local COLUMN_X = 0.985
local COLUMN_TOP = 0.225
local COLUMN_WIDTH = 0.1
local COLUMN_HEIGHT = 0.405
local TITLE_TOP = 0.02
local TITLE_HEIGHT = 0.085
local LIST_TOP = 0.12
local LIST_HEIGHT = 0.86
local MAX_ROWS = 8
local ROW_MAX = 0.24 -- of the list height, so a short list does not become giant
local ROW_GAP = 0.015
local ICON_SHARE = 0.62 -- of the row height; the name takes the rest

local gui: ScreenGui? = nil
local column: Frame? = nil
local columnTop = COLUMN_TOP -- SetTop moves this; the column's bottom edge stays at COLUMN_TOP + COLUMN_HEIGHT
local list: Frame? = nil
local emptyLabel: TextLabel? = nil
local rows: { Row } = {}
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local started = false
local visible = true

-- Rows -------------------------------------------------------------------------

local function buildRow(parent: Frame, index: number): Row
	local frame = Builder.frame({
		parent = parent,
		name = "Row" .. index,
		size = UDim2.fromScale(1, ROW_MAX),
		zIndex = 2,
	})
	frame.LayoutOrder = index
	-- Square icon: the aspect fit keeps it inside both the row height and the column width.
	local icon = Builder.frame({
		parent = frame,
		name = "Icon",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, ICON_SHARE),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Shadow,
		corner = Theme.Corner.Card,
		aspect = 1,
		zIndex = 3,
	})
	local stroke = Builder.stroke(icon, Theme.Stroke.Text, Theme.Rarity.Common)
	local mark = Builder.label({
		parent = icon,
		name = "Mark",
		text = UNKNOWN_MARK,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.6),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	local name = Builder.label({
		parent = frame,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, ICON_SHARE),
		size = UDim2.fromScale(1.1, 1 - ICON_SHARE),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
	return { frame = frame, icon = icon, stroke = stroke, mark = mark, name = name }
end

local function ensureRows(count: number)
	local parent = list
	if not parent then
		return
	end
	while #rows < count do
		table.insert(rows, buildRow(parent, #rows + 1))
	end
end

-- Refresh ----------------------------------------------------------------------

-- The species that can spawn here now: the biome's "Any" list plus the lists for every active condition
-- (State.GetConditions mirrors WorldClock: the special weather while it runs, plus Night or Day).
local function nearbyIds(): { string }
	local tables: { [string]: Spawns.BiomeTable } = Spawns.Biomes
	local biomeTable = tables[State.GetBiome()]
	local ids: { string } = {}
	if not biomeTable then
		return ids
	end
	for _, id in ipairs(biomeTable.Any or {}) do
		table.insert(ids, id)
	end
	for _, condition in ipairs(State.GetConditions()) do
		for _, id in ipairs(biomeTable[condition] or {}) do
			table.insert(ids, id)
		end
	end
	return ids
end

local function refresh()
	if not list or not State.Has() then
		return
	end
	local profile = State.Get()
	local ids = nearbyIds()
	local count = math.min(#ids, MAX_ROWS)
	ensureRows(count)
	-- Rows share the list height evenly up to ROW_MAX each, so four species read large and eight still fit.
	local rowHeight = if count > 0 then math.min(ROW_MAX, (1 - ROW_GAP * (count - 1)) / count) else ROW_MAX

	for index, row in ipairs(rows) do
		local id = ids[index]
		if index > count or not id then
			row.frame.Visible = false
			continue
		end
		local def = Species.ById[id]
		if not def then
			row.frame.Visible = false
			continue
		end
		local entry = profile.codex[id]
		local caught = entry ~= nil and entry.count > 0
		row.frame.Visible = true
		row.frame.Size = UDim2.fromScale(1, rowHeight)
		row.stroke.Color = Builder.tierColor(def.tier)
		if caught then
			row.icon.BackgroundColor3 = Color3.fromHex(def.placeholder.color)
			row.mark.Visible = false
			row.name.Text = def.name
		else
			row.icon.BackgroundColor3 = Theme.Shadow
			row.mark.Visible = true
			row.name.Text = if def.tier == "Secret" then Strings.CODEX_UNKNOWN else def.name
		end
	end

	if emptyLabel then
		emptyLabel.Visible = count == 0
	end
end

-- Ticking ----------------------------------------------------------------------

local function startTicking()
	if heartbeat then
		return
	end
	accumulator = 0
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < Config.NearbyRefreshSeconds then
			return
		end
		accumulator = 0
		refresh()
	end)
end

local function stopTicking()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Nearby", 10)
	gui = root

	local frame = Builder.pill({
		parent = root,
		name = "Column",
		position = UDim2.fromScale(COLUMN_X, columnTop),
		size = UDim2.fromScale(COLUMN_WIDTH, COLUMN_TOP + COLUMN_HEIGHT - columnTop),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 1,
	})
	Builder.gradient(frame, Theme.Colors.Trough)
	column = frame

	Builder.label({
		parent = frame,
		name = "Title",
		text = Strings.NEARBY_TITLE,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, TITLE_TOP),
		size = UDim2.fromScale(0.86, TITLE_HEIGHT),
		anchor = Vector2.new(0.5, 0),
		zIndex = 2,
	})

	local holder = Builder.frame({
		parent = frame,
		name = "List",
		position = UDim2.fromScale(0.5, LIST_TOP),
		size = UDim2.fromScale(0.9, LIST_HEIGHT),
		anchor = Vector2.new(0.5, 0),
		zIndex = 2,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = holder
	list = holder

	local empty = Builder.label({
		parent = frame,
		name = "Empty",
		text = Strings.NEARBY_NONE,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, LIST_TOP + LIST_HEIGHT / 2),
		size = UDim2.fromScale(0.86, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Rarity.Common,
		zIndex = 2,
	})
	empty.Visible = false
	emptyLabel = empty
end

-- Public API -------------------------------------------------------------

function NearbyPanel.Start()
	if started then
		return
	end
	started = true
	build()
	State.OnChanged("biome", refresh)
	State.OnChanged("clock", refresh)
	State.OnChanged("stations", refresh)
	State.OnChanged("codex", refresh)
	refresh()
	if gui then
		gui.Enabled = visible
	end
	if visible then
		startTicking()
	end
end

function NearbyPanel.SetVisible(show: boolean)
	visible = show
	if gui then
		gui.Enabled = show
	end
	if not started then
		return
	end
	if show then
		refresh()
		startTicking()
	else
		stopTicking()
	end
end

-- Moves the column's top edge (screen Scale) and shrinks it so its bottom edge stays where it is
-- (COLUMN_TOP + COLUMN_HEIGHT). The bootstrap feeds in the Radar minimap's bottom edge while the
-- disc shows above the column, and DefaultTop() when it hides. No-op when unchanged; a value outside
-- the column's own span is clamped to it.
function NearbyPanel.SetTop(top: number)
	local bottom = COLUMN_TOP + COLUMN_HEIGHT
	local next = math.clamp(top, COLUMN_TOP, bottom)
	if next == columnTop then
		return
	end
	columnTop = next
	local frame = column
	if frame then
		frame.Position = UDim2.fromScale(COLUMN_X, next)
		frame.Size = UDim2.fromScale(COLUMN_WIDTH, bottom - next)
	end
end

-- The column's top edge with nothing above it: the slot under the HUD's shower chip.
function NearbyPanel.DefaultTop(): number
	return COLUMN_TOP
end

return NearbyPanel
