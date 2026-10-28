--!strict
-- StarterPlayerScripts.Client.UI.CodexScreen: the codex panel. Under the header band (Builder.panelHeader, purple: "Found 12 / 35" and
-- this page's world, "Verdant 3 / 19") the page for the player's current world is a scrolling grid of one square tile per species, cut
-- into one section per tier present on the page (Builder.sectionStrip, "Rare" 3 / 4; FeaturedMath.Sections), Common first and then by
-- name. Caught species show their model, still, on their colour (UI.SpeciesThumb; the name without a model) in the tier's ink with its
-- studs (Builder.tierFrame); uncaught ones are dark silhouettes with the unknown mark in grey ink, named unless Secret so players know
-- what to chase. A tap selects a tile (the gold ink) and fills the featured card (UI.FeaturedCard): the species' model turning slowly
-- (still under Reduced Motion) on its plinth, the tier tag, the name and one flavour line, a few fact lines (jobs, copies caught and
-- the best overlay, the event), and for a caught species the green button "See in Aliens" (AliensScreen.Select, then Screens.Open);
-- for an uncaught one the hint line (where and when it appears, or the weekly, vaulted and event line) takes the flavour's room and
-- there is no button. At a panel of 620 by 330 px or more the card stands left of the grid (side mode); under that (iPhone SE) it is
-- a strip across the top over the grid (strip mode); Shared/FeaturedMath picks the mode. The tiles are placed in Scale values of the
-- scroller's canvas from px worked out by FeaturedMath.GridPlan (the Playbook's "Grids inside scrolling frames": no layout objects).
-- Everything shown is read from the profile mirror in State and the shared data tables; nothing here decides an outcome.
-- The look is block cells (UI Playbook "Screens after the HUD", Decisions B44): the panel a cream plate at the panel cell under the
-- band; a grid tile a square edged block whose ink is its tier's colour (grey while uncaught, gold while selected), its square a flat
-- block, its count badge a flat block.
-- The clean pass (docs/vault/05-ui-design/Clean-UI-Pass.md, package C): the card is never an empty pane, it opens on the most
-- recently caught species (or the first entry; Shared/PanelQuiet.CodexDefault), and an event species wears a small purple block in
-- its corner instead of the word "Event" (the card names the event). "This week" and "Vaulted" stay words: they ask for action.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Panels = require(Shared:WaitForChild("data"):WaitForChild("Panels"))
local PanelHeaderMath = require(Shared:WaitForChild("PanelHeaderMath"))
local PanelQuiet = require(Shared:WaitForChild("PanelQuiet"))
local FeaturedMath = require(Shared:WaitForChild("FeaturedMath"))
local WeeklyMath = require(Shared:WaitForChild("WeeklyMath"))
local SeasonMath = require(Shared:WaitForChild("SeasonMath"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local FeaturedCard = require(script.Parent.FeaturedCard)
local AliensScreen = require(script.Parent.AliensScreen)
local Screens = require(script.Parent.Screens)
local State = require(script.Parent.Parent.State)
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
	caught: boolean,
}

-- The mark on a silhouette. CODEX_UNKNOWN ("???") until a single-glyph key exists in the strings table.
local UNKNOWN_MARK = Strings.UI_UNKNOWN_GLYPH

local PANEL_H = Panels.Shell.Height -- the shell's height, of the screen
local PANEL_ASPECT = PanelHeaderMath.ShellAspect(1.35, 0.78, PANEL_H) -- the old plate's width in px, at the shell's height
local CARD_INSET = 0.92 -- the card inside its grid slot; the rest is the gap between cards
local SCROLLBAR_PX = 4 -- thin dark scrollbar on the right (a thickness, like a stroke)
local SELECTED_INK = Theme.Colors.Featured -- a selection is an ink colour (the Playbook)
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

local ROTATE_SPEED = math.rad(40) -- radians per second while the screen is open (the featured card's model; none under Reduced Motion)

local gui: ScreenGui? = nil
local panel: Frame? = nil
local header: Builder.PanelHeader? = nil -- the band (Builder.panelHeader): refresh feeds its two pills
local featured: FeaturedCard.Card? = nil -- the featured card, built once and refilled on every selection
local layoutMode: FeaturedMath.Mode? = nil -- the shape the body is laid out in now (side or strip)
local grid: ScrollingFrame? = nil
local cells: { Cell } = {}
local strips: { Frame } = {} -- the section strips drawn now (rebuilt with the counts)
local sections: { FeaturedMath.Section } = {} -- the page's tier sections, in the cells' order
local laidW, laidH, laidParentH = 0, 0, 0 -- the scroller's window and its parent's px the tiles were last placed for
local selected: string? = nil
local open = false
local render: RBXScriptConnection? = nil
local angle = 0
local rosterCache: { [number]: { Types.SpeciesDef } } = {}
local codexEntries: { FeaturedMath.CodexEntry } = {} -- every species with its world, for the pills
local builtWorlds: { [number]: boolean } = {}
for _, def in ipairs(Species.List) do
	table.insert(codexEntries, { id = def.id, world = def.world })
end
for id, world in pairs(Worlds) do
	builtWorlds[id] = world.built
end

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

-- Featured card -----------------------------------------------------------------------------------------

-- The card's facts for a caught species: the event it belongs to while its season runs, the jobs, the copies caught with the best
-- overlay, and the overlay's line when it has one; at most three (the card has room for three), the earlier ones first.
local function caughtFacts(def: Types.SpeciesDef, count: number, best: string, tierWord: string): { string }
	local facts: { string } = {}
	local now, override = State.Now(), State.GetSeasonOverride()
	local eventSeason = SeasonMath.Current(now, override)
	if eventSeason and limitedState(def.id, now, State.GetWeeklyOffset(), override) == "event" then
		table.insert(facts, Strings.CODEX_TIER_EVENT:format(tierWord, Builder.text("SEASON_" .. eventSeason.season.id)))
	end
	table.insert(facts, jobsText(def))
	if best == "None" then
		table.insert(facts, Strings.CODEX_CAUGHT:format(count))
	else
		table.insert(facts, Strings.FEATURED_CAUGHT_BEST:format(count, Builder.text("OVERLAY_" .. best)))
		-- an overlay with a `desc` row says what it is ("Caught during launch week.")
		local overlayRow = Overlays.Overlays[best]
		if overlayRow and overlayRow.desc then
			table.insert(facts, Builder.text(overlayRow.desc))
		end
	end
	while #facts > 3 do
		table.remove(facts)
	end
	return facts
end

-- The hint an uncaught species wears in place of its flavour line: an uncaught Alien of the Week says how long it stays; an uncaught
-- event alien says its event is on and how long (or, for a returning weekly drop, which event brought it back); an uncaught limited one
-- out of its window says it is vaulted; an event-track reward says so; any other says where and when it appears.
local function hintLine(def: Types.SpeciesDef): string
	local now = State.Now()
	local override = State.GetSeasonOverride()
	local state = limitedState(def.id, now, State.GetWeeklyOffset(), override)
	local weekly = WeeklyMath.Current(now, State.GetWeeklyOffset())
	local season = SeasonMath.Current(now, override)
	if state == "week" and weekly then
		return Strings.CODEX_WEEKLY_HINT:format(daysHoursText(weekly.secondsLeft))
	elseif state == "event" and season then
		local timeLeft = daysHoursText(season.secondsLeft)
		if SeasonMath.IsLimited(def.id) then
			return Strings.CODEX_EVENT_HINT:format(timeLeft)
		end
		return Strings.CODEX_RETURNING_HINT:format(Builder.text("SEASON_" .. season.season.id), timeLeft)
	elseif state == "vaulted" then
		return Strings.CODEX_VAULTED_HINT
	elseif SeasonMath.IsTrackReward(def.id) then
		return Strings.CODEX_TRACK_HINT -- it never spawns: "by quest" would send players looking
	end
	return Strings.CODEX_HINT:format(Builder.text("BIOME_" .. def.biome), Builder.text("COND_PHRASE_" .. def.condition))
end

-- Fills the featured card from the selected species (a caught one: model, tier, name, flavour, facts and "See in Aliens"; an uncaught
-- one: its silhouette, the hint and what the first catch pays, no button), or with the prompt when the page has no species.
local function fillFeatured(profile: Types.Profile)
	local card = featured
	if not card then
		return
	end
	local id = selected
	local def: Types.SpeciesDef? = if id then Species.ById[id] else nil
	if not def then
		FeaturedCard.Fill(card, nil, Strings.CODEX_SELECT)
		return
	end
	local entry = profile.codex[def.id]
	local count = if entry then entry.count else 0
	local caught = count > 0
	local tierId: string = def.tier
	local tierWord = Builder.text("TIER_" .. tierId)
	local speciesId = def.id
	local function has(key: string): boolean
		return Builder.text(key) ~= key
	end
	local content: FeaturedCard.Content = {
		def = def,
		shadowed = false,
		mark = false,
		name = displayName(def, caught),
		tier = tierId,
		tierWord = tierWord,
		flavour = "",
		facts = {},
		main = nil,
		side = nil,
	}
	if caught then
		content.flavour = Builder.text(FeaturedMath.FlavourKey(def.id, tierId, has))
		content.facts = caughtFacts(def, count, if entry then entry.bestOverlay else "None", tierWord)
		local buttons = FeaturedMath.Button({ screen = "Codex", caught = true })
		local main = buttons.main
		if main then
			content.main = {
				word = Builder.text(main.word),
				role = main.role,
				onTap = function()
					AliensScreen.Select(speciesId) -- the first alien of this species, selected there
					Screens.Open("Aliens")
				end,
			}
		end
	else
		-- Uncaught species stand as silhouettes only while the Silhouettes preference is on (a Secret's always: its colours would give
		-- away what its hidden name keeps), the unknown mark over them.
		content.shadowed = Prefs.Silhouettes() or tierId == "Secret"
		content.mark = true
		content.flavour = hintLine(def)
		content.facts = { jobsText(def), Strings.CODEX_FIRST_CATCH:format(Builder.formatNumber(Tiers.Tiers[tierId].codexScrap)) }
	end
	FeaturedCard.Fill(card, content, nil)
end

-- Gold ink on the selected tile, the tier's on the other caught ones, grey on the uncaught; then the card follows.
local function applySelection(profile: Types.Profile)
	for _, cell in ipairs(cells) do
		if not cell.slot.Visible then
			continue
		end
		local ink = if cell.speciesId == selected
			then SELECTED_INK
			elseif cell.caught then Builder.tierColor(cell.tier)
			else Theme.Rarity.Common
		Builder.setBlockInk(cell.card, ink)
	end
	fillFeatured(profile)
end

-- Grid -------------------------------------------------------------------------

-- Places the section strips and the tiles in Scale values of the scroller's canvas. The px come from FeaturedMath.GridPlan (square tiles
-- of at least Codex.MinCellPx in as many columns as fit, a strip over each section when the page has two or more); a canvas child scales
-- against the canvas, and the canvas is `canvas px / the scroller's parent's px` of the panel (CanvasSize scales against the parent,
-- UI-Rules), so every Scale below is px over the canvas's px. Sizes are read with the open tween's UIScale taken out. Runs again when
-- the window, the mode or the sections change.
local function layoutGrid(force: boolean)
	local scroller, body = grid, panel
	if not scroller or not body then
		return
	end
	local bodyAbs = body.AbsoluteSize
	local window = scroller.AbsoluteWindowSize
	if bodyAbs.X <= 0 or bodyAbs.Y <= 0 or window.X <= 0 or window.Y <= 0 then
		return -- not laid out yet: the scroller's AbsoluteSize signal runs this again
	end
	local factor = FeaturedCard.UnscaledSize(body).X / bodyAbs.X
	local windowW, windowH, parentH = window.X * factor, window.Y * factor, bodyAbs.Y * factor
	if not force and math.abs(windowW - laidW) < 0.5 and math.abs(windowH - laidH) < 0.5 and math.abs(parentH - laidParentH) < 0.5 then
		return
	end
	laidW, laidH, laidParentH = windowW, windowH, parentH
	local c = Panels.Featured.Codex
	local counts: { number } = {}
	for _, section in ipairs(sections) do
		table.insert(counts, section.total)
	end
	local stripPx = math.max(c.StripPx, c.StripShare * windowH)
	local plan = FeaturedMath.GridPlan(windowW, FeaturedMath.CodexColumns(windowW), c.GapPx, stripPx, #sections >= 2, counts)
	local canvasH = math.max(plan.height, windowH)
	scroller.CanvasSize = UDim2.fromScale(0, canvasH / parentH)
	for index, section in ipairs(sections) do
		local planned = plan.sections[index]
		local strip = strips[index]
		if strip then
			strip.Position = UDim2.fromScale(0, planned.stripY / canvasH)
			strip.Size = UDim2.fromScale(1, stripPx / canvasH)
		end
		for offset, item in ipairs(planned.items) do
			local cell = cells[section.from + offset - 1]
			if cell then
				cell.slot.Position = UDim2.fromScale(item.x / windowW, item.y / canvasH)
				cell.slot.Size = UDim2.fromScale(plan.cell / windowW, plan.cell / canvasH)
			end
		end
	end
end

local function buildCell(parent: ScrollingFrame, index: number): Cell
	local slot = Builder.frame({
		parent = parent,
		name = "Cell" .. index,
		zIndex = 4,
	})

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
		caught = false,
	}

	-- An invisible button over the card: a tap selects the species and fills the featured card.
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
	cell.caught = caught
	if caught then
		-- The species' model, still, filling the picture area (SpeciesThumb); without a model, the colour square and its name. Never the placeholder
		-- shape's name (Studio 2026-10-22).
		Builder.setBlockColor(cell.card, Theme.Colors.White)
		cell.card:SetAttribute("TierBase", nil) -- tierFrame takes the face as it is now for its tint (a recycled tile has a new face)
		Builder.tierFrame(cell.card, def.tier) -- the studs and tint of its tier: a Rare one stud up to four from Legendary
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
		cell.card:SetAttribute("TierBase", nil)
		Builder.tierFrame(cell.card, "Common") -- an uncaught tile wears no studs and no tint: it keeps its tier a secret in grey ink
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
-- counts in the codex). Read only while nothing is selected, to pick the species the featured card opens on.
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

