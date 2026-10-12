--!strict
-- StarterPlayerScripts.Client.World.Vfx: client-only particle effects. Each effect is a ParticleEmitter
-- on an invisible anchored part under a client-created Workspace.ClientVfx folder (Instance.new on the
-- client, so nothing here replicates), and the part destroys itself once its particles have died. Pure
-- presentation: callers already hold the server's result (a catch, a finished module, a shower, a
-- landing) and only ask for the sparkle. Durations come from Config; counts, speeds and sizes are look
-- values and live here, like Theme. Each emitter wears its sprite from Icons.Particles; an id of 0 means
-- not uploaded yet and the emitter keeps the soft default sprite, so the effects work with or without the pack.
--
-- Assemble (the build effect, used when a ship module snaps on and when a house piece is placed): a flat ring
-- expands on the ground under the target, a dozen small blocks in the target's colour start just under the
-- ground around its footprint and rise in a wave (far side of the footprint first, as the camera sees it),
-- tween up and inward to a random spot inside its bounds and shrink away as they land, a low dust puff covers
-- the footprint, and a white flash blooms at the middle as the pieces arrive. The blocks are plain anchored,
-- non-colliding parts in this folder, tweened and destroyed on timers; nothing is shared between two calls,
-- so several can play at once. Under reduced motion only the flash plays, at once.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
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
local DUST_THICKNESS = 0.2 -- studs: the emitting patch is a sheet this thick

-- Assemble: the pieces. Sides are studs for a target ASSEMBLE_REFERENCE_STUDS across, scaled with the target's longest side.
local ASSEMBLE_PIECES = NumberRange.new(10, 14) -- blocks per effect
local ASSEMBLE_SIDE = NumberRange.new(0.35, 0.6) -- one block's base side
local ASSEMBLE_STRETCH = NumberRange.new(0.8, 1.4) -- each of its three sides is the base side times a pick from this
local ASSEMBLE_REFERENCE_STUDS = 4 -- the target size the sides above are written for
local ASSEMBLE_SCALE = NumberRange.new(0.75, 3) -- the least and most the sides are scaled by
local ASSEMBLE_TINT = 0.25 -- most a block is lightened towards white, so the wave is not one flat colour
local ASSEMBLE_START_REACH = NumberRange.new(1, 1.4) -- start distance from the middle, times the footprint's half size
local ASSEMBLE_MIN_REACH = 1.5 -- studs: the least half size the footprint counts as, so a thin target still gets a rim
local ASSEMBLE_START_DEPTH = 0.4 -- studs the top of a block starts under the ground
local ASSEMBLE_LAND_INSET = 0.5 -- blocks land within this fraction of the bounds' half sizes (stays inside a ball)
local ASSEMBLE_TURN = math.rad(90) -- each block starts and ends turned up to this far about every axis
local ASSEMBLE_WAVE = 0.35 -- fraction of the rise the blocks' starts are spread over; the rest is one block's flight
local ASSEMBLE_SHRINK = 0.3 -- the last fraction of a flight a block spends shrinking away
local ASSEMBLE_VANISH = 0.05 -- studs: the size a block shrinks to (the smallest a part can be)
local ASSEMBLE_EASING = Enum.EasingStyle.Cubic -- Out: quick off the ground, settling as it lands
-- Assemble: the ring, the dust and the flash.
local ASSEMBLE_RING_START = 1 -- studs across when the ring begins
local ASSEMBLE_RING_SCALE = 1.8 -- its final width, times the footprint's longer side
local ASSEMBLE_RING_RANGE = NumberRange.new(6, 60) -- the least and most that width is held to
local ASSEMBLE_RING_LIFT = 0.15 -- studs above the ground, so it never z-fights the floor
local ASSEMBLE_RING_SPEED = NumberRange.new(0.05) -- a hair of upward speed: VelocityPerpendicular lays the sprite flat on it
local ASSEMBLE_DUST_COUNT = 30
local ASSEMBLE_FLASH_AT = 0.85 -- the flash starts this fraction of the way through the rise, as the first blocks land
local ASSEMBLE_FLASH_SCALE = 1.6 -- its width, times the target's longest side
local ASSEMBLE_FLASH_MIN = 5 -- studs: the least that width
local ASSEMBLE_FLASH_FROM = 0.5 -- it starts at this fraction of its width and blooms to the full width

local showerPart: Part? = nil -- the live shower sheet, while SetShowerSky(true) holds
local rng = Random.new()

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

