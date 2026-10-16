---
tags: [art-pipelines, references, x]
aliases: [X posts, X pass]
up: "[[Art-Pipelines]]"
---
# X posts: what Roblox developers say on X

The X half of Ethan's 2026-10-15 research ask ("YouTube videos and TikToks and X posts about how successful Roblox developers designed their models and UI"). The other half is in `reports/Roblox creature UI and Claude workflows.md`; this note closes the gap the [[Asks-Ledger]] marked. The full pass, 66 posts in four sections (creature and pet art, worlds and props, UI, VFX and animation), is `research_notes/Roblox creature UI and Claude workflows/x_posts.md`. Back to [[Art-Pipelines]].

**How reliable it is.** x.com cannot be opened from the cloud and the `site:x.com` search operator returns nothing, so every entry comes from a search-result snippet found with the search tool's domain filter (`x.com` and `twitter.com`): the author's own first 200 characters or so, nothing opened, no replies, no images, no video. Each date is decoded from the post's id (an X id encodes its posting time; it matched every date a snippet printed). Treat each row as a pointer to check, not as a tested fact. No studio posts process on X; the process posts come from individual artists, UI designers and tool makers.

## The ten most useful posts

| Handle | What it teaches | Link |
|---|---|---|
| @KenneyNL (2026-04-11) | Three cheap rules to keep low poly cute: round edges (even one segment), taper legs and vertical supports, squircle-like shapes | https://x.com/KenneyNL/status/2042894059748917694 |
| @R_xOrze (2025-02-20) | What a sellable pet kit holds: 80 pets with rainbow variants on recolourable textures, 16 eggs, 240 icons (three per pet, five pets per egg) | https://x.com/R_xOrze/status/1892593141410099213 |
| @MA_ABU (2025-07-16) | Grow a Garden's pet mutations were "simple Pet mutations VFX" by a contract artist: an effect over the same mesh, not a new model | https://x.com/MA_ABU/status/1945424462767358124 |
| @EGOTISMS_RBLX (2023-11-27) | Text outlines that fill the holes of letters: set the UIStroke `LineJoinMode` to Bevel or Miter (a reply says rounded fonts only) | https://x.com/EGOTISMS_RBLX/status/1728978450889986339 |
| @Abstractalex (2024-03-06) | UIStroke thickness has no Scale option, which makes outlines look wrong across phone and tablet sizes | https://x.com/Abstractalex/status/1765232017783087369 |
| @KVetteJ (2022-04-28) | Decor meshes: collision fidelity Hull where physics is not precise, non-collide plus Box where never touched; saves memory | https://x.com/KVetteJ/status/1519488089856614406 |
| @Bethink_RBX (2020-02-27) | Adopt Me's creative director shared a generic cartoon lighting preset; the settings are in an image the snippet cannot show | https://x.com/Bethink_RBX/status/1233038898026209281 |
| @dryw3st (2026-02-18) | The viral "Claude built a Roblox game in 4 days" post says "fully scripted"; the art and UI claims come only from relays | https://x.com/dryw3st/status/2024268269608112238 |
| @GenAIRoblox (2026-03-20) | The setup people run: Claude to the Studio MCP as the main line, the Blender MCP only when needed, all in one chat | https://x.com/GenAIRoblox/status/2035108509595971597 |
| @Shigeon_Sir (2026-03-08) | A Blender-to-Studio export plugin exists because FBX scale and export settings are the recurring failure of the hand-off | https://x.com/Shigeon_Sir/status/2030478225223152019 |

## What we take

- **[[UI-Playbook]]** (and `Builder.stroke`): add two stroke rules. Set `LineJoinMode` to Bevel or Miter on the text stroke and test the counters of Fredoka One at a large Text Size; and size the stroke from screen height with a clamp, because UIStroke thickness cannot take Scale and a fixed 2 to 3 px is thinner relative to text on an iPad than on an SE. **Applied 2026-10-15**: `Theme.Stroke.TextJoin` (Bevel) and `ShapeJoin` (Miter), thickness from the screen height between 0.8 and 1.2 of the 1080 look; see the "Font and text" rules in [[UI-Playbook]].
- **[[Map-Dressing]]**: in `src/shared/Props.luau` set `CollisionFidelity` on every placed prop (Box when `CanCollide` is off, Hull for walk-on props). The importer sets `Anchored`, `CanCollide`, `CanQuery` and `CanTouch` today and never the fidelity. **Applied 2026-10-15**: a `collision` row per prop in `src/shared/data/Props.luau`, set by `Props.Place`; see "Collision" in [[Map-Dressing]].
- **[[Roster-Redesign]]**: keep rarity and mutation as an effect and a recolour on one mesh, as Grow a Garden and Pet Simulator 99 buy them (one named effect per ability from a VFX artist), and plan three icons per species (normal, gold, rainbow) and the glow regions as material slots now, not as a repaint later. **Applied 2026-10-16.**
- **[[Character-Pipeline]]**: add Kenney's three rules as cheap ship checks next to the three render checks (a bevel on every hard edge, limbs that taper root to tip, a plan outline closer to a rounded square than a box), and model against the Roblox dummy at the origin so scale and pivot arrive right (Erythia, 2019). **Applied 2026-10-16.**
- **[[Blender-MCP]]**: nothing on X changes the route. The loudest Claude-and-Roblox claims are relays or templates with no output in the snippet, the one primary source says scripting only, and the shared setup (Studio MCP main, Blender MCP on demand) is ours. The weak link people name is the Blender to Roblox hand-off (an upload plugin by hand, FBX scale), which `tools/blender` and the Open Cloud upload tool already cover. **Applied 2026-10-16.**

## Leads for a logged-in browser (the Mac)

- Open the Bethink post above and copy the lighting numbers from the image, then compare them with the world lighting data after the Technology to LightingStyle change ([[Look-Plan]]).
- Crykee's "How I built Adopt Me's 2021 Halloween environment (Realtime)" talk appears only as a title in a search summary; find its link from his X profile.
- The replies under the EGOTISMS stroke post, to see which fonts the join-mode fix works on.
- Tools named by posts and not tried: Bloxender (Blender-style modelling and an agent inside Studio, @Dinonotdilo, 2026-07-29), the free Roblox-to-Blender importer (@CAUTI0NED, 2026-08-27) and VFX Forge's mesh-VFX flipbook videos (named by @doublecats1, 2026-02-08). None has a [[Tools-Status]] row, because none came from Ethan or a reference he sent; the coordinator decides.
