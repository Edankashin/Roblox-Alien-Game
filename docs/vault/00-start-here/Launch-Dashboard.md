---
tags: [start-here, plan, launch]
aliases: [Launch day, Dashboard]
up: "[[Start-Here]]"
---
# Launch dashboard

> **2026-10-15: the weekend launch is off** (Ethan). The bar: seamless, complete creature designs and UI at the top games' level. See [[Board]] "Decided 2026-10-15" and the research report in `reports/`.

One screen for Ethan. Written 2026-10-15 (Thursday) from [[Board]], the logs and the notes linked below; the Board is the live list, this is the picture. Launch week opens **Friday 2026-10-16**: the LaunchGold overlay and the Haunted Nebula event start then, and the experience is still private.

## Launch week (B49, set 2026-10-21)

Ethan: "I want to be able to launch this game by this week." The order matters: art lands, the Mac uploads and checks it in Studio, the coordinator fixes what the Mac finds, the Mac publishes the private places, Ethan plays on his phone, then launch morning.

**Cloud (the coordinator and its workers; no action from Ethan)**
- [ ] Rare aliens 1000x pass, both worlds (running) and the crash wreck and camp (running)
- [x] Pre-launch audit: server authority, saves, purchases and receipts, PolicyService for paid random items, the 14 px text floor, error paths on a cold server, analytics funnel; fix what it finds ([[Prelaunch-Audit]]: 6 fixes; Mac job 46)
- [ ] Launch polish: the loading screen and the home place in block cells (the nine missing home props), sound hooks pointed at existing ids where we have them
- [ ] New store icon and thumbnails in the block-cell look (after the rare pass), the description updated (Starhollow Forest, the new aliens)
- [ ] Phone performance pass on the generated worlds if the Mac's job 43 shows a cost
- [ ] Fix everything the Mac's Studio jobs report, the same day
- [x] TikTok batch 9, the before-launch lessons (`media/tiktok/NOTES.md` "Batch 9"): a tap on a Scrap price you cannot pay says "Need N more Scrap"; the Starter Pack stands on the HUD as a top button until bought; a bought Server Luck names its buyer in chat too, and a repeat buyer is named; payer-conversion benchmarks in [[Growth-Playbook]] section 7. The Studio check is [[TESTING]] "TikTok batch 9" (a Mac job to number)
- [ ] TikTok batch 9, after Ethan's answers: the Tiny Boost under 10 Robux if 47 is yes (about 30 minutes, then the Mac creates the product), Server Luck x4's value if 50 is yes (one number)

**Week two (after launch)**
- [ ] The paid-only prize wheel ([[Decisions]] B50), then the three spin products back on sale

**Mac session (Ethan starts it: "pull and run the jobs in Overnight.md in order")**
- [ ] Job 41: download the three TikToks (batch 9)
- [ ] Job 40: the one-command upload (`tools/finalize_upload.sh`), then commit the ids; moderation can take hours
- [ ] Jobs 36 to 39 and 42 to 46: the Studio checks of the HUD, screens, reveal, models, spectacle, worlds, props, Starhollow and camp
- [ ] Publish the private places from the repo (`tools/publish.py`) once the checks pass

**Only Ethan** (step by step in [[Launch-Steps]])
- [ ] Tell the Mac session to run the jobs (or approve the card that lets the coordinator message it)
- [ ] Check the Open Cloud key has the Assets API and `universe-places:write` for this experience
- [x] The five shop rows without ids (DirectRare, DirectEpic, AutoCollect, ModuleRush, RadarMk1Unlock): no feature grants them yet, so they stay hidden at launch; nothing to create
- [x] ~~Create the five missing shop products~~ Skip them: DirectRare, DirectEpic, AutoCollect, ModuleRush and RadarMk1Unlock have no feature yet, are not on the shelf, and the server will not sell one even with an id ([[Prelaunch-Audit]] finding 6)
- [ ] Decide the paid spins: they spin the free wheel, which pays Scrap, a Lucky Charm and a Double Shift, all three "never sold" ([[Prelaunch-Audit]] finding 7: a paid wheel without them, accept it, or hide the spins at launch)
- [ ] Pick the icon and thumbnails from the new set
- [ ] [[Decide-Now]] 47 to 50, the batch 9 money questions: an offer under 10 Robux, keep Scrap unsold when a player is short, a stacking multiplier after launch week, Server Luck x4 made the better deal
- [ ] Play the private game on your phone for ten minutes and say what feels wrong
- [ ] Launch morning, about 20 minutes: store page from the run sheet, the Experience Questionnaire, Privacy: Public ([[STORE-PAGE]] section 5)
- Optional: the group Moop Games (100 Robux), music listen-through, rejoin notifications (decision 20)

