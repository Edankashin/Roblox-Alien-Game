--!strict
-- StarterPlayerScripts.Client.World.SpeciesFx: the per-species effects and idle motion (data/Effects), drawn on the client
-- under the thing that is the alien: a mesh clone (a Model) or a placeholder part. Pure presentation: callers already know
-- the species and tier from the server's record. The tier aura (WildRenderer's light and glow) stays the base layer; this
-- module adds the species layers the tier allows (Shared/EffectsMath.LayersFor), scaled by the tier's rate, size and light
-- scales, and held under the device's emitter-rate cap (UserInputService.TouchEnabled is a phone).
-- Attach(target, speciesId, tier, opts) registers an alien and returns its cleanup. Nothing is built until the alien is among
-- the nearest Effects.Caps.MaxActive on screen (re-ranked every Config.VfxFxRecheckSeconds by distance to the camera, and
-- within Effects.Caps.ActiveDistance): the farther ones keep only the aura, and an alien that falls out of the ranking has its
-- layers switched off, not destroyed. Hidden or silhouetted aliens call SetShown(target, false).
-- Layers hang on named body regions (Effects.Attach, fractions of the alien's measured bounds): a Model gets one invisible
-- anchor part ("FxAnchor") at its pivot and every Attachment lives on it, so PivotTo carries them all; a part hosts its own.
-- Beams (lightning) strike every `flicker` seconds and redraw their bend a few times per strike; orbit motes circle on
-- attachments that move every frame; lights may pulse. All of that is one RenderStepped connection over the active aliens,
-- connected while any alien is attached. Every motion is an absolute function of os.clock() (EffectsMath), never accumulated.
-- Idle motion cannot be a tween on the target's pivot: the renderers write the pivot absolutely every frame (a bob), and an
-- offset added to it would be lost on a frame they run first and double on a frame they skip (a culled alien). So the renderer
-- composes it: it calls Place(target, pivot) where it used to PivotTo or set CFrame, and Place writes pivot * the idle offset
-- (a Model also swings its named wing parts about hinges, from the same pivot). An alien that is not attached is placed
-- exactly as before. A renderer that does not call Place for an alien (culled, hidden) gets no motion and no drift.
-- Reduced Motion (Prefs): idle motion holds, and every emitter, beam, trail and orbit drops out for one still glow (the
-- species' own light held steady, or Effects.Reduced). Breathe rocks the alien about its feet instead of scaling it: a ScaleTo
-- every frame would also rescale every attachment, emitter and beam parented under the model and pile up float error.
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
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local EffectsMath = require(Shared:WaitForChild("EffectsMath"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local SpeciesFx = {}

local ANCHOR_NAME = "FxAnchor"
local LIGHT_RANGE_LIMIT = 60 -- the engine's ceiling for PointLight.Range
local UPRIGHT_Y = 0.9 -- a part whose up vector is at least this vertical is upright; a rolled cylinder is not

export type Options = {
	scale: number?, -- the alien's size against a 1.0-scale one: it multiplies the idle amplitude (studs); the layers read the real bounds
	sizeScale: number?, -- an extra factor on particle, beam and light sizes
	keepFacing: boolean?, -- the renderer owns the facing (camp, companions): a Spin species does not turn
}

type Bounds = { minX: number, minY: number, minZ: number, sizeX: number, sizeY: number, sizeZ: number }
type FlapPart = { part: BasePart, rest: CFrame, hinge: Vector3, side: number, scale0: number } -- rest and hinge are in the pivot's space at the model's scale `scale0`
type BeamRig = { beam: Beam, flicker: number, length: number, offset: number, step: number }
type OrbitRig = { motes: { Attachment }, centre: Vector3, radius: number, period: number }
type LightRig = { light: PointLight, base: number, pulse: number }

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
	built: boolean,
	dead: boolean,
	bounds: Bounds?,
	host: BasePart?,
	anchor: Part?,
	made: { Instance }, -- everything built on the host, for teardown
	emitters: { ParticleEmitter },
	trails: { Trail },
	lights: { LightRig },
	beams: { BeamRig },
	orbits: { OrbitRig },
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
-- Recheck buffers, cleared and refilled rather than rebuilt.
local eligible: { Handle } = {}
local distances: { number } = {}
local picked: { [number]: boolean } = {}
local actives: { Handle } = {}
local recentSounds: { number } = {} -- when sounds started in the last second, across all aliens (EffectsMath.TakeSoundSlot)

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

local function attachment(handle: Handle, host: BasePart, region: string): Attachment
	local made = Instance.new("Attachment")
	made.Name = "Fx" .. region
	made.Position = regionPoint(handle, region)
	made.Parent = host
	table.insert(handle.made, made)
	return made
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

-- A particle emitter for a resolved layer (still in heights) on `parent`, off until the alien is active.
local function newEmitter(handle: Handle, parent: Instance, layer: Types.EffectLayer, height: number): ParticleEmitter
	local look = Effects.Look
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = layer.rate or 0
	emitter.Color = ColorSequence.new(Theme.Hex(layer.color))
	emitter.LightEmission = layer.glow or look.DefaultGlow
	local size = (layer.size or 0) * height
	if layer.flat then
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, size * look.RingFrom), NumberSequenceKeypoint.new(1, size))
		emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	else
		emitter.Size = keypoints(NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * look.EndSize))
	end
	emitter.Transparency = keypoints(
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(look.FadeIn, look.PeakTransparency),
		NumberSequenceKeypoint.new(look.FadeOut, look.PeakTransparency),
		NumberSequenceKeypoint.new(1, 1)
	)
	local lifetime = layer.lifetime or 1
	emitter.Lifetime = NumberRange.new(lifetime)
	local speed = (layer.speed or 0) * height
	emitter.Speed = NumberRange.new(speed * look.SpeedSpread, speed)
	local spread = layer.spread or 0
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.Acceleration = Vector3.new(0, (layer.rise or 0) * height, 0)
	emitter.EmissionDirection = EMISSION[layer.dir or "Up"] or Enum.NormalId.Top
	local sprite = if layer.sprite ~= nil then Icons.Particles[layer.sprite] else nil
	if sprite ~= nil and sprite ~= 0 then
		emitter.Texture = "rbxassetid://" .. sprite
	end
	emitter.Parent = parent
	table.insert(handle.emitters, emitter)
	return emitter
end

local function buildEmitter(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	newEmitter(handle, attachment(handle, host, layer.at), layer, height)
end

local function buildBeam(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local look = Effects.Look
	local from = attachment(handle, host, layer.at)
	local to = attachment(handle, host, layer.to or layer.at)
	local length = (to.Position - from.Position).Magnitude
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
	light.Parent = attachment(handle, host, layer.at)
	table.insert(handle.lights, { light = light, base = light.Brightness, pulse = if steady then 0 else layer.pulse or 0 })
end

local function buildTrail(handle: Handle, host: BasePart, layer: Types.EffectLayer)
	local look = Effects.Look
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment(handle, host, layer.at)
	trail.Attachment1 = attachment(handle, host, layer.to or "Feet")
	trail.Color = ColorSequence.new(Theme.Hex(layer.color))
	trail.LightEmission = layer.glow or look.DefaultGlow
	trail.Lifetime = layer.lifetime or 1
	trail.FaceCamera = true
	trail.Transparency = keypoints(NumberSequenceKeypoint.new(0, look.TrailTransparency), NumberSequenceKeypoint.new(1, 1))
	trail.WidthScale = NumberSequence.new(layer.width or 1)
	trail.Enabled = false
	trail.Parent = host
	table.insert(handle.made, trail)
	table.insert(handle.trails, trail)
end

-- The motes of an orbit: `count` attachments on a circle about the region, each with a small emitter whose particles stay
-- where they were born, so a mote draws its own arc.
local function buildOrbit(handle: Handle, host: BasePart, layer: Types.EffectLayer, height: number)
	local motes: { Attachment } = {}
	local centre = regionPoint(handle, layer.at)
	for _ = 1, math.max(layer.count or 1, 1) do
		local mote = Instance.new("Attachment")
		mote.Name = "FxMote"
		mote.Position = centre
		mote.Parent = host
		table.insert(handle.made, mote)
		table.insert(motes, mote)
		newEmitter(handle, mote, layer, height)
	end
	table.insert(handle.orbits, { motes = motes, centre = centre, radius = (layer.radius or 0) * height, period = layer.period or 1 })
end

local function teardown(handle: Handle)
	for _, made in ipairs(handle.made) do
		made:Destroy()
	end
	table.clear(handle.made)
	table.clear(handle.emitters)
	table.clear(handle.trails)
	table.clear(handle.lights)
	table.clear(handle.beams)
	table.clear(handle.orbits)
	handle.built = false
end

-- Builds the layers the tier allows (the still glow only, under Reduced Motion), all off.
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
	for _, layer in ipairs(layers) do
		local resolved = EffectsMath.Resolve(layer, handle.tier, mobile, handle.sizeScale)
		if resolved.kind == "Emitter" then
			buildEmitter(handle, host, resolved, height)
		elseif resolved.kind == "Beam" then
			buildBeam(handle, host, resolved, height)
		elseif resolved.kind == "Light" then
			buildLight(handle, host, resolved, height, handle.still)
		elseif resolved.kind == "Trail" then
			buildTrail(handle, host, resolved)
		elseif resolved.kind == "Orbit" then
			buildOrbit(handle, host, resolved, height)
		end
	end
	if not handle.still then
		local ring = EffectsMath.GroundRingFor(handle.speciesId, handle.tier)
		if ring then
			buildEmitter(handle, host, EffectsMath.Resolve(ring, handle.tier, mobile, handle.sizeScale), height)
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

-- Switches a built alien's layers on or off. Beams follow their own strike clock in the frame step.
local function setEnabled(handle: Handle, on: boolean)
	for _, emitter in ipairs(handle.emitters) do
		emitter.Enabled = on
	end
	for _, trail in ipairs(handle.trails) do
		trail.Enabled = on
	end
	for _, rig in ipairs(handle.lights) do
		rig.light.Enabled = on
	end
	if not on then
		for _, rig in ipairs(handle.beams) do
			rig.beam.Enabled = false
			rig.step = 0
		end
		handle.soundBeat = nil
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

local function positionOf(handle: Handle): Vector3
	local model = handle.model
	if model then
		return model:GetPivot().Position
	end
	local part = handle.part
	return if part then part.Position else Vector3.zero
end

-- Ranks every shown alien in the world by distance to the camera: the nearest Effects.Caps.MaxActive within
-- Effects.Caps.ActiveDistance are active (built on first use, then switched on); every other alien is switched off.
local function recheck(now: number)
	lastRecheck = now
	local camera = Workspace.CurrentCamera
	table.clear(eligible)
	table.clear(distances)
	for _, handle in pairs(handles) do
		handle.wanted = false
		if camera and handle.shown and handle.target:IsDescendantOf(Workspace) then
			table.insert(eligible, handle)
			table.insert(distances, (positionOf(handle) - camera.CFrame.Position).Magnitude)
		end
	end
	EffectsMath.PickActive(distances, Effects.Caps.MaxActive, Effects.Caps.ActiveDistance, picked)
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
		if handle.wanted ~= handle.active then
			handle.active = handle.wanted
			setEnabled(handle, handle.active)
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

-- Beams, orbit motes, pulsing lights and sounds of the active aliens.
local function step(_dt: number)
	local now = os.clock()
	if now - lastRecheck >= Config.VfxFxRecheckSeconds then
		recheck(now)
	end
	local soundOn = Prefs.SoundOn()
	for _, handle in ipairs(actives) do
		soundStep(handle, now, soundOn)
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
			if rig.pulse > 0 then
				rig.light.Brightness = rig.base * EffectsMath.Pulse(now, rig.pulse, handle.phase)
			end
		end
	end
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
-- Returns the cleanup; calling it twice is harmless, and so is attaching the same target again (the first is released).
-- An unknown species or tier attaches nothing.
function SpeciesFx.Attach(target: BasePart | Model, speciesId: string, tier: string, opts: Options?): () -> ()
	local fx = Effects.Species[speciesId]
	if not fx or not Effects.Tiers[tier] then
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
		built = false,
		dead = false,
		bounds = nil,
		host = nil,
		anchor = nil,
		made = {},
		emitters = {},
		trails = {},
		lights = {},
		beams = {},
		orbits = {},
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
	lastRecheck = -math.huge -- rank on the next frame
	startRunning()
	return function()
		release(handle)
	end
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
		anchor:Destroy() -- a rescaled model has scaled its anchor too; the next build makes a fresh one at the pivot
		handle.anchor = nil
		handle.host = nil
	end
	handle.bounds = nil
	handle.active = false
	lastRecheck = -math.huge
end

return SpeciesFx
