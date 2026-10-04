# Reference video notes

Seven TikToks sent as references, processed with `tools/watch_video.py` (one frame per second into contact sheets, Whisper transcript). Every sheet and transcript was read. Outputs are in `media/tiktok/out/<code>/`. The videos are about *building* Roblox games with AI tools, not about game design, so the lessons go into the build plan (`docs/PRE_PRODUCTION.md`, section 10).

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLRKPFKv | www.lemonade.gg | 0:44 | Top 5 Studio plugins pro devs use |
| ZPLRKjEf2 | machv10 | 1:15 | Co-play is the metric the algorithm rewards |
| ZPLRKfLP1 | andythropic (Andy Vu) | 2:34 | How a Roblox game was vibe-coded with Claude Code over three months |
| ZPLRw3ubt | lihfolk | 3:25 | AI 3D model, VFX and animation generation for Roblox with Claude |
| ZPLRwG4Co | cuhfilme | 1:53 | Setting up an Obsidian knowledge vault so Claude remembers your standards |
| ZPLRwXx6J | cuhfilme | 2:30 | Training Claude to make good-looking Roblox UI |
| ZPLRwqGrt | cuhfilme | 1:50 | Connecting Claude Code to Roblox Studio through MCP |

---

## ZPLRKPFKv: plugins pro developers actually use

**Said:** "I asked famous Roblox developers what plugins they actually use."

**Shown, in countdown order:**
5. **GapFill and ResizeAlign** (Stravant). Parts never align perfectly; GapFill closes any hole in one click, ResizeAlign snaps parts together with precision. "All the devs had these two." Demo: two offset slabs, gap filled; zig-zag wall joints aligned with the Resize method panel (Outer Touch, Inner Touch, Wedge, Rounded, Butt Joint, Extend).
4. **Brushtool 2.1.** Paint objects across a map instead of placing one by one. Demo: trees and rocks scattered over grass in one drag.
3. **Redupe** (Stravant, "REpeated DUPlicate"). Drag a handle and an array builds itself. Demo: lamp posts along a road. Panel shows Place [5] copies, Stamp and Repeat, Alignment or Count, copy spacing, extra padding, rotation between copies, Automatic ResizeAlign.
2. **Archimedes v3.1.9.** Curved shapes: roads, arches, circular rooms with exact angle and segment count, "Render All."
1. **Lemonade.gg.** An AI plugin that connects to Studio, reads the game, and scripts from a text prompt. Demo prompt "Make a talking NPC" produced an NPC with a dialogue bubble. Note: the account posting the video is Lemonade's own, so item 1 is self-promotion.

**Takeaway for us:** install the four Stravant-era tools before building a single biome. Redupe is the tool for station rows, fence lines and codex pedestals; Brushtool for scattering biome props; Archimedes for round camp pads and curved ship hull pieces; GapFill for the ship's modular seams.

---

## ZPLRKjEf2: co-play

**Said (talking head, no visuals):** Co-play, playing with friends, is a metric most developers never think about. "The Roblox algorithm really loves games that include a lot of co-play." Their past games did worse when co-play was low. Steal a Brainrot has endless co-play and "player-induced events," so there is something new every day. Their game "My Singing Brainrot" came close to number one and co-play was one of the small things that stopped it.

**Takeaway for us:** co-play has to be designed in, measured, and surfaced, not assumed. See the addition to `docs/GAME_DESIGN.md` section 13.

---

## ZPLRKfLP1: vibe-coding a Roblox game with Claude Code

**Shown:** the game "Make a Military Army!" (98% rating, about 2.3K active at the time); a Claude Code terminal (Opus 4.7, Claude Max); a joke prompt "MAKE ME A ROBLOX GAME!!!"; the Rojo logo; two YouTube tutorials for Rojo setup; the real example prompt; the GitHub repo "Agentic Coding for Beginners"; the creator's site with a resources page.

**Said:**
- Not a one-shot. About three months of "debugging, testing, breaking things, fixing things, slowly building system by system."
- **Rojo** lets you code for Roblox Studio from any editor (VS Code, Cursor). Open the project in the editor, open the terminal, run Claude Code (or Codex, Gemini, whatever).
- The biggest mistake is asking for the whole game at once. Give small, specific tasks. The on-screen example, verbatim:

  > inside StarterGui.MainGui.Button, make it so when the player clicks the button, it triggers this action. put the client code in the right place, use a remote event if the server needs to handle anything, and explain where each script goes

