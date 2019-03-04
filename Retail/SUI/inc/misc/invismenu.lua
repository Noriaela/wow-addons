local movable = true
MainMenuBarPerformanceBar:Hide()

if movable == true then

	CharacterMicroButton:SetClampedToScreen(false)
	CharacterMicroButton:SetMovable(true)
	CharacterMicroButton:SetUserPlaced(true)
	CharacterMicroButton:SetScript(
		"OnMouseDown",
		function()
			if (IsAltKeyDown()) then
				CharacterMicroButton:ClearAllPoints()
				CharacterMicroButton:StartMoving()
			end
			if show == nil then
				ShowUIPanel(CharacterFrame)
				show = 1
			elseif show == 1 then
				HideUIPanel(CharacterFrame)
				show = nil
			end
		end
	)
	CharacterMicroButton:SetScript(
		"OnMouseUp",
		function()
			CharacterMicroButton:StopMovingOrSizing()
		end
	)
end

local CF=CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

if not SUIDB.A_INVISBAGS == true then
	CharacterMicroButton:ClearAllPoints()
	CharacterMicroButton:SetPoint('BOTTOMLEFT', MicroButtonAndBagsBar, "BOTTOMLEFT", 6, 3)
	return
elseif SUIDB.A_CLASSICUI == true then return
end

MicroButtonAndBagsBar:Hide()

local ignore

local function setAlpha(b, a)
	if ignore then return end
	ignore = true
	if b:IsMouseOver() then
		b:SetAlpha(1)
	else
		b:SetAlpha(0)
	end
	ignore = nil
end

local function showFoo(self)
    for _, v in ipairs(MICRO_BUTTONS) do
        ignore = true
        _G[v]:SetAlpha(1)
        ignore = nil
    end
end

local function hideFoo(self)
    for _, v in ipairs(MICRO_BUTTONS) do
        ignore = true
        _G[v]:SetAlpha(0)
        ignore = nil
    end
end

for _, v in ipairs(MICRO_BUTTONS) do
    v = _G[v]
    hooksecurefunc(v, "SetAlpha", setAlpha)
    v:HookScript("OnEnter", showFoo)
    v:HookScript("OnLeave", hideFoo)
    v:SetAlpha(0)
end

end)