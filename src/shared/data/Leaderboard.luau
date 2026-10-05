--!strict
-- The weekly leaderboard (docs/vault/01-game-design/Growth-Playbook.md section 4): "Catches this week",
-- one OrderedDataStore key per period, reset on the Friday cadence so a newcomer can reach the top by the
-- weekend. The server tallies catches in memory, flushes them to the store at most once a minute per
-- player (plus on leave), and one fetch per server per minute feeds every client. Every number here.
return {
	StoreName = "Catches", -- OrderedDataStore name; the key is "<StoreName>_<periodId>"
	ResetWeekday = 6, -- os.date("!*t").wday: 1 Sunday ... 6 Friday, 7 Saturday
	ResetHourUtc = 16, -- the period rolls over at this UTC hour on ResetWeekday
	TopCount = 100, -- rows fetched and shown
	FetchSeconds = 60, -- one GetSortedAsync per server per this many seconds
	FlushSeconds = 60, -- a player's pending catches reach the store at most this often
	CatchCapPerMinute = 30, -- catches counted per player per minute (a bug or exploit cannot top the board)
	NameBatch = 100, -- display names looked up per UserService call
	CapWindowSeconds = 60, -- the catch cap counts catches in this sliding window
	NameRetrySeconds = 300, -- a name lookup that failed is not repeated for this long
	NameCacheMax = 1000, -- the display-name cache is emptied past this many names
	CloseWaitSeconds = 25, -- BindToClose waits at most this long for the final flush
	RetryWaitSeconds = 2, -- the one retry after a failed store call waits this long
}
