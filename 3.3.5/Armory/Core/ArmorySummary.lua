--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 312 2010-08-27T19:39:01Z
    URL: http://www.wow-neighbours.com

    License:
        This program is free software; you can redistribute it and/or
        modify it under the terms of the GNU General Public License
        as published by the Free Software Foundation; either version 2
        of the License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program(see GPL.txt); if not, write to the Free Software
        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

    Note:
        This AddOn's source code is specifically designed to work with
        World of Warcraft's interpreted AddOn system.
        You have an implicit licence to use this AddOn with these facilities
        since that is it's designated purpose as per:
        http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
--]]

local Armory = Armory;

local totals = {};
local expiredMail;

local function SummaryAutoHide(parent)
    Armory.summary:SetAutoHideDelay(0.5, parent or Armory.summary.parent);
end

local function SummaryHideDetail(currentTooltip)
    for key, tooltip in Armory.qtip:IterateTooltips() do
        if ( #key > 13 and key:sub(1, 13) == "ArmorySummary" and (not currentTooltip or currentTooltip:GetName() ~= key) ) then
            tooltip:Hide();
        end
    end
end

local function GetCoinText(amount, spaced)
    local gold = floor(amount / 10000);
    local goldStr = GOLD_AMOUNT:gsub("%s*%%d%s*", "");
    local silver = mod(floor(amount / 100), 100);
    local silverStr = SILVER_AMOUNT:gsub("%s*%%d%s*", "");
    local copper = mod(floor(amount), 100);
    local copperStr = COPPER_AMOUNT:gsub("%s*%%d%s*", "");

    if ( (copperStr:byte(1) or 128) <= 127 ) then
        goldStr = goldStr:sub(1, 1):lower();
        silverStr = silverStr:sub(1, 1):lower();
        copperStr = copperStr:sub(1, 1):lower();
    end

    if ( amount >= 10000 ) then
        goldStr = format("|cffffffff%d|r|cffffd700%s|r", gold, goldStr);
    else
        goldStr = "";
    end
    if ( amount >= 100 ) then
        silverStr = format("|cffffffff%d|r|cffc7c7cf%s|r", silver, silverStr);
    else
        silverStr = "";
    end
    copperStr = format("|cffffffff%d|r|cffeda55f%s|r", copper, copperStr);
    
    if ( spaced ) then
        return strtrim(format("%s %s %s", goldStr, silverStr, copperStr));
    end
    return goldStr, silverStr, copperStr;
end

local function GetShortDate(value)
    if ( ARMORY_SHORTDATE_FORMAT ~= "ARMORY_SHORTDATE_FORMAT" ) then
        return date(ARMORY_SHORTDATE_FORMAT, value);
    end
    
    local dummy = time({year=3, month=2, day=1});
    local first = tonumber(date("%x", dummy):match("^(%d+)"));
    local day = date("%d", value):gsub("^0*", "");
    local month = date("%b", value);
    local year = "'"..date("%y", value);

    if ( first == 2 ) then
        return month.." "..day.." "..year;
    end
    return day.." "..month.." "..year;
end

local function OnRealmClick(self, realm)
    local collapsed = Armory:RealmState();
    if ( collapsed[realm] ) then
        collapsed[realm] = nil;
    else
        collapsed[realm] = 1;
    end
    Armory:UpdateSummary();
end

local function OnCharacterClick(self, profile, button)
    if ( button == "RightButton" ) then
        if ( not Armory:IsPlayerSelected(profile) ) then
            local dialog = StaticPopup_Show("ARMORY_DELETE_CHARACTER", profile.character);
            dialog.data = profile;
            Armory:HideSummary();
        end
    else
        Armory:HideSummary();
        ArmoryFrameSelectCharacter(profile);
        if ( not ArmoryFrame:IsShown() ) then
            Armory:Toggle();
        end
    end
end

local function CellShowTooltip(self, text)
    SummaryHideDetail();
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 10, -10);
    GameTooltip:SetFrameLevel(self:GetFrameLevel() + 1);
    if ( type(text) == "table" ) then
        GameTooltip:SetText(text[1], 1.0, 1.0, 1.0);
        GameTooltip:AddLine(text[2]);
        Armory:TooltipAddHints(GameTooltip, select(3, unpack(text)));
    elseif ( text:find("|H") ) then
        GameTooltip:SetHyperlink(text);
    else
        GameTooltip:SetText(text);
    end
    GameTooltip:Show();
