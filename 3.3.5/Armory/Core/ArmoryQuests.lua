--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 310 2010-08-20T17:28:21Z
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
local container = "Quests";

local selectedQuestLine = 0;
local questLogFilter = "";

----------------------------------------------------------
-- Quests Internals
----------------------------------------------------------

local questLines = {};
local dirty = true;
local owner = "";

local function GetQuestLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local count = dbEntry:GetNumValues(container);
    local collapsed = false;
    local hasItems = (questLogFilter == "");
    local include, text, numItems;

    table.wipe(questLines);
    
    for i = 1, count do
        local name, _, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
        local id = dbEntry:GetValue(container, i, "Data");
        local isCollapsed = Armory:GetHeaderLineState(container, name);
        if ( isHeader ) then
            table.insert(questLines, i);
            collapsed = isCollapsed;
        elseif ( not collapsed ) then
            if ( questLogFilter == "" ) then
                include = true;
            else
                text = name.."\t"..dbEntry:GetValue(container, id, "Text");
                numItems = dbEntry:GetValue(container, id, "NumLeaderBoards") or 0;
                if ( numItems > 0 and dbEntry:Contains(container, id, "LeaderBoards") ) then
                    for index = 1, numItems do
                        text = text.."\t"..(dbEntry:GetValue(container, id, "LeaderBoards", index) or "");
                    end
                end
                numItems = dbEntry:GetValue(container, id, "NumRewards") or 0;
                if ( numItems > 0 and dbEntry:Contains(container, id, "Rewards") ) then
                    for index = 1, numItems do
                        text = text.."\t"..(dbEntry:GetValue(container, id, "Rewards", "Info"..index) or "");
                    end
                end
                _, name = dbEntry:GetValue(container, id, "RewardSpell");
                if ( name ) then
                    text = text.."\t"..name;
                end
                include = string.find(strlower(text), strlower(questLogFilter), 1, true);
            end
            if ( include ) then
                hasItems = true;
                table.insert(questLines, i);
            end
        end
    end
    
    if ( not hasItems ) then
        table.wipe(questLines);
    end
    
    dirty = false;
    owner = Armory:SelectedCharacter();

    return questLines;
end

local function GetQuestLineValue(index, key, subkey)
    local numLines = Armory:GetNumQuestLogEntries();
    if ( index > 0 and index <= numLines ) then
        local dbEntry = Armory.selectedDbBaseEntry;
        local id = dbEntry:GetValue(container, questLines[index], "Data");
        if ( subkey ) then
            return dbEntry:GetValue(container, id, key, subkey);
        elseif ( key ) then
            return dbEntry:GetValue(container, id, key);
        else
            return dbEntry:GetValue(container, questLines[index], "Info");
        end
    end
end

local function UpdateQuestHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( index == 0 ) then
        for i = 1, dbEntry:GetNumValues(container) do
            local name, _, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
            if ( isHeader ) then
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    else
        local numLines = Armory:GetNumQuestLogEntries();
        if ( index > 0 and index <= numLines ) then
            local name = dbEntry:GetValue(container, questLines[index], "Info");
            Armory:SetHeaderLineState(container, name, isCollapsed);
        end
    end
    
    dirty = true;
end

----------------------------------------------------------
-- Quests Storage
----------------------------------------------------------

function Armory:ClearQuests()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

