--!strict
-- StarterPlayerScripts.Client.World.CompanionRenderer: the aliens that follow each player, drawn locally for
-- every client. The server decides who follows whom (Services/Companions) and pushes a CompanionsSnapshot per
-- owner (CompanionsChanged to every client, GetAllCompanions for a late joiner); this module only turns those
-- rows into parts and models under a client-made Workspace.ClientCompanions folder (made with Instance.new on
-- the client, so nothing here replicates and no server part exists for a companion). It never decides who
-- follows, what a companion does for its owner, or any outcome.
-- Look: the species mesh (World.Models) at Companions.Scale times the size band's scale times the growth
-- stage's, or the species placeholder shape at the same scale when no mesh was imported. An invisible anchor
-- part as tall as the alien carries the nameplate (the species name, inside Config.NameplateDistance) and the
-- placement, the way CampRenderer's workers do. Every part is anchored with collisions, queries and touches
-- off, so capture raycasts and PartAtScreenPoint never hit a companion.
-- Following (one RenderStepped connection): the i-th of n followers of an owner aims at a spot behind the
-- owner's HumanoidRootPart, spread across an arc, on the ground a downward raycast finds there (characters, the
-- companion and wild visuals and the server's wild parts are ignored; the character's feet height is the
-- fallback). It closes Companions.FollowLerp of the remaining distance per 60 Hz frame, snaps to the spot past
-- Companions.CatchUpDistance (a teleport, a world change), turns toward where it is travelling or, once caught
-- up, toward the owner's look direction, and bobs on its own phase with its feet on the ground at the low point.
-- Culling: the local player's followers are always drawn; another owner's are drawn only while that owner is
-- within Companions.RenderDistance of the camera and fit, nearest owners first, inside Companions.MaxRendered.
-- A hidden follower keeps its record, is parented to nil, and snaps to its spot when it is drawn again.
-- Riding: a snapshot's `riding` uid names the follower its owner rides. That mount leaves the arc (the others
-- spread as if it were not there, so nobody leaves a gap), is put under the rider's feet every frame with no lerp
-- and no bob (the server already lifts the rider's HipHeight by the seat height, so the mount sits on the ground
-- under the lifted character), faces the owner's flat look direction and hides its nameplate, since the rider's
-- own name is above it. A riding change never rebuilds the model; on dismount the follower is already placed, so
-- the follow code above lerps it back into the arc from where it stands.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Growth = require(Shared:WaitForChild("Growth"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Companions = require(Shared:WaitForChild("data"):WaitForChild("Companions"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Models = require(script.Parent:WaitForChild("Models"))

local CompanionRenderer = {}

local FOLDER_NAME = "ClientCompanions" -- client-made Workspace folder for every follower's parts and meshes
local WILD_VISUAL_FOLDER = "ClientWild" -- WildRenderer's mesh folder, ignored by the ground raycast
local WORLD_FOLDER = "World" -- Workspace.World, which holds the server's Wild parts
local WILD_FOLDER = "Wild" -- Workspace.World.Wild: hovering server parts a follower must not stand on
local PLATE_LIFT = 1.2 -- studs between the top of the alien (plus its bob) and its nameplate, as in the other renderers
local EVALUATE_SECONDS = 0.5 -- how often culling is judged between snapshots
local FRAME_RATE = 60 -- the frame rate Companions.FollowLerp is a per-frame fraction at

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

type Follower = {
	uid: string,
	species: string,
	size: string, -- the size band id it is drawn at (data/Sizes)
	stage: string, -- the growth stage id it is drawn at (data/Growth)
	part: Part, -- the placeholder, or an invisible anchor as tall as the mesh that carries the plate
	plate: BillboardGui, -- the nameplate on `part`, hidden while this follower is ridden
	model: Model?, -- the mesh clone when the species has one
	height: number, -- studs from the feet to the top of what is drawn
	upright: CFrame, -- the roll that stands a placeholder cylinder up; identity otherwise
	phase: number, -- bob phase
	feet: Vector3, -- where its feet rest on the ground, before the bob
	turn: CFrame, -- its facing, an orientation with no position
	placed: boolean, -- false until it has been put at its spot since it was last hidden
	shown: boolean, -- parented under the folder
}

type Owner = {
	userId: number,
	followers: { Follower }, -- in slot order, which is the order of the arc
	riding: string?, -- the uid of the follower the owner rides (it leaves the arc), nil on foot
}

local localPlayer = Players.LocalPlayer
local rng = Random.new()

local running = false
local folder: Folder? = nil
local owners: { [number]: Owner } = {}
local eventSeen: { [number]: boolean } = {} -- owners a pushed snapshot has already described
local lastEvaluate = -math.huge
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Lookups --------------------------------------------------------------------

local function rootOf(userId: number): BasePart?
	local player = Players:GetPlayerByUserId(userId)
	local character = if player then player.Character else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- The Y of the ground at `spot`: the first surface under a point one root-height above it (so a slope
-- rising behind the character does not swallow the origin), or the bottom of the character's feet.
local function groundAt(spot: Vector3, root: BasePart, hipHeight: number): number
	local fallback = root.Position.Y - hipHeight - root.Size.Y / 2
	local origin = Vector3.new(spot.X, spot.Y + root.Size.Y, spot.Z)
	local reach = origin.Y - Workspace.FallenPartsDestroyHeight
	if reach <= 0 then
		return fallback
	end
	local hit = Workspace:Raycast(origin, Vector3.new(0, -reach, 0), rayParams)
	if hit then
		return hit.Position.Y
	end
	return fallback
end

-- Everything a follower's ground ray must pass through: every character (the owner's body, other
-- players), this module's folder, WildRenderer's mesh folder and the server's hovering Wild parts.
local function refreshFilter()
	local excluded: { Instance } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	if folder then
		table.insert(excluded, folder)
	end
	local wildVisuals = Workspace:FindFirstChild(WILD_VISUAL_FOLDER)
	if wildVisuals then
		table.insert(excluded, wildVisuals)
	end
	local world = Workspace:FindFirstChild(WORLD_FOLDER)
	local wild = if world then world:FindFirstChild(WILD_FOLDER) else nil
	if wild then
		table.insert(excluded, wild)
	end
	rayParams.FilterDescendantsInstances = excluded
end

-- Building ---------------------------------------------------------------------

local function newPart(name: string, shape: Enum.PartType, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- The species name over the alien, Fredoka One and outlined through Builder, shown inside NameplateDistance.
-- `height` is the studs from the feet to the top of what is drawn; the part bobs, so the plate rides with it.
local function buildPlate(part: Part, name: string, height: number): BillboardGui
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 1) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, height / 2 + Companions.BobStuds + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = name,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 1),
	})
	plate.Parent = part
	return plate
