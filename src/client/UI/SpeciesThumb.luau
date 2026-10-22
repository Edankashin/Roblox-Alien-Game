--!strict
-- StarterPlayerScripts.Client.UI.SpeciesThumb: the species' real model, still, in a small ViewportFrame on a card's square (the
-- Aliens cards, the Codex grid). It replaces the placeholder shape's name ("Ball"), which the cards printed with every model
-- uploaded (Studio 2026-10-22). With no model (none imported in this place, or a species still without one) Show answers false
-- and the card shows the species' display name instead; a card never shows a shape name. The camera stands front-left and a
-- little above, as the Reveal's, far enough back for the whole model (Shared/ViewFit, tests/ViewFit.spec.luau). Nothing here
-- turns: a still view renders once, so a grid of them costs no frame time while it sits. UI Playbook "Studio fixes after the
-- block cells (2026-10-22)".

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
local FIT = 1.02 -- the bounding sphere just inside the view (the sphere is already wider than the model)
local DIRECTION = Vector3.new(-0.6, 0.45, -1) -- from the model's front-left, slightly above (its face is toward -Z)

export type Thumb = {
	view: ViewportFrame,
	camera: Camera,
	model: Model?,
	species: string?, -- what the view holds now, so a refill with the same species and shade keeps the clone
	shadowed: boolean,
}

-- A hidden view on the face of a block square (inside its ink), above the square's content layer.
function SpeciesThumb.New(square: Frame): Thumb
	local view = Instance.new("ViewportFrame")
	view.Name = "Thumb"
	view.BorderSizePixel = 0
	view.BackgroundTransparency = 1
	view.Position, view.Size = Builder.blockInner(square)
	view.Ambient = Builder.darker(Theme.Colors.White, 0.45) -- soft grey fill light, as the Codex and the Reveal
	view.LightColor = Theme.Colors.White
	view.LightDirection = Vector3.new(-1, -2, -1)
	view.ZIndex = Builder.blockTop(square)
	view.Visible = false
	view.Parent = square
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.Parent = view
	view.CurrentCamera = camera
	return { view = view, camera = camera, model = nil, species = nil, shadowed = false }
end

-- Puts `def`'s model in the view (shadowed as a silhouette when `shadowed`), framed whole. Answers whether a model shows; false
-- (no def, or no model for it) hides the view, and the caller shows the species' display name.
function SpeciesThumb.Show(thumb: Thumb, def: Types.SpeciesDef?, shadowed: boolean): boolean
	if def and thumb.model and thumb.species == def.id then
		if thumb.shadowed ~= shadowed then
			Models.SetShadow(thumb.model, shadowed)
			thumb.shadowed = shadowed
		end
		thumb.view.Visible = true
		return true
	end
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
	end
	model.Parent = thumb.view
	local box, size = model:GetBoundingBox()
	local target = box.Position
	local distance = ViewFit.Distance(size.X, size.Y, size.Z, FOV, FIT)
	thumb.camera.CFrame = CFrame.lookAt(target + DIRECTION.Unit * distance, target)
	thumb.model, thumb.species, thumb.shadowed = model, def.id, shadowed
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
