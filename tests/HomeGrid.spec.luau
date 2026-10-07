--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Grid = require(Shared.HomeGrid)
local Data = require(Shared.data.HomeBuild)
local Home = require(Shared.data.Home)
local F = require(script.Parent.Fixtures)
local cells = Home.PlotCells

describe("HomeGrid", function()
	for _, item in ipairs(Data.Items) do
		for rotation = F.zero, Data.RotationSteps - F.one do
			it(item.id .. " corner and four edges at turn " .. rotation, function()
				local sideways = rotation % F.two == F.one
				local width = if sideways then item.cellsZ else item.cellsX
				local depth = if sideways then item.cellsX else item.cellsZ
				local footprint = Grid.Footprint(item, F.zero, F.zero, rotation)
				expect(footprint.x1).toEqual(width - F.one)
				expect(footprint.z1).toEqual(depth - F.one)
				expect(Grid.InsidePlot(footprint, cells)).toEqual(true)
				expect(Grid.InsidePlot(Grid.Footprint(item, cells - width, cells - depth, rotation), cells)).toEqual(true)
				for _, at in ipairs({ {-F.one, F.zero}, {F.zero, -F.one},
					{cells - width + F.one, F.zero}, {F.zero, cells - depth + F.one} }) do
					expect(Grid.InsidePlot(Grid.Footprint(item, at[F.one], at[F.two], rotation), cells)).toEqual(false)
				end
			end)
		end
		if item.kind == "habitat" then
			it(item.id .. " every plot cell and rotation", function()
				for rotation = F.zero, Data.RotationSteps - F.one do
					for x = F.zero, cells - F.one do
						for z = F.zero, cells - F.one do
							local occupied = {}
							for dx = F.zero, item.cellsX - F.one do
								for dz = F.zero, item.cellsZ - F.one do
									table.insert(occupied, if rotation % F.two == F.zero then {x + dx, z + dz} else {x + dz, z + dx})
								end
							end
							local fits = true
							for _, cell in ipairs(occupied) do
								if cell[F.one] >= cells or cell[F.two] >= cells then fits = false end
							end
							expect(Grid.InsidePlot(Grid.Footprint(item, x, z, rotation), cells)).toEqual(fits)
						end
					end
				end
			end)
		end
	end
	it("room and thing overlap is symmetric, with adjacent cells free", function()
		local room, thing = Data.ById.RoomCabin, Data.ById.Bench
		local a = Grid.Footprint(room, F.zero, F.zero, F.zero)
		for x = -F.one, room.cellsX do
			for z = -F.one, room.cellsZ do
				local b = Grid.Footprint(thing, x, z, F.zero)
				local overlaps = x >= F.zero and x < room.cellsX and z >= F.zero and z < room.cellsZ
				expect(Grid.Overlaps(a, b)).toEqual(overlaps)
				expect(Grid.Overlaps(b, a)).toEqual(overlaps)
			end
		end
	end)
	it("rectangular dimensions swap on odd turns", function()
		local item = { cellsX = Data.ById.RoomCabin.cellsX, cellsZ = Data.ById.Bench.cellsZ }
		for turn = F.zero, Data.RotationSteps - F.one do
			local w, d = Grid.Dimensions(item, turn)
			expect(w).toEqual(if turn % F.two == F.one then item.cellsZ else item.cellsX)
			expect(d).toEqual(if turn % F.two == F.one then item.cellsX else item.cellsZ)
		end
	end)
	it("cell borders include near edges and exclude far edges on both axes", function()
		local size = cells * Home.PlotCellStuds
		for border = F.zero, cells do
			for _, delta in ipairs({-F.half, F.zero, F.half}) do
				local point = (border + delta) * Home.PlotCellStuds - size * F.half
				local expected = if delta < F.zero then border - F.one else border
				local valid = expected >= F.zero and expected < cells
				local x, z = Grid.CellAt(cells, Home.PlotCellStuds, size, size, point, -size * F.half)
				expect(x).toEqual(if valid then expected else nil)
				expect(z).toEqual(if valid then F.zero else nil)
				x, z = Grid.CellAt(cells, Home.PlotCellStuds, size, size, -size * F.half, point)
				expect(x).toEqual(if valid then F.zero else nil)
				expect(z).toEqual(if valid then expected else nil)
			end
		end
	end)
end)
return true
