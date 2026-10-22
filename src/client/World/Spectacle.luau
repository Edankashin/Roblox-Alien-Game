--!strict
-- StarterPlayerScripts.Client.World.Spectacle: the spectacle ladder (data/Spectacle, Shared/SpectacleMath) around every wild alien,
-- pure presentation on the client. The server places a plain part and decides every catch, flight and spawn; this module only dresses
-- what it said. Lives here (StarterPlayerScripts, World) because it draws in the 3D world beside WildRenderer, which owns the alien's
-- record and calls in. Nothing here is replicated: every part is made on the client under Workspace.ClientSpectacle.
-- What it draws, by tier (the rows of data/Spectacle):
--   Arrival (a wild part that arrives after the first moments in the place): Rare a pixel portal of cells opens, the alien pops
--   through and the portal snaps shut; Epic cells gather and burst out with a light pulse; Legendary a star falls trailing light,
--   lands, and a ring of cells blooms across the ground; Cosmic the screen dims a touch, a beam comes down and the alien descends in
--   it to a shockwave of cells (SpeciesFx's spawn moment rides on top); Secret the screen's edge flickers and the alien assembles from
--   cells drawn in from around it. While an arrival plays the alien is veiled (WildRenderer hides it) until its pop. From Epic a
--   beacon (a column of light at the alien) stands for the row's seconds, or while it stays, so the player can follow it from far;
--   only the nearest Caps.MaxBeacons (MaxBeaconsMobile) stand.
--   Presence (the nearest Caps.MaxPresence, MaxPresenceMobile on a phone, within Effects.Caps.ActiveDistance): a light pool on the
--   ground in its colour (a stepped disc of three flat cells), glyph cells orbiting its head, footprints that bloom where it steps
--   (flowers in World 1, frost in World 2), a soft aura, a trail of cells while it moves, a star field or a dark haze about it, and
--   an ambient loop (Sounds.TierAmbient, silent while its id is 0). A silhouetted or hidden alien shows none of it.
--   Personality (every drawn alien): it wanders a short leash and plays an idle each cycle (look round, stretch, sit, play; sleep
--   at night, with Zz cells); a player within its notice distance is turned to, its ears perk (RigAnimator.Perk), it hops and a
--   bubble pops over it ("!", or a heart when the player has caught its species); from Rare its flourish plays the first time a
--   player comes close (RigAnimator.PlayFlourish). WildRenderer composes the pose: PoseOf(part) answers the offset and turn it
--   adds to the bob it writes, so the two never fight.
--   Catch (the bootstrap calls Focus as a catch begins, then Caught or Fled with the server's verdict): when the server removes the
--   part, WildRenderer hands the clone over (TakeOver) instead of destroying it; a catch throws a cell burst and spirals the alien
--   into the player's device (Legendary and up a camera nudge and a ground shockwave, Cosmic and Secret a brief slow-mo: the catch's
--   own clocks slow and the view narrows a few degrees); a flight puffs and hops it away (a Secret blinks out). An alien whose
--   verdict does not come within Look.HoldSeconds simply fades.
-- Reduced Motion (Prefs): the still versions. No arrival plays (the alien is simply there, its beacon steady), no wander, idle,
-- hop, turn, Zz, ornament orbit or pool breath; a bubble shows without a pop; a caught or fled alien fades where it stood.
-- Budgets: the counts are SpectacleMath's (tests/Spectacle.spec.luau holds a Cosmic arrival with eight aliens around under the
-- phone's scene caps); at most Caps.MaxArrivals (MaxArrivalsMobile) arrivals play at once and only within Caps.ArrivalDistance.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Effects = require(Shared:WaitForChild("data"):WaitForChild("Effects"))
local SpectacleData = require(Shared:WaitForChild("data"):WaitForChild("Spectacle"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Place = require(Shared:WaitForChild("Place"))
local EffectsMath = require(Shared:WaitForChild("EffectsMath"))
local SpectacleMath = require(Shared:WaitForChild("SpectacleMath"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local SpeciesFx = require(script.Parent:WaitForChild("SpeciesFx"))
local RigAnimator = require(script.Parent:WaitForChild("RigAnimator"))
local CameraDirector = require(script.Parent:WaitForChild("CameraDirector"))

local Spectacle = {}

local FOLDER_NAME = "ClientSpectacle"
local SKY_NAME = "SpectacleSky" -- the ColorCorrectionEffect under Lighting the Cosmic arrival dims (its own; LightingDirector's is untouched)
local VIGNETTE_NAME = "SpectacleVignette"
local ARRIVAL_GRACE = 3 -- seconds after Start in which a part that appears is one already there (the join), not an arrival
local POOL_THICK = 0.05 -- studs: the pool's cells are flat
local SKY_STUDS = 80 -- studs above the landing the Cosmic beam starts
local SPRITE_CELL = "PixelMote" -- the cell sprite the bursts, trail and shimmer wear (its fallback until uploaded)
local SPRITE_STAR = "PixelTwinkle"
local SPRITE_HALO = "PixelHalo"
local SPRITE_PUFF = "PixelPuff"
local GROUND_PROBE = 4 -- studs above a wander point the ground ray starts, and twice that its length
local VIGNETTE_Z = 50
local BEACON_RANGE = 1e6 -- studs: a beacon is seen from the whole map (the ranking only keeps the nearest few)

type Pose = { offset: Vector3, yaw: number, pitch: number, roll: number }

type Footprint = { part: Part, born: number, size: number }
type Arrival = {
	plan: SpectacleMath.ArrivalPlan,
	born: number,
	made: { Instance },
	cells: { { part: Part, from: Vector3, to: Vector3 } },
	light: PointLight?,
	star: Part?,
	beam: Beam?,
	popped: boolean,
	landed: boolean,
	host: Part?,
}

type Record = {
	part: Part,
	model: Model?,
	fxTarget: BasePart | Model,
	species: string,
	tier: string,
	accent: Color3,
	tierColor: Color3, -- the tier's colour (the accent for a Secret, whose tier colour is near-black)
	height: number,
	home: Vector3, -- the feet where the server placed it
	baseYaw: number,
	seed: number,
	shown: boolean, -- drawn in colour: not hidden by the blizzard and not a silhouette (the presence wears its species' colour)
	visible: boolean, -- not hidden by the blizzard (a silhouette's beacon still stands: it is in the tier's colour, not the species')
	setVeil: (boolean) -> (),
	veiled: boolean,
	-- personality
	yaw: number, -- the extra turn now (radians, against the base)
	lastPose: number,
	noticed: boolean,
	noticeAt: number,
	lastNear: number, -- os.clock() a player was last within notice
	greeted: boolean, -- the bubble and the approach flourish of this visit have played
	flourished: boolean,
	wanderIndex: number, -- the cycle whose target is cached
	wanderFrom: Vector3, -- offsets from home
	wanderTo: Vector3,
	stepAcc: number, -- studs walked since the last footprint
	lastOffset: Vector3,
	moving: boolean,
	sleeping: boolean,
	zzAt: number,
	pose: Pose,
	-- presence
	active: boolean,
	host: Part?,
	pool: { Part },
	ornaments: { Part },
	trail: ParticleEmitter?,
	ambient: Sound?,
	presenceMade: { Instance },
	-- beacon
	beacon: { part: Part, beam: Beam, born: number, duration: number }?,
	beaconWanted: boolean,
	arrival: Arrival?,
	bubble: BillboardGui?,
}

type Held = {
	model: Model,
	tier: string,
	accent: Color3,
	height: number,
	at: number,
	outcome: string?,
	playing: boolean,
}

local records: { [Part]: Record } = {}
local list: { Record } = {}
local footprints: { Footprint } = {}
local arrivals: { Record } = {}
local held: Held? = nil
local focus: Part? = nil
local pendingOutcome: { outcome: string, tier: string, at: number }? = nil
local folder: Folder? = nil
local known: { [string]: boolean } = {}
local startedAt = -math.huge
local renderConn: RBXScriptConnection? = nil
local lastRecheck = -math.huge
local rootAt: Vector3? = nil
local mobile = UserInputService.TouchEnabled
local rng = Random.new()
local distances: { number } = {}
local picked: { [number]: boolean } = {}
local beaconPicked: { [number]: boolean } = {}
local skyEffect: ColorCorrectionEffect? = nil
local vignette: ScreenGui? = nil
local vignetteFrames: { Frame } = {}
local localPlayer = Players.LocalPlayer
local lastDimAt = -math.huge -- os.clock() of the last arrival dim or vignette that played (SpectacleMath.DimAllowed spaces them)
local panelProbe: (() -> boolean)? = nil -- the bootstrap's Screens.IsAnyOpen: no screen dim over an open panel

local caps = SpectacleData.Caps
local look = SpectacleData.Look
local maxPresence = if mobile then caps.MaxPresenceMobile else caps.MaxPresence
local maxBeacons = if mobile then caps.MaxBeaconsMobile else caps.MaxBeacons
local maxArrivals = if mobile then caps.MaxArrivalsMobile else caps.MaxArrivals
local maxFootprints = if mobile then caps.MaxFootprintsMobile else caps.MaxFootprints

-- Helpers -----------------------------------------------------------------------

local function workFolder(): Folder
	local existing = folder
	if existing and existing.Parent then
		return existing
	end
	local made = Instance.new("Folder")
	made.Name = FOLDER_NAME
	made.Parent = Workspace
	folder = made
	return made
end

-- A plain client cell: anchored, never collides or answers a ray, no shadow.
local function cell(name: string, size: Vector3, color: Color3, cf: CFrame, neon: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = cf
	part.Parent = workFolder()
	return part
end

local function dressSprite(emitter: ParticleEmitter, key: string)
	local id = EffectsMath.SpriteFor(key)
	if id ~= nil then
		emitter.Texture = "rbxassetid://" .. id
	end
end

-- A particle emitter of block cells (or another sprite), off, on `parent`.
local function cellEmitter(parent: Instance, color: Color3, size: number, life: number, speed: number, sprite: string): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.3) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(life * 0.7, life)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 90)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	dressSprite(emitter, sprite)
	emitter.Parent = parent
	return emitter
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

-- Where the player's catcher is: the right hand, else the root a little up.
local function devicePosition(): Vector3?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	for _, name in ipairs({ "RightHand", "Right Arm" }) do
		local hand = character:FindFirstChild(name)
		if hand and hand:IsA("BasePart") then
			return hand.Position
		end
	end
	local at = rootPosition()
	return if at then at + Vector3.new(0, 1, 0) else nil
end

local function isNight(): boolean
	return State.GetClock().isNight == true
end

local function setModelAlpha(model: Model, value: number)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = value
		end
	end
end

local function destroyAll(made: { Instance })
	for _, instance in ipairs(made) do
		instance:Destroy()
	end
	table.clear(made)
end

local function playOnce(id: string, host: BasePart)
	Builder.playSoundAt(id, host, Effects.Look.SoundRollOffMin, Effects.Look.SoundRollOffMax, Effects.Look.SoundMaxSeconds)
end

-- The feet of a record now (home plus its wander).
local function feetOf(record: Record): Vector3
	return record.home + record.lastOffset
end

-- Glyph bubbles ---------------------------------------------------------------------

-- A pixel glyph (data/Spectacle Glyphs) as cells on a white outlined plate, in a BillboardGui over `adornee`, `lift` studs over
-- its centre. Gone after `seconds`. Scale only (UI Playbook): every cell is a share of the plate.
local function glyphBubble(adornee: BasePart, name: string, ink: Color3, lift: number, studs: number, seconds: number, plate: boolean): BillboardGui
	local cells, width, height = SpectacleMath.GlyphCells(name)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Spectacle" .. name
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(studs, studs) -- studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	local holder = Builder.frame({ parent = gui, name = "Bubble", size = UDim2.fromScale(1, 1), transparency = 1 })
	local side = math.max(width, height) + (if plate then 2 else 0)
	local pad = if plate then 1 else 0
	if plate then
		Builder.frame({
			parent = holder,
			name = "Plate",
			size = UDim2.fromScale(1, 1),
			color = Theme.Colors.White,
			stroke = 2,
			strokeColor = Theme.Colors.Outline,
			zIndex = 1,
		})
	end
	local ox = pad + (side - 2 * pad - width) / 2
	local oy = pad + (side - 2 * pad - height) / 2
	for _, xy in ipairs(cells) do
		Builder.frame({
			parent = holder,
			name = "Cell",
			position = UDim2.fromScale((ox + xy[1]) / side, (oy + xy[2]) / side),
			size = UDim2.fromScale(1 / side, 1 / side),
			color = ink,
			zIndex = 2,
		})
	end
	gui.Parent = adornee
	if not Prefs.ReducedMotion() then
		Builder.pop(holder, 1.5)
	end
	task.delay(seconds, function()
		gui:Destroy()
	end)
	return gui
end

local function showBubble(record: Record)
	local old = record.bubble
	if old then
		old:Destroy()
	end
	local heart = known[record.species] == true
	local half = record.part.Size.Y / 2
	-- Above the nameplate, never over its name (SpectacleMath.BubbleLift; the Rare "!" had covered the middle of the plate, Studio
	-- 2026-10-22).
	local lift = SpectacleMath.BubbleLift(
		record.height - half,
		Config.WildBobStuds,
		Config.NameplateLiftStuds,
		Config.NameplateStudsH,
		look.BubbleGap,
		look.BubbleStuds
	)
	record.bubble = glyphBubble(record.part, if heart then "Heart" else "Alert", Theme.Hex(if heart then look.HeartColor else look.AlertColor), lift, look.BubbleStuds, look.BubbleSeconds, true)
end

-- One Z rising off a sleeper and fading.
local function puffZ(record: Record)
	local half = record.part.Size.Y / 2
	local start = record.height - half + 0.2
	local gui = glyphBubble(record.part, "Z", Theme.Hex(look.ZzColor), start, look.ZzStuds, look.ZzSeconds, false)
	local holder = gui:FindFirstChild("Bubble")
	TweenService:Create(gui, TweenInfo.new(look.ZzSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0.4, start + look.ZzRise, 0),
	}):Play()
	if holder then
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(look.ZzSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			end
		end
	end
end

-- Beacons ---------------------------------------------------------------------------

local function dropBeacon(record: Record)
	local beacon = record.beacon
	if beacon then
		beacon.part:Destroy()
		record.beacon = nil
	end
end

local function raiseBeacon(record: Record, born: number, duration: number)
	if record.beacon then
		return
	end
	local row = SpectacleMath.Arrival(record.tier)
	local part = cell("Beacon", Vector3.one * 0.2, record.tierColor, CFrame.new(record.home), false)
	part.Transparency = 1
	local foot = Instance.new("Attachment")
	foot.Parent = part
	local sky = Instance.new("Attachment")
	sky.Position = Vector3.new(0, row.beaconReach, 0)
	sky.Parent = part
	local beam = Instance.new("Beam")
	beam.Attachment0 = foot
	beam.Attachment1 = sky
	beam.Color = ColorSequence.new(record.tierColor, record.tierColor:Lerp(Theme.Colors.White, 0.5))
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Width0 = row.beaconWidth
	beam.Width1 = row.beaconWidth * 0.4
	beam.Transparency = NumberSequence.new(1)
	beam.Parent = part
	record.beacon = { part = part, beam = beam, born = born, duration = duration }
end

local function stepBeacon(record: Record, now: number, still: boolean)
	local beacon = record.beacon
	if not beacon then
		return
	end
	local alpha = SpectacleMath.BeaconAlpha(now, beacon.born, beacon.duration, still)
	if beacon.duration > 0 and now - beacon.born >= beacon.duration then
		dropBeacon(record)
		return
	end
	-- Close to the camera the column would fill the screen with light: it fades out between Look.BeaconNearFadeStuds and BeaconHideStuds
	-- (measured along the ground) and is gone inside the second.
	-- It stands where the alien stands now (its leash walk included), and fades by the nearer of the camera and the avatar.
	local feet = feetOf(record)
	local camera = Workspace.CurrentCamera
	local cameraStuds: number? = nil
	if camera then
		local offset = feet - camera.CFrame.Position
		cameraStuds = Vector3.new(offset.X, 0, offset.Z).Magnitude
	end
	local avatarStuds: number? = nil
	local at = rootAt
	if at then
		local offset = feet - at
		avatarStuds = Vector3.new(offset.X, 0, offset.Z).Magnitude
	end
	local near = SpectacleMath.BeaconNearest(cameraStuds, avatarStuds)
	beacon.part.CFrame = CFrame.new(feet)
	beacon.beam.Enabled = record.beaconWanted and record.visible and not record.veiled and near > 0
	-- the top fades out, so the column reads as light rising rather than a pole
	local shown = SpectacleMath.BeaconShown(alpha, near)
	beacon.beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, shown), NumberSequenceKeypoint.new(1, 1) })
	-- Readable from a Studio check (which beacon this is, how far its watchers stand, how much of it shows), one beacon part per alien.
	beacon.part:SetAttribute("Species", record.species)
	beacon.part:SetAttribute("NearFade", near)
	beacon.part:SetAttribute("CameraStuds", cameraStuds)
	beacon.part:SetAttribute("AvatarStuds", avatarStuds)
end

-- Presence --------------------------------------------------------------------------

local function dropPresence(record: Record)
	destroyAll(record.presenceMade)
	table.clear(record.pool)
	table.clear(record.ornaments)
	record.host = nil
	record.trail = nil
	record.ambient = nil
end

local function buildPresence(record: Record)
	local row = SpectacleMath.Presence(record.tier)
	local particles, parts = SpectacleMath.PresenceCost(record.tier)
	if particles <= 0 and parts <= 0 then
		return
	end
	local h = record.height
	local feet = feetOf(record)
	local made = record.presenceMade
	local host = cell("PresenceHost", Vector3.new(h * 0.8, h, h * 0.8), record.accent, CFrame.new(feet + Vector3.new(0, h / 2, 0)), false)
	host.Transparency = 1
	record.host = host
	table.insert(made, host)
	local still = Prefs.ReducedMotion()
	if row.pool > 0 then
		local r = row.pool * h
		-- a stepped disc: a bar and two caps, no two overlapping (so no cell doubles up its glow)
		local sizes = { Vector3.new(2 * r, POOL_THICK, 1.2 * r), Vector3.new(1.2 * r, POOL_THICK, 0.4 * r), Vector3.new(1.2 * r, POOL_THICK, 0.4 * r) }
		local shifts = { 0, 0.8 * r, -0.8 * r }
		for index, size in ipairs(sizes) do
			local piece = cell("Pool", size, record.accent, CFrame.new(feet), true)
			piece.Transparency = look.PoolTransparency
			piece:SetAttribute("Dz", shifts[index])
			table.insert(record.pool, piece)
			table.insert(made, piece)
		end
	end
	for index = 1, row.ornaments do
		local orb = cell("Ornament", Vector3.one * look.OrnamentStuds, record.accent:Lerp(Theme.Colors.White, 0.35), CFrame.new(feet), true)
		orb:SetAttribute("Index", index)
		table.insert(record.ornaments, orb)
		table.insert(made, orb)
	end
	if not still then
		local life = SpectacleData.PresenceLifetime
		if row.aura > 0 then
			local point = Instance.new("Attachment")
			point.Parent = host
			local aura = cellEmitter(point, record.accent, h * 1.2, life.aura, 0, SPRITE_HALO)
			aura.LockedToPart = true
			aura.LightEmission = 0.6
			aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(0.7, 0.8), NumberSequenceKeypoint.new(1, 1) })
			aura.Rate = row.aura
			aura.Enabled = true
		end
		if row.trail > 0 then
			local point = Instance.new("Attachment")
			point.Position = Vector3.new(0, -h / 2 + 0.1, 0)
			point.Parent = host
			local trail = cellEmitter(point, record.accent, look.FootprintStuds * 1.2, life.trail, 0.2, SPRITE_CELL)
			trail.Rate = row.trail
			trail.Acceleration = Vector3.new(0, 0.6, 0)
			record.trail = trail
		end
		if row.shimmer ~= "None" then
			local starField = row.shimmer == "StarField"
			local color = if starField then record.accent:Lerp(Theme.Colors.White, 0.6) else record.accent:Lerp(Theme.Hex(Effects.Dark.Color), 0.6)
			local shimmer = cellEmitter(host, color, if starField then 0.12 else h * 0.25, life.shimmer, 0.1, if starField then SPRITE_STAR else SPRITE_PUFF)
			shimmer.Shape = Enum.ParticleEmitterShape.Box
			shimmer.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			shimmer.Rate = row.shimmerRate
			shimmer.Acceleration = Vector3.new(0, if starField then 0 else 0.4, 0)
			shimmer.LightEmission = if starField then 1 else 0.2
			shimmer.Enabled = true
		end
	end
	if row.ambient then
		local id = (Sounds.TierAmbient :: { [string]: string })[record.tier]
		if id and not Builder.isSilent(id) and Prefs.SoundOn() then
			local sound = Instance.new("Sound")
			sound.SoundId = id
			sound.Looped = true
			sound.Volume = Sounds.Volume.Ambience
			sound.RollOffMinDistance = Effects.Look.SoundRollOffMin
			sound.RollOffMaxDistance = Effects.Look.SoundRollOffMax
			sound.Parent = host
			sound:Play()
			record.ambient = sound
		end
	end
end

local function placePresence(record: Record, now: number, still: boolean)
	local host = record.host
	if not host then
		return
	end
	local h = record.height
	local feet = feetOf(record)
	host.CFrame = CFrame.new(feet + Vector3.new(0, h / 2, 0))
	local breathe = if still then 0 else look.PoolBreathe * (0.5 + 0.5 * math.sin(math.pi * 2 * now / look.PoolPeriod + record.seed * 6))
	for _, piece in ipairs(record.pool) do
		local dz = piece:GetAttribute("Dz")
		piece.CFrame = CFrame.new(feet + Vector3.new(0, look.PoolLift, if type(dz) == "number" then dz else 0))
		piece.Transparency = look.PoolTransparency + breathe * (1 - look.PoolTransparency)
	end
	local row = SpectacleMath.Presence(record.tier)
	local count = #record.ornaments
	for index, orb in ipairs(record.ornaments) do
		local angle = if still
			then math.pi * 2 * (index - 1) / math.max(count, 1)
			else EffectsMath.OrbitAngle(now, row.ornamentPeriod, index, count, record.seed * 6)
		local bob = if still then 0 else look.OrnamentBob * h * math.sin(now * 2 + index)
		local r = row.ornamentRadius * h
		orb.CFrame = CFrame.new(feet + Vector3.new(math.cos(angle) * r, h * 1.08 + bob, math.sin(angle) * r)) * CFrame.Angles(0, if still then 0 else now, math.rad(45))
	end
	local trail = record.trail
	if trail then
		trail.Enabled = record.moving
	end
end

-- Footprints ------------------------------------------------------------------------

local function bloom(at: Vector3)
	if #footprints >= maxFootprints then
		local oldest = table.remove(footprints, 1)
		if oldest then
			oldest.part:Destroy()
		end
	end
	local colors = SpectacleMath.FootprintColors(Place.WorldId())
	local pick = colors[1 + (#footprints % #colors)]
	local size = look.FootprintStuds * 2
	local part = cell("Footprint", Vector3.new(size, POOL_THICK, size), Theme.Hex(pick), CFrame.new(at + Vector3.new(0, look.PoolLift, 0)) * CFrame.Angles(0, math.rad(45), 0), true)
	part.Transparency = 1
	table.insert(footprints, { part = part, born = os.clock(), size = size })
end

local function stepFootprints(now: number)
	for index = #footprints, 1, -1 do
		local mark = footprints[index]
		local share, clear = SpectacleMath.FootprintAlpha(now - mark.born)
		if share <= 0 and clear >= 1 and now - mark.born > look.FootprintGrow then
			mark.part:Destroy()
			table.remove(footprints, index)
		else
			local side = math.max(mark.size * share, 0.01)
			mark.part.Size = Vector3.new(side, POOL_THICK, side)
			mark.part.Transparency = 0.15 + 0.85 * clear
		end
	end
end

-- Arrivals --------------------------------------------------------------------------

local function endArrival(record: Record)
	local arrival = record.arrival
	if not arrival then
		return
	end
	destroyAll(arrival.made)
	record.arrival = nil
	local at = table.find(arrivals, record)
	if at then
		table.remove(arrivals, at)
	end
	if record.veiled then
		record.veiled = false
		record.setVeil(false)
	end
end

local function setSky(depth: number)
	if depth <= 0 then
		local effect = skyEffect
		if effect then
			effect.Brightness = 0
			effect.Enabled = false
		end
		return
	end
	local effect = skyEffect
	if not effect or not effect.Parent then
		local made = Instance.new("ColorCorrectionEffect")
		made.Name = SKY_NAME
		made.Parent = Lighting
		skyEffect = made
		effect = made
	end
	if effect then
		effect.Enabled = true
		effect.Brightness = -depth
		effect.Saturation = -depth
	end
end

local function setVignette(alpha: number)
	if alpha >= 1 then
		local gui = vignette
		if gui then
			gui.Enabled = false
		end
		return
	end
	local gui = vignette
	if not gui then
		local made = Builder.screen(VIGNETTE_NAME, VIGNETTE_Z)
		local color = Theme.Hex(look.VignetteColor)
		local d = look.VignetteDepth
		local bars = {
			{ UDim2.fromScale(0, 0), UDim2.fromScale(1, d) },
			{ UDim2.fromScale(0, 1 - d), UDim2.fromScale(1, d) },
			{ UDim2.fromScale(0, 0), UDim2.fromScale(d, 1) },
			{ UDim2.fromScale(1 - d, 0), UDim2.fromScale(d, 1) },
		}
		for _, bar in ipairs(bars) do
			local frame = Builder.frame({ parent = made, name = "Edge", position = bar[1], size = bar[2], color = color })
			local gradient = Instance.new("UIGradient")
			gradient.Transparency = NumberSequence.new(0, 1)
			if bar[2].X.Scale >= 1 then
				gradient.Rotation = if bar[1].Y.Scale > 0 then -90 else 90
			else
				gradient.Rotation = if bar[1].X.Scale > 0 then 180 else 0
			end
			gradient.Parent = frame
			table.insert(vignetteFrames, frame)
		end
		vignette = made
		gui = made
	end
	if gui then
		gui.Enabled = true
	end
	for _, frame in ipairs(vignetteFrames) do
		frame.BackgroundTransparency = alpha
	end
end

-- A light at the landing that flashes to `peak` and dies away (the Epic's pulse, the star's landing, the shockwave).
local function flashLight(arrival: Arrival, host: Part, color: Color3, peak: number, range: number)
	if peak <= 0 then
		return
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = peak
	light.Range = math.min(range, 60)
	light.Shadows = false
	light.Parent = host
	table.insert(arrival.made, light)
	TweenService:Create(light, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

-- Throws `count` cells as particles from `host`.
local function cellBurst(arrival: Arrival, host: Part, color: Color3, count: number, speed: number)
	if count <= 0 then
		return
	end
	local emitter = cellEmitter(host, color, 0.18, 1, speed, SPRITE_CELL)
	emitter.Acceleration = Vector3.new(0, -speed, 0)
	table.insert(arrival.made, emitter)
	emitter:Emit(count)
end

-- The cells of an arrival's shape: `count` cells along a ring of `radius` on the ground (flat), or round a square portal
-- standing at the body facing the camera, or scattered round the body (the assembly's starting points).
local function ringPoints(centre: Vector3, radius: number, count: number): { Vector3 }
	local points: { Vector3 } = {}
	for index = 1, count do
		local angle = math.pi * 2 * (index - 1) / count
		table.insert(points, centre + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
	end
	return points
end

local function portalPoints(centre: Vector3, side: number, count: number): { Vector3 }
	local camera = Workspace.CurrentCamera
	local toward = if camera then (camera.CFrame.Position - centre) else Vector3.new(0, 0, 1)
	local flat = Vector3.new(toward.X, 0, toward.Z)
	local right = if flat.Magnitude > 1e-3 then Vector3.yAxis:Cross(flat.Unit) else Vector3.xAxis
	local points: { Vector3 } = {}
	local half = side / 2
	for index = 1, count do
		local t = (index - 1) / count * 4 -- round the square's four sides
		local edge = math.floor(t)
		local along = (t - edge) * 2 - 1
		local x, y
		if edge == 0 then
			x, y = along, -1
		elseif edge == 1 then
			x, y = 1, along
		elseif edge == 2 then
			x, y = -along, 1
		else
			x, y = -1, -along
		end
		table.insert(points, centre + right * (x * half) + Vector3.yAxis * (y * half))
	end
	return points
end

local function startArrival(record: Record, now: number)
	local plan = SpectacleMath.ArrivalPlan(record.tier, mobile, Prefs.ReducedMotion())
	-- A screen dim (the Cosmic's sky, the Secret's edge flicker) never plays over an open panel or within Look.DimGapSeconds of another.
	if plan.skyDim > 0 or plan.vignette then
		local panelOpen = panelProbe ~= nil and panelProbe()
		if SpectacleMath.DimAllowed(now, lastDimAt, panelOpen) then
			lastDimAt = now
		else
			plan.skyDim = 0
			plan.vignette = false
		end
	end
	if plan.beacon ~= 0 then
		raiseBeacon(record, now, plan.beacon)
	end
	if plan.kind == "None" or plan.seconds <= 0 then
		return
	end
	local camera = Workspace.CurrentCamera
	if #arrivals >= maxArrivals or not camera or (record.home - camera.CFrame.Position).Magnitude > caps.ArrivalDistance then
		return -- too far or too busy: the alien is simply there (its beacon still stands)
	end
	local h = record.height
	local body = record.home + Vector3.new(0, h / 2, 0)
	local arrival: Arrival = { plan = plan, born = now, made = {}, cells = {}, light = nil, star = nil, beam = nil, popped = false, landed = false, host = nil }
	local host = cell("ArrivalHost", Vector3.one * 0.2, record.tierColor, CFrame.new(body), false)
	host.Transparency = 1
	arrival.host = host
	table.insert(arrival.made, host)
	local cellSize = Vector3.one * plan.cellStuds
	local reach = plan.reach * h
	local kind = plan.kind
	local froms: { Vector3 } = {}
	local tos: { Vector3 } = {}
	if kind == "Pop" then
		local square = portalPoints(body, math.max(reach, h * 0.6) * 2, plan.cells)
		for index = 1, #square do
			froms[index] = body
			tos[index] = square[index]
		end
	elseif kind == "Burst" then
		for index = 1, plan.cells do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1), rng:NextNumber(-1, 1))
			froms[index] = body
			tos[index] = body + (if dir.Magnitude > 1e-3 then dir.Unit else Vector3.yAxis) * reach
		end
	elseif kind == "Star" or kind == "Beam" then
		local ground = record.home + Vector3.new(0, look.PoolLift, 0)
		local ring = ringPoints(ground, reach, plan.cells)
		for index = 1, #ring do
			froms[index] = ground
			tos[index] = ring[index]
		end
	elseif kind == "Glitch" then
		for index = 1, plan.cells do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1))
			froms[index] = body + (if dir.Magnitude > 1e-3 then dir.Unit else Vector3.yAxis) * reach
			tos[index] = body + Vector3.new(rng:NextNumber(-0.35, 0.35) * h, rng:NextNumber(-0.45, 0.45) * h, rng:NextNumber(-0.35, 0.35) * h)
		end
	end
	for index = 1, #froms do
		local piece = cell("ArrivalCell", cellSize, record.tierColor:Lerp(Theme.Colors.White, rng:NextNumber(0, 0.4)), CFrame.new(froms[index]), true)
		piece.Transparency = if kind == "Star" or kind == "Beam" then 1 else 0
		table.insert(arrival.cells, { part = piece, from = froms[index], to = tos[index] })
		table.insert(arrival.made, piece)
	end
	if kind == "Star" then
		local star = cell("FallingStar", Vector3.one * math.max(plan.cellStuds * 2, 0.5), record.tierColor:Lerp(Theme.Colors.White, 0.5), CFrame.new(record.home + Vector3.new(plan.fall * 0.4, plan.fall, plan.fall * 0.2)), true)
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.3, 0)
		a0.Parent = star
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.3, 0)
		a1.Parent = star
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(record.tierColor:Lerp(Theme.Colors.White, 0.6), record.tierColor)
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Lifetime = 0.5
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Transparency = NumberSequence.new(0.1, 1)
		trail.Parent = star
		arrival.star = star
		table.insert(arrival.made, star)
	elseif kind == "Beam" then
		local sky = cell("SkyAnchor", Vector3.one * 0.2, record.tierColor, CFrame.new(record.home + Vector3.new(0, SKY_STUDS + plan.fall, 0)), false)
		sky.Transparency = 1
		table.insert(arrival.made, sky)
		local top = Instance.new("Attachment")
		top.Parent = sky
		local foot = Instance.new("Attachment")
		foot.Position = Vector3.new(0, -h / 2, 0)
		foot.Parent = host
		local beam = Instance.new("Beam")
		beam.Attachment0 = top
		beam.Attachment1 = foot
		beam.Color = ColorSequence.new(record.tierColor:Lerp(Theme.Colors.White, 0.4), record.tierColor)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Width0 = h * 0.9
		beam.Width1 = h * 1.4
		beam.Transparency = NumberSequence.new(1)
		beam.Parent = host
		arrival.beam = beam
	end
	-- veiled until its pop (the Cosmic descends in plain sight inside its beam)
	if kind ~= "Beam" then
		record.veiled = true
		record.setVeil(true)
	end
	local arriveSound = (Sounds.Arrive :: { [string]: string })[record.tier]
	if arriveSound then
		playOnce(arriveSound, host)
	end
	record.arrival = arrival
	table.insert(arrivals, record)
end

-- When in the arrival (a share of its length) the alien appears, by kind.
local POP_AT: { [string]: number } = { Pop = 0.4, Burst = 0.25, Star = 0.45, Beam = 0.15, Glitch = 0.8 }
local LAND_AT: { [string]: number } = { Pop = 0.4, Burst = 0.25, Star = 0.45, Beam = 0.8, Glitch = 0.8 }

local function stepArrival(record: Record, now: number)
	local arrival = record.arrival
	if not arrival then
		return
	end
	local plan = arrival.plan
	local k = (now - arrival.born) / plan.seconds
	local kind = plan.kind
	local host = arrival.host
	if k >= 1 or not host then
		endArrival(record)
		return
	end
	local popAt, landAt = POP_AT[kind] or 0, LAND_AT[kind] or 0
	if not arrival.popped and k >= popAt then
		arrival.popped = true
		if record.veiled then
			record.veiled = false
			record.setVeil(false)
		end
	end
	if not arrival.landed and k >= landAt then
		arrival.landed = true
		host.CFrame = CFrame.new(record.home + Vector3.new(0, record.height / 2, 0))
		cellBurst(arrival, host, record.tierColor:Lerp(Theme.Colors.White, 0.3), plan.particles, math.max(record.height * 2, 4))
		flashLight(arrival, host, record.tierColor, plan.lightPulse, record.height * 6)
	end
	-- the cells
	for _, piece in ipairs(arrival.cells) do
		local part = piece.part
		if kind == "Pop" then
			-- out to the portal, hold, back into the middle as it closes
			local out = SpectacleMath.Smooth(k / popAt)
			local back = SpectacleMath.Smooth((k - popAt) / (1 - popAt))
			part.Position = piece.from:Lerp(piece.to, out * (1 - back))
			local side = plan.cellStuds * (1 - back)
			part.Size = Vector3.one * math.max(side, 0.01)
		elseif kind == "Burst" then
			if k < popAt then
				local gather = SpectacleMath.Smooth(k / popAt)
				part.Position = piece.to:Lerp(piece.from, gather)
				part.Transparency = 1 - gather
			else
				local s = (k - popAt) / (1 - popAt)
				local fall = Vector3.new(0, -record.height * s * s, 0)
				part.Position = piece.from:Lerp(piece.to, SpectacleMath.Smooth(s)) + fall
				part.Transparency = s
			end
		elseif kind == "Star" or kind == "Beam" then
			if k < landAt then
				part.Transparency = 1
			else
				local s = (k - landAt) / (1 - landAt)
				part.Position = piece.from:Lerp(piece.to, SpectacleMath.Smooth(s))
				part.Transparency = s
			end
		elseif kind == "Glitch" then
			if k < landAt then
				local s = k / landAt
				-- in glitchy steps: snapped to Look-free twelfths, so the cells jump rather than glide
				local stepped = math.floor(s * 12) / 12
				local jitter = (1 - stepped) * 0.25 * record.height
				part.Position = piece.from:Lerp(piece.to, SpectacleMath.Smooth(stepped)) + Vector3.new(rng:NextNumber(-jitter, jitter), 0, rng:NextNumber(-jitter, jitter))
			else
				local s = (k - landAt) / (1 - landAt)
				part.Size = Vector3.one * math.max(plan.cellStuds * (1 - s), 0.01)
			end
		end
	end
	-- the star falls along its line to the feet, then is gone
	local star = arrival.star
	if star then
		if k < landAt then
			local s = k / landAt
			local top = record.home + Vector3.new(plan.fall * 0.4, plan.fall, plan.fall * 0.2)
			star.CFrame = CFrame.new(top:Lerp(record.home, s * s)) * CFrame.Angles(s * 6, s * 4, 0)
		elseif star.Parent then
			star.Transparency = 1
		end
	end
	-- the Cosmic's beam fades in, holds while it descends, fades out after the landing; the sky dips meanwhile
	local beam = arrival.beam
	if beam then
		local strength = EffectsMath.Envelope(k, 0.15, 0.25)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - 0.7 * strength), NumberSequenceKeypoint.new(1, 1 - 0.85 * strength) })
		host.CFrame = CFrame.new(record.home + Vector3.new(0, record.height / 2, 0))
	end
	if plan.skyDim > 0 then
		setSky(SpectacleMath.SkyDim(now - arrival.born, plan.seconds, plan.skyDim))
	end
	if plan.vignette then
		setVignette(SpectacleMath.VignetteAlpha(now - arrival.born, plan.seconds))
	end
