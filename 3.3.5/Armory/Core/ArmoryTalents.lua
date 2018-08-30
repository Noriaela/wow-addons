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
local container = "Talents";

----------------------------------------------------------
-- Talents Internals
----------------------------------------------------------

local function SetTalentGroupValue(dbEntry, talentGroup, index, key, ...)
    Armory:SelectTalent(dbEntry, index, talentGroup):SetValue(key, ...);
end

local function GetTalentGroupValue(dbEntry, talentGroup, index, key)
    if ( dbEntry:Contains(container, talentGroup, index, key) ) then
        return Armory:SelectTalent(dbEntry, index, talentGroup):GetValue(key);
    end
end

local function GetTalentValue(pet, index, key, talentGroup)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( pet ) then
        if ( not Armory:PetExists(Armory:GetCurrentPet()) ) then
            return;
        end
        dbEntry = Armory:SelectPet(dbEntry, Armory:GetCurrentPet());
    end
    
    if ( talentGroup ) then
        return GetTalentGroupValue(dbEntry, talentGroup, index, key);
    elseif ( dbEntry:Contains(container, index, key) ) then
        return Armory:SelectTalent(dbEntry, index):GetValue(key);
    end
end

----------------------------------------------------------
-- Talents Storage
----------------------------------------------------------

function Armory:ClearTalents(pet)
    local dbEntry = self.selectedDbBaseEntry;
    if ( pet ) then
        dbEntry = self:SelectPet(dbEntry, pet);
    end
    dbEntry:SetValue(container, nil);
end

function Armory:SetTalents(pet)
    local inspect = false;
    local activeTalentGroup = _G.GetActiveTalentGroup(inspect, pet);
    local dbEntry = self.playerDbBaseEntry;
    
    if ( pet ) then
        if ( not (self:PetsEnabled() and self:IsPersistentPet()) ) then
            return;
        end
        dbEntry = self:SelectPet(dbEntry, _G.UnitName("pet"));
    end
    
    if ( not self:TalentsEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    for talentGroup = 1, activeTalentGroup do
        if ( talentGroup == activeTalentGroup or not dbEntry:Contains(container, talentGroup) ) then
            for i = 1, _G.GetNumTalentTabs(inspect, pet) do
                SetTalentGroupValue(dbEntry, talentGroup, i, "Info", _G.GetTalentTabInfo(i, inspect, pet, talentGroup));
                SetTalentGroupValue(dbEntry, talentGroup, i, "NumTalents", _G.GetNumTalents(i, inspect, pet));
                for j = 1, _G.GetNumTalents(i, inspect, pet) do
                    SetTalentGroupValue(dbEntry, talentGroup, i, "Info"..j, _G.GetTalentInfo(i, j, inspect, pet, talentGroup));
                    SetTalentGroupValue(dbEntry, talentGroup, i, "Prereqs"..j, _G.GetTalentPrereqs(i, j, inspect, pet, talentGroup));
                    SetTalentGroupValue(dbEntry, talentGroup, i, "Link"..j, _G.GetTalentLink(i, j, inspect, pet, talentGroup));
                end
            end
        end
    end
end

----------------------------------------------------------
-- Talents Interface
----------------------------------------------------------

function Armory:HasTalents(pet)
    return (self:IsInspectCharacter() or self:TalentsEnabled()) and self:GetNumTalentGroups(inspect, pet) > 0;
end

function Armory:SelectTalent(baseEntry, index, talentGroup)
    local dbEntry = ArmoryDbEntry:new(baseEntry);
    if ( talentGroup ) then
        dbEntry:SetPosition(container, talentGroup, index);
    else
        dbEntry:SetPosition(container, index);
    end
    return dbEntry;
end

function Armory:GetNumTalentGroups(inspect, pet)
    local dbEntry = self.selectedDbBaseEntry;
    
    if ( pet ) then
        if ( not self:PetExists(self:GetCurrentPet()) ) then
            return 0;
        end
        dbEntry = self:SelectPet(dbEntry, self:GetCurrentPet());
    end
    
    return dbEntry:GetNumValues(container);
end

function Armory:GetNumTalentTabs(inspect, pet)
    local dbEntry = self.selectedDbBaseEntry;
    
    if ( pet ) then
        if ( not self:PetExists(self:GetCurrentPet()) ) then
            return 0;
        end
        dbEntry = self:SelectPet(dbEntry, self:GetCurrentPet());
    end
    
    return dbEntry:GetNumValues(container, 1);
end

function Armory:GetNumTalents(index, inspect, pet)
    if ( index ) then
        return GetTalentValue(pet, index, "NumTalents", 1) or 0;
    end
end

function Armory:GetTalentTabInfo(index, inspect, pet, talentGroup)
    if ( index ) then
        return GetTalentValue(pet, index, "Info", talentGroup);
    end
end

function Armory:GetTalentInfo(index, id, inspect, pet, talentGroup)
    if ( index and id ) then
        return GetTalentValue(pet, index, "Info"..id, talentGroup);
    end
end

function Armory:GetTalentLink(index, id, inspect, pet, talentGroup)
    if ( index and id ) then
        return GetTalentValue(pet, index, "Link"..id, talentGroup);
    end
end

function Armory:GetTalentPrereqs(index, id, inspect, pet, talentGroup)
    if ( index and id ) then
        return GetTalentValue(pet, index, "Prereqs"..id, talentGroup);
    end
end
