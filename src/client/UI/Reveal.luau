--!strict
-- StarterPlayerScripts.Client.UI.Reveal: the catch reveal ritual, in three beats (data/Reveal holds every number; the pure
-- half is Shared/RevealMath; the spec is the UI Playbook's "The reveal in three beats"). Pure presentation of a server result:
-- the outcome was decided before the first tap, so the taps are theatre and nobody is ever stuck.
--   1. Crack. An egg sits in the middle with a tap ring and "Tap to crack it!"; three dots count the taps. Each tap wobbles it,
--      draws a crack line, ticks, and lets a little more of the tier colour leak from behind it (never the name). Reduced
--      Motion, or AutoCrackSeconds without a tap, cracks it on its own. Every egg grant runs this beat; a wild catch has no
--      egg in the flow, so it starts at beat 2 (data/Reveal CatchCrack = true gives it a capsule to crack the same way).
--   2. Shards. The shell bursts into shards that fly out and fade, the rays spin up in the tier colour (a static ring under
--      Reduced Motion), the tier word drops in big, the tier's stinger plays and the stage pushes in a little. Legendary and
--      up run the beat longer and bigger and add the gold ground ring under the model; Cosmic's rays take a second colour;
--      Secret dims the screen and opens a dark iris instead of rays (the flags are data/Reveal Tiers). A tap during the
--      shards skips to the card (data/Reveal Skip).
--   3. The card. It drops in; then the chance line ("1 in N · x% chance", only when the client has an honest number: the
--      server's egg draw or the tier's spawn share), the size and multiplier chips, and last the two buttons slide up
--      ("Place it" opens the Aliens screen through Reveal.OnPlace, "Keep going" closes). "Tap anywhere to continue" closes
--      once they are up; an earlier tap finishes the entrance.
-- Toasts and banners wait: Show hushes them at beat 1 and asks Toast.QuietFor for the whole sequence.
-- A size band that names itself (data/Sizes label: Tiny, Big, HUGE) stamps "HUGE Zorp!" in the Featured
-- colour above the species name with its Scrap multiplier beneath the tier, and pops the card by the
-- band's revealPop (no pop under Reduced Motion).
-- The card's Shape area shows the species mesh (World.Models) turning in a ViewportFrame when one
-- exists, the placeholder colour-and-shape frame otherwise.
-- Sprites (Icons.Particles, id 0 = not uploaded, then nothing changes): a Shine sunburst turns behind the
-- card in the tier colour (still under Reduced Motion), and the confetti pieces wear the Confetti sprite.
-- A Perfect catch (info.perfect, not under Reduced Motion) also flashes the screen white for
-- Config.VfxPerfectFlashSeconds when the card lands; the flash takes no input.
-- A grant that carries overflowScrap (the storage cap was full, data/Storage: the alien turned into Scrap and no
-- record was added) wears a red "Storage full: turned into N Scrap" ribbon above the card, has no "Place it" (there is
-- nothing to place), and closing the Reveal toasts the hint to release or fuse aliens to keep new catches.
-- The look is block cells (UI Playbook "Block cells" and "The reveal in block cells", Decisions B44 and B46): the card a cream
-- plate at the panel cell in its tier's ink; the egg a pixel egg (RevealMath.EggBars) whose cracks are stepped pixels; the glow and
-- the iris pixel octagons, the tap ring and the ground ring square dots; the shards flat blocks; the rays a fan of square cells;
-- the chance line, the overlay badge, the NEW ribbon and the storage ribbon flat or edged blocks; the buttons block buttons in
-- cells. At the hero beat (the card landing) the tier's rung of the intensity ladder plays (data/Reveal Ladder, climbing
-- steeply): a pop, bursts of sparkle cells, a pixel starburst, a colour wash, a gold cell frame chasing round the card, a slower
-- turn of the model, the pixel sky (from the shards on) and the name spelled in; World.SpeciesFx.Flourish is asked for the
-- alien's own flourish on the same beat. Reduced Motion keeps the still versions only (the sky and the frame at rest).

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Icons = require(Shared:WaitForChild("data"):WaitForChild("Icons"))
local RevealData = require(Shared:WaitForChild("data"):WaitForChild("Reveal"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local BadgeFit = require(Shared:WaitForChild("BadgeFit"))
local RevealMath = require(Shared:WaitForChild("RevealMath"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local Prefs = require(script.Parent.Parent.Prefs)
local Models = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Models"))
local RigAnimator = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("RigAnimator"))
local MusicDirector = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("MusicDirector"))
local SpeciesFx = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("SpeciesFx"))

local Reveal = {}

export type RevealInfo = {
	speciesName: string,
	speciesId: string?, -- the species row, for its mesh; without it the name is looked up in Species.List
	shape: string, -- placeholder shape name, shown on the card until real art exists
	color: Color3,
	tier: string,
	overlay: string, -- "None" hides the badge
	size: string, -- the size band id (data/Sizes); the labelled bands get the stamp and the pop
	isNew: boolean,
	scrapGained: number,
	perfect: boolean?, -- the server scored a Perfect hit: show the Scrap multiplier line
	overflowScrap: number?, -- the storage cap was full: the alien turned into this much Scrap (already in scrapGained)
	fromEgg: boolean?, -- a grant (an egg claim, a Peddler egg, a quest alien): beat 1 cracks the egg. nil or false: a wild catch
	chancePercent: number?, -- the server's percent chance for this grant (GrantResult.oddsPercent); nil shows no line for a grant
}

type Phase = "Idle" | "Crack" | "Shards" | "Card"

local VIEW_FOV = 40 -- the model viewport's camera
local VIEW_FIT = 1.15 -- camera distance margin over the model's bounding radius
local VIEW_DIRECTION = Vector3.new(-0.6, 0.45, -1) -- from the model's front-left, slightly above
local VIEW_SPIN = math.rad(30) -- radians per second while the reveal is open
-- Card layout (fractions of the card's height): the species and tier lines drop a little under a size
-- stamp, which takes the gap between the model and the name.
local NAME_Y = 0.7
local TIER_Y = 0.8
local NAME_Y_STAMPED = 0.745
local TIER_Y_STAMPED = 0.845
local STAMP_Y = 0.655
local STAMP_SCRAP_Y = 0.945 -- of the screen, on the root like the Scrap (0.815) and Perfect (0.885) lines, under both
local STAMP_PEAK = 1.5 -- the stamp slams in from this scale
local CARD_ASPECT = 0.8 -- the card's width over height
local CARD_POSITION = UDim2.fromScale(0.5, RevealData.StageY)
local CARD_SIZE = UDim2.fromScale(0.6, 0.56) -- ends at 0.75, clear of the Scrap line below
local RAYS_WIDTH = 1.6 -- the sunburst sprite's width, in card widths
local RAYS_TRANSPARENCY = 0.35
local FLASH_START = 0.15 -- the Perfect flash's starting transparency; it fades from here to 1
local TIER_LABEL_W = 0.9 -- the tier label's width, of the card
local TIER_H = 0.08 -- its height, of the card; the rarity badge beside it is this tall and square
local TIER_ICON_GAP = 0.015 -- of the card's width, between the badge and the tier text
local STORAGE_Y = 0.09 -- the storage-full ribbon, of the screen: centred above the card (which starts at 0.19)
local STORAGE_W = 0.7
local STORAGE_H = 0.09
-- The overlay badge, top right of the card: its width before it is fitted (what it was), the most it may grow to, and its height.
local BADGE_MIN_W = 0.42
local BADGE_MAX_W = 0.92
local BADGE_H = 0.09
-- Layers (ZIndex on the root): the dim, the pixel sky, the extra dim, the rays and the iris and the starburst, the gold frame,
-- the card, the stage (egg, shards, word) over it for beats 1 and 2, the footer, the text lines, the buttons, the confetti and
-- the sparkles, the colour wash, the flash.
local Z_DIM = 1
local Z_SKY = 2
local Z_EXTRA_DIM = 3
local Z_BEHIND = 4
local Z_FRAME = 5
local Z_CARD = 6
local Z_STAGE = 7
local Z_FOOTER = 8
local Z_LINES = 10
local Z_BUTTONS = 11
local Z_WASH = 12
local FLASH_LAYER = 13 -- the Perfect flash: over everything on the reveal
-- Inside the card (a block plate: its ink, face and cells take its ZIndex to four above it): content from CARD_TOP up.
local CARD_TOP = Z_CARD + Theme.Block.Layer.Content
local ODDS_Z = CARD_TOP + 8 -- the chance plate on the card, over the card's lines, badges and their plates
local SHAPE_ROWS = 5 -- the placeholder shape square: an edged block of five rows
local RIBBON_ROWS = 3 -- the NEW ribbon: a flat block
local SHARD_ROWS = 7 -- a shard: a flat block 3 by 7 cells at ShardAspect
local TAP_RING_DOTS = 24 -- the tap ring: square white dots round the egg (a ring is dots on a block screen)
local TAP_RING_DOT = 0.035 -- a dot, of the ring's diameter
local GROUND_RING_DOTS = 18 -- the gold ground ring under a Grand tier's model: square gold dots on an ellipse
local GROUND_RING_DOT = 0.32 -- a dot, of the ring's height
local GOLD_LIT_STRIDE = 8 -- every eighth cell of the gold frame is lit, and the lit ones chase round
local STAR_TWINKLE_ALPHA = 0.7 -- a sky star twinkles out to this see-through and back
local STARBURST_INNER = 0.14 -- the starburst's first cell, of the burst's diameter from the centre
local STARBURST_CELL = 0.06 -- its largest (outermost) cell, of the burst's diameter

local gui: ScreenGui? = nil
local card: Frame? = nil
local burst: Frame? = nil
local shapeBox: Frame? = nil
local shapeLabel: TextLabel? = nil
local viewBox: ViewportFrame? = nil
local viewCamera: Camera? = nil
local viewModel: Model? = nil
local spinConn: RBXScriptConnection? = nil
local spinAngle = 0
local speciesByName: { [string]: Types.SpeciesDef }? = nil
local nameLabel: TextLabel? = nil
local tierLabel: TextLabel? = nil
local tierBadge: GuiObject? = nil -- the rarity badge left of the tier text (Builder.blockIcon); absent while it has no icon
local stampLabel: TextLabel? = nil
local stampScrapLabel: TextLabel? = nil
local overlayBadge: Frame? = nil
local overlayLabel: TextLabel? = nil
local stopOverlayShine: (() -> ())? = nil -- stops the slow shine sweep on a tinted overlay's badge (Launch Gold); nil while none runs
local newRibbon: Frame? = nil
local scrapLabel: TextLabel? = nil
local storageRibbon: Frame? = nil -- the "Storage full" ribbon above the card
local storageLabel: TextLabel? = nil
local storageHint = false -- the Reveal on screen was a storage overflow: close toasts the hint
local perfectLabel: TextLabel? = nil
local burstTween: Tween? = nil
local raysFrame: Frame? = nil -- holds the sunburst sprite; made by the rays beat, destroyed with the close
local raysTween: Tween? = nil
local onClose: (() -> ())? = nil
local open = false

-- The three beats' pieces.
local dimExtra: Frame? = nil -- the further dim of a Secret
local iris: Frame? = nil -- the dark iris of a Secret (a pixel octagon's holder)
local irisScale: UIScale? = nil
local stageFrame: Frame? = nil
local stageScale: UIScale? = nil
local glowOuter: { Frame } = {} -- the soft edge of the glow behind the egg: a pixel octagon's frames
local glowCore: { Frame } = {} -- and its bright centre
local burstScale: UIScale? = nil -- the ray ring's spin-up grows it from small
local rayBars: { Frame } = {} -- the ray ring's bars through the middle; their cells are drawn per show (the tier's RayCells)
local skyFrame: Frame? = nil -- the pixel sky of Cosmic and Secret
local skyBands: { Frame } = {}
local skyStars: { Frame } = {}
local skyShown = false
local goldFrame: Frame? = nil -- the gold cell frame round the card (Legendary and up)
local goldCells: { Frame } = {}
local goldToken = 0 -- bumped to stop the chase
local spellCursor: Frame? = nil -- the cell that runs ahead of the name as it is spelled in
local spellToken = 0 -- bumped to stop the spelling
local spinScale = 1 -- the model's turn, times VIEW_SPIN (the tier's TurnScale)
local heroDone = false -- the hero beat (or a settle that stood in for it) has played this show
local speciesId = "" -- the species on the card, for its flourish
local showGen = 0 -- bumped per Show and close: an effect that outlives a phase (the sky, the sparkles) drops out when stale
local ambient: { Tween } = {} -- tweens that outlive a phase (the sky's twinkle); cancelled at the close and the next Show
local tapRing: Frame? = nil
local tapRingScale: UIScale? = nil
local eggHolder: Frame? = nil
local eggPulse: UIScale? = nil
local crackBars: { { Frame } } = {} -- per tap, the bars of its crack line
local shardPieces: { Frame } = {}
local wordLabel: TextLabel? = nil
local promptLabel: TextLabel? = nil
local dotsHolder: Frame? = nil
local dotFrames: { Frame } = {}
local groundRing: Frame? = nil -- the gold ring under the model on a Grand tier's card
local oddsPill: Frame? = nil -- the chance line, hanging on the card's bottom edge
local oddsLabel: TextLabel? = nil
local buttonsHolder: Frame? = nil
local placeButton: Frame? = nil
local footerLabel: TextLabel? = nil

-- The sequence's state.
local rng = Random.new()
local seq = 0 -- bumped at every phase change, close and Show: a delayed step checks it and drops out when the sequence moved on
local phase: Phase = "Idle"
local current: RevealInfo? = nil
local reducedNow = false -- Prefs.ReducedMotion() as of Show
local running: { Tween } = {} -- the tweens of the phase on screen; cancelled when it ends
local tapsMade = 0
local autoGen = 0 -- bumped by every crack tap: the idle auto-crack timer drops out when it is stale
local autoRunning = false -- the taps are playing themselves
local lastActionAt = 0 -- os.clock() of the last phase change: a tap this soon after (SkipGuardSeconds) is ignored
local settled = false -- the card's entrance is over: a tap now closes
local raysShown = false
local irisShown = false
local chipStamp = false -- the stamp wants showing with the chips
local chipPerfect = false
local chipStorage = false
local scrapStarted = false -- the "+N Scrap" line has started its float
local scrapGen = 0 -- bumped per Show: the Scrap line's delayed float drops out when stale
local placeHandler: (() -> ())? = nil

local function clearModel()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	if viewModel then
		viewModel:Destroy()
		viewModel = nil
	end
end

-- Seats the rarity badge just left of the tier text, on the label's own line. The text is centred in its
-- label, so the badge's right edge sits half the text's share of the label (TextBounds over the label's
-- width, both in the same scaled pixels) plus a gap left of the centre line. Until the text is measured it
-- sits at the label's left edge instead, clear of the text. Called when the label moves (the size stamp)
-- and whenever the text is re-measured, so the badge follows the label.
local function placeTierBadge()
	local badge, label = tierBadge, tierLabel
	if not badge or not label then
		return
	end
	local labelWidth = label.AbsoluteSize.X
	local share = if labelWidth > 0 and label.TextBounds.X > 0 then math.min(1, label.TextBounds.X / labelWidth) else 1
	badge.Position = UDim2.fromScale(0.5 - TIER_LABEL_W * share / 2 - TIER_ICON_GAP, label.Position.Y.Scale)
end

-- Stops the sunburst's turning; the sprite stays until clearRays.
local function stopRays()
	if raysTween then
		raysTween:Cancel()
		raysTween = nil
	end
end

local function clearRays()
	stopRays()
	if raysFrame then
		raysFrame:Destroy()
		raysFrame = nil
	end
end

-- Tweens ------------------------------------------------------------------

-- A tween that belongs to the phase on screen: cancelRunning stops them all when the phase ends or the Reveal closes.
local function play(target: Instance, seconds: number, style: Enum.EasingStyle, direction: Enum.EasingDirection, goal: { [string]: any }): Tween
	local tween = TweenService:Create(target, TweenInfo.new(seconds, style, direction), goal)
	table.insert(running, tween)
	tween:Play()
	return tween
end

local function cancelRunning()
	for _, tween in ipairs(running) do
		tween:Cancel()
	end
	table.clear(running)
end

-- Runs `step` after `seconds` unless the sequence has moved on (a later phase, a close, a new Show) in the meantime.
local function later(seconds: number, step: () -> ())
	local mine = seq
	task.delay(seconds, function()
		if open and seq == mine then
			step()
		end
	end)
end

-- Runs `step` after `seconds` unless the Reveal closed or showed again: for the hero beat's effects, which a tap that settles
-- the card should not cut short.
local function afterShow(seconds: number, step: () -> ())
	local mine = showGen
	task.delay(seconds, function()
		if open and showGen == mine then
			step()
		end
	end)
end

local function cancelAmbient()
	for _, tween in ipairs(ambient) do
		tween:Cancel()
	end
	table.clear(ambient)
end

-- The name as it ends: every letter shown, the cursor gone, any spelling stopped.
local function finishSpell()
	spellToken += 1
	if nameLabel then
		nameLabel.MaxVisibleGraphemes = -1
	end
	if spellCursor then
		spellCursor.Visible = false
	end
end

-- The gold frame stops chasing (it stays where it is until the card goes).
local function stopGoldChase()
	goldToken += 1
end

local function stopBurstLoop()
	if burstTween then
		burstTween:Cancel()
		burstTween = nil
	end
end

local function close()
	if not open then
		return
	end
	open = false
	seq += 1
	showGen += 1
	phase = "Idle"
	cancelRunning()
	cancelAmbient()
	stopGoldChase()
	finishSpell()
	local root = gui
	stopBurstLoop()
	stopRays()
	if stopOverlayShine then
		stopOverlayShine()
		stopOverlayShine = nil
	end
	-- The buttons and the footer go at once; the card shrinks away and the root follows.
	if buttonsHolder then
		buttonsHolder.Visible = false
	end
	if footerLabel then
		footerLabel.Visible = false
	end
	if card and root then
		Builder.close(card, function()
			if not open then
				clearModel()
				clearRays()
				root.Enabled = false
			end
		end)
	elseif root then
		clearModel()
		clearRays()
		root.Enabled = false
	end
	local callback = onClose
	onClose = nil
	if callback then
		callback()
	end
	if storageHint then
		storageHint = false
		Toast.Show(Strings.TOAST_STORAGE_FULL_HINT, Theme.Colors.Close)
	end
end

-- The card's width in px, from the viewport: the card is CARD_SIZE of it held to CARD_ASPECT. Read from the camera and not
-- from the card, whose AbsoluteSize follows the open and pop tweens (a UIScale) and is zero while the gui is disabled.
local function cardPx(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 0
	end
	local view = camera.ViewportSize
	return math.min(CARD_SIZE.X.Scale * view.X, CARD_SIZE.Y.Scale * view.Y * CARD_ASPECT)
end

-- The screen's width over its height; 1 until the camera is there.
local function viewportAspect(): number
	local camera = workspace.CurrentCamera
	if not camera or camera.ViewportSize.Y <= 0 then
		return 1
	end
	return camera.ViewportSize.X / camera.ViewportSize.Y
end

-- Sets the overlay badge's width, in Scale of the card, to hold the longest overlay name on one line at the 14 px floor
-- (Builder.longestOverlayName, measured once), never under BADGE_MIN_W. Runs at build and when the window resizes.
local function fitOverlayBadge()
	local badge = overlayBadge
	if not badge then
		return
	end
	local width = BadgeFit.Width(Builder.longestOverlayName().whole.px, cardPx(), Builder.badgeParams(BADGE_MIN_W, BADGE_MAX_W))
	badge.Size = UDim2.fromScale(width, BADGE_H)
end

local onBackdropTap: () -> string -- assigned below: what a tap anywhere does in each phase; answers the cue for it ("" for none)
local onKeepGoing: () -> ()
local onPlaceIt: () -> ()

-- The stage: the egg, its glow, the shards, the word and the prompt, in one full-screen frame that pushes in as a whole.
local function buildStage(root: ScreenGui)
	local stage = Builder.frame({
		parent = root,
		name = "Stage",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(1, 1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Z_STAGE,
	})
	stage.Visible = false
	stageFrame = stage
	local pushScale = Instance.new("UIScale")
	pushScale.Parent = stage
	stageScale = pushScale

	local center = UDim2.fromScale(0.5, RevealData.StageY)
	local middle = Vector2.new(0.5, 0.5)
	-- The glow: the tier colour leaking from behind the egg, two pixel octagons (ink the same colour, so no ring) so the edge
	-- steps out softly.
	local function glow(name: string, height: number, z: number): { Frame }
		local octagon = Builder.pixelOctagon({
			parent = stage,
			name = name,
			color = Theme.Colors.White,
			ink = Theme.Colors.White,
			position = center,
			size = UDim2.fromScale(1, height),
			anchor = middle,
			zIndex = z,
		})
		local frames: { Frame } = {}
		for _, frame in ipairs(octagon.ink) do
			table.insert(frames, frame)
		end
		for _, frame in ipairs(octagon.fill) do
			table.insert(frames, frame)
		end
		return frames
	end
	glowOuter = glow("Glow", RevealData.GlowHeight, 1)
	glowCore = glow("GlowCore", RevealData.GlowHeight * RevealData.GlowCoreScale, 3)
	-- The tap ring: square white dots round the egg that breathe, the cue that the egg is the thing to tap.
	local ring = Builder.frame({
		parent = stage,
		name = "TapRing",
		position = center,
		size = UDim2.fromScale(1, RevealData.TapRingHeight),
		anchor = middle,
		aspect = 1,
		zIndex = 5,
	})
	for index = 1, TAP_RING_DOTS do
		local angle = (index - 1) / TAP_RING_DOTS * math.pi * 2
		Builder.frame({
			parent = ring,
			name = "Dot",
			color = Theme.Colors.White,
			position = UDim2.fromScale(0.5 + 0.5 * math.cos(angle), 0.5 + 0.5 * math.sin(angle)),
			size = UDim2.fromScale(TAP_RING_DOT, TAP_RING_DOT),
			anchor = middle,
			zIndex = 5,
		})
	end
	ring.Visible = false
	tapRing = ring
	local ringScale = Instance.new("UIScale")
	ringScale.Parent = ring
	tapRingScale = ringScale

	-- The egg: a pixel egg on its EggCols by EggRows grid (RevealMath.EggBars): the navy ink one pixel round the cream, the top
	-- rows lit and the bottom rows shaded, square speckles; the cracks are stepped pixels, one set per tap.
	local egg = Builder.frame({
		parent = stage,
		name = "Egg",
		position = center,
		size = UDim2.fromScale(1, RevealData.EggHeight),
		anchor = middle,
		aspect = RevealData.EggAspect,
		zIndex = 6,
	})
	egg.Visible = false
	eggHolder = egg
	local pulse = Instance.new("UIScale")
	pulse.Parent = egg
	eggPulse = pulse
	local cols, rows = RevealData.EggCols, RevealData.EggRows
	local function pixelBar(name: string, bar: RevealMath.Bar, color: Color3, transparency: number, z: number): Frame
		return Builder.frame({
			parent = egg,
			name = name,
			position = UDim2.fromScale(bar.x / cols, bar.y / rows),
			size = UDim2.fromScale(bar.w / cols, bar.h / rows),
			color = color,
			transparency = transparency,
			zIndex = z,
		})
	end
	local ink, fill, lit, shade = RevealMath.EggBars()
	for _, bar in ipairs(ink) do
		pixelBar("Ink", bar, Theme.Colors.Outline, 0, 1)
	end
	for _, bar in ipairs(fill) do
		pixelBar("Shell", bar, Theme.Colors.Panel, 0, 2)
	end
	local speckleColor = Builder.darker(Theme.Colors.Panel, 0.12)
	for index, row in ipairs(RevealData.Speckles) do
		local side = math.max(1, math.floor(row[3] * cols + 0.5))
		local bar: RevealMath.Bar = {
			x = math.floor(row[1] * cols - side / 2 + 0.5),
			y = math.floor(row[2] * rows - side / 2 + 0.5),
			w = side,
			h = side,
		}
		pixelBar("Speckle" .. index, bar, speckleColor, 0, 3)
	end
	for _, bar in ipairs(lit) do
		pixelBar("Lit", bar, Theme.Colors.White, Theme.Block.TopAlpha, 4)
	end
	for _, bar in ipairs(shade) do
		pixelBar("Shade", bar, Theme.Colors.Black, Theme.Block.EdgeAlpha, 4)
	end
	table.clear(crackBars)
	for tap = 1, RevealData.CrackTaps do
		local bars: { Frame } = {}
		for index, cell in ipairs(RevealMath.CrackCells(tap)) do
			local piece = pixelBar("Crack" .. tap .. "_" .. index, { x = cell[1], y = cell[2], w = 1, h = 1 }, Theme.Colors.Outline, 0, 5)
			piece.Visible = false
			table.insert(bars, piece)
		end
		table.insert(crackBars, bars)
	end

	-- The shards: flat blocks 3 by 7 cells in the navy ink; their colour is set per show (shell cream or the tier colour).
	table.clear(shardPieces)
	for index = 1, RevealData.ShardCount do
		local piece = Builder.blockPlate({
			parent = stage,
			name = "Shard" .. index,
			color = Theme.Colors.Panel,
			aspect = RevealData.ShardAspect,
			rows = SHARD_ROWS,
			cells = false,
			position = center,
			size = UDim2.fromScale(1, RevealData.ShardHeight),
			anchor = middle,
			zIndex = 7,
		})
		piece.Visible = false
		table.insert(shardPieces, piece)
	end

	-- The tier word, big, in the tier colour with a heavy outline.
	local word = Builder.label({
		parent = stage,
		name = "Word",
		text = "",
		textSize = RevealData.WordMaxPx,
		position = center,
		size = UDim2.fromScale(RevealData.WordWidth, RevealMath.PxToScale(RevealData.WordPx)),
		anchor = middle,
		stroke = Theme.Stroke.Panel,
		zIndex = 12,
	})
	word.Visible = false
	wordLabel = word

	-- The prompt and the dots that count the taps (square flat blocks in white ink).
	local prompt = Builder.label({
		parent = stage,
		name = "Prompt",
		text = Strings.REVEAL_CRACK,
		textSize = RevealData.PromptMaxPx,
		position = UDim2.fromScale(0.5, RevealData.PromptY),
		size = UDim2.fromScale(RevealData.PromptWidth, RevealMath.PxToScale(RevealData.PromptPx)),
		anchor = middle,
		zIndex = 12,
	})
	prompt.Visible = false
	promptLabel = prompt
	local dots = RevealData.CrackTaps
	local across = dots + (dots - 1) * RevealData.DotGap -- the row's width, in dot widths
	local holder = Builder.frame({
		parent = stage,
		name = "Dots",
		position = UDim2.fromScale(0.5, RevealData.DotY),
		size = UDim2.fromScale(1, RevealData.DotHeight),
		anchor = middle,
		aspect = across,
		zIndex = 12,
	})
	holder.Visible = false
	dotsHolder = holder
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(RevealData.DotGap / across, 0)
	layout.Parent = holder
	table.clear(dotFrames)
	for index = 1, dots do
		local dot = Builder.blockPlate({
			parent = holder,
			name = "Dot" .. index,
			color = Theme.Colors.Outline,
			ink = Theme.Colors.White,
			size = UDim2.fromScale(1 / across, 1),
			aspect = 1,
			rows = Theme.Block.MinRows,
			cells = false,
			zIndex = 12,
		})
		Builder.setBlockFade(dot, RevealData.DotEmptyTransparency)
		dot.LayoutOrder = index
		table.insert(dotFrames, dot)
	end
end

-- The two buttons of the card's last beat, in the bottom corners, in a holder that slides up as one: block buttons in cells
-- (fitted to their box), with the 44 px hit area.
local function buildButtons(root: ScreenGui)
	local holder = Builder.frame({
		parent = root,
		name = "Buttons",
		zIndex = Z_BUTTONS,
	})
	holder.Visible = false
	buttonsHolder = holder
	local size = UDim2.fromScale(RevealData.ButtonWidth, RevealMath.PxToScale(RevealData.ButtonHeightPx))
	placeButton = Builder.blockButton({
		parent = holder,
		name = "PlaceIt",
		text = Strings.REVEAL_PLACE,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(RevealData.ButtonMargin, RevealData.ButtonBottom),
		size = size,
		anchor = Vector2.new(0, 1),
		textSize = Theme.TextSize.Label,
		rows = RevealData.ButtonRows,
		zIndex = Z_BUTTONS,
		hit = true,
	}, function()
		onPlaceIt()
	end)
	Builder.blockButton({
		parent = holder,
		name = "KeepGoing",
		text = Strings.REVEAL_KEEP,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(1 - RevealData.ButtonMargin, RevealData.ButtonBottom),
		size = size,
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Label,
		rows = RevealData.ButtonRows,
		zIndex = Z_BUTTONS,
		hit = true,
	}, function()
		onKeepGoing()
	end)
end

-- The pixel sky of Cosmic and Secret: SkyBands full-width bands (coloured per show, from the tier's colour at the top stepping
-- down to the night) and SkyStars square star cells, all clear until showSky. Takes no input.
local function buildSky(root: ScreenGui)
	local sky = Builder.frame({
		parent = root,
		name = "Sky",
		zIndex = Z_SKY,
	})
	sky.Visible = false
	skyFrame = sky
	table.clear(skyBands)
	local bands = RevealData.SkyBands
	for index = 1, bands do
		table.insert(
			skyBands,
			Builder.frame({
				parent = sky,
				name = "Band",
				color = Theme.Colors.Outline,
				transparency = 1,
				position = UDim2.fromScale(0, (index - 1) / bands),
				size = UDim2.fromScale(1, 1 / bands),
				zIndex = Z_SKY,
			})
		)
	end
	table.clear(skyStars)
	for _ = 1, RevealData.SkyStars do
		table.insert(
			skyStars,
			Builder.frame({
				parent = sky,
				name = "Star",
				color = Theme.Colors.White,
				transparency = 1,
				position = UDim2.fromScale(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.03, 0.9)),
				size = UDim2.fromScale(1, RevealData.SkyStarSize),
				anchor = Vector2.new(0.5, 0.5),
				aspect = 1,
				zIndex = Z_SKY + 1,
			})
		)
	end
end

-- The gold cell frame round the card (Legendary and up): GoldFrameCells square gold cells evenly round a rectangle GoldFrameGap
-- outside the card, in a holder with the card's place, size and shape. Hidden until a tier with GoldFrame lands.
local function buildGoldFrame(root: ScreenGui)
	local holder = Builder.frame({
		parent = root,
		name = "GoldFrame",
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		aspect = CARD_ASPECT,
		zIndex = Z_FRAME,
	})
	holder.Visible = false
	goldFrame = holder
	local gap = RevealData.GoldFrameGap -- in card heights, the same px all round
	local w, h = CARD_ASPECT + 2 * gap, 1 + 2 * gap -- the frame's sides, in card heights
	local perimeter = 2 * (w + h)
	local cell = RevealData.GoldFrameCellSize / CARD_SIZE.Y.Scale -- a cell, of the card's height
	local gold = Builder.tierColor(RevealData.GroundRingRarity)
	table.clear(goldCells)
	for index = 0, RevealData.GoldFrameCells - 1 do
		local d = index / RevealData.GoldFrameCells * perimeter
		local x, y
		if d < w then
			x, y = d, 0
		elseif d < w + h then
			x, y = w, d - w
		elseif d < 2 * w + h then
			x, y = w - (d - w - h), h
		else
			x, y = 0, h - (d - 2 * w - h)
		end
		table.insert(
			goldCells,
			Builder.frame({
				parent = holder,
				name = "Cell",
				color = gold,
				transparency = RevealData.GoldFrameDimAlpha,
				position = UDim2.fromScale((x - gap) / CARD_ASPECT, y - gap),
				size = UDim2.fromScale(1, cell),
				anchor = Vector2.new(0.5, 0.5),
				aspect = 1,
				zIndex = Z_FRAME,
			})
		)
	end
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Reveal", 30)
	root.Enabled = false
	gui = root

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = Z_DIM
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(onBackdropTap())
	end)
	buildSky(root)

	-- A Secret dims the screen further and opens a dark iris behind the card: a black pixel octagon in the purple ink.
	dimExtra = Builder.frame({
		parent = root,
		name = "DimExtra",
		color = Theme.Colors.Black,
		transparency = 1,
		zIndex = Z_EXTRA_DIM,
	})
	local eye = Builder.pixelOctagon({
		parent = root,
		name = "Iris",
		color = Theme.Colors.Black,
		ink = Theme.Colors.Codex,
		position = UDim2.fromScale(0.5, RevealData.StageY),
		size = UDim2.fromScale(1, RevealData.IrisHeight),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Z_BEHIND,
	})
	Builder.paintOctagon(eye, Theme.Colors.Black, RevealData.IrisTransparency, Theme.Colors.Codex, 0, false)
	eye.holder.Visible = false
	iris = eye.holder
	local eyeScale = Instance.new("UIScale")
	eyeScale.Parent = eye.holder
	irisScale = eyeScale

	-- The ray ring: RayCount bars through the middle, each carrying square cells both ways out from the centre (drawn per show:
	-- the tier's RayCells), spun up by the shard beat and then turned slowly while the card is up.
	local rays = Builder.frame({
		parent = root,
		name = "Burst",
		position = UDim2.fromScale(0.5, RevealData.StageY),
		size = UDim2.fromScale(0.9, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = Z_BEHIND,
	})
	rays.Visible = false
	local raysScale = Instance.new("UIScale")
	raysScale.Parent = rays
	burstScale = raysScale
	table.clear(rayBars)
	for i = 1, RevealData.RayCount do
		local bar = Builder.frame({
			parent = rays,
			name = "Ray",
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(1, 0.05),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = Z_BEHIND,
		})
		bar.Rotation = (180 / RevealData.RayCount) * (i - 1)
		table.insert(rayBars, bar)
	end
	burst = rays
	buildGoldFrame(root)

	-- The card: a cream block plate at the card cell, its ink the tier's colour (set per show).
	local panel = Builder.blockPlate({
		parent = root,
		name = "Card",
		color = Theme.Colors.Panel,
		ink = Theme.Rarity.Common,
		aspect = CARD_ASPECT,
		rows = Builder.blockRows(CARD_SIZE.Y.Scale, RevealData.CardCell),
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Z_CARD,
	})
	panel.Visible = false
	card = panel
	local panelScale = Instance.new("UIScale") -- the close shrink and a size band's pop work on this
	panelScale.Parent = panel

	-- The gold ground ring under the model of a Grand tier: square gold dots on an ellipse, under the viewport.
	local ground = Builder.frame({
		parent = panel,
		name = "GroundRing",
		position = UDim2.fromScale(0.5, RevealData.RingY),
		size = UDim2.fromScale(RevealData.RingWidth, RevealData.RingHeight),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = CARD_TOP,
	})
	local gold = Builder.tierColor(RevealData.GroundRingRarity)
	for index = 1, GROUND_RING_DOTS do
		local angle = (index - 1) / GROUND_RING_DOTS * math.pi * 2
		Builder.frame({
			parent = ground,
			name = "Dot",
			color = gold,
			position = UDim2.fromScale(0.5 + 0.5 * math.cos(angle), 0.5 + 0.5 * math.sin(angle)),
			size = UDim2.fromScale(1, GROUND_RING_DOT),
			anchor = Vector2.new(0.5, 0.5),
			aspect = 1,
			zIndex = CARD_TOP,
		})
	end
	groundRing = ground

	-- The placeholder shape: an edged block in the species colour (set per show) with the shape's name on it.
	local box = Builder.blockPlate({
		parent = panel,
		name = "Shape",
		color = Theme.Rarity.Common,
		aspect = 1,
		rows = SHAPE_ROWS,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.5, 0.34),
		size = UDim2.fromScale(0.56, 0.56),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = CARD_TOP + 1,
	})
	shapeBox = box
	shapeLabel = Builder.label({
		parent = box,
		name = "ShapeName",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.3),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(box),
	})
	-- The mesh view, over the same square as the shape block; only one of the two is visible at a time.
	local view = Instance.new("ViewportFrame")
	view.Name = "Model"
	view.BackgroundTransparency = 1
	view.BorderSizePixel = 0
	view.Position = UDim2.fromScale(0.5, 0.34)
	view.Size = UDim2.fromScale(0.56, 0.56)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Ambient = Builder.darker(Theme.Colors.White, 0.45) -- soft grey fill light
	view.LightColor = Theme.Colors.White
	view.LightDirection = Vector3.new(-1, -2, -1)
	view.ZIndex = CARD_TOP + 1
	view.Visible = false
	Builder.aspect(view, 1)
	view.Parent = panel
	local camera = Instance.new("Camera")
	camera.FieldOfView = VIEW_FOV
	camera.Parent = view
	view.CurrentCamera = camera
	viewBox = view
	viewCamera = camera
	local name = Builder.label({
		parent = panel,
		name = "Species",
		text = "",
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, NAME_Y),
		size = UDim2.fromScale(0.9, 0.12),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = CARD_TOP + 1,
	})
	nameLabel = name
	-- The cell that runs ahead of the letters while a top tier's name spells in.
	local cursor = Builder.frame({
		parent = name,
		name = "SpellCursor",
		color = Theme.Colors.White,
		position = UDim2.fromScale(0, 0.5),
		size = UDim2.fromScale(1, RevealData.SpellCursor),
		anchor = Vector2.new(0, 0.5),
		aspect = 1,
		zIndex = CARD_TOP + 2,
	})
	cursor.Visible = false
	spellCursor = cursor
	local tier = Builder.label({
		parent = panel,
		name = "Tier",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, TIER_Y),
		size = UDim2.fromScale(TIER_LABEL_W, TIER_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = CARD_TOP + 1,
	})
	tierLabel = tier
	tier:GetPropertyChangedSignal("TextBounds"):Connect(placeTierBadge)
	tier:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeTierBadge)
	-- Size stamp (shown only for the bands that name themselves): the band and the species in gold over
	-- the model's foot, then the Scrap multiplier small beneath the tier.
	local stamp = Builder.label({
		parent = panel,
		name = "SizeStamp",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, STAMP_Y),
		size = UDim2.fromScale(0.94, 0.07),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = CARD_TOP + 3,
	})
	stamp.Visible = false
	stampLabel = stamp
	local stampScrap = Builder.label({
		parent = root,
		name = "SizeScrap",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, STAMP_SCRAP_Y),
		size = UDim2.fromScale(0.5, 0.05),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = Z_LINES,
	})
	stampScrap.Visible = false
	stampScrapLabel = stampScrap
	-- The overlay badge: a fitted flat block (BadgeFit sets its width, and the plate redraws its columns).
	local badge = Builder.blockPlate({
		parent = panel,
		name = "Overlay",
		color = Theme.Colors.Codex,
		rows = Theme.Block.MinRows,
		cells = false,
		position = UDim2.fromScale(0.96, 0.04),
		size = UDim2.fromScale(BADGE_MIN_W, BADGE_H),
		anchor = Vector2.new(1, 0),
		zIndex = CARD_TOP + 3,
	})
	overlayBadge = badge
	overlayLabel = Builder.label({
		parent = badge,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(Builder.BadgeTextFraction, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(badge),
	})
	-- The badge is right-anchored, so fitting its width grows it to the left, toward the NEW! ribbon and no further than
	-- BADGE_MAX_W. The longest overlay name sets it for every overlay, so the badge never changes size between catches.
	local fitCamera = workspace.CurrentCamera
	fitOverlayBadge()
	if fitCamera then
		fitCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitOverlayBadge)
	end
	-- Diagonal NEW! ribbon across the top-left corner: an edged red block, tilted.
	local ribbon = Builder.blockPlate({
		parent = panel,
		name = "New",
		color = Theme.Colors.Close,
		aspect = 0.5 * CARD_ASPECT / 0.09,
		rows = RIBBON_ROWS,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.12, 0.08),
		size = UDim2.fromScale(0.5, 0.09),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = CARD_TOP + 3,
	})
	ribbon.Rotation = -25
	newRibbon = ribbon
	Builder.label({
		parent = ribbon,
		name = "Text",
		text = Strings.CATCH_NEW,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(ribbon),
	})
	-- The chance line: a navy flat block hanging on the card's bottom edge, wider than the card (the card is 168 px across at
	-- 667x375, too narrow for "1 in 67 · 1.5% chance" at the 14 px floor), its ink the tier's colour, white outlined text.
	local odds = Builder.blockPlate({
		parent = panel,
		name = "Odds",
		color = Theme.Colors.Outline,
		ink = Theme.Colors.White,
		aspect = RevealData.OddsWidth * CARD_ASPECT / RevealData.OddsHeight,
		rows = RevealData.OddsRows,
		cells = false,
		position = UDim2.fromScale(0.5, RevealData.OddsY),
		size = UDim2.fromScale(RevealData.OddsWidth, RevealData.OddsHeight),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = ODDS_Z,
	})
	odds.Visible = false
	oddsPill = odds
	oddsLabel = Builder.label({
		parent = odds,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.92, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(odds),
	})
	-- Storage-full ribbon (shown only for a grant that overflowed the cap): an edged red block above the card.
	local storage = Builder.blockPlate({
		parent = root,
		name = "StorageFull",
		color = Theme.Colors.Close,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.5, STORAGE_Y),
		size = UDim2.fromScale(STORAGE_W, STORAGE_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Z_LINES,
	})
	storage.Visible = false
	storageRibbon = storage
	storageLabel = Builder.label({
		parent = storage,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.92, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(storage),
	})
	scrapLabel = Builder.label({
		parent = root,
		name = "Scrap",
		text = "",
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.815),
		size = UDim2.fromScale(0.5, 0.08),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = Z_LINES,
	})
	-- Perfect bonus line under the Scrap line: gold outlined text, shown only for a Perfect catch.
	local bonus = Builder.label({
		parent = root,
		name = "PerfectBonus",
		text = Strings.CATCH_PERFECT_BONUS:format(Config.PerfectScrapMultiplier),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.885),
		size = UDim2.fromScale(0.4, 0.06),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		zIndex = Z_LINES,
	})
	bonus.Visible = false
	perfectLabel = bonus
	local footer = Builder.label({
		parent = root,
		name = "Footer",
		text = Strings.REVEAL_TAP,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, RevealData.FooterY),
		size = UDim2.fromScale(RevealData.FooterWidth, RevealData.FooterHeight),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Z_FOOTER,
	})
	footer.Visible = false
	footerLabel = footer
	buildStage(root)
	buildButtons(root)
