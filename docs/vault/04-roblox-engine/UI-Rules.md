# Engine rules for UI

- Scale, never Offset, for Position and Size. Check in the device emulator at iPhone SE and iPad sizes.
- UIStroke on every text label over the world; UICorner on every button and panel; UIAspectRatioConstraint on cards.
- UIScale stepped by viewport width for touch targets of at least 44 px.
- Respect safe-area insets; landscape first.
- Build from the theme module; no hard-coded colours or fonts in screens.
- Tweens: open 0.25 s Back, close 0.15 s; buttons press to 0.92 and spring back.
- Every tap makes a sound.

## ScrollingFrame.CanvasSize scales against the parent, not the window (milestone 42c and 42d, 2026-10-06)

`CanvasSize`'s Scale is measured like `Size`: against the ScrollingFrame's parent, not against the frame itself. A list that computed its canvas in "window heights" (`pages`, the rows shown at once) and set `CanvasSize = fromScale(0, pages)` got a canvas `pages` times the PANEL tall whenever the list did not fill its parent: the Build tray showed one row instead of two, the mailbox one letter per window with a huge Claim button, the leaderboard stretched its rows. The rule: `CanvasSize = fromScale(0, pages * listShareOfParent)` where `listShareOfParent` is the list's own `Size.Y.Scale` (size the list before computing it when its height varies). Children of the ScrollingFrame still scale against the canvas, so each row's height stays `rowHeight / pages`. A list that fills its parent (`Size = fromScale(1, 1)`, the Shop's Gear column) needs no factor, which is why the bug hid there. Fixed in BuildScreen, MailScreen and LeaderboardScreen (58303c5); `QuestsScreen` sizes its daily list in body fractions already.

## Lint

Run `python3 -I tools/lint_ui.py` (also in `./tools/lint.sh`); `--list-baseline` prints current locations. It scans direct constructors across **src/client**, skips comments/string contents, and rejects `UDim2.fromOffset`, unproven-zero X/Y offsets in `UDim2.new`, and nonzero `UDim.new(0, n)` assigned to Size/Position. Fonts are allowed only through Theme/Builder. This lexical lint does not resolve constructor aliases or indirect property assignments.

The only offset exception is a vertical grid height assigned to `CellSize` or `CellPadding` on a line ending exactly `-- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)`. The marker attests that the UIGridLayout is in a ScrollingFrame and the height derives from AbsoluteSize; review verifies that relationship. It cannot exempt Size, Position or a horizontal offset. AliensScreen:688–689 are the two approved marked lines.

Colour ratchet: `tools/lint_ui_baseline.json` records normalized constructor expressions and occurrence counts (20 calls, including 6 in UI). New expressions/count increases fail; removed calls require shrinking the baseline. Initial fingerprint ceilings are fixed in the script; available HEAD/HEAD^ baselines also prevent restoring removed allowances. Shallow CI without its parent can enforce the initial ceiling only; baseline diffs still require review. There is no command that adds allowances. Existing data-driven world colours are recorded, not converted to Theme values by this card.

| Baseline source / lines | Expression | Count |
| --- | --- | ---: |
| `src/client/UI/AliensScreen.luau`:147 | `Color3 . fromHex ( def . placeholder . color )` | 1 |
| `src/client/UI/BuildScreen.luau`:277 | `Color3 . fromHex ( def . placeholder . color )` | 1 |
| `src/client/UI/CodexScreen.luau`:242, 616, 623 | `Color3 . fromHex ( def . placeholder . color )` | 3 |
| `src/client/UI/NearbyPanel.luau`:401 | `Color3 . fromHex ( def . placeholder . color )` | 1 |
| `src/client/World/CampRenderer.luau`:121 | `Color3 . fromHex ( hex )` | 1 |
| `src/client/World/CompanionRenderer.luau`:203, 212 | `Color3 . fromHex ( def . placeholder . color )` | 2 |
| `src/client/World/HangarRenderer.luau`:110 | `Color3 . fromHex ( Camp . ShipBaseColor )` | 1 |
| `src/client/World/HomeRenderer.luau`:382 | `Color3 . fromHex ( def . placeholder . color )` | 1 |
| `src/client/World/HomeRenderer.luau`:172 | `Color3 . fromHex ( look . color )` | 1 |
| `src/client/World/LightingDirector.luau`:88 | `Color3 . fromRGB ( rgb [ 1 ] , rgb [ 2 ] , rgb [ 3 ] )` | 1 |
| `src/client/World/PeddlerRenderer.luau`:94 | `Color3 . fromHex ( hex )` | 1 |
| `src/client/World/SightingRenderer.luau`:253 | `Color3 . fromHex ( def . placeholder . color )` | 1 |
| `src/client/World/SightingRenderer.luau`:330 | `Color3 . fromHex ( hex )` | 1 |
| `src/client/World/WeatherFx.luau`:152 | `Color3 . fromHex ( sheet . color )` | 1 |
| `src/client/init.client.luau`:212, 856, 1089 | `Color3 . fromHex ( def . placeholder . color )` | 3 |

Silent taps are advisory: 22 raw TextButton/ImageButton creations checked, 21 with an Activated/MouseButton1Click sound found (including AliensScreen's leading-sound local helper). Builder.button consumers inherit its sound. The checker follows direct callbacks and leading sound calls in named helpers; it is not an all-path control-flow proof.

- **CaptureBar.luau:86, backdrop:** no Activated/MouseButton1Click handler. It intentionally uses InputBegan/InputEnded for press/hold/release and plays result sounds on the server verdict. Review the intended timing; no behavior was changed or exemption silently added.
