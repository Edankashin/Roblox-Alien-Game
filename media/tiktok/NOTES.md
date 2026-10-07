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


---

# Batch 4: tool stacks, prompting, Claude plugins for Roblox (2026-10-05)

Four more TikToks, processed the same way (`media/tiktok/out/<code>/`, contact sheets and Whisper transcripts; full-resolution crops of the on-screen document in the plugins video were read frame by frame).

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPL8uSbPg | ashenbot | 0:34 | The 2026 AI game-dev tool stack: engine CLIs and MCPs, 3D and image generators |
| ZPL8umT3M | dontrunsamurairoblox | 1:01 | The best prompting tip: make the AI ask you questions, then ask again |
| ZPL8uaNaS | lihfolk | 9:12 | "Opus is insane" pt. 2: how a solo dev builds a Roblox game with Claude end to end |
| ZPL8Hb7yS | lihfolk | 3:25 | "Optimize Claude for Roblox Studio" pt. 1: the plugins and skills, with install prompts |

## ZPL8uSbPg: the tool stack (ashenbot)

A rapid list, read off the caption and the transcript. Engines: Godot CLI, Unreal Engine MCP, Unity CLI, Roblox MCP ("connect directly to your AI"). 3D meshes: Meshy (API or MCP) and Tripo (API or MCP). Image generation: not needed inside Codex; otherwise Nano Banana Pro (Gemini image API) or Higgsfield CLI. "Then go crazy."

**What we take.** Our stack already has the Roblox and Blender MCPs. Meshy and Tripo are the mesh generators to try first for the species that the procedural blockouts (`tools/blender/alien_base.py`) do not carry far enough; both export GLB, which Studio imports. For UI icons and reference sheets the image model is Nano Banana (Gemini), which the art pipeline notes already name. No new engine tooling.

## ZPL8umT3M: make it ask you questions (dontrunsamurairoblox)

"If you're struggling because the AI is not following your prompt: make it ask you questions." Give the system request (his example: a global message system triggered by /globalmessage), end with "do you have any questions for me to implement this?", answer them, then ask again: "what questions can you ask me to make this follow through easier?" A broad prompt to an AI is "trying to get your idea to a toddler: they know the language but cannot read your mind." Explain it step by step.

**What we take.** Added to `docs/vault/02-how-we-work/Prompting.md` and the plan's prompting discipline: every milestone brief starts with a questions round, and a second round after the answers, before any code.

## ZPL8uaNaS: building a Roblox game with Claude, end to end (lihfolk)

A nine-minute walkthrough of an RNG "roll a blade" game. The usable lessons, in his order:
- **Start from an existing loop.** "It's hard to create your own sort of game. Most games are a repetitive loop: progression, something to wait for and monetise, a good core loop." Generate the game idea in any model, then paste it into Claude with "ask me as many questions as you need" (5 to 10 questions come back) before anything is built. His own idea generator produced "Steal a Cryptid", which he rejected because kids do not know the word: **the title must be understood by a ten-year-old.**
- **One step at a time, map first.** "A bad map, no one plays the game." Claude builds the basic structures and layout of a map, but placing props (trees, bushes) is where it is weakest; he places those by hand. The cliffs were generated, the volcano was a toolbox asset, colours changed by hand.
- **GUI.** Screenshot another game's GUI and ask an image model for the PNGs; "make sure all your icons are black-stroked, thick, or it just doesn't look good" (he points at thin-stroked upgrade arrows next to thick ones). Shop layout: large tiles for bundles and big purchases, small tiles for singles; "a nice shop goes such a long way" for monetisation.
- **3D models and animation** come from Claude Design: a model with animations and effects plus a Lua installer. Download the GLB and the Lua, paste the Lua into the command bar (or hand it to Claude through MCP) and it rigs and imports. A "model importing" skill he wrote cut the import from three to five minutes of Claude work to a single named step.
- **Usage.** Claude Max; medium effort by default; Opus 5.5 rather than Fable for usage; work in the five-hour windows; a game takes weeks, not a day. Image generation through ChatGPT for PNGs.
- **Finishing is on you.** "Everything the AI can do, but making things ready for the public is on you a little bit": fix jagged cliffs, tidy what players will look at.

