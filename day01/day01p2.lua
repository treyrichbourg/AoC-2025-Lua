local util = require("util.util")
local pos = 50
local zro_hits = 0

-- smooth brain :(
local function spin(dir, num)
	for _ = 1, num do
		pos = pos + (dir == "R" and 1 or -1)
		if dir == "R" and pos > 99 then
			pos = 0
		end
		if dir == "L" and pos < 0 then
			pos = 99
		end
		if pos == 0 then
			zro_hits = zro_hits + 1
		end
	end
end

local function spin_faster(dir, num)
	num = tonumber(num)
	local dir_num = dir == "R" and 1 or -1
	local raw_pos = pos + dir_num * num
	-- use math.abs to normalize the negative positions
	zro_hits = zro_hits + math.floor(math.abs(raw_pos / 100))
	if dir == "L" then
		if pos ~= 0 and pos <= num then
			zro_hits = zro_hits + 1
		end
	end
	pos = raw_pos % 100
end

for line in util.lines("day01/input.txt") do
	local dir, num = line:match("([LR])(%d+)")
	spin(dir, num)
end

print("for loop: " .. zro_hits)
pos = 50
zro_hits = 0

for line in util.lines("day01/input.txt") do
	local dir, num = line:match("([LR])(%d+)")
	spin_faster(dir, num)
end

print("floor: " .. zro_hits)
