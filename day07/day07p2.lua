local util = require("util.util")

local start = os.clock()
local input = util.input_to_grid("day07/input.txt")
local rows = #input
local columns = #input[1]
local result = 0
local result_row = {}

for i = 1, rows do
	result_row[i] = 0
end

local function split(c, curr)
	if c >= 1 and c <= columns then
		result_row[c] = result_row[c] + curr
	end
end

local function process_row(r)
	for c = 1, columns do
		local curr = input[r][c]
		if curr == "S" then
			result_row[c] = 1
		end
		if curr == "^" then
			split(c - 1, result_row[c])
			split(c + 1, result_row[c])
			result_row[c] = 0
		end
	end
end

for r = 1, rows do
	process_row(r)
end

for i = 1, #result_row do
	result = result + result_row[i]
end

local stop = os.clock()

print(result)
print(string.format("Time: %.6f", stop - start))