**What we take.** The title test (a ten-year-old must understand it: our working title is checked against this in PRE_PRODUCTION decisions), the "map first, props by hand" order for World 2, the thick-black-stroke icon rule in the UI Playbook, large-tile-for-bundles in the shop layout, the import-model skill (`.claude/skills/import-model/SKILL.md`), and Claude Design as the candidate for rigged, animated species once the blockouts are in.

## ZPL8Hb7yS: the plugins and skills, with install prompts (lihfolk)

He shares a text document with one section per tool: what it does, when it activates, a "download prompt" to paste into Claude, and the exact commands. Read from the frames:
- **Agent Skills**: a large general skills collection, not Roblox-specific; "makes Claude smarter overall". Activation automatic.
- **Graphify**: builds a knowledge graph of the project so Claude "runs through it faster" on big games. `pip install graphifyy`, `graphify install`, then `/graphify`; run it again after big changes.
- **Ponytail** (Dietrich Gebert): "lazy senior dev mode", forces the simplest shortest solution (YAGNI); claimed 50% token saving, he reckons 20%.
- **Roblox Dev** (Ivar): "Roblox/Luau game development toolkit: exploit-proof remotes, safe DataStores, strict typing, performance, client/server code"; activates automatically when working on Roblox. `/plugin marketplace add ivar-anon/roblox-dev`, `/plugin install roblox-dev@roblox-dev`.
- **Roblox Claude Skills**: map building, UI building, debugging, API help, code cleanup, game setup; aimed at Rojo users; it conflicted with his other skills, so he does not insist on it.
- **Roblox Studio skill** (ShiroKSH): building and placement (maps, arenas, object placement, level design, playtesting); `/plugin marketplace add ShiroKSH/skills`, `/plugin install roblox-studio@skills`, then connect it to the open Studio and test by inspecting Workspace without changing anything.
- **Roblox Studio MCP**: "lets Claude actually see and edit your Studio game; without it Claude mostly gives you code."
- **Superpowers**: makes Claude plan more before big features; `/plugin install superpowers@claude-plugins-official`; "probably unnecessary for tiny changes"; you can say "use Superpowers for this".
- **Blender MCP**: the `uvx` server, "in case I want it".
His closing rule: with about 40 skills installed you do not call them; they activate on their own.

**What we take.** Decided per tool in `docs/vault/02-how-we-work/Claude-Plugins.md`: adopt Roblox Dev and the ShiroKSH Studio skill (both project-scope, after a dry run that proves no conflict with our `.mcp.json` and CLAUDE.md rules), keep Blender MCP and Studio MCP (already in), skip Graphify and Ponytail (our vault and CLAUDE.md do that job and the token saving is unproven), try Superpowers only for the World 2 build. Nothing is installed by a script; each is one deliberate `/plugin` command on the Mac.

# Batch 5: cinematics, map design, the forest reference, retention (2026-10-07)

Five links from Ethan, downloaded on the Mac (`b48eb4d`), processed with `tools/watch_video.py` (Whisper base.en; one frame per second) and every sheet and slide read. These are the references named in the owner direction (PRE_PRODUCTION section 5a); what we take from them is in section 5c there.

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLYS56X5 | turiptoroblox | 0:31 | "Made with Opus 5.5 in 45 minutes": map, lighting and a cinematic system |
| ZPLYSD7G9 | ropilot__ai | 0:18 | "Everything you see Ropilot Astra 6 made": three biome dioramas that assemble around the player |
| ZPLYSaBcg | machv10 | 1:27 | How to get high D1 retention (talking head) |
| ZPLYSA3uR | clovermoongames | 0:35 | The Moonlit Forest, one of six areas of Mushroom Tycoon (alpha Oct 10) |
| ZPLYSjC9y | okviky3 | 7 slides | How to keep good stats (the Spidey Bomb Tag dashboard again, see ZPL8MPnyV) |

