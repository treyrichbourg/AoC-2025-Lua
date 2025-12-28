local util = require("util.util")

local start = os.clock()
local path = "day10/input.txt"
local result = math.huge
local total_result = 0

local strip_outer = util.strip_outer
local gcd = util.gcd
local lcm = util.lcm
local to_positive = util.to_positive
local to_number = tonumber
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local min = math.min
local max = math.max

-- Hermite Normal Form
-- Ax = b
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

local function swap_rows(A, i, j, b)
	A[i], A[j] = A[j], A[i]
	b[i], b[j] = b[j], b[i]
end

-- used in to_rref which isn't used anymore
-- local function pivot_candidate(A, c, pivot_row)
-- 	local rows = #A
-- 	for r = pivot_row, rows do
-- 		if A[r][c] ~= 0 then
-- 			return r
-- 		end
-- 	end
-- 	return nil
-- end

-- local function pivot_candidate2(A, c, pivot_row, min_abs)
-- 	local rows = #A
-- 	for r = pivot_row, rows do
-- 		if A[r][c] ~= 0 and abs(A[r][c]) < min_abs then
-- 			min_abs = abs(A[r][c])
-- 			return r, min_abs
-- 		end
-- 	end
-- 	return nil, min_abs
-- end

-- Close to Hermite Normal Form except no row above/col right of pivot/b
-- mod math. That would kill the b numbers we need to solve for.
local function hnf(A, b)
	local rows = #A
	local columns = #A[1]
	local pivot_rows = {}
	local pivot_cols = {}
	local free_vars = {}

	local pivot_row = 1
	local pivot_col = 1

	-- find a pivot candidate
	while pivot_row <= rows and pivot_col <= columns do
		local pivot = nil
		local min_abs = math.huge
		-- pivot, min_abs = pivot_candidate(A, pivot_col, pivot_row, min_abs)
		for r = pivot_row, rows do
			local v = A[r][pivot_col]
			if v ~= 0 and abs(v) < min_abs then
				pivot = r
				min_abs = abs(v)
			end
		end

		-- if no pivot in column then we mark those as free variables
		if not pivot then
			free_vars[#free_vars + 1] = pivot_col
			pivot_col = pivot_col + 1
		else
			pivot_cols[#pivot_cols + 1] = pivot_col
			pivot_rows[#pivot_rows + 1] = pivot_row
			swap_rows(A, pivot_row, pivot, b)

			if A[pivot_row][pivot_col] < 0 then
				for c = 1, columns do
					A[pivot_row][c] = to_positive(A[pivot_row][c])
				end
				b[pivot_row] = to_positive(b[pivot_row])
			end

			for r = 1, rows do
				if r ~= pivot_row and A[r][pivot_col] ~= 0 then
					local g = gcd(A[r][pivot_col], A[pivot_row][pivot_col])
					local m = A[r][pivot_col] / g
					local n = A[pivot_row][pivot_col] / g

					for c = 1, columns do
						A[r][c] = n * A[r][c] - m * A[pivot_row][c]
					end
					b[r] = n * b[r] - m * b[pivot_row]
				end
			end

			pivot_row = pivot_row + 1
			pivot_col = pivot_col + 1
		end
	end
	for c = pivot_col, columns do
		free_vars[#free_vars + 1] = c
	end

	return pivot_rows, pivot_cols, free_vars
end

-- This works but isn't true HNR. I'm doing procedural reduction here
-- as I initially worked out how the math functions. Required me to
-- track column permutations as I shifted and while initially easier
-- to follow it made solving a bit more obtuse.
-- local function to_rref(A, b)
-- 	local rows = #A
-- 	local columns = #A[1]
--
-- 	local column_perm = {}
-- 	for c = 1, columns do
-- 		column_perm[c] = c
-- 	end
--
-- 	local pivots = 0
-- 	local pivot_row = 1
--
-- 	local c = 1
-- 	while c <= columns do
-- 		local pivot = nil
-- 		local min_val = nil
-- 		for r = pivot_row, rows do
-- 			local v = A[r][c]
-- 			if v ~= 0 then
-- 				local av = abs(v)
-- 				--Since we're only dealing with integers we want to pivot
-- 				--regardless of negative or positive.
-- 				if not min_val or av < min_val then
-- 					min_val = av
-- 					pivot = r
-- 				end
-- 			end
-- 		end
--
-- 		if pivot then
-- 			pivots = pivots + 1
-- 			swap_rows(A, pivot_row, pivot, b)
-- 			local pivot_val = A[pivot_row][c]
--
-- 			-- reduce
-- 			for r = 1, rows do
-- 				if r ~= pivot_row then
-- 					-- Reduce subsequent rows to 0. If the column in the row being reduced
-- 					-- becomes smaller than the pivot row we want to pivot again and
-- 					-- continue to reduce. Basically finding the gcd of the values
-- 					-- in the pivot row column and the column of the row being reduced.
-- 					while A[r][c] ~= 0 do
-- 						if abs(A[r][c]) < abs(A[pivot_row][c]) then
-- 							swap_rows(A, r, pivot_row, b)
-- 							pivot_val = A[pivot_row][c]
-- 						end
--
-- 						local factor = floor(A[r][c] / pivot_val)
-- 						if factor == 0 then
-- 							factor = 1
-- 						end
--
-- 						for k = 1, columns do
-- 							A[r][k] = A[r][k] - factor * A[pivot_row][k]
-- 						end
-- 						b[r] = b[r] - factor * b[pivot_row]
-- 					end
-- 				end
-- 			end
-- 			pivot_row = pivot_row + 1
-- 			c = c + 1
-- 		else
-- 			-- if there is no pivot push column to the right
-- 			local swapped = false
-- 			for k = c + 1, columns do
-- 				if pivot_candidate(A, k, pivot_row) then
-- 					for r = 1, rows do
-- 						A[r][c], A[r][k] = A[r][k], A[r][c]
-- 					end
-- 					column_perm[c], column_perm[k] = column_perm[k], column_perm[c]
-- 					swapped = true
-- 					break
-- 				end
-- 			end
-- 			if not swapped then
-- 				c = c + 1
-- 			end
-- 		end
-- 	end
-- 	return pivots, column_perm
-- end

-- Using recursive dfs to brute force solutions using constraints
-- set by free variables after the HNF style elimination.
local function recursive_dfs(A, b, pivot_cols, free_vars, idx, x)
	if idx > #free_vars then
		local sum = 0
		local pvs = {}
		for i, pc in ipairs(pivot_cols) do
			local pr = i
			local rhs = b[pr]
			for _, fc in ipairs(free_vars) do
				rhs = rhs - A[pr][fc] * x[fc]
			end
			local coeff = A[pr][pc]
			if rhs % coeff ~= 0 then
				return
			end
			local val = rhs / coeff
			if val < 0 then
				return
			end
			pvs[pc] = val
		end

		for _, v in pairs(x) do
			sum = sum + v
		end
		for _, v in pairs(pvs) do
			sum = sum + v
		end

		result = min(result, sum)
		return
	end

	local fc = free_vars[idx]
	local lower, upper = 0, 100
	for i = 1, #pivot_cols do
		-- local pc = pivot_cols[i]
		local pr = i
		local coeff = A[pr][fc]
		if coeff ~= 0 then
			local rhs = b[pr]

			for j = 1, idx - 1 do
				local prev_c = free_vars[j]
				rhs = rhs - A[pr][prev_c] * x[prev_c]
			end

			if coeff > 0 then
				upper = min(upper, floor(rhs / coeff))
			elseif coeff < 0 then
				lower = max(lower, ceil(rhs / coeff))
			end
		end
	end

	for v = lower, upper do
		x[fc] = v
		recursive_dfs(A, b, pivot_cols, free_vars, idx + 1, x)
		x[fc] = nil
	end
end

local function solve(A, b, pivot_cols, free_vars)
	local x = {}
	--if #free_vars == 0 then
	--	if #free_vars == 0 then
	--		-- Fully determined system: back-substitution
	--		local n = #pivot_cols
	--		local v = {}
	--		for i = n, 1, -1 do
	--			local r = i
	--			local c = pivot_cols[i]
	--			local rhs = b[r]

	--			-- subtract contributions of pivot vars already solved below
	--			for j = i + 1, n do
	--				local cj = pivot_cols[j]
	--				rhs = rhs - A[r][cj] * v[cj]
	--			end

	--			local coeff = A[r][c]
	--			if rhs % coeff ~= 0 then
	--				return -- no integer solution
	--			end

	--			local val = rhs / coeff
	--			if val < 0 then
	--				return -- no non-negative solution
	--			end

	--			v[c] = val
	--		end

	--		-- sum all pivot values
	--		local sum = 0
	--		for _, val in pairs(v) do
	--			sum = sum + val
	--		end
	--		result = min(result, sum)
	--	end
	--	--local sum = 0
	--	--for i, pc in ipairs(pivot_cols) do
	--	--	local pr = i
	--	--	local rhs = b[pr]
	--	--	local coeff = A[pr][pc]
	--	--	if coeff == 0 or rhs % coeff ~= 0 then
	--	--		return
	--	--	end
	--	--	local v = rhs / coeff
	--	--	if v < 0 then
	--	--		return
	--	--	end
	--	--	sum = sum + v
	--	--end
	--	--result = min(result, sum)
	--else
	recursive_dfs(A, b, pivot_cols, free_vars, 1, x)
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

for i, row in ipairs(input) do
	local A = get_A(row)
	local b = row.joltages
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
	local pivot_rows, pivot_cols, free_vars = hnf(A, b)

	io.write("\n")
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
	io.write("\nPivot Rows: ")
	for r = 1, #pivot_rows do
		io.write(pivot_rows[r])
		if r < #pivot_rows then
			io.write(",")
		end
	end
	io.write("\nPivot Columns: ")
	for c = 1, #pivot_cols do
		io.write(pivot_cols[c])
		if c < #pivot_cols then
			io.write(",")
		end
	end
	io.write("\n", "Free variables: ")
	for f = 1, #free_vars do
		io.write(free_vars[f])
		if f < #free_vars then
			io.write(",")
		end
	end
	io.write("\n", "---", "\n")
	result = math.huge
	local prev_result = result
	solve(A, b, pivot_cols, free_vars)
	if result == prev_result then
		print(string.format("No result found for row: %d", i))
		break
	end
	total_result = total_result + result
end

local stop = os.clock()
print(total_result)
print(string.format("Time: %.6f", stop - start))
