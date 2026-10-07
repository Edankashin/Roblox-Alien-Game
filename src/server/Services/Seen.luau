--!strict
-- ServerScriptService.Server.Services.Seen: the first-time moments a player has watched (profile.seen, save schema v18).
-- The first arrival in each world plays a cinematic once per profile per world (CameraDirector.PlayShots, data/Cinematics);
-- the client decides to play it from the flag and tells the server it did, so a rejoin or a flight back never plays it
-- again. The client sends a key and nothing else: MarkSeen(key) accepts only the fixed keys data/Cinematics.SeenKeys lists
-- (CinematicMath.IsSeenKey), stores `profile.seen[key] = true` through PlayerData.Update and pushes the whole table back
-- (SeenChanged). Nothing about it touches Scrap, a catch or any outcome: the flag only decides whether a camera
-- moment is shown. The Studio chat command /cinematic goes through DevPlay and DevReset (guarded by Dev).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local CinematicsData = require(Shared.data.Cinematics)
local CinematicMath = require(Shared.CinematicMath)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)

local Seen = {}

local REMOTE_RATE_PER_SECOND = 4 -- MarkSeen calls per player per second (one per world arrival; a client bug cannot flood it)

-- Pushes -----------------------------------------------------------------

local function pushSeen(player: Player, profile: Types.Profile)
	local state: Types.SeenState = profile.seen
	Net.event("SeenChanged"):FireClient(player, state)
end

-- Remotes ----------------------------------------------------------------

-- MarkSeen(key) -> (ok, reason). Reasons: BadArgs (not one of data/Cinematics.SeenKeys), RateLimited, NoProfile.
local function onMarkSeen(player: Player, key: any): (boolean, string?)
	if not Net.allow(player, "MarkSeen", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if type(key) ~= "string" or not CinematicMath.IsSeenKey(key) then
		return false, "BadArgs"
	end
	local accepted: string = key
	local ok = PlayerData.Update(player, function(profile)
		profile.seen[accepted] = true
	end)
	if not ok then
		return false, "NoProfile"
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushSeen(player, profile)
	end
	return true, nil
end

-- Public API -------------------------------------------------------------

-- Developer overrides (Studio commands, guarded by Dev): forget every seen flag so the arrivals can play again.
function Seen.DevReset(player: Player)
	local ok = PlayerData.Update(player, function(profile)
		profile.seen = {}
	end)
	local profile = PlayerData.Get(player)
	if ok and profile then
		pushSeen(player, profile)
	end
end

-- Developer override: tell the client to play `momentId` now (a data/Cinematics moment). False for an unknown moment.
function Seen.DevPlay(player: Player, momentId: string): boolean
	if not CinematicMath.HasMoment(momentId) then
		return false
	end
	Net.event("DevCinematic"):FireClient(player, momentId)
	return true
end

-- The keys the profile has watched, sorted (for a Studio print).
function Seen.DevList(player: Player): { string }
	local list: { string } = {}
	local profile = PlayerData.Get(player)
	if profile then
		for key, watched in pairs(profile.seen) do
			if watched then
				table.insert(list, key)
			end
		end
	end
	table.sort(list)
	return list
end

function Seen.Init()
	-- DevCinematic is created in every server so the client's listener never waits for it; only Dev ever fires it, and Dev
	-- exists in Studio only.
	for _, name in ipairs({ "SeenChanged", "DevCinematic" }) do
		Net.event(name)
	end
	Net.func("MarkSeen").OnServerInvoke = onMarkSeen
end

function Seen.Start()
	local count = 0
	for _ in pairs(CinematicsData.SeenKeys) do
		count += 1
	end
	print(("[%s] Seen: %d first-time moments"):format(Config.WorkingTitle, count))
end

return Seen
