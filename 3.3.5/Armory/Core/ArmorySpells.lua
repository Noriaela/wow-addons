--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 305 2010-07-07T14:22:51Z
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
local container = "Spells";

----------------------------------------------------------
-- Spells Internals
----------------------------------------------------------

local function SetSpellValue(index, key, ...)
    local dbEntry = Armory.playerDbBaseEntry;

    if ( index == BOOKTYPE_PET ) then
        if ( Armory:IsPersistentPet() ) then
            Armory:SelectPet(dbEntry, _G.UnitName("pet")):SetValue(2, container, key, ...);
        end
    else
        dbEntry:SetValue(2, container, key, ...);
    end
end

local function GetSpellValue(index, key)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( index == BOOKTYPE_PET ) then
        if ( Armory:PetExists(Armory:GetCurrentPet()) and Armory:SelectPet(dbEntry, Armory:GetCurrentPet()):Contains(container, key) ) then
            return Armory:SelectPet(dbEntry, Armory:GetCurrentPet()):GetValue(container, key);
        end
    elseif ( dbEntry:Contains(container, key) ) then
        return dbEntry:GetValue(container, key);
    end
end

----------------------------------------------------------
-- Spells Storage
----------------------------------------------------------

function Armory:ClearSpells()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
end

function Armory:SetSpells()
    local dbEntry = self.playerDbBaseEntry;
    local offset, numSpells;

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        if ( not self:HasSpellBook() ) then
            dbEntry:SetValue(container, nil);
        else
            dbEntry:SelectContainer(container);

            local oldTabs = dbEntry:GetValue(container, "NumTabs") or 0;
             _, _, offset, numSpells = dbEntry:GetValue(container, "Info"..oldTabs);
            local oldNum = (offset or 0) + (numSpells or 0);

            local newTabs = _G.GetNumSpellTabs();
            _, _, offset, numSpells = _G.GetSpellTabInfo(newTabs);
            local newNum = (offset or 0) + (numSpells or 0);

            SetSpellValue(BOOKTYPE_SPELL, "NumTabs", newTabs);
            for i = 1, max(oldTabs, newTabs) do
                if ( i > newTabs ) then
                    SetSpellValue(BOOKTYPE_SPELL, "Info"..i, nil);
                else
                    SetSpellValue(BOOKTYPE_SPELL, "Info"..i, _G.GetSpellTabInfo(i));
                end
            end
            for i = 1, max(oldNum, newNum) do
                if ( i > newNum ) then
                    SetSpellValue(BOOKTYPE_SPELL, "DisplayId"..i, nil);
                    SetSpellValue(BOOKTYPE_SPELL, "AutoCast"..i, nil);
                    SetSpellValue(BOOKTYPE_SPELL, "Name"..i, nil);
                    SetSpellValue(BOOKTYPE_SPELL, "Texture"..i, nil);
                    SetSpellValue(BOOKTYPE_SPELL, "Link"..i, nil);
                else
                    SetSpellValue(BOOKTYPE_SPELL, "DisplayId"..i, _G.GetKnownSlotFromHighestRankSlot(i));
                    SetSpellValue(BOOKTYPE_SPELL, "AutoCast"..i, _G.GetSpellAutocast(i, BOOKTYPE_SPELL));
                    SetSpellValue(BOOKTYPE_SPELL, "Name"..i, _G.GetSpellName(i, BOOKTYPE_SPELL));
                    SetSpellValue(BOOKTYPE_SPELL, "Texture"..i, _G.GetSpellTexture(i, BOOKTYPE_SPELL));
                    SetSpellValue(BOOKTYPE_SPELL, "Link"..i, _G.GetSpellLink(i, BOOKTYPE_SPELL));
                end
            end
        end
        
        if ( self:IsPersistentPet() ) then
            dbEntry = self:SelectPet(dbEntry, _G.UnitName("pet"));
            if ( not self:HasSpellBook() ) then
                dbEntry:SetValue(container, nil);
            else
                dbEntry:SelectContainer(container);
                oldNum = dbEntry:GetValue("HasSpells") or 0;
                newNum = _G.HasPetSpells() or 0;
                for i = 1, max(oldNum, newNum) do
                    if ( i > newNum ) then
                        SetSpellValue(BOOKTYPE_PET, "AutoCast"..i, nil);
                        SetSpellValue(BOOKTYPE_PET, "Name"..i, nil);
                        SetSpellValue(BOOKTYPE_PET, "Texture"..i, nil);
                        SetSpellValue(BOOKTYPE_PET, "Link"..i, nil);
                    else
                        SetSpellValue(BOOKTYPE_PET, "AutoCast"..i, _G.GetSpellAutocast(i, BOOKTYPE_PET));
                        SetSpellValue(BOOKTYPE_PET, "Name"..i, _G.GetSpellName(i, BOOKTYPE_PET));
                        SetSpellValue(BOOKTYPE_PET, "Texture"..i, _G.GetSpellTexture(i, BOOKTYPE_PET));
                        SetSpellValue(BOOKTYPE_PET, "Link"..i, _G.GetSpellLink(i, BOOKTYPE_PET));
                    end
                end
            end
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Spells Interface
----------------------------------------------------------

