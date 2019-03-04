local SUI=CreateFrame("Frame")
SUI:RegisterEvent("ADDON_LOADED")
SUI:RegisterEvent("PLAYER_ENTERING_WORLD")
SUI:SetScript("OnEvent", function(self, event)

if not SUIDB.A_CHAT == true then return end

CHAT_FRAME_FADE_TIME = 0.15
CHAT_FRAME_FADE_OUT_TIME = 1
CHAT_TAB_HIDE_DELAY = 0
CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0
CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1
CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1
CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 1
CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0

for i = 1, 7 do
	_G["ChatFrame" .. i]:SetFading(1)
end

BNToastFrame:SetClampedToScreen(true)
BNToastFrame:SetClampRectInsets(-15, 15, 15, -15)

ChatFrameMenuButton:HookScript("OnShow", ChatFrameMenuButton.Hide)
ChatFrameMenuButton:Hide()

QuickJoinToastButton:Hide()
QuickJoinToastButton.Show = function()
end

--[[ChatFrameMenuButton:Hide()
ChatFrameMenuButton.Show = function()
end

ChatFrameChannelButton:Hide()
ChatFrameChannelButton.Show = function()
end

ChatFrameToggleVoiceDeafenButton:Hide()
ChatFrameToggleVoiceDeafenButton.Show = function()
end

ChatFrameToggleVoiceMuteButton:Hide()
ChatFrameToggleVoiceMuteButton.Show = function()
end]]

-- Table to keep track of frames you already saw:
local frames = {}

-- Function to handle customzing a chat frame:
local function ProcessFrame(frame)
	if frames[frame] then
		return
	end

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
	frame:SetMinResize(250, 100)

	local name = frame:GetName()
	_G[name .. "ButtonFrame"]:Hide()
	_G[name .. "EditBoxLeft"]:Hide()
	_G[name .. "EditBoxMid"]:Hide()
	_G[name .. "EditBoxRight"]:Hide()

	local editbox = _G[name .. "EditBox"]
	editbox:ClearAllPoints()
	editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -7, 25)
	editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 10, 25)
	editbox:SetAltArrowKeyMode(false)

	local cf = _G[name]

	local tt = _G[name .. "ThumbTexture"]
	tt:Hide()
	tt.Show = function()
	end

	local sb = cf["ScrollBar"]
	sb:Hide()
	sb.Show = function()
	end

	local s2bb = cf["ScrollToBottomButton"]
	s2bb:Hide()
	s2bb.Show = function()
	end

	cf:EnableMouse(1)
	ChatFrameChannelButton:EnableMouse(1)
	ChatFrameToggleVoiceDeafenButton:EnableMouse(1)
	ChatFrameToggleVoiceMuteButton:EnableMouse(1)
	ChatFrameChannelButton:SetAlpha(0)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0)

	cf:SetScript("OnEnter", function(self)
		ChatFrameChannelButton:SetAlpha(0.8)
		ChatFrameToggleVoiceDeafenButton:SetAlpha(0.8)
		ChatFrameToggleVoiceMuteButton:SetAlpha(0.8)
	end)
	cf:SetScript("OnLeave", function(self)
		ChatFrameChannelButton:SetAlpha(0)
		ChatFrameToggleVoiceDeafenButton:SetAlpha(0)
		ChatFrameToggleVoiceMuteButton:SetAlpha(0)
	end)

	ChatFrameChannelButton:SetScript("OnEnter", function(self)
	ChatFrameChannelButton:SetAlpha(0.8)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0.8)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0.8)
	end)
	ChatFrameChannelButton:SetScript("OnLeave", function(self)
	ChatFrameChannelButton:SetAlpha(0)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0)
	end)
	ChatFrameToggleVoiceDeafenButton:SetScript("OnEnter", function(self)
	ChatFrameChannelButton:SetAlpha(0.8)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0.8)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0.8)
	end)
	ChatFrameToggleVoiceDeafenButton:SetScript("OnLeave", function(self)
	ChatFrameChannelButton:SetAlpha(0)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0)
	end)
	ChatFrameToggleVoiceMuteButton:SetScript("OnEnter", function(self)
	ChatFrameChannelButton:SetAlpha(0.8)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0.8)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0.8)
	end)
	ChatFrameToggleVoiceMuteButton:SetScript("OnLeave", function(self)
	ChatFrameChannelButton:SetAlpha(0)
	ChatFrameToggleVoiceDeafenButton:SetAlpha(0)
	ChatFrameToggleVoiceMuteButton:SetAlpha(0)
	end)

	frames[frame] = true
end

-- Loop Through Chat Windows
for i = 1, NUM_CHAT_WINDOWS do
	ProcessFrame(_G["ChatFrame" .. i])
	local chatWindowName = _G["ChatFrame" .. i]:GetName()
	local name, size, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(i)

	-- Change Chat Tabs
	local chatTab = _G[chatWindowName .. "Tab"]

	--Hide Tab Backgrounds
	_G[chatWindowName .. "TabLeft"]:SetTexture(nil)
	_G[chatWindowName .. "TabMiddle"]:SetTexture(nil)
	_G[chatWindowName .. "TabRight"]:SetTexture(nil)
	_G[chatWindowName .. "TabSelectedLeft"]:SetTexture(nil)
	_G[chatWindowName .. "TabSelectedMiddle"]:SetTexture(nil)
	_G[chatWindowName .. "TabSelectedRight"]:SetTexture(nil)
	chatTab:SetAlpha(1.0)
