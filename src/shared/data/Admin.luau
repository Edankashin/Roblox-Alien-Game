--!strict
-- The developer panel (docs/GAME_DESIGN.md section 12, "Tooling for two people"): in-game commands the team's
-- own accounts can type in any server (DeveloperUserIds; a user id is public, not a secret) that reach every
-- server at once through MessagingService: a gifted luck window, a Meteor Shower now, a weather state, a line
-- announced to everyone. Each server applies what arrives; a server that cannot publish (Studio without API
-- access) applies the command to itself so it can be tested. Nothing here is sold or shown to players except
-- its effects. Every number here, never in code.

return {
	DeveloperUserIds = { 1492992374 } :: { number }, -- the team's Roblox user ids (Ethan); empty means the panel is off everywhere
	Topic = "AlienAdmin", -- the MessagingService topic every server subscribes to
	LuckBonusDefault = 2.0, -- /admin luck [bonus] [minutes]: added to everyone's luck, like a bought Server Luck
	LuckMinutesDefault = 10,
	LuckBonusMax = 4.0,
	LuckMinutesMax = 60,
	AnnounceMaxChars = 80, -- /admin say <text>: longer lines are cut
	CommandsPerMinute = 6, -- per developer, so a stuck key cannot flood every server
	ReplayGuardSeconds = 30, -- a message older than this (publish to receive) is ignored
	PublishTimeoutSeconds = 5, -- a publish that has not returned by then (an unpublished place never answers) is applied here instead
	LuckName = "ADMIN_LUCK_NAME", -- strings key shown as who gifted the luck
}
