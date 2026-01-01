local util = require("util.util")

local start = os.clock()
local path = "day11/input.txt"
local memo = {}

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

local function recursive_dfs(input, node, required)
	table.sort(required)
	local key = node .. table.concat(required, ",")

	if memo[key] then
		return memo[key]
	end

	local d = "out"

	if node == d then
		if #required == 0 then
			return 1
		else
			return 0
		end
	end

	local count = 0

	for _, next in ipairs(input[node]) do
		local required_copy = {}
		for _, r in ipairs(required) do
			if r ~= next then
				required_copy[#required_copy + 1] = r
			end
		end
		count = count + recursive_dfs(input, next, required_copy)
	end

	memo[key] = count
	return count
end

local input = get_input(path)
local result = recursive_dfs(input, "svr", { "fft", "dac" })

local stop = os.clock()
print(string.format("%.0f", result))
print(string.format("Time: %.6f", stop - start))
