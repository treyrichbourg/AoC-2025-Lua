-- util.lua

local util = {}

-- return input as a table with a row of lines
function util.input_to_table(path)
	local f = io.open(path)
	if not f then
		error("Failed to open file at: " .. path)
	end

	local lines = {}
	for line in f:lines() do
		lines[#lines + 1] = line
	end

	f:close()
	return lines
end

-- wrapper for LSP support on io.lines()
---@return fun(): string
function util.lines(path)
	return io.lines(path)
end

-- return input as a grid
function util.input_to_grid(path)
	local grid = {}
	local sub = string.sub
	for line in io.lines(path) do
		local row = {}
		for i = 1, #line do
			row[i] = sub(line, i, i)
		end
		grid[#grid + 1] = row
	end
	return grid
end

-- return input as a grid with whitespace replaced by 0s
function util.input_to_grid_fill_zeroes(path)
	local grid = {}
	local sub = string.sub
	for line in io.lines(path) do
		local row = {}
		line = line:gsub("%s", "0")
		for i = 1, #line do
			row[i] = sub(line, i, i)
		end
		grid[#grid + 1] = row
	end
	return grid
end

-- return input as a table where rows are whitespace delimited
function util.input_to_table_space(path)
	local grid = {}
	local lines = io.lines
	local gmatch = string.gmatch
	for line in lines(path) do
		local row = {}
		for group in gmatch(line, "%S+") do
			row[#row + 1] = group
		end
		grid[#grid + 1] = row
	end
	return grid
end

-- transpose table like a grid matrix
function util.transpose_table(table)
	local rows = #table
	local columns = #table[1]
	local transposed = {}
	for c = 1, columns do
		transposed[c] = {}
		for r = 1, rows do
			transposed[c][r] = table[r][c]
		end
	end
	return transposed
end

function util.init_visited(grid)
	local visited_table = {}
	local rows = #grid
	local columns = #grid[1]
	for r = 1, rows do
		visited_table[r] = {}
		for c = 1, columns do
			visited_table[r][c] = false
		end
	end
	return visited_table
end

function util.Set(list)
	local set = {}
	for _, v in ipairs(list) do
		set[v] = true
	end
	return set
end

function util.strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

-- check if grid coord is in bounds of grid
function util.in_bounds(r, c, max_r, max_c)
	return r >= 1 and r <= max_r and c >= 1 and c <= max_c
end

function util.split(s, d)
	local parts = {}
	for part in s:gmatch("([^" .. d .. "]+)") do
		parts[#parts + 1] = part
	end
	return parts
end

function util.strip_outer(s)
	return s:sub(2, -2)
end

function util.to_positive(i)
	return i < 0 and -i or i
end

function util.gcd(a, b)
	while b ~= 0 do
		a, b = b, a % b
	end
	return math.abs(a)
end

function util.get_lcm(a, b)
	local g = util.gcd(a, b)
	return math.abs(a) / g * math.abs(b)
end

function util.mod(a, m)
	return ((a % m) + m) % m
end

function util.idiv(a, b)
	if (a * b) >= 0 then
		return math.floor(a / b)
	else
		return math.ceil(a / b)
	end
end

return util
