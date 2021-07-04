if not modules then modules = { } end modules ['t-karnaugh'] = {
    version   = "0.95",
    comment   = "Karnaugh",
    author    = "VicSanRoPe",
    copyright = "VicSanRoPe 2021",
    license   = "GNU GPL 2.0"
}

-- TODO: more colors, add option indicesstart=NUMBER for submaps

thirddata = thirddata or { }
thirddata.karnaugh = {
	indices = false,
	labelStyle, -- Varies with the map's size: "corner" or "edge"
	groupStyle = "pass",
	scale = 1, -- big=1.75, small=0.8
	
	rotate = [[rotatedaround((0.5*size, -0.5*size), %s) ]],
	shift  = [[shifted((%s-1)*size, (1-%s)*size) ]],
	color  = [[withcolor(%s) withtransparency("darken", 0.85)]],
	
	colors = {
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


karnaugh.opts = {}


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



function karnaugh.processOpts(content)
	local opts = {}
	for k, v in pairs(content) do
		if k == "indices" then
			if v == "on" or v == "yes" then opts.indices = true;
			elseif v == "off" or v == "no" then opts.indices = false;
			else error("What is indices="..v.."?") end
		elseif k == "labelstyle" then
			if v == "corner" then opts.labelStyle = "corner"
			elseif v == "edge" then opts.labelStyle = "edge"
			else error("What is labelstyle="..v.."?") end
		elseif k == "groupstyle" then
			if v == "pass" then opts.groupStyle = "pass"
			elseif v == "stop" then opts.groupStyle = "stop"
			else error("What is groupstyle="..v.."?") end
		elseif k == "ylabels" then
			opts.vVars = utilities.parsers.settings_to_array(v)
		elseif k == "xlabels" then
			opts.hVars = utilities.parsers.settings_to_array(v)
		elseif k == "ny" then
			opts.height = tonumber(v)
		elseif k == "nx" then
			opts.width = tonumber(v)
		elseif k == "name" then
			opts.label = v
		elseif k == "spacing" then
			if v == "normal" then opts.scale = 1.0
			elseif v == "small" then opts.scale = 0.8
			elseif v == "big" then opts.scale = 1.75
			else opts.scale = tonumber(v) end
		elseif k == "indicesstart" then
			opts.indicesstart = tonumber(v)
		end
	end
	return opts
end


function karnaugh.setup(content)
	kn.height,kn.width,kn.vVars,kn.hVars,kn.label = nil,nil,nil,nil,nil
	kn.indices,kn.groupStyle,kn.labelStyle,kn.scale = false,"pass",nil,1
	kn.indicesstart = 0

	kn.opts = kn.processOpts(content)
end


function karnaugh.start(content)
	kn.started = true;

	local opts = kn.processOpts(content)

	kn.data,kn.groups,kn.notes,kn.conns = nil,nil,nil,nil

	-- I have to compare to nil because it is a boolean
	if opts.indices==nil and kn.opts.indices==nil then kn.indices = false
	elseif opts.indices==nil then kn.indices = kn.opts.indices
	else kn.indices = opts.indices end
	kn.groupStyle = opts.groupStyle or kn.opts.groupStyle or "pass"
	kn.labelStyle = opts.labelStyle or kn.opts.labelStyle or nil
	kn.scale = opts.scale or kn.opts.scale or 1
	print(kn.label, kn.scale, opts.scale, kn.opts.scale)
	kn.indicesstart = opts.indicesstart or kn.opts.indicesstart or 0

	kn.height = opts.height or kn.opts.height or nil
	kn.width = opts.width or kn.opts.width or nil
	kn.vVars = opts.vVars or kn.opts.vVars or nil
	kn.hVars = opts.hVars or kn.opts.hVars or nil
	kn.label = opts.label or kn.opts.label or nil

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


function karnaugh.checkArrSize(arr, msg)
	-- This ignores a trailing comma
	if #arr < kn.width*kn.height or #arr > kn.width*kn.height+1 or
			(#arr == kn.width*kn.height+1 and arr[#arr] ~= "") then
		error("Wrong number of "..msg.." elements, try clearing the global options if they are not needed")
	end
end

function karnaugh.processData(buffer)
	if not kn.started then error("Where is my Karnaugh environment?") end
	if kn.width and kn.height then
		local arr = utilities.parsers.settings_to_array(buffer)
		for i=1, #arr, 1 do -- Remove leading and trailing spaces
			arr[i] = arr[i]:gsub("^%s+", ""):gsub("%s+$", "") end
		kn.checkArrSize(arr, "data")
		local data = {}
		for y = 1, kn.height, 1 do
			data[y] = {}
			for x = 1, kn.width, 1 do
				data[y][x] = arr[(y-1) * kn.width + x]
			end
		end
		kn.data = data
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


function karnaugh.setTableData(content)
	if not kn.started then error("Where is my Karnaugh environment?") end
	local data = {}
	if #content == 1 then
		local str = content[1]
		for i = 1, str:len(), 1 do
			content[i] = str:sub(i, i)
		end
	end

	if not kn.width or not kn.height then
		local nVars = math.log(#content) / math.log(2)
		if nVars % 2 == 0 then
			kn.width, kn.height = nVars/2, nVars/2
		else
			kn.width = math.sqrt(2^(nVars+1))
			kn.height = kn.width / 2
		end
		kn.calculateOptionals()
	end

	kn.checkArrSize(content, "data")
	for y = 0, kn.height-1, 1 do
		data[y+1] = {}
		for x = 0, kn.width-1, 1 do
			local pos = ((y ~ (y >> 1)) << #kn.hVars) + (x ~ (x >> 1))
			data[y+1][x+1] = content[pos+1]:gsub("^%s+", ""):gsub("%s+$", "")
		end
	end
	karnaugh.data = data
end

function karnaugh.setMintermsData(content)
	if not kn.started then error("Where is my Karnaugh environment?") end
	karnaugh.setTermsData(content, "1", "0")
end
function karnaugh.setMaxtermsData(content)
	if not kn.started then error("Where is my Karnaugh environment?") end
	karnaugh.setTermsData(content, "0", "1")
end

function karnaugh.setTermsData(content, normal, negated)
	local data = {}
	for y = 0, kn.height-1, 1 do
		data[y+1] = {}
		for x = 0, kn.width-1, 1 do
			local pos = ((y ~ (y >> 1)) << #kn.hVars) + (x ~ (x >> 1))
			for i, val in pairs(content) do
				if tonumber(val) - kn.indicesstart == pos then
					data[y+1][x+1] = normal
				elseif tonumber(val) - kn.indicesstart >=
						kn.width*kn.height then
					error("Invalid minterm/maxterm")
				end
			end
		end
	end
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			if not data[y][x] then data[y][x] = negated end
		end
	end
	karnaugh.data = data
end


function karnaugh.processGroups(buffer)
	if not kn.started then error("Where is my Karnaugh environment?") end
	local arr = utilities.parsers.settings_to_array(buffer)
	local grArr, labelArr, sConnArr, dConnArr = {}, {}, {}, {}
	for i=1, #arr, 1 do
		arr[i] = arr[i]:gsub("%s", "")     -- Remove all spaces
		labelArr[i] = arr[i]:gsub("[^%a%*]", "") -- Leave the asterisks
		dConnArr[i] = arr[i]:gsub("[^%a%-]", "") -- Leave the dashes
		sConnArr[i] = arr[i]:gsub("[^%a%+]", "") -- Leave the pluses
		grArr[i]    = arr[i]:gsub("[^%a]", "")   -- Just Letters
	end
	kn.checkArrSize(grArr, "group")
	kn.setGroups(grArr) -- Just the letters
	kn.setNotes(labelArr) -- Letters and asterisks
	kn.setConnections(dConnArr, sConnArr) -- Letters and dashes/pluses
end


function karnaugh.setConnections(dConnArr, sConnArr)
	if #dConnArr == 0 or #sConnArr == 0 then
		return false
	end

	local conns = {}
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			local cell = dConnArr[(y-1) * kn.width + x]
			for gr in cell:gmatch("(%a)%-") do
				conns[gr] = conns[gr] or {}
				conns[gr].dst = conns[gr].dst or {}
				conns[gr].dst[#conns[gr].dst+1] = {oy=y, ox=x}
			end
			local cell = sConnArr[(y-1) * kn.width + x]
			for gr in cell:gmatch("(%a)%+") do
				conns[gr] = conns[gr] or {}
				conns[gr].src = {y=y, x=x}
			end
		end
	end

	karnaugh.conns = conns
end


function karnaugh.setNotes(content)
	local notes = {}
	for y = 1, kn.height, 1 do
		notes[y] = {}
		for x = 1, kn.width, 1 do
			notes[y][x] = {}
			local cell = content[(y-1) * kn.width + x]
			for gr in cell:gmatch("(%a)%*") do
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
			groups[y][x].d = {} -- Directions for each cell and group
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
end


function karnaugh.processGroup(gr, y, x, yf, xf, ch)
	function offset(v, vf, lim)
		vs = v + vf
		if vs > lim then return 1, true
		elseif vs == 0 then return lim, true end
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
				ys, overY = offset(ys, -yf, kn.height) -- Look the
				xs, overX = offset(xs, -xf, kn.width)  -- other way
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
	if not kn.started then error("Where is my Karnaugh environment?") end
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for g, v in pairs(kn.notes[y][x]) do
				if (gr == g) then
					dir = dir:gsub("%s+", "") -- Remove all spaces
					kn.notes[y][x][g][1] = dir
					kn.notes[y][x][g][2] = note
				end
			end
		end
	end
end




---------------------------------------------------------------------

                        -- DRAWING FUNCTIONS --

---------------------------------------------------------------------




function karnaugh.drawMap()
	if not kn.started then error("Where is my Karnaugh environment?") end
	metafun.start()
	--metafun("interim bboxmargin := 0;")

	if kn.indices == true and kn.groups then
		-- More space if the small spacing is selected, and the size is
		-- not that much bigger than with no indices with big spacing
		metafun("size := %s*1.6*LineHeight;", kn.scale*0.6+0.4)
	else
		metafun("size := %s*1.25*LineHeight;", kn.scale)
	end
	karnaugh.drawGrid()
	karnaugh.drawData()
	if kn.groups then
		karnaugh.drawGroups()
		if kn.conns then
			karnaugh.drawConnections()
		end
	end
	if kn.notes then
		karnaugh.drawNotes()
	end
	--metafun("draw bbox currentpicture withpen pencircle scaled 1pt;")
	metafun.stop()

	kn.started = false;
end


function karnaugh.drawGrid()
	-- Labels
	metafun([[pickup pencircle scaled 0.3mm;]])
	if kn.labelStyle == "corner" then
		local length;
		if #kn.vVars >= #kn.hVars then
			length = 2 + (#kn.vVars-2) / 2
		else
			length = 2 + (#kn.hVars-2) / 2
		end
		metafun([[draw origin -- (-%s*LineHeight, %s*LineHeight);]],
			length, length)
		
		for i = 1, #kn.vVars, 1 do
			metafun([[label.llft(textext("{%s}"),
				(-%s*LineHeight, %s*LineHeight));]],
				--This one looks better with indices, but worse without
				--kn.vVars[#kn.vVars-i+1], 0.8*i-0.2, 0.8*i+0.1)
				kn.vVars[#kn.vVars-i+1], 0.8*i, 0.8*i)
		end
		for i = 1, #kn.hVars, 1 do
			metafun([[label.urt(textext("{%s}"),
				(-%s*LineHeight, %s*LineHeight));]],
				--kn.hVars[#kn.hVars-i+1], 0.8*i+0.2, 0.8*i)
				kn.hVars[#kn.hVars-i+1], 0.8*i, 0.8*i)
		end

		if kn.label then
			-- Map's label
			metafun([[label.top(textext("{%s}"), (%s*size, 0.8size));]],
				kn.label, kn.width/2)
		end

	elseif kn.labelStyle == "edge" then
		local str = ""
		for i = 1, #kn.hVars, 1 do str = str .. " " .. kn.hVars[i] end
		metafun([[draw thelabel.top(textext("{%s}"), (0, 0))
			shifted(%s*size, LineHeight);]],
			str, kn.width/2)
		str = ""
		for i = 1, #kn.vVars, 1 do str = str .. " " .. kn.vVars[i] end
		metafun([[draw thelabel.top(textext("{%s}"), (0, 0))
			rotated(90) shifted((-1-%s)*LineHeight, %s*size);]],
			str, (#kn.vVars/4), -kn.height/2)
		if kn.label then
			-- Map's label
			metafun([[label.ulft(textext("{%s}"), (-0.2size, 0.2size));]],
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
	local graysize = "tfx" -- Gray code is small
	if kn.width > 4 or kn.height > 4 then graysize="tfxx" end -- Smaller
	if kn.indices == true and kn.groups then
		graysize="tfx" end -- There actially is space
	for y = 0, kn.height-1, 1 do
		metafun([[label.lft(textext("{\%s %s}"), (-0.1*size, -%s*size));]],
		graysize, kn.numToGray(y, #kn.vVars), (0.5 + y))
	end
	for x = 0, kn.width-1, 1 do
		metafun([[label.top(textext("{\%s %s}"), (%s*size, 0.1*size));]],
		graysize, kn.numToGray(x, #kn.hVars), (0.5 + x))
	end
end


function karnaugh.drawData()
	for y = 0, kn.height-1, 1 do
		for x = 0, kn.width-1, 1 do
			if kn.data and kn.indices == false then
				metafun([[label(textext("{%s}"), (%s*size,-%s*size));]],
					kn.data[y+1][x+1], x+0.5, y+0.5)
			elseif kn.indices == true then
				local offset = 0
				if kn.groups then offset = 0.07 end
				local pos = ((y ~ (y >> 1)) << #kn.hVars) + (x ~ (x >> 1))
						+ kn.indicesstart
				metafun([[draw thelabel(textext("{\tfxx %s}"),
					(%s*size, -%s*size)) withcolor(0.33white);]],
					pos, x+0.33+offset, y+0.33)
				if kn.data then
					metafun([[label(textext("{%s}"), (%s*size,-%s*size));]],
						kn.data[y+1][x+1], x+0.62, y+0.62)
				end
			end
		end
	end
end



local p = { -- Clockwise: i initial f final
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
	metafun([[pickup pencircle scaled(0.06*size);]])
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
							x, y, kn.colors[gr] or "black")
					end
				end
			end
		end
	end

	for gr, str in pairs(arr) do -- Draw all cells of a group at once
		metafun(str)
	end

	metafun([[interim linecap := rounded;]])
end


function karnaugh.drawConnections()
	-- For every group that has connections
	for gr, data in pairs(kn.conns) do
		-- There can be many destinations
		for i, coor in pairs(data.dst) do
			-- Just one source: data.src.y, data.src.x
			local y , x  = data.src.y, data.src.x
			local oy, ox = coor.oy,    coor.ox

			-- This determines whether the curve should go to the left
			-- (if the groups connnect to the right) or to the bottom
			-- (if the groups connect to the top)
			local negx, negy = 1, 1
			for i, dir in pairs(kn.groups[y][x].d[gr]) do
				for oi, odir in pairs(kn.groups[oy][ox].d[gr]) do
					if dir:lower() == "r" and odir:lower() == "r" then
						negx = -1
					end
					if dir:lower() == "t" and odir:lower() == "t" then
						negy = -1
					end
				end
			end

			-- Determines the direction of the part we are to connect to
			local dirS, dirD = "", ""
			if oy < y then dirS=dirS.."t" dirD=dirD.."b"
			elseif oy > y then dirS=dirS.."b" dirD=dirD.."t"
			end
			if ox < x then dirS=dirS.."l" dirD=dirD.."r"
			elseif ox > x then dirS=dirS.."r" dirD=dirD.."l"
			end
			-- And we offset the starting and ending points accordingly
			-- To be on the group's line's edge
			y , x  = kn.directionsoffsets(dirS,  y,  x)
			oy, ox = kn.directionsoffsets(dirD, oy, ox)

			-- Calculate 3 middle point to get a curve that starts turning
			-- quiclky and then is mostly flat during most of the travel
			local dy, dx = oy - y, ox - x
			local angle = math.abs(math.atan(dy / dx))
			local yoff = negy * 0.35 * math.sin(angle - math.pi / 2)
			local xoff = negx * 0.35 * math.cos(angle - math.pi / 2)
			local midy, midx = dy * 0.5 + y, dx * 0.5 + x
			local newy, newx = midy + yoff*1.1, midx + xoff*1.1
			local midy1, midx1 = dy * 0.2 + y, dx * 0.2 + x
			local newy1, newx1 = midy1 + yoff*0.9, midx1 + xoff*0.9
			local midy2, midx2 = dy * 0.8 + y, dx * 0.8 + x
			local newy2, newx2 = midy2 + yoff*0.9, midx2 + xoff*0.9

			-- This "disables" the origin offset for diagonals, smoothly
			local multiplier = 0.5 * (1-math.sin(2*angle))^4
			-- Move the origin points by an offset, to get them further
			-- apart from the content of nearby cells
			x, ox = x + xoff * multiplier, ox + xoff * multiplier
			y, oy = y + yoff * multiplier, oy + yoff * multiplier

			metafun([[draw (%s*size,-%s*size)..(%s*size,-%s*size)..
				(%s*size,-%s*size)..(%s*size,-%s*size)..
				(%s*size,-%s*size)]]..kn.color..";",
				x, y, newx1, newy1, newx, newy, newx2, newy2, ox, oy,
				kn.colors[gr] or "black")
		end
	end
end



function karnaugh.directionsoffsets(dir, y, x)
	    if dir == "tr" then return y-0.8, x-0.2
	elseif dir == "tl" then return y-0.8, x-0.8
	elseif dir == "br" then return y-0.2, x-0.2
	elseif dir == "bl" then return y-0.2, x-0.8
	elseif dir == "lb" then return y-0.2, x-0.8
	elseif dir == "lt" then return y-0.8, x-0.8
	elseif dir == "rb" then return y-0.2, x-0.2
	elseif dir == "rt" then return y-0.8, x-0.2
	elseif dir == "r"  then return y-0.5, x-0.1
	elseif dir == "b"  then return y-0.1, x-0.5
	elseif dir == "l"  then return y-0.5, x-0.9
	elseif dir == "t"  then return y-0.9, x-0.5
	end
end


function karnaugh.directionsdestinations(dir, y, x)
	    if dir == "tr" then return -1, x
	elseif dir == "Tr" then return -2, x
	elseif dir == "tl" then return -1, x-1
	elseif dir == "Tl" then return -2, x-1
	elseif dir == "br" then return kn.height+0.7, x
	elseif dir == "Br" then return kn.height+1.7, x
	elseif dir == "bl" then return kn.height+0.7, x-1
	elseif dir == "Bl" then return kn.height+1.7, x-1
	elseif dir == "lb" then return y, -1
	elseif dir == "lt" then return y-1, -1
	elseif dir == "rb" then return y, kn.width+0.7
	elseif dir == "rt" then return y-1, kn.width+0.7
	elseif dir == "r"  then return y-0.5, kn.width+0.7
	elseif dir == "b"  then return kn.height+0.7, x-0.5
	end
end


function karnaugh.drawNotes()
	for y = 1, kn.height, 1 do
		for x = 1, kn.width, 1 do
			for gr, v in pairs(kn.notes[y][x]) do
				local dir, note = v[1], v[2]
				local dsty, dstx = kn.directionsdestinations(dir, y, x)
				local srcy, srcx = kn.directionsoffsets(dir:lower(), y, x)
				
				metafun([[drawarrow (%s*size, %s*size)--(%s*size, %s*size)]]
					.. kn.color .. ";", srcx, -srcy, dstx, -dsty,
					kn.colors[gr] or "black")
				
				local posTable = {["t"] = "top", ["b"] = "bot",
					["l"] = "lft", ["r"] = "rt"}
				metafun([[label.%s(textext("{%s}"), (%s*size, %s*size));]],
					posTable[dir:sub(1, 1):lower()], note, dstx, -dsty)
				
			end
		end
	end
end


