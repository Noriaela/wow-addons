local CF=CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

local debug = true
local font = STANDARD_TEXT_FONT
local backdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	TedgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = {
		left = 1,
		right = 1,
		top = 1,
		bottom = 1
	}
}

--SUIEDIT FUNCTION
local activ = false
function SUIEDIT()

if activ == true then return end

activ = true
--FRAME
local function SUICreateFrame(text,name,size1,size2,target)
	frame = CreateFrame("Button", name, target, "UIPanelInfoButton")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(0, 0, 0, 1)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetSize(size1, size2)
	frame.text = frame:CreateFontString(nil,"ARTWORK")
	frame.text:SetFont(font, 13, "OUTLINE")
	frame.text:SetPoint("CENTER",0,0)
	frame.text:SetText(text)
	frame:ClearAllPoints()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("RightButton")
	frame:SetScript("OnDragStart",self.StartMoving)
end

--OPTIONFRAME
local function SUICreateOptionFrame(text,name,size1,size2,target)
	frame = CreateFrame("Frame", name, target , "BasicFrameTemplate")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropBorderColor(0, 0, 0, 1)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetSize(size1, size2)
	frame.text = frame:CreateFontString(nil,"ARTWORK")
	frame.text:SetFont(font, 13, "OUTLINE")
	frame.text:SetPoint("TOP",0,-4)
	frame.text:SetText(text)
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOM",0,50)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart",function(self)self:StartMoving()end)
	frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)

    if SUIDB.A_DARKFRAMES == true then
		for i, v in pairs(
		{
			frame.TopBorder,
			frame.BottomBorder,
			frame.RightBorder,
			frame.LeftBorder,
			frame.TopLeftCorner,
			frame.TopRightCorner,
			frame.BotLeftCorner,
			frame.BotRightCorner,
		}
		) do
			v:SetVertexColor(.30, .30, .30)
		end
	end

end

--BUTTON
local function SUICreateBTN(text,point1,anchor,point2,pos1,pos2,width,height)
	frame = CreateFrame("Button", nil, anchor, "UIPanelButtonTemplate")
	frame:SetPoint(point1, anchor, point2, pos1, pos2)
	frame:SetWidth(width)
	frame:SetHeight(height)
	frame:SetText(text)
end

--INPUTBOX
local function SUICreateIB(text,name,point1,anchor,point2,pos1,pos2,width,height)
 	frame = CreateFrame("EditBox", name, anchor, "InputBoxTemplate")
	frame.text = frame:CreateFontString(nil,"ARTWORK")
	frame.text:SetFont(font, 13, "OUTLINE")
	frame.text:SetPoint("Left",-20,0)
	frame.text:SetText(text)
	frame:SetPoint(point1, anchor, point2, pos1, pos2)
	frame:SetWidth(width)
	frame:SetHeight(height)
	frame:SetAutoFocus(false)
	frame:SetText("test")
end

--CHECKBOX
local function SUICreateCB(name,point1,anchor,point2,pos1,pos2,tooltip)
	frame = CreateFrame("CheckButton", nil , anchor, "OptionsBaseCheckButtonTemplate")
	frame:SetPoint(point1, anchor, point2, pos1, pos2)

	frame:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(tooltip, 248, 248, 255)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", GameTooltip_Hide)

	frame.text = frame:CreateFontString(nil,"GameFontHighlight")
	frame.text:SetFont(font, 13, "OUTLINE")
	frame.text:SetPoint("LEFT", frame, "RIGHT", 0, 1)
	frame.text:SetText(name)
end

--SLIDER
local function SUICreateSL(name,point1,anchor,point2,pos1,pos2,width,height)
	frame = CreateFrame("Slider",name,anchor,"OptionsSliderTemplate")
	frame:SetPoint(point1, anchor, point2, pos1, pos2)
	frame.textLow = _G[name.."Low"]
	frame.textHigh = _G[name.."High"]
	frame.text = _G[name.."Text"]
	frame:SetMinMaxValues(1, 100)
	frame.minValue, frame.maxValue = frame:GetMinMaxValues()
	frame.textLow:SetText(frame.minValue)
	frame.textHigh:SetText(frame.maxValue)
	frame.text:SetText(name)
	frame:SetValueStep(1)
	frame.stepValue = 1
