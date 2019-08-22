local Graph = LibStub:GetLibrary("LibGraph-2.0")
SLD = {}

local curTime = 0
local dmgTimes = {}
local nTimes = 10000
local damages = {}
local frontIndex = 1
local backIndex = 1
local deltaT = 3
local deltaTRamp = 0.5
local g = {}
local liveDps = 0


function SLD:OnLoad()	
	-- Create the graph ((0,0,250,150) = (posx, posy, width, height))
	g = Graph:CreateGraphRealtime("TestRealtimeGraph", UIParent, "CENTER", "CENTER", 0, 0, 250, 150)
	g:SetAutoScale(true)
	g:SetGridSpacing(20, 100.0)
	g:SetYMax(1)
	g:SetXAxis(-10, 0)
	g:SetMode("RAW")
	g:SetYLabels(true,true)
	g:SetBarColors({0.2, 0.0, 0.0, 0.4}, {1.0, 0.0, 0.0, 1.0})
	
	--adding text to the graph ((0 -85) = (posx posy) of the text relatively to the center of the graph)
	g.text = g:CreateFontString(nil,"ARTWORK") 
	g.text:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
	g.text:SetPoint("CENTER",0,-85)
end


function SLD:UpdateDpsGraph()
	curTime=GetTime()
	local curDmg = 0
	local skada = _G.Skada
	local set = skada.total
	local player = skada:get_player(set,UnitGUID("player"),UnitName("player"))
	local curDmg = player.damage
	dmgTimes[frontIndex] = curTime
	damages[curTime] = curDmg
	frontIndex = (frontIndex)%nTimes +1
	
	-- fetch the first time value > curTime-deltaT (and clear the hashmap of the values older than that)
	while dmgTimes[backIndex] < curTime-deltaT do
		damages[dmgTimes[backIndex]]=nil
		backIndex = (backIndex)%nTimes +1
	end
	
	-- CALCULATE THE AVERAGE DPS WEIGHTED BY A TRAPEZOID KIND OF THING
	local deltaDmge = 0
	liveDps = 0
	-- only if front != back (useful to avoid nil values when entering the game (or reloading))
	if frontIndex ~= backIndex then
		--itgtIndex will go from backIndex to frontIndex and we'll increase deltaDmge (by itgtMult * difference of dmg between two consecutive values)
		local itgtIndex = backIndex+1
		local oldDmg = damages[dmgTimes[backIndex]]
		
		if dmgTimes[itgtIndex] then
			--upward ramp
			while dmgTimes[itgtIndex] < curTime-deltaT+deltaTRamp do
				local itgtTime = dmgTimes[itgtIndex]
				-- itgtMult goes linearly from 0 to 1
				local itgtMult = (deltaT-(curTime-itgtTime))/deltaTRamp
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				itgtIndex = (itgtIndex)%nTimes +1
			end	
			--flat part at the top of the ramp
			while dmgTimes[itgtIndex] < curTime-deltaTRamp do
				local itgtTime = dmgTimes[itgtIndex]
				local itgtMult = 1
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				itgtIndex = (itgtIndex)%nTimes +1
			end	
			--downward ramp
			while dmgTimes[itgtIndex] < curTime do
				local itgtTime = dmgTimes[itgtIndex]
				-- itgtMult goes linearly from 1 to 0
				local itgtMult = (curTime-itgtTime)/deltaTRamp
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				itgtIndex = (itgtIndex)%nTimes +1
			end	
			liveDps = (deltaDmge)/(deltaT-deltaTRamp)/1000
		
		end
	end
	
	--add the value to the graph and add text under it
	g:AddBar(liveDps)
	g.text:SetText(floor(liveDps*1000))
	
end