- That works better than "make me a UI system" because Roblox has client scripts, server scripts, remote events, ReplicatedStorage, StarterGui, ServerScriptService, and everything has to be in the right place.
- Workflow loop: tell Claude what you want, it writes a first version, test in Studio, when it breaks copy the error back and explain what you clicked and what happened, tell it what to fix.
- "An AI coding partner that can write code faster than you, but you still need to understand what's going on enough to test it, guide it, and debug it."
- Start with one button, one UI, one system at a time.
- Free resource: `github.com/adv-andrew/agentic-coding-for-beginners`. We cloned it. Its useful parts: be specific, tell the tool what is going on, ask it to explain fixes, plan before building for big features, and "the one file that changes everything," a `CLAUDE.md` in the project root with rules, structure and how to run.

**Takeaway for us:** this is the exact workflow in `docs/PRE_PRODUCTION.md`, now made concrete: Rojo project, `CLAUDE.md` at the root, one system per prompt, prompts that name the instance path and say where scripts go, errors pasted back with the action that caused them.

---

## ZPLRw3ubt: AI model, VFX and animation generation

**Shown:** a dark 3D preview viewer with a generated sword wrapped in white-blue particle VFX and a file tab "roblox setup .lua"; a Notepad window inside Roblox Studio with the prompt; a second generated sword (teal, "lantern" themed); an enemy called "enemy-nullmantis" (neon purple and cyan) in the viewer with animation buttons Taunt, Dash, Block, Dodge, Stagger, Stun, Knock-up, Caught in ult, Death, and a file "roblox installer .lua."

**Said:**
- "Blender or Claude Design? Claude Design." Simpler workflow, and driving Blender through Claude uses far more tokens for a minimal difference in result. Needs a paid Claude subscription.
- The initial prompt, verbatim from the screen:

  > generate me a roblox ready sword with vfx, 4 attack animations , 1 basic slash, 2 advanced attacks, 1 super (ultimate move) attack, use heavy vfx, very flashy, vibrant and animated movements. make player animations fluid and agile, quick with the same color lightning movement as the weapon. Make the weapon insanely cool, a blade with animation people have not seen before, ensure all VFX settings are good to go through roblox, I want this to import 1:1. Go! 10000x cooler!

- Later removed attack animations from the prompt and generated blades only, doing animations separately.
- For enemies: say "Roblox ready," describe the game, the setting, the map, the theme of the enemy, and the animations wanted (block, dodge from any side, hits from different angles, stagger, stun, knock-up, death, spawn).
- **Tell Claude to ask you as many questions as it can first.** Can generate ten at once. Ten enemies used about 30% of the usage allowance.
- Animations: ask for a Lua installer, paste it into the Studio command bar (or hand it to Claude through MCP). It rigs the model and imports the animations. Then ask Claude (or Codex, or any tool) to wire it up.

**Takeaway for us:** a creature pipeline that a two-person team can run: one prompt per species with the body rules from `GAME_DESIGN.md` section 15, idle, walk, work-at-station, catch-reveal and ride animations, a `.lua` installer per species, then a wiring prompt. We should verify the current name and availability of the generation tool before relying on it; the video calls it Claude Design.

---

## ZPLRwG4Co: an Obsidian vault so Claude remembers

**Shown:** the creator's own game (a tropical sea-creature egg game: Egg Scout stand, Sell, Index 8/10 with a $1M reward, Rebirth, Shop with Ancient Egg and Titanic Egg, Passes, Cash); the Obsidian download page; the vault itself.

**Vault structure (read from the frames):**
- `00 Start Here` with Glossary and Home
- `01 Game Design`
- `02 How We Work`
- `03 Studio And MCP`
- `04 Roblox Engine`
- `05 UI Design` with `refs/` (ad-popup, hud-buttons, luck-board, sell-dialogue, stud-passes, stud-pet-index, stud-shop-cash, stud-shop-featured, stud-shop-upgrade, stud-timers, wood-cash-cards, wood-food-shop, wood-gamepass-card, wood-index, wood-shop-egg-banners), UI Checklist, UI Kit, UI Playbook, UI Recipes, User UI Taste
- `06 Art Pipelines` with Blender Pipeline (running Blender headless, FBX export settings that work, getting mesh data from Studio into Blender, rebuilding a skinned mesh as glTF, what happens on import to Roblox), Importing User Art, Open Cloud Upload API (a supported-types table: model, animation, decal, audio, video, mesh)
- `07 Ride The Ocean` (their game) and `08 Other Projects`

