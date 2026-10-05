--!strict
-- StarterPlayerScripts.Client.World.Waypoint: one floating marker over whatever the caller points at
-- (the tutorial's next target). A client-only invisible anchored part under Workspace.ClientWaypoint
-- (made with Instance.new on the client, so nothing here replicates) carries a BillboardGui that is
-- always on top and never culled by distance: the glyph in the Featured colour bobbing gently, the
-- label beneath in white outlined text, and under it the distance to the player's HumanoidRootPart.
-- The part follows the caller's getPosition closure every FOLLOW_SECONDS and hides while it answers
-- nil, so a target that is collected, caught or not yet spawned hands the marker on without the
-- caller doing anything. Pure presentation: nothing here decides what is pointed at.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local Waypoint = {}

local FOLLOW_SECONDS = 0.25 -- the marker re-reads its target and the distance this often
local FOLDER_NAME = "ClientWaypoint"
local LIFT_STUDS = 4 -- the billboard floats this far above the target
local BILLBOARD_SIZE = UDim2.fromScale(8, 3) -- studs
local BOB_SECONDS = 0.6 -- half a bob (down or up)
local BOB_SCALE = 0.1 -- the glyph bobs this far, in billboard height
local GLYPH_H = 0.42 -- of the billboard; the label and the distance share the rest
local LABEL_Y = 0.46
local LABEL_H = 0.32
local DISTANCE_Y = 0.78
local DISTANCE_H = 0.22

local localPlayer = Players.LocalPlayer

local part: Part? = nil
local billboard: BillboardGui? = nil
local glyph: TextLabel? = nil
local bob: Tween? = nil
local labelText: TextLabel? = nil
local distanceText: TextLabel? = nil
local shown = false
local generation = 0 -- each Show starts a new follow loop; Clear and a later Show retire the old one

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

-- Builds the part and its billboard once; later Shows reuse them.
local function ensureBuilt(): (Part, BillboardGui)
	local existingPart, existingBillboard = part, billboard
	if existingPart and existingBillboard then
		return existingPart, existingBillboard
	end

	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace

	local marker = Instance.new("Part")
	marker.Name = "Marker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Transparency = 1
	marker.Size = Vector3.one
	marker.Parent = created
	part = marker

	local gui = Instance.new("BillboardGui")
	gui.Name = "Waypoint"
	gui.Adornee = marker
	gui.Size = BILLBOARD_SIZE
	gui.StudsOffsetWorldSpace = Vector3.new(0, LIFT_STUDS, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = math.huge -- visible from anywhere on the floor
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local arrow = Builder.label({
		parent = gui,
		name = "Glyph",
		text = Strings.UI_WAYPOINT_GLYPH,
		textSize = Theme.TextSize.Reveal,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, GLYPH_H),
		anchor = Vector2.new(0.5, 0),
	})
	glyph = arrow
	bob = TweenService:Create(
		arrow,
		TweenInfo.new(BOB_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = UDim2.fromScale(0.5, BOB_SCALE) }
	)
	labelText = Builder.label({
		parent = gui,
		name = "Label",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0, LABEL_Y),
		size = UDim2.fromScale(1, LABEL_H),
	})
	distanceText = Builder.label({
		parent = gui,
		name = "Distance",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, DISTANCE_Y),
		size = UDim2.fromScale(1, DISTANCE_H),
	})
	gui.Parent = marker
	billboard = gui
	return marker, gui
end

-- Moves the marker to the target (or hides it while there is none) and refreshes the distance line.
local function follow(getPosition: () -> Vector3?)
	local marker, gui = part, billboard
	if not marker or not gui then
		return
	end
	local target = getPosition()
	if not target then
		gui.Enabled = false
		return
	end
	marker.CFrame = CFrame.new(target)
	gui.Enabled = true
	local distance = distanceText
	if distance then
		local at = rootPosition()
		if at then
			distance.Text = Strings.WAYPOINT_DISTANCE:format(math.floor((target - at).Magnitude))
			distance.Visible = true
		else
			distance.Visible = false
		end
	end
end

-- Public API -------------------------------------------------------------

-- Points the marker at whatever getPosition answers, re-read every FOLLOW_SECONDS (nil hides it),
-- with `label` under the glyph. A second Show replaces the first.
function Waypoint.Show(getPosition: () -> Vector3?, label: string)
	ensureBuilt()
	generation += 1
	local mine = generation
	shown = true
	local text = labelText
	if text then
		text.Text = label
	end
	local arrow = glyph
	if arrow then
		arrow.Position = UDim2.fromScale(0.5, 0)
	end
	local tween = bob
	if tween then
		tween:Play()
	end
	follow(getPosition)
	task.spawn(function()
		while generation == mine and shown do
			task.wait(FOLLOW_SECONDS)
			if generation == mine and shown then
				follow(getPosition)
			end
		end
	end)
end

function Waypoint.Clear()
	generation += 1
	shown = false
	local gui = billboard
	if gui then
		gui.Enabled = false
	end
	local tween = bob
	if tween then
		tween:Cancel()
	end
end

function Waypoint.IsShown(): boolean
	return shown
end

-- World lookups ------------------------------------------------------------
-- Attribute scans over the server's folders, so callers need no renderer. Non-yielding: a folder that
-- has not arrived yet simply answers nil.

-- The wild part the server reserved for the local player (ReservedFor = UserId) of the given species,
-- or nil while none stands. The tutorial's trainee aliens are placed this way.
function Waypoint.FindReservedSpawn(species: string): Part?
	local world = Workspace:FindFirstChild("World")
	local wild = if world then world:FindFirstChild("Wild") else nil
	if not wild then
		return nil
	end
	local userId = localPlayer.UserId
	for _, child in ipairs(wild:GetChildren()) do
		if child:IsA("Part") and child:GetAttribute("SpeciesId") == species and child:GetAttribute("ReservedFor") == userId then
			return child
		end
	end
	return nil
end

-- The nearest available node part (Available ~= false) yielding the given material, measured from
-- the local character, or the first one found without a character. Nil while none stands.
function Waypoint.FindNearestNode(materialId: string): Part?
	local world = Workspace:FindFirstChild("World")
	local materials = if world then world:FindFirstChild("Materials") else nil
	if not materials then
		return nil
	end
	local at = rootPosition()
	local best: Part? = nil
	local bestDistance = math.huge
	for _, child in ipairs(materials:GetChildren()) do
		if not child:IsA("Part") or child:GetAttribute("MaterialId") ~= materialId or child:GetAttribute("Available") == false then
			continue
		end
		if not at then
			return child
		end
		local distance = (child.Position - at).Magnitude
		if distance < bestDistance then
			best = child
			bestDistance = distance
		end
	end
	return best
end

-- The top surface of Workspace.World.MeadowFloor, or nil until the floor exists.
function Waypoint.FloorTop(): number?
	local world = Workspace:FindFirstChild("World")
	local floor = if world then world:FindFirstChild("MeadowFloor") else nil
	if floor and floor:IsA("BasePart") then
		return floor.Position.Y + floor.Size.Y / 2
	end
	return nil
end

return Waypoint