end

--SUIEDIT OPTION FRAMES

--PLAYERUNIT OPTION FRAME
local function SUICreatePlayerUnitOptions()
	SUICreateOptionFrame("PlayerUnitFrame-Options","PUnitOptions",250,150,SUIPlayerUnitFrame)

	SUICreateCB("Class Colors","TOPLEFT",PUnitOptions,"TOPLEFT",5,-30,"UnitFrames Class Colors")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.UNITFRAMES.CLASSCOLOR = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("ClassColor Enabled", 0, 1, 0)
			SUIDB.UNITFRAMES.CLASSCOLOR = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("ClassColor Disabled", 1, 0, 0)
			SUIDB.UNITFRAMES.CLASSCOLOR = false
		end
	end)
	frame:SetChecked(SUIDB.UNITFRAMES.CLASSCOLOR)

	SUICreateCB("Hide Background","TOPLEFT",PUnitOptions,"TOPLEFT",5,-60,"UnitFrames Background")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.UNITFRAMES.HIDEBACK = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("Hide Background Enabled", 0, 1, 0)
			SUIDB.UNITFRAMES.HIDEBACK = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("Hide Background Disabled", 1, 0, 0)
			SUIDB.UNITFRAMES.HIDEBACK = false
		end
	end)
	frame:SetChecked(SUIDB.UNITFRAMES.HIDEBACK)

	SUICreateCB("Hide Stuff","TOPLEFT",PUnitOptions,"TOPLEFT",5,-90,"Rest glow Prestige Icon etc")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.UNITFRAMES.HIDESTUFF = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("Hide Stuff Enabled", 0, 1, 0)
			SUIDB.UNITFRAMES.HIDESTUFF = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("Hide Stuff Disabled", 1, 0, 0)
			SUIDB.UNITFRAMES.HIDESTUFF = false
		end
	end)
	frame:SetChecked(SUIDB.UNITFRAMES.HIDESTUFF)

	SUICreateBTN("Save","BOTTOMLEFT",PUnitOptions,"BOTTOMLEFT",5,5,70,25)
	frame:SetScript("OnClick",function(self, button, down)

		PUnitOptions:Hide()
	end)
end

--TARGETUNIT OPTION FRAME
local function SUICreateTargetUnitOptions()
	SUICreateOptionFrame("TargetUnitFrame-Options","TUnitOptions",250,150,SUITargetUnitFrame)

	SUICreateSL("LBuffSlider","TOPLEFT",TUnitOptions,"TOPLEFT",15,-40,120,25)
	frame:SetValue(SUIDB.UNITFRAMES.LBUFF)
	frame:SetScript("OnValueChanged", function(self,event,arg1)
		local halfStep = self.stepValue / 2
		event = event + halfStep - (event + halfStep) % self.stepValue -- faster than calling math.floor
		if event ~= SUIDB.UNITFRAMES.LBUFF then
		   LBuff:SetText(event)
		end
	end)
	SUICreateSL("SBuffSlider","TOPLEFT",TUnitOptions,"TOPLEFT",15,-90,120,25)
	frame:SetValue(SUIDB.UNITFRAMES.SBUFF)
	frame:SetScript("OnValueChanged", function(self,event,arg1)
		local halfStep = self.stepValue / 2
		event = event + halfStep - (event + halfStep) % self.stepValue -- faster than calling math.floor
		if event ~= SUIDB.UNITFRAMES.SBUFF then
		   SBuff:SetText(event)
		end
	end)
	SUICreateIB("","LBuff","TOPRIGHT",TUnitOptions,"TOPRIGHT",-10,-30,50,25)
	frame:SetText(SUIDB.UNITFRAMES.LBUFF)
	SUICreateIB("","SBuff","TOPRIGHT",TUnitOptions,"TOPRIGHT",-10,-90,50,25)
	frame:SetText(SUIDB.UNITFRAMES.SBUFF)

	SUICreateBTN("Save","BOTTOMLEFT",TUnitOptions,"BOTTOMLEFT",5,5,70,25)
	frame:SetScript("OnClick",function(self, button, down)
		SUIDB.UNITFRAMES.LBUFF = tonumber(LBuff:GetText())
		SUIDB.UNITFRAMES.SBUFF = tonumber(SBuff:GetText())
		TUnitOptions:Hide()
	end)
