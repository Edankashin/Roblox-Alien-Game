--!strict
-- ReplicatedStorage.Shared.LaunchCamera: the pure half of the lift-off shot (CameraDirector.FollowShip), shared so the
-- client and the headless spec agree. Nothing here touches the camera, a Part or a clock; vectors are plain { x, y, z }
-- tables so the maths runs outside Roblox.
--
-- Why it exists: the first launch shot reused the module-complete pan, which takes a POINT (the ship where it rests) and
-- aims the camera at it. The ship then rose 80 studs while the camera kept looking at the ground it left, so the ship
-- was out of the top of the frame within about a second and the scene stayed empty until the fade. The launch shot aims
-- at where the ship IS: Pose is asked again every frame with the ship's current position.
--
-- What it answers, for the elapsed seconds since the shot began:
--   * the focus: the ship's current position plus Config.LaunchCameraFocusStuds, so the ship stays in the middle of the
--     frame all the way up (the camera's tilt does the following);
--   * the eye: the seat on the side the camera already stands (SideOf), Config.LaunchCameraDistance out and
--     Config.LaunchCameraHeight up, climbing Config.LaunchCameraFollow of the ship's rise so the tilt stays gentle;
--   * the glide: both of them eased in from the pose the camera had when the shot began over glideSeconds
--     (Config.LaunchCameraGlideSeconds, shortened by the caller under reduced motion), so there is no cut.

local LaunchCamera = {}

export type Vec = { x: number, y: number, z: number }
export type Pose = { eye: Vec, focus: Vec }

-- The numbers the shot reads, handed in by the caller (from Config) so this module needs no data and the spec can vary them.
export type Params = {
	distance: number, -- flat studs from the ship to the eye's seat
	height: number, -- studs above the ship at rest the seat stands
	follow: number, -- fraction of the ship's rise the eye climbs
	focusStuds: number, -- studs above the ship's position the camera aims
	glideSeconds: number, -- seconds to settle from the starting pose onto the seat (0 or less: at once)
}

local MIN_FLAT = 1e-3 -- a horizontal distance shorter than this has no usable direction
local FALLBACK_SIDE: Vec = { x = 0, y = 0, z = 1 } -- the side to stand on when the camera is over the ship

local function lerp(a: Vec, b: Vec, alpha: number): Vec
	return { x = a.x + (b.x - a.x) * alpha, y = a.y + (b.y - a.y) * alpha, z = a.z + (b.z - a.z) * alpha }
end

-- Quad InOut on 0..1, the curve the other glides use.
function LaunchCamera.Ease(alpha: number): number
	local a = math.clamp(alpha, 0, 1)
	if a < 0.5 then
		return 2 * a * a
	end
	return 1 - (2 - 2 * a) ^ 2 / 2
end

-- The unit flat direction from the ship to the camera, so the glide never cuts through the ship; +Z when the camera
-- is straight above or below it.
function LaunchCamera.SideOf(ship: Vec, camera: Vec): Vec
	local dx, dz = camera.x - ship.x, camera.z - ship.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length < MIN_FLAT then
		return FALLBACK_SIDE
	end
	return { x = dx / length, y = 0, z = dz / length }
end

-- The eye and focus `elapsed` seconds into the shot. `start` is the pose the camera had at the first frame, `rest` the
-- ship's position before it moved, `ship` its position now and `side` the unit flat direction from SideOf(rest, eye).
function LaunchCamera.Pose(p: Params, start: Pose, rest: Vec, ship: Vec, side: Vec, elapsed: number): Pose
	local rise = math.max(0, ship.y - rest.y)
	local seat: Vec = {
		x = rest.x + side.x * p.distance,
		y = rest.y + p.height + p.follow * rise,
		z = rest.z + side.z * p.distance,
	}
	local aim: Vec = { x = ship.x, y = ship.y + p.focusStuds, z = ship.z }
	local alpha = if p.glideSeconds > 0 then LaunchCamera.Ease(elapsed / p.glideSeconds) else 1
	return { eye = lerp(start.eye, seat, alpha), focus = lerp(start.focus, aim, alpha) }
end

return LaunchCamera
