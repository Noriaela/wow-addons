--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 263 2010-04-11T16:01:14Z
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
local container = "Skills";

----------------------------------------------------------
-- Skills Internals
----------------------------------------------------------

local skillLines = {};
local dirty = true;
local owner = "";

local function GetSkillLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local count = dbEntry:GetNumValues(container);
    local expanded = true;

    table.wipe(skillLines);
    
    for i = 1, count do
        local name, isHeader = dbEntry:GetValue(container, i);
        local isExpanded = not Armory:GetHeaderLineState(container, name);
        if ( isHeader ) then
            table.insert(skillLines, i);
            expanded = isExpanded;
        elseif ( expanded ) then
            table.insert(skillLines, i);
        end
    end
    
    dirty = false;
    owner = Armory:SelectedCharacter();

    return skillLines;
end

local function UpdateSkillHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( index == 0 ) then
        for i = 1, dbEntry:GetNumValues(container) do
            local name, isHeader = dbEntry:GetValue(container, i);
            if ( isHeader ) then
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    else
        local numLines = Armory:GetNumSkillLines();
        if ( index > 0 and index <= numLines ) then
            local name = dbEntry:GetValue(container, skillLines[index]);
            Armory:SetHeaderLineState(container, name, isCollapsed);
        end
    end
    
    dirty = true;
end

----------------------------------------------------------
-- Skills Storage
----------------------------------------------------------

function Armory:ClearSkills()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

local skills = {};
function Armory:UpdateSkills()
    local dbEntry = self.playerDbBaseEntry;
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        table.wipe(skills);
    
        if ( not self:SkillsEnabled() ) then
            dbEntry:SetValue(container, nil);
            
            for i = 1, _G.GetNumSkillLines() do
                local name = _G.GetSkillLineInfo(i);
                table.insert(skills, name);
            end
        else
            self:PrintDebug("UPDATE", container);

            -- store the complete (expanded) list
            local funcNumLines = _G.GetNumSkillLines;
            local funcGetLineInfo = function(index)
                local name = _G.GetSkillLineInfo(index);
                table.insert(skills, name);
                return _G.GetSkillLineInfo(index);
            end
            local funcGetLineState = function(index)
                local _, isHeader, isExpanded = _G.GetSkillLineInfo(index);
                return isHeader, isExpanded;
            end;
            local funcExpand = _G.ExpandSkillHeader;
            local funcCollapse = _G.CollapseSkillHeader;

            dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse);
        end
        
        -- check if the stored trade skills are still valid
        local data, found;
        data = dbEntry:GetValue("Professions");
        if ( data ) then
            for name,_ in pairs(data) do
                found = false;
                for i = 1, #skills do
                    if ( name == skills[i] ) then
                        found = true;
                        break;
                    end
                end
                if ( not found and #skills > 0 ) then
                    self:PrintDebug("DELETE profession", name);
                    dbEntry:SetValue(2, "Professions", name, nil);
                end
            end
        end
        
        table.wipe(skills);
        
        dirty = dirty or self:IsPlayerSelected();

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Skills Interface
----------------------------------------------------------

function Armory:HasSkills()
    return self:SkillsEnabled() and self:GetNumSkillLines() > 0;
end

function Armory:GetNumSkillLines()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetSkillLines();
    end
    return #skillLines;
end

function Armory:GetSkillLineInfo(index)
    local numLines = self:GetNumSkillLines();
    if ( index > 0 and index <= numLines ) then
        local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = self.selectedDbBaseEntry:GetValue(container, skillLines[index]);
        isExpanded = not self:GetHeaderLineState(container, skillName);
        return skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription;
    end
end

function Armory:ExpandSkillHeader(index)
    UpdateSkillHeaderState(index, false);
end

function Armory:CollapseSkillHeader(index)
    UpdateSkillHeaderState(index, true)
end

local primarySkills = {};
function Armory:GetPrimaryTradeSkills(inspect)
    local dbEntry = self.selectedDbBaseEntry;
    local key = "Skills";
    local skillName, isHeader, skillRank, skillMaxRank;

    table.wipe(primarySkills);
    
    if ( inspect ) then
        for i = 1, 2 do
            if ( dbEntry:GetValue(key..i) ) then
                skillName, skillRank, skillMaxRank = dbEntry:GetValue(key..i);
                table.insert(primarySkills, {skillName, skillRank, skillMaxRank});
            end
        end
    else
        local inProfessions = false;
        for i = 1, dbEntry:GetNumValues(key) do
            skillName, isHeader, _, skillRank, _, _, skillMaxRank = dbEntry:GetValue(key, i);
            if ( isHeader and skillName == TRADE_SKILLS ) then
                inProfessions = true;
            elseif ( inProfessions and isHeader ) then
                break;
            elseif ( inProfessions ) then
                table.insert(primarySkills, {skillName, skillRank, skillMaxRank});
            end
        end
    end
        
    return primarySkills;
end
