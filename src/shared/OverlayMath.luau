--!strict
-- ReplicatedStorage.Shared.OverlayMath: the overlay rolls as pure functions, so the server's Spawner and the headless
-- tests read one rule. Pick walks the usual odds (data/Overlays chances, in Order); the launch overlay is a separate
-- roll that exists only inside LaunchWindow (a unix-seconds window in UTC, like data/Seasons) and rolls on free wild
-- spawns only. The caller draws the rolls (percent, [0, 100)); nothing here reads the clock or a random number.

local Types = require(script.Parent.types.Types)
local Overlays = require(script.Parent.data.Overlays)

local OverlayMath = {}

-- The usual overlay for a roll in [0, 100): the Order rows' chances laid end to end, "None" past their sum.
function OverlayMath.Pick(roll: number): Types.Overlay
	local acc = 0
	for _, name in ipairs(Overlays.Order) do
		acc += Overlays.Overlays[name].chance
		if roll < acc then
			return name :: Types.Overlay
		end
	end
	return "None"
end

-- Whether the launch window is open at `now` (unix seconds): [startsAt, endsAt).
function OverlayMath.LaunchActive(now: number): boolean
	local window = Overlays.LaunchWindow
	return now >= window.startsAt and now < window.endsAt
end

-- The launch overlay for a roll in [0, 100) when `now` is inside the window, else nil (the caller rolls on as usual).
function OverlayMath.LaunchPick(now: number, roll: number): Types.Overlay?
	local window = Overlays.LaunchWindow
	if OverlayMath.LaunchActive(now) and roll < window.chance then
		return window.overlay :: Types.Overlay
	end
	return nil
end

return OverlayMath
