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
local container = "Currency";

----------------------------------------------------------
-- Currency Internals
----------------------------------------------------------

local currencyLines = {};
local dirty = true;
local owner = "";

local function GetCurrencyLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local count = dbEntry:GetNumValues(container);
    local expanded = true;

    table.wipe(currencyLines);
    
    for i = 1, count do
        local name, isHeader = dbEntry:GetValue(container, i);
        if ( isHeader ) then
            table.insert(currencyLines, i);
            expanded = not Armory:GetHeaderLineState(container, name);
        elseif ( expanded ) then
            table.insert(currencyLines, i);
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();

    return currencyLines;
end

local function GetCurrencyLineValue(index, key, subkey)
    local numLines = Armory:GetCurrencyListSize();
    if ( index > 0 and index <= numLines ) then
        local dbEntry = Armory.selectedDbBaseEntry;
        if ( subkey ) then
            return dbEntry:GetValue(container, currencyLines[index], key, subkey);
        elseif ( key ) then
            return dbEntry:GetValue(container, currencyLines[index], key);
        else
            return dbEntry:GetValue(container, currencyLines[index]);
        end
    end
end

local function UpdateCurrencyHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;
    if ( index == 0 ) then
        for i = 1, dbEntry:GetNumValues(container) do
            local name, isHeader = dbEntry:GetValue(container, i);
            if ( isHeader ) then
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    else
        local numLines = Armory:GetCurrencyListSize();
        if ( index > 0 and index <= numLines ) then
            local name = dbEntry:GetValue(container, currencyLines[index]);
            Armory:SetHeaderLineState(container, name, isCollapsed);
        end
    end

    dirty = true;
end

----------------------------------------------------------
-- Currency Storage
----------------------------------------------------------

function Armory:ClearCurrency()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

function Armory:UpdateCurrency()
    local dbEntry = self.playerDbBaseEntry;
    
    if ( not self:CurrencyEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        -- store the complete (expanded) list
        local funcNumLines = _G.GetCurrencyListSize;
        local funcGetLineInfo = _G.GetCurrencyListInfo;
        local funcGetLineState = function(index)
            local _, isHeader, isExpanded = _G.GetCurrencyListInfo(index);
            return isHeader, isExpanded;
        end;
        local funcExpand = function(index) _G.ExpandCurrencyList(index, 1); end;
        local funcCollapse = function(index) _G.ExpandCurrencyList(index, 0); end;

        dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse);

        dirty = dirty or self:IsPlayerSelected();
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Currency Interface
----------------------------------------------------------

function Armory:HasCurrency()
    return self:CurrencyEnabled() and self:GetCurrencyListSize() > 0;
end

function Armory:GetCurrencyListSize()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetCurrencyLines();
    end
    return #currencyLines;
end

function Armory:GetCurrencyListInfo(index)
    local numLines = self:GetCurrencyListSize();
    if ( index > 0 and index <= numLines ) then
        local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = self.selectedDbBaseEntry:GetValue(container, currencyLines[index]);
        isExpanded = not Armory:GetHeaderLineState(container, name);
        return name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID; 
    end
end

function Armory:ExpandCurrencyList(index, expand)
    UpdateCurrencyHeaderState(index, expand ~= 1);
end

function Armory:SetCurrencyToken(index)
    local itemId, link;
    _, _, _, _, _, _, _, _, itemId = self:GetCurrencyListInfo(index);
    if ( itemId ) then
        _, link = _G.GetItemInfo(itemId);
    end
    if ( link ) then
        GameTooltip:SetHyperlink(link);
        GameTooltip:Show();
    end
end

function Armory:CountCurrency(link)
    local dbEntry = self.selectedDbBaseEntry;
    if ( link ) then
        local name = link;
        if ( link:find("|H") ) then
            name = self:GetNameFromLink(link);
        end
        for i = 1, dbEntry:GetNumValues(container) do
            local currencyName, isHeader, _, _, _, count, extraCurrencyType = dbEntry:GetValue(container, i);
            if ( currencyName and not isHeader and extraCurrencyType ~= 1 and extraCurrencyType ~= 2 and strtrim(currencyName) == strtrim(name) ) then
                return count;
            end
        end
    end
    return 0;
end
