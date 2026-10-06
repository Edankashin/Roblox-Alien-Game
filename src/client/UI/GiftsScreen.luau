--!strict
-- StarterPlayerScripts.Client.UI.GiftsScreen: the Gifts & Spin panel. Left half: Welcome Week, a
-- 7-tile gift calendar (one tile per data/Gifts row: the day, the reward and its state: a Claim button
-- when the day is reached, a Claimed chip once taken, a locked line otherwise). Right half: the spin
-- wheel, a ring of segment labels (name and odds, so the odds are always visible) around a hub with
-- the Spin button, a pointer at the top, the spin balance and an odds line under it. Every value shown
-- is read from the gift state mirrored in State (GiftsChanged) and the shared data tables; every tap
-- asks the server (ClaimGift, Spin) and a refusal becomes a toast. Nothing here decides an outcome:
-- the server rolls the segment and the client only turns the wheel to the index it is told, and an
-- egg comes back as a GrantResult the bootstrap turns into a Reveal. A "Tomorrow" line names the next
-- gift. A third column holds the social asks: join the team's group (the native prompt, then the
-- server checks membership and pays) and invite friends (the native invite sheet); the server owns
-- who is a member and what a referral pays, this only prompts, asks and shows the answer.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Gifts = require(Shared:WaitForChild("data"):WaitForChild("Gifts"))
local Spins = require(Shared:WaitForChild("data"):WaitForChild("Spins"))
local Social = require(Shared:WaitForChild("data"):WaitForChild("Social"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local GiftsScreen = {}

type Reward = { kind: string, id: string?, amount: number?, tier: string? }
type GiftRow = { day: number, label: string, reward: Reward }
type Segment = { id: string, label: string, odds: number, reward: Reward }

-- The server's answer to GetSocial and the body of the SocialChanged push.
export type SocialSnapshot = {
	groupId: number,
	inGroup: boolean,
	groupClaimed: boolean,
	referralsRewarded: number,
	referredBy: number,
}

-- The rows carry rewards of different shapes, so the data tables are read through a loose type.
local giftRows: { GiftRow } = (Gifts :: any)
local segments: { Segment } = (Spins.Segments :: any)

-- One gift tile. Children are built once and refreshed in place.
type Tile = {
	card: Frame,
	dayChip: Frame,
	dayLabel: TextLabel,
	reward: TextLabel,
	claim: Frame,
	claimed: Frame,
	locked: TextLabel,
	icon: ImageLabel?, -- the reward's icon, rebuilt by refreshTile (absent while its image is not uploaded)
}

-- One wheel segment: a block of name and odds labels that orbits the hub and is kept upright.
type Wedge = { block: Frame, name: TextLabel, odds: TextLabel }

-- Panel layout, as fractions of the panel. The panel is wide (PANEL_ASPECT) so three columns sit side by
-- side on a phone: Welcome Week, the wheel and the social column. The header tab straddles the top edge
-- and the close button reaches down to 0.155, so every column starts under it.
local PANEL_ASPECT = 1.8
local BODY_Y = 0.16
local HEADING_H = 0.065
local COL_GAP = Theme.Margin
local LEFT_X = Theme.Margin
local LEFT_W = 0.34
local MID_X = LEFT_X + LEFT_W + COL_GAP
local MID_W = 0.32
local SOCIAL_X = MID_X + MID_W + COL_GAP
local SOCIAL_W = 1 - Theme.Margin - SOCIAL_X
local DAYS_Y = 0.225
local DAYS_H = 0.045
local NEXT_Y = 0.272 -- the Tomorrow line, under Days played
local NEXT_H = 0.068
local GRID_Y = 0.345
local GRID_COLS = 3 -- 3 + 3 + 1: Day 7 ends the last row alone and the hint fills the two free cells beside it
local GRID_ROWS = 3
local GRID_H = LEFT_W * PANEL_ASPECT * GRID_ROWS / GRID_COLS -- square cells at any panel size
local TILE_INSET = 0.92 -- the card inside its grid slot; the rest is the gap
-- The reward's icon on a tile (the card is square): a quarter of the card's width, tucked into the top-right corner.
local TILE_ICON_W = 0.25
local TILE_ICON_INSET = 0.03
local WHEEL_Y = 0.235
local WHEEL_H = 0.5
local LINES_Y = 0.75
local LINES_H = 0.045
local ODDS_Y = 0.81
local ODDS_H = 1 - Theme.Margin - ODDS_Y
-- The social column: the group block (button over the line saying what it pays), then the invite block.
-- With no group (Social.GroupId == 0) the invite block takes the top slot.
local SOCIAL_Y = 0.17
local SOCIAL_BUTTON_H = 0.1
local SOCIAL_LINE_GAP = 0.01
local GROUP_LINE_H = 0.19
local INVITE_LINE_H = 0.3
local SOCIAL_BLOCK_GAP = 0.04

-- Wheel geometry, as fractions of the wheel square (the ring reads at any size).
local LABEL_RADIUS = 0.34 -- where each segment block sits
local LABEL_W = 0.28
local LABEL_H = 0.17
local NAME_SHARE = 0.6 -- of the block height; the odds take the rest
local DIVIDER_W = 0.012
local HUB_SIZE = 0.38
local POINTER_SIZE = 0.09
local SPIN_MIN_TURNS = 3 -- full turns before the wheel settles on the server's segment
local SPIN_MAX_TURNS = 4
local SPIN_SECONDS = 3.2

local gui: ScreenGui? = nil
local panel: Frame? = nil
local daysLabel: TextLabel? = nil
local tiles: { Tile } = {}
local wheel: Frame? = nil
local wedges: { Wedge } = {}
local spinButton: Frame? = nil
local freeLabel: TextLabel? = nil
local bankedLabel: TextLabel? = nil
local nextLabel: TextLabel? = nil -- the Tomorrow line
local groupButton: Frame? = nil -- absent while Social.GroupId is 0
local social: SocialSnapshot? = nil -- the server's last word on the group gift (GetSocial, SocialChanged)
local socialSeq = 0 -- bumped by every fetch and push so a slow answer never overwrites a newer one
local groupPending = false -- one group request in flight at a time: the prompt, the claim and the re-fetch
local invitePending = false
local open = false
local pending = false -- one server request in flight at a time
local spinning = false -- the wheel is turning; the Spin button stays grey until it settles
local claimedLocal: { [string]: boolean } = {} -- days the server confirmed, until the next GiftsChanged
local onGrant: ((Types.GrantResult) -> ())? = nil
local rng = Random.new()

-- Helpers ----------------------------------------------------------------

-- Recolours a Builder.button in place (lip, face, thick stroke, gradient).
local function recolorButton(container: Frame, color: Color3)
	local dark = Builder.darker(color)
	local lip = container:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = dark
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.BackgroundColor3 = color
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.Thickness == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

-- Recolours a pill chip in place (fill and gradient).
local function recolorChip(chip: Frame, color: Color3)
	chip.BackgroundColor3 = color
	local gradient = chip:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(color), color)
	end
end

-- Sets the label of a Builder.button (its "Face" child).
local function setButtonText(container: Frame, text: string)
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = text
	end
end

-- A lure's or power-up's name from its id key (LURE_Lure1, POWERUP_SpeedBurst); nil for other kinds.
local function itemName(kind: string, id: string?): string?
	if kind == "lure" and id then
		return Builder.text("LURE_" .. id)
	elseif kind == "powerUp" and id then
		return Builder.text("POWERUP_" .. id)
	end
	return nil
end

-- The reward's name: lures and power-ups by their id keys, everything else by the row's label with
-- the spaces removed (GIFT_LABEL_WelcomePack), falling back to the raw label if no key exists.
local function rewardLabel(row: GiftRow): string
	local reward = row.reward
	local name = itemName(reward.kind, reward.id)
	if name then
		return name
	end
	local key = "GIFT_LABEL_" .. row.label:gsub("%s+", "")
	local text = Builder.text(key)
	return if text == key then row.label else text
end

-- One social reward through the existing REWARD_ templates ("500 Scrap", "3 x Twig Lure", "2 free spin");
-- a power-up reads like a lure, count then name.
local function socialRewardText(reward: Social.Reward): string
	if reward.kind == "scrap" then
		return Strings.REWARD_scrap:format(Builder.formatNumber(reward.amount))
	elseif reward.kind == "spin" then
		return Strings.REWARD_spin:format(reward.amount)
	end
	return Strings.REWARD_lure:format(reward.amount, itemName(reward.kind, reward.id) or (reward.id or ""))
end

-- A whole reward list, joined with the translated separator.
local function rewardListText(rewards: { Social.Reward }): string
	local parts: { string } = {}
	for _, reward in ipairs(rewards) do
		table.insert(parts, socialRewardText(reward))
	end
	return table.concat(parts, Strings.SOCIAL_REWARD_SEPARATOR)
end

-- The icon key for a gift reward: Scrap, a lure or power-up by its id, an egg by its tier's rarity badge.
-- A spin has no icon.
local function rewardIconKey(reward: Reward): string?
	if reward.kind == "scrap" then
		return "Scrap"
	elseif reward.kind == "lure" or reward.kind == "powerUp" then
		return reward.id
	elseif reward.kind == "egg" then
		return reward.tier
	end
	return nil
end

-- The tile's accent: an egg takes its tier colour (Day 7's Epic egg reads Epic), the rest gold.
local function giftAccent(row: GiftRow): Color3
	if row.reward.kind == "egg" then
		return Builder.tierColor(row.reward.tier or "Common")
	end
	return Theme.Colors.Featured