end

-- One follower's parts, hidden (parent nil) until culling draws it. `from` is the follower this one replaces
-- (its growth stage moved), whose place, facing and bob phase it keeps.
local function build(row: Types.CompanionRow, def: Types.SpeciesDef, from: Follower?): Follower
	local band = Sizes.ById[row.size] or Sizes.ById[Sizes.Default]
	local stage = Growth.StageAt(row.workedSeconds)
	local grown = 1 + stage.scaleBonus
	local model: Model? = Models.Clone(def, Companions.Scale * band.scale * grown)
	local part: Part
	local height: number
	local upright = CFrame.identity
	if model then
		-- The mesh's pivot is its bottom centre; the invisible anchor is as tall as the mesh, centred on it.
		height = Models.Height(model)
		part = newPart(row.uid, Enum.PartType.Block, Vector3.one * height, Color3.fromHex(def.placeholder.color))
		part.Transparency = 1
		model.Name = row.uid .. "Model"
	else
		height = 2 * def.placeholder.scale * Companions.Scale * band.scale * grown
		part = newPart(
			row.uid,
			SHAPES[def.placeholder.shape] or Enum.PartType.Ball,
			Vector3.one * height,
			Color3.fromHex(def.placeholder.color)
		)
		if def.placeholder.shape == "Cylinder" then
			upright = CFrame.Angles(0, 0, math.rad(90)) -- stand it upright, as CampRenderer does
		end
	end
	local plate = buildPlate(part, def.name, height)
	return {
		uid = row.uid,
		species = row.species,
		size = row.size,
		stage = stage.id,
		part = part,
		plate = plate,
		model = model,
		height = height,
		upright = upright,
		phase = if from then from.phase else rng:NextNumber(0, math.pi * 2),
		feet = if from then from.feet else Vector3.zero,
		turn = if from then from.turn else CFrame.identity,
		placed = if from then from.placed else false,
		shown = false,
	}
end

local function setShown(follower: Follower, shown: boolean)
	local parent = folder
	if follower.shown == shown or not parent then
		return
	end
	follower.shown = shown
	local model = follower.model
	if shown then
		follower.part.Parent = parent
		if model then
			model.Parent = parent
		end
	else
		follower.part.Parent = nil
		if model then
			model.Parent = nil
		end
		follower.placed = false -- it snaps to its spot when it is drawn again
	end
end

local function destroyFollower(follower: Follower)
	follower.part:Destroy()
	local model = follower.model
	if model then
		model:Destroy()
	end
end

local function clearOwner(userId: number)
	local owner = owners[userId]
	eventSeen[userId] = nil
	if not owner then
		return
	end
	owners[userId] = nil
	for _, follower in ipairs(owner.followers) do
		destroyFollower(follower)
	end
