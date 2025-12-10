local util = require("util.util")

local input_path = "day06/input.txt"

local function invert_table(path)
	local input = util.input_to_table_space(path)
	local rows = #input
	local columns = #input[1]
	local inverted_table = {}
	for c = 1, columns do
		inverted_table[c] = {}
		for r = 1, rows do
			inverted_table[c][r] = input[r][c]
		end
	end
	return inverted_table
end

local cephalopod_math_sheet = invert_table(input_path)

local function do_homework(math_sheet)
	local result = 0
	for r = 1, #math_sheet do
		local row_result = 0
		for c = 1, #math_sheet[r] - 1 do
			local operator = math_sheet[r][#math_sheet[r]]
			local n = tonumber(math_sheet[r][c])
			if operator == "+" then
				row_result = row_result + n
			elseif operator == "*" then
				if c == 1 then
					row_result = 1
				end
				row_result = row_result * n
			end
		end
		result = result + row_result
	end
	return result
end

print(do_homework(cephalopod_math_sheet))
