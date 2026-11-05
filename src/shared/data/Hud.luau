--!strict
-- The quiet HUD (docs/vault/05-ui-design/Clean-UI-Pass.md, package A): where the goal plate, the right-hand chips and the world labels
-- go, and how many show at once. Fractions are of the screen's width (x) or height (y) unless a name says Px. Shared/HudStages turns
-- these into a layout (headless-tested); UI/Hud, UI/TutorialHint, World/WildRenderer and World/NodeRenderer place it, Scale only.
-- Every number here, never in code.

local Hud = {
	-- The goal plate, top centre under the compass strip (strip 0.006 to 0.046, its one line under it to 0.068): the ship bar, and joined
	-- under it the objective line (the tutorial's hint, UI/TutorialHint). Both are centred; the objective may be a little wider than
	-- the bar when its text needs it.
	Goal = {
		Top = 0.07, -- the ship bar's top
		Width = 0.28, -- the bar's and the objective line's width: 0.36 to 0.64 of the screen
		ShipHeight = 0.05,
		LineGap = 0.006, -- between the bar and the objective line
		LineHeight = 0.05, -- one line of the objective
		MinHeightPx = 22, -- no plate of the goal is shorter than this: one 14 px line inside the ink (BlockMath HUD fit)
		MaxWidth = 0.44, -- the objective never grows wider than this, then it wraps to more lines
		MaxLines = 3, -- and never past this many lines
		CharEm = 0.55, -- a letter of Fredoka is this many ems wide on average (a long word wraps a little early: WrapSlack)
		WrapSlack = 1.15,
		LineEm = 1.15, -- a line of text is this many ems tall
		PadPx = 8, -- the plate's ink and air above and below the lines
		TextShare = 0.92, -- the share of the plate's width the hint's text takes with no counter chip
		TextShareCounter = 0.72, -- and with the "1/3" chip alone
		-- UI richness pass, package A (the goal card): a Field Notes step has a reward, and the plate is its own bar. With the reward chip
		-- the text takes TextShareReward; the chips share the rest from the plate's right edge (ChipRight), the counter CounterShare wide
		-- (a tutorial step has no reward and keeps the wider CounterWide), the reward RewardShare, ChipGap between them.
		TextShareReward = 0.5,
		RewardShare = 0.2,
		CounterShare = 0.17,
		CounterWide = 0.2,
		ChipGap = 0.01,
		ChipRight = 0.97,
		RewardAspect = 3.2, -- the reward chip's width over its height: the pixel icon and "+300" in green
		StepPopSeconds = 1.2, -- the objective's face is gold this long when the step changes, then the dark trough
		-- The loud goal card (data/Tutorial Script.LoudUntilStep; HudStages.Loud): through the first steps the objective line takes
		-- these in place of Width, MaxWidth, LineHeight, MinHeightPx and the 14 px text floor, so the hint reads as the one thing to
		-- do. The same arithmetic (HudStages.Objective) fits the words whole.
		Loud = {
			Width = 0.4, -- the card's width before it wraps (0.3 to 0.7 of the screen)
			MaxWidth = 0.6,
			LineHeight = 0.07,
			MinHeightPx = 30,
			TextPx = 18, -- the floor the words are fitted at (Theme.TextSize.Body; the label's ceiling is Label)
		},
	},
	-- The world marker (World/Waypoint): the floating glyph over the tutorial's or a quest's target, in studs, and the screen-edge arrow
	-- that points at the target while it is off screen (playtest 1, 2026-11-05: "put arrows pointing where to go").
	Waypoint = {
		LiftStuds = 4, -- the billboard floats this far above the target
		WidthStuds = 8,
		HeightStuds = 3,
		LoudScale = 1.6, -- the billboard is this much bigger through the loud steps (HudStages.Loud)
		Edge = {
			Inset = 0.06, -- the arrow keeps this far inside the screen's left and right edges
			Top = 0.2, -- and runs no higher than this (under the compass strip and the goal card)...
			Bottom = 0.82, -- ...nor lower (above the power-up bar and the action button)
			Size = 0.09, -- the arrow's height, of the screen (square)
			MinPx = 32,
			DistanceHeight = 0.04, -- the distance line under it
			Seconds = 0.05, -- how often the arrow follows the target
		},
	},
	-- The top-right stack, from `Right` in from the screen's edge, each under the last by `Gap`: the place chip (where and when), the
	-- event chip (only while one of the rules of HudStages.EventSlot holds), the Friend Boost chip (only above +0%). The radar
	-- column keeps its own top (0.228, UI/RadarColumn). Each chip keeps its aspect (the Hud's CLOCK_, BANNER_ and FRIEND_CHIP_ASPECT);
	-- the height is the fraction, or the pixel floor when that is taller (a phone).
	Chips = {
		Right = 0.985, -- the chips' right edge
		Top = 0.025,
		Gap = 0.008,
		PlaceHeight = 0.075, -- two lines: the biome, then "Day · Rain"
		PlaceMinPx = 40,
		EventHeight = 0.048,
		EventMinPx = 34,
		FriendHeight = 0.055,
		FriendMinPx = 28,
		MaxWidth = 0.4, -- the size bound the aspect fits inside (the width follows from the height)
	},
	PanelPollSeconds = 0.1, -- how often the HUD asks whether a panel is open (the whole HUD hides while one is, the Scrap pill included)
	-- The top-left stack: the Scrap pill, its rate line under it, then the left button column (the Shop, the Menu). Playtest 1
	-- (2026-11-05, docs/playtests/2026-11-05-tester-1.md): the pill sat inside Roblox's own menu and chat buttons, which live in the
	-- top inset every ScreenGui here ignores. So the pill starts at Top, or under the inset plus InsetGap when that is lower
	-- (GuiService:GetGuiInset, read by UI/Hud; the arithmetic is HudStages.LeftColumn), and the rest of the stack hangs under it.
	Left = {
		Top = 0.025, -- the pill's top with no inset (the stack then reads as before: pill 0.025, rate line 0.115, column 0.19)
		InsetGap = 0.012, -- air between Roblox's bar and the pill when the inset is what places it
		PillLeft = 0.015,
		PillHeight = 0.085,
		PillWidth = 0.3, -- the size bound the pill's aspect fits inside
		RateGap = 0.005, -- between the pill and the rate line
		RateX = 0.03,
		RateHeight = 0.045,
		RateWidth = 0.3,
		ColumnGap = 0.03, -- from the rate line's bottom to the first button slot
	},
	-- World labels (WildRenderer, NodeRenderer): only what is near wears a name.
	Plates = {
		MaxShown = 5, -- a wild alien's plate shows for the nearest this many in range, never more (no "plus any within 15 studs")
		StackMaxDepth = 3, -- of aliens standing side by side (Config.NameplateStackRadiusStuds) only this many plates stack up; the later ones' plates are dropped, so none climbs into the compass strip
		TierStuds = 30, -- its tier line only within this (farther, the name alone)
		NodeStuds = 30, -- a node's plate shows within this...
		NodeTargetStuds = 5000, -- ...and the node a tutorial or quest marker points at from any distance
		TargetSameSpotStuds = 3, -- a node this close to the marker's point is the node it points at
		PollSeconds = 0.25, -- how often a node judges its target rule
	},
}

return Hud
