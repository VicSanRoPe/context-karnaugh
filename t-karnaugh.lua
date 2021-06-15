if not modules then modules = { } end modules ['t-karnaugh'] = {
    version   = 0.1,
    comment   = "Karnaugh",
    author    = "",
    copyright = "",
    email     = "",
    license   = ""
}

thirddata = thirddata or { }
thirddata.karnaugh = {
	indices = false,
	labelStyle, -- It varies with the map's size
	groupStyle = "pass",
	
	rotate = [[rotatedaround((0.5*size, -0.5*size), %s) ]],
	shift  = [[shifted((%s-1)*size, (1-%s)*size) ]],
	color  = [[withcolor(%s) withtransparency("darken", 0.85)]],
	
	colors = { -- TODO: more colors
		["A"] = "red",
		["B"] = "green",
		["C"] = "blue",
		["D"] = "yellow",
		["E"] = "(0  , 1  , 1  )", -- Cyan
		["F"] = "(1  , 0  , 1  )", -- Pink
		["G"] = "(1  , 0.5, 0  )", -- Orange
		["H"] = "(0  , 0.6, 0  )", -- Dark Green
		["I"] = "(0.1, 0.5, 0.9)", -- Light Blue
		["J"] = "(0.6, 0  , 0.6)", -- Violet
		["K"] = "(0.5, 0.9, 0.5)", -- Pale green
		["L"] = "(0.5, 0.3, 0.15)" -- Brown
	}
}

local karnaugh = thirddata.karnaugh
local kn = karnaugh
local metafun = context.metafun



function karnaugh.numToGray(num, bits)
	-- ~ is exclusive or, >> is shift right --
	local grayNum = num ~ (num >> 1)
	local arr = {}
	for b = bits, 1, -1 do
		arr[b] = math.fmod(grayNum, 2)
		grayNum = math.floor((grayNum - arr[b]) / 2)
	end
	return table.concat(arr)
end


function karnaugh.setup(string)
	local opts = utilities.parsers.settings_to_hash(string)
	for k, v in pairs(opts) do
		if k == "indices" and (v == "on" or v == "yes") then
			kn.indices = true;
		elseif k == "labelstyle" then
			if v == "corner" then kn.labelStyle = "corner"
			elseif v == "edge" then kn.labelStyle = "edge"
			else error("What is "..v.."?") end
		elseif k == "groupstyle" then
			if v == "pass" then kn.groupStyle = "pass"
			elseif v == "stop" then kn.groupStyle = "stop"
			else error("What is groupstyle="..v.."?") end
		elseif k == "ylabels" then
			kn.vVars = utilities.parsers.settings_to_array(v)
		elseif k == "xlabels" then
			kn.hVars = utilities.parsers.settings_to_array(v)
		elseif k == "ny" then
			kn.height = tonumber(v)
		elseif k == "nx" then
			kn.width = tonumber(v)
		elseif k == "label" then
			kn.label = v
		end
	end

	-- Just checking things
	if kn.height and kn.vVars and kn.height ~= 2^#kn.vVars then
		error("Wrong vertical size!") end
	if kn.width and kn.hVars and kn.width ~= 2^#kn.hVars then
		error("Wrong horizontal size!") end
	if kn.hVars and not kn.vVars then error("Why just some labels") end
	if kn.vVars and not kn.hVars then error("Why just some labels") end

	-- Generate some optional arguments
	kn.calculateOptionals()
end


