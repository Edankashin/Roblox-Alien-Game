--!strict
-- StarterPlayerScripts.Client.UI.NearbyPanel: the free radar (tier 0). A narrow dark column on the
-- right edge under the HUD's biome chip that lists the species that can appear where the player stands
-- right now: Spawns.Biomes[biome].Any plus the list for the current condition, nothing else. Caught
-- species show their placeholder colour with a tier-coloured stroke; uncaught ones are dark silhouettes
-- with the unknown mark, named unless Secret. It re-reads the biome, the condition and the codex from
-- State on every change and every Config.NearbyRefreshSeconds while visible. No interaction yet: a
-- later milestone adds the compass direction. Pure presentation of State and the data tables.
-- Radar Mk2 and up (profile.gear.radar >= data/Radar Mk2.Tier): after the species that are out now,
-- up to Mk2.AbsentRows dimmed rows for the biome's species of tier Mk2.AbsentMinTier and up that are
-- listed under a condition not active right now, uncaught first and then the higher tier first, each
-- with a small tag naming the condition it needs ("in the rain"). Present rows keep priority within
-- MAX_ROWS. Below Mk2 nothing changes.
-- Compact mode: at Mk2 and up the Radar disc sits above the column (SetTop moves the column's top below
-- its default), and the disc already shows what is out, so the column becomes a short "not now" list: the
-- present species are skipped and only the absent rows show, each as two lines of minimum-size text (the
-- name, the condition under it) with no icon, as many as fit two lines each in the pixels the column has.
-- Nothing absent, or no room for even one, hides the whole column.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Spawns = require(Shared:WaitForChild("data"):WaitForChild("Spawns"))
local RadarTiers = require(Shared:WaitForChild("data"):WaitForChild("Radar"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)

local NearbyPanel = {}

type Row = {
	frame: Frame,
	icon: Frame,
	stroke: UIStroke,
	mark: TextLabel,
	markStroke: UIStroke?,
	name: TextLabel,
	nameStroke: UIStroke?,
	tag: TextLabel, -- the condition a dimmed row needs ("in the rain"); hidden on a present row
}

type Mk2Rules = {
	Tier: number,
	SecretPingFarSeconds: number,
	SecretPingNearSeconds: number,
	SecretNearStuds: number,
	SecretPulseScale: number,
	AbsentRows: number,
	AbsentMinTier: string,
}

-- A species listed under a condition that is not active now.
type Absent = { id: string, condition: string, caught: boolean, rank: number }

local mk2: Mk2Rules = (RadarTiers :: any).Mk2
-- Position of each tier in the rarity ladder, to compare against Mk2.AbsentMinTier.
local tierRank: { [string]: number } = {}
for index, name in ipairs(Tiers.Order) do
	tierRank[name] = index
end
local ANY_CONDITION = "Any" -- Spawns.Biomes key for the species that are always available

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
local LIST_BOTTOM = 1 - LIST_TOP - LIST_HEIGHT -- the gap under the list, of the column
local MAX_ROWS = 8
local ROW_MAX = 0.24 -- of the list height, so a short list does not become giant
local ROW_GAP = 0.015
local ICON_SHARE = 0.62 -- of the row height; the name takes the rest
-- A dimmed row (a species not out now) makes room for its tag: a smaller icon, then the name and the tag
-- half of the rest each. At the iPhone SE size a row is too short for two 14 px lines at any icon size,
-- so the name and the tag overlap a little there; the tag sits on the row's lower edge.
local DIM_ICON_SHARE = 0.4
local DIM_TRANSPARENCY = 0.55 -- the icon, its mark and the name of a species that is not out now
-- Compact mode's fitting rule, in pixels (the sizes it sets stay Scale): a text line is LINE_HEIGHT times
-- its size tall and a row is COMPACT_LINES lines.
local LINE_HEIGHT = 1.25
local COMPACT_LINES = 2

local gui: ScreenGui? = nil
local column: Frame? = nil
local columnTop = COLUMN_TOP -- SetTop moves this; the column's bottom edge stays at COLUMN_TOP + COLUMN_HEIGHT
local list: Frame? = nil
local titleLabel: TextLabel? = nil
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
	-- The tag: the minimum text size in the Select blue, on the row's lower edge, trimmed rather than spilling
	-- past the column when a condition's phrase is long.
	local tag = Builder.label({
		parent = frame,
		name = "Tag",
		text = "",
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(1.1, (1 - DIM_ICON_SHARE) / 2),
		anchor = Vector2.new(0.5, 1),
		zIndex = 4,
	})
	tag.TextTruncate = Enum.TextTruncate.AtEnd
	tag.Visible = false
	return {
		frame = frame,
		icon = icon,
		stroke = stroke,
		mark = mark,
		markStroke = mark:FindFirstChildOfClass("UIStroke"),
		name = name,
		nameStroke = name:FindFirstChildOfClass("UIStroke"),
		tag = tag,
	}
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

-- True from Radar.Mk2.Tier up, read from the profile's radar tier (pushed by GearChanged).
local function mk2Held(profile: Types.Profile): boolean
	return profile.gear.radar >= mk2.Tier
end

-- The species of this biome's Spawns table listed under a condition that is not active now, of tier
-- Mk2.AbsentMinTier or higher, not already out (`present`), at most `limit`: uncaught first, then the higher
-- tier first, then by id so the order never shuffles. A species listed under several absent conditions
-- is named for the first of them in alphabetical order.
local function absentEntries(present: { [string]: boolean }, profile: Types.Profile, limit: number): { Absent }
	local found: { Absent } = {}
	local tables: { [string]: Spawns.BiomeTable } = Spawns.Biomes
	local biomeTable = tables[State.GetBiome()]
	if not biomeTable or limit <= 0 then
		return found
	end
	local active: { [string]: boolean } = {}
	for _, condition in ipairs(State.GetConditions()) do
		active[condition] = true
	end
	local conditions: { string } = {}
	for condition in pairs(biomeTable) do
		if condition ~= ANY_CONDITION and not active[condition] then
			table.insert(conditions, condition)
		end
	end
	table.sort(conditions)
	local minRank = tierRank[mk2.AbsentMinTier] or (#Tiers.Order + 1) -- an unknown tier lists nothing
	local seen: { [string]: boolean } = {}
	for _, condition in ipairs(conditions) do
		for _, id in ipairs(biomeTable[condition]) do
			local def = Species.ById[id]
			if def and not present[id] and not seen[id] then
				local rank = tierRank[def.tier] or 0
				if rank >= minRank then
					seen[id] = true
					local entry = profile.codex[id]
					table.insert(found, { id = id, condition = condition, caught = entry ~= nil and entry.count > 0, rank = rank })
				end
			end
		end
	end
	table.sort(found, function(a: Absent, b: Absent): boolean
		if a.caught ~= b.caught then
			return not a.caught
		end
		if a.rank ~= b.rank then
			return a.rank > b.rank
		end
		return a.id < b.id
	end)
	while #found > limit do
		table.remove(found)
	end
	return found
end

type RowMode = "present" | "dimmed" | "compact"

-- Lays a row out as a present species (the full icon, the name under it), a dimmed one (a smaller icon,
-- the name, then the tag on the lower edge) or a compact one (no icon, the name above the tag, both left
-- aligned and trimmed to the row) and sets its dimming. Everything is rewritten every refresh because the
-- pooled rows swap between the modes.
local function layoutRow(row: Row, mode: RowMode)
	local compact = mode == "compact"
	local dimmed = mode == "dimmed"
	row.icon.Visible = not compact
	row.tag.Visible = compact or dimmed
	local align = if compact then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	row.name.TextXAlignment = align
	row.tag.TextXAlignment = align
	row.name.TextTruncate = if compact then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None
	if compact then
		row.name.AnchorPoint = Vector2.new(0, 0)
		row.name.Position = UDim2.fromScale(0, 0)
		row.name.Size = UDim2.fromScale(1, 1 / COMPACT_LINES)
		row.tag.AnchorPoint = Vector2.new(0, 1)
		row.tag.Position = UDim2.fromScale(0, 1)
		row.tag.Size = UDim2.fromScale(1, 1 / COMPACT_LINES)
	else
		local share = if dimmed then DIM_ICON_SHARE else ICON_SHARE
		row.icon.Size = UDim2.fromScale(1, share)
		row.name.AnchorPoint = Vector2.new(0.5, 0)
		row.name.Position = UDim2.fromScale(0.5, share)
		row.name.Size = UDim2.fromScale(1.1, if dimmed then (1 - share) / 2 else 1 - share)
		row.tag.AnchorPoint = Vector2.new(0.5, 1)
		row.tag.Position = UDim2.fromScale(0.5, 1)
		row.tag.Size = UDim2.fromScale(1.1, (1 - DIM_ICON_SHARE) / 2)
	end
	local fade = if dimmed then DIM_TRANSPARENCY else 0
	row.icon.BackgroundTransparency = fade
	row.stroke.Transparency = fade
	row.mark.TextTransparency = fade
	row.name.TextTransparency = fade
	local markStroke, nameStroke = row.markStroke, row.nameStroke
	if markStroke then
		markStroke.Transparency = fade
	end
	if nameStroke then
		nameStroke.Transparency = fade
	end
end

-- The title's text and height and the list's top and height (the column's fractions).
local function setHeader(text: string, titleHeight: number, listTop: number, listHeight: number)
	local title, holder = titleLabel, list
	if title then
		title.Text = text
		title.Size = UDim2.fromScale(0.86, titleHeight)
	end
	if holder then
		holder.Position = UDim2.fromScale(0.5, listTop)
		holder.Size = UDim2.fromScale(0.9, listHeight)
	end
end

-- Compact mode's geometry and how many two-line rows fit. The column's height in pixels is the screen's
-- times its fraction (the ScreenGui's own size, so it is known while the column is hidden); the rule is
-- that the list, LIST_HEIGHT of the column, holds COMPACT_LINES lines of minimum-size text per row. The
-- title takes one line at the top and the list sits right under it, so the rows never run into the title.
-- 0 while the screen has not been measured yet; the size signal and the tick call refresh again.
local function fitCompact(): number
	local root = gui
	local columnPx = if root then root.AbsoluteSize.Y * (COLUMN_TOP + COLUMN_HEIGHT - columnTop) else 0
	if columnPx <= 0 then
		return 0
	end
	local linePx = Theme.TextSize.Min * LINE_HEIGHT
	local fit = math.floor(LIST_HEIGHT * columnPx / (COMPACT_LINES * linePx))
	local top = math.max(LIST_TOP, TITLE_TOP + linePx / columnPx)
	local height = math.max(0, 1 - LIST_BOTTOM - top)
	fit = math.min(fit, math.floor(height * columnPx / (COMPACT_LINES * Theme.TextSize.Min)))
	setHeader(Strings.NEARBY_ABSENT_TAG, linePx / columnPx, top, height)
	return math.max(fit, 0)
end

local function refresh()
	if not list or not State.Has() then
		return
	end
	local profile = State.Get()
	local ids = nearbyIds()
	local held = mk2Held(profile)
	-- Under the Radar disc (the column's top is below its default) at Mk2 and up: the compact "not now" list.
	local compact = held and columnTop > COLUMN_TOP
	local presentCount = 0
	local absentLimit = 0
	if compact then
		absentLimit = math.min(mk2.AbsentRows, MAX_ROWS, fitCompact())
	else
		setHeader(Strings.NEARBY_TITLE, TITLE_HEIGHT, LIST_TOP, LIST_HEIGHT)
		presentCount = math.min(#ids, MAX_ROWS)
		absentLimit = if held then math.min(mk2.AbsentRows, MAX_ROWS - presentCount) else 0
	end
	local absent: { Absent } = {}
	if absentLimit > 0 then
		local present: { [string]: boolean } = {}
		for _, id in ipairs(ids) do
			present[id] = true
		end
		absent = absentEntries(present, profile, absentLimit)
	end
	local count = presentCount + #absent
	ensureRows(count)
	-- Rows share the list height evenly up to ROW_MAX each, so four species read large and eight still fit.
	-- A compact row is one of the `fit` slots the list was sized for, stacked from the top.
	local rowHeight = if count > 0 then math.min(ROW_MAX, (1 - ROW_GAP * (count - 1)) / count) else ROW_MAX
	if compact and absentLimit > 0 then
		rowHeight = (1 - ROW_GAP * (absentLimit - 1)) / absentLimit
	end

	for index, row in ipairs(rows) do
		if index > count then
			row.frame.Visible = false
			continue
		end
		local absentIndex = index - presentCount
		local absentEntry: Absent? = if absentIndex >= 1 then absent[absentIndex] else nil
		local id = if absentEntry then absentEntry.id else ids[index]
		local def = if id then Species.ById[id] else nil
		if not id or not def then
			row.frame.Visible = false
			continue
		end
		local entry = profile.codex[id]
		local caught = entry ~= nil and entry.count > 0
		row.frame.Visible = true
		row.frame.Size = UDim2.fromScale(1, rowHeight)
		layoutRow(row, if compact then "compact" elseif absentEntry then "dimmed" else "present")
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
		if absentEntry then
			-- The tag is narrow: a condition with a COND_SHORT_ string uses it ("in a Shower"), the rest their phrase.
			local shortKey = "COND_SHORT_" .. absentEntry.condition
			local phrase = Builder.text(shortKey)
			if phrase == shortKey then
				phrase = Builder.text("COND_PHRASE_" .. absentEntry.condition)
			end
			row.tag.Text = Strings.NEARBY_APPEARS:format(phrase)
		end
	end

	if emptyLabel then
		emptyLabel.Visible = not compact and count == 0
	end
	if column then
		column.Visible = not compact or count > 0 -- compact with nothing absent (or no room) hides the whole column
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

	titleLabel = Builder.label({
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
	State.OnChanged("gear", refresh) -- a new radar tier adds or drops the dimmed rows
	if gui then
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh) -- the compact list's fit depends on the pixels
	end
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
	refresh() -- a column under the disc is the compact "not now" list at Mk2 and up
end

-- The column's top edge with nothing above it: the slot under the HUD's shower chip.
function NearbyPanel.DefaultTop(): number
	return COLUMN_TOP
end

return NearbyPanel