end

-- The sunburst sprite (Icons.Particles.Shine) behind the card, built per reveal: a square in the tier
-- colour, RAYS_WIDTH card widths wide, turning once per Config.VfxRevealRaysSeconds (still under Reduced
-- Motion). Nothing is made while the sprite is not uploaded. Layered under the card, over the dim.
local function showRays(root: ScreenGui, tierColor: Color3)
	clearRays()
	local sprite = Icons.Particles.Shine
	if sprite == 0 then
		return
	end
	-- A holder with the card's own place, size and shape, so the sprite is sized in card widths with Scale only.
	local holder = Builder.frame({
		parent = root,
		name = "Sunburst",
		position = CARD_POSITION,
		size = CARD_SIZE,
		anchor = Vector2.new(0.5, 0.5),
		aspect = CARD_ASPECT,
		zIndex = Z_BEHIND,
	})
	local image = Instance.new("ImageLabel")
	image.Name = "Rays"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = "rbxassetid://" .. sprite
	image.ImageColor3 = tierColor
	image.ImageTransparency = RAYS_TRANSPARENCY
	image.ScaleType = Enum.ScaleType.Fit
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(RAYS_WIDTH, RAYS_WIDTH * CARD_ASPECT) -- the holder is CARD_ASPECT wide per tall: this is square
	image.ZIndex = 2
	image.Parent = holder
	raysFrame = holder
	if not reducedNow then
		local spin = TweenService:Create(image, TweenInfo.new(Config.VfxRevealRaysSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		raysTween = spin
		spin:Play()
	end
end

-- One confetti piece at the stage's centre: the Confetti sprite (Icons.Particles) when it is uploaded,
-- a plain frame otherwise. Also returns the property that fades it.
local function confettiPiece(root: ScreenGui, color: Color3, sprite: number): (GuiObject, string)
	if sprite ~= 0 then
		local image = Instance.new("ImageLabel")
		image.Name = "Confetti"
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Image = "rbxassetid://" .. sprite
		image.ImageColor3 = color
		image.ScaleType = Enum.ScaleType.Fit
		image.Position = UDim2.fromScale(0.5, RevealData.StageY)
		image.Size = UDim2.fromScale(0.012, 0.025)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ZIndex = Z_BUTTONS
		image.Parent = root
		return image, "ImageTransparency"
	end
	local piece = Builder.frame({ -- a confetti cell: a square, like every cell on a block screen
		parent = root,
		name = "Confetti",
		position = UDim2.fromScale(0.5, RevealData.StageY),
		size = UDim2.fromScale(1, RevealData.SparkleSize),
		anchor = Vector2.new(0.5, 0.5),
		color = color,
		aspect = 1,
		zIndex = Z_BUTTONS,
	})
	return piece, "BackgroundTransparency"
end

local function confetti(root: ScreenGui, tierColor: Color3, count: number)
	local palette = { tierColor, Theme.Colors.Featured, Theme.Colors.Confirm, Theme.Colors.Select, Theme.Colors.Close, Theme.Colors.White }
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local sprite = Icons.Particles.Confetti
	for _ = 1, count do
		local piece, fade = confettiPiece(root, palette[rng:NextInteger(1, #palette)], sprite)
		piece.Rotation = rng:NextNumber(0, 360)
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0.18, 0.42)
		local target = UDim2.fromScale(0.5 + math.cos(angle) * distance, RevealData.StageY + math.sin(angle) * distance * 1.4)
		local tween = TweenService:Create(piece, info, { Position = target, Rotation = piece.Rotation + rng:NextNumber(-360, 360), [fade] = 1 })
		tween.Completed:Once(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

-- The white flash of a Perfect catch: a full-screen frame over everything on the reveal, fading out and
-- then removed. A plain Frame that is not Active, so it takes no input and the tap that closes still lands.
local function perfectFlash(root: ScreenGui)
	local flash = Builder.frame({
		parent = root,
		name = "PerfectFlash",
		color = Theme.Colors.White,
		transparency = FLASH_START,
		zIndex = FLASH_LAYER,
	})
	flash.Active = false
	local tween = TweenService:Create(flash, TweenInfo.new(Config.VfxPerfectFlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		flash:Destroy()
	end)
	tween:Play()
end

-- The "+N Scrap" line floats up from the card's foot and fades; once per Show (a settle after the landing does not restart it).
local function flyScrap(amount: number)
	local label = scrapLabel
	if not label or scrapStarted then
		return
	end
	scrapStarted = true
	local mine = scrapGen
	if amount <= 0 then
		label.Visible = false
		return
	end
	label.Text = Strings.REVEAL_SCRAP:format(Builder.formatNumber(amount))
	label.TextTransparency = 0
	label.Position = UDim2.fromScale(0.5, 0.8)
	label.Visible = true
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	task.delay(0.6, function()
		if mine ~= scrapGen then
			return
		end
		local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(label, info, { Position = UDim2.fromScale(0.5, 0.66), TextTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
	end)
end

-- Model view -------------------------------------------------------------

local function speciesFor(info: RevealInfo): Types.SpeciesDef?
	local id = info.speciesId
	if id then
		return Species.ById[id]
	end
	local byName = speciesByName
	if byName then
		return byName[info.speciesName]
	end
	local map: { [string]: Types.SpeciesDef } = {}
	for _, def in ipairs(Species.List) do
		map[def.name] = def
	end
	speciesByName = map
	return map[info.speciesName]
end

-- The model's pivot (its feet) sits on the viewport origin; the camera looks at its centre from the
-- front-left, slightly above, far enough back for the whole bounding box at this field of view.
local function frameCamera(camera: Camera, model: Model)
	local size = model:GetExtentsSize()
	local radius = math.max(size.X, size.Y, size.Z) / 2
	local distance = radius / math.tan(math.rad(VIEW_FOV) / 2) * VIEW_FIT
	local target = Vector3.new(0, size.Y / 2, 0)
	camera.CFrame = CFrame.lookAt(target + VIEW_DIRECTION.Unit * distance, target)
end

-- Shows the species mesh turning in the viewport when one exists, the placeholder shape frame otherwise.
local function showModel(def: Types.SpeciesDef?)
	clearModel()
	local view, camera = viewBox, viewCamera
	local model: Model? = nil
	if def and view and camera then
		model = Models.Clone(def, Config.ModelViewportScale)
	end
	if shapeBox then
		shapeBox.Visible = model == nil
	end
	if not view or not camera then
		return
	end
	view.Visible = model ~= nil
	if not model then
		return
	end
	spinAngle = 0
	model:PivotTo(CFrame.Angles(0, spinAngle, 0))
	model.Parent = view
	frameCamera(camera, model)
	viewModel = model
	RigAnimator.Attach(model, if def then def.id else "", { always = true }) -- the B46 idle in the viewport; released on destroy
	spinConn = RunService.RenderStepped:Connect(function(dt: number)
		spinAngle = (spinAngle + dt * VIEW_SPIN * spinScale) % (math.pi * 2)
		model:PivotTo(CFrame.Angles(0, spinAngle, 0))
	end)
end

-- Size stamp --------------------------------------------------------------

-- A whole multiplier prints bare ("2"), a fractional one with its decimals trimmed ("1.5", "1.25").
local function formatMultiplier(multiplier: number): string
	if multiplier == math.floor(multiplier) then
		return tostring(math.floor(multiplier))
	end
	return (string.format("%.2f", multiplier):gsub("0+$", ""))
end

-- Sets the size stamp for a band and moves the name and tier lines to suit; the stamp itself shows with the chips (revealChips).
-- A band without a label (Normal, Small) leaves the card exactly as it was.
local function showStamp(info: RevealInfo, band: Sizes.Band)
	local stamp, stampScrap = stampLabel, stampScrapLabel
	local stamped = band.label
	chipStamp = stamped
	if nameLabel then
		nameLabel.Position = UDim2.fromScale(0.5, if stamped then NAME_Y_STAMPED else NAME_Y)
	end
	if tierLabel then
		tierLabel.Position = UDim2.fromScale(0.5, if stamped then TIER_Y_STAMPED else TIER_Y)
		placeTierBadge()
	end
	if stamp then
		stamp.Visible = false
		if stamped then
			stamp.Text = if band.scrapMultiplier ~= 1
				then Strings.REVEAL_SIZE_SCRAP:format(Builder.text("SIZE_" .. band.id), info.speciesName, formatMultiplier(band.scrapMultiplier))
				else Strings.REVEAL_SIZE:format(Builder.text("SIZE_" .. band.id), info.speciesName)
			local scale = stamp:FindFirstChildOfClass("UIScale")
			if scale then
				scale.Scale = 1
			end
		end
	end
	if stampScrap then
		local bonus = stamped and band.scrapMultiplier ~= 1
		stampScrap.Visible = bonus
		if bonus then
			stampScrap.Text = "" -- the multiplier rides on the stamp line; the root's Scrap, Perfect and Tap lines keep their slots
		end
	end
end

-- The card's pop-in for a band with its own revealPop: up from the usual start to `peak` times the
-- resting size with the Back ease, then settling to 1. Normal (1) keeps the plain landing.
local function popCard(panel: GuiObject, peak: number)
	local scale = panel:FindFirstChildOfClass("UIScale")
	if not scale then
		return
	end
	scale.Scale = 0.85
	local rise = TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = peak })
	table.insert(running, rise)
	rise.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed and open then
			local settle = TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
			table.insert(running, settle)
			settle:Play()
		end
	end)
	rise:Play()
end

-- The beats ----------------------------------------------------------------

-- The glow behind the egg, at `transparency` at its centre (the outer disc, the soft edge, sits part of the way to clear).
local function setGlow(transparency: number)
	for _, frame in ipairs(glowOuter) do
		frame.BackgroundTransparency = transparency + (1 - transparency) * RevealData.GlowSoftness
	end
	for _, frame in ipairs(glowCore) do
		frame.BackgroundTransparency = transparency
	end
end

local function tweenGlow(transparency: number, seconds: number)
	local edge = transparency + (1 - transparency) * RevealData.GlowSoftness
	for _, frame in ipairs(glowOuter) do
		play(frame, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = edge })
	end
	for _, frame in ipairs(glowCore) do
		play(frame, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = transparency })
	end
end

-- The colour the show wears: the rarity colour, except that a tier's accent stands in where the tier colour would vanish on the
-- dim (a Secret is near black).
local function accentColor(info: RevealInfo): Color3
	local colors: { [string]: Color3 } = Theme.Colors
	local accent = RevealMath.Flags(info.tier).WordAccent
	return if accent and colors[accent] then colors[accent] else Builder.tierColor(info.tier)
end

local function tintGlow(color: Color3)
	for _, frames in ipairs({ glowOuter, glowCore }) do
		for _, frame in ipairs(frames) do
			frame.BackgroundColor3 = color
		end
	end
end

-- Everything of the three beats back to its starting state: the stage empty and hidden, the card hidden, the extras off.
local function resetStage()
	if stageFrame then
		stageFrame.Visible = false
	end
	if stageScale then
		stageScale.Scale = 1
	end
	if eggHolder then
		eggHolder.Visible = false
		eggHolder.Rotation = 0
	end
	if eggPulse then
		eggPulse.Scale = 1
	end
	for _, bars in ipairs(crackBars) do
		for _, bar in ipairs(bars) do
			bar.Visible = false
		end
	end
	for _, piece in ipairs(shardPieces) do
		piece.Visible = false
		piece.Position = UDim2.fromScale(0.5, RevealData.StageY)
		Builder.setBlockFade(piece, 0)
	end
	setGlow(1)
	if tapRing then
		tapRing.Visible = false
	end
	if tapRingScale then
		tapRingScale.Scale = 1
	end
	if wordLabel then
		wordLabel.Visible = false
		wordLabel.TextTransparency = 0
		local stroke = wordLabel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
	end
	if promptLabel then
		promptLabel.Visible = false
	end
	if dotsHolder then
		dotsHolder.Visible = false
	end
	for _, dot in ipairs(dotFrames) do
		Builder.setBlockColor(dot, Theme.Colors.Outline)
		Builder.setBlockFade(dot, RevealData.DotEmptyTransparency)
		local scale = dot:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
	if dimExtra then
		dimExtra.BackgroundTransparency = 1
	end
	if iris then
		iris.Visible = false
	end
	if irisScale then
		irisScale.Scale = 1
	end
	if burst then
		burst.Visible = false
		burst.Rotation = 0
	end
	raysShown = false
	irisShown = false
	if burstScale then
		burstScale.Scale = 1
	end
	cancelAmbient()
	skyShown = false
	if skyFrame then
		skyFrame.Visible = false
	end
	stopGoldChase()
	if goldFrame then
		goldFrame.Visible = false
	end
	finishSpell()
	if groundRing then
		groundRing.Visible = false
	end
	if oddsPill then
		oddsPill.Visible = false
	end
	if buttonsHolder then
		buttonsHolder.Visible = false
		buttonsHolder.Position = UDim2.fromScale(0, 0)
	end
	if footerLabel then
		footerLabel.Visible = false
	end
	if storageRibbon then
		storageRibbon.Visible = false
	end
	if perfectLabel then
		perfectLabel.Visible = false
	end
	if stampLabel then
		stampLabel.Visible = false
	end
	if card then
		card.Visible = false
		card.Position = CARD_POSITION
	end
end

-- The slow turn of the ray ring behind the card, from wherever it stands; idempotent, and not under Reduced Motion.
local function startRaysLoop()
	local ring = burst
	if not ring or reducedNow or burstTween then
		return
	end
	local loop = TweenService:Create(ring, TweenInfo.new(Config.VfxRevealRaysSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = ring.Rotation + 360 })
	burstTween = loop
	loop:Play()
end

-- Draws the ray ring's cells for this show: `count` square cells along each bar both ways out from RayCellStart of the radius to
-- the rim, RayCellGap of a cell apart, every other bar in the second colour (Cosmic). A bar is as thick as its cells, so they
-- stay square (the ring keeps a 1:1 aspect).
local function fillRays(count: number, first: Color3, second: Color3)
	local start = RevealData.RayCellStart * 0.5 -- of the ring's width, from the centre
	local reach = 0.5 - start
	local side = if count > 0 then reach / (count + (count - 1) * RevealData.RayCellGap) else 0
	for index, bar in ipairs(rayBars) do
		for _, child in ipairs(bar:GetChildren()) do
			child:Destroy()
		end
		bar.Size = UDim2.fromScale(1, math.max(side, 0.001))
		local color = if index % 2 == 1 then first else second
		for _, sign in ipairs({ -1, 1 }) do
			for k = 0, count - 1 do
				local offset = start + k * side * (1 + RevealData.RayCellGap) + side / 2
				Builder.frame({
					parent = bar,
					name = "Cell",
					color = color,
					transparency = RevealData.RayTransparency,
					position = UDim2.fromScale(0.5 + sign * offset, 0.5),
					size = UDim2.fromScale(side, 1),
					anchor = Vector2.new(0.5, 0.5),
					zIndex = Z_BEHIND,
				})
			end
		end
	end
end

-- The ray ring in the tier colour (every other ray in the second colour where the tier has one), its cells the tier's RayCells:
-- grown and spun up from small over `seconds`, or at rest at once. Then the Shine sprite, when uploaded.
local function showRayRing(info: RevealInfo, seconds: number, spinUp: boolean)
	local ring, root = burst, gui
	if not ring or not root then
		return
	end
	raysShown = true
	local first = Builder.tierColor(info.tier)
	local colors: { [string]: Color3 } = Theme.Colors
	local secondName = RevealMath.Flags(info.tier).SecondRayColor
	local second = if secondName and colors[secondName] then colors[secondName] else first
	local animate = spinUp and not reducedNow
	fillRays(RevealMath.Ladder(info.tier).RayCells, first, second)
	ring.Visible = true
	ring.Rotation = 0
	local grow = burstScale
	if animate then
		if grow then
			grow.Scale = 0.2
			play(grow, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
		end
		play(ring, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Rotation = RevealData.RaySpinUpDegrees })
	else
		if grow then
			grow.Scale = 1
		end
		startRaysLoop()
	end
	showRays(root, first)
end

-- The Secret iris: a dark disc with a purple rim opening from a point behind the card, or open at once.
local function showIris(seconds: number, spinUp: boolean)
	local eye, scale = iris, irisScale
	if not eye or not scale then
		return
	end
	irisShown = true
	eye.Visible = true
	if spinUp and not reducedNow then
		scale.Scale = 0.05
		play(scale, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
	else
		scale.Scale = 1
	end
end

-- Lands the rays or the iris of the tier in their resting state, whatever the beat reached, and starts the rays' slow turn.
local function ensureRays(info: RevealInfo)
	local flags = RevealMath.Flags(info.tier)
	if flags.Rays then
		if not raysShown then
			showRayRing(info, 0, false)
		else
			if burstScale then
				burstScale.Scale = 1
			end
			startRaysLoop()
		end
	end
	if flags.Iris then
		if not irisShown then
			showIris(0, false)
		elseif irisScale then
			irisScale.Scale = 1
		end
		if dimExtra then
			dimExtra.BackgroundTransparency = 1 - flags.DimExtra
		end
	end
end

-- The ladder (data/Reveal Ladder) -------------------------------------------------

-- The pixel sky of Cosmic and Secret: the bands step in from the top (the tier's colour stepping down to the night), the stars
-- twinkle; at rest at once under Reduced Motion. Stays behind the card until the Reveal closes.
local function showSky(info: RevealInfo, animate: boolean)
	local sky = skyFrame
	if not sky or skyShown then
		return
	end
	skyShown = true
	sky.Visible = true
	local top = accentColor(info)
	local bands = #skyBands
	for index, band in ipairs(skyBands) do
		band.BackgroundColor3 = top:Lerp(Theme.Colors.Outline, (index - 1) / math.max(1, bands - 1))
		band.BackgroundTransparency = 1
		local function land()
			band.BackgroundTransparency = RevealData.SkyAlpha
		end
		if animate then
			afterShow((index - 1) * RevealData.SkyInSeconds / bands, land)
		else
			land()
		end
	end
	for _, star in ipairs(skyStars) do
		star.BackgroundTransparency = 0
		if animate then
			local twinkle = TweenService:Create(
				star,
				TweenInfo.new(RevealData.SkyTwinkleSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, RevealData.SkyTwinkleSeconds)),
				{ BackgroundTransparency = STAR_TWINKLE_ALPHA }
			)
			table.insert(ambient, twinkle)
			twinkle:Play()
		end
	end
end

-- The gold cell frame round the card: every GOLD_LIT_STRIDE-th cell lit, the lit ones stepping round one cell each
-- GoldFrameStepSeconds until the Reveal closes (still under Reduced Motion).
local function showGoldFrame(animate: boolean)
	local holder = goldFrame
	if not holder then
		return
	end
	holder.Visible = true
	stopGoldChase()
	local token = goldToken
	local function paint(step: number)
		for index, cell in ipairs(goldCells) do
			cell.BackgroundTransparency = if (index - 1 - step) % GOLD_LIT_STRIDE == 0
				then RevealData.GoldFrameLitAlpha
				else RevealData.GoldFrameDimAlpha
		end
	end
	paint(0)
	if not animate then
		return
	end
	task.spawn(function()
		local step = 0
		while open and goldToken == token do
			task.wait(RevealData.GoldFrameStepSeconds)
			if not open or goldToken ~= token then
				return
			end
			step += 1
			paint(step)
		end
	end)
end

-- One burst of sparkle cells from behind the card: square cells in white, gold and the tier's colour fly out and fade.
local function sparkleBurst(root: ScreenGui, info: RevealInfo, count: number)
	local aspect = viewportAspect()
	local palette = { Theme.Colors.White, Theme.Colors.Featured, accentColor(info) }
	local tweenInfo = TweenInfo.new(RevealData.SparkleSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for index = 1, count do
		local piece = Builder.frame({
			parent = root,
			name = "Sparkle",
			color = palette[(index - 1) % #palette + 1],
			position = UDim2.fromScale(0.5, RevealData.StageY),
			size = UDim2.fromScale(1, RevealData.SparkleSize),
			anchor = Vector2.new(0.5, 0.5),
			aspect = 1,
			zIndex = Z_BUTTONS,
		})
		local angle = (index - 1) / count * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local distance = RevealData.SparkleDistance * rng:NextNumber(0.6, 1.1)
		local tween = TweenService:Create(piece, tweenInfo, {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * distance / aspect, RevealData.StageY + math.sin(angle) * distance),
			BackgroundTransparency = 1,
		})
		tween.Completed:Once(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

-- The pixel starburst behind the card: `arms` lines of square cells out from the centre, growing outward, the tip white; it
-- grows out and fades over StarburstSeconds, then goes. Axis-aligned cells on the diagonals: a pixel-art star.
local function starburst(root: ScreenGui, info: RevealInfo, arms: number)
	local holder = Builder.frame({
		parent = root,
		name = "Starburst",
		position = UDim2.fromScale(0.5, RevealData.StageY),
		size = UDim2.fromScale(1, RevealData.StarburstLength * 2),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = Z_BEHIND,
	})
	local grow = Instance.new("UIScale")
	grow.Scale = 0.3
	grow.Parent = holder
	local colors: { [string]: Color3 } = Theme.Colors
	local first = accentColor(info)
	local secondName = RevealMath.Flags(info.tier).SecondRayColor
	local second = if secondName and colors[secondName] then colors[secondName] else first
	local count = RevealData.StarburstCells
	local tweenInfo = TweenInfo.new(RevealData.StarburstSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for arm = 1, arms do
		local angle = (arm - 1) / arms * math.pi * 2
		for k = 1, count do
			local share = k / count
			local radius = STARBURST_INNER + (0.5 - STARBURST_INNER) * (k - 1) / math.max(1, count - 1)
			local cell = Builder.frame({
				parent = holder,
				name = "Cell",
				color = if k == count then Theme.Colors.White elseif arm % 2 == 1 then first else second,
				position = UDim2.fromScale(0.5 + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius),
				size = UDim2.fromScale(STARBURST_CELL * (0.5 + 0.5 * share), STARBURST_CELL * (0.5 + 0.5 * share)),
				anchor = Vector2.new(0.5, 0.5),
				zIndex = Z_BEHIND,
			})
			TweenService:Create(cell, tweenInfo, { BackgroundTransparency = 1 }):Play()
		end
	end
	local out = TweenService:Create(grow, TweenInfo.new(RevealData.StarburstSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
	out.Completed:Once(function()
		holder:Destroy()
	end)
	out:Play()
end

-- The colour wash: the whole screen flashes the tier's colour up to `peak` see-through and fades. Takes no input.
local function colourWash(root: ScreenGui, color: Color3, peak: number)
	local wash = Builder.frame({
		parent = root,
		name = "Wash",
		color = color,
		transparency = 1,
		zIndex = Z_WASH,
	})
	local up = TweenService:Create(wash, TweenInfo.new(RevealData.WashPeakSeconds, Enum.EasingStyle.Linear), { BackgroundTransparency = peak })
	up.Completed:Once(function()
		local down = TweenService:Create(wash, TweenInfo.new(RevealData.WashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		down.Completed:Once(function()
			wash:Destroy()
		end)
		down:Play()
	end)
	up:Play()
end

-- The species name spelled in: a letter a step (SpellSecondsPerLetter), a cell in the tier's colour running ahead of the
-- letters across the centred line; then the whole name. A tap that settles the card shows it whole at once (finishSpell).
local function spellName(info: RevealInfo)
	local label, cursor = nameLabel, spellCursor
	if not label then
		return
	end
	finishSpell()
	local token = spellToken
	local letters = utf8.len(info.speciesName) or #info.speciesName
	local width = label.AbsoluteSize.X
	local share = if width > 0 then math.min(1, label.TextBounds.X / width) else 1 -- the whole name's share of its line
	local function placeCursor(done: number)
		if cursor then
			cursor.Position = UDim2.fromScale(0.5 - share / 2 + share * done, 0.5)
		end
	end
	label.MaxVisibleGraphemes = 0
	if cursor then
		cursor.BackgroundColor3 = accentColor(info)
		cursor.Visible = true
	end
	placeCursor(0)
	task.spawn(function()
		for shown = 1, letters do
			task.wait(RevealData.SpellSecondsPerLetter)
			if not open or spellToken ~= token then
				return
			end
			label.MaxVisibleGraphemes = shown
			placeCursor(shown / math.max(1, letters))
		end
		if spellToken == token then
			finishSpell()
		end
	end)
end

-- The hero beat, as the card lands: the pop (the size band's own when it is bigger), the alien's flourish (World.SpeciesFx, on
-- the viewport's model; the burst is drawn here in 2D, as particles do not render in a ViewportFrame), then the tier's rung:
-- sparkle bursts, the starburst, the colour wash, the gold frame and the name spelled in.
local function heroBeat(info: RevealInfo, panel: Frame, band: Sizes.Band)
	heroDone = true
	local rung = RevealMath.Ladder(info.tier)
	popCard(panel, math.max(band.revealPop, rung.Pop))
	local model = viewModel
	if model and speciesId ~= "" then
		SpeciesFx.Flourish(model, speciesId)
	end
	local root = gui
	if root then
		for burstIndex = 0, rung.SparkleBursts - 1 do
			afterShow(burstIndex * RevealData.SparkleGapSeconds, function()
				sparkleBurst(root, info, rung.Sparkles)
			end)
		end
		if rung.Starburst > 0 then
			starburst(root, info, rung.Starburst)
		end
		if rung.Wash < 1 then
			colourWash(root, accentColor(info), rung.Wash)
		end
	end
	if rung.GoldFrame then
		showGoldFrame(true)
	end
	if rung.SpellName then
		spellName(info)
	end
end

-- Beat 3: the card drops in, then the chance line, the chips and the buttons arrive in turn, then a tap closes.
local function revealOdds()
	local pill = oddsPill
	if pill and not pill.Visible and oddsLabel and oddsLabel.Text ~= "" then
		pill.Visible = true
		if not reducedNow then
			Builder.pop(pill, RevealData.PopScale)
		end
	end
end

local function revealChips()
	local stamp = stampLabel
	if stamp and chipStamp then
		stamp.Visible = true
		if not reducedNow then
			Builder.pop(stamp, STAMP_PEAK)
		end
	end
	local bonus = perfectLabel
	if bonus and chipPerfect then
		bonus.Visible = true
		if not reducedNow then
			Builder.pop(bonus)
		end
	end
	local ribbon = storageRibbon
	if ribbon and chipStorage then
		ribbon.Visible = true
		if not reducedNow then
			Builder.pop(ribbon, 1.15)
		end
	end
end

local function showButtons(animate: boolean)
	local holder = buttonsHolder
	if not holder then
		return
	end
	if placeButton then
		placeButton.Visible = placeHandler ~= nil and not chipStorage
	end
	holder.Visible = true
	if animate and not reducedNow then
		holder.Position = UDim2.fromScale(0, RevealData.ButtonSlideDistance)
		play(holder, RevealData.ButtonSlideSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromScale(0, 0) })
	else
		holder.Position = UDim2.fromScale(0, 0)
	end
end

-- The entrance is over: the stage is done, the footer says a tap closes.
local function finishCard()
	settled = true
	if stageFrame then
		stageFrame.Visible = false
	end
	if footerLabel then
		footerLabel.Visible = true
	end
end

-- The entrance's last state in one go: for Reduced Motion, and for a tap that cannot wait.
local function applyCardFinal()
	cancelRunning()
	finishSpell()
	-- A tap before the landing skips the hero beat's motion, never the tier's frame: the card stays as exclusive as its tier.
	local info = current
	if info and not heroDone then
		heroDone = true
		if RevealMath.Ladder(info.tier).GoldFrame then
			showGoldFrame(not reducedNow)
		end
	end
	local panel = card
	if panel then
		panel.Position = CARD_POSITION
		panel.Visible = true
		local scale = panel:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
	revealOdds()
	local stamp = stampLabel
	if stamp and chipStamp then
		stamp.Visible = true
		local scale = stamp:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
	if perfectLabel and chipPerfect then
		perfectLabel.Visible = true
	end
	if storageRibbon and chipStorage then
		storageRibbon.Visible = true
	end
	showButtons(false)
	finishCard()
end

local function beginCard()
	local info, root, panel = current, gui, card
	if not info or not root or not panel then
		return
	end
	seq += 1
	phase = "Card"
	settled = false
	lastActionAt = os.clock()
	cancelRunning()
	local flags = RevealMath.Flags(info.tier)
	-- The stage's pieces go; the word fades and the push-in eases back as the card drops.
	if eggHolder then
		eggHolder.Visible = false
	end
	if tapRing then
		tapRing.Visible = false
	end
	if promptLabel then
		promptLabel.Visible = false
	end
	if dotsHolder then
		dotsHolder.Visible = false
	end
	for _, piece in ipairs(shardPieces) do
		piece.Visible = false
	end
	local word = wordLabel
	if word and word.Visible then
		if reducedNow then
			word.Visible = false
		else
			local stroke = word:FindFirstChildOfClass("UIStroke")
			play(word, RevealData.WordFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { TextTransparency = 1 })
			if stroke then
				play(stroke, RevealData.WordFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
			end
			later(RevealData.WordFadeSeconds, function()
				word.Visible = false
			end)
		end
	end
	if not reducedNow then
		tweenGlow(1, RevealData.WordFadeSeconds)
	else
		setGlow(1)
	end
	if stageScale and stageScale.Scale ~= 1 then
		play(stageScale, RevealData.CardDropSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
	end
	ensureRays(info)
	if groundRing then
		groundRing.Visible = flags.GroundRing
	end
	-- The card.
	local scale = panel:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 1
	end
	panel.Visible = true
	local rung = RevealMath.Ladder(info.tier)
	if reducedNow then
		applyCardFinal() -- the gold frame at rest, no chase, for a tier that has one
		flyScrap(info.scrapGained)
		return
	end
	local band = Sizes.ById[info.size] or Sizes.ById[Sizes.Default]
	panel.Position = UDim2.fromScale(CARD_POSITION.X.Scale, CARD_POSITION.Y.Scale - RevealData.CardDropDistance)
	play(panel, RevealData.CardDropSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = CARD_POSITION })
	local landing = RevealData.CardDropSeconds
	later(landing, function()
		heroBeat(info, panel, band)
		flyScrap(info.scrapGained)
		if info.perfect == true then
			perfectFlash(root)
		end
	end)
	-- The top tiers hold the moment longer (their HoldExtra) before the buttons slide up.
	later(landing + RevealData.OddsDelaySeconds, revealOdds)
	later(landing + RevealData.ChipDelaySeconds, revealChips)
	later(landing + RevealData.ButtonDelaySeconds + rung.HoldExtra, function()
		showButtons(true)
	end)
	later(landing + RevealMath.HoldSeconds(info.tier), finishCard)
end

-- A tap while the entrance plays: land everything now, so the next tap can close.
local function settleCard()
	seq += 1
	lastActionAt = os.clock()
	applyCardFinal()
	local info = current
	if info then
		flyScrap(info.scrapGained)
	end
end

-- The shard pieces fly out from the egg and fade; a Grand tier's fly farther and are bigger.
local function flyShards(scale: number, color: Color3)
	local aspect = viewportAspect()
	local count = #shardPieces
	local seconds = RevealData.ShardSeconds * scale
	for index, piece in ipairs(shardPieces) do
		local angle = ((index - 1) / count) * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local distance = RevealData.ShardDistance * scale * rng:NextNumber(0.8, 1.2)
		piece.Size = UDim2.fromScale(1, RevealData.ShardHeight * scale)
		piece.Position = UDim2.fromScale(0.5, RevealData.StageY)
		piece.Rotation = rng:NextNumber(0, 360)
		Builder.setBlockColor(piece, color)
		Builder.setBlockFade(piece, 0)
		piece.Visible = true
		-- The shard is a flat block: its ink and face frames fade together.
		for _, part in ipairs(piece:GetChildren()) do
			if part:IsA("Frame") then
				play(part, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
			end
		end
		local spin = RevealData.ShardSpinDegrees * (if index % 2 == 0 then 1 else -1)
		play(piece, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * distance / aspect, RevealData.StageY + math.sin(angle) * distance),
			Rotation = piece.Rotation + spin,
		})
	end
end

-- Beat 2: the shell bursts, the word drops in, the tier's stinger plays, the rays spin up (or the iris opens), then the card.
local function beginShards()
	local info, root = current, gui
	if not info or not root then
		return
	end
	seq += 1
	phase = "Shards"
	lastActionAt = os.clock()
	cancelRunning()
	local flags = RevealMath.Flags(info.tier)
	local scale = RevealMath.ShardScale(info.tier)
	local shardSeconds = RevealData.ShardSeconds * scale
	local graceSeconds = RevealData.RaySpinSeconds * scale
	local tierColor = Builder.tierColor(info.tier)
	-- The shell is gone: the egg, its ring, the prompt and the dots go with the burst.
	if eggHolder then
		eggHolder.Visible = false
	end
	if tapRing then
		tapRing.Visible = false
	end
	if promptLabel then
		promptLabel.Visible = false
	end
	if dotsHolder then
		dotsHolder.Visible = false
	end
	if stageFrame then
		stageFrame.Visible = true
	end
	tintGlow(accentColor(info))
	-- The tier's stinger plays through the music director, which ducks the bed for its length (data/Music Ducking).
	MusicDirector.Stinger(if Sounds.Reveal[info.tier] ~= nil then "Reveal." .. info.tier else "Reveal.Common")
	-- The tier word: in the tier colour (or the tier's accent), dropping in big where the egg was.
	local word = wordLabel
	if word and flags.Word then
		word.Text = Builder.text("REVEAL_WORD_" .. info.tier)
		word.TextColor3 = accentColor(info)
		word.TextTransparency = 0
		word.Visible = true
		if reducedNow then
			word.Position = UDim2.fromScale(0.5, RevealData.StageY)
		else
			word.Position = UDim2.fromScale(0.5, RevealData.StageY - RevealData.CardDropDistance)
			play(word, RevealData.WordDropSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromScale(0.5, RevealData.StageY) })
		end
	end
	-- Cosmic and Secret: the pixel sky comes in with the burst (at rest at once under Reduced Motion).
	if RevealMath.Ladder(info.tier).Sky then
		showSky(info, not reducedNow)
	end
	if reducedNow then
		-- One still frame: the glow full, the word, the static rays or the open iris; no shards, no confetti, no push-in.
		setGlow(RevealData.GlowTransparencyEnd)
		ensureRays(info)
		later(RevealData.ReducedMotionSeconds, beginCard)
		return
	end
	-- The burst: shards fly (shell cream from an egg, the tier colour from a catch), the glow flashes, confetti for Epic and up,
	-- the stage pushes in, a Secret dims.
	flyShards(scale, if info.fromEgg == true then Theme.Colors.Panel else tierColor)
	setGlow(RevealData.GlowBurstTransparency)
	tweenGlow(RevealData.GlowTransparencyEnd, shardSeconds + graceSeconds)
	local confettiCount = RevealMath.ConfettiCount(info.tier)
	if confettiCount > 0 then
		confetti(root, tierColor, confettiCount)
	end
	local beat = RevealMath.ShardBeatSeconds(info.tier)
	if stageScale then
		play(stageScale, beat, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = RevealData.PushInScale })
	end
	if dimExtra and flags.DimExtra > 0 then
		play(dimExtra, beat, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 - flags.DimExtra })
	end
	-- After the shards the rays spin up (or the iris opens); a tier with neither goes straight on.
	if flags.Rays or flags.Iris then
		later(shardSeconds, function()
			if flags.Rays then
				showRayRing(info, graceSeconds, true)
			end
			if flags.Iris then
				showIris(graceSeconds, true)
			end
		end)
	end
	later(beat, beginCard)
end

-- Beat 1: one tap of the crack. The last tap hands over to the shards when its wobble ends.
local function crackTap()
	local info = current
	if not info or phase ~= "Crack" or tapsMade >= RevealData.CrackTaps then
		return
	end
	tapsMade += 1
	local tap = tapsMade
	Builder.playSound(Sounds.CrackTick)
	-- The dot fills with a pop.
	local dot = dotFrames[tap]
	if dot then
		Builder.setBlockColor(dot, Theme.Colors.Featured)
		Builder.setBlockFade(dot, 0)
		Builder.pop(dot, RevealData.PopScale + 0.2)
	end
	-- The crack line appears; the tier colour leaks a little more from behind the egg.
	local bars = crackBars[tap]
	if bars then
		for _, bar in ipairs(bars) do
			bar.Visible = true
		end
	end
	tweenGlow(RevealMath.GlowTransparency(tap), RevealData.CrackSecondsPerTap)
	-- The egg squeezes and wobbles harder with every tap: out to one side, back past the middle, home.
	local egg, pulse = eggHolder, eggPulse
	if egg and pulse then
		local degrees = RevealMath.WobbleDegrees(tap) * (if tap % 2 == 0 then -1 else 1)
		local quarter = RevealData.CrackSecondsPerTap / 4
		pulse.Scale = RevealData.TapPulseScale
		play(pulse, RevealData.CrackSecondsPerTap, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
		local swing = TweenService:Create(egg, TweenInfo.new(quarter, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Rotation = degrees })
		table.insert(running, swing)
		swing.Completed:Once(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed or phase ~= "Crack" then
				return
			end
			local back = TweenService:Create(egg, TweenInfo.new(quarter * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = -degrees * 0.5 })
			table.insert(running, back)
			back.Completed:Once(function(backState: Enum.PlaybackState)
				if backState == Enum.PlaybackState.Completed and phase == "Crack" then
					play(egg, quarter, Enum.EasingStyle.Sine, Enum.EasingDirection.In, { Rotation = 0 })
				end
			end)
			back:Play()
		end)
		swing:Play()
	end
	if tap >= RevealData.CrackTaps then
		later(RevealData.CrackSecondsPerTap, beginShards)
	end
end

-- Without a tap for AutoCrackSeconds the rest of the taps play themselves, one every CrackSecondsPerTap.
local function autoCrack()
	if autoRunning then
		return
	end
	autoRunning = true
	local mine = seq
	task.spawn(function()
		while open and seq == mine and phase == "Crack" and tapsMade < RevealData.CrackTaps do
			crackTap()
			task.wait(RevealData.CrackSecondsPerTap)
		end
		autoRunning = false
	end)
end

-- (Re)starts the idle timer: AutoCrackSeconds from now without a tap, the egg cracks itself.
local function scheduleAutoCrack()
	autoGen += 1
	local gen = autoGen
	later(RevealData.AutoCrackSeconds, function()
		if gen == autoGen and phase == "Crack" then
			autoCrack()
		end
	end)
end

-- Beat 1: the egg, its ring, the prompt and the dots appear; the tier colour waits behind the egg, almost clear.
local function beginCrack()
	local info = current
	if not info then
		return
	end
	seq += 1
	phase = "Crack"
	tapsMade = 0
	autoRunning = false
	lastActionAt = os.clock()
	cancelRunning()
	tintGlow(accentColor(info))
	setGlow(RevealMath.GlowTransparency(0))
	if stageFrame then
		stageFrame.Visible = true
	end
	if eggHolder then
		eggHolder.Visible = true
		eggHolder.Rotation = 0
	end
	if tapRing then
		tapRing.Visible = true
	end
	if tapRingScale then
		tapRingScale.Scale = 1
		local breathe = TweenService:Create(
			tapRingScale,
			TweenInfo.new(RevealData.TapRingPulseSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Scale = RevealData.TapRingPulse }
		)
		table.insert(running, breathe)
		breathe:Play()
	end
	if promptLabel then
		promptLabel.Visible = true
		Builder.pop(promptLabel, RevealData.PopScale)
	end
	if dotsHolder then
		dotsHolder.Visible = true
	end
	scheduleAutoCrack()
end

onBackdropTap = function(): string
	if phase == "Crack" then
		crackTap() -- ticks for itself (the idle timer's taps tick too)
		if tapsMade < RevealData.CrackTaps then
			scheduleAutoCrack()
		end
		return ""
	elseif phase == "Shards" then
		if RevealData.Skip and os.clock() - lastActionAt >= RevealData.SkipGuardSeconds then
			beginCard()
			return Sounds.Click
		end
		return ""
	elseif phase == "Card" then
		if os.clock() - lastActionAt < RevealData.SkipGuardSeconds then
			return ""
		end
		if settled then
			close()
		else
			settleCard()
		end
		return Sounds.Click
	end
	close()
	return Sounds.Click
end

onKeepGoing = function()
	close()
end

onPlaceIt = function()
	local handler = placeHandler
	close()
	if handler then
		handler()
	end
end

-- Public API -------------------------------------------------------------

function Reveal.IsOpen(): boolean
	return open
end

-- Wires "Place it": the bootstrap says what opening the newcomer's place means (the Aliens screen). Without a handler the
-- button stays hidden, so no tap is ever silent.
function Reveal.OnPlace(handler: (() -> ())?)
	placeHandler = handler
end

function Reveal.Show(info: RevealInfo, onClosed: (() -> ())?)
	-- The card is a quiet moment and it starts here, before build() or anything else can take a frame: `open` first (the
	-- toast queue's probe reads it, so the drain Hush starts finds the moment already quiet and draws nothing), then
	-- whatever is on screen goes back in the queue and replays after the close.
	open = true
	Toast.Hush()
	build()
	local root = gui
	local panel = card
	if not root or not panel then
		open = false
		return
	end
	onClose = onClosed
	-- A Show over a Show starts the sequence again from nothing.
	seq += 1
	showGen += 1
	heroDone = false
	cancelRunning()
	stopBurstLoop()
	stopRays()
	current = info
	reducedNow = Prefs.ReducedMotion()
	local withCrack = RevealMath.PlansCrack(info.fromEgg == true)
	-- Toasts and banners wait for the whole sequence and a calm after it (the probe holds them while the Reveal is open anyway).
	Toast.QuietFor(RevealMath.QuietTotal(info.tier, withCrack, reducedNow))

	local tierColor = Builder.tierColor(info.tier)
	local band = Sizes.ById[info.size] or Sizes.ById[Sizes.Default]

	Builder.setBlockInk(panel, tierColor) -- the rarity ring is the card's ink
	if shapeBox then
		Builder.setBlockColor(shapeBox, info.color)
	end
	if shapeLabel then
		shapeLabel.Text = Builder.text("SHAPE_" .. info.shape)
	end
	local def = speciesFor(info)
	speciesId = if def then def.id else ""
	spinScale = RevealMath.Ladder(info.tier).TurnScale -- the top tiers turn slower, grander
	showModel(def)
	if nameLabel then
		nameLabel.Text = info.speciesName
	end
	if tierLabel then
		tierLabel.Text = Builder.text("TIER_" .. info.tier)
		tierLabel.TextColor3 = tierColor
	end
	-- The rarity badge (key = the tier) beside the tier text, rebuilt per reveal; showStamp seats it.
	if tierBadge then
		tierBadge:Destroy()
		tierBadge = nil
	end
	tierBadge = Builder.blockIcon({
		parent = panel,
		name = "TierBadge",
		key = info.tier,
		size = UDim2.fromScale(TIER_H / CARD_ASPECT, TIER_H),
		anchor = Vector2.new(1, 0.5),
		zIndex = CARD_TOP + 1,
	})
	showStamp(info, band)
	if overlayBadge and overlayLabel then
		overlayBadge.Visible = info.overlay ~= "None"
		Builder.setBlockColor(overlayBadge, Builder.overlayColor(info.overlay))
		overlayLabel.Text = Builder.text("OVERLAY_" .. info.overlay)
		if stopOverlayShine then
			stopOverlayShine()
			stopOverlayShine = nil
		end
		if info.overlay ~= "None" and Builder.overlayTint(info.overlay) then
			stopOverlayShine = Builder.shine(overlayBadge) -- the slow sparkle of a tinted overlay (Launch Gold)
		end
	end
	if newRibbon then
		newRibbon.Visible = info.isNew
	end
	-- The chance line: the server's percent for a grant, the tier's spawn share for a wild catch, nothing where the client has neither.
	local percent = info.chancePercent
	if percent == nil and info.fromEgg ~= true then
		percent = RevealMath.SpawnPercent(info.tier)
	end
	if oddsLabel then
		oddsLabel.Text = RevealMath.OddsLine(percent) or ""
	end
	if oddsPill then
		Builder.setBlockInk(oddsPill, tierColor)
	end
	local overflow = info.overflowScrap
	storageHint = overflow ~= nil
	chipStorage = overflow ~= nil
	chipPerfect = info.perfect == true
	if storageLabel and overflow ~= nil then
		storageLabel.Text = Strings.REVEAL_STORAGE_FULL:format(Builder.formatNumber(overflow))
	end
	if perfectLabel and chipPerfect then
		perfectLabel.Text = Strings.CATCH_PERFECT_BONUS:format(Config.PerfectScrapMultiplier)
	end
	scrapGen += 1
	scrapStarted = false
	if scrapLabel then
		scrapLabel.Visible = false
	end
	resetStage()
	local panelScale = panel:FindFirstChildOfClass("UIScale")
	if panelScale then
		panelScale.Scale = 1
	end
	phase = "Idle"
	settled = false
	root.Enabled = true
	if reducedNow or not withCrack then
		beginShards()
	else
		beginCrack()
	end
end

function Reveal.Close()
	close()
end

return Reveal