function Armory:GetKnownSlotFromHighestRankSlot(id)
    return GetSpellValue(BOOKTYPE_SPELL, "DisplayId"..id) or id;
end

function Armory:GetNumSpellTabs()
    return GetSpellValue(BOOKTYPE_SPELL, "NumTabs") or 0;
end

function Armory:GetSpellAutocast(id, bookType)
    if ( id and bookType ) then
        return GetSpellValue(bookType, "Autocast"..id);
    end
end

function Armory:GetSpellName(id, bookType)
    if ( id and bookType ) then
        return GetSpellValue(bookType, "Name"..id);
    end
end

function Armory:GetSpellLink(id, bookType)
    if ( id and bookType ) then
        return GetSpellValue(bookType, "Link"..id);
    end
end

function Armory:GetSpellTabInfo(spellTab)
    if ( spellTab ) then
        return GetSpellValue(BOOKTYPE_SPELL, "Info"..spellTab);
    end
end

function Armory:GetSpellTexture(id, bookType)
    if ( id and bookType ) then
        return GetSpellValue(bookType, "Texture"..id);
    end
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindSpell(spellList, ...)
    local list = spellList or {};

    local numSkillLineTabs = self:GetNumSpellTabs();
    local tabName, spellName, subSpellName, offset, numSpells, link, text;
    if ( numSkillLineTabs ) then
        for i = 1, numSkillLineTabs do
            tabName, _, offset, numSpells = self:GetSpellTabInfo(i);
            for j = 1, numSpells do
                spellName, subSpellName = self:GetSpellName(j + offset, BOOKTYPE_SPELL);
                link = self:GetSpellLink(j + offset, BOOKTYPE_SPELL);
                if ( self:GetConfigExtendedSearch() ) then
                    text = self:GetTextFromLink(link);
                else
                    text = spellName;
                end
                if ( self:FindTextParts(text, ...) ) then
                    if ( subSpellName and subSpellName ~= "" ) then
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, link=link, extra=subSpellName});
                    else
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, link=link});
                    end
                end
            end
        end
    end

    local pets = self:GetPets();
    local currentPet = self.selectedPet;
    for i = 1, #pets do
        self.selectedPet = pets[i];
        local numPetSpells = self:HasPetSpells() or 0;
        for id = 1, numPetSpells do
            spellName, subSpellName = self:GetSpellName(id, BOOKTYPE_PET);
            link = self:GetSpellLink(id, BOOKTYPE_PET);
            if ( self:GetConfigExtendedSearch() ) then
                text = self:GetTextFromLink(link);
            else
                text = spellName;
            end
            if ( self:FindTextParts(text, ...) ) then
                if ( subSpellName and subSpellName ~= "" ) then
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, link=link, extra=subSpellName});
                else
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, link=link});
                end
            end
        end
    end
    self.selectedPet = currentPet;
    
    return list;
end