-- Copyright (C) 2021  VicSanRoPe

-- This work is licensed under the
-- Creative Commons Attribution-ShareAlike 4.0 International License.
-- To view a copy of this license, visit
-- http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to
-- Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.


-- Way too much code for a cover, I know...

local pi, rad, deg, sin, cos, atan2, sqrt =
	math.pi, math.rad, math.deg, math.sin, math.cos, math.atan2, math.sqrt
math.randomseed(1) for i=1, 10, 1 do math.random() end



local origin = {y=0, x=0, dir, odir, p={}} -- Origin point


-- Better than no distance checking (it does space the lines a bit)
-- but this is not actually the right distancce to measure
function tooClose(point, orig)
	for _, pt in pairs(orig.p) do
		local dist = sqrt((pt.x-point.x)^2+(pt.y-point.y)^2)
		if dist < 0.4 then return true
		elseif tooClose(point, pt) then return true end
	end
	return false
end


function makePoint(o, angleOffset)
	function doMakePoint(o, angleOffset)
		local direction = o.dir + angleOffset
		local point = {dir = direction, odir = o.odir, p = {},
			y = o.y + sin(rad(direction)),
			x = o.x + cos(rad(direction))}
		if not tooClose(point, origin) then return point end
	end


	local pointA = doMakePoint(o, angleOffset)
	local pointB = doMakePoint(o, -angleOffset)

	if pointA and not pointB then return pointA
	elseif pointB and not pointA then return pointB end

	-- if we care or not about the angle
	if math.random() < 0.8 and pointA and pointB then
		local dAngleA = math.abs(deg(atan2(pointA.y, pointA.x)) - o.odir)
		local dAngleB = math.abs(deg(atan2(pointB.y, pointB.x)) - o.odir)
		if dAngleA < dAngleB then return pointA
		else return pointB end
	elseif pointA then return pointA end
end



function nextRound(orig)
	if orig.p[1] == nil then
		if math.random() < 0.2 then
			orig.p[1] = makePoint(orig, -45)
			orig.p[2] = makePoint(orig, 45)
		else
			orig.p[1] = makePoint(orig, math.random(-1, 1) * 45)
		end
	else
		for _, point in pairs(orig.p) do
			nextRound(point)
		end
	end
end




function drawPoints(o) -- o = origin
	for _, p in pairs(o.p) do -- p = point
		context("draw (%.3f, %.3f)--(%.3f, %.3f);",
			o.x, o.y, p.x, p.y)
		drawPoints(p)
	end
end




-- This will fill the origin point with more points than the others
for dir=-180, 180-45, 45 do
	origin.p[#origin.p+1] = {
		y = sin(rad(dir)), x = cos(rad(dir)), dir = dir, odir = dir, p = {}}
	-- odir = original direction
	-- p = point array, all the points this one connects to
end

for i=1, 25, 1 do nextRound(origin) end

-- Actual drawing here

context([[\startuseMPgraphic{cover} StartPage;]])

context("picture pic; pic = image(")
drawPoints(origin)
context(");")

context([[fill unitsquare xscaled(OverlayWidth) yscaled(OverlayHeight)
	withcolor(0.1white);]])

context([[
		draw pic scaled(1cm) shifted(OverlayWidth/2,12.5cm)
	withcolor(0.5blue) withpen pencircle scaled(3mm);
		draw pic scaled(1cm) shifted(OverlayWidth/2,12.5cm)
	withcolor(0.5green) withpen pencircle scaled(1.5mm);
]])

context([[
	draw image (
		draw anchored.top(textext("\bf\CONTEXT")
			ysized 3.7cm, (OverlayWidth/2,OverlayHeight-1.5cm)) ;
		draw anchored.urt(textext("\bf\type{Karnaugh}")
			ysized 2.5cm, urcorner Page shifted (-1.5cm,-6cm)) ;
		draw anchored.urt(textext("\bf user module")
			ysized 0.8cm, urcorner Page shifted (-1.5cm,-9cm)) ;
		draw anchored.urt(textext("\bf VicSanRoPe")
			ysized 1.2cm,lrcorner Page shifted (-1cm, 5cm)) ;
		draw anchored.urt(textext("\bf v1.1.0")
			ysized 0.8cm,lrcorner Page shifted (-1cm, 3cm)) ;
	) withcolor white;

	fill fullsquare smoothed(0.1) yscaled(12cm) xscaled(13cm)
		shifted(OverlayWidth/2,12.5cm) withcolor(white);
	draw fullsquare smoothed(0.1) yscaled(12cm) xscaled(13cm)
		shifted(OverlayWidth/2,12.5cm) withcolor(0.8blue)
		withpen pencircle scaled(2mm);
]])

context([[StopPage; \stopuseMPgraphic]])