-- A random number from within `range`.
local function pick(range: NumberRange): number
	return rng:NextNumber(range.Min, range.Max)
end

-- A cream puff of `count` wisps rising from a flat sheet `pad` studs across at `position`, spreading low and slowing.
local function groundPuff(name: string, position: Vector3, pad: Vector3, count: number)
	local part = anchor(name, CFrame.new(position), pad)
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
	puff:Emit(count)
	expire(part, DUST_LIFETIME)
end

-- The world-aligned box around a part or a model: its centre and its half sizes along X, Y and Z.
local function worldBounds(target: BasePart | Model): (Vector3, Vector3)
	local cframe: CFrame
	local size: Vector3
	if target:IsA("Model") then
		cframe, size = target:GetBoundingBox()
	else
		cframe, size = target.CFrame, target.Size
	end
	local half = size / 2
	local right, up, back = cframe.RightVector, cframe.UpVector, cframe.LookVector
	local extent = Vector3.new(
		math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(back.X) * half.Z,
		math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(back.Y) * half.Z,
		math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(back.Z) * half.Z
	)
	return cframe.Position, extent
end

local function randomTurn(): CFrame
	return CFrame.Angles(rng:NextNumber(-ASSEMBLE_TURN, ASSEMBLE_TURN), rng:NextNumber(-ASSEMBLE_TURN, ASSEMBLE_TURN), rng:NextNumber(-ASSEMBLE_TURN, ASSEMBLE_TURN))
end

-- The flat ring: one sprite lying on the ground that grows from the base out past the footprint and fades.
local function assembleRing(ground: Vector3, reachX: number, reachZ: number, color: Color3)
	local lifetime = Config.VfxAssembleRiseSeconds
	local width = math.clamp(math.max(reachX, reachZ) * 2 * ASSEMBLE_RING_SCALE, ASSEMBLE_RING_RANGE.Min, ASSEMBLE_RING_RANGE.Max)
	local part = anchor("AssembleRing", CFrame.new(ground + Vector3.new(0, ASSEMBLE_RING_LIFT, 0)), Vector3.one)
	local ring = emitter(part, {
		color = ColorSequence.new(color),
		speed = ASSEMBLE_RING_SPEED,
		lifetime = lifetime,
		size = grow(ASSEMBLE_RING_START, width),
		glow = CATCH_GLOW,
		spread = Vector2.zero,
		texture = Icons.Particles.Ring,
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
	})
	ring:Emit(1)
	expire(part, lifetime)
end

-- The small blocks: each starts just under the ground on the footprint's rim and flies up and in to a spot inside
-- the bounds, then shrinks away. Their starts are staggered far side first (as seen from the camera), so the wave
-- sweeps across the footprint towards the viewer. Every block is finished within Config.VfxAssembleRiseSeconds.
local function assemblePieces(centre: Vector3, half: Vector3, reachX: number, reachZ: number, color: Color3)
	local rise = Config.VfxAssembleRiseSeconds
	local flight = rise * (1 - ASSEMBLE_WAVE)
	local groundY = centre.Y - half.Y
	local towardCamera = Vector3.zAxis
	local camera = Workspace.CurrentCamera
	if camera then
		local position = camera.CFrame.Position
		local flat = Vector3.new(position.X - centre.X, 0, position.Z - centre.Z)
		if flat.Magnitude > 0 then
			towardCamera = flat.Unit
		end
	end
	local longest = math.max(half.X, half.Y, half.Z) * 2
	local scale = math.clamp(longest / ASSEMBLE_REFERENCE_STUDS, ASSEMBLE_SCALE.Min, ASSEMBLE_SCALE.Max)
	local reach = math.max(reachX, reachZ) * ASSEMBLE_START_REACH.Max -- the furthest a block can start, to turn a side into 0..1
	local count = rng:NextInteger(ASSEMBLE_PIECES.Min, ASSEMBLE_PIECES.Max)
	local parent = folder()
	for index = 1, count do
		local angle = (index - 1 + rng:NextNumber()) / count * math.pi * 2 -- one block per slice of the rim
		local out = pick(ASSEMBLE_START_REACH)
		local offsetX = math.cos(angle) * reachX * out
		local offsetZ = math.sin(angle) * reachZ * out
		local side = pick(ASSEMBLE_SIDE) * scale
		local size = Vector3.new(side * pick(ASSEMBLE_STRETCH), side * pick(ASSEMBLE_STRETCH), side * pick(ASSEMBLE_STRETCH))
		local start = Vector3.new(centre.X + offsetX, groundY - ASSEMBLE_START_DEPTH - size.Y / 2, centre.Z + offsetZ)
		local land = Vector3.new(
			centre.X + rng:NextNumber(-1, 1) * half.X * ASSEMBLE_LAND_INSET,
			centre.Y + rng:NextNumber(-1, 1) * half.Y * ASSEMBLE_LAND_INSET,
			centre.Z + rng:NextNumber(-1, 1) * half.Z * ASSEMBLE_LAND_INSET
		)
		-- 0 for a block on the camera's far side, 1 for the near side
		local nearness = math.clamp(0.5 + 0.5 * (offsetX * towardCamera.X + offsetZ * towardCamera.Z) / reach, 0, 1)
		local delay = nearness * ASSEMBLE_WAVE * rise

		local piece = Instance.new("Part")
		piece.Name = "AssemblePiece"
		piece.Size = size
		piece.Color = color:Lerp(Theme.Colors.White, rng:NextNumber(0, ASSEMBLE_TINT))
		piece.Material = Enum.Material.SmoothPlastic
		piece.Anchored = true
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.CastShadow = false
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.CFrame = CFrame.new(start) * randomTurn()
		piece.Parent = parent
		TweenService:Create(
			piece,
			TweenInfo.new(flight, ASSEMBLE_EASING, Enum.EasingDirection.Out, 0, false, delay),
			{ CFrame = CFrame.new(land) * randomTurn() }
		):Play()
		TweenService:Create(
			piece,
			TweenInfo.new(flight * ASSEMBLE_SHRINK, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, delay + flight * (1 - ASSEMBLE_SHRINK)),
			{ Size = Vector3.one * ASSEMBLE_VANISH }
		):Play()
		expire(piece, delay + flight)
	end
