--!strict
-- StarterPlayerScripts.Client.UI.CodexScreen: the codex panel. The left two-thirds is the page for the
-- player's current world: a title with the caught/total count, a purple progress bar, and a scrolling
-- grid of one square card per species (Tiers.Order, then name). Caught species show their model, still, on their
-- colour (UI.SpeciesThumb; the name without a model); uncaught ones are dark silhouettes with the unknown mark, named unless Secret so
-- players know what to chase. The right third is the detail card: a slowly turning ViewportFrame of
-- the species mesh (World.Models; shadowed while uncaught) or, without one, the placeholder part on a
-- pedestal, the name, the tier in its colour, the jobs, and either where it
-- was found, the caught count and the best overlay, or a hint line and the first-catch payout.
-- Everything shown is read from the profile mirror in State and the shared data tables; nothing here
-- decides an outcome.
-- The look is block cells (UI Playbook "Screens after the HUD", Decisions B44): the panel a cream plate at the panel cell with the
-- block header and close; a grid card a square edged block whose ink is its tier's colour (Codex purple while selected: the
-- stroke's thickness step is now a colour step), its square a flat block, its count badge a flat block; the progress bar a flat
-- dark block filled cell-true; the detail card a fitted edged block in its tier's ink, the turning view on a flat block in the
-- tier's lighter colour.
-- The clean pass (docs/vault/05-ui-design/Clean-UI-Pass.md, package C): the detail card is never an empty pane, it opens on the most
-- recently caught species (or the first entry; Shared/PanelQuiet.CodexDefault), and an event species wears a small purple block in
-- its corner instead of the word "Event" (the detail card names the event). "This week" and "Vaulted" stay words: they ask for action.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local PanelQuiet = require(Shared:WaitForChild("PanelQuiet"))
local WeeklyMath = require(Shared:WaitForChild("WeeklyMath"))
local SeasonMath = require(Shared:WaitForChild("SeasonMath"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local State = require(script.Parent.Parent.State)
local Models = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Models"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local CodexScreen = {}

-- One grid card. Built once per slot and refilled on every refresh.
type Cell = {
	slot: Frame,
	card: Frame, -- an edged block plate: setBlockInk is its ring
	square: Frame, -- the colour block behind the picture: the empty state, hidden while the species' model shows
	picture: Frame, -- the card's picture area: the model's view fills it; the mark stands over it
	mark: TextLabel,
	name: TextLabel,
	badge: Frame,
	badgeLabel: TextLabel,
	stamp: TextLabel, -- top-left: "This week" for the Alien of the Week, "Vaulted" for a limited species out of its window
	eventMark: Frame, -- top-left: a small purple block for an event alien (or a returning drop) while its season runs
	thumb: SpeciesThumb.Thumb, -- the species' model, still, filling the picture area (hidden without one)
	speciesId: string,
	tier: string,
}

-- The detail card on the right.
type Detail = {
	card: Frame, -- a fitted edged block plate, its ink the tier's colour
	prompt: TextLabel,
	content: Frame,
	viewport: ViewportFrame,
	view: Frame, -- the flat block the viewport stands on: its face the tier's lighter colour, its ink the tier's
	camera: Camera,
	part: Part, -- the placeholder; hidden while a mesh clone stands on the pedestal
	model: Model?,
	mark: TextLabel,
	name: TextLabel,
	tier: TextLabel,
	jobs: TextLabel,
	lineA: TextLabel,
	lineB: TextLabel,
	lineC: TextLabel,
}

-- The mark on a silhouette. CODEX_UNKNOWN ("???") until a single-glyph key exists in the strings table.
local UNKNOWN_MARK = Strings.UI_UNKNOWN_GLYPH

local PAGE_WIDTH = 0.62 -- of the panel; the detail card takes the rest
local DETAIL_X = 0.66
local DETAIL_TOP = 0.17 -- below the close button
local MIN_COLS = 3
local MAX_COLS = 5
local MIN_CELL_PX = 80 -- a ten-letter name at the minimum text size needs about this much width
local CARD_INSET = 0.92 -- the card inside its grid slot; the rest is the gap between cards
local SCROLLBAR_PX = 4 -- thin dark scrollbar on the right (a thickness, like a stroke)
-- The weekly stamp, in card Scale: inside the card's top-left corner (clear of the count badge, which sits at
-- 0.48 to 0.64 down the right side), wide enough for "This week" at the minimum text size on the narrowest card.
local STAMP_X = 0.06
local STAMP_Y = 0.03
local STAMP_W = 0.84
local STAMP_H = 0.14 -- one line of the minimum text; taller touched the unknown mark on an 81 px cell
local EVENT_MARK_W = 0.13 -- the event block's side, of the card: about 10 px on an 81 px card
-- A grid card's layers: the card plate at 4 takes 4 to 7 (its ink, face and edges); on it the square at CARD_TOP (its mark at
-- its own top), the badge one above, the stamp over both, the tap button over everything.
local CARD_TOP = 4 + Theme.Block.Layer.Content
local STAMP_Z = CARD_TOP + Theme.Block.Layer.Content + 2 -- above the square's mark and the badge's label
local TAP_Z = STAMP_Z + 1
local CARD_ROWS = 10 -- a grid card is an edged block this many cells tall (an 81 px card at iPhone SE: 7.4 px cells)
local PICTURE_Y = 0.04 -- the picture area on a card: the model's view fills it, over the card's face (no colour block behind a real model)
local PICTURE_W = 0.9
local PICTURE_H = 0.6
local FLAT_ROWS = 3 -- a flat block (the square, the badge, the bar, the view's block)
local SECONDS_PER_HOUR = 3600 -- unit conversions for the "Nd Nh" time left of the Alien of the Week and of the season
local SECONDS_PER_DAY = 86400

-- "Nd Nh" for the weekly's and the season's time left.
local function daysHoursText(seconds: number): string
	local left = math.max(0, math.floor(seconds))
	return Strings.TIME_DH:format(left // SECONDS_PER_DAY, (left % SECONDS_PER_DAY) // SECONDS_PER_HOUR)
end

-- What a species' limited window reads as in the Codex: "week" (the Alien of the Week now), "event" (an event alien
-- while its season runs, or a limited weekly drop the running season brings back: the Vault Rotation), "vaulted" (a
-- limited species out of its window), nil (an ordinary species). The weekly's own "This week" wins when a returning
-- species is also the week's drop. `override` is the season Dev's /season forced (nil in play).
type LimitedState = "week" | "event" | "vaulted"
local function limitedState(speciesId: string, now: number, offset: number, override: string?): LimitedState?
	if WeeklyMath.IsCurrent(speciesId, now, offset) then
		return "week"
	elseif SeasonMath.IsLimited(speciesId) then
		return if SeasonMath.IsCurrent(speciesId, now, override) then "event" else "vaulted"
	elseif WeeklyMath.IsLimited(speciesId) then
		return if SeasonMath.IsReturning(speciesId, now, override) then "event" else "vaulted"
	end
	return nil
end

local PART_STUDS = 2 -- placeholder part size at scale 1, as the Spawner builds them
local PEDESTAL_RADIUS = 1.6
local PEDESTAL_THICKNESS = 0.25
local PEDESTAL_TOP = -1.2 -- studs; the alien part stands on this
local ROTATE_SPEED = math.rad(40) -- radians per second while the screen is open
local CAMERA_FOV = 45
local CAMERA_DISTANCE = 6 -- studs from the look-at point along the line of sight, for aliens that fit
local CAMERA_HEIGHT = 1.3 -- camera height at that distance; the line of sight keeps this slope when it pulls back
local CAMERA_TARGET_Y = 0.1 -- the look-at point, just above the pedestal centre
local CAMERA_FIT = 1.15 -- margin over the exact fit when a tall mesh pushes the camera back

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

local gui: ScreenGui? = nil
local panel: Frame? = nil
local titleLabel: TextLabel? = nil
local setBar: ((number) -> ())? = nil -- the progress bar's block fill
local barPercent: TextLabel? = nil
local grid: ScrollingFrame? = nil
local gridLayout: UIGridLayout? = nil
local cells: { Cell } = {}
local detail: Detail? = nil
local selected: string? = nil
local open = false
local render: RBXScriptConnection? = nil
local angle = 0
local partBaseY = 0
local partUpright = false -- cylinders stand on end, as the Spawner places them
local rosterCache: { [number]: { Types.SpeciesDef } } = {}

-- Data -----------------------------------------------------------------------

-- Every species of a world, in Tiers.Order then by name. Cached: the tables never change at runtime.
local function roster(worldId: number): { Types.SpeciesDef }
	local cached = rosterCache[worldId]
	if cached then
		return cached
	end
	local list: { Types.SpeciesDef } = {}
	for _, def in ipairs(Species.List) do
		if def.world == worldId then
			table.insert(list, def)
		end
	end
	local rank: { [string]: number } = {}
	for index, tier in ipairs(Tiers.Order) do
		rank[tier] = index
	end
	table.sort(list, function(a: Types.SpeciesDef, b: Types.SpeciesDef): boolean
		local ra, rb = rank[a.tier] or 0, rank[b.tier] or 0
		if ra ~= rb then
			return ra < rb
		end
		return a.name < b.name
	end)
	rosterCache[worldId] = list
	return list
end

local function caughtCount(profile: Types.Profile, id: string): number
	local entry = profile.codex[id]
	return if entry then entry.count else 0
end

-- Uncaught Secrets stay "???"; every other uncaught species shows its name so players know what to chase.
local function displayName(def: Types.SpeciesDef, caught: boolean): string
	return if caught or def.tier ~= "Secret" then def.name else Strings.CODEX_UNKNOWN
end

local function jobsText(def: Types.SpeciesDef): string
	local parts: { string } = {}
	for _, job in ipairs(def.jobs) do
		table.insert(parts, Strings.CODEX_JOB_LEVEL:format(Builder.text("JOB_" .. job.job), job.level))
	end
	return Strings.CODEX_JOBS:format(table.concat(parts, ", "))
end

-- Detail card ----------------------------------------------------------------

-- Turns whatever stands on the pedestal: the mesh clone by its pivot (its feet, on the pedestal top),
-- or the placeholder part about its centre, upright for cylinders.
local function placePart(d: Detail)
	local model = d.model
	if model then
		model:PivotTo(CFrame.new(0, PEDESTAL_TOP, 0) * CFrame.Angles(0, angle, 0))
		return
	end
	local cf = CFrame.new(0, partBaseY, 0) * CFrame.Angles(0, angle, 0)
	if partUpright then
		cf = cf * CFrame.Angles(0, 0, math.rad(90))
	end
	d.part.CFrame = cf
end

-- The camera keeps its line of sight and pulls back only when something taller than the default
-- framing stands on the pedestal (meshes run to about twice the placeholder height).
local function frameCamera(d: Detail, height: number)
	local target = Vector3.new(0, CAMERA_TARGET_Y, 0)
	local direction = Vector3.new(0, CAMERA_HEIGHT - CAMERA_TARGET_Y, CAMERA_DISTANCE).Unit
	local halfSpan = math.max(PEDESTAL_TOP + height - CAMERA_TARGET_Y, CAMERA_TARGET_Y - (PEDESTAL_TOP - PEDESTAL_THICKNESS))
	local distance = math.max(CAMERA_DISTANCE, halfSpan / math.tan(math.rad(CAMERA_FOV) / 2) * CAMERA_FIT)
	d.camera.CFrame = CFrame.lookAt(target + direction * distance, target)
end

local function setPart(d: Detail, def: Types.SpeciesDef, caught: boolean)
	local previous = d.model
	if previous then
		previous:Destroy()
		d.model = nil
	end
	-- Uncaught species stand as silhouettes only while the Silhouettes preference is on.
	local shadowed = not caught and Prefs.Silhouettes()
	local model = Models.Clone(def, Config.ModelViewportScale)
	if model then
		Models.SetShadow(model, shadowed)
		model.Parent = d.viewport
		d.model = model
		d.part.Transparency = 1
		frameCamera(d, Models.Height(model))
		placePart(d)
		return
	end
	d.part.Transparency = 0
	local size = PART_STUDS * def.placeholder.scale
	d.part.Shape = SHAPES[def.placeholder.shape] or Enum.PartType.Ball
	d.part.Size = Vector3.one * size
	d.part.Color = if shadowed then Theme.Shadow else Color3.fromHex(def.placeholder.color)
	partUpright = def.placeholder.shape == "Cylinder"
	partBaseY = PEDESTAL_TOP + size / 2
	frameCamera(d, size)
	placePart(d)
end

local function fillDetail(profile: Types.Profile)
	local d = detail
	if not d then
		return
	end
	local id = selected
	local def: Types.SpeciesDef? = nil
	if id then
		def = Species.ById[id]
	end
	if not def then
		d.prompt.Visible = true
		d.content.Visible = false
		Builder.setBlockInk(d.card, Theme.Rarity.Common)
		return
	end

	local entry = profile.codex[def.id]
	local count = if entry then entry.count else 0
	local caught = count > 0
	local tierColor = Builder.tierColor(def.tier)
	d.prompt.Visible = false
	d.content.Visible = true
	Builder.setBlockInk(d.card, tierColor)
	Builder.setBlockInk(d.view, tierColor)
	Builder.setBlockColor(d.view, Builder.lighter(tierColor, 0.55)) -- the backdrop in its rarity colour
	setPart(d, def, caught)
	d.mark.Visible = not caught
	d.name.Text = displayName(def, caught)
	d.tier.Text = Builder.text("TIER_" .. def.tier)
	d.tier.TextColor3 = tierColor
	local eventSeason = SeasonMath.Current(State.Now(), State.GetSeasonOverride())
	if eventSeason and limitedState(def.id, State.Now(), State.GetWeeklyOffset(), State.GetSeasonOverride()) == "event" then
		-- an event species: the card says which event brought it
		d.tier.Text = Strings.CODEX_TIER_EVENT:format(d.tier.Text, Builder.text("SEASON_" .. eventSeason.season.id))
	end
	d.jobs.Text = jobsText(def)

	local biome = Builder.text("BIOME_" .. def.biome)
	local phrase = Builder.text("COND_PHRASE_" .. def.condition)
	if caught then
		d.lineA.Text = Strings.CODEX_FOUND:format(biome, phrase)
		d.lineB.Text = Strings.CODEX_CAUGHT:format(count)
		local best = if entry then entry.bestOverlay else "None"
		d.lineC.Visible = best ~= "None"
		if best ~= "None" then
			-- an overlay with a `desc` row says what it is after its name ("Best: Launch Gold. Caught during launch week.")
			local overlayRow = Overlays.Overlays[best]
			local bestName = Builder.text("OVERLAY_" .. best)
			d.lineC.Text = if overlayRow and overlayRow.desc
				then Strings.CODEX_BEST_DESC:format(bestName, Builder.text(overlayRow.desc))
				else Strings.CODEX_BEST:format(bestName)
		end
	else
		-- An uncaught Alien of the Week says how long it stays; an uncaught event alien says its event is on and how
		-- long (or, for a returning weekly drop, which event brought it back); an uncaught limited one out of its
		-- window says it is vaulted.
		local now = State.Now()
		local override = State.GetSeasonOverride()
		local state = limitedState(def.id, now, State.GetWeeklyOffset(), override)
		local weekly = WeeklyMath.Current(now, State.GetWeeklyOffset())
		local season = SeasonMath.Current(now, override)
		if state == "week" and weekly then
			d.lineA.Text = Strings.CODEX_WEEKLY_HINT:format(daysHoursText(weekly.secondsLeft))
		elseif state == "event" and season then
			local timeLeft = daysHoursText(season.secondsLeft)
			if SeasonMath.IsLimited(def.id) then
				d.lineA.Text = Strings.CODEX_EVENT_HINT:format(timeLeft)
			else
				d.lineA.Text = Strings.CODEX_RETURNING_HINT:format(Builder.text("SEASON_" .. season.season.id), timeLeft)
			end
		elseif state == "vaulted" then
			d.lineA.Text = Strings.CODEX_VAULTED_HINT
		elseif SeasonMath.IsTrackReward(def.id) then
			d.lineA.Text = Strings.CODEX_TRACK_HINT -- it never spawns: "by quest" would send players looking
		else
			d.lineA.Text = Strings.CODEX_HINT:format(biome, phrase)
		end
		d.lineB.Text = Strings.CODEX_FIRST_CATCH:format(Builder.formatNumber(Tiers.Tiers[def.tier].codexScrap))
		d.lineC.Visible = false
	end
end

-- Purple ink on the selected card, the tier's ink on the rest, then the detail card follows.
local function applySelection(profile: Types.Profile)
	for _, cell in ipairs(cells) do
		if not cell.slot.Visible then
			continue
		end
		local isSelected = cell.speciesId == selected
		Builder.setBlockInk(cell.card, if isSelected then Theme.Colors.Codex else Builder.tierColor(cell.tier))
	end
	fillDetail(profile)
end

local function buildDetail(parent: Frame): Detail
	local card = Builder.blockPlate({
		parent = parent,
		name = "Detail",
		color = Theme.Colors.White,
		ink = Theme.Rarity.Common,
		cells = false,
		edges = true,
		position = UDim2.fromScale(DETAIL_X, DETAIL_TOP),
		size = UDim2.fromScale(1 - DETAIL_X - Theme.Margin, 1 - DETAIL_TOP - Theme.Margin),
		zIndex = Builder.blockTop(parent),
	})
	local top = Builder.blockTop(card)

	local prompt = Builder.label({
		parent = card,
		name = "Select",
		text = Strings.CODEX_SELECT,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.3),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Rarity.Common,
		zIndex = top,
	})

	local content = Builder.frame({
		parent = card,
		name = "Content",
		zIndex = top,
	})
	content.Visible = false

	-- The alien on a pedestal, turning slowly. Square, as wide as the card allows: a flat block in the tier's lighter colour
	-- and ink, the viewport clear on its face.
	local view = Builder.blockPlate({
		parent = content,
		name = "ViewBlock",
		color = Builder.lighter(Theme.Rarity.Common, 0.55),
		ink = Theme.Rarity.Common,
		aspect = 1,
		rows = FLAT_ROWS,
		cells = false,
		position = UDim2.fromScale(0.5, 0.03),
		size = UDim2.fromScale(0.9, 0.42),
		anchor = Vector2.new(0.5, 0),
		zIndex = top + 1,
	})
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "View"
	viewport.BorderSizePixel = 0
	viewport.BackgroundTransparency = 1
	viewport.Position, viewport.Size = Builder.blockInner(view)
	viewport.Ambient = Builder.darker(Theme.Colors.White, 0.45) -- soft grey fill light
	viewport.LightColor = Theme.Colors.White
	viewport.LightDirection = Vector3.new(-1, -2, -1)
	viewport.ZIndex = Builder.blockTop(view)
	viewport.Parent = view

	local camera = Instance.new("Camera")
	camera.FieldOfView = CAMERA_FOV
	camera.CFrame = CFrame.lookAt(Vector3.new(0, CAMERA_HEIGHT, CAMERA_DISTANCE), Vector3.new(0, CAMERA_TARGET_Y, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(PEDESTAL_THICKNESS, PEDESTAL_RADIUS * 2, PEDESTAL_RADIUS * 2)
	pedestal.CFrame = CFrame.new(0, PEDESTAL_TOP - PEDESTAL_THICKNESS / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	pedestal.Color = Builder.darker(Theme.Colors.Panel, 0.15)
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Anchored = true
	pedestal.CanCollide = false
	pedestal.Parent = viewport

	local part = Instance.new("Part")
	part.Name = "Alien"
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = viewport

	local mark = Builder.label({
		parent = viewport,
		name = "Mark",
		text = UNKNOWN_MARK,
		textSize = Theme.TextSize.Reveal,
		position = UDim2.fromScale(0.5, 0.45),
		size = UDim2.fromScale(0.6, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = viewport.ZIndex + 1,
	})

	local function line(name: string, top: number, height: number, textSize: number): TextLabel
		return Builder.label({
			parent = content,
			name = name,
			text = "",
			textSize = textSize,
			position = UDim2.fromScale(0.5, top),
			size = UDim2.fromScale(0.94, height),
			anchor = Vector2.new(0.5, 0),
			zIndex = top + 1,
		})
	end

	return {
		card = card,
		prompt = prompt,
		content = content,
		viewport = viewport,
		view = view,
		camera = camera,
		part = part,
		model = nil,
		mark = mark,
		name = line("Name", 0.46, 0.09, Theme.TextSize.Label),
		tier = line("Tier", 0.55, 0.06, Theme.TextSize.Body),
		jobs = line("Jobs", 0.62, 0.1, Theme.TextSize.Body),
		lineA = line("Where", 0.73, 0.1, Theme.TextSize.Body),
		lineB = line("Count", 0.84, 0.06, Theme.TextSize.Body),
		lineC = line("Best", 0.91, 0.06, Theme.TextSize.Body),
	}
end

-- Grid -------------------------------------------------------------------------

-- Column count from the grid's width so a ten-letter name still fits under a card at iPhone SE size;
-- cells are Scale, square through the layout's aspect constraint (width-dominant, so the canvas height
-- never feeds back into the cell size).
local function relayoutGrid()
	local scroller, layout = grid, gridLayout
	if not scroller or not layout then
		return
	end
	local width = scroller.AbsoluteWindowSize.X
	local cols = MAX_COLS
	if width > 0 then
		cols = math.clamp(math.floor(width / MIN_CELL_PX), MIN_COLS, MAX_COLS)
	end
	layout.CellSize = UDim2.fromScale(1 / cols, 1 / cols)
end

local function buildCell(parent: ScrollingFrame, index: number): Cell
	local slot = Builder.frame({
		parent = parent,
		name = "Cell" .. index,
		zIndex = 4,
	})
	slot.LayoutOrder = index

	-- A square edged block (the slot is square) whose ink is the tier's colour, set on every fill.
	local card = Builder.blockPlate({
		parent = slot,
		name = "Card",
		color = Theme.Colors.White,
		ink = Theme.Rarity.Common,
		aspect = 1,
		rows = CARD_ROWS,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(CARD_INSET, CARD_INSET),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})

	-- The placeholder colour square (or the silhouette), a flat block, with the shape name or the unknown mark inside.
	local square = Builder.blockPlate({
		parent = card,
		name = "Square",
		color = Theme.Shadow,
		aspect = 1,
		rows = FLAT_ROWS,
		cells = false,
		position = UDim2.fromScale(0.5, 0.07),
		size = UDim2.fromScale(0.7, 0.56),
		anchor = Vector2.new(0.5, 0),
		zIndex = CARD_TOP,
	})
	-- The picture area: a real model fills it (the colour block above is only the empty state), the mark stands over it.
	local picture = Builder.frame({
		parent = card,
		name = "Picture",
		position = UDim2.fromScale(0.5, PICTURE_Y),
		size = UDim2.fromScale(PICTURE_W, PICTURE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = CARD_TOP,
	})
	local mark = Builder.label({
		parent = picture,
		name = "Mark",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.62, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2, -- over the model view
	})
	local thumb = SpeciesThumb.New(picture, 1, PICTURE_W / PICTURE_H)
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.67),
		size = UDim2.fromScale(0.96, 0.26),
		anchor = Vector2.new(0.5, 0),
		zIndex = CARD_TOP,
	})

	-- Count badge over the square's bottom-right corner, shown from the second catch on: a fitted flat block.
	local badge = Builder.blockPlate({
		parent = card,
		name = "Count",
		color = Theme.Colors.Codex,
		rows = FLAT_ROWS,
		cells = false,
		position = UDim2.fromScale(0.97, 0.64),
		size = UDim2.fromScale(0.62, 0.16),
		anchor = Vector2.new(1, 1),
		zIndex = CARD_TOP + 2,
	})
	local badgeLabel = Builder.label({
		parent = badge,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(badge),
	})
	badge.Visible = false

	-- The weekly stamp over the square's top-left; text and colour are set on every fill, hidden when neither applies.
	local stamp = Builder.label({
		parent = card,
		name = "Stamp",
		text = "",
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(STAMP_X, STAMP_Y),
		size = UDim2.fromScale(STAMP_W, STAMP_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = STAMP_Z,
	})
	stamp.Visible = false

	-- An event alien's mark: a small purple flat block where the stamp would stand.
	local eventMark = Builder.blockPlate({
		parent = card,
		name = "EventMark",
		color = Theme.Colors.Codex,
		aspect = 1,
		rows = Theme.Block.MinRows,
		cells = false,
		position = UDim2.fromScale(STAMP_X, STAMP_Y),
		size = UDim2.fromScale(EVENT_MARK_W, EVENT_MARK_W),
		zIndex = STAMP_Z,
	})
	eventMark.Visible = false

	local cell: Cell = {
		slot = slot,
		card = card,
		square = square,
		picture = picture,
		mark = mark,
		name = name,
		badge = badge,
		badgeLabel = badgeLabel,
		stamp = stamp,
		eventMark = eventMark,
		thumb = thumb,
		speciesId = "",
		tier = "Common",
	}

	-- An invisible button over the card: a tap selects the species and fills the detail card.
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = TAP_Z
	tap.Parent = card
	tap.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		if cell.speciesId == "" or not State.Has() then
			return
		end
		selected = cell.speciesId
		Builder.pop(card, 1.08)
		applySelection(State.Get())
	end)
	return cell
end

local function ensureCells(count: number)
	local parent = grid
	if not parent then
		return
	end
	while #cells < count do
		table.insert(cells, buildCell(parent, #cells + 1))
	end
end

local function fillCell(cell: Cell, def: Types.SpeciesDef, count: number, now: number, offset: number, override: string?)
	cell.speciesId = def.id
	cell.tier = def.tier
	cell.slot.Visible = true
	local caught = count > 0
	if caught then
		-- The species' model, still, filling the picture area (SpeciesThumb); without a model, the colour square and its name. Never the placeholder
		-- shape's name (Studio 2026-10-22).
		Builder.setBlockColor(cell.card, Theme.Colors.White)
		Builder.setBlockColor(cell.square, Color3.fromHex(def.placeholder.color))
		local shown = SpeciesThumb.Show(cell.thumb, def, false)
		cell.square.Visible = not shown
		cell.mark.Text = if shown then "" else displayName(def, true)
		cell.name.TextColor3 = Theme.Colors.White
	else
		-- Dimmed card, the name in grey, the unknown mark; the square is a dark silhouette while the
		-- Silhouettes preference is on and the species colour otherwise. The model stands in it shadowed the same way (a
		-- Secret's always: its colours would give away what its hidden name keeps), the mark over it.
		local silhouette = Prefs.Silhouettes()
		Builder.setBlockColor(cell.card, Builder.lighter(Theme.Rarity.Common, 0.6))
		Builder.setBlockColor(cell.square, if silhouette then Theme.Shadow else Color3.fromHex(def.placeholder.color))
		cell.square.Visible = not SpeciesThumb.Show(cell.thumb, def, silhouette or def.tier == "Secret")
		cell.mark.Text = UNKNOWN_MARK
		cell.name.TextColor3 = Theme.Rarity.Common
	end
	cell.name.Text = displayName(def, caught)
	cell.badge.Visible = count > 1
	if count > 1 then
		cell.badgeLabel.Text = Strings.CODEX_COUNT_BADGE:format(count)
	end
	-- The stamp: the Alien of the Week now, Event for an event alien while its season runs (and for a weekly drop it
	-- brings back), else Vaulted for a limited species that is out of its window.
	local state = limitedState(def.id, now, offset, override)
	cell.eventMark.Visible = state == "event"
	if state == "week" then
		cell.stamp.Text = Strings.CODEX_THIS_WEEK
		cell.stamp.TextColor3 = Theme.Colors.Featured
		cell.stamp.Visible = true
	elseif state == "vaulted" then
		cell.stamp.Text = Strings.CODEX_VAULTED
		cell.stamp.TextColor3 = Theme.Rarity.Common
		cell.stamp.Visible = true
	else
		cell.stamp.Visible = false
	end
end

-- Refresh ----------------------------------------------------------------------

-- When each species the player owns was last caught: its newest alien's catch time, or its first catch (a released species still
-- counts in the codex). Read only while nothing is selected, to pick the card the detail opens on.
local function recentCatches(profile: Types.Profile): { [string]: number }
	local recent: { [string]: number } = {}
	for id, entry in pairs(profile.codex) do
		if entry.count > 0 then
			recent[id] = entry.firstCaughtAt
		end
	end
	for _, record in pairs(profile.aliens) do
		local known = recent[record.species]
		if known == nil or record.caughtAt > known then
			recent[record.species] = record.caughtAt
		end
	end
	return recent
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local worldId = profile.world.current
	local list = roster(worldId)
	ensureCells(#list)
	local now = State.Now()
	local offset = State.GetWeeklyOffset()
	local override = State.GetSeasonOverride()

	local caught = 0
	for index, cell in ipairs(cells) do
		local def = list[index]
		if not def then
			cell.slot.Visible = false
			continue
		end
		local count = caughtCount(profile, def.id)
		if count > 0 then
			caught += 1
		end
		fillCell(cell, def, count, now, offset, override)
	end

	-- A selection only survives while it belongs to the page on show.
	local id = selected
	if id then
		local def = Species.ById[id]
		if not def or def.world ~= worldId then
			selected = nil
		end
	end
	if selected == nil then
		-- Never an empty pane: the most recent catch of this page, else its first species.
		local ids: { string } = {}
		for _, def in ipairs(list) do
			table.insert(ids, def.id)
		end
		selected = PanelQuiet.CodexDefault(ids, recentCatches(profile))
	end

	local world = Worlds[worldId]
	local worldName = if world then world.name else tostring(worldId)
	if titleLabel then
		titleLabel.Text = Strings.CODEX_PAGE:format(worldName, caught, #list)
	end
	local p = if #list > 0 then caught / #list else 0
	if setBar then
		setBar(p)
	end
	if barPercent then
		barPercent.Text = Strings.UI_PERCENT:format(math.floor(p * 100))
	end
	applySelection(profile)
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("CodexScreen", 20)
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
		CodexScreen.Close()
	end)

	local body = Builder.blockPlate({
		parent = root,
		name = "Panel",
		color = Theme.Colors.Panel,
		aspect = 1.35,
		rows = Builder.blockPanelRows(0.78), -- a cream block plate at the panel cell (UI Playbook "Screens after the HUD")
		quiet = true, -- one cream surface behind the text (Clean UI pass)
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, purple for the codex, title in white outlined text.
	Builder.blockHeader(body, 1.35, Strings.CODEX_TITLE, Theme.Colors.Codex, Vector2.new(0.42, 0.11))

	Builder.blockClose(body, 0.78, function()
		CodexScreen.Close()
	end)

	-- Page: title line, progress bar, then the grid.
	local page = Builder.frame({
		parent = body,
		name = "Page",
		position = UDim2.fromScale(Theme.Margin, 0.085),
		size = UDim2.fromScale(PAGE_WIDTH, 1 - 0.085 - Theme.Margin),
		zIndex = Builder.blockTop(body),
	})
	titleLabel = Builder.label({
		parent = page,
		name = "Title",
		text = "",
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 0.085),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 3,
	})

	-- The progress bar: a fitted flat dark block, filled cell-true in Codex purple (Builder.blockBar).
	local bar = Builder.blockPlate({
		parent = page,
		name = "Bar",
		color = Theme.Block.Trough,
		rows = FLAT_ROWS,
		cells = false,
		position = UDim2.fromScale(0, 0.1),
		size = UDim2.fromScale(1, 0.06),
		zIndex = 3,
	})
	setBar = Builder.blockBar(bar, Theme.Colors.Codex)
	barPercent = Builder.label({
		parent = bar,
		name = "Percent",
		text = Strings.UI_PERCENT:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(bar),
	})

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(0, 0.18)
	scroller.Size = UDim2.fromScale(1, 0.82)
	scroller.CanvasSize = UDim2.fromScale(1, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.Always -- a constant window width, so the column count never flaps
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Outline
	scroller.ZIndex = 3
	scroller.Parent = page
	grid = scroller

	local layout = Instance.new("UIGridLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.CellPadding = UDim2.fromScale(0, 0) -- the gap is the inset of each card inside its slot
	layout.CellSize = UDim2.fromScale(1 / MAX_COLS, 1 / MAX_COLS)
	layout.Parent = scroller
	gridLayout = layout
	local squareCells = Instance.new("UIAspectRatioConstraint")
	squareCells.AspectRatio = 1
	squareCells.AspectType = Enum.AspectType.ScaleWithParentSize
	squareCells.DominantAxis = Enum.DominantAxis.Width
	squareCells.Parent = layout
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayoutGrid)

	detail = buildDetail(body)

	-- A catch changes the codex counts; the server pushes aliens with stations (cheap while closed).
	State.OnChanged("stations", refresh)
	State.OnChanged("codex", refresh)
	State.OnChanged("weekly", refresh) -- the week flips or the Studio shift changes: stamps and detail lines follow
	State.OnChanged("season", refresh) -- a season starts or ends: the Event and Vaulted stamps and the detail hint follow
	Prefs.OnChanged(refresh) -- the Silhouettes preference changes how uncaught species draw
end

-- Public API -------------------------------------------------------------

function CodexScreen.IsOpen(): boolean
	return open
end

function CodexScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	relayoutGrid()
	refresh()
	root.Enabled = true
	Builder.open(body)
	if render then
		render:Disconnect()
	end
	render = RunService.RenderStepped:Connect(function(dt: number)
		angle = (angle + dt * ROTATE_SPEED) % (math.pi * 2)
		local d = detail
		if d and d.content.Visible then
			placePart(d)
		end
	end)
end

function CodexScreen.Close()
	if not open then
		return
	end
	open = false
	if render then
		render:Disconnect()
		render = nil
	end
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

function CodexScreen.Toggle()
	if open then
		CodexScreen.Close()
	else
		CodexScreen.Open()
	end
end

return CodexScreen
