--!strict
-- ReplicatedStorage.Shared.RigMath: the clip math of the B46 rigs (data/Rigs), pure functions of the clock so the client's
-- World.RigAnimator and the headless specs (tests/RigMath.spec.luau) share it. Every pose is an absolute function of the time and the
-- alien's own offset (never accumulated), so a skipped frame or an alien that comes back on screen is exactly in step.
-- A pose is a RigPose table the caller owns and reuses: Reset it, Accumulate each clip and the flourish's moves into it, then build a
-- CFrame from it. Offsets add, turns add, scales multiply. tools/blocky/rigs.py has the same math in Python for the Blender idle preview.
-- Kinds (amp units): bob (studs along the axis), sway (degrees, a sine), flap (degrees, 0 to amp and back: a beat), spin (degrees a period,
-- continuous), wag (degrees, bursts of a double-speed wag), squash (a share: stretch along the axis, the other two give half), pulse (a
-- share: all three grow and shrink), orbit (studs: a circle round the axis). Flourish moves over their own progress s (0 to 1): hop
-- (studs, up and down once), turn (degrees, eased from 0 to amp), flare (degrees, out and back), swish (degrees, a dying double swish),
-- pop (a share, grow and back), squash (a share, a squash and stretch).

local Types = require(script.Parent.types.Types)

local RigMath = {}

local TAU = math.pi * 2

function RigMath.NewPose(): Types.RigPose
	return { px = 0, py = 0, pz = 0, rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1 }
end

function RigMath.Reset(pose: Types.RigPose)
	pose.px, pose.py, pose.pz = 0, 0, 0
	pose.rx, pose.ry, pose.rz = 0, 0, 0
	pose.sx, pose.sy, pose.sz = 1, 1, 1
end

local function addOffset(pose: Types.RigPose, axis: Types.RigAxis, value: number)
	if axis == "x" then
		pose.px += value
	elseif axis == "y" then
		pose.py += value
	else
		pose.pz += value
	end
end

local function addTurn(pose: Types.RigPose, axis: Types.RigAxis, radians: number)
	if axis == "x" then
		pose.rx += radians
	elseif axis == "y" then
		pose.ry += radians
	else
		pose.rz += radians
	end
end

-- Stretch along `axis` by (1 + share) and give half of it back on the other two.
local function stretch(pose: Types.RigPose, axis: Types.RigAxis, share: number)
	local along, across = 1 + share, 1 - share / 2
	if axis == "x" then
		pose.sx *= along
		pose.sy *= across
		pose.sz *= across
	elseif axis == "y" then
		pose.sx *= across
		pose.sy *= along
		pose.sz *= across
	else
		pose.sx *= across
		pose.sy *= across
		pose.sz *= along
	end
end

local function grow(pose: Types.RigPose, share: number)
	pose.sx *= 1 + share
	pose.sy *= 1 + share
	pose.sz *= 1 + share
end

-- Where a looping clip is in its cycle at `now`: turns since the start, with the clip's phase and the alien's own offset (both shares of a
-- period), so a crowd of one species is not in step.
function RigMath.Turns(clip: Types.RigClip, now: number, offset: number): number
	if clip.period <= 0 then
		return 0
	end
	return now / clip.period + clip.phase + offset
end

-- Adds one looping clip at `now` into `pose`.
function RigMath.Accumulate(pose: Types.RigPose, clip: Types.RigClip, now: number, offset: number)
	local u = RigMath.Turns(clip, now, offset)
	local kind, amp = clip.kind, clip.amp
	local axis: Types.RigAxis = clip.axis
	if kind == "bob" then
		addOffset(pose, axis, amp * math.sin(TAU * u))
	elseif kind == "sway" then
		addTurn(pose, axis, math.rad(amp) * math.sin(TAU * u))
	elseif kind == "flap" then
		addTurn(pose, axis, math.rad(amp) * (1 - math.cos(TAU * u)) / 2)
	elseif kind == "spin" then
		addTurn(pose, axis, math.rad(amp) * (u % 1))
	elseif kind == "wag" then
		addTurn(pose, axis, math.rad(amp) * math.sin(2 * TAU * u) * math.max(0, math.sin(TAU * u)))
	elseif kind == "squash" then
		stretch(pose, axis, amp * math.sin(TAU * u))
	elseif kind == "pulse" then
		grow(pose, amp * (0.5 + 0.5 * math.sin(TAU * u)))
	elseif kind == "orbit" then
		local a, b = amp * math.cos(TAU * u), amp * math.sin(TAU * u)
		if axis == "x" then
			pose.py += a
			pose.pz += b
		elseif axis == "y" then
			pose.px += a
			pose.pz += b
		else
			pose.px += a
			pose.py += b
		end
	end
