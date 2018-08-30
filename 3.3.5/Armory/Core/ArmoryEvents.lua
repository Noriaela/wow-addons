--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 269 2010-05-15T17:11:43Z
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

ARMORY_MAX_EVENT_DAYS = 31;

local Armory = Armory;
local container = "Events";

----------------------------------------------------------
-- Events Internals
----------------------------------------------------------

local function CreateKey(timestamp, index)
    return Armory:MinutesTime(timestamp)..";"..index;
end

local function GetTimeFromKey(key)
    return tonumber( (strsplit(";", key)) );
end

local function GetSharedCooldownTitle(current, title)
    local common = title:match("(.-):") or title:match("%w+");
    if ( common ) then
        common = strtrim(common);
        if ( #current >= #common and current:sub(1, #common) == common ) then
            return common;
        end
    end
end

local function GetCooldownEntry(dbEntry, cooldown)
    local index = 0;
    local key, title, calendarType;
    while ( true ) do
        index = index + 1;
        key = CreateKey(cooldown.time, index);
        if ( not dbEntry:Contains(container, key) ) then
            return key, cooldown.skill;
        end
        title, calendarType = dbEntry:GetValue(container, key);
        if ( calendarType == "COOLDOWN" ) then
            title = GetSharedCooldownTitle(title, cooldown.skill);
            if ( title ) then
                return key, title;
            end
        end
    end
end


local eventLines = {};
local dirty = true;
local owner = "";

local function GetEventLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local db = dbEntry:SelectContainer(container);
    local now = time();
    local eventTime, calendarType;

    table.wipe(eventLines);

    for key in pairs(db) do
        eventTime = GetTimeFromKey(key);
        _, calendarType = dbEntry:GetValue(container, key);
        if ( eventTime >= now and (calendarType ~= "COOLDOWN" or Armory:GetConfigEnableCooldownEvents()) ) then
            table.insert(eventLines, key);
        end
    end
    
    table.sort(eventLines);

    dirty = false;
    owner = Armory:SelectedCharacter();

    return eventLines;
end

----------------------------------------------------------
-- Events Storage
----------------------------------------------------------

function Armory:ClearEvents()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

function Armory:UpdateEvents()
    local dbEntry = self.playerDbBaseEntry;

    if ( not self:HasSocial() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
   
    local _, presentMonth, presentDay, presentYear = CalendarGetDate();
    local month, year = CalendarGetMonth();
    local monthOffset = 0;
    if (month ~= presentMonth or year ~= presentYear) then
        month, year = CalendarGetMonth(-1);
        if (month == presentMonth and year == presentYear) then
            monthOffset = -1;
        else
            self:PrintDebug("UPDATE", container, "not possible (wrong offset)");
            return;
        end
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);
        
        self:PrintDebug("UPDATE", container);
        
        dbEntry:ClearContainer(container);

        local today = self:MakeDate(presentDay, presentMonth, presentYear);
        local eventTime, eventDate, numEvents;
        local key;

        for i = 1, ARMORY_MAX_EVENT_DAYS do
            eventTime = today + (i - 1) * 24*60*60;
            eventDate = date("*t", eventTime);
            if ( eventDate.month ~= month ) then
                month = eventDate.month;
                monthOffset = monthOffset + 1;
            end

            numEvents = CalendarGetNumDayEvents(monthOffset, eventDate.day);
            for eventIndex = 1, numEvents do
                local title, hour, minute, calendarType, sequenceType, eventType, texture,
                    modStatus, inviteStatus, invitedBy, difficulty, inviteType,
                    sequenceIndex, numSequenceDays, difficultyName = CalendarGetDayEvent(monthOffset, eventDate.day, eventIndex);

                if ( calendarType ~= "HOLIDAY" and calendarType ~= "SYSTEM" ) then
                    key = CreateKey(self:GetServerTimeAsLocalTime(eventTime + hour*60*60 + minute*60), eventIndex);
                    dbEntry:SetValue(2, container, key, title, calendarType, eventType, texture, modStatus, inviteStatus, invitedBy, difficulty, inviteType, difficultyName);
                end
            end
        end

        if ( self:GetConfigEnableCooldownEvents() ) then
            local cooldowns = self:GetTradeSkillCooldowns();
            local title;
            for _, cooldown in ipairs(cooldowns) do
                key, title = GetCooldownEntry(dbEntry, cooldown);
                dbEntry:SetValue(2, container, key, title, "COOLDOWN");
            end
        end
         
        dirty = dirty or self:IsPlayerSelected();

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Events Interface
----------------------------------------------------------

function Armory:GetNumEvents()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetEventLines();
    end
    return #eventLines;
end

function Armory:GetEventInfo(index)
    local dbEntry = self.selectedDbBaseEntry;
    local numEvents = self:GetNumEvents();
    if ( index > 0 and index <= numEvents ) then
        return GetTimeFromKey(eventLines[index]), dbEntry:GetValue(container, eventLines[index]);
    end
    return 0;
end

function Armory:SetEventsDirty()
    dirty = true;
end

local reminders = {};
local altEvents = {};
local populated;
function Armory:GetEventReminders()
    table.wipe(reminders);
    if ( self:HasSocial() ) then
        local now = time();
        local watchPeriod = now + 24*60*60;
        local dbEntry, db, eventTime, title, calendarType, inviteStatus, isCooldown;
        
        if ( not populated ) then
            local currentProfile = self:CurrentProfile();
            for _, profile in ipairs(self:Profiles()) do
                self:SelectProfile(profile);
                dbEntry = self.selectedDbBaseEntry;
                db = dbEntry:SelectContainer(container);
                if ( not self:IsPlayerSelected() ) then
                    for key in pairs(db) do
                        eventTime = GetTimeFromKey(key);
                        title, calendarType, _, _, _, inviteStatus = dbEntry:GetValue(container, key);
                        isCooldown = calendarType == "COOLDOWN";
                        if ( eventTime > now and eventTime < watchPeriod and (isCooldown or inviteStatus == CALENDAR_INVITESTATUS_CONFIRMED) ) then
                            table.insert(altEvents, {profile=profile, time=eventTime, title=title, cooldown=isCooldown});
                        end
                    end
                end
            end            
            self:SelectProfile(currentProfile);
            
            populated = true;
        end
        
        dbEntry = self.playerDbBaseEntry;
        db = dbEntry:SelectContainer(container);
        for key in pairs(db) do
            eventTime = GetTimeFromKey(key);
            title, calendarType, _, _, _, inviteStatus = dbEntry:GetValue(container, key);
            isCooldown = calendarType == "COOLDOWN";
            if ( eventTime > now and eventTime < watchPeriod and (isCooldown or inviteStatus == CALENDAR_INVITESTATUS_CONFIRMED) ) then
                table.insert(reminders, {time=eventTime, title=title, cooldown=isCooldown});
            end
        end
        
        for _, event in pairs(altEvents) do
            if ( event.time > now ) then
                table.insert(reminders, event);
            end
        end
    end
    return reminders;
end

function Armory:CheckAvailableCooldowns()
    if ( self:HasSocial() and self:GetConfigEnableCooldownEvents() ) then
        local currentProfile = self:CurrentProfile();
        local now = time();
        local dbEntry, db, eventTime, title, calendarType;
        for _, profile in ipairs(self:Profiles()) do
            self:SelectProfile(profile);
            dbEntry = self.selectedDbBaseEntry;
            db = dbEntry:SelectContainer(container);
            for key in pairs(db) do
                eventTime = GetTimeFromKey(key);
                title, calendarType = dbEntry:GetValue(container, key);
                if ( eventTime < now and calendarType == "COOLDOWN" ) then
                    self:PrintInfo(format(ARMORY_COOLDOWN_AVAILABLE, title, profile.character, profile.realm));
                    dbEntry:SetValue(2, container, key, nil);
                end
            end
        end            
        self:SelectProfile(currentProfile);
    end
end