**Glossary rows visible:** Promise, FTUE / first 10 minutes, Funnel, Bounce, Play-through, D1 / D7 / D30, Cohort, Co-play, LiveOps, Three-goal ladder, Source / sink, Prestige / rebirth, Paid random item. Each row has a one-line meaning and a link to a numbered design note (02 The Engagement Model, 05 First 10 Minutes, 08 Progression and Content Pacing, 09 Retention and LiveOps, 10 Social Systems, 12 Economy, 15 Discovery and Thumbnails, 17 Monetization and Trust, 24 Experiments and Open Questions).

**UI Playbook excerpts visible (the level of detail that makes it work):**
- Close button: red, square-ish, white X with a black stroke, about 80% of the header's height, top right, always the same place on every panel.
- Body scrolls with a thin dark scrollbar on the right. Nothing touches the frame: at least 2% inner margin all round.
- Stud header: bright colour (shop green `#51DF51`, index blue `#68C9FE` to `#89ACFE`), studs at about 10% contrast, two or three diagonal lighter stripes (about `#7CE977`, about 60 degree lean) grouped between 40% and 70% of the width. Static.
- Section heading: "— FEATURED —", "— PASSES —" in yellow `#FFEF4A` text with a black stroke, centred, about 7% of panel height, the dashes are part of the text. The wood dialect uses a big cream word with a dark-brown stroke ("Gamepasses") or a green word with a dark-green stroke ("Cash").
- Featured egg banner: full width, aspect about 2.6:1, an illustrated background themed to the egg, darkened.
- Collection index: cells coloured by rarity (common grey `#6F6F6F`, uncommon green `#57F96C`, rare blue `#825AFD`, epic magenta).
- Big pack: red to rainbow moving gradient, a struck-through "was" price in red above.
- Two UI "dialects" are named throughout: **stud** (bright stud texture, as in Steal an Egg) and **wood** (parchment and planks).

**Said:** Obsidian is a local note app. Link Claude to the vault and it writes down everything it learns and remembers how you want things done. The vault was written by Claude. "Every model was made by Claude, all these pet models, all the sea creatures." Starting a new project, it already knows how you like things to look.

**Takeaway for us:** a knowledge vault is the mechanism that turns "train Claude on good UI" into something repeatable. We keep ours inside the repo as markdown so every session, cloud or local, reads it. Structure in `docs/PRE_PRODUCTION.md` section 10.

---

## ZPLRwXx6J: training Claude to make good UI

**Shown:** the creator's game with its wood-dialect shop (Featured Ancient Egg with odds, Titanic Egg, Passes, Cash), Pets and Eggs side panels, a Rebirth panel; the Roblox charts page; **Steal an Egg**'s store page and in-game UI: a stud-dialect Shop with "— FEATURED —" Extinction Egg (timer 9d 15h, per-pet odds, Robux prices 3499 / 799 / 249 / 99), "— PASSES —" (x2 Growth 467, x2 Money 399), "— SPEED —" (x1 to x2), speed and money bundles, "Upgrade Treadmill" card, a Pet Index with rarity-coloured cells, "1/8", "Unlocked: 1/104" and a green "CLAIM!" button; the HUD with a left icon stack (Rebirth, Index, Shop), a "Friend Boost +0%" readout, cash bottom left, a pet bar at the bottom; Studio's device emulator switching between iPad and iPhone 7 with the UI staying in place.

**Said:**
- "Claude sucks at making UI for Roblox games unless you know how to do it correctly." Untrained, it produces something "really not that intuitive."
- Load the most popular game similar to yours (Steal an Egg at the time). Notice the stud texture, the clean shop icons. "It's the most popular game, so obviously it works."
- Take screenshots and give them to Claude, or better, build your own UI in Studio first (learn ScreenGui) and show it to Claude so it sees how you did it. Then correct it until it gets it right.
- **Use Scale, never Offset, for Position and Size.** With Offset the UI looks different on every device; with Scale an iPad and an iPhone 7 show every button where it belongs.
- Once results are good, tell Claude to save what it learned into the vault.

**Takeaway for us:** a `refs/` folder of named screenshots, a UI Playbook written to the level of hex codes and proportions, a Scale-only rule in `CLAUDE.md`, and a device-emulator check (iPhone SE size and iPad) on every screen. This matches `GAME_DESIGN.md` section 16 and gives it a training procedure.

---

## ZPLRwqGrt: connecting Claude Code to Roblox Studio

**Shown:** Studio's AI Assistant panel, its settings dialog with "Enable Studio as MCP server" and a Quick connect list (ChatGPT (codex), Claude Code CLI, Claude Desktop, Cursor) with toggles; the Claude desktop app Settings, Developer, Local MCP servers, an entry "Roblox_Studio" with a command and arguments path; the Codex and Claude download pages; a finished island map in Studio at the end.