end

-- Snapshots ---------------------------------------------------------------------

local function isRow(value: any): boolean
	return type(value) == "table"
		and type(value.uid) == "string"
		and type(value.species) == "string"
		and type(value.size) == "string"
		and type(value.workedSeconds) == "number"
end

local function isSnapshot(value: any): boolean
	return type(value) == "table" and type(value.userId) == "number" and type(value.rows) == "table"
end

-- A snapshot replaces its owner's whole list. A follower whose uid, species, size band and growth stage are
-- unchanged keeps its model and its place; a changed one is rebuilt where it stood; a missing one is destroyed.
-- A row whose species is unknown is skipped. The `riding` uid is only kept: which follower is the mount is read
-- per frame, so a riding change never rebuilds a model, and a uid that matches no follower leaves everyone in the arc.
local function apply(snapshot: Types.CompanionsSnapshot)
	local userId = snapshot.userId
	local riding: string? = snapshot.riding
	if type(riding) ~= "string" then
		riding = nil
	end
	local owner = owners[userId]
	local existing: { [string]: Follower } = {}
	if owner then
		for _, follower in ipairs(owner.followers) do
			existing[follower.uid] = follower
		end
	end
	local ordered: { Follower } = {}
	local seen: { [string]: boolean } = {}
	for _, row in ipairs(snapshot.rows) do
		local def: Types.SpeciesDef? = if isRow(row) then Species.ById[row.species] else nil
		if not def or seen[row.uid] then
			continue
		end
		seen[row.uid] = true
		local stage = Growth.StageAt(row.workedSeconds).id
		local kept = existing[row.uid]
		if kept and kept.species == row.species and kept.size == row.size and kept.stage == stage then
			existing[row.uid] = nil
			table.insert(ordered, kept)
		else
			local replacement = build(row, def, kept)
			if kept then
				existing[row.uid] = nil
				local wasShown = kept.shown
				destroyFollower(kept)
				if wasShown then
					setShown(replacement, true)
				end
			end
			table.insert(ordered, replacement)
		end
	end
	for _, gone in pairs(existing) do
		destroyFollower(gone)
	end
	if #ordered == 0 then
		owners[userId] = nil
	else
		owners[userId] = { userId = userId, followers = ordered, riding = riding }
	end
	lastEvaluate = -math.huge -- judge culling on the next frame, not in up to EVALUATE_SECONDS
end

-- Culling ----------------------------------------------------------------------

-- Decides which owners' followers are drawn: the local player's always, then the owners within RenderDistance
-- of the camera, nearest first, while a whole owner still fits under MaxRendered. Hidden followers are parented
-- to nil; the owner needs a character either way, since a follower with no root has nowhere to stand.
local function evaluate(now: number)
	lastEvaluate = now
	local camera = Workspace.CurrentCamera
	local budget = Companions.MaxRendered
	local drawn: { [Owner]: boolean } = {}
	local candidates: { { owner: Owner, distance: number } } = {}
	for userId, owner in pairs(owners) do
		if userId == localPlayer.UserId then
			drawn[owner] = true
			budget -= #owner.followers
		else
			local root = rootOf(userId)
			if root and camera then
				local distance = (root.Position - camera.CFrame.Position).Magnitude
				if distance <= Companions.RenderDistance then
					table.insert(candidates, { owner = owner, distance = distance })
				end
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)
	for _, candidate in ipairs(candidates) do
		local count = #candidate.owner.followers
		if count <= budget then
			drawn[candidate.owner] = true
			budget -= count
		end
	end
	local localHasRoot = rootOf(localPlayer.UserId) ~= nil
	for userId, owner in pairs(owners) do
		local visible = drawn[owner] == true
		for _, follower in ipairs(owner.followers) do
			-- The local player's followers stay drawn through a respawn, but one that was never put anywhere
			-- waits for the character instead of showing at the origin.
			local wanted = visible and (userId ~= localPlayer.UserId or follower.shown or localHasRoot)
			setShown(follower, wanted)
		end
	end
end

-- Following --------------------------------------------------------------------

-- The direction a follower should face: where it is travelling once it is farther than FaceTravelStuds from its spot,
-- else the owner's look direction, else wherever it already faces.
local function faceDirection(follower: Follower, travel: Vector3, ownerLook: Vector3?): Vector3
	if travel.Magnitude > Companions.FaceTravelStuds then
		return travel
	end
	if ownerLook then
		return ownerLook
	end
	return follower.turn.LookVector
end

