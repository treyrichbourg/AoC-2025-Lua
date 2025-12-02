-- util.lua

local util = {}

-- return input as a table
function util.read_lines(path)
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

return util
