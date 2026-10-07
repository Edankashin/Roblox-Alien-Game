# Player moment inventory

Source snapshot: 2026-10-07, after C18. Inputs: `src/client/init.client.luau`, its named UI/World consumers, `data/Sounds`, `data/Tiers`, and `GAME_DESIGN.md` §§3, 6, 7, 9, 15. Static source review; no Studio/audio playback. Recheck by searching `Sounds.`, `Vfx.`, `CameraDirector.`, `Toast.`, `Reveal.Show` and the named event in `src/client`; re-enumerate zero ids from `src/shared/data/Sounds.luau`. Lines are snapshot anchors and will move under formatting. [[Music-Plan]] · [[UI-Rules]] · [[Performance]].

**57 moments; 33 zero-ID sound slots.** Every named cue below is a hook with id 0 and is skipped by the sound helper today. Toast.Show adds ToastDing; Toast.Banner adds Banner; Builder buttons add Click. These are included where relevant, not claims that sound is audible. All moments have **no phone rumble and no music**: the only condition audio system is Ambience, whose four loops also have zero IDs. A blank emotion cell means the design does not explicitly assign that moment an emotion; descriptions are not proposed new design.

| Moment | Trigger / source anchor | Sound today | Effects today | Camera today | UI today | Phone rumble | Music | Intended emotion in design |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| First catch ever | src/client/init.client.luau:184 onCaught; src/server/Services/Economy.luau:743 first-catch analytics | hit cue + Reveal.Common (0) | Vfx.CatchBurst | Cancel at capture start | NEW ribbon; Scrap fly; tutorial progresses | none | none | Mastery: new worker takes over the task (design §3/§P0) |
| Catch: Common | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Common (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Common | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Common | src/client/UI/Reveal.luau:674 Show | Reveal.Common (0) | UI rays + rotating burst; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Catch: Uncommon | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Uncommon (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Uncommon | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Uncommon | src/client/UI/Reveal.luau:674 Show | Reveal.Uncommon (0) | UI rays + rotating burst; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Catch: Rare | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Rare (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Rare | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Rare | src/client/UI/Reveal.luau:674 Show | Reveal.Rare (0) | UI rays + rotating burst; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Catch: Epic | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Epic (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Epic | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Epic | src/client/UI/Reveal.luau:674 Show | Reveal.Epic (0) | UI rays + rotating burst; UI confetti; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Catch: Legendary | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Legendary (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none | Cute-to-epic payoff (Warden only, §3) |
| Catch bar opening: Legendary | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Legendary | src/client/UI/Reveal.luau:674 Show | Reveal.Legendary (0) | UI rays + rotating burst; UI confetti; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none | Filmable Legendary reveal (§15) |
| Catch: Cosmic | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Cosmic (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Cosmic | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Cosmic | src/client/UI/Reveal.luau:674 Show | Reveal.Cosmic (0) | UI rays + rotating burst; UI confetti; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Catch: Secret | src/client/init.client.luau:184 onCaught | CatchHit or Perfect + Reveal.Secret (0) | Vfx.CatchBurst in tier color | none after Cancel on entry | Scrap fly + Reveal; server announcement only at configured tier threshold | none | none |  |
| Catch bar opening: Secret | src/client/UI/CaptureBar.luau:484 Begin; src/client/init.client.luau:274 | none | no Vfx call; bar/zone/ticker tweens | CameraDirector.Cancel at src/client/init.client.luau:261 | Name, tier-derived zones/speed/rounds; catch variant is server supplied | none | none |  |
| Reveal: Secret | src/client/UI/Reveal.luau:674 Show | Reveal.Secret (0) | UI rays + rotating burst; UI confetti; no Vfx call | none (Viewport model, no CameraDirector call) | Tier badge, model, NEW/overlay/size stamps, Scrap; Perfect bonus when true | none | none |  |
| Perfect | src/client/UI/CaptureBar.luau:585 ApplyResult | Perfect (0) | Reveal perfectFlash at Reveal.luau:758 when final catch is Perfect | none | Perfect text/pop; final Reveal bonus | none | none | Clean skill feedback (§7 fairness/feel) |
| Miss / near miss | src/client/UI/CaptureBar.luau:597 ApplyResult | Miss (0) | flashZone on near miss; Builder.shake(bar); no Vfx | none (UI shake only) | Miss / Almost feedback | none | none | Almost had it (§3 juice rules) |
| Wiggle / failed Good roll | src/client/UI/CaptureBar.luau:589 ApplyResult | Wiggle (0) | bar feedback | none | Wiggle text; another sweep | none | none |  |
| Flee / chase timeout | src/client/UI/CaptureBar.luau:577 ApplyResult | Fled (0) | no dedicated Vfx | none | Escaped/Bolted; capture closes | none | none |  |
| Rare spawn nearby | src/client/World/WildRenderer.luau:581 buildAura | none; Secret proximity alone uses Heartbeat (0) in Radar | PointLight + optional glow sprite when aura > 0; no Vfx call | none | Nameplate/silhouette, radar according to tier/range | none | none | Discovery (§3 new silhouette) |
| Warden sighting | src/client/init.client.luau:890 SightingChanged | WardenAppear + Banner (0) | SightingRenderer walking model and pooled trail; no Vfx call in listener | none | SIGHTING_BANNER; compass marker; end toast | none | none |  |
| Warden encounter | src/client/init.client.luau:563 horn success; :869 WardenSummoned | HornCall, WardenAppear, Banner (0) | usual Legendary aura/capture burst; no dedicated stomp effect in this path | Cancel on capture; no boss camera sequence | Awake banner; server-supplied multi-round bar | none | none | Cute-to-epic world payoff; skill and persistence (§3/§7) |
| Meteor Shower start | src/client/init.client.luau:1414 refreshEventBanner | ShowerHorn + Banner (0); Ambience.Shower (0) | Vfx.SetShowerSky(true); weather/lighting condition readers | none | Shower event chip/banner; tutorial holds announcements | none | none |  |
| Meteor Shower end | src/client/init.client.luau:1426 refreshEventBanner | ToastDing (0); condition ambience crossfade | Vfx.SetShowerSky(false) | none | SHOWER_OVER unless tutorial held it | none | none |  |
| Catch Rush start | src/client/init.client.luau:1385 refreshEventBanner | Banner (0); no dedicated Rush start cue | none | none | RUSH_NOW; score/time chip; holds behind Shower/tutorial | none | none |  |
| Catch Rush win | src/client/init.client.luau:830 CatchRushResult; :798 Announcement | ToastDing + Banner (0) | none | none | Rank/reward toast + winner banner | none | none |  |
| Weekly flip | src/client/init.client.luau:1522 State weekly listener | Banner (0) | lighting/weather condition readers; no direct Vfx call | none | Alien-of-week announcement, weather/time chip | none | none |  |
| Season start | src/client/init.client.luau:1535 onSeason | ToastDing (0) | condition lighting/weather readers; no dedicated start Vfx | none | Season toast on transition; banner; first join suppresses began toast | none | none |  |
| Module completing | src/client/init.client.luau:662 ModuleCompleted | ModuleComplete + ToastDing (0) | Vfx.ModuleBurst(ship position) | CameraDirector.PanTo when capture/modal permits | Module done; slot-unlock toast; first gift may follow | none | none | Progress payoff (§3 dopamine map) |
| Ship launching | src/client/init.client.luau:678 Launched → src/client/World/LaunchSequence.luau:156 Play | Launch (0) | Vfx.ModuleBurst; CampRenderer.LiftShip | CameraDirector.PanTo; Cancel previous moment | HUD hides; destination text; fade/teleport/fallback | none | none | World payoff (§3 dopamine map) |
| Arriving on new world | src/client/init.client.luau:1861 ProfileLoaded; :1698 crash opener path | no distinct arrival cue; condition ambience placeholders | ordinary world boot, not a new arrival Vfx | CrashLanding only when tutorial startup selects it; no dedicated later-world reveal | HUD/biome/current-world sync; no separate arrival Reveal | none | none | Progress on return (§3) |
| Star Chart flight | src/client/init.client.luau:757 Flew | Banner (0) | LaunchSequence.Fade; no Vfx | no CameraDirector call | Screens close; flying banner, black fade; not-live fallback | none | none | Returning as a veteran: victory lap (§9/outposts) |
| Home unlocking | src/client/init.client.luau:694 HomeUnlocked | ToastDing (0) | none | none | Unlock toast waits until launch sequence ends | none | none |  |
| Arriving home / returning from visit | src/client/init.client.luau:1193 onVisit; :757 Flew for travel | ToastDing/Banner (0) | fade on travel; HomeRenderer on load | none | Home biome; return toast only when clearing a prior visit; no universal home-arrival Reveal | none | none | Cozy home/camp (§15) |
| Habitat income | src/client/init.client.luau:707 toastIncome / :713 HabitatIncome | ToastDing (0) | none | none | Paid amount toast for positive income | none | none |  |
| Mail arriving | src/client/init.client.luau:727 MailArrived | ToastDing (0) | none | none | Mailbox notification toast | none | none |  |
| Visitor arriving | src/client/init.client.luau:735 VisitorArrived | ToastDing (0) | home view redraw on visitor client | none | Owner toast; Visitor Book refresh | none | none |  |
| Wave | src/client/init.client.luau:498 successful WaveAt; :741 WaveReceived | GiftClaim + ToastDing (0) | Vfx.CatchBurst at displayed alien on sender | none | Sender/owner reward toast; no wave animation | none | none |  |
| Resting | src/client/init.client.luau:1055 AfkChanged | none on rest entry | screen dim; no Vfx | none | Resting card, timer/income, rate halves | none | none |  |
| Waking | src/client/init.client.luau:1073 AfkChanged wake | ToastDing (0) | none | none | Resting card closes; earned-income toast | none | none |  |
| Fusion | src/client/UI/AliensScreen.luau:457 toastFused | Click via button + ToastDing (0) | no fusion Vfx | none | Fused level toast; cards/state refresh; no Reveal | none | none |  |
| Growth stage | src/client/init.client.luau:968 AlienGrew | ToastDing (0) | CampRenderer redraw/scale via shared growth; no direct listener Vfx | none | Per-alien stage toast; chip/countdown refresh | none | none |  |
| Companion follows | src/client/UI/AliensScreen.luau:270 companion response | Click + ToastDing (0) | CompanionRenderer follow/bob; no Vfx | none | Following toast/status/perks | none | none |  |
| Riding / hop off | src/client/UI/AliensScreen.luau:297 mount response | Mount/Dismount + ToastDing (0) | Mounted positioning / other follower arc; no dedicated Vfx | none | Ride/Hop off card and toast | none | none | Visible social flex (§6 mounts) |
| Scrap purchase / craft | src/client/UI/ShopScreen.luau:317 successful buy | Click + ToastDing (0) | none | none | Crafted/bought toast; inventory/owned status | none | none |  |
| Robux purchase | src/client/UI/ShopScreen.luau:1109 purchase update | ToastDing (0) | Grant-dependent; alien uses Reveal path | none | Native prompt; server-confirmed thanks/Owned; failure toast | none | none |  |
| Daily / weekly quest claim | src/client/UI/QuestsScreen.luau:760 claim response | Click + ToastDing (0) | none | none | Claimed reward toast and row Done | none | none |  |
| Season track claim | src/client/UI/QuestsScreen.luau:1019 claim response | GiftClaim + ToastDing (0); alien uses Reveal tier (0) | Alien Reveal for alien reward; otherwise none | none | Claim toast suppressed for alien reward Reveal | none | none |  |
| Field Notes step | src/client/init.client.luau:1632 completion listener; QuestsScreen.luau:374 QuestClaim | ToastDing + button Click (0) | Grant-dependent Reveal; no step Vfx | none | Step-complete toast; claim summary/next step | none | none | Skill/persistence toward Warden (§9) |
| Codex first entry / milestone | src/server/Services/Economy.luau:702 codex count; :718 first payout; src/client/UI/CodexScreen.luau:588 selection | Reveal tier (0) for catch; Click (0) for card | catch/Reveal common path | none | NEW ribbon and updated Codex; no separate page/set milestone celebration found | none | none | Collection progress (§3 dopamine map) |

## Legendary encounter worked trace

Horn success → HornCall; WardenSummoned → WardenAppear plus banner. Selecting the spawn cancels the camera moment and opens the server-configured bar. Each round plays its verdict hook; the bar introduces the next round. No Warden stomp or camera shake sequence was found here: Builder.shake affects the bar, and the design’s boss choreography remains a gap. Final catch → tier-colored CatchBurst and Scrap fly → Reveal.Show with Legendary badge/model/rays/confetti and Reveal.Legendary hook. A configured catch announcement waits briefly for the Reveal. No camera pull, phone rumble, voice line or music plays in this path today.

## Decisions for the coordinator

- Populate and mix the zero-ID sound ladder before evaluating emotional impact; the current hooks are silent.
- Decide the Legendary round-transition/arrival choreography: the design asks for boss feedback and a filmable reveal, while current presentation shares most of the generic catch path.
- Give C21’s music director ownership/priority rules and decide accessible, optional rumble; do not infer either from existing Ambience.
- A dedicated Codex page/set milestone ceremony and a distinct new-world arrival moment were not found; decide whether those remain planned.

## Every Sounds id still zero

- `Sounds.Ambience.Day` = `rbxassetid://0`
- `Sounds.Ambience.Night` = `rbxassetid://0`
- `Sounds.Ambience.Rain` = `rbxassetid://0`
- `Sounds.Ambience.Shower` = `rbxassetid://0`
- `Sounds.Banner` = `rbxassetid://0`
- `Sounds.CatchHit` = `rbxassetid://0`
- `Sounds.Click` = `rbxassetid://0`
- `Sounds.Dismount` = `rbxassetid://0`
- `Sounds.Fled` = `rbxassetid://0`
- `Sounds.GiftClaim` = `rbxassetid://0`
- `Sounds.Heartbeat` = `rbxassetid://0`
- `Sounds.HornCall` = `rbxassetid://0`
- `Sounds.Launch` = `rbxassetid://0`
- `Sounds.Miss` = `rbxassetid://0`
- `Sounds.ModuleComplete` = `rbxassetid://0`
- `Sounds.Mount` = `rbxassetid://0`
- `Sounds.PartSnap` = `rbxassetid://0`
- `Sounds.PeddlerLanding` = `rbxassetid://0`
- `Sounds.Perfect` = `rbxassetid://0`
- `Sounds.Reveal.Common` = `rbxassetid://0`
- `Sounds.Reveal.Cosmic` = `rbxassetid://0`
- `Sounds.Reveal.Epic` = `rbxassetid://0`
- `Sounds.Reveal.Legendary` = `rbxassetid://0`
- `Sounds.Reveal.Rare` = `rbxassetid://0`
- `Sounds.Reveal.Secret` = `rbxassetid://0`
- `Sounds.Reveal.Uncommon` = `rbxassetid://0`
- `Sounds.ScrapTick` = `rbxassetid://0`
- `Sounds.ShowerHorn` = `rbxassetid://0`
- `Sounds.ToastDing` = `rbxassetid://0`
- `Sounds.WardenAppear` = `rbxassetid://0`
- `Sounds.WheelStop` = `rbxassetid://0`
- `Sounds.WheelTick` = `rbxassetid://0`
- `Sounds.Wiggle` = `rbxassetid://0`
