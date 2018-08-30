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

local achievementFilter = "";

----------------------------------------------------------
-- Achievement Internals
----------------------------------------------------------

local counts = {};

local function GetCategoryList(categories, categoryAccessor)
    local cats = categoryAccessor();
    local parent;
    
    for _, id in ipairs(cats) do
        _, parent = _G.GetCategoryInfo(id);
        if ( parent == -1 ) then
            table.insert(categories, { id=id });
        end
    end

    for i = #cats, 1, -1 do 
        _, parent = _G.GetCategoryInfo(cats[i]);
        for j, category in ipairs(categories) do
            if ( category.id == parent ) then
                table.insert(categories, j+1, { id=cats[i], parent=category.id });
            end
        end
    end
end

local achievementCategories;
local function GetAchievementCategories()
    if ( not achievementCategories ) then
        achievementCategories = {};
        GetCategoryList(achievementCategories, _G.GetCategoryList);
    end
end

local statisticCategories;
local function GetStatisticCategories()
    if ( not statisticCategories ) then
        statisticCategories = {};
        GetCategoryList(statisticCategories, _G.GetStatisticsCategoryList);
    end
end

local achievementLines = {};
local achievementLinesDirty = true;
local achievementLinesOwner = "";
local achievements = {};

local function GetAchievementLines()
    local container = "Achievements";
    local dbEntry = Armory.selectedDbBaseEntry;

    table.wipe(achievements);
    table.wipe(achievementLines);
    
    if ( dbEntry:Contains(container) ) then
        GetAchievementCategories();
         
        for _, category in ipairs(achievementCategories) do
            achievements[tostring(category.id)] = {};
        end

        local index, link, completed, date, category;
        for id in pairs(dbEntry:GetValue(container)) do
            index, link, completed, date, quantity, reqQuantity = dbEntry:GetValue(container, id);
            category = _G.GetAchievementCategory(id);
            if ( index and category ) then
                table.insert(achievements[tostring(category)], {id=id, order=index, link=link, completed=completed, date=date, quantity=quantity, reqQuantity=reqQuantity});
            end
        end
        
        for _, achievement in pairs(achievements) do
            table.sort(achievement, function(a, b) return a.order < b.order end);
        end
        
        local numAchievements;
        table.wipe(counts);
        for _, category in ipairs(achievementCategories) do
            numAchievements = table.getn(achievements[tostring(category.id)]);
            counts[tostring(category.id)] = (counts[tostring(category.id)] or 0) + numAchievements;
            if ( category.parent ) then
                counts[tostring(category.parent)] = (counts[tostring(category.parent)] or 0) + numAchievements;
            end
        end
     
        local collapsed = false;
        local childCollapsed = false;
        local name, include;
        for _, category in ipairs(achievementCategories) do
            if ( counts[tostring(category.id)] > 0 ) then
                name = _G.GetCategoryInfo(category.id);
                if ( category.parent ) then
                    if ( not collapsed ) then
                        table.insert(achievementLines, {name=name, id=category.id, isHeader=true, isChild=true, collapsed=category.collapsed});
                    end
                    childCollapsed = collapsed or category.collapsed;
                else
                    table.insert(achievementLines, {name=name, id=category.id, isHeader=true, collapsed=category.collapsed});
                    collapsed = category.collapsed;
                    childCollapsed = false;
                end
                if ( not (collapsed or childCollapsed) ) then
                    for _, achievement in ipairs(achievements[tostring(category.id)]) do
                        _, name = _G.GetAchievementInfo(achievement.id);
                        if ( achievementFilter == "" ) then
                            include = true;
                        else
                            include = string.find(strlower(name), strlower(achievementFilter), 1, true);
                        end
                        if ( include ) then
                            table.insert(achievementLines, {name=name, id=achievement.id, link=achievement.link, completed=achievement.completed, date=achievement.date, quantity=achievement.quantity, reqQuantity=achievement.reqQuantity});
                        end
                    end
                end
            end
        end
    end
    
    achievementLinesDirty = false;
    achievementLinesOwner = Armory:SelectedCharacter();
    
    return achievementLines;