end

local function segmentName(id: string): string
	return Builder.text("SEGMENT_" .. id)
end

-- Segment `index` sits at this angle, clockwise from the pointer at the top, in the wheel's own frame.
local function segmentAngle(index: number): number
	return (index - 1) * (360 / math.max(1, #segments))
end

-- A point on the wheel square at `radius` (fraction of the square) along `angle` clockwise from the top.
local function ringPosition(angle: number, radius: number): UDim2
	local rad = math.rad(angle)
	return UDim2.fromScale(0.5 + radius * math.sin(rad), 0.5 - radius * math.cos(rad))
end

-- The labels orbit with the wheel but counter-rotate so they stay upright and readable.
local function setLabelsUpright(wheelRotation: number)
	for _, wedge in ipairs(wedges) do
		wedge.block.Rotation = -wheelRotation
	end
end

-- Refresh ----------------------------------------------------------------------

local function setTileStyle(tile: Tile, cardColor: Color3, accent: Color3)
	tile.card.BackgroundColor3 = cardColor
	local stroke = tile.card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = accent
	end
	recolorChip(tile.dayChip, accent)
end

local function refreshTile(tile: Tile, row: GiftRow, gifts: Types.GiftState)
	local key = tostring(row.day)
	local isClaimed = gifts.claimed[key] == true or claimedLocal[key] == true
	local unlocked = row.day <= gifts.daysPlayed
	local accent = giftAccent(row)
	tile.dayLabel.Text = Strings.GIFTS_DAY:format(row.day)
	tile.reward.Text = rewardLabel(row)
	tile.claim.Visible = unlocked and not isClaimed
	tile.claimed.Visible = isClaimed
	tile.locked.Visible = not unlocked and not isClaimed
	-- The corner icon is rebuilt on every refresh, so a re-render never stacks a second one.
	local previousIcon = tile.icon
	if previousIcon then
		previousIcon:Destroy()
		tile.icon = nil
	end
	local iconKey = rewardIconKey(row.reward)
	if iconKey then
		tile.icon = Builder.icon({
			parent = tile.card,
			name = "RewardIcon",
			key = iconKey,
			position = UDim2.fromScale(1 - TILE_ICON_INSET, TILE_ICON_INSET),
			size = UDim2.fromScale(TILE_ICON_W, TILE_ICON_W),
			anchor = Vector2.new(1, 0),
			zIndex = 6,
		})
	end
	local dimmed = Builder.lighter(Theme.Rarity.Common, 0.6)
	if isClaimed then
		setTileStyle(tile, dimmed, Theme.Rarity.Common)
	elseif unlocked then
		setTileStyle(tile, Theme.Colors.White, accent)
	else
		-- Locked: grey, except an egg keeps its tier colour so the week's prize stays in view.
		setTileStyle(tile, dimmed, if row.reward.kind == "egg" then accent else Theme.Rarity.Common)
	end
end

-- The spin balance and the button colour: green only with a spin to spend and nothing in flight.
local function refreshSpin()
	local gifts = State.GetGifts()
	if freeLabel then
		freeLabel.Text = Strings.SPIN_FREE:format(gifts.freeSpins)
	end
	if bankedLabel then
		bankedLabel.Text = Strings.SPIN_BANKED:format(gifts.bankedSpins)
	end
	local button = spinButton
	if button then
		local canSpin = gifts.freeSpins + gifts.bankedSpins > 0 and not spinning and not pending
		recolorButton(button, if canSpin then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
end

-- The Tomorrow line: the first gift whose day is still ahead, or the all-claimed line. Hidden when every
-- day is reached but some gifts still wait (there is no tomorrow to name and the week is not done).
local function refreshNext(gifts: Types.GiftState)
	local label = nextLabel
	if not label then
		return
	end
	local upcoming: GiftRow? = nil
	local allClaimed = true
	for _, row in ipairs(giftRows) do
		local key = tostring(row.day)
		if gifts.claimed[key] ~= true and claimedLocal[key] ~= true then
			allClaimed = false
		end
		if upcoming == nil and row.day > gifts.daysPlayed then
			upcoming = row
		end
	end
	if upcoming then
		label.Text = Strings.GIFTS_NEXT:format(rewardLabel(upcoming))
		label.Visible = true
	elseif allClaimed then
		label.Text = Strings.GIFTS_NEXT_DONE
		label.Visible = true
	else
		label.Visible = false
	end
end

-- The group button's state from the server's snapshot: Join, then Claim once a member, then a dimmed
-- Claimed. It greys while a request is in flight.
local function refreshSocial()
	local button = groupButton
	if not button then
		return
	end
	local snap = social
	local text: string
	local color: Color3
	if snap and snap.groupClaimed then
		text, color = Strings.SOCIAL_GROUP_CLAIMED, Theme.Rarity.Common
	elseif snap and snap.inGroup then
		text, color = Strings.SOCIAL_GROUP_CLAIM, Theme.Colors.Confirm
	else
		text, color = Strings.SOCIAL_GROUP_JOIN, Theme.Colors.Select
	end
	if groupPending then
		color = Theme.Rarity.Common
	end
	setButtonText(button, text)
	recolorButton(button, color)
end

local function refresh()
	if not open then
		return
	end
	local gifts = State.GetGifts()
	if daysLabel then
		daysLabel.Text = Strings.GIFTS_DAYS_PLAYED:format(gifts.daysPlayed)
	end
	for index, tile in ipairs(tiles) do
		local row = giftRows[index]
		if row then
			refreshTile(tile, row, gifts)
		end
	end
	refreshNext(gifts)
	refreshSpin()
	refreshSocial()
end

-- Server calls -------------------------------------------------------------

local function handleClaimRefusal(reason: any)
	if reason == "Locked" then
		Toast.Show(Strings.GIFTS_LOCKED, Theme.Rarity.Common)
	elseif reason == "AlreadyClaimed" then
		-- The server's GiftsChanged carries the truth; the redraw below picks it up.
		return
	else
		print(("[%s] ClaimGift refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server for the gift of `row`. Runs in its own thread: callers are taps. The server pushes
-- GiftsChanged (and Scrap or inventory) itself; this toasts the answer and hands an egg's GrantResult on.
local function claim(row: GiftRow)
	if pending then
		return
	end
	pending = true
	refreshSpin()
	task.spawn(function()
		local ok, reason, raw = Net.func("ClaimGift"):InvokeServer(row.day)
		pending = false
		if ok == true then
			claimedLocal[tostring(row.day)] = true
			Builder.playSound(Sounds.GiftClaim)
			Toast.Show(Strings.TOAST_GIFT_CLAIMED:format(row.day, rewardLabel(row)), giftAccent(row))
			refresh()
			local grant = raw :: Types.GrantResult?
			local callback = onGrant
			if grant and callback then
				callback(grant)
			end
		else
			handleClaimRefusal(reason)
			refresh()
		end
	end)
end

-- Turns the wheel SPIN_MIN_TURNS..SPIN_MAX_TURNS full turns plus whatever brings segment `index`
-- under the pointer, Quart Out, keeping the labels upright on the way, then calls onDone.
local function spinTo(index: number, onDone: () -> ())
	local disc = wheel
	if not disc then
		onDone()
		return
	end
	local start = disc.Rotation % 360
	local target = -segmentAngle(index) -- rotating the wheel by -angle puts that segment at the top
	local delta = (target - start) % 360
	local turns = rng:NextInteger(SPIN_MIN_TURNS, SPIN_MAX_TURNS)
	local final = start + delta + turns * 360
	disc.Rotation = start
	setLabelsUpright(start)
	-- The dividers sit half a wedge either side of each segment's centre, so the pointer crosses one
	-- whenever floor((rotation + step / 2) / step) changes; each crossing is a tick.
	local step = 360 / math.max(1, #segments)
	local lastWedge = math.floor((start + step / 2) / step)
	local upright = RunService.RenderStepped:Connect(function()
		local rotation = disc.Rotation
		setLabelsUpright(rotation)
		local wedge = math.floor((rotation + step / 2) / step)
		if wedge ~= lastWedge then
			lastWedge = wedge
			Builder.playSound(Sounds.WheelTick)
		end
	end)
	local info = TweenInfo.new(SPIN_SECONDS, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(disc, info, { Rotation = final })
	tween.Completed:Once(function()
		upright:Disconnect()
		disc.Rotation = final % 360
		setLabelsUpright(disc.Rotation)
		Builder.playSound(Sounds.WheelStop)
		onDone()
	end)
	tween:Play()
end

local function handleSpinRefusal(reason: any)
	if reason == "NoSpins" then
		Toast.Show(Strings.SPIN_NONE, Theme.Rarity.Common)
	else
		print(("[%s] Spin refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server for a spin. The server rolls, spends the spin and grants the reward; the client only
-- lands the wheel on the index it is told, then says what was won.
local function spin()
	if pending or spinning then
		return
	end
	pending = true
	refreshSpin()
	task.spawn(function()
		local ok, reason, raw = Net.func("Spin"):InvokeServer()
		pending = false
		local result = raw :: Types.SpinResult?
		if ok == true and result then
			spinning = true
			refreshSpin()
			spinTo(result.index, function()
				spinning = false
				local wedge = wedges[result.index]
				if wedge then
					Builder.pop(wedge.block, 1.3)
				end
				Toast.Show(Strings.SPIN_WON:format(segmentName(result.segmentId)), Theme.Colors.Featured)
				refreshSpin()
			end)
		else
			if ok ~= true then
				handleSpinRefusal(reason)
			end
			refreshSpin()
		end
	end)
end

-- Social ------------------------------------------------------------------

-- Asks the server where the player stands with the group gift and redraws. Yields: callers run it in a task.
local function fetchSocial()
	socialSeq += 1
	local seq = socialSeq
	local ok, raw = pcall(function()
		return Net.func("GetSocial"):InvokeServer()
	end)
	if not ok or seq ~= socialSeq or type(raw) ~= "table" then
		return
	end
	social = raw :: SocialSnapshot
	refreshSocial()
end

-- The native join prompt for the team's group: client-only, yields until the player answers. Whatever the
-- answer, the server is asked again afterwards because it alone says who is a member.
local function promptJoin()
	local ok, err = pcall(function()
		return GroupService:PromptJoinAsync(Social.GroupId)
	end)
	if not ok then
		print(("[%s] PromptJoinAsync failed: %s"):format(Config.WorkingTitle, tostring(err)))
	end
end

-- Asks the server to pay the group gift and toasts the answer; the server pushes Scrap, inventory and spins.
local function claimGroup()
	local called, ok, reason = pcall(function()
		return Net.func("ClaimGroupReward"):InvokeServer()
	end)
	if called and ok == true then
		Builder.playSound(Sounds.GiftClaim)
		Toast.Show(Strings.TOAST_GROUP_CLAIMED:format(rewardListText(Social.GroupReward)), Theme.Colors.Featured)
	elseif called and reason == "NotMember" then
		Toast.Show(Strings.TOAST_GROUP_NOT_MEMBER, Theme.Colors.Select)
	elseif called and reason == "AlreadyClaimed" then
		Toast.Show(Strings.TOAST_GROUP_ALREADY, Theme.Rarity.Common)
	else
		print(("[%s] ClaimGroupReward refused: %s"):format(Config.WorkingTitle, tostring(if called then reason else ok)))
	end
end

-- The group button: Join prompts, Claim asks the server, Claimed only says so. One request at a time.
local function onGroupTap()
	if groupPending then
		return
	end
	local snap = social
	if snap and snap.groupClaimed then
		Toast.Show(Strings.TOAST_GROUP_ALREADY, Theme.Rarity.Common)
		return
	end
	groupPending = true
	refreshSocial()
	task.spawn(function()
		if snap and snap.inGroup then
			claimGroup()
		else
			promptJoin()
		end
		fetchSocial()
		groupPending = false
		refreshSocial()
	end)
end

-- The invite button: the native invite sheet when the platform allows it, otherwise a toast.
local function onInviteTap()
	if invitePending then
		return
	end
	invitePending = true
	task.spawn(function()
		local player = Players.LocalPlayer
		local askedOk, canInvite = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		local prompted = false
		if askedOk and canInvite == true then
			prompted = pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		end
		if not prompted then
			Toast.Show(Strings.TOAST_INVITE_UNAVAILABLE, Theme.Rarity.Common)
		end
		invitePending = false
	end)
end

-- Tiles ---------------------------------------------------------------------

-- A white card in its grid slot: a day chip on top, the reward name, and along the bottom the Claim
-- button, the Claimed chip or the locked line (one visible at a time).
local function buildTile(parent: Frame, index: number, row: GiftRow): Tile
	local slot = Builder.frame({
		parent = parent,
		name = "Day" .. row.day,
		zIndex = 3,
	})
	slot.LayoutOrder = index
	local card = Builder.frame({
		parent = slot,
		name = "Card",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(TILE_INSET, TILE_INSET),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})

	local dayChip = Builder.pill({
		parent = card,
		name = "DayChip",
		position = UDim2.fromScale(0.5, 0.06),
		size = UDim2.fromScale(0.74, 0.2),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(dayChip, Theme.Colors.Featured)
	local dayLabel = Builder.label({
		parent = dayChip,
		name = "Text",
		text = Strings.GIFTS_DAY:format(row.day),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	local reward = Builder.label({
		parent = card,
		name = "Reward",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.3),
		size = UDim2.fromScale(0.9, 0.34),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})

	local claim = Builder.button({
		parent = card,
		name = "Claim",
		text = Strings.GIFTS_CLAIM,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.5, 0.94),
		size = UDim2.fromScale(0.8, 0.26),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		claim(row)
	end)

	local claimed = Builder.pill({
		parent = card,
		name = "Claimed",
		position = UDim2.fromScale(0.5, 0.94),
		size = UDim2.fromScale(0.8, 0.23),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Confirm,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(Theme.Colors.Confirm),
		zIndex = 4,
	})
	Builder.gradient(claimed, Theme.Colors.Confirm)
	Builder.label({
		parent = claimed,
		name = "Text",
		text = Strings.GIFTS_CLAIMED,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	claimed.Visible = false

	local locked = Builder.label({
		parent = card,
		name = "Locked",
		text = Strings.GIFTS_LOCKED,
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, 0.94),
		size = UDim2.fromScale(0.9, 0.24),
		anchor = Vector2.new(0.5, 1),
		zIndex = 4,
	})
	locked.Visible = false

	return {
		card = card,
		dayChip = dayChip,
		dayLabel = dayLabel,
		reward = reward,
		claim = claim,
		claimed = claimed,
		locked = locked,
		icon = nil,
	}
end

-- Wheel ---------------------------------------------------------------------

-- One segment's labels: the name over its odds, in a block placed on the ring at the segment's angle.
local function buildWedge(parent: Frame, index: number, segment: Segment): Wedge
	local angle = segmentAngle(index)
	local block = Builder.frame({
		parent = parent,
		name = "Segment_" .. segment.id,
		position = ringPosition(angle, LABEL_RADIUS),
		size = UDim2.fromScale(LABEL_W, LABEL_H),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	local name = Builder.label({
		parent = block,
		name = "Name",
		text = segmentName(segment.id),
		textSize = Theme.TextSize.Body,
		size = UDim2.fromScale(1, NAME_SHARE),
		zIndex = 4,
	})
	local odds = Builder.label({
		parent = block,
		name = "Odds",
		text = Strings.UI_PERCENT:format(segment.odds),
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0, NAME_SHARE),
		size = UDim2.fromScale(1, 1 - NAME_SHARE),
		zIndex = 4,
	})
	return { block = block, name = name, odds = odds }
end

-- The wheel in its square holder: the turning disc (dividers and the segment ring), and over it the
-- fixed hub with the Spin button and the pointer at the top.
local function buildWheel(parent: Frame): Frame
	local holder = Builder.frame({
		parent = parent,
		name = "Wheel",
		position = UDim2.fromScale(MID_X + MID_W / 2, WHEEL_Y),
		size = UDim2.fromScale(MID_W, WHEEL_H),
		anchor = Vector2.new(0.5, 0),
		aspect = 1,
		zIndex = 3,
	})

	local disc = Builder.pill({
		parent = holder,
		name = "Disc",
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		zIndex = 3,
	})
	Builder.gradient(disc, Theme.Colors.Trough)
	wheel = disc

	local step = 360 / math.max(1, #segments)
	wedges = {}
	for index, segment in ipairs(segments) do
		-- A faint divider at the boundary before this segment, from the hub out to the rim.
		local boundary = segmentAngle(index) - step / 2
		local divider = Builder.frame({
			parent = disc,
			name = "Divider" .. index,
			position = ringPosition(boundary, 0.25),
			size = UDim2.fromScale(DIVIDER_W, 0.5),
			anchor = Vector2.new(0.5, 0.5),
			color = Theme.Colors.White,
			transparency = 0.7,
			zIndex = 3,
		})
		divider.Rotation = boundary
		table.insert(wedges, buildWedge(disc, index, segment))
	end

	local hub = Builder.pill({
		parent = holder,
		name = "Hub",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(HUB_SIZE, HUB_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})
	spinButton = Builder.button({
		parent = hub,
		name = "Spin",
		text = Strings.SPIN_BUTTON,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.8, 0.45),
		anchor = Vector2.new(0.5, 0.5),
		textSize = Theme.TextSize.Label,
		zIndex = 6,
	}, spin)

	-- Pointer: a gold square turned 45 degrees so a corner points down into the rim.
	local pointer = Builder.frame({
		parent = holder,
		name = "Pointer",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(POINTER_SIZE, POINTER_SIZE),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = 1,
		zIndex = 7,
	})
	pointer.Rotation = 45
	Builder.gradient(pointer, Theme.Colors.Featured)

	return holder
end

-- The odds line: every segment's odds, so they are visible whether or not the wheel has been read.
local function oddsLine(): string
	local parts: { string } = {}
	for _, segment in ipairs(segments) do
		table.insert(parts, Strings.SPIN_ODD:format(segmentName(segment.id), segment.odds))
	end
	return Strings.SPIN_ODDS:format(table.concat(parts, Strings.UI_LIST_SEPARATOR))
end

-- The social column: the group gift (button, then what it pays) when the team has a group, then the
-- invite button and what a referral pays. The labels start at the top so a long line grows downwards.
local function buildSocial(body: Frame)
	local y = SOCIAL_Y
	if Social.GroupId ~= 0 then
		groupButton = Builder.button({
			parent = body,
			name = "GroupGift",
			text = Strings.SOCIAL_GROUP_JOIN,
			color = Theme.Colors.Select,
			position = UDim2.fromScale(SOCIAL_X, y),
			size = UDim2.fromScale(SOCIAL_W, SOCIAL_BUTTON_H),
			textSize = Theme.TextSize.Body,
			zIndex = 3,
		}, onGroupTap)
		y += SOCIAL_BUTTON_H + SOCIAL_LINE_GAP
		local groupLine = Builder.label({
			parent = body,
			name = "GroupLine",
			text = Strings.SOCIAL_GROUP_LINE:format(rewardListText(Social.GroupReward)),
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Outline,
			stroke = 0,
			position = UDim2.fromScale(SOCIAL_X, y),
			size = UDim2.fromScale(SOCIAL_W, GROUP_LINE_H),
			zIndex = 3,
		})
		groupLine.TextYAlignment = Enum.TextYAlignment.Top
		y += GROUP_LINE_H + SOCIAL_BLOCK_GAP
	end
	Builder.button({
		parent = body,
		name = "InviteFriends",
		text = Strings.SOCIAL_INVITE,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(SOCIAL_X, y),
		size = UDim2.fromScale(SOCIAL_W, SOCIAL_BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 3,
	}, onInviteTap)
	y += SOCIAL_BUTTON_H + SOCIAL_LINE_GAP
	local inviteLine = Builder.label({
		parent = body,
		name = "InviteLine",
		text = Strings.SOCIAL_INVITE_LINE:format(rewardListText(Social.ReferralInviter), rewardListText(Social.ReferralInvitee)),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(SOCIAL_X, y),
		size = UDim2.fromScale(SOCIAL_W, INVITE_LINE_H),
		zIndex = 3,
	})
	inviteLine.TextYAlignment = Enum.TextYAlignment.Top
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("GiftsScreen", 20)
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
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		GiftsScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.86, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = PANEL_ASPECT,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, gold, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.34, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.GIFTS_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(0.985, 0.015),
		size = UDim2.fromScale(0.11, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		GiftsScreen.Close()
	end)

	-- Left half: Welcome Week ------------------------------------------------
	Builder.label({
		parent = body,
		name = "WeekHeading",
		text = Strings.GIFTS_WEEK,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(LEFT_X, BODY_Y),
		size = UDim2.fromScale(LEFT_W, HEADING_H),
		zIndex = 3,
	})
	daysLabel = Builder.label({
		parent = body,
		name = "DaysPlayed",
		text = Strings.GIFTS_DAYS_PLAYED:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(LEFT_X, DAYS_Y),
		size = UDim2.fromScale(LEFT_W, DAYS_H),
		zIndex = 3,
	})
	nextLabel = Builder.label({
		parent = body,
		name = "Tomorrow",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(LEFT_X, NEXT_Y),
		size = UDim2.fromScale(LEFT_W, NEXT_H),
		zIndex = 3,
	})
	-- The hint fills the two free cells beside Day 7, the last row's only tile.
	Builder.label({
		parent = body,
		name = "Hint",
		text = Strings.GIFTS_HINT,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(LEFT_X + LEFT_W / GRID_COLS, GRID_Y + GRID_H * (GRID_ROWS - 1) / GRID_ROWS),
		size = UDim2.fromScale(LEFT_W * (GRID_COLS - 1) / GRID_COLS, GRID_H / GRID_ROWS),
		zIndex = 3,
	})

	-- The calendar: square slots in a grid (the aspect constraint on the layout keeps the cells square
	-- as the panel scales), each holding a tile card inset by the gap.
	local grid = Builder.frame({
		parent = body,
		name = "Calendar",
		position = UDim2.fromScale(LEFT_X, GRID_Y),
		size = UDim2.fromScale(LEFT_W, GRID_H),
		zIndex = 3,
	})
	local layout = Instance.new("UIGridLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.CellPadding = UDim2.fromScale(0, 0) -- the gap is the inset of each card inside its slot
	layout.CellSize = UDim2.fromScale(1 / GRID_COLS, 1 / GRID_ROWS)
	layout.Parent = grid
	local squareCells = Instance.new("UIAspectRatioConstraint")
	squareCells.AspectRatio = 1
	squareCells.AspectType = Enum.AspectType.ScaleWithParentSize
	squareCells.DominantAxis = Enum.DominantAxis.Width
	squareCells.Parent = layout
	tiles = {}
	for index, row in ipairs(giftRows) do
		table.insert(tiles, buildTile(grid, index, row))
	end

	-- Middle column: the spin wheel -----------------------------------------
	Builder.label({
		parent = body,
		name = "SpinHeading",
		text = Strings.SPIN_TITLE,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(MID_X, BODY_Y),
		size = UDim2.fromScale(MID_W, HEADING_H),
		zIndex = 3,
	})
	buildWheel(body)
	freeLabel = Builder.label({
		parent = body,
		name = "FreeSpins",
		text = Strings.SPIN_FREE:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(MID_X, LINES_Y),
		size = UDim2.fromScale(MID_W / 2, LINES_H),
		zIndex = 3,
	})
	bankedLabel = Builder.label({
		parent = body,
		name = "BankedSpins",
		text = Strings.SPIN_BANKED:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(MID_X + MID_W / 2, LINES_Y),
		size = UDim2.fromScale(MID_W / 2, LINES_H),
		zIndex = 3,
	})
	Builder.label({
		parent = body,
		name = "Odds",
		text = oddsLine(),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(MID_X, ODDS_Y),
		size = UDim2.fromScale(MID_W, ODDS_H),
		zIndex = 3,
	})

	buildSocial(body)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	State.OnChanged("gifts", function()
		claimedLocal = {} -- the push is the truth again
		refresh()
	end)
end

-- Public API -------------------------------------------------------------

function GiftsScreen.IsOpen(): boolean
	return open
end

function GiftsScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
	task.spawn(fetchSocial)
end

function GiftsScreen.Close()
	if not open then
		return
	end
	open = false
	local root, body = gui, panel
	if root and body then
		Builder.close(body, function()
			if not open then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

function GiftsScreen.Toggle()
	if open then
		GiftsScreen.Close()
	else
		GiftsScreen.Open()
	end
end

-- A reward list as one line ("500 Scrap, 3 x Twig Lure, 2 free spin"), for the group line, the invite line
-- and the bootstrap's referral toasts.
function GiftsScreen.RewardText(rewards: { Social.Reward }): string
	return rewardListText(rewards)
end

-- The bootstrap's hook for SocialChanged: the server's new group state, drawn at once if the screen is up.
function GiftsScreen.SetSocial(snapshot: SocialSnapshot)
	socialSeq += 1
	social = snapshot
	refreshSocial()
end

-- The bootstrap's hook for an egg: the server's GrantResult for a hatched alien, to show as a Reveal.
function GiftsScreen.OnGrant(callback: (Types.GrantResult) -> ())
	onGrant = callback
end

return GiftsScreen
