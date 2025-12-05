local util = require("util.util")

local result = 0

for line in util.lines("day03/input.txt") do
	local highest, highest_index, second_highest = 0, 0, 0
	for i = 1, #line do
		local v = tonumber(line:sub(i, i), 10)
		if v > highest and i ~= #line then
			highest = v
			highest_index = i
			second_highest = 0
		elseif i > highest_index and v > second_highest then
			second_highest = v
		end
	end
	result = result + (highest * 10 + second_highest)
end

print(result)
