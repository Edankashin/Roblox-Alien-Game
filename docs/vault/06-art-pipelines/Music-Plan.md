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

- Approve the cozy exploration / playful challenge palette and the 33-row routing contract; built worlds 0–2 are the first audio scope.
- Assign Reveal/Launch cue ownership across Sounds and Music before the director lands.
- Pick and permission-test actual licensed assets; no verified Creator Store candidates are available from this run. Record chosen title, asset id, creator, license/access evidence and audition notes in this note without committing audio files.