end

-- The Cosmic's descent: studs above the ground it stands at `now` (0 outside its arrival).
local function descentOf(record: Record, now: number): number
	local arrival = record.arrival
	if not arrival or arrival.plan.kind ~= "Beam" or arrival.plan.fall <= 0 then
		return 0
	end
	local k = (now - arrival.born) / arrival.plan.seconds
	local from, to = POP_AT.Beam, LAND_AT.Beam
	if k <= from then
		return arrival.plan.fall
	end
	return arrival.plan.fall * (1 - SpectacleMath.Smooth((k - from) / (to - from)))
end

-- Personality -----------------------------------------------------------------------

-- The ground under a wander point is within Look.MaxStep of home's (so it never walks into a slope, a rock or a pond).
local function groundOk(record: Record, offset: Vector3): boolean
	local origin = record.home + offset + Vector3.new(0, GROUND_PROBE, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { workFolder() }
	local character = localPlayer.Character
	if character then
		table.insert(exclude, character)
	end
	local wildVisual = Workspace:FindFirstChild("ClientWild")
	if wildVisual then
		table.insert(exclude, wildVisual)
	end
	local world = Workspace:FindFirstChild("World")
	local wild = if world then world:FindFirstChild("Wild") else nil
	if wild then
		table.insert(exclude, wild)
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(origin, Vector3.new(0, -GROUND_PROBE * 2, 0), params)
	if not hit then
		return false
	end
	return math.abs(hit.Position.Y - record.home.Y) <= look.MaxStep
end

local function wanderTarget(record: Record, index: number, leash: number): Vector3
	local dx, dz = SpectacleMath.WanderPoint(record.seed, index, leash)
	local offset = Vector3.new(dx, 0, dz)
	if offset.Magnitude > 0 and not groundOk(record, offset) then
		return Vector3.zero
	end
	return offset
end

local function notice(record: Record, now: number, row: SpectacleData.Personality)
	record.noticed = true
	record.noticeAt = now
	record.sleeping = false
	if record.greeted then
		return
	end
	record.greeted = true
	if row.bubble then
		showBubble(record)
	end
	local model = record.model
	if model and row.perk > 0 then
		RigAnimator.Perk(model, row.perk)
	end
end

-- The pose this record adds this frame (absolute in the clock, except the turn, which eases toward its aim).
local function computePose(record: Record, now: number): Pose
	local pose = record.pose
	local dt = math.clamp(now - record.lastPose, 0, 0.25)
	record.lastPose = now
	local still = Prefs.ReducedMotion()
	local row = SpectacleMath.Personality(record.tier)
	local descent = descentOf(record, now)
	if still then
		record.moving = false
		record.lastOffset = Vector3.zero
		pose.offset = Vector3.new(0, descent, 0)
		pose.yaw, pose.pitch, pose.roll = record.yaw, 0, 0
		return pose
	end
	-- the leash walk
	local index, moving, k, idleShare = SpectacleMath.WanderAt(now, record.seed, row.cycle)
	if index ~= record.wanderIndex then
		record.wanderFrom = record.wanderTo
		record.wanderTo = wanderTarget(record, index, row.wander)
		record.wanderIndex = index
	end
	local offset = record.wanderFrom:Lerp(record.wanderTo, k)
	local stepped = (offset - record.lastOffset).Magnitude
	record.lastOffset = offset
	record.moving = moving and stepped > 1e-4
	-- footprints from Legendary while it walks
	if record.moving and record.active and SpectacleMath.Presence(record.tier).footprints then
		record.stepAcc += stepped
		if record.stepAcc >= look.FootprintStep then
			record.stepAcc = 0
			bloom(record.home + offset)
		end
	end
	-- where it looks: the player while noticed, else along its walk, else where it last looked
	local aim = record.yaw
	local at = rootAt
	if record.noticed and at then
		local feet = record.home + offset
		local face = SpectacleMath.FaceYaw(at.X - feet.X, at.Z - feet.Z) - record.baseYaw
		aim = SpectacleMath.TurnToward(record.yaw, face, row.turn)
	elseif record.moving then
		local dir = record.wanderTo - record.wanderFrom
		aim = SpectacleMath.FaceYaw(dir.X, dir.Z) - record.baseYaw
	end
	record.yaw = SpectacleMath.TurnToward(record.yaw, aim, SpectacleMath.TurnShare(dt))
	-- the idle of this cycle (none while it walks or watches a player)
	local lift, idleYaw, pitch, roll = 0, 0, 0, 0
	if not moving and not record.noticed then
		local kind = SpectacleMath.IdleFor(record.tier, record.seed, index, isNight())
		lift, idleYaw, pitch, roll = SpectacleMath.IdlePose(kind :: any, idleShare, row.theatre)
		local sleeping = kind == "Sleep"
		if sleeping and not record.sleeping then
			record.zzAt = now
		end
		record.sleeping = sleeping
		if sleeping and now - record.zzAt >= look.ZzEvery and record.shown then
			record.zzAt = now
			puffZ(record)
		end
	else
		record.sleeping = false
	end
	local hop = SpectacleMath.Hop(now - record.noticeAt, row.hops, row.hop)
	pose.offset = Vector3.new(offset.X, lift + hop + descent, offset.Z)
	pose.yaw, pose.pitch, pose.roll = record.yaw + idleYaw, pitch, roll
	return pose
end

local function personalityTick(record: Record, now: number)
	local at = rootAt
	if not at then
		return
	end
	local row = SpectacleMath.Personality(record.tier)
	local distance = (feetOf(record) - at).Magnitude
	if SpectacleMath.Noticed(record.tier, distance) then
		record.lastNear = now
		if not record.noticed then
			notice(record, now, row)
		end
		if SpectacleMath.ApproachFlourish(record.tier, distance, record.flourished) and not record.veiled then
			record.flourished = true
			local model = record.model
			local played = model ~= nil and RigAnimator.PlayFlourish(model)
			if not played then
				SpeciesFx.Flourish(record.fxTarget, record.species)
			end
		end
	else
		record.noticed = false
		if now - record.lastNear >= look.ForgetSeconds then
			record.greeted = false
			record.flourished = false
		end
	end
end

-- Ranking ---------------------------------------------------------------------------

local function recheck(now: number)
	lastRecheck = now
	local camera = Workspace.CurrentCamera
	table.clear(distances)
	for index, record in ipairs(list) do
		local d = math.huge
		if camera and record.shown and record.part.Parent then
			d = (record.home - camera.CFrame.Position).Magnitude
		end
		distances[index] = d
	end
	EffectsMath.PickActive(distances, maxPresence, Effects.Caps.ActiveDistance, picked)
	for index, record in ipairs(list) do
		local d = math.huge
		if camera and record.visible and record.part.Parent and SpectacleMath.Arrival(record.tier).beacon ~= 0 then
			d = (record.home - camera.CFrame.Position).Magnitude
		end
		distances[index] = d
	end
	EffectsMath.PickActive(distances, maxBeacons, BEACON_RANGE, beaconPicked)
	for index, record in ipairs(list) do
		local on = picked[index] == true and not record.veiled
		if on ~= record.active then
			record.active = on
			if on then
				buildPresence(record)
			else
				dropPresence(record)
			end
		end
		record.beaconWanted = beaconPicked[index] == true
		-- a staying beacon for an alien there before this client came (no arrival raised it)
		if record.beaconWanted and not record.beacon and SpectacleMath.Arrival(record.tier).beacon == -1 then
			raiseBeacon(record, now - SpectacleData.Look.BeaconFade, -1)
		end
	end
end

-- The catch's outro -----------------------------------------------------------------

local function finishHeld()
	local h = held
	if not h then
		return
	end
	held = nil
	pendingOutcome = nil
	if h.model.Parent then
		h.model:Destroy()
	end
end

local function fadeHeld(h: Held, seconds: number)
	local start = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local s = math.clamp((os.clock() - start) / seconds, 0, 1)
		if h.model.Parent then
			setModelAlpha(h.model, s)
		end
		if s >= 1 then
			if conn then
				conn:Disconnect()
			end
			if held == h then
				finishHeld()
			elseif h.model.Parent then
				h.model:Destroy()
			end
		end
	end)
