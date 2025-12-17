local util = require("util.util")
local path = "day09/input.txt"
local start = os.clock()

local result = 0
local lo = math.min
local hi = math.max

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
			for y = lo(a.y, b.y), hi(a.y, b.y) do
				grid[y][a.x] = "#"
			end
		elseif a.y == b.y then
			for x = lo(a.x, b.x), hi(a.x, b.x) do
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
				for i = x - 1, 1, -1 do
					local curr = grid[y][i]
					if curr == "#" then
						local up = (y > 1) and grid[y - 1][i] or "."
						local down = (y < #grid) and grid[y + 1][i] or "."
						if up == "#" and down == "#" then
							hits = hits + 1
						end
					end
				end
				if (hits % 2) == 1 then
					return { x = x, y = y }
				end
			end
		end
	end
end

-- simple DFS
local function flood_fill(grid, inner)
	local table_remove = table.remove
	local w = #grid[1]
	local h = #grid
	local dirs = { { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 1, y = 0 }, { x = 0, y = -1 } }
	if grid[inner.y][inner.x] == "#" then
		return
	end
	local queue = { inner }
	while #queue > 0 do
		local curr = table_remove(queue)
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

-- build prefix sum of grid
-- converts grid to 0/1 and creates a sum for each
-- coordinate using sum of left/up/itself
local function make_prefix(grid)
	local prefix = {}
	local h, w = #grid, #grid[1]
	for y = 1, h do
		prefix[y] = {}
		for x = 1, w do
			local val = (grid[y][x] == "#") and 1 or 0
			local up = (y > 1) and prefix[y - 1][x] or 0
			local left = (x > 1) and prefix[y][x - 1] or 0
			local diag = (y > 1 and x > 1) and prefix[y - 1][x - 1] or 0
			prefix[y][x] = val + up + left - diag -- remove top left because it is added twice implicitly
		end
	end
	return prefix
end

-- original brute force check
local function check_bounds(grid, a, b)
	for y = lo(a.y, b.y), hi(a.y, b.y) do
		for x = lo(a.x, b.x), hi(a.x, b.x) do
			if grid[y][x] == "." then
				return false
			end
		end
	end
	return true
end

-- prefix sum is way faster
local function check_bounds_prefix(prefix, a, b)
	local y1, y2 = lo(a.y, b.y), hi(a.y, b.y)
	local x1, x2 = lo(a.x, b.x), hi(a.x, b.x)
	local total = prefix[y2][x2]
		- ((y1 > 1) and prefix[y1 - 1][x2] or 0) -- subject rows above check
		- ((x1 > 1) and prefix[y2][x1 - 1] or 0) -- subject columns to the left
		+ ((y1 > 1 and x1 > 1) and prefix[y1 - 1][x1 - 1] or 0) -- previous 2 removes top-left twice so we add it back
	local area = (x2 - x1 + 1) * (y2 - y1 + 1)
	return total == area
end

local tiles = parse(path)
-- used this for grid size on example before compression
-- local w = 0
-- local h = 0
-- for _, t in ipairs(tiles) do
-- 	if t.x > w then
-- 		w = t.x
-- 	end
-- 	if t.y > h then
-- 		h = t.y
-- 	end
-- end

local squished = compress(tiles)

local grid = make_grid(#squished.x_list, #squished.y_list)
rasterize(grid, squished.tiles)
local inner = raycast(grid)
flood_fill(grid, inner)
for i in ipairs(grid) do
	io.write(table.concat(grid[i]), "\n")
end
print(inner.x, inner.y)
local prefix = make_prefix(grid)

for i = 1, #tiles do
	for j = i + 1, #tiles do
		local a = { x = squished.x_map[tiles[i].x], y = squished.y_map[tiles[i].y] }
		local b = { x = squished.x_map[tiles[j].x], y = squished.y_map[tiles[j].y] }
		if check_bounds_prefix(prefix, a, b) then
			local width = math.abs(tiles[i].x - tiles[j].x) + 1
			local height = math.abs(tiles[i].y - tiles[j].y) + 1
			local area = width * height
			if area > result then
				result = area
			end
		end
	end
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
