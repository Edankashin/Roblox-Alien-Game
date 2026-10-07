--!strict
-- Alien storage cap (milestone 50; PRE_PRODUCTION section 5c item 7, Codex C17). Why: a save is ONE DataStore value
-- and Roblox refuses a value past 4,194,304 bytes (docs/vault/04-roblox-engine/Save-Budget.md). Each alien record
-- costs about 193 bytes, so a player who keeps every catch passes the limit around day 25 at 3 hours a day without
-- fusion (day 8 at 10 hours a day); past it the save fails and progress is lost. A profile therefore holds at most
-- StorageCap alien records: 1,500 of them are about 290 KB, well under the limit with room for everything else.
-- The rule (Economy.GrantAlien, the one door every alien enters through): at the cap a new alien adds no record, yet
-- everything else a catch does still happens (the codex entry and its first-catch Scrap, the quests, the weekly board,
-- analytics), and the alien turns into ReleaseScrap[tier] Scrap, reported to the client as GrantResult.overflowScrap.
-- The player makes room by releasing aliens (Economy.Release, ReleaseAliens and ReleaseAllOfTier remotes), which pays
-- the same Scrap, or by fusing. An alien that is working, following, ridden or on display is never released.
-- Every number here, never in code.
local ReleaseScrap: { [string]: number } = {
	Common = 5,
	Uncommon = 12,
	Rare = 40,
	Epic = 150,
	Legendary = 500,
	Cosmic = 1500,
	Secret = 1500,
}

local BulkReleaseTiers: { string } = { "Common", "Uncommon" }

return {
	StorageCap = 1500, -- alien records a profile may hold
	WarnFraction = 0.9, -- the Aliens count turns to the warning colour from this fraction of the cap
	ReleaseScrap = ReleaseScrap, -- Scrap for releasing one alien of a tier; also what an overflow catch turns into
	BulkReleaseTiers = BulkReleaseTiers, -- tiers "Release all unused" may sweep in one tap
	MaxReleasePerCall = 200, -- uids one ReleaseAliens call may name
	ConfirmSeconds = 3, -- the second tap on the Release button must come within this many seconds
	HoldSeconds = 0.45, -- holding an alien card this long opens its Release panel
	HoldMovePixels = 12, -- a held finger that drifts further than this is scrolling, not holding
}
