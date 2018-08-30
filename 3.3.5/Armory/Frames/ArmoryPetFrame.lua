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

ARMORY_NUM_PET_SLOTS = 5;

StaticPopupDialogs["ARMORY_DELETE_PET"] = {
    text = ARMORY_DELETE_UNIT,
    button1 = YES,
    button2 = NO,
    OnAccept = function (self) Armory:DeletePet(Armory:GetCurrentPet()); end,
    OnCancel = function (self) Armory.selectedPet = ArmoryPetFrame.selectedPet; end,
    OnHide = function (self) ArmoryPetFrame_Update(1); end,
    timeout = 0,
    whileDead = 1,
    exclusive = 1,
    showAlert = 1,
    hideOnEscape = 1
};

function ArmoryPetFrameTab_OnClick(self)
    local id = self:GetID();

    PanelTemplates_SetTab(ArmoryPetFrame, id);
    PlaySound("igCharacterInfoTab");
    if ( id == 1 ) then
        ArmoryPetTalentFrame:Hide();
        ArmoryPetPaperDollFrame:Show();
    else
        ArmoryPetPaperDollFrame:Hide();
        ArmoryPetTalentFrame:Show();
    end
end

function ArmoryPetSlot_OnClick(self, button)
    local pets = Armory:GetPets();
    if ( pets[self:GetID()] ) then
        for i = 1, ARMORY_NUM_PET_SLOTS do
            _G["ArmoryPetFramePet"..i]:SetChecked(false);
        end
        self:SetChecked(true);
        Armory.selectedPet = pets[self:GetID()];
        if ( button == "RightButton" ) then
            StaticPopup_Show("ARMORY_DELETE_PET", Armory:GetCurrentPet());
        else
            ArmoryPetFrame_Update(1);
        end
    end
end

function ArmoryPetFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PET_UI_UPDATE");
    self:RegisterEvent("PET_BAR_UPDATE");
    self:RegisterEvent("PET_UI_CLOSE");
    self:RegisterEvent("UNIT_PET");
    self:RegisterEvent("PET_TALENT_POINTS_CHANGED");

    PanelTemplates_SetNumTabs(self, 2);
    PanelTemplates_SetTab(self, 1);
end

function ArmoryPetFrame_OnEvent(self, event, ...)
    local arg1 = ...;
    
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( HasPetUI() ) then
            Armory:Execute(ArmoryPetFrame_Update);
        end
    elseif ( event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") ) then
        ArmoryFrameTab_Update();
        Armory:Execute(ArmoryPetFrame_Update);
    elseif ( event == "PET_UI_CLOSE" ) then
        ArmoryFrameTab_Update();
    elseif ( event == "PET_TALENT_POINTS_CHANGED" ) then
        Armory:Execute(ArmoryPetFrame_Update);
    end
end

function ArmoryPetFrame_OnShow(self)
    ArmoryNameText:Hide();
    ArmoryPetNameText:Show();
    ArmoryPetFrame_Update();

    if ( PanelTemplates_GetSelectedTab(ArmoryPetFrame) == 1 ) then
        ArmoryPetTalentFrame:Hide();
        ArmoryPetPaperDollFrame:Show();
    else
        ArmoryPetPaperDollFrame:Hide();
        ArmoryPetTalentFrame:Show();
    end
end

function ArmoryPetFrame_OnHide(self)
    ArmoryNameText:Show();
    ArmoryPetNameText:Hide();
end

function ArmoryPetFrame_Update(petChanged)
    if ( (not Armory:PetsEnabled() or petChanged) and ArmorySpellBookFrame:IsShown() ) then
        ArmorySpellBookFrame:Hide();
        ArmorySpellBookFrame:Show();
    end

    local currentPet = Armory:GetCurrentPet();
    if ( not Armory:PetsEnabled() or (currentPet == UNKNOWN and not HasPetUI()) ) then
        ArmoryFrameTab_Update(); 
        return;
    end
    ArmoryPetNameText:SetText(currentPet);

    local button, background, icon;
    local pets = Armory:GetPets();
    for i = 1, ARMORY_NUM_PET_SLOTS do
        button = _G["ArmoryPetFramePet"..i];
        background = _G["ArmoryPetFramePet"..i.."Background"];
        if ( i <= #pets ) then
            Armory.selectedPet = pets[i];
            background:SetVertexColor(1.0, 1.0, 1.0);
            button:Enable();
            icon = Armory:GetPetIcon();
            SetItemButtonTexture(button, icon);
            if ( icon ) then
                button.tooltip = Armory.selectedPet;
                button.tooltipSubtext = format(UNIT_TYPE_LEVEL_TEMPLATE, Armory:UnitLevel("pet"), Armory:UnitCreatureFamily("pet"));
                button.hint = ARMORY_DELETE_UNIT_HINT;
            else
                button.tooltip = nil;
                button.tooltipSubtext = "";
                button.hint = nil;
            end
            button:SetChecked(Armory.selectedPet == currentPet and icon);
        else
            SetItemButtonTexture(button, "");
            background:SetVertexColor(1.0,0.1,0.1);
            button:SetChecked(false);
            button:Disable();
        end
    end
    Armory.selectedPet = currentPet;
    ArmoryPetFrame.selectedPet = currentPet;

    local _, canGainXP = Armory:HasPetUI();

    if ( canGainXP and Armory:HasTalents(true) ) then
        ArmoryPetFrameTab1:Show();
        ArmoryPetFrameTab2:Show();
        ArmoryPetTalentPointText:SetText(Armory:GetUnspentTalentPoints(false, true, Armory:GetActiveTalentGroup(false, true)));
        ArmoryPetTalentPointText:Show();
        ArmoryPetTalentPointLabel:Show();
        
        for i = 1, 2 do
            if ( i == PanelTemplates_GetSelectedTab(ArmoryPetFrame) ) then
                PanelTemplates_SelectTab(_G["ArmoryPetFrameTab"..i]);
            else
                PanelTemplates_DeselectTab(_G["ArmoryPetFrameTab"..i]);
            end
	    end
    else
        PanelTemplates_SetTab(ArmoryPetFrame, 1);
        ArmoryPetFrameTab1:Hide();
        ArmoryPetFrameTab2:Hide();
        ArmoryPetTalentPointText:Hide();
        ArmoryPetTalentPointLabel:Hide();
    end
    
    ArmoryPetPaperDollFrame_Update();
    ArmoryPetTalentFrame_Update();
end
