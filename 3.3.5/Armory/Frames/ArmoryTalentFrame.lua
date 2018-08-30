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

ARMORY_MAX_TALENT_SPECTABS = 2;

local tabWidthCache = {};

function ArmoryTalentFrameTalent_OnClick(self)
    ArmoryTalentFrameTalent_Click(ArmoryTalentFrame, self:GetID());
end

function ArmoryTalentFrameTalent_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    ArmoryTalentFrameTalent_Enter(ArmoryTalentFrame, self:GetID());
end

function ArmoryTalentFrameTab_OnClick(self)
    PanelTemplates_SetTab(ArmoryTalentFrame, self:GetID());
    ArmoryTalentFrame_Update();
end

function ArmoryTalentFrame_OnLoad(self)
    PanelTemplates_SetNumTabs(self, 3);
    PanelTemplates_SetTab(self, 1);
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("CHARACTER_POINTS_CHANGED");
    self:RegisterEvent("SPELLS_CHANGED");
    self.pet = false;
    self.talentGroup = 1;
    self.selectedTab = 1;
    self.updateFunc = ArmoryTalentFrame_Update;
    
    ArmoryTalentFrame_Load(self);
    
    local button;
    for i=1, MAX_NUM_TALENTS do
        button = _G["ArmoryTalentFrameTalent"..i];
        if ( button ) then
            button.talentButton_OnClick = ArmoryTalentFrameTalent_OnClick;
            button.talentButton_OnEnter = ArmoryTalentFrameTalent_OnEnter;
        end
    end
end

function ArmoryTalentFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        self.talentGroup = Armory:GetActiveTalentGroup();
    end
    ArmoryTalentFrame_ConditionalUpdate(ArmoryTalentFrame);
end

function ArmoryTalentFrame_OnShow(self)
    PanelTemplates_SetTab(self, 1);
    Armory:SetTalents(false);
    
    local hasMultipleTalentGroups = Armory:GetNumTalentGroups() > 1;
    local tab, activeTab;
    self.talentGroup = Armory:GetActiveTalentGroup();
    for i = 1, ARMORY_MAX_TALENT_SPECTABS do
        tab = _G["ArmoryPlayerSpecTab" .. i];
        if ( i == self.talentGroup ) then
            activeTab = tab;
        end
        if ( hasMultipleTalentGroups and i <= Armory:GetNumTalentGroups() ) then
            local primaryTabIndex, iconTexture = ArmoryTalentFrame_GetSpecInfo(tab:GetID());
            tab:GetNormalTexture():SetTexture(iconTexture);
            tab:Show();
        else
            tab:Hide();
        end
    end

    ArmoryPlayerSpecTab_OnClick(activeTab);
end

function ArmoryTalentFrame_Update()
    ArmoryTalentFrame.selectedTab = PanelTemplates_GetSelectedTab(ArmoryTalentFrame);
    
    -- Setup Tabs
    local tab, name, iconTexture, pointsSpent, button;
    local numTabs = Armory:GetNumTalentTabs(false, false);
    local totalTabWidth = 0;

    for i = 1, MAX_TALENT_TABS do
        tabWidthCache[i] = 0;
        tab = _G["ArmoryTalentFrameTab" .. i];
        if ( i <= numTabs ) then
            name, iconTexture, pointsSpent, background, previewPointsSpent = Armory:GetTalentTabInfo(i, false, false, ArmoryTalentFrame.talentGroup);
            if ( i == PanelTemplates_GetSelectedTab(ArmoryTalentFrame) ) then
                -- If tab is the selected tab set the points spent info
                --TalentFrameSpentPoints:SetText(format(MASTERY_POINTS_SPENT, name).." "..HIGHLIGHT_FONT_COLOR_CODE..pointsSpent..FONT_COLOR_CODE_CLOSE);
                ArmoryTalentFrame.pointsSpent = pointsSpent;
            end
            tab:SetText(name);
            PanelTemplates_TabResize(tab, 0);
            tab.textWidth = tab:GetTextWidth();
            tabWidthCache[i] = PanelTemplates_GetTabWidth(tab);
            totalTabWidth = totalTabWidth + tabWidthCache[i];
            tab:Show();
        else
            tab:Hide();
            tab.textWidth = 0;
        end
    end
    ArmoryFrame_CheckTabBounds("ArmoryTalentFrameTab", totalTabWidth, 285, tabWidthCache);

    PanelTemplates_SetNumTabs(ArmoryTalentFrame, numTabs);
    PanelTemplates_UpdateTabs(ArmoryTalentFrame);

    ArmoryTalentFrame_UpdateFrame(ArmoryTalentFrame);
end

function ArmoryPlayerSpecTab_OnClick(self)
    for i = 1, ARMORY_MAX_TALENT_SPECTABS do
        _G["ArmoryPlayerSpecTab" .. i]:SetChecked(nil);
    end
    self:SetChecked(1);

    ArmoryTalentFrame.talentGroup = self:GetID();

    local primaryTabIndex = ArmoryTalentFrame_GetSpecInfo(ArmoryTalentFrame.talentGroup);
    if ( primaryTabIndex > 0 ) then
        PanelTemplates_SetTab(ArmoryTalentFrame, primaryTabIndex);
    end
    
    ArmoryTalentFrame_Update();
     
    if ( ArmoryGlyphFrame:IsShown() ) then
        ArmoryGlyphFrame_OnShow(ArmoryGlyphFrame);
    end
end

function ArmoryPlayerSpecTab_OnEnter(self)
    if ( self.tooltip ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        -- name
        if ( Armory:GetNumTalentGroups(false, false) <= 1 ) then
            -- set the tooltip to be the unit's name
            GameTooltip:AddLine(Armory:UnitName("player"), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        else
            -- set the tooltip to be the spec name
            GameTooltip:AddLine(self.tooltip);
            if ( self:GetID() == Armory:GetActiveTalentGroup(false, false) ) then
                -- add text to indicate that this spec is active
                GameTooltip:AddLine(TALENT_ACTIVE_SPEC_STATUS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
            end
        end
        -- points spent
        local primaryTabIndex, _, talentPoints = ArmoryTalentFrame_GetSpecInfo(self:GetID());
        for index, info in ipairs(talentPoints) do
            if ( info.name ) then
                -- assign a special color to a tab that surpasses the max points spent threshold
                local pointsColor;
                if ( primaryTabIndex == index ) then
                    pointsColor = GREEN_FONT_COLOR;
                else
                    pointsColor = HIGHLIGHT_FONT_COLOR;
                end
                GameTooltip:AddDoubleLine(
                    info.name,
                    info.pointsSpent,
                    HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
                    pointsColor.r, pointsColor.g, pointsColor.b,
                    1
                );
            end
        end
        GameTooltip:Show();
    end
end
