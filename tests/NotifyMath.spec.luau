--!strict
-- The notification budget (data/Notify) and its rules (Shared/NotifyMath): the four classes, the banner queue (priority order, one per kind,
-- the limit, the stale drop, the gap), the toast stack (two places, a third waits, quiet lines go first and are never held), merging, the cue
-- gap, the Announcements levels and the offline welcome toast. UI/Toast draws exactly this.
local Shared = game:GetService("ReplicatedStorage").Shared
local Notify = require(Shared.data.Notify)
local Settings = require(Shared.data.Settings)
local NotifyMath = require(Shared.NotifyMath)
local Strings = require(Shared.strings.en)
local Tiers = require(Shared.data.Tiers)

local function banner(kind: string, queuedAt: number): NotifyMath.Banner
	return { kind = kind, queuedAt = queuedAt, payload = kind .. "@" .. tostring(queuedAt) }
end

local function kinds(queue: { NotifyMath.Banner }): string
	local out: { string } = {}
	for _, item in ipairs(queue) do
		table.insert(out, item.kind)
	end
	return table.concat(out, ",")
end

describe("the budget numbers", function()
	it("holds one banner and two toasts at most", function()
		expect(Notify.ToastMax).toEqual(2)
		expect(Notify.BannerQueueMax).toEqual(3)
		expect(Notify.BannerGapSeconds).toEqual(1.5)
		expect(Notify.BannerStaleSeconds).toEqual(12)
		expect(Notify.MergeSeconds).toEqual(3)
		expect(Notify.CueGapSeconds).toEqual(0.5)
	end)

	it("puts the banner's slot above the toast stack at its default", function()
		expect(Notify.BannerTop < Notify.StackTop).toEqual(true)
	end)

	it("gives every banner kind a priority and every banner message a kind", function()
		for id, class in pairs(Notify.Messages) do
			if class == "Banner" then
				expect(Notify.BannerKinds[id] ~= nil).toEqual(true)
			end
		end
		for kind, row in pairs(Notify.BannerKinds) do
			expect(row.priority >= 0).toEqual(true)
			expect(kind ~= "").toEqual(true)
		end
	end)

	it("orders the kinds as the spec does: Rush and Shower, Warden and sighting, Peddler, Server Luck, others' catches", function()
		local p = NotifyMath.BannerPriority
		expect(p("rush")).toEqual(p("shower"))
		expect(p("rush") < p("warden")).toEqual(true)
		expect(p("warden")).toEqual(p("sighting"))
		expect(p("sighting") < p("peddler")).toEqual(true)
		expect(p("peddler") < p("serverluck")).toEqual(true)
		expect(p("serverluck") < p("announce")).toEqual(true)
		expect(p("crash") < p("rush")).toEqual(true)
		expect(p("something else") > p("announce")).toEqual(true)
	end)
end)

describe("message classes", function()
	it("sends the join-now events to the banner, results to toasts and the rest to quiet lines", function()
		for _, id in ipairs({ "rush", "shower", "warden", "sighting", "peddler", "serverluck" }) do
			expect(NotifyMath.MessageClass(id)).toEqual("Banner")
		end
		for _, id in ipairs({ "material", "welcomeBack", "weeklyStart", "specialWeather", "blizzard" }) do
			expect(NotifyMath.MessageClass(id)).toEqual("Toast")
		end
		for _, id in ipairs({ "showerOver", "wardenRetreat", "sightingOver", "friendLeft", "visitor", "waveGot", "waveSent", "habitatIncome", "alienGrew" }) do
			expect(NotifyMath.MessageClass(id)).toEqual("Quiet")
		end
	end)

	it("makes an unnamed message a toast", function()
		expect(NotifyMath.MessageClass("anything at all")).toEqual("Toast")
	end)

	it("never gives a message a class outside the four", function()
		for _, class in pairs(Notify.Messages) do
			expect(class == "Banner" or class == "Toast" or class == "Quiet" or class == "Chat" or class == "None").toEqual(true)
		end
	end)
end)

