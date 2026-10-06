--!strict
-- StarterPlayerScripts.Client.World.Vfx: client-only particle effects. Each effect is a ParticleEmitter
-- on an invisible anchored part under a client-created Workspace.ClientVfx folder (Instance.new on the
-- client, so nothing here replicates), and the part destroys itself once its particles have died. Pure
-- presentation: callers already hold the server's result (a catch, a finished module, a shower, a
-- landing) and only ask for the sparkle. Durations come from Config; counts, speeds and sizes are look
-- values and live here, like Theme. Each emitter wears its sprite from Icons.Particles; an id of 0 means
-- not uploaded yet and the emitter keeps the soft default sprite, so the effects work with or without the pack.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local CampRenderer = require(script.Parent:WaitForChild("CampRenderer"))

local Vfx = {}

local FOLDER_NAME = "ClientVfx"
local DESTROY_SLACK = 0.25 -- seconds past the longest particle lifetime before a one-shot part is removed

-- Look values (not tunables): how each burst reads. Lifetimes and rates are in Config.
local CATCH_COUNT = 24
local CATCH_SPEED = NumberRange.new(8, 14)
local CATCH_SIZE = 0.6
local CATCH_GLOW = 0.5
local CATCH_RING_SIZE = 16 -- studs: the ring sprite's final width, about where the burst's edge reaches

local MODULE_COUNT = 60
local MODULE_SPEED = NumberRange.new(14, 22)
local MODULE_SIZE = 0.9
local MODULE_SPARKLE_COUNT = 30 -- the slow gold drift that follows the ring
local MODULE_SPARKLE_SPEED = NumberRange.new(2, 4)
local MODULE_SPARKLE_SIZE = 0.5
local MODULE_SPARKLE_RISE = Vector3.new(0, 3, 0) -- acceleration, so the sparkles keep lifting
local MODULE_SPARKLE_SPREAD = Vector2.new(35, 35)

local SHOWER_HEIGHT = 90 -- studs above the ship the streaks start from
local SHOWER_SPAN = 80 -- studs across the emitting sheet, so streaks fall over the whole camp
local SHOWER_DIRECTION = Vector3.new(0.55, -1, 0.25) -- down and sideways; normalised when used
local SHOWER_SPEED = NumberRange.new(60, 90)
local SHOWER_LIFETIME = 1.2
local SHOWER_SIZE = 1.5
local SHOWER_SPREAD = Vector2.new(6, 6)
local SHOWER_ROTATION = NumberRange.new(-20, 20)
local SHOWER_ROT_SPEED = NumberRange.new(-40, 40)

local DUST_COUNT = 20
local DUST_SPEED = NumberRange.new(4, 7)
local DUST_LIFETIME = 0.9
local DUST_SIZE = 1.4
local DUST_SPREAD = Vector2.new(75, 75) -- a wide, low puff
local DUST_DRAG = 2.5 -- the puff slows and hangs instead of flying off
local DUST_PAD = 3 -- studs across the ground patch the puff rises from

local showerPart: Part? = nil -- the live shower sheet, while SetShowerSky(true) holds

-- Helpers ----------------------------------------------------------------

-- Workspace.ClientVfx, created on first use (client-side only, never replicates).
local function folder(): Folder
	local existing = Workspace:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	return created
end

-- An invisible anchored part for an emitter to sit on. The emitter fills the part's volume, so a flat
-- wide size spreads particles over an area and a small one makes a point source.
local function anchor(name: string, cframe: CFrame, size: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder()
	return part
end

-- A CFrame at `position` whose +Y (the emitter's Top direction) points along `up`.
local function frameWithUp(position: Vector3, up: Vector3): CFrame
	local axis = up.Unit
	local right = axis:Cross(Vector3.zAxis)
	if right.Magnitude < 1e-3 then
		right = Vector3.xAxis
	end
	return CFrame.fromMatrix(position, right.Unit, axis)
end

local function fadeOut(): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
end

local function shrink(from: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, 0) })
end

local function grow(from: number, to: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) })
end

type EmitterProps = {
	color: ColorSequence,
	speed: NumberRange,
	lifetime: number,
	size: NumberSequence,
	glow: number,
	spread: Vector2,
	acceleration: Vector3?,
	drag: number?,
	rotation: NumberRange?,
	rotSpeed: NumberRange?,
	texture: number?, -- an Icons.Particles id; nil or 0 keeps the default sprite
	orientation: Enum.ParticleOrientation?,
}

-- An emitter on `part` with the shared defaults: the soft default sprite (unless props.texture names an
-- uploaded one), fading out over its life, emitting nothing until Emit or Enabled.
local function emitter(part: Part, props: EmitterProps): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Rate = 0
	e.Color = props.color
	e.Speed = props.speed
	e.Lifetime = NumberRange.new(props.lifetime)
	e.Size = props.size
	e.Transparency = fadeOut()
	e.LightEmission = props.glow
	e.SpreadAngle = props.spread
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = props.acceleration or Vector3.zero
	e.Drag = props.drag or 0
	e.Rotation = props.rotation or NumberRange.new(0)
	e.RotSpeed = props.rotSpeed or NumberRange.new(0)
	local texture = props.texture
	if texture ~= nil and texture ~= 0 then
		e.Texture = "rbxassetid://" .. texture
	end
	if props.orientation then
		e.Orientation = props.orientation
	end
	e.Parent = part
	return e
