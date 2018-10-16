﻿local E, L, V, P, G = unpack(select(2, ...));
local LSM = LibStub("LibSharedMedia-3.0");
local Masque = LibStub("Masque", true)

local _G = _G;
local tonumber, pairs, ipairs, error, unpack, select, tostring = tonumber, pairs, ipairs, error, unpack, select, tostring;
local assert, print, type, collectgarbage, pcall, date = assert, print, type, collectgarbage, pcall, date;
local twipe, tinsert, tremove, next = table.wipe, tinsert, tremove, next
local floor = floor;
local format, find, match, strrep, len, sub, gsub = string.format, string.find, string.match, strrep, string.len, string.sub, string.gsub;

local UnitGUID = UnitGUID
local CreateFrame = CreateFrame;
local GetCVar = GetCVar;
local IsAddOnLoaded = IsAddOnLoaded;
local GetSpellInfo = GetSpellInfo;
local IsInInstance, GetNumPartyMembers, GetNumRaidMembers = IsInInstance, GetNumPartyMembers, GetNumRaidMembers;
local RequestBattlefieldScoreData = RequestBattlefieldScoreData;
local GetPrimaryTalentTree, GetActiveTalentGroup = GetPrimaryTalentTree, GetActiveTalentGroup;
local GetCombatRatingBonus = GetCombatRatingBonus;
local UnitStat, UnitAttackPower, UnitBuff = UnitStat, UnitAttackPower, UnitBuff;
local SendAddonMessage = SendAddonMessage;
local InCombatLockdown = InCombatLockdown;
local GetFunctionCPUUsage = GetFunctionCPUUsage;
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT;

-- Constants
E.myfaction, E.myLocalizedFaction = UnitFactionGroup("player")
E.myLocalizedClass, E.myclass, E.myClassID = UnitClass("player")
E.myLocalizedRace, E.myrace = UnitRace("player")
E.myname = UnitName("player")
E.myrealm = GetRealmName()
E.version = GetAddOnMetadata("ElvUI", "Version")
E.wowpatch, E.wowbuild = GetBuildInfo() E.wowbuild = tonumber(E.wowbuild)
E.resolution = GetCVar("gxResolution");
E.screenheight = tonumber(match(E.resolution, "%d+x(%d+)"));
E.screenwidth = tonumber(match(E.resolution, "(%d+)x+%d"));
E.isMacClient = IsMacClient();
E.LSM = LSM;

E["media"] = {};
E["frames"] = {};
E["unitFrameElements"] = {};
E["statusBars"] = {};
E["texts"] = {};
E["snapBars"] = {};
E["RegisteredModules"] = {};
E['RegisteredInitialModules'] = {};
E["ModuleCallbacks"] = {["CallPriority"] = {}}
E["InitialModuleCallbacks"] = {["CallPriority"] = {}}
E['valueColorUpdateFuncs'] = {};
E.TexCoords = {.08, .92, .08, .92};
E.VehicleLocks = {};
E.CreditsList = {};
E.PixelMode = false;

E.InversePoints = {
	TOP = "BOTTOM",
	BOTTOM = "TOP",
	TOPLEFT = "BOTTOMLEFT",
	TOPRIGHT = "BOTTOMRIGHT",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	BOTTOMLEFT = "TOPLEFT",
	BOTTOMRIGHT = "TOPRIGHT",
	CENTER = "CENTER"
};

E.DispelClasses = {
	['PRIEST'] = {
		['Magic'] = true,
		['Disease'] = true
	},
	['SHAMAN'] = {
		['Magic'] = false,
		['Curse'] = true
	},
	['PALADIN'] = {
		['Poison'] = true,
		['Magic'] = false,
		['Disease'] = true
	},
	['MAGE'] = {
		['Curse'] = true
	},
	['DRUID'] = {
		['Magic'] = false,
		['Curse'] = true,
		['Poison'] = true
	},
};

E.HealingClasses = {
	PALADIN = 1,
	SHAMAN = 3,
	DRUID = 3,
	PRIEST = {1, 2}
};

E.ClassRole = {
	PALADIN = {
		[1] = "Caster",
		[2] = "Tank",
		[3] = "Melee"
	},
	PRIEST = "Caster",
	WARLOCK = "Caster",
	WARRIOR = {
		[1] = "Melee",
		[2] = "Melee",
		[3] = "Tank"
	},
	HUNTER = "Melee",
	SHAMAN = {
		[1] = "Caster",
		[2] = "Melee",
		[3] = "Caster"
	},
	ROGUE = "Melee",
	MAGE = "Caster",
	DEATHKNIGHT = {
		[1] = "Tank",
		[2] = "Melee",
		[3] = "Melee"
	},
	DRUID = {
		[1] = "Caster",
		[2] = "Melee",
		[3] = "Caster"
	}
}

E.DEFAULT_FILTER = {}
for filter, tbl in pairs(G.unitframe.aurafilters) do
	E.DEFAULT_FILTER[filter] = tbl.type
end

E.noop = function() end;

local hexvaluecolor
function E:Print(...)
	hexvaluecolor = self["media"].hexvaluecolor or "|cff00b3ff"
	print(hexvaluecolor..'ElvUI:|r', ...)
end

E.PriestColors = {
	r = 0.99,
	g = 0.99,
	b = 0.99
};