end

local function CellHideTooltip(self)
    if ( self.oldnewbie ~= nil ) then
        SHOW_NEWBIE_TIPS = self.oldnewbie;
        self.oldnewbie = nil;
    end
    GameTooltip:Hide();
end

local function OnMoneyEnter(self, info)
    SummaryHideDetail();
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetFrameLevel(self:GetFrameLevel() + 1);
    GameTooltip:AddLine(format(ARMORY_MONEY_TOTAL, info[1], info[2]), "", 1, 1, 1);
    SetTooltipMoney(GameTooltip, totals[info[1]][info[2]]);
    GameTooltip:Show();
end

local function OnXPEnter(self, tooltipText)
    SummaryHideDetail();
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetFrameLevel(self:GetFrameLevel() + 1);
    GameTooltip:AddLine(tooltipText, "", 1, 1, 1);
    Armory:TooltipAddHints(GameTooltip, ARMORY_LINK_HINT);
    GameTooltip:Show();
end

local function OnXPClick(self, text, button)
    if ( text and button == "LeftButton" and IsShiftKeyDown() ) then
        if ( not ChatEdit_InsertLink(text) ) then
            ChatEdit_GetLastActiveWindow():Show();
            ChatEdit_InsertLink(text);
        end
    end
end

local function OnExpiredEnter(self, info)
    local tooltip = Armory.qtip:Acquire("ArmorySummaryExpiredTooltip", 3);
    local iconProvider = Armory.qtipIconProvider;
    local index, column, myColumn, name;
    local lastVisit = GetShortDate(info[3]);
    local font = Armory.summary:GetHeaderFont();
    font:SetTextColor(GetTableColor(NORMAL_FONT_COLOR));

    SummaryHideDetail(tooltip);

    tooltip:Clear();
    tooltip:SetScale(Armory:GetConfigFrameScale());
    tooltip:SetFrameLevel(self:GetFrameLevel() + 1);
    tooltip:EnableMouse(true);
    tooltip:SetAutoHideDelay(0.5, self);
    tooltip:SmartAnchorTo(self);

    if ( floor(time() / (24 * 60 * 60)) - floor(info[3] / (24 * 60 * 60)) >= 30 - Armory:GetConfigExpirationDays() ) then
       lastVisit = RED_FONT_COLOR_CODE..lastVisit..FONT_COLOR_CODE_CLOSE;
    end
    index, column = tooltip:AddLine();
    myColumn = column; index, column = tooltip:SetCell(index, myColumn, ARMORY_MAIL_LAST_VISIT, font, "LEFT", 2);
    myColumn = column; index, column = tooltip:SetCell(index, myColumn, lastVisit, font, "RIGHT");
    index, column = tooltip:AddLine();
    myColumn = column; index, column = tooltip:SetCell(index, myColumn, ARMORY_MAIL_ITEM_COUNT, nil, "LEFT", 2);
    myColumn = column; index, column = tooltip:SetCell(index, myColumn, info[4], nil, "RIGHT");
    if ( info[2] and info[2] > 0 ) then    
        index, column = tooltip:AddLine();
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, ARMORY_MAIL_REMAINING, nil, "LEFT", 2);
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, RED_FONT_COLOR_CODE..info[2]..FONT_COLOR_CODE_CLOSE, nil, "RIGHT");
    end
    if ( info[1] ) then    
        index, column = tooltip:AddLine();
        index, column = tooltip:AddHeader();
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, INBOX, font, "LEFT", 2);
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, ARMORY_EXPIRATION_LABEL, font, "RIGHT");
        tooltip:AddSeparator();

        for _, item in ipairs(info[1]) do
            name = Armory:GetColorFromLink(item.link)..item.name..FONT_COLOR_CODE_CLOSE.." ["..item.count.."]";
            if ( item.ignored ) then
                name = name..NORMAL_FONT_COLOR_CODE.." ("..IGNORED..")"..FONT_COLOR_CODE_CLOSE;
            end
            index, column = tooltip:AddLine();
            myColumn = column; index, column = tooltip:SetCell(index, myColumn, GetItemIcon(item.link), iconProvider);
            myColumn = column; index, column = tooltip:SetCell(index, myColumn, name);
            myColumn = column; index, column = tooltip:SetCell(index, myColumn, item.left, nil, "RIGHT");
        end
    end

    tooltip:UpdateScrolling(512);
    tooltip:Show();
        
    SummaryAutoHide(tooltip);
    tooltip.OnRelease = function(self) SummaryAutoHide() end;
