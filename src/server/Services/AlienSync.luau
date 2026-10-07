--!strict
-- ServerScriptService.Server.Services.AlienSync: how the alien list reaches the client (milestone 50 report). A profile can hold
-- 640 records today and 1,500 later (about 193 bytes each), so sending every record after every catch, fusion, release, seat
-- change and growth stage was 125 to 290 KB a push. Now the client gets the list once, as a snapshot, and after that only what
-- changed (AliensDelta).
-- Per player this keeps a shadow: a copy of the records and stations as the client was last told them, and the number of the
-- last delta. Flush(player, profile) is the one helper every push site calls after its PlayerData.Update: it diffs the live
-- profile against the shadow (Shared/AlienDelta), and when anything differs advances the shadow, numbers the delta and sends
-- it, so one update is one delta however many records it touched, and an update that changed nothing the client holds sends
-- nothing. Because it compares values, every service that writes a record and calls Economy.PushCamp (Habitats, HomeBuild, Dev)
-- is covered without telling this module which record it changed.
-- Snapshots: PlayerData hands the client the join profile and the GetProfile pull through Baseline, which copies the live
-- records into the shadow and returns the number they start at (profile.aliensSeq); the GetAliens pull (Snapshot) is the
-- client's answer to a missed delta. Every snapshot takes a new number, so a client that kept an older snapshot sees a gap at the
-- next delta and pulls. Until a client has a snapshot there is no shadow and Flush sends nothing: the join profile is read from
-- the live records.
-- Needs no other service: PlayerData requires this module (never the reverse), so the profile is always passed in.
-- Studio: DevGap (the /deltas gap command) skips one number so the client's recovery can be watched.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local AlienDelta = require(Shared.AlienDelta)
local Net = require(Shared.Net)

local AlienSync = {}

type Shadow = {
	seq: number, -- the number of the last delta sent (or the snapshot's number before any delta)
	mirror: AlienDelta.Mirror, -- the records and stations as the client was last told
}

local shadows: { [number]: Shadow } = {}

-- Hands the client a snapshot of this profile's alien list: copies it into the shadow and returns the number the list starts at
-- (0 for a player's first snapshot, then one past the last number used). Call it when the profile goes to the client.
function AlienSync.Baseline(player: Player, profile: Types.Profile): number
	local old = shadows[player.UserId]
	local seq = if old then old.seq + 1 else 0
	shadows[player.UserId] = { seq = seq, mirror = AlienDelta.Copy(profile) }
	return seq
end

-- The GetAliens answer: the live records and stations with the number they start at.
function AlienSync.Snapshot(player: Player, profile: Types.Profile): Types.AliensSnapshot
	return { seq = AlienSync.Baseline(player, profile), aliens = profile.aliens, stations = profile.stations }
end

-- Sends the client what changed in the alien list since it was last told, as one AliensDelta. Nothing is sent when nothing
-- differs, or before the client has a snapshot. Call it after the PlayerData.Update that changed records or seats.
function AlienSync.Flush(player: Player, profile: Types.Profile)
	local shadow = shadows[player.UserId]
	if not shadow then
		return
	end
	local delta = AlienDelta.Diff(shadow.mirror, profile, shadow.seq + 1)
	if not delta then
		return
	end
	AlienDelta.Apply(shadow.mirror, delta)
	shadow.seq = delta.seq
	Net.event("AliensDelta"):FireClient(player, delta)
end

-- Forgets a player who left.
function AlienSync.Forget(player: Player)
	shadows[player.UserId] = nil
end

-- Studio Dev (/deltas gap): skips one delta number and sends an empty delta with the next, so the client sees a gap at once.
-- Returns the number sent, nil when the client has no snapshot yet.
function AlienSync.DevGap(player: Player): number?
	local shadow = shadows[player.UserId]
	if not shadow then
		return nil
	end
	shadow.seq += 1 -- the number the client never hears of
	shadow.seq += 1 -- the one it does
	Net.event("AliensDelta"):FireClient(player, { seq = shadow.seq })
	return shadow.seq
end

-- Studio Dev (/deltas): the number of the last delta sent and how many records the shadow holds; nil without a snapshot.
function AlienSync.DevStatus(player: Player): (number?, number)
	local shadow = shadows[player.UserId]
	if not shadow then
		return nil, 0
	end
	local count = 0
	for _ in pairs(shadow.mirror.aliens) do
		count += 1
	end
	return shadow.seq, count
end

function AlienSync.Init()
	-- Created up front so a client that joins before its profile loads can already be listening.
	Net.event("AliensDelta")
end

return AlienSync