-- Puts a follower's parts at its feet and facing; `bob` lifts the feet (0 for a ridden mount).
local function place(follower: Follower, bob: number)
	local pivot = CFrame.new(follower.feet + Vector3.new(0, bob, 0)) * follower.turn
	follower.part.CFrame = pivot * CFrame.new(0, follower.height / 2, 0) * follower.upright
	local model = follower.model
	if model then
		model:PivotTo(pivot)
	end
end

local function onRender(dt: number)
	local now = os.clock()
	if now - lastEvaluate >= EVALUATE_SECONDS then
		evaluate(now)
	end
	local alpha = 1 - (1 - Companions.FollowLerp) ^ (dt * FRAME_RATE)
	local omega = math.pi * 2 * Companions.BobHz
	local filterReady = false
	for userId, owner in pairs(owners) do
		local followers = owner.followers
		local mountUid = owner.riding
		local anyShown = false
		local count = 0 -- the arc's size: every follower but the mount
		for _, follower in ipairs(followers) do
			if follower.shown then
				anyShown = true
			end
			if follower.uid ~= mountUid then
				count += 1
			end
		end
		local root = if anyShown then rootOf(userId) else nil
		if not root then
			continue
		end
		if not filterReady then
			filterReady = true
			refreshFilter()
		end
		local character = root.Parent
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local hipHeight = if humanoid then humanoid.HipHeight else 0
		local rootFrame = root.CFrame
		local look = rootFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		local ownerLook: Vector3? = if flatLook.Magnitude > 0 then flatLook.Unit else nil
		local ground = root.Position - Vector3.new(0, root.Size.Y / 2 + hipHeight, 0) -- under the (lifted) rider
		local arcIndex = 0
		for _, follower in ipairs(followers) do
			local ridden = follower.uid == mountUid
			if not ridden then
				arcIndex += 1
			end
			if not follower.shown then
				continue
			end
			follower.plate.Enabled = not ridden
			if ridden then
				-- The mount moves with the character exactly: no lerp, no bob. It stays placed, so a dismount
				-- lerps it back into the arc from here (or snaps it past CatchUpDistance).
				follower.feet = ground
				follower.placed = true
				if ownerLook then
					follower.turn = CFrame.lookAt(Vector3.zero, ownerLook)
				end
				place(follower, 0)
				continue
			end
			local spot = (rootFrame * CFrame.new((arcIndex - (count + 1) / 2) * Companions.FollowSpacing, 0, Companions.FollowDistance)).Position
			local target = Vector3.new(spot.X, groundAt(spot, root, hipHeight), spot.Z)
			local remaining = target - follower.feet
			local travel = Vector3.zero
			if not follower.placed or remaining.Magnitude > Companions.CatchUpDistance then
				follower.feet = target
				follower.placed = true
				follower.turn = CFrame.lookAt(Vector3.zero, faceDirection(follower, travel, ownerLook))
			else
				follower.feet += remaining * alpha
				travel = Vector3.new(remaining.X, 0, remaining.Z)
				local desired = CFrame.lookAt(Vector3.zero, faceDirection(follower, travel, ownerLook))
				follower.turn = follower.turn:Lerp(desired, alpha)
			end
			-- The feet rest BobStuds above the ground and swing BobStuds either way, so they touch the
			-- ground at the bob's low point and lift a little at the top, as WildRenderer's meshes do.
			local bob = Companions.BobStuds + math.sin(now * omega + follower.phase) * Companions.BobStuds
			place(follower, bob)
		end
	end
end

-- Public API -------------------------------------------------------------

-- Makes Workspace.ClientCompanions and starts drawing every player's followers: one RenderStepped connection
-- for the following and the culling, PlayerRemoving to clear a leaver, then (off the calling thread) the
-- CompanionsChanged push and a one-time GetAllCompanions for what was pushed before this client joined.
-- Safe to call once; a second call does nothing.
function CompanionRenderer.Start()
	if running then
		return
	end
	running = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created
	RunService.RenderStepped:Connect(onRender)
	Players.PlayerRemoving:Connect(function(player: Player)
		clearOwner(player.UserId)
	end)
	task.spawn(function()
		Net.event("CompanionsChanged").OnClientEvent:Connect(function(snapshot: any)
			if isSnapshot(snapshot) then
				local value = snapshot :: Types.CompanionsSnapshot
				eventSeen[value.userId] = true
				apply(value)
			end
		end)
		-- A push that landed while this call was in flight is newer than the answer, so it wins.
		local ok, result = pcall(function()
			return Net.func("GetAllCompanions"):InvokeServer()
		end)
		if not ok or type(result) ~= "table" then
			return
		end
		for _, snapshot in ipairs(result :: { any }) do
			if isSnapshot(snapshot) then
				local value = snapshot :: Types.CompanionsSnapshot
				if not eventSeen[value.userId] then
					apply(value)
				end
			end
		end
	end)
end

return CompanionRenderer
