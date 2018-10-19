--Plugins pass their info using the table like:
--[[
	addon = {
		Title = "Your Own Title",
		Name = "AddOnName",
		tutorialImage = "TexturePath",
		Pages = {
			[1] = function1,
			[2] = function2,
			[3] = function3,
		},
		StepTitles = {
			[1] = "Title 1",
			[2] = "Title 2",
			[3] = "Title 3",
		},
		StepTitlesColor = {r,g,b},
		StepTitlesColorSelected = {r,g,b},
		StepTitleWidth = 140,
		StepTitleButtonWidth = 130,
		StepTitleTextJustification = "CENTER",
	}
	E:GetModule("PluginInstaller"):Queue(addon)

	Title is wat displayed on top of the window. By default it's ""ElvUI Plugin Installation""
	Name is how your installation will be showin in "pending list", Default is "Unknown"
	tutorialImage is a path to your own texture to use in frame. if not specified, then it will use ElvUI's one
	Pages is a table to set up pages of your install where numbers are representing actual pages' order and function is what previously was used to set layout. For example
		function function1()
			PluginInstallFrame.SubTitle:SetText("Title Text")
			PluginInstallFrame.Desc1:SetText("Desc 1 Tet")
			PluginInstallFrame.Desc2:SetText("Desc 2 Tet")
			PluginInstallFrame.Desc3:SetText("Desc 3 Tet")

			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() <Do Some Stuff> end)
			PluginInstallFrame.Option1:SetText("Text 1")

			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetScript("OnClick", function() <Do Some Other Stuff> end)
			PluginInstallFrame.Option2:SetText("Text 2")
		end
	StepTitles - a table to specify "titles" for your install steps. If specified and number of lines here = number of pages then you'll get an additional frame to the right of main frame
	with a list of steps (current one being highlighted), clicking on those will open respective step. BenikUI style of doing stuff.
	StepTitlesColor - a table with color values to color "titles" when they are not active
	StepTitlesColorSelected - a table with color values to color "titles" when they are active
	StepTitleWidth - Width of the steps frame on the right side
	StepTitleButtonWidth - Width of each step button in the steps frame
	StepTitleTextJustification - The justification of the text on each step button ("LEFT", "RIGHT", "CENTER"). Default: "CENTER"
]]

local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local PI = E:NewModule("PluginInstaller");

--Cache global variables
--Lua functions
local _G = _G
local pairs, unpack = pairs, unpack
local tinsert, tremove = tinsert, tremove
local format = string.format
--WoW API / Variables
local CreateFrame = CreateFrame
local PlaySoundFile = PlaySoundFile
local UIFrameFadeOut = UIFrameFadeOut
local CreateAnimationGroup = CreateAnimationGroup
local CONTINUE, PREV, UNKNOWN = CONTINUE, PREV, UNKNOWN

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: PluginInstallFrame

--Installation Functions
PI.Installs = {}
local f
local BUTTON_HEIGHT = 20

local function ResetAll()
	f.Next:Disable()
	f.Prev:Disable()
	f.Option1:Hide()
	f.Option1:SetScript("OnClick", nil)
	f.Option1:SetText("")
	f.Option2:Hide()
	f.Option2:SetScript("OnClick", nil)
	f.Option2:SetText("")
	f.Option3:Hide()
	f.Option3:SetScript("OnClick", nil)
	f.Option3:SetText("")
	f.Option4:Hide()
	f.Option4:SetScript("OnClick", nil)
	f.Option4:SetText("")
	f.SubTitle:SetText("")
	f.Desc1:SetText("")
	f.Desc2:SetText("")
	f.Desc3:SetText("")
	f.Desc4:SetText("")
	E:Size(f, 550, 400)
	if f.StepTitles then
		for i = 1, getn(f.side.Lines) do f.side.Lines[i].text:SetText("") end
	end
end

