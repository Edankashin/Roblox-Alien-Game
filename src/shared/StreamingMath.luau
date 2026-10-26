--!strict
-- ReplicatedStorage.Shared.StreamingMath: pure rules for Workspace streaming (data/Streaming). No Roblox runtime needed, so
-- tests/StreamingMath.spec.luau runs it headless. The server compares the live Workspace with the data table (Mismatch); the client's
-- cinematics ask for the far shot positions to be streamed (FarPoints).

local StreamingMath = {}

export type Live = { enabled: boolean, minRadius: number, targetRadius: number, integrityMode: string }
export type Want = { Enabled: boolean, MinRadius: number, TargetRadius: number, IntegrityMode: string }

-- What differs between the live Workspace and the data table, one sentence each (empty when the place matches). A place that was
-- not synced from its project file (Studio opened without Rojo, a place saved before the properties were added) reports here.
function StreamingMath.Mismatch(live: Live, want: Want): { string }
	local found = {}
	if live.enabled ~= want.Enabled then
		table.insert(found, ("StreamingEnabled is %s, data/Streaming wants %s"):format(tostring(live.enabled), tostring(want.Enabled)))
	end
	if want.Enabled then
		if live.minRadius ~= want.MinRadius then
			table.insert(found, ("StreamingMinRadius is %s, data/Streaming wants %s"):format(tostring(live.minRadius), tostring(want.MinRadius)))
		end
		if live.targetRadius ~= want.TargetRadius then
			table.insert(found, ("StreamingTargetRadius is %s, data/Streaming wants %s"):format(tostring(live.targetRadius), tostring(want.TargetRadius)))
		end
		if live.integrityMode ~= want.IntegrityMode then
			table.insert(found, ("StreamingIntegrityMode is %s, data/Streaming wants %s"):format(live.integrityMode, want.IntegrityMode))
		end
	end
	return found
end

-- The positions a cinematic should ask the server to stream: of `points` (shot positions, in play order) the ones strictly farther
-- than `minDistance` (3D) from `origin`, first ones first, at most `limit`, each at most once (a pull-out that returns to the same
-- spot asks once). Points are {x, y, z}.
export type Point = { x: number, y: number, z: number }
function StreamingMath.FarPoints(points: { Point }, origin: Point, minDistance: number, limit: number): { Point }
	local chosen: { Point } = {}
	for _, point in ipairs(points) do
		if #chosen >= limit then
			break
		end
		local dx, dy, dz = point.x - origin.x, point.y - origin.y, point.z - origin.z
		if dx * dx + dy * dy + dz * dz > minDistance * minDistance then
			local repeated = false
			for _, taken in ipairs(chosen) do
				if taken.x == point.x and taken.y == point.y and taken.z == point.z then
					repeated = true
					break
				end
			end
			if not repeated then
				table.insert(chosen, point)
			end
		end
	end
	return chosen
end

return StreamingMath