end

-- Seconds into the flourish at `now`, or -1 between flourishes. `offset` (a share of `every`) staggers a crowd.
function RigMath.FlourishElapsed(flourish: Types.RigFlourish, now: number, offset: number): number
	if flourish.every <= 0 then
		return -1
	end
	local into = (now + offset * flourish.every) % flourish.every
	return if into < flourish.length then into else -1
end

local function smooth(s: number): number
	return s * s * (3 - 2 * s)
end

-- Adds one flourish move at `elapsed` seconds into the flourish (nothing outside the move's own window).
function RigMath.AccumulateMove(pose: Types.RigPose, move: Types.RigMove, elapsed: number)
	if move.length <= 0 or elapsed < move.at or elapsed > move.at + move.length then
		return
	end
	local s = (elapsed - move.at) / move.length
	local kind, amp = move.kind, move.amp
	local axis: Types.RigAxis = move.axis
	if kind == "hop" then
		addOffset(pose, axis, amp * math.sin(math.pi * s))
	elseif kind == "turn" then
		addTurn(pose, axis, math.rad(amp) * smooth(s))
	elseif kind == "flare" then
		addTurn(pose, axis, math.rad(amp) * math.sin(math.pi * s))
	elseif kind == "swish" then
		addTurn(pose, axis, math.rad(amp) * math.sin(2 * TAU * s) * (1 - s))
	elseif kind == "pop" then
		grow(pose, amp * math.sin(math.pi * s))
	elseif kind == "squash" then
		stretch(pose, axis, amp * math.sin(TAU * s))
	end
end

-- The face plate's frame (0-based) at `now`: a blink wins (half, closed, half over blinkLength), then a glint (small, big, small over
-- glintLength), then the iris cycle at cycleFps, else the open frame.
function RigMath.FaceFrame(face: Types.RigFace, now: number, offset: number): number
	if face.blinkEvery > 0 and face.blinkLength > 0 then
		local into = (now + offset * face.blinkEvery) % face.blinkEvery
		if into < face.blinkLength then
			local third = face.blinkLength / 3
			return if into < third or into >= 2 * third then face.half else face.closed
		end
	end
	if #face.glint > 0 and face.glintEvery > 0 and face.glintLength > 0 then
		-- half a cycle after the blink's start, so a glint never lands on a blink of the same timing
		local into = (now + (offset + 0.5) * face.glintEvery) % face.glintEvery
		if into < face.glintLength then
			local third = face.glintLength / 3
			local big = into >= third and into < 2 * third
			return if big then face.glint[math.min(2, #face.glint)] else face.glint[1]
		end
	end
	if #face.cycle > 0 and face.cycleFps > 0 then
		local index = math.floor((now + offset * #face.cycle) * face.cycleFps) % #face.cycle
		return face.cycle[index + 1]
	end
	return face.open
end

-- The pixel offset of frame `frame` in the plate's sheet (frames run left to right, `columns` a row).
function RigMath.FrameOffset(face: Types.RigFace, frame: number): (number, number)
	local columns = math.max(1, face.columns)
	return (frame % columns) * face.frameWidth, math.floor(frame / columns) * face.frameHeight
end

-- The blink as a height share of the plate when no flipbook is uploaded: 1 open (and on glint or cycle frames), `half` and `closed` on
-- the blink's frames.
function RigMath.FallbackShare(face: Types.RigFace, frame: number, half: number, closed: number): number
	if frame == face.closed then
		return closed
	elseif frame == face.half then
		return half
	end
	return 1
end

-- Ranks aliens nearest first: `distances` (one per alien, math.huge for one that may not animate) into `picked` (true for the nearest
-- `cap` within `limit`). Ties keep the earlier alien. Allocation-free apart from the order list the caller passes in.
function RigMath.PickNearest(distances: { number }, cap: number, limit: number, picked: { boolean }, order: { number })
	table.clear(order)
	for i, d in ipairs(distances) do
		picked[i] = false
		if d <= limit then
			table.insert(order, i)
		end
	end
	table.sort(order, function(a: number, b: number): boolean
		if distances[a] == distances[b] then
			return a < b
		end
		return distances[a] < distances[b]
	end)
	for k = 1, math.min(cap, #order) do
		picked[order[k]] = true
	end
end

return RigMath
