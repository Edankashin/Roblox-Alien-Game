--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.CinematicMath)
local Cinematics = require(Shared.data.Cinematics)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local Layouts = require(Shared.data.Layouts)
local F = require(script.Parent.Fixtures)

local RIGHT_ANGLE = 90 -- degrees: orbitCamp's angle 0 is +X and 90 is +Z
local MAX_FOV = 120 -- Roblox's field-of-view ceiling
local near = F.tolerance
local three = F.two + F.one
local four = F.two + F.two
local ten = four + four + F.two

-- A camp off the origin, so a rule that forgets the camp's position fails.
local camp = { x = F.two, y = F.one, z = three }
local function vec(x, y, z)
	return { x = x, y = y, z = z }
end

-- A context with everything known: the layout's biome centres for `worldId`, a character, a camera and a target.
local function contextFor(worldId)
	local biomes = {}
	local layout = Layouts[worldId]
	if layout then
		for name, region in pairs(layout.Regions) do
			biomes[name] = vec(region.x, camp.y, region.z)
		end
	end
	return {
		camp = camp,
		biomes = biomes,
		character = vec(F.one, camp.y, F.one),
		characterBack = vec(F.zero, F.zero, F.one),
		camera = vec(four, camp.y + F.two, F.zero),
		cameraLook = vec(F.zero, F.zero, -F.one),
		target = vec(F.zero, camp.y, F.zero),
	}
end

local function expectVec(actual, x, y, z)
	expect(actual ~= nil).toEqual(true)
	expect(actual.x).toBeClose(x, near)
	expect(actual.y).toBeClose(y, near)
	expect(actual.z).toBeClose(z, near)
end

local function momentIds()
	local ids = {}
	for id in pairs(Cinematics.Moments) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

-- The world a moment belongs to: Arrival_<id> is that world's, anything else none.
local function worldOf(id)
	for worldId in pairs(Worlds) do
		if type(worldId) == "number" and Math.ArrivalMoment(worldId) == id then
			return worldId
		end
	end
	return nil
end

