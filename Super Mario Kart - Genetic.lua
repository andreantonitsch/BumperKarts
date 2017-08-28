Filename = "genetic.state"
ButtonNames = {
		"B",
		"Left",
		"Right",
}

inputs = {}

px = 0x0088 --south
py = 0x008C --east


-- north = 0
-- east = 64
-- south = 128
-- west = 192
cam_angle = 0x0095

origin_x = 2000
origin_y = 2288
start_x = 3712
stary_y = 2288
start_vector = {start_x - origin_x , stary_y - origin_y}

--small x, big x, small y, big y
fitless_zone = { 3250, 4056, 2200, 2900 }

track = {}
matrix = {}
track_size = 4100


species_counter = 1

-- Genetic Paramenters
elitism_level = 3
num_specimens = 100
mutation_rate = 1

-- State parameters

sin_state = false

poli_length = 10
exp_start_range = {-2.0, 2.0}
coef_start_range = {-20.0, 20.0}

accelexp_mutation_range = {-0.1, 1.0}
accelcoef_mutation_range = {-1.0, 5.0}
turnexp_mutation_range = {-0.1, 1.0}
turncoef_mutation_range = {-1.0, 5.0}

fit_correction = 0.75

-- START Map Localtion Functions
inner_x,inner_y,outer_x,outer_y = {}, {}, {}, {}

function read_track()
	local f = io.open("track.txt","r")
	for line in f:lines() do
		if(line == "inner") then inner_outer = true
		elseif(line == "outer") then inner_outer = false
		else
			x,y = line:gmatch(line,'[0-9]+')
			if inner_outer then
				table.insert(inner_x,tonumber(x))
				table.insert(inner_y,tonumber(y))
			else
				table.insert(outer_x,tonumber(x))
				table.insert(outer_y,tonumber(y))
			end
		end
	end
	f:close()
end

