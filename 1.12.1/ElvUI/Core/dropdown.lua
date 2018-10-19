local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Cache global variables
--Lua functions
local tinsert = tinsert
--WoW API / Variables
local CreateFrame = CreateFrame
local ToggleFrame = ToggleFrame
local GetCursorPosition = GetCursorPosition

local PADDING = 10
local BUTTON_HEIGHT = 16
local BUTTON_WIDTH = 135

local function OnClick(btn)
	btn.func()

	btn:GetParent():Hide()
end

local function OnEnter(btn)
	btn.hoverTex:Show()
end

local function OnLeave(btn)
	btn.hoverTex:Hide()
end

function E:DropDown(list, frame, xOffset, yOffset)
	if not frame.buttons then
		frame.buttons = {}
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		tinsert(UISpecialFrames, frame:GetName())
		frame:Hide()
	end

	xOffset = xOffset or 0
	yOffset = yOffset or 0

	for i = 1, getn(frame.buttons) do
		frame.buttons[i]:Hide()
	end

	for i = 1, getn(list) do
		if not frame.buttons[i] then
			frame.buttons[i] = CreateFrame("Button", nil, frame)

			frame.buttons[i].hoverTex = frame.buttons[i]:CreateTexture(nil, "OVERLAY")
			frame.buttons[i].hoverTex:SetAllPoints()
			frame.buttons[i].hoverTex:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
			frame.buttons[i].hoverTex:SetBlendMode("ADD")
			frame.buttons[i].hoverTex:Hide()

			frame.buttons[i].text = frame.buttons[i]:CreateFontString(nil, "BORDER")
			frame.buttons[i].text:SetAllPoints()
			E:FontTemplate(frame.buttons[i].text)
			frame.buttons[i].text:SetJustifyH("LEFT")

			frame.buttons[i]:SetScript("OnEnter", OnEnter)
			frame.buttons[i]:SetScript("OnLeave", OnLeave)
		end

		frame.buttons[i]:Show()
		E:Size(frame.buttons[i], BUTTON_WIDTH, BUTTON_HEIGHT)
		frame.buttons[i].text:SetText(list[i].text)
		frame.buttons[i].func = list[i].func
		frame.buttons[i]:SetScript("OnClick", OnClick)

		if i == 1 then
			E:Point(frame.buttons[i], "TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
		else
			E:Point(frame.buttons[i], "TOPLEFT", frame.buttons[i-1], "BOTTOMLEFT")
		end
	end

	E:Size(frame, BUTTON_WIDTH + PADDING * 2, (getn(list) * BUTTON_HEIGHT) + PADDING * 2)

	local UIScale = UIParent:GetScale()
	local x, y = GetCursorPosition()
	x = x/UIScale
	y = y/UIScale
	frame:ClearAllPoints()
	E:Point(frame, "TOPLEFT", UIParent, "BOTTOMLEFT", x + xOffset, y + yOffset)

	ToggleFrame(frame)
end