# Growth playbook: discovery, retention, rejoin, first five minutes

Researched 2026-10-05. Every claim carries a source tag `[S#]` resolved in the Sources section. Evidence tiers: **doc** = opened a Roblox creator-docs page (read through its GitHub mirror, because create.roblox.com and devforum.roblox.com are blocked from the research environment); **summary** = only a search-result summary of a Roblox post was available, not the post itself; **3rd** = third-party write-up, not Roblox; **unverified** = could not be confirmed. Nothing here is tested on our game. All numbers are starting values and belong in `src/shared/data` when built.

## 1. Algorithm facts

**Verdict on "Roblox rewards a game that is one of the first three a player plays that day for 5 minutes": not supported.** No Roblox page I could read mentions "first three games", and no official page publishes a minute threshold for a "qualified play" (Roblox says only "a meaningful play session ... filters out accidental clicks or quick bounces") [S1][S17]. The 5-minute figure appears in third-party posts that read qualified play as 5 minutes or more [S30] and in Roblox's onboarding advice ("fun within the first five minutes") [S2][S3], which is probably where the belief comes from.

**Refined belief, from official text:** Roblox scores each game per user over 28 days. It likes a game that (1) gets clicked from Home, (2) does not lose the player in the first 60 or 180 seconds, and (3) brings the same player back on more distinct days, with friends, and spends. Nothing in the docs scores your game against the other games a player opened that day; it scores your game's own per-user behaviour, though distribution can still fall if other games engage better [S1].

| Home "Recommended For You" signal | Roblox priority | Tier | What it means for us |
|---|---|---|---|
| Play through rate (saw tile, pressed play) | Most important | doc [S1] | Icon, thumbnails, title, video (section 2) |
| First play bounce rate: left under 60 s, and 61 to 180 s | Most important, negative | doc [S1] | The first-minute script (section 6) must pay off before 60 s |
| Play days per user, windows Day 1, Day 2 to 7, Day 8 to 28 | Most important | doc [S1] | Welcome Week, quests, Shower cadence, rejoin reminders |
| Playtime per user, capped at 60 min per user per game per day | Most important | doc [S1] | Hour-long sessions add nothing; many short return days do |
| Intentional co-play days (join, invites, private servers) | Important | doc [S1] | Friend Boost, invite prompt, referral rewards |
| Qualified play sessions per user (users who came via Home) | Important | doc [S1] | "Meaningful session" has no published minutes |
| Spend days per user, Robux spent per user | Important | doc [S1] | Starter Pack, passes; never a second currency |

- **Two stages:** retrieval picks candidates from engagement, retention and monetization; ranking orders them. "Roblox doesn't count the engagement, monetization, or retention of users first acquired from ads, curation, friends, search, social media, or any other source in the ranking stage of Recommended for You" [S1]. Only players who first arrived through Home count, so a Home-acquired player's first session is what gets scored.
- **Correction to `docs/PRE_PRODUCTION.md` section 7:** it says paid traffic "drags down the engagement signals". Per [S1], ad-acquired users are simply not counted in the ranking stage. The "ads only after D1 above 20%" gate is still sensible for ad return, but not for the reason written. Left unedited; owner to decide.
- **Timeline:** 2024-07-18 qualified play-through analytics [S24]; 2025-12-11 improved algorithm, six signals over 7 days [S21]; early 2026 deep play-through rate and 7-day qualified play sessions announced [S22]; 2026-04-10 tests of longer windows, with creator reports of impression drops [S20]; 2026-06-15 live with 28-day windows [S18][S19]; 2026-08-20 further test of "long-term player value" [S23]. All summary tier.
- **Search:** Roblox publishes no ranking formula. It says search now understands natural-language queries ("food games") [S1]. Metadata implying monetary rewards, metadata that does not match gameplay, and games whose metadata and place closely resemble existing games "are no longer prioritized" [S1]. Claims that title outranks description outranks tags are 3rd tier, unverified.
- **Unverified claim to ignore:** "games climb by players returning within 24 to 48 hours for a shorter session" is from third-party sites [S31]; do not design to it.
- **Moments:** from September 2026 videos on a game's details page appear in the Moments tab (reported in summaries, source unclear) [S36], so the 10-second gameplay clip is worth making well.

## 2. Icon, thumbnails, name

