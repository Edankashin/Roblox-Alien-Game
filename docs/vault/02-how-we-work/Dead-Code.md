# Dead code and data candidates

Regenerate: `python3 -I tools/deadcode.py --write`. Inputs: all src Luau, Shop/Icons/Sounds data, C8 string families, C9 remote inventory, and milestone names from docs/PRE_PRODUCTION.md. Input fingerprint: `a2d86c600def2035`.

This is a conservative lexical inventory, not a deletion plan. Public members are flagged only when no other file references their member name at all; same-named unrelated members can hide candidates. Dynamic dispatch and external Studio/plugin callers require human review. Icon references include data ids and aliases, so “no candidate” does not prove every icon is rendered. Sound id 0 means not uploaded, not unused. No game code or data changed.

## Counts

| Category | Candidates |
| --- | ---: |
| Public API | 22 |
| Shop catalog | 5 |
| Icon | 0 |
| Sound | 0 |
| String | 14 |
| Remote | 0 |

## Findings

| Category | Item / source | Evidence | Suggested disposition |
| --- | --- | --- | --- |
| Public API | src/client/UI/Builder.luau:189 Builder.gloss | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/Builder.luau:570 Builder.shine | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/VisitScreen.luau:355 VisitScreen.Redraw | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/Ambience.luau:155 Ambience.Stop | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Buffs.luau:171 Buffs.PushLuckAll | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Companions.luau:115 Companions.SlotCount | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Companions.luau:304 Companions.UseToken | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:768 EconomyService.Optimize | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:776 EconomyService.AddSlots | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:854 EconomyService.Fuse | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Friends.luau:68 Friends.CountInServer | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:107 Habitats.Prune | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:126 Habitats.SetDisplay | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:262 Habitats.OnArrivedHome | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/HomeBuild.luau:165 HomeBuild.Remove | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Mail.luau:103 Mail.Claim | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Monetization.luau:232 Monetization.GrantItem | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Peddler.luau:244 Peddler.GetVisit | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Seasons.luau:413 Seasons.OnShowerEnded | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Shop.luau:183 Shop.ApplyMovement | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Visiting.luau:495 Visiting.OwnerOf | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/WorldClock.luau:99 WorldClock.GetCondition | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Shop catalog | AutoCollect | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | DirectEpic | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | DirectRare | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | ModuleRush | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | RadarMk1Unlock | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| String | COMING_SOON | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_Ashfall | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_Eclipse | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_GravityFlip | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_KingTide | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_PowerSurge | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_BUY_ROBUX | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_ITEM_HoverSkinStarter | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_ROBUX_SOON | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WORLD_3 | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WORLD_4 | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WORLD_5 | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WORLD_6 | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WORLD_7 | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |

## Coordinator priorities

1. Resolve catalog rows with no grant/Launch route before exposing more purchases; CompanionSlot4 is a live-reader exception, not an unused pass implementation.
2. Review public APIs without external references; remove obsolete wrappers only after checking manual Studio and callback use.
3. Review the C8 string candidates alongside the UI polish pass; retain future-world labels until the world plan is settled.

Every finding above includes a delete, keep or wire-up suggestion. Counts are candidates, not proven removable assets.

## C18 reviewed cleanup — 2026-10-07

The generated inventory above describes the remaining tree; this hand-written ledger must be preserved when regenerating it. C18 changed game source only by deletion. All 12 surviving module bodies are byte-identical after removing the listed uncalled declarations; game/Dev/tool/test member searches found no callers. The 140 headless tests still pass.

| Removed API | Commit |
| --- | --- |
| `src/client/UI/Builder.luau` Builder.innerShadow | `1aceda6` |
| `src/client/UI/CaptureBar.luau` CaptureBar.IsActive | `1aceda6` |
| `src/client/UI/Hud.luau` Hud.SetShowerCountdown | `1aceda6` |
| `src/client/World/HomeRenderer.luau` HomeRenderer.CellCenter | `1aceda6` |
| `src/client/World/LightingDirector.luau` LightingDirector.Reapply | `1aceda6` |
| `src/client/World/LightingDirector.luau` LightingDirector.ActiveConditions | `1aceda6` |
| `src/client/World/NodeRenderer.luau` NodeRenderer.MaterialIdOf | `1aceda6` |
| `src/server/Services/CatchRush.luau` CatchRush.IsActive | `efe4d00` |
| `src/server/Services/Economy.luau` EconomyService.OnCaught | `efe4d00` |
| `src/server/Services/Heaters.luau` Heaters.Near | `efe4d00` |
| `src/server/Services/Meadow.luau` Meadow.GetShrinePosition | `efe4d00` |
| `src/server/Services/Seasons.luau` Seasons.GetOverride | `efe4d00` |
| `src/server/Services/Sightings.luau` Sightings.IsActive | `efe4d00` |

String removals (`1032608`): `ACTION_RIDE`, `ALIENS_RESTING`, `ALIENS_RIDING`, `CAMP_IDLE`, `CAMP_WORKER`, `CONDITION_Day`, `HEATER_NAME`, `HUD_SCRAP`, `LAUNCH_GO`, `LAUNCH_WELCOME`, `MODULE_COMPLETE`, `MODULE_NEEDS_KEY`, `QUESTS_TITLE`, `RUSH_OVER`, `SHIP_TAB_BAR`, `SHOWER_INCOMING`, `TOAST_NEW_DAY`, `VERB_Build`, `VERB_Gather`, `VERB_Spark`, `VERB_Tinker`, `WEEKLY_CHIP_WORLD`.

Kept all 22 remaining API candidates: each has an internal caller or a same-name executable reference requiring a broader call-graph proof. Builder.gloss/shine, VisitScreen.Redraw, Ambience.Stop, Buffs.PushLuckAll, Companions.SlotCount/UseToken, Economy.Optimize/AddSlots/Fuse, Friends.CountInServer, Habitats.Prune/SetDisplay/OnArrivedHome, HomeBuild.Remove, Mail.Claim, Monetization.GrantItem, Peddler.GetVisit, Seasons.OnShowerEnded, Visiting.OwnerOf and any conservative same-name candidates remain intact.

Kept 14 unused string candidates: WORLD_3–WORLD_7 and CONDITION_PowerSurge/Ashfall/KingTide/GravityFlip/Eclipse for designed worlds; SHOP_BUY_ROBUX, SHOP_ROBUX_SOON and SHOP_ITEM_HoverSkinStarter for catalog expansion; COMING_SOON for that planned locked catalog/world UI. No season-family or Shop.Items row was removed. Five catalog routing gaps remain coordinator-owned.
