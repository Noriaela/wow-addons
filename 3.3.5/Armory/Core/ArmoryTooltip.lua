--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 271 2010-05-22T17:04:38Z
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

local tooltipHooks = {};
local tooltipLines = {};

----------------------------------------------------------
-- Tooltip Enhancement
----------------------------------------------------------

local function AddSpacer(tooltip)
    local lastLine = _G[tooltip:GetName().."TextLeft"..tooltip:NumLines()];
    if ( lastLine and strtrim(lastLine:GetText() or "") ~= "" ) then
        tooltip:AddLine(" ");
    end
    return 1;
end

local knownBy;
local function AddKnownBy(tooltip, spaceAdded)
    if ( knownBy and #knownBy > 0 ) then
        spaceAdded = spaceAdded or AddSpacer(tooltip);
        local r, g, b = Armory:GetConfigRecipeKnownColor();
        for i = 1, #knownBy do
            if ( i == 1 ) then
                tooltip:AddDoubleLine(USED, knownBy[i], r, g, b, r, g, b);
            else
                tooltip:AddDoubleLine(" ", knownBy[i], r, g, b, r, g, b);
            end
        end
    end
    return spaceAdded;
end

local currentItem, gemInfo, crafters, itemCount;
local function EnhanceItemTooltip(tooltip, id, link)
    local spaceAdded, name;
    
    if ( link ~= currentItem ) then
        currentItem = link;

        -- Need the fully qualified link
        name, link = tooltip:GetItem();
        
        gemInfo = nil;
        if ( Armory:GetConfigShowGems() ) then
            local numGems;
            gemInfo, numGems = Armory:GetSocketInfo(link);
            if ( numGems == 0 ) then
                gemInfo = nil;
            end
        end
        
        knownBy = Armory:GetRecipeOwnersByName(name, link);
        crafters = Armory:GetCrafters(id);
        itemCount = Armory:GetItemCount(link);
    end

    if ( gemInfo ) then
        AddSpacer(tooltip);
        for _, socket in ipairs(gemInfo) do
            if ( socket.link ) then
                tooltip:AddLine(Armory:GetColorFromLink(socket.link)..socket.gem..FONT_COLOR_CODE_CLOSE.." : "..(socket.gemColor or UNKNOWN));
                tooltip:AddTexture(socket.texture);
            end
        end
        spaceAdded = spaceAdded or AddSpacer(tooltip);
    end

    if ( itemCount and #itemCount > 0 ) then
        spaceAdded = spaceAdded or AddSpacer(tooltip);
        local count, bagCount, bankCount, mailCount, auctionCount, equipCount = 0, 0, 0, 0, 0, 0;
        local details;
        local r, g, b = Armory:GetConfigItemCountColor();
        for k, v in ipairs(itemCount) do
            if ( not v.currency ) then
                count = count + v.count;
            end
            bagCount = bagCount + (v.bags or 0);
            bankCount = bankCount + (v.bank or 0);
            mailCount = mailCount + (v.mail or 0);
            auctionCount = auctionCount + (v.auction or 0);
            equipCount = equipCount + (v.equipped or 0);
            details = v.details or Armory:GetCountDetails(v.bags, v.bank, v.mail, v.auction, nil, nil, v.equipped);
            tooltip:AddDoubleLine(format("%s [%d]", v.name, v.count), details, r, g, b, r, g, b);
        end

        if ( Armory:HasInventory() and count > 0 and Armory:GetConfigShowItemCountTotals() ) then
            r, g, b = Armory:GetConfigItemCountTotalsColor();
            local guildCount = count - bagCount - bankCount - mailCount - auctionCount - equipCount;
            details = Armory:GetCountDetails(bagCount, bankCount, mailCount, auctionCount, nil, guildCount, equipCount);
            tooltip:AddDoubleLine(format(ARMORY_TOTAL, count), details, r, g, b, r, g, b);
        end
    end

    if ( crafters and #crafters > 0 ) then
        spaceAdded = spaceAdded or AddSpacer(tooltip);
        local r, g, b = Armory:GetConfigCraftersColor();
        for i = 1, #crafters do
            if ( i == 1 ) then
                tooltip:AddDoubleLine(ARMORY_CRAFTABLE_BY, crafters[i], r, g, b, r, g, b);
            else
                tooltip:AddDoubleLine(" ", crafters[i], r, g, b, r, g, b);
            end
        end
    end

    spaceAdded = AddKnownBy(tooltip, spaceAdded);

    tooltip:Show();
end

local currentRecipe, reagents, reagentCount;
local function EnhanceRecipeTooltip(tooltip, id, link)
    local spaceAdded;
    
    if ( id ~= currentRecipe ) then
        currentRecipe = id;

        knownBy = Armory:GetRecipeOwners(id);

        reagentCount = nil;
        if ( Armory:HasInventory() and Armory:GetConfigShowItemCount() ) then
            reagents = Armory:GetReagentsFromTooltip(tooltip);
            if ( reagents ) then
                reagentCount = Armory:GetMultipleItemCount(reagents);
            end
        end
    end

    spaceAdded = AddKnownBy(tooltip, spaceAdded);

    if ( reagentCount and #reagentCount > 0 ) then
        local count, bags, bank, mail, auction, alts;
        local name, quantity, details;

        spaceAdded = spaceAdded or AddSpacer(tooltip);
        local r, g, b = Armory:GetConfigItemCountColor();
        for i = 1, #reagents do
            name, quantity = unpack(reagents[i]);
            count, bags, bank, mail, auction, alts = 0, 0, 0, 0, 0, 0;
            for _, v in ipairs(reagentCount[i]) do
                if ( v.mine ) then
                    bags = bags + (v.bags or 0);
                    bank = bank + (v.bank or 0);
                    mail = mail + (v.mail or 0);
                    auction = auction + (v.auction or 0);
                else
                    alts = alts + (v.bags or 0) + (v.bank or 0) + (v.mail or 0) + (v.auction or 0);
                end
                count = count + v.count;
            end
            details = Armory:GetCountDetails(bags, bank, mail, auction, alts, count - bags - bank - mail - auction - alts);
            tooltip:AddDoubleLine(name..format(" [%d/%d]", count, quantity), details, r, g, b, r, g, b);
        end
    end
    
    tooltip:Show();
end

local function EnhanceQuestTooltip(tooltip, id, link)
    if ( not (Armory:HasQuestLog() and Armory:GetConfigShowQuestAlts()) ) then
        return;
    end

    local currentProfile = Armory:CurrentProfile();

    table.wipe(tooltipLines);

    for _, profile in ipairs(Armory:Profiles()) do
        Armory:SelectProfile(profile);

        if ( profile.realm == Armory.playerRealm ) then
            if ( Armory:IsOnQuest(id) ) then
                table.insert(tooltipLines, profile.character);
            end
        end
    end
    Armory:SelectProfile(currentProfile);
    
    if ( #tooltipLines > 0 ) then
        AddSpacer(tooltip);
        local r, g, b = Armory:GetConfigQuestAltsColor();
        tooltip:AddLine(ARMORY_QUEST_TOOLTIP_LABEL);
        tooltip:AddLine(table.concat(tooltipLines, ", "), r, g, b, true);
        tooltip:Show();
    end
end

local function EnhanceAchievementTooltip(tooltip, id, link)
    if ( not (Armory:HasAchievements() and Armory:GetConfigShowAchievements()) ) then
        return;
    end

    local currentProfile = Armory:CurrentProfile();
    local completed, dateCompleted, quantity, reqQuantity, progress;

    local tooltipText = Armory:GetTextFromLink(link);
    local inProgressColor = Armory:HexColor(Armory:GetConfigAchievementInProgressColor());

    table.wipe(tooltipLines);
    
    for _, profile in ipairs(Armory:Profiles()) do
        Armory:SelectProfile(profile);
        if ( profile.realm == Armory.playerRealm ) then
            completed, dateCompleted, quantity, reqQuantity = Armory:GetAchievement(id);
            if ( dateCompleted ) then
                progress = format(ACHIEVEMENT_TOOLTIP_COMPLETE, profile.character, date("%m", dateCompleted), date("%d", dateCompleted), date("%y", dateCompleted));
            elseif ( quantity or reqQuantity ) then
                progress = format(ACHIEVEMENT_TOOLTIP_IN_PROGRESS, profile.character);
                if ( (reqQuantity or 0) > 0 ) then
                    progress = progress..format(" (%d%% [%d/%d])", ceil((quantity * 100) / reqQuantity), quantity, reqQuantity);
                end
                if ( Armory:GetConfigUseInProgressColor() ) then
                    progress = inProgressColor..progress..FONT_COLOR_CODE_CLOSE;
                end
            else
                progress = nil;
            end

            if ( progress and not tooltipText:find(progress) ) then
                table.insert(tooltipLines, progress);
            end
        end
    end
    Armory:SelectProfile(currentProfile);

    if ( #tooltipLines > 0 ) then
        AddSpacer(tooltip);
        local r, g, b = Armory:GetConfigAchievementsColor();
        for i = 1, #tooltipLines do
            tooltip:AddLine(tooltipLines[i], r, g, b);
        end
        tooltip:Show();
    end
end

----------------------------------------------------------
-- Tooltip Internals
----------------------------------------------------------

local function ExecuteHook(tooltip, hook, link)
    local idType, id = Armory:GetLinkId(link);
    if ( hook.idType == idType and hook.id == id ) then
        return;
    end

    hook.idType = idType;
    hook.id = id;

    if ( hook.hooks[idType] and id ) then
        for _, v in ipairs(hook.hooks[idType]) do
            v[1](tooltip, id, link);
        end
    end
end

local function RegisterTooltipHook(tooltip, idType, hook, reset)
    if ( not tooltip ) then
        return;
    elseif ( not tooltipHooks[tooltip] ) then
        tooltipHooks[tooltip] = {};
        tooltipHooks[tooltip].hooks = {};
        tooltipHooks[tooltip].setTradeSkillItem = tooltip.SetTradeSkillItem;
        tooltipHooks[tooltip].setHyperlink = tooltip.SetHyperlink;
        tooltipHooks[tooltip].onSetItem = tooltip:GetScript("OnTooltipSetItem");
        tooltipHooks[tooltip].onCleared = tooltip:GetScript("OnTooltipCleared");

        tooltip.SetTradeSkillItem = function(self, index, ...)
            local hook = tooltipHooks[self];
            if ( index and pcall(hook.setTradeSkillItem, self, index, ...) and not self:GetItem() ) then
                ExecuteHook(self, hook, _G.GetTradeSkillItemLink(index));
            end
        end;

        tooltip.SetHyperlink = function(self, link, ...)
            local hook = tooltipHooks[self];
            pcall(hook.setHyperlink, self, link, ...);
            ExecuteHook(self, hook, link);
        end
        
        tooltip:SetScript("OnTooltipSetItem", function(self, ...)
            local hook = tooltipHooks[self];
            local _, link = self:GetItem();
            if ( hook.onSetItem ) then
                pcall(hook.onSetItem, self, ...);
            end
            ExecuteHook(self, hook, link);
        end);

        tooltip:SetScript("OnTooltipCleared", function(self, ...)
            local hook = tooltipHooks[self];
            local idType = hook.idType;
            if ( hook.onCleared ) then
                pcall(hook.onCleared, self, ...);
            end

            if ( idType and hook.hooks[idType] ) then
                for _, v in ipairs(hook.hooks[idType]) do
                    if ( v[2] ) then
                        v[2](self);
                    end
                end
            end
            
            hook.idType = nil;
            hook.id = nil;
        end);
    end
    if ( not tooltipHooks[tooltip].hooks[idType] ) then
        tooltipHooks[tooltip].hooks[idType] = {};
    end
    table.insert(tooltipHooks[tooltip].hooks[idType], {hook, reset});
end

----------------------------------------------------------
-- Tooltip Functions
----------------------------------------------------------

function Armory:RegisterTooltipHooks(tooltip)
    RegisterTooltipHook(tooltip, "item", EnhanceItemTooltip);
    RegisterTooltipHook(tooltip, "enchant", EnhanceRecipeTooltip);
    RegisterTooltipHook(tooltip, "quest", EnhanceQuestTooltip);
    RegisterTooltipHook(tooltip, "achievement", EnhanceAchievementTooltip);
end

function Armory:ResetTooltipItemHook()
    currentItem = nil; 
end

local sides = {"Left", "Right"};
function Armory:Tooltip2String(tooltip)
    local name = tooltip:GetName();
    local text = "";
    local fontString;

    for i = 1, tooltip:NumLines() do
        for _, side in ipairs(sides) do
            fontString = _G[name.."Text"..side..i];
            if ( fontString and fontString:IsShown() ) then
                text = text..fontString:GetText().."\n";
            end
        end
    end

    return text;
end

function Armory:Tooltip2Table(tooltip, all)
    local name = tooltip:GetName();
    local lines = {};
    local textLeft, textRight, icon, relativeTo, line;

    local getLine = function(fontString)
            if ( fontString ) then
                local text = fontString:GetText();
                if ( text and strtrim(text) ~= "" ) then
                    return self:Text2String(text, fontString:GetTextColor());
                end
            end
            return "";
        end

    for i = 1, tooltip:NumLines() do
        textLeft = _G[name.."TextLeft"..i];
        if ( textLeft and textLeft:IsShown() ) then
            lines[i] = getLine(textLeft);
        else
            lines[i] = "";
        end
        textRight = _G[name.."TextRight"..i];
        if ( textRight and textRight:IsShown() ) then
            lines[i] = lines[i]..ARMORY_TOOLTIP_COLUMN_SEPARATOR..getLine(textRight);
        end

        if ( not all and lines[i] == "" ) then
            table.remove(lines, i);
            break;
        end
    end

    for i = 1, 10 do
        icon = _G[name.."Texture"..i];
        if ( icon and icon:IsShown() ) then
            _, relativeTo = icon:GetPoint();
            line = tonumber(relativeTo:GetName():match("(%d+)$"));
            if ( line > 0 and line <= #lines ) then
                lines[line] = lines[line]..ARMORY_TOOLTIP_TEXTURE_SEPARATOR..icon:GetTexture();
            end
        else
            break;
        end
    end

    return lines;
end

function Armory:Table2Tooltip(tooltip, t, firstWrap)
    local line, texture, left, right, textLeft, textRight;
    local leftR, leftG, leftB, rightR, rightG, rightB;

    tooltip:ClearLines();
    for i = 1, #t do
        line, texture = strsplit(ARMORY_TOOLTIP_TEXTURE_SEPARATOR, t[i]);
        if ( line ) then
            left, right = strsplit(ARMORY_TOOLTIP_COLUMN_SEPARATOR, line);
            if ( left ) then
                leftR, leftG, leftB, textLeft = self:String2Text(left);
                if ( right ) then
                    rightR, rightG, rightB, textRight = self:String2Text(right);
                    tooltip:AddDoubleLine(textLeft, textRight, leftR, leftG, leftB, rightR, rightG, rightB);
                elseif ( (textLeft or "") == "" ) then
                    tooltip:AddLine(" ");
                else
                    tooltip:AddLine(textLeft, leftR, leftG, leftB, not texture and i >= (firstWrap or 3));
                end
            end
            if ( texture ) then
                tooltip:AddTexture(texture);
            end
        end
    end
end

function Armory:PrepareTooltip()
    local timestamp = time();
    if ( not self.tooltip ) then
        self.tooltip = CreateFrame("GameTooltip", "ArmoryTooltip", UIParent, "GameTooltipTemplate");
    end
    while ( self:IsLocked(self.tooltip:GetName()) and time() - timestamp < 10 ) do end
    self:Lock(self.tooltip:GetName());
    self.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    self.tooltip:ClearLines();
end

function Armory:ReleaseTooltip()
    self:Unlock(self.tooltip:GetName());
end

function Armory:TooltipAddHints(tooltip, ...)
    for i = 1, select("#", ...) do
        tooltip:AddLine(select(i, ...), GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, 1);
    end
end