local delayedTimer
local delayedFuncs = {}
function E:ShapeshiftDelayedUpdate(func, ...)
	delayedFuncs[func] = {...}

	if delayedTimer then return end

	delayedTimer = E:ScheduleTimer(function()
		for func in pairs(delayedFuncs) do
			func(unpack(delayedFuncs[func]))
		end

		twipe(delayedFuncs)
		delayedTimer = nil
	end, 0.05) 
end

function E:GetPlayerRole()
	local assignedRole = UnitGroupRolesAssigned("player")

	if assignedRole == "NONE" then
		if self.HealingClasses[self.myclass] ~= nil and self:CheckTalentTree(self.HealingClasses[E.myclass]) then
			return "HEALER"
		elseif E.Role == "Tank" then
			return "TANK"
		else
			return "DAMAGER"
		end
	else
		return assignedRole
	end
end

function E:CheckClassColor(r, g, b)
	r, g, b = floor(r*100+.5)/100, floor(g*100+.5)/100, floor(b*100+.5)/100
	local matchFound = false;
	for class, _ in pairs(RAID_CLASS_COLORS) do
		if(class ~= E.myclass) then
			local colorTable = class == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]);
			if(colorTable.r == r and colorTable.g == g and colorTable.b == b) then
				matchFound = true;
			end
		end
	end

	return matchFound;
end

function E:GetColorTable(data)
	if(not data.r or not data.g or not data.b) then
		error("Could not unpack color values.");
	end

	if(data.a) then
		return {data.r, data.g, data.b, data.a};
	else
		return {data.r, data.g, data.b};
	end
end

function E:UpdateMedia()
	if(not self.db["general"] or not self.private["general"]) then return; end

	self["media"].normFont = LSM:Fetch("font", self.db["general"].font);
	self["media"].combatFont = LSM:Fetch("font", self.db["general"].dmgfont);
	self["media"].blankTex = LSM:Fetch("background", "ElvUI Blank");
	self["media"].normTex = LSM:Fetch("statusbar", self.private["general"].normTex);
	self["media"].glossTex = LSM:Fetch("statusbar", self.private["general"].glossTex);

	local border = E.db["general"].bordercolor;
	if(self:CheckClassColor(border.r, border.g, border.b)) then
		local classColor = E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass]);
		E.db["general"].bordercolor.r = classColor.r;
		E.db["general"].bordercolor.g = classColor.g;
		E.db["general"].bordercolor.b = classColor.b;
	end

	self["media"].bordercolor = {border.r, border.g, border.b};

	border = E.db["unitframe"].colors.borderColor
	if self:CheckClassColor(border.r, border.g, border.b) then
		local classColor = E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass])
		E.db["unitframe"].colors.borderColor.r = classColor.r
		E.db["unitframe"].colors.borderColor.g = classColor.g
		E.db["unitframe"].colors.borderColor.b = classColor.b
	end
	self["media"].unitframeBorderColor = {border.r, border.g, border.b}
	self["media"].backdropcolor = E:GetColorTable(self.db["general"].backdropcolor);
	self["media"].backdropfadecolor = E:GetColorTable(self.db["general"].backdropfadecolor);

	local value = self.db["general"].valuecolor;
	if(self:CheckClassColor(value.r, value.g, value.b)) then
		value = E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass]);
		self.db["general"].valuecolor.r = value.r;
		self.db["general"].valuecolor.g = value.g;
		self.db["general"].valuecolor.b = value.b;
	end

	self["media"].hexvaluecolor = self:RGBToHex(value.r, value.g, value.b);
	self["media"].rgbvaluecolor = {value.r, value.g, value.b};

	if(LeftChatPanel and LeftChatPanel.tex and RightChatPanel and RightChatPanel.tex) then
		LeftChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameLeft);
		local a = E.db.general.backdropfadecolor.a or 0.5;
		LeftChatPanel.tex:SetAlpha(a);

		RightChatPanel.tex:SetTexture(E.db.chat.panelBackdropNameRight);
		RightChatPanel.tex:SetAlpha(a);
	end

	self:ValueFuncCall();
	self:UpdateBlizzardFonts();
end

local function LSMCallback()
	E:UpdateMedia();
end
LSM.RegisterCallback(E, "LibSharedMedia_Registered", LSMCallback)

local MasqueGroupState = {}
local MasqueGroupToTableElement = {
	["ActionBars"] = {"actionbar", "actionbars"},
	["Pet Bar"] = {"actionbar", "petBar"},
	["Stance Bar"] = {"actionbar", "stanceBar"},
	["Buffs"] = {"auras", "buffs"},
	["Debuffs"] = {"auras", "debuffs"},
	["Reminder"] = {"auras", "reminder"},
}

local function MasqueCallback(_, Group, _, _, _, _, Disabled)
	if not E.private then return; end

	local element = MasqueGroupToTableElement[Group]

	if element then
		if Disabled then
			if E.private[element[1]].masque[element[2]] and MasqueGroupState[Group] == "enabled" then
				E.private[element[1]].masque[element[2]] = false
				E:StaticPopup_Show("CONFIG_RL")
			end
			MasqueGroupState[Group] = "disabled"
		else
			MasqueGroupState[Group] = "enabled"
		end
	end
end

if Masque then
	Masque:Register("ElvUI", MasqueCallback)
end

function E:RequestBGInfo()
	RequestBattlefieldScoreData();
end

function E:PLAYER_ENTERING_WORLD()
	if(not self.MediaUpdated) then
		self:UpdateMedia();
		self.MediaUpdated = true;
	else
		self:ScheduleTimer("CheckRole", 0.01);
	end

	local _, instanceType = IsInInstance();
	if(instanceType == "pvp") then
		self.BGTimer = self:ScheduleRepeatingTimer("RequestBGInfo", 5);
		self:RequestBGInfo();
	elseif(self.BGTimer) then
		self:CancelTimer(self.BGTimer);
		self.BGTimer = nil;
	end