| Asset | Official guidance (doc) | Our rule |
|---|---|---|
| Icon | Square; 512x512 template; scales down to 150x150 so test small; relevant, clear, high resolution, colour and contrast for mood; no ambiguous or generic art [S5] | One alien face fills about 70% of the frame, thick navy outline, no text, passes the greyscale-at-150 px check |
| Thumbnails | 16:9, ideally 1920x1080; up to 10 images or videos; keep essential text and elements out of the bottom (metadata overlays it) [S4] | Text top-left or top-right, subject centre |
| Personalization | With 2 or more active thumbnails Roblox shows each to random users, then re-weights per user group by qualified play-through rate, hourly; the docs advise keeping several active [S4][S25]. Tests averaged +8.5% qualified play-through rate (summary) [S25] | Ship three, keep all three live; judge by Creator Hub, not taste |
| Icon A/B test | Not in the icon docs [S5]; a community request is open [S26] (summary) | Rotate the icon by hand, one change per two weeks, compare play-through rate |
| Honesty | "Make sure all thumbnails accurately reflect your game"; videos must be authentic [S1][S4] | Every frame is an in-engine render of real features |

**What top collection and simulator games do** (3rd tier; I could not view live store pages from here): one big character close-up with an emotion, two to four words of huge outlined text, bright contrasting colours, one focal point, one promise [S34]. Our pillars already match: one bar, aliens everywhere.

**Name rules:** [unique name] plus a genre keyword; no "FREE", Robux or codes words (Roblox deprioritizes reward-implying metadata [S1]); do not echo an existing game (same rule); search Roblox for collisions before locking. I could not check availability from here.

| # | Name candidate | Reason |
|---|---|---|
| 1 | **Crash Planet: Catch Aliens** | Names the hook (crash-land) and the exact search phrase "catch aliens" in one line |
| 2 | **Alien Pals: Build a Rocket** | "Pals" signals cute and collectible; "Build a Rocket" is the promise no pet simulator makes |
| 3 | **Planet Hoppers: Alien Collector** | Short brand-first name that carries the world-to-world arc and still has the genre keyword |

| # | Thumbnail brief | In frame | Text overlay | Colour |
|---|---|---|---|---|
| A | The Catch | Mossbop huge on the right two thirds, wide-eyed; the player avatar reaching in from the left; the timing-bar zone glowing mid-frame | "CATCH ALIENS!" top-left, yellow with navy outline | Lime-green alien on a magenta and violet nebula (complementary pair) |
| B | The Ship | Half-built rocket at the crash site, a swarm of small aliens carrying panels, the real ship bar at 62% across the top | "ALIENS BUILD YOUR SHIP" top-centre, white with navy outline | Warm orange sunset against a cyan sky |
| C | The Collection | A 4x3 grid of aliens in rarity-coloured frames, one dark "?" silhouette glowing in the centre | "WHO'S THAT?" top-right, white with navy outline | Deep navy field with rainbow rarity borders |

## 3. Retention loop

