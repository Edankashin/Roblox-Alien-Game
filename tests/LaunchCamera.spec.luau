--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local LaunchCamera = require(Shared.LaunchCamera)
local Config = require(Shared.data.Config)

-- The numbers the shot reads in the game, and a ship off the origin so a rule that forgets the ship's position fails.
local params = {
	distance = Config.LaunchCameraDistance,
	height = Config.LaunchCameraHeight,
	follow = Config.LaunchCameraFollow,
	focusStuds = Config.LaunchCameraFocusStuds,
	glideSeconds = Config.LaunchCameraGlideSeconds,
}
local rest = { x = 4, y = 1, z = -20 }
local start = { eye = { x = 14, y = 9, z = -5 }, focus = { x = 14, y = 7, z = 5 } }
local near = 1e-6
local PITCH_LIMIT = math.rad(45) -- the tilt up to the ship stays under this at full lift

-- The ship `rise` studs above where it rests, straight up (the lift moves nothing sideways).
local function shipAt(rise)
	return { x = rest.x, y = rest.y + rise, z = rest.z }
end

local function flatFromShip(eye)
	return math.sqrt((eye.x - rest.x) ^ 2 + (eye.z - rest.z) ^ 2)
end

describe("LaunchCamera.Pose (the launch camera follows the rising ship)", function()
	local side = LaunchCamera.SideOf(rest, start.eye)

	it("starts exactly where the camera was, so there is no cut", function()
		local pose = LaunchCamera.Pose(params, start, rest, shipAt(0), side, 0)
		expect(pose.eye.x).toBeClose(start.eye.x, near)
		expect(pose.eye.y).toBeClose(start.eye.y, near)
		expect(pose.eye.z).toBeClose(start.eye.z, near)
		expect(pose.focus.x).toBeClose(start.focus.x, near)
		expect(pose.focus.y).toBeClose(start.focus.y, near)
		expect(pose.focus.z).toBeClose(start.focus.z, near)
	end)

	it("aims at the ship where it is now, all the way up, not at the ground it left", function()
		local previous = -math.huge
		for _, rise in ipairs({ 0, 10, 40, Config.LaunchLiftStuds }) do
			local pose = LaunchCamera.Pose(params, start, rest, shipAt(rise), side, params.glideSeconds)
			expect(pose.focus.x).toBeClose(rest.x, near)
			expect(pose.focus.z).toBeClose(rest.z, near)
			expect(pose.focus.y).toBeClose(rest.y + rise + params.focusStuds, near)
			expect(pose.focus.y > previous).toEqual(true) -- a fixed point would give the same height every time
			previous = pose.focus.y
		end
	end)

	it("stands on the side the camera already was, at the seat distance, climbing a fraction of the rise", function()
		for _, rise in ipairs({ 0, 25, Config.LaunchLiftStuds }) do
			local pose = LaunchCamera.Pose(params, start, rest, shipAt(rise), side, params.glideSeconds)
			expect(flatFromShip(pose.eye)).toBeClose(params.distance, near)
			local along = (pose.eye.x - rest.x) * side.x + (pose.eye.z - rest.z) * side.z
			expect(along > 0).toEqual(true) -- the glide never goes round or through the ship
			expect(pose.eye.y).toBeClose(rest.y + params.height + params.follow * rise, near)
		end
	end)

	it("glides in with the Quad InOut curve and does not overshoot after the glide", function()
		local half = LaunchCamera.Pose(params, start, rest, shipAt(0), side, params.glideSeconds / 2)
		local seat = LaunchCamera.Pose(params, start, rest, shipAt(0), side, params.glideSeconds)
		expect(half.eye.x).toBeClose((start.eye.x + seat.eye.x) / 2, near)
		expect(half.eye.y).toBeClose((start.eye.y + seat.eye.y) / 2, near)
		expect(half.focus.y).toBeClose((start.focus.y + seat.focus.y) / 2, near)
		local late = LaunchCamera.Pose(params, start, rest, shipAt(0), side, params.glideSeconds * 5)
		expect(late.eye.x).toBeClose(seat.eye.x, near)
		expect(late.eye.z).toBeClose(seat.eye.z, near)
	end)

	it("keeps the tilt up to the ship under 45 degrees at full lift with the game's numbers", function()
		local pose = LaunchCamera.Pose(params, start, rest, shipAt(Config.LaunchLiftStuds), side, params.glideSeconds)
		local pitch = math.atan2(pose.focus.y - pose.eye.y, flatFromShip(pose.eye))
		expect(pitch > 0).toEqual(true)
		expect(pitch < PITCH_LIMIT).toEqual(true)
	end)

	it("with no glide time the camera is on its seat from the first frame", function()
		local quick = { distance = params.distance, height = params.height, follow = params.follow, focusStuds = params.focusStuds, glideSeconds = 0 }
		local pose = LaunchCamera.Pose(quick, start, rest, shipAt(0), side, 0)
		expect(flatFromShip(pose.eye)).toBeClose(params.distance, near)
		expect(pose.eye.y).toBeClose(rest.y + params.height, near)
	end)

	it("a ship that has not risen yet gives the resting seat, and one below its rest never pulls the eye down", function()
		local resting = LaunchCamera.Pose(params, start, rest, shipAt(0), side, params.glideSeconds)
		expect(resting.eye.y).toBeClose(rest.y + params.height, near)
		local sunk = LaunchCamera.Pose(params, start, rest, shipAt(-3), side, params.glideSeconds)
		expect(sunk.eye.y).toBeClose(rest.y + params.height, near)
	end)
end)

describe("LaunchCamera.SideOf and Ease", function()
	it("SideOf is the unit flat direction from the ship to the camera", function()
		local side = LaunchCamera.SideOf({ x = 1, y = 5, z = 1 }, { x = 4, y = 50, z = 5 })
		expect(side.y).toEqual(0)
		expect(math.sqrt(side.x * side.x + side.z * side.z)).toBeClose(1, near)
		expect(side.x).toBeClose(3 / 5, near)
		expect(side.z).toBeClose(4 / 5, near)
	end)
	it("SideOf falls back to +Z when the camera is straight above the ship", function()
		local side = LaunchCamera.SideOf(rest, { x = rest.x, y = rest.y + 30, z = rest.z })
		expect(side.x).toEqual(0)
		expect(side.z).toEqual(1)
	end)
	it("Ease runs 0 to 1, is symmetric about the middle and clamps outside", function()
		expect(LaunchCamera.Ease(0)).toEqual(0)
		expect(LaunchCamera.Ease(1)).toEqual(1)
		expect(LaunchCamera.Ease(0.5)).toBeClose(0.5, near)
		expect(LaunchCamera.Ease(0.25) + LaunchCamera.Ease(0.75)).toBeClose(1, near)
		expect(LaunchCamera.Ease(-2)).toEqual(0)
		expect(LaunchCamera.Ease(9)).toEqual(1)
	end)
end)
return true