end

-- A ring of cells rolling out over the ground at `at`.
local function shockwave(at: Vector3, color: Color3, count: number, reach: number, made: { Instance })
	local cells: { Part } = {}
	for index = 1, count do
		local piece = cell("Shockwave", Vector3.one * 0.3, color:Lerp(Theme.Colors.White, (index % 3) * 0.15), CFrame.new(at), true)
		table.insert(cells, piece)
		table.insert(made, piece)
	end
	local start = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local s = math.clamp((os.clock() - start) / look.ShockwaveSeconds, 0, 1)
		local r = reach * SpectacleMath.Smooth(s)
		for index, piece in ipairs(cells) do
			local angle = math.pi * 2 * (index - 1) / count
			piece.Position = at + Vector3.new(math.cos(angle) * r, 0.15, math.sin(angle) * r)
			piece.Transparency = s
		end
		if s >= 1 then
			if conn then
				conn:Disconnect()
			end
			for _, piece in ipairs(cells) do
				piece:Destroy()
			end
		end
	end)
end

local function playCaught(h: Held)
	h.playing = true
	local row = SpectacleMath.CatchLook(h.tier)
	if Prefs.ReducedMotion() then
		fadeHeld(h, 0.3)
		return
	end
	local model = h.model
	local start = model:GetPivot()
	local scale0 = model:GetScale()
	local made: { Instance } = {}
	local burstHost = cell("CatchCells", Vector3.one * 0.2, h.accent, CFrame.new(start.Position + Vector3.new(0, h.height / 2, 0)), false)
	burstHost.Transparency = 1
	table.insert(made, burstHost)
	local burst = cellEmitter(burstHost, h.accent:Lerp(Theme.Colors.White, 0.3), 0.2, 0.9, math.max(h.height * 2.5, 5), SPRITE_CELL)
	burst.Acceleration = Vector3.new(0, -4, 0)
	burst:Emit(row.cells)
	if row.shockwave > 0 then
		shockwave(start.Position, h.accent, row.shockwave, look.ShockwaveReach * h.height, made)
	end
	if row.nudge > 0 then
		CameraDirector.Rumble(row.nudgeSeconds, row.nudge)
	end
	local camera = Workspace.CurrentCamera
	local fov0 = if camera then camera.FieldOfView else 70
	local spiralSound = Sounds.CatchSpiral
	playOnce(spiralSound, burstHost)
	local clock = 0
	local began = os.clock()
	local last = began
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local real = now - began
		local scale = SpectacleMath.SlowMoScale(real, row.slowmo)
		clock += (now - last) * scale
		last = now
		burst.TimeScale = scale
		if row.slowmo > 0 and camera then
			camera.FieldOfView = fov0 - look.FovPunch * (1 - scale) / (1 - caps.SlowMoMinScale)
		end
		local s = clock / math.max(row.spiral, 0.05)
		local device = devicePosition() or start.Position
		local angle, radius, travel, size = SpectacleMath.SpiralAt(s, row.turns)
		if model.Parent then
			local path = start.Position:Lerp(device, travel) + Vector3.new(0, look.SpiralRise * math.sin(math.pi * travel), 0)
			local r = look.SpiralRadius * h.height * radius
			local spot = path + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
			model:ScaleTo(math.max(scale0 * size, 0.01))
			model:PivotTo(CFrame.new(spot) * start.Rotation * CFrame.Angles(0, angle, 0))
		end
		if s >= 1 and (row.slowmo <= 0 or real >= row.slowmo) then
			if conn then
				conn:Disconnect()
			end
			if camera and row.slowmo > 0 then
				camera.FieldOfView = fov0
			end
			burst.TimeScale = 1
			task.delay(1, function()
				destroyAll(made)
			end)
			if held == h then
				finishHeld()
			elseif model.Parent then
				model:Destroy()
			end
		end
	end)
