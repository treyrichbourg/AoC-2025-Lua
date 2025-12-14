local util = require("util.util")
local path = "day08/input.txt"
local start = os.clock()
local mst = {}

local function distance(a, b)
	return (b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2
end

local coords = {}
for line in util.lines(path) do
	local x, y, z = line:match("(%d+),(%d+),(%d+)")
	coords[#coords + 1] = {
		tonumber(x),
		tonumber(y),
		tonumber(z),
	}
end

local edges = {}
for i = 1, #coords do
	for j = i + 1, #coords do
		edges[#edges + 1] = { i, j, distance(coords[i], coords[j]) }
	end
end
table.sort(edges, function(a, b)
	return a[3] < b[3]
end)

local roots = {}
for i = 1, #coords do
	roots[i] = i
end

local function find_root(i)
	if roots[i] ~= i then
		roots[i] = find_root(roots[i])
	end
	return roots[i]
end

for i = 1, #edges do
	local a, b = edges[i][1], edges[i][2]
	local rootA, rootB = find_root(a), find_root(b)
	if rootA ~= rootB then
		roots[rootB] = rootA
		mst[#mst + 1] = edges[i]
	end
end

local stop = os.clock()
local a, b = mst[#mst][1], mst[#mst][2]
local ax, bx = coords[a][1], coords[b][1]
local cable_length = ax * bx
print(cable_length)
print(string.format("Time: %.6f", stop - start))
