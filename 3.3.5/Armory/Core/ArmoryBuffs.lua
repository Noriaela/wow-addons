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
local container = "Buffs";

----------------------------------------------------------
-- Buffs Internals
----------------------------------------------------------

local function SetBuff(dbEntry, unit, index, filter)
    local tooltipLines;
    
    if ( _G.UnitAura(unit, index, filter) ) then
        Armory:PrepareTooltip();
        Armory.tooltip:SetUnitAura(unit, index, filter);
        tooltipLines = Armory:Tooltip2Table(Armory.tooltip);
        Armory:ReleaseTooltip();
    
        if ( #tooltipLines > 2 and tooltipLines[#tooltipLines]:match("^%d") ) then
            table.remove(tooltipLines);
        end

        dbEntry:SetValue(3, container, filter, "Aura"..index, _G.UnitAura(unit, index, filter));
        dbEntry:SetValue(3, container, filter, "Tooltip"..index, unpack(tooltipLines));
    else
        dbEntry:SetValue(3, container, filter, "Aura"..index, nil);
        dbEntry:SetValue(3, container, filter, "Tooltip"..index, nil);
    end
end

local function GetBuffValue(unit, filter, key)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( strlower(unit) == "pet" ) then
        if ( not Armory:PetExists(Armory:GetCurrentPet()) ) then
            return;
        end
        dbEntry = Armory:SelectPet(dbEntry, Armory:GetCurrentPet());
    end

    return dbEntry:GetValue(container, filter, key);
end

----------------------------------------------------------
-- Buffs Storage
----------------------------------------------------------

function Armory:ClearBuffs(pet)
    local dbEntry = self.selectedDbBaseEntry;
    if ( pet ) then
        dbEntry = self:SelectPet(dbEntry, pet);
    end
    dbEntry:SetValue(container, nil);
end

function Armory:SetBuffs(unit)
    local dbEntry = self.playerDbBaseEntry;

    if ( strlower(unit) == "pet" ) then
        if ( not self:IsPersistentPet() ) then
            return;
        end
        dbEntry = self:SelectPet(dbEntry, _G.UnitName("pet"));
    end

    if ( not self:BuffsEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);
        
        self:PrintDebug("UPDATE", container);
        
        dbEntry:SelectContainer(container);

        -- Handle Buffs
        for i = 1, ARMORY_BUFF_MAX_DISPLAY do
            SetBuff(dbEntry, unit, i, "HELPFUL");
        end

        -- Handle debuffs
        for i = 1, ARMORY_DEBUFF_MAX_DISPLAY do
            SetBuff(dbEntry, unit, i, "HARMFUL");
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Buffs Interface
----------------------------------------------------------

function Armory:GetBuff(unit, index, filter)
    if ( index ) then
        return GetBuffValue(unit, filter, "Aura"..index);
    end
end

local buffTooltip = {};
function Armory:GetBuffTooltip(unit, index, filter)
    if ( index ) then
        self:FillTable(buffTooltip, GetBuffValue(unit, filter, "Tooltip"..index));
        return buffTooltip;
    end
end
