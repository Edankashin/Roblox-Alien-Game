# Performance budget inventory

Regenerate: `python3 -I tools/perf_report.py --write` (default eight players; `--players N` changes the scenario).

Inputs: all src Luau (fingerprint `73b09731dd3dc5f4`); Layouts → Home/Meadow/Frostbyte, Config, Camp, Jobs, Modules, Spawns, KeyMaterials, Companions, HomeBuild, Habitats, Weather, Sightings, Compass and Spins. Uses the C2 table reader in lint_data.py. Source constants and reviewed construction formulas supply part multipliers; no Roblox execution, assets downloaded, or game changes.

Connection discovery scans comment-stripped source for direct event `:Connect` calls. Descriptions trace current callbacks and their helpers manually; this is not a Luau call-graph proof. New unannotated connections are flagged; changed callback behavior requires annotation review. Counts describe one client at the stated player count, not the sum across clients.

## Frame connections (16)

| Source | Event | Work / scenario | Bound | Cadence | Allocation evidence | Suggestion |
| --- | --- | --- | --- | --- | --- | --- |
| src/client/UI/CaptureBar.luau:564 | RenderStepped | 1 ticker, fixed zone positions and countdown | Fixed | every frame while capture active | No recurring table-building loop found | Keep fixed-size capture updates. |
| src/client/UI/CodexScreen.luau:895 | RenderStepped | 1 selected model/part | Fixed; grid is not rotated each frame | every frame while open | No recurring table-building loop found | Keep rotation limited to selected detail. |
| src/client/UI/Compass.luau:307 | Heartbeat | 24 ticks/letters + 8 markers | Data-bounded passes | every 0.05s | Existing shown tables cleared/reused | Keep marker count bounded. |
| src/client/UI/GiftsScreen.luau:467 | RenderStepped | 9 wheel labels | Spins.Segments fixed | every frame only during spin | No recurring table-building loop found | Keep temporary connection disconnected after spin. |
| src/client/UI/NearbyPanel.luau:435 | Heartbeat | ≤6 biome species entries across condition lists; display rows capped | Data-bounded; reads Spawns lists, not live wild records | every 1s | YES on poll: temporary ids/seen/absent/condition tables | Reuse scratch buffers; refresh on biome/weather/codex changes. |
| src/client/UI/PeddlerScreen.luau:515 | Heartbeat | 1 countdown label | Fixed | countdown every 1.0s while open | No recurring table-building loop found | Keep timer gated. |
| src/client/UI/Radar.luau:580 | Heartbeat | S wild children (112 scenario), pooled blips at retained high-water count | Grows with spawns/blips | heading every frame; blips every 0.1s; ping pass on beat | YES on poll: GetChildren(); YES on beat: one tween goal table per visible secret ping | Cache wild membership; reuse ping animation objects; trim oversized idle blip pool. |
| src/client/UI/Reveal.luau:598 | RenderStepped | 1 reveal model | Fixed | every frame while reveal model exists | No recurring table-building loop found | Keep connection teardown on close. |
| src/client/UI/ShipScreen.luau:658 | Heartbeat | ≤5 module rows and their button children | Module count fixed; UI children source-built | every 0.25s while open | YES on poll: recolorButton calls GetChildren() | Cache button text descendants when rows are built. |
| src/client/World/CampRenderer.luau:625 | RenderStepped | up to 9 seated workers | One local camp; station count × StationMaxSlots | every frame | No recurring table allocation found | Keep worker cap; profile mesh PivotTo cost. |
| src/client/World/CompanionRenderer.luau:512 | RenderStepped | 8 owners; 40 follower records checked, at most 24 visible moved/raycast | Grows with players; MaxSlots per owner, MaxRendered for drawing only | every frame; culling every 0.5s | YES every active frame: excluded={} and GetPlayers(); culling allocates drawn/candidates/rows | Cache character/folder exclusions on membership changes; reuse culling buffers. |
| src/client/World/HomeRenderer.luau:539 | RenderStepped | up to 6 displayed aliens for ONE viewed home | Data cap; not multiplied by visitors | every frame at home | No recurring table allocation found in onRender/placeDisplay | Keep habitat caps; profile imported models. |
| src/client/World/NodeRenderer.luau:206 | RenderStepped | 0 at home, 16 material records per wild world | Data node sum | every frame | No recurring table allocation found | Keep count data-driven; distance-cull if expanded. |
| src/client/World/SightingRenderer.luau:332 | RenderStepped | 1 live Warden record | Server single active sighting | every frame | YES on trail steps: dropPuff creates two tween-property tables, Part and light | Pool trail parts/lights and reuse immutable tween goals. |
| src/client/World/WildRenderer.luau:728 | RenderStepped | S tracked spawns; density scenario 112; Blizzard also S × H heater tests on evaluation | Grows with records; H up to 16 active heaters; NO hard S cap | every frame; visibility every 0.25s | YES at Blizzard evaluation: GetChildren() + one heater record per heater | Bound global spawns and skip hidden/distant bob/PivotTo; cache heater membership. |
| src/client/init.client.luau:1595 | Heartbeat | nearest wild S (112 scenario), nodes ≤16; ship modules ≤5; home displays ≤6 | Wild grows; other passes data-bounded | action 0.1s, ship 0.5s, biome 0.5s, shower 1s | Polling callback; no unconditional per-frame table-building loop found | Share nearest-target index with wild/radar scans. |

