# Owner guide: the dashboard steps only Ethan can do

Written 2026-10-06 for someone new to Roblox Studio. Every step says where the button is. Two websites and one app are involved:

- **The Creator Dashboard**, create.roblox.com, signed in as the account that owns the game (EDankashin). "Creations" in the left menu lists your experiences.
- **Roblox Studio**, the app on the Mac. "Home" and "View" are tabs along its top. The **Output** window (View tab, Output) is where the game prints.
- **The repo** on the Mac (`Roblox-Alien-Game`). The numbers you collect go into three files under `src/shared/data/`: `Worlds.luau`, `Shop.luau`, `Social.luau`, plus one line in `Config.luau`. You can paste the numbers to me in chat instead of editing: I put them in, run the checks and push.

Words: an **experience** is the whole game (one entry in Creations). A **place** is one map inside it; this game has three (World 1, which is the start place and is already published; Frostbyte, World 2; the Home Planet). An **id** is the number Roblox gives each thing; the game's data tables hold those numbers, and `0` means "not published yet", which makes the game skip that feature safely.

## 1. Publish World 2 and the Home Planet as places inside the same experience

Why: the ship flies between places by teleport, and a teleport only works inside one experience. Do this once per place, World 2 first.

1. On the Mac, in Terminal, go to the repo folder and start Rojo for the place: `rojo serve world2.project.json` (later `rojo serve home.project.json`). Leave it running.
2. Open Studio. Home tab, **New** (a Baseplate is fine). Delete the Baseplate part in the Explorer (View tab, Explorer; right-click Baseplate, Delete). The game builds its own floor.
3. Plugins tab, **Rojo**, **Connect**. The Explorer fills with ReplicatedStorage > Shared, ServerScriptService > Server and so on. If the Rojo button is missing, install the Rojo plugin from the Creator Store (search "Rojo", by the Rojo team) and restart Studio.
4. File menu, **Publish to Roblox As...**. In the dialog, under your experiences, click the existing game (the one World 1 lives in), then choose the option to **create a new place inside it** (it is labelled "Create new place" or shown as a plus tile beside the existing places). Do not create a new experience. Name it "Frostbyte" (or "Home Planet"), then Create / Publish.
5. Get the place id: View tab, **Command Bar**, type `print(game.PlaceId)` and press Enter. The number appears in the Output. Copy it.
6. Put it in the table: `src/shared/data/Worlds.luau`, row `[2]` ends with `placeId = 0`; change the 0 to the number. The Home Planet goes in row `[0]`. Or paste both numbers to me.
7. Repeat for the Home Planet with `home.project.json`.

Check: back in the World 1 place, Play, finish the ship (`/complete` in the chat, then launch). With the id in place, the launch now teleports instead of saying "not published yet". Teleports do not run inside Studio's Play button; test it from the real game (Roblox app, your experience, Play), after you also push the data change and republish World 1 (step 1 with `default.project.json`, then File, **Publish to Roblox**, which republishes the same place).

