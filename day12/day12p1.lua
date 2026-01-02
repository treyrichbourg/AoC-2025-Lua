local util = require("util.util")
local start = os.clock()

local path = "day12/input.txt"

local function get_input(p)
	local presents = {}
	local present = {}
	local regions = {}
	local index

	for line in util.lines(p) do
		local idx = line:match("^(%d):$")
		if idx then
			index = tonumber(idx) + 1
			presents[index] = {}
		elseif line:match("^[#.][#.][#.]$") then
			local row = {}
			for c in line:gmatch("([#.])") do
				row[#row + 1] = c
			end
			present[#present + 1] = row
			if #present == 3 then
				presents[index] = present
				present = {}
			end
		elseif line:match("%S+") then
			local w, h, rest = line:match("^(%d+)x(%d+):%s+(.*)$")
			local area = tonumber(w) * tonumber(h)
			local pi = {}
			for d in rest:gmatch("%d+") do
				pi[#pi + 1] = tonumber(d)
			end

			regions[#regions + 1] = { area = area, pi = pi }
		end
	end
	return presents, regions
end

local function get_present_area(presents)
	local new_presents = {}
	for k, v in pairs(presents) do
		local area = 0
		for r = 1, #v do
			for c = 1, #v[1] do
				if v[r][c] == "#" then
					area = area + 1
				end
			end
		end
		new_presents[k] = area
	end
	return new_presents
end

local function solve(presents, regions)
	local result = 0
	for i = 1, #regions do
		local region = regions[i]
		local area = 0
		for j = 1, #region.pi do
			area = area + (presents[j] * region.pi[j])
		end
		if area <= region.area then
			result = result + 1
		end
	end
	return result
end

local presents, regions = get_input(path)
presents = get_present_area(presents)
local result = solve(presents, regions)

local stop = os.clock()
print(string.format("Result: %d", result))
print(string.format("Time: %.6f", stop - start))