function gen_track()
		--generates the track - a 4000x4000 matrix of booleans
		--true means that track[i][j] is in the main part of the track 
		track = {}
		for i=1,track_size do
			track[i]={}
			for j=1,track_size do
				track[i][j] = false
			end
		end
		--due to our poor sampling techniques, there's no guarantee
		--that the inner and outer arrays of points are going to be the same size
		--so I first iterate the inner points and then the outer ones
		--(the two inner arrays obviously have the same size though as well as the two outer ones)
		for i=1,#inner_x do
			local curr_x = inner_x[math.fmod(i,#inner_x)]
			local curr_y = inner_y[math.fmod(i,#inner_x)]
			local next_x = inner_x[math.fmod(i+1,#inner_x)]
			local next_y = inner_y[math.fmod(i+1,#inner_x)]
			draw_line(curr_x,curr_y,next_x,next_y,matrix)
		end
		--time to draw the outer lines...
		for i=1,#outer_x do
			local curr_x = outer_x[math.fmod(i,#inner_x)]
			local curr_y = outer_y[math.fmod(i,#inner_x)]
			local next_x = outer_x[math.fmod(i+1,#inner_x)]
			local next_y = outer_y[math.fmod(i+1,#inner_x)]
			draw_line(curr_x,curr_y,next_x,next_y,matrix)
		end
		fill_track(matrix)
end

--merely an implementation of Bresenham's algorithm
--please refer to "Algorithm for computer control of a digital plotter",  J. E. Bresenham
--for as many details as possible: https://pdfs.semanticscholar.org/c443/c0b5f74f75d87193bc373cdc5b0b61cf28fd.pdf
--should work right out of the box
function draw_line(xi,yi,xf,yf,matrix)
		local delta_x = xf-xi
		local delta_y = yf-yi
		--taking my chances here with a possible division by zero
		local delta_err = math.abs(delta_y/delta_x)
		local err_val = delta_err - 0.5
		local y = yi
		if(xi > xf) then
			xi,xf = xf,xi
		end
		for x=xi,xf do
			matrix[x][y] = true
			err_val = err_val + delta_err
			if err_val >= 0.5 then
				y = y + 1
				err_val = err_val - 1
			end
		end	
end

--this is a trivial implementation of a polygon-filling algorithm based on scanlines
--basically, I run through every line from left to right and begin each line NOT painting
--every time I hit a "true" in the matrix (which is going to a point along one of the lines
--previously drawn with the draw_line() method), I change my behaviour to the opposite
function fill_track(matrix)
		for i=1,#matrix do
			local must_paint = false
			for j=1,#matrix do
				--if a point is hit...
				if matrix[i][j] then
					--then I change my behaviour
					must_paint = not must_paint
				--if must_paint is true, then everything is going to be painted until I hit
				--another true. otherwise, everything is NOT going to be painted until then
				else 
					matrix[i][j] = must_paint
				end
			end
		end
end

--it's wise to remember that pos_x and pos_y are 0-indexed
--so their range is [0..4000]
function is_in_track(pos_x,pos_y,track)
		return track[pos_x+1][pos_y+1]
end

-- END Map Location Functions


-- START helper functions
function vector_len(v)
	return math.sqrt( v[1] * v[1] + v[2] * v[2] )
end

function dot_prod(v1, v2)
	return (v1[1] * v2[1] + v1[2] * v2[2])
end

function angle_vectors(v1, v2)
	--local angle = math.atan(v1[2], v1[1]) - math.atan(v2[2], v2[1]);
	
	local delta_y = v2[2] - v1[2]
	local delta_x = v2[1] - v1[1]
	local angle = math.atan2(delta_y, delta_x)	
	
	if angle < 0 then
		angle =  angle + (2 * math.pi)
	end
	angle = (2 * math.pi) - angle
	return angle
end

function get_fitness_alpha( x, y)
	-- corrects some odd edge cases. Ideally, we'd only track fitness moving 'forward'.
	-- a better fitness function is needed for further accuracy.
	-- this rectangle prevents yoshi doing donuts to max out fitness.
	if x >= fitless_zone[1] and  x <= fitless_zone[2] and y >= fitless_zone[3] and y <= fitless_zone[4] then
		return 0.0
	end

	local v1 = {x - origin_x , y - origin_y}
	local angle = angle_vectors( start_vector, v1)
	--local angle = angle_vectors(  v1, start_vector)
	return angle
	
end


function clearInput()
	
	for i = 1,#ButtonNames do
		inputs["P1 " .. ButtonNames[i]] = false
	end

end

function print_mario_position()

	local x = memory.read_s16_le(px)
	local y = memory.read_s16_le(py)
	
	gui.drawText(223, 24+80, x, color, 9)
	gui.drawText(223, 24+95, y, color, 9)

end
-- END helper functions

function new_pool()

	local pool = {}
	
	pool.specimens = {}
	
	for i=1, num_specimens do
	
		local specimen = new_specimen()
		table.insert(pool.specimens, specimen)
		
	end 
	
	return pool

end


function new_specimen()
	
	local specimen = {}
	
	local turn_coefs = {}
	local turn_exps = {}
	
	local accel_coefs = {}
	local accel_exps = {}
	
	
	for i = 1, poli_length do
		turn_coefs[i] = math.random() * coef_start_range[2]
		turn_exps[i] = math.random() * exp_start_range[2] --math.random(exp_start_range[1], exp_start_range[2])
		
		accel_coefs[i] = math.random() *coef_start_range[2]
		accel_exps[i] =  math.random() * exp_start_range[2] --math.random(exp_start_range[1], exp_start_range[2])	
		
	end
	
	specimen.turn_coeficients	= turn_coefs
	specimen.turn_exponents	= turn_exps
	
	specimen.accel_coeficients	= accel_coefs
	specimen.accel_exponents	= accel_exps 
	
	specimen.max_fit = 0.0
	specimen.id = species_counter
	
	species_counter = species_counter +1
	
	return specimen

end

--copies from 1 into 2
function copy_genome(spec1, spec2)
	
	for i=1, poli_length do
		spec2.turn_coeficients[i] = spec1.turn_coeficients[i]
		spec2.turn_exponents[i] = spec1.turn_exponents[i]
		
		spec2.accel_coeficients[i] = spec1.accel_coeficients[i]
		spec2.accel_exponents[i] = spec1.accel_exponents[i]
		
	end
	
end

function mutate_specimen(spec1)
	
	local i = math.random(1, poli_length)
	spec1.accel_coeficients[i] = spec1.accel_coeficients[i] + ((math.random() * accelcoef_mutation_range[2]) * mutation_rate)
	spec1.accel_exponents[i] = spec1.accel_exponents[i] + ((math.random() * accelexp_mutation_range[2]) * mutation_rate)
	spec1.turn_coeficients[i] = spec1.turn_coeficients[i] + ((math.random() * turncoef_mutation_range[2])* mutation_rate)
	spec1.turn_exponents[i] = spec1.turn_exponents[i] + ((math.random() *  turnexp_mutation_range[2]) * mutation_rate)
	
	return spec1
end

function breed_specimen(spec1, spec2)
	
	local specimen = new_specimen()
	
	
	for i=1, (poli_length) do
	
		local index = math.random(1, 2)
		
		if index == 1 or spec2 == nil then
			specimen.accel_coeficients[i] = spec1.accel_coeficients[i]
			specimen.accel_exponents[i] = spec1.accel_exponents[i]
		else

			specimen.accel_coeficients[i] = spec2.accel_coeficients[i]
			specimen.accel_exponents[i] = spec2.accel_exponents[i]
		end
		
		index = math.random(1, 2)
		
		if index == 1 or spec2 == nil then
			specimen.turn_coeficients[i] = spec1.turn_coeficients[i]
			specimen.turn_exponents[i] = spec1.turn_exponents[i]
		else
			specimen.turn_coeficients[i] = spec2.turn_coeficients[i]
			specimen.turn_exponents[i] = spec2.turn_exponents[i]
		end

	end
	
	return specimen
	
end

function save_population()
	local f = io.open("generation".. tostring(generation_count) ..".txt","w")
	f:write(tostring(num_specimens) .. "\n")
	f:write(tostring(poli_length) .. "\n")
	
	for i, spec in pairs(pool.specimens) do
	
		f:write(tostring(spec.max_fit) .. " ")
		
		for j = 1, poli_length do
			f:write(tostring(spec.accel_coeficients[j]) .. " ")
		end
		
		for j = 1, poli_length do
			f:write(tostring(spec.accel_exponents[j]) .. " ")
		end
		
		for j = 1, poli_length do
			f:write(tostring(spec.turn_coeficients[j]) .. " ")
		end
		
		for j = 1, poli_length do
			f:write(tostring(spec.turn_exponents[j]) .. " ")
		end
		
		f:write("\n")
	end
	
	f:close()
	
end

if not sin_state then

	function generate_input(specimen, x, y)

		local accel = 0
		local turn = 0

		for i=1, poli_length, 2 do
			
			accel = accel + (specimen.accel_coeficients[i] * (math.pow(x, specimen.accel_exponents[i])))
			accel = accel + (specimen.accel_coeficients[i+1] * (math.pow(y, specimen.accel_exponents[i+1])))
			
			turn = turn + (specimen.turn_coeficients[i] * (math.pow(x, specimen.turn_exponents[i])))
			turn = turn + (specimen.turn_coeficients[i+1] * (math.pow(y, specimen.turn_exponents[i+1])))
			
		end
		
		local right = accel >= 0 
		local left = turn >= 0 

		
		gui.drawText(0, 24+160, "turn: " .. tostring(turn), color, 9)
		gui.drawText(0, 24+170, "accel: " .. tostring(accel), color, 9)
		
		inputs["P1 " .. ButtonNames[1]] = true
		if right and left then
			inputs["P1 " .. ButtonNames[3]] = false
			inputs["P1 " .. ButtonNames[2]] = false
		else
			inputs["P1 " .. ButtonNames[3]] = right
			inputs["P1 " .. ButtonNames[2]] = left
		end

	end
	
else

	function generate_input(specimen, x, y)

		local accel = 0
		local turn = 0

		for i=1, poli_length, 2 do
			
			accel = accel + (specimen.accel_coeficients[i] * (math.pow(x, specimen.accel_exponents[i])))
			accel = accel + (specimen.accel_coeficients[i+1] * (math.pow(y, specimen.accel_exponents[i+1])))
			
			turn = turn + (specimen.turn_coeficients[i] * (math.pow(x, specimen.turn_exponents[i])))
			turn = turn + (specimen.turn_coeficients[i+1] * (math.pow(y, specimen.turn_exponents[i+1])))
			
		end
		
		accel = math.sin(accel)
		turn = math.sin(turn)
		
		inputs["P1 " .. ButtonNames[1]] = true
		
		--if accel >= 0 then
		--	inputs["P1 " .. ButtonNames[1]] = true
		--else
		--	inputs["P1 " .. ButtonNames[1]] = false
		--end
		
		gui.drawText(0, 24+160, "turn: " .. tostring(turn), color, 9)
		gui.drawText(0, 24+170, "accel: " .. tostring(accel), color, 9)
		
		if (turn >= -0.33 and turn <= 0.33) then
			inputs["P1 " .. ButtonNames[3]] = false
			inputs["P1 " .. ButtonNames[2]] = false
		elseif turn < -0.33 then
			inputs["P1 " .. ButtonNames[2]] = true
			inputs["P1 " .. ButtonNames[3]] = false
		else
			inputs["P1 " .. ButtonNames[2]] = false
			inputs["P1 " .. ButtonNames[3]] = true
		end
		

	end

	
end

function cull_bottomhalf()
	
	local specimens = pool.specimens
	table.sort(specimens, function(s1, s2)
		return (s1.max_fit > s2.max_fit)
	end)
	
	for i=1, math.floor(num_specimens/2) do
		table.remove(specimens)
	end
	
end


function new_generation()
	
	cull_bottomhalf()
	
	
	local specimens = pool.specimens
	table.sort(specimens, function(s1, s2)
		return (s1.max_fit > s2.max_fit)
	end)
	
	local size = #specimens
	local count = 1
	for i, spec in ipairs(specimens) do

		local spec_index = math.random(1, size)
		local specimen = breed_specimen(spec, specimens[spec_index])
		
		if i > elitism_level then
			specimens[i] = mutate_specimen(spec)
		end
		
		table.insert(pool.specimens, specimen)
		count = count +1
		if count > size then
			break
		end
	end
	
	gen_size = #pool.specimens
end



function load_population()

end


pool = new_pool()
generation_count = 0
gen_size = 0
maximum_fit = 0
max_fit_change = false

gen_track()

while true do

	-- run a generation
	for i, specimen in pairs(pool.specimens) do
	
		savestate.load(Filename);
		stale = 0
		specimen = pool.specimens[i]
		specimen.max_fit = 0
		
		-- run a species
		while  stale < 150 do
			local x = memory.read_s16_le(px)
			local y = memory.read_s16_le(py)
			
			gui.drawText(0, 24+80, "x: " .. tostring(x), color, 9)
			gui.drawText(0, 24+95, "y: " .. tostring(y), color, 9)

			local new_fit =  get_fitness_alpha(x, y)
			local corrected_fit = new_fit
			local in_track = is_in_track(x, y, track)
			--if is_in_track(x, y, track) then
			--	corrected_fit = new_fit * fit_correction
			--end
			
			if (specimen.max_fit < corrected_fit) and (corrected_fit <= 6.0) then
				specimen.max_fit = corrected_fit
				
				if specimen.max_fit > maximum_fit then
					maximum_fit = specimen.max_fit
					max_fit_change = true
				end
				stale = 0
			else
				stale = stale + 1
			end

			gui.drawText(0, 24+65, "gen size: " .. tostring(gen_size), color, 9)
			gui.drawText(0, 24+110, "max fit: " .. tostring(specimen.max_fit), color, 9)
			gui.drawText(0, 24+120, "fit: " .. tostring(new_fit), color, 9)
			
			gui.drawText(0, 24+130, "gen: " .. tostring(generation_count), color, 9)
			gui.drawText(0, 24+140, "stale: " .. tostring(stale), color, 9)
			gui.drawText(0, 24+150, "in track: " .. tostring(in_track), color, 9)
			
			
			
			generate_input(specimen, x, y)
			
			joypad.set(inputs)
			emu.frameadvance()
		end
		
		if max_fit_change then 
			console.log("maximum fitness" .. tostring(maximum_fit))
			max_fit_change = false
		end
		
	end
	
	save_population()

	new_generation()
	generation_count = generation_count +1
	console.log(gen_size)
	
	mutation_rate = mutation_rate - 0.01

	
	if mutation_rate  < 0.01 then
		break
	end
	
	
end