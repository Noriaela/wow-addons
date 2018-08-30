--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 233 2010-01-29T08:43:10Z
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
local container = "GearSets";

----------------------------------------------------------
-- Gear Set Internals
----------------------------------------------------------

local function GetEquipmentSetIndex(name)
    for i = 1, Armory:GetNumEquipmentSets() do
        if ( Armory:GetEquipmentSetInfo(i) == name ) then
            return i;
        end
    end
    return -1;
end

----------------------------------------------------------
-- Gear Set Storage
----------------------------------------------------------

function Armory:UpdateGearSets()
    local dbEntry = self.playerDbBaseEntry;

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        local oldNum = dbEntry:GetValue(container, "NumSets") or 0;
        local newNum = _G.GetNumEquipmentSets();
        
        if ( newNum == 0 ) then
            dbEntry:SetValue(container, nil);
        else
            dbEntry:SelectContainer(container);
            dbEntry:SetValue(2, container, "NumSets", newNum);
            local name;
            for i = 1, max(oldNum, newNum) do
                if ( i > newNum ) then
                    dbEntry:SetValue(2, container, "Info"..i, nil);
                    dbEntry:SetValue(2, container, "ItemIDs"..i, nil);
                else
                    name = _G.GetEquipmentSetInfo(i);
                    dbEntry:SetValue(2, container, "Info"..i, _G.GetEquipmentSetInfo(i));
                    dbEntry:SetValue(2, container, "ItemIDs"..i, unpack(_G.GetEquipmentSetItemIDs(name)));
                    dbEntry:SetValue(2, container, "Locations"..i, unpack(_G.GetEquipmentSetLocations(name)));
                end
            end
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Gear Set Interface
----------------------------------------------------------

function Armory:GetNumEquipmentSets()
    return self.selectedDbBaseEntry:GetValue(container, "NumSets") or 0;
end

function Armory:GetEquipmentSetInfo(id)
    if ( type(id) == "string" ) then
        id = GetEquipmentSetIndex(id);
    end
    return self.selectedDbBaseEntry:GetValue(container, "Info"..id);
end

function Armory:GetEquipmentSetItemIDs(id, t)
    local result = t or {};
    if ( type(id) == "string" ) then
        id = GetEquipmentSetIndex(id);
    end
    self:FillTable(result, self.selectedDbBaseEntry:GetValue(container, "ItemIDs"..id));
    return result;
end

function Armory:GetEquipmentSetLocations(id, t)
    local result = t or {};
    if ( type(id) == "string" ) then
        id = GetEquipmentSetIndex(id);
    end
    self:FillTable(result, self.selectedDbBaseEntry:GetValue(container, "Locations"..id));
    return result;
end

local gearSets = {};
local gearSetItems = {};
function Armory:AddEquipmentSet(tooltip)
    if ( not self:GetConfigShowGearSets() ) then
        return;
    end

    local numSets = self:GetNumEquipmentSets();
    if ( numSets > 0 ) then
        local _, link = tooltip:GetItem();
        if ( link and IsEquippableItem(link) ) then
            local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link);
            if ( equipLoc ~= "" ) then
                local itemId = tonumber(self:GetItemId(link));
                local name;
                table.wipe(gearSets);
                for id = 1, numSets do
                    name = self:GetEquipmentSetInfo(id);
                    self:GetEquipmentSetItemIDs(id, gearSetItems);
                    for i = 1, 19 do
                        if ( gearSetItems[i] == itemId ) then
                            table.insert(gearSets, name);
                            break;
                        end  
                    end
                end
                if ( #gearSets > 0 ) then
                    tooltip:AddLine(format(EQUIPMENT_SETS, table.concat(gearSets, ", ")), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
                    tooltip:Show();
                end
            end
        end
    end
end