end

function E:ValueFuncCall()
	for func, _ in pairs(self["valueColorUpdateFuncs"]) do
		func(self["media"].hexvaluecolor, unpack(self["media"].rgbvaluecolor));
	end
end

function E:UpdateFrameTemplates()
	for frame in pairs(self["frames"]) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreFrameTemplates then
				frame:SetTemplate(frame.template, frame.glossTex)
			end
		else
			self["frames"][frame] = nil
		end
	end

	for frame in pairs(self["unitFrameElements"]) do
		if frame and frame.template and not frame.ignoreUpdates then
			if not frame.ignoreFrameTemplates then
				frame:SetTemplate(frame.template, frame.glossTex)
			end
		else
			self["unitFrameElements"][frame] = nil
		end
	end
end

function E:UpdateBorderColors()
	for frame, _ in pairs(self["frames"]) do
		if frame and not frame.ignoreUpdates then
			if not frame.ignoreBorderColors then
				if frame.template == "Default" or frame.template == "Transparent" or frame.template == nil then
					frame:SetBackdropBorderColor(unpack(self["media"].bordercolor))
				end
			end
		else
			self["frames"][frame] = nil
		end
	end

	for frame, _ in pairs(self["unitFrameElements"]) do
		if frame and not frame.ignoreUpdates then
			if not frame.ignoreBorderColors then
				if frame.template == "Default" or frame.template == "Transparent" or frame.template == nil then
					frame:SetBackdropBorderColor(unpack(self["media"].unitframeBorderColor))
				end
			end
		else
			self["unitFrameElements"][frame] = nil
		end
	end
end

function E:UpdateBackdropColors()
	for frame, _ in pairs(self["frames"]) do
		if frame then
			if not frame.ignoreBackdropColors then
				if frame.template == "Default" or frame.template == nil then
					if frame.backdropTexture then
						frame.backdropTexture:SetVertexColor(unpack(self["media"].backdropcolor))
					else
						frame:SetBackdropColor(unpack(self["media"].backdropcolor))
					end
				elseif frame.template == "Transparent" then
					frame:SetBackdropColor(unpack(self["media"].backdropfadecolor))
				end
			end
		else
			self["frames"][frame] = nil
		end
	end

	for frame, _ in pairs(self["unitFrameElements"]) do
		if frame then
			if not frame.ignoreBackdropColors then
				if frame.template == "Default" or frame.template == nil then
					if frame.backdropTexture then
						frame.backdropTexture:SetVertexColor(unpack(self["media"].backdropcolor))
					else
						frame:SetBackdropColor(unpack(self["media"].backdropcolor))
					end
				elseif frame.template == "Transparent" then
					frame:SetBackdropColor(unpack(self["media"].backdropfadecolor))
				end
			end
		else
			self["unitFrameElements"][frame] = nil
		end
	end
end

function E:UpdateFontTemplates()
	for text, _ in pairs(self["texts"]) do
		if(text) then
			text:FontTemplate(text.font, text.fontSize, text.fontStyle);
		else
			self["texts"][text] = nil;
		end
	end
end

function E:RegisterStatusBar(statusBar)
	tinsert(self.statusBars, statusBar);
end

function E:UpdateStatusBars()
	for _, statusBar in pairs(self.statusBars) do
		if(statusBar and statusBar:GetObjectType() == "StatusBar") then
			statusBar:SetStatusBarTexture(self.media.normTex);
		elseif(statusBar and statusBar:GetObjectType() == "Texture") then
			statusBar:SetTexture(self.media.normTex);
		end
	end
end