end

local function OnEventsEnter(self, info)
    local numEvents = #info;
    if ( numEvents == 0 ) then
        return;
    end

    local tooltip = Armory.qtip:Acquire("ArmorySummaryEventsTooltip", 2);
    local index, column, myColumn;
    local fullDate, title, status, typeName, text;

    SummaryHideDetail(tooltip);
    
    tooltip:Clear();
    tooltip:SetScale(Armory:GetConfigFrameScale());
    tooltip:SetFrameLevel(self:GetFrameLevel() + 1);
    tooltip:EnableMouse(true);
    tooltip:SetAutoHideDelay(0.5, self);
    tooltip:SmartAnchorTo(self);

    tooltip:AddSeparator(2);
    for i = 1, numEvents do
        fullDate, title, status, typeName, text = unpack(info[i]);
        if ( not status ) then
            status = "";
        end
        if ( typeName ) then
            typeName = NORMAL_FONT_COLOR_CODE..typeName..FONT_COLOR_CODE_CLOSE;
        else
            typeName = "";
        end
        if ( text ) then
            text = NORMAL_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
        else
            text = "";
        end
        index, column = tooltip:AddLine();
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, title.." "..typeName.."\n"..fullDate);
        myColumn = column; index, column = tooltip:SetCell(index, myColumn, status.."\n"..text);
        tooltip:AddSeparator(2);
    end

    tooltip:UpdateScrolling(512);
    tooltip:Show();
        
    SummaryAutoHide(tooltip);
    tooltip.OnRelease = function(self) SummaryAutoHide() end;
end

local function OnSkillClick(self, info)
    local currentProfile = Armory:CurrentProfile();
    local currentSkill = Armory:GetSelectedProfession();
    local link;

    Armory:SelectProfile(info);
    Armory:SetSelectedProfession(info.name);
    link = Armory:GetTradeSkillListLink();
    Armory:SetSelectedProfession(currentSkill);
    Armory:SelectProfile(currentProfile);
    
    if ( link ) then
        if ( IsShiftKeyDown() ) then
            if ( not ChatEdit_InsertLink(link) ) then
                ChatEdit_GetLastActiveWindow():Show();
                ChatEdit_InsertLink(link);
            end
        else
            ShowUIPanel(ItemRefTooltip);
            if ( not ItemRefTooltip:IsShown() ) then
                ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
            end
            ItemRefTooltip:SetHyperlink(link:match("|H(.-)|h"));
            Armory:HideSummary();
        end
    end
end

function Armory:ShowSummary(parent)
    if ( self:GetConfigShowSummary() ) then
        local command = ArmoryCommand:new(Armory.InitializeSummary, self, parent);
        command:SetDelay(self:GetConfigSummaryDelay());
        command:Enforce();
        Armory.commandHandler:AddCommand(command);
    end
end

