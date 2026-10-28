--!strict
-- StarterPlayerScripts.Client.UI.RadarColumn: the radar (data/Radar, data/RadarScroll, Decisions B52 and B57, UI Playbook "Radar
-- column"). Ethan, 2026-10-22: "having a map of where the aliens are and what rarities defeats the whole struggle aspect of the
-- game ... a radar which is depicted on the screen by a column of the silhouettes of each alien listed from closest to furthest from
-- you." Ethan, 2026-10-26: "The radar ui looks very sloppy. It should be one long rectangle ... that shows the silhouette and
-- shadow of the aliens on a white or something similar background. Almost like if you opened up a scroll vertically. Not everything
-- has to be that gaming design." So the radar is ONE TALL SCROLL on the right edge: a cream sheet (Theme.Colors.Paper) with a thin
-- dark edge, a slightly darker rolled end at the top and at the bottom, a soft drop shadow, and nothing else: no block cells, no
-- chip, no title, no slot frames. Each alien standing in reach is a picture on the paper, the NEAREST at the top and the furthest at
-- the bottom, with a soft ground shadow under its feet: an all-black silhouette while the player has no catch of that species in the
-- codex (SpeciesThumb), the real model once there is one. An unused slot is blank paper. No name, no rarity, no distance, no tap.
--
-- Motion: the scroll unrolls from the top when it first appears (data/RadarScroll UnrollSeconds) and rolls up when it hides; a
-- slot's picture fades out and in (FadeSeconds) when the order changes, never pops. Reduced Motion (Prefs) makes both instant.
--
-- What is listed: the wild parts under Workspace.World.Wild (the client already sees them; the server owns the spawns) within the
-- tier's range of the player, flat (data/Radar), nearest first, at most the tier's slot count (Mk1 5, Mk2 7, Mk3 9). Skipped: an
-- alien reserved for another player, one the Blizzard rule hides (WildRenderer.IsHidden), and every Secret-tier alien (never
-- listed, not even as a shadow). Tier 0 (no radar owned) shows nothing. While a Scanner Pulse runs (WildRenderer.ScannerPulseActive,
-- data/PowerUps) the scroll also works without a radar and lists the nearest `Pulse.slots` aliens of the player's current biome
-- whatever their range: still shadows and order only, no positions. The sheet is as tall as its slot count needs.
--
-- Cost: the Wild folder's parts are kept in a list by ChildAdded/ChildRemoved (no GetChildren per refresh), the nearest-first sort
-- is RadarMath.Offer over two reused arrays (no table per refresh), and the slots are a pool built once for the most any tier or
-- the pulse can show; a refresh every Config.RadarRefreshSeconds only sets what each slot WANTS, and a Heartbeat that runs only
-- while something moves (the unroll, a fade) swaps a picture (a clone of the model is made then) once it has faded out. The pure
-- choices (range, slot count, order, shadow or face, heights, fades) are Shared/RadarMath, tests/RadarMath.spec.luau.
-- Client-only presentation of wild parts the client already sees: the server owns which tier is held (profile.gear.radar, fed in
-- with SetTier) and decides every outcome; nothing here can be tapped, so it can neither mark nor catch anything.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local RadarTiers = require(Shared:WaitForChild("data"):WaitForChild("Radar"))
local Look = require(Shared:WaitForChild("data"):WaitForChild("RadarScroll"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local RadarMath = require(Shared:WaitForChild("RadarMath"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local HudStages = require(Shared:WaitForChild("HudStages"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local State = require(script.Parent.Parent.State)
local Prefs = require(script.Parent.Parent.Prefs)
local WildRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("WildRenderer"))

local RadarColumn = {}

type TierRow = { name: string, range: number, slots: number, scrap: number, unlock: string? }
type PulseRow = { slots: number }

-- Literal number keys, some rows without `unlock`, and a Pulse block under a string key: cast through any the way the Shop does.
local tiers: { [number]: TierRow } = (RadarTiers :: any) :: { [number]: TierRow }
local pulseSlots: number = ((RadarTiers :: any).Pulse :: PulseRow).slots

-- The highest tier the data knows (SetTier clamps to it, so a save from a later build never asks for a row that is not there) and
-- the most slots any tier or the pulse can show (the pool's size).
local maxTier = 0
local maxSlots = pulseSlots
for key, row in pairs(tiers) do
	if type(key) == "number" then
		maxTier = math.max(maxTier, key)
		maxSlots = math.max(maxSlots, row.slots)
	end
end

local DISPLAY_ORDER = 10 -- the HUD's layer, where the minimap and the Nearby column were

-- Layout, all Scale and all in screen fractions (data/RadarScroll): every piece is a child of one full-screen holder, so a Scale
-- there is a fraction of the screen. The holder takes no input.
local PAPER_CENTRE = Look.X - Look.Width / 2 -- the sheet's centre, of the screen width
local ROLLER_WIDTH = Look.Width * Look.RollerOverhang
local ART_OF_SLOT = Look.ArtHeight / Look.SlotPitch -- the picture's box, of its slot's height
local ZPAPER, ZSLOT, ZROLL = 2, 3, 6 -- ZIndex: the sheet, a slot, the rolled ends (over the pictures that slide under them)

local localPlayer = Players.LocalPlayer

type Slot = {
	frame: Frame, -- the slot's strip of paper (transparent): holds the ground shadow and the picture
	ground: Frame, -- the soft ellipse under the feet
	fallback: Frame, -- the plain blob shown while a model is missing (hidden otherwise)
	mark: TextLabel, -- the "?" of a shadow whose model is missing
	thumb: SpeciesThumb.Thumb,
	top: number, -- where the slot begins, of the screen height
	showing: string?, -- the species the picture holds now (nil: nothing)
	showingShadowed: boolean,
	modeled: boolean, -- whether a model showed; a slot without one tries again each refresh (the models load at run time)
	wanted: string?, -- the species the order puts here
	wantedShadowed: boolean,
	alpha: number, -- the picture's own opacity, 0 to 1 (before the unrolling's reveal)
}

local gui: ScreenGui? = nil
local paper: Frame? = nil
local dropInner: Frame? = nil
local dropOuter: Frame? = nil
local topRoller: Frame? = nil
local bottomRoller: Frame? = nil
local slots: { Slot } = {}
local wildParts: { Part } = {} -- the parts under the Wild folder, in arrival order, kept by ChildAdded/ChildRemoved
local watchedWild: Instance? = nil
local wildConns: { RBXScriptConnection } = {}
local connections: { RBXScriptConnection } = {}
local heartbeat: RBXScriptConnection? = nil
local animator: RBXScriptConnection? = nil
local accumulator = 0
local nearDistance: { number } = {} -- the nearest-first list RadarMath.Offer keeps, reused every refresh
local nearPart: { Part } = {}
local tier = 0 -- the radar tier the server says the player holds (SetTier); 0 shows nothing
local visible = true -- the bootstrap's SetVisible: captures, reveals and open panels hide the HUD extras
local stageShown = false -- the staged reveal (SetStage): hidden until the tutorial has earned the column, whatever radar the account owns
local shown = false
local limitNow = 0 -- how many slots the sheet has room for now (the tier's or the pulse's)
local lastLimit = 1 -- the last non-zero count, which sets how fast the sheet rolls up
local heightNow = 0 -- the sheet's open height, of the screen height: 0 rolled up, ScrollHeight(limit) fully open

-- Helpers ------------------------------------------------------------------

local function tierRow(): TierRow
	return tiers[tier] or tiers[0]
end

local function heightFor(count: number): number
	return RadarMath.ScrollHeight(count, Look.RollerHeight, Look.Pad, Look.SlotPitch)
end

local function rootPosition(): Vector3?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Workspace.World.Wild without yielding: until it exists there is simply nothing to list.
local function wildFolder(): Instance?
	local world = Workspace:FindFirstChild("World")
	return if world then world:FindFirstChild("Wild") else nil
end

-- Follows the Wild folder's parts instead of listing it on every refresh: the folder is picked up (or replaced) the first refresh
-- after it exists, its parts are listed once, and every later arrival and removal is one event.
local function unwatchWild()
	for _, connection in ipairs(wildConns) do
		connection:Disconnect()
	end
	table.clear(wildConns)
	table.clear(wildParts)
	watchedWild = nil
end

local function addWildPart(child: Instance)
	if child:IsA("Part") then
		table.insert(wildParts, child)
	end
end

local function removeWildPart(child: Instance)
	local index = table.find(wildParts, child :: any)
	if index then
		table.remove(wildParts, index)
	end
end

local function syncWild(wild: Instance?)
	if wild == watchedWild then
		return
	end
	unwatchWild()
	watchedWild = wild
	if not wild then
		return
	end
	for _, child in ipairs(wild:GetChildren()) do
		addWildPart(child)
	end
	table.insert(wildConns, wild.ChildAdded:Connect(addWildPart))
	table.insert(wildConns, wild.ChildRemoved:Connect(removeWildPart))
end

-- The codex count of a species: the profile's catches of it, nil with no entry (or no profile yet).
local function catches(speciesId: string): number?
	if not State.Has() then
		return nil
	end
	local entry = State.Get().codex[speciesId]
	return if entry then entry.count else nil
end

-- Drawing --------------------------------------------------------------------

-- Puts the sheet, its drop shadow and its rolled ends at the open height `heightNow`. The top roller stays on the top edge and the
-- bottom roller rides the sheet's lower edge, so the scroll seems to unroll downward.
local function layout()
	local sheet, inner, outer, upper, lower = paper, dropInner, dropOuter, topRoller, bottomRoller
	if not (sheet and inner and outer and upper and lower) then
		return
	end
	local open = heightNow > 0
	sheet.Visible, inner.Visible, outer.Visible, upper.Visible, lower.Visible = open, open, open, open, open
	if not open then
		return
	end
	sheet.Size = UDim2.fromScale(Look.Width, heightNow)
	inner.Position = UDim2.fromScale(Look.X + Look.DropOffsetX, Look.Top + Look.DropOffsetY)
	inner.Size = UDim2.fromScale(Look.Width, heightNow)
	outer.Position = UDim2.fromScale(Look.X + Look.DropOffsetX + Look.DropGrow, Look.Top + Look.DropOffsetY + Look.DropGrow)
	outer.Size = UDim2.fromScale(Look.Width + 2 * Look.DropGrow, heightNow + 2 * Look.DropGrow)
	local roller = math.min(Look.RollerHeight, heightNow / 2)
	upper.Size = UDim2.fromScale(ROLLER_WIDTH, roller)
	lower.Size = UDim2.fromScale(ROLLER_WIDTH, roller)
	lower.Position = UDim2.fromScale(PAPER_CENTRE, Look.Top + heightNow)
end

-- The slot's picture, ground shadow and fallback at its opacity, held back by how much of the slot the sheet has uncovered.
local function paintSlot(slot: Slot)
	local reveal = RadarMath.Reveal(slot.top, Look.SlotPitch, Look.Top + heightNow, Look.RollerHeight, Look.Pad)
	local alpha = math.min(slot.alpha, reveal)
	local clear = 1 - alpha
	slot.thumb.view.ImageTransparency = clear
	slot.ground.BackgroundTransparency = 1 - alpha * (1 - Look.GroundTransparency)
	if not slot.modeled then
		slot.fallback.BackgroundTransparency = clear
		slot.mark.TextTransparency = clear
	end
	slot.frame.Visible = alpha > 0
end

-- Shows `speciesId` in a slot's picture as a shadow or as the real model, or empties it (nil). Only called while the slot is
-- invisible (its opacity is 0), so the swap never shows. A species whose model is not there (none imported in this place, or not
-- loaded yet) shows a plain blob: the shadow colour with a "?" for an uncaught species, the placeholder colour for a caught one; the
-- next refresh tries the model again.
local function fillSlot(slot: Slot, speciesId: string?, shadowed: boolean)
	slot.showing, slot.showingShadowed = speciesId, shadowed
	local def = if speciesId then Species.ById[speciesId] else nil
	if not def then
		slot.modeled = true
		SpeciesThumb.Show(slot.thumb, nil, false)
		slot.fallback.Visible = false
		slot.mark.Visible = false
		return
	end
	local modeled = SpeciesThumb.Show(slot.thumb, def, shadowed)
	slot.modeled = modeled
	slot.fallback.Visible = not modeled
	slot.mark.Visible = not modeled and shadowed
	if not modeled then
		slot.fallback.BackgroundColor3 = if shadowed then Theme.Shadow else Theme.Hex(def.placeholder.color)
	end
end

-- One frame of motion for the sheet and the slots; answers whether anything is still moving (the Heartbeat stops itself when not).
local function step(dt: number): boolean
	local reduced = Prefs.ReducedMotion()
	local moving = false

	local target = if shown then heightFor(limitNow) else 0
	if heightNow ~= target then
		local rate = heightFor(math.max(limitNow, lastLimit)) / math.max(Look.UnrollSeconds, 0.001)
		heightNow = if reduced then target else RadarMath.Approach(heightNow, target, rate * dt)
		layout()
		if heightNow ~= target then
			moving = true
		end
	end

	local fade = if reduced then 1 else RadarMath.FadeStep(dt, Look.FadeSeconds)
	for _, slot in ipairs(slots) do
		local goal, swap = RadarMath.SlotPlan(slot.showing, slot.showingShadowed, slot.wanted, slot.wantedShadowed, slot.alpha)
		if swap then
			fillSlot(slot, slot.wanted, slot.wantedShadowed)
		end
		slot.alpha = RadarMath.Approach(slot.alpha, goal, fade)
		-- Still moving while a fade runs or a picture waits for its turn to change (the swap comes the frame after it is invisible).
		if slot.alpha ~= goal or slot.showing ~= slot.wanted or (slot.wanted ~= nil and slot.showingShadowed ~= slot.wantedShadowed) then
			moving = true
		end
		paintSlot(slot)
	end

	if heightNow <= 0 and not shown then
		local root = gui
		if root and root.Enabled then
			root.Enabled = false -- rolled up: nothing to draw
		end
	end
	return moving
end

local function wake()
	if animator then
		return
	end
	local root = gui
	if root and not root.Enabled then
		root.Enabled = true
	end
	animator = RunService.Heartbeat:Connect(function(dt: number)
		if not step(dt) then
			local connection = animator
			animator = nil
			if connection then
				connection:Disconnect()
			end
		end
	end)
end

-- Slots ----------------------------------------------------------------------

local function newSlot(parent: Frame, index: number): Slot
	local top = RadarMath.SlotTop(index, Look.Top, Look.RollerHeight, Look.Pad, Look.SlotPitch)
	local frame = Builder.frame({
		parent = parent,
		name = "Slot" .. index,
		position = UDim2.fromScale(Look.X, top),
		size = UDim2.fromScale(Look.Width, Look.SlotPitch),
		anchor = Vector2.new(1, 0),
		zIndex = ZSLOT,
	})
	frame.Visible = false
	-- The soft ground shadow: a flat ellipse in the shadow colour, faint, under the feet (below the picture).
	local ground = Builder.frame({
		parent = frame,
		name = "Ground",
		color = Theme.Shadow,
		transparency = 1,
		corner = Theme.Corner.Pill,
		position = UDim2.fromScale(0.5, Look.GroundCentre),
		size = UDim2.fromScale(Look.GroundWidth, Look.GroundHeight),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = ZSLOT,
	})
	-- The picture's box: a square the picture is framed in, kept square by an aspect constraint inside the slot's width.
	local art = Builder.frame({
		parent = frame,
		name = "Art",
		position = UDim2.fromScale(0.5, Look.ArtCentre),
		size = UDim2.fromScale(1, ART_OF_SLOT),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = ZSLOT + 1,
	})
	Builder.aspect(art, 1)
	local fallback = Builder.frame({
		parent = art,
		name = "Blob",
		color = Theme.Shadow,
		corner = Theme.Corner.Pill,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.8, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = ZSLOT + 1,
	})
	fallback.Visible = false
	local mark = Builder.label({
		parent = art,
		name = "Unknown",
		text = Strings.UI_UNKNOWN_GLYPH,
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Paper,
		stroke = 0,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(1, 1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = ZSLOT + 2,
	})
	mark.Visible = false
	local thumb = SpeciesThumb.New(art, ZSLOT + 2, 1)
	return {
		frame = frame,
		ground = ground,
		fallback = fallback,
		mark = mark,
		thumb = thumb,
		top = top,
		showing = nil,
		showingShadowed = true,
		modeled = true,
		wanted = nil,
		wantedShadowed = true,
		alpha = 0,
	}
end

-- Sets what a slot should show; the animator fades the old picture out, swaps and fades the new one in.
local function want(slot: Slot, speciesId: string?, shadowed: boolean)
	slot.wanted, slot.wantedShadowed = speciesId, shadowed
	if speciesId ~= nil and slot.showing == speciesId and slot.showingShadowed == shadowed and not slot.modeled then
		-- Standing on a plain blob: look for the model again now (the models load at run time), without a fade.
		fillSlot(slot, speciesId, shadowed)
	end
end

-- Refresh ------------------------------------------------------------------------

-- One pass: reads the wild parts, keeps the nearest few in reach (RadarMath), and tells each slot which one stands at its place in
-- the order.
local function refresh()
	local pulse = WildRenderer.ScannerPulseActive()
	local row = tierRow()
	local limit = RadarMath.Slots(row.slots, pulse, pulseSlots)
	local count = 0
	local at = rootPosition()
	local wild = wildFolder()
	syncWild(wild)
	if at and wild and limit > 0 then
		local biome = State.GetBiome()
		local me = localPlayer.UserId
		for _, child in ipairs(wildParts) do
			local reservedFor = child:GetAttribute("ReservedFor")
			if type(reservedFor) == "number" and reservedFor ~= me then
				continue -- hidden for this player everywhere
			end
			if WildRenderer.IsHidden(child) then
				continue -- the radar never lists what the world does not show
			end
			local speciesId = child:GetAttribute("SpeciesId")
			if type(speciesId) ~= "string" then
				continue
			end
			local offset = child.Position - at
			local flat = RadarMath.Flat(offset.X, offset.Z)
			local sameBiome = pulse and child:GetAttribute("Biome") == biome
			if not RadarMath.Reaches(flat, row.range, pulse, sameBiome) then
				continue
			end
			local tierAttribute = child:GetAttribute("Tier")
			local def = Species.ById[speciesId]
			local tierName: string = if type(tierAttribute) == "string" then tierAttribute elseif def then def.tier else "Common"
			if not RadarMath.TierListed(tierName) then
				continue -- a Secret is never told, not even as a shadow
			end
			count = RadarMath.Offer(nearDistance, nearPart, count, limit, flat, child)
		end
	end
	if limit ~= limitNow then
		limitNow = limit
		if limit > 0 then
			lastLimit = limit
		end
	end
	for index, slot in ipairs(slots) do
		local speciesId: string? = nil
		if index <= limit and index <= count then
			local attribute = nearPart[index]:GetAttribute("SpeciesId")
			if type(attribute) == "string" then
				speciesId = attribute
			end
		end
		want(slot, speciesId, if speciesId then RadarMath.Shadowed(catches(speciesId)) else true)
	end
	if count == 0 then
		table.clear(nearPart)
	end
	wake()
end

-- Ticking ----------------------------------------------------------------------

local function wantShown(): boolean
	if not visible or not stageShown or not gui then
		return false
	end
	return RadarMath.Slots(tierRow().slots, WildRenderer.ScannerPulseActive(), pulseSlots) > 0
end

local applyShown: () -> ()

local function startTicking()
	if heartbeat then
		return
	end
	accumulator = Config.RadarRefreshSeconds -- list on the first frame
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < Config.RadarRefreshSeconds then
			return
		end
		accumulator = 0
		applyShown() -- a Scanner Pulse that just ended takes the scroll away when there is no radar
		if shown then
			refresh()
		end
	end)
end

local function stopTicking()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	unwatchWild() -- nothing reads the list while the loop is down; the next refresh lists the folder again
	table.clear(nearPart)
end

-- Shown only while the bootstrap allows it and the tier (or a Scanner Pulse) gives at least one slot; the loop runs only while
-- shown. Showing unrolls the sheet; hiding rolls it up, and the sheet's slots fade out with it.
function applyShown()
	local next = wantShown()
	if next == shown then
		return
	end
	shown = next
	if shown then
		refresh()
		startTicking()
	else
		stopTicking()
		for _, slot in ipairs(slots) do
			slot.wanted, slot.wantedShadowed = nil, true -- rolling up: the pictures go as the paper does
		end
		limitNow = 0
		wake()
	end
end

-- Build ----------------------------------------------------------------------

-- Creates the ScreenGui once, hidden. SetTier, SetVisible and the Scanner Pulse decide when it shows.
function RadarColumn.Build()
	if gui then
		return
	end
	local root = Builder.screen("RadarColumn", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	-- One full-screen holder: every piece below is positioned in screen fractions (data/RadarScroll). It takes no input.
	local holder = Builder.frame({ parent = root, name = "Holder", zIndex = 1 })

	local function dropLayer(name: string, transparency: number): Frame
		local layer = Builder.frame({
			parent = holder,
			name = name,
			color = Theme.Colors.Black,
			transparency = transparency,
			position = UDim2.fromScale(Look.X, Look.Top),
			size = UDim2.fromScale(Look.Width, 0),
			anchor = Vector2.new(1, 0),
			zIndex = ZPAPER - 1,
		})
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(Look.CornerScale, 0)
		corner.Parent = layer
		layer.Visible = false
		return layer
	end
	dropOuter = dropLayer("DropOuter", Look.DropOuterTransparency)
	dropInner = dropLayer("DropInner", Look.DropTransparency)

	-- The sheet: cream paper with a thin dark edge and a rounded outline, its height set by `layout`.
	local sheet = Builder.frame({
		parent = holder,
		name = "Paper",
		color = Theme.Colors.Paper,
		position = UDim2.fromScale(Look.X, Look.Top),
		size = UDim2.fromScale(Look.Width, 0),
		anchor = Vector2.new(1, 0),
		stroke = Look.EdgePx,
		strokeColor = Theme.Colors.Outline,
		zIndex = ZPAPER,
	})
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(Look.CornerScale, 0)
	corner.Parent = sheet
	sheet.Visible = false
	paper = sheet

	-- The rolled ends: a darker capsule across the top and the bottom edge, a little wider than the sheet.
	local function roller(name: string, anchorY: number, y: number): Frame
		local band = Builder.frame({
			parent = holder,
			name = name,
			color = Theme.Colors.PaperRoll,
			position = UDim2.fromScale(PAPER_CENTRE, y),
			size = UDim2.fromScale(ROLLER_WIDTH, Look.RollerHeight),
			anchor = Vector2.new(0.5, anchorY),
			stroke = Look.RollerEdgePx,
			strokeColor = Theme.Colors.Outline,
			zIndex = ZROLL,
		})
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = band
		band.Visible = false
		return band
	end
	topRoller = roller("RollerTop", 0, Look.Top)
	bottomRoller = roller("RollerBottom", 1, Look.Top)

	for index = 1, maxSlots do
		table.insert(slots, newSlot(holder, index))
	end

	table.insert(connections, State.OnChanged("codex", function()
		if shown then
			refresh() -- a catch turns that species' shadow into its face at once
		end
	end))
	table.insert(connections, State.OnChanged("buffs", function()
		applyShown() -- a Scanner Pulse starting or ending shows or hides the scroll, even with no radar
		if shown then
			refresh()
		end
	end))
	applyShown()
end

-- The radar tier the server says the player holds (profile.gear.radar): 0 shows nothing (bar a Scanner Pulse), 1 and up show that
-- tier's slots and range (clamped to the highest tier in the data).
function RadarColumn.SetTier(next: number)
	if next ~= next then
		next = 0
	end
	tier = math.clamp(math.floor(next), 0, maxTier)
	applyShown()
	if shown then
		refresh() -- the range and the slots changed, so list again now rather than on the next tick
	end
end

-- The staged reveal (HudStages "Radar"): UI/TutorialHint calls this with the server's tutorial step on each change. A new player with
-- Radar Mk1 already owned (the Explorer Pack) sees no scroll until the stage the data names; a finished tutorial shows it at once.
function RadarColumn.SetStage(step: number)
	stageShown = HudStages.Shown("Radar", step, HudStages.IsDone(step))
	applyShown()
end

-- The bootstrap hides the scroll during a capture, a reveal or an open panel, like the other HUD extras.
function RadarColumn.SetVisible(show: boolean)
	if visible == show then
		return
	end
	visible = show
	applyShown()
end

function RadarColumn.IsShown(): boolean
	return shown
end

-- Stops the loops, drops every connection and destroys the ScreenGui; Build may run again afterwards.
function RadarColumn.Stop()
	stopTicking()
	if animator then
		animator:Disconnect()
		animator = nil
	end
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	shown = false
	limitNow = 0
	heightNow = 0
	for _, slot in ipairs(slots) do
		SpeciesThumb.Destroy(slot.thumb)
	end
	slots = {}
	paper, dropInner, dropOuter, topRoller, bottomRoller = nil, nil, nil, nil, nil
	local root = gui
	gui = nil
	if root then
		root:Destroy()
	end
end

return RadarColumn
