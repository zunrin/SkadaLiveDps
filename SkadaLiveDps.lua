local Graph = LibStub:GetLibrary("LibGraph-2.0")
SLD = {}

local curTime = 0
local dmgTimes = {}
local nTimes = 10000
local damages = {}
local timesFront = 1
local timesBack = 1
local delta_t = 3
local delta_t_itgt = 0.5
local g = {}
local liveDps = 0


function SLD:OnLoad()	
	g = Graph:CreateGraphRealtime("TestRealtimeGraph", UIParent, "CENTER", "CENTER", 0, 0, 250, 150)
	g:SetAutoScale(true)
	g:SetGridSpacing(20, 100.0)
	g:SetYMax(1)
	g:SetXAxis(-10, 0)
	
	g:SetMode("RAW")
	g:SetYLabels(true,true)
	
	g:SetBarColors({0.2, 0.0, 0.0, 0.4}, {1.0, 0.0, 0.0, 1.0})
	g:SetGridColorSecondary({0.5,0.5,0.5,0.25})
	g.text = g:CreateFontString(nil,"ARTWORK") 
	g.text:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
	g.text:SetPoint("CENTER",0,-85)
end


function SLD:UpdateDpsGraph()
	curTime=GetTime()
	local dmg = 0
	local skada = _G.Skada
	local set = skada.total
	local player = skada:get_player(set,UnitGUID("player"),UnitName("player"))
	local dmg = player.damage
	dmgTimes[timesFront] = curTime
	damages[curTime] = dmg
	timesFront = (timesFront)%nTimes +1
	while dmgTimes[timesBack] < curTime-delta_t do
		damages[dmgTimes[timesBack]]=nil
		timesBack = (timesBack)%nTimes +1
	end
	local deltaDmge = 0
	liveDps = 0
	if timesFront ~= timesBack then
		local timesItgt = timesBack+1
		local oldDmg = damages[dmgTimes[timesBack]]
		
		if dmgTimes[timesItgt] then
			while dmgTimes[timesItgt] < curTime-delta_t+delta_t_itgt do
				local itgtTime = dmgTimes[timesItgt]
				local itgtMult = (delta_t-(curTime-itgtTime))/delta_t_itgt
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				timesItgt = (timesItgt)%nTimes +1
			end	
			while dmgTimes[timesItgt] < curTime-delta_t_itgt do
				local itgtTime = dmgTimes[timesItgt]
				local itgtMult = 1
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				timesItgt = (timesItgt)%nTimes +1
			end	
			while dmgTimes[timesItgt] < curTime do
				local itgtTime = dmgTimes[timesItgt]
				local itgtMult = (curTime-itgtTime)/delta_t_itgt
				deltaDmge = deltaDmge + itgtMult*(damages[itgtTime]-oldDmg)
				oldDmg = damages[itgtTime]
				timesItgt = (timesItgt)%nTimes +1
			end	
			liveDps = (deltaDmge)/(delta_t-delta_t_itgt)/1000
		
		end
	end
	g:AddBar(liveDps)
	g.text:SetText(floor(liveDps*1000))
	
end