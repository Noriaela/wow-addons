--[[
	tullaRange
		Adds out of range coloring to action buttons
		Derived from RedRange with negligable improvements to CPU usage
--]]

local E, L, V, P, G = unpack(ElvUI)

local _G = _G
local UPDATE_DELAY = 0.1

local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange
local IsUsableAction = IsUsableAction
local HasAction = HasAction

local tullaRange = CreateFrame("Frame", "tullaRange", UIParent)

function tullaRange:Load()
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnHide", self.OnHide)
	self:SetScript("OnEvent", self.OnEvent)
	self.elapsed = 0

	self:RegisterEvent("PLAYER_LOGIN")
end

function tullaRange:OnEvent()
	local action = this[event]
	if action then
		action(this, event)
	end
end

function tullaRange:OnUpdate()
	if this.elapsed < UPDATE_DELAY then
		this.elapsed = this.elapsed + arg1
	else
		this:Update()
	end
end

function tullaRange:OnHide()
	this.elapsed = 0
end

function tullaRange:PLAYER_LOGIN()
	if not TULLARANGE_COLORS then
		self:LoadDefaults()
	end
	self.colors = TULLARANGE_COLORS

	self.buttonsToUpdate = {}

	hooksecurefunc("ActionButton_OnUpdate", self.RegisterButton)
	hooksecurefunc("ActionButton_UpdateUsable", self.OnUpdateButtonUsable)
	hooksecurefunc("ActionButton_Update", self.OnButtonUpdate)
end

function tullaRange:Update()
	self:UpdateButtons(self.elapsed)
	self.elapsed = 0
end

function tullaRange:ForceColorUpdate()
	for button in pairs(self.buttonsToUpdate) do
		tullaRange.OnUpdateButtonUsable(button)
	end
end

function tullaRange:UpdateShown()
	if next(self.buttonsToUpdate) then
		self:Show()
	else
		self:Hide()
	end
end

function tullaRange:UpdateButtons(elapsed)
	if not next(self.buttonsToUpdate) then
		self:Hide()
		return
	end

	for button in pairs(self.buttonsToUpdate) do
		self:UpdateButton(button, elapsed)
	end
end

function tullaRange:UpdateButton(button, elapsed)
	tullaRange:UpdateButtonUsable(button)
end

function tullaRange:UpdateButtonStatus()
	local action = ActionButton_GetPagedID(this)
	if not(this:IsVisible() and action and HasAction(action) and ActionHasRange(action)) then
		self.buttonsToUpdate[this] = nil
	else
		self.buttonsToUpdate[this] = true
	end
	self:UpdateShown()
end

function tullaRange.RegisterButton()
	this:SetScript("OnShow", tullaRange.OnButtonShow)
	this:SetScript("OnHide", tullaRange.OnButtonHide)
	this:SetScript("OnUpdate", nil)

	tullaRange:UpdateButtonStatus(this)
end

function tullaRange.OnButtonShow()
	tullaRange:UpdateButtonStatus(this)
end

function tullaRange.OnButtonHide()
	tullaRange:UpdateButtonStatus(this)
end

function tullaRange:OnUpdateButtonUsable()
	this.tullaRangeColor = nil
	tullaRange:UpdateButtonUsable(this)
end

function tullaRange.OnButtonUpdate()
	tullaRange:UpdateButtonStatus(this)
end

function tullaRange:UpdateButtonUsable(button)
	local action = ActionButton_GetPagedID(button)
	local isUsable, notEnoughMana = IsUsableAction(action)

	if isUsable then
		if IsActionInRange(action) == 0 then
			tullaRange.SetButtonColor(button, "OOR")
		else
			tullaRange.SetButtonColor(button, "NORMAL")
		end
	elseif notEnoughMana then
		tullaRange.SetButtonColor(button, "OOM")
	else
		tullaRange.SetButtonColor(button, "UNUSABLE")
	end
end

function tullaRange.SetButtonColor(button, colorType)
	if button.tullaRangeColor ~= colorType then
		button.tullaRangeColor = colorType

		local r, g, b = tullaRange:GetColor(colorType)

		local icon = _G[button:GetName() .. "Icon"]
		icon:SetVertexColor(r, g, b)
	end
end

function tullaRange:LoadDefaults()
	TULLARANGE_COLORS = {
		["OOR"] = E:GetColorTable(E.db.actionbar.noRangeColor),
		["OOM"] = E:GetColorTable(E.db.actionbar.noPowerColor),
		["NORMAL"] = E:GetColorTable(E.db.actionbar.usableColor),
		["UNUSABLE"] = E:GetColorTable(E.db.actionbar.notUsableColor)
	};
end

function tullaRange:Reset()
	self:LoadDefaults()
	self.colors = TULLARANGE_COLORS

	self:ForceColorUpdate()
end

function tullaRange:SetColor(index, r, g, b)
	local color = self.colors[index]
	color[1] = r
	color[2] = g
	color[3] = b

	self:ForceColorUpdate()
end

function tullaRange:GetColor(index)
	local color = self.colors[index]
	return color[1], color[2], color[3]
end

tullaRange:Load()