## Live now (private)

World 1 **v90**, World 2 **v5**, Home **v4**, published from the repo by the Mac session ([[2026-10-14]], job 21). They carry everything built on 2026-10-14 except the evening fixes; the six shop items are live. Nobody outside the team can join until you set the experience Public.

## Built and waiting

- **The 32 bodies**, all rebuilt with surfaces in the cloud: shapes in [[Silhouette-Pass]], surfaces in [[Surface-Pass]]; previews are embedded in both. They are not in the game yet: the upload waits on your "upload" and on the Mac's two Studio probes (vertex colours through the GLB upload, a script-made SurfaceAppearance).
- **The names**, applied in `Species.luau`: Moop for the Mossbop and 21 others ([[Species-Names]], id to name map; decision B26).
- **The thumbnails**: four candidates (Moment, Reward, Mystery, Haunted Nebula) and icon v3 in `media/store/2026-10-15/`, the reasoning in [[Thumbnail-Research]]. Your pick of icon and thumbnails is still open.
- **The group page**: name Moop Games, emblem, description, ranks ([[Group-Page]]). You create the group on Roblox (100 Robux) if you have not yet.
- **The run sheet**: every Creator Dashboard field in order, no decisions left in it, in [`docs/STORE-PAGE.md`](../../STORE-PAGE.md) section 5d (the pointer note is [[STORE-PAGE]]).
- **Next for the look**: [[Character-Pipeline]], a recipe to fuse each creature into one skin; it waits on the sculpt prototype.

## Only you can do these ([[Board]], "Waiting on Ethan", has the full list)

1. Close the extra Roblox Studio windows on the Mac (keep one), then tell the Mac session "Studio is back". Quit Studio before a Blender run ([[Setup-and-Tips#Memory on the Mac|Memory on the Mac]]).
2. Say "upload" for the 32 bodies, and pick the icon and the thumbnails.
3. Listen to the overnight music and sound picks in the place.
4. The launch morning, about 20 minutes: join the private game on your phone, fill the store page from the run sheet, the Experience Questionnaire, Public, then tell the coordinator "public" ([[STORE-PAGE]] section 5).
5. Create the group Moop Games (100 Robux) and add the collaborator: friend them, Collaborate with Edit, GitHub Write.
6. Check the Open Cloud key (Assets API and `universe-places:write` for this experience only, an expiry, only in `~/.zshrc`) and give the Terminal Screen Recording permission for the store clips.
7. Decide: rejoin notifications (decision 20, [[Board]] "Needs a decision"), and credits if a hero species should come from a 3D generator ([[Tools-Status]]).

## Decided on 2026-10-14 (Ethan)

The game is **Catch an Alien** (decision 19). Launch from the repo publish and dress in week one. The group is **Moop Games**, the experience stays under your account for launch ([[Decisions]] 16). The twelve unheard music picks ship and get swapped in week one. Max players 8. The build decisions of the day, in [[Decisions]]: **B21** the launch-week hook (LaunchGold), **B22** our own loading screen, **B23** the What's on card, **B24** every species its own base design, **B25** a surface pass on the creatures, **B26** the species display names.

## The three checks a creature must pass before it ships

From [[Character-Pipeline]] section 3.5, run in Blender on the exported GLB; a pass is written into the species' `notes.md`.

1. **Silhouette at 64 px.** The black shape alone names the creature, and its overlap with every other species stays under 0.85.
2. **No visible seam at the joins.** One connected skin, no edge sharper than 60 degrees except parts marked flat, and a clay render with no line or step where limbs, ears and tail meet the body.
3. **The face reads at 128 px.** Each eye white at least 6 px wide, pupil and white separable in greyscale, the highlight visible, the mouth a distinct mark, and eyes at least 5 percent of the body width.

Terms used here are in [[Glossary]]; the map of the whole vault is [[Start-Here]].
