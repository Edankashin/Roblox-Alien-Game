--!strict
-- ReplicatedStorage.Shared.CinematicMath: the pure half of the cinematic camera (data/Cinematics), shared so the client's
-- CameraDirector, the server's Seen service and the headless tests agree. Nothing here touches the camera, a Part or a
-- clock. Vectors are plain { x, y, z } tables so the maths runs outside Roblox. What it answers:
--   * Fallback: where a shot's camera stands (eye) and what it looks at (focus) when the shot has no anchor Part in the
--     place's camera rig, from the world's layout (the camp and the biome centres), the character and the moment's
--     target. nil when the rule lacks a field or an input it needs (an unknown biome, no character yet).
--   * Easing: the Quad or Sine curve and its direction named by a shot's easing string.
--   * BlurIntensities: the depth-of-field near and far intensities a shot's blur stands for.
--   * Moment lookups and the seen-key allow-list the MarkSeen remote checks.

local Cinematics = require(script.Parent.data.Cinematics)

local CinematicMath = {}

export type Vec = { x: number, y: number, z: number }
export type Pose = { eye: Vec, focus: Vec }

-- What the rules read. `camp` is the ship (the camp's centre, on the ground) and `biomes` the layout's region centres at
-- ground height; the rest is whatever is known when a shot starts: the character's position and the flat unit
-- direction behind it, the camera's position and look direction, and the moment's target (the alien being caught).
export type Context = {
	camp: Vec,
	biomes: { [string]: Vec },
	character: Vec?,
	characterBack: Vec?,
	camera: Vec?,
	cameraLook: Vec?,
	target: Vec?,
}

local MIN_FLAT = 1e-3 -- a horizontal distance shorter than this has no usable direction
local FALLBACK_BACK = { x = 0, y = 0, z = 1 } -- the side to stand on when nothing says which

local STYLES: { [string]: boolean } = { Quad = true, Sine = true }
local DIRECTIONS: { [string]: boolean } = { InOut = true, In = true, Out = true }

-- Moment lookups ------------------------------------------------------------

-- The moment (and seen key) for a world's first arrival: data/Cinematics.ArrivalPrefix then the world id.
function CinematicMath.ArrivalMoment(worldId: number): string
	return ("%s%d"):format(Cinematics.ArrivalPrefix, worldId)
end

function CinematicMath.HasMoment(momentId: any): boolean
	return type(momentId) == "string" and Cinematics.Moments[momentId] ~= nil
end

-- Whether `key` is one of the keys profile.seen may hold: the only ones the MarkSeen remote accepts, whatever the client sends.
function CinematicMath.IsSeenKey(key: any): boolean
	return type(key) == "string" and Cinematics.SeenKeys[key] == true
end

-- The seconds a moment's shots add up to (the first shot's rest included); 0 for an unknown moment.
function CinematicMath.TotalSeconds(momentId: string): number
	local moment = Cinematics.Moments[momentId]
	if not moment then
		return 0
	end
	local total = 0
	for _, shot in ipairs(moment.shots) do
		total += shot.seconds
	end
	return total
end

-- Easing and blur -------------------------------------------------------------

-- The easing style ("Quad" or "Sine") and direction ("In", "Out" or "InOut") a shot's easing string names; nil when it names neither.
function CinematicMath.Easing(easing: string): (string?, string?)
	for style in pairs(STYLES) do
		local direction = string.match(easing, "^" .. style .. "(%a+)$")
		if direction ~= nil and DIRECTIONS[direction] then
			return style, direction
		end
	end
	return nil, nil
end

-- The depth-of-field (near, far) intensities for a shot's blur (0 none .. 1 full), each clamped to 0..1.
function CinematicMath.BlurIntensities(blur: number): (number, number)
	local level = math.clamp(blur, 0, 1)
	local effect = Cinematics.DepthOfField
	return math.clamp(level * effect.NearFactor, 0, 1), math.clamp(level * effect.FarFactor, 0, 1)
end

-- Vector helpers --------------------------------------------------------------

local function add(a: Vec, b: Vec): Vec
	return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

local function scale(a: Vec, factor: number): Vec
	return { x = a.x * factor, y = a.y * factor, z = a.z * factor }
end

local function lifted(a: Vec, height: number): Vec
	return { x = a.x, y = a.y + height, z = a.z }
end

-- The unit direction in the ground plane from `from` to `to`; nil when they stand on one vertical line.
function CinematicMath.FlatDirection(from: Vec, to: Vec): Vec?
	local dx, dz = to.x - from.x, to.z - from.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length < MIN_FLAT then
		return nil
	end
	return { x = dx / length, y = 0, z = dz / length }
end

-- Fallback views ---------------------------------------------------------------

-- The view a rule stands for in `context`, or nil when a field or an input it needs is missing.
function CinematicMath.Fallback(rule: Cinematics.Rule, context: Context): Pose?
	local kind = rule.kind
	local camp = context.camp
	local lookHeight = rule.lookHeight or 0
	if kind == "orbitCamp" then
		local radius, height, angle = rule.radius, rule.height, rule.angle
		if radius == nil or height == nil or angle == nil then
			return nil
		end
		local turn = math.rad(angle)
		local eye = { x = camp.x + math.cos(turn) * radius, y = camp.y + height, z = camp.z + math.sin(turn) * radius }
		return { eye = eye, focus = lifted(camp, lookHeight) }
	elseif kind == "overBiome" then
		local name, height = rule.biome, rule.height
		if name == nil or height == nil then
			return nil
		end
		local centre = context.biomes[name]
		if not centre then
			return nil
		end
		return { eye = lifted(centre, height), focus = lifted(camp, lookHeight) }
	elseif kind == "behindCharacter" then
		local back, height = rule.back, rule.height
		local character = context.character
		if back == nil or height == nil or character == nil then
			return nil
		end
		local behind = context.characterBack or FALLBACK_BACK
		return { eye = lifted(add(character, scale(behind, back)), height), focus = character }
	elseif kind == "towardTarget" then
		local distance, height = rule.distance, rule.height
		local target = context.target
		if distance == nil or height == nil or target == nil then
			return nil
		end
		-- Stay on the side the camera already stands, so the push-in never swings through the alien.
		local side: Vec? = nil
		if context.camera then
			side = CinematicMath.FlatDirection(target, context.camera)
		end
		local direction = side or context.characterBack or FALLBACK_BACK
		return { eye = lifted(add(target, scale(direction, distance)), height), focus = lifted(target, lookHeight) }
	elseif kind == "current" then
		local camera, look = context.camera, context.cameraLook
		if camera == nil or look == nil then
			return nil
		end
		return { eye = camera, focus = add(camera, look) }
	end
	return nil
end

return CinematicMath