end

local faneifyTab = function(frame, sel)
	local i = frame:GetID()

	if (not frame.Fane) then
		frame.leftTexture:Hide()
		frame.middleTexture:Hide()
		frame.rightTexture:Hide()

		frame.leftSelectedTexture:Hide()
		frame.middleSelectedTexture:Hide()
		frame.rightSelectedTexture:Hide()

		frame.leftSelectedTexture.Show = frame.leftSelectedTexture.Hide
		frame.middleSelectedTexture.Show = frame.middleSelectedTexture.Hide
		frame.rightSelectedTexture.Show = frame.rightSelectedTexture.Hide

		frame.Fane = true
	end
end

hooksecurefunc("FCFTab_UpdateColors", faneifyTab)
for i = 1, 7 do
	faneifyTab(_G["ChatFrame" .. i .. "Tab"])
end

-- Set up a dirty hook to catch temporary windows and customize them when they are created:
local old_OpenTemporaryWindow = FCF_OpenTemporaryWindow
FCF_OpenTemporaryWindow = function(...)
	local frame = old_OpenTemporaryWindow(...)
	ProcessFrame(frame)
	return frame
end

-- Chat Scroll Module
function FloatingChatFrame_OnMouseScroll(self, delta)
	if delta > 0 then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		else
			self:ScrollUp()
		end
	elseif delta < 0 then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		else
			self:ScrollDown()
		end
	end
end

local _G = _G
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local table_insert = table.insert
local CreateFrame, UIParent = _G.CreateFrame, _G.UIParent
local GetSpellInfo = _G.GetSpellInfo
local ToggleFrame = _G.ToggleFrame
local lines = {}
local frame = nil
local editBox = nil
local font = nil
local isf = nil
local sizes = {
	":14:14",
	":15:15",
	":16:16",
	":12:20",
	":14"
}

local function CreatCopyFrame()
	frame = CreateFrame("Frame", "CopyFrame", UIParent)
	frame:SetBackdrop(
		{
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = false,
			tileSize = 32,
			edgeSize = 15,
			insets = {
				left = 1,
				right = 1,
				top = 1,
				bottom = 1
			}
		}
	)
	frame:SetBackdropBorderColor(0, 0, 0, 1)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetSize(540, 300)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	table_insert(UISpecialFrames, "CopyFrame")
	frame:Hide()

	local scrollArea = CreateFrame("ScrollFrame", "CopyScroll", frame, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -10)
	scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)

	editBox = CreateFrame("EditBox", "CopyBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetSize(500, 300)
	editBox:SetScript(
		"OnEscapePressed",
		function()
			frame:Hide()
		end
	)

	scrollArea:SetScrollChild(editBox)

	editBox:SetScript(
		"OnTextSet",
		function(self)
			local text = self:GetText()

			for _, size in pairs(sizes) do
				if string_find(text, size) and not string_find(text, size .. "]") then
					self:SetText(string_gsub(text, size, ":12:12"))
				end
			end
		end
	)

	font = frame:CreateFontString(nil, nil, "GameFontNormal")
	font:Hide()

	isf = true
end

local scrollDown = function()
	CopyScroll:SetVerticalScroll((CopyScroll:GetVerticalScrollRange()) or 0)
end

local function Copy(cf)
	if not isf then
		CreatCopyFrame()
	end
	local text = ""
	for i = 1, cf:GetNumMessages() do
		local line, r, g, b = cf:GetMessageInfo(i)
		local colorCode = r and g and b and ConvertRGBtoColorString({r = r, g = g, b = b}) or YELLOW_FONT_COLOR_CODE
		font:SetFormattedText("%s\n", line)
		local cleanLine = font:GetText() or ""
		text = text .. cleanLine
		text = format("%s%s|r", colorCode, text:gsub(FONT_COLOR_CODE_CLOSE, FONT_COLOR_CODE_CLOSE .. colorCode))
	end
	if frame:IsShown() then
		frame:Hide()
		return
	end
	frame:Show()
	editBox:SetText(text)
	C_Timer.After(0.10, scrollDown)
end

for i = 1, NUM_CHAT_WINDOWS do
	local cf = _G[string_format("ChatFrame%d", i)]
	local function CreateCopyButton(self)
		self.Copy = CreateFrame("Button", nil, _G[self:GetName()])
		self.Copy:SetSize(20, 20)
		self.Copy:SetPoint("TOPRIGHT", self, 10, -5)

		self.Copy:SetNormalTexture("Interface\\AddOns\\SUI\\inc\\media\\core\\copynormal")
		self.Copy:GetNormalTexture():SetSize(20, 20)

		self.Copy:SetHighlightTexture("Interface\\AddOns\\SUI\\inc\\media\\core\\copyhighlight")
		self.Copy:GetHighlightTexture():SetAllPoints(self.Copy:GetNormalTexture())

		local tab = _G[self:GetName() .. "Tab"]
		hooksecurefunc(
			tab,
			"SetAlpha",
			function()
				self.Copy:SetAlpha(tab:GetAlpha() * 0.55)
			end
		)

		self.Copy:SetScript(
			"OnMouseUp",
			function()
				Copy(cf)
			end
		)
	end

	local function EnableCopyButton()
		for _, v in pairs(CHAT_FRAMES) do
			local chat = _G[v]
			if (chat and not chat.Copy) then
				CreateCopyButton(chat)
			end
		end
	end
	EnableCopyButton()
end
end)