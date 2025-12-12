local util = require("util.util")

local input = util.input_to_grid("day07/input.txt")
local rows = #input
local columns = #input[1]
local result = 0

local function beam(r, c)
	if util.in_bounds(r, c, rows, columns) then
		input[r][c] = "|"
	end
end

local function process_row(r)
	for c = 1, columns do
		local curr = input[r][c]
		if curr == "S" then
			beam(r + 1, c)
			return
		elseif curr == "|" then
			if not util.in_bounds(r + 1, c, rows, columns) then
				return
			end
			if input[r + 1][c] == "^" then
				beam(r + 1, c - 1)
				beam(r + 1, c + 1)
				result = result + 1
			else
				beam(r + 1, c)
			end
		end
	end
end

for r = 1, rows do
	process_row(r)
end

for r = 1, rows do
	print(table.concat(input[r]))
end

print(result)