end

local function playFled(h: Held)
	h.playing = true
	local row = SpectacleMath.CatchLook(h.tier)
	if Prefs.ReducedMotion() then
		fadeHeld(h, 0.3)
		return
	end
	local model = h.model
	local start = model:GetPivot()
	local made: { Instance } = {}
	local puffHost = cell("EscapePuff", Vector3.one * 0.2, h.accent, CFrame.new(start.Position + Vector3.new(0, 0.2, 0)), false)
	puffHost.Transparency = 1
	table.insert(made, puffHost)
	local puff = cellEmitter(puffHost, Theme.Colors.White:Lerp(h.accent, 0.2), h.height * 0.35, 0.8, 2, SPRITE_PUFF)
	puff.Acceleration = Vector3.new(0, 1, 0)
	puff:Emit(8)
	task.delay(1.2, function()
		destroyAll(made)
	end)
	if row.escape == "BlinkOut" then
		playOnce(Sounds.BlinkOut, puffHost)
		local began = os.clock()
		local conn: RBXScriptConnection? = nil
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - began
			local visible = SpectacleMath.BlinkVisible(t)
			if model.Parent then
				setModelAlpha(model, if visible then 0 else 1)
			end
			if t >= look.BlinkSeconds then
				if conn then
					conn:Disconnect()
				end
				if held == h then
					finishHeld()
				elseif model.Parent then
					model:Destroy()
				end
			end
		end)
		return
	end
	playOnce(Sounds.EscapePuff, puffHost)
	local at = rootPosition()
	local away = if at then Vector3.new(start.Position.X - at.X, 0, start.Position.Z - at.Z) else start.LookVector
	local dir = if away.Magnitude > 1e-3 then away.Unit else Vector3.xAxis
	local total = look.EscapeStride * row.escapeHops
	local face = CFrame.new(Vector3.zero, dir)
	local began = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - began
		local lift, stride, done = SpectacleMath.EscapeHopAt(t, row.escapeHops)
		if model.Parent then
			model:PivotTo(CFrame.new(start.Position + dir * total * stride + Vector3.new(0, lift, 0)) * face.Rotation)
		end
		if done then
			if conn then
				conn:Disconnect()
			end
			fadeHeld(h, 0.35)
		end
	end)