--This frame everything in ElvUI should be anchored to for Eyefinity support.
E.UIParent = CreateFrame("Frame", "ElvUIParent", UIParent);
E.UIParent:SetFrameLevel(UIParent:GetFrameLevel());
E.UIParent:SetPoint("CENTER", UIParent, "CENTER");
E.UIParent:SetSize(UIParent:GetSize());
E["snapBars"][#E["snapBars"] + 1] = E.UIParent;

E.HiddenFrame = CreateFrame("Frame");
E.HiddenFrame:Hide();

function E:IsDispellableByMe(debuffType)
	if(not self.DispelClasses[self.myclass]) then return; end

	if(self.DispelClasses[self.myclass][debuffType]) then
		return true;
	end
end

function E:CheckTalentTree(tree)
	local activeGroup = GetActiveTalentGroup(false,false)
	if type(tree) == 'number' then
		if activeGroup and GetPrimaryTalentTree(activeGroup-1) then
			return tree == GetPrimaryTalentTree(activeGroup-1)
		end
	elseif type(tree) == 'table' then
		local activeGroup = GetActiveTalentGroup(false,false)
		for _, index in pairs(tree) do
			if activeGroup and GetPrimaryTalentTree(activeGroup-1) then
				return index == GetPrimaryTalentTree(activeGroup-1)
			end
		end
	end
end

function E:CheckForKnownTalent(spellid)
	local wanted_name = GetSpellInfo(spellid)
	if not wanted_name then return nil end

	local num_tabs = GetNumTalentTabs()
	for t = 1, num_tabs do
		local num_talents = GetNumTalents(t)
		for i = 1, num_talents do
			local name_talent, _, _, _, current_rank = GetTalentInfo(t, i)
			if name_talent and (name_talent == wanted_name) then
				if current_rank and (current_rank > 0) then
					return true
				else
					return false
				end
			end
		end
	end
	return false
end

function E:CheckRole()
	local talentTree = GetPrimaryTalentTree();
	local resilperc = GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
	local resilience;
	local role;

	if resilperc > GetDodgeChance() and resilperc > GetParryChance() and UnitLevel("player") == MAX_PLAYER_LEVEL then
		resilience = true;
	else
		resilience = false;
	end

	if(type(self.ClassRole[self.myclass]) == "string") then
		role = self.ClassRole[self.myclass];
	elseif(talentTree) then

		if (self.myclass == "DEATHKNIGHT" and talentTree == 1) and resilience == false
		or (E.myclass == "DRUID" and talentTree == 2 and GetBonusBarOffset() == 3) then
			role = "Tank";
		else
			role = self.ClassRole[self.myclass][talentTree];
		end
	end

	if(not role) then
		local int = select(2, UnitStat("player", 4));
		local agi = select(2, UnitStat("player", 2));
		local base, posBuff, negBuff = UnitAttackPower("player");
		local ap = base + posBuff + negBuff;

		if(ap > int) or (agi > int) then
			role = "Melee";
		else
			role = "Caster";
		end
	end

	if(self.Role ~= role) then
		self.Role = role;
		self.callbacks:Fire("RoleChanged");
	end

	if E.myclass == "SHAMAN" and talentTree == 3 then
		if self:CheckForKnownTalent(77130) then -- Improved Cleanse Spirit
			self.DispelClasses[self.myclass].Magic = true
		else
			self.DispelClasses[self.myclass].Magic = false
		end
	elseif E.myclass == "DRUID" and talentTree == 3 then
		if self:CheckForKnownTalent(88423) then -- Nature's Cure
			self.DispelClasses[self.myclass].Magic = true
		else
			self.DispelClasses[self.myclass].Magic = false
		end
	elseif E.myclass == "PALADIN" and talentTree == 1 then
		if self:CheckForKnownTalent(53551) then -- Sacred Cleansing
			self.DispelClasses[self.myclass].Magic = true
		else
			self.DispelClasses[self.myclass].Magic = false
		end
	end
end

function E:IncompatibleAddOn(addon, module)
	E.PopupDialogs["INCOMPATIBLE_ADDON"].button1 = addon;
	E.PopupDialogs["INCOMPATIBLE_ADDON"].button2 = "ElvUI "..module;
	E.PopupDialogs["INCOMPATIBLE_ADDON"].addon = addon;
	E.PopupDialogs["INCOMPATIBLE_ADDON"].module = module;
	E:StaticPopup_Show("INCOMPATIBLE_ADDON", addon, module);
end

function E:CheckIncompatible()
	if(E.global.ignoreIncompatible) then return; end

	if(IsAddOnLoaded("Prat-3.0") and E.private.chat.enable) then
		E:IncompatibleAddOn("Prat-3.0", "Chat");
	end

	if(IsAddOnLoaded("Chatter") and E.private.chat.enable) then
		E:IncompatibleAddOn("Chatter", "Chat");
	end

	if(IsAddOnLoaded("SnowfallKeyPress") and E.private.actionbar.enable) then
		E.private.actionbar.keyDown = true
		E:IncompatibleAddOn("SnowfallKeyPress", "ActionBar");
	end

	if(IsAddOnLoaded("TidyPlates") and E.private.nameplates.enable) then
		E:IncompatibleAddOn("TidyPlates", "NamePlates");
	end
end

function E:IsFoolsDay()
	if(find(date(), "04/01/") and not E.global.aprilFools) then
		return true;
	else
		return false;
	end
end

function E:CopyTable(currentTable, defaultTable)
	if(type(currentTable) ~= "table") then currentTable = {}; end

	if type(defaultTable) == "table" then
		for option, value in pairs(defaultTable) do
			if(type(value) == "table") then
				value = self:CopyTable(currentTable[option], value);
			end

			currentTable[option] = value;
		end
	end

	return currentTable;
end

function E:RemoveEmptySubTables(tbl)
	if(type(tbl) ~= "table") then
		E:Print("Bad argument #1 to 'RemoveEmptySubTables' (table expected)");
		return;
	end

	for k, v in pairs(tbl) do
		if(type(v) == "table") then
			if next(v) == nil then
				tbl[k] = nil;
			else
				self:RemoveEmptySubTables(v);
			end
		end
	end
end

function E:RemoveTableDuplicates(cleanTable, checkTable)
	if(type(cleanTable) ~= "table") then
		E:Print("Bad argument #1 to 'RemoveTableDuplicates' (table expected)");
		return;
	end
	if(type(checkTable) ~= "table") then
		E:Print("Bad argument #2 to 'RemoveTableDuplicates' (table expected)");
		return;
	end

	local cleaned = {};
	for option, value in pairs(cleanTable) do
		if(type(value) == "table" and checkTable[option] and type(checkTable[option]) == "table") then
			cleaned[option] = self:RemoveTableDuplicates(value, checkTable[option]);
		else
			if(cleanTable[option] ~= checkTable[option]) then
				cleaned[option] = value;
			end
		end
	end

	self:RemoveEmptySubTables(cleaned);

	return cleaned;
end

--Compare 2 tables and remove blacklisted key/value pairs
--param cleanTable : table you want cleaned
--param blacklistTable : table you want to check against.
--return : a copy of cleanTable with blacklisted key/value pairs removed
function E:FilterTableFromBlacklist(cleanTable, blacklistTable)
	if type(cleanTable) ~= "table" then
		E:Print("Bad argument #1 to 'FilterTableFromBlacklist' (table expected)")
		return
	end
	if type(blacklistTable) ~=  "table" then
		E:Print("Bad argument #2 to 'FilterTableFromBlacklist' (table expected)")
		return
	end

	local cleaned = {}
	for option, value in pairs(cleanTable) do
		if type(value) == "table" and blacklistTable[option] and type(blacklistTable[option]) == "table" then
			cleaned[option] = self:FilterTableFromBlacklist(value, blacklistTable[option])
		else
			-- Filter out blacklisted keys
			if blacklistTable[option] ~= true then
				cleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	self:RemoveEmptySubTables(cleaned)

	return cleaned
end

function E:TableToLuaString(inTable)
	if(type(inTable) ~= "table") then
		E:Print("Invalid argument #1 to E:TableToLuaString (table expected)");
		return;
	end

	local ret = "{\n";
	local function recurse(table, level)
		for i, v in pairs(table) do
			ret = ret .. strrep("    ", level).."[";
			if(type(i) == "string") then
				ret = ret .. "\"" .. i .. "\"";
			else
				ret = ret .. i;
			end
			ret = ret .. "] = ";

			if(type(v) == "number") then
				ret = ret .. v .. ",\n"
			elseif(type(v) == "string") then
				ret = ret .. "\"" .. v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\""):gsub("\124", "\124\124") .. "\",\n"
			elseif(type(v) == "boolean") then
				if(v) then
					ret = ret .. "true,\n";
				else
					ret = ret .. "false,\n";
				end
			elseif(type(v) == "table") then
				ret = ret .. "{\n";
				recurse(v, level + 1);
				ret = ret .. strrep("    ", level) .. "},\n";
			else
				ret = ret .. "\""..tostring(v) .. "\",\n";
			end
		end
	end

	if(inTable) then
		recurse(inTable, 1);
	end
	ret = ret.."}";

	return ret;
