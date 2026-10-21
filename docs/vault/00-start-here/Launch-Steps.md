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

## 2. Check the Open Cloud key (3 minutes)

1. Go to create.roblox.com, sign in, top menu **Open Cloud** (or the left column **Open Cloud > API Keys**).
2. Open the key you made for this game (named like `alien-game-assets`).
3. Under **Access Permissions** it needs:
   - **Assets**: Read and Write.
   - **Universe-places** (sometimes shown as "Place Publishing"): Write, with the experience **Catch an Alien** (universe 10769415131) selected. Add it with **Add API System** if it is missing.
4. **Expiration**: a date at least two weeks away. **IP allowlist**: `0.0.0.0/0` or your Mac's address.
5. Click **Save Changes**. Do not copy the secret anywhere; the Mac already has it in `~/.zshrc`. If you had to make a new key, put it on the Mac only: Terminal `nano ~/.zshrc`, replace the line `export ROBLOX_OPEN_CLOUD_KEY=...`, save, then `source ~/.zshrc`.

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