end

local function tryPlayHeld()
	local h = held
	local verdict = pendingOutcome
	if not h or not verdict or h.playing then
		return
	end
	if verdict.outcome == "Caught" then
		h.tier = verdict.tier ~= "" and verdict.tier or h.tier
		playCaught(h)
	else
		playFled(h)
	end
end

-- The frame step --------------------------------------------------------------------

local function step()
	local now = os.clock()
	rootAt = rootPosition()
	local still = Prefs.ReducedMotion()
	if now - lastRecheck >= Config.VfxFxRecheckSeconds then
		recheck(now)
	end
	for index = #arrivals, 1, -1 do
		stepArrival(arrivals[index], now)
	end
	if #arrivals == 0 then
		setSky(0)
		setVignette(1)
	end
	for _, record in ipairs(list) do
		if record.part.Parent then
			personalityTick(record, now)
			if record.active then
				placePresence(record, now, still)
			end
			stepBeacon(record, now, still)
		end
	end
	stepFootprints(now)
	local h = held
	if h and not h.playing and now - h.at >= look.HoldSeconds then
		h.playing = true
		fadeHeld(h, 0.4) -- no verdict came: it simply fades
	end
end

local function ensureRunning()
	if not renderConn then
		renderConn = RunService.RenderStepped:Connect(step)
	end