Every time the code changes, each place needs republishing the same way (connect Rojo with that place's project, open that place in Studio, Publish to Roblox). A `World 1` republish is File, Publish to Roblox, while Rojo is connected with `default.project.json`.

## 2. Turn on Studio access to API services, then flip the save flag

Why: without it Studio uses throwaway in-memory saves. With it, Play sessions in Studio read and write the real saves, which is how we test the save migrations.

1. Creator Dashboard, Creations, click the experience, then **Settings** in the left column (it may read "Configure Experience").
2. Open **Security**. Turn on **Enable Studio Access to API Services**. Save.
   The same switch is in Studio: Home tab, **Game Settings**, Security.
3. In the repo, `src/shared/data/Config.luau`, find `UseDataStoreInStudio = false` and make it `true`. Or tell me and I will.

Warning: from then on, Playing in Studio with your own account edits your real profile. That is what we want for the migration test; a fresh profile for a clean run means playing with a different account.

## 3. Create the developer products and passes, and put their ids in the Shop table

Why: every Robux item in the game is a row in `src/shared/data/Shop.luau` with `productId = 0` or `passId = 0`. A 0 makes the Buy button refuse safely. The price in the table is what the game displays; Roblox charges whatever the dashboard says, so make both the same.

Developer products (one-time purchases): Creator Dashboard, the experience, **Monetization**, **Developer Products**, **Create**. Name, price, description, create. The id shows in the list (and in the product's page address). Create these, with these prices in Robux:

| Table row id | Name to type | Price |
|---|---|---|
| StarterPack | Starter Pack | 199 |
| DirectRare | A Rare alien | 99 |
| DirectEpic | An Epic alien | 199 |
| ModuleRush | Module Rush | 59 |
| RadarMk1Unlock | Radar Mk1 | 149 |
| SpeedBurstx5 | 5 Speed Bursts | 49 |
| SteadyHandsx3 | 3 Steady Hands | 79 |
| ScrapMagnetx3 | 3 Scrap Magnets | 99 |
| ServerLuck2x | Server Luck x2 | 249 |
| ServerLuck4x | Server Luck x4 | 999 |
| Spins1 | 1 Spin | 49 |
| Spins5 | 5 Spins | 199 |
| Spins12 | 12 Spins | 399 |

Passes (own once, keep forever): Creator Dashboard, the experience, **Monetization**, **Passes**, **Create a Pass**. Name and description, create. Then open the pass, **Sales**, turn **Item for Sale** on and set the price. The id is the number in the pass's page address.

| Table row id | Name to type | Price |
|---|---|---|
| CompanionSlot4 | +1 Companion | 249 |
| SlotEveryStation1 | +1 Slot at Every Station | 399 |
| SlotEveryStation2 | +2 Slots at Every Station | 799 |
| AutoCollect | Auto Collect | 199 |
| AutoOptimize | Auto Optimize | 299 |
| LongerOffline | Longer Offline Earnings | 299 |
| ExplorerPack | Explorer Pack | 399 |

Send me the twenty numbers as "row id: number" lines, or edit the table: each row's `productId = 0` or `passId = 0` takes its number.

Notes: the items marked paid random in the table (the two Server Luck products and the spins) already show their odds in the game and are hidden where Roblox requires it; nothing to set on the dashboard for that. Your Roblox account needs no special status to create products; cashing out Robux later does.

## 4. The group (optional, for the group gift)

The game offers a one-time gift for joining the team's Roblox group. With no group it stays hidden, so this can wait.

1. roblox.com, **Create a Group** (Roblox calls them communities on some pages). It costs 100 Robux.
2. Open the group's page. The number in the address bar after `/communities/` (or `/groups/`) is the id.
3. `src/shared/data/Social.luau`, `GroupId = 0` takes the id. Do not transfer the experience to the group now; that is a separate decision.

## 5. The game's name and store page

1. Creator Dashboard, the experience, **Basic Settings**: Name, Description, Genre. The name is what players see; pick it when you are ready, it can change later.
2. Icon and thumbnails live on the same page; those come with the visual pass.
3. In the repo, `Config.WorkingTitle = "AlienGame"` is only the prefix on log lines; I change it to match once the name is final.

## 6. Notifications

Nothing to do now. The in-game opt-in card is on by default (`src/shared/data/Social.luau`, `NotificationsEnabled = true`); tell me if you would rather it stayed off at launch. Sending actual notifications later needs a notification string created under Creator Dashboard, the experience, **Engagement**, **Notifications**; that is a later milestone.

## 7. Before the game goes public (later, after the visual pass)

1. Creator Dashboard, the experience, **Experience Questionnaire** (in the left column, under the settings). Answer it honestly; it sets the age rating. The game has paid random items (the spins and Server Luck), so say yes there.
2. Creator Dashboard, the experience, **Access**: Private until then, then Public (or Friends for a test weekend).

## 8. A two-player test in Studio (for the visiting milestone)

The Mac's Claude can drive one player at a time; visiting needs two in one server, and only Studio's own test mode starts that.

1. Terminal: `rojo serve home.project.json` in the repo folder.
2. Studio: open a new Baseplate (Home, New), delete the Baseplate part, Plugins, Rojo, Connect. The place must say it is the home world: in the Explorer click **Workspace**, in the Properties window scroll to **Attributes** and check **WorldId** reads 0. (A second Studio window connected to a different `rojo serve` can overwrite this; if WorldId reads 1, set it to 0 by hand.)
3. Test tab, in the **Clients and Servers** group pick **2 Players** in the dropdown, then **Start**. Studio opens one server window and two player windows.
4. Tell the Mac's Claude it is running; it drives the two players through `docs/TESTING.md` "Milestone 42e" steps 3 to 5, or you follow those steps yourself in the two windows (one is the owner, one the visitor).
5. Test tab, **Cleanup** closes the windows when done.

## 9. Codex's C4 summary

Paste the summary text into our chat when you have it. I review it, mark card C4 done in `docs/vault/02-how-we-work/Codex-Queue.md`, and hand Codex C5 to C7 (they are already written there).

## What to send me, in one message

- The two place ids (Home Planet, Frostbyte).
- "API access is on" once step 2 is done.
- The twenty product and pass ids as "row id: number" lines.
- The group id, if you made one.
- The name, if you picked one.
- "The two-player test is running" when you start one (section 8).

I put every number in the right table, run the checks, push, and republish nothing (republishing the places is yours, step 1; I tell you when a push needs one).