end

local statisticLines = {};
local statisticLinesDirty = true;
local statisticLinesOwner = "";
local statistics = {};

local function GetStatisticLines()
    local container = "Statistics";
    local dbEntry = Armory.selectedDbBaseEntry;

    table.wipe(statistics);
    table.wipe(statisticLines);
    
    if ( dbEntry:Contains(container) ) then
        GetStatisticCategories();
        
        for _, category in ipairs(statisticCategories) do
            statistics[tostring(category.id)] = {};
        end

        local index, quantity, category;
        for id in pairs(dbEntry:GetValue(container)) do
            index, quantity = dbEntry:GetValue(container, id);
            category = _G.GetAchievementCategory(id);
            if ( index and category ) then
                table.insert(statistics[tostring(category)], {id=id, order=index, quantity=quantity});
            end
        end
        
        for _, statistic in pairs(statistics) do
            table.sort(statistic, function(a, b) return a.order < b.order end);
        end
        
        local numStatistics;
        table.wipe(counts);
        for _, category in ipairs(statisticCategories) do
            numStatistics = table.getn(statistics[tostring(category.id)]);
            counts[tostring(category.id)] = (counts[tostring(category.id)] or 0) + numStatistics;
            if ( category.parent ) then
                counts[tostring(category.parent)] = (counts[tostring(category.parent)] or 0) + numStatistics;
            end
        end
     
        local collapsed = false;
        local childCollapsed = false;
        local name, include;
        for _, category in ipairs(statisticCategories) do
            if ( counts[tostring(category.id)] > 0 ) then
                name = _G.GetCategoryInfo(category.id);
                if ( category.parent ) then
                    if ( not collapsed ) then
                        table.insert(statisticLines, {name=name, id=category.id, isHeader=true, isChild=true, collapsed=category.collapsed});
                    end
                    childCollapsed = collapsed or category.collapsed;
                else
                    table.insert(statisticLines, {name=name, id=category.id, isHeader=true, collapsed=category.collapsed});
                    collapsed = category.collapsed;
                    childCollapsed = false;
                end
                if ( not (collapsed or childCollapsed) ) then
                    for _, statistic in ipairs(statistics[tostring(category.id)]) do
                        _, name = _G.GetAchievementInfo(statistic.id);
                        if ( achievementFilter == "" ) then
                            include = true;
                        else
                            include = string.find(strlower(name), strlower(achievementFilter), 1, true);
                        end
                        if ( include ) then
                            table.insert(statisticLines, {name=name, id=statistic.id, quantity=statistic.quantity});
                        end
                    end
                end
            end
        end
    end
    
    statisticLinesDirty = false;
    statisticLinesOwner = Armory:SelectedCharacter();
    
    return statisticLines;
end

local function SetAchievementHeaderState(isAchievement, index, collapsed)
    local categories, line;

    if ( isAchievement ) then
        categories = achievementCategories;
        line = achievementLines[index];
        achievementLinesDirty = true;
    else
        categories = statisticCategories;
        line = statisticLines[index];
        statisticLinesDirty = true;
    end

    for _, category in ipairs(categories) do
        if ( index == 0 ) then
            category.collapsed = collapsed;
        elseif ( category.id == line.id ) then
            category.collapsed = collapsed;
            break;
        end
    end
end

----------------------------------------------------------
-- Achievement Storage
----------------------------------------------------------

local achievementUpdater = ArmoryBackgroundUpdater:new();
local achievementCache = ArmoryDbEntry:new({});
local achievementsDirty;

function Armory:ClearAchievements()
    local container = "Achievements";
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    achievementsDirty = true;
end

