--!strict
-- ReplicatedStorage.Shared.PartyMath: the co-play measurement's two pure rules, kept out of the Friends service so
-- they can be tested without a server. Friends counts a player's friends from the pair cache and rate-limits the
-- Party analytics event (Config.PartyEventGapSeconds); nothing here reads a clock, a Player or a data table.

local PartyMath = {}

-- How many entries of one player's pair row (other UserId -> is a friend) are true. A nil row (no lookups yet) is 0.
function PartyMath.CountFriends(row: { [number]: boolean? }?): number
	local n = 0
	if row then
		for _, isFriend in pairs(row) do
			if isFriend then
				n += 1
			end
		end
	end
	return n
end

-- Whether a Party event may go out now: none was sent before (lastSentAt nil), or `gap` seconds have passed since it.
function PartyMath.GapElapsed(lastSentAt: number?, now: number, gap: number): boolean
	return lastSentAt == nil or now - lastSentAt >= gap
end

return PartyMath