-- The band's pills: "Found 12 / 35" over the species of the built worlds, and this page's world, "Verdant 3 / 19" (short name: its first
-- word), gone on a page with no species. Both read the same caught set the sections do.
local function updatePills(worldId: number, caught: { [string]: boolean })
	local band = header
	if not band then
		return
	end
	local found, total, pageFound, pageTotal = FeaturedMath.CodexCounts(codexEntries, caught, builtWorlds, worldId)
	local overall: { any } = { found, total }
	if pageTotal == 0 then
		band.setPills({ overall })
		return
	end
	local world = Worlds[worldId]
	local name = if world then world.name else tostring(worldId)
	local page: { any } = { name:match("^%S+") or name, pageFound, pageTotal }
	band.setPills({ overall, page })
end

-- One strip over each tier section ("RARE" and "3 / 4"), only where the page has two or more; the strips are rebuilt with the counts and
-- placed by layoutGrid.
local function rebuildStrips()
	local scroller = grid
	if not scroller then
		return
	end
	for _, strip in ipairs(strips) do
		strip:Destroy()
	end
	table.clear(strips)
	if #sections < 2 then
		return
	end
	for index, section in ipairs(sections) do
		strips[index] = Builder.sectionStrip(scroller, "TIER_" .. section.tier, Strings.FEATURED_COUNT:format(section.found, section.total))
	end
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

	local tiers: { string } = {}
	local flags: { boolean } = {}
	for index, cell in ipairs(cells) do
		local def = list[index]
		if not def then
			cell.slot.Visible = false
			continue
		end
		local count = caughtCount(profile, def.id)
		tiers[index] = def.tier
		flags[index] = count > 0
		fillCell(cell, def, count, now, offset, override)
	end
	local caughtSet: { [string]: boolean } = {}
	for id, entry in pairs(profile.codex) do
		if entry.count > 0 then
			caughtSet[id] = true
		end
	end
	sections = FeaturedMath.Sections(tiers, flags)
	rebuildStrips()
	layoutGrid(true)

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
	updatePills(worldId, caughtSet)
	applySelection(profile)
