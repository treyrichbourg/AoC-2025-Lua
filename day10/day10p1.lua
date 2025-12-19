local util = require("util.util")

local start = os.clock()
local path = "day10/input.txt"
local result = 0

local strip_outer = util.strip_outer
local table_remove = table.remove
local to_number = tonumber

local function get_input(p)
	local input = {}
	for line in util.lines(p) do
		local buttons = {}
		local l, btns, js = line:match("(%b[])%s*(.-)%s*(%b{})")
		for b in btns:gmatch("%b()") do
			local nums = {}
			for n in strip_outer(b):gmatch("%d+") do
				nums[#nums + 1] = to_number(n) + 1
			end
			buttons[#buttons + 1] = nums
		end
		l, js = strip_outer(l), strip_outer(js)
		input[#input + 1] = { lights = l, buttons = buttons, joltages = js }
	end
	return input
end

local function convert_lights(lights)
	local desired_state = {}
	local start_state = {}
	for i = 1, #lights do
		local c = lights:sub(i, i)
		desired_state[i] = c == "#" and 1 or 0
		start_state[i] = 0
	end
	return desired_state, start_state
end

local function to_binary(state)
	local num = 0
	for i = 1, #state do
		num = num * 2 + state[i]
	end
	return num
end

local function bfs_bb(row)
	local desired, s = convert_lights(row.lights)
	local start_state = { state = s, d = 0 }
	desired = to_binary(desired)
	local buttons = row.buttons
	local queue = { start_state }
	local visited = {}
	while #queue > 0 do
		local curr = table_remove(queue, 1)
		local curr_state, d = curr.state, curr.d
		local n = to_binary(curr_state)
		if n == desired then
			result = result + d
			return
		end
		if not visited[n] then
			visited[n] = true
			for b = 1, #buttons do
				local new_state = {}
				for i = 1, #curr_state do
					new_state[i] = curr_state[i]
				end
				for j = 1, #buttons[b] do
					local index = buttons[b][j]
					new_state[index] = 1 - new_state[index]
					queue[#queue + 1] = { state = new_state, d = d + 1 }
				end
			end
		end
	end
end

local input = get_input(path)
-- math hurts my head, trying BFS
for _, row in ipairs(input) do
	bfs_bb(row)
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