end

--PLAYERCASTBAR OPTION FRAME
local function SUICreatePlayerCastBarOptions()
	SUICreateOptionFrame("PlayerCastBar-Options","PCastBarOptions",230,120,SUIPlayerCastBarFrame)

	SUICreateIB("X","PCastBarX","TOPLEFT",PCastBarOptions,"TOPLEFT",25,-30,120,25)
	frame:SetText(SUIDB.PLAYERCASTBAR.X)
	SUICreateIB("Y","PCastBarY","TOPLEFT",PCastBarOptions,"TOPLEFT",25,-60,120,25)
	frame:SetText(SUIDB.PLAYERCASTBAR.Y)

	SUICreateCB("Timer","TOPRIGHT",PCastBarOptions,"TOPRIGHT",-50,-45,"test")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.PLAYERCASTBAR.TIMER = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("PlayerCastBar Timer Enabled", 0, 1, 0)
			SUIDB.PLAYERCASTBAR.TIMER = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("PlayerCastBar Timer Disabled", 1, 0, 0)
			SUIDB.PLAYERCASTBAR.TIMER = false
		end
	end)
	frame:SetChecked(SUIDB.PLAYERCASTBAR.TIMER)

	SUICreateBTN("Save","BOTTOMLEFT",PCastBarOptions,"BOTTOMLEFT",5,5,70,25)
	frame:SetScript("OnClick",function(self, button, down)
		SUIDB.PLAYERCASTBAR.X = tonumber(PCastBarX:GetText())
		SUIDB.PLAYERCASTBAR.Y = tonumber(PCastBarY:GetText())
		CastingBarFrame:SetPoint(SUIDB.PLAYERCASTBAR.POINT, MainMenuBar, SUIDB.PLAYERCASTBAR.RELPOINT, SUIDB.PLAYERCASTBAR.X, SUIDB.PLAYERCASTBAR.Y)
		SUIPlayerCastBarFrame:SetPoint("CENTER", CastingBarFrame, "CENTER", 0,0)
		PCastBarOptions:Hide()
	end)
end

--TARGETCASTBAR OPTION FRAME
local function SUICreateTargetCastBarOptions()
	SUICreateOptionFrame("TargetCastBar-Options","TCastBarOptions",230,120,SUITargetCastBarFrame)

	SUICreateIB("X","TCastBarX","TOPLEFT",TCastBarOptions,"TOPLEFT",25,-30,120,25)
	frame:SetText(SUIDB.TARGETCASTBAR.X)
	SUICreateIB("Y","TCastBarY","TOPLEFT",TCastBarOptions,"TOPLEFT",25,-60,120,25)
	frame:SetText(SUIDB.TARGETCASTBAR.Y)

	SUICreateCB("Timer","TOPRIGHT",TCastBarOptions,"TOPRIGHT",-50,-45,"test")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.TARGETCASTBAR.TIMER = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("TargetCastBar Timer Enabled", 0, 1, 0)
			SUIDB.TARGETCASTBAR.TIMER = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("TargetCastBar Timer Disabled", 1, 0, 0)
			SUIDB.TARGETCASTBAR.TIMER = false
		end
	end)
	frame:SetChecked(SUIDB.TARGETCASTBAR.TIMER)

	SUICreateBTN("Save","BOTTOMLEFT",TCastBarOptions,"BOTTOMLEFT",5,5,70,25)
	frame:SetScript("OnClick",function(self, button, down)
		SUIDB.TARGETCASTBAR.X = tonumber(TCastBarX:GetText())
		SUIDB.TARGETCASTBAR.Y = tonumber(TCastBarY:GetText())
		TargetFrameSpellBar:SetPoint(SUIDB.TARGETCASTBAR.POINT, MainMenuBar, SUIDB.TARGETCASTBAR.RELPOINT, SUIDB.TARGETCASTBAR.X , SUIDB.TARGETCASTBAR.Y)
		SUITargetCastBarFrame:SetPoint("CENTER", TargetFrameSpellBar, "CENTER", 0,0)
		TCastBarOptions:Hide()
	end)
end

