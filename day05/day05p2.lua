local util = require("util.util")
local s = os.clock()

local db_ranges = {}
local result = 0

for line in util.lines("day05/input.txt") do
	local first, last = line:match("(%d+)-(%d+)")
	if first and last then
		db_ranges[#db_ranges + 1] = { tonumber(first), tonumber(last) }
	end
end

table.sort(db_ranges, function(a, b)
	return a[1] < b[1]
end)

local function merge_ranges(ranges)
	local merged_ranges = {}
	local curr = ranges[1]
	for r = 2, #ranges do
		if ranges[r][1] > curr[2] then
			merged_ranges[#merged_ranges + 1] = curr
			curr = ranges[r]
		else
			curr[2] = math.max(curr[2], ranges[r][2])
		end
	end
	merged_ranges[#merged_ranges + 1] = curr
	return merged_ranges
end

local merged_ranges = merge_ranges(db_ranges)

for r = 1, #merged_ranges do
	local start, last = merged_ranges[r][1], merged_ranges[r][2]
	result = (result + last - start) + 1
end

local f = os.clock()
print(string.format("Time: %.6f", f - s))
print(string.format("%.0f", result))