end

-- Public API ------------------------------------------------------------------------

export type TrackInfo = {
	fxTarget: BasePart | Model,
	model: Model?,
	species: string,
	tier: string,
	height: number, -- studs from the feet to the top of what the player sees
	feet: CFrame, -- where the server placed it: the clone's rest pivot, or the part's bottom (upright)
	setVeil: (boolean) -> (), -- hides (true) or shows the alien while an arrival has it veiled
}

-- Starts the module: `knownSpecies` is the player's caught set (WildRenderer's, kept live), so a heart greets a species they know.
-- The bootstrap hands in Screens.IsAnyOpen so an arrival's screen dim waits for a clear screen.
function Spectacle.SetPanelProbe(probe: (() -> boolean)?)
	panelProbe = probe
end

function Spectacle.Start(knownSpecies: { [string]: boolean })
	known = knownSpecies
	startedAt = os.clock()
	ensureRunning()
end

-- Dresses a wild part. Parts that appear within the first moments after Start were already there (the join): they get their
-- beacon and presence but no arrival.
function Spectacle.Track(part: Part, info: TrackInfo)
	if records[part] then
		Spectacle.Untrack(part)
	end
	local accentHex = EffectsMath.Accent(info.species)
	local accent = Theme.Hex(accentHex)
	local tierColor = if info.tier == "Secret" then accent else Builder.tierColor(info.tier)
	local _, yaw, _ = info.feet:ToEulerAnglesYXZ()
	local record: Record = {
		part = part,
		model = info.model,
		fxTarget = info.fxTarget,
		species = info.species,
		tier = info.tier,
		accent = accent,
		tierColor = tierColor,
		height = math.max(info.height, 0.5),
		home = info.feet.Position,
		baseYaw = yaw,
		seed = rng:NextNumber(),
		shown = true,
		visible = true,
		setVeil = info.setVeil,
		veiled = false,
		yaw = 0,
		lastPose = os.clock(),
		noticed = false,
		noticeAt = -math.huge,
		lastNear = -math.huge,
		greeted = false,
		flourished = false,
		wanderIndex = math.huge,
		wanderFrom = Vector3.zero,
		wanderTo = Vector3.zero,
		stepAcc = 0,
		lastOffset = Vector3.zero,
		moving = false,
		sleeping = false,
		zzAt = -math.huge,
		pose = { offset = Vector3.zero, yaw = 0, pitch = 0, roll = 0 },
		active = false,
		host = nil,
		pool = {},
		ornaments = {},
		trail = nil,
		ambient = nil,
		presenceMade = {},
		beacon = nil,
		beaconWanted = false,
		arrival = nil,
		bubble = nil,
	}
	records[part] = record
	table.insert(list, record)
	local now = os.clock()
	if now - startedAt > ARRIVAL_GRACE then
		startArrival(record, now)
	end
	lastRecheck = -math.huge
	ensureRunning()