Server frame connections: **0**. Server spawning is a 1s task loop, not a frame connection. CameraDirector also uses RenderStepped:Wait during its camera sequence (one camera per waiting frame). WeatherFx follows sheets every 0.1s in a task loop.

## Scene parts

Fallback geometry scenario: no imported models, max worker slots and visible companion budget, one viewed home. BasePart counts include SpawnLocation; they exclude folders, UI, constraints and lights. The scoped estimate is not a bound on the complete live scene: avatars/accessories, imported meshes, reserved/retained spawns, heaters, hangar trophies, peddler, temporary VFX and editor additions are itemized separately below.

| World | Trees / rocks / cones | Region patches / roofs / walls | Shrine fallback | Hero placements (import only) | Static fallback parts | Nodes | Wild density scenario | Camp parts | Visible companions | Home items + displays | Scoped parts estimate |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 | 0 | 9 | 0 | 0 | 13 | 24 | 48 | 94 |
| 1 | 70 / 56 / 0 | 2 / 1 / 26 | 10 | 2 | 238 | 16 | 112 | 18 | 24 | 0 | 408 |
| 2 | 24 / 50 / 14 | 2 / 1 / 26 | 10 | 2 | 182 | 16 | 112 | 13 | 24 | 0 | 347 |

Formula: floor + camp pad + spawn = 3; tree = trunk + leaves = 2; rock = 1; cone = 3 tiers; region = patch + optional roof + wallCount; shrine = stoneCount + pedestal + glow. Home adds plot + 3 pads + kiosk + mailbox. Sources: src/server/Services/Meadow.luau:251, src/server/Services/Meadow.luau:306, src/server/Services/Meadow.luau:361.

Camp = slab + module ids present in Camp.Modules + one station anchor and up to 3 workers per unlocked job. World 2 module ids currently have no Camp.Modules entries, so its fallback module part count is zero. Home uses module world 0 here; a transitioning profile may retain a different ship. Home items use independent caps (conservative; grid packing may lower the result): room + furniture + habitat × [1 pad + 4 × (PostsPerSide−1) posts], plus 6 displayed aliens. Only one viewed plot/camp is drawn per client.

Additional countable parts: up to 6 fallback trophy parts at home (hull + pilot per pad), 2 peddler ship parts while present, and during a sighting 1 server anchor + 1 client body + up to approximately 81 trail puffs including one boundary puff, derived from ceil(speed × CatchUpScale / TrailStepStuds × TrailLifeSeconds)+1. Trail puffs also have one PointLight each. Weather and Shower each add one emitter anchor while active; fading weather sheets can overlap. Heaters add player-dependent geometry, and decorating adds a preview. None of these substitutes for measuring the imported scene.

**Spawn bound is unresolved.** 8 × SpawnDensityTarget(14) = 112 is a fresh separated-player density scenario, not a cap. SpawnRadius=90, SpawnCullDistance=180; records outside density range but inside cull range persist while new ones are added. SpawnAt/reserved spawns bypass density/cull. No global record ceiling is enforced in Spawner.tick. S is therefore a runtime variable; the 200-item budget cannot be certified from density alone.

Imported scenery replaces fallback trees/rocks/cones; heroes add models and can replace the shrine ring; station/ship/alien imports retain anchors. Layout data does not contain each imported model’s BasePart count. The 4,000-part test applies to the scoped fallback estimates only; the actual imported scene remains unverified. Count live Workspace descendants in an authorized Studio pass before declaring it within budget.

## Weather and Shower particles

| Weather sheet | Emitted / second | Max lifetime seconds | Conservative steady alive (rate × max lifetime) |
| --- | ---: | ---: | ---: |
| Ashfall | 38 | 5 | 190 |
| Aurora | 4 | 12 | 48 |
| Blizzard | 95 | 2 | 190 |
| Fog | 6 | 9 | 54 |
| Haze | 8 | 8 | 64 |
| Mist | 6 | 9 | 54 |
| Rain | 190 | 0.5 | 95 |
| Smog | 10 | 8 | 80 |
| Snow | 36 | 4 | 144 |

