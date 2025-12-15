local util = require("util.util")
local path = "day09/input.txt"
local start = os.clock()

local result = 0
local tiles = {}

for line in util.lines(path) do
	local x, y = line:match("(%d+),(%d+)")
	x, y = tonumber(x), tonumber(y)
	tiles[#tiles + 1] = { x = x, y = y }
end

table.sort(tiles, function(a, b)
	return a.x > b.x
end)

for i = 1, #tiles do
	for j = i + 1, #tiles do
		local tile1 = tiles[i]
		local tile2 = tiles[j]
		local width = math.abs(tile2.x - tile1.x) + 1
		local height = math.abs(tile2.y - tile1.y) + 1
		local area = width * height
		if area > result then
			result = area
		end
	end
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
