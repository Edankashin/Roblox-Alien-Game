--!strict
-- ReplicatedStorage.Shared.OnceGate: lets a thing through once per key until the gate is cleared. Pure logic, no Roblox
-- types; the launch sequence (the lift-off continuation and the "opens when it is published" toast) and the server's
-- Sightings service (the "crosses the map" line) each own one, and the headless spec runs the same module.
--
-- Why it exists: a callback that a presentation chains onto an engine event can run more than once for one cause (the
-- launch sequence's lift-done callback rode a tween's Completed event, which is also the event a Cancel raises, and the
-- reset behind the black screen cancels the finished lift's tweens; a second run of the return showed the toast a second
-- time), and a diagnostic that reports a start repeats itself when the start is repeated (a restarted sighting reported
-- the same 74 s each time). The gate answers "has this already happened for this key?" in one place.
--
-- Take(key) answers true the first time a key is offered and false for every later offer of it. Clear() forgets every key,
-- so the same keys pass again (a new launch, the next sighting).

local OnceGate = {}

export type Gate = {
	Take: (key: string) -> boolean,
	Clear: () -> (),
}

function OnceGate.new(): Gate
	local taken: { [string]: boolean } = {}
	local gate: Gate = {
		Take = function(key: string): boolean
			if taken[key] then
				return false
			end
			taken[key] = true
			return true
		end,
		Clear = function()
			taken = {}
		end,
	}
	return gate
end

return OnceGate
