local util = require("util.util")

local input_path = "day06/input.txt"
local raw_input = util.input_to_grid(input_path)
local rows = #raw_input
local columns = #raw_input[1]
local result = 0

local function get_column(grid, col)
	local column = {}
	for r = 1, rows do
		column[#column + 1] = grid[r][col]
	end
	return table.concat(column)
end

local function compute(operands, operator)
	if operator == "+" then
		local sum = 0
		for _, v in ipairs(operands) do
			sum = sum + v
		end
		return sum
	elseif operator == "*" then
		local prod = 1
		for _, v in ipairs(operands) do
			prod = prod * v
		end
		return prod
	end
end

local operands = {}
local operator = ""
local problem = 0
for c = columns, 1, -1 do
	local column = get_column(raw_input, c)
	column = util.strip(column)
	if column ~= "" then
		local operand = tonumber(column:match("%d+"))
		operator = column:match("[%+%*]")
		operands[#operands + 1] = operand
		if operator then
			problem = compute(operands, operator)
			result = result + problem
			operands = {}
			operator = ""
			problem = 0
		end
	end
end

print(result)
