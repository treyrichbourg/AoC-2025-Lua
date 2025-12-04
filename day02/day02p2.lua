local util = require("util.util")
local total_invalid = 0

for line in util.lines("day02/input.txt") do
	for part in line:gmatch("([^,]+)") do
		local first, last = part:match("(%d+)-(%d+)")
		for i = first, last do
			local n = tostring(i)
			for j = 1, math.floor(#n / 2) do
				local prefix = n:sub(1, j)
				local repeated = prefix:rep(math.floor(#n / j))
				-- only match n once then break
				if repeated == n then
					total_invalid = total_invalid + tonumber(repeated)
					break
				end
			end
		end
	end
end

print(total_invalid)
