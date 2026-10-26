--!strict
-- Shared types for the whole game. Every data table and service imports from here.

export type Tier = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Cosmic" | "Secret"
export type Job = "Gather" | "Build" | "Spark" | "Tinker"
export type Overlay = "None" | "Shiny" | "Gold" | "Crystal" | "Rainbow" | "Spectral" | "LaunchGold"
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
-- The aliens a visitor waved at on one gift day, by owner id then alien uid (Shared/VisitRules, kept by the Visiting service in
-- memory): a wave is once per alien per owner per day, however many times the visitor leaves and comes back.
export type WavedBook = { day: number, owners: { [number]: { [string]: boolean } } }
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

-- One slot's surface look in a model's materials.json (carried into data/ModelAssets.Surfaces by tools/model_assets.py):
-- a Roblox Material name (ModelInstall.SurfaceMaterials), a key of data/Textures, and glossy (SmoothPlastic with a
-- Reflectance from Config.ModelGlossReflectance). Every field is optional; a slot without a row looks as it always did.
export type SurfaceSpec = { material: string?, texture: string?, glossy: boolean? }
-- One shared tileable texture set (data/Textures): the Image ids of its colour, normal and roughness maps (0 until
-- uploaded) and how many times the map repeats across a mesh primitive's 0..1 UV square (tools/blender/species_bodies.py
-- scales the slot's UVs by it; SurfaceAppearance itself has no tiling property).
export type TextureRow = { colorMap: number, normalMap: number, roughnessMap: number, tiling: { number } }
-- How an imported prop collides (data/Props, Shared/ModelInstall.CollisionPlan, applied by Shared/Props.Place). Box: decor the
-- player never walks on (a box fits the part cheaply). Hull: a prop the player stands on or bumps close to (a convex hull follows
-- the silhouette). Precise: a prop with an opening to walk through, an arch or a ring, which a box or a hull would plug. None: purely
-- visual, CanCollide off whatever the caller asks.
export type PropCollision = "Box" | "Hull" | "Precise" | "None"
-- `slots` overrides `collision` for a block-cell prop's MeshParts by colour slot name (Body, BodyDark, Accessory, Trim, Glow):
-- a giant glowcap's stem boxes while its cap, rim and moss never collide.
export type PropSlotCollisions = {
	Body: PropCollision?,
	BodyDark: PropCollision?,
	Accessory: PropCollision?,
	Trim: PropCollision?,
	Glow: PropCollision?,
}
-- `origin` places a prop by another point than its bottom centre: that point from the mesh's bottom centre, studs at scale 1 in the
-- spec note's axes (its frontmatter `origin`): a sign arm by its post's foot, the camp flag by its pole.
export type PropRow = { collision: PropCollision, slots: PropSlotCollisions?, origin: { number }? }

