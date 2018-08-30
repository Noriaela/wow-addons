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
local container = "Glyphs";

----------------------------------------------------------
-- Glyphs Internals
----------------------------------------------------------

local function GetGlyphValue(key, talentGroup)
    return Armory.selectedDbBaseEntry:GetValue(container, talentGroup, key);
end

----------------------------------------------------------
-- Glyphs Storage
----------------------------------------------------------

function Armory:ClearGlyphs()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
end

function Armory:UpdateGlyphs()
    local dbEntry = self.playerDbBaseEntry;
    local activeTalentGroup = _G.GetActiveTalentGroup();

    if ( not self:HasSpellBook() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        for talentGroup = 1, activeTalentGroup do
            if ( talentGroup == activeTalentGroup or not dbEntry:Contains(container, talentGroup) ) then
                self:UpdateGlyphGroup(dbEntry, talentGroup);
            end
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

function Armory:UpdateGlyphGroup(dbEntry, talentGroup)
    dbEntry:SelectContainer(container, talentGroup);
    for i = 1, ARMORY_NUM_GLYPH_SLOTS do
        if ( _G.GetGlyphSocketInfo(i, talentGroup) ) then
            dbEntry:SetValue(3, container, talentGroup, "Info"..i, _G.GetGlyphSocketInfo(i, talentGroup));
            dbEntry:SetValue(3, container, talentGroup, "Link"..i, _G.GetGlyphLink(i, talentGroup));
        else
            dbEntry:SetValue(3, container, talentGroup, "Info"..i, nil);
            dbEntry:SetValue(3, container, talentGroup, "Link"..i, nil);
        end
    end
end

----------------------------------------------------------
-- Glyphs Interface
----------------------------------------------------------

function Armory:GetGlyphSocketInfo(id, talentGroup)
    return GetGlyphValue("Info"..id, talentGroup);
end

function Armory:GetGlyphLink(id, talentGroup)
    return GetGlyphValue("Link"..id, talentGroup);
end
