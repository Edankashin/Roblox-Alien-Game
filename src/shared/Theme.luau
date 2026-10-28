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
	Paper = Color3.fromHex("F4EEDC"), -- the radar scroll's sheet (Decision B57): calm cream paper, no game chrome
	PaperRoll = Color3.fromHex("D9CCA6"), -- its rolled ends, a shade darker
	ShopBackdrop = Color3.fromHex("6948B9"), -- the Shop's takeover ground: this violet at the top fading to Outline (navy) at the bottom
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
-- Text, Button and Panel are the stroke's pixels at ReferenceHeight; Builder.stroke scales them to the real screen height
-- (Shared/StrokeMath) inside [MinScale, MaxScale], so text keeps 2 to 3 px of outline from a phone to a 4K window.
-- TextJoin is the LineJoinMode of the outline round a letter and ShapeJoin that of a border on a frame, button or input:
-- the X pass (X-Posts take 1) says Bevel or Miter instead of the default Round. Bevel for text, because a miter spikes at the
-- sharp joins in a letter; Miter for a border, to keep a square corner square. Check Fredoka's counters in Studio at Reveal size.
Theme.Stroke = {
	Text = 2.5,
	Button = 3,
	Panel = 4,
	ReferenceHeight = 1080,
	MinScale = 0.8,
	MaxScale = 1.2,
	TextJoin = Enum.LineJoinMode.Bevel,
	ShapeJoin = Enum.LineJoinMode.Miter,
}
Theme.Tween = { Open = 0.25, Close = 0.15, Press = 0.08, Toast = 2.5, StaggerStep = 0.025, StaggerRows = 12, BannerLine = 2.5 } -- StaggerStep: delay between list rows sliding in on open, over the first StaggerRows rows; BannerLine: seconds each line of a one-line HUD event banner shows before the other takes its turn
Theme.Scale = { PressDown = 0.92, Hover = 1.05, Breathe = 1.04 }
Theme.Margin = 0.02 -- 2% inner margin on panels
Theme.TapMin = 44 -- the smallest tappable face in px (UI Playbook, phone rules): a smaller face gets an invisible hit area this big (Builder.button `hit`)
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
-- The shop's status shapes (Builder.ribbon, Builder.seal), in block cells since the Shop's change: a ribbon's folded end is a
-- darker flat square Tail tall (of the holder's height) under each end of its plate; a seal is a stepped pixel octagon whose
-- label is Text of its width.
Theme.Ribbon = { Tail = 0.7 }
Theme.Seal = { Text = 0.7 }
-- Block cells (UI Playbook "Block cells", Decisions B44, Decide-Now 43): a plate is a whole number of square cells with its four
-- corner cells cut (the stepped pixel corner), a navy ink border, a lit top row, darker side and bottom cells, a grout line on each
-- cell and a few cells a shade off (Blocky-Style C1 to C6): frames only, no image, no gradient, no gloss. Shared/BlockMath does the
-- arithmetic; Builder.blockPlate, Builder.blockButton and Builder.pixelIcon build from these. Cell is a cell's height as a fraction of
-- the screen height, from which each plate's rows are picked (7.5 px at iPhone SE, 16 px on an iPad); Ink and Grout are in cells;
-- the Alpha values are the transparency of the white or black overlays, so a plate recolours by its Fill frames alone. Layer is the
-- ZIndex step inside a plate above the plate's own: content (labels, icons) goes at Layer.Content or higher (Builder.blockTop).
-- tools/tests/test_block_theme.py keeps these equal to the parameters tests/BlockMath.spec.luau checks the HUD's fit with.
Theme.Block = {
	Cell = 0.02,
	Ink = 0.4,
	MinRows = 3,
	Grout = 0.125,
	GroutAlpha = 0.9,
	QuietGroutAlpha = 0.95, -- a quiet panel face's grout (Builder.blockPlate quiet = true, Clean UI pass package C): fainter, with no jitter
	TopAlpha = 0.7,
	EdgeAlpha = 0.8,
	JitterAlpha = 0.9,
	Seed = 44,
	Hover = 1.04,
	PixelGrid = 8,
	PanelCell = 0.04, -- a modal panel's cell (Builder.blockPanelRows): twice Cell, as the world's cell is twice a creature's (C1)
	Trough = Color3.fromHex("2A2F55"), -- a dark plate's face (the Scrap plate, the ship bar's trough, the idle Friend chip): the ink a step up
	Layer = { Ink = 0, Fill = 1, Bar = 2, Cells = 3, Content = 4 },
	MaxCells = 6000, -- a grid of more cells draws as an edged block (BlockMath.WithinBudget): a whole 21:9 screen at the HUD cell is about 5,600; the start-up measurement asked for millions
	FitBudget = 0.004, -- seconds of fitted-plate measuring and redrawing per frame; the rest waits for the next frame (Builder fitPlate)
}
Theme.Lighten = 0.25 -- gradient top: how far toward white
Theme.Darken = 0.35 -- strokes and lips: how far toward black
Theme.Shadow = Color3.new(0.1, 0.1, 0.12) -- uncaught species silhouette

-- A colour from a six-digit hex string, the way the data tables name colours (data/Effects). The one place client code
-- turns such a string into a Color3, so the colour constructors tools/lint_ui.py counts in src/client do not grow.
function Theme.Hex(hex: string): Color3
	return Color3.fromHex(hex)
end

return Theme
