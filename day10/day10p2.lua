local util = require("util.util")

local start = os.clock()
local path = "day10/example.txt"
local result = 0

local strip_outer = util.strip_outer
local to_number = tonumber
local floor = math.floor
local abs = math.abs

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

local function pivot_candidate(A, c, pivot_row)
	local rows = #A
	for r = pivot_row, rows do
		if A[r][c] ~= 0 then
			return true
		end
	end
	return false
end

local function to_rref(A, b)
	local rows = #A
	local columns = #A[1]

	local column_perm = {}
	for c = 1, columns do
		column_perm[c] = c
	end

	local pivots = 0
	local pivot_row = 1

	local c = 1
	while c <= columns do
		local pivot = nil
		local min_val = nil
		for r = pivot_row, rows do
			local v = A[r][c]
			if v ~= 0 then
				local av = abs(v)
				--Since we're only dealing with integers we want to pivot
				--regardless of negative or positive.
				if not min_val or av < min_val then
					min_val = av
					pivot = r
				end
			end
		end

		if pivot then
			pivots = pivots + 1
			swap_rows(A, pivot_row, pivot, b)
			local pivot_val = A[pivot_row][c]

			-- reduce
			for r = 1, rows do
				if r ~= pivot_row then
					-- Reduce subsequent rows to 0. If the column in the row being reduced
					-- becomes smaller than the pivot row we want to pivot again and
					-- continue to reduce. Basically finding the gcd of the values
					-- in the pivot row column and the column of the row being reduced.
					while A[r][c] ~= 0 do
						if abs(A[r][c]) < abs(A[pivot_row][c]) then
							swap_rows(A, r, pivot_row, b)
							pivot_val = A[pivot_row][c]
						end

						local factor = floor(A[r][c] / pivot_val)
						if factor == 0 then
							factor = 1
						end

						for k = 1, columns do
							A[r][k] = A[r][k] - factor * A[pivot_row][k]
						end
						b[r] = b[r] - factor * b[pivot_row]
					end
				end
			end
			pivot_row = pivot_row + 1
			c = c + 1
		else
			-- if there is no pivot push column to the right
			local swapped = false
			for k = c + 1, columns do
				if pivot_candidate(A, k, pivot_row) then
					for r = 1, rows do
						A[r][c], A[r][k] = A[r][k], A[r][c]
					end
					column_perm[c], column_perm[k] = column_perm[k], column_perm[c]
					swapped = true
					break
				end
			end
			if not swapped then
				c = c + 1
			end
		end
	end
	return pivots, column_perm
end

local function get_free_vars(A)
	local rows, columns = #A, #A[1]
	local free_vars = {}
	for c = 1, columns do
		local ones = 0
		for r = 1, rows do
			if A[r][c] ~= 0 then
				ones = ones + 1
			end
		end
		if ones ~= 1 then
			free_vars[#free_vars + 1] = c
		end
	end
	return free_vars
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
end

for _, row in ipairs(input) do
	local A = get_A(row)
	local b = row.joltages
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
	to_rref(A, b)
	io.write("\n")
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
	io.write("\n", "---", "\n")
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
