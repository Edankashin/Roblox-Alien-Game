--!strict
-- Social rewards and rejoin nudges (docs/vault/01-game-design/Growth-Playbook.md sections 3 and 5):
-- a group-join gift checked on the server (Player:IsInGroupAsync), rewards for the official referral
-- system (Player:GetJoinData().ReferredByPlayerId), and the opt-in card for Experience Notifications.
-- None of it gates progress; a like or favorite is never rewarded (no API can check one). Every number here.

export type Reward = { kind: "scrap" | "lure" | "powerUp" | "spin", id: string?, amount: number }

return {
	GroupId = 0, -- the team's Roblox group id; 0 hides the group gift everywhere (set it when the group exists)
	GroupReward = { { kind = "scrap", amount = 500 }, { kind = "lure", id = "Lure1", amount = 3 }, { kind = "spin", amount = 2 } } :: { Reward },
	-- The referral system: the invitee is paid once on their first join through a referral link, the inviter
	-- per invitee up to a lifetime cap (abuse guard), banked for them when they are offline.
	ReferralInvitee = { { kind = "scrap", amount = 300 }, { kind = "lure", id = "Lure1", amount = 2 } } :: { Reward },
	ReferralInviter = { { kind = "scrap", amount = 500 }, { kind = "spin", amount = 2 } } :: { Reward },
	ReferralMaxRewarded = 50, -- inviter rewards per profile, lifetime
	-- The notifications ask (decision 20): never in the first session, never in the first minutes, once per
	-- cooldown, and only while the market flag is on.
	NotificationsEnabled = true,
	NotifyAskMinSession = 2, -- the card can show from this session count on
	NotifyAskAfterSeconds = 120, -- seconds into the session before the card
	NotifyAskCooldownSeconds = 30 * 24 * 3600, -- between cards (Roblox's own prompt has a 30-day cooldown too)
}