end

local profileFormat = {
	["profile"] = "E.db",
	["private"] = "E.private",
	["global"] = "E.global",
	["filters"] = "E.global",
	["styleFilters"] = "E.global"
}

local lineStructureTable = {};

function E:ProfileTableToPluginFormat(inTable, profileType)
	local profileText = profileFormat[profileType];
	if(not profileText) then
		return;
	end

	twipe(lineStructureTable);
	local returnString = "";
	local lineStructure = "";
	local sameLine = false;

	local function buildLineStructure()
		local str = profileText;
		for _, v in ipairs(lineStructureTable) do
			if(type(v) == "string") then
				str = str .. "[\"" .. v .. "\"]";
			else
				str = str .. "[" .. v .. "]";
			end
		end

		return str;
	end

	local function recurse(tbl)
		lineStructure = buildLineStructure();
		for k, v in pairs(tbl) do
			if(not sameLine) then
				returnString = returnString .. lineStructure;
			end

			returnString = returnString .. "[";

			if(type(k) == "string") then
				returnString = returnString.."\"" .. k .. "\"";
			else
				returnString = returnString .. k;
			end

			if(type(v) == "table") then
				tinsert(lineStructureTable, k);
				sameLine = true;
				returnString = returnString .. "]";
				recurse(v);
			else
				sameLine = false;
				returnString = returnString .. "] = ";

				if(type(v) == "number") then
					returnString = returnString .. v .. ";\n";
				elseif(type(v) == "string") then
					returnString = returnString .. "\"" .. v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\""):gsub("\124", "\124\124") .. "\"\n"
				elseif(type(v) == "boolean") then
					if(v) then
						returnString = returnString .. "true;\n";
					else
						returnString = returnString .. "false;\n";
					end
				else
					returnString = returnString .. "\"" .. tostring(v) .. "\"\n";
				end
			end
		end

		tremove(lineStructureTable);
		lineStructure = buildLineStructure();
	end

	if(inTable and profileType) then
		recurse(inTable);
	end

	return returnString;
end

function E:StringSplitMultiDelim(s, delim)
	assert(type (delim) == "string" and len(delim) > 0, "bad delimiter");

	local start = 1;
	local t = {};

	while(true) do
		local pos = find(s, delim, start, true);
		if(not pos) then
			break;
		end

		tinsert(t, sub(s, start, pos - 1));
		start = pos + len(delim);
	end

	tinsert(t, sub(s, start));

	return unpack(t);
end

function E:SendMessage()
	local numRaid, numParty = GetNumRaidMembers(), GetNumPartyMembers()
	if numRaid > 1 then
		local _, instanceType = IsInInstance()
		if instanceType == "pvp" then
			SendAddonMessage("ELVUI_VERSIONCHK", E.version, "BATTLEGROUND")
		else
			SendAddonMessage("ELVUI_VERSIONCHK", E.version, "RAID")
		end
	elseif numParty > 0 then
		SendAddonMessage("ELVUI_VERSIONCHK", E.version, "PARTY")
	end

	if E.SendMSGTimer then
		self:CancelTimer(E.SendMSGTimer)
		E.SendMSGTimer = nil
	end
end

