--!strict
-- The mailbox on the home planet (docs/GAME_DESIGN.md section 10): gifts from friends and events wait in the
-- player's mail until they are claimed at the mailbox; the Visitor Book under it lists who came by. Mail arrives
-- from the developer panel (/admin mail, to every player online on every server) and, later, from visitors and
-- events. A letter carries Social-style rewards paid through Gifts.GrantRewards on claim. Every number here.

return {
	MaxLetters = 20, -- the newest letters stay; an older one is dropped unread when a 21st arrives
	MaxVisitors = 10, -- names kept in the Visitor Book
	TextMaxChars = 80, -- a letter's line is cut to this
	DefaultScrap = 100, -- /admin mail with no amount sends this much Scrap
	MaxScrap = 5000, -- and never more than this per letter
	ClaimsPerSecond = 2, -- the ClaimMail remote's rate limit
}