-- The generated worlds in block cells (tools/blocky/world_gen.py writes data/WorldGen1, WorldGen2 and WorldKit; Shared/WorldGrid reads
-- them; Services/Meadow builds them). A ground kind: its tile keys (data/BlockTiles ids), the fallback colours and Roblox Material
-- while a tile id is 0, and whether a wild alien may spawn on it.
-- tint false: the night's ground tint (data/Lighting groundTint) leaves it alone (the Starhollow's glowing path and water).
export type GroundKind = { top: string, side: string, body: string, color: string, sideColor: string, bodyColor: string, material: string, spawn: boolean, tint: boolean }
-- neon: the water glows (the Starhollow's moon pool and waterfall).
export type WaterLook = { transparency: number, reflectance: number, neon: boolean }
-- A named sight (B48): `name` is a strings key, `area` the strings key of the area it is in.
export type WorldSight = { id: string, name: string, area: string, x: number, y: number, z: number }
-- One box of a scatter prop's block-built placeholder (studs at scale 1, feet at y = 0); roll tilts it about its local Z, degrees.
export type RecipeBox = { size: { number }, at: { number }, color: string, material: string, collide: boolean?, neon: boolean?, roll: number? }
export type RecipeLight = { color: string, range: number, brightness: number, at: { number } }
-- hang: the prop hangs from its point (icicles under a cliff edge) instead of standing on it.
export type PropRecipe = { boxes: { RecipeBox }, light: RecipeLight?, hang: boolean? }
export type WorldBuild = { edgeWallHeight: number, edgeWallThickness: number, baseThickness: number, fallThickness: number, fallTransparency: number, fallColor: string, decorShadowBelow: number }
export type WorldBudget = { groundParts: number, textures: number, scatter: number, placeholderParts: number, lights: number, fxEmitters: number }
-- A beautiful place: rare-alien luck (a multiplier on the tier odds of a spawn inside its radius) and a name.
export type WorldSpot = { id: string, x: number, y: number, z: number, radius: number, luck: number }
export type WorldFxSpot = { kind: string, x: number, y: number, z: number, size: number }
-- The generated rows are flat number arrays (strides in data/WorldKit's header and in Shared/WorldGrid).
export type WorldGen = {
	World: number,
	Cell: number,
	Count: number,
	Origin: number,
	Base: number,
	Chunk: number,
	Kinds: { string },
	Props: { string },
	Caps: { number },
	Bodies: { number },
	Water: { number },
	Falls: { number },
	Solids: { number },
	NoSpawn: { number },
	Place: { number },
	Spots: { WorldSpot },
	Sights: { WorldSight },
	Fx: { WorldFxSpot },
	Stats: { [string]: number },
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

-- Per-species effects (data/Effects, drawn by the client's World.SpeciesFx; the server never reads them).
-- Every length in a layer is a fraction of the alien's own height (its bounds), so one row fits a Tiny and a Huge of the same
-- species and the data names no stud; the only studs are the idle amplitudes below, for a 1.0-scale alien.
export type EffectKind = "Emitter" | "Beam" | "Light" | "Trail" | "Orbit" | "Burst" | "Sparkle" | "RingPulse" | "Pillar" | "Aura"
-- Burst: `count` particles at once, every `every` seconds and/or on the flourish. Sparkle: a twinkle that grows and shrinks at
-- one point every `every` seconds, like a blink. RingPulse: a flat ring that grows out along the ground, on a timer and/or the
-- flourish. Pillar: a column of light from `at` straight up `reach` heights, shown `lifetime` seconds on the flourish and in
-- the spawn moment. Aura: a soft shell of large glow sprites held on the body.
export type EmitDirection = "Up" | "Front" | "Back" | "Down"
export type EffectLayer = {
	kind: EffectKind,
	color: string, -- hex
	at: string, -- a region of data/Effects.Attach, or a signature piece of data/Effects.Pieces, the layer hangs on (a Beam or Trail starts here)
	-- Emitter, and the motes of an Orbit
	rate: number?, -- particles per second (per mote for an Orbit); capped by Effects.Caps
	size: number?, -- particle size, in heights
	lifetime: number?, -- seconds (Emitter, Orbit mote, Trail)
	speed: number?, -- heights per second
	spread: number?, -- degrees
	sprite: string?, -- a key of Icons.Particles; nil keeps the default soft sprite
	dir: EmitDirection?, -- nil is Up
	rise: number?, -- heights per second squared, positive up (embers) or negative (petals falling)
	glow: number?, -- LightEmission 0..1; nil is Effects.Look.DefaultGlow
	flat: boolean?, -- lies flat on the ground and grows (the Legendary ring)
	spin: number?, -- degrees a second each particle turns (a rune ring that turns, a twinkle that spins); nil is none
	-- Burst, Sparkle and RingPulse (`count` is also an Orbit's motes)
	every: number?, -- seconds between two firings on the alien's own clock; nil fires on the flourish only
	flourish: boolean?, -- also fires on the flourish (SpeciesFx.Flourish, or the tier's own flourish timer)
	-- Pillar
	reach: number?, -- heights the column stands up from `at`
	-- Beam (lightning between `at` and `to`) and Trail (a ribbon between them)
	to: string?,
	width: number?, -- Beam: heights across; Trail: the ribbon's width scale (1 is the full span of its two points)
	flicker: number?, -- Beam: seconds between strikes
	segments: number?, -- Beam: the bolt's bends
	-- Light
	brightness: number?,
	range: number?, -- heights
	pulse: number?, -- seconds for one swell of the glow; nil holds it steady
	-- Orbit (and Burst, Sparkle, RingPulse)
	count: number?, -- motes; for a Burst, Sparkle or RingPulse the particles one firing throws
	radius: number?, -- heights
	period: number?, -- seconds for one turn
}
export type MotionKind = "Still" | "Bob" | "Hover" | "Flap" | "Spin" | "Breathe"
-- Still: none. Bob: hops 0 to amplitude studs. Hover: floats amplitude studs up and sways. Breathe: rocks amplitude degrees
-- about the feet with a small lift. Spin: turns amplitude degrees a period (a multiple of 360, so the loop is seamless).
-- Flap: swings the named `parts` amplitude degrees; a model without them bobs instead.
export type IdleMotion = { kind: MotionKind, amplitude: number, period: number, parts: { string }? }
export type SpeciesFx = {
	element: string, -- what the effect is made of ("Lightning", "Frost"); a design label, not shown
	layers: { EffectLayer }, -- strongest first: a tier draws the first layersAllowed of them
	idle: IdleMotion,
	sound: string?, -- a key of data/Sounds: a one-shot the alien plays at its position on its signature beat, at most once per Effects.Look.SoundEverySeconds (World/SpeciesFx)
	accent: string?, -- hex: the colour the tier's extras wear (ring, orbit, trail, aura, pillar, spawn moment); nil is the first layer's
	flourishEvery: number?, -- seconds between flourishes on the alien's own timer (tiers with `flourish`); nil is Effects.Look.FlourishEvery
	signature: string?, -- Rare and up: the attach point of its signature piece (a key of Effects.Pieces, or of Effects.Attach for a static one); its first layer hangs there
}
export type TierFxRule = {
	layersAllowed: number, -- how many of the species' layers it draws, strongest first (a layer of a kind it may not draw is skipped)
	kinds: { [string]: boolean }, -- the EffectKinds it may draw: the body up to Epic, the ground from Legendary, the sky from Cosmic
	rateScale: number, -- on every emitter's rate
	sizeScale: number, -- on particle, beam and light sizes
	lightScale: number, -- on light brightness
	burstMax: number, -- the most particles one Burst, Sparkle or RingPulse firing may throw
	trail: boolean, -- the tier adds a ribbon trail if the species has none
	orbit: boolean, -- the tier adds a ring of orbiting motes if the species has none
	groundRing: boolean, -- a ring pulses out along the ground if the species has no timed RingPulse of its own
	aura: boolean, -- the tier adds a soft aura shell if the species has none
	pillar: boolean, -- the tier adds a sky column on the flourish if the species has none
	flourish: boolean, -- the alien runs its own flourish timer (SpeciesFx.Flourish fires it from outside too)
	spawnMoment: boolean, -- a wild arrival plays Effects.SpawnMoment once, seen from Effects.Caps.MomentDistance
	dark: boolean, -- the dark variant: colours sink toward Effects.Dark.Color
}
export type AttachPoint = { x: number, y: number, z: number } -- x and z from the bounds' centre, y from the feet, each a fraction of that side
-- A signature piece (data/Effects.Pieces): an attach point on a named moving part of the block-cell model (the Blender object's rig
-- name, as data/Rigs names it), so a layer there follows the part as the rig moves it. `spot` is the point in the part's own box,
-- each a fraction of that side from its centre (-0.5 to 0.5; the face toward -z at rest). `region` is the body region it falls
-- back to on a model without that part (an old blockout).
export type FxPiece = { part: string, spot: { number }, region: string }
-- Where a layer's point resolves on one model (EffectsMath.Place): on the piece's part at the spot, or on a body region.
export type FxPlace = { part: string?, region: string, x: number, y: number, z: number }

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
-- Both carry the visit first and then `nextAt` (a number): the server wall clock (os.time()) at which the next visit
-- lands, so the "What's on" card can count to it between visits; 0 where no visit ever comes (the home planet).
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
-- oddsPercent is set by the egg grants only (Peddler, Welcome Week and playtime eggs): the percent chance this species had among
-- the species the egg could hatch (Shared/EggMath.Percent over the pool the server drew from). The Reveal prints it as "1 in N";
-- a grant without it (a fixed reward, the Starter Pack) shows no chance line.
export type GrantResult = { species: string, tier: Tier, overlay: Overlay, size: string, isNew: boolean, scrapGained: number, scrap: number, overflowScrap: number?, oddsPercent: number? }

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

-- B46 rigs (data/Rigs, generated by tools/blocky/rigs.py; drawn by World.RigAnimator; the math in Shared/RigMath) -------------------
-- Kept together at the end of the file to ease merges. Every vector is a { x, y, z } list in studs in the model's own space at the size
-- the species was built (x the alien's right, y up, z back; it faces -z), measured from the bottom centre of its bounds.
export type RigAxis = "x" | "y" | "z"
export type RigClipKind = "bob" | "sway" | "flap" | "spin" | "wag" | "squash" | "pulse" | "orbit"
export type RigMoveKind = "hop" | "turn" | "flare" | "swish" | "pop" | "squash"
-- A looping clip: amp is studs (bob, orbit), degrees (sway, flap, wag; spin: degrees a period) or a share of the size (squash, pulse).
export type RigClip = { kind: RigClipKind, amp: number, period: number, phase: number, axis: RigAxis }
-- One move of the flourish: it runs from `at` for `length` seconds inside the flourish; `part` is a moving part's name or "root".
export type RigMove = { part: string, kind: RigMoveKind, amp: number, axis: RigAxis, at: number, length: number }
export type RigFlourish = { every: number, length: number, moves: { RigMove } }
-- A moving part: its name in the model (the Blender object name), the point it turns about, its clips.
-- `rest` (degrees about x, y, z, absent when 0) is the turn of the rest pose this object's mesh already has baked in (B54: a tail cocked,
-- a leg lifted): the clips play round it, nothing re-applies it at runtime; it is the record the notes and the checks read.
export type RigPart = { name: string, pivot: { number }, rest: { number }?, clips: { RigClip } }
-- The face plate's flipbook: one image (0 until uploaded) of `frames` frames, `columns` a row, frame indices 0-based.
export type RigFace = {
	part: string,
	image: number,
	frameWidth: number,
	frameHeight: number,
	columns: number,
	frames: number,
	open: number,
	half: number,
	closed: number,
	glint: { number },
	cycle: { number },
	blinkEvery: number,
	blinkLength: number,
	glintEvery: number,
	glintLength: number,
	cycleFps: number,
}
export type RigRow = {
	height: number, -- studs as built: the clone's measured height over this is its scale
	parts: { RigPart },
	root: { RigClip }, -- clips of the whole body about its feet
	face: RigFace?,
	flourish: RigFlourish?,
}
-- The pose RigMath accumulates for one part: an offset (studs), a turn (radians about x, y, z) and a scale. Reused, never allocated per frame.
export type RigPose = { px: number, py: number, pz: number, rx: number, ry: number, rz: number, sx: number, sy: number, sz: number }
export type RigBudget = {
	MaxAnimated: number, -- aliens animated at once on a computer (the nearest on screen)
	PhoneMaxAnimated: number, -- and on a phone (a touch screen)
	Distance: number, -- studs from the camera past which an alien holds its rest pose
	RecheckSeconds: number, -- how often the nearest are ranked again
	FallbackHalf: number, -- with no uploaded flipbook, the face plate's height share on the blink's half frame
	FallbackClosed: number, -- and on its closed frame
}

-- Effects worker, 2026-10-21 (B46, the steep effects ladder) -------------------------------------------------------------
-- A particle sprite of Icons.Particles that is a flipbook sheet (data/Effects.Sheets): its frame grid, how it plays, and how
-- fast. Applied only once the sheet's id is real; until then the emitter wears Effects.SpriteFallback's single sprite.
export type SpriteSheet = { layout: "Grid2x2" | "Grid4x4", mode: "Loop" | "OneShot" | "PingPong" | "Random", fps: number }

return {}