end

-- The panel's px with the open tween taken out, or the usual window's before it is laid out (a disabled gui measures zero).
local function panelPx(): (number, number)
	local body = panel
	local size = if body then FeaturedCard.UnscaledSize(body) else Vector2.zero
	if size.X > 0 and size.Y > 0 then
		return size.X, size.Y
	end
	local camera = workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else Vector2.new(1154, 663)
	local w = math.min(PANEL_H * screen.Y * PANEL_ASPECT, 0.8 * screen.X)
	return w, w / PANEL_ASPECT
end

-- Lays the body out for the panel's shape (FeaturedMath.Mode): at 620 by 330 px or more the card stands left of the grid, under that it
-- is a strip over the grid. Runs again when the mode changes.
local function applyLayout(force: boolean)
	local card, scroller = featured, grid
	if not card or not scroller then
		return
	end
	local w, h = panelPx()
	local mode: FeaturedMath.Mode = FeaturedMath.Mode(w, h)
	if not force and mode == layoutMode then
		return
	end
	layoutMode = mode
	local f = Panels.Featured
	local c = f.Codex
	if mode == "side" then
		FeaturedCard.Place(card, mode, UDim2.fromScale(f.Side.CardX, c.SideTop), UDim2.fromScale(f.Side.CardW, c.Bottom - c.SideTop))
		scroller.Position = UDim2.fromScale(f.Side.GridX, c.SideTop)
		scroller.Size = UDim2.fromScale(f.Side.GridW, c.Bottom - c.SideTop)
	else
		FeaturedCard.Place(card, mode, UDim2.fromScale(f.Wide.X, c.StripTop), UDim2.fromScale(f.Wide.W, c.StripH))
		scroller.Position = UDim2.fromScale(f.Wide.X, c.StripGridTop)
		scroller.Size = UDim2.fromScale(f.Wide.W, c.Bottom - c.StripGridTop)
	end
	layoutGrid(true)
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
		aspect = PANEL_ASPECT,
		rows = Builder.blockPanelRows(PANEL_H), -- a cream block plate at the panel cell (UI Playbook "Screens after the HUD")
		quiet = true, -- one cream surface behind the text (Clean UI pass)
		position = UDim2.fromScale(0.5, Panels.Shell.Top), -- below the Scrap pill, which ends at Top; the band is inside the panel
		size = UDim2.fromScale(0.8, PANEL_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 2,
	})
	panel = body
	local top = Builder.blockTop(body)

	-- The header band: purple, the Codex icon, "Found n / 35" and this page's world (refresh), the red X.
	header = Builder.panelHeader(body, { panelId = "Codex", panelAspect = PANEL_ASPECT, panelHeight = PANEL_H }, function()
		CodexScreen.Close()
	end)

	-- The grid: a window over the sections with a thin dark bar. There are no layout objects: layoutGrid puts every strip and tile
	-- at Scale values of the canvas from px (FeaturedMath.GridPlan), and applyLayout gives it its place for the panel's shape.
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Grid"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Panels.Featured.Side.GridX, Panels.Featured.Codex.SideTop)
	scroller.Size = UDim2.fromScale(Panels.Featured.Side.GridW, Panels.Featured.Codex.Bottom - Panels.Featured.Codex.SideTop)
	scroller.CanvasSize = UDim2.fromScale(0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.Always -- a constant window width, so the column count never flaps
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Outline
	scroller.ZIndex = top
	scroller.Parent = body
	grid = scroller
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		layoutGrid(false)
	end)

	-- The featured card (UI.FeaturedCard), built once and refilled on every selection; its model turns while the screen is open.
	featured = FeaturedCard.Build(body, "Featured", top, true)
	applyLayout(true)
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyLayout(false) -- the mode follows the panel's real size once it is laid out, and when the window changes
	end)

	-- A catch changes the codex counts; the server pushes aliens with stations (cheap while closed).
	State.OnChanged("stations", refresh)
	State.OnChanged("codex", refresh)
	State.OnChanged("weekly", refresh) -- the week flips or the Studio shift changes: stamps and hints follow
	State.OnChanged("season", refresh) -- a season starts or ends: the Event and Vaulted stamps and the hint follow
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
	root.Enabled = true
	applyLayout(true)
	refresh()
	Builder.open(body)
	if render then
		render:Disconnect()
	end
	-- The featured card's model turns slowly while the screen is open; under Reduced Motion it stands still.
	render = RunService.RenderStepped:Connect(function(dt: number)
		local card = featured
		if not card then
			return
		end
		if Prefs.ReducedMotion() then
			if angle ~= 0 then
				angle = 0
				FeaturedCard.Spin(card, 0)
			end
			return
		end
		angle = (angle + dt * ROTATE_SPEED) % (math.pi * 2)
		FeaturedCard.Spin(card, angle)
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
