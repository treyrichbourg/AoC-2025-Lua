local util = require("util.util")
local pos = 50
local zro = 0

local function spin(dir, num)
	pos = dir == "R" and (pos + num) or (pos - num)
	pos = pos % 100
	if pos == 0 then
		zro = zro + 1
	end
end

for line in util.lines("day01/input.txt") do
	local dir, num = line:match("([LR])(%d+)")
	spin(dir, num)
end

print(zro)
