--!strict
-- StarterPlayerScripts.Client.UI.FeaturedCard: the featured card of the Aliens and Codex screens (UI richness pass, package C;
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 4). A grid tile selects; this card shows the selected species whole: its model
-- (UI.SpeciesThumb, still, or turning in the Codex) on a flat plinth in the tier colour's lighter tone, a tier tag (the tier's word on
-- its colour: never colour alone), the name, one flavour line, up to three quiet fact lines (the Codex), and one main button by
-- context with at most one beside it (Shared/FeaturedMath.Button picks them; the screen supplies the taps and the words).
-- It is built once and refilled on every selection: Fill keeps the view and its clone when the species is the same, so a selection
-- never rebuilds anything. Two shapes, one table of numbers (data/Panels.Featured): the side card at a panel of 620 by 330 px or more
-- (a column, FeaturedMath.SideLayout) and the strip across the top of the body under it (iPhone SE, FeaturedMath.StripLayout). The
-- card measures its own px (with a panel's open tween taken out) and places every child as a Scale of itself, again when it resizes.
-- Nothing here decides an outcome: a button only calls what the screen gave it, which asks the server.
-- The look is block cells: an edged white block in the tier's ink, a flat plinth, flat tag, block buttons (Playbook "Richness pass:
-- featured and grid"). Colours of buttons come from the roles (Builder.roleColor); the quiet lines are navy on the white face.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Panels = require(Shared:WaitForChild("data"):WaitForChild("Panels"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local FeaturedMath = require(Shared:WaitForChild("FeaturedMath"))
local Builder = require(script.Parent.Builder)
local SpeciesThumb = require(script.Parent.SpeciesThumb)

local FeaturedCard = {}

-- One button: the word it shows (already looked up), its colour role (a data/Panels.Roles key) and what a tap does.
export type Action = { word: string, role: string, onTap: () -> () }

-- What a card shows. `def` is the species whose model stands on the plinth (nil: the card shows only the prompt); `shadowed` makes it
-- an all-black silhouette (an uncaught species while the Silhouettes preference is on, a Secret always) and `mark` puts the "?" over it.
-- `flavour` is the flavour line (the Codex puts a hint here for an uncaught species), `facts` up to three quiet lines under it.
export type Content = {
	def: Types.SpeciesDef?,
	shadowed: boolean,
	mark: boolean,
	name: string,
	tier: string,
	tierWord: string,
	flavour: string,
	facts: { string },
	main: Action?,
	side: Action?,
}

export type Card = {
	frame: Frame, -- the edged plate: place it with Place
	content: Frame,
	prompt: TextLabel,
	view: Frame, -- the plinth
	host: Frame, -- the model's picture area inside it
	fallback: Frame, -- a flat block in the species colour while there is no model
	fallbackLabel: TextLabel,
	mark: TextLabel,
	thumb: SpeciesThumb.Thumb,
	tag: Frame,
	tagLabel: TextLabel,
	name: TextLabel,
	flavour: TextLabel,
	facts: { TextLabel },
	main: Frame,
	side: Frame,
	mode: FeaturedMath.Mode,
	hasMain: boolean,
	hasSide: boolean,
	factCount: number,
	turns: boolean, -- the model turns (Codex)
	mainTap: (() -> ())?,
	sideTap: (() -> ())?,
	laidW: number, -- the px the children were last placed for
	laidH: number,
	dirty: boolean,
}

local FLAT_ROWS = 3 -- a flat block's rows: the plinth, the tag, the fallback square

-- A panel's (or any gui's) size in px with every open-tween UIScale on its ancestors and itself taken out, so a pop or an open does not
-- change what mode it is in or move a child in and out.
function FeaturedCard.UnscaledSize(gui: GuiObject): Vector2
	local size = gui.AbsoluteSize
	local scale = 1
	local at: Instance? = gui
	while at do
		local ui = at:FindFirstChildOfClass("UIScale")
		if ui and ui.Scale > 0 then
			scale *= ui.Scale
		end
		at = at.Parent
	end
	return size / scale
end

