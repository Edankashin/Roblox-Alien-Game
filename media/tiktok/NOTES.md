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

# Batch 6: Claude-made 3D creatures, importing them, hatch animations, Open Cloud keys (2026-10-14)

Five links from Ethan (added in `54919f1`), processed in the cloud session with `tools/watch_video.py` (Whisper base.en through sherpa-onnx, named in each `out/<code>/info.json`; one frame per second) and every sheet and transcript read. Four are from one small Roblox creator, vos_studiostt (a farm game), who makes creatures with Claude Design and Claude chat; the fifth is a how-to for the Open Cloud key such tools need. Captions were checked against the transcripts and win where they differ.

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLS5oJs2 | vos_studiostt | 0:12 | "You switched from Astra to Opus 5.5": a farm game, then three glowing 3D creature viewers |
| ZPLSah2VR | vos_studiostt | 4:12 | Models with Claude, part 2: importing a GLB into Studio and fixing grey, colourless imports |
| ZPLS5oQoQ | vos_studiostt | 8:04 | Making a 3D creature in Claude Design: handoff documents, star ratings, reference images, two-prompt iteration |
| ZPLSaNotv | vos_studiostt | 0:21 | Egg-hatch animation before and after "one prompt" (Mythical Egg versus Secret Egg) |
| ZPLSaURU3 | taircreates | 2:39 | Making a Roblox Open Cloud API key and storing it as a Windows environment variable |

## ZPLS5oJs2: "You switched from Astra to Opus 5.5" (vos_studiostt)

**Shown:** one fixed caption, "POV: You switched from Astra to Opus 5.5" (Astra is the Ropilot tool from batch 5, ZPLYSD7G9). 0 to 3 s, a phone filming a monitor: a blocky farm game with a red voxel fox labelled Lv1 in a fenced pen, a green cash pill ("$408.6") over an XP bar ("Lv 1, 35/60 XP"), SELL and SHOPS buttons each with a red badge, a Shovel tool slot. 4 to 11 s, three browser pages (Void+Hydra.html, Creation+Dragon.html, Infinity+Axolotl.html), each one creature turning on a glowing floor ring with orbiting particles: a dark many-headed hydra with violet neon rings, a gold-and-white winged dragon over a pentagram ring, a pastel axolotl inside a figure-eight ring of loops.

**Said:** nothing; music only (Whisper: "(upbeat music)").

**Takeaway for us.** The pages are Claude Design 3D-object output (see ZPLS5oQoQ). The shared recipe is one hero creature, a lit floor ring and particles circling it: the creator's rarity signal. It matches the Legendary ("halo, ground ring") and Cosmic ("trail, aura") rows of the tier table in `docs/GAME_DESIGN.md` section 15, so ring plus motes is a cheap overlay for those two tiers. The farm HUD (pill, bar, two badged buttons) is the layout our HUD already uses (section 16); nothing to take.

## ZPLSah2VR: importing Claude-made models into Studio (vos_studiostt)

**Shown:** caption "Roblox Models with Claude AI: Importing into Studio" (0 to 10 s). 0 to 45 s: the land shark from ZPLS5oQoQ in a dark viewer, `land_shark.glb` in the downloads. 46 s to 1:20: Studio, File, Import (not "Import Roblox Model"), then the Import Preview with the model untextured grey, "AuxScene" renamed LandShark. 1:24 to 2:28: Explorer with ReplicatedStorage modules (AnimalModels, AnimalModelColors, AnimalVFX). 2:29 to 4:12: a Claude chat, the GLB attached.

**Said:** (1) Export GLB. (2) Rename to the animal's exact name, no spaces. (3) The import has no colours or effects: "gray silhouettes... they had no animations"; his fix is three ReplicatedStorage modules (colours, models, VFX) that Claude writes from the attached GLB. (4) Animation comes from Claude chat, not Design: "all 63 of the animals in our game were animated completely with 3 or 4 prompts", one big prompt then batches. (Whisper returned one word for 180 to 210 s; I re-ran it in 10 s windows.)

**Takeaway for us.** (1) We already solved grey imports: a GLB upload drops colours, so each model folder carries `materials.json` and the runtime loader restores them (`docs/vault/06-art-pipelines/Map-Dressing.md`). (2) His exact-name rule is our `ModelAssets` key matching the species id; a miss shows in the `Models: 53 loaded, 0 failed` boot line. (3) 63 animals in 4 prompts answers the Tools-Status Claude Design row ("animation not started"): take the batching, not his colour and VFX modules.

## ZPLS5oQoQ: making a 3D creature in Claude Design (vos_studiostt)

**Shown:** caption "Roblox 3D Models with Claude Design" (0 to 7 s). 0:30 to 0:50: the Design page, "Model a 3D object" chosen. 0:51 to 4:20: earlier results (an axolotl, a violet hydra) turned on a glowing ring. 4:22 to 4:47: a long handoff document scrolled. 4:48 to 5:07: a new chat, "I want to make the land shark, with the previous details mentioned in mind". 5:16 to 5:51: result one, a grey two-legged shark with red glowing tail. 5:52 to 6:48: prompt two with a reference image. 6:49 to 8:04: result two, a bigger, fanged shark-dragon with red-lit blades.

**Said:** (1) Handoff documents: accept a fresh chat or ask for one; it "starts a new conversation with an entire script for everything that you've done". (2) Rate every output with stars; it keeps your preferences. (3) Use reference images; he bases creatures on Pokemon but changes details because "Nintendo, they're going to copyright me". (4) Never one-prompt: prompt two listed changes and which part of the reference to copy ("if you don't specify... it's going to change it to look exactly like that"), "a thousand times better".

**Takeaway for us.** (1) We already do this: `docs/vault/00-start-here/Handoff.md`, the Board, the daily log. (3) is the legal line for our roster: aliens are original (`docs/GAME_DESIGN.md` section 4), so a reference steers silhouette and palette only. (4) is the pass structure of `docs/vault/06-art-pipelines/Creature-Generation.md`. The viewer's animation is not in the GLB.

## ZPLSaNotv: egg-hatch animation, before and after one prompt (vos_studiostt)

**Shown:** a phone filming Studio. Caption "Before Opus 5.5" (0 to 6 s): a magenta MYTHICAL EGG on a glowing pedestal, "Tap to crack!" then "One more!" with progress dots, a white flash, a black silhouette in a crack burst, the card "Ocean Horse, MYTHICAL, 20% chance", "Tap to continue". Caption "One prompt with Opus 5.5" (7 to 15 s): a SECRET EGG drops as a pink orb before a red barn (7 s); the dark purple egg grows with each tap ("Again!", "One more!"; 9 to 10 s), shatters into polygon shards (11 s), a black hydra silhouette in a ring (12 s), "Void Hydra, SECRET, 3% chance" under magenta light beams (13 to 15 s). 16 to 21 s: "Eclipse Tiger, SECRET, 11% chance", then a white flash and "Heaven Ox, DIVINE, 9% chance".

**Said:** nothing; music only (Whisper "[Music]").

**Takeaway for us.** The beats are the reveal popup in `docs/GAME_DESIGN.md` section 16 (silhouette, burst, tier name, "Tap to continue") plus three we do not list: a multi-tap crack with dots and growth per tap, shards instead of a flash, and a card printing "N% chance" for what you got. Our only hatch is the Welcome Week day-7 Epic egg (section 11), so this is post-launch polish for that beat, not a system. A chance line after the reveal fits the paid-random rules (section 14).

## ZPLSaURU3: an Open Cloud API key and an environment variable (taircreates)

**Shown:** yellow subtitles, caption "API KEY + Environment Variable" (0 to 8 s). 12 to 24 s: Creator Hub, All tools, API Keys, Create API Key. 25 to 40 s: Access Permissions, assets and asset-permissions, then game-passes, creator-store-products, developer-products, each read and write. 41 to 48 s: Security (IP restriction, expiration) and the "Unrestricted Experience Access" warning ("all your current and future experiences"). 59 s to 1:59: PowerShell, `$env:ROBLOX_API_KEY="..."`, then `[Environment]::SetEnvironmentVariable(..., "User")`. 2:00 to 2:23: a Claude one-liner printing "API key detected" or "API key NOT detected".

**Said:** the shout-out is to @cuhfilme (Whisper heard "Car Film"; captions win), the batch 1 creator. The pitch: an API key "which does all the importing for you". Save the key "somewhere safe, preferably... a picture of it on your phone". The check runs "without revealing on screen the actual API key". Whisper missed the permission list; the subtitles supplied it.

**Takeaway for us.** Our scripts already read the key from the shell (`ROBLOX_OPEN_CLOUD_KEY` or `ROBLOX_API_KEY`; `docs/vault/00-start-here/Handoff.md` "Secrets"), on a Mac an `export` in `~/.zshrc`. Adopt: the presence check that never prints the key; tick only the APIs a script calls (`upload_assets.py` needs Assets read and write), not four; set an expiration. Watch: "all experiences" means a leaked key reaches every one, so scope it to one and rotate it if it ever shows in a chat. Refuse: the phone photo; a key never goes in a file, report or chat.


## Batch 7 (2026-10-15): the UI reference

