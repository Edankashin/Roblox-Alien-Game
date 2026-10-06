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