-- Places a label's text for the shape it has now: the side card's flavour line wraps to two lines and scales to its box, the strip's is
-- one 14 px line that ends in an ellipsis (a TextScaled label narrower than its text wraps it mid-word).
local function quietLine(label: TextLabel, oneLine: boolean, left: boolean)
	label.TextWrapped = not oneLine
	label.TextScaled = not oneLine
	if oneLine then
		label.TextSize = Panels.Featured.FactSize
		label.TextTruncate = Enum.TextTruncate.AtEnd
	else
		label.TextTruncate = Enum.TextTruncate.None
	end
	label.TextXAlignment = if left then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
end

local function setBox(object: GuiObject, x: number, y: number, w: number, h: number, anchorX: number?)
	object.AnchorPoint = Vector2.new(anchorX or 0, 0)
	object.Position = UDim2.fromScale(x, y)
	object.Size = UDim2.fromScale(w, h)
end

-- Places every child for the card's shape and its px (the picture's aspect follows, so the model is framed whole).
local function layout(card: Card)
	local size = FeaturedCard.UnscaledSize(card.frame)
	local w, h = size.X, size.Y
	if w <= 0 or h <= 0 then
		w, h = if card.mode == "side" then 190 else 380, if card.mode == "side" then 252 else 50 -- not laid out yet: the usual card
	end
	card.laidW, card.laidH, card.dirty = w, h, false
	local f = Panels.Featured
	local inset = f.ViewInset
	if card.mode == "side" then
		local c = f.Card
		local plan = FeaturedMath.SideLayout(card.hasMain, card.hasSide, card.factCount)
		local x = c.InsetX
		local full = 1 - 2 * x
		setBox(card.view, 0.5, plan.view.y, full, plan.view.h, 0.5)
		SpeciesThumb.Reframe(card.thumb, (full * w * (1 - 2 * inset)) / math.max(1, plan.view.h * h * (1 - 2 * inset)))
		setBox(card.tag, 0.5, plan.tag.y, c.TagW, plan.tag.h, 0.5)
		setBox(card.name, 0.5, plan.name.y, full, plan.name.h, 0.5)
		setBox(card.flavour, 0.5, plan.flavour.y, full, plan.flavour.h, 0.5)
		quietLine(card.flavour, false, false)
		for index, line in ipairs(card.facts) do
			local box = plan.facts[index]
			line.Visible = box ~= nil and index <= card.factCount
			if box then
				setBox(line, 0.5, box.y, full, box.h, 0.5)
				quietLine(line, true, false)
			end
		end
		local main, side = plan.main, plan.side
		card.main.Visible = main ~= nil
		card.side.Visible = side ~= nil
		if main then
			setBox(card.main, 0.5, main.y, full, main.h, 0.5)
		end
		if side then
			setBox(card.side, 0.5, side.y, full, side.h, 0.5)
		end
	else
		local c = f.StripCard
		local plan = FeaturedMath.StripLayout(w / h, card.hasMain, card.hasSide)
		local p = plan.plinth
		setBox(card.view, p.x, p.y, p.w, p.h)
		SpeciesThumb.Reframe(card.thumb, 1)
		local col = plan.column
		local tagW = col.w * c.TagW
		setBox(card.name, col.x, c.NameY, col.w - tagW - c.Gap, c.NameH)
		card.name.TextXAlignment = Enum.TextXAlignment.Left
		setBox(card.tag, col.x + col.w - tagW, c.NameY + (c.NameH - c.TagH) / 2, tagW, c.TagH)
		setBox(card.flavour, col.x, c.FlavourY, col.w, c.FlavourH)
		quietLine(card.flavour, true, true)
		for _, line in ipairs(card.facts) do
			line.Visible = false -- the strip is for the name, the line and the button
		end
		local main, side = plan.main, plan.side
		card.main.Visible = main ~= nil
		card.side.Visible = side ~= nil
		if main then
			setBox(card.main, main.x, main.y, main.w, main.h)
		end
		if side then
			setBox(card.side, side.x, side.y, side.w, side.h)
		end
	end
	if card.mode == "side" then
		card.name.TextXAlignment = Enum.TextXAlignment.Center
	end
end

