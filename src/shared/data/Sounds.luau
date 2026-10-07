--!strict
-- Sound ids for every UI, capture, event and ambience cue (the launch list in PRE_PRODUCTION 3.4). All
-- placeholders (rbxassetid://0) until the audio pass; Builder.playSound and the Ambience loops skip an
-- id of 0 so nothing errors while they are empty. Volumes are 0..1 per SoundGroup.
-- Ownership (Codex C21): this file owns the one-shots and the stingers (Reveal.<tier>, Launch); the music director
-- (World/MusicDirector, rows in data/Music.luau) owns the beds and layers. Reveal.<tier> and Launch play through
-- MusicDirector.Stinger so the bed ducks for the stinger's length.
return {
	Volume = { UI = 0.6, Ambience = 0.35 },
	Click = "rbxassetid://0",
	ToastDing = "rbxassetid://0", -- every toast
	Banner = "rbxassetid://0", -- server-wide announcement banners
	PartSnap = "rbxassetid://0", -- a key part goes into a module (the bass hit)
	ModuleComplete = "rbxassetid://0", -- the fanfare when a module finishes
	ShowerHorn = "rbxassetid://0", -- a Meteor Shower begins
	PeddlerLanding = "rbxassetid://0",
	GiftClaim = "rbxassetid://0",
	WheelTick = "rbxassetid://0", -- the wheel passes a wedge
	WheelStop = "rbxassetid://0",
	HornCall = "rbxassetid://0", -- the Warden's Horn is sounded
	WardenAppear = "rbxassetid://0",
	Mount = "rbxassetid://0", -- the player hops onto a mount
	Dismount = "rbxassetid://0",
	Heartbeat = "rbxassetid://0", -- Radar Mk2: a secret is in range; the beat quickens as the player nears it
	Launch = "rbxassetid://0", -- reserved for the launch sequence (World 2)
	-- looping ambiences, crossfaded by the client as the conditions change
	Ambience = {
		Day = "rbxassetid://0",
		Night = "rbxassetid://0",
		Rain = "rbxassetid://0",
		Shower = "rbxassetid://0",
	} :: { [string]: string },
	CatchHit = "rbxassetid://0", -- the ticker stops in the Good zone
	Perfect = "rbxassetid://0", -- the ticker stops in the Perfect zone
	Miss = "rbxassetid://0",
	Wiggle = "rbxassetid://0", -- a Good hit that failed the catch roll
	Fled = "rbxassetid://0",
	ScrapTick = "rbxassetid://0", -- the Scrap counter rolls
	-- Moments C20 found with no cue at all (docs/vault/01-game-design/Moments.md). Silent until the sound pass; each
	-- consumer wires in as its id lands (LegendaryRumble already plays with the Legendary opening).
	LegendaryRumble = "rbxassetid://0", -- the low rumble under the screen shake before a Legendary or higher catch bar opens
	BarOpen = "rbxassetid://0", -- the catch bar opens
	RareNearby = "rbxassetid://0", -- a rare alien comes into range
	RushStart = "rbxassetid://0", -- a Catch Rush round begins (it has only the banner's cue today)
	Arrival = "rbxassetid://0", -- the player lands on a world (no distinct arrival cue today)
	RestStart = "rbxassetid://0", -- the crew starts resting
	Reveal = {
		Common = "rbxassetid://0",
		Uncommon = "rbxassetid://0",
		Rare = "rbxassetid://0",
		Epic = "rbxassetid://0",
		Legendary = "rbxassetid://0",
		Cosmic = "rbxassetid://0",
		Secret = "rbxassetid://0",
	} :: { [string]: string },
}