describe("CinematicMath data", function()
	it("every moment has well-formed shots", function()
		local count = F.zero
		for _, id in ipairs(momentIds()) do
			local moment = Cinematics.Moments[id]
			count += F.one
			expect(#moment.shots >= F.one).toEqual(true)
			for index, shot in ipairs(moment.shots) do
				expect(shot.seconds >= F.zero).toEqual(true)
				expect(index == F.one or shot.seconds > F.zero).toEqual(true)
				expect(shot.blur >= F.zero and shot.blur <= F.one).toEqual(true)
				expect(shot.fov == nil or (shot.fov > F.zero and shot.fov <= MAX_FOV)).toEqual(true)
				expect(Math.Easing(shot.easing) ~= nil).toEqual(true)
				expect(shot.anchor == nil or #shot.anchor > F.zero).toEqual(true)
			end
		end
		expect(count >= F.one).toEqual(true)
	end)
	it("a wild world's arrival runs the planned length and the home's is shorter", function()
		for worldId, world in pairs(Worlds) do
			if type(worldId) == "number" and world.built then
				local seconds = Math.TotalSeconds(Math.ArrivalMoment(worldId))
				if worldId == F.zero then
					expect(seconds > F.zero and seconds < Cinematics.ArrivalSeconds.min).toEqual(true)
				else
					expect(seconds >= Cinematics.ArrivalSeconds.min and seconds <= Cinematics.ArrivalSeconds.max).toEqual(true)
				end
			end
		end
	end)
	it("every built world has an arrival moment and a seen key, and every seen key is a moment", function()
		for worldId, world in pairs(Worlds) do
			if type(worldId) == "number" and world.built then
				expect(Math.HasMoment(Math.ArrivalMoment(worldId))).toEqual(true)
				expect(Math.IsSeenKey(Math.ArrivalMoment(worldId))).toEqual(true)
			end
		end
		for key in pairs(Cinematics.SeenKeys) do
			expect(Math.HasMoment(key)).toEqual(true)
		end
	end)
	it("the Legendary push-in has no blur and no bars, and with the rumble stays under its budget", function()
		local moment = Cinematics.Moments.Legendary
		expect(moment.letterbox).toEqual(false)
		expect(moment.skippable).toEqual(false)
		expect(moment.skipOnReducedMotion).toEqual(true)
		for _, shot in ipairs(moment.shots) do
			expect(shot.blur).toEqual(F.zero)
			expect(shot.fov).toEqual(nil)
		end
		expect(Math.TotalSeconds("Legendary") + Config.LegendaryRumbleSeconds < Cinematics.LegendaryBudgetSeconds).toEqual(true)
	end)
	it("anchor names are unique across moments and start with their moment's id", function()
		local used = {}
		for _, id in ipairs(momentIds()) do
			for _, shot in ipairs(Cinematics.Moments[id].shots) do
				if shot.anchor then
					expect(used[shot.anchor]).toEqual(nil)
					used[shot.anchor] = true
					expect(string.sub(shot.anchor, F.one, #id)).toEqual(id)
				end
			end
		end
	end)
	it("every fallback rule resolves in its world's layout", function()
		for _, id in ipairs(momentIds()) do
			local moment = Cinematics.Moments[id]
			local context = contextFor(worldOf(id) or F.one)
			for _, shot in ipairs(moment.shots) do
				local pose = Math.Fallback(shot.fallback, context)
				expect(pose ~= nil).toEqual(true)
				if pose then
					local dx, dy, dz = pose.focus.x - pose.eye.x, pose.focus.y - pose.eye.y, pose.focus.z - pose.eye.z
					-- a "current" shot looks one unit ahead; every other shot looks at something away from its eye
					expect(math.sqrt(dx * dx + dy * dy + dz * dz) >= (if shot.fallback.kind == "current" then F.one - near else near)).toEqual(true)
				end
			end
		end
	end)
	it("the layouts keep the regions the arrival rules fly over", function()
		for _, id in ipairs(momentIds()) do
			local worldId = worldOf(id)
			for _, shot in ipairs(Cinematics.Moments[id].shots) do
				local biome = shot.fallback.biome
				if biome and worldId then
					expect(Layouts[worldId].Regions[biome] ~= nil).toEqual(true)
				end
			end
		end
	end)
end)

describe("CinematicMath seen keys", function()
	it("names a world's arrival from the prefix and the id", function()
		expect(Math.ArrivalMoment(F.one)).toEqual(Cinematics.ArrivalPrefix .. tostring(F.one))
	end)
	it("accepts exactly the listed keys", function()
		for key in pairs(Cinematics.SeenKeys) do
			expect(Math.IsSeenKey(key)).toEqual(true)
		end
		expect(Math.IsSeenKey("Legendary")).toEqual(false)
		expect(Math.IsSeenKey(string.lower(Math.ArrivalMoment(F.one)))).toEqual(false)
		expect(Math.IsSeenKey(F.one)).toEqual(false)
		expect(Math.IsSeenKey(nil)).toEqual(false)
		expect(Math.IsSeenKey({})).toEqual(false)
		expect(Math.IsSeenKey("")).toEqual(false)
	end)
	it("knows its moments", function()
		expect(Math.HasMoment("Legendary")).toEqual(true)
		expect(Math.HasMoment("Nope")).toEqual(false)
		expect(Math.HasMoment(F.one)).toEqual(false)
		expect(Math.TotalSeconds("Nope")).toEqual(F.zero)
	end)
end)

describe("CinematicMath easing and blur", function()
	it("reads a style and a direction", function()
		local style, direction = Math.Easing("SineInOut")
		expect(style).toEqual("Sine")
		expect(direction).toEqual("InOut")
		style, direction = Math.Easing("QuadIn")
		expect(style).toEqual("Quad")
		expect(direction).toEqual("In")
		style, direction = Math.Easing("QuadOut")
		expect(style).toEqual("Quad")
		expect(direction).toEqual("Out")
	end)
	it("refuses anything else", function()
		for _, bad in ipairs({ "", "Quad", "In", "CubicIn", "QuadSideways", "quadin", "QuadInOutIn" }) do
			local style, direction = Math.Easing(bad)
			expect(style).toEqual(nil)
			expect(direction).toEqual(nil)
		end
	end)
	it("scales the depth-of-field intensities by blur and clamps it", function()
		local nearNone, farNone = Math.BlurIntensities(F.zero)
		expect(nearNone).toEqual(F.zero)
		expect(farNone).toEqual(F.zero)
		local nearFull, farFull = Math.BlurIntensities(F.one)
		expect(nearFull).toBeClose(Cinematics.DepthOfField.NearFactor, near)
		expect(farFull).toBeClose(Cinematics.DepthOfField.FarFactor, near)
		local nearOver, farOver = Math.BlurIntensities(F.one + F.two)
		expect(nearOver).toBeClose(nearFull, near)
		expect(farOver).toBeClose(farFull, near)
		local nearUnder = Math.BlurIntensities(-F.one)
		expect(nearUnder).toEqual(F.zero)
		local nearHalf = Math.BlurIntensities(F.half)
		expect(nearHalf).toBeClose(nearFull * F.half, near)
	end)
end)

describe("CinematicMath fallback views", function()
	it("orbits the camp: angle 0 on +X, a quarter turn on +Z, the camp's height and position added", function()
		local radius, height, lookHeight = four, three, F.one
		local context = contextFor(F.one)
		local onX = Math.Fallback({ kind = "orbitCamp", radius = radius, height = height, angle = F.zero, lookHeight = lookHeight }, context)
		expect(onX ~= nil).toEqual(true)
		if onX then
			expectVec(onX.eye, camp.x + radius, camp.y + height, camp.z)
			expectVec(onX.focus, camp.x, camp.y + lookHeight, camp.z)
		end
		local onZ = Math.Fallback({ kind = "orbitCamp", radius = radius, height = height, angle = RIGHT_ANGLE }, context)
		if onZ then
			expectVec(onZ.eye, camp.x, camp.y + height, camp.z + radius)
			expectVec(onZ.focus, camp.x, camp.y, camp.z)
		end
	end)
	it("hangs over a biome's centre and looks at the camp", function()
		local context = contextFor(F.one)
		local height = ten
		local name, region = next(Layouts[F.one].Regions)
		local pose = Math.Fallback({ kind = "overBiome", biome = name, height = height }, context)
		expect(pose ~= nil).toEqual(true)
		if pose then
			expectVec(pose.eye, region.x, camp.y + height, region.z)
			expectVec(pose.focus, camp.x, camp.y, camp.z)
		end
		expect(Math.Fallback({ kind = "overBiome", biome = "NoSuchBiome", height = height }, context)).toEqual(nil)
	end)
	it("stands behind the character", function()
		local context = contextFor(F.one)
		local back, height = four, F.two
		local pose = Math.Fallback({ kind = "behindCharacter", back = back, height = height }, context)
		expect(pose ~= nil).toEqual(true)
		if pose and context.character and context.characterBack then
			expectVec(pose.eye, context.character.x + context.characterBack.x * back, context.character.y + height, context.character.z + context.characterBack.z * back)
			expectVec(pose.focus, context.character.x, context.character.y, context.character.z)
		end
		context.characterBack = nil -- direction unknown: a side is still chosen
		expect(Math.Fallback({ kind = "behindCharacter", back = back, height = height }, context) ~= nil).toEqual(true)
		context.character = nil
		expect(Math.Fallback({ kind = "behindCharacter", back = back, height = height }, context)).toEqual(nil)
	end)
	it("pushes toward a target from the side the camera stands on", function()
		local context = contextFor(F.one)
		local distance, height, lookHeight = four, F.two, F.one
		local pose = Math.Fallback({ kind = "towardTarget", distance = distance, height = height, lookHeight = lookHeight }, context)
		expect(pose ~= nil).toEqual(true)
		local target, camera = context.target, context.camera
		if pose and target and camera then
			-- the camera stands on +X of the target, so the eye does too, `distance` away on the ground plane
			expect(pose.eye.x).toBeClose(target.x + distance, near)
			expect(pose.eye.z).toBeClose(target.z, near)
			expect(pose.eye.y).toBeClose(target.y + height, near)
			expectVec(pose.focus, target.x, target.y + lookHeight, target.z)
		end
		-- straight above the target there is no side: it falls back to behind the character
		context.camera = vec(F.zero, camp.y + ten, F.zero)
		local above = Math.Fallback({ kind = "towardTarget", distance = distance, height = height }, context)
		if above and context.target and context.characterBack then
			expect(above.eye.z).toBeClose(context.target.z + context.characterBack.z * distance, near)
		end
		context.target = nil
		expect(Math.Fallback({ kind = "towardTarget", distance = distance, height = height }, context)).toEqual(nil)
	end)
	it("keeps the camera where it is for 'current'", function()
		local context = contextFor(F.one)
		local pose = Math.Fallback({ kind = "current" }, context)
		expect(pose ~= nil).toEqual(true)
		if pose and context.camera and context.cameraLook then
			expectVec(pose.eye, context.camera.x, context.camera.y, context.camera.z)
			expectVec(pose.focus, context.camera.x + context.cameraLook.x, context.camera.y + context.cameraLook.y, context.camera.z + context.cameraLook.z)
		end
		context.camera = nil
		expect(Math.Fallback({ kind = "current" }, context)).toEqual(nil)
	end)
	it("answers nil when a rule lacks a field it needs", function()
		local context = contextFor(F.one)
		expect(Math.Fallback({ kind = "orbitCamp", radius = F.one, height = F.one }, context)).toEqual(nil)
		expect(Math.Fallback({ kind = "orbitCamp", height = F.one, angle = F.zero }, context)).toEqual(nil)
		expect(Math.Fallback({ kind = "overBiome", height = F.one }, context)).toEqual(nil)
		expect(Math.Fallback({ kind = "behindCharacter", back = F.one }, context)).toEqual(nil)
		expect(Math.Fallback({ kind = "towardTarget", distance = F.one }, context)).toEqual(nil)
	end)
	it("gives a flat direction between two points, nil on one vertical line", function()
		local direction = Math.FlatDirection(vec(F.zero, F.zero, F.zero), vec(four, F.two, F.zero))
		expect(direction ~= nil).toEqual(true)
		if direction then
			expectVec(direction, F.one, F.zero, F.zero)
		end
		expect(Math.FlatDirection(vec(F.one, F.zero, F.one), vec(F.one, ten, F.one))).toEqual(nil)
	end)
end)
return true