local function quietLabel(parent: Instance, name: string, zIndex: number): TextLabel
	local label = Builder.label({
		parent = parent,
		name = name,
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		zIndex = zIndex,
	})
	return label
end

-- Builds the card, hidden, empty, in the side shape. `turns` makes the model turn (the Codex calls Spin each frame it is open).
function FeaturedCard.Build(parent: Instance, name: string, zIndex: number, turns: boolean): Card
	local frame = Builder.blockPlate({
		parent = parent,
		name = name,
		color = Theme.Colors.White,
		ink = Theme.Rarity.Common,
		cells = false,
		edges = true,
		zIndex = zIndex,
	})
	local top = Builder.blockTop(frame)

	local prompt = Builder.label({
		parent = frame,
		name = "Prompt",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = top,
	})
	prompt.Visible = false

	local content = Builder.frame({ parent = frame, name = "Content", zIndex = top })

	-- The plinth: a flat block in the tier colour's lighter tone, ink in the tier colour, the model's picture area inside it.
	local view = Builder.blockPlate({
		parent = content,
		name = "Plinth",
		color = Builder.lighter(Theme.Rarity.Common, Panels.Featured.PlinthTint),
		ink = Theme.Rarity.Common,
		rows = FLAT_ROWS,
		cells = false,
		zIndex = top,
	})
	local viewTop = Builder.blockTop(view)
	local inset = Panels.Featured.ViewInset
	local host = Builder.frame({
		parent = view,
		name = "Picture",
		position = UDim2.fromScale(inset, inset),
		size = UDim2.fromScale(1 - 2 * inset, 1 - 2 * inset),
		zIndex = viewTop,
	})
	-- Without a model (none imported for the species) the plinth shows a flat block in the species colour and its name.
	local fallback = Builder.blockPlate({
		parent = host,
		name = "Placeholder",
		color = Theme.Shadow,
		aspect = 1,
		rows = FLAT_ROWS,
		cells = false,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.7, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 1,
	})
	local fallbackLabel = Builder.label({
		parent = fallback,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.4),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(fallback),
	})
	fallback.Visible = false
	local thumb = SpeciesThumb.New(host, 2, 1.6)
	local mark = Builder.label({
		parent = host,
		name = "Mark",
		text = Strings.UI_UNKNOWN_GLYPH,
		textSize = Theme.TextSize.Reveal,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	mark.Visible = false

	-- The tier tag: a flat block in the tier colour with the tier's word on it.
	local tag = Builder.blockPlate({
		parent = content,
		name = "Tag",
		color = Theme.Rarity.Common,
		rows = FLAT_ROWS,
		cells = false,
		zIndex = top,
	})
	local tagLabel = Builder.label({
		parent = tag,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(tag),
	})
	tagLabel.TextWrapped = false

	local nameLabel = Builder.label({
		parent = content,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		zIndex = top,
	})
	nameLabel.TextWrapped = false
	local flavour = quietLabel(content, "Flavour", top)
	local facts: { TextLabel } = {}
	for index = 1, 3 do
		local line = quietLabel(content, "Fact" .. index, top)
		line.Visible = false
		facts[index] = line
	end

	local rows = Builder.blockButtonRows(Panels.Featured.ButtonScreenH)
	local card: Card = {
		frame = frame,
		content = content,
		prompt = prompt,
		view = view,
		host = host,
		fallback = fallback,
		fallbackLabel = fallbackLabel,
		mark = mark,
		thumb = thumb,
		tag = tag,
		tagLabel = tagLabel,
		name = nameLabel,
		flavour = flavour,
		facts = facts,
		main = content, -- replaced below
		side = content,
		mode = "side",
		hasMain = false,
		hasSide = false,
		factCount = 0,
		turns = turns,
		mainTap = nil,
		sideTap = nil,
		laidW = 0,
		laidH = 0,
		dirty = true,
	}
	-- The buttons ride above the plinth and the lines; a tap calls what the last Fill gave (the closures read the card).
	card.main = Builder.blockButton({
		parent = content,
		name = "Main",
		text = "",
		color = Builder.roleColor("main"),
		rows = rows,
		textSize = Theme.TextSize.Label,
		hit = true, -- the face is under the 44 px floor: an invisible 44 px area over it (Theme.TapMin)
		zIndex = top + 2,
	}, function()
		local tap = card.mainTap
		if tap then
			tap()
		end
	end)
	card.side = Builder.blockButton({
		parent = content,
		name = "Side",
		text = "",
		color = Builder.roleColor("select"),
		rows = rows,
		textSize = Theme.TextSize.Label,
		hit = true,
		zIndex = top + 2,
	}, function()
		local tap = card.sideTap
		if tap then
			tap()
		end
	end)
	card.main.Visible = false
	card.side.Visible = false

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local size = FeaturedCard.UnscaledSize(frame)
		if card.dirty or math.abs(size.X - card.laidW) > 0.5 or math.abs(size.Y - card.laidH) > 0.5 then
			layout(card)
		end
	end)
	layout(card)
	return card
end

-- Puts the card at `position` and `size` (Scale values of its parent) in `mode`. The screen calls it when the panel's mode changes or
-- the body is re-laid out.
function FeaturedCard.Place(card: Card, mode: FeaturedMath.Mode, position: UDim2, size: UDim2)
	card.mode = mode
	card.frame.Position = position
	card.frame.Size = size
	card.dirty = true
	layout(card)
end

function FeaturedCard.SetVisible(card: Card, visible: boolean)
	card.frame.Visible = visible
end

-- Styles one button for an action (or hides it): the role's colour, the word, and the Check mark on a grey "current" button so the
-- state is never colour alone.
local function setAction(button: Frame, action: Action?): boolean
	if not action then
		button.Visible = false
		return false
	end
	Builder.restyleBlockButton(button, action.word, Builder.roleColor(action.role), true)
	Builder.setButtonMark(button, if action.role == "current" then "Check" else nil)
	return true
end

-- Shows `content` on the card, or, with nil, only `promptText` (an empty store, a page with no species): never an empty pane. A fill
-- with the same species and shade keeps the model's view and clone, so selecting does not rebuild it.
function FeaturedCard.Fill(card: Card, content: Content?, promptText: string?)
	if not content or not content.def then
		card.content.Visible = false
		card.prompt.Visible = true
		card.prompt.Text = promptText or ""
		Builder.setBlockInk(card.frame, Theme.Rarity.Common)
		card.hasMain, card.hasSide, card.factCount = false, false, 0
		card.mainTap, card.sideTap = nil, nil
		return
	end
	local def = content.def
	card.prompt.Visible = false
	card.content.Visible = true
	local tierColor = Builder.tierColor(content.tier)
	Builder.setBlockInk(card.frame, tierColor)
	Builder.setBlockInk(card.view, tierColor)
	Builder.setBlockColor(card.view, Builder.lighter(tierColor, Panels.Featured.PlinthTint))
	Builder.setBlockColor(card.tag, tierColor)

	local shown = SpeciesThumb.Show(card.thumb, def, content.shadowed, card.turns)
	card.fallback.Visible = not shown
	if not shown then
		Builder.setBlockColor(card.fallback, if content.shadowed then Theme.Shadow else Theme.Hex(def.placeholder.color))
		card.fallbackLabel.Text = if content.mark then "" else content.name
	end
	card.mark.Visible = content.mark

	card.tagLabel.Text = content.tierWord
	card.name.Text = content.name
	card.flavour.Text = content.flavour
	local count = math.min(#content.facts, #card.facts)
	for index, line in ipairs(card.facts) do
		line.Text = content.facts[index] or ""
	end
	card.factCount = count
	card.hasMain = setAction(card.main, content.main)
	card.hasSide = setAction(card.side, content.side)
	card.mainTap = if content.main then content.main.onTap else nil
	card.sideTap = if content.side then content.side.onTap else nil
	card.dirty = true
	layout(card)
end

-- Spins the model by `angle` radians (a card built with `turns`); the Codex's frame step calls it while open and not under Reduced Motion.
function FeaturedCard.Spin(card: Card, angle: number)
	if card.turns and card.thumb.model then
		SpeciesThumb.Turn(card.thumb, angle)
	end
end

return FeaturedCard