end

-- The white bloom at the target's middle, pulled towards the camera by the target's own size so a solid part does not
-- hide it. Starts `delay` seconds from now and fades over Config.VfxAssembleFlashSeconds.
local function assembleFlash(centre: Vector3, half: Vector3, delay: number)
	local lifetime = Config.VfxAssembleFlashSeconds
	local longest = math.max(half.X, half.Y, half.Z) * 2
	local width = math.max(longest * ASSEMBLE_FLASH_SCALE, ASSEMBLE_FLASH_MIN)
	local part = anchor("AssembleFlash", CFrame.new(centre), Vector3.one)
	local flash = emitter(part, {
		color = ColorSequence.new(Theme.Colors.White),
		speed = NumberRange.new(0),
		lifetime = lifetime,
		size = grow(width * ASSEMBLE_FLASH_FROM, width),
		glow = 1,
		spread = Vector2.zero,
		texture = Icons.Particles.Glow,
	})
	flash.ZOffset = longest / 2
	task.delay(delay, function()
		if part.Parent then
			flash:Emit(1)
		end
	end)
	expire(part, delay + lifetime)
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
	groundPuff("PeddlerDust", position, Vector3.new(DUST_PAD, DUST_THICKNESS, DUST_PAD), DUST_COUNT)
end

-- Something was just built (a ship module snapped on, a house piece placed): `target` is the finished part or model,
-- `color` the colour of its ring and blocks. Fire and forget; it returns at once and cleans up after itself in about
-- Config.VfxAssembleRiseSeconds plus Config.VfxAssembleFlashSeconds. The ground under it is the bottom of its bounds.
function Vfx.Assemble(target: BasePart | Model, color: Color3)
	local centre, half = worldBounds(target)
	if half.Magnitude <= 0 then
		return -- an empty model: nothing to build
	end
	if Prefs.ReducedMotion() then
		assembleFlash(centre, half, 0) -- no ring, no blocks, no dust
		return
	end
	local reachX = math.max(half.X, ASSEMBLE_MIN_REACH)
	local reachZ = math.max(half.Z, ASSEMBLE_MIN_REACH)
	local ground = Vector3.new(centre.X, centre.Y - half.Y, centre.Z)
	assembleRing(ground, reachX, reachZ, color)
	groundPuff("AssembleDust", ground, Vector3.new(reachX * 2, DUST_THICKNESS, reachZ * 2), ASSEMBLE_DUST_COUNT)
	assemblePieces(centre, half, reachX, reachZ, color)
	assembleFlash(centre, half, Config.VfxAssembleRiseSeconds * ASSEMBLE_FLASH_AT)
end

return Vfx
