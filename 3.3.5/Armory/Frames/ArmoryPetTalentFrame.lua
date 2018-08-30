--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 72 2009-09-27T22:31:40Z
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

function ArmoryPetTalentFrameTalent_OnClick(self)
    ArmoryTalentFrameTalent_Click(ArmoryPetTalentFrame, self:GetID());
end

function ArmoryPetTalentFrameTalent_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    ArmoryTalentFrameTalent_Enter(ArmoryPetTalentFrame, self:GetID());
end

function ArmoryPetTalentFrame_OnLoad(self)
    self:RegisterEvent("SPELLS_CHANGED");
    self.pet = true;
    self.selectedTab = 1;
    self.updateFunc = ArmoryPetTalentFrame_Update;
    self.talentGroup = 1;

    ArmoryTalentFrame_Load(self);

    local button;
    for i=1, MAX_NUM_TALENTS do
        button = _G["ArmoryPetTalentFrameTalent"..i];
        if ( button ) then
            button.talentButton_OnClick = ArmoryPetTalentFrameTalent_OnClick;
            button.talentButton_OnEnter = ArmoryPetTalentFrameTalent_OnEnter;
        end
    end
end

function ArmoryPetTalentFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    end
    
    local _, isHunterPet = HasPetUI();
    if ( isHunterPet ) then
        ArmoryTalentFrame_ConditionalUpdate(ArmoryPetTalentFrame);
    end
end

function ArmoryPetTalentFrame_OnShow(self)
    Armory:SetTalents(true);
    ArmoryPetTalentFrame_Update();
end

function ArmoryPetTalentFrame_Update()
    local name, iconTexture, pointsSpent = Armory:GetTalentTabInfo(1, false, true, ArmoryPetTalentFrame.talentGroup);

    if ( name ) then
        ArmoryPetTalentFrameSpentPoints:SetText(format(MASTERY_POINTS_SPENT, name, HIGHLIGHT_FONT_COLOR_CODE..pointsSpent..FONT_COLOR_CODE_CLOSE));
        ArmoryPetTalentFrameSpentPoints:Show();
    else
        ArmoryPetTalentFrameSpentPoints:Hide();
    end
    ArmoryPetTalentFrame.pointsSpent = pointsSpent or 0;

    ArmoryTalentFrame_UpdateFrame(ArmoryPetTalentFrame);
end


