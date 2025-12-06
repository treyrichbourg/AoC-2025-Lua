-- util.lua

local util = {}

-- return input as a table
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

return util
