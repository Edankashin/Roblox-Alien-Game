# Dead code and data candidates

Regenerate: `python3 -I tools/deadcode.py --write`. Inputs: all src Luau, Shop/Icons/Sounds data, C8 string families, C9 remote inventory, and milestone names from docs/PRE_PRODUCTION.md. Input fingerprint: `cd69d22b7ee26d05`.

This is a conservative lexical inventory, not a deletion plan. Public members are flagged only when no other file references their member name at all; same-named unrelated members can hide candidates. Dynamic dispatch and external Studio/plugin callers require human review. Icon references include data ids and aliases, so “no candidate” does not prove every icon is rendered. Sound id 0 means not uploaded, not unused. No game code or data changed.

## Counts

| Category | Candidates |
| --- | ---: |
| Public API | 35 |
| Shop catalog | 10 |
| Icon | 0 |
| Sound | 0 |
| String | 36 |
| Remote | 0 |

## Findings

| Category | Item / source | Evidence | Suggested disposition |
| --- | --- | --- | --- |
| Public API | src/client/UI/Builder.luau:189 Builder.gloss | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/Builder.luau:206 Builder.innerShadow | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/Builder.luau:586 Builder.shine | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/CaptureBar.luau:483 CaptureBar.IsActive | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/Hud.luau:792 Hud.SetShowerCountdown | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/UI/VisitScreen.luau:355 VisitScreen.Redraw | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/Ambience.luau:155 Ambience.Stop | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/HomeRenderer.luau:600 HomeRenderer.CellCenter | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/LightingDirector.luau:296 LightingDirector.Reapply | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/LightingDirector.luau:301 LightingDirector.ActiveConditions | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/client/World/NodeRenderer.luau:252 NodeRenderer.MaterialIdOf | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Buffs.luau:156 Buffs.PushLuckAll | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/CatchRush.luau:280 CatchRush.IsActive | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Companions.luau:115 Companions.SlotCount | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Companions.luau:304 Companions.UseToken | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:762 EconomyService.OnCaught | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:768 EconomyService.Optimize | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:776 EconomyService.AddSlots | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Economy.luau:854 EconomyService.Fuse | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Friends.luau:68 Friends.CountInServer | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:107 Habitats.Prune | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:126 Habitats.SetDisplay | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Habitats.luau:262 Habitats.OnArrivedHome | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Heaters.luau:172 Heaters.Near | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/HomeBuild.luau:187 HomeBuild.Remove | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Mail.luau:103 Mail.Claim | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Meadow.luau:568 Meadow.GetShrinePosition | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Monetization.luau:231 Monetization.GrantItem | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Peddler.luau:225 Peddler.GetVisit | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Seasons.luau:332 Seasons.GetOverride | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Seasons.luau:416 Seasons.OnShowerEnded | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Shop.luau:183 Shop.ApplyMovement | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Sightings.luau:289 Sightings.IsActive | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/Visiting.luau:495 Visiting.OwnerOf | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Public API | src/server/Services/WorldClock.luau:99 WorldClock.GetCondition | No external dot/colon reference to this member name. | Keep internal callers intact; remove only an unnecessary export after alias/callback review, or wire the intended external caller. |
| Shop catalog | AutoCollect | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | CompanionSlot4 | No Grants row and absent from Launch. Companions reads this pass live; it is not dead behavior. | Keep for milestone 36 companions; decide whether to expose the existing pass in Launch. |
| Shop catalog | DirectEpic | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | DirectRare | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | ModuleRush | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | RadarMk1Unlock | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | SlotEveryStation2 | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | Spins1 | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | Spins12 | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| Shop catalog | Spins5 | No Grants row and absent from Launch. | Keep for the milestone 14 shop follow-up / documented P1 catalog; wire grant and Launch entry together before exposure. |
| String | ACTION_RIDE | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | ALIENS_RESTING | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | ALIENS_RIDING | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CAMP_IDLE | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CAMP_WORKER | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | COMING_SOON | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_Ashfall | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_Day | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_Eclipse | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_GravityFlip | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_KingTide | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | CONDITION_PowerSurge | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | HEATER_NAME | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | HUD_SCRAP | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | LAUNCH_GO | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | LAUNCH_WELCOME | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | MODULE_COMPLETE | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | MODULE_NEEDS_KEY | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | QUESTS_TITLE | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | RUSH_OVER | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHIP_TAB_BAR | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_BUY_ROBUX | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_ITEM_HoverSkinStarter | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOP_ROBUX_SOON | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | SHOWER_INCOMING | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | TOAST_NEW_DAY | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | VERB_Build | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | VERB_Gather | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | VERB_Spark | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | VERB_Tinker | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
| String | WEEKLY_CHIP_WORLD | C8 unused-string candidate; no direct or mapped family reference. | Delete only after checking intended UI and translation compatibility; otherwise wire the intended label. |
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
