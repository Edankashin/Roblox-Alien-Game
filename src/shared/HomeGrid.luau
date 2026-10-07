--!strict
-- ReplicatedStorage.Shared.HomeGrid: pure house-grid maths shared by the server and renderer.
-- Cell indices are zero-based; footprint ranges are inclusive. No placement policy lives here.
local HomeGrid = {}
export type Footprint = { x0: number, z0: number, x1: number, z1: number }
type ItemSize = { cellsX: number, cellsZ: number }

function HomeGrid.Dimensions(item: ItemSize, rotation: number): (number, number)
	if rotation % 2 == 1 then
		return item.cellsZ, item.cellsX
	end
	return item.cellsX, item.cellsZ
end

function HomeGrid.Footprint(item: ItemSize, cellX: number, cellZ: number, rotation: number): Footprint
	local width, depth = HomeGrid.Dimensions(item, rotation)
	return { x0 = cellX, z0 = cellZ, x1 = cellX + width - 1, z1 = cellZ + depth - 1 }
end

function HomeGrid.Overlaps(a: Footprint, b: Footprint): boolean
	return a.x0 <= b.x1 and b.x0 <= a.x1 and a.z0 <= b.z1 and b.z0 <= a.z1
end

function HomeGrid.InsidePlot(f: Footprint, cells: number): boolean
	return f.x0 >= 0 and f.z0 >= 0 and f.x1 <= cells - 1 and f.z1 <= cells - 1
end

-- The caller transforms a world point into plot-local coordinates; height is irrelevant.
-- Use the actual plot size and the configured cell width, exactly as the renderer does.
function HomeGrid.CellAt(cells: number, studs: number, sizeX: number, sizeZ: number, localX: number, localZ: number): (number?, number?)
	local x = (localX + sizeX / 2) / studs
	local z = (localZ + sizeZ / 2) / studs
	if x < 0 or z < 0 then
		return nil, nil
	end
	local cellX, cellZ = math.floor(x), math.floor(z)
	if cellX >= cells or cellZ >= cells then
		return nil, nil
	end
	return cellX, cellZ
end

return HomeGrid
