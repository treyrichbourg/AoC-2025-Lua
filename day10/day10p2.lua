local util = require("util.util")

---@class BasisV
---@field limit number
---@field cost number
---@field coeffs number[]

---@class Subspace
---@field rank number
---@field nullity number
---@field lcm number
---@field rhs number[]
---@field basis BasisV[]

local start = os.clock()
local path = "day10/input.txt"
local result = 0

local strip_outer = util.strip_outer
local get_lcm = util.get_lcm
local idiv = util.idiv
local to_number = tonumber
local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor
local ceil = math.ceil

local function get_input(p)
	local input = {}
	for line in util.lines(p) do
		local buttons = {}
		local _, btns, js = line:match("(%b[])%s*(.-)%s*(%b{})")
		for b in btns:gmatch("%b()") do
			local nums = {}
			for n in strip_outer(b):gmatch("%d+") do
				nums[#nums + 1] = to_number(n) + 1
			end
			buttons[#buttons + 1] = nums
		end
		js = strip_outer(js)
		local joltages = {}
		for j in js:gmatch("%d+") do
			joltages[#joltages + 1] = to_number(j)
		end
		input[#input + 1] = { buttons = buttons, joltages = joltages }
	end
	return input
end

local function get_A(input)
	local rows = #input.joltages
	local columns = #input.buttons
	local A = {}

	for r = 1, rows do
		A[r] = {}
		for c = 1, columns do
			A[r][c] = 0
		end
	end

	for c, btn in ipairs(input.buttons) do
		for _, r in ipairs(btn) do
			A[r][c] = 1
		end
	end
	return A
end

local function swap_rows(A, i, j)
	A[i], A[j] = A[j], A[i]
end

-- Weird Guassian-ish/HNF-ish style elimination.
-- Keeping everything as integer math but going to
-- permute columns during elimination to help build
-- null space for solving.
---return @Subspace
local function eliminate(input)
	local rows = #input.joltages
	local columns = #input.buttons
	local A = get_A(input)
	local b = input.joltages

	-- append b to A to ensure everything is mutated together. Previously
	-- kept these separate but it was bug prone if I forgot to adjust b
	for r = 1, rows do
		A[r][columns + 1] = b[r]
	end

	-- adding a limit row to the bottom of A to track bounds for free_vars
	-- when I go to recurse later
	local limit_row = {}
	for c = 1, columns do
		local limit = math.huge
		for _, r in ipairs(input.buttons[c]) do
			limit = min(limit, input.joltages[r])
		end
		limit_row[c] = limit
	end
	A[rows + 1] = limit_row

	local rhs_c = columns + 1
	local limit_r = rows + 1
	local rank = 1
	local last = columns

	while rank <= rows and rank <= last do
		local pivot_row = nil
		local min_abs = math.huge

		for r = rank, rows do
			local v = abs(A[r][rank])
			if v ~= 0 and v < min_abs then
				min_abs = v
				pivot_row = r
			end
		end

		if pivot_row then
			swap_rows(A, rank, pivot_row)
			local pv = A[rank][rank]
			-- pivot must be positive, need to apply to
			-- entire row + rhs
			if pv < 0 then
				pv = -pv
				for c = rank, rhs_c do
					A[rank][c] = -A[rank][c]
				end
			end

			for r = 1, rows do
				if r ~= rank then
					local coeff = A[r][rank]
					if coeff ~= 0 then
						local lcm = get_lcm(abs(coeff), pv)
						local m = idiv(lcm, abs(coeff))
						local n = idiv(lcm, pv) * (coeff > 0 and 1 or -1)

						for c = 1, rhs_c do
							A[r][c] = m * A[r][c] - n * A[rank][c]
						end
					end
				end
			end
			rank = rank + 1
		else
			-- column permutation allows my dfs search to just cleanly loop
			-- through rank indexes to solve later
			for r = 1, limit_r do
				A[r][rank], A[r][last] = A[r][last], A[r][rank]
			end
			last = last - 1
		end
	end

	rank = rank - 1
	-- get lcm for pivots and scale
	local L = 1
	for p = 1, rank do
		L = get_lcm(L, abs(A[p][p]))
	end

	for p = 1, rank do
		local q = idiv(L, A[p][p])
		for c = rank + 1, rhs_c do
			A[p][c] = A[p][c] * q
		end
	end

	-- free variables
	local nullity = columns - rank

	local rhs = {}
	for r = 1, rank do
		rhs[r] = A[r][rhs_c]
	end

	-- basis vector handles free variable permutation much cleaner
	-- than my previous column_perm {}
	local basis = {}
	for c = 1, nullity do
		local limit = A[limit_r][rank + c] -- original limit for free variable
		local coeffs = {} -- free_var coefficients per row
		for r = 1, rank do
			coeffs[r] = A[r][rank + c]
		end
		local sum = 0
		for i = 1, rank do
			sum = sum + coeffs[i]
		end
		local cost = L - sum -- affect free_var has on the row solving for b
		basis[#basis + 1] = {
			limit = limit,
			cost = cost,
			coeffs = coeffs,
		}
	end

	return {
		rank = rank,
		nullity = nullity,
		lcm = L,
		rhs = rhs,
		basis = basis,
	}
end

-- using recursive dfs to brute force solutions using constraints
-- set by free variables after the HNF style elimination
---@param subspace Subspace
---@param rhs number[]
---@param remaining number[]
---@param pivot_total number
local function recursive_dfs(subspace, rhs, remaining, pivot_total)
	local rank = subspace.rank

	local buffered_rhs = {}
	for i = 1, rank do
		buffered_rhs[i] = rhs[i]
	end

	-- handle negativity because pain
	for _, i in ipairs(remaining) do
		local b = subspace.basis[i]
		for r = 1, rank do
			local v = b.coeffs[r]
			if v < 0 then
				buffered_rhs[r] = buffered_rhs[r] - (v * b.limit)
			end
		end
	end

	-- set bounds using limit on the basis vector
	local min_size, min_index, global_lower, global_upper = math.huge, nil, 0, 0
	for _, i in ipairs(remaining) do
		local free_var = subspace.basis[i]
		local lower, upper = 0, free_var.limit

		for r = 1, rank do
			local v = free_var.coeffs[r]
			local row_req = buffered_rhs[r] + (v < 0 and (v * free_var.limit) or 0)

			if v > 0 then
				upper = min(upper, floor(row_req / v))
			elseif v < 0 then
				lower = max(lower, ceil(row_req / v))
			end
		end

		local size = upper - lower + 1
		if size > 0 and size < min_size then
			min_size, min_index, global_lower, global_upper = size, i, lower, upper
		end
	end

	if not min_index then
		return nil
	end

	local new_remaining = {}
	for _, i in ipairs(remaining) do
		if i ~= min_index then
			new_remaining[#new_remaining + 1] = i
		end
	end

	local free_var = subspace.basis[min_index]
	local coeffs, cost, lcm = free_var.coeffs, free_var.cost, subspace.lcm
	local best = math.huge

	for n = global_lower, global_upper do
		local next_rhs = {}
		for r = 1, rank do
			next_rhs[r] = rhs[r] - (n * coeffs[r])
		end

		if #new_remaining > 0 then
			local res = recursive_dfs(subspace, next_rhs, new_remaining, pivot_total + n * cost)
			if res and res < best then
				best = res
			end
		else
			local ok = true
			for r = 1, rank do
				if next_rhs[r] % lcm ~= 0 then
					ok = false
					break
				end
			end
			if ok then
				local current_res = (pivot_total + n * cost) / lcm
				if current_res < best then
					best = current_res
				end
			end
		end
	end

	return best ~= math.huge and best or nil
end

---@param subspace Subspace
local function solve(subspace)
	local nullity = subspace.nullity
	local lcm = subspace.lcm
	local rhs = subspace.rhs

	local pivot_total = 0
	for i = 1, #rhs do
		pivot_total = pivot_total + rhs[i]
	end

	if nullity == 0 then
		local res = pivot_total / lcm
		print(string.format("Returning result for problem: %d", result))
		return res
	else
		local remaining = {}
		for i = 1, #subspace.basis do
			remaining[i] = i
		end
		local res = recursive_dfs(subspace, rhs, remaining, pivot_total)
		assert(res, "recursion failed because I'm dumb")
		print(string.format("Returning result for problem: %d", result))
		return res
	end
end

local input = get_input(path)

for i, row in ipairs(input) do
	print(string.format("Processing problem %d", i))
	local subspace = eliminate(row)
	result = result + solve(subspace)
end

local stop = os.clock()
print(string.format("Result: %d", result))
print(string.format("Time: %.6f", stop - start))
