local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local pairs = pairs
--WoW API / Variables
local CreateFrame = CreateFrame

local RegisterAsWidget, RegisterAsContainer
local function SetModifiedBackdrop()
	if this.backdrop then this = this.backdrop end
	this:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))
end

local function SetOriginalBackdrop()
	if this.backdrop then this = this.backdrop end
	this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
end

local function SkinScrollBar(frame, thumbTrim)
	if _G[frame:GetName().."BG"] then _G[frame:GetName().."BG"]:SetTexture(nil) end
	if _G[frame:GetName().."Track"] then _G[frame:GetName().."Track"]:SetTexture(nil) end

	if _G[frame:GetName().."Top"] then
		_G[frame:GetName().."Top"]:SetTexture(nil)
		_G[frame:GetName().."Bottom"]:SetTexture(nil)
		_G[frame:GetName().."Middle"]:SetTexture(nil)
	end

	if _G[frame:GetName().."ScrollUpButton"] and _G[frame:GetName().."ScrollDownButton"] then
		E:StripTextures(_G[frame:GetName().."ScrollUpButton"])
		if not _G[frame:GetName().."ScrollUpButton"].icon then
			S:HandleNextPrevButton(_G[frame:GetName().."ScrollUpButton"])
			S:SquareButton_SetIcon(_G[frame:GetName().."ScrollUpButton"], "UP")
			E:Size(_G[frame:GetName().."ScrollUpButton"], _G[frame:GetName().."ScrollUpButton"]:GetWidth() + 7, _G[frame:GetName().."ScrollUpButton"]:GetHeight() + 7)
		end

		E:StripTextures(_G[frame:GetName().."ScrollDownButton"])
		if not _G[frame:GetName().."ScrollDownButton"].icon then
			S:HandleNextPrevButton(_G[frame:GetName().."ScrollDownButton"])
			S:SquareButton_SetIcon(_G[frame:GetName().."ScrollDownButton"], "DOWN")
			E:Size(_G[frame:GetName().."ScrollDownButton"], _G[frame:GetName().."ScrollDownButton"]:GetWidth() + 7, _G[frame:GetName().."ScrollDownButton"]:GetHeight() + 7)
		end

		if not frame.trackbg then
			frame.trackbg = CreateFrame("Frame", nil, frame)
			E:Point(frame.trackbg, "TOPLEFT", _G[frame:GetName().."ScrollUpButton"], "BOTTOMLEFT", 0, -1)
			E:Point(frame.trackbg, "BOTTOMRIGHT", _G[frame:GetName().."ScrollDownButton"], "TOPRIGHT", 0, 1)
			E:SetTemplate(frame.trackbg, "Transparent")
		end

		if frame:GetThumbTexture() then
			if not thumbTrim then thumbTrim = 3 end
			frame:GetThumbTexture():SetTexture(nil)
			E:Height(frame:GetThumbTexture(), 24)
			if not frame.thumbbg then
				frame.thumbbg = CreateFrame("Frame", nil, frame)
				E:Point(frame.thumbbg, "TOPLEFT", frame:GetThumbTexture(), "TOPLEFT", 2, -thumbTrim)
				E:Point(frame.thumbbg, "BOTTOMRIGHT", frame:GetThumbTexture(), "BOTTOMRIGHT", -2, thumbTrim)
				E:SetTemplate(frame.thumbbg, "Default", true, true)
				frame.thumbbg:SetBackdropColor(0.3, 0.3, 0.3)
				if frame.trackbg then
					frame.thumbbg:SetFrameLevel(frame.trackbg:GetFrameLevel() + 1)
				end
			end
		end
	end
end

local function SkinButton(f, strip, noTemplate)
	local name = f:GetName()

	if(name) then
		local left = _G[name.."Left"]
		local middle = _G[name.."Middle"]
		local right = _G[name.."Right"]

		if(left) then E:Kill(left) end
		if(middle) then E:Kill(middle) end
		if(right) then E:Kill(right) end
	end

	if(f.Left) then E:Kill(f.Left) end
	if(f.Middle) then E:Kill(f.Middle) end
	if(f.Right) then E:Kill(f.Right) end

	if f.SetNormalTexture then f:SetNormalTexture("") end
	if f.SetHighlightTexture then f:SetHighlightTexture("") end
	if f.SetPushedTexture then f:SetPushedTexture("") end
	if f.SetDisabledTexture then f:SetDisabledTexture("") end

	if strip then E:StripTextures(f) end

	if not f.template and not noTemplate then
		E:SetTemplate(f, "Default", true)
	end

	HookScript(f, "OnEnter", SetModifiedBackdrop)
	HookScript(f, "OnLeave", SetOriginalBackdrop)