Three links from Ethan, downloaded on the Mac (`3d585a8`) and processed in the cloud session. Each mp4 went through `tools/watch_video.py` one at a time, from the repo root, with `SHERPA_WHISPER_DIR` set to the Whisper base.en model directory (the variable the script reads; without it the script falls back to pocketsphinx): `python3 tools/watch_video.py media/tiktok/<code>.mp4`. On clips over 30 s the script's 30 s chunks print a "less than 30 seconds" warning; the transcripts read continuous. Every sheet and transcript was read, and the UI clip was also read frame by frame at full resolution (60 fps, 1080 x 1920) and sampled for colour with Pillow. Outputs are in `media/tiktok/out/<code>/` (scratch, never committed). Ethan's words: "copy this type of UI" for ZPLSQA4aX. The other two arrived in the same drop and are not UI references.

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLSQBRMa | milesreevesai | 0:50 | Three free AI API tiers for coding tools (talking head); not a UI reference |
| ZPLSQA4aX | jarvislabsreal | 0:17 | "New shop using Claude Design", before and after; Ethan: "copy this type of UI" |
| ZPLSQ8AAE | vos_studiostt | 8:04 | Making a 3D creature in Claude Design; the same file as ZPLS5oQoQ (batch 6) |

### ZPLSQBRMa: three free API tiers (milesreevesai)

**Shown (0 to 49 s):** a presenter at a desk under the caption "STOP PAYING FOR AI API KEYS" over a red spend counter that climbs from $311 to $847 (0 to 2 s); then fast stock cutaways, one every one to three seconds, under word-by-word captions in bold white with a dark outline: the GitHub mark (3 to 7 s), a rack of NVIDIA servers (8 to 12 s), an API-key card and a free-tier card reading "0,00 EUR" (13 to 18 s), an "80+ models" tile (19 s), monitors and a laptop running code (20 to 37 s), a phone with a keyboard running a terminal (38 to 46 s), then the presenter again (47 to 49 s). Nothing in it is game UI.

**Said (Whisper, checked against the post text):** "If you're paying hundreds of dollars for API keys, these three free tools and one secret GitHub repo will get that bill to zero." The three: NVIDIA NIM ("a free API key with a 40 requests per minute limit"), Baseten ("a single API key gets you the newest open source models"), OpenRouter ("free API keys for open models... capped at 50 free requests per day"). The repo "lists every one of these free providers with copy-paste config snippets so you can plug any of them into Claude Code or Cursor in under a minute." The repo is never named or shown. Whisper wrote "NIMH" and "Baston"; the post text, which wins, spells them NIM and Baseten.

**Lessons for us**
- Not a UI reference; nothing to build from. It came in with the batch, so it is logged and set aside.
- The tier limits (40 requests a minute, 50 a day) are far below a coding session's need, and routing Claude Code through another provider is a tool-stack choice for Ethan, not a game feature. It has a row in `docs/vault/02-how-we-work/Tools-Status.md`; no decision was made.
- The "secret repo" is unnamed, so nothing in it can be vetted. Do not paste its config snippets into this repo, and keep keys where `docs/vault/00-start-here/Handoff.md` "Secrets" puts them (the shell environment, never a file, report or chat).
- The one craft point: a caption that changes word by word every half second carries a 50 s talk. It is a pacing idea for the trailer captions, nothing more.

### ZPLSQA4aX: the new shop, before and after (jarvislabsreal)

Sheet: [the 12-frame UI sheet](../../docs/vault/05-ui-design/refs/tiktok-ZPLSQA4aX-ui.jpg) (`docs/vault/05-ui-design/refs/tiktok-ZPLSQA4aX-ui.jpg`; 12 frames from 0.3 s to 15.7 s, every 1.4 s, cropped to the recording, with timestamps).

**Shown.** A vertical clip. A caption "NEW SHOP USING CLAUDE DESIGN" sits over a blurred zoom of the footage (white, with "CLAUDE DESIGN" in yellow, thick black outline); the Roblox recording runs letterboxed in the middle at about 2.1:1; a red "BEFORE" and then a green "AFTER" label sit under it. 0 to 3 s, BEFORE: a centred Store panel with a rainbow neon rim and a vertical list that scrolls (Starter Packs, Gamepasses, Upgrades). 3.0 to 3.6 s: the world view and a glow on the SHOP button. About 3.7 s: the new shop opens and plays to 17 s (a cursor hovers, taps, drags the scrollbar and taps each tab). Audio: a music track only (Whisper: "I"; the post lists a track by prodbyCyn). The game is a gym and titan collector (Serum Lab, Titan Armory, "+1 TITAN CHARGE"), the same creator and game as ZPLSQ1o7Q, ZPLSQAq5q, ZPLSxw532 and ZPLSQAhnb in batch 8.

**The old one, for contrast (0 to 3 s).** A centred panel about half the screen wide with a thick gradient rim that runs pink, cyan, violet and magenta, a navy body (about `#151D59`) and a purple ribbon tab holding "STORE" in gold with a red shopping bag. Content is a vertical list of full-width coloured rows (orange Starter Pack, purple VIP, red x2 Power, green Auto Collect, blue Serum Lab), each with a round icon on the left, a name, a two-line paragraph and a grey "COMING SOON" button (a green "OPEN" on the two live ones); section headings "Starter Packs!", "Gamepasses!", "Upgrades!" in white on navy; a red round X at the panel's top right. It scrolls like a document and every row is a paragraph.

**UI breakdown of the new shop (frame by frame).** Fractions are of the recording (960 x 460); hex values are the median colour of small patches, accurate to about 10%.

- **Frame and layout.** A full-screen takeover: no panel border, no dim layer, the HUD gone (only Roblox's own logo, menu and chat buttons stay at the far top left). The ground is a vertical gradient from `#6948B9` (top) to `#0E0E42` (bottom) with faint radial rays. Header row, top 13%: a red X at 14 to 19% of the width, "SHOP" at 20 to 30%, a small lavender tag "+1 TITAN CHARGE" (the event) at 30 to 42%, and two dark currency pills (cash icon and count, bolt icon and count) at 87 to 98% of the width. Tab rail: five tabs stacked at the left, 1 to 13% of the width, from 18% down to 67% of the height, each 7% tall with 3% gaps, drawn over the strip. Card strip: one horizontal row from 14% of the width to the right edge, cards 22% to 88% of the height with a 1.4% gap; the first (featured) card is 23% wide, the others 12%. Scrollbar: 93 to 97% of the height, 20 to 80% of the width. Edge chevrons: a white outlined ">" at the right edge, and a "<" at the left once the strip has moved.
- **Panels and borders.** Cards are tall portrait rounded rectangles (aspect about 1:2.7; the featured one about 1:1.4), corner radius about 12% of the card width, a thick dark-navy outline (about 3% of the width) with a thin lighter stroke inside it and a soft drop shadow. Each is a vertical gradient: a light tint at the top, the base colour in the middle, a deep shade at the bottom, with a lighter sunburst of rays behind the icon. Tabs are rounded rectangles in dark blue (`#13135A`) with a lighter rim (`#5B58A4`), an icon on the left and a label; the active tab is gold (about `#ECA747`, the same gold as the scrollbar thumb) with a cream rim (`#FFFFB7`). The scrollbar trough is near-black (`#000013`) with a round gold thumb (`#ECA747` to `#FFE8AD`) carrying three grip ticks.
- **Colour.** One colour family per product category: starter pack purple (`#AF7AFF` to `#6F42BC`), gamepass gold-orange (`#FBAB13`), power boost blue (`#65A2FF` to `#357CF2`), auto-collect indigo (`#9374FF` to `#462AAE`), cash green (`#72FF84` to `#44DA5D`), crate red (`#EB565D`), serum pink (`#E83C7D`), armory violet (`#955AF0`); card bottoms fall to about `#271351` (purple) and `#0F421F` (green). Price pill `#72EC61` to `#26C12E`. Disabled "SOON" pill dark green (`#175318`) with a pale grey label. Close X `#FF1211`. Currency pills `#140C2C`. Title text white. Saturated and bright against the dark purple ground, every shape outlined.
- **Fonts and text.** Heavy, slightly condensed display type, all caps, white fill, a thick dark outline and a darker drop edge, a little different in size and tilt on each card (the lettering looks drawn into the card art; the "VIP" wordmark is gold with a brown outline and about twice the size). It is not Fredoka One; Lilita One is the nearest common face (a guess). Sizes at the recording's 460 px height: "SHOP" cap height about 22 px (4.8%), card titles about 19 px (4.1%), price numbers about 17 px (3.7%), tab labels about 12 px (2.6%), ribbon words and the "+1 TITAN CHARGE" tag about 10 px (2.2%). Our 14 px floor on a 390 px phone is 3.6%, so the tab labels, ribbons, tag and the "PERMANENT" sub-line would all be too small there.
- **Icons.** Large rendered, glossy 3D-style illustrations, one per card, about half the card height: a gold crown on a red cushion, a golden fist with blue sparks, a red horseshoe magnet with coins and notes, stacks of banknotes, a treasure chest, a lightning orb, a round purple potion flask, a golden armour set; the starter pack is a black bodybuilder silhouette over a gym bag, cash, a bolt and a bottle. Each has a thick dark outline, a warm highlight, a few four-point sparkles, and sits on the sunburst. The small tab icons are the same style (a calendar with a tick, an armour crest, banknotes, a bolt orb, a flask). One style throughout; no emoji, no flat glyphs.
- **Button anatomy.** The price pill spans the card minus about 5% each side, about 10% of the card height, at 83 to 95% down: a green gradient (lighter top half, darker lower half), a thin dark outline, a gloss band, a white Robux ring glyph and the number in white with a dark outline ("99", "399", "299", "249"). Unreleased items get the same pill in dark green reading "SOON", dimmed. Items that open another screen read "OPEN" in the same green. Gold and cyan are the only accents (the active tab, the selected card); there is no second button shape.
- **Status and rarity.** The shop does not use rarity colours: colour is the product category and the status is a ribbon. A small folded ribbon with swallowtail ends straddles the top edge of each card at the left: "BEST DEAL" (dark red), "GAMEPASS" (brown and gold), "POPULAR" (violet), "NEW!" (red), "LIMITED" (green), "TOP DEAL" (red), white caps with an outline. Spiky red starburst seals tilted about 15 degrees overlap a card corner ("BEST VALUE" at the bottom left of the featured card, "+25% BONUS" on the 100K cash card). On the tab rail a red round "!" badge (white rim) marks tabs with something new, a green "FREE" chip tops the Featured tab and a red "NEW" chip the Serums tab. Rarity itself shows elsewhere in the same game (batch 8, ZPLSQAhnb): the rarity word in each cell, a tinted cell, and in the roll reel a yellow card with a "SECRET" chip and a pink card with a "TITAN" chip.
- **What moves and when.** About 3.7 s: the screen replaces the world; the cards slide in from the right edge tilted about 10 degrees and straighten as they travel left, the featured card first and the rest a beat apart; the five tabs drop in one by one from the top; all is settled by about 4.3 s. A hovered card lifts about 10 px (3% of its height) and its price pill glints. The "POPULAR" card keeps a cyan glow outline with four-point stars twinkling at two corners for the whole clip. A tap on an unreleased card pops a yellow outlined "Coming soon!" over its title for about a second (the starter pack at 6 s, the VIP at 7 s): not a silent tap. Dragging the scrollbar thumb (7 to 11 s) or tapping a tab (12 to 15 s) scrolls the strip with a springy ease; as the strip moves the active (gold) tab follows the section in view (Passes at 8 s, Cash at 9 s, Serums at 10 and 11 s), the cards that pass under the tab rail are dimmed by a dark fade, and the chevrons appear and vanish with the scroll position.
- **Structure.** Five tabs (Featured, Passes, Cash, Boosts, Serums) over one flat row of twelve cards ordered by section: Starter Pack (featured, double width); VIP, x2 Power, Auto Collect; 100K, 1M and 10M Cash; Titan Crate, 2X Power, 2X Cash; Serum Lab and Titan Armory (each "OPEN", the doors to the in-game-currency shops). A tab is a scroll target, not a filter. The row reads left to right like a shelf; each card is name, icon, price and at most one ribbon, with the descriptions gone (the old list needed two lines each).

**What we copy** (the structure and treatment, in our palette and font, built through `Builder` and `Theme`):
- The shelf of tall category-coloured cards on a sunburst with a rendered hero icon, a white outlined name above and a wide green price pill below, in place of text rows. Category colours come from our palette (blue `#68C9FE` select, green `#51DF51` confirm, gold `#FFC83D` featured, purple `#A855F7` codex, red `#FF4D4D` alert) and never from the rarity table, which stays for aliens. Fredoka One, outlined `#1B1F3B`, 14 px minimum, Scale only.
- Status as ribbons and starburst seals (BEST VALUE, POPULAR, NEW, LIMITED), strings keyed in `src/shared/strings`, so a tile says what it is in one word and a shape.
- A left tab rail with icon, label, a red "!" and a "NEW" chip, whose active tab follows the scroll position; tabs scroll the strip; a pill scrollbar with a gold thumb; a dim fade under the rail.
- The entrance (tabs drop, cards slide in tilted and settle), the hover lift, the cyan outline and twinkle on the one recommended card, and a visible "Coming soon" toast for anything not live. Each needs a Reduced Motion form (cards fade in place, no tilt, no twinkle).
- The dark currency pill (icon and count) in the header.

**What we do not copy.** The game's art and names: the crown, fist, magnet, flask, armour, chest and bodybuilder icons, "Titan Charge", "Serum Lab", "Titan Armory", its tab names and its wordmark lettering. The rainbow neon rim of the old panel. Cash packs sold for Robux ("100K CASH", "10M CASH"): our one currency, Scrap, is never sold for Robux. Lettering baked into card art (every player-facing string is keyed text). The red X beside the title at the top left (our Playbook puts the close at the top right and keeps the top-left corner clear of Roblox's own buttons), text under 14 px, and the grey "COMING SOON" dead-end buttons of the old panel. Any paid random crate would still need its odds line and the policy gate.

