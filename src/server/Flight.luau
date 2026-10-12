--!strict
-- ServerScriptService.Server.Flight: the one flight latch, by UserId. A launch, a Star Chart flight or a
-- visit trip (Launch.luau) sets it when accepted and clears it when the teleport fails, the delay ends with
-- no live place, or the player leaves. While it is set, Launch answers Busy to a second flight and the
-- capture, pickup, module and heater handlers refuse with InFlight (Exploit-Review D4): the profile already
-- names the next world while the ship is still lifting off, so those actions would land in the wrong world.
-- A plain module beside ProfileSchema, not a service: it has no Init or Start, requires nothing, and any
-- service may require it without a cycle.

local Flight = {}

local inFlight: { [number]: boolean } = {} -- by UserId

-- Starts a flight for this player. False when one is already in flight (nothing changes).
function Flight.Begin(userId: number): boolean
	if inFlight[userId] then
		return false
	end
	inFlight[userId] = true
	return true
end

-- Ends the flight (teleport failed or skipped, or the player gave up). Safe when none is set.
function Flight.End(userId: number)
	inFlight[userId] = nil
end

function Flight.IsInFlight(userId: number): boolean
	return inFlight[userId] == true
end

-- The player left the server: same as End, named for the leave hook.
function Flight.Clear(userId: number)
	Flight.End(userId)
end

return Flight
