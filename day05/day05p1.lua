local util = require("util.util")

local function parse_data(path)
	local db_ranges = {}
	local ingredients = {}
	for line in util.lines(path) do
		local first, last = line:match("(%d+)-(%d+)")
		if first and last then
			db_ranges[#db_ranges + 1] = { tonumber(first), tonumber(last) }
		end
		local ingredient = line:match("^%d+$")
		if ingredient then
			ingredients[#ingredients + 1] = ingredient
		end
	end
	return db_ranges, ingredients
end

local function fresh_fruit_for_rotting_vegetables(ranges, ingredients)
	local count = 0
	for i = 1, #ingredients do
		local ing = tonumber(ingredients[i])
		for _, r in ipairs(ranges) do
			if ing >= r[1] and ing <= r[2] then
				count = count + 1
				break
			end
		end
	end
	return count
end

local db_ranges, ingredients = parse_data("day05/input.txt")
local result = fresh_fruit_for_rotting_vegetables(db_ranges, ingredients)

print(result)
