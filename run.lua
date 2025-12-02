local day = arg[1]
local part = arg[2]

if not day or not part then
	print("Usage: lua run.lua <day> <part>")
	os.exit(1)
end

local path = string.format("day%02d/day%02dp%s.lua", tonumber(day), tonumber(day), part)
print("Running:", path)
dofile(path)
