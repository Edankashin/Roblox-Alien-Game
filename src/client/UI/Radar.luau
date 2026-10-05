--!strict
-- StarterPlayerScripts.Client.UI.Radar: the Radar Mk1 minimap (data/Radar, tier 1 and up). A round
-- north-up disc on the right edge under the HUD's shower chip, in the slot the free Nearby panel
-- (tier 0) otherwise starts in; the bootstrap hears the disc's bottom edge through OnLayout and
-- pushes the panel's top down under it. One blip per wild alien part under Workspace.World.Wild
-- within the tier's range of the player's HumanoidRootPart: tier-coloured for a caught species, a
-- dark silhouette ringed in the tier colour for one not yet in the codex (the world's shadow rule),
-- gold-ringed for an alien the server reserved for this player; an alien the Blizzard rule hides has
-- no blip. A cream square marks the camp and a
-- gold diamond the Peddler while it visits, both pinned to the disc edge when out of range so they
-- point the way. A tap on a blip hands the wild part to the bootstrap, which sets the waypoint.
-- Client-only and pure presentation: the server owns which tier is held (profile.gear.radar, pushed
-- by GearChanged into State and fed in with SetTier) and the Spawner owns the wild parts; this module
-- only reads positions and attributes and draws. It never decides what the player may see, mark or
-- catch.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local RadarTiers = require(Shared:WaitForChild("data"):WaitForChild("Radar"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)
local CampRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("CampRenderer"))
local PeddlerRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("PeddlerRenderer"))
local WildRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("WildRenderer"))

local Radar = {}

type RadarTier = { name: string, range: number, scrap: number, unlock: string? }
-- Literal number keys, some rows without `unlock`: cast through any the way the server's Shop does.
local tiers: { [number]: RadarTier } = (RadarTiers :: any) :: { [number]: RadarTier }

-- The highest tier the data knows; SetTier clamps to it so a save from a later build never asks for
-- a row that is not there.
local maxTier = 0
for tier in pairs(tiers) do
	if tier > maxTier then
		maxTier = tier
	end
end

-- One pooled alien blip. Built once, restyled and re-placed on every refresh, hidden while spare.
type Blip = {
	frame: Frame,
	stroke: UIStroke,
	part: Part?, -- the wild part this blip stands for since the last refresh; nil while pooled
}

local DISPLAY_ORDER = 10 -- the HUD's layer, beside the Nearby panel

-- Right edge under the HUD's shower chip (which ends near y 0.215): the Nearby column's default slot,
-- which the disc takes over while a radar is held.
local SLOT_X = 0.985
local SLOT_TOP = 0.225
local RADAR_WIDTH = 0.14 -- of the screen width; the aspect fit makes the holder a square of this side
local LAYOUT_GAP = 0.012 -- between the disc's bottom edge and the Nearby column's top
local RING_SIZE = 0.5 -- the range ring's diameter, of the disc: half the radius, so half the range
local RING_TRANSPARENCY = 0.6
local NORTH_TOP = 0.03
local NORTH_SIZE = 0.2 -- the cardinal letter's box, of the disc
local RANGE_LABEL_W = 0.4
local RANGE_LABEL_H = 0.12
local BLIP_SIZE = 0.1 -- of the disc
local HIT_SCALE = 2 -- the invisible tap area is this many blips wide and tall
local MARKER_SIZE = 0.09 -- the camp square and the Peddler diamond
local PLAYER_SIZE = 0.14 -- the player marker's box
local PLAYER_DIAMOND = 0.7 -- the square inside it; on its point (45 degrees) its corners reach the box
local PLAYER_TIP = 0.28 -- the facing dot at the top of the box, of the box
local EDGE = 0.5 - BLIP_SIZE / 2 -- how far a blip's centre may sit from the disc centre and stay inside
local SILHOUETTE = Builder.darker(Theme.Colors.Trough) -- fill for a species not yet caught

local localPlayer = Players.LocalPlayer

local gui: ScreenGui? = nil
local holder: Frame? = nil -- the square the aspect fit sizes; its height is the disc's height
local disc: Frame? = nil
local rangeLabel: TextLabel? = nil
local playerMarker: Frame? = nil
local campMarker: Frame? = nil
local peddlerMarker: Frame? = nil
local blips: { Blip } = {}
local connections: { RBXScriptConnection } = {}
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local known: { [string]: boolean } = {} -- species with a catch in the codex: solid blips, not silhouettes
local tier = 0 -- the radar tier the server says the player holds (SetTier); 0 is the free Nearby panel
local range = 0 -- studs, from the tier's row; the disc radius
local visible = true -- the bootstrap's SetVisible: captures, reveals and open panels hide the HUD extras
local shown = false -- visible and tier >= 1
local lastBottom: number? = nil -- the last value handed to OnLayout, so unchanged layouts stay quiet
local onBlipTapped: ((part: Part) -> ())? = nil
local onLayout: ((bottom: number) -> ())? = nil

