local util = require("util.util")

local result = 0
for line in util.lines("day03/input.txt") do
	local batteries = {}
	local maxLength = 12

	for i = 1, #line do
		local v = tonumber(line:sub(i, i), 10)
		local remaining = #line - i
		while #batteries > 0 and batteries[#batteries] < v and #batteries + remaining >= maxLength do
			table.remove(batteries)
		end
		if #batteries < maxLength then
			batteries[#batteries + 1] = v
		end
	end
	result = result + table.concat(batteries)
end

print(string.format("%.0f", result))
