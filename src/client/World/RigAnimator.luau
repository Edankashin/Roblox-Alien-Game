--!strict
-- StarterPlayerScripts.Client.World.RigAnimator: plays a species' B46 rig (data/Rigs, written by tools/blocky/rigs.py from its spec
-- note) on a cloned model: each moving part's looping clips about its pivot, the clips of the whole body about its feet (`root`), the
-- face plate's blink, glint and iris cycle, and the flourish on its timer. Pure presentation: the clock and the data decide every pose,
-- nothing here touches an outcome. The math is Shared/RigMath (absolute functions of os.clock(), never accumulated), so a skipped
-- frame or an alien that comes back on screen is exactly in step.
-- How a pose lands: every animated part is written absolutely from the model's pivot each frame (pivot * root pose * part pose * rest),
-- with its rest captured against the pivot when it was attached, so the renderers' own PivotTo (WildRenderer's bob, SpeciesFx.Place)
-- carries it rigidly and the two never fight. A ScaleTo since the capture scales the rests and pivots (as SpeciesFx's wings do). Parts
-- that SpeciesFx swings (data/Effects `idle.parts`) are left to it.
-- The face plate (a part named data/Rigs face.part): once its flipbook is uploaded (face.image ~= 0) the plate's own texture is hidden and
-- a SurfaceGui on its front shows the frames (ImageRectOffset, nearest filtering); until then the blink squashes the plate's height
-- (Budget.FallbackHalf, FallbackClosed) and the other frames are skipped. A model shadowed by Models.SetShadow (its "Shadowed"
-- attribute) hides the flipbook so a silhouette never shows lit eyes.
-- Old blockouts: a model in which no moving part and no face plate is found by name is not animated at all (Attach returns a no-op).
-- Phone budgets: the nearest Budget.MaxAnimated (Budget.PhoneMaxAnimated on a touch screen) on-screen aliens within Budget.Distance of the
-- camera animate, re-ranked every Budget.RecheckSeconds; the rest hold their rest pose. A model shown in a viewport (the reveal) is
-- attached with `always`, outside the ranking. Reduced Motion (Prefs): every clip and the flourish hold still; the blink stays.
-- When an animated alien's flourish begins, SpeciesFx.Flourish(model, speciesId) plays the species' flourish effects on the same beat
-- (a model SpeciesFx does not know, like the reveal's, is ignored there), and OnFlourish(callback) hears (model, speciesId) too.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Rigs = require(Shared:WaitForChild("data"):WaitForChild("Rigs"))
local Effects = require(Shared:WaitForChild("data"):WaitForChild("Effects"))
local RigMath = require(Shared:WaitForChild("RigMath"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local SpeciesFx = require(script.Parent:WaitForChild("SpeciesFx"))

local RigAnimator = {}

local SHADOWED = "Shadowed" -- the model attribute Models.SetShadow keeps
local FX_ANCHOR = "FxAnchor" -- SpeciesFx's invisible anchor part: never posed here
local FACE_GUI = "RigFace"

export type Options = {
	always: boolean?, -- animate whatever the distance or the count cap (a model in a viewport)
}

type Joint = { part: BasePart, rest: CFrame, size: Vector3 } -- the rest against the pivot at the attach scale
type Mover = { name: string, pivot: Vector3, clips: { Types.RigClip }, joints: { Joint }, pose: Types.RigPose }
type Handle = {
	model: Model,
	speciesId: string,
	row: Types.RigRow,
	always: boolean,
	offset: number, -- a share of a period, so a crowd of one species is not in step
	scale0: number, -- model:GetScale() at the capture
	studs: number, -- model studs per data stud at the capture
	movers: { Mover },
	body: { Joint }, -- every other part, posed only when the whole body moves (root clips or root flourish moves)
	rootMoves: boolean,
	rootPose: Types.RigPose,
	face: Joint?,
	faceImage: ImageLabel?,
	faceGui: SurfaceGui?,
	faceFrame: number,
	active: boolean,
	atRest: boolean,
	inFlourish: boolean,
	forcedAt: number?, -- os.clock() when PlayFlourish started a flourish off the timer
	destroying: RBXScriptConnection?,
}

local handles: { Handle } = {}
local byModel: { [Model]: Handle } = {}
local listeners: { (Model, string) -> () } = {}
local renderConn: RBXScriptConnection? = nil
local lastRecheck = -math.huge
local distances: { number } = {}
local picked: { boolean } = {}
local order: { number } = {}
local rng = Random.new()

local function noop() end

local function budgetCap(): number
	return if UserInputService.TouchEnabled then Rigs.Budget.PhoneMaxAnimated else Rigs.Budget.MaxAnimated
end

-- Every BasePart of the model named `name`, or under a child named `name` (an import may split one object into several parts).
local function partsNamed(model: Model, name: string): { BasePart }
	local found: { BasePart } = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local node: Instance? = descendant
			while node and node ~= model do
				if node.Name == name then
					table.insert(found, descendant)
					break
				end
				node = node.Parent
			end
		end
	end
	return found
end

local function joint(pivot: CFrame, part: BasePart): Joint
	return { part = part, rest = pivot:ToObjectSpace(part.CFrame), size = part.Size }
end

-- The face of `part` that looks most along `direction` (world space): where the flipbook goes.
local function faceToward(part: BasePart, direction: Vector3): Enum.NormalId
	local cf = part.CFrame
	local best, bestDot = Enum.NormalId.Front, -math.huge
	local candidates: { { Enum.NormalId | Vector3 } } = {
		{ Enum.NormalId.Front, cf.LookVector },
		{ Enum.NormalId.Back, -cf.LookVector },
		{ Enum.NormalId.Right, cf.RightVector },
		{ Enum.NormalId.Left, -cf.RightVector },
		{ Enum.NormalId.Top, cf.UpVector },
		{ Enum.NormalId.Bottom, -cf.UpVector },
	}
	for _, pair in ipairs(candidates) do
		local normal = pair[2] :: Vector3
		local dot = normal:Dot(direction)
		if dot > bestDot then
			best, bestDot = pair[1] :: Enum.NormalId, dot
		end
	end
	return best
end

local function buildFlipbook(handle: Handle, face: Types.RigFace, plate: BasePart)
	if face.image == 0 then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = FACE_GUI
	gui.Face = faceToward(plate, handle.model:GetPivot().LookVector) -- the alien faces its pivot's look
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(face.frameWidth, face.frameHeight)
	gui.LightInfluence = 1
	gui.Adornee = plate
	local image = Instance.new("ImageLabel")
	image.Name = "Frames"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://" .. face.image
	image.ImageRectSize = Vector2.new(face.frameWidth, face.frameHeight)
	image.ResampleMode = Enum.ResamplerMode.Pixelated
	image.Parent = gui
	gui.Parent = plate
	plate.Transparency = 1 -- the flipbook draws the face; the baked open frame underneath would double it
	handle.faceGui = gui
	handle.faceImage = image
end

-- Applies `pose` about the point `around` (pivot space, model studs) to a pivot-space frame and size: offset, turn, then scale.
local function applyPose(pose: Types.RigPose, around: Vector3, studs: number, frame: CFrame, size: Vector3): (CFrame, Vector3)
	local s = Vector3.new(pose.sx, pose.sy, pose.sz)
	local rel = (frame.Position - around) * s
	local moved = CFrame.new(around + Vector3.new(pose.px, pose.py, pose.pz) * studs)
		* CFrame.Angles(pose.rx, pose.ry, pose.rz)
		* CFrame.new(rel)
		* frame.Rotation
	return moved, size * s
end

local function scaled(rest: CFrame, k: number): CFrame
	return CFrame.new(rest.Position * k) * rest.Rotation
end

local function setPart(part: BasePart, cf: CFrame, size: Vector3)
	if part.Size ~= size then
		part.Size = size
	end
	part.CFrame = cf
end

-- Puts every captured part back at its rest (an alien leaving the budget, Reduced Motion, a release).
local function restPose(handle: Handle)
	if handle.atRest then
		return
	end
	handle.atRest = true
	local pivot = handle.model:GetPivot()
	local k = handle.model:GetScale() / handle.scale0
	local function back(j: Joint)
		setPart(j.part, pivot * scaled(j.rest, k), j.size * k)
	end
	for _, mover in ipairs(handle.movers) do
		for _, j in ipairs(mover.joints) do
			back(j)
		end
	end
	for _, j in ipairs(handle.body) do
		back(j)
	end
	local face = handle.face
	if face then
		back(face)
	end
end

local function fireFlourish(handle: Handle)
	-- the species' effects play their flourish on the rig's beat (SpeciesFx then stands its own timer down, so the two never double)
	SpeciesFx.Flourish(handle.model, handle.speciesId)
	for _, callback in ipairs(listeners) do
		task.spawn(callback, handle.model, handle.speciesId)
	end
end

local function faceStep(handle: Handle, now: number, still: boolean, pivot: CFrame, k: number, rootCF: CFrame?, rootPose: Types.RigPose)
	local face = handle.row.face
	local plate = handle.face
	if not face or not plate then
		return
	end
	local frame = RigMath.FaceFrame(face, now, handle.offset)
	if still and frame ~= face.half and frame ~= face.closed then
		frame = face.open
	end
	local image = handle.faceImage
	if image then
		local gui = handle.faceGui
		if gui then
			gui.Enabled = handle.model:GetAttribute(SHADOWED) ~= true
		end
		if frame ~= handle.faceFrame then
			handle.faceFrame = frame
			local x, y = RigMath.FrameOffset(face, frame)
			image.ImageRectOffset = Vector2.new(x, y)
		end
		if rootCF then
			local cf, size = applyPose(rootPose, Vector3.zero, handle.studs * k, scaled(plate.rest, k), plate.size * k)
			setPart(plate.part, pivot * cf, size)
		end
		return
	end
	-- no flipbook yet: the blink squashes the plate's height
	local share = RigMath.FallbackShare(face, frame, Rigs.Budget.FallbackHalf, Rigs.Budget.FallbackClosed)
	local rest, size = scaled(plate.rest, k), plate.size * k
	local cf = rest
	if rootCF then
		cf, size = applyPose(rootPose, Vector3.zero, handle.studs * k, rest, size)
	end
	setPart(plate.part, pivot * cf, Vector3.new(size.X, size.Y * share, size.Z))
end

local function step(handle: Handle, now: number, still: boolean)
	local row = handle.row
	local model = handle.model
	local pivot = model:GetPivot()
	local k = model:GetScale() / handle.scale0
	local studs = handle.studs * k
	if still then
		restPose(handle)
		faceStep(handle, now, true, pivot, k, nil, handle.rootPose)
		handle.inFlourish = false
		return
	end
	handle.atRest = false
	local flourish = row.flourish
	local elapsed = if flourish then RigMath.FlourishElapsed(flourish, now, handle.offset) else -1
	local forcedAt = handle.forcedAt
	if flourish and forcedAt then
		if now - forcedAt < flourish.length then
			elapsed = now - forcedAt -- a flourish asked for by PlayFlourish runs its whole length from that moment
		else
			handle.forcedAt = nil
		end
	end
	if elapsed >= 0 and not handle.inFlourish then
		fireFlourish(handle)
	end
	handle.inFlourish = elapsed >= 0
	local rootPose = handle.rootPose
	RigMath.Reset(rootPose)
	for _, clip in ipairs(row.root) do
		RigMath.Accumulate(rootPose, clip, now, handle.offset)
	end
	if flourish and elapsed >= 0 then
		for _, move in ipairs(flourish.moves) do
			if move.part == "root" then
				RigMath.AccumulateMove(rootPose, move, elapsed)
			end
		end
	end
	local rootCF: CFrame? = if handle.rootMoves then CFrame.identity else nil
	for _, mover in ipairs(handle.movers) do
		local pose = mover.pose
		RigMath.Reset(pose)
		for _, clip in ipairs(mover.clips) do
			RigMath.Accumulate(pose, clip, now, handle.offset)
		end
		if flourish and elapsed >= 0 then
			for _, move in ipairs(flourish.moves) do
				if move.part == mover.name then
					RigMath.AccumulateMove(pose, move, elapsed)
				end
			end
		end
		local around = mover.pivot * studs
		for _, j in ipairs(mover.joints) do
			local cf, size = applyPose(pose, around, studs, scaled(j.rest, k), j.size * k)
			if rootCF then
				cf, size = applyPose(rootPose, Vector3.zero, studs, cf, size)
			end
			setPart(j.part, pivot * cf, size)
		end
	end
	if rootCF then
		for _, j in ipairs(handle.body) do
			local cf, size = applyPose(rootPose, Vector3.zero, studs, scaled(j.rest, k), j.size * k)
			setPart(j.part, pivot * cf, size)
		end
	end
	faceStep(handle, now, false, pivot, k, rootCF, rootPose)
end

-- Ranks the ranked handles nearest first (on screen, within the distance) and switches the rest to their rest pose.
local function recheck()
	local camera = Workspace.CurrentCamera
	table.clear(distances)
	for i, handle in ipairs(handles) do
		local d = math.huge
		if not handle.always and camera and handle.model.Parent then
			local at = handle.model:GetPivot().Position
			local _, onScreen = camera:WorldToViewportPoint(at)
			if onScreen then
				d = (at - camera.CFrame.Position).Magnitude
			end
		end
		distances[i] = d
	end
	RigMath.PickNearest(distances, budgetCap(), Rigs.Budget.Distance, picked, order)
	for i, handle in ipairs(handles) do
		local on = handle.always or picked[i] == true
		if handle.active and not on then
			restPose(handle)
			handle.inFlourish = false
		end
		handle.active = on
	end
end

local function onRender()
	local now = os.clock()
	if now - lastRecheck >= Rigs.Budget.RecheckSeconds then
		lastRecheck = now
		recheck()
	end
	local still = Prefs.ReducedMotion()
	for _, handle in ipairs(handles) do
		if handle.active and handle.model.Parent then
			step(handle, now, still)
		end
	end
end

local function release(handle: Handle)
	if byModel[handle.model] ~= handle then
		return
	end
	byModel[handle.model] = nil
	local at = table.find(handles, handle)
	if at then
		table.remove(handles, at)
	end
	local conn = handle.destroying
	if conn then
		conn:Disconnect()
	end
	if handle.model.Parent then
		restPose(handle)
	end
	if #handles == 0 and renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

-- Plays `speciesId`'s rig on `model` (a fresh clone from Models.Clone, at its rest pose) until the model is destroyed or the returned
-- cleanup is called. A species with no row, or a model in which no moving part and no face plate is found (an old blockout), gets a
-- no-op. Attaching the same model again replaces the first.
function RigAnimator.Attach(model: Model, speciesId: string, opts: Options?): () -> ()
	local row: Types.RigRow? = Rigs.Species[speciesId]
	if not row then
		return noop
	end
	local previous = byModel[model]
	if previous then
		release(previous)
	end
	local pivot = model:GetPivot()
	local fx = Effects.Species[speciesId]
	local leave: { [BasePart]: boolean } = {}
	if fx and fx.idle.parts then
		for _, name in ipairs(fx.idle.parts) do
			for _, part in ipairs(partsNamed(model, name)) do
				leave[part] = true -- SpeciesFx swings these
			end
		end
	end
	local taken: { [BasePart]: boolean } = {}
	local movers: { Mover } = {}
	local height = model:GetExtentsSize().Y
	local studs = if row.height > 0 then height / row.height else 1
	for _, def in ipairs(row.parts) do
		local joints: { Joint } = {}
		for _, part in ipairs(partsNamed(model, def.name)) do
			if not leave[part] and not taken[part] then
				taken[part] = true
				table.insert(joints, joint(pivot, part))
			end
		end
		if #joints > 0 then
			table.insert(movers, {
				name = def.name,
				pivot = Vector3.new(def.pivot[1], def.pivot[2], def.pivot[3]),
				clips = def.clips,
				joints = joints,
				pose = RigMath.NewPose(),
			})
		end
	end
	local face: Joint? = nil
	local rowFace = row.face
	if rowFace then
		local plates = partsNamed(model, rowFace.part)
		if #plates > 0 then
			face = joint(pivot, plates[1])
			taken[plates[1]] = true
		end
	end
	if #movers == 0 and not face then
		return noop -- an old blockout: none of the rig's parts are there
	end
	local rootMoves = #row.root > 0
	local flourish = row.flourish
	if flourish then
		for _, move in ipairs(flourish.moves) do
			if move.part == "root" then
				rootMoves = true
			end
		end
	end
	local body: { Joint } = {}
	if rootMoves then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and not taken[descendant] and not leave[descendant] and descendant.Name ~= FX_ANCHOR then
				table.insert(body, joint(pivot, descendant))
			end
		end
	end
	local handle: Handle = {
		model = model,
		speciesId = speciesId,
		row = row,
		always = opts ~= nil and opts.always == true,
		offset = rng:NextNumber(),
		scale0 = model:GetScale(),
		studs = studs,
		movers = movers,
		body = body,
		rootMoves = rootMoves,
		rootPose = RigMath.NewPose(),
		face = face,
		faceImage = nil,
		faceGui = nil,
		faceFrame = -1,
		active = false,
		atRest = true,
		inFlourish = false,
		forcedAt = nil,
		destroying = nil,
	}
	if face and rowFace then
		buildFlipbook(handle, rowFace, face.part)
	end
	byModel[model] = handle
	table.insert(handles, handle)
	handle.destroying = model.Destroying:Connect(function()
		release(handle)
	end)
	lastRecheck = -math.huge -- rank on the next frame
	if not renderConn then
		renderConn = RunService.RenderStepped:Connect(onRender)
	end
	return function()
		release(handle)
	end
end

-- Starts `model`'s flourish now, off its timer (the reveal's hero beat). Returns false when the model is not animated or its
-- species has no flourish (Commons and Uncommons). The rig's own timer carries on afterwards; a timed flourish that falls inside
-- this one is absorbed by it.
function RigAnimator.PlayFlourish(model: Model): boolean
	local handle = byModel[model]
	if not handle or not handle.row.flourish then
		return false
	end
	handle.forcedAt = os.clock()
	handle.inFlourish = false -- so the effects fire on this beat
	return true
end

-- Calls `callback(model, speciesId)` whenever an animated alien's flourish begins (the hook effects hang a burst on). Returns the
-- disconnect.
function RigAnimator.OnFlourish(callback: (Model, string) -> ()): () -> ()
	table.insert(listeners, callback)
	return function()
		local at = table.find(listeners, callback)
		if at then
			table.remove(listeners, at)
		end
	end
end

return RigAnimator
