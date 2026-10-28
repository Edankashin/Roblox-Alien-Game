--!strict
-- StarterPlayerScripts.Client.UI.ArrivalTitle: the title card of an arrival (UI richness pass, package B,
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 6; reference zpl-avd/arrive.jpg "VOID ABYSS / NOW ARRIVING"). One ScreenGui at
-- DisplayOrder 55 (over the launch fade at 50), built once: the destination's name screen-wide in Reveal size, white and outlined
-- (it shrinks to fit 0.8 of the width on one line, never wraps), a flat bar in the world's colour under it, "NOW ARRIVING" in
-- outlined yellow under that, and behind them 12 speed lines (flat white blocks, axis-aligned, no rotation) that streak inward from
-- both edges over the first 1.2 seconds. The name grows from 1.15 to 1.0 as the card fades in (0.25 s), holds, and fades out
-- (0.35 s); Toast.QuietFor holds the notification budget still for the whole card. Under Reduced Motion there are no lines and no
-- scale: a plain fade in, a hold and a fade out (Shared/ArrivalTitleMath.Timeline). Every number is data/Cinematics.Title.
-- Play(worldId, delaySeconds, onDone) starts the card (a first visit asks for it Title.AtSeconds into the Arrival moment, a later
-- arrival at once); it answers false while one is already showing. Presentation only: it decides nothing.

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local ArrivalTitleMath = require(Shared:WaitForChild("ArrivalTitleMath"))
local Cinematics = require(Shared:WaitForChild("data"):WaitForChild("Cinematics"))
local WorldCards = require(Shared:WaitForChild("data"):WaitForChild("WorldCards"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local WorldCard = require(script.Parent.WorldCard)
local Prefs = require(script.Parent.Parent.Prefs)

local ArrivalTitle = {}

local Title = Cinematics.Title

local gui: ScreenGui? = nil
local group: CanvasGroup? = nil -- the name, the bar and "NOW ARRIVING", faded together
local nameLabel: TextLabel? = nil
local nameScale: UIScale? = nil
local bar: Frame? = nil
local nowLabel: TextLabel? = nil
local lineFrames: { Frame } = {}
local playing = false
local token = 0 -- each Play takes a number, so a stale callback never touches a newer card
local tweens: { Tween } = {}

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("ArrivalTitle", Title.DisplayOrder)
	root.Enabled = false
	gui = root

	-- The speed lines sit behind the card: flat white blocks, a cell tall (Title.CellShare of the screen's height).
	for index = 1, Title.Lines.Count do
		local line = Builder.frame({ parent = root, name = "Line" .. index, color = Theme.Colors.White, zIndex = 1 })
		line.Visible = false
		lineFrames[index] = line
	end

	local card = Instance.new("CanvasGroup")
	card.Name = "Card"
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Size = UDim2.fromScale(1, 1)
	card.GroupTransparency = 1
	card.ZIndex = 2
	card.Parent = root
	group = card

	local name = Builder.label({
		parent = card,
		name = "Name",
		text = "",
		textSize = Title.NameSize,
		position = UDim2.fromScale(0.5, Title.NameY),
		size = UDim2.fromScale(Title.NameWidthShare, 0.16),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	name.TextScaled = false -- the size is set to fit (ArrivalTitleMath.NameSize), never wrapped
	name.TextWrapped = false
	name.TextSize = Title.NameSize
	local scale = Instance.new("UIScale")
	scale.Parent = name
	nameLabel = name
	nameScale = scale

	local stripe = Builder.blockPlate({
		parent = card,
		name = "Bar",
		color = Theme.Colors.Featured,
		cells = false,
		rows = Title.BarCells,
		position = UDim2.fromScale(0.5, Title.BarY),
		size = UDim2.fromScale(Title.BarWidthShare, Title.BarCells * Title.CellShare),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	bar = stripe

	nowLabel = Builder.label({
		parent = card,
		name = "Now",
		text = Strings.ARRIVAL_NOW,
		textSize = Title.NowSize,
		color = Theme.Colors.Heading,
		position = UDim2.fromScale(0.5, Title.NowY),
		size = UDim2.fromScale(0.6, 0.08),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
end

-- The width in px the name takes at `size` on one line.
local function textPx(text: string, size: number): number
	local ok, width = pcall(function(): number
		return TextService:GetTextSize(text, size, Theme.Font, Vector2.new(10000, 10000)).X
	end)
	return if ok then width else #text * size * 0.55
end

local function tween(target: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local made = TweenService:Create(target, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	table.insert(tweens, made)
	made:Play()
	return made
end

local function cancelTweens()
	for _, made in ipairs(tweens) do
		made:Cancel()
	end
	table.clear(tweens)
end

-- Streaks the speed lines in: each line's inner end starts on its screen edge and slides inward by its travel while it fades.
local function runLines(mine: number, root: ScreenGui, color: Color3)
	local height = Title.Lines.HeightCells * Title.CellShare
	local aspect = if root.AbsoluteSize.Y > 0 then root.AbsoluteSize.X / root.AbsoluteSize.Y else 16 / 9
	for index, spec in ipairs(ArrivalTitleMath.Lines()) do
		local frame = lineFrames[index]
		if not frame then
			break
		end
		local width = spec.cells * Title.CellShare / aspect -- a cell is square: its share of the width is its share of the height over the aspect
		local fromX = if spec.side < 0 then 0 else 1
		local toX = if spec.side < 0 then spec.travel else 1 - spec.travel
		frame.AnchorPoint = Vector2.new(if spec.side < 0 then 1 else 0, 0.5)
		frame.Size = UDim2.fromScale(width, height)
		frame.Position = UDim2.fromScale(fromX, spec.row)
		frame.BackgroundColor3 = if index % 3 == 0 then color else Theme.Colors.White -- one in three takes the world's colour
		frame.BackgroundTransparency = Title.Lines.StartTransparency
		task.delay(spec.delay, function()
			if token ~= mine then
				return
			end
			frame.Visible = true
			tween(frame, spec.seconds, { Position = UDim2.fromScale(toX, spec.row) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tween(frame, spec.seconds, { BackgroundTransparency = 1 }, Enum.EasingStyle.Linear)
			task.delay(spec.seconds, function()
				if token == mine then
					frame.Visible = false
				end
			end)
		end)
	end
end

local function finish(mine: number, onDone: (() -> ())?)
	if token ~= mine then
		return
	end
	playing = false
	local root = gui
	if root then
		root.Enabled = false
	end
	for _, frame in ipairs(lineFrames) do
		frame.Visible = false
	end
	if onDone then
		onDone()
	end
end

-- Public API -------------------------------------------------------------

function ArrivalTitle.IsPlaying(): boolean
	return playing
end

-- Plays the card for `worldId` after `delaySeconds` (0 or nil: now), then runs `onDone`. Answers false, with nothing changed, while
-- a card is already showing.
function ArrivalTitle.Play(worldId: number, delaySeconds: number?, onDone: (() -> ())?): boolean
	if playing then
		return false
	end
	build()
	local root, card, name, scale, stripe, now = gui, group, nameLabel, nameScale, bar, nowLabel
	if not root or not card or not name or not scale or not stripe or not now then
		return false
	end
	playing = true
	token += 1
	local mine = token
	cancelTweens()
	local reduced = Prefs.ReducedMotion()
	local timeline = ArrivalTitleMath.Timeline(reduced)
	local def = WorldCards.Cards[worldId] or WorldCards.Cards[1]
	local color = Theme.Hex(def.color)
	local text = WorldCard.WorldName(worldId)
	name.Text = text
	local viewport = root.AbsoluteSize
	local limit = Title.NameWidthShare * (if viewport.X > 0 then viewport.X else 1)
	name.TextSize = ArrivalTitleMath.NameSize(textPx(text, Title.NameSize), limit, Title.NameSize, Theme.TextSize.Min)
	Builder.setBlockColor(stripe, color)
	scale.Scale = if timeline.scale then Title.ScaleFrom else 1
	card.GroupTransparency = 1
	for _, frame in ipairs(lineFrames) do
		frame.Visible = false
	end

	task.spawn(function()
		if delaySeconds and delaySeconds > 0 then
			task.wait(delaySeconds)
		end
		if token ~= mine then
			return
		end
		Toast.QuietFor(timeline.total) -- no new banner or toast starts while the card shows
		root.Enabled = true
		tween(card, timeline.inSeconds, { GroupTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if timeline.scale then
			tween(scale, timeline.inSeconds, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
		if timeline.lines then
			runLines(mine, root, color)
		end
		task.wait(timeline.inSeconds + timeline.holdSeconds)
		if token ~= mine then
			return
		end
		tween(card, timeline.outSeconds, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(timeline.outSeconds)
		finish(mine, onDone)
	end)
	return true
end

-- A first visit: the Arrival moment is playing, so the card starts Title.AtSeconds into it (the end of its open shot), over the low
-- fast "Fly" shot, and is gone before the rise.
function ArrivalTitle.PlayFirstVisit(worldId: number): boolean
	return ArrivalTitle.Play(worldId, Title.AtSeconds, nil)
end

-- Whether this join is a later arrival that takes a card: the join came from another place of this game (the join data's
-- SourcePlaceId: a flight), so a rejoin or a website join never says "now arriving". The caller (the bootstrap, with no cinematic
-- playing) hides the HUD, calls Play(worldId, 0, onDone) and gives the HUD back in onDone.
function ArrivalTitle.Flown(): boolean
	local ok, source = pcall(function(): number?
		return Players.LocalPlayer:GetJoinData().SourcePlaceId
	end)
	return ok and ArrivalTitleMath.PlaysOnLaterArrival(source)
end

return ArrivalTitle