--MINIMAP OPTION FRAME
local function SUICreateMinimapOptions()
	SUICreateOptionFrame("Minimap-Options","MinimapOptions",230,120,SUIMinimapFrame)

	SUICreateCB("Hide Icon","TOPLEFT",MinimapOptions,"TOPLEFT",5,-25,"test")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.MINIMAP.HIDEGARNI = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("HIDEGARNI Enabled", 0, 1, 0)
			SUIDB.MINIMAP.HIDEGARNI = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("HIDEGARNI Disabled", 1, 0, 0)
			SUIDB.MINIMAP.HIDEGARNI = false
		end
	end)
	frame:SetChecked(SUIDB.MINIMAP.HIDEGARNI)

	SUICreateCB("Old Icon","TOPLEFT",MinimapOptions,"TOPLEFT",5,-55,"test")
	frame:SetScript("OnClick",function(frame)
		local tick = frame:GetChecked()
		SUIDB.MINIMAP.OLDSYMBOL = tick
		if tick then
			DEFAULT_CHAT_FRAME:AddMessage("OLDSYMBOL Timer Enabled", 0, 1, 0)
			SUIDB.MINIMAP.OLDSYMBOL = true
		else
			DEFAULT_CHAT_FRAME:AddMessage("OLDSYMBOL Disabled", 1, 0, 0)
			SUIDB.MINIMAP.OLDSYMBOL = false
		end
	end)
	frame:SetChecked(SUIDB.MINIMAP.OLDSYMBOL)

	SUICreateBTN("Save","BOTTOMLEFT",MinimapOptions,"BOTTOMLEFT",5,5,70,25)
	frame:SetScript("OnClick",function(self, button, down)
		MinimapOptions:Hide()
	end)
end

--SUIEDIT DEFAULT FRAMES

--DEFAULT
SUICreateOptionFrame("SUI Edit","SUIEditFrame",250,100,UIParent)
frame:ClearAllPoints()
frame:SetPoint("CENTER", UIParent, ("CENTER"), 0, 0)
frame.text = frame:CreateFontString(nil,"GameFontHighlight")
frame.text:SetFont(font, 13, "OUTLINE")
frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
frame.text:SetText("LeftButton-Options RightButton-Drag")
SUICreateBTN("Save","BOTTOMLEFT",SUIEditFrame,"BOTTOMLEFT",5,5,70,25)
frame:SetScript("OnClick",function(self, button, down)
	ReloadUI()
end)

--PLAYER
local PUnitOptionsShow = 0
PlayerFrameWidth = PlayerFrame:GetWidth();
PlayerFrameHeight = PlayerFrame:GetHeight();
SUICreateFrame("Player UnitFrame","SUIPlayerUnitFrame",PlayerFrameWidth,PlayerFrameHeight,UIParent)
frame:SetPoint("CENTER", PlayerFrame, "CENTER", 0,0)
frame:SetScript("OnClick",function(self)
	if PUnitOptionsShow == 0 then
		SUICreatePlayerUnitOptions()
		PUnitOptionsShow = 1
	else
		PUnitOptions:Show()
	end
end)
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()
	PlayerFrame:ClearAllPoints()
	PlayerFrame:SetPoint("CENTER", SUIPlayerUnitFrame, "CENTER", 0,0)
	if debug then
		print(self:GetPoint())
	end
end)

--TARGET
local TUnitOptionsShow = 0
TargetFrameWidth = TargetFrame:GetWidth();
TargetFrameHeight = TargetFrame:GetHeight();
SUICreateFrame("Target UnitFrame","SUITargetUnitFrame",TargetFrameWidth,TargetFrameHeight,UIParent)
frame:SetPoint("CENTER", TargetFrame, "CENTER", 0,0)
frame:SetScript("OnClick",function(self)
	if TUnitOptionsShow == 0 then
		SUICreateTargetUnitOptions()
		TUnitOptionsShow = 1
	else
		TUnitOptions:Show()
	end
end)
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()
	TargetFrame:ClearAllPoints()
	TargetFrame:SetPoint("CENTER", SUITargetUnitFrame, "CENTER", 0,0)
	if debug then
		print(self:GetPoint())
	end
end)

