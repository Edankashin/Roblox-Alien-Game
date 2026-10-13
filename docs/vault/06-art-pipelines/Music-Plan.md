# Music plan

Proposal only, 2026-10-07. Inputs: [[Moments]] (57 moments, 33 silent sound slots), `GAME_DESIGN.md` §§3, 7, 8, 15, and `data/Worlds`. No audio is selected and no game code/data is changed. Worlds 3–7 remain designed-only; their rows are future direction, not launch requirements. All tempo, duration, volume and fade numbers below are proposed creative starting points, not measured game balance.

Creator Store catalog browsing was unavailable: browser security rejected access to create.roblox.com because site permission was declined. No alternate browser route was attempted. Use the search terms below in the [Creator Store Audio section](https://create.roblox.com/store/audio), filter to Roblox-provided licensed music, audition loops and verify each selected asset’s current usage/access terms and experience permission. No candidate asset IDs or license claims are invented.

## State palette (30 rows)

| State id | Mood | Tempo BPM | Instruments | Loop/length | Layer | Enter / leave | Creator Store search words |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VerdantDay | Welcoming curiosity | 82–94 | wood flute, marimba, rounded bass | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | forest playful marimba adventure day |
| VerdantNight | Welcoming curiosity with space and softness | 62–74 | wood flute, marimba, rounded bass | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | forest playful marimba adventure night |
| FrostbyteDay | Bright isolation, warmth near camp | 76–88 | celesta, felt piano, bowed glass | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | snow magical celesta ambient day |
| FrostbyteNight | Bright isolation, warmth near camp with space and softness | 56–68 | celesta, felt piano, bowed glass | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | snow magical celesta ambient night |
| NeonGridDay | Playful urban discovery | 104–116 | soft arpeggiator, synth bass, muted electronic drums | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | playful cyber synth city day |
| NeonGridNight | Playful urban discovery with space and softness | 94–106 | soft arpeggiator, synth bass, muted electronic drums | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | playful cyber synth city night |
| EmberfallDay | Energetic caution, never horror | 98–110 | wood percussion, low strings, airy flute | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | volcanic adventure percussion day |
| EmberfallNight | Energetic caution, never horror with space and softness | 78–90 | wood percussion, low strings, airy flute | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | volcanic adventure percussion night |
| TidepoolDay | Buoyant wonder | 78–90 | plucked harp, liquid mallets, soft pads | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | underwater wonder harp ambient day |
| TidepoolNight | Buoyant wonder with space and softness | 58–70 | plucked harp, liquid mallets, soft pads | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | underwater wonder harp ambient night |
| DreamdriftDay | Goofy dreamlike surprise | 90–102 | music box, pizzicato, reversed bells | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | whimsical music box dream day |
| DreamdriftNight | Goofy dreamlike surprise with space and softness | 66–78 | music box, pizzicato, reversed bells | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | whimsical music box dream night |
| VoidHubDay | Earned awe and anticipation | 70–82 | warm choir pad, glass harmonics, sparse toms | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | cosmic gate wonder ambient day |
| VoidHubNight | Earned awe and anticipation with space and softness | 54–66 | warm choir pad, glass harmonics, sparse toms | 64–96 s | base | World/clock edge: 3 s crossfade; leave for another base | cosmic gate wonder ambient night |
| CatchBase | Focused playful tension | 104–116 | muted plucks, light pulse | 16–32 s | capture | CaptureStart accepted: duck base in 0.2 s, fade in 0.3 s; end in 0.25 s | playful tension pluck loop |
| CatchIntense | Exciting challenge, not threat | 104–116 | matching low ostinato, toms, rising airy synth | same loop/grid as CatchBase | intensity | Epic+ only: add stem in 0.3 s; fade with capture; do not speed with ticker | adventure boss playful percussion stem |
| MeteorShower | Shared sky wonder | 96–108 | sparkly arpeggio, warm strings, low pulse | 48–64 s | event | Shower edge: 1 s in, 2 s out; capture/Reveal temporarily duck it | meteor cosmic magical adventure |
| CatchRush | Friendly competition | 120–132 | bouncy drums, pizzicato, bright bass | 32–48 s | event | Round edge: 0.5 s in, 1 s out; Shower wins; no restart per score update | playful race competition loop |
| HauntedNebula | Cute spooky curiosity | 84–96 | music box, bassoon, theremin accents | 64–96 s | season | Active event in eligible world: 3 s in/out; above exploration below Rush/Shower | cute spooky playful halloween |
| Launch | Proud release into adventure | 96–112 | brass-like synth, strings, big soft drums | 8–12 s one-shot | cinematic | Launched: 0.15 s attack synchronized to lift, fade 1 s on teleport/failure | uplifting space launch fanfare |
| Home | Belonging and relaxed ownership | 70–82 | felt piano, acoustic plucks, soft mallets | 64–96 s | base | Home arrival: 3 s in; leaving: 2 s out; visitors share local home mood | cozy home gentle piano loop |
| Resting | Safe, quiet rest | 50–64 | soft pad, rare piano notes; no rhythmic pressure | 96–128 s | rest | AfkChanged resting: 4 s in; wake: 1.5 s back to current world | calm sleep soft space ambient |
| Menus | Clear focus without losing place | inherits base | filtered world track, no extra composition required | inherits base | modifier | Panel opens: base gain x0.65 in 0.25 s; closes restore in 0.4 s | gentle menu ambient minimal |
| RevealCommon | Delight | free / shared motif | one motif with 1 notes; small mallet | 1.0 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward common magical stinger |
| RevealUncommon | Delight | free / shared motif | one motif with 2 notes; small mallet | 1.6 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward uncommon magical stinger |
| RevealRare | Delight | free / shared motif | one motif with 3 notes; small mallet | 2.2 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward rare magical stinger |
| RevealEpic | Delight | free / shared motif | one motif with 4 notes; brighter synth/chord tail | 2.8 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward epic magical stinger |
| RevealLegendary | Delight; earned awe | free / shared motif | one motif with 5 notes; brighter synth/chord tail | 3.4 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward legendary magical stinger |
| RevealCosmic | Delight; earned awe | free / shared motif | one motif with 6 notes; brighter synth/chord tail | 4.0 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward cosmic magical stinger |
| RevealSecret | Delight; earned awe | free / shared motif | one motif with 7 notes; brighter synth/chord tail | 4.6 s one-shot | stinger | Reveal.Show once: 0.05 s in; allow tail, then restore current state in 0.8 s | cartoon reward secret magical stinger |

Day/night arrangements should share a motif and compatible key; use paired stems only when supplied and licensed as such. Unrelated Creator Store tracks cannot be assumed phase-aligned. The capture pulse must not mimic or promise a hit timing window; timing feedback remains the server verdict’s responsibility. Reveal stingers belong to one audio owner so the existing Sounds.Reveal hook cannot double-play them. Legendary gets the longest clear payoff available inside the filmable ten-second design, while Cosmic/Secret distinguish timbre rather than simply getting louder.

## Proposed Music.luau data contract

A `Rows` dictionary keyed by each state id above, an explicit `Order`, and a `Policy` block. This is a schema proposal, not a new executable module. Every row has the following fields:

| Field | Meaning / constraint |
| --- | --- |
| id | Unique symbolic row id, equal to its dictionary key. |
| assetId | Numeric Roblox audio asset id; **0 for every row until chosen and permission-tested**. |
| volume | Base gain 0–1 before Music preference and duck multipliers. Menus is a modifier; its volume is the gain multiplier, not a Sound volume. |
| loop | Boolean; exploration/capture/events/home/rest loop; launch/Reveal do not. Menus creates no Sound. |
| layer | base, capture, intensity, event, season, cinematic, rest, stinger or modifier. |
| fadeInSeconds / fadeOutSeconds | Independent nonnegative seconds; interrupt cleanup still applies. |
| worldId / phase | Optional eligibility; phase Day or Night for per-world tracks. |
| tierMin / seasonId | Optional routing constraint for capture intensity or the named event. |
| syncGroup / bpm / beatsPerBar / loopSeconds | Optional verified stem timing; absent for unrelated tracks. |
| priority / duck | Declarative selection rank and gains for lower layers; constants live in Policy if shared. |

| Row | assetId | volume | loop | layer | fade-in seconds |
| --- | ---: | ---: | --- | --- | ---: |
| VerdantDay | 0 | .20 | true | base | 3 |
| VerdantNight | 0 | .20 | true | base | 3 |
| FrostbyteDay | 0 | .20 | true | base | 3 |
| FrostbyteNight | 0 | .20 | true | base | 3 |
| NeonGridDay | 0 | .20 | true | base | 3 |
| NeonGridNight | 0 | .20 | true | base | 3 |
| EmberfallDay | 0 | .20 | true | base | 3 |
| EmberfallNight | 0 | .20 | true | base | 3 |
| TidepoolDay | 0 | .20 | true | base | 3 |
| TidepoolNight | 0 | .20 | true | base | 3 |
| DreamdriftDay | 0 | .20 | true | base | 3 |
| DreamdriftNight | 0 | .20 | true | base | 3 |
| VoidHubDay | 0 | .20 | true | base | 3 |
| VoidHubNight | 0 | .20 | true | base | 3 |
| CatchBase | 0 | .22 | true | capture | 0.3 |
| CatchIntense | 0 | .12 | true | intensity | 0.3 |
| MeteorShower | 0 | .22 | true | event | 1 |
| CatchRush | 0 | .22 | true | event | 0.5 |
| HauntedNebula | 0 | .18 | true | season | 3 |
| Launch | 0 | .28 | false | cinematic | 0.15 |
| Home | 0 | .18 | true | base | 3 |
| Resting | 0 | .12 | true | rest | 4 |
| Menus | 0 | .65 | false | modifier | 0.25 |
| RevealCommon | 0 | .26 | false | stinger | 0.05 |
| RevealUncommon | 0 | .26 | false | stinger | 0.05 |
| RevealRare | 0 | .26 | false | stinger | 0.05 |
| RevealEpic | 0 | .26 | false | stinger | 0.05 |
| RevealLegendary | 0 | .26 | false | stinger | 0.05 |
| RevealCosmic | 0 | .26 | false | stinger | 0.05 |
| RevealSecret | 0 | .26 | false | stinger | 0.05 |

Fade-out values are the explicit exits in the palette; defaults for unspecified looping exits: 2 s for base/season, 1 s for event/rest, 0.25 s for capture/intensity; natural one-shot endings are not truncated, but interruption fades over 0.15 s. Each row still stores the resolved value so review sees it. Menus has no asset or loop; it covers that state without creating a competing track.

## Director behavior proposed for the coordinator

1. Select from authoritative client state mirrors. Priority: launch cinematic > Reveal stinger > capture pair > rest > Shower > Rush > eligible season > current world day/night or home. UI menus modify gain underneath; they never select a new competing theme. Preserve the current visual event precedence (Shower over Rush over season) from init.client.luau.
2. Keep at most two base/event sounds during a crossfade, one capture base, one intensity stem and one one-shot voice. Stop/destroy obsolete sounds on completion; use a generation token to invalidate stale fade callbacks. Repeated state pushes do not restart playback. A zero ID is silent and never loaded; retain the eligible lower layer if the replacement is unavailable.
3. Capture ducks exploration/event beds to 20% and brings in CatchBase. Epic and above adds CatchIntense; match phase only within a verified sync group, otherwise use a compatible single alternate cue. On flee/cancel, restore the current world/event instead of whatever was active at capture entry.
4. Reveal ducks other music to 10% for its stinger; existing hit/Perfect/voice cues retain intelligibility. Launch owns the musical bus until teleport or sequence cancellation. A late-loading cue may not start after its moment ended. Decide whether the old Sounds.Reveal and Sounds.Launch slots are migrated or retained as effects before implementation.
5. Resting lowers density and gain smoothly without a wake-up blast. Menu close and wake restore the recomputed current state. Home visits select Home regardless of the owner; no music state is persisted in saves. Reduced Motion does not mute audio; Music needs its own preference and should respect a global mute.
6. Use equal-power crossfades for unrelated tracks at conservative gain to avoid a perceived volume dip, then audition phone speakers and headphones. Shared-stem transitions may switch on a bar boundary, but gameplay/UI never waits for music. Keep ambience and music on separate buses and reduce the ambience bed modestly only where they compete.
7. Verify in the Mac session: world day/night and world changes, capture interrupts every event, all seven Reveal tiers, Shower/Rush overlap, event end while a panel is open, rest/wake, launch failure, mute before load, missing/inaccessible ID and rapid state flips. Check that only the intended voice survives and no cue double-plays.

## Decisions before implementation

- Approve the cozy exploration / playful challenge palette and the 30-row routing contract; built worlds 0–2 are the first audio scope.
- Assign Reveal/Launch cue ownership across Sounds and Music before the director lands.
- Pick and permission-test actual licensed assets; no verified Creator Store candidates are available from this run. Record chosen title, asset id, creator, license/access evidence and audition notes in this note without committing audio files.

## Implemented (milestone 51a, 2026-10-07)

The system is built and waits for tracks; no audio is chosen. [[Decisions]] ownership held: `Sounds` owns the one-shots and stingers (the Reveal tiers, the launch hit), `Music` owns the beds and layers.

- **Data:** `src/shared/data/Music.luau` has 13 rows (World 1 and 2 day and night, Home, Resting, CatchBase, CatchIntense, MeteorShower, CatchRush, HauntedNebula, Launch, Menus), each `{ assetId = 0, volume, loop, layer, fadeIn, fadeOut, priority }` with the volumes and fades from the tables above, plus the world map, the capture pair, the event names, the ducking numbers (stinger lengths per `Sounds` path) and the tier from which a catch is intense. Worlds 3 to 7 add a row and one map line when they are built.
- **Module:** `src/client/World/MusicDirector.luau` (API: `Start`, `SetWorldState`, `SetCapture`, `SetEvent`, `SetLaunch`, `SetResting`, `SetMenuOpen`, `Stinger`, `SetVolumeScale`) with the rules in `src/shared/MusicMath.luau` (spec `tests/MusicMath.spec.luau`). One bed at a time by priority (launch, intense capture, events, plain capture, resting, world or Home), equal-power crossfades, the Menus layer as a gain multiplier, stingers ducking the bed (the launch bed is never ducked). A winning row at 0 stays the logged state but the strongest row below it that has an id keeps playing, so tracks can be filled one at a time.
- **Changes against the proposal above:** the intense capture sits above the events (a Legendary during a Meteor Shower is still the Legendary moment), the events above the plain capture and resting, as the owner ordered; CatchIntense is its own bed that crossfades with CatchBase, not a stem; Resting is below the events; there is a separate `SetLaunch` for the cinematic. Settings gained a `Music` level (default High).
- **Filling ids (Mac session):** audition in Studio's Toolbox (Audio, Roblox-provided licensed music), check the asset's access terms and the experience permission, paste the digits into the row's `assetId`, record title, creator, licence and notes here, and run the [[TESTING]] step 10 check. The Studio Output line `[AlienGame] Music: <state>` shows the state either way.

## How the top games do it, and what we take (2026-10-14, for overnight job 5)

Researched for Ethan's ask "look at how other popular games similar to ours got their sounds and music".

- **Adopt Me** has an in-house composer and sound designer (Mark Sparling, also *A Short Hike*): original music, with a **day piece and a night piece per area and per season** that play across most of the map, plus short stingers. Lesson: two beds per world (day, night) of the same family, which is exactly our row shape; a season gets its own pair.
- **Pet Simulator 99** ships its own soundtrack (BIG Games; a 25-track album by Ostinarium is on the stores): energetic, loop-friendly, one palette for the whole game, with cheerful short SFX ("pop" on every egg and catch, "ding" on currency). Lesson: a consistent palette and loud, happy feedback sounds matter more than long tracks.
- **Grow a Garden** uses **public-domain classical and library recordings** (Grieg's Morning Mood, Mozart's Rondo Alla Turca, Debussy's Clair de Lune, Haydn's Trumpet Concerto), tied to weather, events and admin moments, with no original score at all. Lesson: licensed library music is enough for a top game when each piece is matched to a state; the recognisable calm pieces are part of its cozy identity.
- **Where the music comes from on Roblox:** the Creator Store's Audio section (Toolbox > Creator Store > Audio in Studio, or `search_asset` over the Studio MCP) holds over 100,000 professionally produced tracks and effects from partners (APM Music as `@APMOfficial`, Monstercat and others), free to use inside any experience; community sound effects under 10 s must be acquired into the inventory first (inserting from the Toolbox does that). Prefer partner and Roblox-provided assets so permission never fails.

**What we apply tonight (job 5), in this order of importance:**

1. **One palette.** Pick every bed from the same family (acoustic, bright, a little whimsical: the Adopt Me and Grow a Garden mood, not PS99's EDM), so the game sounds like one place. Day and night of a world are two pieces of that family at different energy.
2. **Match the state, not the taste.** Use the brief per row below; a calm piece for calm states, the two capture beds clearly different from the beds, the launch cue short and rising.
3. **Classical is allowed and good.** A bright classical recording from the library (Grieg, Vivaldi, Mozart) for a day bed is the Grow a Garden move and reads as cozy and premium at zero cost; keep night and home softer (music box, piano).
4. **SFX loud and happy.** Short pops, dings and chimes from Roblox's own library for the catch, Scrap and UI slots; the Reveal tiers each louder and longer than the one below (PS99's egg-open ladder).
5. **Volumes:** beds 0.35 to 0.5 in `Music.luau`, SFX through the existing `Sounds.Volume` groups; nothing clips, nothing is louder than the catch pop.
6. **Record every pick** in the tables below (title, creator, id) so Ethan can swap one number per row after listening.

### Music rows and the pick per row

| Row | Brief and search words | Picked (title, creator, id) |
|---|---|---|
| `VerdantDay` | bright pastoral, acoustic guitar or ukulele, whistling, light percussion; "morning", "pastoral", "sunny", "ukulele", "happy acoustic" || Peaceful Day Ukulele, Patrick Fradji Maarek (APM, 74 s), 1839580585 |
| `VerdantNight` | soft music box or lullaby, pads, the same instrument family at half the energy; "music box", "lullaby", "night ambient", "calm piano" || Ukulele Lullaby, Jacob King (APM, 154 s), 1842619720 |
| `FrostbyteDay` | bright and crisp, bells, light strings, a little wind; "winter", "snow", "bells", "sleigh", "crisp" || Winter Sleigh Bells, KPM Main Series (APM, 104 s), 1840810235 |
| `FrostbyteNight` | slow, icy pads, soft chimes; "winter night", "ambient ice", "aurora", "glass pad" || Frozen Planet, Andreas Brunnmeier (APM, 158 s), 1844634116 |
| `Home` | cozy acoustic, warm, slow; "cozy", "home", "warm acoustic", "fireside" || Feathers Instrumental, The Box (APM, 122 s), 9040068735 |
| `Resting` | near-silent ambient pad, no drums; "ambient pad", "sleep", "drone calm" || Mercury Lake 2 (60), KPM Shorts (APM, 61 s), 9039651194 |
| `CatchBase` | see the state palette above || Pizzicato Spritz (a), Johnny Wishbone (APM, 143 s), 9046599262 |
| `CatchIntense` | see the state palette above || Percussive Adventure (c), Brian James Brasher (APM, 63 s), 1841294396 |
| `MeteorShower` | cosmic synth, arpeggios, wonder; "space", "cosmic", "arpeggio synth", "stars" || Starlight Flight, Magnum Opus (APM, 135 s), 1840954608 |
| `CatchRush` | upbeat chiptune or electro, fast; "chiptune", "arcade", "upbeat electronic", "race" || Retro Gamer (60), Skip Armstrong (APM, 60 s), 1837769001 |
| `HauntedNebula` | see the state palette above || Spooky Ride, Michael Shapiro (APM, 120 s), 1837803400 |
| `Launch` | a 10 to 20 s rising orchestral cue ending on a hit; "rising", "launch", "countdown", "triumphant short" || Welcome Home Sting, Bradley James Farmer (APM, 13 s), 9047296345 |
| `Menus` | a soft pad layer, no melody; "soft pad", "ui ambient" || none: a gain layer, plays no sound of its own (stays 0) |
| `Events` | see the state palette above | |
| `Capture` | light, playful, a ticking pulse, no big drums; "playful", "quirky", "pizzicato", "light tension" | |
| `Ducking` | see the state palette above | |

Picked 2026-10-14 (Mac session, overnight job 5) through the Creator Store search (the public `toolbox-service/v2/assets:search`, the same index as Studio's Toolbox), only from the creators Roblox and APMOfficial, chosen by title, genre and length: **nobody has listened to them yet**. Volumes in `Music.luau` were left as they were.

### Sound slots and the search words per slot

| Slot | Search words | Picked (title, creator, id) |
|---|---|---|
| `Click` | "ui click soft", "button pop" || Roblox_UI_Small_Click, Roblox, 15675032796 |
| `ToastDing` | "notification ding soft" || Roblox GUI - Notification High, Roblox, 17208361335 |
| `Banner` | "announcement chime" || Powered Up Chimes, Juice Music (APM), 1839901345 |
| `PartSnap` | "metal click snap", "lego click" || Roblox_Pinball_Small_Metal_Click_01, Roblox, 16480551554 |
| `ModuleComplete` | "success fanfare short", "level up" || Winner, Rolf Anton Krueger (APM), 1844584698 |
| `ShowerHorn` | "deep horn", "cosmic horn" || Space Chimes, Juice Music (APM), 1839901334 (no licensed cosmic horn found) |
| `PeddlerLanding` | "spaceship landing", "hover land" || Rocket whoosh 01.wav, Roblox, 12222095 |
| `GiftClaim` | "gift open", "present chime" || TV Winners Link (b), Richard Myhill (APM), 1841114489 |
| `WheelTick` | "wheel tick", "ratchet click" || Roblox_UI_Bright_Click, Roblox, 15675059323 |
| `WheelStop` | "ding bell win" || Finger Cymbal Sounds (a), KPM 1000 LP Series (APM), 1842279701 |
| `HornCall` | "horn call", "war horn" || Tuba Tone K, Otto Sieben (APM), 1846987124 |
| `WardenAppear` | "monster roar cute", "big stomp" || not found among Roblox and APM assets; left 0 for a Studio Toolbox pick | | **needs Studio acquire**, candidates (community, under 10 s): Snow Impact Big Hits Semi- Deep Stomping (SFX), ProSoundEffects, 9125965517 (5 s); Classic Monster Roar sound effect (1), Sloit's Fanclub, 140183060324629 (5 s); Monster Roar, JuanitoproCritica, 133651202885353 (4 s) |
| `Mount` | "jump hop", "boing" || not found among Roblox and APM assets; left 0 | | **needs Studio acquire**, candidates: Cartoon Jump Sound [HQ] - BOING, Dizzota, 2772396665 (1 s); Spring Jump, B0B_2, 4117546024 (1 s); Cartoon Jump, darkenweb, 6746569988 (2 s) |
| `Dismount` | "soft land thud" || Deep Gaia Soft breath impact, Will Cohen (APM), 1841354575 |
| `Heartbeat` | "heartbeat" || Heart Beat OL, Kosinus (APM), 1839090417 |
| `Launch` | "rocket launch whoosh" || Welcome Home Sting, Bradley James Farmer (APM, 13 s), 9047296345 |
| `CatchHit` | "pop", "bubble pop" || Roblox_UI_Cute_Pop, Roblox, 15675055424 |
| `Perfect` | "sparkle chime", "magic twinkle" || Magical Meetup - Hit1, Spot On (APM), 9048764474 |
| `Miss` | "wrong buzz soft", "miss boop" || Roblox_UI_Delete, Roblox, 15675075163 |
| `Wiggle` | "squeak wiggle", "rubber" || not found among Roblox and APM assets; left 0 | | **needs Studio acquire**, candidates: Squeaky Toy Sound Effect, Riley_Mutt, 129088013422694 (1 s); Rubber Raft Squeaking Sliding On Surface 4 (SFX), ProSoundEffects, 9118737438 (1 s); Metal Rub Short Squeaks Rubber Soles Sliding (SFX), ProSoundEffects, 9125686041 (1 s) |
| `Fled` | "whoosh away", "dash" || Roblox_UI_Whoosh_02, Roblox, 15675028888 |
| `ScrapTick` | "coin tick", "small coin" || CoinTransfer_01, Roblox, 127645268874265 |
| `LegendaryRumble` | "earthquake rumble", "deep rumble" || Wild Rumble (SFX 2), Martin Perry France (APM), 1842481856 |
| `BarOpen` | "ui open whoosh", "swoosh up" || Roblox_UI_Whoosh_04, Roblox, 15675012262 |
| `RareNearby` | "radar blip", "sonar ping" || Roblox_UI_Indicator, Roblox, 15675085146 |
| `RushStart` | "air horn short", "starting whistle" || Roblox_UI_Whistle_Low, Roblox, 15675062723 |
| `Arrival` | "magical arrival", "orchestral swell short" || Once upon a Time (sting), Thomas Howe (APM), 1838007773 |
| `RestStart` | "soft yawn", "wind chime" || Roblox_UI_Cute_Goodbye, Roblox, 15675081158 |
| `Ambience.Day` | "meadow birds ambience", "nature loop" || Bird Song, KPM 1000 LP Series (APM, 12 s), 1842360915 |
| `Ambience.Night` | "crickets night loop" || African Night, David Peter Bradnum (APM, 89 s), 1840267237 |
| `Ambience.Rain` | "rain loop light" || Rain Effect, Roblox (59 s), 1516791621 |
| `Ambience.Shower` | "space wind ambience" || Space Wind, Sonoton Music (APM, 52 s), 1846553484 |
| `Reveal.Common..Secret` | one short fanfare per tier, each louder and longer than the one below: "ta-da short" (Common) to "epic reveal orchestral" (Cosmic), "mysterious reveal" (Secret) || Common Roblox_UI_Tonal_Stinger (Roblox) 15675043410; Uncommon Magical Meetup - Hit2 (APM) 9048764475; Rare Something Magical (sting) (APM) 9039420865; Epic Glamour Fanfare 4 (APM) 1844584807; Legendary Orchestral Sting (APM) 1846284687; Cosmic Palace Magic (sting) (APM) 1841820743; Secret Mysterious Path - Sting 3 (APM) 1843092991 |