local SendRecieveGroupSize
local function SendRecieve(_, event, prefix, message, _, sender)
	if not E.global.general.versionCheck then return end

	if event == "CHAT_MSG_ADDON" then
		if prefix ~= "ELVUI_VERSIONCHK" then return end
		if not sender or sender == E.myname or E.recievedOutOfDateMessage then return end

		message = tonumber(message)

		if message and message > tonumber(E.version) then
			E:Print(L["ElvUI is out of date. You can download the newest version from https://github.com/ElvUI-Cataclysm"])

			if (message - tonumber(E.version)) >= 0.05 then
				E:StaticPopup_Show("ELVUI_UPDATE_AVAILABLE")
			end

			E.recievedOutOfDateMessage = true
		end
	else
		local numRaid, numParty = GetNumRaidMembers(), GetNumPartyMembers() + 1
		local num = numRaid > 0 and numRaid or numParty
		if num ~= SendRecieveGroupSize then
			if num > 1 and SendRecieveGroupSize and num > SendRecieveGroupSize then
				E.SendMSGTimer = E:ScheduleTimer("SendMessage", 12)
			end
			SendRecieveGroupSize = num
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", SendRecieve)

function E:UpdateAll(ignoreInstall)
	self.private = self.charSettings.profile;
	self.db = self.data.profile;
	self.global = self.data.global;
	self.db.theme = nil;
	self.db.install_complete = nil;
	--LibStub('LibDualSpec-1.0'):EnhanceDatabase(self.data, "ElvUI");

	self:SetMoversClampedToScreen(false)

	self:SetMoversPositions();
	self:UpdateMedia();
	self:UpdateCooldownSettings("all")

	local UF = self:GetModule("UnitFrames")
	UF.db = self.db.unitframe;
	UF:Update_AllFrames();

	local CH = self:GetModule("Chat");
	CH.db = self.db.chat;
	CH:PositionChat(true);
	CH:SetupChat();
	CH:UpdateAnchors();

	local AB = self:GetModule("ActionBars");
	AB.db = self.db.actionbar;
	AB:UpdateButtonSettings();
	AB:UpdateMicroPositionDimensions();
	AB:Extra_SetAlpha();
	AB:Extra_SetScale();
	AB:ToggleDesaturation()

	local bags = E:GetModule("Bags"); 
	bags.db = self.db.bags;
	bags:Layout();
	bags:Layout(true);
	bags:SizeAndPositionBagBar();
	bags:UpdateItemLevelDisplay();
	bags:UpdateCountDisplay();

	local totems = E:GetModule("Totems"); 
	totems.db = self.db.general.totems;
	totems:PositionAndSize();
	totems:ToggleEnable();

	self:GetModule("Layout"):ToggleChatPanels();

	local DT = self:GetModule("DataTexts");
	DT.db = self.db.datatexts;
	DT:LoadDataTexts();

	local NP = self:GetModule("NamePlates");
	NP.db = self.db.nameplates;
	NP:StyleFilterInitializeAllFilters()
	NP:ConfigureAll();

	local DataBars = self:GetModule("DataBars");
	DataBars.db = E.db.databars;
	DataBars:UpdateDataBarDimensions();
	DataBars:EnableDisable_ExperienceBar();
	DataBars:EnableDisable_ReputationBar();

	local T = self:GetModule("Threat");
	T.db = self.db.general.threat;
	T:UpdatePosition();
	T:ToggleEnable();

	self:GetModule("Auras").db = self.db.auras
	self:GetModule("Tooltip").db = self.db.tooltip

	if(ElvUIPlayerBuffs) then
		E:GetModule("Auras"):UpdateHeader(ElvUIPlayerBuffs);
	end

	if(ElvUIPlayerDebuffs) then
		E:GetModule("Auras"):UpdateHeader(ElvUIPlayerDebuffs);
	end

	if(self.private.install_complete == nil or (self.private.install_complete and type(self.private.install_complete) == 'boolean') or (self.private.install_complete and type(tonumber(self.private.install_complete)) == 'number' and tonumber(self.private.install_complete) <= 3.83)) then
		if(not ignoreInstall) then
			self:Install();
		end
	end

	self:GetModule("Minimap"):UpdateSettings();
	self:GetModule("AFK"):Toggle();

	self:UpdateBorderColors();
	self:UpdateBackdropColors();

	self:UpdateFrameTemplates();
	self:UpdateStatusBars();

	local LO = E:GetModule("Layout");
	LO:ToggleChatPanels();
	LO:BottomPanelVisibility();
	LO:TopPanelVisibility();
	LO:SetDataPanelStyle();

	self:GetModule("Blizzard"):SetWatchFrameHeight();

	self:SetMoversClampedToScreen(true)

	collectgarbage("collect");
end

function E:EnterVehicleHideFrames(_, unit)
	if(unit ~= "player") then return; end

	for object in pairs(E.VehicleLocks) do
		object:SetParent(E.HiddenFrame);
	end
end

function E:ExitVehicleShowFrames(_, unit)
	if(unit ~= "player") then return; end

	for object, originalParent in pairs(E.VehicleLocks) do
		object:SetParent(originalParent);
	end
end

function E:RegisterObjectForVehicleLock(object, originalParent)
	if(not object or not originalParent) then
		E:Print("Error. Usage: RegisterObjectForVehicleLock(object, originalParent)");
		return;
	end

	object = _G[object] or object;
	if(object.IsProtected and object:IsProtected()) then
		E:Print("Error. Object is protected and cannot be changed in combat.");
		return;
	end

	if(UnitHasVehicleUI("player")) then
		object:SetParent(E.HiddenFrame);
	end

	E.VehicleLocks[object] = originalParent;
end