describe("someone else's catch", function()
	it("at Big only: a Rare in chat, an Epic as a toast, a Legendary and up as a banner", function()
		expect(NotifyMath.OthersCatchClass(1, "Rare")).toEqual("Chat")
		expect(NotifyMath.OthersCatchClass(1, "Epic")).toEqual("Toast")
		for _, tier in ipairs({ "Legendary", "Cosmic", "Secret" }) do
			expect(NotifyMath.OthersCatchClass(1, tier)).toEqual("Banner")
		end
	end)

	it("at All: a Rare as a quiet line too", function()
		expect(NotifyMath.OthersCatchClass(2, "Rare")).toEqual("Quiet")
		expect(NotifyMath.OthersCatchClass(2, "Epic")).toEqual("Toast")
		expect(NotifyMath.OthersCatchClass(2, "Legendary")).toEqual("Banner")
	end)

	it("at Off: nothing from any tier", function()
		for _, tier in ipairs(Tiers.Order) do
			expect(NotifyMath.OthersCatchClass(0, tier)).toEqual("None")
		end
	end)

	it("shows nothing for a tier below Rare, and reads a level outside the range as the default", function()
		expect(NotifyMath.OthersCatchClass(2, "Common")).toEqual("None")
		expect(NotifyMath.OthersCatchClass(2, "Uncommon")).toEqual("None")
		expect(NotifyMath.OthersCatchClass(9, "Epic")).toEqual(NotifyMath.OthersCatchClass(Notify.AnnounceLevelDefault, "Epic"))
		expect(NotifyMath.OthersCatchClass(-3, "Legendary")).toEqual(NotifyMath.OthersCatchClass(Notify.AnnounceLevelDefault, "Legendary"))
	end)

	it("never shows a quieter class for a higher tier", function()
		local rank = { None = 0, Chat = 1, Quiet = 2, Toast = 3, Banner = 4 }
		for level = 0, 2 do
			local last = 0
			for _, tier in ipairs(Tiers.Order) do
				local now = rank[NotifyMath.OthersCatchClass(level, tier)]
				expect(now >= last).toEqual(true)
				last = now
			end
		end
	end)

	it("matches the Announcements row of the Settings: levels 0 to 2, default Big only, three level names, after Silhouettes", function()
		local row = Settings.ById.Announcements
		expect(row ~= nil).toEqual(true)
		local def = row :: Settings.SettingDef
		expect(def.kind).toEqual("level")
		expect(#(def.levels :: { number })).toEqual(3)
		expect(def.default).toEqual(Notify.AnnounceLevelDefault)
		expect(#(def.levelKeys :: { string })).toEqual(3)
		local silhouettes, announcements = 0, 0
		for index, entry in ipairs(Settings.Order) do
			if entry.key == "Silhouettes" then
				silhouettes = index
			elseif entry.key == "Announcements" then
				announcements = index
			end
		end
		expect(announcements).toEqual(silhouettes + 1)
	end)

	it("has a row for each of the three Announcements levels, and a name for each", function()
		expect(#Notify.OthersCatch).toEqual(3)
		for index = 0, 2 do
			expect((Strings :: any)["SETTINGS_Announce_" .. index] ~= nil).toEqual(true)
		end
	end)
end)

describe("the banner queue", function()
	it("shows banners in priority order, first come first served within one", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("announce", 0), false)
		NotifyMath.InsertBanner(queue, banner("peddler", 1), false)
		NotifyMath.InsertBanner(queue, banner("rush", 2), false)
		expect(kinds(queue)).toEqual("rush,peddler,announce")
		local queue2: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue2, banner("shower", 0), false)
		NotifyMath.InsertBanner(queue2, banner("rush", 1), false)
		expect(kinds(queue2)).toEqual("shower,rush")
	end)

	it("puts a banner that came down for a quiet moment ahead of the others of its priority", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("shower", 0), false)
		NotifyMath.InsertBanner(queue, banner("peddler", 0), false)
		NotifyMath.InsertBanner(queue, banner("rush", 1), true)
		expect(kinds(queue)).toEqual("rush,shower,peddler")
	end)

	it("keeps one banner per kind: the latest wins", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("announce", 0), false)
		NotifyMath.InsertBanner(queue, banner("peddler", 1), false)
		NotifyMath.InsertBanner(queue, banner("announce", 2), false)
		expect(#queue).toEqual(2)
		expect(kinds(queue)).toEqual("peddler,announce")
		expect(queue[2].queuedAt).toEqual(2)
	end)

	it("holds at most BannerQueueMax, dropping the lowest-priority newest", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("announce", 0), false)
		NotifyMath.InsertBanner(queue, banner("serverluck", 0), false)
		NotifyMath.InsertBanner(queue, banner("peddler", 0), false)
		expect(#queue).toEqual(Notify.BannerQueueMax)
		local dropped = NotifyMath.InsertBanner(queue, banner("rush", 0), false)
		expect(#queue).toEqual(Notify.BannerQueueMax)
		expect((dropped :: NotifyMath.Banner).kind).toEqual("announce")
		expect(kinds(queue)).toEqual("rush,peddler,serverluck")
		-- a banner that ranks last is the one dropped
		local late = NotifyMath.InsertBanner(queue, banner("something else", 0), false)
		expect((late :: NotifyMath.Banner).kind).toEqual("something else")
		expect(#queue).toEqual(Notify.BannerQueueMax)
	end)

	it("drops a banner queued longer than BannerStaleSeconds and keeps the fresh ones", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("rush", 0), false)
		NotifyMath.InsertBanner(queue, banner("peddler", 8), false)
		expect(NotifyMath.DropStale(queue, Notify.BannerStaleSeconds)).toEqual(0)
		expect(#queue).toEqual(2)
		expect(NotifyMath.DropStale(queue, Notify.BannerStaleSeconds + 0.5)).toEqual(1)
		expect(kinds(queue)).toEqual("peddler")
	end)

	it("waits for the slot: nothing before it frees, the first banner after, the stale ones never", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("rush", 0), false)
		NotifyMath.InsertBanner(queue, banner("warden", 0), false)
		expect(NotifyMath.NextBanner(queue, 1, 2)).toEqual(nil)
		expect(#queue).toEqual(2)
		local first = NotifyMath.NextBanner(queue, 2, 2) :: NotifyMath.Banner
		expect(first.kind).toEqual("rush")
		expect(#queue).toEqual(1)
		-- the warden has waited too long by now
		expect(NotifyMath.NextBanner(queue, Notify.BannerStaleSeconds + 1, 0)).toEqual(nil)
		expect(#queue).toEqual(0)
		expect(NotifyMath.NextBanner(queue, 100, 0)).toEqual(nil)
	end)

	it("lets a rush and a sighting share the slot one after the other, a gap apart", function()
		local queue: { NotifyMath.Banner } = {}
		NotifyMath.InsertBanner(queue, banner("sighting", 0), false)
		NotifyMath.InsertBanner(queue, banner("rush", 0.5), false)
		local now = 1
		local shown = NotifyMath.NextBanner(queue, now, 0) :: NotifyMath.Banner
		expect(shown.kind).toEqual("rush")
		local leaves = now + 4 -- AnnounceSeconds
		local freeAt = leaves + NotifyMath.BannerGap(shown.kind)
		expect(freeAt).toEqual(leaves + Notify.BannerGapSeconds)
		expect(NotifyMath.NextBanner(queue, leaves + 1, freeAt)).toEqual(nil)
		local second = NotifyMath.NextBanner(queue, freeAt, freeAt) :: NotifyMath.Banner
		expect(second.kind).toEqual("sighting")
	end)

	it("has no gap after a cinematic line, so the two crash lines follow each other", function()
		expect(NotifyMath.BannerGap("crash")).toEqual(0)
		expect(NotifyMath.BannerGap("crash2")).toEqual(0)
		expect(NotifyMath.BannerGap("fly")).toEqual(0)
		expect(NotifyMath.BannerGap("rush")).toEqual(Notify.BannerGapSeconds)
		expect(NotifyMath.BannerGap("unknown")).toEqual(Notify.BannerGapSeconds)
	end)
end)

describe("a banner and an open panel", function()
	it("drops a banner standing at the top when a panel opens, so it never covers the header or the close button", function()
		expect(NotifyMath.BannerMustMoveDown(true, true)).toEqual(true)
	end)
	it("leaves a top banner alone with no panel and a bottom banner alone always", function()
		expect(NotifyMath.BannerMustMoveDown(true, false)).toEqual(false)
		expect(NotifyMath.BannerMustMoveDown(false, true)).toEqual(false)
		expect(NotifyMath.BannerMustMoveDown(false, false)).toEqual(false)
	end)
end)

describe("the toast stack", function()
	it("shows a toast or a quiet line while there is room", function()
		expect((NotifyMath.StackAnswer({}, "Toast"))).toEqual("show")
		expect((NotifyMath.StackAnswer({ "Toast" }, "Toast"))).toEqual("show")
		expect((NotifyMath.StackAnswer({ "Toast" }, "Quiet"))).toEqual("show")
	end)

	it("makes a third toast wait", function()
		expect((NotifyMath.StackAnswer({ "Toast", "Toast" }, "Toast"))).toEqual("wait")
	end)

	it("lets a toast push out the oldest quiet line when the stack is full", function()
		local answer, evict = NotifyMath.StackAnswer({ "Toast", "Quiet" }, "Toast")
		expect(answer).toEqual("show")
		expect(evict).toEqual(2)
		local answer2, evict2 = NotifyMath.StackAnswer({ "Quiet", "Quiet" }, "Toast")
		expect(answer2).toEqual("show")
		expect(evict2).toEqual(1)
	end)

	it("drops a quiet line when the stack is full, never holding it", function()
		expect((NotifyMath.StackAnswer({ "Toast", "Toast" }, "Quiet"))).toEqual("drop")
		expect((NotifyMath.StackAnswer({ "Toast", "Quiet" }, "Quiet"))).toEqual("drop")
	end)
end)

describe("merging", function()
	it("joins a message within MergeSeconds of the last update and not after", function()
		expect(NotifyMath.CanMerge(10, 10)).toEqual(true)
		expect(NotifyMath.CanMerge(10, 10 + Notify.MergeSeconds)).toEqual(true)
		expect(NotifyMath.CanMerge(10, 10 + Notify.MergeSeconds + 0.01)).toEqual(false)
		expect(NotifyMath.CanMerge(10, 9)).toEqual(false)
	end)

	it("counts three quick pickups up to +3 and starts again after a pause", function()
		local total, at = 0, -100
		for step = 1, 3 do
			local now = step * 0.8
			total = NotifyMath.MergedTotal(total, at, now, 1)
			at = now
			expect(total).toEqual(step)
		end
		expect(Strings.TOAST_MATERIAL:format(total, "Wreck Plate")).toEqual("+3 Wreck Plate")
		total = NotifyMath.MergedTotal(total, at, at + Notify.MergeSeconds + 1, 1)
		expect(total).toEqual(1)
	end)

	it("restarts the window with every update", function()
		local total, at = 0, -100
		for step = 1, 6 do
			local now = step * 2.5 -- each inside 3 s of the one before, the whole run far longer than 3 s
			total = NotifyMath.MergedTotal(total, at, now, 1)
			at = now
		end
		expect(total).toEqual(6)
	end)
end)

describe("the cue gap", function()
	it("allows a sound at once, then not again for CueGapSeconds", function()
		expect(NotifyMath.CueAllowed(5, -math.huge)).toEqual(true)
		expect(NotifyMath.CueAllowed(5.2, 5)).toEqual(false)
		expect(NotifyMath.CueAllowed(5 + Notify.CueGapSeconds, 5)).toEqual(true)
		expect(NotifyMath.CueAllowed(6, 5)).toEqual(true)
	end)
end)

describe("the offline welcome toast", function()
	it("is one greeting line when nothing happened but the Scrap", function()
		local lines = NotifyMath.OfflineLines({ scrapText = "1,234", moduleNames = {}, grown = 0 })
		expect(#lines).toEqual(1)
		expect(lines[1]).toEqual(Strings.OFFLINE_SUMMARY:format("1,234"))
	end)

	it("falls back to the plain greeting without Scrap", function()
		local lines = NotifyMath.OfflineLines({ moduleNames = {}, grown = 0 })
		expect(lines[1]).toEqual(Strings.OFFLINE_TITLE)
		local empty = NotifyMath.OfflineLines({ scrapText = "", moduleNames = { "Hull Frame" }, grown = 0 })
		expect(empty[1]).toEqual(Strings.OFFLINE_TITLE)
	end)

	it("adds one line for the modules and one for the growth, three at most", function()
		local lines = NotifyMath.OfflineLines({ scrapText = "900", moduleNames = { "Hull Frame" }, grown = 4 })
		expect(#lines).toEqual(3)
		expect(lines[2]).toEqual(Strings.OFFLINE_LINE_MODULE:format("Hull Frame"))
		expect(lines[3]).toEqual(Strings.OFFLINE_LINE_GREW:format(4))
	end)

	it("counts several modules in one line instead of naming each", function()
		local lines = NotifyMath.OfflineLines({ scrapText = "900", moduleNames = { "A", "B", "C", "D", "E" }, grown = 1 })
		expect(#lines).toEqual(3)
		expect(lines[2]).toEqual(Strings.OFFLINE_LINE_MODULES:format(5))
		expect(lines[3]).toEqual(Strings.OFFLINE_LINE_GREW_ONE)
	end)

	it("never has more lines than the budget allows, whatever the parts", function()
		for modules = 0, 6 do
			for grown = 0, 3 do
				local names: { string } = {}
				for index = 1, modules do
					table.insert(names, "M" .. index)
				end
				local lines = NotifyMath.OfflineLines({ scrapText = "5", moduleNames = names, grown = grown })
				expect(#lines <= Notify.OfflineLinesMax).toEqual(true)
				expect(#lines >= 1).toEqual(true)
			end
		end
	end)
end)

return true
