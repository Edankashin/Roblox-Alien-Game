--!strict
-- ReplicatedStorage.Shared.CodesMath: when a promo code (data/Codes) works. Pure: the caller passes the clock
-- (os.time()), so the server's redeem check and the headless tests run the same rule. A code with `startsAt` is not
-- live before that second; one with an `expiresAt` above 0 stops working after that second (its last good second).

local CodesMath = {}

export type Window = { startsAt: number?, expiresAt: number }
export type Status = "Active" | "NotYet" | "Expired"

-- Where `now` falls against the code's window.
function CodesMath.Status(window: Window, now: number): Status
	local startsAt = window.startsAt
	if startsAt ~= nil and now < startsAt then
		return "NotYet"
	end
	if window.expiresAt > 0 and now > window.expiresAt then
		return "Expired"
	end
	return "Active"
end

return CodesMath
