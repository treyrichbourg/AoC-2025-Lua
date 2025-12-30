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
local path = "day10/example.txt"
local result = 0

local strip_outer = util.strip_outer
local get_lcm = util.get_lcm
local to_positive = util.to_positive
local to_number = tonumber
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local min = math.min
local max = math.max

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
	local limit_row = {}
	for c = 1, columns do
		local limit = math.huge
		for _, r in ipairs(input.buttons[c]) do
			limit = min(limit, input.joltages[r])
		end
		limit_row[c] = limit
	end
	A[rows + 1] = limit_row

	-- total row/col indexes including rhs and mod
	local rhs_c = #A[1]
	local limit_r = #A

	local rank = 1
	local last = columns
	while rank < rows and rank < last do
		local pivot = nil
		local min_abs = math.huge
		for r = rank, rows do
			local v = A[r][rank]
			if v ~= 0 and abs(v) < min_abs then
				min_abs = abs(v)
				pivot = r
			end
		end

		if pivot then
			swap_rows(A, rank, pivot)
			local pv = A[rank][rank]
			-- pivot must be positive, need to apply to
			-- entire row + rhs
			if pv < 0 then
				for c = rank, rhs_c do
					A[rank][c] = to_positive(A[rank][c])
				end
				pv = -pv
			end

			for r = 1, rows do
				if r ~= rank then
					local coeff = A[r][rank]
					if coeff ~= 0 then
						print(coeff)
						print(pv)
						local l = abs(coeff)
						local lcm = get_lcm(l, pv)
						local m = util.idiv(lcm, l)
						local n = util.idiv(lcm / pivot * (coeff >= 0 and 1 or -1), 1)

						for c = 1, rhs_c do
							A[r][c] = m * A[r][c] - n * A[rank][c]
						end
					end
				end
			end
			rank = rank + 1
		else
			-- column permutation
			last = last - 1
			for r = 1, limit_r do
				A[r][rank], A[r][last + 1] = A[r][last + 1], A[r][rank]
			end
		end
	end

	-- get lcm for pivots and scale
	local L = 1
	for p = 1, rank do
		L = get_lcm(L, abs(A[p][p]))
	end

	for p = 1, rank do
		local q = L / A[p][p]
		for c = rank, rhs_c do
			A[p][c] = A[p][c] * q
		end
	end

	-- free variables
	local nullity = columns - rank

	local rhs = {}
	for r = 1, rows do
		rhs[r] = A[r][rhs_c]
	end

	-- Basis vector handles free variable permutation much cleaner
	-- than my previous column_perm {}.
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
		local cost = L - sum
		basis[#basis + 1] = {
			limit = limit,
			cost = cost,
			coeffs = coeffs,
		}
	end

	io.write("\n")
	for r = 1, limit_r do
		io.write("Row: ", r, " ", table.concat(A[r]), "\n")
	end
	return {
		rank = rank,
		nullity = nullity,
		lcm = L,
		rhs = rhs,
		basis = basis,
	}
end