end

-- Drops a part's spectacle (its presence, beacon, bubble and any arrival still playing).
function Spectacle.Untrack(part: Part)
	local record = records[part]
	if not record then
		return
	end
	records[part] = nil
	local at = table.find(list, record)
	if at then
		table.remove(list, at)
	end
	endArrival(record)
	dropPresence(record)
	dropBeacon(record)
	local bubble = record.bubble
	if bubble then
		bubble:Destroy()
	end
end

-- The pose WildRenderer adds to the alien this frame: (offset studs, extra yaw, pitch, roll radians). An untracked part adds
-- nothing.
function Spectacle.PoseOf(part: Part): (Vector3, number, number, number)
	local record = records[part]
	if not record then
		return Vector3.zero, 0, 0, 0
	end
	local pose = computePose(record, os.clock())
	return pose.offset, pose.yaw, pose.pitch, pose.roll
end

-- The alien is drawn in colour (`shown`: not hidden, not a silhouette) and at all (`visible`: not hidden by the blizzard). A
-- silhouette wears no presence (its colour would give the species away) but keeps its beacon (the tier's colour); a hidden one
-- wears neither.
function Spectacle.SetShown(part: Part, shown: boolean, visible: boolean)
	local record = records[part]
	if not record or (record.shown == shown and record.visible == visible) then
		return
	end
	record.shown = shown
	record.visible = visible
	lastRecheck = -math.huge
end

-- Whether an arrival has this part veiled right now (WildRenderer keeps it hidden meanwhile).
function Spectacle.IsVeiled(part: Part): boolean
	local record = records[part]
	return record ~= nil and record.veiled
end

-- A catch begins on `part`: if the server removes it, its clone is handed here for the outro.
function Spectacle.Focus(part: Part?)
	focus = part
	pendingOutcome = nil
end

-- WildRenderer, removing a part: answers true when it takes the clone over (the part is the catch's focus), in which case the
-- caller must not destroy it.
function Spectacle.TakeOver(part: Part, model: Model?): boolean
	if part ~= focus or not model or not model.Parent then
		return false
	end
	local record = records[part]
	local tier = if record then record.tier else "Common"
	local accent = if record then record.accent else Theme.Colors.White
	local height = if record then record.height else 2
	if held then
		finishHeld()
	end
	focus = nil
	setModelAlpha(model, 0)
	held = { model = model, tier = tier, accent = accent, height = height, at = os.clock(), outcome = nil, playing = false }
	ensureRunning()
	tryPlayHeld()
	return true
end

-- The server's verdict on the focused catch: "Caught" (with the tier) or "Fled".
function Spectacle.Verdict(outcome: string, tier: string?)
	pendingOutcome = { outcome = outcome, tier = tier or "", at = os.clock() }
	tryPlayHeld()
end

-- The catch ended without a verdict for an alien (refused, dropped): nothing will be handed over.
function Spectacle.ClearFocus()
	focus = nil
end

-- The colour a species flashes the capture bar in (its accent).
function Spectacle.AlienColor(speciesId: string): Color3
	return Theme.Hex(EffectsMath.Accent(speciesId))
end

return Spectacle
