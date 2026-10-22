--!strict
-- StarterPlayerScripts.Client.UI.RadarColumn: the radar (data/Radar, Decision B52, UI Playbook "Radar column"). Ethan, 2026-10-22:
-- "having a map of where the aliens are and what rarities defeats the whole struggle aspect of the game. We want them to search for
-- the aliens like a pokemon game ... a radar which is depicted on the screen by a column of the silhouettes of each alien listed
-- from closest to furthest from you." There is no map, no blip, no rarity colour, no name, no distance and no tap: a narrow column
-- on the right edge under the weather and biome chips, in the slot the minimap used to take, of small square block slots, the
-- NEAREST wild alien at the top and the furthest at the bottom. Each slot is the species' model in a viewport (SpeciesThumb): an
-- all-black silhouette while the player has no catch of that species in the codex, the real model once there is one. The head of
-- the column is a small "Radar" chip.
--
-- What is listed: the wild parts under Workspace.World.Wild (the client already sees them; the server owns the spawns) within the
-- tier's range of the player, flat (data/Radar), nearest first, at most the tier's slot count (Mk1 5, Mk2 7, Mk3 9). Skipped: an
-- alien reserved for another player, one the Blizzard rule hides (WildRenderer.IsHidden), and every Secret-tier alien (never
-- listed, not even as a shadow; the Mk2 heartbeat that quickened near a Secret went with the minimap, since a sound that quickens
-- as you near it tells a direction). Tier 0 (no radar owned) shows nothing. While a Scanner Pulse runs (WildRenderer.ScannerPulseActive,
-- data/PowerUps) the column also works without a radar and lists the nearest `Pulse.slots` aliens of the player's current biome
-- whatever their range: still shadows and order only, no positions; its head turns Codex purple meanwhile.
--
-- Cost: the Wild folder's parts are kept in a list by ChildAdded/ChildRemoved (no GetChildren per refresh), the nearest-first sort
-- is RadarMath.Offer over two reused arrays (no table per refresh), and the slots are a pool built once for the most any tier or
-- the pulse can show; a refresh every Config.RadarRefreshSeconds rewrites only the slots whose species or shade changed (a clone of
-- the model is made then). The pure choices (range, slot count, order, shadow or face) are Shared/RadarMath, tests/RadarMath.spec.luau.
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
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local RadarMath = require(Shared:WaitForChild("RadarMath"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local HudStages = require(Shared:WaitForChild("HudStages"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)
local State = require(script.Parent.Parent.State)
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

-- Layout, all Scale. The column's slot is the old minimap's: right edge 0.985, under the shower chip (which ends near y 0.215), and
-- it ends above the Catch button (top near 0.83). Heights are fractions of the screen height; the holder is as tall as the full
-- nine-slot column, and each square is kept square by an aspect constraint inside the holder's width (an iPhone SE slot is about
-- 20 px, an iPad's 44).
local COLUMN_X = 0.985
local COLUMN_TOP = 0.228
local COLUMN_WIDTH = 0.1 -- of the screen width: wider than any slot, so the squares are limited by their height
local HEAD_H = 0.05 -- the "Radar" chip
local HEAD_ASPECT = 3 -- its width over its height
local HEAD_GAP = 0.008
local SLOT_H = 0.054
local SLOT_GAP = 0.005
local HOLDER_H = HEAD_H + HEAD_GAP + maxSlots * SLOT_H + (maxSlots - 1) * SLOT_GAP
local EMPTY_FADE = 0.6 -- an unused slot is the same block, fainter
local SLOT_ROWS = Builder.blockRows(SLOT_H) -- cell rows across a slot (3 at the HUD's cell)

local localPlayer = Players.LocalPlayer

type Slot = {
	plate: Frame, -- the block the square stands on
	host: Frame, -- the plate's inner box: the viewport fills it; its colour is the fallback when no model shows
	thumb: SpeciesThumb.Thumb,
	mark: TextLabel, -- the "?" of a shadow whose model is missing
	species: string?, -- what the slot shows now (nil: empty), so an unchanged slot is left alone
	shadowed: boolean,
	modeled: boolean, -- whether a model showed; a slot without one tries again each refresh (the models load at run time)
}

local gui: ScreenGui? = nil
local head: Frame? = nil
local slots: { Slot } = {}
local wildParts: { Part } = {} -- the parts under the Wild folder, in arrival order, kept by ChildAdded/ChildRemoved
local watchedWild: Instance? = nil
local wildConns: { RBXScriptConnection } = {}
local connections: { RBXScriptConnection } = {}
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local nearDistance: { number } = {} -- the nearest-first list RadarMath.Offer keeps, reused every refresh
local nearPart: { Part } = {}
local tier = 0 -- the radar tier the server says the player holds (SetTier); 0 shows nothing
local visible = true -- the bootstrap's SetVisible: captures, reveals and open panels hide the HUD extras
local stageShown = false -- the staged reveal (SetStage): hidden until the tutorial has earned the column, whatever radar the account owns
local shown = false
local pulseLook = false -- whether the head is dressed for a Scanner Pulse

-- Helpers ------------------------------------------------------------------

local function tierRow(): TierRow
	return tiers[tier] or tiers[0]
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

-- Slots ----------------------------------------------------------------------

local function newSlot(parent: Frame, index: number): Slot
	local top = HEAD_H + HEAD_GAP + (index - 1) * (SLOT_H + SLOT_GAP)
	local plate = Builder.blockPlate({
		parent = parent,
		name = "Slot" .. index,
		color = Theme.Colors.Panel, -- cream, so a black shadow and a coloured model both read on it
		aspect = 1,
		rows = SLOT_ROWS,
		cells = false, -- a small block stays one flat colour (UI Playbook "Block cells")
		position = UDim2.fromScale(1, top / HOLDER_H),
		size = UDim2.fromScale(1, SLOT_H / HOLDER_H),
		anchor = Vector2.new(1, 0),
		zIndex = 2,
	})
	plate.Visible = false
	local innerPosition, innerSize = Builder.blockInner(plate)
	local content = Builder.blockTop(plate)
	local host = Builder.frame({
		parent = plate,
		name = "Host",
		position = innerPosition,
		size = innerSize,
		zIndex = content,
	})
	local thumb = SpeciesThumb.New(host, content + 1, 1)
	local mark = Builder.label({
		parent = host,
		name = "Unknown",
		text = Strings.UI_UNKNOWN_GLYPH,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(1, 1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = content + 2,
	})
	mark.Visible = false
	Builder.setBlockFade(plate, EMPTY_FADE) -- a new slot is empty
	return { plate = plate, host = host, thumb = thumb, mark = mark, species = nil, shadowed = true, modeled = true }
end

-- Shows `speciesId` in a slot as a shadow or as the real model, or empties it (nil). Only touches what changed. A species whose
-- model is not there (none imported in this place, or not loaded yet) shows a plain block: the black shadow with a "?", or the
-- species' placeholder colour once caught; the next refresh tries the model again.
local function fillSlot(slot: Slot, speciesId: string?, shadowed: boolean)
	if slot.species == speciesId and slot.shadowed == shadowed and slot.modeled then
		return
	end
	slot.species, slot.shadowed = speciesId, shadowed
	local def = if speciesId then Species.ById[speciesId] else nil
	if not def then
		slot.modeled = true
		SpeciesThumb.Show(slot.thumb, nil, false)
		slot.host.BackgroundTransparency = 1
		slot.mark.Visible = false
		Builder.setBlockFade(slot.plate, EMPTY_FADE)
		return
	end
	Builder.setBlockFade(slot.plate, 0)
	local modeled = SpeciesThumb.Show(slot.thumb, def, shadowed)
	slot.modeled = modeled
	if modeled then
		slot.host.BackgroundTransparency = 1
		slot.mark.Visible = false
	else
		slot.host.BackgroundTransparency = 0
		slot.host.BackgroundColor3 = if shadowed then Theme.Shadow else Theme.Hex(def.placeholder.color)
		slot.mark.Visible = shadowed
	end
end

-- The head chip's look: the dark HUD block, or Codex purple while a Scanner Pulse runs.
local function dressHead(pulse: boolean)
	if pulse == pulseLook then
		return
	end
	pulseLook = pulse
	local chip = head
	if chip then
		Builder.setBlockColor(chip, if pulse then Theme.Colors.Codex else Theme.Block.Trough)
	end
end

-- Refresh ------------------------------------------------------------------------

-- One pass: reads the wild parts, keeps the nearest few in reach (RadarMath), and sets each slot to the shadow or the face of the
-- one standing at its place in the order.
local function refresh()
	local pulse = WildRenderer.ScannerPulseActive()
	dressHead(pulse)
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
	for index, slot in ipairs(slots) do
		slot.plate.Visible = index <= limit
		if index > limit then
			continue
		end
		if index <= count then
			local speciesId = nearPart[index]:GetAttribute("SpeciesId")
			if type(speciesId) == "string" then
				fillSlot(slot, speciesId, RadarMath.Shadowed(catches(speciesId)))
			else
				fillSlot(slot, nil, true)
			end
		else
			fillSlot(slot, nil, true)
		end
	end
	if count == 0 then
		table.clear(nearPart)
	end
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
		applyShown() -- a Scanner Pulse that just ended takes the column away when there is no radar
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

-- Shown only while the bootstrap allows it and the tier (or a Scanner Pulse) gives at least one slot; the loop runs only while shown.
function applyShown()
	local root = gui
	local next = wantShown()
	if root and root.Enabled ~= next then
		root.Enabled = next
	end
	if next == shown then
		return
	end
	shown = next
	if shown then
		refresh()
		startTicking()
	else
		stopTicking()
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

	local column = Builder.frame({
		parent = root,
		name = "Column",
		position = UDim2.fromScale(COLUMN_X, COLUMN_TOP),
		size = UDim2.fromScale(COLUMN_WIDTH, HOLDER_H),
		anchor = Vector2.new(1, 0),
	})

	-- The head: a small dark block reading "Radar", the column's name (a flat block, as the HUD's chips).
	local chip = Builder.blockPlate({
		parent = column,
		name = "Head",
		color = Theme.Block.Trough,
		aspect = HEAD_ASPECT,
		rows = Theme.Block.MinRows,
		cells = false,
		position = UDim2.fromScale(1, 0),
		size = UDim2.fromScale(1, HEAD_H / HOLDER_H),
		anchor = Vector2.new(1, 0),
		zIndex = 2,
	})
	head = chip
	local innerPosition, innerSize = Builder.blockInner(chip)
	Builder.label({
		parent = chip,
		name = "Title",
		text = Strings.RADAR_COLUMN_TITLE,
		textSize = Theme.TextSize.Min,
		position = innerPosition,
		size = innerSize,
		zIndex = Builder.blockTop(chip),
	})

	for index = 1, maxSlots do
		table.insert(slots, newSlot(column, index))
	end

	table.insert(connections, State.OnChanged("codex", function()
		if shown then
			refresh() -- a catch turns that species' shadow into its face at once
		end
	end))
	table.insert(connections, State.OnChanged("buffs", function()
		applyShown() -- a Scanner Pulse starting or ending shows or hides the column, even with no radar
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
	local clamped = math.clamp(math.floor(next), 0, maxTier)
	local gained = clamped >= 1 and tier < 1
	tier = clamped
	applyShown()
	if shown then
		refresh() -- the range and the slots changed, so list again now rather than on the next tick
		local chip = head
		if gained and chip then
			Builder.pop(chip, 1.15) -- the chip, not the holder: a scale on the holder would move the layout
		end
	end
end

-- The staged reveal (HudStages "Radar"): UI/TutorialHint calls this with the server's tutorial step on each change. A new player with
-- Radar Mk1 already owned (the Explorer Pack) sees no column until the stage the data names; a finished tutorial shows it at once.
function RadarColumn.SetStage(step: number)
	stageShown = HudStages.Shown("Radar", step, HudStages.IsDone(step))
	applyShown()
end

-- The bootstrap hides the column during a capture, a reveal or an open panel, like the other HUD extras.
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

-- Stops the loop, drops every connection and destroys the ScreenGui; Build may run again afterwards.
function RadarColumn.Stop()
	stopTicking()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	shown = false
	pulseLook = false
	for _, slot in ipairs(slots) do
		SpeciesThumb.Destroy(slot.thumb)
	end
	slots = {}
	head = nil
	local root = gui
	gui = nil
	if root then
		root:Destroy()
	end
end

return RadarColumn