**Said, as steps:**
1. Choose the AI (ChatGPT/Codex, Claude Code, or Gemini). Install the desktop app.
2. In Studio, click the AI Assistant button (two buttons left of the profile picture), then the three dots, then Settings, then MCP servers.
3. Turn on "Enable Studio as MCP server." Under Quick connect, toggle the client you use.
4. In the Claude desktop app, Settings, Developer, Local MCP servers: the Roblox Studio entry should appear; toggle it on until it says running.
5. Fully restart both Studio and Claude. The Assistant settings should then show "1 client connected."

**Takeaway for us:** Rojo carries the code; the Studio MCP connection lets Claude read and edit the live place (instances, UI trees, properties) and run things in Studio. Both belong in the setup checklist.

---

# Batch 2: three photo slideshows (read slide by slide)

| Code | Creator | Slides | Topic |
|---|---|---|---|
| ZPL8MPnyV | okviky3 | 8 | "Tips I used to get 1,000 CCU on my game" (Spidey Bomb Tag) |
| ZPL8MSTwW | larpe_r | 4 | Party and casual games vs simulators, with real Creator Hub charts (Guess the Flag Color 2) |
| ZPL8MNKUy | ayaangiggy | 9 | "How I (almost) made a Roblox game with 0 experience" (a 99 Nights-style medical game) |

## ZPL8MPnyV: tips for 1,000 CCU (okviky3)

**Shown:** the Creator Hub realtime page for Spidey Bomb Tag (Ascending Studiozz): 1,014 concurrent users (+38.5%), session time 8.7 min, client crash rate 0.24%, client frame rate 39; Audience Reach "All ages". Retention page: Day 1 retention 14.55% at the 97th percentile of its genre benchmark (50th = 6.16%, 90th = 11.93%), Day 7 retention 1.18% at the 73rd percentile (50th = 0.51%, 90th = 2.01%). The game page with a video trailer thumbnail and 1,869 likes to 185 dislikes. A Robux transactions page (about 3.59M Robux total).

**The six tips, verbatim:**
1. Create something unique and only release something if you find it fun and genuinely think players will enjoy.
2. Don't slack on sound design and VFX; this stuff helps pretty much every stat and makes the game feel sooo good.
3. Use video trailers and good PTR thumbnails. (PTR = play-through rate: the share of people who see the tile and press play.)
4. Onboarding is a must for simulator games, and use funnel systems to guide you where your game lacks.
5. Use real-world trends and add a unique twist.
6. Study other games that are similar to yours (and feel free to study mine, 99th percentile in D1 retention).
Bonus: watch Tizzy_RBLX.

## ZPL8MSTwW: party and casual games vs simulators (larpe_r)

**Shown:** Creator Hub charts for Guess the Flag Color 2: peak concurrent players about 1,000 in late August 2026 decaying to about 100 to 200 by mid September; Day 1 retention 12.53% against the Party & Casual genre benchmark band of 6.19% to 11.84% (50th to 90th percentile); First play bounce rate 10.94% under 60 s and 16.37% at 61 to 180 s, with the Creator Hub warning "High rates lower your home recommendations exposure"; New user first session retention 57.84% still playing after 5 minutes.

**Said, verbatim:**
- "Party and casual games are much easier to get players than simulators. This is because they are so much simpler to make, and the benchmark for stats is much lower, since the genre as a whole has lower standards than the simulator genre for example."
- "Players are very likely to stay early on if you have a good concept, keeping your bounce rate low, and allowing for home rec exposure."
- "A great tip for high payer conversion and monetization is to mix your party games with elements from a simulator, like coins you earn each match to get new cosmetics."

## ZPL8MNKUy: zero-experience build with AI tools (ayaangiggy)

**Shown, in order:** a Times Square cover; a three-monitor setup (a 3D generator with a rigged orange character, Studio with a forest camp, VS Code with Claude) captioned "Connect VS Code w/ claude or codex to roblox studio"; "Gemini for icons and 3D model references" over a finished wood-and-parchment "Casebook" UI (patient card, assessment checklist, recipe materials with three item icons); "3daistudio > meshi.ai, better control over target polygon counts" over three rigged cylinder characters with bandages standing in Studio; two pages of a Meshy library (GLB models tagged ANIM and RIG, "Meshy Rigging", "Prism 3.1", an animated suit-wearing rat, decorative keys, a chest); "Befriend a roblox dev" (creator of "Ball Drop Game"); a Before shot of placeholder blocks (a plank jeep, a casket, a text-only HUD, errors in Output, place named "medical brainrot"); an After shot of a stylized ambulance jeep with lanterns at "Night 10" with a glowing tree monster boss, "Game dropping this week".

