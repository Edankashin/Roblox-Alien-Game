--!strict
-- ReplicatedStorage.Shared.data.Notify: the notification budget (docs/vault/05-ui-design/Clean-UI-Pass.md "The notification
-- budget"; UI Playbook "Clean pass: notifications"). Ethan, 2026-10-22: "the viewer shouldn't be overstimulated". At most three
-- things announce at once: ONE banner and TWO toasts. Every message the client shows belongs to one of four classes; the pure
-- rules live in Shared/NotifyMath and are held in tests/NotifyMath.spec.luau, the drawing in UI/Toast. Nothing here decides an
-- outcome: the server has already said what happened, this only says how loudly the client tells it.
--   Banner: its own slot, top centre, a sound once, Config.AnnounceSeconds. Something the player can join NOW (a Rush, a Shower, the
--     Warden, the Peddler, a bought Server Luck, someone else's Legendary and up) or a cinematic line (crash, fly). One on screen, a
--     queue of BannerQueueMax in priority order, one per kind (the latest wins), BannerGapSeconds between two, a queued banner older
--     than BannerStaleSeconds is dropped (its state is in the event chip by then).
--   Toast: the stack, a ding, Theme.Tween.Toast seconds. The player's own results and refusals. At most ToastMax on screen (a
--     third waits). A toast with the same merge key as a live one within MergeSeconds updates it in place, without a ding.
--   Quiet: the stack under the toasts, no sound, QuietSeconds. Dropped first when the stack is full, never held through a moment.
--   Chat / None: a system line in the chat, or nothing at all (the event chip carries the state).

export type Class = "Banner" | "Toast" | "Quiet" | "Chat" | "None"

-- A banner kind: the lower the priority, the sooner it shows when several wait; `gap` false lets the next banner follow at once
-- (the two crash lines belong to one cinematic).
export type BannerKind = { priority: number, gap: boolean }

local BannerKinds: { [string]: BannerKind } = {
	crash = { priority = 0, gap = false }, -- CameraDirector's first crash line
	crash2 = { priority = 0, gap = false }, -- and its second (its own kind, so the first is not replaced by it while it waits)
	fly = { priority = 0, gap = false }, -- the Star Chart's Fly line
	rush = { priority = 1, gap = true }, -- the Catch Rush starts
	shower = { priority = 1, gap = true }, -- the Meteor Shower starts
	warden = { priority = 2, gap = true }, -- the Warden is awake
	sighting = { priority = 2, gap = true }, -- the Warden's sighting starts
	peddler = { priority = 3, gap = true }, -- the Peddler landed
	serverluck = { priority = 4, gap = true }, -- someone bought Server Luck
	announce = { priority = 5, gap = true }, -- someone else's Legendary and up, a line from the team
}

-- Which class each named message takes. Anything not listed is a Toast (the default for a result or a refusal). A banner id is the
-- banner's kind (BannerKinds). The bootstrap routes through these names (init.client `notify`).
local Messages: { [string]: Class } = {
	-- banners: something to join now
	rush = "Banner",
	shower = "Banner",
	warden = "Banner",
	sighting = "Banner",
	peddler = "Banner",
	serverluck = "Banner",
	announce = "Banner",
	-- toasts: the player's own results, and things worth a ding that last longer than a moment
	material = "Toast",
	welcomeBack = "Toast",
	weeklyStart = "Toast", -- it lasts a week; the event chip carries it
	specialWeather = "Toast",
	blizzard = "Toast",
	friendJoined = "Toast",
	rushWinner = "Toast", -- someone else's win: not something to join
	-- quiet lines: the player loses nothing by missing them
	showerOver = "Quiet",
	wardenRetreat = "Quiet",
	sightingOver = "Quiet",
	friendLeft = "Quiet",
	visitor = "Quiet",
	waveGot = "Quiet",
	waveSent = "Quiet",
	habitatIncome = "Quiet",
	alienGrew = "Quiet",
}

-- Someone else's catch, by the player's Announcements setting (data/Settings, level index 0 Off, 1 Big only, 2 All) and the tier.
-- Rare: chat at Big only, a quiet line at All. Epic: a toast. Legendary and up: a banner. Off shows none. The array is by level index plus one.
local OthersCatch: { { [string]: Class } } = {
	{}, -- level 0, Off: nothing at all
	{ Rare = "Chat", Epic = "Toast", Legendary = "Banner", Cosmic = "Banner", Secret = "Banner" }, -- level 1, Big only
	{ Rare = "Quiet", Epic = "Toast", Legendary = "Banner", Cosmic = "Banner", Secret = "Banner" }, -- level 2, All
}

return {
	-- Budget
	ToastMax = 2, -- toasts and quiet lines on the stack at once; a third toast waits
	BannerQueueMax = 3, -- banners waiting behind the one on screen
	BannerGapSeconds = 1.5, -- from one banner leaving to the next showing
	BannerStaleSeconds = 12, -- a banner older than this in the queue is dropped
	QuietSeconds = 2, -- a quiet line's time on screen
	MergeSeconds = 3, -- a toast with the same key within this updates the live one in place
	CueGapSeconds = 0.5, -- at most one UI cue (banner sound, toast ding) in this time

	-- Where things sit (fractions of the screen)
	BannerTop = 0.19, -- the banner's slot, top centre, under the goal plate
	BannerWidth = 0.6,
	BannerAspect = 9,
	StackTop = 0.27, -- the toast stack starts here (lower while a banner stands in the top slot)

	-- The offline welcome toast: its lines, at most
	OfflineLinesMax = 3,

	-- The default Announcements level (data/Settings is the owner of the row; this is the fallback for a profile that lacks it)
	AnnounceLevelDefault = 1,

	BannerKinds = BannerKinds,
	Messages = Messages,
	OthersCatch = OthersCatch,
}
