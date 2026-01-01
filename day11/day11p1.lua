local util = require("util.util")

local start = os.clock()
local path = "day11/input.txt"

local function get_input(p)
	local input = {}
	for line in util.lines(p) do
		local iter = line:gmatch("%a%a%a")
		local key = iter()
		local values = {}
		for match in iter do
			values[#values + 1] = match
		end
		input[key] = values
	end
	return input
end

local function bfs(input)
	local d = "out"
	local s = input["you"]
	local queue = { s }
	local paths = 0
	local head = 1
	while head <= #queue do
		local c = queue[head]
		head = head + 1
		for i = 1, #c do
			local n = c[i]
			if n == d then
				paths = paths + 1
			end
			queue[#queue + 1] = input[n]
		end
	end
	return paths
end

local input = get_input(path)

local result = bfs(input)

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