-- Helpers ------------------------------------------------------------------

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

-- Workspace.World.Wild without yielding: until it exists there is simply nothing to draw.
local function wildFolder(): Instance?
	local world = Workspace:FindFirstChild("World")
	return if world then world:FindFirstChild("Wild") else nil
end

-- Puts a marker on the disc for a world offset from the player. North-up: world -Z is up the disc,
-- +X is right, and the range is the disc radius (0.5), so a blip at the full range sits on the rim.
-- The offset is clamped to EDGE, so a blip right at the range stays inside the disc and an
-- out-of-range camp or Peddler marker becomes a direction marker on the rim.
local function place(object: GuiObject, dx: number, dz: number)
	if range <= 0 then
		object.Position = UDim2.fromScale(0.5, 0.5)
		return
	end
	local ox = dx / range * 0.5
	local oy = dz / range * 0.5
	local magnitude = math.sqrt(ox * ox + oy * oy)
	if magnitude > EDGE then
		local shrink = EDGE / magnitude
		ox *= shrink
		oy *= shrink
	end
	object.Position = UDim2.fromScale(0.5 + ox, 0.5 + oy)
end

-- The species the player has caught, from the profile's codex (the rule the Nearby panel and the
-- world's silhouettes share); re-read on every codex change.
local function readKnown()
	local next: { [string]: boolean } = {}
	if State.Has() then
		for species, entry in pairs(State.Get().codex) do
			if entry.count > 0 then
				next[species] = true
			end
		end
	end
	known = next
end

-- Blips --------------------------------------------------------------------

local function newBlip(parent: Frame): Blip
	local frame = Builder.pill({
		parent = parent,
		name = "Blip",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(BLIP_SIZE, BLIP_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Rarity.Common,
		aspect = 1,
		zIndex = 5,
	})
	frame.Visible = false
	local stroke = Builder.stroke(frame, Theme.Stroke.Text, Theme.Colors.Outline)
	-- Invisible tap area twice the blip, a child so it moves with it; a click on every tap.
	local hit = Instance.new("TextButton")
	hit.Name = "Tap"
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.BorderSizePixel = 0
	hit.BackgroundTransparency = 1
	hit.Position = UDim2.fromScale(0.5, 0.5)
	hit.Size = UDim2.fromScale(HIT_SCALE, HIT_SCALE)
	hit.AnchorPoint = Vector2.new(0.5, 0.5)
	hit.ZIndex = 6
	hit.Parent = frame
	local blip: Blip = { frame = frame, stroke = stroke, part = nil }
	hit.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		local part = blip.part
		if part and part.Parent and onBlipTapped then
			onBlipTapped(part)
		end
	end)
	table.insert(blips, blip)
	return blip
end

-- Caught species: solid tier colour with the outline. Uncaught: the silhouette rule, a dark fill with
-- the ring in the tier colour (white for a Secret, whose tier colour is near black). An alien the
-- server reserved for this player (a trainee, the summoned Warden) gets the Featured ring either way.
local function styleBlip(blip: Blip, tierName: string, caught: boolean, reservedForMe: boolean)
	local tierColor = Builder.tierColor(tierName)
	if caught then
		blip.frame.BackgroundColor3 = tierColor
		blip.stroke.Color = Theme.Colors.Outline
	else
		blip.frame.BackgroundColor3 = SILHOUETTE
		blip.stroke.Color = if tierName == "Secret" then Theme.Colors.White else tierColor
	end
	if reservedForMe then
		blip.stroke.Color = Theme.Colors.Featured
	end
end

-- The camp square and, while a visit is on, the Peddler diamond; both clamp to the rim when far.
local function refreshMarkers(at: Vector3?)
	local camp, peddler = campMarker, peddlerMarker
	if not camp or not peddler then
		return
	end
	if not at or range <= 0 then
		camp.Visible = false
		peddler.Visible = false
		return
	end
	local ship = CampRenderer.ShipPosition() - at
	place(camp, ship.X, ship.Z)
	camp.Visible = true
	if PeddlerRenderer.IsVisiting() then
		local offset = PeddlerRenderer.Position() - at
		place(peddler, offset.X, offset.Z)
		peddler.Visible = true
	else
		peddler.Visible = false
	end
end

