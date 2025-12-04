local util = require("util.util")
local total_invalid = 0

for line in util.lines("day02/input.txt") do
	for part in line:gmatch("([^,]+)") do
		local first, last = part:match("(%d+)-(%d+)")
		for i = first, last do
			local n = tostring(i)
			local len = #n
			if len % 2 == 0 and n:sub(1, len / 2) == n:sub(len / 2 + 1) then
				total_invalid = total_invalid + tonumber(n)
			end
		end
	end
end

print(total_invalid)