**Lessons for us**
- A shelf of tall cards reads in one glance where a list of paragraph rows does not: twelve products, no description text, and the eye goes icon, name, price. Rebuild the Shop's featured band and the pass and boost tiles toward this, one card per product, not a wider list.
- Colour means category, the ribbon means status, and rarity stays out of the shop. Our palette already has the family colours; a ribbon and a seal are the only new shapes to build.
- Motion is four small moves (entrance stagger, hover lift, one twinkling card, a tab that follows the scroll) and each has a Reduced Motion form. Everything else is still.
- At phone size the reference's small text fails our floor (tab labels, ribbons and the tag are 2.2 to 2.6% of the height against our 3.6%): copy the structure, raise the type, and measure it in the device emulator at iPhone SE.
- The art is the cost: twelve rendered icons for one screen. The Icons pack and its pipeline (`docs/vault/05-ui-design/UI-Playbook.md` "Icons (batch 4)") are the route; the old list needed none, which is why it looked thin.
- The post credits the redesign to Claude Design; our use of it is the review canvas for mockups before the build (`docs/vault/02-how-we-work/Tools-Status.md`).

### ZPLSQ8AAE: making a 3D creature in Claude Design (vos_studiostt)

The file is byte-identical to ZPLS5oQoQ (same size, 24,768,144 bytes, same MD5): one video saved from two share links. The batch 6 section on ZPLS5oQoQ already describes it. A fresh Whisper pass and a look at the sheets (every second, across the whole length) turned up these additions.

**Shown:** a face camera over a screen recording of the Claude web app. 0:00 to 0:50: the left sidebar, the Design entry, the Claude Design page "What should we create?" and its picker with "Model a 3D object". 0:51 to 4:20: earlier results turning on a glowing ring in a dark viewer (an axolotl in a figure-eight ring, a violet hydra on stacked rings). 4:22 to 4:47: a handoff document scrolled. 5:16 to 5:51: land shark one, grey and upright with red glowing tail and blade lines and water rings at its feet. 6:49 to 7:50: land shark two, bigger, with fanged overlapping teeth and red-lit blades, turned by hand in the viewer.

**Said (Whisper; "cloud design" is Claude Design, "quad" is Claude):** [30 s] "I don't know if you need a Pro... I think you do, but I'm not too certain"; "visit standalone Claude Design... click 3D object if you're making a model." [60 s] "handoff documents you want to always be creating... it starts a new conversation with an entire script for everything that you've done." [90 s] rate every result with stars and "tell it what you like and you don't like." [120 s] "have ChatGPT actually come up with a mock reference image, and you can use that to input in the" tool. [150 s] "based off Pokemon, but I don't want them to look like Pokemon because we all know Nintendo, they're going to copyright me." [180 s] "there are actually video effects with these models, but this is just a projection of the GLB. So it's not included." The first prompt (an upright land shark, rough skin, short arms with curved blades, dark blue, red and black, a menacing open mouth) took about "two Clash Royale games" to come back; the second listed changes (rougher skin, bigger claws, water effects at the feet, bigger polished blades with a flowing red, gills like scars, a bigger head fin, "don't make his gums visible", bigger overlapping teeth, a bigger body) and named what to take from the reference image, "because if you don't specify then it's just going to change it to look exactly like that." Verdict: "a thousand times better... don't try to one prompt your stuff."

**Lessons for us**
- New against batch 6: the effects (ring, particles, water at the feet, glowing lines) live in the viewer page, not in the exported GLB; the creator says so. Treat a Claude Design 3D result as a mesh plus a spec for effects we rebuild in `Effects.luau` (`docs/vault/01-game-design/Roster-Redesign.md` section 6).
- A mock reference image from a second tool, then a prompt that says which part of it to copy, is a two-step we can use for species sheets; a reference steers silhouette and palette only (our aliens are original, `docs/vault/01-game-design/Species-Names.md`).
- Prompt two is a list of verbs about parts ("bigger blades, rougher skin, fix the mouth"). Keep our own revision briefs in that form (`docs/vault/06-art-pipelines/Creature-Generation.md`).
- Nothing else is new; do not process the file again.


## Batch 8 (2026-10-15): the toolchain

Six links from Ethan (`86cf642`), processed with the same commands as batch 7 (`python3 tools/watch_video.py media/tiktok/<code>.mp4` with `SHERPA_WHISPER_DIR` set, one video at a time). Every sheet and transcript was read; the six slides of the photo post were read one by one (they are 2160 x 2880 photos of a laptop with text overlays); the clips that carry screens were also read at full resolution. Ethan's words: "incorporate Blockbench, Blender and Substance Painter to create these character models."

**The finding up front: none of the six names or shows Blockbench or Substance Painter**, in speech, captions, slides or on any screen (the one macOS dock that is visible, on slide 5, has Roblox Studio, Claude, ChatGPT, Obsidian, Chrome and Blender among its readable icons, and no Blockbench or Substance icon). The tools that do appear are Blender, Claude (the chat app and Claude Code, joined to Roblox Studio through its MCP server), Claude Design, Obsidian and Roblox Studio. Five of the six are results with the music on and no voice; only the photo post explains any step, and it explains it in one line each. Where a step below is "inferred", the video does not show it. Two files are duplicates of batch 6.

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLSQrYcW | deep.haul.studios | 6 slides | "How I made a high-quality Roblox game using AI + tools": Claude, Studio MCP, Obsidian, Blender |
| ZPLSQ1o7Q | jarvislabsreal | 0:20 | "VFX made in Blender for my Roblox game": a ring-pad arena of powers |
| ZPLSQAq5q | jarvislabsreal | 0:17 | "+1 Titan Charge, Common to Legendary": fourteen cube-head character models turning |
| ZPLSxw532 | jarvislabsreal | 0:10 | "Titan transformation": a flash, smoke, a titan lit by orange neon lines |
| ZPLSQAhnb | jarvislabsreal | 1:27 | "24 hours: a Claude model + Blender + Claude Design": ten screens, the charge effects, the roll reel |
| ZPLSxwKHm | vos_studiostt | 0:12 | The same file as ZPLS5oJs2 (batch 6) |