function Armory:UpdateQuests()
    local dbEntry = self.playerDbBaseEntry;

    if ( not self:IsLocked(container) ) then
        if ( self.ignoreQuestUpdate ) then
            self.ignoreQuestUpdate = false;
            return;
        end
        
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        if ( self:HasQuestLog() ) then
            local _, numQuests = _G.GetNumQuestLogEntries();
            local currentQuest = _G.GetQuestLogSelection();

            -- store the complete (expanded) list
            local funcNumLines = _G.GetNumQuestLogEntries;
            local funcGetLineInfo = _G.GetQuestLogTitle;
            local funcGetLineState = function(index)
                local _, _, _, _, isHeader, isCollapsed = _G.GetQuestLogTitle(index);
                return isHeader, not isCollapsed;
            end;
            local funcExpand = _G.ExpandQuestHeader;
            local funcCollapse = _G.CollapseQuestHeader;
            local funcSelect = function(index)
                _G.SelectQuestLogEntry(index);
                ProcessQuestLogRewardFactions();
            end;
            local funcAdditionalInfo = function(index)
                local link = _G.GetQuestLink(index);
                local _, id = self:GetLinkId(link);
                local info = dbEntry:SelectContainer(container, id);
                info.Link = link;
                info.Failed = _G.IsCurrentQuestFailed();
                info.Text = _G.GetQuestLogQuestText();
                info.TimeLeft = dbEntry.Save(_G.GetQuestLogTimeLeft(), time()); 
                info.RequiredMoney = _G.GetQuestLogRequiredMoney();
                info.RewardMoney = _G.GetQuestLogRewardMoney();
                info.RewardHonor = _G.GetQuestLogRewardHonor();
                info.RewardSpell = _G.GetQuestLogRewardSpell();
                info.RewardTalents = _G.GetQuestLogRewardTalents();
                info.RewardXP = _G.GetQuestLogRewardXP();
                info.RewardArenaPoints = _G.GetQuestLogRewardArenaPoints();
                info.SpellLink = _G.GetQuestLogSpellLink();
                info.RewardTitle = _G.GetQuestLogRewardTitle();
                info.GroupNum = _G.GetQuestLogGroupNum();
                info.NumLeaderBoards = _G.GetNumQuestLeaderBoards();
                info.LeaderBoards = {};
                for i = 1, info.NumLeaderBoards do
                    info.LeaderBoards[i] = dbEntry.Save(_G.GetQuestLogLeaderBoard(i));
                end
                info.NumRewards = _G.GetNumQuestLogRewards();
                info.Rewards = {};
                for i = 1, info.NumRewards do
                    info.Rewards["Info"..i] = dbEntry.Save(_G.GetQuestLogRewardInfo(i));
                    info.Rewards["Link"..i] = dbEntry.Save(_G.GetQuestLogItemLink("reward", i));
                end
                info.NumChoices = _G.GetNumQuestLogChoices();
                info.Choices = {};
                for i = 1, info.NumChoices do
                    info.Choices["Info"..i] = dbEntry.Save(_G.GetQuestLogChoiceInfo(i));
                    info.Choices["Link"..i] = dbEntry.Save(_G.GetQuestLogItemLink("choice", i));
                end
                info.NumFactions = _G.GetNumQuestLogRewardFactions();
                if ( info.NumFactions ) then
                    info.Factions = {};
                    for i = 1, info.NumFactions do
                        info.Factions["Info"..i] = dbEntry.Save(_G.GetQuestLogRewardFactionInfo(i));
                    end
                end
                return id;
            end;
            
            -- LightHeaded hooks SelectQuestLogEntry
            local stubbed;
            if ( LightHeaded ) then
                stubbed = LightHeaded.GetCurrentQID;
                LightHeaded.GetCurrentQID = function() return nil; end;
            end
            
            dbEntry:ClearContainer(container);
           
            -- if expand/collapse has been called a QUEST_LOG_UPDATE event will be fired immediately after the scan has been completed
            self.ignoreQuestUpdate = dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse, funcAdditionalInfo, funcSelect);

            dbEntry:SetValue(2, container, "NumQuests", numQuests);
            dbEntry:SetValue(2, container, "MaxDailyQuests", _G.GetMaxDailyQuests());
            dbEntry:SetValue(2, container, "DailyQuestsCompleted", _G.GetDailyQuestsCompleted());

            _G.SelectQuestLogEntry(currentQuest);
            
            if ( stubbed ) then
                LightHeaded.GetCurrentQID = stubbed;
            end
        else
            dbEntry:SetValue(container, nil);
        end

        dirty = dirty or self:IsPlayerSelected();
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Quests Interface
----------------------------------------------------------

function Armory:GetQuestLogIndexByName(name)
    local dbEntry = self.playerDbBaseEntry;
    if ( name ) then
        local count = dbEntry:GetNumValues(container);
        for i = 1, count do
            if ( strtrim(name) == dbEntry:GetValue(container, i, "Info") ) then
                return i;
            end
        end
    end
end

function Armory:GetQuestHeader(index)
    local dbEntry = self.playerDbBaseEntry;
    for i = index, 1, -1 do
        local title, _, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
        if ( isHeader ) then
            return title;
        end
    end
    return UNKNOWN;
