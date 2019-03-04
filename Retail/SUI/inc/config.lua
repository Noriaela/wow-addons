SUIDB = {}

local SUI=CreateFrame("Frame")
SUI:RegisterEvent("PLAYER_LOGIN")
SUI:SetScript("OnEvent", function(self, event)

print("Welcome to |cfff58cbaS|r|cff009cffUI|r use |CFFFE8A0E/SUI|r for Options.")

--SavedVariables Defaults
local defaults = {
	A_UNITFRAMES = true,
	A_PARTYFRAMES = true,
	A_CLASSCOLORS = true,
	A_CASTBARS = true,
	A_HOTKEYS = true,
	A_MACROS = true,
	A_FONTS = false,
	A_GRYPHONES = true,
	A_DARKFRAMES = true,
	A_STATS = true,
	A_CHAT = true,
	A_RANGE = true,
	A_SHORTBAR = false,
	A_TOOLTIP = true,
	A_TABBINDER = false,
	A_SAFEQUEUE = true,
	A_LOSECONTROL = true,
	A_SHOWRAID = false,
	A_HOVERBIND = false,
	A_ITEMLEVEL = true,
	A_INCOMBAT = false,
	A_FRIENDLIST = true,
	A_CHARLINKS = false,
	A_AUTOREP = true,
	A_ORDERHALLBAR = false,
	A_TALKINGHEAD = false,
	A_KEYPRESS = false,
	A_SKINS = false,
	A_EASYDELETE = false,
	A_PARTYBUFFS = false,
	A_TEXTURES = true,
	A_INVISBAGS = false,

	FONTS = {
		NORMAL = "Interface\\AddOns\\SUI\\inc\\media\\fonts\\FRIZQT__.TTF"
	},
	UNITFRAMES = {
		ACTIV = true,
		SIZE = 1,
		LBUFF = 27,
		SBUFF = 25,
		COLOR = true,
		CLASSCOLOR = true,
		HIDEBACK = true,
		HIDESTUFF = true,
	},
	PLAYER = {
		POINT = "CENTER",
		PARENT = "UIParent",
		RELPOINT = "BOTTOMLEFT",
		X = 0,
		Y = 0,
	},
	TARGET = {
		POINT = "CENTER",
		PARENT = "UIParent",
		RELPOINT = "BOTTOMLEFT",
		X = 0,
		Y = 0,
	},
	PLAYERCASTBAR = {
		POINT = "CENTER",
		PARENT = "MainMenuBar",
		RELPOINT = "CENTER",
		X = 0,
		Y = 120,
		TIMER = true,
	},
	TARGETCASTBAR = {
		POINT = "CENTER",
		PARENT = "CastingBarFrame",
		RELPOINT = "CENTER",
		X = 0,
		Y = 150,
		TIMER = true,
	},
	FOCUSCASTBAR = {
		POINT = "CENTER",
		PARENT = "UIParent",
		RELPOINT = "CENTER",
		X = 0,
		Y = 0,
	},
	TOOLTIP = {
		X = -10,
		Y = 180,
	},
	MINIMAP = {
		OLDSYMBOL = false,
		HIDEGARNI = true,
		POINT = "TOPRIGHT",
		PARENT = "UIParent",
		RELPOINT = "TOPRIGHT",
		X = -10,
		Y = -20,
	},
	STATS = {
		ACTIV = true,
		POINT = "BOTTOMRIGHT",
		PARENT = "UIParent",
		RELPOINT = "BOTTOMRIGHT",
		X = -315,
		Y = 5,
		SIZE = 13,
		COLOR = true,
		CLOCK = false,
	},
	SKINS = {
		LITEBAG = true,
	},

	--LORTI
	textures = {
		normal = "Interface\\AddOns\\SUI\\inc\\media\\core\\gloss",
		flash = "Interface\\AddOns\\SUI\\inc\\media\\core\\flash",
		hover = "Interface\\AddOns\\SUI\\inc\\media\\core\\hover",
		pushed = "Interface\\AddOns\\SUI\\inc\\media\\core\\pushed",
		checked = "Interface\\AddOns\\SUI\\inc\\media\\core\\checked",
		equipped = "Interface\\AddOns\\SUI\\inc\\media\\core\\gloss_grey",
		buttonback = "Interface\\AddOns\\SUI\\inc\\media\\core\\button_background",
		buttonbackflat = "Interface\\AddOns\\SUI\\inc\\media\\core\\button_background_flat",
		outer_shadow = "Interface\\AddOns\\SUI\\inc\\media\\core\\outer_shadow"
	},
	background = {
		showbg = true, --show an background image?
		showshadow = true, --show an outer shadow?
		useflatbackground = false, --true uses plain flat color instead
		backgroundcolor = {r = 0.2, g = 0.2, b = 0.2, a = 0.3},
		shadowcolor = {r = 0, g = 0, b = 0, a = 0.9},
		classcolored = false,
		inset = 5
	},
	color = {
		maincolor = {r = 0.37, g = 0.3, b = 0.3},
		normal = {r = 0.37, g = 0.3, b = 0.3},
		equipped = {r = 0.1, g = 0.5, b = 0.1},
		classcolored = false
	},
	hotkeys = {
		show = false,
		fontsize = 12,
		pos1 = {a1 = "TOPRIGHT", x = 0, y = 0},
		pos2 = {a1 = "TOPLEFT", x = 0, y = 0} --important! two points are needed to make the hotkeyname be inside of the button
	},
	macroname = {
		show = false,
		fontsize = 12,
		pos1 = {a1 = "BOTTOMLEFT", x = 0, y = 0},
		pos2 = {a1 = "BOTTOMRIGHT", x = 0, y = 0} --important! two points are needed to make the macroname be inside of the button
	},
	itemcount = {
		show = true,
		fontsize = 12,
		pos1 = {a1 = "BOTTOMRIGHT", x = 0, y = 0}
	},
	cooldown = {
		spacing = 0
	},
	adjustOneletterAbbrev = true,
	consolidatedTooltipScale = 1.2,
	combineBuffsAndDebuffs = false,
	buffFrame = {
		pos = {a1 = "TOPRIGHT", af = "Minimap", a2 = "TOPLEFT", x = -35, y = 0},
		gap = 30, --gap between buff and debuff rows
		userplaced = true, --want to place the bar somewhere else?
		rowSpacing = 10,
		colSpacing = 7,
		buttonsPerRow = 10,
		button = {
		  size = 32
		},
		icon = {
		  padding = -2
		},
		border = {
		  texture = "Interface\\AddOns\\SUI\\inc\\media\\core\\gloss",
		  color = {r = 0.4, g = 0.35, b = 0.35},
		  classcolored = false
		},
		background = {
		  show = true, --show backdrop
		  edgeFile = "Interface\\AddOns\\SUI\\inc\\media\\core\\outer_shadow",
		  color = {r = 0, g = 0, b = 0, a = 0.9},
		  classcolored = false,
		  inset = 6,
		  padding = 4
		},
		duration = {
		  font = STANDARD_TEXT_FONT,
		  size = 12,
		  pos = {a1 = "BOTTOM", x = 0, y = 0}
		},
		count = {
		  font = STANDARD_TEXT_FONT,
		  size = 11,
		  pos = {a1 = "TOPRIGHT", x = 0, y = 0}
		}
	},
	debuffFrame = {
		pos = {a1 = "TOPRIGHT", af = "Minimap", a2 = "TOPLEFT", x = -35, y = -85},
		gap = 10, --gap between buff and debuff rows
		userplaced = true, --want to place the bar somewhere else?
		rowSpacing = 10,
		colSpacing = 7,
		buttonsPerRow = 10,
		button = {
		  size = 34
		},
		icon = {
		  padding = -2
		},
		border = {
		  texture = "Interface\\AddOns\\SUI\\inc\\media\\core\\gloss",
		  color = {r = 0.4, g = 0.35, b = 0.35},
		  classcolored = false
		},
		background = {
		  show = true, --show backdrop
		  edgeFile = "Interface\\AddOns\\SUI\\inc\\media\\core\\outer_shadow",
		  color = {r = 0, g = 0, b = 0, a = 0.9},
		  classcolored = false,
		  inset = 6,
		  padding = 4
		},
		duration = {
		  font = STANDARD_TEXT_FONT,
		  size = 12,
		  pos = {a1 = "BOTTOM", x = 0, y = 0}
		},
		count = {
		  font = STANDARD_TEXT_FONT,
		  size = 11,
		  pos = {a1 = "TOPRIGHT", x = 0, y = 0}
		}
	}
}

--CopyDefaults
local function SUICopyDefaults(src, dst)
	if type(src) ~= "table" then return {} end
	if type(dst) ~= "table" then dst = { } end
	for k, v in pairs(src) do
	if type(v) == "table" then
		dst[k] = SUICopyDefaults(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
		dst[k] = v
		end
	end
		return dst
end

SUIDB = SUICopyDefaults(defaults, SUIDB)

if SUIDB.A_DEFAULTS == nil then
	--Install
	StaticPopupDialogs["INSTALL"] = {
		text = "Welcome to SUI thanks for using it, Pls Support me on Twitch.tv/Syiana",
		button1 = "Install",
		button2 = "Skip",
		OnAccept = function()
			SUIDB.A_DEFAULTS = true
			ReloadUI()
		end,
		OnCancel = function()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}
	StaticPopup_Show("INSTALL")
end

end)

--SUIConfigFrame
local function SUICreateConfig()
	--FRAME
	local SUIConfig = CreateFrame("Frame", "SUIConfig", UIParent, "ButtonFrameTemplate")
	SetPortraitToTexture(SUIConfig.portrait, "Interface\\Icons\\Inv_helmet_06")
	SUIConfig:SetSize(450, 550)
	SUIConfig:SetPoint("CENTER")
	SUIConfig:SetClampedToScreen(true)
	SUIConfig:EnableMouse(true)
	SUIConfig:SetMovable(true)
	SUIConfig:RegisterForDrag("LeftButton")
	SUIConfig:SetScript("OnDragStart",function(self)self:StartMoving()end)
	SUIConfig:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
	SUIConfig:Hide()

	local SUIConfigTitle = SUIConfig:CreateFontString(nil, SUIConfig, "GameFontNormalLarge")
	SUIConfigTitle:SetPoint("TOP", 0, -32)
	SUIConfigTitle:SetText("SUI Config v7.2")

	local SUIConfigTwitch = SUIConfig:CreateFontString(nil, SUIConfig, "GameFontNormalLarge")
	SUIConfigTwitch:SetPoint("BOTTOMRIGHT", SUIConfig, "BOTTOMRIGHT", -10, 5)
	SUIConfigTwitch:SetText("Twitch.tv/Syiana")
	SUIConfigTwitch:SetTextColor(248, 248, 255)

	--COLOR
	for i, v in pairs(
		{
		SUIConfigBg,
		SUIConfigTitleBg
		}
		) do
		v:SetVertexColor(.40, .40, .40)
	end

	for i, v in pairs(
		{
		SUIConfigPortraitFrame,
		SUIConfig.NineSlice.TopEdge,
		SUIConfig.NineSlice.BottomEdge,
		SUIConfig.NineSlice.RightEdge,
		SUIConfig.NineSlice.LeftEdge,
		SUIConfig.NineSlice.TopLeftCorner,
		SUIConfig.NineSlice.BottomLeftCorner,
		SUIConfig.NineSlice.TopRightCorner,
		SUIConfig.NineSlice.BottomRightCorner,
		}
		) do
		v:SetVertexColor(.30, .30, .30)
	end
end
SUICreateConfig()

--SUI SHOW
local function SUICONFIGSHOW()
	--Backdrop
	local backdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
	}

	--POPUPS
	local function HELP()
		StaticPopupDialogs["HELP"] = {
			text = "Pls report Errors on WoWInterface.com or wispher me on Twitch.tv/Syiana",
			button1 = "Close",
			button2 = "Reset UI",
			OnAccept = function()
				SUICONFIGSHOW()
			end,
			OnCancel = function()
				SUIDB = nil
				ReloadUI()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3
		}
		StaticPopup_Show("HELP")
	end

	--FAQ
	local function FAQ()
		print("|CFFFF0303How can i open the Minimap menu ?|R")
		print("|CFF20C000press middle mouse button|R")

		print("|CFFFF0303Is Sivax rly Gay ?|R")
		print("|CFF20C000YES|R")

		print("|CFFFF0303Who is the best Ret in the WORLD ?!|R")
		print("|CFF20C000Syiana!|R")
	end

	--SUI BUTTONS
	local function SUICreateBTN(text,point1,anchor,point2,pos1,pos2,width,height)
		SUIBTN = CreateFrame("Button", nil, SUIConfig, "UIPanelButtonTemplate")
		SUIBTN:SetPoint(point1, anchor, point2, pos1, pos2)
		SUIBTN:SetWidth(width)
		SUIBTN:SetHeight(height)
		SUIBTN:SetText(text)
	end

	--SUI TEXT
	local function SUICreateTXT(text,anchor,point,pos1,pos2, ...)
		SUITXT = SUIConfig:CreateFontString(nil, SUIConfig, "GameFontNormalLarge")
		SUITXT:SetPoint(point, anchor, pos1, pos2)
		SUITXT:SetText(text)
	end

	--SUI CHECKBOX
	local function SUICreateCB(name,anchor,tooltip,db, ...)
		SUICheckbox = CreateFrame("CheckButton", nil , SUIConfig, "OptionsBaseCheckButtonTemplate")
		SUICheckbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -5)

		SUICheckbox:SetScript(
			"OnClick",
			function(frame)
				local tick = frame:GetChecked()
				SUIDB[db] = tick
				if tick then
					DEFAULT_CHAT_FRAME:AddMessage(name .. " Enabled", 0, 1, 0)
					SUIDB[db] = true
				else
					DEFAULT_CHAT_FRAME:AddMessage(name .. " Disabled", 1, 0, 0)
					SUIDB[db] = false
				end
			end
		)
		SUICheckbox:SetScript(
			"OnShow",
			function(frame)
				frame:SetChecked(SUIDB[db])
			end
		)

		SUICheckbox:SetScript(
			"OnEnter",
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
				GameTooltip:AddLine(tooltip, 248, 248, 255)
				GameTooltip:Show()
			end
		)
		SUICheckbox:SetScript("OnLeave", GameTooltip_Hide)

		text = SUIConfig:CreateFontString(nil, SUIConfig, "GameFontHighlight")
		text:SetPoint("LEFT", SUICheckbox, "RIGHT", 0, 1)
		text:SetText(name)

	end

	--[[
	local function showColorPicker(callback)
		ColorPickerFrame:SetColorRGB(SUIDB.color.r,SUIDB.color.g,SUIDB.color.b)
		ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
		ColorPickerFrame.previousValues = {SUIDB.color.r,SUIDB.color.g,SUIDB.color.b,SUIDB.color.a}
		ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = SUIDB.color.r, SUIDB.color.g, SUIDB.color.b
		ColorPickerFrame:Hide() -- Need to run the OnShow handler.
		ColorPickerFrame:Show()
	end
	--]]

	--BUTTONS
	SUICreateBTN("Save & Reload","BOTTOMLEFT",SUIConfig,"BOTTOMLEFT",16,35,100,25)
	SUIBTN:SetScript(
		"OnClick",
		function(self, button, down)
			ReloadUI()
		end
	)

	SUICreateBTN("Help & Reset","BOTTOMLEFT",SUIConfig,"BOTTOMLEFT",120,35,100,25)
	SUIBTN:SetScript(
		"OnClick",
		function(self, button, down)
			SUIConfig:Hide()
			HELP()
		end
	)

	SUICreateBTN("FAQ","BOTTOMLEFT",SUIConfig,"BOTTOMLEFT",225,35,40,25)
	SUIBTN:SetScript(
		"OnClick",
		function(self, button, down)
			FAQ()
		end
	)

	SUICreateBTN("Edit","BOTTOMLEFT",SUIConfig,"BOTTOMRIGHT",-116,35,100,25)
	SUIBTN:SetScript(
		"OnClick",
		function(self, button, down)
			SUIConfig:Hide()
			SUIEDIT()
		end
	)

	--[[
	SUICreateBTN("UI Color","BOTTOMLEFT",SUIConfig,"BOTTOMRIGHT",-116,65,100,25)
	SUIBTN:SetScript(
		"OnClick",
		function(self, button, down)
			SUIConfig:Hide()
			showColorPicker()
		end
	)
	--]]

	--UI
	SUICreateTXT("Custom UI",SUIConfig,"TOPLEFT",20,-75)

	--SPACE
	SUICreateTXT("",SUIConfig,"TOPLEFT",20,-100)

	SUICreateCB("Unitframes",SUITXT,"Custom UnitFrames","A_UNITFRAMES")
	SUICreateCB("PartyFrames",SUICheckbox,"Custom PartyFrames","A_PARTYFRAMES")
	SUICreateCB("Castbars",SUICheckbox,"Custom CastBars","A_CASTBARS")
	SUICreateCB("Chat",SUICheckbox,"Custom Chat","A_CHAT")
	SUICreateCB("Tooltip",SUICheckbox,"Custom Tooltips","A_TOOLTIP")

	--SPACE
	SUICreateTXT("",SUIConfig,"TOPLEFT",180,-100)

	SUICreateCB("Keys",SUITXT,"Show Keys on Actionbar","A_HOTKEYS")
	SUICreateCB("Macros",SUICheckbox,"Show Macros on Actionbar","A_MACROS")
	SUICreateCB("Gryphones",SUICheckbox,"Show Gryphones","A_GRYPHONES")
	SUICreateCB("Dark Frames",SUICheckbox,"Dark Interface","A_DARKFRAMES")
	SUICreateCB("Friendlist",SUICheckbox,"Friendlist Class Colors","A_FRIENDLIST")

	--SPACE
	SUICreateTXT("",SUITXT,"CENTER",150,0)

	SUICreateCB("ShortBar",SUITXT,"Short Actionbar","A_SHORTBAR")
	SUICreateCB("Range",SUICheckbox,"Actionbar Spellrange Color","A_RANGE")
	SUICreateCB("Invismenu",SUICheckbox,"Invisible Mainmenu","A_INVISBAGS")
	SUICreateCB("Textures",SUICheckbox,"Custom Textures","A_TEXTURES")
	SUICreateCB("Fonts",SUICheckbox,"Custom Fonts","A_FONTS")
	--END

	--MISC
	SUICreateTXT("MISC",SUIConfig,"TOPLEFT",20,-270)

	--SPACE
	SUICreateTXT("",SUIConfig,"TOPLEFT",20,-295)

	SUICreateCB("Safequeue",SUITXT,"Time left for Q accept","A_SAFEQUEUE")
	SUICreateCB("LoseControl",SUICheckbox,"Custom Losecontrol","A_LOSECONTROL")
	SUICreateCB("TabBinder",SUICheckbox,"Binds the Tabkey to Player only in Arena","A_TABBINDER")
	SUICreateCB("KeyPress",SUICheckbox,"Keypress Effect on Actionbar","A_KEYPRESS")
	SUICreateCB("Itemlevel",SUICheckbox,"RaidFrameFix Beta","A_ITEMLEVEL")

	--SPACE
	SUICreateTXT("",SUIConfig,"TOPLEFT",180,-295)

	SUICreateCB("ShowRaid",SUITXT,"Show RaidFrame without group","A_SHOWRAID")
	SUICreateCB("InCombat",SUICheckbox,"Incombat Symbols on UnitFrames","A_INCOMBAT")
	SUICreateCB("Charlinks",SUICheckbox,"Charlinks on UnitFrame Menu","A_CHARLINKS")
	SUICreateCB("HoverBind",SUICheckbox,"/hb to bind Keys on Actionbar","A_HOVERBIND")
	SUICreateCB("TalkingHead",SUICheckbox,"Show Talking Head over Actionbar","A_TALKINGHEAD")

	--SPACE
	SUICreateTXT("",SUITXT,"CENTER",150,0)

	SUICreateCB("PartyBuffs",SUITXT,"Big Party Buffs","A_PARTYBUFFS")
	SUICreateCB("FPS/MS",SUICheckbox,"FPS/MS Frame","A_STATS")
	SUICreateCB("AutoRep",SUICheckbox,"Auto Repair","A_AUTOREP")
	SUICreateCB("EasyDelete",SUICheckbox,"Easy delete Items","A_EASYDELETE")
	SUICreateCB("OrderhallBar",SUICheckbox,"Show the Orderhallbar","A_ORDERHALLBAR")
	--END

	SUIConfig:Show()
end

local activ = false
SlashCmdList["SUI"] = function()
	if activ == false then
	SUICONFIGSHOW()
	activ = true
	else
	SUIConfig:Show()
	end
end
SLASH_SUI1 = "/SUI"
