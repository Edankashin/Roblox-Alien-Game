--!strict
-- StarterPlayerScripts.Client.World.SpeciesFx: the per-species effects and idle motion (data/Effects), drawn on the client
-- under the thing that is the alien: a mesh clone (a Model) or a placeholder part. Pure presentation: callers already know
-- the species and tier from the server's record. The tier aura (WildRenderer's light and glow) stays the base layer; this
-- module adds the species layers the tier allows (Shared/EffectsMath.LayersFor: B46's steep ladder, from one subtle touch on a
-- Common to eight layers, a pillar of light and a spawn moment on a Cosmic), scaled by the tier's rate, size and light scales,
-- held under the device's emitter-rate, burst and per-alien budgets (UserInputService.TouchEnabled is a phone).
-- Attach(target, speciesId, tier, opts) registers an alien and returns its cleanup. Nothing is built until the alien is among
-- the nearest Effects.Caps.MaxActive (MaxActiveMobile on a phone) on screen (re-ranked every Config.VfxFxRecheckSeconds by
-- distance to the camera, within Effects.Caps.ActiveDistance): the farther ones keep only the aura, and an alien that falls out
-- of the ranking has its layers switched off, not destroyed. Past Caps.NearDistance an active alien's rates and bursts drop to
-- Caps.FarRateScale and its sparkles stop. Hidden or silhouetted aliens call SetShown(target, false).
-- Layers hang on named body regions (Effects.Attach, fractions of the alien's measured bounds): a Model gets one invisible
-- anchor part ("FxAnchor") at its pivot and every Attachment lives on it, so PivotTo carries them all; a part hosts its own.
-- A layer may instead hang on a signature piece (Effects.Pieces, Rare and up): its Attachment goes on the model's part of that
-- name (the rig's moving object), at the piece's spot in the part's box, so it rides every spin, sway and pop World.RigAnimator
-- gives the part (an orbiting comet carries its own trail, a pane its light). A model without the part (an old blockout) hangs the
-- layer on the piece's fallback region instead (EffectsMath.Place). A pillar's sky end always stays on the anchor, straight up.
-- Kinds: an Emitter flows; a Burst, Sparkle or RingPulse fires `count` particles on its own clock (`every`, slid per alien so a
-- crowd is out of step) and/or on the flourish; an Aura holds large glow sprites on the body; a Beam (lightning) strikes every
-- `flicker` seconds and redraws its bend a few times per strike; a Trail is a ribbon; Orbit motes circle on attachments that
-- move every frame; a Light may pulse, and flares on the flourish; a Pillar is a column of light straight up, shown only on the
-- flourish. All of that is one RenderStepped connection over the active aliens, connected while any alien is attached. Every
-- motion is an absolute function of os.clock() (EffectsMath), never accumulated.
-- Flourish: a tier with `flourish` (Legendary and up) runs its own timer per alien (EffectsMath.FlourishEvery, the first one
-- slid by the alien's phase). Another client module (the rig animator) may call Flourish(target) on its own timer instead: the
-- alien's own timer then stands down for Look.ExternalHold periods, so the two never double up. OnFlourish(callback) hears
-- every flourish that plays, from either side, so an animation can ride the effect.
-- Spawn moment: a wild arrival of a tier with `spawnMoment` (Cosmic and Secret; WildRenderer passes opts.arrival, the server's
-- spawn part) plays Effects.SpawnMoment once per arrival (a pillar into the sky, rings rolling out, a star burst), seen from
-- Caps.MomentDistance whether or not the alien is among the nearest, at most Caps.MaxMoments at once.
-- Idle motion cannot be a tween on the target's pivot: the renderers write the pivot absolutely every frame (a bob), and an
-- offset added to it would be lost on a frame they run first and double on a frame they skip (a culled alien). So the renderer
-- composes it: it calls Place(target, pivot) where it used to PivotTo or set CFrame, and Place writes pivot * the idle offset
-- (a Model also swings its named wing parts about hinges, from the same pivot). An alien that is not attached is placed
-- exactly as before. A renderer that does not call Place for an alien (culled, hidden) gets no motion and no drift.
-- Reduced Motion (Prefs; the game's low-effects switch): idle motion holds, and every emitter, burst, sparkle, ring, beam,
-- trail, orbit, aura, pillar, flourish and spawn moment drops out for one still glow (the species' own light held steady, or
-- Effects.Reduced). Breathe rocks the alien about its feet instead of scaling it: a ScaleTo every frame would also rescale
-- every attachment, emitter and beam parented under the model and pile up float error.
-- Sound: a species row with a `sound` (a key of data/Sounds) plays it as a 3D one-shot at the alien (Builder.playSoundAt, through
-- the UI sound group, so the player's Sounds level applies) while the alien is active and not under Reduced Motion's still glow,
-- on its signature beat: the strike of its first beam, else the start of its idle cycle (EffectsMath.SoundClock and SoundBeat).
-- One alien plays at most once per Effects.Look.SoundEverySeconds, and all aliens together start at most
-- Effects.Caps.MaxSoundsPerSecond a second. An alien that has only just come up (or come back into the nearest) does not play
-- on its first frame: it waits for its next beat.
-- World.Vfx requires CampRenderer, so this module (which CampRenderer requires) keeps its own small emitter code.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Effects = require(Shared:WaitForChild("data"):WaitForChild("Effects"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local EffectsMath = require(Shared:WaitForChild("EffectsMath"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local SpeciesFx = {}

local ANCHOR_NAME = "FxAnchor"
local LIGHT_RANGE_LIMIT = 60 -- the engine's ceiling for PointLight.Range
local UPRIGHT_Y = 0.9 -- a part whose up vector is at least this vertical is upright; a rolled cylinder is not
local WHITE = "FFFFFF"

export type Options = {
	scale: number?, -- the alien's size against a 1.0-scale one: it multiplies the idle amplitude (studs); the layers read the real bounds
	sizeScale: number?, -- an extra factor on particle, beam and light sizes
	keepFacing: boolean?, -- the renderer owns the facing (camp, companions): a Spin species does not turn
	arrival: Instance?, -- a wild arrival (the server's spawn part): its spawn moment plays once per arrival, at a tier that has one
}

type Bounds = { minX: number, minY: number, minZ: number, sizeX: number, sizeY: number, sizeZ: number }
type FlapPart = { part: BasePart, rest: CFrame, hinge: Vector3, side: number, scale0: number } -- rest and hinge are in the pivot's space at the model's scale `scale0`
type BeamRig = { beam: Beam, flicker: number, length: number, offset: number, step: number }
type OrbitRig = { motes: { Attachment }, centre: Vector3, radius: number, period: number }
type LightRig = { light: PointLight, base: number, pulse: number, flareAt: number }
type FlowRig = { emitter: ParticleEmitter, rate: number } -- an emitter that flows at a rate (Emitter, Orbit mote, Aura)
-- An emitter that fires: `count` at once on its clock (`every`, nil for the flourish only) and/or on the flourish.
type FiredRig = { emitter: ParticleEmitter, kind: Types.EffectKind, count: number, every: number?, offset: number, beat: number?, flourish: boolean }
type PillarRig = { outer: Beam, core: Beam, width: number, life: number, born: number } -- born is -math.huge while dark
type MomentRig = { made: { Instance }, pillars: { PillarRig }, endsAt: number }

type Handle = {
	target: Instance,
	model: Model?,
	part: BasePart?,
	speciesId: string,
	tier: string,
	scale: number,
	sizeScale: number,
	keepFacing: boolean,
	phase: number, -- radians, so a crowd of one species is not in step
	motion: Types.IdleMotion, -- what really plays (a Flap with no wing part bobs)
	flaps: { FlapPart },
	flapAngle: number,
	still: boolean, -- Reduced Motion as of the last build
	shown: boolean,
	wanted: boolean, -- the ranking's verdict during a recheck
	active: boolean, -- among the nearest, so its layers are on
	near: boolean, -- within Caps.NearDistance at the last ranking
	distance: number, -- studs to the camera at the last ranking
	built: boolean,
	dead: boolean,
	bounds: Bounds?,
	pieces: { [string]: BasePart | false }, -- the model's part for each piece part name looked up so far (false: not there)
	host: BasePart?,
	anchor: Part?,
	made: { Instance }, -- everything built on the host, for teardown
	flowing: { FlowRig },
	fired: { FiredRig },
	trails: { Trail },
	lights: { LightRig },
	beams: { BeamRig },
	orbits: { OrbitRig },
	pillars: { PillarRig },
	flourishes: boolean, -- the tier runs its own flourish timer
	flourishEvery: number,
	nextFlourish: number?, -- os.clock() of its own next flourish; nil until the alien is up
	externalAt: number, -- os.clock() of the last Flourish from outside
	momentUntil: number, -- os.clock() past which a pending spawn moment is dropped
	moment: MomentRig?,
	soundId: string?, -- the species' sound as an asset id; nil when it has none or the id is still a placeholder
	soundPeriod: number, -- the beat the sound rides (EffectsMath.SoundClock), set at each build
	soundOffset: number,
	soundBeat: number?, -- the beat the last frame fell in; nil until the alien has been seen once
	soundAt: number, -- os.clock() when it last played
	destroying: RBXScriptConnection?,
}

local handles: { [Instance]: Handle } = {}
local count = 0
local renderConn: RBXScriptConnection? = nil
local prefsConn: RBXScriptConnection? = nil
local lastRecheck = -math.huge
local rng = Random.new()
local mobile = UserInputService.TouchEnabled
local maxActive = if mobile then Effects.Caps.MaxActiveMobile else Effects.Caps.MaxActive
local flourished = Instance.new("BindableEvent")
-- Recheck buffers, cleared and refilled rather than rebuilt.
local eligible: { Handle } = {}
local distances: { number } = {}
local picked: { [number]: boolean } = {}
local actives: { Handle } = {}
local recentSounds: { number } = {} -- when sounds started in the last second, across all aliens (EffectsMath.TakeSoundSlot)
local pendingMoments: { Handle } = {} -- arrivals waiting to play their spawn moment
local moments: { MomentRig } = {} -- spawn moments now playing
local momentSeen: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- arrivals whose moment has been taken

local function noop() end

-- The asset id of a species' `sound` key, or nil when it names none or its id is a placeholder.
local function soundIdOf(key: string?): string?
	if key == nil then
		return nil
	end
	local id = (Sounds :: any)[key]
	if type(id) == "string" and not Builder.isSilent(id) then
		return id
	end
	return nil
end

-- Placement -------------------------------------------------------------------

-- The box around an alien in its pivot's space (the pivot is upright, the face toward -Z), measured from the parts of a
-- model other than the anchor, or the part's own size. An empty model counts as a unit cube.
local function measure(handle: Handle): Bounds
	local existing = handle.bounds
	if existing then
		return existing
	end
	local bounds: Bounds
	local model = handle.model
	local part = handle.part
	if model then
		local pivot = model:GetPivot()
		local minV = Vector3.new(math.huge, math.huge, math.huge)
		local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name ~= ANCHOR_NAME then
				local cf = pivot:ToObjectSpace(descendant.CFrame)
				local half = descendant.Size / 2
				local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
				local extent = Vector3.new(
					math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
					math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
					math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
				)
				minV = minV:Min(cf.Position - extent)
				maxV = maxV:Max(cf.Position + extent)
			end
		end
		if minV.X == math.huge then
			bounds = { minX = -0.5, minY = 0, minZ = -0.5, sizeX = 1, sizeY = 1, sizeZ = 1 }
		else
			local size = maxV - minV
			bounds = { minX = minV.X, minY = minV.Y, minZ = minV.Z, sizeX = size.X, sizeY = size.Y, sizeZ = size.Z }
		end
	elseif part then
		local size = part.Size
		bounds = { minX = -size.X / 2, minY = -size.Y / 2, minZ = -size.Z / 2, sizeX = size.X, sizeY = size.Y, sizeZ = size.Z }
	else
		bounds = { minX = -0.5, minY = 0, minZ = -0.5, sizeX = 1, sizeY = 1, sizeZ = 1 }
	end
	handle.bounds = bounds
	return bounds
end

-- The studs from the feet to the top of the alien.
local function heightOf(handle: Handle): number
	return math.max(measure(handle).sizeY, 0.1)
end

-- The part attachments live on: the part itself, or a model's invisible anchor at its pivot (made once; it sits just above
-- the feet so it never lengthens the model's bounds).
local function hostOf(handle: Handle): BasePart?
	local existing = handle.host
	if existing then
		return existing
	end
	local part = handle.part
	if part then
		handle.host = part
		return part
	end
	local model = handle.model
	if not model then
		return nil
	end
	local pivot = model:GetPivot()
	local anchor = Instance.new("Part")
	anchor.Name = ANCHOR_NAME
	anchor.Size = Vector3.one * Effects.Look.AnchorStuds
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.CFrame = pivot * CFrame.new(0, Effects.Look.AnchorStuds / 2, 0)
	anchor.Parent = model
	if model.PrimaryPart == nil then
		model.WorldPivot = pivot -- adding a part must not move an implicit pivot
	end
	handle.anchor = anchor
	handle.host = anchor
	return anchor
end

-- The model's part named `name` (a signature piece's moving part): a BasePart of that name, else the largest BasePart under an
-- instance of that name (an import may wrap one object). Looked up once per model; nil for a part target or a missing part.
local function pieceHost(handle: Handle, name: string): BasePart?
	local cached = handle.pieces[name]
	if cached == false then
		return nil
	elseif cached ~= nil then
		return cached :: BasePart
	end
	local found: BasePart? = nil
	local model = handle.model
	if model then
		local node = model:FindFirstChild(name, true)
		if node and node:IsA("BasePart") then
			found = node
		elseif node then
			local best = -1
			for _, descendant in ipairs(node:GetDescendants()) do
				if descendant:IsA("BasePart") then
					local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
					if volume > best then
						best, found = volume, descendant
					end
				end
			end
		end
	end
	handle.pieces[name] = found or false
	return found
end

-- A region's position in the host's space.
local function regionPoint(handle: Handle, region: string): Vector3
	local bounds = measure(handle)
	local x, y, z = EffectsMath.AttachOffset(region, bounds.minX, bounds.minY, bounds.minZ, bounds.sizeX, bounds.sizeY, bounds.sizeZ)
	local part = handle.part
	if part then
		if part.CFrame.UpVector.Y >= UPRIGHT_Y then
			return Vector3.new(x, y, z)
		end
		return part.CFrame:VectorToObjectSpace(Vector3.new(x, y, z)) -- a rolled placeholder: keep "up" up
	end
	return Vector3.new(x, y - Effects.Look.AnchorStuds / 2, z)
end

local function attachmentAt(host: BasePart, name: string, position: Vector3, made: { Instance }): Attachment
	local point = Instance.new("Attachment")
	point.Name = name
	point.Position = position
	point.Parent = host
	table.insert(made, point)
	return point
end

-- Where a layer's point `at` hangs: the piece's part and the spot in its space, or the host and the region's point in its space.
local function placeIn(handle: Handle, host: BasePart, at: string): (BasePart, Vector3)
	local place = EffectsMath.Place(at, function(name: string): boolean
		return pieceHost(handle, name) ~= nil
	end)
	local partName = place.part
	local piece = if partName then pieceHost(handle, partName) else nil
	if piece then
		local size = piece.Size
		return piece, Vector3.new(place.x * size.X, place.y * size.Y, place.z * size.Z)
	end
	return host, regionPoint(handle, place.region)
end

local function attachment(handle: Handle, host: BasePart, at: string, made: { Instance }): Attachment
	local parent, position = placeIn(handle, host, at)
	return attachmentAt(parent, "Fx" .. at, position, made)
end

-- Layers -----------------------------------------------------------------------

local EMISSION: { [string]: Enum.NormalId } = {
	Up = Enum.NormalId.Top,
	Front = Enum.NormalId.Front,
	Back = Enum.NormalId.Back,
	Down = Enum.NormalId.Bottom,
}

local function keypoints(...: NumberSequenceKeypoint): NumberSequence
	return NumberSequence.new({ ... })
end

-- The sprite a layer's key draws (EffectsMath.SpriteFor: the key, its fallback, or the soft default), with its flipbook.
local function dressSprite(emitter: ParticleEmitter, key: string?)
	local id, sheet = EffectsMath.SpriteFor(key)
	if id == nil then
		return
	end
	emitter.Texture = "rbxassetid://" .. id
	if sheet then
		local layout = (Enum.ParticleFlipbookLayout :: any)[sheet.layout]
		local mode = (Enum.ParticleFlipbookMode :: any)[sheet.mode]
		if layout and mode then
			emitter.FlipbookLayout = layout
			emitter.FlipbookMode = mode
			emitter.FlipbookFramerate = NumberRange.new(sheet.fps)
		end
	end
end

-- A particle emitter for a resolved layer (still in heights) on `parent`, off: an Emitter, an Orbit mote or an Aura flows at
-- its rate once switched on; a Burst, Sparkle or RingPulse has no rate and only ever Emits.
local function makeEmitter(parent: Instance, layer: Types.EffectLayer, height: number): ParticleEmitter
	local look = Effects.Look
	local kind = layer.kind
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = if kind == "Burst" or kind == "Sparkle" or kind == "RingPulse" then 0 else layer.rate or 0
	emitter.Color = ColorSequence.new(Theme.Hex(layer.color))
	emitter.LightEmission = layer.glow or look.DefaultGlow
	local size = (layer.size or 0) * height
	local fade = keypoints(
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(look.FadeIn, look.PeakTransparency),
		NumberSequenceKeypoint.new(look.FadeOut, look.PeakTransparency),
		NumberSequenceKeypoint.new(1, 1)
	)
	local speed = (layer.speed or 0) * height
	local spread = layer.spread or 0
	if kind == "RingPulse" or layer.flat then
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, size * look.RingFrom), NumberSequenceKeypoint.new(1, size))
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		speed = math.max(speed, look.RingDrift * height)
		if kind == "RingPulse" then
			spread = 0
		end
	elseif kind == "Sparkle" then
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(look.SparklePeak, size), NumberSequenceKeypoint.new(1, 0))
		emitter.LockedToPart = true
		speed = 0
	elseif kind == "Aura" then
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, size * look.AuraFrom), NumberSequenceKeypoint.new(1, size))
		emitter.LockedToPart = true
		speed = 0
		spread = 0
		fade = keypoints(
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(look.FadeIn, look.AuraTransparency),
			NumberSequenceKeypoint.new(look.FadeOut, look.AuraTransparency),
			NumberSequenceKeypoint.new(1, 1)
		)
	else
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * look.EndSize))
	end
	emitter.Transparency = fade
	emitter.Lifetime = NumberRange.new(layer.lifetime or 1)
	emitter.Speed = NumberRange.new(speed * look.SpeedSpread, speed)
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.Acceleration = Vector3.new(0, (layer.rise or 0) * height, 0)
	emitter.EmissionDirection = EMISSION[layer.dir or "Up"] or Enum.NormalId.Top
	local spin = layer.spin or (if kind == "Sparkle" then look.SparkleSpin else nil)
	if spin ~= nil then
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(spin)
	end
	dressSprite(emitter, layer.sprite)
	emitter.Parent = parent
	return emitter
end

local function buildFlowing(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local emitter = makeEmitter(attachment(handle, host, layer.at, handle.made), layer, height)
	table.insert(handle.made, emitter)
	table.insert(handle.flowing, { emitter = emitter, rate = emitter.Rate })
end

local function buildFired(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local emitter = makeEmitter(attachment(handle, host, layer.at, handle.made), layer, height)
	table.insert(handle.made, emitter)
	local every = layer.every
	table.insert(handle.fired, {
		emitter = emitter,
		kind = layer.kind,
		count = layer.count or 1,
		every = every,
		offset = if every then rng:NextNumber(0, every) else 0,
		beat = nil,
		flourish = layer.flourish == true,
	})
end

-- A column of light from a region straight up `reach` heights: an outer beam in the layer's colour and a core beam nearer
-- white, both dark until a flourish (or a spawn moment) lights them.
local function buildPillar(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number, made: { Instance }): PillarRig
	local look = Effects.Look
	local from = attachment(handle, host, layer.at, made)
	local up = host.CFrame:VectorToObjectSpace(Vector3.yAxis) * (layer.reach or 0) * height
	local to = attachmentAt(host, "FxSky", host.CFrame:PointToObjectSpace(from.WorldPosition) + up, made) -- on the anchor: straight up, even from a turning piece
	local width = (layer.width or 0) * height
	local function beam(color: string, across: number): Beam
		local made1 = Instance.new("Beam")
		made1.Attachment0 = from
		made1.Attachment1 = to
		made1.Color = ColorSequence.new(Theme.Hex(color))
		made1.LightEmission = 1
		made1.LightInfluence = 0
		made1.FaceCamera = true
		made1.Segments = 1
		made1.Width0 = across
		made1.Width1 = across
		made1.Transparency = NumberSequence.new(1)
		made1.Enabled = false
		made1.Parent = host
		table.insert(made, made1)
		return made1
	end
	local outer = beam(layer.color, width)
	local core = beam(EffectsMath.Mix(layer.color, WHITE, look.CoreMix), width * look.CoreWidth)
	return { outer = outer, core = core, width = width, life = layer.lifetime or 1, born = -math.huge }
end

local function buildBeam(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local look = Effects.Look
	local from = attachment(handle, host, layer.at, handle.made)
	local to = attachment(handle, host, layer.to or layer.at, handle.made)
	local length = (to.WorldPosition - from.WorldPosition).Magnitude -- the ends may sit on different parts (a piece and a region)
	if length <= 0 then
		return -- both ends on one spot: nothing to strike between
	end
	local width = (layer.width or 0) * height
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Color = ColorSequence.new(Theme.Hex(layer.color))
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Width0 = width
	beam.Width1 = width
	beam.Segments = math.max(layer.segments or 1, 1)
	beam.Transparency = NumberSequence.new(look.BeamTransparency)
	beam.Enabled = false
	beam.Parent = host
	table.insert(handle.made, beam)
	local flicker = layer.flicker or 0
	table.insert(handle.beams, { beam = beam, flicker = flicker, length = length, offset = rng:NextNumber(0, math.max(flicker, 0.01)), step = 0 })
end

local function buildLight(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number, steady: boolean)
	local light = Instance.new("PointLight")
	light.Color = Theme.Hex(layer.color)
	light.Brightness = layer.brightness or 0
	light.Range = math.min((layer.range or 0) * height, LIGHT_RANGE_LIMIT)
	light.Shadows = false
	light.Enabled = false
	light.Parent = attachment(handle, host, layer.at, handle.made)
	table.insert(handle.lights, { light = light, base = light.Brightness, pulse = if steady then 0 else layer.pulse or 0, flareAt = -math.huge })
end

local function buildTrail(handle: Handle, host: BasePart, layer: Types.EffectLayer)
	local look = Effects.Look
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment(handle, host, layer.at, handle.made)
	trail.Attachment1 = attachment(handle, host, layer.to or "Feet", handle.made)
	trail.Color = ColorSequence.new(Theme.Hex(layer.color))
	trail.LightEmission = layer.glow or look.DefaultGlow
	trail.Lifetime = layer.lifetime or 1
	trail.FaceCamera = true
	trail.Transparency = keypoints(NumberSequenceKeypoint.new(0, look.TrailTransparency), NumberSequenceKeypoint.new(1, 1))
	local width = layer.width or 1
	trail.WidthScale = keypoints(NumberSequenceKeypoint.new(0, width), NumberSequenceKeypoint.new(1, width * look.TrailTaper))
	trail.Enabled = false
	trail.Parent = host
	table.insert(handle.made, trail)
	table.insert(handle.trails, trail)
end

-- The motes of an orbit: `count` attachments on a circle about the region, each with a small emitter whose particles stay
-- where they were born, so a mote draws its own arc.
local function buildOrbit(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local motes: { Attachment } = {}
	local parent, centre = placeIn(handle, host, layer.at) -- on a piece, the circle rides the part
	for _ = 1, math.max(layer.count or 1, 1) do
		local mote = attachmentAt(parent, "FxMote", centre, handle.made)
		table.insert(motes, mote)
		local emitter = makeEmitter(mote, layer, height)
		table.insert(handle.made, emitter)
		table.insert(handle.flowing, { emitter = emitter, rate = emitter.Rate })
	end
	table.insert(handle.orbits, { motes = motes, centre = centre, radius = (layer.radius or 0) * height, period = layer.period or 1 })
end

local function teardown(handle: Handle)
	for _, made in ipairs(handle.made) do
		made:Destroy()
	end
	table.clear(handle.made)
	table.clear(handle.flowing)
	table.clear(handle.fired)
	table.clear(handle.trails)
	table.clear(handle.lights)
	table.clear(handle.beams)
	table.clear(handle.orbits)
	table.clear(handle.pillars)
	handle.built = false
end

-- Builds the layers the tier allows (the still glow only, under Reduced Motion), all off, held under the per-alien budget.
local function build(handle: Handle)
	handle.built = true
	handle.still = Prefs.ReducedMotion()
	local host = hostOf(handle)
	if not host then
		return
	end
	local height = heightOf(handle)
	local layers = EffectsMath.LayersFor(handle.speciesId, handle.tier)
	if handle.still then
		local glow: { Types.EffectLayer } = {}
		for _, layer in ipairs(layers) do
			if layer.kind == "Light" then
				table.insert(glow, layer)
			end
		end
		if #glow == 0 and #layers > 0 then
			local first = layers[1]
			table.insert(glow, { kind = "Light", color = first.color, at = "Body", brightness = Effects.Reduced.GlowBrightness, range = Effects.Reduced.GlowRange })
		end
		layers = glow
	end
	local resolved: { Types.EffectLayer } = {}
	for _, layer in ipairs(layers) do
		table.insert(resolved, EffectsMath.Resolve(layer, handle.tier, mobile, handle.sizeScale))
	end
	EffectsMath.FitBudget(resolved, mobile)
	for _, layer in ipairs(resolved) do
		local kind = layer.kind
		if kind == "Emitter" or kind == "Aura" then
			buildFlowing(handle, host, layer, height)
		elseif kind == "Burst" or kind == "Sparkle" or kind == "RingPulse" then
			buildFired(handle, host, layer, height)
		elseif kind == "Beam" then
			buildBeam(handle, host, layer, height)
		elseif kind == "Light" then
			buildLight(handle, host, layer, height, handle.still)
		elseif kind == "Trail" then
			buildTrail(handle, host, layer)
		elseif kind == "Orbit" then
			buildOrbit(handle, host, layer, height)
		elseif kind == "Pillar" then
			table.insert(handle.pillars, buildPillar(handle, host, layer, height, handle.made))
		end
	end
	local firstBeam = handle.beams[1]
	handle.soundPeriod, handle.soundOffset = EffectsMath.SoundClock(
		if firstBeam then firstBeam.flicker else nil,
		if firstBeam then firstBeam.offset else 0,
		handle.motion.period,
		handle.phase
	)
	handle.soundBeat = nil
end

-- The flowing rates at the alien's distance: full near the camera, Caps.FarRateScale of them beyond Caps.NearDistance.
local function applyRates(handle: Handle)
	local factor = if handle.near then 1 else Effects.Caps.FarRateScale
	for _, rig in ipairs(handle.flowing) do
		rig.emitter.Rate = rig.rate * factor
	end
end

local function darkenPillar(rig: PillarRig)
	rig.born = -math.huge
	rig.outer.Enabled = false
	rig.core.Enabled = false
end

-- Switches a built alien's layers on or off. Beams follow their own strike clock, firings their own clocks, in the frame step.
local function setEnabled(handle: Handle, on: boolean)
	for _, rig in ipairs(handle.flowing) do
		rig.emitter.Enabled = on
	end
	for _, trail in ipairs(handle.trails) do
		trail.Enabled = on
	end
	for _, rig in ipairs(handle.lights) do
		rig.light.Enabled = on
	end
	if on then
		applyRates(handle)
	else
		for _, rig in ipairs(handle.beams) do
			rig.beam.Enabled = false
			rig.step = 0
		end
		for _, rig in ipairs(handle.fired) do
			rig.beat = nil
		end
		for _, rig in ipairs(handle.pillars) do
			darkenPillar(rig)
		end
		handle.soundBeat = nil
		handle.nextFlourish = nil
	end
end

-- Firing and the flourish ---------------------------------------------------------

-- Throws one firing: `count` particles at once (a RingPulse's rings one after another, Look.RingStagger apart). A sparkle beyond
-- Caps.NearDistance is too small to see and is skipped; any other firing throws Caps.FarRateScale of its count there.
local function fire(rig: FiredRig, near: boolean)
	if rig.kind == "Sparkle" and not near then
		return
	end
	local total = EffectsMath.FarCount(rig.count, near)
	local emitter = rig.emitter
	if rig.kind == "RingPulse" and total > 1 then
		emitter:Emit(1)
		for index = 1, total - 1 do
			task.delay(index * Effects.Look.RingStagger, function()
				if emitter.Parent ~= nil then
					emitter:Emit(1)
				end
			end)
		end
		return
	end
	emitter:Emit(total)
end

-- A column of light rises now.
local function lightPillar(rig: PillarRig, now: number)
	rig.born = now
	rig.outer.Enabled = true
	rig.core.Enabled = true
end

-- Plays a flourish on an active alien: every firing marked `flourish`, every pillar, and a flare of its lights. Answers whether
-- anything played (an alien whose tier draws nothing for the flourish plays nothing). OnFlourish hears it.
local function flourish(handle: Handle, now: number): boolean
	if handle.still or not handle.active or not handle.built then
		return false
	end
	local played = false
	for _, rig in ipairs(handle.fired) do
		if rig.flourish then
			fire(rig, handle.near)
			played = true
		end
	end
	for _, rig in ipairs(handle.pillars) do
		lightPillar(rig, now)
		played = true
	end
	if played then
		for _, rig in ipairs(handle.lights) do
			rig.flareAt = now
		end
		flourished:Fire(handle.target, handle.speciesId)
	end
	return played
end

-- A pillar's look at `now`: faded in and out over its life (EffectsMath.Envelope), dark again once its life is over.
local function stepPillar(rig: PillarRig, now: number)
	if rig.born == -math.huge then
		return
	end
	local look = Effects.Look
	local k = (now - rig.born) / rig.life
	if k >= 1 then
		darkenPillar(rig)
		return
	end
	local strength = EffectsMath.Envelope(k, look.PillarIn, look.PillarOut)
	local transparency = NumberSequence.new(1 - (1 - look.PillarTransparency) * strength)
	local across = rig.width * (0.5 + 0.5 * strength)
	rig.outer.Transparency = transparency
	rig.outer.Width0 = across
	rig.outer.Width1 = across
	rig.core.Transparency = transparency
	rig.core.Width0 = across * look.CoreWidth
	rig.core.Width1 = across * look.CoreWidth
end

-- The spawn moment ----------------------------------------------------------------

local function endMoment(rig: MomentRig)
	for _, made in ipairs(rig.made) do
		made:Destroy()
	end
	table.clear(rig.made)
	table.clear(rig.pillars)
	local at = table.find(moments, rig)
	if at then
		table.remove(moments, at)
	end
end

-- Plays an arrival's spawn moment now: its own one-off parts on the host, removed once the longest piece is over.
local function playMoment(handle: Handle, now: number)
	local host = hostOf(handle)
	if not host then
		return
	end
	local height = heightOf(handle)
	local rig: MomentRig = { made = {}, pillars = {}, endsAt = now }
	local longest = 0
	for _, layer in ipairs(EffectsMath.MomentFor(handle.speciesId, handle.tier)) do
		local resolved = EffectsMath.Resolve(layer, handle.tier, mobile, handle.sizeScale)
		local life = resolved.lifetime or 1
		if resolved.kind == "Pillar" then
			local pillar = buildPillar(handle, host, resolved, height, rig.made)
			lightPillar(pillar, now)
			table.insert(rig.pillars, pillar)
		else
			local emitter = makeEmitter(attachment(handle, host, resolved.at, rig.made), resolved, height)
			table.insert(rig.made, emitter)
			local total = resolved.count or 1
			fire({ emitter = emitter, kind = resolved.kind, count = total, every = nil, offset = 0, beat = nil, flourish = false }, true)
			if resolved.kind == "RingPulse" then
				life += (total - 1) * Effects.Look.RingStagger
			end
		end
		longest = math.max(longest, life)
	end
	rig.endsAt = now + longest + Effects.Look.MomentSlack
	handle.moment = rig
	table.insert(moments, rig)
end

local function positionOf(handle: Handle): Vector3
	local model = handle.model
	if model then
		return model:GetPivot().Position
	end
	local part = handle.part
	return if part then part.Position else Vector3.zero
end

-- Starts the pending spawn moments that may: within Caps.MomentDistance of the camera and under Caps.MaxMoments at once. One
-- not started by Look.MomentWindow after its arrival is dropped (the moment is the arrival; later it means nothing).
local function stepMoments(now: number)
	for index = #moments, 1, -1 do
		local rig = moments[index]
		for _, pillar in ipairs(rig.pillars) do
			stepPillar(pillar, now)
		end
		if now >= rig.endsAt then
			endMoment(rig)
		end
	end
	if #pendingMoments == 0 then
		return
	end
	local camera = Workspace.CurrentCamera
	local reduced = Prefs.ReducedMotion()
	for index = #pendingMoments, 1, -1 do
		local handle = pendingMoments[index]
		if handle.dead or reduced or now > handle.momentUntil then
			table.remove(pendingMoments, index)
		elseif #moments < Effects.Caps.MaxMoments and camera and handle.target:IsDescendantOf(Workspace) then
			if (positionOf(handle) - camera.CFrame.Position).Magnitude <= Effects.Caps.MomentDistance then
				table.remove(pendingMoments, index)
				playMoment(handle, now)
			end
		end
	end
end

-- Idle motion --------------------------------------------------------------------

-- (lift in studs, yaw, pitch in radians) now: nothing under Reduced Motion, and no yaw where the renderer owns the facing.
local function pose(handle: Handle): (number, number, number)
	if handle.still then
		return 0, 0, 0
	end
	local lift, yaw, pitch = EffectsMath.Idle(handle.motion, os.clock(), handle.phase, handle.scale)
	if handle.keepFacing then
		yaw = 0
	end
	return lift, yaw, pitch
end

-- A wing part's rest pose and hinge against the pivot at the model's scale now (a ScaleTo since the capture scales the offsets).
local function flapFrame(handle: Handle, flap: FlapPart): (CFrame, Vector3)
	local model = handle.model
	local k = if model then model:GetScale() / flap.scale0 else 1
	return CFrame.new(flap.rest.Position * k) * flap.rest.Rotation, flap.hinge * k
end

-- Swings a model's named wing parts about their hinges, from the pivot the model now stands at. Absolute: the same pivot and
-- angle give the same pose however many frames were skipped. An alien that is not active holds its wings at rest.
local function poseFlaps(handle: Handle, pivot: CFrame)
	if #handle.flaps == 0 then
		return
	end
	local angle = 0
	if handle.active and not handle.still then
		angle = EffectsMath.FlapAngle(handle.motion, os.clock(), handle.phase)
	end
	if angle == 0 and handle.flapAngle == 0 then
		return
	end
	handle.flapAngle = angle
	for _, flap in ipairs(handle.flaps) do
		local rest, hinge = flapFrame(handle, flap)
		local swing = CFrame.new(hinge) * CFrame.Angles(0, 0, angle * flap.side) * CFrame.new(-hinge)
		flap.part.CFrame = pivot * swing * rest
	end
end

-- The named wing parts of a model, each with where it rests against the pivot and the hinge it swings about: the edge of the
-- part nearest the body's centre line, along the front-to-back axis.
local function findFlaps(model: Model, names: { string }?): { FlapPart }
	local found: { FlapPart } = {}
	if not names then
		return found
	end
	local pivot = model:GetPivot()
	local scale0 = model:GetScale()
	for _, name in ipairs(names) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			local rest = pivot:ToObjectSpace(part.CFrame)
			local side = if rest.Position.X < 0 then -1 else 1
			local half = part.Size / 2
			local extentX = math.abs(rest.RightVector.X) * half.X + math.abs(rest.UpVector.X) * half.Y + math.abs(rest.LookVector.X) * half.Z
			local hinge = Vector3.new(rest.Position.X - side * extentX, rest.Position.Y, rest.Position.Z)
			table.insert(found, { part = part, rest = rest, hinge = hinge, side = side, scale0 = scale0 })
		end
	end
	return found
end

-- Ranking and the frame step ---------------------------------------------------------

-- Ranks every shown alien in the world by distance to the camera: the nearest `maxActive` within Effects.Caps.ActiveDistance
-- are active (built on first use, then switched on); every other alien is switched off. An active alien beyond
-- Caps.NearDistance draws at Caps.FarRateScale.
local function recheck(now: number)
	lastRecheck = now
	local camera = Workspace.CurrentCamera
	table.clear(eligible)
	table.clear(distances)
	for _, handle in pairs(handles) do
		handle.wanted = false
		if camera and handle.shown and handle.target:IsDescendantOf(Workspace) then
			local distance = (positionOf(handle) - camera.CFrame.Position).Magnitude
			handle.distance = distance
			table.insert(eligible, handle)
			table.insert(distances, distance)
		end
	end
	EffectsMath.PickActive(distances, maxActive, Effects.Caps.ActiveDistance, picked)
	for index, handle in ipairs(eligible) do
		handle.wanted = picked[index] == true
	end
	table.clear(eligible)
	table.clear(actives)
	for _, handle in pairs(handles) do
		if handle.wanted then
			if not handle.built then
				build(handle)
			end
			table.insert(actives, handle)
		end
		local near = handle.distance <= Effects.Caps.NearDistance
		if handle.wanted ~= handle.active then
			handle.active = handle.wanted
			handle.near = near
			setEnabled(handle, handle.active)
		elseif handle.active and near ~= handle.near then
			handle.near = near
			applyRates(handle)
		end
	end
end

-- Plays an active alien's sound when its clock beats, if it is not too soon after its last and the second's budget has room.
local function soundStep(handle: Handle, now: number, soundOn: boolean)
	local id = handle.soundId
	if not id or handle.still then
		return
	end
	local beat = EffectsMath.SoundBeat(now, handle.soundPeriod, handle.soundOffset)
	local previous = handle.soundBeat
	handle.soundBeat = beat
	local host = handle.host
	if not soundOn or previous == nil or beat == previous or not host then
		return
	end
	local look = Effects.Look
	if not EffectsMath.SoundDue(now, handle.soundAt, look.SoundEverySeconds) then
		return
	end
	if not EffectsMath.TakeSoundSlot(recentSounds, now, Effects.Caps.MaxSoundsPerSecond) then
		return
	end
	handle.soundAt = now
	Builder.playSoundAt(id, host, look.SoundRollOffMin, look.SoundRollOffMax, look.SoundMaxSeconds)
end

-- An active alien's own clocks: its timed firings (a firing waits out the beat it came up in), and its flourish timer.
local function clockStep(handle: Handle, now: number)
	if handle.still then
		return
	end
	for _, rig in ipairs(handle.fired) do
		local every = rig.every
		if every then
			local beat = EffectsMath.Beat(now, every, rig.offset)
			local previous = rig.beat
			rig.beat = beat
			if previous ~= nil and beat ~= previous then
				fire(rig, handle.near)
			end
		end
	end
	if handle.flourishes then
		local nextAt = handle.nextFlourish
		if nextAt == nil then
			handle.nextFlourish = EffectsMath.FirstFlourish(now, handle.flourishEvery, handle.phase)
		elseif now >= nextAt then
			handle.nextFlourish = now + handle.flourishEvery
			if EffectsMath.FlourishDue(now, nextAt, handle.externalAt, handle.flourishEvery) then
				flourish(handle, now)
			end
		end
	end
end

-- Beams, orbit motes, pulsing and flaring lights, firings, pillars, flourishes, sounds and spawn moments.
local function step(_dt: number)
	local now = os.clock()
	if now - lastRecheck >= Config.VfxFxRecheckSeconds then
		recheck(now)
	end
	local soundOn = Prefs.SoundOn()
	for _, handle in ipairs(actives) do
		soundStep(handle, now, soundOn)
		clockStep(handle, now)
		for _, rig in ipairs(handle.beams) do
			local on, bend = EffectsMath.BeamState(now, rig.flicker, rig.offset)
			if on ~= rig.beam.Enabled then
				rig.beam.Enabled = on
			end
			if on and bend ~= rig.step then
				rig.step = bend
				local curve = rig.length * Effects.Look.BeamCurve
				rig.beam.CurveSize0 = rng:NextNumber(-1, 1) * curve
				rig.beam.CurveSize1 = rng:NextNumber(-1, 1) * curve
			end
		end
		for _, rig in ipairs(handle.orbits) do
			local motes = rig.motes
			for index, mote in ipairs(motes) do
				local angle = EffectsMath.OrbitAngle(now, rig.period, index, #motes, handle.phase)
				mote.Position = rig.centre + Vector3.new(math.cos(angle) * rig.radius, 0, math.sin(angle) * rig.radius)
			end
		end
		for _, rig in ipairs(handle.lights) do
			local flaring = now - rig.flareAt < Effects.Look.FlareSeconds
			if rig.pulse > 0 or flaring then
				local pulse = if rig.pulse > 0 then EffectsMath.Pulse(now, rig.pulse, handle.phase) else 1
				rig.light.Brightness = rig.base * pulse * EffectsMath.Flare(now - rig.flareAt)
			end
		end
		for _, rig in ipairs(handle.pillars) do
			stepPillar(rig, now)
		end
	end
	stepMoments(now)
end

-- Reduced Motion (or anything else Prefs applies) may have changed: an alien built the other way is rebuilt at the next ranking.
local function onPrefs()
	local still = Prefs.ReducedMotion()
	for _, handle in pairs(handles) do
		if handle.still ~= still then
			handle.still = still
			if handle.built then
				setEnabled(handle, false)
				teardown(handle)
				handle.active = false
			end
		end
	end
	lastRecheck = -math.huge
end

local function startRunning()
	if not renderConn then
		renderConn = RunService.RenderStepped:Connect(step)
	end
	if not prefsConn then
		prefsConn = Prefs.OnChanged(onPrefs)
	end
end

local function stopRunning()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	if prefsConn then
		prefsConn:Disconnect()
		prefsConn = nil
	end
	table.clear(actives)
	table.clear(pendingMoments)
	for index = #moments, 1, -1 do
		endMoment(moments[index])
	end
end

local function release(handle: Handle)
	if handle.dead then
		return
	end
	handle.dead = true
	local connection = handle.destroying
	if connection then
		connection:Disconnect()
		handle.destroying = nil
	end
	if handles[handle.target] == handle then
		handles[handle.target] = nil
		count -= 1
	end
	local at = table.find(actives, handle)
	if at then
		table.remove(actives, at)
	end
	local pending = table.find(pendingMoments, handle)
	if pending then
		table.remove(pendingMoments, pending)
	end
	local moment = handle.moment
	if moment then
		endMoment(moment)
		handle.moment = nil
	end
	if handle.target.Parent ~= nil and handle.flapAngle ~= 0 then
		handle.flapAngle = 0
		local pivot = if handle.model then handle.model:GetPivot() else CFrame.identity
		for _, flap in ipairs(handle.flaps) do
			local rest = flapFrame(handle, flap)
			flap.part.CFrame = pivot * rest -- wings back to rest where the model stands
		end
	end
	teardown(handle)
	local anchor = handle.anchor
	if anchor then
		anchor:Destroy()
		handle.anchor = nil
		handle.host = nil
	end
	if count <= 0 then
		count = 0
		stopRunning()
	end
end

-- Public API ---------------------------------------------------------------------

-- Gives `target` (the mesh clone, or the placeholder part when there is none) the effects and idle motion of `speciesId` at
-- `tier`. Effects come up when the alien is among the nearest on screen and stay under the target, so they move with it.
-- `opts.arrival` marks a wild arrival: a tier with a spawn moment plays it once per arrival instance. Returns the cleanup;
-- calling it twice is harmless, and so is attaching the same target again (the first is released). An unknown species or tier
-- attaches nothing.
function SpeciesFx.Attach(target: BasePart | Model, speciesId: string, tier: string, opts: Options?): () -> ()
	local fx = Effects.Species[speciesId]
	local rule = Effects.Tiers[tier]
	if not fx or not rule then
		return noop
	end
	local previous = handles[target]
	if previous then
		release(previous)
	end
	local model: Model? = nil
	local part: BasePart? = nil
	if target:IsA("Model") then
		model = target
	else
		part = target :: BasePart
	end
	local flaps = if model then findFlaps(model, fx.idle.parts) else {}
	local now = os.clock()
	local handle: Handle = {
		target = target,
		model = model,
		part = part,
		speciesId = speciesId,
		tier = tier,
		scale = if opts and opts.scale then opts.scale else 1,
		sizeScale = if opts and opts.sizeScale then opts.sizeScale else 1,
		keepFacing = opts ~= nil and opts.keepFacing == true,
		phase = rng:NextNumber(0, math.pi * 2),
		motion = EffectsMath.EffectiveMotion(fx.idle, #flaps > 0),
		flaps = flaps,
		flapAngle = 0,
		still = Prefs.ReducedMotion(),
		shown = true,
		wanted = false,
		active = false,
		near = true,
		distance = math.huge,
		built = false,
		dead = false,
		bounds = nil,
		pieces = {},
		host = nil,
		anchor = nil,
		made = {},
		flowing = {},
		fired = {},
		trails = {},
		lights = {},
		beams = {},
		orbits = {},
		pillars = {},
		flourishes = rule.flourish,
		flourishEvery = EffectsMath.FlourishEvery(speciesId),
		nextFlourish = nil,
		externalAt = -math.huge,
		momentUntil = now + Effects.Look.MomentWindow,
		moment = nil,
		soundId = soundIdOf(fx.sound),
		soundPeriod = 0,
		soundOffset = 0,
		soundBeat = nil,
		soundAt = -math.huge,
		destroying = nil,
	}
	handles[target] = handle
	count += 1
	handle.destroying = target.Destroying:Connect(function()
		release(handle)
	end)
	local arrival = if opts then opts.arrival else nil
	if arrival and rule.spawnMoment and not momentSeen[arrival] then
		momentSeen[arrival] = true
		table.insert(pendingMoments, handle)
	end
	lastRecheck = -math.huge -- rank on the next frame
	startRunning()
	return function()
		release(handle)
	end
end

-- Plays the flourish of an attached alien now (the rig animator calls this on its own flourish timer): its firings marked
-- `flourish`, its pillar of light and a flare of its light, when it is active and not under Reduced Motion. The alien's own
-- flourish timer then stands down for Effects.Look.ExternalHold periods. `speciesId`, when given, must match the attached one.
-- Answers whether anything played.
function SpeciesFx.Flourish(target: Instance, speciesId: string?): boolean
	local handle = handles[target]
	if not handle or (speciesId ~= nil and speciesId ~= handle.speciesId) then
		return false
	end
	local now = os.clock()
	handle.externalAt = now
	return flourish(handle, now)
end

-- Hears every flourish that plays, from the alien's own timer or from Flourish: (target, speciesId).
function SpeciesFx.OnFlourish(callback: (Instance, string) -> ()): RBXScriptConnection
	return flourished.Event:Connect(callback)
end

-- Puts `target` at `pivot`, plus its idle motion: a Model is PivotTo'd (and its wings swung), a part gets a CFrame. A renderer
-- calls this in place of PivotTo / .CFrame = every frame it draws the alien; a target nobody attached is simply placed.
-- For a part only the lift and the turn apply (the rock of a Breathe needs a model's upright pivot).
function SpeciesFx.Place(target: BasePart | Model, pivot: CFrame)
	local handle = handles[target]
	if not handle then
		if target:IsA("Model") then
			target:PivotTo(pivot)
		else
			(target :: BasePart).CFrame = pivot
		end
		return
	end
	local lift, yaw, pitch = pose(handle)
	local model = handle.model
	if model then
		local placed = pivot * CFrame.new(0, lift, 0) * CFrame.Angles(pitch, yaw, 0)
		model:PivotTo(placed)
		poseFlaps(handle, placed)
		return
	end
	local part = handle.part
	if part then
		local at = pivot.Position
		part.CFrame = CFrame.new(0, lift, 0) * CFrame.new(at) * CFrame.Angles(0, yaw, 0) * CFrame.new(-at) * pivot
	end
end

-- The alien is drawn (true) or hidden for now (false: a blizzard hides it, or it is still a silhouette). Hidden aliens drop
-- their layers at once; shown ones get them back at the next ranking. A target nobody attached is ignored.
function SpeciesFx.SetShown(target: Instance, shown: boolean)
	local handle = handles[target]
	if not handle or handle.shown == shown then
		return
	end
	handle.shown = shown
	if not shown and handle.active then
		handle.active = false
		setEnabled(handle, false)
		local at = table.find(actives, handle)
		if at then
			table.remove(actives, at)
		end
	end
	lastRecheck = -math.huge
end

-- The alien's size changed (the renderer rescaled it): measure it again and rebuild the layers at the next ranking.
-- `scale`, when given, is its new size against a 1.0-scale alien (the idle amplitude follows).
function SpeciesFx.Refresh(target: Instance, scale: number?)
	local handle = handles[target]
	if not handle then
		return
	end
	if scale ~= nil then
		handle.scale = scale
	end
	setEnabled(handle, false)
	teardown(handle)
	local anchor = handle.anchor
	if anchor then
		local moment = handle.moment
		if moment then
			endMoment(moment) -- its parts live on the old anchor
			handle.moment = nil
		end
		anchor:Destroy() -- a rescaled model has scaled its anchor too; the next build makes a fresh one at the pivot
		handle.anchor = nil
		handle.host = nil
	end
	handle.bounds = nil
	table.clear(handle.pieces)
	handle.active = false
	lastRecheck = -math.huge
end

return SpeciesFx
