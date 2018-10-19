local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local pairs = pairs
local join = string.join
--WoW API / Variables
local GetMoney = GetMoney
local IsShiftKeyDown = IsShiftKeyDown

local Profit = 0
local Spent = 0
local resetInfoFormatter = join("", "|cffaaaaaa", L["Reset Data: Hold Shift + Right Click"], "|r")

local function OnEvent(self)
	local NewMoney = GetMoney()
	ElvDB = ElvDB or {}
	ElvDB["gold"] = ElvDB["gold"] or {}
	ElvDB["gold"][E.myrealm] = ElvDB["gold"][E.myrealm] or {}
	ElvDB["gold"][E.myrealm][E.myname] = ElvDB["gold"][E.myrealm][E.myname] or NewMoney

	local OldMoney = ElvDB["gold"][E.myrealm][E.myname] or NewMoney

	local Change = NewMoney - OldMoney
	if OldMoney > NewMoney then
		Spent = Spent - Change
	else
		Profit = Profit + Change
	end

	self.text:SetText(E:FormatMoney(NewMoney, E.db.datatexts.goldFormat or "BLIZZARD"))

	ElvDB["gold"][E.myrealm][E.myname] = NewMoney
end

local function OnClick(self)
	if arg1 == "RightButton" and IsShiftKeyDown() then
		ElvDB.gold = nil
		OnEvent(self)
		DT.tooltip:Hide()
	else
		OpenAllBags()
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)
	local style = E.db.datatexts.goldFormat or "BLIZZARD"

	DT.tooltip:AddLine(L["Session:"])
	DT.tooltip:AddDoubleLine(L["Earned:"], E:FormatMoney(Profit, style), 1, 1, 1, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Spent:"], E:FormatMoney(Spent, style), 1, 1, 1, 1, 1, 1)
	if Profit < Spent then
		DT.tooltip:AddDoubleLine(L["Deficit:"], E:FormatMoney(Profit-Spent, style), 1, 0, 0, 1, 1, 1)
	elseif (Profit - Spent) > 0 then
		DT.tooltip:AddDoubleLine(L["Profit:"], E:FormatMoney(Profit-Spent, style), 0, 1, 0, 1, 1, 1)
	end
	DT.tooltip:AddLine(" ")

	local totalGold = 0;
	DT.tooltip:AddLine(L["Character: "])

	for k, _ in pairs(ElvDB["gold"][E.myrealm]) do
		if ElvDB["gold"][E.myrealm][k] then
			DT.tooltip:AddDoubleLine(k, E:FormatMoney(ElvDB["gold"][E.myrealm][k], style), 1, 1, 1, 1, 1, 1)
			totalGold = totalGold + ElvDB["gold"][E.myrealm][k]
		end
	end

	DT.tooltip:AddLine(" ")
	DT.tooltip:AddLine(L["Server: "])
	DT.tooltip:AddDoubleLine(L["Total: "], E:FormatMoney(totalGold, style), 1, 1, 1, 1, 1, 1)

	DT.tooltip:AddLine(" ")
	DT.tooltip:AddLine(resetInfoFormatter)

	DT.tooltip:Show()
end

DT:RegisterDatatext("Gold", {"PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "SEND_MAIL_MONEY_CHANGED", "SEND_MAIL_COD_CHANGED", "PLAYER_TRADE_MONEY", "TRADE_MONEY_CHANGED"}, OnEvent, nil, OnClick, OnEnter, nil, L["Gold"])