--!strict
-- StarterPlayerScripts.Client.World.WildRenderer: presentation for every wild alien part under
-- Workspace.World.Wild. The server places a plain anchored part with attributes; this module adds the
-- nameplate (name + tier in its colour, visible within NameplateDistance), bobs the part locally
-- (the server never moves it, so a local CFrame does not fight replication), and renders species
-- the player has not caught as dark silhouettes until they walk within ShadowRevealDistance (only while
-- the Silhouettes preference is on, Prefs.Silhouettes; off, every alien shows in colour). A part
-- reserved for another player (ReservedFor, a summoned Warden) is hidden locally and never tracked.
-- A species with a mesh in ReplicatedStorage.Models (World.Models) is drawn as a clone of it under the
-- client-made Workspace.ClientWild folder, feet on the ground at the bob's low point, bobbing with the
-- part; the server part is then invisible locally but stays what Nearest and PartAtScreenPoint return.
-- Without a mesh the placeholder part shows exactly as before.
-- Sizes (data/Sizes): the server rolls a band per spawn and writes its id as the part's Size attribute
-- (missing means Sizes.Default). The alien is drawn at the band's `scale` on top of its own: the mesh
-- clone is built at Config.ModelWildScale * scale, and the server part (the placeholder, or the invisible
-- tap target behind a mesh) is resized locally by the same factor with its bottom held where it was, so the
-- tap target, the nameplate height and the visual always agree. A change of the attribute re-applies it.
-- The Heater rule (World 2): while State.GetConditions() holds "Blizzard", a tracked alien farther
-- (flat distance) than Config.BlizzardHideStuds from the player is hidden locally, unless it stands
-- within Radius of a lit Heater (a Part under Workspace.World.Heaters with the attributes Radius and
-- ExpiresAt, made by the server). Hidden means the server part and the mesh clone get a
-- LocalTransparencyModifier of 1 and the nameplate is disabled; a hidden alien stays tracked, so
-- Nearest still finds it (the catch distance is inside the hide distance, so a catchable alien is
-- always drawn). The state is computed in `evaluate`, on every visibility tick, on arrival and on a clock change.
-- Tier aura (data/Tiers `aura` > 0, Rare and up): a PointLight on the part in the tier colour (Brightness =
-- aura) and, once Icons.Particles.Glow is uploaded, a glow sprite behind the alien that breathes over
-- Config.VfxAuraPulseSeconds (it holds its midpoint under Reduced Motion). Both follow the hide rule with
-- the nameplate (applyVisibility) and go with the record (untrack), so a reserved spawn never has one.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Tiers = require(Shared:WaitForChild("data"):WaitForChild("Tiers"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Models = require(script.Parent:WaitForChild("Models"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local WildRenderer = {}

local VISUAL_FOLDER = "ClientWild" -- client-made Workspace folder for the mesh clones; nothing in it replicates
local PLATE_LIFT = 1.2 -- studs between the top of the alien (plus its bob) and its nameplate
local EVALUATE_SECONDS = 0.25 -- how often the blizzard hide rule is re-judged for every tracked alien
local BLIZZARD = "Blizzard" -- the condition (the world's special weather) under which the hide rule runs
local HEATER_FOLDER = "Heaters" -- Workspace.World.Heaters, made by the server's Heaters service
local AURA_LIGHT_RANGE = 14 -- studs the tier light reaches (its Brightness is the tier's aura)
local AURA_GLOW_STUDS = 6 -- the glow sprite's width and height in the world
local AURA_GLOW_DIM = 0.75 -- the glow's most transparent point in its breath
local AURA_GLOW_BRIGHT = 0.35 -- and its least; under Reduced Motion it holds the midpoint

type Record = {
	part: Part,
	species: string,
	tier: string,
	base: CFrame,
	phase: number,
	realColor: Color3,
	shadowed: boolean,
	hidden: boolean, -- the blizzard hide rule: out of sight beyond BlizzardHideStuds and outside every Heater
	plate: BillboardGui,
	nameLabel: TextLabel,
	model: Model?, -- the mesh clone when the species has one; the server part is then hidden locally
	modelBase: CFrame?, -- the clone's rest pivot: feet where the placeholder's bottom sits
	baseSize: Vector3, -- the part's Size as the server made it, before the size band
	restBase: CFrame, -- the part's CFrame as the server placed it; `base` is this raised for the band
	sizeFactor: number, -- the band scale currently applied to the part and the clone
	light: PointLight?, -- the tier aura's light (tier aura > 0)
	glow: BillboardGui?, -- the aura's glow sprite; absent until Icons.Particles.Glow is uploaded
	glowImage: ImageLabel?,
	glowTween: Tween?, -- the breathing loop; nil while still (Reduced Motion) or without a glow
}

local records: { [Part]: Record } = {}
local known: { [string]: boolean } = {}
local rng = Random.new()
local wildFolder: Folder? = nil
local visualFolder: Folder? = nil
local renderConn: RBXScriptConnection? = nil
local prefsConn: RBXScriptConnection? = nil
local clockConn: RBXScriptConnection? = nil
local blizzard = false -- State.GetConditions() holds "Blizzard"
local heaterSpots: { { x: number, z: number, radius: number } } = {} -- lit heaters as of the last evaluate
local lastEvaluate = 0
local localPlayer = Players.LocalPlayer

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

-- Where the nameplate floats above its adornee, from the distance up to the top of what the player sees.
local function plateOffset(topOffset: number): Vector3
	return Vector3.new(0, topOffset + Config.WildBobStuds + PLATE_LIFT, 0)
end

-- `topOffset` is the distance from the part's centre up to the top of what the player sees: half the
-- part for a placeholder, the mesh's top for a model (both after the size band).
local function buildPlate(part: Part, name: string, tier: string, topOffset: number): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 2) -- studs
	plate.StudsOffsetWorldSpace = plateOffset(topOffset)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	local nameLabel = Builder.label({
		parent = plate,
		name = "Name",
		text = name,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 0.55),
	})
	Builder.label({
		parent = plate,
		name = "Tier",
		text = Builder.text("TIER_" .. tier),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, 0.55),
		size = UDim2.fromScale(1, 0.45),
		color = Builder.tierColor(tier),
	})
	plate.Parent = part
	return plate, nameLabel
end

-- The band for a wild part's Size attribute; a missing or unknown id is the default band.
local function bandOf(part: Part): Sizes.Band
	local id = part:GetAttribute("Size")
	local band = if type(id) == "string" then Sizes.ById[id] else nil
	return band or Sizes.ById[Sizes.Default]
end

-- The mesh clone for a wild part, at the species' wild scale times the size band's, stood where the
-- placeholder's bottom sits. The Spawner centres the part Size.Y / 2 above WildHoverStuds over the
-- surface, so `feet` is the part's centre minus half its (unscaled) height; the facing is a random yaw
-- so a field of one species does not stand in formation.
local function buildModel(def: Types.SpeciesDef, feet: Vector3, factor: number): (Model?, CFrame?)
	local parent = visualFolder
	if not parent then
		return nil, nil
	end
	local clone = Models.Clone(def, Config.ModelWildScale * factor)
	if not clone then
		return nil, nil
	end
	local base = CFrame.new(feet) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	clone:PivotTo(base)
	clone.Parent = parent
	return clone, base
end

-- The aura of a spawn whose tier has `aura` > 0: a shadowless point light in the tier colour on the part,
-- and (sprite uploaded) a glow billboard on it. Returns nothing for a tier without an aura.
local function buildAura(part: Part, tier: string): (PointLight?, BillboardGui?, ImageLabel?)
	local def = Tiers.Tiers[tier]
	if not def or def.aura <= 0 then
		return nil, nil, nil
	end
	local color = Builder.tierColor(tier)
	local light = Instance.new("PointLight")
	light.Name = "Aura"
	light.Color = color
	light.Brightness = def.aura
	light.Range = AURA_LIGHT_RANGE
	light.Shadows = false
	light.Parent = part
	local sprite = Icons.Particles.Glow
	if sprite == 0 then
		return light, nil, nil
	end
	local glow = Instance.new("BillboardGui")
	glow.Name = "AuraGlow"
	glow.Adornee = part
	glow.Size = UDim2.fromScale(AURA_GLOW_STUDS, AURA_GLOW_STUDS) -- studs
	glow.AlwaysOnTop = false
	glow.LightInfluence = 0
	glow.ResetOnSpawn = false
	local image = Instance.new("ImageLabel")
	image.Name = "Glow"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = "rbxassetid://" .. sprite
	image.ImageColor3 = color
	image.ImageTransparency = (AURA_GLOW_DIM + AURA_GLOW_BRIGHT) / 2
	image.ScaleType = Enum.ScaleType.Fit
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = glow
	glow.Parent = part
	return light, glow, image
end

-- Starts the glow's breathing loop, or holds its midpoint under Reduced Motion. Safe to call again: a
-- loop that should keep running is left alone, so a settings change does not restart every glow.
local function setPulse(record: Record)
	local image = record.glowImage
	if not image then
		return
	end
	local still = Prefs.ReducedMotion()
	local running = record.glowTween
	if running then
		if not still then
			return
		end
		running:Cancel()
		record.glowTween = nil
	end
	if still then
		image.ImageTransparency = (AURA_GLOW_DIM + AURA_GLOW_BRIGHT) / 2
		return
	end
	image.ImageTransparency = AURA_GLOW_DIM
	-- One breath is out and back, so each way takes half the pulse.
	local info = TweenInfo.new(Config.VfxAuraPulseSeconds / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(image, info, { ImageTransparency = AURA_GLOW_BRIGHT })
	record.glowTween = tween
	tween:Play()
end

-- The Reduced Motion setting may have changed: every glow follows it.
local function applyAuraMotion()
	for _, record in pairs(records) do
		setPulse(record)
	end
end

local function applyShadow(record: Record)
	record.shadowed = true
	record.part.Color = Theme.Shadow
	record.part.Material = Enum.Material.SmoothPlastic
	local model = record.model
	if model then
		Models.SetShadow(model, true)
	end
	record.nameLabel.Text = Strings.UNKNOWN_NAME
end

local function reveal(record: Record)
	if not record.shadowed then
		return
	end
	record.shadowed = false
	local def = Species.ById[record.species]
	record.nameLabel.Text = if def then def.name else record.species
	local model = record.model
	if model then
		Models.SetShadow(model, false)
	else
		TweenService:Create(record.part, TweenInfo.new(Theme.Tween.Open * 2, Enum.EasingStyle.Quad), { Color = record.realColor }):Play()
	end
	local scale = record.plate:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 1.35
		TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

-- Blizzard hide rule ---------------------------------------------------------

local function refreshBlizzard()
	local on = false
	for _, condition in ipairs(State.GetConditions()) do
		if condition == BLIZZARD then
			on = true
			break
		end
	end
	blizzard = on
end

-- The lit heaters under Workspace.World.Heaters as flat spots. FindFirstChild only, so it never yields;
-- a heater past its ExpiresAt (server wall clock) is ignored even if its part has not been removed yet.
local function readHeaters()
	table.clear(heaterSpots)
	local world = Workspace:FindFirstChild("World")
	local folder = if world then world:FindFirstChild(HEATER_FOLDER) else nil
	if not folder then
		return
	end
	local now = State.Now()
	for _, child in ipairs(folder:GetChildren()) do
		if not child:IsA("BasePart") then
			continue
		end
		local radius = child:GetAttribute("Radius")
		local expires = child:GetAttribute("ExpiresAt")
		if type(radius) ~= "number" or (type(expires) == "number" and expires < now) then
			continue
		end
		table.insert(heaterSpots, { x = child.Position.X, z = child.Position.Z, radius = radius })
	end
end

-- Whether a point is out of sight under the current rule: during a blizzard, farther than
-- BlizzardHideStuds from the player (flat distance) and outside every lit heater's radius.
local function hiddenAt(point: Vector3, at: Vector3): boolean
	if not blizzard then
		return false
	end
	local dx, dz = point.X - at.X, point.Z - at.Z
	if math.sqrt(dx * dx + dz * dz) <= Config.BlizzardHideStuds then
		return false
	end
	for _, spot in ipairs(heaterSpots) do
		local hx, hz = point.X - spot.x, point.Z - spot.z
		if math.sqrt(hx * hx + hz * hz) <= spot.radius then
			return false
		end
	end
	return true
end

-- Draws or hides one record from its `hidden` flag: the server part (always invisible locally when a
-- mesh clone stands in for it), every part of the clone, the nameplate and the aura.
local function applyVisibility(record: Record)
	local hide = record.hidden
	record.part.LocalTransparencyModifier = if hide or record.model then 1 else 0
	local model = record.model
	if model then
		local value = if hide then 1 else 0
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = value
			end
		end
	end
	if record.plate.Parent then
		record.plate.Enabled = not hide
	end
	local light, glow = record.light, record.glow
	if light then
		light.Enabled = not hide
	end
	if glow then
		glow.Enabled = not hide
	end
end

-- Re-judges the hide rule for every tracked alien. Without a blizzard everything is shown; with no
-- character yet nothing changes.
local function evaluate()
	lastEvaluate = os.clock()
	local at = rootPosition()
	if blizzard then
		if not at then
			return
		end
		readHeaters()
	end
	for _, record in pairs(records) do
		local hide = if at then hiddenAt(record.base.Position, at) else false
		if hide ~= record.hidden then
			record.hidden = hide
			applyVisibility(record)
		end
	end
end

-- Distance from a part's centre up to the top of what the player sees: half the part for a placeholder,
-- the mesh's top for a model (its feet are the part's bottom, which the band never moves).
local function topOffsetOf(part: Part, model: Model?): number
	if model then
		return Models.Height(model) - part.Size.Y / 2
	end
	return part.Size.Y / 2
end

-- Re-reads the part's Size attribute for a tracked alien (the server may set it after the part
-- appears) and moves the part, the clone and the plate to the new band, bottom unchanged.
local function applySize(record: Record)
	local factor = bandOf(record.part).scale
	if factor == record.sizeFactor then
		return
	end
	local ratio = factor / record.sizeFactor
	record.sizeFactor = factor
	local part = record.part
	part.Size = record.baseSize * factor
	record.base = record.restBase + Vector3.new(0, (part.Size.Y - record.baseSize.Y) / 2, 0)
	local model = record.model
	if model then
		model:ScaleTo(model:GetScale() * ratio)
	end
	record.plate.StudsOffsetWorldSpace = plateOffset(topOffsetOf(part, model))
end

local function track(instance: Instance)
	if not instance:IsA("Part") or records[instance] then
		return
	end
	local species = instance:GetAttribute("SpeciesId")
	local tier = instance:GetAttribute("Tier")
	if type(species) ~= "string" or type(tier) ~= "string" then
		return
	end
	local def: Types.SpeciesDef? = Species.ById[species]
	local displayName = if def then def.name else species
	local model: Model? = nil
	local modelBase: CFrame? = nil
	-- The band scales the server part itself (the placeholder, or the tap target behind a mesh) with its
	-- bottom held at the same height, so the part's top, the clone's top and the plate all follow.
	local baseSize = instance.Size
	local restBase = instance.CFrame
	-- The server part floats WildHoverStuds over the ground and the bob swings WildBobStuds either way, so a
	-- mesh whose feet sat at the part's bottom hovered (Studio 2026-10-06: 0.7 studs at the low point). The
	-- mesh stands WildHoverStuds minus WildBobStuds lower: its feet touch the ground at the bob's low point
	-- and lift a little at the top, a hop rather than a float.
	local feet = restBase.Position - Vector3.new(0, baseSize.Y / 2 + Config.WildHoverStuds - Config.WildBobStuds, 0)
	local factor = bandOf(instance).scale
	instance.Size = baseSize * factor
	local base = restBase + Vector3.new(0, (instance.Size.Y - baseSize.Y) / 2, 0)
	if def then
		model, modelBase = buildModel(def, feet, factor)
	end
	local plate, nameLabel = buildPlate(instance, displayName, tier, topOffsetOf(instance, model))
	local light, glow, glowImage = buildAura(instance, tier)
	local record: Record = {
		part = instance,
		species = species,
		tier = tier,
		base = base,
		baseSize = baseSize,
		restBase = restBase,
		sizeFactor = factor,
		phase = rng:NextNumber(0, math.pi * 2),
		realColor = instance.Color,
		shadowed = false,
		hidden = false,
		plate = plate,
		nameLabel = nameLabel,
		model = model,
		modelBase = modelBase,
		light = light,
		glow = glow,
		glowImage = glowImage,
		glowTween = nil,
	}
	records[instance] = record
	setPulse(record)
	if not known[species] and Prefs.Silhouettes() then
		applyShadow(record)
	end
end

-- The Silhouettes preference changed: off un-shadows everything at once; on re-shadows the uncaught
-- species standing beyond the reveal distance (the nearer ones would reveal on the next frame anyway).
local function applySilhouettes()
	local on = Prefs.Silhouettes()
	local at = rootPosition()
	for _, record in pairs(records) do
		if not on then
			reveal(record)
		elseif not known[record.species] and not record.shadowed then
			local far = at == nil or (record.base.Position - at).Magnitude > Config.ShadowRevealDistance
			if far then
				applyShadow(record)
			end
		end
	end
end

local function untrack(instance: Instance)
	local record = records[instance :: any]
	if record then
		records[instance :: any] = nil
		if record.plate.Parent then
			record.plate:Destroy()
		end
		local pulse = record.glowTween
		if pulse then
			pulse:Cancel()
		end
		if record.light then
			record.light:Destroy()
		end
		if record.glow then
			record.glow:Destroy()
		end
		local model = record.model
		if model then
			model:Destroy()
		end
	end
end

-- Reserved spawns -----------------------------------------------------------
-- A summoned Warden for one player carries the number attribute ReservedFor (their UserId). Everyone
-- else never tracks it: no plate, no bob, out of Nearest and PartAtScreenPoint, and locally invisible.

local reservedConns: { [Part]: RBXScriptConnection } = {}
local sizeConns: { [Part]: RBXScriptConnection } = {}

local function reservedForOther(part: Part): boolean
	local reservedFor = part:GetAttribute("ReservedFor")
	return type(reservedFor) == "number" and reservedFor ~= localPlayer.UserId
end

-- Tracks or hides a wild part by its reservation; runs on arrival and whenever ReservedFor changes.
-- A tracked part stays invisible when a mesh clone stands in for it.
local function consider(instance: Instance)
	if not instance:IsA("Part") then
		return
	end
	if reservedForOther(instance) then
		local record = records[instance]
		if record then
			instance.CFrame = record.restBase -- park it so a later reveal starts from rest,
			instance.Size = record.baseSize -- at the server's size, so the band is not applied twice
			untrack(instance)
		end
		instance.LocalTransparencyModifier = 1
		return
	end
	track(instance)
	local record = records[instance]
	if record then
		local at = rootPosition()
		record.hidden = if at then hiddenAt(record.base.Position, at) else false -- a new arrival never flashes into view
		applyVisibility(record)
	else
		instance.LocalTransparencyModifier = 0
	end
end

local function watch(instance: Instance)
	if not instance:IsA("Part") then
		return
	end
	if not reservedConns[instance] then
		reservedConns[instance] = instance:GetAttributeChangedSignal("ReservedFor"):Connect(function()
			consider(instance)
		end)
	end
	if not sizeConns[instance] then
		sizeConns[instance] = instance:GetAttributeChangedSignal("Size"):Connect(function()
			local record = records[instance]
			if record then
				applySize(record)
			end
		end)
	end
	consider(instance)
end

local function unwatch(instance: Instance)
	untrack(instance)
	local connection = reservedConns[instance :: any]
	if connection then
		connection:Disconnect()
		reservedConns[instance :: any] = nil
	end
	local sizeConnection = sizeConns[instance :: any]
	if sizeConnection then
		sizeConnection:Disconnect()
		sizeConns[instance :: any] = nil
	end
end

local function onRender()
	local now = os.clock()
	local at = rootPosition()
	local omega = math.pi * 2 * Config.WildBobHz
	if now - lastEvaluate >= EVALUATE_SECONDS then
		evaluate()
	end
	for part, record in pairs(records) do
		if not part.Parent then
			continue
		end
		local lift = Vector3.new(0, math.sin(now * omega + record.phase) * Config.WildBobStuds, 0)
		part.CFrame = record.base + lift
		local model, modelBase = record.model, record.modelBase
		if model and modelBase then
			model:PivotTo(modelBase + lift)
		end
		if at and record.shadowed and (record.base.Position - at).Magnitude <= Config.ShadowRevealDistance then
			reveal(record)
		end
	end
end

-- Public API -------------------------------------------------------------

-- `knownSpecies` is the set of species the player has caught (from the profile's codex).
function WildRenderer.Start(knownSpecies: { [string]: boolean })
	known = knownSpecies
	if not visualFolder then
		local created = Instance.new("Folder")
		created.Name = VISUAL_FOLDER
		created.Parent = Workspace
		visualFolder = created
	end
	if not Models.Available() then
		warn(("[%s] WildRenderer: ReplicatedStorage.%s is missing; placeholder shapes in use"):format(Config.WorkingTitle, Config.ModelFolderName))
	end
	local world = Workspace:WaitForChild("World")
	local wild = world:WaitForChild("Wild") :: Folder
	wildFolder = wild
	for _, child in ipairs(wild:GetChildren()) do
		watch(child)
	end
	wild.ChildAdded:Connect(watch)
	wild.ChildRemoved:Connect(unwatch)
	if not prefsConn then
		prefsConn = Prefs.OnChanged(function()
			applySilhouettes()
			applyAuraMotion()
		end)
	end
	if not clockConn then
		clockConn = State.OnChanged("clock", function()
			refreshBlizzard()
			evaluate()
		end)
	end
	refreshBlizzard()
	if renderConn then
		renderConn:Disconnect()
	end
	renderConn = RunService.RenderStepped:Connect(onRender)
end

-- A species was just caught: it is no longer a silhouette anywhere.
function WildRenderer.MarkKnown(species: string)
	known[species] = true
	for _, record in pairs(records) do
		if record.species == species then
			reveal(record)
		end
	end
end

-- The nearest wild part within maxDistance of the player, with its distance.
function WildRenderer.Nearest(maxDistance: number): (Part?, number)
	local at = rootPosition()
	if not at then
		return nil, math.huge
	end
	local best: Part? = nil
	local bestDistance = maxDistance
	for part, record in pairs(records) do
		if part.Parent then
			local distance = (record.base.Position - at).Magnitude
			if distance <= bestDistance then
				best = part
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

-- True while the blizzard hide rule has this alien out of sight (the radar skips it). An untracked part
-- is not hidden by this rule.
function WildRenderer.IsHidden(part: Part): boolean
	local record = records[part]
	return record ~= nil and record.hidden
end

-- The wild part under a screen point, if any (tap-to-catch on the alien itself). Mesh clones have
-- CanQuery off, so the ray only ever meets the server parts, visible or not.
function WildRenderer.PartAtScreenPoint(x: number, y: number): Part?
	local camera = Workspace.CurrentCamera
	local wild = wildFolder
	if not camera or not wild then
		return nil
	end
	-- Only tracked parts are candidates, so an invisible reserved spawn never shadows the alien behind it.
	local tracked: { Instance } = {}
	for part, record in pairs(records) do
		if part.Parent == wild and not record.hidden then
			table.insert(tracked, part)
		end
	end
	if #tracked == 0 then
		return nil
	end
	local ray = camera:ScreenPointToRay(x, y) -- input positions include the GUI inset
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = tracked
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	if hit and hit.Instance:IsA("Part") and records[hit.Instance] then
		return hit.Instance
	end
	return nil
end

return WildRenderer