function karnaugh.calculateOptionals()
	if not kn.height and kn.vVars then kn.height = 2^#kn.vVars end
	if not kn.width  and kn.hVars then kn.width  = 2^#kn.hVars end
	if not kn.vVars and kn.height then kn.vVars = {}
		for i=1, math.log(kn.height)/math.log(2), 1 do
			kn.vVars[i] = "$I_{"..(i-1).."}$" end end
	if not kn.hVars and kn.width then kn.hVars = {}
		for i=1, math.log(kn.width)/math.log(2), 1 do
			kn.hVars[i] = "$I_{"..(i+(#kn.vVars)-1).."}$" end end

	-- Dynamic optional settings
	if not kn.labelStyle and kn.hVars then
		if #kn.hVars >= 3 or #kn.vVars >= 3 then kn.labelStyle = "edge"
		else kn.labelStyle = "corner" end
	end
end


function karnaugh.data(buffer)
	if kn.width and kn.height then
		local arr = utilities.parsers.settings_to_array(buffer)
		for i=1, #arr, 1 do -- Remove leading and trailing spaces
			arr[i] = arr[i]:gsub("^%s+", ""):gsub("%s+$", "") end
		karnaugh.setData(arr)
	else -- We'll guess the map's size
		local lines = string.splitlines(buffer)
		local data = {}
		for y=1, #lines, 1 do
			if lines[y] ~= "" then
				local row = utilities.parsers.settings_to_array(lines[y])
				data[y] = {}
				for x=1, #row, 1 do
					row[x] = row[x]:gsub("^%s+", ""):gsub("%s+$", "")
					-- The last element may be empty
					if x == #row and row[x] == "" then break end
					data[y][x] = row[x]
				end
				if not kn.width then kn.width = #data[y]
				elseif kn.width ~= #data[y] then
					error("Cannot guess width") end
			end
		end
		kn.height = #data
		kn.data = data
		kn.calculateOptionals() -- To generate the labels
	end
end


function karnaugh.setData(content)
	local data = {}
	for y = 1, kn.height, 1 do
		data[y] = {}
		for x = 1, kn.width, 1 do
			data[y][x] = content[(y-1) * kn.width + x]
		end
	end
	
	if #content == 0 then
		return false
	end
	
	karnaugh.data = data
end


function karnaugh.setTableData(content)
	local data = {}
	for y = 0, kn.height-1, 1 do
		data[y+1] = {}
		for x = 0, kn.width-1, 1 do
			local pos = ((y ~ (y >> 1)) << #kn.hVars) + (x ~ (x >> 1))
			data[y+1][x+1] = content[pos+1]
		end
	end
	karnaugh.data = data
end


function karnaugh.groups(buffer)
	local dirArr = utilities.parsers.settings_to_array(buffer)
	local grArr = {}
	for i=1, #dirArr, 1 do
		-- Remove leading and trailing spaces
		dirArr[i] = dirArr[i]:gsub("^%s+", ""):gsub("%s+$", "")
		grArr[i]  = dirArr[i]:gsub("%*", "")  -- Remove asterisks
	end
	kn.setGroups(grArr) -- Just the letters

	kn.setNotes(dirArr) -- Letters and asterisks
end


function karnaugh.setNotes(content)
	local notes = {}
	for y = 1, kn.height, 1 do
		notes[y] = {}
		for x = 1, kn.width, 1 do
			notes[y][x] = {}
			local cell = content[(y-1) * kn.width + x]
			for gr in cell:gmatch("(%u)%*") do
				notes[y][x][gr] = {"", ""}
			end
		end
	end

	if #content == 0 then
		return false
	end

	karnaugh.notes = notes
end


function karnaugh.setGroups(content)
	local nx = {["t"] = "l", ["r"] = "t", ["b"] = "r", ["l"] = "b"} -- Next
	local groups = {}
	for y = 1, kn.height, 1 do
		groups[y] = {}
		for x = 1, kn.width, 1 do
			groups[y][x] = {}
			groups[y][x].g = content[(y-1) * kn.width + x] -- Groups
			groups[y][x].d = {} -- Directions for each cell, for each group
		end
	end
	
	if #content == 0 then
		return false
	end

	karnaugh.groups = groups
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for gr in string.characters(kn.groups[y][x].g) do
				arr = {}
				arr[#arr+1] = kn.processGroup(gr, y, x, 0,-1, "l")
				arr[#arr+1] = kn.processGroup(gr, y, x, 0, 1, "r")
				arr[#arr+1] = kn.processGroup(gr, y, x,-1, 0, "t")
				arr[#arr+1] = kn.processGroup(gr, y, x, 1, 0, "b")
				if #arr == 0 then
					arr[1] = "h"
				elseif #arr >= 2 then
					table.sort(arr, function(a, b)
						return nx[a:lower()] == b:lower() end)
				end
				kn.groups[y][x].d[gr] = arr
			end
		end
	end






	karnaugh.figureoutgroupconnections()
end


function karnaugh.figureoutgroupconnections()
	local data , checked= {}, {}
	--data["A"][1] = {{1, 2}, {2, 2}} -- {y, x}
	--data["A"][2] = {{1, 2}, {2, 2}}
	--group ^ | ^ detached part | ^ all cells that have that part
	--data["A"][1][2] = {2, 2}
	--   an index  ^   |   ^ coordinates

	-- This stores all cells that form a detached part of a group
	-- and (just for itself) all the cells where it has looked
	function getPart(gr, id, y, x)
		function check(gr, id, y, x, yf, xf)
			local ys, xs = y + yf, x + xf
			if ys > kn.height then ys = 1
				elseif ys == 0 then ys = kn.height end
			if xs > kn.width then xs = 1
				elseif xs == 0 then xs = kn.width end

			for i=1, #checked[gr][id], 1 do
				if checked[gr][id][i][1] == ys and
						checked[gr][id][i][2] == xs then
					return nil, nil end
			end
			checked[gr][id][#checked[gr][id]+1] = {ys, xs}

			if kn.groups[ys][xs].g:match(gr) then
				data[gr][id][#data[gr][id]+1] = {ys, xs}
				return ys, xs
			end
			return nil, nil
		end

		local ys, xs
		ys, xs = check(gr, id, y, x, 0, -1) -- Left
		if ys and xs then getPart(gr, id, ys, xs) end
		ys, xs = check(gr, id, y, x, 0, 1) -- Right
		if ys and xs then getPart(gr, id, ys, xs) end
		ys, xs = check(gr, id, y, x, -1, 0) -- Top
		if ys and xs then getPart(gr, id, ys, xs) end
		ys, xs = check(gr, id, y, x, 1, 0) -- Bottom
		if ys and xs then getPart(gr, id, ys, xs) end
	end


	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for gr in kn.groups[y][x].g:characters() do
				if not data[gr] then -- First time seeing a group
					data[gr], checked[gr] = {}, {}
					local id = 1
					data[gr][id], checked[gr][id] = {}, {}
					getPart(gr, id, y, x)
				else -- We'll have to look at all parts of the group
					--  to see if this cell is not yet indexed
					local haveISeenIt = false    -- Assume it's new
					for id = 1, #data[gr] do           -- All parts
						for i = 1, #data[gr][id], 1 do -- All cells
							if data[gr][id][i][1] == y and
									data[gr][id][i][2] == x then
								haveISeenIt = true
							end
						end
					end
					if not haveISeenIt then -- New part of group
						local id = #data[gr]+1
						data[gr][id], checked[gr][id] = {}, {}
						getPart(gr, id, y, x)
					end
				end
			end
		end
	end
end


function karnaugh.processGroup(gr, y, x, yf, xf, ch)
	function offset(v, vf, lim)
		vs = v + vf
		if vs > lim then
			return 1, true
		elseif vs == 0 then
			return lim, true
		end
		return vs, false
	end

	local ys, overY = offset(y, yf, kn.height)
	local xs, overX = offset(x, xf, kn.width)

	if not overY and not overX then
		if string.find(kn.groups[ys][xs].g, gr) then
			return ch
		end
	else
		if string.find(kn.groups[ys][xs].g, gr) then
			local ys, xs, timesFound, timesLooped = y, x, 0, 0
			repeat
				timesLooped = timesLooped + 1
				ys, overY = offset(ys, -yf, kn.height) -- Look for groups in
				xs, overX = offset(xs, -xf, kn.width)  -- the other direction
				if string.find(kn.groups[ys][xs].g, gr) then
					timesFound = timesFound + 1
				end
			until (overY or overX)
			if timesFound ~= timesLooped then -- If not on all cells
				return ch:upper()
			end
		end
	end
end


function karnaugh.setNote(gr, note, dir)
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for g, v in pairs(kn.notes[y][x]) do
				if (gr == g) then
					dir = dir:gsub("%s+", "") -- Remove spaces
					kn.notes[y][x][g][1] = dir
					kn.notes[y][x][g][2] = note
				end
			end
		end
	end
end




---------------------------------------------------------------------

                        --DRAWING FUNCTIONS--

---------------------------------------------------------------------




function karnaugh.drawMap()
	metafun.start()
	if kn.indices and kn.groups then
		metafun("size := 7mm;")
	else
		metafun("size := 6mm;")
	end
	karnaugh.drawGrid()
	karnaugh.drawData()
	if kn.groups then
		karnaugh.drawGroups()
	end
	if kn.notes then
		karnaugh.drawNotes()
	end
	
	metafun.stop()
end


function karnaugh.drawGrid()
	-- Labels
	metafun([[pickup pencircle scaled 0.3mm;]])
	if kn.labelStyle == "corner" then
		local length;
		if #kn.vVars >= #kn.hVars then
			length = 1.2 + (#kn.vVars-2) / 2
		else
			length = 1.2 + (#kn.hVars-2) / 2
		end
		metafun([[draw origin -- (-%s*size, %s*size);]], length, length)
		
		for i = 1, #kn.vVars, 1 do
			metafun([[label.llft(btex {%s} etex, (-%s*size, %s*size));]],
				kn.vVars[#kn.vVars-i+1], 0.5*i-0.2, 0.5*i+0.1)
		end
		for i = 1, #kn.hVars, 1 do
			metafun([[label.urt(btex {%s} etex, (-%s*size, %s*size));]],
				kn.hVars[#kn.hVars-i+1], 0.5*i+0.2, 0.5*i-0.1)
		end

		if kn.label then
			-- Map's label
			metafun([[label.top(btex %s etex, (%s*size, 0.8size));]],
				kn.label, kn.width/2)
		end

	elseif kn.labelStyle == "edge" then
		local str = ""
		for i = 1, #kn.hVars, 1 do str = str .. " " .. kn.hVars[i] end
		metafun([[draw thelabel.top(btex {%s} etex, (0, 0))
			shifted(%s*size, %s*size);]],
			str, kn.width/2, 0.75)
		str = ""
		for i = 1, #kn.vVars, 1 do str = str .. " " .. kn.vVars[i] end
		metafun([[draw thelabel.top(btex {%s} etex, (0, 0))
			rotated(90) shifted(-%s*size, %s*size);]],
			str, (0.4+#kn.vVars/4), -kn.height/2)
		if kn.label then
			-- Map's label
			metafun([[label.ulft(btex %s etex, (-0.2size, 0.2size));]],
				kn.label)
		end
	end
	
	-- Grid
	for y = 0, kn.height-1, 1 do
		for x = 0, kn.width-1, 1 do
		metafun([[draw unitsquare rotated(-90) scaled(size)
			shifted(%s * size, -%s * size);]], x, y)
		end
	end
	
	-- Mirror lines
	local widePen = [[withpen pencircle scaled 0.6mm;]]
	--metafun([[interim linecap := squared;]])
	if kn.width > 4 then
		for w = kn.width-4, 4, -4 do
			metafun([[draw (%s*size, 0.2*size) --
				(%s*size, -(%s+0.2)*size)]] .. widePen,
				w, w, kn.height)
		end
	end
	if kn.height > 4 then
		for h = kn.height-4, 4, -4 do
			metafun([[draw (-0.2*size, -%s*size) --
				((%s+0.2)*size, -%s*size)]] .. widePen,
				h, kn.width, h)
		end
	end
	
	--Gray code
	for y = 0, kn.height-1, 1 do
		metafun([[label.lft(btex {\tfx %s} etex, (-0.1*size, -%s*size));]],
		kn.numToGray(y, #kn.vVars), (0.5 + y))
	end
	for x = 0, kn.width-1, 1 do
		if kn.width <= 8 then
		metafun([[label.top(btex {\tfx %s} etex, (%s*size, 0.1*size));]],
		kn.numToGray(x, #kn.hVars), (0.5 + x))
		else
		metafun([[label.top(btex {\tfxx %s} etex, (%s*size, 0.1*size));]],
		kn.numToGray(x, #kn.hVars), (0.5 + x))
		end
	end
	
	--metafun([[setbounds currentpicture to fullsquare
	--	scaled(7*size) shifted(2*size, -1.75*size);]])
end


function karnaugh.drawData()
	for y = 0, kn.height-1, 1 do
		for x = 0, kn.width-1, 1 do
			if kn.data and not kn.indices then
				metafun([[label(btex {%s} etex, (%s*size,-%s*size));]],
					kn.data[y+1][x+1], x+0.5, y+0.5)
			else
				if kn.groups then offset = 0.11 else offset = 0.02 end
				local pos = ((y ~ (y >> 1)) << #kn.hVars) + (x ~ (x >> 1))
				metafun([[draw thelabel.lrt(btex {\tfxx %s} etex,
					(%s*size, -%s.size)) withcolor(0.33white);]],
					pos, x+offset, y+offset)
				if kn.data then
					metafun([[label(btex {%s} etex, (%s*size,-%s*size));]],
						kn.data[y+1][x+1], x+0.64, y+0.64)
				end
			end
		end
	end
end



local p = { -- Clockwise i initial f final
["Ri"] = "(1.2size, -0.9size)..{left}",  ["ri"] = "(size, -0.9size)..{left}",
["Bi"] = "(0.1size, -1.2size)..{up}",    ["bi"] = "(0.1size, -size)..{up}",
["Li"] = "(-0.2size, -0.1size)..{right}",["li"] = "(0, -0.1size)..{right}",
["Ti"] = "(0.9size, 0.2size)..{down}",   ["ti"] = "(0.9size, 0)..{down}",

["Rf"] = "{right}..(1.2size, -0.1size)", ["rf"] = "{right}..(size, -0.1size)",
["Bf"] = "{down}..(0.9size, -1.2size)",  ["bf"] = "{down}..(0.9size, -size)",
["Lf"] = "{left}..(-0.2size, -0.9size)", ["lf"] = "{left}..(0, -0.9size)",
["Tf"] = "{up}..(0.1size, 0.2size)",     ["tf"] = "{up}..(0.1size, 0)",

["l"]  = "(0.1size, -0.5size)",          ["r"]  = "(0.9size, -0.5size)",
["t"]  = "(0.5size, -0.1size)",          ["b"]  = "(0.5size, -0.9size)"
}


function karnaugh.groupPath(arg)
	local op = {["t"] = "b", ["b"] = "t", ["l"] = "r", ["r"] = "l"} -- Other
	local nx = {["t"] = "l", ["r"] = "t", ["b"] = "r", ["l"] = "b"} -- Next

	local a1, a2, a3
	if kn.groupStyle == "pass" then
		if #arg >= 1 then a1 = arg[1] end
		if #arg >= 2 then a2 = arg[2] end
		if #arg >= 3 then a3 = arg[3] end
	else
		if #arg >= 1 then a1 = arg[1]:lower() end
		if #arg >= 2 then a2 = arg[2]:lower() end
		if #arg >= 3 then a3 = arg[3]:lower() end
	end

	if a3 then
		local mid = op[a2:lower()]
		return {p[a1.."i"] .. p[mid] .. p[a3.."f"]}
	elseif a2 then
		if a1:lower() ~= op[a2:lower()] then --Corners
			return {p[a1.."i"] .. p[op[a2:lower()]] .. ".."
				.. p[op[a1:lower()]] .. p[a2.."f"]}
		else -- Tubes
			local mid = nx[a2:lower()]
			return {p[a1.."i"] .. p[mid] .. p[a2.."f"],
				    p[a2.."i"] .. p[op[mid]] .. p[a1.."f"]}
		end
	elseif a1 then
		if a1 ~= "h" then -- Halves
			local ch = a1:lower()
			return {p[a1.."i"] .. p[op[nx[ch]]] .. ".."
				.. p[op[ch]] .. ".." .. p[nx[ch]] .. p[a1.."f"]}
		else -- Circle
			return {p["t"]..".."..p["r"]..".."
				.. p["b"]..".."..p["l"].."..cycle"}
		end
	end
end


function karnaugh.drawGroups()
	metafun([[pickup pencircle scaled(0.4mm);]])
	metafun([[interim linecap := squared;]])
	
	local arr = {}

	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for gr, dir in pairs(kn.groups[y][x].d) do
				if #dir ~= 4 then -- There is something to draw
					arr[gr] = arr[gr] or ""
					local paths = kn.groupPath(dir)
					for i=1, #paths, 1 do
						arr[gr] = arr[gr] .. string.format("draw ("..
							paths[i]..") "..kn.shift..kn.color..";",
							x, y, kn.colors[gr])
					end
				end
			end
		end
	end

	for gr, str in pairs(arr) do -- To draw all cells of a group at once
		metafun(str)
	end
end


function karnaugh.drawNotes()
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for gr, v in pairs(kn.notes[y][x]) do
				local dstStr = "(%s*size, %s*size)";
				local srcStr = "(%s*size, %s*size)";
				if v[1] == "tr" then
					dstStr = dstStr:format(x, 1)
					srcStr = srcStr:format(x-0.2, -y+0.8)
				elseif v[1] == "tl" then
					dstStr = dstStr:format(x-1, 1)
					srcStr = srcStr:format(x-0.8, -y+0.8)
				elseif v[1] == "br" then
					dstStr = dstStr:format(x, -kn.height-0.7)
					srcStr = srcStr:format(x-0.2, -y+0.2)
				elseif v[1] == "bl" then
					dstStr = dstStr:format(x-1, -kn.height-0.7)
					srcStr = srcStr:format(x-0.8, -y+0.2)
				elseif v[1] == "lb" then
					dstStr = dstStr:format(-1, -y)
					srcStr = srcStr:format(x-0.8, -y+0.2)
				elseif v[1] == "lt" then
					dstStr = dstStr:format(-1, -y+1)
					srcStr = srcStr:format(x-0.8, -y+0.8)
				elseif v[1] == "rb" then
					dstStr = dstStr:format(kn.width+0.7, -y)
					srcStr = srcStr:format(x-0.2, -y+0.2)
				elseif v[1] == "rt" then
					dstStr = dstStr:format(kn.width+0.7, -y+1)
					srcStr = srcStr:format(x-0.2, -y+0.8)
				elseif v[1] == "r" then
					dstStr = dstStr:format(kn.width+0.7, -y+0.5)
					srcStr = srcStr:format(x-0.1, -y+0.5)
				elseif v[1] == "b" then
					dstStr = dstStr:format(x-0.5, -kn.height-0.7)
					srcStr = srcStr:format(x-0.5, -y+0.1)
				end
				
				metafun("drawarrow %s -- %s" .. kn.color .. ";",
					srcStr, dstStr, kn.colors[gr])
				
				local posTable = {["t"] = "top", ["b"] = "bot",
					["l"] = "lft", ["r"] = "rt"}
				metafun("label.%s(btex {%s} etex, %s);",
					posTable[v[1]:sub(1, 1)], v[2], dstStr)
				
			end
		end
	end
end


