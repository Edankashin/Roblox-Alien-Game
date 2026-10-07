--!strict
-- One place for the look. Generated from docs/vault/05-ui-design/UI-Playbook.md.
local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.BuilderSans

Theme.Colors = {
	Panel = Color3.fromHex("FFF4DC"),
	Outline = Color3.fromHex("1B1F3B"),
	Trough = Color3.fromHex("1B1F3B"),
	Confirm = Color3.fromHex("51DF51"),
	Close = Color3.fromHex("FF4D4D"),
	Select = Color3.fromHex("68C9FE"),
	Featured = Color3.fromHex("FFC83D"),
	Heading = Color3.fromHex("FFEF4A"),
	Codex = Color3.fromHex("A855F7"),
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	StudStripe = Color3.fromHex("7CE977"),
}

Theme.Rarity = {
	Common = Color3.fromHex("B0B0B0"),
	Uncommon = Color3.fromHex("57F96C"),
	Rare = Color3.fromHex("3B82F6"),
	Epic = Color3.fromHex("C026D3"),
	Legendary = Color3.fromHex("F59E0B"),
	Cosmic = Color3.fromHex("EC4899"),
	Secret = Color3.fromHex("111111"),
}

Theme.TextSize = { Min = 14, Body = 18, Label = 24, Title = 36, Reveal = 48 }
Theme.Corner = { Button = 12, Panel = 16, Card = 10, Pill = 999 }
Theme.Stroke = { Text = 2.5, Button = 3, Panel = 4 }
Theme.Tween = { Open = 0.25, Close = 0.15, Press = 0.08, Toast = 2.5, StaggerStep = 0.025, StaggerRows = 12 } -- StaggerStep: delay between list rows sliding in on open, over the first StaggerRows rows
Theme.Scale = { PressDown = 0.92, Hover = 1.05, Breathe = 1.04 }
Theme.Margin = 0.02 -- 2% inner margin on panels
-- The HUD's left icon column (Hud.AddMenuButton), as screen fractions: each slot is SlotW of the width wide at most and SlotH of the
-- height tall, kept at Aspect (width over height), so on a tall narrow window it is SlotW wide and on a wide one it follows the height.
-- Builder.menuRight turns these into the column's right edge, which the Build tray and the Ship screen keep clear of (Gap).
Theme.Menu = { Left = 0.015, SlotW = 0.12, SlotH = 0.13, Aspect = 0.8, Gap = 0.01 }
Theme.Backdrop = 0.6 -- modal backdrops dim the world by this much
Theme.ButtonLip = 0.1 -- the darker "lip" under a button, as a fraction of its height
Theme.Gloss = {
	Top = 0.5, -- the highlight band's height, as a fraction of the face it sits on
	Alpha = 0.72, -- the highlight's transparency at its top edge
	EdgeAlpha = 0.92, -- and at its bottom edge (a UIGradient from Alpha to EdgeAlpha to 1 fades it out)
	Shadow = 0.08, -- the inner-shadow band's height on a panel, as a fraction of the panel
	ShadowAlpha = 0.82, -- and its transparency at the bottom edge
	ShineSeconds = 0.6, -- the shine sweep: seconds to cross the target
	ShineWidth = 0.18, -- the sweeping band's width, as a fraction of the target's width
	ShineAlpha = 0.55, -- the band's transparency at its centre (it fades to clear at both edges)
	ShineEvery = 4, -- seconds of rest between two sweeps
}
Theme.Lighten = 0.25 -- gradient top: how far toward white
Theme.Darken = 0.35 -- strokes and lips: how far toward black
Theme.Shadow = Color3.new(0.1, 0.1, 0.12) -- uncaught species silhouette

return Theme
