--!strict
-- Shared types for the whole game. Every data table and service imports from here.

export type Tier = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Cosmic" | "Secret"
export type Job = "Gather" | "Build" | "Spark" | "Tinker"
export type Overlay = "None" | "Shiny" | "Gold" | "Crystal" | "Rainbow" | "Spectral"
export type Biome = "Meadow" | "Forest" | "Cave" | "Snowfield" | "IceCave" | "GeyserField" | "Home"
-- Conditions a spawn or node can need. The world-specific ones are each world's special weather (Worlds.luau).
export type Condition = "Any" | "Day" | "Night" | "Rain" | "Shower" | "Quest" | "Blizzard" | "PowerSurge" | "Ashfall" | "KingTide" | "GravityFlip" | "Eclipse"
export type Traversal = "Sprint" | "Hover" | "Glide" | "Swim" | "Climb"

export type JobLevel = { job: Job, level: number }

-- The home planet on the profile: whether it is unlocked, the visits, and the house grid (data/HomeBuild): one
-- entry per placed item, keyed by its uid, at a plot cell (0-based from the plot's -X -Z corner) with a quarter-turn rotation.
export type HomeItem = { uid: string, itemId: string, cellX: number, cellZ: number, rotation: number }
-- A letter in the mailbox: who sent it (a name shown as is), its line, Social-style rewards, when it came.
export type MailItem = { uid: string, from: string, text: string, rewards: { SocialReward }, sentAt: number }
export type SocialReward = { kind: "scrap" | "lure" | "powerUp" | "spin", id: string?, amount: number }
export type Visitor = { name: string, at: number }
-- Today's waves (data/Visiting, Shared/VisitRules): `day` is the gift day the counts are for, `sent` the waves the
-- player made as a visitor, `got` the Scrap their aliens received from live waves as an owner.
export type WaveTally = { day: number, sent: number, got: number }
export type HomeState = {
	unlocked: boolean,
	visits: number,
	items: { [string]: HomeItem },
	habitatSettled: number, -- os.time() of the last habitat payout
	mail: { MailItem }, -- newest last; claimed letters are removed
	visitors: { Visitor }, -- the Visitor Book, newest last
	waves: WaveTally,
}
-- What a visitor sees of someone else's home (milestone 42e): the owner, their house grid, their aliens on display
-- (the records whose `habitat` is set, by uid; the client draws them roaming) and the worlds they launched from
-- (the hangar), ascending. The server builds it from the owner's live profile or their save read without a lock.
export type HomeView = {
	ownerId: number,
	ownerName: string,
	items: { [string]: HomeItem },
	displayed: { [string]: AlienRecord },
	launchedWorlds: { number },
}
-- What visitors left for an owner who was not in the server, kept in the HomeInbox DataStore under the owner's
-- user id until their next load drains it: the Visitor Book lines (newest last) and the day's waves (count, Scrap owed).
export type InboxWaves = { day: number, count: number, scrap: number }
export type HomeInbox = { visitors: { Visitor }, waves: InboxWaves }

export type SpeciesDef = {
	id: string,
	name: string,
	concept: string,
	tier: Tier,
	jobs: { JobLevel },
	biome: Biome,
	condition: Condition,
	world: number,
	ride: Traversal?,
	-- placeholder rendering until real meshes exist
	placeholder: { shape: "Ball" | "Block" | "Cylinder", color: string, scale: number },
	-- ReplicatedStorage.<Config.ModelFolderName> child to render instead of the placeholder when it exists;
	-- defaults to id (the client's World.Models looks it up)
	model: string?,
	voiceLine: string,
	-- data/CatchVariants row this species is caught with; nil means its world's catchVariant (Worlds.luau), else Standard
	variant: string?,
}

export type TierDef = {
	share: number, -- share of wild spawns, percent (Cosmic and Secret are 0: event or quest only)
	workSpeed: number, -- multiplier versus Common
	passive: number, -- camp-wide bonus, fraction (0.10 = +10%)
	catchChance: number, -- chance a Good hit catches, 0..1
	tickerSpeed: number, -- bar sweeps per second
	goodZone: number, -- fraction of bar width
	perfectZone: number,
	rounds: number,
	codexScrap: number, -- first-catch payout
	catchScrap: number, -- every catch pays this; a Perfect multiplies it by Config.PerfectScrapMultiplier
	color: string,
	aura: number, -- glow strength of a wild spawn of this tier (0 = none): a point light and a pulsing glow sprite (Vfx)
}

export type AlienRecord = {
	uid: string,
	species: string,
	level: number, -- 1..7 (base level plus fusion)
	overlay: Overlay,
	caughtAt: number,
	size: string, -- data/Sizes band id (Tiny .. Huge); "Normal" for records from before sizes
	workedSeconds: number, -- time at a station so far (data/Growth stages); 0 for records from before growth
	station: Job?, -- which station it is assigned to, if any
	slot: number?,
	habitat: string?, -- the home habitat item (HomeItem uid) it is on display in; never seated or following while set
}

-- A station's open slots: what the modules have unlocked (data/Modules unlocksSlots, capped by Config.StationMaxSlots)
-- plus `bonus`, the slots bought with the +1 slot pass, which sit on top of every unlock and raise the cap by as much.
export type StationState = { slots: number, assigned: { string }, bonus: number? }

export type ModuleProgress = {
	scrapPaid: number,
	keyPaid: number,
	progress: number, -- 0..1 assembly progress
	started: boolean,
	completedAt: number?,
	updatedAt: number, -- os.time() of the last progress write; both sides extrapolate from here
}

export type OutpostState = { level: number, lastCollect: number }
-- Resting in the game (data/Afk): whether the player is resting, since when (os.time) and the Scrap earned since then.
export type AfkState = { resting: boolean, since: number, earned: number }
-- A seasonal event's track on the profile (data/Seasons): counts by quest id and the quests already claimed.
export type SeasonProgress = { progress: { [string]: number }, claimed: { [string]: boolean } }
-- Playtime gifts (data/Playtime): the day (Shared/PlaytimeMath.DayOf) the seconds and claims below belong to, the seconds
-- of active play so far that day, and the gifts claimed, keyed by tostring(index). A new day starts both again.
export type PlaytimeProgress = { day: number, seconds: number, claimed: { [string]: boolean } }
export type PeriodQuests = { period: string, ids: { string }, progress: { [string]: number }, claimed: { [string]: boolean }, rerolls: number }

export type Profile = {
	version: number,
	scrap: number,
	aliens: { [string]: AlienRecord },
	stations: { [string]: StationState },
	modules: { [string]: { [string]: ModuleProgress } }, -- modules[worldId][moduleId]
	world: { current: number, unlocked: { number }, outposts: { [string]: OutpostState } },
	codex: { [string]: { count: number, bestOverlay: Overlay, firstCaughtAt: number } },
	gear: { boots: boolean, hoverboard: boolean, glider: boolean, radar: number },
	companions: { string }, -- uids of the aliens following the player (data/Companions), in slot order
	companionSlots: number, -- extra slots unlocked with Companion Tokens (the pass adds its own at read time)
	home: HomeState, -- the home planet (data/Home): unlocked by the first launch; the house grid comes in 42a's second part
	-- fieldNotes[worldId] = the current step index (1-based; past the last step means the chain is done);
	-- progress[objectiveId] = count so far for objectives of the current step
	-- daily and weekly (data/DailyQuests): the dealt quest ids for `period`, progress and claims by quest id,
	-- rerolls used this period; the Field Notes keep their own step index and objective progress
	quests: { daily: PeriodQuests, weekly: PeriodQuests, fieldNotes: { [string]: number }, progress: { [string]: number } },
	codes: { [string]: boolean }, -- promo codes already redeemed (data/Codes)
	seasons: { [string]: SeasonProgress }, -- the event tracks, by season id (data/Seasons)
	gifts: { daysPlayed: number, claimed: { [string]: boolean }, lastPlayDay: number },
	playtime: PlaytimeProgress, -- today's active play and the playtime gifts claimed (data/Playtime)
	seen: { [string]: boolean }, -- first-time moments watched (data/Cinematics SeenKeys): the arrival in each world, once per profile
	storage: { bayLevel: number }, -- Storage Bay levels bought with Scrap (data/Storage); the alien cap is StorageMath.CapFor over this, the modules finished and the pass
	spins: { free: number, banked: number, lastFree: number },
	luck: { pity: number },
	purchases: { [string]: number }, -- Robux products granted, by item id -> count (passes are read live)
	shop: { starterSpecies: string?, receipts: { [string]: number } }, -- the Starter Pack's chosen Rare; receipt ids already granted -> os.time()
	buffs: { [string]: number }, -- active power-ups: id -> seconds remaining (ticks down only while online)
	inventory: { keyMaterials: { [string]: number }, lures: { [string]: number }, powerUps: { [string]: number }, items: { [string]: number } },
	stats: { catches: number, perfects: number, playSeconds: number },
	-- player preferences (data/Settings.luau names the keys and their allowed values); the client applies them
	settings: { [string]: number },
	tutorialStep: number, -- index into data/Tutorial.luau Steps; past the last step means done
	-- social rewards (data/Social.luau): sessions counts loads; referredBy is the inviter's UserId or 0
	social: { sessions: number, groupClaimed: boolean, referredBy: number, referralClaimed: boolean, referralsRewarded: number, notifyAskedAt: number },
	tutorialCounter: number, -- catches (or other counted events) since the current step started
	lastSeen: number,
	firstSeen: number,
	lock: { jobId: string, time: number }?,
	aliensSeq: number?, -- never saved: the copy the client receives carries the sequence number its alien list starts at (AliensDelta)
}

-- Net payloads ------------------------------------------------------------

-- Settings -> the player after SetSetting (and in the profile): every key with its current value.
export type SettingsState = { [string]: number }
-- Seen -> the player (SeenChanged): the whole profile.seen table, after MarkSeen stored a key or a Studio reset cleared them.
export type SeenState = { [string]: boolean }

-- Monetization -> the player: products granted so far and the passes owned right now.
export type PurchasesState = { purchases: { [string]: number }, passes: { [string]: boolean }, starterSpecies: string? }
-- Monetization -> everyone: the shared luck a player bought (bonus added to every luck number), or nil when none runs.
export type ServerLuckState = { bonus: number, secondsLeft: number, playerName: string }?

-- WorldClock -> clients on every day/night or weather change, and from GetClock.
export type ClockState = { isNight: boolean, weather: string, secondsLeft: number, weatherSecondsLeft: number }

-- One sweep set of the capture bar. The client draws from these; the server judges from these.
export type SweepParams = {
	tickerSpeed: number, -- full left-right-left cycles per second
	goodZone: number, -- fraction of bar width
	perfectZone: number,
	zoneCenter: number, -- 0..1 along the bar
	roundsTotal: number,
	round: number, -- 1-based
	sweepsLeft: number,
	startClock: number, -- workspace:GetServerTimeNow() when this sweep's ticker leaves 0
}

export type CaptureStartResult = {
	token: string,
	species: string,
	tier: Tier,
	tickerSpeed: number,
	goodZone: number,
	perfectZone: number,
	zoneCenter: number,
	roundsTotal: number,
	round: number,
	sweepsLeft: number,
	startClock: number,
	lure: string?, -- the lure consumed for this encounter (Lures.Lures id), if any
	variant: string, -- data/CatchVariants row id the encounter runs (Standard, Reel, Chase)
	driftPhase: number, -- radians; the zone centre swings from Capture.driftCenter(elapsed, zoneCenter, ...) with this phase
	deadline: number?, -- server clock (workspace:GetServerTimeNow) after which the encounter flees; nil without a time limit
}

export type HitOutcome = "Perfect" | "Good" | "Miss"

-- "Round": a multi-round catch won this round; the next sweep set follows.
export type CaptureOutcome = "Caught" | "Fled" | "Wiggle" | "Miss" | "Round"

export type CaptureHitResult = {
	outcome: CaptureOutcome,
	hit: HitOutcome?, -- what the tap scored, present on every outcome but Fled-by-timeout
	pos: number?, -- where the server placed the ticker for that tap
	-- continued sweeps (Wiggle, Miss, Round)
	sweepsLeft: number?,
	round: number?,
	roundsTotal: number?,
	nextStartClock: number?,
	zoneCenter: number?,
	goodZone: number?,
	perfectZone: number?,
	driftPhase: number?, -- the next sweep's drift phase (a new one every sweep)
	zoneAt: number?, -- where the server placed the zone centre at the tap (the drifted value it scored against)
	-- Caught
	perfect: boolean?,
	species: string?,
	tier: Tier?,
	overlay: Overlay?,
	isNew: boolean?,
	scrapGained: number?,
	scrap: number?,
	overflowScrap: number?, -- the storage cap was full: the alien turned into this much Scrap (part of scrapGained), no record added
}

-- Peddler visit (PeddlerChanged event to all clients, GetPeddler for late joiners); nil between visits.
export type PeddlerOffer = { id: string, kind: string, scrap: number, amount: number?, tier: string? }
export type PeddlerVisit = { offers: { PeddlerOffer }, endsAt: number } -- endsAt on the server wall clock (os.time())

-- Economy -> the player (StorageChanged): the alien storage cap right now (StorageMath.CapFor over the live profile) and the
-- Storage Bay levels bought, sent on join and whenever a ship module finishes, the Bay is bought or the StorageBoost pass
-- changes. `gained` is set when a finished module raised the cap: the cap rose by that much and the client toasts it.
-- The owned count is not in it: the client counts the records it mirrors (the join profile and AliensDelta).
export type StorageState = { cap: number, bayLevel: number, gained: number? }

-- A granted alien that was not caught in the wild (an egg from the Peddler): the client shows the Reveal.
-- overflowScrap is set only when the storage cap (data/Storage) was full: no record was added, the alien turned into
-- that much Scrap instead, and scrapGained already includes it. The Reveal shows the "Storage full" ribbon for it.
export type GrantResult = { species: string, tier: Tier, overlay: Overlay, size: string, isNew: boolean, scrapGained: number, scrap: number, overflowScrap: number? }

-- Gifts -> client (GiftsChanged): Welcome Week progress and the spin balance.
export type GiftState = { daysPlayed: number, claimed: { [string]: boolean }, freeSpins: number, bankedSpins: number }

-- Playtime -> client (PlaytimeChanged, GetPlaytime): whether the gifts are on, the seconds of active play today and the
-- gifts claimed (by tostring(index)). The client derives each card (unlocked, time left, ready count) from the data
-- table and Shared/PlaytimeMath, so nothing else travels.
export type PlaytimeState = { enabled: boolean, seconds: number, claimed: { [string]: boolean } }

-- Spin() answer: the segment the server rolled; the client animates the wheel to it.
export type SpinResult = { segmentId: string, index: number }

-- Events -> clients (ShowerChanged, FireAllClients): the Meteor Shower clock.
export type ShowerState = { active: boolean, secondsLeft: number, nextInSeconds: number }
-- Sightings -> every client (SightingChanged, GetSighting): the Warden crossing the map, or when the next one starts.
export type SightingState = { active: boolean, species: string, secondsLeft: number, nextInSeconds: number }

-- The Catch Rush clock (CatchRushChanged event to all clients, GetCatchRush for late joiners): the round's
-- state plus the leaders so far (top TopCount by catches, then the asking player's own row when outside it).
export type CatchRushRow = { userId: number, name: string, catches: number }
export type CatchRushState = { active: boolean, secondsLeft: number, nextInSeconds: number, rows: { CatchRushRow } }

-- A player's companions as every client draws them (CompanionsChanged to all clients, GetAllCompanions for a
-- late joiner): the owner and one row per following alien.
export type CompanionRow = { uid: string, species: string, size: string, overlay: Overlay, level: number, workedSeconds: number }
export type CompanionsSnapshot = { userId: number, rows: { CompanionRow }, riding: string? } -- riding: the uid of the row the owner rides, nil on foot

-- One fusion (FuseSpecies remote, data/Fusion): the kept copy's new level and what was consumed.
export type FuseResult = { species: string, uid: string, level: number, consumed: number }

-- One player's result at the end of a round (CatchRushResult event to that player).
export type CatchRushResult = { rank: number, catches: number, rewards: { any } } -- rank 0: no catches, nothing paid

-- Quests -> client (QuestsChanged): the Field Notes step per world and the objective counts.
export type QuestState = { fieldNotes: { [string]: number }, progress: { [string]: number } }

-- Server-wide banner (Announcement event, FireAllClients) when someone catches a rare enough alien.
export type Announcement = {
	kind: "catch" | "rush" | "notice", -- a rare enough catch, the Catch Rush winner, or a line from the team (text; the rest unused)
	playerName: string,
	species: string,
	tier: Tier,
	overlay: Overlay,
	catches: number?, -- rush: the winner's count
	text: string?, -- notice: the line itself, already cut to Admin.AnnounceMaxChars
}

-- Camp -------------------------------------------------------------------

-- Economy -> client whenever an assignment or a work speed changes (RateChanged). assemblySpeed is by job.
-- `multiplier` is the station income factor the server applies right now (Buffs.StationMultiplier: Double Shift, the
-- Friend Boost, resting); the HUD's Scrap per minute is ratePerSecond times it. nil reads as 1 (a profile-derived state).
export type CampState = { ratePerSecond: number, assemblySpeed: { [string]: number }, multiplier: number? }

-- Economy -> client, the alien list (AlienSync on the server, Shared/AlienDelta on both sides). The records and seats reach the
-- client once as a snapshot (the join profile, whose aliensSeq is the number below, or the GetAliens pull) and after that only
-- as AliensDelta events, one per change the server pushes (a catch, a fusion, a release, a seat change, a growth stage).
-- `seq` counts the deltas the server has made for this player: the client applies seq = have + 1, ignores anything older and
-- pulls the snapshot again when one is missing. Every list is nil when empty. `added` and `changed` carry whole records (the
-- client replaces its copy), `removed` the uids, `stations` the whole StationState of each job whose seats or slots changed.
export type AliensDelta = {
	seq: number,
	added: { AlienRecord }?,
	changed: { AlienRecord }?,
	removed: { string }?,
	stations: { [string]: StationState }?,
}
export type AliensSnapshot = { seq: number, aliens: { [string]: AlienRecord }, stations: { [string]: StationState } }

-- Economy -> client once on join when the player was away long enough (OfflineSummary).
export type OfflineSummary = {
	awaySeconds: number,
	scrap: number,
	completedModules: { string },
	grown: { { uid: string, stage: string } }?, -- aliens that reached a new growth stage while away (data/Growth), in seating order
}

return {}