Shower adds 6/s × 1.2s = 7.2 alive. **Requested Shower + Rain scenario: 196 particles/s, approximately 103 steady alive** (unrounded rate×lifetime estimate 102.2). These sheets are local, so eight players do not multiply the count on one device.

Largest steady sheet + Shower = 197.2 alive. Two worst sheets overlapping on one transition + Shower give a deliberately conservative 387.2, still below 2000. WeatherParticleMax=200 is a warning threshold, NOT an enforced clamp. Repeated forced weather changes can retain several retiring sheets; one-shots (catch/module/dust) add burst particles. Those event rates are not bounded by the weather table, so this is not a global particle ceiling.

## Budget flags and decisions

| Check | Result | Fix / next step |
| --- | --- | --- |
| World 0, >4000 scoped parts | Within scoped estimate: 94 | Measure imported models, avatars and transient instances; use mesh/LOD budgets if total exceeds limit. |
| World 1, >4000 scoped parts | Within scoped estimate: 408 | Measure imported models, avatars and transient instances; use mesh/LOD budgets if total exceeds limit. |
| World 2, >4000 scoped parts | Within scoped estimate: 347 | Measure imported models, avatars and transient instances; use mesh/LOD budgets if total exceeds limit. |
| Shower + Rain, >2000 alive | Within scenario: 103 | Bound retiring sheets/bursts before claiming a global ceiling. |
| >200 items in one frame loop | Not proven exceeded in density scenario; actual S has no hard cap | Add a global spawn ceiling and a visible animation budget; test moving eight players. |
| Recurring frame table allocation | FLAG: CompanionRenderer.refreshFilter allocates every active frame | Update and reuse the exclusion list on character/folder changes. |
| Conditional frame-loop allocation | FLAG: sighting trail step and radar ping beat create tween goal tables | Pool effects/reuse goals; profile before/after. |
| Polled frame-callback allocations | Advisory: companion culling, Blizzard heaters, Radar, Nearby, Ship UI | Cache membership and reuse scratch buffers; preserve current poll cadence. |
| Imported full-world parts / aggregate particles | UNVERIFIED; inputs lack a global bound | Runtime instance/particle sampling with imported assets is required. |

## Top three coordinator actions

1. Cache companion raycast exclusions; it is the clear recurring allocation on the active per-frame path.
2. Enforce a global spawn/visible-animation budget. Density is not a cap; hidden wild models still receive bob/PivotTo updates, and radar/nearest-target scans grow with the same records.
3. Measure the imported eight-player scene, including sighting trail lights and weather transitions, before the visual pass. Pool trail effects and set explicit imported-part/burst budgets from that measurement.

This report makes no FPS or device-memory claim. A static count cannot establish those; no Studio session was run.

## Fixed (2026-10-07)

Static changes against the flags above; nothing was run in Studio, so the tables above are not regenerated and no FPS claim is made.

- **CompanionRenderer allocation:** the ground ray's exclusion list is one array and one RaycastParams, rebuilt only on a player or character coming or going, a companion-folder child change or a wild folder appearing; the culling pass reuses its `drawn`, `candidates` and row buffers with `table.clear`.
- **Global spawn ceiling:** `Config.SpawnMaxWild = 80` stops `Spawner.tick` placing wild spawns once that many are alive (reserved spawns neither count nor are blocked); the top-up places one spawn per player per pass so a full server shares the free slots.
- **Hidden and distant wild aliens:** `WildRenderer` skips the bob, both PivotTo calls and the reveal check for a record that is `hidden` or beyond `Config.SpawnCullDistance` (flat) of the local character root; the bob is a pure function of `os.clock()` and the record's phase, so it resumes in step.
- **Heater membership:** `WildRenderer` keeps the Heaters folder's parts from ChildAdded/ChildRemoved instead of calling `GetChildren()` on each evaluation, and reuses its heater spot rows.
- **SightingRenderer trail:** puffs are pooled (parts and lights reused, at most `ceil(TrailLifeSeconds / (TrailStepStuds / SpeedStudsPerSecond))` = 54 kept idle), and the TweenInfo and both fade goal tables are built once.
- **Radar:** the Wild folder's parts are tracked with ChildAdded/ChildRemoved while the loop runs instead of `GetChildren()` on each poll, and the ping tweens share one constant goal table; the blip pool already only grows to the most blips drawn at once and is reused.

Still open: the imported eight-player scene needs measuring in Studio (action 3 above), and the NearbyPanel and ShipScreen polls and the nearest-target scans in `init.client.luau` are untouched.
