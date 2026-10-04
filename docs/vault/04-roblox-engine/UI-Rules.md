# Engine rules for UI

- Scale, never Offset, for Position and Size. Check in the device emulator at iPhone SE and iPad sizes.
- UIStroke on every text label over the world; UICorner on every button and panel; UIAspectRatioConstraint on cards.
- UIScale stepped by viewport width for touch targets of at least 44 px.
- Respect safe-area insets; landscape first.
- Build from the theme module; no hard-coded colours or fonts in screens.
- Tweens: open 0.25 s Back, close 0.15 s; buttons press to 0.92 and spring back.
- Every tap makes a sound.