| Mechanic | What top games do | Policy line | Ours |
|---|---|---|---|
| Daily login, 7th-day reward | PS99: escalating streak boost, claim every 24 h [S33]. Bubble Gum Simulator Infinity: Stars equal streak times 10, capped at 200 [S33]. Adopt Me: 2026-09-11 revamp to a 30-day streak, 1 Star per login, Stars buy a Streak Saver (summary) [S33] | Roblox ships an official Engagement Rewards package with login streaks and time rewards [S11]. The EU KIDS Act draft (2026-09-17) targets regular-interval rewards and streak penalties for minors; a proposal, not law (summary) [S32] | **Exists**: Welcome Week by days played, day 7 Epic Egg (`data/Gifts.luau`). Keep no-penalty framing |
| Playtime gifts | PS99: 12 gifts at 5, 10, 15, 20, 30, 40, 50, 60, 75, 90 min, 2 h, 3 h [S33] | Engagement Rewards time progress resets on leaving [S11]; KIDS draft is wary of rewards at regular intervals [S32] | **Skip**: the 5-minute Peddler already gives a reason to look up, and Roblox counts only 60 min per day [S1] |
| Group join reward | PS99 hands out boosts via its group page [S33] | Community consensus: rewarding group membership is allowed, and the check is real: `Player:IsInGroupAsync` (the older `IsInGroup` is deprecated) [S13][S28]. `GroupService:PromptJoinAsync` shows a native join modal and returns None if ineligible [S12] | **Add**: one cosmetic plus one lure, claimed once, server-checked, never gating progress; hide the button when ineligible |
| Like or favorite reward | Widespread among mid-size games, per a 2026 forum thread [S28] | No Engine API reports a like or favorite. Forum consensus citing Roblox rules says rewarding ratings is not allowed and promising it is dishonest because it cannot be verified [S28]. I could not open an official page that states the rule [S29]; treat as prohibited | **Skip.** At most an unrewarded, one-time "enjoying it?" card after the first module |
| Friend invites | PS99 clans; Grow a Garden gifting [S33] | Official referral system: `ReferredByPlayerId` in `Player:GetJoinData()`, inviter and invitee rewards, one banner at a time [S10] | **Add** on top of the Friend Boost already designed; co-play days are scored [S1] |
| Daily and weekly quests | Fisch: daily challenges refresh 00:00 UTC, 2 rerolls [S33] | None | **Designed, not built** (P1). Add one reroll per day |
| Limited events | Grow a Garden: Saturday patches, 3-week cycles, restock timers [S33]; PS99 and Fisch run timed event boards | Roblox Experience Events: up to 10 live or upcoming, notify opted-in players when one starts [S9]; a listed discovery surface [S1] | **Exists** (Meteor Shower, weekly, monthly). **Add**: list every weekly and monthly event in Creator Hub, zero code |
| Offline earnings | Idle loops such as Grow a Garden crops growing offline (3rd) | None | **Exists** (50% for up to 60 min, assembly at full speed) |
| Leaderboards | Event-scoped boards (section 4) | Display names only | **Add** (milestone 20) |
| Codes | Every big simulator posts codes | Promo codes are fine if not traded for a like (forum, summary) [S28] | **Add, small**: one table, Scrap, lures and cosmetics; hand to the creators from `PRE_PRODUCTION.md` section 7 |
| Season pass | BGSI Bubble Pass runs 3 to 4 weeks [S33] | Paid items follow the paid-random rules | **Skip** at launch; the free event quest track covers it |
| Rejoin reminders | Notifications plus in-game timers | Opt-in and 13+ only (section 5) | **Add** (milestone 19) |

Blox Fruits: I found no reliable source for its retention mechanics (only a fan-concept wiki, discarded).

## 4. Leaderboard recommendation

| Metric | For | Against |
|---|---|---|
| Total catches | The core verb; kids can read it; server-authoritative; every session moves it | Needs a weekly reset or veterans lock the top |
| Scrap earned, lifetime | Easy to count | Rewards idle time and boosts; moves with economy tuning; drifts toward pay advantage |
| Codex percent | Matches the collection fantasy | Capped at 100%, so ties; falls when we add species; whole numbers only in an ordered store |
| Ship launches | Matches the story | One per 2 to 7 days, so the board is mostly ties |

**Recommend: "Catches this week" (resets Friday with Alien of the Week) as the main board, plus an all-time "Aliens in codex" count (a count, not a percent) on the profile.** Reason: a weekly reset lets a player who joined on Tuesday reach the top 100 by Sunday, which is the 28-day return hook, and it ties to the Friday cadence. Top games rank event-scoped activity, not lifetime wealth: PS99 event boards by boss kills, clan battles by points, Fisch crews by Crew Rating [S33] (3rd).

Platform facts (doc): ordered stores hold integers only, no versioning or metadata, no `userIds` on `SetAsync` or `IncrementAsync` [S15]; `GetSortedAsync` page size defaults to 50, max 100 [S15]. Per-server budgets per minute: list `5 + 2 x players`, write `30 + 5 x players`, read `60 + 40 x players` [S14].
- **Pattern** ("top 100 refreshed every minute" is community practice, not a Roblox rule): one server fetches the top 100 every 60 s (one list call of a small budget), caches it, and sends it to clients through the net wrapper. Never call `GetSortedAsync` per player. Roblox's own tutorial polls every 3 s for a top-3 board [S16]; if each poll reached the store it would exhaust the list budget.
- **Writes:** keep the running count in the save; push `IncrementAsync` at most once a minute per player, plus on leave and `BindToClose`.
- **Keys:** `Catches_<year>W<week>`; old weeks stay read-only. Server caps catches per minute (data table) so a bug cannot top the board.

## 5. Rejoin reminders

