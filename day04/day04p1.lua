local util = require("util.util")

local grid = util.input_to_grid("day04/input.txt")

local dr = { -1, -1, -1, 0, 1, 1, 1, 0 }
local dc = { -1, 0, 1, 1, 1, 0, -1, -1 }

local rows = #grid
local columns = #grid[1]
local result = 0

for r = 1, rows do
	for c = 1, columns do
		local adjacent_rolls = 0
		local coord = grid[r][c]
		for i = 1, 8 do
			local ar = r + dr[i]
			local ac = c + dc[i]
			if ar >= 1 and ar <= rows and ac >= 1 and ac <= columns then
				if grid[ar][ac] == "@" then
					adjacent_rolls = adjacent_rolls + 1
				end
			end
		end
		if adjacent_rolls < 4 and coord ~= "." then
			result = result + 1
		end
	end
end

print(result)