function Armory:UpdateAchievements(force)
    local container = "Achievements";
    local dbEntry = self.playerDbBaseEntry;

    achievementLinesDirty = achievementLinesDirty or self:IsPlayerSelected();
    
    if ( not self:HasAchievements() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);
        
        self:PrintDebug("UPDATE", container);

        GetAchievementCategories();

        local updater = achievementUpdater;
        local dbCache = achievementCache;

        if ( force ) then
            dbEntry:ClearContainer(container);
            for _, category in ipairs(achievementCategories) do
                for i = 1, _G.GetCategoryNumAchievements(category.id) do
                    self:UpdateAchievement(category.id, i);
                end
            end
            self:Unlock(container);
        else
            achievementsDirty = true;
            updater:Start(
                function(updater)
                    while ( achievementsDirty ) do
                        local start = time();
                        achievementsDirty = false;
                        for _, category in ipairs(achievementCategories) do
                            for i = 1, _G.GetCategoryNumAchievements(category.id) do
                                self:UpdateAchievement(category.id, i, dbCache);
                                updater:Suspend();
                            end
                        end
                        dbEntry:ClearContainer(container);
                        self:CopyTable(dbCache.db, dbEntry.db);
                        self:PrintDebug(container, "updated in", time() - start, "s.");
                    end
                    self:Unlock(container);
                end
            );
        end
    else
        achievementsDirty = true;
        self:PrintDebug("LOCKED", container);
    end
end

function Armory:UpdateAchievement(achievementId, index, dbEntry)
    if ( not self:HasAchievements() ) then
        return;
    elseif ( not dbEntry ) then
        dbEntry = self.playerDbBaseEntry;
    end

    self:GetTotalAchievementPoints();

    local id, completed, month, day, year;
    if ( not index ) then
        id, _, _, completed, month, day, year = _G.GetAchievementInfo(achievementId);
    else
        id, _, _, completed, month, day, year = _G.GetAchievementInfo(achievementId, index);
    end
    if ( not id ) then
        return;
    end
        
    local container = "Achievements";
    local key = tostring(id);
    local quantity = 0;
    local totalQuantity = 0;
    local started;
    local previous;

    if ( not completed ) then
        for i = 1, _G.GetAchievementNumCriteria(id) do
            local _, criteriaType, completed, quantityNumber, reqQuantity, _, flags, assetId = _G.GetAchievementCriteriaInfo(id, i);
            if ( criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetId ) then
                _, _, _, completed = _G.GetAchievementInfo(assetId);
                totalQuantity = totalQuantity + 1;
                if ( completed ) then
                    quantity = quantity + 1;
                    started = true;
                end
            elseif ( bit.band(flags, ACHIEVEMENT_CRITERIA_PROGRESS_BAR) == ACHIEVEMENT_CRITERIA_PROGRESS_BAR ) then
                totalQuantity = totalQuantity + reqQuantity;
                quantity = quantity + quantityNumber;
                if ( quantityNumber > 0 ) then
                    started = true;
                end
            elseif ( completed ) then
                totalQuantity = totalQuantity + 1;
                quantity = quantity + 1;
                started = true;
            else
                totalQuantity = totalQuantity + 1;
            end
        end
    elseif ( _G.GetPreviousAchievement(id) ) then
        previous = _G.GetPreviousAchievement(id);
        self:UpdateAchievement(previous, nil, dbEntry);
    end
    
    if ( (completed or started) and (index or not dbEntry:GetValue(container, key)) ) then
        dbEntry:SetValue(2, container, key, index, _G.GetAchievementLink(id), completed, self:MakeDate(day, month, year), quantity, totalQuantity, previous);
    end
end

local statisticUpdater = ArmoryBackgroundUpdater:new();
local statisticCache = ArmoryDbEntry:new({});
local statisticDirty;

function Armory:ClearStatistics()
    local container = "Statistics";
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    statisticDirty = true;
end