function E:UnregisterObjectForVehicleLock(object)
	if(not object) then
		E:Print("Error. Usage: UnregisterObjectForVehicleLock(object)");
		return;
	end

	object = _G[object] or object;
	if(not E.VehicleLocks[object]) then
		return;
	end

	local originalParent = E.VehicleLocks[object];
	if(originalParent) then
		object:SetParent(originalParent);
	end

	E.VehicleLocks[object] = nil;
end

function E:ResetAllUI()
	self:ResetMovers();

	if(E.db.lowresolutionset) then
		E:SetupResolution(true)
	end

	if(E.db.layoutSet) then
		E:SetupLayout(E.db.layoutSet, true);
	end
end

function E:ResetUI(...)
	if(InCombatLockdown()) then E:Print(ERR_NOT_IN_COMBAT) return; end

	if(... == "" or ... == " " or ... == nil) then
		E:StaticPopup_Show("RESETUI_CHECK");
		return;
	end

	self:ResetMovers(...);
end

function E:RegisterModule(name, loadFunc)
	if (loadFunc and type(loadFunc) == "function") then
		if self.initialized then
			loadFunc()
		else
			if self.ModuleCallbacks[name] then
				E:Print("Invalid argument #1 to E:RegisterModule (module name:", name, "is already registered, please use a unique name)")
				return
			end

			self.ModuleCallbacks[name] = true
			self.ModuleCallbacks["CallPriority"][#self.ModuleCallbacks["CallPriority"] + 1] = name

			E:RegisterCallback(name, loadFunc, E:GetModule(name))
		end
	else
		if self.initialized then
			self:GetModule(name):Initialize()
		else
			self['RegisteredModules'][#self['RegisteredModules'] + 1] = name
		end
	end
end

function E:RegisterInitialModule(name, loadFunc)
	if (loadFunc and type(loadFunc) == "function") then
		if self.InitialModuleCallbacks[name] then

			E:Print("Invalid argument #1 to E:RegisterInitialModule (module name:", name, "is already registered, please use a unique name)")
			return
		end

		self.InitialModuleCallbacks[name] = true
		self.InitialModuleCallbacks["CallPriority"][#self.InitialModuleCallbacks["CallPriority"] + 1] = name

		E:RegisterCallback(name, loadFunc, E:GetModule(name))
	else
		self['RegisteredInitialModules'][#self['RegisteredInitialModules'] + 1] = name
	end
end

function E:InitializeInitialModules()
	--Fire callbacks for any module using the new system
	for index, moduleName in ipairs(self.InitialModuleCallbacks["CallPriority"]) do
		self.InitialModuleCallbacks[moduleName] = nil;
		self.InitialModuleCallbacks["CallPriority"][index] = nil
		E.callbacks:Fire(moduleName)
	end

	--Old deprecated initialize method, we keep it for any plugins that may need it
	for _, module in pairs(E["RegisteredInitialModules"]) do
		module = self:GetModule(module, true);
		if(module and module.Initialize) then
			local _, catch = pcall(module.Initialize, module);
			if(catch and GetCVarBool("scriptErrors") == 1) then
				ScriptErrorsFrame_OnError(catch, false);
			end
		end
	end
end

function E:RefreshModulesDB()
	local UF = self:GetModule("UnitFrames");
	twipe(UF.db);
	UF.db = self.db.unitframe;
end

function E:InitializeModules()
	--Fire callbacks for any module using the new system
	for index, moduleName in ipairs(self.ModuleCallbacks["CallPriority"]) do
		self.ModuleCallbacks[moduleName] = nil;
		self.ModuleCallbacks["CallPriority"][index] = nil
		E.callbacks:Fire(moduleName)
	end

	--Old deprecated initialize method, we keep it for any plugins that may need it
	for _, module in pairs(E["RegisteredModules"]) do
		module = self:GetModule(module);
		if(module.Initialize) then
			local _, catch = pcall(module.Initialize, module);
			if(catch and GetCVarBool("scriptErrors") == 1) then
				ScriptErrorsFrame_OnError(catch, false);
			end
		end
	end
end

--DATABASE CONVERSIONS
function E:DBConversions()
	--Combat & Resting Icon options update
	if E.db.unitframe.units.player.combatIcon ~= nil then
		E.db.unitframe.units.player.CombatIcon.enable = E.db.unitframe.units.player.combatIcon
		E.db.unitframe.units.player.combatIcon = nil
	end
	if E.db.unitframe.units.player.restIcon ~= nil then
		E.db.unitframe.units.player.RestIcon.enable = E.db.unitframe.units.player.restIcon
		E.db.unitframe.units.player.restIcon = nil
	end

	--Convert old "Buffs and Debuffs" font size option to individual options
	if E.db.auras.fontSize then
		local fontSize = E.db.auras.fontSize
		E.db.auras.buffs.countFontSize = fontSize
		E.db.auras.buffs.durationFontSize = fontSize
		E.db.auras.debuffs.countFontSize = fontSize
		E.db.auras.debuffs.durationFontSize = fontSize
		E.db.auras.fontSize = nil
	end

	--Convert old private cooldown setting to profile setting
	if E.private.cooldown and (E.private.cooldown.enable ~= nil) then
		E.db.cooldown.enable = E.private.cooldown.enable
		E.private.cooldown.enable = nil
		E.private.cooldown = nil
	end

	if not E.db.chat.panelColorConverted then
		local color = E.db.general.backdropfadecolor
		E.db.chat.panelColor = {r = color.r, g = color.g, b = color.b, a = color.a}
		E.db.chat.panelColorConverted = true
	end
end

local CPU_USAGE = {};
local function CompareCPUDiff(showall, module, minCalls)
	local greatestUsage, greatestCalls, greatestName, newName, newFunc;
	local greatestDiff, lastModule, mod, newUsage, calls, differance = 0;

	for name, oldUsage in pairs(CPU_USAGE) do
		newName, newFunc = name:match("^([^:]+):(.+)$");
		if(not newFunc) then
			E:Print("CPU_USAGE:", name, newFunc);
		else
			if(newName ~= lastModule) then
				mod = E:GetModule(newName, true) or E;
				lastModule = newName;
			end
			newUsage, calls = GetFunctionCPUUsage(mod[newFunc], true);
			differance = newUsage - oldUsage;
			if showall and (calls > minCalls) then
				E:Print('Name('..name..')  Calls('..calls..') Diff('..(differance > 0 and format("%.3f", differance) or 0)..')')
			end
			if((differance > greatestDiff) and calls > minCalls) then
				greatestName, greatestUsage, greatestCalls, greatestDiff = name, newUsage, calls, differance;
			end
		end
	end

	if(greatestName) then
		E:Print(greatestName.. " had the CPU usage difference of: "..(greatestUsage > 0 and format("%.3f", greatestUsage) or 0).."ms. And has been called ".. greatestCalls.." times.")
	else
		E:Print("CPU Usage: No CPU Usage differences found.");
	end

	twipe(CPU_USAGE)
end

function E:GetTopCPUFunc(msg)
	if not GetCVarBool("scriptProfile") then
		E:Print("For `/cpuusage` to work, you need to enable script profiling via: `/console scriptProfile 1` then reload. Disable after testing by setting it back to 0.")
		return
	end

	local module, showall, delay, minCalls = msg:match("^(%S+)%s*(%S*)%s*(%S*)%s*(.*)$")
	local checkCore, mod = (not module or module == "") and "E"

	showall = (showall == "true" and true) or false
	delay = (delay == "nil" and nil) or tonumber(delay) or 5
	minCalls = (minCalls == "nil" and nil) or tonumber(minCalls) or 15

	twipe(CPU_USAGE)
	if module == "all" then
		for moduName, modu in pairs(self.modules) do
			for funcName, func in pairs(modu) do
				if (funcName ~= "GetModule") and (type(func) == "function") then
					CPU_USAGE[moduName..":"..funcName] = GetFunctionCPUUsage(func, true)
				end
			end
		end
	else
		if not checkCore then
			mod = self:GetModule(module, true)
			if not mod then
				self:Print(module.." not found, falling back to checking core.")
				mod, checkCore = self, "E"
			end
		else
			mod = self
		end

		for name, func in pairs(mod) do
			if (name ~= "GetModule") and type(func) == "function" then
				CPU_USAGE[(checkCore or module)..":"..name] = GetFunctionCPUUsage(func, true)
			end
		end
	end

	self:Delay(delay, CompareCPUDiff, showall, module, minCalls)
	self:Print("Calculating CPU Usage differences (module: "..(checkCore or module)..", showall: "..tostring(showall)..", minCalls: "..tostring(minCalls)..", delay: "..tostring(delay)..")")
end

function E:Initialize()
	twipe(self.db);
	twipe(self.global);
	twipe(self.private)

	self.myguid = UnitGUID("player")
	self.data = LibStub("AceDB-3.0"):New("ElvDB", self.DF);
	self.data.RegisterCallback(self, "OnProfileChanged", "UpdateAll");
	self.data.RegisterCallback(self, "OnProfileCopied", "UpdateAll");
	self.data.RegisterCallback(self, "OnProfileReset", "OnProfileReset");
	LibStub("LibDualSpec-1.0"):EnhanceDatabase(self.data, "ElvUI");
	self.charSettings = LibStub("AceDB-3.0"):New("ElvPrivateDB", self.privateVars);
	self.private = self.charSettings.profile;
	self.db = self.data.profile;
	self.global = self.data.global;
	self:CheckIncompatible();
	self:DBConversions();

	self:ScheduleTimer("CheckRole", 0.01);
	self:UIScale("PLAYER_LOGIN");

	self:LoadCommands();
	self:InitializeModules();
	self:LoadMovers();
	self:UpdateCooldownSettings("all")
	self.initialized = true;

	if(self.private.install_complete == nil) then
		self:Install();
	end

	if(not find(date(), "04/01/")) then
		E.global.aprilFools = nil;
	end

	if(self:HelloKittyFixCheck()) then
		self:HelloKittyFix();
	end

	self:UpdateMedia();
	self:UpdateFrameTemplates();
	self:UpdateBorderColors()
	self:UpdateBackdropColors()
	self:UpdateStatusBars()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "CheckRole");
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "CheckRole");
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "CheckRole");
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "CheckRole");
	self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "CheckRole");
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "UIScale");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "EnterVehicleHideFrames")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "ExitVehicleShowFrames")

	if(self.db.general.kittys) then
		self:CreateKittys();
		self:Delay(5, self.Print, self, L["Type /hellokitty to revert to old settings."]);
	end

	self:Tutorials();
	self:GetModule("Minimap"):UpdateSettings();
	self:RefreshModulesDB()
	collectgarbage("collect");

	if(self.db.general.loginmessage) then
		print(select(2, E:GetModule("Chat"):FindURL("CHAT_MSG_DUMMY", format(L["LOGIN_MSG"], self["media"].hexvaluecolor, self["media"].hexvaluecolor, self.version)))..".");
	end
end