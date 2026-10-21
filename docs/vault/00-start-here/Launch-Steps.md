---
tags: [start-here, launch, how-to]
aliases: [Launch steps, Your launch steps]
up: "[[Launch-Dashboard]]"
---
# Your launch steps, one by one

2026-10-21, for Ethan, from [[Launch-Dashboard]] "Launch week" ([[Decisions]] B49). Each step says where to click and what to type. Do 1 first: everything on the Mac waits on it.

## 1. Start the Mac session on the queue (5 minutes, then it runs by itself)

The cloud session cannot message your Mac's Claude session (Roblox Studio and the API key live there), so you start it.

1. On the Mac, close every Roblox Studio window but one (File > Close, Don't Save).
2. Open the Mac's Claude Code session for this repo (Terminal: `cd ~/Roblox-Alien-Game && claude`, or the Claude app's session for it).
3. Paste this and press Return:
   ```
   Pull claude/alien-system-research, then work through docs/vault/02-how-we-work/Overnight.md in order: job 41 first (download the three TikToks), then job 40 (tools/finalize_upload.sh), then the Studio jobs 39, 38, 37, 36 and every open job from 42 up. Commit and push after each job and log it.
   ```
4. Optional, saves you doing this again: when the cloud session shows a card asking to let it reach your other sessions, approve it on your phone or Mac. Then the cloud session can message the Mac session itself.

## 1b. Connect Roblox Studio to the Mac session (5 minutes; the Studio checks wait on it)

The Mac session uploaded everything, but it has no Studio tools, so it cannot run the Studio checks (jobs 36 to 39 and 42 to 52). On the Mac:

1. Open Roblox Studio and open any place (the Assistant button only appears with a place open). Keep it to one Studio window.
2. Click **Assistant** (the purple atom icon, top right) > the **three dots** > **Manage MCP Servers** > **MCP Servers** > turn on **Enable Studio as MCP server**.
3. In the Terminal window where the Mac's Claude session runs, type `/mcp` and press Return. You want one line `Roblox_Studio` marked connected. In Studio's MCP page, the green dot says "1 client connected".
4. If `/mcp` does not show it: quit that Claude session (`/exit`), then in Terminal run these three lines, one at a time:
   ```
   claude mcp remove Roblox_Studio -s local
   claude mcp remove Roblox_Studio -s user
   cd ~/Roblox-Alien-Game && claude
   ```
   When it asks to use the project's MCP server from `.mcp.json`, answer **yes**. (Either remove line may say "not found"; that is fine.)
5. Tell that session: `Studio is connected. Pull, then run the open Studio jobs in Overnight.md in order, starting with job 40's last step.`

## 2. Finish the Open Cloud key (5 minutes)

You already added **universe-places** with **Write**. The rest, on the same key page (create.roblox.com > Open Cloud > API Keys > your key):

1. In the **universe-places** row, find the experience picker (labelled **Select Experience**, or a **Restrict by Experience** switch). Turn the restriction on and choose **Catch an Alien**. Leave the operation as **Write**.
2. Make sure there is also an **Assets** row. If not: click **Select API System** (or **Add API System**), choose **Assets**, then in **Select Operations** tick **Read** and **Write**. Assets has no experience picker.
3. **Security**: leave **Restrict IP addresses** off (your Mac's address changes; Roblox says leave it off if you have no fixed IP).
4. **Expiration**: pick a date at least two weeks away, or no expiration.
5. Click **Save Changes** (or **Save & Generate key** if this is a new key).
6. Only if Roblox showed you a new secret (a new key, or after **Regenerate Key**): on the Mac open Terminal and paste this one line; it asks for the key without showing it, then saves it:
   ```
   read -s "K?Paste the new key and press Return: " && sed -i '' '/ROBLOX_OPEN_CLOUD_KEY/d' ~/.zshrc && echo "export ROBLOX_OPEN_CLOUD_KEY=$K" >> ~/.zshrc && unset K && source ~/.zshrc && echo " saved"
   ```
   If you only edited the existing key, skip this: the Mac already has it.

If the page will not let you change an existing key's experience, make a new key (**Create API Key**, name `alien-game-launch`, both rows as above, **Save & Generate key**) and do step 6.

## 3. The five shop items without ids: nothing to do

DirectRare, DirectEpic, AutoCollect, ModuleRush and RadarMk1Unlock are rows in the shop table, but no game feature is wired to them yet (checked 2026-10-21: nothing in the code grants them). Creating them on the dashboard would sell items that give nothing, so do not. With an id of 0 the game hides them; the pre-launch audit makes sure of that. The 15 items that work are already created and on sale.

## 4. Pick the icon and thumbnails (5 minutes)

1. The coordinator sends a new set in the block-cell look (one icon, about six thumbnails) and puts it in `media/store/2026-10-22/`.
2. Reply with your picks in order, for example: `icon A, thumbs 3, 1, 5, 2`.
3. On launch morning you upload them (step 6).

## 5. Ten minutes on your phone (after the Mac publishes the private places)

1. The Mac session says "published" in its log (or the coordinator tells you).
2. On your phone, open the Roblox app, **Create > your experiences**, or search your profile's Creations for **Catch an Alien**, and press Play (it is private, so only you and collaborators can join).
3. Play for ten minutes: walk out of the camp, catch three aliens, open the Aliens and Shop screens, walk into the Starhollow Forest, and find a rare one if you can.
4. Send the coordinator anything that felt wrong, slow, confusing, too small to tap or ugly, as plain notes. A screenshot helps (power + volume up on iPhone).

## 6. Launch morning (about 20 minutes)

Creator Dashboard (create.roblox.com) > **Creations** > **Catch an Alien**. Every value is in `docs/STORE-PAGE.md` section 5d; in order:

1. **Basic Settings**: Name `Catch an Alien`; Description: paste section 2 of STORE-PAGE as is, plus the LAUNCHWEEK line; Genre **Adventure**; Devices: Computer, Phone, Tablet on, Console and VR off. **Save**.
2. **Icon**: upload your pick. **Thumbnails**: upload your picks in your order. **Save**.
3. **Places > World 1**: Max players **8**.
4. **Access**: Private servers off, Paid access off. **Communication**: chat on.
5. **Monetization > Passes** and **Developer Products**: each shows **For sale**.
6. **Experience Questionnaire** (left column, under Audience or Maturity): answer from STORE-PAGE 5d: no realistic violence, no fear, no romance, crude humour or alcohol; paid random items **yes** (spins and eggs, odds shown in game); free-form text chat yes. Submit; the rating should come back All ages or 9+.
7. **Events** (Creator Hub > Events): optional on day 1.
8. **Privacy**: set **Public**. This is the launch.
9. Tell the coordinator `public`. It watches the first day's numbers with you (STORE-PAGE 5b).

## Optional

- The group Moop Games (100 Robux): roblox.com > Groups > **Create Group**; name, emblem and description in [[Group-Page]]. The game can launch under your account and move later.
- Music: play the place with sound on and say which tracks to swap.