-- Using recursive dfs to brute force solutions using constraints
-- set by free variables after the HNF style elimination.
---@param subspace Subspace
---@param rhs number[]
---@param remaining number[]
---@param pivot_total number
local function recursive_dfs(subspace, rhs, remaining, pivot_total)
	local rank = subspace.rank
	local temp_rhs = {}
	for i = 1, #rhs do
		temp_rhs[i] = rhs[i]
	end

	-- adjust any negative free_var coefficients
	for _, i in ipairs(remaining) do
		local free_var = subspace.basis[i]
		for r = 1, rank do
			local v = free_var.coeffs[r]
			if v < 0 then
				temp_rhs[r] = temp_rhs[r] - v * free_var.limit
			end
		end
	end

	-- using limit row to set upper/lower bounds where before I just set
	-- arbitrarily high values to initialize.
	local min_size, min_index, global_lower, global_upper = math.huge, nil, 0, 0
	for _, i in ipairs(remaining) do
		local free_var = subspace.basis[i]
		local lower, upper = 0, free_var.limit
		for r = 1, rank do
			local v = free_var.coeffs[r]
			local rhs_v = temp_rhs[r]
			if v > 0 then
				upper = min(upper, floor(rhs_v / v))
			elseif v < 0 then
				lower = max(lower, ceil((rhs_v + v * free_var.limit + v + 1) / v))
			end
		end
		if upper >= lower then
			local size = upper - lower + 1
			if size > 0 and size < min_size then
				min_size, min_index, global_lower, global_upper = size, i, lower, upper
			end
		end
	end

	if not min_index then
		print("failing on min_index")
		return nil
	end

	-- adjust remaining and recurse until solved
	local new_remaining = {}
	for _, i in ipairs(remaining) do
		if i ~= min_index then
			new_remaining[#new_remaining + 1] = i
		end
	end

	local free_var = subspace.basis[min_index]
	local coeffs, cost, lcm = free_var.coeffs, free_var.cost, subspace.lcm
	if #new_remaining > 0 then
		--local adjusted_rhs = {}
		--for r=1, rank do
		--  adjusted_rhs[r] = temp_rhs[r] - (global_lower - 1) * coeffs[r]
		--end
		for r = 1, rank do
			temp_rhs[r] = temp_rhs[r] - (global_lower - 1) * coeffs[r]
		end
		local best = math.huge
		for n = global_lower, global_upper do
			local next_rhs = {}
			for r = 1, rank do
				next_rhs[r] = temp_rhs[r] - n * coeffs[r]
			end
			local res = recursive_dfs(subspace, next_rhs, new_remaining, pivot_total + n * cost)
			if res and res < best then
				best = res
			end
		end
		if best == math.huge then
			print("failing on best")
			return nil
		end
		return best
	else
		local iter, step
		if cost >= 0 then
			iter, step = global_lower, 1
		else
			iter, step = global_upper, -1
		end
		local bound = cost >= 0 and global_upper or global_lower
		while (step > 0 and iter <= bound) or (step < 0 and iter >= bound) do
			local ok = true
			for r = 1, rank do
				if (temp_rhs[r] - iter * coeffs[r]) % lcm ~= 0 then
					ok = false
					break
				end
			end
			if ok then
				return (pivot_total + iter * cost) / lcm
			end
			iter = iter + step
		end
		return nil
	end
	-- for n = global_lower, global_upper do
	-- 	local ok = true
	-- 	for r = 1, rank do
	-- 		if util.mod(temp_rhs[r] - n * coeffs[r], lcm) ~= 0 then
	-- 			ok = false
	-- 			break
	-- 		end
	-- 	end
	-- 	if ok then
	-- 		return (pivot_total + n * cost) / lcm
	-- 	end
	-- end
	-- print("failing on else")
	-- return nil
end

---@param subspace Subspace
local function solve(subspace)
	local rank = subspace.rank
	local nullity = subspace.nullity
	local lcm = subspace.lcm
	local rhs = subspace.rhs
	local pivot_total = 0
	for i = 1, rank do
		pivot_total = pivot_total + rhs[i]
	end

	-- No free vars = fully determined system. Since we LCM
	-- scaled rhs + pivot rows this is easy.
	if nullity == 0 then
		return pivot_total / lcm
	else
		local remaining = {}
		for i = 1, #subspace.basis do
			remaining[i] = i
		end
		return recursive_dfs(subspace, rhs, remaining, pivot_total)
	end
end

local input = get_input(path)
for k, r in ipairs(input) do
	io.write(string.format("Row: %d Buttons: ", k))
	for _, b in ipairs(r.buttons) do
		io.write("(" .. table.concat(b, ",") .. ") ")
	end
	io.write(" Joltages: ")
	for j = 1, #r.joltages do
		io.write(r.joltages[j])
		if j < #r.joltages then
			io.write(",")
		else
			io.write("\n")
		end
	end
	io.write("\n")
end

for _, row in ipairs(input) do
	local subspace = eliminate(row)
	result = result + solve(subspace)
	-- local A = get_A(row)
	-- local b = row.joltages
	-- for r = 1, #A do
	-- 	io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	-- end

	-- io.write("\nPivot Rows: ")
	-- for r = 1, #pivot_rows do
	-- 	io.write(pivot_rows[r])
	-- 	if r < #pivot_rows then
	-- 		io.write(",")
	-- 	end
	-- end
	-- io.write("\nPivot Columns: ")
	-- for c = 1, #pivot_cols do
	-- 	io.write(pivot_cols[c])
	-- 	if c < #pivot_cols then
	-- 		io.write(",")
	-- 	end
	-- end
	-- io.write("\n", "Free variables: ")
	-- for f = 1, #free_vars do
	-- 	io.write(free_vars[f])
	-- 	if f < #free_vars then
	-- 		io.write(",")
	-- 	end
	-- end
	-- io.write("\n", "---", "\n")
	-- local min_press = solve(A, b, pivot_cols, free_vars)
	-- if not min_press then
	-- 	print(string.format("No result found for row: %d", i))
	-- 	break
	-- end
	-- total_result = total_result + min_press
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