## ZPLYS56X5: the 45-minute cinematic (turiptoroblox)

**Shown, as one continuous camera move (0 to 29 s):** a closed wooden barn gate fills the frame; the doors swing open toward the camera (0 to 4 s) and the camera dollies through onto a stone path (4 to 7 s); it flies low and fast between wooden walls with heavy foreground blur (8 to 10 s); it rises past a tree as the blur clears (11 to 12 s); it cranes up over rows of fenced farm plots, warm sunlight and lens bloom from the left (13 to 19 s); it pulls up and out until the whole map reads as one floating island, a square diorama with a layered dirt-and-cliff skirt, a perimeter of trees, a central cross path and a hub building, and holds there drifting slowly (20 to 29 s). At 30 s it cuts to the player character (winged) standing in the world. Audio: "dramatic music" only.

**Lessons.** (1) The cinematic is one unbroken shot built from five classic moves (reveal through an opening, dolly, low fly-through, crane, establishing pull-out) with eased speed changes between them; it is never a series of cuts. (2) Depth of field does most of the "cinematic" work: blur the foreground during fast moves, clear it as the camera slows. (3) Bloom and a low sun on one side give the warm glow. (4) It ends on the establishing shot that shows the whole world as an object, then hands control to the player. (5) The map is built to be filmed: one bounded island, a readable grid, a centre, a rim.

## ZPLYSD7G9: the world assembles (ropilot__ai)

**Shown:** a player stands on an empty baseplate. A glowing ring marks the ground (1 s); blocks fly up from below and slot into place around the player in a wave, with dust and light (2 to 4 s), until a volcano zone stands: dark basalt terrain, a cone with a lava river down its side, a lava pool, an arch and scattered rocks (5 to 7 s, 12 s). Then a desert canyon: stepped red mesa walls topped with grass, a mine door, cacti, a huge animal skeleton in the sand (8 to 11 s). Then a green zone: a pool with a waterfall from a tall rock, a wooden bridge, ruined stone pillars, floating islands (13 to 17 s). Each zone is a square tile with a visible rim, about four times the player's height at its tallest point.

**Lessons.** (1) Every zone is one theme with **one hero landmark** (volcano, skeleton, waterfall) and two or three supporting props, never an even spread. (2) Strong height change inside a small footprint: a cone, stepped mesas, a raised pool. (3) Hard colour identity per zone (basalt and lava orange; red rock and sand; green and water blue). (4) The assembly effect (pieces flying up and snapping in with a ring, dust and light) is a reusable moment: a biome unlocking, a ship module snapping on, a house piece placed.

## ZPLYSaBcg: D1 retention (machv10)

**Said (Whisper, checked):** "You want to create enough content for your players to come back the next day. If you're letting players beat your game in one session... they're not going to come back tomorrow." Three steps: (1) "make sure your core loop is fun", tested by releasing and watching the audience; (2) "suck the player in within the first five minutes", then keep them for 20 to 30 minutes with "enough compelling content"; the ideal is a first session of about 30 minutes, then back "tomorrow and tomorrow for a week straight"; (3) "focus on play-through rate": "We recently released a game that had insane stats. The only stat holding it back... literally the play-through rate", meaning is the tile clickable, viral, trendy enough for players to press it. "Good PTR, good D1 retention, good play time: you have the biggest game on Roblox."

