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

----------------------------------------------------------
-- Arean Teams Internals
----------------------------------------------------------

local function GetArenaTeamValue(id, key)
    return Armory.selectedDbBaseEntry:GetValue("ArenaTeam"..id, key);
end

----------------------------------------------------------
-- Arena Teams Storage
----------------------------------------------------------

function Armory:ClearArenaTeams()
    local dbEntry = self.selectedDbBaseEntry;
    local container;
    for id = 1, MAX_ARENA_TEAMS do
        container = "ArenaTeam"..id; 
        dbEntry:SetValue(container, nil);
    end
end

function Armory:UpdateArenaTeams()
    local dbEntry = self.playerDbBaseEntry;
    local container;

    for id = 1, MAX_ARENA_TEAMS do
        container = "ArenaTeam"..id; 

        if ( not self:PVPEnabled() ) then
            dbEntry:SetValue(container, nil);
        else
            dbEntry:SetValue(2, container, "Info", _G.GetArenaTeam(id));

            local oldNum = dbEntry:GetValue(container, "NumTeamMembers") or 0;
            local newNum = 0;
            
            if ( _G.GetArenaTeam(id) ) then
                _G.ArenaTeamRoster(id);
                newNum = _G.GetNumArenaTeamMembers(id, 1);
                for i = 1, newNum do
                    dbEntry:SetValue(2, container, "Info"..i, _G.GetArenaTeamRosterInfo(id, i));
                end
            end
            if ( newNum > 0 ) then
                dbEntry:SetValue(2, container, "NumTeamMembers", newNum);
            else
                dbEntry:SetValue(2, container, "NumTeamMembers", nil);
            end
            for i = newNum + 1, oldNum do
                dbEntry:SetValue(2, container, "Info"..i, nil);
            end
        end
    end
end

----------------------------------------------------------
-- Arena Teams Interface
----------------------------------------------------------

function Armory:GetArenaTeam(id)
    return GetArenaTeamValue(id, "Info");
end

function Armory:GetNumArenaTeamMembers(id, showOffline)
    return GetArenaTeamValue(id, "NumTeamMembers") or 0;
end

function Armory:GetArenaTeamRosterInfo(id, index)
    if ( index ) then
        return GetArenaTeamValue(id, "Info"..index);
    end
end
