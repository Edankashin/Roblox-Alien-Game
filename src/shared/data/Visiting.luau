--!strict
-- Visiting the home planet (docs/GAME_DESIGN.md section 10, milestone 42e): a friend's home is a reserved server
-- of the home place keyed by the owner's user id, the owner's save read without a lock when they are away, a lock
-- level in Settings (the HomeLock row: only me, friends, anyone), and a Wave at a displayed alien that pays both
-- players a little Scrap through the gifts' reward path. Every number here; the rules in Shared/VisitRules.

return {
	MemoryStoreMap = "HomeServers", -- MemoryStore sorted map: owner user id -> the access code of their home's reserved server
	CodeTtlSeconds = 30 * 24 * 3600, -- an entry lives this long (MemoryStore allows 45 days); after it a fresh server is reserved
	InboxStoreName = "HomeInbox", -- DataStore: what visitors leave for an owner who is not in the server (the Visitor Book, waves)
	PeekCacheSeconds = 60, -- an owner's save, read once without a lock, answers a server's lookups this long
	FriendListMax = 50, -- friends listed on the Visit screen, from Players:GetFriendsAsync in page order
	WavesPerDay = 10, -- waves one visitor can make in a day, over every home (the day is Config.GiftDaySeconds long)
	WaveScrapVisitor = 5, -- Scrap a wave pays the visitor
	WaveScrapOwner = 5, -- Scrap a wave pays the owner (at once when they are in the server, else in one letter at their next load)
	WaveOwnerScrapCapPerDay = 100, -- the most an owner's aliens earn from waves in a day (counted apart for live waves and the inbox)
	WaveInteractDistance = 10, -- studs from a displayed alien within which the action button reads "Wave"
	TeleportDataKey = "homeOwnerId", -- the teleport data field naming the owner, set by the server that sends a player to a reserved home server
	-- The HomeLock preference (data/Settings row HomeLock) stores one of these
	LockOwnerOnly = 0,
	LockFriends = 1,
	LockAnyone = 2,
}