**Lessons:** the pipeline a beginner used was exactly ours (Rojo-style editor link, Claude or Codex, Studio) plus three asset tools: an image model for icons and model reference sheets, 3D AI Studio for meshes with a polygon budget, and Meshy for rigged and animated GLBs. The before/after is the clearest argument in any of the ten references that placeholder blocks must be replaced by stylized assets before launch.

# Batch 3: a pre-release competitor worth copying from

## ZPL8MtkYu: "this might be better than Steal an Egg" (humblesuperior.s)

A 41-second creator preview of an unnamed dinosaur ranch game, posted the day before its release. 465.8K views and 38.9K likes before the game existed, with a Discord link in the caption. Watched from contact sheets and a Whisper transcript; frames saved under `media/tiktok/out/ZPL8MtkYu/` and six crops in `docs/vault/05-ui-design/refs/dino-*.jpg`.

**What the game is.** Dig fossils at marked spots, hatch the egg in an incubator, raise the dinosaur from baby to elder "taking up your whole ranch", ride the ones you raised, fish for money and dinosaur food, and chase map-wide live events. "Over five maps, each in a different time period", "hundreds of dinosaurs with unique models and traits". Voxel-brick art: every surface, including the ground, is a tiled brick grid, so even simple geometry looks deliberate.

**Timeline.**
- 0 to 2 s: rowing a wooden boat; a huge sea dinosaur breaches beside it. Spectacle as an event.
- 3 to 7 s: desert and meadow with floating "✦ DIG" markers over resource spots; a 4-slot round hotbar bottom centre (shovel, rod, two eggs).
- 8 to 9 s: night, meteor streaks over ruins, big dinosaurs roaming.
- 10 to 12 s: "THUNDERSTORM 3:39 left · 1.5x LUCK" banner, rain. Fishing: "PERFECT THROW!" on the cast, then an underwater view where the hook sinks past labelled fish (Coelacanth, Pufferfish, Sardine, Mackerel) with "HOOKED 2/3" at the top; steer with A/D or mouse, click to reel.
- 13 to 17 s: more biomes (red desert, pine forest), the boat at night, a sky shot.
- 18 to 22 s: the incubator: a brick egg under a lamp dome, close-ups as it cracks.
- 23 to 26 s: nameplates on grown dinosaurs: name, ADULT, weight in kg (17,857 kg), a NORMAL mutation tag, a belly bar.
- 27 to 32 s: riding a dinosaur across the ranch; a "Your Ranch 42m" waypoint under the compass strip.
- 33 to 36 s: codex ("Fossils" tab): a 3D rotatable model on a pedestal, IDLE / MOVE toggle, rarity tag, habitat and found-by panels; an uncaught Epic shown as a black "?" silhouette named "???" with a hint on how to find it.
- 37 to 40 s: hub with physical stalls: SHOVELS, RANCH 1, DNA LAB.

**What we take (added to the plan, none of it changes the current milestone).**
1. Size rolls and growth stages (P1): every catch rolls a size shown on the nameplate, and a working alien grows Hatchling to Grown to Elder by time worked, with no feeding. Cheap variance that keeps duplicates interesting; growth without upkeep keeps our "no hunger" rule.
2. Compass strip with waypoint distance (P1): cardinal letters, a heading number, coloured markers for camp, quest target, Peddler and event, plus a "Camp 42m" label. Better on a phone than a minimap.
3. Verb markers over nodes: our key-material nodes get a floating "Collect" marker with a glyph visible from far away; the material name appears up close.
4. Event banner anatomy: dark pill, icon, name, time left, green luck chip. Written into the UI Playbook; our Meteor Shower and weather events use it.
5. Warden sightings: the Warden crosses the map on a timer as an uncatchable spectacle before the Field Notes finale, the way the sea dinosaur breaches by the boat.
6. Codex entry layout: 3D rotatable viewport, Idle / Move toggle, rarity tag, "Found: Meadow, Rain" line, a hint for uncaught entries drawn as a black "?" silhouette on the rarity colour.
7. Launch marketing: a Discord before launch, a release date announced in advance, and one creator teaser framed against the current number one. The teaser alone reached 466K views.
8. Placeholder look: a tiled grid material on our placeholder floor and pads so grey-box builds read as a style rather than a gap.

**What we skip.** Hunger (the belly bar) is upkeep and against pillar 3. Breeding and the DNA lab are already decided out. The fishing minigame is a second core mechanic; our timing bar stays the one catch verb, and a steer-the-hook variant is parked as a P2 idea for the Tidepool world.