local function SetPage(PageNum, PrevPage)
	f.CurrentPage = PageNum
	f.PrevPage = PrevPage
	ResetAll()
	f.Status.anim.progress:SetChange(PageNum)
	f.Status.anim.progress:Play()

	local r, g, b = E:ColorGradient(f.CurrentPage / f.MaxPage, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	f.Status:SetStatusBarColor(r, g, b)

	if PageNum == f.MaxPage then
		f.Next:Disable()
	else
		f.Next:Enable()
	end

	if PageNum == 1 then
		f.Prev:Disable()
	else
		f.Prev:Enable()
	end

	f.Pages[f.CurrentPage]()
	f.Status.text:SetText(format("%d / %d", f.CurrentPage, f.MaxPage))
	if f.StepTitles then
		for i = 1, getn(f.side.Lines) do
			local b = f.side.Lines[i]
			local color
			b.text:SetText(f.StepTitles[i])
			if i == f.CurrentPage then
				color = f.StepTitlesColorSelected or {.09,.52,.82}
			else
				color = f.StepTitlesColor or {1,1,1}
			end
			b.text:SetTextColor(color[1] or color.r, color[2] or color.g, color[3] or color.b)
		end
	end
end

local function NextPage()
	if f.CurrentPage ~= f.MaxPage then
		f.CurrentPage = f.CurrentPage + 1
		SetPage(f.CurrentPage, f.CurrentPage - 1)
	end
end

local function PreviousPage()
	if f.CurrentPage ~= 1 then
		f.CurrentPage = f.CurrentPage - 1
		SetPage(f.CurrentPage, f.CurrentPage + 1)
	end
end

function PI:CreateStepComplete()
	local imsg = CreateFrame("Frame", "PluginInstallStepComplete", E.UIParent)
	E:Size(imsg, 418, 72)
	E:Point(imsg, "TOP", 0, -190)
	imsg:Hide()
	imsg:SetScript("OnShow", function(self)
		if self.message then
			PlaySoundFile([[Sound\Interface\LevelUp.wav]])
			self.text:SetText(self.message)
			UIFrameFadeOut(self, 3.5, 1, 0)
			E:Delay(4, function() self:Hide() end)
			self.message = nil
		else
			self:Hide()
		end
	end)

	imsg.firstShow = false

	imsg.bg = imsg:CreateTexture(nil, "BACKGROUND")
	imsg.bg:SetTexture([[Interface\LevelUp\LevelUpTex]])
	E:Point(imsg.bg, "BOTTOM", 0, 0)
	E:Size(imsg.bg, 326, 103)
	imsg.bg:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
	imsg.bg:SetVertexColor(1, 1, 1, 0.6)

	imsg.lineTop = imsg:CreateTexture(nil, "BACKGROUND")
	imsg.lineTop:SetDrawLayer("BACKGROUND", 2)
	imsg.lineTop:SetTexture([[Interface\LevelUp\LevelUpTex]])
	E:Point(imsg.lineTop, "TOP", 0, 0)
	E:Size(imsg.lineTop, 418, 7)
	imsg.lineTop:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

	imsg.lineBottom = imsg:CreateTexture(nil, "BACKGROUND")
	imsg.lineBottom:SetDrawLayer("BACKGROUND", 2)
	imsg.lineBottom:SetTexture([[Interface\LevelUp\LevelUpTex]])
	E:Point(imsg.lineBottom, "BOTTOM", 0, 0)
	E:Size(imsg.lineBottom, 418, 7)
	imsg.lineBottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

	imsg.text = imsg:CreateFontString(nil, "ARTWORK")
	E:FontTemplate(imsg.text, E["media"].normFont, 32, "OUTLINE")
	E:Point(imsg.text, "BOTTOM", 0, 12)
	imsg.text:SetTextColor(1, 0.82, 0)
	imsg.text:SetJustifyH("CENTER")
end

function PI:CreateFrame()
	f = CreateFrame("Button", "PluginInstallFrame", E.UIParent)
	f.SetPage = SetPage
	E:Size(f, 550, 400)
	E:SetTemplate(f, "Transparent")
	E:Point(f, "CENTER", 0, 0)
	f:SetFrameStrata("TOOLTIP")

	f.Title = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Title, nil, 17, nil)
	E:Point(f.Title, "TOP", 0, -5)

	f.Next = CreateFrame("Button", "PluginInstallNextButton", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Next)
	E:SetTemplate(f.Next, "Default", true)
	E:Size(f.Next, 110, 25)
	E:Point(f.Next, "BOTTOMRIGHT", -5, 5)
	f.Next:SetText(CONTINUE)
	f.Next:Disable()
	f.Next:SetScript("OnClick", NextPage)
	E.Skins:HandleButton(f.Next, true)

	f.Prev = CreateFrame("Button", "PluginInstallPrevButton", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Prev)
	E:SetTemplate(f.Prev, "Default", true)
	E:Size(f.Prev, 110, 25)
	E:Point(f.Prev, "BOTTOMLEFT", 5, 5)
	f.Prev:SetText(PREV)
	f.Prev:Disable()
	f.Prev:SetScript("OnClick", PreviousPage)
	E.Skins:HandleButton(f.Prev, true)

	f.Status = CreateFrame("StatusBar", "PluginInstallStatus", f)
	f.Status:SetFrameLevel(f.Status:GetFrameLevel() + 2)
	E:CreateBackdrop(f.Status, "Default", true)
	f.Status:SetStatusBarTexture(E["media"].normTex)
	f.Status:SetStatusBarColor(unpack(E["media"].rgbvaluecolor))
	E:Point(f.Status, "TOPLEFT", f.Prev, "TOPRIGHT", 6, -2)
	E:Point(f.Status, "BOTTOMRIGHT", f.Next, "BOTTOMLEFT", -6, 2)
	-- Setup StatusBar Animation
	f.Status.anim = CreateAnimationGroup(f.Status)
	f.Status.anim.progress = f.Status.anim:CreateAnimation("Progress")
	f.Status.anim.progress:SetSmoothing("Out")
	f.Status.anim.progress:SetDuration(.3)

	f.Status.text = f.Status:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Status.text)
	E:Point(f.Status.text, "CENTER", 0, 0)

	f.Option1 = CreateFrame("Button", "PluginInstallOption1Button", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Option1)
	E:Size(f.Option1, 160, 30)
	E:Point(f.Option1, "BOTTOM", 0, 45)
	f.Option1:SetText("")
	f.Option1:Hide()
	E.Skins:HandleButton(f.Option1, true)

	f.Option2 = CreateFrame("Button", "PluginInstallOption2Button", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Option2)
	E:Size(f.Option2, 160, 30)
	E:Point(f.Option2, "BOTTOMLEFT", f, "BOTTOM", 4, 45)
	f.Option2:SetText("")
	f.Option2:Hide()
	f.Option2:SetScript("OnShow", function() E:Width(f.Option1, 110); f.Option1:ClearAllPoints(); E:Point(f.Option1, "BOTTOMRIGHT", f, "BOTTOM", -4, 45) end)
	f.Option2:SetScript("OnHide", function() E:Width(f.Option1, 160); f.Option1:ClearAllPoints(); E:Point(f.Option1, "BOTTOM", 0, 45) end)
	E.Skins:HandleButton(f.Option2, true)

	f.Option3 = CreateFrame("Button", "PluginInstallOption3Button", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Option3)
	E:Size(f.Option3, 100, 30)
	E:Point(f.Option3, "LEFT", f.Option2, "RIGHT", 4, 0)
	f.Option3:SetText("")
	f.Option3:Hide()
	f.Option3:SetScript("OnShow", function() E:Width(f.Option1, 100); f.Option1:ClearAllPoints(); E:Point(f.Option1, "RIGHT", f.Option2, "LEFT", -4, 0); E:Width(f.Option2, 100); f.Option2:ClearAllPoints(); E:Point(f.Option2, "BOTTOM", f, "BOTTOM", 0, 45) end)
	f.Option3:SetScript("OnHide", function() E:Width(f.Option1, 160); f.Option1:ClearAllPoints(); E:Point(f.Option1, "BOTTOM", 0, 45); E:Width(f.Option2, 110); f.Option2:ClearAllPoints(); E:Point(f.Option2, "BOTTOMLEFT", f, "BOTTOM", 4, 45) end)
	E.Skins:HandleButton(f.Option3, true)

	f.Option4 = CreateFrame("Button", "PluginInstallOption4Button", f, "UIPanelButtonTemplate")
	E:StripTextures(f.Option4)
	E:Size(f.Option4, 100, 30)
	E:Point(f.Option4, "LEFT", f.Option3, "RIGHT", 4, 0)
	f.Option4:SetText("")
	f.Option4:Hide()
	f.Option4:SetScript("OnShow", function()
		E:Width(f.Option1, 100)
		E:Width(f.Option2, 100)

		f.Option1:ClearAllPoints();
		E:Point(f.Option1, "RIGHT", f.Option2, "LEFT", -4, 0);
		f.Option2:ClearAllPoints();
		E:Point(f.Option2, "BOTTOMRIGHT", f, "BOTTOM", -4, 45)
	end)
	f.Option4:SetScript("OnHide", function() E:Width(f.Option1, 160); f.Option1:ClearAllPoints(); E:Point(f.Option1, "BOTTOM", 0, 45); E:Width(f.Option2, 110); f.Option2:ClearAllPoints(); E:Point(f.Option2, "BOTTOMLEFT", f, "BOTTOM", 4, 45) end)
	E.Skins:HandleButton(f.Option4, true)

	f.SubTitle = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.SubTitle, nil, 15, nil)
	E:Point(f.SubTitle, "TOP", 0, -40)

	f.Desc1 = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Desc1)
	E:Point(f.Desc1, "TOPLEFT", 20, -75)
	E:Width(f.Desc1, f:GetWidth() - 40)

	f.Desc2 = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Desc2)
	E:Point(f.Desc2, "TOP", f.Desc1, "BOTTOM", 0, -20)
	E:Width(f.Desc2, f:GetWidth() - 40)

	f.Desc3 = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Desc3)
	E:Point(f.Desc3, "TOP", f.Desc2, "BOTTOM", 0, -20)
	E:Width(f.Desc3, f:GetWidth() - 40)

	f.Desc4 = f:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(f.Desc4)
	E:Point(f.Desc4, "TOP", f.Desc3, "BOTTOM", 0, -20)
	E:Width(f.Desc4, f:GetWidth() - 40)

	local close = CreateFrame("Button", "PluginInstallCloseButton", f, "UIPanelCloseButton")
	E:Point(close, "TOPRIGHT", f, "TOPRIGHT")
	close:SetScript("OnClick", function() f:Hide() end)
	E.Skins:HandleCloseButton(close)

	f.pending = CreateFrame("Frame", "PluginInstallPendingButton", f)
	E:Size(f.pending, 20)
	E:Point(f.pending, "TOPLEFT", f, "TOPLEFT", 8, -8)
	f.pending.tex = f.pending:CreateTexture(nil, "OVERLAY")
	E:Point(f.pending.tex, "TOPLEFT", f.pending, "TOPLEFT", 2, -2)
	E:Point(f.pending.tex, "BOTTOMRIGHT", f.pending, "BOTTOMRIGHT", -2, 2)
	f.pending.tex:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon]])
	E:CreateBackdrop(f.pending, "Transparent")
	f.pending:SetScript("OnEnter", function(self)
		_G["GameTooltip"]:SetOwner(self, "ANCHOR_BOTTOMLEFT", E.PixelMode and -7 or -9);
		_G["GameTooltip"]:AddLine(L["List of installations in queue:"], 1, 1, 1)
		_G["GameTooltip"]:AddLine(" ")
		for i = 1, getn(PI.Installs) do
			_G["GameTooltip"]:AddDoubleLine(format("%d. %s", i, (PI.Installs[i].Name or UNKNOWN)), i == 1 and format("|cff00FF00%s|r", L["In Progress"]) or format("|cffFF0000%s|r", L["Pending"]))
		end
		_G["GameTooltip"]:Show()
	end)
	f.pending:SetScript("OnLeave", function()
		_G["GameTooltip"]:Hide()
	end)

	f.tutorialImage = f:CreateTexture("PluginInstallTutorialImage", "OVERLAY")
	E:Size(f.tutorialImage, 256, 128)
	E:Point(f.tutorialImage, "BOTTOM", 0, 70)

	f.side = CreateFrame("Frame", "PluginInstallTitleFrame", f)
	E:SetTemplate(f.side, "Transparent")
	E:Point(f.side, "TOPLEFT", f, "TOPRIGHT", E.PixelMode and 1 or 3, 0)
	E:Point(f.side, "BOTTOMLEFT", f, "BOTTOMRIGHT", E.PixelMode and 1 or 3, 0)
	E:Width(f.side, 140)
	f.side.text = f.side:CreateFontString(nil, "OVERLAY")
	E:Point(f.side.text, "TOP", f.side, "TOP", 0, -4)
	f.side.text:SetFont(E["media"].normFont, 18, "OUTLINE")
	f.side.text:SetText(L["Steps"])
	f.side.Lines = {} --Table to keep shown lines
	f.side:Hide()
	for i = 1, 18 do
		local button = CreateFrame("Button", nil, f)
		if i == 1 then
			E:Point(button, "TOP", f.side.text, "BOTTOM", 0, -6)
		else
			E:Point(button, "TOP", f.side.Lines[i - 1], "BOTTOM")
		end
		E:Size(button, 130, BUTTON_HEIGHT)
		button.text = button:CreateFontString(nil, "OVERLAY")
		E:Point(button.text, "TOPLEFT", button, "TOPLEFT", 2, -2)
		E:Point(button.text, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button.text:SetFont(E["media"].normFont, 14, "OUTLINE")
		button:SetScript("OnClick", function() if i <= f.MaxPage then SetPage(i, f.CurrentPage) end end)
		button.text:SetText("")
		f.side.Lines[i] = button
		button:Hide()
	end

	f:Hide()

	f:SetScript("OnHide", function() PI:CloseInstall() end)
end

function PI:Queue(addon)
	local addonIsQueued = false
	for _, v in pairs(self.Installs) do
		if v.Name == addon.Name then
			addonIsQueued = true
		end
	end

	if not addonIsQueued then
		tinsert(self.Installs, getn(self.Installs)+1, addon)
		self:RunInstall()
	end
end

function PI:CloseInstall()
	tremove(self.Installs, 1)
	f.side:Hide()
	for i = 1, getn(f.side.Lines) do
		f.side.Lines[i].text:SetText("")
		f.side.Lines[i]:Hide()
	end
	if getn(self.Installs) > 0 then E:Delay(1, function() PI:RunInstall() end) end
end

function PI:RunInstall()
	if not E.private.install_complete then return end
	if self.Installs[1] and not PluginInstallFrame:IsShown() and not (_G["ElvUIInstallFrame"] and _G["ElvUIInstallFrame"]:IsShown()) then
		f.StepTitles = nil
		f.StepTitlesColor = nil
		f.StepTitlesColorSelected = nil
		local db = self.Installs[1]
		f.CurrentPage = 0
		f.MaxPage = getn(db.Pages)

		f.Title:SetText(db.Title or L["ElvUI Plugin Installation"])
		f.Status:SetMinMaxValues(0, f.MaxPage)
		f.Status.text:SetText(f.CurrentPage.." / "..f.MaxPage)
		f.tutorialImage:SetTexture(db.tutorialImage or [[Interface\AddOns\ElvUI\media\textures\logo.tga]])

		f.Pages = db.Pages

		PluginInstallFrame:Show()
		E:Point(f, "CENTER")
		if db.StepTitles and getn(db.StepTitles) == f.MaxPage then
			E:Point(f, "CENTER", E.UIParent, "CENTER", -((db.StepTitleWidth or 140)/2), 0)
			E:Width(f.side, db.StepTitleWidth or 140)
			f.side:Show()

			for i = 1, getn(f.side.Lines) do
				if db.StepTitles[i] then
					E:Width(f.side.Lines[i], db.StepTitleButtonWidth or 130)
					f.side.Lines[i].text:SetJustifyH(db.StepTitleTextJustification or "CENTER")
					f.side.Lines[i]:Show()
				end
			end

			f.StepTitles = db.StepTitles
			f.StepTitlesColor = db.StepTitlesColor
			f.StepTitlesColorSelected = db.StepTitlesColorSelected
		end
		NextPage()
	end
	if getn(self.Installs) > 1 then
		f.pending:Show()
--		E:Flash(f.pending, 0.53, true)
	else
		f.pending:Hide()
--		E:StopFlash(f.pending)
	end
end

function PI:Initialize()
	PI:CreateStepComplete()
	PI:CreateFrame()
end

local function InitializeCallback()
	PI:Initialize()
end

E:RegisterModule(PI:GetName(), InitializeCallback)