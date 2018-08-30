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
local container = "Professions";
local itemContainer = "SkillLines";

local selectedSkill;
local selectedSkillLine = 1;

local tradeSkillSubClassFilter = {};
local tradeSkillInvSlotFilter = {};
local tradeSkillFilter = "";
local tradeSkillMinLevel = 0;
local tradeSkillMaxLevel = 0;

local invSlots = {};
local subClasses = {};

----------------------------------------------------------
-- TradeSkills Internals
----------------------------------------------------------

local professionLines = {};
local dirty = true;
local owner = "";

local function SelectProfession(baseEntry, name)
    local dbEntry = ArmoryDbEntry:new(baseEntry);
    local _, newEntry = dbEntry:SetPosition(container, name);
    if ( newEntry ) then
        dbEntry:SetValue("Texture", Armory:FindSpellTexture(name));
    end
    return dbEntry;
end

local groups = {};
local invSlot = {};
local function GetProfessionLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local group = { index=0, expanded=true, included=true, items={} };
    local numReagents, oldPosition, names, isIncluded, itemMinLevel;
    local numLines, extended;
    local name, id, skillType, isExpanded;

    table.wipe(professionLines);

    if ( dbEntry:Contains(container, selectedSkill, itemContainer) ) then
        dbEntry = SelectProfession(dbEntry, selectedSkill)

        numLines = dbEntry:GetNumValues(itemContainer);
        if ( numLines > 0 ) then
            table.wipe(groups);
            _, skillType = dbEntry:GetValue(itemContainer, 1, "Info");
            extended = (skillType == "header");
            -- apply filters
            for i = 1, numLines do
                name, skillType = dbEntry:GetValue(itemContainer, i, "Info");
                id = dbEntry:GetValue(itemContainer, i, "Data");
                isExpanded = not Armory:GetHeaderLineState(itemContainer..selectedSkill, name);
                if ( skillType == "header" ) then
                    if ( tradeSkillSubClassFilter ) then
                        isIncluded = tradeSkillSubClassFilter[name..(#groups + 1)];
                    else
                        isIncluded = true;
                    end
                    group = { index=i, expanded=isExpanded, included=isIncluded, items={} };
                    table.insert(groups, group);
                 elseif ( group.included ) then
                    numReagents = dbEntry:GetValue(id, "NumReagents") or 0;
                    names = name or "";
                    if ( numReagents > 0 and dbEntry:Contains(id, "Reagents") ) then
                        for index = 1, numReagents do
                            names = names.."\t"..(dbEntry:GetValue(id, "Reagents", "ReagentInfo"..index) or "");
                        end
                    end

                    Armory:FillTable(invSlot, dbEntry:GetValue(id, "InvSlot"));
                    if ( extended and tradeSkillInvSlotFilter ) then
                        isIncluded = false;
                        for _, slot in ipairs(invSlot) do
                            if ( tradeSkillInvSlotFilter[slot] ) then
                                isIncluded = true;
                                break;
                            end
                        end
                    else
                        isIncluded = true;
                    end
                    if ( isIncluded and tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
                        _, _, _, _, itemMinLevel = _G.GetItemInfo(dbEntry:GetValue(itemContainer, i, "ItemLink"));
                        isIncluded = itemMinLevel and itemMinLevel >= tradeSkillMinLevel and itemMinLevel <= tradeSkillMaxLevel;
                    elseif ( isIncluded and not name or (tradeSkillFilter ~= "" and not string.find(strlower(names), strlower(tradeSkillFilter), 1, true)) ) then
                        isIncluded = false;
                    end
                    if ( isIncluded ) then
                        table.insert(group.items, {index=i, name=name});
                    end
                 end
            end
        
            -- build the list
            if ( #groups == 0 ) then
                if ( not extended ) then
                    table.sort(group.items, function(a, b) return a.name < b.name; end);
                end
                for _, v in ipairs(group.items) do
                    table.insert(professionLines, v.index);
                end
            else
                local hasFilter = Armory:HasTradeSkillFilter();
                for i = 1, #groups do
                    if ( groups[i].included and (table.getn(groups[i].items) > 0 or not hasFilter) ) then
                        table.insert(professionLines, groups[i].index);
                        if ( groups[i].expanded ) then
                            for _, v in ipairs(groups[i].items) do
                                table.insert(professionLines, v.index);
                            end
                        end
                    end
                end
            end
            table.wipe(groups);
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();
    
    return professionLines;
end

local function UpdateTradeSkillHeaderState(index, isCollapsed)
    local dbEntry = SelectProfession(Armory.selectedDbBaseEntry, selectedSkill);
    if ( index == 0 ) then
        for i = 1, dbEntry:GetNumValues(itemContainer) do
            local name, skillType = dbEntry:GetValue(itemContainer, i, "Info");
            if ( skillType == "header" ) then
                Armory:SetHeaderLineState(itemContainer..selectedSkill, name, isCollapsed);
            end
        end
    else
        local numLines = Armory:GetNumTradeSkills();
        if ( index > 0 and index <= numLines ) then
            local name = dbEntry:GetValue(itemContainer, professionLines[index], "Info");
            Armory:SetHeaderLineState(itemContainer..selectedSkill, name, isCollapsed);
        end
    end
    dirty = true;
end

local function ClearProfessions()
    Armory.playerDbBaseEntry:SetValue(container, nil);
end

local function SetProfessionValue(name, key, ...)
    if ( name ~= "UNKNOWN" ) then
        SelectProfession(Armory.playerDbBaseEntry, name):SetValue(key, ...);
    end
end

local function GetProfessionValue(key)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( dbEntry:Contains(container, selectedSkill, key) ) then
        return SelectProfession(dbEntry, selectedSkill):GetValue(key);
    end
end

local function GetProfessionLineValue(index, key, subkey)
    local dbEntry = Armory.selectedDbBaseEntry;
    local numLines = Armory:GetNumTradeSkills();
    if ( index > 0 and index <= numLines ) then
        local id = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Data");
        if ( subkey ) then
            return dbEntry:GetValue(container, selectedSkill, id, key, subkey);
        elseif ( key ) then
            return dbEntry:GetValue(container, selectedSkill, id, key);
        else
            return dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Info");
        end
    end
end

local function PreserveTradeSkillsState()
    local button = TradeSkillFrameAvailableFilterCheckButton;
    local editBox = TradeSkillFrameEditBox;
    local state = { subClassFilter=0, invSlotFilter=0, makeable=false, index=_G.GetTradeSkillSelectionIndex(), collapsed={} };
    local skillType, isExpanded;
    
    if ( button ) then
        state.makeable = button:GetChecked();
    end
    if ( editBox ) then
        state.text, state.minLevel, state.maxLevel = Armory:GetTradeSkillItemFilter(editBox:GetText());
    end
    Armory:FillTable(subClasses, _G.GetTradeSkillSubClasses());
    for i = 0, #subClasses do
        if ( _G.GetTradeSkillSubClassFilter(i) ) then
            state.subClassFilter = i;
            break;
        end
    end
    Armory:FillTable(invSlots, _G.GetTradeSkillInvSlots());
    for i = 0, #invSlots do
        if ( _G.GetTradeSkillInvSlotFilter(i) ) then
            state.invSlotFilter = i;
            break;
        end
    end

    if ( (state.minLevel or 0) ~= 0 or (state.maxLevel or 0) ~= 0 ) then
        _G.SetTradeSkillItemLevelFilter(0, 0);
    end
    if ( state.text and state.text ~= "" ) then
        _G.SetTradeSkillItemNameFilter(nil);
    end
    if ( state.subClassFilter > 0 ) then
        _G.SetTradeSkillSubClassFilter(0, 1, 1);
    end
    if ( state.invSlotFilter > 0 ) then
        _G.SetTradeSkillInvSlotFilter(0, 1, 1);
    end
    if ( state.makeable ) then
        _G.TradeSkillOnlyShowMakeable(nil);
    end
    
    for i = _G.GetNumTradeSkills(), 1, -1 do
        _, skillType, _, isExpanded = _G.GetTradeSkillInfo(i);
        if ( skillType == "header" and not isExpanded ) then
            table.insert(state.collapsed, i);
            _G.ExpandTradeSkillSubClass(i);
        end
    end

    return state;
end

local function RestoreTradeSkillsState(state)
    table.sort(state.collapsed);
    for _, i in pairs(state.collapsed) do
        _G.CollapseTradeSkillSubClass(i);
    end

    if ( (state.minLevel or 0) ~= 0 or (state.maxLevel or 0) ~= 0 ) then
        _G.SetTradeSkillItemLevelFilter(state.minLevel, state.maxLevel);
    end
    if ( state.text and state.text ~= "" ) then
        _G.SetTradeSkillItemNameFilter(state.text);
    end
    if ( state.subClassFilter > 0 ) then
        _G.SetTradeSkillSubClassFilter(state.subClassFilter, 1, 1);
    end
    if ( state.invSlotFilter > 0 ) then
        _G.SetTradeSkillInvSlotFilter(state.invSlotFilter, 1, 1);
    end
    if ( state.makeable ) then
        _G.TradeSkillOnlyShowMakeable(state.makeable);
    end
    
    _G.SelectTradeSkill(state.index);
end

----------------------------------------------------------
-- TradeSkills Item Caching
----------------------------------------------------------

local function SetItemCache(dbEntry, profession, link)
    if ( Armory:GetConfigShowCrafters() and not Armory:GetConfigUseEncoding() ) then
        local itemId = Armory:GetItemId(link);
        if ( itemId ) then
            if ( profession ) then
                dbEntry:SetValue(4, container, profession, ARMORY_CACHE_CONTAINER, itemId, 1);
            else
                dbEntry:SetValue(2, ARMORY_CACHE_CONTAINER, itemId, 1);
            end
        end
    end
end

local function ItemIsCached(dbEntry, profession, itemId)
    if ( itemId ) then
        return dbEntry:Contains(container, profession, ARMORY_CACHE_CONTAINER, itemId);
    end
    return false;
end

local function ClearItemCache(dbEntry)
    dbEntry:SetValue(ARMORY_CACHE_CONTAINER, nil);
end

local function ItemCacheExists(dbEntry, profession)
    return dbEntry:Contains(container, profession, ARMORY_CACHE_CONTAINER);
end

----------------------------------------------------------
-- TradeSkills Storage
----------------------------------------------------------

function Armory:ClearTradeSkills()
    local dbEntry = self.selectedDbBaseEntry;
    dbEntry:SetValue(container, nil);
    dirty = true;
end

function Armory:UpdateTradeSkill()
    local name, rank, maxRank;
    local modeChanged, hasCooldown;

    if ( not self:HasTradeSkills() ) then
        ClearProfessions();
        return;
    end

    name, rank, maxRank = _G.GetTradeSkillLine();

    if ( name and name ~= "UNKNOWN" ) then
        if ( not self:IsLocked(itemContainer) ) then
            self:Lock(itemContainer);

            self:PrintDebug("UPDATE", name);
            
            SetProfessionValue(name, "Rank", rank, maxRank);
            SetProfessionValue(name, "ListLink", _G.GetTradeSkillListLink());
            if ( self:GetConfigExtendedTradeSkills() ) then
                SetProfessionValue(name, "SubClasses", _G.GetTradeSkillSubClasses());
                SetProfessionValue(name, "InvSlots", _G.GetTradeSkillInvSlots());
            else
                SetProfessionValue(name, "SubClasses", nil);
                SetProfessionValue(name, "InvSlots", nil);
            end

            local dbEntry = SelectProfession(self.playerDbBaseEntry, name);
            local numSkills, extended = self:GetNumTradeSkills();
            if ( self:GetConfigExtendedTradeSkills() ) then
                local state = PreserveTradeSkillsState();
                if ( not extended or numSkills < _G.GetNumTradeSkills() ) then
                    hasCooldown = self:UpdateTradeSkillExtended(dbEntry);
                else
                    hasCooldown = self:UpdateTradeSkillCooldowns(dbEntry);
                end
                RestoreTradeSkillsState(state);
                modeChanged = not extended;
            else
                hasCooldown = self:UpdateTradeSkillSimple(dbEntry);
                modeChanged = extended;
            end

            self:Unlock(itemContainer);
        else
            self:PrintDebug("LOCKED", name);
        end
    elseif ( Armory:GetConfigExtendedTradeSkills() ) then
        self:PrintWarning(ARMORY_TRADE_UPDATE_WARNING);
    end
    
    return name, modeChanged, hasCooldown;
end

local function StoreTradeSkillInfo(dbEntry, index)
    local link = _G.GetTradeSkillRecipeLink(index);
    local _, id = Armory:GetLinkId(link);
    local info = dbEntry:SelectContainer(id);

    info.RecipeLink = link;
    info.Description = _G.GetTradeSkillDescription(index);
    info.Icon = _G.GetTradeSkillIcon(index);
    info.Tools = _G.GetTradeSkillTools(index);
    info.ItemLink = _G.GetTradeSkillItemLink(index);
    info.NumMade = _G.GetTradeSkillNumMade(index);
    info.NumReagents = _G.GetTradeSkillNumReagents(index);
    info.Reagents = {};
    for i = 1, info.NumReagents do
        info.Reagents["ReagentInfo"..i] = dbEntry.Save(_G.GetTradeSkillReagentInfo(index, i));
        info.Reagents["ReagentItemLink"..i] = dbEntry.Save(_G.GetTradeSkillReagentItemLink(index, i));
    end
    if ( _G.GetTradeSkillCooldown(index) ) then
        info.Cooldown = dbEntry.Save(_G.GetTradeSkillCooldown(index), time());
    end

    SetItemCache(dbEntry, nil, info.ItemLink);
   
    return id, info;
end

local invSlotTypes = {};
function Armory:UpdateTradeSkillExtended(dbEntry)
    -- retrieve slot types (would be to time consuming if put in funcAdditionalInfo)
    local name, hasCooldown;
    self:FillTable(invSlots, _G.GetTradeSkillInvSlots());
    table.wipe(invSlotTypes);
    for i = 1, #invSlots do
        _G.SetTradeSkillInvSlotFilter(i, 1, 1);
        for id = 1, _G.GetNumTradeSkills() do
            name = _G.GetTradeSkillInfo(id);
            if ( invSlotTypes[name] ) then
                table.insert(invSlotTypes[name], invSlots[i]);
            else
                invSlotTypes[name] = {invSlots[i]};
            end
        end
    end
    _G.SetTradeSkillInvSlotFilter(0, 1, 1);

    local funcNumLines = _G.GetNumTradeSkills;
    local funcGetLineInfo = _G.GetTradeSkillInfo;
    local funcGetLineState = function(index)
        local _, skillType, _, isExpanded = _G.GetTradeSkillInfo(index);
        local isHeader = (skillType == "header");
        return isHeader, isExpanded;
    end;
    local funcAdditionalInfo = function(index)
        local name = _G.GetTradeSkillInfo(index);
        local id, info = StoreTradeSkillInfo(dbEntry, index);
        if ( info.Cooldown ) then
            hasCooldown = true;
        end
        if ( invSlotTypes[name] ) then
            info.InvSlot = dbEntry.Save(unpack(invSlotTypes[name]));
        end
        return id;
    end
    
    ClearItemCache(dbEntry);

    -- store the complete (expanded) list
    dbEntry:SetExpandableListValues(itemContainer, funcNumLines, funcGetLineState, funcGetLineInfo, nil, nil, funcAdditionalInfo);
    
    table.wipe(invSlotTypes);
    
    return hasCooldown;
end

function Armory:UpdateTradeSkillCooldowns(dbEntry)
    local hasCooldown, id;
    for index = 1, _G.GetNumTradeSkills() do
        id = dbEntry:GetValue(itemContainer, index, "Data");
        if ( _G.GetTradeSkillCooldown(index) ) then
            dbEntry:SetValue(2, id, "Cooldown", _G.GetTradeSkillCooldown(index), time());
            hasCooldown = true;
        elseif ( id ) then
            dbEntry:SetValue(2, id, "Cooldown", nil);
        end
    end
    return hasCooldown;
end

function Armory:UpdateTradeSkillSimple(dbEntry)
    local skillName, skillType, hasCooldown, itemLink;
    local skillIndex = 1;
    local index = 1;

    dbEntry:ClearContainer(itemContainer);

    ClearItemCache(dbEntry);

    repeat
        skillName, skillType = _G.GetTradeSkillInfo(skillIndex);

        if ( skillName and skillType ~= "header" ) then
            local id, info = StoreTradeSkillInfo(dbEntry, skillIndex);

            dbEntry:SetValue(3, itemContainer, index, "Info", _G.GetTradeSkillInfo(skillIndex));
            dbEntry:SetValue(3, itemContainer, index, "Data", id);
            
            if ( info.Cooldown ) then
                hasCooldown = true;
            end
            index = index + 1;
       end
       skillIndex = skillIndex + 1;
    until ( not skillName )
    
    return hasCooldown;
end

----------------------------------------------------------
-- TradeSkills Hooks
----------------------------------------------------------

hooksecurefunc("SetTradeSkillItemNameFilter", function(text)
    if ( not Armory:IsLocked(itemContainer) ) then
        tradeSkillItemNameFilter = text;
    end
end);

----------------------------------------------------------
-- TradeSkills Interface
----------------------------------------------------------

function Armory:SetSelectedProfession(name)
    selectedSkill = name;
    dirty = true;
end

function Armory:GetSelectedProfession()
    return selectedSkill;
end

function Armory:GetProfessionTexture(name)
    local dbEntry = self.selectedDbBaseEntry;
    local texture;

    if ( dbEntry:Contains(container, name, "Texture") ) then
        texture = SelectProfession(dbEntry, name):GetValue("Texture");
    end

    -- Note: Sometimes the name cannot be found because it differs from the spellbook (e.g. "Mining" vs "Smelting")
    if ( not texture ) then
        ----  Maybe we should solely rely on the table below...
        ----  Note: not all entries are relevant
        local tradeIcons = {};
        tradeIcons[ARMORY_TRADE_ALCHEMY] = "Trade_Alchemy";
        tradeIcons[ARMORY_TRADE_BLACKSMITHING] = "Trade_BlackSmithing";
        tradeIcons[ARMORY_TRADE_COOKING] = "INV_Misc_Food_15";
        tradeIcons[ARMORY_TRADE_ENCHANTING] = "Trade_Engraving";
        tradeIcons[ARMORY_TRADE_ENGINEERING] = "Trade_Engineering";
        tradeIcons[ARMORY_TRADE_FIRST_AID] = "Spell_Holy_SealOfSacrifice";
        tradeIcons[ARMORY_TRADE_FISHING] = "Trade_Fishing";
        tradeIcons[ARMORY_TRADE_HERBALISM] = "Trade_Herbalism";
        tradeIcons[ARMORY_TRADE_JEWELCRAFTING] = "INV_Misc_Gem_01";
        tradeIcons[ARMORY_TRADE_LEATHERWORKING] = "Trade_LeatherWorking";
        tradeIcons[ARMORY_TRADE_MINING] = "Trade_Mining";
        tradeIcons[ARMORY_TRADE_POISONS] = "Trade_BrewPoison";
        tradeIcons[ARMORY_TRADE_SKINNING] = "INV_Weapon_ShortBlade_01";
        tradeIcons[ARMORY_TRADE_TAILORING] = "Trade_Tailoring";
        tradeIcons[ARMORY_TRADE_INSCRIPTION] = "INV_Inscription_Tradeskill01";

        if ( tradeIcons[name] ) then
            texture = "Interface\\Icons\\"..tradeIcons[name];
        else
            texture = "Interface\\Icons\\INV_Misc_QuestionMark";
        end
    end

    return texture;
end

function Armory:GetNumProfessions()
    return table.getn(self.GetProfessionNames());
end

local professionNames = {};
function Armory:GetProfessionNames()
    local data = self.selectedDbBaseEntry:GetValue(container);

    table.wipe(professionNames);
    
    if ( data ) then
        for name, _ in pairs(data) do
            table.insert(professionNames, name);
        end
        table.sort(professionNames);
    end

    return professionNames;
end

function Armory:GetNumTradeSkills()
    local numSkills, extended, skillType;
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetProfessionLines();
    end
    numSkills = #professionLines;
    if ( numSkills == 0 ) then
        extended = self:GetConfigExtendedTradeSkills();
    else
        _, skillType = self.selectedDbBaseEntry:GetValue(container, selectedSkill, itemContainer, professionLines[1], "Info");
        extended = (skillType == "header");
    end
    return numSkills, extended;
end

function Armory:GetTradeSkillInfo(index)
    local skillName, skillType, numAvailable, isExpanded, altVerb = GetProfessionLineValue(index);
    isExpanded = not self:GetHeaderLineState(itemContainer..selectedSkill, skillName); 
    return skillName, skillType, numAvailable, isExpanded, altVerb;
end

function Armory:ExpandTradeSkillSubClass(index)
    UpdateTradeSkillHeaderState(index, false);
end

function Armory:CollapseTradeSkillSubClass(index)
    UpdateTradeSkillHeaderState(index, true);
end

function Armory:SetTradeSkillInvSlotFilter(index, onOff, exclusive)
    local dbEntry = self.selectedDbBaseEntry;
    self:FillTable(invSlots, self:GetTradeSkillInvSlots());
    if ( (index or 0) == 0 ) then
        table.wipe(tradeSkillInvSlotFilter);
        for i = 1, #invSlots do
            tradeSkillInvSlotFilter[invSlots[i]] = onOff;
        end
    elseif ( exclusive ) then
        for i = 1, #invSlots do
            if ( i == index ) then
                tradeSkillInvSlotFilter[invSlots[i]] = onOff;
            else
                tradeSkillInvSlotFilter[invSlots[i]] = not onOff;
            end
        end
    else
        tradeSkillInvSlotFilter[invSlots[index]] = onOff;
    end

    self:ExpandTradeSkillSubClass(0);
end

function Armory:GetTradeSkillInvSlotFilter(index)
    local checked = true;
    self:FillTable(invSlots, self:GetTradeSkillInvSlots());
    if ( (index or 0) == 0 ) then
        for i = 1, #invSlots do
            if ( not tradeSkillInvSlotFilter[invSlots[i]] ) then
                checked = false;
                break;
            end
        end
    else
        checked = tradeSkillInvSlotFilter[invSlots[index]];
    end

    return checked;
end

function Armory:SetTradeSkillSubClassFilter(index, onOff, exclusive)
    local subClasses = self:GetUniqueTradeSkillSubClasses();

    if ( (index or 0) == 0 ) then
        table.wipe(tradeSkillSubClassFilter);
        for i = 1, #subClasses do
            tradeSkillSubClassFilter[subClasses[i]] = onOff;
        end
    elseif ( exclusive ) then
        for i = 1, #subClasses do
            if ( i == index ) then
                tradeSkillSubClassFilter[subClasses[i]] = onOff;
            else
                tradeSkillSubClassFilter[subClasses[i]] = not onOff;
            end
        end
    else
        tradeSkillSubClassFilter[subClasses[index]] = onOff;
    end

    self:ExpandTradeSkillSubClass(0);
end

function Armory:GetTradeSkillSubClassFilter(index)
    local subClasses = self:GetUniqueTradeSkillSubClasses();
    local checked = true;

    if ( (index or 0) == 0 ) then
        for i = 1, #subClasses do
            if ( not tradeSkillSubClassFilter[subClasses[i]] ) then
                checked = false;
                break;
            end
        end
    else
        checked = tradeSkillSubClassFilter[subClasses[index]];
    end

    return checked;
end

function Armory:SetTradeSkillItemNameFilter(text)
    local refresh = (tradeSkillFilter ~= text);
    tradeSkillFilter = text;
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetTradeSkillItemNameFilter()
    return tradeSkillFilter;
end

function Armory:SetTradeSkillItemLevelFilter(minLevel, maxLevel)
    local refresh = (tradeSkillMinLevel ~= minLevel or tradeSkillMaxLevel ~= maxLevel);
    tradeSkillMinLevel = max(0, minLevel);
    tradeSkillMaxLevel = max(0, maxLevel);
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetTradeSkillItemLevelFilter()
    return tradeSkillMinLevel, tradeSkillMaxLevel;
end

function Armory:GetTradeSkillItemFilter(text)
    if ( not text ) then
        text = tradeSkillItemNameFilter or "";
    end
    if ( text == SEARCH ) then
        text = "";
    end
    
    local minLevel, maxLevel;
    local approxLevel = strmatch(text, "^~(%d+)");
    if ( approxLevel ) then
        minLevel = approxLevel - 2;
        maxLevel = approxLevel + 2;
    else
        minLevel, maxLevel = strmatch(text, "^(%d+)%s*-*%s*(%d*)$");
    end
    if ( minLevel ) then
        if ( maxLevel == "" or maxLevel < minLevel ) then
            maxLevel = minLevel;
        end
        text = "";
    else
        minLevel = 0;
        maxLevel = 0;
    end

    return text, minLevel, maxLevel;
end

function Armory:HasTradeSkillFilter()
    if ( not self:GetTradeSkillSubClassFilter(0) ) then
        return true;
    elseif ( not self:GetTradeSkillInvSlotFilter(0) ) then
        return true;
    elseif ( tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
        return true;
    elseif ( tradeSkillFilter ~= "" ) then
        return true;
    end
    return false;
end

function Armory:SelectTradeSkill(index)
    selectedSkillLine = index;
end

function Armory:GetTradeSkillSelectionIndex()
    return selectedSkillLine;
end

function Armory:GetTradeSkillLine()
    if ( selectedSkill ) then
        local rank, maxRank = GetProfessionValue("Rank");
        return selectedSkill, rank, maxRank;
    else
        return "UNKNOWN", 0, 0;
    end
end

function Armory:GetFirstTradeSkill()
    local numLines = self:GetNumTradeSkills();
    for i = 1, numLines do
        local _, skillType = self:GetTradeSkillInfo(i);
        if ( skillType ~= "header" ) then
            return i;
        end
    end
    return 0;
end

function Armory:GetUniqueTradeSkillSubClasses()
    self:FillTable(subClasses, self:GetTradeSkillSubClasses());
    for i = 1, #subClasses do
        subClasses[i] = subClasses[i]..i;
    end
    return subClasses;    
end

function Armory:GetTradeSkillSubClasses()
    return GetProfessionValue("SubClasses");
end

function Armory:GetTradeSkillInvSlots()
    return GetProfessionValue("InvSlots");
end

function Armory:GetTradeSkillListLink()
    return GetProfessionValue("ListLink");
end

function Armory:GetTradeSkillDescription(index)
    return GetProfessionLineValue(index, "Description");
end

function Armory:GetTradeSkillSpellFocus(index)
    return GetProfessionLineValue(index, "SpellFocus") or "";
end

function Armory:GetTradeSkillCooldown(index)
    local cooldown, timestamp = GetProfessionLineValue(index, "Cooldown");

    if ( cooldown ) then
        cooldown = cooldown - (time() - timestamp);
        if ( cooldown < 0 ) then
            cooldown = 0;
        end
    end
    return cooldown;
end

function Armory:GetTradeSkillIcon(index)
    return GetProfessionLineValue(index, "Icon") or nil;
end

function Armory:GetTradeSkillNumMade(index)
    local minMade, maxMade = GetProfessionLineValue(index, "NumMade");
    minMade = minMade or 0;
    maxMade = maxMade or 0;
    return minMade, maxMade;
end

function Armory:GetTradeSkillNumReagents(index)
    return GetProfessionLineValue(index, "NumReagents") or 0;
end

function Armory:GetTradeSkillTools(index)
    return GetProfessionLineValue(index, "Tools") or "";
end

function Armory:GetTradeSkillItemLink(index)
    return GetProfessionLineValue(index, "ItemLink");
end

function Armory:GetTradeSkillRecipeLink(index)
    return GetProfessionLineValue(index, "RecipeLink");
end

function Armory:GetTradeSkillReagentInfo(index, id)
    return GetProfessionLineValue(index, "Reagents", "ReagentInfo"..id);
end

function Armory:GetTradeSkillReagentItemLink(index, id)
    return GetProfessionLineValue(index, "Reagents", "ReagentItemLink"..id);
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindSkill(itemList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = itemList or {};

    -- need low-level access because of all the possible active filters
    local professions = dbEntry:GetValue(container);
    if ( professions ) then
        local text, link, skillName, skillType, id;
        for name in pairs(professions) do
            for i = 1, dbEntry:GetNumValues(container, name, itemContainer) do
                skillName, skillType = dbEntry:GetValue(container, name, itemContainer, i, "Info");
                if ( skillType ~= "header" ) then
                    id = dbEntry:GetValue(container, name, itemContainer, i, "Data");
                    if ( itemList ) then
                        link = dbEntry:GetValue(container, name, id, "ItemLink");
                    else
                        link = dbEntry:GetValue(container, name, id, "RecipeLink");
                    end
                    if ( self:GetConfigExtendedSearch() ) then
                        text = self:GetTextFromLink(link);
                    else
                        text = skillName;
                    end
                    if ( self:FindTextParts(text, ...) ) then
                        table.insert(list, {label=name, name=skillName, link=link});
                    end
                end
            end
        end
    end

    return list;
end

local recipeOwners = {};
function Armory:GetRecipeOwners(id)
    table.wipe(recipeOwners);

    if ( self:HasTradeSkills() and self:GetConfigShowRecipeKnown() ) then
        local currentProfile = self:CurrentProfile();

        for _, profile in ipairs(self:Profiles()) do
            self:SelectProfile(profile);
            
            if ( profile.realm == self.playerRealm ) then
                local dbEntry = self.selectedDbBaseEntry;
                if ( dbEntry:Contains(container) ) then
                    local data = dbEntry:SelectContainer(container);
                    for profession in pairs(data) do
                        if ( dbEntry:Contains(container, profession, id) ) then
                            table.insert(recipeOwners, profile.character);
                            break;
                        end
                    end
                end
            end
        end
        self:SelectProfile(currentProfile);
    end

    return recipeOwners;
end

function Armory:GetRecipeOwnersByName(name, link)
    table.wipe(recipeOwners);

    if ( name and self:HasTradeSkills() and self:GetConfigShowRecipeKnown() ) then
        local skill, name = name:match("^(.-): (.+)$");
        if ( name and name ~= "" ) then
            local currentProfile = self:CurrentProfile();
            local skillName, skillType, dbEntry;
            local _, _, _, _, _, _, itemSubType = _G.GetItemInfo(link or name);
            local profession = itemSubType or skill;
 
            for _, profile in ipairs(self:Profiles()) do
                self:SelectProfile(profile);
                if ( profile.realm == self.playerRealm ) then
                    dbEntry = self.selectedDbBaseEntry;
                    for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                        skillName, skillType = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                        if ( skillType ~= "header" and strlower(skillName) == strlower(strtrim(name)) ) then
                            table.insert(recipeOwners, profile.character);
                            break;
                        end
                    end
                end
            end
            self:SelectProfile(currentProfile);
        end
    end

    return recipeOwners;
end

local cooldowns = {};
function Armory:GetTradeSkillCooldowns()
    table.wipe(cooldowns);

    if ( self:HasTradeSkills() ) then
        local dbEntry = self.playerDbBaseEntry;
        local professions = dbEntry:GetValue(container);
        if ( professions ) then
            local _, month, day, year = CalendarGetDate();
            local today = self:MakeDate(day, month, year);
            local cooldown, timestamp, skillName, id;
            
            for profession in pairs(professions) do
                for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                    id = dbEntry:GetValue(container, profession, itemContainer, i, "Data"); 
                    cooldown, timestamp = dbEntry:GetValue(container, profession, id, "Cooldown");
                    if ( cooldown ) then
                        cooldown = self:MinutesTime(cooldown + timestamp);
                        if ( cooldown >= today ) then
                            skillName = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                            table.insert(cooldowns, {skill=skillName, time=cooldown});
                        end
                    end
                end
            end
        end
    end

    return cooldowns;
end

local crafters = {};
function Armory:GetCrafters(itemId)
    table.wipe(crafters);

    if ( itemId and self:HasTradeSkills() and self:GetConfigShowCrafters() ) then
        local currentProfile = self:CurrentProfile();
        local dbEntry, buildCache, found, id;

        for _, profile in ipairs(self:Profiles()) do
            if ( profile.realm == self.playerRealm ) then
                self:SelectProfile(profile);
                dbEntry = self.selectedDbBaseEntry;
                if ( dbEntry:Contains(container) ) then
                    found = false;

                    for profession in pairs(dbEntry:GetValue(container)) do
                        if ( not ItemCacheExists(dbEntry, profession) ) then
                            for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                                id = dbEntry:GetValue(container, profession, itemContainer, i, "Data");
                                link = dbEntry:GetValue(container, profession, id, "ItemLink");
                                SetItemCache(dbEntry, profession, link);
                                if ( itemId == self:GetItemId(link) ) then
                                    table.insert(crafters, profile.character);
                                    if ( self:GetConfigUseEncoding() ) then
                                        found = true;
                                        break;
                                    end
                                end
                            end
                            if ( found ) then
                                break;
                            end
                        elseif ( ItemIsCached(dbEntry, profession, itemId) ) then
                            table.insert(crafters, profile.character);
                        end
                    end
                end
            end            
        end
        self:SelectProfile(currentProfile);
    end

    return crafters;
end