end

-- Removes a one-shot part once every particle it emitted has died.
local function expire(part: Part, lifetime: number)
	task.delay(lifetime + DESTROY_SLACK, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

-- Public API -------------------------------------------------------------

-- Where a caught alien stood: a round burst of sparkles in the species (or tier) colour that shrinks
-- away, and (once the Ring sprite is uploaded) one ring in the same colour that grows wide and fades.
function Vfx.CatchBurst(position: Vector3, color: Color3)
	local lifetime = Config.VfxCatchBurstSeconds
	local part = anchor("CatchBurst", CFrame.new(position), Vector3.one)
	local burst = emitter(part, {
		color = ColorSequence.new(color),
		speed = CATCH_SPEED,
		lifetime = lifetime,
		size = shrink(CATCH_SIZE),
		glow = CATCH_GLOW,
		spread = Vector2.new(360, 360),
		texture = Icons.Particles.Sparkle,
	})
	burst:Emit(CATCH_COUNT)
	local ringSprite = Icons.Particles.Ring
	if ringSprite ~= 0 then
		local ring = emitter(part, {
			color = ColorSequence.new(color),
			speed = NumberRange.new(0),
			lifetime = lifetime,
			size = grow(CATCH_SIZE, CATCH_RING_SIZE),
			glow = CATCH_GLOW,
			spread = Vector2.zero,
			texture = ringSprite,
		})
		ring:Emit(1)
	end
	expire(part, lifetime)
end

-- Over a finished module: a wide ring of stars in the module's colour plus slow gold glows drifting upward.
function Vfx.ModuleBurst(position: Vector3, color: Color3)
	local lifetime = Config.VfxModuleBurstSeconds
	local part = anchor("ModuleBurst", CFrame.new(position), Vector3.one)
	local ring = emitter(part, {
		color = ColorSequence.new(color),
		speed = MODULE_SPEED,
		lifetime = lifetime,
		size = shrink(MODULE_SIZE),
		glow = CATCH_GLOW,
		spread = Vector2.new(360, 360),
		texture = Icons.Particles.Star,
	})
	local sparkles = emitter(part, {
		color = ColorSequence.new(Theme.Colors.Featured),
		speed = MODULE_SPARKLE_SPEED,
		lifetime = lifetime,
		size = shrink(MODULE_SPARKLE_SIZE),
		glow = 1,
		spread = MODULE_SPARKLE_SPREAD,
		acceleration = MODULE_SPARKLE_RISE,
		texture = Icons.Particles.Glow,
	})
	ring:Emit(MODULE_COUNT)
	sparkles:Emit(MODULE_SPARKLE_COUNT)
	expire(part, lifetime)
end

-- Meteor streaks over the camp while `on`: a sheet above the ship rains bright purple-to-white dots
-- down at an angle at Config.VfxShowerStreaksPerSecond. Off lets the last streaks finish, then clears.
-- With the Raindrop sprite uploaded each particle is a streak laid along its fall; until then bright dots.
function Vfx.SetShowerSky(on: boolean)
	local current = showerPart
	if on then
		if current and current.Parent then
			return
		end
		local sprite = Icons.Particles.Raindrop
		local origin = CampRenderer.ShipPosition() + Vector3.new(0, SHOWER_HEIGHT, 0)
		local part = anchor("ShowerSky", frameWithUp(origin, SHOWER_DIRECTION), Vector3.new(SHOWER_SPAN, 1, SHOWER_SPAN))
		local streaks = emitter(part, {
			color = ColorSequence.new(Theme.Colors.Codex, Theme.Colors.White),
			speed = SHOWER_SPEED,
			lifetime = SHOWER_LIFETIME,
			size = shrink(SHOWER_SIZE),
			glow = 1,
			spread = SHOWER_SPREAD,
			rotation = SHOWER_ROTATION,
			rotSpeed = SHOWER_ROT_SPEED,
			texture = sprite,
			orientation = if sprite ~= 0 then Enum.ParticleOrientation.VelocityParallel else nil,
		})
		streaks.Rate = Config.VfxShowerStreaksPerSecond
		streaks.Enabled = true
		showerPart = part
	elseif current then
		showerPart = nil
		for _, child in ipairs(current:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = false
			end
		end
		expire(current, SHOWER_LIFETIME)
	end
end

-- A short cream ground puff where the Peddler's ship touches down.
function Vfx.PeddlerDust(position: Vector3)
	local part = anchor("PeddlerDust", CFrame.new(position), Vector3.new(DUST_PAD, 0.2, DUST_PAD))
	local puff = emitter(part, {
		color = ColorSequence.new(Theme.Colors.Panel),
		speed = DUST_SPEED,
		lifetime = DUST_LIFETIME,
		size = shrink(DUST_SIZE),
		glow = 0,
		spread = DUST_SPREAD,
		drag = DUST_DRAG,
		texture = Icons.Particles.Wisp,
	})
	puff:Emit(DUST_COUNT)
	expire(part, DUST_LIFETIME)
end

return Vfx
