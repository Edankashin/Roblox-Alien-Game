# Owner guide: everything only you can do

Written 2026-10-06 for someone new to Roblox Studio. Follow the parts in order. Each step names the window, the tab and the button. Tick the boxes as you go.

> **New (2026-10-07): most of this guide is about to stop being yours.** A 15-minute one-time setup in `docs/vault/02-how-we-work/Hands-Off.md` lets the Mac's Claude session and Codex take over the hands-on work of Parts A, C, D, E and H (publishing, shop items, two-player tests, Codex runs). After it, you answer the Mac's approval prompts, decisions, money, identity and legal steps, and play the game.

**Where to send things back:** this Claude conversation (the one that wrote this guide), in the Claude app or at https://claude.ai/code/session_01AXvT6QCi1wEkW64tWcXEt5. Every part ends with a ready-made message to copy, fill in and paste there. I do the code side from it: putting numbers in tables, checks, pushing.

## Contents

| Part | What | Time | Needed for |
|---|---|---|---|
| [0](#part-0-the-three-tools-you-will-use) | The three tools you will use | 5 min, read once | everything |
| [A](#part-a-publish-frostbyte-and-the-home-planet-as-places) | Publish Frostbyte and the Home Planet as places | 25 min | flying between worlds, visiting friends |
| [B](#part-b-turn-on-studio-access-to-saves) | Turn on Studio access to saves | 5 min | testing real saves |
| [C](#part-c-create-the-robux-products-and-passes) | Create the Robux products and passes | 35 min | the shop selling anything |
| [D](#part-d-the-two-player-visiting-test) | The two-player visiting test | 30 min | finishing the visiting feature |
| [E](#part-e-codex-the-next-cards) | Codex: the next cards | 5 min | the balance and test work |
| [F](#part-f-optional-the-group-and-the-name) | Optional: the group and the game's name | 15 min | the group gift, the store page |
| [G](#part-g-later-not-now) | Later, not now | none | launch |
| [H](#part-h-repeat-recipe-republish-a-place) | Repeat recipe: republish a place | 5 min each | whenever I say "republish" |
| [I](#part-i-if-something-goes-wrong) | If something goes wrong | as needed | |

---

## Part 0: the three tools you will use

**1. Terminal** (the Mac app for typing commands).
- Open it: press **Cmd + Space**, type `Terminal`, press **Return**.
- Every command in this guide starts by going into the game's folder. Type this and press Return:
  ```
  cd ~/Roblox-Alien-Game
  ```
- If it says "no such file or directory", the folder is somewhere else. Type this and press Return, then use the path it prints instead of `~/Roblox-Alien-Game` everywhere below:
  ```
  mdfind -name Roblox-Alien-Game | head -3
  ```
- To stop a command that keeps running (like `rojo serve`), click its Terminal window and press **Ctrl + C**.

**2. Roblox Studio** (the app that builds and publishes the game).
- Along the top are tabs: **Home**, **Model**, **Test**, **View**, **Plugins**. The **File** menu is in the Mac menu bar at the very top of the screen.
- Open these two windows once and leave them open (both from the **View** tab): **Explorer** (the tree of everything in the place) and **Properties** (the details of whatever you click in the Explorer). Also open **Output** (View tab, Output): it is where the game prints messages.
- **Command Bar**: View tab, **Command Bar**. A one-line box appears at the bottom. You type a line there and press Return.

**3. The Creator Dashboard** (the website where the game's settings and products live).
- Go to https://create.roblox.com/dashboard/creations and sign in as **EDankashin**.
- You see your experiences as tiles. Click the game's tile to open it. Its menu is the column on the left: Overview, Places, Monetization, and more. If a heading in that column is folded, click it to unfold.

**Words used below.** An **experience** is the whole game (one tile in Creations). A **place** is one map inside it. This game has three: World 1 (Verdant Crash Site, already published, the one players start in), World 2 (Frostbyte) and the Home Planet. An **id** is the number Roblox gives a thing.

**Rojo** copies the game's code from the folder on your Mac into Studio. It has two halves: `rojo serve` in Terminal and the **Rojo** button in Studio's **Plugins** tab. Only one `rojo serve` can run at a time.

**Before you start any part:** if the Mac's Claude window is open and working in Studio, type this into it first, so the two of you don't clash:
```
I'm doing the owner steps in Studio now. Stop any rojo serve you are running and leave Studio to me until I say I'm done.
```

---

## Part A: publish Frostbyte and the Home Planet as places

Why: the ship flies between worlds by teleport, and teleports only work between places inside the same experience. Visiting a friend's home needs the Home Planet place too.

You do this twice: first for Frostbyte, then for the Home Planet. The steps are the same except for two words, shown as **[Frostbyte / Home]**.

### A1. Find the experience (once)
- [ ] Open https://create.roblox.com/dashboard/creations. Find the tile for the game World 1 was published as (the Mac's Claude published it from Studio; the tile shows the game's current name). Remember its name; you pick it in step A5.
- [ ] If there is no tile at all, stop and send me: `Part A: there is no experience in Creations.` I'll give you the extra step.

### A2. Get the latest code
- [ ] Terminal:
  ```
  cd ~/Roblox-Alien-Game
  git pull
  ```
  It prints a list of changed files or "Already up to date". Either is fine. If it prints an error, see [Part I](#part-i-if-something-goes-wrong), "git pull complains".

### A3. Start Rojo for the place
- [ ] Terminal, for Frostbyte:
  ```
  rojo serve world2.project.json
  ```
  For the Home Planet (the second time through):
  ```
  rojo serve home.project.json
  ```
  It prints a line ending in `localhost:34872`. Leave this Terminal window open; Rojo runs as long as it is open.

### A4. Make an empty place in Studio and fill it
- [ ] Studio: **File** menu, **New**. A new window opens with a grey floor (called a Baseplate).
- [ ] In the **Explorer**, click the arrow next to **Workspace** to unfold it. Right-click **Baseplate**, choose **Delete**. If there is a **SpawnLocation**, delete it the same way. Leave **Camera** and **Terrain**.
- [ ] **Plugins** tab, click **Rojo**. A small Rojo panel opens showing `localhost` and `34872`. Click **Connect**. After a second it says connected, and the Explorer gains folders: ReplicatedStorage has **Shared**, ServerScriptService has **Server**.
- [ ] Check the world number. In the **Explorer** click **Workspace**. In the **Properties** window scroll to the bottom, to **Attributes**. **WorldId** must read **2** for Frostbyte, **0** for the Home Planet. If it reads anything else, click the number and type the right one.

### A5. Publish it into the experience as a new place
- [ ] **File** menu, **Publish to Roblox As…**
- [ ] In the window that opens, click the tile of the experience from step A1.
- [ ] Choose **Add as a new place** (do not pick an existing place: that would overwrite World 1). Name it **Frostbyte** or **Home Planet**. Click **Create**.
- [ ] If you don't see "Add as a new place": close that window and use the other route. **View** tab, **Asset Manager**. In it, open **Places**, right-click the empty space, choose **Add New Place**. Double-click the new place to open it, then repeat A4 inside that new window and use **File**, **Publish to Roblox** (without "As").

### A6. Copy the place id
- [ ] **View** tab, **Command Bar**. Click in it, type exactly this, press Return:
  ```
  print(game.PlaceId)
  ```
- [ ] A long number appears in the **Output** window. That is the place id. Copy it (select it, Cmd + C) into a note.

### A7. Close up
- [ ] Rojo panel: **Disconnect**. Terminal: press **Ctrl + C** to stop `rojo serve`.
- [ ] Close the Studio window. If it asks to save, choose **Don't Save** (the place is already on Roblox).
- [ ] Go back to A3 for the Home Planet. After both:

### A8. World 1's place id (the start place)
- [ ] Creator Dashboard, the game's tile, left column **Places**. You should see three places: the start place (World 1), **Frostbyte** and **Home Planet**. If Frostbyte or Home Planet is missing from this list, it was published as a separate game: tell me and I'll give you the fix.
- [ ] Hover over the start place, click its **⋯** button, choose **Copy Place ID** (or open it: the number in the address bar is the id).

**Send me:**
```
Part A done.
World 1 place id: ____________
Frostbyte place id: ____________
Home Planet place id: ____________
All three are listed under Places: yes / no
```
I put them in the game's world table and push. Then I tell you to republish World 1 once (Part H) so the start place knows where the other two are.

---

## Part B: turn on Studio access to saves

Why: right now every test in Studio uses a throwaway save that vanishes. With this on, Studio tests use real saves, which is how we test that old saves upgrade correctly.

- [ ] Open World 1 in Studio: Studio's start screen lists your recent games; click the game's tile, then its start place. (Or Creator Dashboard, the game's tile, **Places**, the start place, **Edit in Studio**.)
- [ ] **File** menu, **Experience Settings** (on some versions: **Home** tab, **Game Settings**).
- [ ] Click **Security** in the window's left column.
- [ ] Turn on **Enable Studio Access to API Services**. Click **Save**.
- [ ] Close Studio (Don't Save is fine).

What changes: from now on, playing in Studio as yourself reads and writes your real save. That is what we want before launch. Before the game goes public I switch testing to a separate copy (Part G), because Roblox warns against this setting on a live game.

**Send me:**
```
Part B done: Studio API access is on.
```
I flip the game's matching switch (`UseDataStoreInStudio`) and push.

---

## Part C: create the Robux products and passes

Why: every Robux item in the shop is a row in the game's shop table with its id set to 0, which makes its Buy button refuse safely. Each item needs creating on the dashboard once; then its id goes into the table.

Two kinds:
- **Developer products** can be bought again and again (boosts and spins). 9 of them.
- **Passes** are bought once and kept forever. 6 of them.

Only these fifteen are in the shop today. The game's table lists more (paid spins, direct-buy aliens, Module Rush and others); their features come later, and creating them now would put items on sale that grant nothing. I'll add a short list for them when they are built.

The pictures: every item uses an icon file that is already in the game's folder. When the upload window opens, press **Cmd + Shift + G**, paste the path from the table (for example `~/Roblox-Alien-Game/assets/icons/Gifts.png`), press Return, then click **Open**.

### C1. Developer products (do this 9 times)
- [ ] Creator Dashboard, click the game's tile. Left column: **Monetization**, then **Developer Products**.
- [ ] Click **Create developer product** (top right).
- [ ] Upload the image from the table. Type the **Name** and **Description** exactly as in the table. **Price**: the number in the table. Leave everything else as it is. Click **Create** (or **Save**).
- [ ] Back on the list, hover over the new product's picture, click the **⋯** button, choose **Copy Asset ID**. Paste the number into the "Send me" block below, next to its row id.

| Row id (for the Send me block) | Name to type | Price (Robux) | Description to type | Image |
|---|---|---|---|---|
| StarterPack | Starter Pack | 199 | A Rare alien of your choice, Speed Boots now, 5 spins and a hoverboard skin. Once per account. | `~/Roblox-Alien-Game/assets/icons/Gifts.png` |
| SpeedBurstx5 | Speed Burst x5 | 49 | Five Speed Bursts for your power-up bar. | `~/Roblox-Alien-Game/assets/icons/SpeedBurst.png` |
| SteadyHandsx3 | Steady Hands x3 | 79 | Three Steady Hands: wider catch zones for ten minutes each. | `~/Roblox-Alien-Game/assets/icons/SteadyHands.png` |
| ScrapMagnetx3 | Scrap Magnet x3 | 99 | Three Scrap Magnets: more Scrap per catch for ten minutes each. | `~/Roblox-Alien-Game/assets/icons/ScrapMagnet.png` |
| ServerLuck2x | Server Luck x2 | 249 | Doubles everyone's luck on this planet for 15 minutes. | `~/Roblox-Alien-Game/assets/icons/LuckyCharm.png` |
| ServerLuck4x | Server Luck x4 | 999 | Four times everyone's luck on this planet for 15 minutes. | `~/Roblox-Alien-Game/assets/icons/LuckyCharm.png` |
| Spins1 | 1 Spin | 49 | One spin of the prize wheel. Every prize and its odds are shown on the wheel. | `~/Roblox-Alien-Game/assets/icons/Gifts.png` |
| Spins5 | 5 Spins | 199 | Five spins of the prize wheel. Every prize and its odds are shown on the wheel. | `~/Roblox-Alien-Game/assets/icons/Gifts.png` |
| Spins12 | 12 Spins | 399 | Twelve spins of the prize wheel. Every prize and its odds are shown on the wheel. | `~/Roblox-Alien-Game/assets/icons/Gifts.png` |

### C2. Passes (do this 6 times)
- [ ] Creator Dashboard, the game's tile. Left column: **Monetization**, then **Passes**.
- [ ] Click **Create a pass**. Upload the image, type the **Name** and **Description** from the table, click **Create Pass**.
- [ ] Set the price: on the passes list, click the new pass to open it. In its left column click **Sales**. Turn on **Item for Sale**. Type the price from the table into **Price in Robux**. Click **Save Changes**.
- [ ] Back on the passes list, hover over its picture, click **⋯**, choose **Copy Asset ID**. Paste it into the block below.

| Row id (for the Send me block) | Name to type | Price (Robux) | Description to type | Image |
|---|---|---|---|---|
| SlotEveryStation1 | +1 Slot on Every Station | 399 | One more alien working at every station, forever. | `~/Roblox-Alien-Game/assets/icons/Ship.png` |
| SlotEveryStation2 | +2 Slots on Every Station | 799 | Two more aliens working at every station, forever. | `~/Roblox-Alien-Game/assets/icons/Ship.png` |
| CompanionSlot4 | +1 Companion | 249 | One more alien can follow you around, forever. | `~/Roblox-Alien-Game/assets/icons/Aliens.png` |
| StorageBoost | +100 Alien Storage | 149 | Room for 100 more aliens in your storage, forever. It stacks with the Storage Bay. | `~/Roblox-Alien-Game/assets/icons/Aliens.png` |
| AutoOptimize | Auto-Optimize | 299 | Every new alien goes straight to its best station. | `~/Roblox-Alien-Game/assets/icons/Aliens.png` |
| ExplorerPack | Explorer Pack | 399 | Speed Boots, the Hoverboard and Radar Mk1 right now. Same speed as earning them. | `~/Roblox-Alien-Game/assets/icons/Hoverboard.png` |

Server Luck and the spins are paid random items in Roblox's rules: the game already shows their odds (a spin tile opens the wheel, which lists every prize with its odds) and hides them in countries that restrict them. Nothing to set for that on the dashboard.

**Send me** (fill in every blank; it's fine to send it in two halves):
```
Part C done.
StarterPack: 
SpeedBurstx5: 
SteadyHandsx3: 
ScrapMagnetx3: 
ServerLuck2x: 
ServerLuck4x: 
Spins1: 
Spins5: 
Spins12: 
SlotEveryStation1: 
SlotEveryStation2: 
CompanionSlot4: 
StorageBoost: 
AutoOptimize: 
ExplorerPack: 
```

---

## Part D: the two-player visiting test

Why: visiting a friend's home needs two players in one server, and only Studio's own test mode can start that. The Mac's Claude can drive one player at a time, so you do this one by hand. It's a short play session with a script.

### D1. Start the test
- [ ] Terminal:
  ```
  cd ~/Roblox-Alien-Game
  git pull
  rojo serve home.project.json
  ```
- [ ] Studio: **File**, **New**. Delete **Baseplate** and **SpawnLocation** from Workspace (as in A4). **Plugins**, **Rojo**, **Connect**. Click **Workspace** and check **WorldId** reads **0** in Properties, Attributes.
- [ ] **Test** tab. Find the test-mode dropdown (it may say **Server & Clients**, or there is a group called **Clients and Servers**). Set it to **Server & Clients** and the number of players or clients to **2**. Click **Start** (or the **Play** button, or press **F7**).
- [ ] Three new windows open: **Server**, **Player1** and **Player2**. Arrange them side by side. Player1 is the owner, Player2 the visitor.

How to type a chat command: in a player window, click the chat bubble at the top left, click in the text box, type the command (including the `/`), press **Return**.

### D2. Set up Player1's home (in the Player1 window)
- [ ] Type these four commands, one at a time:
  ```
  /scrap 5000
  /world 0
  /outpost 1
  /dupes Mossbop 1
  ```
- [ ] Walk (W A S D keys) toward the sand-coloured square past the camp. When the round button at the bottom right reads **Decorate**, click it. A tray opens along the bottom.
- [ ] In the tray, scroll down to the **Habitats** row. Click **Verdant Habitat**, then click a free spot on the sand square: a see-through ghost appears. Click the ghost to place it. Toast: "Verdant Habitat placed".
- [ ] If no ghost appears: (1) check the card you clicked now has a thick gold border and the hint line in the tray reads "Tap a spot on the plot to place it" (if not, click the card again); (2) the camera should glide over the plot when the tray opens so the whole sand square shows above the tray (added after your report); if part of the square is still behind the tray, click on the part you can see, and tell me; (3) look in **Player1's own Output** (the Player1 window, View tab, Output): each ignored click prints a line starting `Build tap ignored:` that says why. Copy that line and send it to me with the Part D results.
- [ ] In the **Rooms** row, click **Cabin**, click another free spot, click the ghost. Click **Done**.
- [ ] Left menu, click **Aliens** (the button marked A). Find the **Mossbop** card and click its purple **Display** button. Toast: "Mossbop is on display". Close the screen (red X). The Mossbop now walks around inside the habitat's fence.

### D3. Visit (in the Player2 window)
- [ ] Type `/world 0` in chat.
- [ ] Left menu, **Ship** (the ^ button), then the **Star Chart** button. Click the small planet in the centre of the map (Home). On its card, click **Visit**.
- [ ] "Visit a friend" opens. Under **In this server**, next to **Player1**, click **Visit**.
- [ ] Check in Player2: toast "Welcome to Player1's home!"; the chip at the top right reads "Player1's home"; Player1's cabin and habitat stand on the sand square; the Mossbop walks in the habitat; a small ship stands on a grey pad behind the camp.
- [ ] Check in Player1: toast "Player2 came to see your home".

### D4. Wave (Player2)
- [ ] Walk up to the Mossbop in the habitat. The bottom-right button reads **Wave**. Click it. Player2: toast "You waved at Player1's Mossbop (+5 Scrap)". Player1: toast "Player2 waved at your Mossbop (+5 Scrap)".
- [ ] Click **Wave** again: "You already waved at this one".
- [ ] Walk to the sand square: the button never reads Decorate. Walk to the blue mailbox on the right side of the camp: the button never reads Mail.

### D5. The lock (both windows)
- [ ] Player1: the gear button at the top right (**Settings**). Row "Who can visit your home": click **Only me**.
- [ ] Player2: Ship, Star Chart, the Home planet, **Fly**. Toast "Back at your own home"; the chip reads "Home".
- [ ] Player2: Star Chart, Home, **Visit**, Player1, **Visit**: "Player1's home is closed to visitors".
- [ ] Player1: Settings, click **Anyone**. Player2: Visit Player1 again: welcome toast.
- [ ] Player2: type `/visit off`. Back at its own home.
- [ ] Player1: walk to the blue mailbox, click **Mail**: "Visitors" lists Player2.

### D6. Collect the results and end
- [ ] Take a screenshot of the Player2 window while it shows "Player1's home": press **Cmd + Shift + 4**, drag a box around the window. The picture lands on your Desktop.
- [ ] In the **Server** window: **View** tab, **Output**. Click inside the Output, press **Cmd + A** then **Cmd + C**.
- [ ] End the test: **Test** tab, **Stop** (or **Cleanup**). Terminal: **Ctrl + C**.

**Send me:** paste the copied Output, drag the screenshot into the chat, and add:
```
Part D done. Anything that didn't match the guide: ____________
```

---

## Part E: Codex, the next cards

Codex finished C1 to C4; I reviewed C4 and opened C5, C6 and C7.

- [ ] Open Codex the way you did before, in the game's folder.
- [ ] If it is a new Codex session, open `docs/vault/02-how-we-work/Codex-Prompt.md` in the game's folder, copy everything between the two lines of three backticks, and paste it into Codex first.
- [ ] Then type:
  ```
  Take the next open card.
  ```
- [ ] When it reports, paste its message here. To let it do the following card, type `next` to Codex. It stops after each card on its own.

---

## Part F: optional, the group and the game's name

### F1. The group (optional; skip it if you don't want one yet)
The game gives a one-time gift for joining the team's Roblox group (Roblox now calls groups "communities"). With no group the gift stays hidden.
- [ ] On roblox.com, open the menu, **Communities**, **Create Community**. It costs 100 Robux.
- [ ] Open your new community's page. The address bar reads like `roblox.com/communities/12345678/Name`: the number is the id.
- [ ] Do not move the game into the group now; that is a separate decision for later.

**Send me:** `Group id: ____________`

### F2. The name
- [ ] Creator Dashboard, the game's tile, left column **Basic Settings** (under **Configure** if it is folded). Type the **Name** and a **Description**. Click **Save**. You can change both later.

**Send me:** `Name: ____________` (I use it in the game's log lines.)

---

## Part G: later, not now

These come after the visual pass. I'll tell you when; they're listed so nothing is a surprise.
- **Icons upload:** the Mac's Claude asks for your yes before it uploads the game's images to Roblox. When it asks, the answer is yes.
- **Sounds:** about 40 sound ids, chosen with your collaborator.
- **The other ten shop items** (direct-buy aliens, Module Rush, Radar Mk1, Auto Collect): created the same way as Part C once each feature is built.
- **The age questionnaire:** Creator Dashboard, the game, **Experience Questionnaire**. The game has paid random items (spins, Server Luck): answer yes there.
- **The test copy:** before going public, I set up testing on a copy of the game and you switch off Studio API access on the live one (Part B, the same switch, turned off).
- **Going public:** Creator Dashboard, the game, **Access** (or **Privacy**), switch from Private to Public.

---

## Part H: repeat recipe, republish a place

When I say "please republish World 1" (or Frostbyte, or the Home Planet), it means the code changed and the copy on Roblox needs updating. You can also just ask the Mac's Claude to do it.

| Place | Project file |
|---|---|
| World 1 | `default.project.json` |
| Frostbyte | `world2.project.json` |
| Home Planet | `home.project.json` |

- [ ] Terminal: `cd ~/Roblox-Alien-Game`, then `git pull`, then `rojo serve` followed by the project file from the table (for example `rojo serve default.project.json`).
- [ ] Studio: open that place. Studio's start screen, the game's tile, then the place. (Or open World 1, then **View**, **Asset Manager**, **Places**, double-click the place.)
- [ ] **Plugins**, **Rojo**, **Connect**. Check **WorldId** on Workspace: 1 for World 1, 2 for Frostbyte, 0 for the Home Planet.
- [ ] **File**, **Publish to Roblox** (not "As").
- [ ] Rojo **Disconnect**, Terminal **Ctrl + C**, close Studio with **Don't Save**.

---

## Part I: if something goes wrong

**Terminal says `rojo: command not found`.** Type this, then try again:
```
export PATH="$HOME/.rokit/bin:$HOME/.local/bin:$PATH"
```
If it still fails, type into the Mac's Claude window: `Start rojo serve <the project file> for me in the repo and leave it running.`

**Terminal says "address already in use" (or port 34872 is busy).** Another `rojo serve` is running. Find its Terminal window and press **Ctrl + C**. If you can't find one, type into the Mac's Claude window: `Stop any rojo serve you are running.`

**The Rojo panel won't connect.** Check the Terminal with `rojo serve` is still open and shows `localhost:34872`. In the Rojo panel the address must be `localhost` and the port `34872`.

**`git pull` complains about local changes.** Type into the Mac's Claude window: `Commit or stash your local changes, then pull claude/alien-system-research.` Then run `git pull` again.

**WorldId reads the wrong number.** Click **Workspace** in the Explorer, scroll the Properties to **Attributes**, click the number, type the right one (1, 2 or 0), press Return. A second Studio window connected to Rojo can change it; keep only one Studio window connected at a time.

**The publish window has no "Add as a new place".** Use the Asset Manager route in step A5.

**Studio asks you to sign in, or the experience tile is missing in the publish window.** Make sure Studio is signed in as EDankashin: the account picture at the top right of Studio.

**A player window shows errors in red in the Output.** Copy the whole Output (click in it, Cmd + A, Cmd + C) and paste it to me with one line saying which step you were on.

**Anything else.** Send me the part and step number and what you see; a screenshot helps (Cmd + Shift + 4).

---

Sources for the Roblox steps: [publishing places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places), [developer products](https://create.roblox.com/docs/production/monetization/developer-products), [passes](https://create.roblox.com/docs/production/monetization/passes), [Studio access to API services](https://create.roblox.com/docs/cloud-services/data-stores), [multi-client testing](https://create.roblox.com/docs/studio/testing-modes). Roblox renames buttons now and then; when a label differs a little, the nearest match is the one.