-- One blip per wild part within range, measured flat (XZ) since the disc is a flat map. Parts the
-- server reserved for another player are skipped: they are hidden for this player everywhere. So are
-- aliens the Blizzard rule hides (WildRenderer.IsHidden): the radar never shows what the world does not.
local function refreshBlips()
	local face = disc
	if not face then
		return
	end
	local at = rootPosition()
	local wild = wildFolder()
	local used = 0
	if at and wild and range > 0 then
		for _, child in ipairs(wild:GetChildren()) do
			if not child:IsA("Part") then
				continue
			end
			local reservedFor = child:GetAttribute("ReservedFor")
			local reserved = type(reservedFor) == "number"
			if reserved and reservedFor ~= localPlayer.UserId then
				continue
			end
			if WildRenderer.IsHidden(child) then
				continue
			end
			local species = child:GetAttribute("SpeciesId")
			if type(species) ~= "string" then
				continue
			end
			local offset = child.Position - at
			if math.sqrt(offset.X * offset.X + offset.Z * offset.Z) > range then
				continue
			end
			used += 1
			local blip = blips[used] or newBlip(face)
			blip.part = child
			local def = Species.ById[species]
			local tierAttribute = child:GetAttribute("Tier")
			local tierName: string = if type(tierAttribute) == "string" then tierAttribute elseif def then def.tier else "Common"
			styleBlip(blip, tierName, known[species] == true, reserved)
			place(blip.frame, offset.X, offset.Z)
			blip.frame.Visible = true
		end
	end
	for index = used + 1, #blips do
		local blip = blips[index]
		blip.part = nil
		blip.frame.Visible = false
	end
	refreshMarkers(at)
end

-- Turns the player marker to the camera's look yaw: north (-Z) is 0, east (+X) is 90, clockwise like
-- GuiObject.Rotation. A camera looking straight down has no yaw, so the marker keeps its last one.
local function refreshHeading()
	local marker = playerMarker
	local camera = Workspace.CurrentCamera
	if not marker or not camera then
		return
	end
	local look = camera.CFrame.LookVector
	if look.X * look.X + look.Z * look.Z < 1e-6 then
		return
	end
	marker.Rotation = math.deg(math.atan2(look.X, -look.Z))
end

-- Layout -----------------------------------------------------------------------

-- The disc's bottom edge in screen Scale plus the gap, for the Nearby column's top; the slot's own
-- top while the disc is hidden, so the column gets its default back. The holder is a square of
-- RADAR_WIDTH of the screen width, so its height in Scale depends on the viewport's aspect: it is
-- read back from the absolute sizes (and, before the first layout pass, from what the fit will give).
local function discBottom(): number
	local root, square = gui, holder
	if not shown or not root or not square then
		return SLOT_TOP
	end
	local screen = root.AbsoluteSize
	if screen.Y <= 0 then
		return SLOT_TOP
	end
	local side = square.AbsoluteSize.Y
	if side <= 0 then
		side = math.min(RADAR_WIDTH * screen.X, screen.Y)
	end
	return SLOT_TOP + side / screen.Y + LAYOUT_GAP
end

local function notifyLayout()
	local bottom = discBottom()
	if bottom == lastBottom then
		return
	end
	lastBottom = bottom
	if onLayout then
		onLayout(bottom)
	end
end

-- Ticking ----------------------------------------------------------------------

local function startTicking()
	if heartbeat then
		return
	end
	accumulator = Config.RadarRefreshSeconds -- place the blips on the first frame
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		refreshHeading() -- one rotation write per frame keeps the marker smooth
		accumulator += dt
		if accumulator < Config.RadarRefreshSeconds then
			return
		end
		accumulator = 0
		refreshBlips()
	end)
end

local function stopTicking()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

-- Shown only while the bootstrap allows it and a radar tier is held; the loop runs only while shown.
local function applyShown()
	local root = gui
	local next = visible and tier >= 1 and root ~= nil
	if root and root.Enabled ~= next then
		root.Enabled = next
	end
	if next ~= shown then
		shown = next
		if shown then
			readKnown()
			refreshBlips()
			startTicking()
		else
			stopTicking()
		end
	end
	notifyLayout()
end

-- Build ----------------------------------------------------------------------

