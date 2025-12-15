local util = require("util.util")
local path = "day09/example.txt"
local start = os.clock()

local result = 0

-- 2d compression is crazy
local function setup(p)
	local tiles = {}
	local x_set = {}
	local x_list = {}
	local x_map = {}
	local y_set = {}
	local y_list = {}
	local y_map = {}
	local grid = {}
	local compressed_tiles = {}
	for line in util.lines(p) do
		local x, y = line:match("(%d+),(%d+)")
		x, y = tonumber(x), tonumber(y)
		tiles[#tiles + 1] = { x = x, y = y }
		if x and y then
			x_set[x] = true
			y_set[y] = true
		end
	end

	for x in pairs(x_set) do
		x_list[#x_list + 1] = x
	end

	for y in pairs(y_set) do
		y_list[#y_list + 1] = y
	end
	table.sort(x_list)
	table.sort(y_list)

	for i, x in ipairs(x_list) do
		x_map[x] = i
	end

	for i, y in ipairs(y_list) do
		y_map[y] = i
	end

	for y = 1, #y_list do
		grid[y] = {}
		for x = 1, #x_list do
			grid[y][x] = "."
		end
	end

	for _, t in ipairs(tiles) do
		local cx = x_map[t.x]
		local cy = y_map[t.y]
		grid[cy][cx] = "#"
		compressed_tiles[#compressed_tiles + 1] = { x = cx, y = cy }
	end

	for i in ipairs(grid) do
		print(table.concat(grid[i]))
	end
end

-- for i = 1, #tiles do
-- 	for j = i + 1, #tiles do
-- 		local tile1 = tiles[i]
-- 		local tile2 = tiles[j]
-- 		if check_interior(tile1, tile2) then
-- 			local width = math.abs(tile2.x - tile1.x) + 1
-- 			local height = math.abs(tile2.y - tile1.y) + 1
-- 			local area = width * height
-- 			if area > result then
-- 				result = area
-- 			end
-- 		end
-- 	end
-- end

setup(path)
local stop = os.clock()
-- print(result)
print(string.format("Time: %.6f", stop - start))