--PLAYER CASTBAR
local PCastBarOptionsShow = 0
PlayerCastBarWidth = 250
PlayerCastBarHeight = 23
SUICreateFrame("Player Castbar","SUIPlayerCastBarFrame",PlayerCastBarWidth,PlayerCastBarHeight,UIParent)
frame:SetPoint("CENTER", CastingBarFrame, "CENTER", 0,0)
frame:SetMovable(false)
frame:SetScript("OnDragStart",self.StopMoving)
frame:SetScript("OnClick",function(self)
	if PCastBarOptionsShow == 0 then
		SUICreatePlayerCastBarOptions()
		PCastBarOptionsShow = 1
	else
		PCastBarOptions:Show()
	end
end)
--[[
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()
	CastingBarFrame:ClearAllPoints()
	CastingBarFrame:SetPoint("CENTER", SUIPlayerCastBarFrame, "CENTER", 0,0)
	SUIDB.PLAYERCASTBAR.POINT, UIParent, SUIDB.PLAYERCASTBAR.RELPOINT, SUIDB.PLAYERCASTBAR.X, SUIDB.PLAYERCASTBAR.Y = self:GetPoint();
	if debug then
		print(self:GetPoint())
	end
end)
--]]

--TARGET CASTBAR
local TCastBarOptionsShow = 0
TargetCastBarWidth = 250
TargetCastBarHeight = 23
SUICreateFrame("Target Castbar","SUITargetCastBarFrame",TargetCastBarWidth ,TargetCastBarHeight,UIParent)
frame:SetPoint("CENTER", TargetFrameSpellBar, "CENTER", 0,0)
frame:SetMovable(false)
frame:SetScript("OnDragStart",self.StopMoving)
frame:SetScript("OnClick",function(self)
	if TCastBarOptionsShow == 0 then
		SUICreateTargetCastBarOptions()
		TCastBarOptionsShow = 1
	else
		TCastBarOptions:Show()
	end
end)
--[[ not working because of resize to 1,3
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()
	TargetFrameSpellBar:ClearAllPoints()
	TargetFrameSpellBar:SetPoint("CENTER", SUITargetCastBarFrame, "CENTER", 0,0)
	SUIDB.TARGETCASTBAR.POINT, UIParent, SUIDB.TARGETCASTBAR.RELPOINT, SUIDB.TARGETCASTBAR.X, SUIDB.TARGETCASTBAR.Y = self:GetPoint();
	if debug then
		print(self:GetPoint())
	end
end)
--]]

--STATS
SUICreateFrame("FPS & MS","SUIStatsFrame",100,25,UIParent)
frame:SetScript("OnClick",function(self)
	SUICreatePlayerOptionFrame()
end)

--MINIMAP
local MinimapOptionsShow = 0
MinimapFrameWidth = Minimap:GetWidth();
MinimapFrameHeight = Minimap:GetHeight();
SUICreateFrame("Minimap","SUIMinimapFrame",MinimapFrameWidth,MinimapFrameHeight,UIParent)
frame:SetPoint("CENTER", Minimap, "CENTER", 0,0)
frame:SetScript("OnClick",function(self)
	if MinimapOptionsShow == 0 then
		SUICreateMinimapOptions()
		MinimapOptionsShow = 1
	else
		MinimapOptions:Show()
	end
end)
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()

	if debug then
		print(self:GetPoint())
	end
end)

--GRID
f = CreateFrame('Frame', nil, UIParent)
f:SetAllPoints(UIParent)
local w = GetScreenWidth() / 64
local h = GetScreenHeight() / 36
for i = 0, 64 do
	local t = f:CreateTexture(nil, 'BACKGROUND')
	if i == 32 then
		t:SetColorTexture(1, 1, 0, 0.5)
	else
		t:SetColorTexture(1, 1, 1, 0.15)
	end
	t:SetPoint('TOPLEFT', f, 'TOPLEFT', i * w - 1, 0)
	t:SetPoint('BOTTOMRIGHT', f, 'BOTTOMLEFT', i * w + 1, 0)
	f:SetFrameStrata("HIGH")
end
for i = 0, 36 do
	local t = f:CreateTexture(nil, 'BACKGROUND')
	if i == 18 then
		t:SetColorTexture(1, 1, 0, 0.5)
	else
		t:SetColorTexture(1, 1, 1, 0.15)
	end
	t:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -i * h + 1)
	t:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT', 0, -i * h - 1)
	f:SetFrameStrata("LOW")
end

end


end)
