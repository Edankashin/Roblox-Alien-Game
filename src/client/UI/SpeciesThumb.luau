--!strict
-- StarterPlayerScripts.Client.UI.SpeciesThumb: the species' real model, still, in a ViewportFrame that fills a card's picture area
-- (the Aliens cards, the Codex grid). It replaces the placeholder shape's name ("Ball"), which the cards printed with every model
-- uploaded (Studio 2026-10-22), and the small colour square the model once stood in (it showed tiny inside a green plus block,
-- Studio 2026-10-22 second run): the caller hides that backdrop while Show answers true and keeps it only as the empty state.
-- With no model (none imported in this place, or a species still without one) Show answers false and the card shows the
-- backdrop and the species' display name; a card never shows a shape name. The camera stands front-left and a little above, as
-- the Reveal's, at the distance that frames the model's bounding box whole in a picture of the given aspect (Shared/ViewFit,
-- tests/ViewFit.spec.luau). Nothing here turns: a still view renders once, so a grid of them costs no frame time while it sits.
-- UI Playbook "Studio fixes after the block cells (2026-10-22)".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local ViewFit = require(Shared:WaitForChild("ViewFit"))
local Builder = require(script.Parent.Builder)
local Models = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Models"))

local SpeciesThumb = {}

local FOV = 30 -- a long lens: little perspective on a small square
local FIT = 1.04 -- the bounding box just inside the view: a little air round the model
local DIRECTION = Vector3.new(-0.6, 0.45, -1) -- from the model's front-left, slightly above (its face is toward -Z)

export type Thumb = {
	view: ViewportFrame,
	camera: Camera,
	model: Model?,
	species: string?, -- what the view holds now, so a refill with the same species and shade keeps the clone
	shadowed: boolean,
	turns: boolean, -- framed for a model that turns (by the horizontal diagonal of its box)
	aspect: number, -- the picture's width over its height, which the camera frames the box in
	center: Vector3, -- the model's box centre at its resting pose: the camera's target and the turn's axis
	size: Vector3, -- its box
}

-- A hidden view filling `host` (a plain frame the caller sizes to the card's picture area, `aspect` wide for its height in px) at
-- ZIndex `z`, above the host's backdrop.
function SpeciesThumb.New(host: Frame, z: number, aspect: number): Thumb
	local view = Instance.new("ViewportFrame")
	view.Name = "Thumb"
	view.BorderSizePixel = 0
	view.BackgroundTransparency = 1
	view.Position, view.Size = UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
	view.Ambient = Builder.darker(Theme.Colors.White, 0.45) -- soft grey fill light, as the Codex and the Reveal
	view.LightColor = Theme.Colors.White
	view.LightDirection = Vector3.new(-1, -2, -1)
	view.ZIndex = z
	view.Visible = false
	view.Parent = host
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.Parent = view
	view.CurrentCamera = camera
	return {
		view = view,
		camera = camera,
		model = nil,
		species = nil,
		shadowed = false,
		turns = false,
		aspect = aspect,
		center = Vector3.zero,
		size = Vector3.zero,
	}
end

-- Points the camera at the model's box, at the distance that frames it whole in a picture of the thumb's aspect (a turning model by
-- the diagonal of its footprint, so no angle clips).
local function frame(thumb: Thumb)
	local size = thumb.size
	local width = if thumb.turns then math.sqrt(size.X * size.X + size.Z * size.Z) else nil
	local distance = ViewFit.BoxDistance(
		width or size.X,
		size.Y,
		width or size.Z,
		DIRECTION.X,
		DIRECTION.Y,
		DIRECTION.Z,
		FOV,
		thumb.aspect,
		FIT
	)
	thumb.camera.CFrame = CFrame.lookAt(thumb.center + DIRECTION.Unit * distance, thumb.center)
end

-- A new picture shape (the card changed between its side and strip modes): the same model, framed again.
function SpeciesThumb.Reframe(thumb: Thumb, aspect: number)
	if math.abs(aspect - thumb.aspect) < 0.01 then
		return
	end
	thumb.aspect = aspect
	if thumb.model then
		frame(thumb)
	end
end

-- Spins the model by `angle` radians about the vertical axis through its centre (a view made with `turns`).
function SpeciesThumb.Turn(thumb: Thumb, angle: number)
	local model = thumb.model
	if not model then
		return
	end
	local c = thumb.center
	model:PivotTo(CFrame.new(c.X, 0, c.Z) * CFrame.Angles(0, angle, 0) * CFrame.new(-c.X, 0, -c.Z))
end

-- Puts `def`'s model in the view (shadowed as an all-black silhouette when `shadowed`: no texture, no decal, no colour), framed whole. Answers whether a model shows; false
-- (no def, or no model for it) hides the view, and the caller keeps its backdrop and shows the species' display name.
function SpeciesThumb.Show(thumb: Thumb, def: Types.SpeciesDef?, shadowed: boolean, turns: boolean?): boolean
	local turning = turns == true
	if def and thumb.model and thumb.species == def.id and thumb.shadowed == shadowed and thumb.turns == turning then
		thumb.view.Visible = true
		return true
	end
	-- A different species, or the same one in the other shade: the clone is rebuilt (a silhouette strips the model's decals, which
	-- SetShadow leaves, and cannot be put back by un-shadowing).
	if thumb.model then
		thumb.model:Destroy()
		thumb.model = nil
	end
	thumb.species = nil
	local model = if def then Models.Clone(def, Config.ModelViewportScale) else nil
	if not def or not model then
		thumb.view.Visible = false
		return false
	end
	model:PivotTo(CFrame.identity)
	if shadowed then
		Models.SetShadow(model, true)
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("Decal") or descendant:IsA("Texture") then
				descendant:Destroy() -- a painted-on face would show through the black
			end
		end
	end
	model.Parent = thumb.view
	local box, size = model:GetBoundingBox()
	thumb.center, thumb.size, thumb.turns = box.Position, size, turning
	thumb.model, thumb.species, thumb.shadowed = model, def.id, shadowed
	frame(thumb)
	thumb.view.Visible = true
	return true
end

-- Drops the view and its clone (a card scrolled far off its grid's window).
function SpeciesThumb.Destroy(thumb: Thumb)
	thumb.view:Destroy()
	thumb.model = nil
	thumb.species = nil
end

return SpeciesThumb