end

function Armory:IsOnQuest(id)
    return self.selectedDbBaseEntry:Contains(container, id);
end

function Armory:GetDailyQuestsCompleted()
    return self.selectedDbBaseEntry:GetValue(container, "DailyQuestsCompleted") or 0;
end

function Armory:GetMaxDailyQuests()
    return self.selectedDbBaseEntry:GetValue(container, "MaxDailyQuests") or 0;
end

function Armory:GetNumQuestLogEntries()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetQuestLines();
    end
    local numQuests = self.selectedDbBaseEntry:GetValue(container, "NumQuests") or 0;
    return #questLines, numQuests;
end

function Armory:GetQuestLogTitle(index)
    local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID = GetQuestLineValue(index);
    isCollapsed = self:GetHeaderLineState(container, title);
    return title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID;
end

function Armory:ExpandQuestHeader(index)
    UpdateQuestHeaderState(index, false);
end

function Armory:CollapseQuestHeader(index)
    UpdateQuestHeaderState(index, true);
end

function Armory:GetQuestLink(index)
    return GetQuestLineValue(index, "Link");
end

function Armory:GetQuestLogSelection()
    return selectedQuestLine;
end

function Armory:SelectQuestLogEntry(index)
    selectedQuestLine = index;
end

function Armory:IsCurrentQuestFailed()
    return GetQuestLineValue(selectedQuestLine, "Failed");
end

function Armory:GetQuestLogQuestText()
    return GetQuestLineValue(selectedQuestLine, "Text");
end

function Armory:GetQuestLogTimeLeft()
    local timeLeft, timestamp = GetQuestLineValue(selectedQuestLine, "TimeLeft");

    if ( timeLeft ) then
        timeLeft = timeLeft - (time() - timestamp);
        if ( timeLeft < 0 ) then
            timeLeft = 0;
        end
    end
    return timeLeft;
end

function Armory:GetQuestLogRequiredMoney()
    return GetQuestLineValue(selectedQuestLine, "RequiredMoney");
end

function Armory:GetQuestLogRewardMoney()
    return GetQuestLineValue(selectedQuestLine, "RewardMoney");
end

function Armory:GetQuestLogRewardHonor()
    return GetQuestLineValue(selectedQuestLine, "RewardHonor");
end

function Armory:GetQuestLogRewardSpell()
    return GetQuestLineValue(selectedQuestLine, "RewardSpell");
end

function Armory:GetQuestLogRewardTalents()
    return GetQuestLineValue(selectedQuestLine, "RewardTalents");
end

function Armory:GetQuestLogRewardXP()
    return GetQuestLineValue(selectedQuestLine, "RewardXP");
end

function Armory:GetQuestLogRewardArenaPoints()
    return GetQuestLineValue(selectedQuestLine, "RewardArenaPoints");
end

function Armory:GetQuestLogRewardTitle()
    return GetQuestLineValue(selectedQuestLine, "RewardTitle");
end

function Armory:GetQuestLogSpellLink()
    return GetQuestLineValue(selectedQuestLine, "SpellLink");
end

function Armory:GetQuestLogGroupNum()
    return GetQuestLineValue(selectedQuestLine, "GroupNum");
end

function Armory:GetNumQuestLeaderBoards()
    return GetQuestLineValue(selectedQuestLine, "NumLeaderBoards");
end

function Armory:GetQuestLogLeaderBoard(id)
    return GetQuestLineValue(selectedQuestLine, "LeaderBoards", id);
end

function Armory:GetNumQuestLogRewards()
    return GetQuestLineValue(selectedQuestLine, "NumRewards");
end

function Armory:GetQuestLogRewardInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Rewards", "Info"..id);
end

function Armory:GetNumQuestLogChoices()
    return GetQuestLineValue(selectedQuestLine, "NumChoices");
end

function Armory:GetQuestLogChoiceInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Choices", "Info"..id);
end

function Armory:GetNumQuestLogRewardFactions()
    return GetQuestLineValue(selectedQuestLine, "NumFactions") or 0;
end

function Armory:GetQuestLogRewardFactionInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Factions", "Info"..id);
end

