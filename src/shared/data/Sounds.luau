--!strict
-- Sound ids for every UI, capture, event and ambience cue (the launch list in PRE_PRODUCTION 3.4). All
-- placeholders (rbxassetid://0) until the audio pass; Builder.playSound and the Ambience loops skip an
-- id of 0 so nothing errors while they are empty. Volumes are 0..1 per SoundGroup.
-- Ownership (Codex C21): this file owns the one-shots and the stingers (Reveal.<tier>, Launch); the music director
-- (World/MusicDirector, rows in data/Music.luau) owns the beds and layers. Reveal.<tier> and Launch play through
-- MusicDirector.Stinger so the bed ducks for the stinger's length.
return {
	Volume = { UI = 0.6, Ambience = 0.35 },
	Click = "rbxassetid://15675032796",
	ToastDing = "rbxassetid://17208361335", -- every toast
	Banner = "rbxassetid://1839901345", -- server-wide announcement banners
	PartSnap = "rbxassetid://16480551554", -- a key part goes into a module (the bass hit)
	ModuleComplete = "rbxassetid://1844584698", -- the fanfare when a module finishes
	ShowerHorn = "rbxassetid://1839901334", -- a Meteor Shower begins
	PeddlerLanding = "rbxassetid://12222095",
	GiftClaim = "rbxassetid://1841114489",
	WheelTick = "rbxassetid://15675059323", -- the wheel passes a wedge
	CrackTick = "rbxassetid://15675059323", -- a tap on the Reveal's egg (the wheel's tick until the sound pass picks a crack)
	WheelStop = "rbxassetid://1842279701",
	HornCall = "rbxassetid://1846987124", -- the Warden's Horn is sounded
	WardenAppear = "rbxassetid://0",
	Mount = "rbxassetid://0", -- the player hops onto a mount
	Dismount = "rbxassetid://1841354575",
	Launch = "rbxassetid://12222065", -- reserved for the launch sequence (World 2)
	-- looping ambiences, crossfaded by the client as the conditions change
	Ambience = {
		Day = "rbxassetid://1842360915",
		Night = "rbxassetid://1840267237",
		Rain = "rbxassetid://1516791621",
		Shower = "rbxassetid://1846553484",
	} :: { [string]: string },
	CatchHit = "rbxassetid://15675055424", -- the ticker stops in the Good zone
	Perfect = "rbxassetid://9048764474", -- the ticker stops in the Perfect zone
	Miss = "rbxassetid://15675075163",
	Wiggle = "rbxassetid://0", -- a Good hit that failed the catch roll
	Fled = "rbxassetid://15675028888",
	ScrapTick = "rbxassetid://127645268874265", -- the Scrap counter rolls
	-- Moments C20 found with no cue at all (docs/vault/01-game-design/Moments.md). Silent until the sound pass; each
	-- consumer wires in as its id lands (LegendaryRumble already plays with the Legendary opening).
	LegendaryRumble = "rbxassetid://1842481856", -- the low rumble under the screen shake before a Legendary or higher catch bar opens
	BarOpen = "rbxassetid://15675012262", -- the catch bar opens
	RushStart = "rbxassetid://15675062723", -- a Catch Rush round begins (it has only the banner's cue today)
	Arrival = "rbxassetid://1838007773", -- the player lands on a world (no distinct arrival cue today)
	RestStart = "rbxassetid://15675081158", -- the crew starts resting
	-- The spectacle ladder (data/Spectacle, World.Spectacle): hooks only, silent until the sound pass. TierAmbient is a soft loop
	-- (ambient notes) at a wild alien of a tier with a presence, nearest few only; Arrive the one-shot as a tier's arrival lands;
	-- CatchSpiral as a caught alien spirals into the device; EscapePuff as one hops away; BlinkOut as a Secret blinks out.
	TierAmbient = {
		Rare = "rbxassetid://0",
		Epic = "rbxassetid://0",
		Legendary = "rbxassetid://0",
		Cosmic = "rbxassetid://0",
		Secret = "rbxassetid://0",
	} :: { [string]: string },
	Arrive = {
		Rare = "rbxassetid://0",
		Epic = "rbxassetid://0",
		Legendary = "rbxassetid://0",
		Cosmic = "rbxassetid://0",
		Secret = "rbxassetid://0",
	} :: { [string]: string },
	CatchSpiral = "rbxassetid://0",
	EscapePuff = "rbxassetid://0",
	BlinkOut = "rbxassetid://0",
	Reveal = {
		Common = "rbxassetid://15675043410",
		Uncommon = "rbxassetid://9048764475",
		Rare = "rbxassetid://9039420865",
		Epic = "rbxassetid://1844584807",
		Legendary = "rbxassetid://1846284687",
		Cosmic = "rbxassetid://1841820743",
		Secret = "rbxassetid://1843092991",
	} :: { [string]: string },
}
