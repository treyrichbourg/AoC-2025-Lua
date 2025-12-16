local util = require("util.util")
local path = "day09/example.txt"
local start = os.clock()

local result = 0

local function parse(p)
	local tiles = {}
	for line in util.lines(p) do
		local x, y = line:match("(%d+),(%d+)")
		x, y = tonumber(x), tonumber(y)
		tiles[#tiles + 1] = { x = x, y = y }
	end
	return tiles
end

-- 2d compression is crazy
local function compress(tiles)
	local x_set, y_set = {}, {}
	for _, t in ipairs(tiles) do
		x_set[t.x] = true
		y_set[t.y] = true
	end

	local x_list, y_list = {}, {}
	for x in pairs(x_set) do
		x_list[#x_list + 1] = x
	end
	for y in pairs(y_set) do
		y_list[#y_list + 1] = y
	end
	table.sort(x_list)
	table.sort(y_list)

	local x_map, y_map = {}, {}
	for i, x in ipairs(x_list) do
		x_map[x] = i
	end
	for i, y in ipairs(y_list) do
		y_map[y] = i
	end

	local compressed = {}
	for _, t in ipairs(tiles) do
		compressed[#compressed + 1] = {
			x = x_map[t.x],
			y = y_map[t.y],
		}
	end

	return {
		tiles = compressed,
		x_list = x_list,
		y_list = y_list,
		x_map = x_map,
		y_map = y_map,
	}
end

local function make_grid(w, h)
	local grid = {}
	for y = 1, h do
		grid[y] = {}
		for x = 1, w do
			grid[y][x] = "."
		end
	end
	return grid
end

local function rasterize(grid, tiles)
	for i = 1, #tiles do
		local a = tiles[i]
		local b = tiles[i % #tiles + 1]
		if a.x == b.x then
			for y = math.min(a.y, b.y), math.max(a.y, b.y) do
				grid[y][a.x] = "#"
			end
		elseif a.y == b.y then
			for x = math.min(a.x, b.x), math.max(a.x, b.x) do
				grid[a.y][x] = "#"
			end
		end
	end
end

-- 1 index made this harder than it should have been...
local function raycast(grid)
	for y = 1, #grid do
		for x = 1, #grid[1] do
			if grid[y][x] == "." then
				local hits = 0
				local prev = "."
				for i = x, 1, -1 do
					local curr = grid[y][i]
					if prev == "." and curr ~= prev then
						hits = hits + 1
					end
					prev = curr
				end
				if (hits % 2) == 1 then
					return { x = x, y = y }
				end
			end
		end
	end
end

-- simple bfs
local function flood_fill(grid, inner)
	local w = #grid[1]
	local h = #grid
	local dirs = { { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 1, y = 0 }, { x = 0, y = -1 } }
	if grid[inner.y][inner.x] == "#" then
		return
	end
	local queue = { inner }
	while #queue > 0 do
		local curr = table.remove(queue, 1)
		for i = 1, #dirs do
			local nr = curr.y + dirs[i].y
			local nc = curr.x + dirs[i].x
			if util.in_bounds(nr, nc, h, w) then
				if grid[nr][nc] == "." then
					grid[nr][nc] = "#"
					queue[#queue + 1] = { x = nc, y = nr }
				end
			end
		end
	end
end

local tiles = parse(path)
local w = 0
local h = 0
for _, t in ipairs(tiles) do
	if t.x > w then
		w = t.x
	end
	if t.y > h then
		h = t.y
	end
end
local grid = make_grid(w, h)
rasterize(grid, tiles)
local inner = raycast(grid)
flood_fill(grid, inner)
for i in ipairs(grid) do
	print(table.concat(grid[i]))
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

local stop = os.clock()
print(string.format("Time: %.6f", stop - start))
