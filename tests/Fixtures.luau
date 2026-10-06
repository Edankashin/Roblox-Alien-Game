--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local Growth = require(Shared.data.Growth)
local Leaderboard = require(Shared.data.Leaderboard)
local one = Tiers.Tiers.Common.workSpeed
local zero = Growth.ById[Growth.Default].workedSeconds
local two = one + one
-- Calendar expectations use the standard UTC calendar, independently of the
-- production reset formula. TZ=UTC is set by test.sh for os.time's local input.
local function advanceReset(start, direction)
	local candidate = start
	repeat
		candidate += Config.GiftDaySeconds * direction
	until os.date("!*t", candidate).wday == Leaderboard.ResetWeekday
	return candidate
end
local date = os.date("!*t", zero)
date.hour, date.min, date.sec = Leaderboard.ResetHourUtc, zero, zero
local boundary = os.time(date)
while os.date("!*t", boundary).wday ~= Leaderboard.ResetWeekday do
	boundary += Config.GiftDaySeconds
end
return {
	zero = zero, one = one, two = two, half = one / two,
	quarter = one / (two * two), tick = Config.IncomeTickSeconds,
	-- Derive numerical tolerance from the configured near-miss resolution.
	tolerance = Config.CaptureNearMissWidth ^ (two * two),
	boundary = boundary, advanceReset = advanceReset,
}