function Armory:UpdateStatistics(force)
    local container = "Statistics";
    local dbEntry = self.playerDbBaseEntry;

    statisticLinesDirty = statisticLinesDirty or self:IsPlayerSelected();

    if ( not self:HasAchievements() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);
        
        self:PrintDebug("UPDATE", container);
        
        GetStatisticCategories();

        local updater = statisticUpdater;
        local dbCache = statisticCache;

        if ( force ) then
            local id, quantity;
            dbEntry:ClearContainer(container);
            for _, category in ipairs(statisticCategories) do
                for i = 1, _G.GetCategoryNumAchievements(category.id) do
                    id = _G.GetAchievementInfo(category.id, i);
                    if ( id ) then
                        quantity = _G.GetStatistic(id);
                        if ( quantity and quantity ~= "--" ) then
                            dbEntry:SetValue(2, container, tostring(id), i, quantity);
                        end
                    end
                end
            end
            self:Unlock(container);
        else
            statisticDirty = true;
            updater:Start(
                function(updater)
                    local id, quantity;
                    while ( statisticDirty ) do
                        local start = time();
                        statisticDirty = false;
                        for _, category in ipairs(statisticCategories) do
                            for i = 1, _G.GetCategoryNumAchievements(category.id) do
                                id = _G.GetAchievementInfo(category.id, i);
                                if ( id ) then
                                    quantity = _G.GetStatistic(id);
                                    if ( quantity and quantity ~= "--" ) then
                                        dbCache:SetValue(2, container, tostring(id), i, quantity);
                                    end
                                end
                                updater:Suspend();
                            end
                        end
                        dbEntry:ClearContainer(container);
                        self:CopyTable(dbCache.db, dbEntry.db);
                        self:PrintDebug(container, "updated in", time() - start, "s.");
                    end
                    self:Unlock(container);
                end
            );
        end
    else
        statisticDirty = true;
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Achievement Interface
----------------------------------------------------------

function Armory:GetNumAchievements()
    if ( achievementLinesDirty or not self:IsSelectedCharacter(achievementLinesOwner) ) then
        GetAchievementLines();
    end
    return #achievementLines;
end

function Armory:GetAchievementInfo(index)
    local numLines = self:GetNumAchievements();
    if ( index > 0 and index <= numLines ) then
        local line = achievementLines[index];
        return line.name, line.isHeader, line.isChild, line.collapsed, line.link, line.completed, line.date, line.quantity, line.reqQuantity;
    end
end

function Armory:ExpandAchievementHeader(isAchievement, index)
    SetAchievementHeaderState(isAchievement, index, false);
end

function Armory:CollapseAchievementHeader(isAchievement, index)
    SetAchievementHeaderState(isAchievement, index, true);
end

function Armory:GetNumStatistics()
    if ( statisticLinesDirty or not self:IsSelectedCharacter(statisticLinesOwner) ) then
        GetStatisticLines();
    end
    return #statisticLines;
end

function Armory:GetStatisticInfo(index)
    local numLines = self:GetNumStatistics();
    if ( index > 0 and index <= numLines ) then
        local line = statisticLines[index];
        return line.name, line.isHeader, line.isChild, line.collapsed, line.quantity;
    end
end

function Armory:SetAchievementFilter(text)
    local refresh = (achievementFilter ~= text);
    achievementFilter = text;
    return refresh;
end

function Armory:GetAchievementFilter()
    return achievementFilter;
end

function Armory:GetAchievement(id)
    local _, _, completed, date, quantity, reqQuantity, previous = self.selectedDbBaseEntry:GetValue("Achievements", id);
    return completed, date, quantity, reqQuantity, previous;
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindAchievement(...)
    local container = "Achievements";
    local dbEntry = self.selectedDbBaseEntry;
    local list = {};

    local achievements = dbEntry:GetValue(container);
    if ( achievements ) then
        local link, name, text;
        for id in pairs(achievements) do
            _, link = dbEntry:GetValue(container, id);
            name = self:GetNameFromLink(link);
            if ( self:GetConfigExtendedSearch() ) then
                text = self:GetTextFromLink(link);
            else
                text = name;
            end
            if ( self:FindTextParts(text, ...) ) then
                table.insert(list, {label=ACHIEVEMENTS, name=name, link=link});
            end
        end
    end

    return list;
end