**Experience Notifications (shipped 2024; doc unless marked).**
- **Opt-in only.** Roblox delivers to opted-in players aged 13+ in the notification stream with a Join button [S6]. Under-13 players never get them.
- **Prompt:** `ExperienceNotificationService:PromptOptIn()` on the client, after `CanPromptOptInAsync()` is true. No modal if the player is under 13, already opted in, or saw the prompt in the past 30 days [S6][S8].
- **Strings:** created in the Creator Dashboard; there is no Open Cloud API for it [S7]. Limit 99 characters (summary, unverified in the docs I opened) [S27]. Parameters let the text carry numbers.
- **Send:** `POST https://apis.roblox.com/cloud/v2/users/{userId}/notifications` with an API key or OAuth 2.0; type `MOMENT` is the only one; optional launch data up to 200 bytes, read with `Player:GetJoinData()`; a `category` for analytics [S6][S7].
- **Rate limit:** one notification per user per day per experience; a throttled user returns feedback (HTTP 429, summary) [S7][S27]. Keep our own request rate to a few per second.
- **Eligibility and usage rules** live on an included page I could not read. Unverified.

**How we use it:** (1) Ask only on session 2 or later, after the offline chest, with our own one-line card first ("Tell me when my ship part is ready?"); call `PromptOptIn()` only on yes, so the 30-day cooldown is not burned. Never inside the first five minutes. (2) Event-based text only: part ready, Alien of the Week landed, Shower Storm hosted; no guilt, no streak-loss copy. House cap: 3 per week, under the platform's 1 per day. (3) Gate behind a `Config` flag like the paid-spin switch: the EU KIDS Act draft lists re-engagement push notifications for minors (summary) [S32]. (4) All text keyed in `src/shared/strings`.

**In-game nudges (no platform dependency):**
- Offline chest summary on join (exists), naming the part that snapped on while away.
- Leave with a timer on screen: "Hull Frame ready in 12 min".
- Gift tray shows "Next gift: Twig Lure, tomorrow". Welcome Week is by days played, so the line is an invitation, never "don't lose your streak".

## 6. First five minutes script

Roblox's own advice: fun inside the first five minutes, no long tutorials, learning in short action-based pop-ups [S2], an onboarding of "5 minutes or less" [S3]. The bounce windows are 60 and 180 s [S1]. `PRE_PRODUCTION.md` 3.1 has the first catch at 1:00 and the first module at 7:00, so this script is about 2.5 minutes tighter. Needs a tutorial-only assembly time of about 90 s in data.

**Story in 30 seconds (three beats, three lines of text):** 0:00 you crashed and the HUD ship bar reads 0%; 0:15 plates move the bar, so parts fix the ship; 0:30 a Mossbop waddles up with a "!", so aliens are friendly and will help. New strings: `STORY_CRASH`, `STORY_PARTS`, `STORY_ALIEN`; none exist yet.

| Time | Step | Player does | Sees and hears | Understands | Measure |
|---|---|---|---|---|---|
| 0:00 | Opener | Nothing; skippable after first time | Crash cinematic, ship breaks, ship bar appears at 0% | "I crashed; that bar is my ship" | Onboarding funnel step 1 |
| 0:08 | T1 collect 3 WreckPlate | Walks to the marker, grabs 3 | Pop and chime per plate, bar creeps up on the first | Parts go to the ship | Step 2 |
| 0:25 | (spawn) | Watches | Mossbop waddles in, "!" bubble | A creature wants me | |
| 0:30 | T2 catch Mossbop | Taps Catch, hits the cannot-fail zone | Catch burst, rarity card, codex "NEW" stamp, Scrap | **Aha 1: I caught a cute alien** | `FirstCatchSeconds` median 45 s or less |
| 0:55 | (auto) | Watches | Mossbop walks to the Gather station; timer drops | My alien works for me | |
| 1:25 | T3 moduleStarted | Pays for the Hull Frame, adds plates | Ship bar jumps, bass hit, module sub-bar starts | Building moves the bar | Step 4 before 180 s |
| 2:00 | T4 catch Puffpuff | Second catch | Puffpuff takes the build job | Different aliens, different jobs | |
| 2:45 | T5 catch 3 more | Free catching, Nearby panel on | Counter 1/3 to 3/3, Scrap counter appears | More aliens, faster ship | |
| 3:45 | T6 moduleComplete | Watches | Swarm, camera pan, part snaps on, bar +20% | **Aha 2: my crew built part of the ship** | `FirstModuleSeconds` median 270 s or less |
| 4:30 | T7 Forest and Glowroot | Taps Claim, follows the marker | Welcome Week gift 1 (300 Scrap) pops; tray says "Tomorrow: Twig Lure"; "Thrusters need Glowroot" | **Aha 3: a gift, a goal, a reason to return** | `GiftClaim` day 1; funnel done; first-session retention at 5 min above 55% |