**Checked against our data.** `tools/econ_sim.py` (fixed today: it read the Home Planet's row after row 0 was added, so it never saw World 1's Rain and reported the Nav Array as never finishing) gives, for an active player catching every 30 s: Hull Frame 1 min, Thrusters 6 min, Life Pod 19 min, Nav Array 37 min, Engine Core 1 h 17 min (the Warden's Core is the last gate). A 30-minute first session ends with three of five modules done and the Nav Array under way: World 1 cannot be finished in one session, as the advice wants.

## ZPLYSA3uR: the Moonlit Forest (clovermoongames, Mushroom Tycoon)

**Shown:** a high view down a pale winding path through a dense forest of chunky low-poly trees in indigo, violet and teal toward a floating landmark (a small island with a glowing halo arch and a waterfall falling from it) that is visible from everywhere (0 to 4 s). The player walks the path under falling streaks of light dripping from the canopy and drifting fireflies (5 to 9 s, "this is the Moonlit Forest"). A glowing moon pool ringed with mossy stones and lily pads under a light shaft (10 to 14 s). A grove of giant glowcaps, pastel white, pink and blue mushrooms three to five times the player's height, with small glowing mushrooms at their feet and lanterns on posts (15 to 19 s). A glowing blue waterfall watched from a little wooden bridge (20 to 24 s). A wide view: the stream, stepping stones, lit mushrooms and the floating island again, "and it's only 1 of 6 areas" (25 to 30 s). End card: the Mushroom Tycoon logo, "Alpha October 10", "follow for more".

**Lessons for World 1's Forest at night.** (1) A night palette of indigo, violet and teal with warm-white and pastel light sources, not a dark scene: the light comes from the props. (2) Three particle layers: fireflies (slow, small, everywhere), light drips under the canopy, sparkles over water. (3) Giant glowing mushrooms as the signature prop, with small ones at their feet. (4) Water as the centrepiece: a glowing pool and a waterfall, each with a viewpoint (the bridge) where a player stops. (5) A pale path that leads the eye to a floating landmark seen from everywhere. (6) Each stop is captioned in the trailer ("there's a glowing moon pool...", "giant glowcaps"): the map is designed as a list of named sights.

## ZPLYSjC9y: how to keep good stats (okviky3, slideshow)

The same creator and game as ZPL8MPnyV (Spidey Bomb Tag): realtime 1,029 CCU (+55.2%), session 9.3 min, crash rate 0.23%, frame rate 41, server memory 436. Slide by slide:
1. "My game peaks at 1k CCU, here's how to maintain good stats for your game."
2. **Playtime:** "playtime rewards, make a satisfying enjoyable game, afk zones, add a lot of content. MAKE A GOOD GAME YOU WOULD PLAY!!"
3. **D1 retention** (99th percentile): "make a game that is very fun and players would return to. Add login rewards and quests for joining back the next day, as well as boosts that players want to fully use and save until their next login (what went well for my game)."
4. **D7 retention** (about 80th percentile): "login rewards, an OP one for day 7, events and frequent updates."
5. **Bounce rate and PTR:** "make a fun tutorial and SHOW DON'T TELL!! Make the first 60 seconds fun"; "game trailers to boost PTR and nice thumbnails which also show and don't tell."
6. **Monetisation:** "make loads of micro transactions for cheap prices (revive, 2x cash) and make gamepasses for higher prices: small fries, medium and big fries."
7. "Bonus: watch Tizzy_RBLX."

**Checked against what we have.** AFK zones: resting (milestone 46). Login rewards with a strong day 7: Welcome Week, day 7 an Epic Egg. Quests for coming back: daily and weekly quests. Events and updates: Meteor Shower, Catch Rush, the weekly drop, Haunted Nebula. Boosts saved for the next login: power-ups are kept as counts until used. Show-don't-tell tutorial: the five-minute script (milestone 27). Small, medium and big fries: 49 to 99 R$ boosts, 199 to 399 R$ passes, 799 to 999 R$ top items. **Gap: playtime rewards**, which the Growth Playbook (section 3) chose to skip; reopened as decision 5c-1 in PRE_PRODUCTION.
