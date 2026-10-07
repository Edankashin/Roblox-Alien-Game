--!strict
-- StarterPlayerScripts.Client.UI.Compass: the compass strip (data/Compass, UI Playbook "Event banner
-- and compass"). A thin navy band along the top edge, centred above the HUD's ship bar: the four
-- cardinal letters and tick marks slide along it as the camera turns, a small dark pill at the centre
-- reads the heading in whole degrees, and one coloured diamond per data marker (the camp, the
-- waypoint, the radar target, the Peddler, the landmarks) sits at its bearing. One line under the
-- band names the marker the player is heading for and its flat distance ("Camp 42m").
-- Bearings agree with the Radar minimap: world -Z is north (0), +X is east (90), clockwise, taken
-- from the camera's look yaw. A thing `delta` degrees from the heading sits at x = 0.5 + delta /
-- FieldOfViewDegrees and is hidden beyond half the field of view; near either end it fades.
-- Client-only and pure presentation: it reads positions the world renderers already hold (and the
-- waypoint's) and draws; it never decides what is worth marking. Every number lives in data/Compass.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local CompassData = require(Shared:WaitForChild("data"):WaitForChild("Compass"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local World = script.Parent.Parent:WaitForChild("World")
local CampRenderer = require(World:WaitForChild("CampRenderer"))
local LandmarkRenderer = require(World:WaitForChild("LandmarkRenderer"))
local PeddlerRenderer = require(World:WaitForChild("PeddlerRenderer"))
local Waypoint = require(World:WaitForChild("Waypoint"))

local Compass = {}

-- One thing on the strip: a tick, a cardinal letter or a marker diamond.
type Item = {
	object: GuiObject,
	text: TextLabel?, -- set for a letter: its fade is TextTransparency, not BackgroundTransparency
	stroke: UIStroke?, -- the outline that fades with it
	bearing: number, -- degrees, north 0, clockwise; ticks and letters only (a diamond's comes from its marker)
}

local DISPLAY_ORDER = 10 -- the HUD's layer
local WORLD_FOLDER = "World" -- Workspace.World, made by the server
local SIGHTINGS_FOLDER = "Sightings" -- Workspace.World.Sightings: the Warden's walking part sits here while a sighting runs

-- Layout, in screen Scale (the strip) and strip Scale (what is inside it).
local STRIP_TOP = 0.006 -- the strip hugs the top edge; the HUD's centre column starts under it
local STRIP_H = 0.04 -- about 15 px on a phone in landscape, so the 14 px minimum text fits the band
local STRIP_W = CompassData.StripWidth -- clear of the round top buttons beside the clock chip: the Hud lays them out around it
local LABEL_H = 0.022 -- the line under the strip fills the gap above the HUD's shifted ship bar
local TRACK_INSET = 0.03 -- of the strip's width: bearings map inside this margin, so a thing on the rounded end still sits in the band
local LETTER_W = 0.08 -- a cardinal letter's box
local TICK_W = 0.003
local TICK_H = 0.3
local MAJOR_TICK_H = 0.5
local DIAMOND_SIZE = 0.55 -- the square's side, of the strip's height; turned 45 degrees its corners reach about 0.78
local HEADING_H = 0.8
local HEADING_W = 0.3 -- the heading pill's width bound; its aspect constraint derives the width from the height
local HEADING_ASPECT = 2.4
local HEADING_TEXT = Vector2.new(0.9, 0.8) -- the number's box inside the pill

-- Layers inside the strip (Sibling z-order): the heading pill covers ticks and letters, but a diamond
-- always shows over it, so a marker dead ahead is never hidden.
local Z_TICK = 1
local Z_LETTER = 2
local Z_HEADING = 3
local Z_DIAMOND = 4 -- plus how far the marker's priority number is below the highest, so the lowest number is on top

local FULL_TURN = 360
local CARDINAL_STEP = 90 -- N, E, S, W
local LOOK_EPSILON = 1e-6 -- a look this close to straight up or down has no yaw

local localPlayer = Players.LocalPlayer

local gui: ScreenGui? = nil
local fixed: { Item } = {} -- ticks and letters
local diamonds: { Item } = {} -- one per CompassData.Markers row, same order
local headingLabel: TextLabel? = nil
local lineLabel: TextLabel? = nil
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local heading = 0 -- degrees, 0 to 360; kept while the camera looks straight up or down
local headingShown = -1
local visible = false -- the bootstrap's SetVisible: captures, reveals, open panels and cinematics hide it
local targetPart: Part? = nil -- the alien marked from the radar (SetTarget)
local shownDistance: { [number]: number } = {} -- by marker index: flat studs, only for a marker on the strip this refresh
local shownName: { [number]: string } = {}
local lineIndex: number? = nil -- the marker the line names
local lineSince = 0 -- os.clock() when the line took it

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

-- A marker's Theme.Colors or Theme.Rarity key to a colour.
local function colorOf(key: string): Color3
	local colors: { [string]: Color3 } = Theme.Colors
	local rarity: { [string]: Color3 } = Theme.Rarity
	return colors[key] or rarity[key] or Theme.Colors.White
end

-- Degrees from the heading to a bearing, wrapped to -180 .. 180 (negative is left of the heading).
local function deltaFrom(bearing: number): number
	return (bearing - heading + FULL_TURN / 2) % FULL_TURN - FULL_TURN / 2
end

-- North (-Z) is 0, east (+X) is 90, clockwise: the Radar's convention.
local function bearingOf(dx: number, dz: number): number
	return math.deg(math.atan2(dx, -dz))
end

-- Transparency for a thing at x (0 to 1 across the field of view): clear through the middle, fading up
-- to MarkerFadeMax toward either end, within EdgeFade of it.
local function fadeAt(x: number): number
	local edge = math.max(0, math.min(x, 1 - x))
	if edge >= CompassData.EdgeFade then
		return 0
	end
	return (1 - edge / CompassData.EdgeFade) * CompassData.MarkerFadeMax
end

-- The fields are typed through this constructor so a Frame or TextLabel passes as the GuiObject.
local function newItem(object: GuiObject, text: TextLabel?, stroke: UIStroke?, bearing: number): Item
	return { object = object, text = text, stroke = stroke, bearing = bearing }
end

local function fade(item: Item, transparency: number)
	local text = item.text
	if text then
		text.TextTransparency = transparency
	else
		item.object.BackgroundTransparency = transparency
	end
	local stroke = item.stroke
	if stroke then
		stroke.Transparency = transparency
	end
end

-- Puts an item `delta` degrees from the heading, or hides it beyond half the field of view.
-- Returns whether it is on the strip.
local function placeItem(item: Item, delta: number): boolean
	local field = CompassData.FieldOfViewDegrees
	if math.abs(delta) > field / 2 then
		item.object.Visible = false
		return false
	end
	local x = 0.5 + delta / field
	item.object.Position = UDim2.fromScale(TRACK_INSET + x * (1 - 2 * TRACK_INSET), 0.5)
	fade(item, fadeAt(x))
	item.object.Visible = true
	return true
end

-- Workspace.World.Sightings, or nil while the server has not made it (no world yet, or a place with no sightings).
local function sightingsFolder(): Instance?
	local world = Workspace:FindFirstChild(WORLD_FOLDER)
	return if world then world:FindFirstChild(SIGHTINGS_FOLDER) else nil
end

-- Where a marker stands in the world, and the waypoint's own label when it is the waypoint; nil
-- position while the marker has no place (no landmark yet, no visit, no waypoint, no target).
local function markerPlace(marker: CompassData.Marker): (Vector3?, string?)
	local kind = marker.kind
	if kind == "camp" then
		return CampRenderer.ShipPosition(), nil
	elseif kind == "landmark" then
		local id = marker.landmarkId
		return (if id then LandmarkRenderer.Position(id) else nil), nil
	elseif kind == "peddler" then
		return (if PeddlerRenderer.IsVisiting() then PeddlerRenderer.Position() else nil), nil
	elseif kind == "waypoint" then
		return Waypoint.Target()
	end
	local part = targetPart
	if not (part and part.Parent) then
		return nil, nil
	end
	local at = part.Position
	-- A part under the Sightings folder is the Warden walking the land, not a radar-marked alien: its own name.
	local sightings = sightingsFolder()
	local label = if sightings and part.Parent == sightings then Strings.COMPASS_SIGHTING else nil
	-- A radar-marked alien also gets the waypoint: when the waypoint already points here, one diamond
	-- (the waypoint's, which carries the alien's name on the line), not two on top of each other.
	local waypointAt = Waypoint.Target()
	if waypointAt and (Vector3.new(at.X, 0, at.Z) - Vector3.new(waypointAt.X, 0, waypointAt.Z)).Magnitude < CompassData.SameSpotStuds then
		return nil, nil
	end
	return at, label
end

-- Refresh ------------------------------------------------------------------

local function readHeading()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local look = camera.CFrame.LookVector
	if look.X * look.X + look.Z * look.Z < LOOK_EPSILON then
		return
	end
	heading = bearingOf(look.X, look.Z) % FULL_TURN
	local degrees = math.floor(heading + 0.5) % FULL_TURN
	local label = headingLabel
	if label and degrees ~= headingShown then
		headingShown = degrees
		label.Text = Strings.COMPASS_HEADING:format(degrees)
	end
end

-- Places every diamond and picks the marker the line names. A marker is shown when the player is far
-- enough (and, with a maxDistance, near enough) and it is within the strip's field of view. The line
-- takes the lowest priority number, the nearest of equals, and keeps its marker for LabelHoldSeconds
-- before switching (at once when that marker leaves the strip).
local function refreshMarkers()
	local at = rootPosition()
	local best: number? = nil
	for index, marker in ipairs(CompassData.Markers) do
		local item = diamonds[index]
		shownDistance[index] = nil
		shownName[index] = nil
		local position, waypointLabel = markerPlace(marker)
		local onStrip = false
		if at and position then
			local dx = position.X - at.X
			local dz = position.Z - at.Z
			local distance = math.sqrt(dx * dx + dz * dz)
			local near = distance >= marker.minDistance
			local far = marker.maxDistance > 0 and distance > marker.maxDistance
			if near and not far then
				onStrip = placeItem(item, deltaFrom(bearingOf(dx, dz)))
				if onStrip then
					shownDistance[index] = distance
					shownName[index] = waypointLabel or Builder.text(marker.labelKey)
					-- The target diamond borrows the Legendary colour while it points at a walking Warden.
					if marker.kind == "target" then
						item.object.BackgroundColor3 = if waypointLabel == Strings.COMPASS_SIGHTING then Theme.Rarity.Legendary else colorOf(marker.color)
					end
					local rival = if best then CompassData.Markers[best] else nil
					local rivalDistance = if best then shownDistance[best] else nil
					if
						not rival
						or not rivalDistance
						or marker.priority < rival.priority
						or (marker.priority == rival.priority and distance < rivalDistance)
					then
						best = index
					end
				end
			end
		end
		if not onStrip then
			item.object.Visible = false
		end
	end

	local now = os.clock()
	local held = lineIndex
	if held ~= nil and shownDistance[held] == nil then
		held = nil
	end
	if best ~= nil and held ~= best and (held == nil or now - lineSince >= CompassData.LabelHoldSeconds) then
		held = best
		lineSince = now
	end
	lineIndex = held

	local line = lineLabel
	if not line then
		return
	end
	local distance = if held then shownDistance[held] else nil
	local name = if held then shownName[held] else nil
	if distance and name then
		local text = Strings.COMPASS_LABEL:format(name, math.floor(distance))
		if line.Text ~= text then
			line.Text = text
		end
		line.Visible = true
	else
		line.Visible = false
	end
end

local function refresh()
	readHeading()
	for _, item in ipairs(fixed) do
		placeItem(item, deltaFrom(item.bearing))
	end
	refreshMarkers()
end

local function startTicking()
	if heartbeat then
		return
	end
	accumulator = CompassData.UpdateSeconds -- place everything on the first frame
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < CompassData.UpdateSeconds then
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

-- Build --------------------------------------------------------------------

local function buildTicks(band: Frame)
	for bearing = 0, FULL_TURN - 1, CompassData.TickEveryDegrees do
		if bearing % CARDINAL_STEP ~= 0 then -- a letter takes the place of the tick at N, E, S and W
			local major = bearing % CompassData.MajorTickEveryDegrees == 0
			local frame = Builder.frame({
				parent = band,
				name = "Tick",
				size = UDim2.fromScale(TICK_W, if major then MAJOR_TICK_H else TICK_H),
				anchor = Vector2.new(0.5, 0.5),
				color = Theme.Colors.White,
				zIndex = Z_TICK,
			})
			frame.Visible = false
			table.insert(fixed, newItem(frame, nil, nil, bearing))
		end
	end
end

local function buildLetters(band: Frame)
	local letters = { Strings.COMPASS_N, Strings.COMPASS_E, Strings.COMPASS_S, Strings.COMPASS_W }
	for index, letter in ipairs(letters) do
		local label = Builder.label({
			parent = band,
			name = "Cardinal_" .. letter,
			text = letter,
			textSize = Theme.TextSize.Min,
			size = UDim2.fromScale(LETTER_W, 1),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Z_LETTER,
		})
		label.Visible = false
		table.insert(fixed, newItem(label, label, label:FindFirstChildOfClass("UIStroke"), (index - 1) * CARDINAL_STEP))
	end
end

-- The heading in whole degrees, in a small dark pill at the centre of the band.
local function buildHeading(band: Frame)
	local pill = Builder.pill({
		parent = band,
		name = "Heading",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(HEADING_W, HEADING_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Builder.darker(Theme.Colors.Trough),
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = HEADING_ASPECT,
		zIndex = Z_HEADING,
	})
	headingLabel = Builder.label({
		parent = pill,
		name = "Degrees",
		text = Strings.COMPASS_HEADING:format(0),
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(HEADING_TEXT.X, HEADING_TEXT.Y),
		anchor = Vector2.new(0.5, 0.5),
	})
end

-- One diamond per data marker: a square on its point in the marker's colour with the outline stroke.
-- The lowest priority number is on top where two overlap (the waypoint over the radar target when
-- both stand on the same alien).
local function buildDiamonds(band: Frame)
	local maxPriority = 0
	for _, marker in ipairs(CompassData.Markers) do
		maxPriority = math.max(maxPriority, marker.priority)
	end
	for _, marker in ipairs(CompassData.Markers) do
		local frame = Builder.frame({
			parent = band,
			name = "Marker_" .. marker.id,
			size = UDim2.fromScale(1, DIAMOND_SIZE),
			anchor = Vector2.new(0.5, 0.5),
			color = colorOf(marker.color),
			aspect = 1,
			zIndex = Z_DIAMOND + maxPriority - marker.priority,
		})
		frame.Rotation = 45
		frame.Visible = false
		local stroke = Builder.stroke(frame, Theme.Stroke.Text, Theme.Colors.Outline)
		table.insert(diamonds, newItem(frame, nil, stroke, 0))
	end
end

-- Public API -------------------------------------------------------------

-- Builds the strip once, hidden; SetVisible decides when it shows (and runs it).
function Compass.Start()
	if gui then
		return
	end
	local root = Builder.screen("Compass", DISPLAY_ORDER)
	root.Enabled = visible
	gui = root

	local band = Builder.pill({
		parent = root,
		name = "Strip",
		position = UDim2.fromScale(0.5, STRIP_TOP),
		size = UDim2.fromScale(STRIP_W, STRIP_H),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
	})
	Builder.gradient(band, Theme.Colors.Trough)
	buildTicks(band)
	buildLetters(band)
	buildHeading(band)
	buildDiamonds(band)

	local line = Builder.label({
		parent = root,
		name = "Line",
		text = "",
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, STRIP_TOP + STRIP_H),
		size = UDim2.fromScale(STRIP_W, LABEL_H),
		anchor = Vector2.new(0.5, 0),
	})
	line.Visible = false
	lineLabel = line

	if visible then
		startTicking()
	end
end

-- Shown unless the bootstrap hides the HUD extras (a capture, a reveal, an open panel, a cinematic);
-- the refresh loop runs only while shown.
function Compass.SetVisible(value: boolean)
	visible = value
	local root = gui
	if not root then
		return
	end
	if root.Enabled ~= value then
		root.Enabled = value
	end
	if value then
		startTicking()
	else
		stopTicking()
	end
end

-- The wild part a tapped radar blip marked, or nil once it is cleared; the "target" marker shows
-- while the part has a parent. A part under Workspace.World.Sightings (the Warden walking the land) is
-- marked too and named COMPASS_SIGHTING on the line.
function Compass.SetTarget(part: Part?)
	targetPart = part
end

-- The part SetTarget last set, nil when none. A target whose part has been destroyed is still returned
-- (its Parent is nil), so a caller can tell "that part went" from "nothing was marked".
function Compass.GetTarget(): Part?
	return targetPart
end

return Compass