function Armory:GetQuestLogItemLink(itemType, id)
    if ( itemType == "reward" ) then
        return GetQuestLineValue(selectedQuestLine, "Rewards", "Link"..id);
    elseif ( itemType == "choice" ) then
        return GetQuestLineValue(selectedQuestLine, "Choices", "Link"..id);
    end
end

function Armory:SetQuestLogFilter(text)
    local refresh = (questLogFilter ~= text);
    questLogFilter = text;
    return refresh;
end

function Armory:GetQuestLogFilter()
    return questLogFilter;
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindQuest(...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = {};

    local numEntries = dbEntry:GetNumValues(container);
    if ( numEntries ) then
        local name, level, isHeader, link, text, id;
        for index = 1, numEntries do
            name, level, _, _, isHeader = dbEntry:GetValue(container, index, "Info");
            if ( not isHeader ) then
                id = dbEntry:GetValue(container, index, "Data");
                link = dbEntry:GetValue(container, id, "Link");
                if ( self:GetConfigExtendedSearch() ) then
                    text = self:GetTextFromLink(link);
                else
                    text = name;
                end
                if ( self:FindTextParts(text, ...) ) then
                    name = self:HexColor(ArmoryGetDifficultyColor(level))..name..FONT_COLOR_CODE_CLOSE;
                    table.insert(list, {label=QUEST_LOG, name=name, link=link});
                end
            end
        end
    end

    return list;
end

function Armory:FindQuestItem(itemList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = itemList or {};
    
    local numEntries = dbEntry:GetNumValues(container);
    if ( numEntries ) then
        local questLogTitleText, level, isHeader;
        local text, label, name, link, id;

        for index = 1, numEntries do
            questLogTitleText, level, _, _, isHeader = dbEntry:GetValue(container, index, "Info");
            if ( not isHeader ) then
                id = dbEntry:GetValue(container, index, "Data");
                label = ARMORY_CMD_FIND_QUEST_REWARD.." "..self:HexColor(ArmoryGetDifficultyColor(level))..questLogTitleText..FONT_COLOR_CODE_CLOSE;
                for i = 1, dbEntry:GetValue(container, id, "NumChoices") do
                    link = dbEntry:GetValue(container, id, "Choices", "Link"..i);
                    name = dbEntry:GetValue(container, id, "Choices", "Info"..i);
                    if ( self:GetConfigExtendedSearch() ) then
                        text = self:GetTextFromLink(link);
                    else
                        text = name;
                    end
                    if ( self:FindTextParts(text, ...) ) then
                        table.insert(list, {label=label, name=name, link=link});
                    end
                end
                for i = 1, dbEntry:GetValue(container, id, "NumRewards") do
                    link = dbEntry:GetValue(container, id, "Rewards", "Link"..i);
                    name = dbEntry:GetValue(container, id, "Rewards", "Info"..i);
                    if ( self:GetConfigExtendedSearch() ) then
                        text = self:GetTextFromLink(link);
                    else
                        text = name;
                    end
                    if ( self:FindTextParts(text, ...) ) then
                        table.insert(list, {label=label, name=name, link=link});
                    end
                end
            end
        end
    end
    
    return list;
end

function Armory:FindQuestSpell(spellList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = spellList or {};

    local numEntries = dbEntry:GetNumValues(container);
    if ( numEntries ) then
        local questLogTitleText, level, isHeader;
        local text, label, name, link, id;

        for index = 1, numEntries do
            questLogTitleText, level, _, _, isHeader = dbEntry:GetValue(container, index, "Info");
            if ( not isHeader ) then
                id = dbEntry:GetValue(container, index, "Data");
                if ( dbEntry:GetValue(container, id, "RewardSpell") ) then
                    _, name = dbEntry:GetValue(container, id, "RewardSpell");
                    link = dbEntry:GetValue(container, id, "SpellLink");
                    if ( self:GetConfigExtendedSearch() ) then
                        text = self:GetTextFromLink(link);
                    else
                        text = name;
                    end
                    if ( self:FindTextParts(text, ...) ) then
                        label = ARMORY_CMD_FIND_QUEST_REWARD.." "..self:HexColor(ArmoryGetDifficultyColor(level))..questLogTitleText..FONT_COLOR_CODE_CLOSE;
                        table.insert(list, {label=label, name=name, link=link});
                    end
                end
            end
        end
    end
    
    return list;
end