end

function S:SkinAce3()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end
	local oldRegisterAsWidget = AceGUI.RegisterAsWidget

	RegisterAsWidget = function(self, widget)
		if not E.private.skins.ace3.enable then
			return oldRegisterAsWidget(self, widget)
		end
		local TYPE = widget.type
		if TYPE == "MultiLineEditBox" then
			local frame = widget.frame

			if not widget.scrollBG.template then
				E:SetTemplate(widget.scrollBG, "Default")
			end

			SkinButton(widget.button)
			SkinScrollBar(widget.scrollBar)
			E:Point(widget.scrollBar, "RIGHT", frame, "RIGHT", 0 -4)
			E:Point(widget.scrollBG, "TOPRIGHT", widget.scrollBar, "TOPLEFT", -2, 19)
			E:Point(widget.scrollBG, "BOTTOMLEFT", widget.button, "TOPLEFT")
			E:Point(widget.scrollFrame, "BOTTOMRIGHT", widget.scrollBG, "BOTTOMRIGHT", -4, 8)
		elseif TYPE == "CheckBox" then
			E:Kill(widget.checkbg)
			E:Kill(widget.highlight)

			if not widget.skinnedCheckBG then
				widget.skinnedCheckBG = CreateFrame("Frame", nil, widget.frame)
				E:SetTemplate(widget.skinnedCheckBG, "Default")
				E:Point(widget.skinnedCheckBG, "TOPLEFT", widget.checkbg, "TOPLEFT", 4, -4)
				E:Point(widget.skinnedCheckBG, "BOTTOMRIGHT", widget.checkbg, "BOTTOMRIGHT", -4, 4)
			end

			widget.check:SetParent(widget.skinnedCheckBG)
		elseif TYPE == "Dropdown" then
			local frame = widget.dropdown
			local button = widget.button
			local text = widget.text
			E:StripTextures(frame)

			button:ClearAllPoints()
			E:Point(button, "RIGHT", frame, "RIGHT", -20, 0)

			S:HandleNextPrevButton(button, true)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
				E:Point(frame.backdrop, "TOPLEFT", 20, -2)
				E:Point(frame.backdrop, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
			end
			button:SetParent(frame.backdrop)
			text:SetParent(frame.backdrop)
			HookScript(button, "OnClick", function()
				local dropdown = this.obj.pullout
				if dropdown.frame then
					E:SetTemplate(dropdown.frame, "Default", true)
					if dropdown.slider then
						E:SetTemplate(dropdown.slider, "Default")
						E:Point(dropdown.slider, "TOPRIGHT", dropdown.frame, "TOPRIGHT", -10, -10)
						E:Point(dropdown.slider, "BOTTOMRIGHT", dropdown.frame, "BOTTOMRIGHT", -10, 10)

						if dropdown.slider:GetThumbTexture() then
							dropdown.slider:SetThumbTexture(E["media"].blankTex)
							dropdown.slider:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
							E:Size(dropdown.slider:GetThumbTexture(), 10, 12)
						end
					end
				end
			end)
		elseif TYPE == "LSM30_Font" or TYPE == "LSM30_Sound" or TYPE == "LSM30_Border" or TYPE == "LSM30_Background" or TYPE == "LSM30_Statusbar" then
			local frame = widget.frame
			local button = frame.dropButton
			local text = frame.text
			E:StripTextures(frame)

			S:HandleNextPrevButton(button, true)
			frame.text:ClearAllPoints()
			E:Point(frame.text, "RIGHT", button, "LEFT", -2, 0)

			button:ClearAllPoints()
			E:Point(button, "RIGHT", frame, "RIGHT", -10, -6)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
				if TYPE == "LSM30_Font" then
					E:Point(frame.backdrop, "TOPLEFT", 20, -17)
				elseif TYPE == "LSM30_Sound" then
					E:Point(frame.backdrop, "TOPLEFT", 20, -17)
					widget.soundbutton:SetParent(frame.backdrop)
					widget.soundbutton:ClearAllPoints()
					E:Point(widget.soundbutton, "LEFT", frame.backdrop, "LEFT", 2, 0)
				elseif TYPE == "LSM30_Statusbar" then
					E:Point(frame.backdrop, "TOPLEFT", 20, -17)
					widget.bar:SetParent(frame.backdrop)
					E:SetInside(widget.bar)
				elseif TYPE == "LSM30_Border" or TYPE == "LSM30_Background" then
					E:Point(frame.backdrop, "TOPLEFT", 42, -16)
				end

				E:Point(frame.backdrop, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
			end
			button:SetParent(frame.backdrop)
			text:SetParent(frame.backdrop)
			HookScript(button, "OnClick", function()
				local dropdown = this.obj.dropdown
				if dropdown then
					E:SetTemplate(dropdown, "Default", true)
					if dropdown.slider then
						E:SetTemplate(dropdown.slider, "Transparent")
						E:Point(dropdown.slider, "TOPRIGHT", dropdown, "TOPRIGHT", -10, -10)
						E:Point(dropdown.slider, "BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -10, 10)

						if dropdown.slider:GetThumbTexture() then
							dropdown.slider:SetThumbTexture(E["media"].blankTex)
							dropdown.slider:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
							E:Size(dropdown.slider:GetThumbTexture(), 10, 12)
						end
					end

					if TYPE == "LSM30_Sound" then
						local frame = this.obj.frame
						local width = frame:GetWidth()
						E:Point(dropdown, "TOPLEFT", frame, "BOTTOMLEFT")
						E:Point(dropdown, "TOPRIGHT", frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 30, 0)
					end
				end
			end)
		elseif TYPE == "EditBox" then
			local frame = widget.editbox
			local button = widget.button
			E:Kill(_G[frame:GetName().."Left"])
			E:Kill(_G[frame:GetName().."Middle"])
			E:Kill(_G[frame:GetName().."Right"])
			E:Height(frame, 17)
			E:CreateBackdrop(frame, "Default")
			E:Point(frame.backdrop, "TOPLEFT", -2, 0)
			E:Point(frame.backdrop, "BOTTOMRIGHT", 2, 0)
			frame.backdrop:SetParent(widget.frame)
			frame:SetParent(frame.backdrop)
			SkinButton(button)
		elseif TYPE == "Button" then
			local frame = widget.frame
			SkinButton(frame, nil, true)
			E:StripTextures(frame)
			E:CreateBackdrop(frame, "Default", true)
			E:SetInside(frame.backdrop)
			widget.text:SetParent(frame.backdrop)
		elseif TYPE == "Button-ElvUI" then
			local frame = widget.frame
			SkinButton(frame, nil, true)
			E:StripTextures(frame)
			E:CreateBackdrop(frame, "Default", true)
			E:SetInside(frame.backdrop)
			widget.text:SetParent(frame.backdrop)
		elseif TYPE == "Keybinding" then
			local button = widget.button
			local msgframe = widget.msgframe
			local msg = widget.msgframe.msg
			SkinButton(button)
			E:StripTextures(msgframe)
			E:CreateBackdrop(msgframe, "Default", true)
			E:SetInside(msgframe.backdrop)
			msgframe:SetToplevel(true)

			msg:ClearAllPoints()
			E:Point(msg, "LEFT", 10, 0)
			E:Point(msg, "RIGHT", -10, 0)
			msg:SetJustifyV("MIDDLE")
			E:Width(msg, msg:GetWidth() + 10)
		elseif TYPE == "Slider" then
			local frame = widget.slider
			local editbox = widget.editbox
			local lowtext = widget.lowtext
			local hightext = widget.hightext
			local HEIGHT = 12

			E:StripTextures(frame)
			E:SetTemplate(frame, "Default")
			E:Height(frame, HEIGHT)
			frame:SetThumbTexture(E["media"].blankTex)
			frame:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
			E:Size(frame:GetThumbTexture(), HEIGHT-2, HEIGHT+2)

			E:SetTemplate(editbox, "Default")
			E:Height(editbox, 15)
			E:Point(editbox, "TOP", frame, "BOTTOM", 0, -1)

			E:Point(lowtext, "TOPLEFT", frame, "BOTTOMLEFT", 2, -2)
			E:Point(hightext, "TOPRIGHT", frame, "BOTTOMRIGHT", -2, -2)

		--[[elseif TYPE == "ColorPicker" then
			local frame = widget.frame
			local colorSwatch = widget.colorSwatch
		]]
		end
		return oldRegisterAsWidget(self, widget)
	end
	AceGUI.RegisterAsWidget = RegisterAsWidget

	local oldRegisterAsContainer = AceGUI.RegisterAsContainer
	RegisterAsContainer = function(self, widget)
		if not E.private.skins.ace3.enable then
			return oldRegisterAsContainer(self, widget)
		end
		local TYPE = widget.type
		if TYPE == "ScrollFrame" then
			local frame = widget.scrollbar
			SkinScrollBar(frame)
		elseif TYPE == "InlineGroup" or TYPE == "TreeGroup" or TYPE == "TabGroup" or TYPE == "Frame" or TYPE == "DropdownGroup" or TYPE == "Window" then
			local frame = widget.content:GetParent()
			if TYPE == "Frame" then
				E:StripTextures(frame)
				if(not E.GUIFrame) then
					E.GUIFrame = frame
				end

				for _, child in ipairs({frame:GetChildren()}) do
					if child:GetObjectType() == "Button" and child:GetText() then
						SkinButton(child)
					else
						E:StripTextures(child)
					end
				end

				--[[for i=1, frame:GetNumChildren() do
					local child = select(i, frame:GetChildren())
					if child:GetObjectType() == "Button" and child:GetText() then
						SkinButton(child)
					else
						E:StripTextures(child)
					end
				end]]
			elseif TYPE == "Window" then
				E:StripTextures(frame)
				S:HandleCloseButton(frame.obj.closebutton)
			end
			E:SetTemplate(frame, "Transparent")

			if widget.treeframe then
				E:SetTemplate(widget.treeframe, "Transparent")
				E:Point(frame, "TOPLEFT", widget.treeframe, "TOPRIGHT", 1, 0)

				local oldCreateButton = widget.CreateButton
				widget.CreateButton = function(self)
					local button = oldCreateButton(self)
					E:StripTextures(button.toggle)
					button.toggle.SetNormalTexture = E.noop
					button.toggle.SetPushedTexture = E.noop
					button.toggleText = button.toggle:CreateFontString(nil, "OVERLAY")
					E:FontTemplate(button.toggleText, nil, 19)
					E:Point(button.toggleText, "CENTER", 0, 0)
					button.toggleText:SetText("+")
					return button
				end

				local oldRefreshTree = widget.RefreshTree
				widget.RefreshTree = function(self, scrollToSelection)
					oldRefreshTree(self, scrollToSelection)
					if not self.tree then return end
					local status = self.status or self.localstatus
					local groupstatus = status.groups
					local lines = self.lines
					local buttons = self.buttons

					for i, line in pairs(lines) do
						local button = buttons[i]
						if groupstatus[line.uniquevalue] and button then
							button.toggleText:SetText("-")
						elseif button then
							button.toggleText:SetText("+")
						end
					end
				end
			end

			if TYPE == "TabGroup" then
				local oldCreateTab = widget.CreateTab
				widget.CreateTab = function(self, id)
					local tab = oldCreateTab(self, id)
					E:StripTextures(tab)
					--[[tab.backdrop = CreateFrame("Frame", nil, tab)
					E:SetTemplate(tab.backdrop, "Transparent")
					tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
					E:Point(tab.backdrop, "TOPLEFT", 10, -3)
					E:Point(tab.backdrop, "BOTTOMRIGHT", -10, 0)]]
					return tab
				end
			end

			if widget.scrollbar then
				SkinScrollBar(widget.scrollbar)
			end
		elseif TYPE == "SimpleGroup" then
			local frame = widget.content:GetParent()
			E:SetTemplate(frame, "Transparent", nil, true) --ignore border updates
			frame:SetBackdropBorderColor(0,0,0,0) --Make border completely transparent
		end

		return oldRegisterAsContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer
end

local function attemptSkin()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		S:SkinAce3()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", attemptSkin)

S:AddCallback("Ace3", attemptSkin)