Built as milestone 27 (decision 18, 2026-10-06): gift 1 opens as the T6 payoff (the Gifts screen with its "Tomorrow" line, after the fanfare and the pan); the Peddler's landing banner and the Shower chip and banner stay off a new player's screen until the tutorial ends, while the events themselves run server-wide as ever; the notification card already waits for session 2 and there is no shop pop-up. All of it is the `Script` block in `data/Tutorial.luau`. Hint strings TUT_1 to TUT_7 stay as written.

## Sources (all read 2026-10-05)

Opened, Roblox creator-docs (GitHub mirror of create.roblox.com/docs; base `https://github.com/Roblox/creator-docs/blob/main/content/en-us/`):
- S1 `discovery.md` (same as https://create.roblox.com/docs/discovery). S2 `production/analytics/engagement.md`. S3 `production/analytics/retention.md`. S4 `production/publishing/thumbnails.md`. S5 `production/publishing/experience-icons.md`. S6 `production/promotion/experience-notifications.md`. S7 `cloud/guides/experience-notifications.md`. S9 `production/promotion/experience-events.md`. S10 `production/promotion/referral-system.md`. S11 `resources/feature-packages/engagement-rewards.md`. S14 `cloud-services/data-stores/error-codes-and-limits.md`. S16 `tutorials/use-case-tutorials/data-storage/create-leaderboard.md`. S17 `production/analytics/acquisition.md` (defines no qualified play).
- S8 `reference/engine/classes/ExperienceNotificationService.yaml`. S12 `reference/engine/classes/GroupService.yaml`. S15 `reference/engine/classes/OrderedDataStore.yaml`. S13 https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/Player.yaml.

Search-result summary only (post not opened; blocked host):
- S18 https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- S19 https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- S20 https://devforum.roblox.com/t/testing-more-recommended-for-you-algorithm-signals/4568033
- S21 https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441
- S22 https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571
- S23 https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042
- S24 https://devforum.roblox.com/t/analytics-recommendations-qualified-play-through-rate-and-similar-experiences-benchmarks/3075185
- S25 https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233 and https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665
- S26 https://devforum.roblox.com/t/add-ab-testing-and-stats-for-titles-icons/4778726 and https://devforum.roblox.com/t/are-you-able-to-ab-test-game-icons/3339468
- S27 https://devforum.roblox.com/t/introducing-experience-notifications/2826474, https://devforum.roblox.com/t/experience-notifications-and-rate-limits/4615621, https://devforum.roblox.com/t/introducing-in-experience-notification-permission-prompts/2909125
- S28 https://devforum.roblox.com/t/boundaries-of-in-game-rewards/3051700, https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969, https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286, https://devforum.roblox.com/t/do-tos-allow-x-likes-for-next-reward/1029127
- S29 https://about.roblox.com/community-standards and https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards
- S36 https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all

Third party (not Roblox; treat as leads):
- S30 https://x.com/ooStarwarsbccoo/status/2066928795244712419 and https://www.indg.vc/blog/what-is-qptr-on-roblox-and-why-it-matters (5-minute reading of qualified play)
- S31 https://rowatcher.com/news/what-the-roblox-algorithm-actually-rewards-in-2026-not-ccu
- S32 https://www.pocketgamer.biz/daily-log-in-bonuses-and-activity-streaks-under-threat-in-eu-kids-act/ and https://www.dwt.com/blogs/privacy--security-law-blog/2026/09/eu-kids-act-online-child-safety-proposal
- S33 https://pet-simulator.fandom.com/wiki/Free_Rewards_(Pet_Simulator_99), https://db.biggames.io/clans/leaderboard, https://www.petsim99.co/player-leaderboards/current-event, https://www.playadopt.me/news/new-star-rewards, https://bgs-infinity.fandom.com/wiki/Daily_Rewards, https://fischipedia.org/wiki/Challenges, https://fischipedia.org/wiki/Crews, https://gamerant.com/roblox-grow-a-garden-weekly-events-changes/
- S34 https://www.obby.fun/blog/roblox-obby-thumbnail and https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail
