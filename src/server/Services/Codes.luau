--!strict
-- ServerScriptService.Server.Services.Codes: promo codes (Shared/data/Codes). RedeemCode(code) pays a code's
-- rewards once per player through Gifts.GrantRewards and records it in profile.codes. The client sends the
-- text as typed; this service upper-cases it, trims the spaces and decides everything. Init also hands

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CodesData = require(Shared.data.Codes)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Gifts = require(script.Parent.Gifts)

local Codes = {}

-- RedeemCode(code) -> (ok, reason). Reasons: RateLimited, NoProfile, TooLong (over MaxLength, refused
-- before any lookup), Unknown (not a string, empty, or not in the table), Used (this player already
-- redeemed it), Expired (expiresAt is set and has passed).
local function onRedeem(player: Player, code: any): (boolean, string?)
	if not Net.allow(player, "RedeemCode", CodesData.RedeemPerSecond) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if type(code) ~= "string" then
		return false, "Unknown"
	end
	if #code > CodesData.MaxLength then
		return false, "TooLong"
	end
	local key = string.upper((string.gsub(code, "%s+", "")))
	local def = CodesData.Codes[key]
	if key == "" or not def then
		return false, "Unknown"
	end
	if def.expiresAt > 0 and os.time() > def.expiresAt then
		return false, "Expired"
	end
	local used = false
	local ok = PlayerData.Update(player, function(profile)
		if profile.codes[key] then
			used = true
		else
			profile.codes[key] = true
		end
	end)
	if not ok then
		return false, "NoProfile"
	end
	if used then
		return false, "Used"
	end
	Gifts.GrantRewards(player, def.rewards)
	Analytics.Event(player, AnalyticsData.Events.Code, 1, { id = key })
	return true, nil
end

function Codes.Init()
	Net.func("RedeemCode").OnServerInvoke = onRedeem
end

function Codes.Start() end

return Codes
