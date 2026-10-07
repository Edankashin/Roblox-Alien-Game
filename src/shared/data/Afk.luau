--!strict
-- Resting (AFK) in the game: a player who neither moves nor uses the game for a while is resting. Their stations keep
-- paying at IncomeScale of the usual rate for as long as they stay in the game, so leaving the game on overnight is
-- worth it, while playing is worth about twice as much and earns catches, materials and progress on top. Being away
-- (game closed) pays the same half rate but stops after Config.OfflineCapSeconds; resting never runs out. Roblox
-- disconnects a player who sends no input for 20 minutes, so before that the client asks the server to rejoin it to the
-- same server, which resets Roblox's timer and keeps the rest going. Every number here.

return {
	IdleAfterSeconds = 120, -- no movement and no gameplay action for this long: the player is resting
	MoveStuds = 3, -- the character must move at least this far between two checks to count as active
	CheckSeconds = 5, -- how often the server checks every player
	ActivityPingSeconds = 20, -- use the server cannot see (menus, scrolling): the client says so at most this often
	IncomeScale = 0.5, -- station income while resting (the offline rate, without the offline cap)
	RejoinAfterIdleSeconds = 17 * 60, -- the client asks to rejoin after this long without input (Roblox's cutoff is 20 minutes)
	OverlayDimTransparency = 0.35, -- the resting screen's dim over the world (0 is black)
}
