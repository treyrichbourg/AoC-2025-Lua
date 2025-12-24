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

local function to_echelon(A, b)
	local rows = #A
	local columns = #A[1]
	local pivot_row = 1
	for c = 1, columns do
		local pivot = nil
		local min_val = nil
		for r = pivot_row, rows do
			if A[r][c] ~= 0 then
				local abs_val = abs(A[r][c])
				if not min_val or abs_val < min_val then
					min_val = abs_val
					pivot = r
				end
			end
		end
		if pivot then
			swap_rows(A, pivot_row, pivot, b)
			local pivot_val = A[pivot_row][c]
			-- reduce
			for r = 1, rows do
				if r ~= pivot_row then
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
		end
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
end

for _, row in ipairs(input) do
	local A = get_A(row)
	local b = row.joltages
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
	to_echelon(A, b)
	io.write("\n")
	for r = 1, #A do
		io.write("Row: ", r, " ", table.concat(A[r]), " | ", b[r], "\n")
	end
end

local stop = os.clock()
print(result)
print(string.format("Time: %.6f", stop - start))