local function buildDisc(parent: Frame): Frame
	local face = Builder.pill({
		parent = parent,
		name = "Disc",
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 1,
	})
	Builder.gradient(face, Theme.Colors.Trough)

	-- Faint range ring at half the radius, with half the range on its top edge.
	local ring = Builder.pill({
		parent = face,
		name = "Ring",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(RING_SIZE, RING_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = 2,
	})
	local ringStroke = Builder.stroke(ring, Theme.Stroke.Text, Theme.Colors.Select)
	ringStroke.Transparency = RING_TRANSPARENCY
	rangeLabel = Builder.label({
		parent = face,
		name = "Range",
		text = Strings.RADAR_RANGE:format(0),
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(0.5, 0.5 - RING_SIZE / 2),
		size = UDim2.fromScale(RANGE_LABEL_W, RANGE_LABEL_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 6, -- over the blips (5), so the distance stays readable in a crowd
	})

	-- The map is north-up and never rotates, so one cardinal letter is enough.
	Builder.label({
		parent = face,
		name = "North",
		text = Strings.RADAR_NORTH,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, NORTH_TOP),
		size = UDim2.fromScale(NORTH_SIZE, NORTH_SIZE),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
	return face
end

local function buildMarkers(face: Frame)
	local camp = Builder.frame({
		parent = face,
		name = "Camp",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(MARKER_SIZE, MARKER_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 4,
	})
	camp.Visible = false
	campMarker = camp

	local peddler = Builder.frame({
		parent = face,
		name = "Peddler",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(MARKER_SIZE, MARKER_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 4,
	})
	peddler.Rotation = 45 -- a square on its point reads as a diamond
	peddler.Visible = false
	peddlerMarker = peddler
end

-- The player at the centre: a gold diamond with a white dot at its tip, the whole marker turned to
-- the camera's yaw by refreshHeading so the dot shows which way the player faces.
local function buildPlayerMarker(face: Frame)
	local marker = Builder.frame({
		parent = face,
		name = "Player",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(PLAYER_SIZE, PLAYER_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = 7,
	})
	local diamond = Builder.frame({
		parent = marker,
		name = "Diamond",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(PLAYER_DIAMOND, PLAYER_DIAMOND),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 7,
	})
	diamond.Rotation = 45
	Builder.pill({
		parent = marker,
		name = "Tip",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(PLAYER_TIP, PLAYER_TIP),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.White,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 8,
	})
	playerMarker = marker
end

-- Public API -------------------------------------------------------------

-- Creates the ScreenGui once, hidden. SetTier and SetVisible decide when it shows.
function Radar.Build()
	if gui then
		return
	end
	local root = Builder.screen("Radar", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	-- A square under the shower chip: RADAR_WIDTH of the screen wide, and as tall as that is in pixels.
	local square = Builder.frame({
		parent = root,
		name = "Holder",
		position = UDim2.fromScale(SLOT_X, SLOT_TOP),
		size = UDim2.fromScale(RADAR_WIDTH, 1),
		anchor = Vector2.new(1, 0),
		aspect = 1,
	})
	holder = square
	local face = buildDisc(square)
	disc = face
	buildMarkers(face)
	buildPlayerMarker(face)

	-- The disc's height in Scale follows the viewport's aspect, so the column under it must follow too.
	table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(notifyLayout))
	table.insert(connections, square:GetPropertyChangedSignal("AbsoluteSize"):Connect(notifyLayout))
	table.insert(connections, State.OnChanged("codex", readKnown))
	readKnown()
	applyShown()
end

-- The radar tier the server says the player holds (profile.gear.radar): 0 hides the minimap, 1 and
-- up show it with that tier's range (clamped to the highest tier in the data).
function Radar.SetTier(next: number)
	if next ~= next then
		next = 0
	end
	local clamped = math.clamp(math.floor(next), 0, maxTier)
	local gained = clamped >= 1 and tier < 1
	tier = clamped
	local row = tiers[clamped]
	range = if row then row.range else 0
	local label = rangeLabel
	if label then
		label.Text = Strings.RADAR_RANGE:format(math.floor(range / 2))
	end
	applyShown()
	local face = disc
	if gained and shown and face then
		Builder.pop(face, 1.1) -- the disc, not the holder: a scale on the holder would move the layout
	end
	if shown then
		refreshBlips() -- the range changed, so re-place everything now rather than on the next tick
	end
end

-- The bootstrap hides the minimap during a capture, a reveal or an open panel, like the Nearby panel.
function Radar.SetVisible(show: boolean)
	visible = show
	applyShown()
end

function Radar.IsShown(): boolean
	return shown
end

-- A tap on an alien blip hands its wild part over; the bootstrap sets the waypoint.
function Radar.OnBlipTapped(callback: (part: Part) -> ())
	onBlipTapped = callback
end

-- Called with the disc's bottom edge in screen Scale plus a gap while the minimap shows, or the slot's
-- top (the Nearby column's default) while hidden, whenever that changes: shown or hidden, a tier
-- change, a viewport resize. Fires once on registration with the current value.
function Radar.OnLayout(callback: (bottom: number) -> ())
	onLayout = callback
	lastBottom = nil
	notifyLayout()
end

-- Stops the loop, drops every connection and destroys the ScreenGui; Build may run again afterwards.
function Radar.Stop()
	stopTicking()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	shown = false
	blips = {}
	holder = nil
	disc = nil
	rangeLabel = nil
	playerMarker = nil
	campMarker = nil
	peddlerMarker = nil
	local root = gui
	gui = nil
	if root then
		root:Destroy()
	end
	notifyLayout()
end

return Radar
