local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local RM = E:NewModule("RaidMarkersBar");
local EP = LibStub("LibElvUIPlugin-1.0");

--Cache global variables
--Lua functions
local ipairs = ipairs
local format = string.format
--WoW API / Variables
local CreateFrame = CreateFrame
local SetRaidTargetIcon = SetRaidTargetIcon
local UnitInParty = UnitInParty
local UnitIsPartyLeader = UnitIsPartyLeader

-- Profile
P["actionbar"]["raidmarkersbar"] = {
	["orient"] = "HORIZONTAL",
	["sort"] = "DESCENDING",
	["buttonSize"] = 18,
	["buttonSpacing"] = 5
}

-- Config
local function InjectOptions()
	E.Options.args.actionbar.args.raidMarkers = {
		order = 1000,
		type = "group",
		name = L["Raid Markers Bar"],
		get = function(info) return E.db.actionbar.raidmarkersbar[ info[getn(info)] ] end,
		set = function(info, value) E.db.actionbar.raidmarkersbar[ info[getn(info)] ] = value RM:UpdateBar() end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Raid Markers"]
			},
			sort = {
				order = 2,
				type = "select",
				name = L["Sort Direction"],
				desc = L["The direction that the mark frames will grow from the anchor."],
				values = {
					["ASCENDING"] = L["Ascending"],
					["DESCENDING"] = L["Descending"]
				}
			},
			orient = {
				order = 3,
				type = "select",
				name = L["Bar Direction"],
				desc = L["Choose the orientation of the raid markers bar."],
				values = {
					["HORIZONTAL"] = L["Horizontal"],
					["VERTICAL"] = L["Vertical"]
				}
			},
			buttonSize = {
				order = 4,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1
			},
			buttonSpacing = {
				order = 5,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 10, step = 1
			}
		}
	}
end

function RM:UpdateBar(first)
	if first then
		self.frame:ClearAllPoints()
		E:Point(self.frame, "CENTER", 0, 0)
	end

	if self.db.orient == "VERTICAL" then
		E:Size(self.frame, self.db.buttonSize + (self.db.buttonSpacing*2), (self.db.buttonSize + self.db.buttonSpacing) * 9 + self.db.buttonSpacing)
	else
		E:Size(self.frame, (self.db.buttonSize + self.db.buttonSpacing) * 9 + self.db.buttonSpacing, self.db.buttonSize + (self.db.buttonSpacing*2))
	end

	for i = 1, 9 do
		local button = self.frame.buttons[i]
		local prev = self.frame.buttons[i - 1]
		E:Size(button, self.db.buttonSize)
		button:ClearAllPoints()

		if self.db.orient == "HORIZONTAL" and self.db.sort == "ASCENDING" then
			if i == 1 then
				E:Point(button, "LEFT", self.db.buttonSpacing, 0)
			elseif prev then
				E:Point(button, "LEFT", prev, "RIGHT", self.db.buttonSpacing, 0)
			end
		elseif self.db.orient == "VERTICAL" and self.db.sort == "ASCENDING" then
			if i == 1 then
				E:Point(button, "TOP", 0, -self.db.buttonSpacing)
			elseif(prev) then
				E:Point(button, "TOP", prev, "BOTTOM", 0, -self.db.buttonSpacing)
			end
		elseif self.db.orient == "HORIZONTAL" and self.db.sort == "DESCENDING" then
			if i == 1 then
				E:Point(button, "RIGHT", -self.db.buttonSpacing, 0)
			elseif prev then
				E:Point(button, "RIGHT", prev, "LEFT", -self.db.buttonSpacing, 0)
			end
		else
			if i == 1 then
				E:Point(button, "BOTTOM", 0, self.db.buttonSpacing, 0)
			elseif prev then
				E:Point(button, "BOTTOM", prev, "TOP", 0, self.db.buttonSpacing)
			end
		end
	end

	self.frame:SetScript("OnEvent", function()
		if event then
			if UnitInParty("player") and UnitIsPartyLeader("player") then
				self.frame:Show()
			else
				self.frame:Hide()
			end
		end
	end)
end

function RM:ButtonFactory()
	for i = 1, 9 do
		local button = CreateFrame("Button", format("ElvUI_RaidMarkersBarButton%d", i), self.frame, "ActionButtonTemplate")
		E:StripTextures(button)
		E:SetTemplate(button, "Default", true)

		local image = button:CreateTexture(nil, "OVERLAY")
		E:SetInside(image)
		image:SetTexture(i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or format("Interface\\AddOns\\ElvUI_RaidMarkers\\Media\\UI-RaidTargetingIcon_%d", i))

		button:SetID(i)

		button:SetScript("OnClick", function()
			SetRaidTargetIcon("target", this:GetID() < 9 and this:GetID() or 0)
		end)

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
			GameTooltip:AddLine(this:GetID() == 9 and L["Click to clear the mark."] or L["Click to mark the target."], 1, 1, 1)
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		E:StyleButton(button)
		self.frame.buttons[i] = button
	end
end

function RM:Initialize()
	self.db = E.db.actionbar.raidmarkersbar

	self.frame = CreateFrame("Frame", "ElvUI_RaidMarkersBar", E.UIParent)
	self.frame:SetResizable(false)
	self.frame:SetClampedToScreen(true)
	E:SetTemplate(self.frame, "Transparent")

	self.frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.frame.buttons = {}
	self:ButtonFactory()
	self:UpdateBar(true)

	E:CreateMover(self.frame, "ElvUI_RMBarMover", L["Raid Markers Bar"])
end

EP:RegisterPlugin("ElvUI_RaidMarkers", InjectOptions)

local function InitializeCallback()
	RM:Initialize()
end

E:RegisterModule(RM:GetName(), InitializeCallback)