function Armory:InitializeSummary(parent)
    if ( self.summaryEnabled and not ((self.summary and self.summary:IsShown()) or ArmoryDropDownList1:IsVisible()) ) then
        local columns = 3;
        if ( self:GetConfigSummaryClass() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryLevel() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryZone() ) then
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryXP() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryPlayed() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryOnline() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryMoney() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryAchievement() and self:HasAchievements() ) then   
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryQuest() and self:HasQuestLog() ) then
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryExpiration() and self:HasInventory() ) then
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryEvents() and self:HasSocial() ) then
            columns = columns + 1;
        end
        if ( self:GetConfigSummaryTradeSkills() and self:HasTradeSkills() ) then  
            columns = columns + 5;
        end

        self.summary = self.qtip:Acquire("ArmorySummary", columns);
        self.summary:SetScale(Armory:GetConfigFrameScale());
        self.summary:SmartAnchorTo(parent);
        self.summary.parent = parent;
        
        if ( self:HasInventory() ) then
            _, expiredMail = self:CheckMailItems(2);
        end
        
        self:UpdateSummary();
    end    
end

function Armory:UpdateSummary()
    local collapsed = Armory:RealmState();

    local iconProvider = self.qtipIconProvider;
    GameTooltip:Hide();
    self.summary:Clear();

    local font = self.summary:GetHeaderFont();
    font:SetTextColor(GetTableColor(NORMAL_FONT_COLOR));
    
    local unknown = GRAY_FONT_COLOR_CODE..UNKNOWN..FONT_COLOR_CODE_CLOSE;

    local index, column = self.summary:AddHeader();
    local myColumn;

    myColumn = column; index, column = self.summary:SetCell(index, myColumn, "");    
    myColumn = column; index, column = self.summary:SetCell(index, myColumn, NAME, font, "LEFT", 2);
    if ( self:GetConfigSummaryClass() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, CLASS, font);
    end
    if ( self:GetConfigSummaryLevel() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, LEVEL_ABBR, font, "RIGHT");    
    end
    if ( self:GetConfigSummaryZone() ) then
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, ZONE, font);
    end
    if ( self:GetConfigSummaryXP() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, XP, font, "CENTER");
    end
    if ( self:GetConfigSummaryPlayed() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, PLAYED, font, "CENTER");    
    end
    if ( self:GetConfigSummaryOnline() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, LASTONLINE, font, "RIGHT");
    end
    if ( self:GetConfigSummaryMoney() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, MONEY, font, "CENTER");
    end
    if ( self:GetConfigSummaryAchievement() and self:HasAchievements() ) then   
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, "Interface\\Icons\\Achievement_Level_10", iconProvider);
        self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, ACHIEVEMENT_TITLE); 
        self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
    end
    if ( self:GetConfigSummaryQuest() and self:HasQuestLog() ) then
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, "Interface\\Icons\\INV_Misc_Book_08", iconProvider);
        self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, QUESTS_LABEL); 
        self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
    end
    if ( self:GetConfigSummaryExpiration() and self:HasInventory() ) then
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, "Interface\\Icons\\INV_Letter_15", iconProvider);
        self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, ARMORY_EXPIRATION_TITLE); 
        self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
    end
    if ( self:GetConfigSummaryEvents() and self:HasSocial() ) then
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, "Interface\\Calendar\\EventNotification", iconProvider);
        self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, EVENTS_LABEL); 
        self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
    end
    if ( self:GetConfigSummaryTradeSkills() and self:HasTradeSkills() ) then  
        myColumn = column; index, column = self.summary:SetCell(index, myColumn, TRADE_SKILLS, font, "CENTER", 5);
    end

    self.summary:AddSeparator();

    local realms = self:RealmList();
    local currentProfile = self:CurrentProfile();
    local checked, class, classEn, timePlayed, lastPlayed, factionGroup, professions;
    local unit = "player";

    table.wipe(totals);
    
    for _, realm in ipairs(realms) do
        if ( realm ~= ARMORY_LOOKUP_REALM_ALIAS ) then
            totals[realm] = {};
            
            index, column = self.summary:AddLine();

            myColumn = column; 
            if ( #realms > 1 ) then
                index, column = self.summary:SetCell(index, myColumn, format("Interface\\Buttons\\UI-%sButton-Up", collapsed[realm] and "Plus" or "Minus"), iconProvider); 
                self.summary:SetCellScript(index, myColumn, "OnMouseDown", OnRealmClick, realm);
            else
                index, column = self.summary:SetCell(index, myColumn, "");
            end

            myColumn = column; index, column = self.summary:SetCell(index, myColumn, realm, nil, "LEFT", 2); 

            for _, character in ipairs(self:CharacterList(realm)) do
                local profile = {realm=realm, character=character};
                self:SelectProfile(profile);

                factionGroup = self:UnitFactionGroup(unit);
                if ( factionGroup ) then
                    if ( not totals[realm][factionGroup] ) then
                        totals[realm][factionGroup] = self:GetMoney();
                    else
                        totals[realm][factionGroup] = totals[realm][factionGroup] + self:GetMoney();
                    end
                end

                if ( not collapsed[realm] ) then
                    checked = (realm == currentProfile.realm and character == currentProfile.character);

                    class, classEn = self:UnitClass(unit);
                    class = self:ClassColor(classEn, true)..class..FONT_COLOR_CODE_CLOSE;
                    timePlayed, lastPlayed = self:GetTimePlayed();
                    skillIcons = "";
                    
                    index, column = self.summary:AddLine();

                    myColumn = column; 
                    if ( checked ) then
                        index, column = self.summary:SetCell(index, myColumn, "Interface\\Buttons\\UI-CheckBox-Check", iconProvider);
                    else
                        index, column = self.summary:SetCell(index, myColumn, "");
                    end
                    
                    myColumn = column; 
                    if ( factionGroup ) then
                        index, column = self.summary:SetCell(index, myColumn, "Interface\\TargetingFrame\\UI-PVP-"..factionGroup, iconProvider);
                    else
                        index, column = self.summary:SetCell(index, myColumn, "");
                    end
                    myColumn = column; index, column = self.summary:SetCell(index, myColumn, NORMAL_FONT_COLOR_CODE..character..FONT_COLOR_CODE_CLOSE);
                    self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, {character, realm, ARMORY_SELECT_UNIT_HINT, ARMORY_DELETE_UNIT_HINT} ); 
                    self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
                    self.summary:SetCellScript(index, myColumn, "OnMouseDown", OnCharacterClick, profile);

                    if ( self:GetConfigSummaryClass() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, class);
                    end
                    if ( self:GetConfigSummaryLevel() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, self:UnitLevel(unit), nil, "CENTER");
                    end
                    if ( self:GetConfigSummaryZone() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, self:GetZoneText());
                    end
                    if ( self:GetConfigSummaryXP() ) then
                        local xpText, tooltipText, chatText = self:GetXP();
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, xpText or NOT_APPLICABLE, nil, "CENTER");
                        if ( tooltipText ) then
                            self.summary:SetCellScript(index, myColumn, "OnEnter", OnXPEnter, tooltipText);
                            self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip);
                        end
                        self.summary:SetCellScript(index, myColumn, "OnMouseDown", OnXPClick, chatText); 
                    end
                    if ( self:GetConfigSummaryPlayed() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, (timePlayed and SecondsToTime(timePlayed, true)) or unknown, nil, "CENTER");
                    end
                    if ( self:GetConfigSummaryOnline() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, (lastPlayed and GetShortDate(lastPlayed)) or unknown, nil, "CENTER");
                    end
                    if ( self:GetConfigSummaryMoney() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, GetCoinText(self:GetMoney(), true), nil, "RIGHT");
                        if ( factionGroup ) then
                            self.summary:SetCellScript(index, myColumn, "OnEnter", OnMoneyEnter, {realm, factionGroup}); 
                            self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
                        end
                    end
                    if ( self:GetConfigSummaryAchievement() and self:HasAchievements() ) then   
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, self:GetTotalAchievementPoints() or "", nil, "CENTER");
                    end
                    if ( self:GetConfigSummaryQuest() and self:HasQuestLog() ) then
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, select(2, self:GetNumQuestLogEntries()) or "", nil, "CENTER");
                    end
                    if ( self:GetConfigSummaryExpiration() and self:HasInventory() ) then
                        local expired;
                        for profile, items in pairs(expiredMail) do
                            if ( realm == profile.realm and character == profile.character ) then
                                expired = items;
                                break;
                            end
                        end
                        myColumn = column; 
                        local text = "";
                        if ( expired ) then
                            local count = 0;
                            for _, item in ipairs(expired) do
                                if ( not item.ignored ) then
                                    count = count + 1;
                                end
                            end
                            text = count.."/"..#expired;
                        end
                        local _, numItems, _, timestamp = self:GetInventoryContainerInfo(ARMORY_MAIL_CONTAINER);
                        count = self:GetNumRemainingMailItems();
                        if ( count > 0 or floor(time() / (24 * 60 * 60)) - floor(timestamp / (24 * 60 * 60)) >= 30 - self:GetConfigExpirationDays() ) then
                            text = text..RED_FONT_COLOR_CODE.."!"..FONT_COLOR_CODE_CLOSE;
                        end
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, text, nil, "CENTER");
                        self.summary:SetCellScript(index, myColumn, "OnEnter", OnExpiredEnter, {expired, count, timestamp, numItems});
                    end
                    if ( self:GetConfigSummaryEvents() and self:HasSocial() ) then
                        local numEvents = self:GetNumEvents();
                        local eventTime, isOldEvent, title, status, calendarType, typeName, text, fullDate;
                        local events = {};
                        for i = 1, numEvents do
                            eventTime, isOldEvent, title, status, calendarType, typeName, text = ArmoryEventsList_GetEventDetail(i);
                            if ( not isOldEvent ) then
                                if ( not self:GetConfigUseEventLocalTime() ) then
                                    eventTime = self:GetLocalTimeAsServerTime(eventTime);
                                end   
                                eventTime = date("*t", eventTime);
                                fullDate = format(FULLDATE, self:GetFullDate(eventTime));
                                fullDate = format(FULLDATE_AND_TIME, fullDate, GameTime_GetFormattedTime(eventTime.hour, eventTime.min, true));
                                table.insert(events, {fullDate, title, status, typeName, text});
                            end
                        end
                        myColumn = column; index, column = self.summary:SetCell(index, myColumn, #events > 0 and #events or "", nil, "CENTER");
                        self.summary:SetCellScript(index, myColumn, "OnEnter", OnEventsEnter, events);
                    end
                    if ( self:GetConfigSummaryTradeSkills() and self:HasTradeSkills() ) then
                        for _, name in ipairs(self:GetProfessionNames()) do
                            myColumn = column; index, column = self.summary:SetCell(index, myColumn, self:GetProfessionTexture(name), iconProvider);
                            self.summary:SetCellScript(index, myColumn, "OnEnter", CellShowTooltip, {character, name, ARMORY_OPEN_HINT, ARMORY_LINK_HINT}); 
                            self.summary:SetCellScript(index, myColumn, "OnLeave", CellHideTooltip); 
                            self.summary:SetCellScript(index, myColumn, "OnMouseDown", OnSkillClick, {name=name, realm=realm, character=character});
                        end
                    end
                end
            end
        end
    end
    self:SelectProfile(currentProfile);

    self.summary:UpdateScrolling(512);
    self.summary:Show();
    
    SummaryAutoHide();
end

function Armory:HideSummary()
    if ( self.summary ) then
        self.qtip:Release(self.summary);
        Armory.summary = nil;
    end
end