### ZPLSQrYcW: "how I made a high-quality Roblox game using AI + tools" (deep.haul.studios, photo post of 2026-10-12)

The creator's own game is Deep Haul Fishing Survival (the Roblox page is slide 1: 100% rating, ages 16+, "HUGE UPDATE" banner art). The post text adds: learn Roblox Studio, practise Lua scripting, "explore Blender for custom 3D models", and "study how popular games design their maps, mechanics, and progression systems."

**The process, slide by slide (the creator's words in quotes):**
1. Title: "HOW I MADE A HIGH-QUALITY ROBLOX GAME USING AI + TOOLS (will show): VERY SIMPLE GUIDE".
2. "make sure to know how to code first"; "download Claude" (the current top model) and "buy Pro or max". The photo is the Claude desktop app on the Code tab: a project called DeepHaul, a chat "Roblox game development strategy", a branch bar "DeepHaul main" with a diff count (+100,586, -803) and a "Commit changes" button, the model picker set to a Claude model at Medium effort, a "Pro" plan label. The visible chat is the creator's ad-spend analysis (51 impressions for $0.01 against a $6 daily budget, ad images in review, the 16+ reach limit).
3. "Connect Claude to Roblox Studio MCP"; "plan out everything you want on the game brainstorm"; "find your core loop". The photo is Studio with the game open on an empty baseplate, the Terrain Editor and Toolbox (Creator Store) panels on the left, Explorer on the right (Workspace, Players, Lighting, MaterialService, ReplicatedFirst, ReplicatedStorage, ServerScriptService, ServerStorage, StarterGui, StarterPack, StarterPlayer, Teams, SoundService, TextChatService) and an Output line loading an asset from `assetdelivery.roblox.com`.
4. "Connect Claude to Obsidian (VERY IMPORTANT)"; "obsidian adapts as you create games and keeps workflow organized". The photo is Obsidian's graph view of a vault called DeepHaul, about a hundred notes, with hubs Home, Roadmap, Board Pulse, Playtest Log, Session Log, Playbook and Retention Scorecard, a competitor note "Fisch Teardown", art notes "Blender AI Workflow", "ART_AND_ANIMATION", "3D Model Gallery", "Import authored models", "MCP_WORKFLOW", and feature notes in purple; the graph panel shows arrows off, text fade threshold -1.40, node size 3.57, link thickness 1.75.
5. "learn how to build models in Blender"; "upload Blender models into Roblox Studio". The photo is Blender 5.2.2 LTS on the Layout workspace in Object Mode, file `HarborLayout_Cinematic.blend`: a low-poly harbour (a flat green island slab, five cottages with grey roofs and teal walls, a lighthouse, stepped pale rock outcrops, a T-shaped wooden pier on stilts, a flat water plane). The Scene Collection lists objects named per piece (BeachAp..., Boardwa..., PierCross...), the workspace tabs are the stock set (Layout, Modeling, Sculpting, UV Editing, Texture Paint, Shading, Animation, Rendering, Compositing, Geometry Nodes, Scripting), the timeline is at the default 1 to 250, and the status bar warns "active object has non-uniform scale". No add-on is visible. No export dialog is shown and no file format is named; how the models reach Studio is only that caption.
6. "and here it is": the finished game: a plank dock with named NPCs and three signboards (an event, a "THE DEEP" board, a "Server's rarest catch" board), a compass strip at the top centre with the location "Port Haul", a Shop and a Menu button either side of it, an event ticker ("Feeding frenzy: fish bite 2x faster"), a five-slot hotbar of labelled icons at the bottom centre (Golden Trident, Bag, Bestiary, Quest Book, Collection), a "Playtime gift in 4:57" chip, a pink octopus pet and a Fish Index.

**Tools named or seen:** Claude (desktop app, Code tab), a Claude model on a Pro plan, Roblox Studio and its MCP, Obsidian, Blender 5.2.2 LTS, the Roblox Creator Hub ad manager (in the chat screenshot), ChatGPT and Chrome (dock only). No plugin names.

**Lessons for us**
- It is our stack, in the creator's order: Claude with the Studio MCP, a plan and a core loop first, an Obsidian vault as the memory, Blender for the models, upload to Studio. Nothing to add; it confirms the order of `docs/vault/06-art-pipelines/Model-Toolchain.md` section 1 (Blender builds, Studio receives).
- Blender is the only modelling tool the creator shows, building a scene as separately named objects. The one Blender gotcha on screen is the status-bar "non-uniform scale" warning: apply scale before export so Studio reads the true size. Our `species_sculpt.py` already writes 1 unit = 1 stud.
- Blockbench and Substance Painter are absent. This audience reaches a good-looking Roblox game without either, so they stay in our chain only as the hand-paint and animation desk (Blockbench) and the optional coat for hero species (Painter), as decided; no creator here is evidence for them.
- Their vault is hubs (Home, Roadmap, Board Pulse, Playtest Log) around a note per feature and a note per competitor. Ours has the same bones (Board, Handoff, the daily log, the TikTok notes); a one-page competitor note per reference game would be the cheap addition.

### ZPLSQ1o7Q: "VFX made in Blender for my Roblox game" (jarvislabsreal, 0:20)

Post text: "made every power in my roblox game with claude + blender, which one hits hardest?"

**Shown (no voice; Whisper: "(music)"):** a caption, "VFX MADE IN BLENDER for my roblox game" (white, then yellow). A night arena: a round stone floor with cracks, a ring of glowing cream-orange runes, two torch pillars, a moon and a dark mountain skyline. About seven coloured ring pads sit on it, each holding one power: a dark obelisk with white glowing notch lines under white forked lightning that fills the frame (9 to 11 s); a tall gold column of light wrapped in stacked glowing rings with orbiting sparks (12 to 13 s, 17 s); a translucent violet crystal burst (4 to 6 s, 15 s); a brick wall that is smashed into flying bricks and rubble and rebuilt, a red flame on its pad (7 to 8 s); a red-pink fan of blade shards (2 s, 14 s); a spinning gold sigil with orange sparks (0 to 3 s); a white star-shaped ground crack with a ring of boulders and red-orange lightning arcs at the centre (4 to 6 s, 14 s); and a shower of coins and leaves (1 to 4 s). The camera orbits and cuts in close on each power for a second or two, then pulls back to the whole arena (0 to 2 s and 16 to 19 s, so the clip loops).

**The process (inferred; the clip shows only the result):** the effects are low-poly meshes with emissive materials: flat rings and thin cylinders for the light column, flat zig-zag ribbons for the lightning, faceted chunks for rock, crystal and brick. They are modelled in Blender (the caption), brought into Studio as meshes, and moved there (spin, flicker, tween, particles); the sky, bloom and shadows are Roblox's lighting. No Blender window, export setting or format is shown.

**Tools named or seen:** Blender and Claude (caption and post text). No plugin.

**Lessons for us**
- A power is a small kit: a coloured ring pad on the ground that names the element, one hero mesh, two or three kinds of particle. That is the structure of the `ring`, `emitters` and `beams` fields in `Effects.luau` (`docs/vault/01-game-design/Roster-Redesign.md` section 6).
- Mesh VFX (rings, columns, ribbons, shards) are cheap MeshParts and can be built headless in Blender the way `tools/blender/species_sculpt.py` builds bodies; the motion stays on the Roblox side as tweens, so there is no animation export to solve.
- One accent colour per pad on a dark, warm-lit ground is why seven effects read as seven different things in a one-second cut: our element colours should be assigned the same way.
- The showcase format (orbit, one power per beat, pull back) is a good template for a hero-alien effects preview video.

### ZPLSQAq5q: "+1 Titan Charge, Common to Legendary" (jarvislabsreal, 0:17)

Post text: "which titan are you picking? +1 titan charge drops on roblox tomorrow".

**Shown (no voice; Whisper: "Music"):** a caption, "+1 TITAN CHARGE / COMMON TO LEGENDARY", over a plain blue-grey studio backdrop with a graded floor and soft contact shadows (it looks like a Blender render, not the Roblox engine). One character model turns slowly each second, fourteen in all: an ice-spiked blue titan with crystal claws, a blue-and-white robot with a gold lightning-bolt chest emblem, a red-shirted fighter with gold gloves, a boxer with a punching bag, a weightlifter with a barbell over his head, a drummer in a red hat, a black knight with a sword, a purple ice king with a staff, a gold spiked brute swinging two chain flails, a boxer in a green parka, a shield-and-spear guard, an ice king on a fountain, an ice serpent coil, an angry ice golem with spiked fists.

**Construction, read off the frames:** every character is a stack of bevelled cubes: a cube head about 40% of the body height, a cube torso, block limbs, with faceted low-poly "ball" hands and feet (small icospheres) and cone spikes; flat saturated colours, three or four per model; thin gold bands as trim; an emblem built as stepped pixel geometry (the lightning bolt is a staircase). The face is a pixel-art texture on the front of the head: two big eyes as ringed pixel discs on a coarse grid, small pink cheek squares and a tiny mouth, changed per character (worried, fierce, cheerful). The class is readable from the held item (gloves, barbell, drum, sword, shield) and the colour theme (ice, gold, red, black).

**Tools named or seen:** Blender (post tag `#blender`, the render look). Nothing else; no texturing tool is visible. The pixel face is a plain image texture on a cube face, the kind Blockbench's paint tab makes natively and Blender can also take (inferred; the video shows neither).

**Lessons for us**
- A cube head with a pixel face texture, bevelled blocks, faceted ball hands and cone spikes is a simple, blocky build that should sit well inside our 1,000 to 2,500 triangle budget, and it reads at 64 px from the item and the colour alone, as our silhouette pass wants (`docs/vault/06-art-pipelines/Silhouette-Pass.md`).
- The pixel face is the argument for Blockbench in our chain: pixel-accurate painting of a small face texture on a cube is exactly what it does, and no Substance coat is needed for this look (flat colours, one texture). That is inference; no video shows the tool.
- Fourteen models, one second each, is a lineup format worth reusing for a "meet the roster" post and for the Aliens-screen header art.
- The tiers are in the caption (Common to Legendary), not in a rarity colour on the model: the model carries the theme, the card around it carries the tier, as in `docs/vault/05-ui-design/UI-Playbook.md`.

### ZPLSxw532: "Titan transformation" (jarvislabsreal, 0:10)

Post text: "it drops tonight 6pm est, +1 Titan Charge on roblox, built with ai... OG code + giveaway (3 x 400 robux) in our discord".

**Shown (no voice; Whisper "[Music]"):** a caption "TITAN TRANSFORMATION" with a bolt. 0 s: the arena of ZPLSQ1o7Q at dusk under heavy grey cloud, a tiny black figure at the centre between two pillars, camera low. 1 s: one full-white frame. 2 to 3 s: a white bloom burst at the centre, streaks of lightning, sparks and dark debris falling, the floor runes glowing, a column of smoke. 4 to 5 s: the silhouette grows through the light into a giant, still dark, white eyes glowing, lightning crawling on it. 6 s: thin orange lines begin to light from the feet upward. 7 s: the whole armour is lit, orange neon lines on every plate and fist, a warm glow bleeding into the fog. 8 to 9 s: hold, with the caption "+1 TITAN CHARGE / OUT TONIGHT 6PM EST".

**Tools named or seen:** none by name; the post says "built with ai" and the hashtag `#claudeai`. The titan is a stack of dark plates with emissive orange trim (Neon material in Roblox terms), the clouds and sparks are particle layers, the white flash is a full-screen frame, the bloom is Roblox lighting (inferred).

**Lessons for us**
- A three-beat transformation: a flash that hides the cut, a silhouette in light and smoke, then the detail lighting in sequence from the feet up. It is the shape of our reveal ("tap to crack", shards and rays, the card), with the light-up-in-order beat as the new part, for the Cosmic and Secret tiers (`docs/vault/01-game-design/Roster-Redesign.md` section 6).
- The glow lives in thin emissive stripes on a dark body, not in a colour change of the whole body: our Neon slots (a slot property in `materials.json`, planned into the recipe) can do this once a species has the stripes as their own slot.
- A low camera, a slow push and heavy fog make a small model feel huge; use it for the hero aliens, not for common ones.
- It is a teaser: the end card names the drop time. Our store-page clips can end the same way.

### ZPLSQAhnb: "24 hours: a Claude model + Blender + Claude Design" (jarvislabsreal, 1:27)

Post text: "What should I upgrade next?"

**Shown (the clip is a screen recording of the same game in the same letterbox as ZPLSQA4aX; the music track has lyrics, which Whisper transcribed as nonsense and which are not the creator):** a caption, "24 HOURS / [a Claude model] + BLENDER + CLAUDE DESIGN", over a blurred zoom. In order: a Starter Pack pop-up with an "ENDS IN" timer (0 to 1 s); the Store list (3 to 5 s, the "before" of ZPLSQA4aX); a Skill Tree of hexagon nodes in six branches (Money, Offline, Power, Charge, Luck, Mutation) with an "OWNED" bar (6 to 10 s); Rebirth with a before-and-after arrow (12 to 13 s); the Index, a grid of cells with model renders, a rarity word and an income per second ("Uncommon, $89/S", "Rare, $400/S"), and a green "MANAGE PEDESTALS" button (14 to 17 s); Daily Rewards, a seven-day calendar with a big Day 7 gift and a green CLAIM (18 to 20 s); Playtime Rewards, a 3 x 4 grid of twelve timed slots from 0:30 to 2:49:30 with a rarity word, a lock and a red countdown pill each (21 to 22 s); the Daily Spin wheel of eight coloured segments with "SPIN!" and "YOU WON x2 MONEY 5m" (23 to 34 s); the Titan Armory and its list with EQUIP, EQUIPPED and price buttons (36 to 44 s); the Serum Lab list with "$10K BUY" and LOCKED (45 to 49 s); a "HOLD TO CHARGE" mechanic with a rainbow progress bar, a growing glow and speed-line bursts, then a fall-off with "10B!" pop-ups (50 to 76 s); a "ROLLING..." reel of tall rarity-coloured cards behind a gold diamond-ended selector (79 to 81 s); "YOU GOT" with rays and sparkles over a yellow SECRET card (81 s); the result card and a character with a fire aura (82 to 87 s). All panels use the rainbow-rim neon dialect that ZPLSQA4aX then replaced for the shop (posted a day later).

**Tools named or seen:** a Claude model, Blender and Claude Design, all three in the caption; the game's models appear as renders in the Index and the reel (the same cube-head characters as ZPLSQAq5q). No plugin, no Studio window.

**Lessons for us**
- The caption is the creator's own account of the chain: a Claude model writes the code, Blender makes the models and effects, Claude Design makes the screens; 24 hours for the lot. Again no Blockbench and no Substance Painter.
- It is a checklist of what a competing collector ships in a first day: shop, skill tree, rebirth, index, daily rewards, playtime rewards, a wheel, two equipment shops, a charge mechanic and a roll reel. We have most of them; the playtime gifts (milestone 49) are six cards where this grid shows twelve at once with locks and countdown pills, which is worth a look when that screen is next touched (`docs/vault/05-ui-design/UI-Playbook.md`).
- The roll reel (tall cards, a selector, "YOU GOT" with rays over the winner) is a second reference for the reveal's valuation beat, after ZPLSaNotv in batch 6.
- The model renders in the Index cells (cube-head characters on a tinted cell with a rarity word) confirm the route we already use for icons: render the model, do not draw a second asset.

### ZPLSxwKHm: "Farm Showdown has lost the plot" (vos_studiostt, 0:12)

The file is byte-identical to ZPLS5oJs2 (same size, 1,545,133 bytes, same MD5), saved from a second share link with a different post text. The batch 6 section on ZPLS5oJs2 already describes it: a farm game, then three Claude Design 3D viewers (a hydra, a dragon, an axolotl) each turning on a glowing ring with particles. Whisper heard only music. Tools: Claude Design and Roblox Studio, nothing else.

**Lessons for us**
- Nothing new; do not process the file again. The ring-and-particle recipe is in `docs/vault/01-game-design/Roster-Redesign.md` section 6.
- Counted for the record: of the nine items Ethan sent in batches 7 and 8, two are repeats of batch 6 and one is off topic, so the new material is six.


---

## The design reference ZPLSHwXqp (2026-10-14, noted 2026-10-15)

Ethan, 2026-10-14 night: "Look at how this tik tok does their designs. Be able to replicate this and use the same skills." The Mac downloaded it (overnight job 25, `9bc248d`) without watching it, and the **GAP** row in `docs/vault/00-start-here/Asks-Ledger.md` stayed open until now. Processed in the cloud session with the Whisper base.en model directory in `SHERPA_WHISPER_DIR` (the variable `tools/watch_video.py` reads) and `python3 tools/watch_video.py media/tiktok/ZPLSHwXqp.mp4` from the repo root: 16 frames, one 4 x 4 sheet, the transcript, in `media/tiktok/out/ZPLSHwXqp/` (scratch, not committed). The sheet and transcript were read, then 32 frames at full resolution (every half second, 1080 x 1080) and the first second at 15 frames a second for the chat text. The creatures were sampled for colour with Pillow after masking the grass-green background; a phone filmed a monitor, so hex values are approximate (bloom and glare lift them). The frame sheet kept for the vault is `docs/vault/06-art-pipelines/refs/tiktok-ZPLSHwXqp-design.jpg` (12 frames, 0 to 14.7 s).

| Code | Creator | Length | Title |
|---|---|---|---|
| ZPLSHwXqp | jubydandev (channel jubydan) | 0:16, 1080 x 1080, posted 2026-10-05 (51.2K views, 3.4K likes at download) | post text "join the community Hemin Studios #roblox #game #gamedeveloper #fyp #viral"; on-screen caption "first two weeks of roblox development w/ claude"; sound "original sound" (a music bed) |

**The finding up front: the clip shows finished designs and no design process.** Whisper heard `[   0s] [Music]` and nothing else. The creator never speaks, and no modelling tool, menu, setting or step is on screen: no Blender, Blockbench, Substance Painter or Studio mesh tool, only Studio's Home ribbon around a running game. So the tool, operation, settings and order of the creator's modelling are NOT in the video, and nothing below invents them. Each claim is tagged SEEN (on screen), READ (legible text) or INFERRED (my reading of the frames; the video does not show it).

**Shown, by second (a phone filming two monitors)**
- 0 to 1 s. The left monitor is a Claude chat. Beside the conversation sits one finished image with a "Download as PNG" control above it: key art of a red and gold phoenix bursting out of a golden cage into a bright sky full of confetti, a Roblox avatar with a shocked face at the left, a small title strip at the top (its feathers look like stepped cubes). READ, with the left edge cut off by the screen: "...ual look into the", "...gle, Miner", "...rple three-headed", "...ry setup behind.", "...s high above the", "...ic). Want #3 redone", a grey bubble "...ry, always seend them here" (typo included; probably the creator's own message), "...m your library.", "...lowed to download", "...brary automatically,", "...sfield (select them in". A model picker label sits under the input box; its name is deliberately not copied here.
- 1 to 3 s. A swish to the right monitor: Roblox Studio (Home ribbon: Character, GUI, Script, Import, Material, Color, Group, Lock, Anchor, Explorer, Properties, Toolbox, Assets) with the game "Digsite" running. A brown dig pit with a yellow rim, three chunky studded top buttons (Digsite blue, Pen green, Sell pink), icon tiles down the left, a pickaxe tool button, "AUTO MINER" (locked), "PIT REFILL 12:02".
- 3 to 4 s. A stock Roblox avatar holds the Dark Matter Pickaxe: a purple, stair-stepped (pixel) pickaxe with glowing veins and a soft purple halo. An orange tutorial banner with a stud pattern: "1/8 Tap DIGSITE at the top to go to the dig pit!"
- 4 to 7 s. Void Hydra, rarity word Secret, popup "+$2.0M". A squat near-black navy body on four thick legs, three necks with purple horn spikes, a chest and belly of glowing magenta cells, a flat cyan halo disc floating above. Every part is the same small cube (the stair-steps show on the legs, tail and horns); by eye the cell is about 1/30 to 1/40 of the creature's height. At 6 to 7 s it dissolves into a violet pixel-grid dither, cells vanishing in a noise pattern, with white bloom puffs either side.
- 7 to 10 s. The Phoenix arrives: banner "Phoenix is back home!", tag "Mythic / Phoenix / $102.4K/s", buttons "Lucky Spin" and "Rewards". Front-on, wings spread: a red leading edge, two or three rows of overlapping red, gold and orange feather cards under it, a chest of gold feather scales each edged in navy, a gold crest, orange thighs, navy talons. The wings beat (motion blur) and leave two large white-gold crescent sweep trails. A prompt "E / Pick up".
- 10 to 13 s. The Celestial Dragon: banner "Dragon is back home!", tag "Mythic / Celestial Dragon / $409.6K/s", popup "+$409.6K". A long blue body speckled with stars, cyan glowing eyes and mouth, Y-shaped yellow horn spikes, gold claws, and a tail made of dark navy cubes each carrying an orange stripe. White fog puffs and cyan sparkles around it.
- 13 to 16 s. The Pet Index, a green studded panel: "Found 5 / 52 pets", "CLAIM +3% LUCK!", one row per habitat (Dirt Burrows, Sakura Grove, Frost Caverns, Glowshroom Hollow, Magma Core, Cosmic Void) with a themed picture strip, "???" cards coloured by rarity (grey Common, green Uncommon, blue Rare, purple Epic, gold Legendary, pink Mythic, teal Secret) each with "1 in N" (1 in 4.1 for a Common, 1 in 418 for a Legendary, 1 in 4,182 for the Mythic, 1 in 50,000 for the Secret Void Hydra), and a cage at the row's end with a reward ($5,000 up to $1.50B) and "Find all 8". A five-slot hotbar below shows model renders: Dark Matter Pickaxe, Aurora Jelly, Cat (a cube-head voxel cat), Phoenix, Void Hydra.

**What the creator does, as far as the clip supports it**
1. A concept image first (SEEN and READ): a Claude chat makes numbered concept options, one is redone by number ("Want #3 redone"), and the pick is a PNG with a download control. The key art's phoenix already has the colours (red, gold, orange) and the wings-spread pose of the in-game Phoenix, but not its construction (stepped cubes in the art, shingled feather cards in the game), so the image fixes colour and pose, not the build.
2. The creature built in the game (INFERRED; not shown): three constructions sit in one game. Cube cells of one size (Void Hydra, the cat, the pickaxe, the fences and lamp posts). Overlapping feather cards (Phoenix). A smoother body with a star-speckle surface and a chain of cube segments for the tail (Celestial Dragon). The caption says the work is done with Claude, but which tool made which mesh is not shown. A grid of equal cells plus a dissolve that removes cells in a noise pattern fits a creature written as a grid of cells by a script; that is a guess.
3. The arrival staged (SEEN): a banner, a rarity-coloured tag with name and rate, an income popup, a halo disc or sweep trails, bloom, fog and sparkles, the creature shown front-on with its wings out.

**What makes the result read as finished**
- **Shape language.** One construction unit per creature, held on every part of it: a cube cell, a feather card, a cube chain. The big masses come first (a squat body and three necks; a wing as one swept shape; one long S-curve) and the unit second, so the silhouette reads before the surface does.
- **Proportions.** The Mythic and the Secret are huge against the avatar (by eye at 10 s and 12 s: about four avatar heights tall or long, a phoenix wingspan of more than eight avatar widths): rarity is scale. The small cat in the hotbar is the opposite, a cube head about as wide as its body.
- **Face.** None of the three epic creatures has a readable face; the eyes are glow points (yellow on the phoenix, cyan on the dragon, magenta cells on the hydra). They are not cute and do not try to be.
- **Colour.** Three hues and a near-black anchor each. Hydra: near-black navy body (#061147, #060D84, luminance 0.07 to 0.09) with violet (#6C08D2) and magenta glow and a cyan halo. Dragon: deep blue (#0E4BA3, #040B5B) with cyan (#45AFD0), gold claws and yellow horns. Phoenix: red (#8B1A26 where lit) with gold and orange and a near-black navy ink (#12101E) on talons and feather edges. The accent sits across the wheel from the body (blue and gold, navy and magenta, red and gold), and all three stand on a bright green field, so value contrast does the silhouette.
- **Outline.** No outline shader on any creature. The dark ink is built into the pattern (navy edges between the phoenix's chest feathers, navy legs and talons), and the UI wears thick dark outlines on every button.
- **Texture.** The pattern is the geometry or a painted motif: cube cells, feather rows, star specks. Flat colour elsewhere; no noise-only surface.
- **Lighting and glow.** Emission is drawn as lines and cells (the hydra's belly, the eyes), not whole parts, plus a halo disc, bloom, fog, sparkles and trails. The dark Secret glows; the bright Mythic is lit by its own colours.
- **Staging.** Every arrival has the same stack: banner, rarity-coloured tag with name and rate, popup, ring or trail, and the creature in its hero pose.
- **One idiom, partly.** The fences, lamp posts, pickaxe, cat and hydra share the cube; the buttons, banner and index share a brick-stud motif that echoes the baseplate's studs. The trees are smooth blobs and the ground is Roblox's stock stud texture, so the idiom holds for creatures, props and UI, not for the whole world.

**Which of these skills our pipeline already has**

| The clip does | Ours today | Verdict |
|---|---|---|
| One seamless creature, no joins | the hybrid sculpt, `tools/blender/species_sculpt.py --method hybrid`: one fused skin, crisp parts on it, seven slots, 2,500 triangles | ahead of the clip (its creatures are cell and card assemblies); keep |
| Silhouette first, one hero feature | `silhouette` and `hero` in `tools/blender/species_recipes.py`, the 64 px grey check in `preview.py` | have |
| Rarity is scale, the Secret dark and grand | the rule in `docs/vault/06-art-pipelines/Character-Pipeline.md`, the effects ladder in `docs/vault/04-roblox-engine/Species-Effects.md` | have (a written height-per-tier ladder is not) |
| Glow | `glow` per slot in the recipe, `materials.json` emission, Neon in `tools/studio/install_models.luau` | have, whole slot only |
| Palette and clean UV islands | `tools/blender/unwrap_bake.py`: 512 px atlas of slot hex times the vertex gradient, optional AO | have, flat colour only |
| Tiled surface textures | the Surface pass, `tools/blender/bake_textures.py` (fur, moss, stone, ice, scales) | have, generic; not in the atlas |
| Model renders as icons | `tools/blender/icons.py` | have |
| Concept image first | `docs/vault/05-ui-design/Claude-Design-Brief.md` critiques a turnaround | partial: no numbered options, no redo by number, no arrival art |
| Cube-cell build | nothing (`species_recipes.py` has a `cube` primitive, no grid quantiser) | lacks |
| Feather, scale and star rows with an ink edge | nothing | lacks |
| Glow as lines and cells | nothing (no emissive map) | lacks |
| Moving wings, a segmented tail, a display pose | nothing in code; `Suiryn` is planned with three kept body segments (`docs/vault/01-game-design/Roster-Redesign.md` section 7 step 3) | lacks |

**Lessons for us: how we replicate it (the five skills to add, in order)**
1. **A cube-cell build route (`--method voxel`) for the epic tier and for props.** Tool: `tools/blender/species_sculpt.py`, which already builds the recipe's metaball field. Add a method that samples that field on a grid at one pitch (a data number, start at 1/12 of the species' height), keeps the filled cells, merges coplanar faces (greedy meshing) and gives each cell the slot with the largest field (the hybrid's rule), then writes the same GLB and notes. Pilot: Panpipe (the one Secret row in `src/shared/data/Species.luau`) or the Skydrake prototype. Check: the triangle count per pitch. The clip's hydra, at about 1/30 to 1/40, would run far past our 2,500 cap (Roblox's own limit is 20,000 a mesh), so the prototype reports triangles per pitch and Ethan chooses a chunkier cell or a hero budget. It is a different house look from "seamless, fluid", so it is his call whether it sits beside the soft skin at all.
2. **Pattern rows with an ink edge, painted on the atlas.** Today `unwrap_bake.py` writes one flat hex per slot and leaves tiled textures out. Add a `pattern` entry to a recipe slot (`motif`: feather rows, scales or stars; `ink` hex; `rows`; cell size), rasterised in UV space by the numpy raster that script already runs, with the ink as a one to two texel edge between cells. For a hero species the same motif is hand-painted in Blockbench on the `tools/blockbench/to_bbmodel.py` project (the palette already goes in) and re-imported. Check: `preview.py --lit --textured`, then the 64 px grey shape (the motif must not change the black shape). Pilot: the Skydrake's scales.
3. **An emissive line map.** Today a slot glows as a whole (`materials.json` emission becomes Neon in `tools/studio/install_models.luau`). Add `<Id>_emissive.png` to `unwrap_bake.py`: a mask of cells, cracks or rings per slot from a `glow_lines` entry, the whole slot as the default, wired as the SurfaceAppearance emissive mask (`docs/vault/06-art-pipelines/Character-Pipeline.md` section 2.5 lists the map; confirm the property name in the Creator docs when wiring). The upload is the Mac's textures route. Fallback with no new map: a `Rune` slot of small separate glowing faces in the hybrid. Pilot: a dark Secret body.
4. **Articulated hero parts and a display pose.** The hybrid fuses wings and tail into the skin, so nothing can beat or sway; the clip's phoenix beats its wings and its dragon's tail is a chain. Extend the Suiryn plan: `species_sculpt.py` takes a per-species `split` list (wing_L, wing_R, tail_1 to tail_n), each part its own mesh in the same GLB with its pivot on the joint; `install_models.luau` parents them under one Model with welds; the client tweens their CFrames from data (flap rate, sweep angle), the "tweened MeshPart motion" route of Character-Pipeline. Add a second recipe pose, wings out and front-on, for the reveal card and the index icon. Check: the split and unsplit builds render the same at rest (`preview.py --compare`).
5. **The numbered concept loop and arrival key art.** The chat shows numbered options, one redone by number, the pick as a PNG. Add a hero-tier step 0 to Character-Pipeline section 3.2: three or four numbered concepts per hero species in Claude Design (or the chat), the pick redone by number until colour and pose are settled, then written into the recipe's `silhouette`, `hero` and `palette` before any Blender run; plus one arrival key art per tier (the creature bursting from its egg, a surprised avatar, confetti) for the store thumbnail comps (`docs/vault/01-game-design/Thumbnail-Research.md`). The concept PNG sits beside the recipe note in `docs/vault/06-art-pipelines/refs/`.
- Two cheap rules, no code: write a rarity-to-height ladder in `docs/vault/06-art-pipelines/Look-Plan.md` (the clip's Mythic is about four avatar heights), and render one frame with a creature, a prop and a button at the game camera's distance before a style is called finished.
- Do not copy: the brick-stud UI motif (our UI Playbook has its own), the dollars-per-second tags (our one currency is Scrap), or the cell count of the hydra. The index's "1 in N" per cell is fine for free drops; the paid-random rules in `CLAUDE.md` stay as they are.

**Tools named or seen:** a Claude chat that returns an image with a PNG download (its product name is not on screen, so it is not assumed to be Claude Design) and Roblox Studio (Home ribbon only). Nothing else, and no Blockbench or Substance Painter. No new `docs/vault/02-how-we-work/Tools-Status.md` row: both are already tracked.

## Batch 9 (2026-10-21): monetization and the click

Three links from Ethan, downloaded by the Mac (job 41, `98547f2`): "They are super helpful and should definitely be implemented into the game." Processed in the cloud with `python3 tools/watch_video.py media/tiktok/<code>.mp4` (`SHERPA_WHISPER_DIR` at the Whisper base.en model; the transcripts are good, cross-checked against the burned-in captions); the photo post read slide by slide. Every sheet, every caption and both transcripts were read; the four frames that carry the clip's screens (0:14, 0:37, 0:52, 0:53) at full width. Committed from `media/tiktok/out/`: the four sheets, transcript and info of ZPLAB8GM3, and only the first sheet, transcript and info of ZPLAkEnnf (all 102 s are one talking head, so the other six sheets add nothing).

| Code | Creator | Length | Topic |
|---|---|---|---|
| ZPLAB8GM3 | palm_dev | 1:02 | "3 niche tips that will help monetize your Roblox game" (post text: "Last one is probably the most important") |
| ZPLAk7qKN | bennettbenito | 6 slides (21 s of music) | "made over 5,000,000 robux ($20,000+) on my first ever roblox game in a month": the dashboard stats and three monetization tips |
| ZPLAkEnnf | machv10 | 1:42 | "3 secrets for insane Roblox CTR": thumbnails |

### ZPLAB8GM3: three niche monetization tips (palm_dev, 1:02)

A talking head in the lower half, game footage in the upper half, and a four-step tracker across the top that lights as he goes: SHOP, CHEAP 2x, ROBUX PROMPT, SHOW IT.

**Shown and said, in order**
- 0 to 3 s. "CRASH COURSE, Roblox monetization", "3 niche tips that will help monetize your Roblox game". "Obvious stuff first: you need a shop. It has to look good."
- 4 to 8 s (SHOP). A yellow-and-orange shop with a two-wide Starter Pack card ("BEST VALUE!" ribbon, "1 SET + your next slingshot free! ONE TIME ONLY!", 23 Robux) over a Pet Starter Pack, with callouts STARTER PACK, BEST VALUE TAG, CLEAN ICONS, GLINTS ON THE BUTTONS. "When I open it I should be tempted to buy something: a starter pack, a best value tag, clean icons, glints on the buttons."
- 9 to 20 s (CHEAP 2x). A cash-pack page (+66% more, +257% more, +368% more, +1011% more on the bigger packs) and a "2x Speed Forever, +80 Speed/s instead of +40" card at **3 Robux** ("2X FOREVER = 3 ROBUX"). "One thing has to be cheap, like 2x cash or whatever your currency is; it should be under 10 Robux. That's a high payer conversion rate, so it signals to Roblox that people who play your game want to spend money, and they're going to push your game." A grid of player icons turning gold, an arrow to a card "ROBLOX SEES players spend here", then "PUSHES YOUR GAME" with a rising line.
- 21 to 42 s (ROBUX PROMPT). "90% of the games I playtest miss this": a trails screen, then a pet sim toast "Not enough Cash! This pet costs $16,000,000" and a red stamp SALE LOST. "When I click on something I can't afford, nothing happens; it says 'you can't afford this item'. That could be a sale." HOW IT SHOULD WORK: an Upgrades panel, a tap on an unaffordable row opens a Robux prompt, "Purchase completed". The method on a card: "MISSING $9,638,691" over five cash packs (+$100,000 for 5, +$300,000 for 9, +$1,000,000 for 14, +$3,000,000 for 32, +$10,000,000 for 45 Robux); the four too small are crossed out, the smallest that covers the gap stays; balance $6,361,309 becomes $16,361,309 ("+$10,000,000 PURCHASED") and the item is bought for the player. "Make a few cash packs, prompt the smallest one that covers the difference, and whenever it goes through, buy the item for them automatically." Then a plug for his prompt pack.
- 43 to 55 s (SHOW IT, the "most important" of the post text). "Not all of your monetized items should be hidden behind the shop button, because nobody's going to be tempted to open it. It should be physical, on the map or on the screen, or both even better. They should see what they can have before they open a menu." ON THE MAP: a "x5 WINS" pad on the walkway, signs over stations ("Upgrade Plot", "Upgrade Treadmill, Level 4 > Level 5, $5M") under a big green arrow. ON THE SCREEN: a column at the right edge with a gift-box Starter Pack and two offers ("5X STRENGTH, ONLY R$19", "2X WINS"). BOTH: the pad and the column in one frame. The left edge carries Shop, Upgrades, Quests, Index, Teleport buttons.
- 56 to 61 s. A Discord plug: "game feedback event every Saturday", 2,280 then 3,000+ devs, "110 players in one game at once".

**Lessons for us**
1. The shop must tempt on open: a starter pack, a best value tag, clean icons, a glint on the buy button.
2. One offer under 10 Robux, because the share of players who pay at all (payer conversion) is what tells Roblox that people spend here.
3. A tap on something the player cannot afford must never end at a bare "can't afford". His fix sells the missing currency for Robux and buys the item automatically.
4. Show the offers: on the screen and on the map, not only behind the Shop button. The creator calls this the most important.

### ZPLAk7qKN: 5 million Robux in a month, three tips with stats (bennettbenito, photo post)

Six slides over a music bed ("im not alone", no voice). Post text: "i'll be posting more videos like this so follow if you're looking to learn more about developing games on roblox!"

**Slide by slide**
1. "made over 5,000,000 robux ($20,000+) on my first ever roblox game in a month", "3 MONETIZATION TIPS (stats provided)", over his avatar on the Roblox app showing 3.5M Robux.
2. Creator Hub benchmark bars: payer conversion rate **2.10%** (down 19.3%), 87th percentile, where the 50th is 0.55% and the 90th 2.46%; average revenue per paying user **307.1 Robux** (up 19.3%), 90th percentile, where the 50th is 65.9 and the 90th 292.7; play-through rate 0.00% ("Request failed").
3. The same page on Daily: average playtime **37.6 min** (93rd; 50th 12.8 min, 90th 30.0 min); day 1 retention **16.60%** (88th; 50th 10.00%, 90th 16.90%); day 7 retention **1.88%** (76th; 50th 0.90%, 90th 2.94%).
4. "1. Scaling multipliers that start cheap. Sell a stackable 2x multiplier that starts at a low price and rises with every purchase. This captures the most value from players willing to spend robux"
5. "2. Server wide boosts. Sell a luck or cash boost that applies to everyone in the server and announce the buyer's name in chat. Everyone sees someone spending, and players become inclined to spend themselves or to extend the boost"
6. "3. Decoy pricing. Price the middle bundle so it looks like a bad deal next to the biggest one. Players skip it and jump straight to the top pack."

**Lessons for us**
5. The benchmark bars are the first real percentiles we have for payer conversion and spend per payer: a game in the top tenth has about 2.5% of its players paying and about 290 Robux per payer; the median is 0.55% and 66.
6. A stackable multiplier whose price climbs with each purchase (a product per level, since a developer product's price is fixed).
7. A server-wide boost, the buyer named in chat, that anyone can extend.
8. Decoy pricing: a middle bundle made to look bad so players jump to the top one.

### ZPLAkEnnf: three secrets for high click-through (machv10, 1:42)

One shot of the creator at a kitchen counter, caption "3 SECRETS FOR INSANE ROBLOX CTR" for the first 10 s, then "discord.gg/rblxdevs" to the end. No game footage; the content is all speech (Whisper, checked).

**Said, in order**
- 0 to 10 s. "If you're a Roblox dev and you're struggling to get high CTR thumbnails..."
- 10 to 30 s. "Number one, keep your thumbnail simple. I see a lot of Roblox devs over-complicating their thumbnails ... that all creates friction. The more complicated things you have in your thumbnail, the less likely someone's going to click on it ... a kid won't understand it. They have to understand it immediately."
- 30 to 60 s. "Number two, your thumbnail needs to match your game name. Look at Steal an Egg: if it had something completely random that made no sense, would people click? The key to a very high CTR thumbnail is transparency: people read your game name, look at your thumbnail and go 'this sounds like a really cool idea, I instantly understand this game'. If they can't immediately connect the two, you just missed a click."
- 60 to 102 s. "Number three, give people a reason to click. What makes your game so interesting that somebody wants to click the second they see it? Stealing an egg, stealing something from a dinosaur ... The best way is trial and error, and A/B testing. If you're not A/B testing thumbnails, more than one thumbnail, you're missing out ... see what your audience wants to play."

**Lessons for us**
9. Simple: one idea a child reads at a glance.
10. The picture says the name: Catch an Alien shows a catch and an alien.
11. A reason to click: the moment that makes the game interesting.
12. Run more than one thumbnail and keep the winner.

### Batch 9: what we already do, and what we add

Checked against the code, data and vault on 2026-10-21. "Before launch" means under a day of code, data or docs; the ones marked *built* are in this batch's commits.

| # | Lesson | Status | Where, or what is added |
|---|---|---|---|
| 1 | A shop that tempts: starter pack, best value tag, clean icons, a glint | **done** | the Shop shelf (`src/shared/data/Shop.luau` Cards: the Starter Pack two wide with the BestDeal ribbon and BestValue seal and the one shine sweep; pixel icons), `docs/vault/05-ui-design/UI-Playbook.md` "Shop shelf" |
| 2 | One offer under 10 Robux, for payer conversion | **before launch, needs Ethan** | our cheapest is Speed Burst x5 at 49; Decide-Now 47 |
| 3a | A tap you cannot afford never ends at a bare "can't afford" | **before launch, built** | every Scrap refusal says how much more Scrap is needed (`ShopMath.ScrapShort`, `TOAST_SCRAP_SHORT`) |
| 3b | ...and prompts Robux for the missing currency, then buys the item | **not copied** | it sells Scrap for Robux, which the one-currency rule forbids (`CLAUDE.md`, data/Shop `NeverSold`); Decide-Now 48 asks Ethan to confirm |
| 4a | Show the offers on the screen | **before launch, built** | a Starter Pack button in the HUD's top row until it is bought; it opens the Shop on the Featured shelf |
| 4b | Show the offers on the map | **week one, other workers** | upgrade signs over the stations with the next level and its Scrap price, a shop stand at the camp: props and world data, left for the coordinator |
| 5 | Payer conversion and spend-per-payer benchmarks | **before launch, built** | `docs/vault/01-game-design/Growth-Playbook.md` "Benchmarks from a creator's dashboard" |
| 6 | A stackable multiplier whose price climbs | **week one, needs Ethan** | nothing like it today; Decide-Now 49 |
| 7a | A server-wide boost that names the buyer, which anyone can extend | **done** | Server Luck x2 and x4 (`Monetization.startServerLuck`): the banner "%s bought %sx luck for everyone!", and the same bonus bought again adds its time |
| 7b | ...named in chat too | **before launch, built** | a system line in the general chat when a bought luck starts (`CHAT_SERVERLUCK_START`) |
| 8 | Decoy pricing | **not copied** | a bundle priced to look bad on purpose is a trick on a young audience; the honest half is done (the biggest Spins pack is the best per spin and wears the Best Value seal). Found on the way: Server Luck x4 is *worse* per point of luck than x2 (999 for +3.0 against 249 for +1.0); Decide-Now 50 |
| 9 | A simple thumbnail | **done** | `docs/vault/01-game-design/Thumbnail-Research.md` section 6 (one hero, zero to three words) |
| 10 | The thumbnail matches the name | **done** | Thumbnail-Research section 0 item 4 and section 9 (the Moment shows the catch) |
| 11 | A reason to click | **done** | the three arms Moment, Reward, Mystery (Thumbnail-Research section 8) |
| 12 | A/B test more than one thumbnail | **done** as a plan; the block-cell set is the store worker's | Thumbnail-Research section 10 (three active thumbnails through Roblox's personalization); the new set is the Launch-week cloud row "New store icon and thumbnails" |

Totals: 6 done (1, 7a, 9, 10, 11, 12), 5 before launch (3a, 4a, 5, 7b built; 2 waits on Ethan), 2 week one (4b, 6), 2 not copied (3b, 8).

## Batch 10 (2026-10-24, studied 2026-10-26): the character bar

### ZPLAV8hDw: "all models made with claude btw" (jubydandev, 11 s)

Ethan: "look at these models and be able to replicate these ideas and character design. We want to keep the sort of blocky look but these designs should be what we aim for." A pet game ("Diga pet update 1", egg hatching, rarities to Mythic 0.1%) shown in a custom model viewer with Idle / Move / Ability / Still tabs, height in studs, GLB and OBJ exports. Six pets on screen: a Blood Moon Wolf (Legendary), a Nightmare Stallion (Mythic), a kraken, a clockwork mammoth, a sea serpent, and a prompt document listing every pet by tier.

**What the models do** (frames in the coordinator's scratchpad, never committed):
1. **Still voxel.** Every body is cube cells, like ours, but the silhouette is posed and dynamic: the stallion rears, the serpent coils, the tentacles spread, the mammoth's fur hangs in layered strips. Nothing stands as a box.
2. **One world accent kit, worn by every pet of that world, more of it as rarity rises.** "Clockwork": brass bands, rivets, plate seams, a windup key on the back, gears, a gear ring round the face, steam pipes, a clock. "Atlantis": gold bands, barnacles between spikes, a gold shell, bubbles, anchors. The kit is what makes a world's roster read as one family.
3. **Rare and up carry a satellite set**: 6 to 10 small themed objects orbiting the body at mid height (red shards and a blood-moon disc behind the wolf; violet shards and bone pieces round the stallion; gold anchors and ship bits round the kraken; gears round the mammoth; gold pillars, bottles and bubbles round the serpent). The top tiers add one **big backdrop prop** (the moon disc, a halo ring with clock numerals) that frames the whole pet from the front.
4. **Three colour roles on every body**: a base in two tones (lighter underside), one emissive accent (crystal mint, flame magenta, rune yellow) and one metal accent (gold or brass). Eyes glow in the accent colour on rares.
5. **Energy is shaped, not sprayed**: flames are "layered teardrop forms" (the creator rejected the first pass as "spiky hair"); crystals are faceted shards; bubbles are rings. Each effect is modelled cells, so it reads at a glance from the game camera.
6. **Detail must read from the game camera**: "leave as is, unless the theme details are too small to see from above"; "the pipes must not look like a tail"; "remove any eagle-looking blocks"; "one smooth connected body, never a row of spheres".
7. **The prompt method**: a numbered list per tier (Commons, Uncommons, Rares, Epic, Legendaries) naming each pet's theme and three or four visible parts, with must-nots; work in rounds, each round shown side by side next to a Roblox avatar from the front and the side before the next; every pet gets an idle and a movement cycle plus an ability pose.
8. **The top tiers are fierce** (red eyes, fangs, an open jaw). That is the one place the reference and our [[Decisions]] B46 ("cooler or cuter, never fiercer") disagree; [[Decide-Now]] 51.

**Lessons for us** (the rules go in [[Blocky-Style]] section 10; the pilot is Decide-Now 51):
- Give each world an accent kit and put it on every alien of that world, by tier count: Verdant gets moss cells, vine wraps, blossom buds, amber sap drops and bark bands; Frostbyte gets frost rims, ice shards, snowflake studs, silver bands and aurora wisps.
- Rare and up: a satellite set of 6 to 10 modelled pieces on the signature-piece orbit, from the world kit plus the alien's own theme; Legendary and up add a backdrop prop; Cosmic and Secret add a ground aura ring.
- Pose the silhouette: every alien's idle is a stance, never a box at rest.
- Shape every effect as cells (teardrop flames, faceted shards, ring bubbles) before any particle.
- Keep the face rule and the height rule: cute at every tier (B46, pending Decide-Now 51), 2 to 3.5 studs (B45).
- Keep the creator's method: a per-tier prompt list with must-nots, rounds reviewed on a sheet beside the avatar, front and side.
- Inspiration only: no clockwork or Atlantis kit, no wolf, stallion, kraken, mammoth or serpent; our aliens keep their own anatomy ([[Blocky-Style]] section 5).

### ZPLAVdpnX: Ethan's UI reference (not yet downloaded)

Ethan: "examine this ui. See how everything seems complete and less basic. There is more going on while also looking clean and easy to navigate around. I want that replicated." Mac job 69 downloads it; the study follows.
