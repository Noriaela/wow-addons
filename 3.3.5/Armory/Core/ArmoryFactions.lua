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
local container = "Factions";

----------------------------------------------------------
-- Factions Internals
----------------------------------------------------------

local factionLines = {};
local dirty = true;
local owner = "";

local function GetFactionLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local count = dbEntry:GetNumValues(container);
    local collapsed = false;
    local childCollapsed = false;

    table.wipe(factionLines);

    for i = 1, count do
        local name, _, _, _, _, _, _, _, isHeader, _, _, _, isChild = dbEntry:GetValue(container, i);
        local isCollapsed = Armory:GetHeaderLineState(container, name);
        if ( isHeader and not isChild ) then
            table.insert(factionLines, i);
            collapsed = isCollapsed;
            childCollapsed = false;
        elseif ( isHeader and isChild ) then
            if ( not collapsed ) then
                table.insert(factionLines, i);
            end
            childCollapsed = collapsed or isCollapsed;
        elseif ( not (collapsed or childCollapsed) ) then
            table.insert(factionLines, i);
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();
    
    return factionLines;
end

local function UpdateFactionHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( index == 0 ) then
        for i = 1, dbEntry:GetNumValues(container) do
            local name, _, _, _, _, _, _, _, isHeader = dbEntry:GetValue(container, i);
            if ( isHeader ) then
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    else
        local numLines = Armory:GetNumFactions();
        if ( index > 0 and index <= numLines ) then
            local name = dbEntry:GetValue(container, factionLines[index]);
            Armory:SetHeaderLineState(container, name, isCollapsed);
        end
    end
    
    dirty = true;
end

----------------------------------------------------------
-- Factions Storage
----------------------------------------------------------

function Armory:ClearFactions()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

function Armory:UpdateFactions()
    local dbEntry = self.playerDbBaseEntry;

    if ( not self:ReputationEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        -- store the complete (expanded) list
        local funcNumLines = _G.GetNumFactions;
        local funcGetLineInfo = _G.GetFactionInfo;
        local funcGetLineState = function(index)
            local _, _, _, _, _, _, _, _, isHeader, isCollapsed = _G.GetFactionInfo(index);
            return isHeader, not isCollapsed;
        end;
        local funcExpand = _G.ExpandFactionHeader;
        local funcCollapse = _G.CollapseFactionHeader;

        dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse);

        dirty = dirty or self:IsPlayerSelected();
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
 end

----------------------------------------------------------
-- Factions Interface
----------------------------------------------------------

function Armory:HasReputation()
    return self:ReputationEnabled() and self:GetNumFactions() > 0;
end

function Armory:GetNumFactions()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetFactionLines();
    end
    return #factionLines;
end

function Armory:GetFactionInfo(index)
    local numLines = self:GetNumFactions();
    if ( index > 0 and index <= numLines ) then
        local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = self.selectedDbBaseEntry:GetValue(container, factionLines[index]);
        isCollapsed = self:GetHeaderLineState(container, name);
        return name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild;
    end
end

function Armory:ExpandFactionHeader(index)
    UpdateFactionHeaderState(index, false);
end

function Armory:CollapseFactionHeader(index)
    UpdateFactionHeaderState(index, true);
end
