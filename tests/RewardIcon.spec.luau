--!strict
-- Shared/RewardIcon: every reward on a Welcome Week or Playtime card resolves to a drawn pixel icon, so no card shows a blank where the
-- others show a picture (Mac job 64: the 30 min "1 free spin" card had none).
local Shared = game:GetService("ReplicatedStorage").Shared
local Gifts = require(Shared.data.Gifts)
local Playtime = require(Shared.data.Playtime)
local PixelIcons = require(Shared.data.PixelIcons)
local RewardIcon = require(Shared.RewardIcon)

describe("RewardIcon", function()
	it("gives a free spin the wheel icon", function()
		expect(RewardIcon.Key({ kind = "spin", amount = 1 })).toEqual("Spin")
		expect(PixelIcons.Icons.Spin ~= nil).toEqual(true)
	end)
	it("names the other kinds as before", function()
		expect(RewardIcon.Key({ kind = "scrap", amount = 150 })).toEqual("Scrap")
		expect(RewardIcon.Key({ kind = "lure", id = "Lure1", amount = 1 })).toEqual("Lure1")
		expect(RewardIcon.Key({ kind = "powerUp", id = "SpeedBurst", amount = 1 })).toEqual("SpeedBurst")
		expect(RewardIcon.Key({ kind = "egg", tier = "Rare", amount = 1 })).toEqual("EggRare")
		expect(RewardIcon.Key({ kind = "nonsense", amount = 1 })).toEqual(nil)
	end)
	it("has a drawn icon for every Playtime gift", function()
		for _, gift in ipairs(Playtime.Gifts) do
			local key = RewardIcon.Key(gift.reward)
			assert(key ~= nil and PixelIcons.Icons[key] ~= nil, ("Playtime %d min (%s) has no pixel icon"):format(gift.minutes, gift.reward.kind))
		end
	end)
	it("has a drawn icon for every Welcome Week reward, the lead and the also list", function()
		for _, row in ipairs(Gifts) do
			local key = RewardIcon.Key(row.reward)
			assert(key ~= nil and PixelIcons.Icons[key] ~= nil, ("Welcome Week day %d (%s) has no pixel icon"):format(row.day, row.reward.kind))
			for _, extra in ipairs(row.also or {}) do
				local extraKey = RewardIcon.Key(extra)
				assert(extraKey ~= nil and PixelIcons.Icons[extraKey] ~= nil, ("Welcome Week day %d also %s has no pixel icon"):format(row.day, extra.kind))
			end
		end
	end)
end)

return true
