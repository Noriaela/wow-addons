--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 310 2010-08-20T17:28:21Z
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

function ArmoryOptionsPanel_OnLoad(self)
    self.okay = ArmoryOptionsPanel_Okay;
    self.cancel = ArmoryOptionsPanel_Cancel;
    self.default = ArmoryOptionsPanel_Default;
    self.refresh = ArmoryOptionsPanel_Refresh;

    InterfaceOptions_AddCategory(self);

    for i, control in next, self.controls do
        if ( control.text ) then
            _G[control:GetName() .. "Text"]:SetText(Armory:Proper(control.text));
        end
    end
end

function ArmoryOptionsPanel_Okay(self)
    for _, control in next, self.controls do
        if ( control.onOkay ) then
            control.onOkay(control);
        end
        control.init = nil;
    end
end

function ArmoryOptionsPanel_Cancel(self)
    for _, control in next, self.controls do
        if ( control.value ~= control.currValue ) then
            control:SetValue(control.currValue);
        end
        if ( control.currColor and control.colorSet ) then
            control.colorSet(GetTableColor(control.currColor));
        end
        if ( control.onCancel ) then
            control.onCancel(control);
        end
        control.init = nil;
    end
end

function ArmoryOptionsPanel_Default(self)
    for _, control in next, self.controls do
        if ( control:GetValue() ~= control.defaultValue ) then
            control:SetValue(control.defaultValue);
        end
        if ( control.colorGet and control.colorSet ) then
            control.colorSet(control.colorGet(true));
        end
    end
end

function ArmoryOptionsPanel_Refresh(self)
    for _, control in next, self.controls do
        if ( control.GetValue ) then
            if ( control.type == CONTROLTYPE_SLIDER ) then
                control.value = control.getFunc();
                control:SetValue(control.value);
            else
                control.value = control:GetValue();
            end

            if ( not control.init ) then
                control.currValue = control.value;
            end
            control.disabled = control.disabledFunc();
            if ( control.type == CONTROLTYPE_CHECKBOX ) then

                if ( not control.invert ) then
                    control:SetChecked(control.value);
                else
                    control:SetChecked(not control.value);
                end
    
                ArmoryOptionsPanel_RefreshDependentControls(control);

                if ( control.disabled ) then
                    BlizzardOptionsPanel_CheckButton_Disable(control);
                elseif ( not control.dependency ) then 
                    BlizzardOptionsPanel_CheckButton_Enable(control, 1);
                end

            elseif ( control.type == CONTROLTYPE_SLIDER ) then

                if ( control.disabled ) then
                    BlizzardOptionsPanel_Slider_Disable(control);
                else
                    BlizzardOptionsPanel_Slider_Enable(control);
                end

            end
            
            if ( control.colorGet ) then
                local frame = control:GetParent();
                local swatch = _G[frame:GetName().."ColorSwatch"];
                
                frame.r, frame.g, frame.b = control.colorGet();
                swatch:GetNormalTexture():SetVertexColor(control.colorGet());

                if ( not control.init ) then
                    control.currColor = {};
                    SetTableColor(control.currColor, control.colorGet());
                end
                
                if ( not control.dependency ) then
                    ArmoryOptionsPanel_EnableSwatch(swatch, not control.disabled);
                end
            end

            control.init = true;
        end
    end
end

function ArmoryOptionsPanel_CheckButton_OnClick(checkButton)
    local setting = false;
    if ( checkButton:GetChecked() ) then
        if ( not checkButton.invert ) then
            setting = true;
        end
    elseif ( checkButton.invert ) then
        setting = true;
    end 

    checkButton:SetValue(setting);

    ArmoryOptionsPanel_RefreshDependentControls(checkButton);
end

function ArmoryOptionsPanel_DefaultSearchTypeDropDown_OnEvent(self, event, ...)
    if ( event == "PLAYER_ENTERING_WORLD" ) then
        self.defaultValue = ARMORY_CMD_FIND_ITEM;
        self.oldValue = Armory:GetConfigDefaultSearch();
        self.value = self.oldValue or self.defaultValue;
        self.tooltip = ARMORY_CMD_SET_DEFAULTSEARCH_TOOLTIP;

        ArmoryDropDownMenu_SetWidth(self, 90);
        ArmoryDropDownMenu_Initialize(self, ArmoryOptionsPanel_DefaultSearchTypeDropDown_Initialize);
        ArmoryDropDownMenu_SetSelectedValue(self, self.value);

        self.SetValue = 
            function (self, value)
                self.value = value;
                ArmoryDropDownMenu_SetSelectedValue(self, value);
                Armory:SetConfigDefaultSearch(value);
            end
        self.GetValue =
            function (self)
                return ArmoryDropDownMenu_GetSelectedValue(self);
            end
        self.RefreshValue =
            function (self)
                ArmoryDropDownMenu_Initialize(self, ArmoryOptionsPanel_DefaultSearchTypeDropDown_Initialize);
                ArmoryDropDownMenu_SetSelectedValue(self, self.value);
            end

        ArmoryOptionsFindPanelDefaultSearchTypeDropDownLabel:SetText(Armory:Proper(ARMORY_CMD_SET_DEFAULTSEARCH_TEXT));

        self:UnregisterEvent(event);
    end
end

function ArmoryOptionsPanel_DefaultSearchTypeDropDown_OnClick(self)
	ArmoryOptionsFindPanelDefaultSearchTypeDropDown:SetValue(self.value);
end

function ArmoryOptionsPanel_DefaultSearchTypeDropDown_Initialize()
    ArmoryFindType_CreateButtons(ArmoryOptionsPanel_DefaultSearchTypeDropDown_OnClick);
end

function ArmoryOptionsPanel_RegisterControl(control, parentFrame)
    local entry;

    if ( control.label ) then
        entry = Armory.options[control.label];

        if ( control.type == CONTROLTYPE_CHECKBOX ) then    

            control.text = _G[control.label.."_TEXT"];
            control.tooltipText = _G[control.label.."_TOOLTIP"];
            control.setFunc = entry.set;
            control.GetValue = entry.get;
            control.SetValue = function(self, value) self.value = value; if ( self.setFunc ) then self.setFunc(self.value) end end;

        elseif ( control.type == CONTROLTYPE_SLIDER ) then

            control.text = _G[control.label.."_TEXT"];
            control.tooltipText = _G[control.label.."_TOOLTIP"];
            control.setFunc = entry.set;
            control.getFunc = entry.get;
            control.minValue = entry.minValue;
            control.maxValue = entry.maxValue;
            control:SetMinMaxValues(entry.minValue, entry.maxValue);
            control:SetValueStep(entry.valueStep);
            control.SetDisplayValue = control.SetValue;
            control.SetValue = function(self, value) self:SetDisplayValue(value); self.value = value; self.setFunc(value); end;

        end

        control.defaultValue = control.defaultValue or entry.default;
        control.disabledFunc = entry.disabled or function() end;
    else
        control.disabledFunc = function() end;
    end
    
    local parent = control:GetParent();
    local swatch = _G[parent:GetName().."ColorSwatch"];
    if ( swatch ) then
        swatch.control = control;
    end

    parentFrame.controls = parentFrame.controls or {};
    table.insert(parentFrame.controls, control);    
end

function ArmoryOptionsPanel_SetupDependentControl(dependency, control, invert)
    if ( not dependency ) then
       return;
    end

    control = control or this;
    control.dependentInvert = invert;
    control.dependency = dependency;

    dependency.dependentControls = dependency.dependentControls or {};
    table.insert(dependency.dependentControls, control);

    if ( control.type == CONTROLTYPE_SLIDER ) then
        control.Disable = BlizzardOptionsPanel_Slider_Disable;
        control.Enable = BlizzardOptionsPanel_Slider_Enable;
    elseif ( control.type == CONTROLTYPE_DROPDOWN ) then
        control.Disable = function (self) ArmoryDropDownMenu_DisableDropDown(self) end;
        control.Enable = function (self) ArmoryDropDownMenu_EnableDropDown(self) end;
    else
        control.oldDisable = control.Disable;
        control.oldEnable = control.Enable;
        control.Disable = function (self) self.oldDisable(self); _G[self:GetName().."Text"]:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b) end;
        control.Enable = function (self) self.oldEnable(self); _G[self:GetName().."Text"]:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b) end;
    end
end

function ArmoryOptionsPanel_RefreshDependentControls(checkButton)
    if ( checkButton.dependentControls ) then
        for _, control in next, checkButton.dependentControls do
            ArmoryOptionsPanel_EnableDependentControl(control, checkButton:GetChecked())
        end
    end
end

function ArmoryOptionsPanel_EnableDependentControl(control, enable)
    if ( control.dependency.disabled ) then
        control:Disable();
    elseif ( enable ) then
        if ( control.dependentInvert ) then
            control:Disable();
        else
            control:Enable();
        end
    else
        if ( control.dependentInvert ) then
            control:Enable();
        else
            control:Disable();
        end
    end
    
    local parent = control:GetParent();
    local swatch = _G[parent:GetName().."ColorSwatch"];
    if ( swatch ) then
        ArmoryOptionsPanel_EnableSwatch(swatch, control:IsEnabled() == 1);
    end
end

function ArmoryOptionsPanel_EnableSwatch(swatch, enable)
    local parent = swatch:GetParent();
    if ( enable ) then
        swatch:Enable();
        _G[parent:GetName().."Text"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    else
        swatch:Disable();
        _G[parent:GetName().."Text"]:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
    end
end

function ArmoryOptionsPanel_OpenColorPicker(self)
    ArmoryOptionsPanel.colorPicker = self;
    ArmoryOptionsPanel.colorGet = self.control.colorGet;
    ArmoryOptionsPanel.colorSet = self.control.colorSet;

    local frame = self:GetParent();
    local info = UIDropDownMenu_CreateInfo();

    info.r, info.g, info.b = self.control.colorGet();
    info.swatchFunc = function() 
        ArmoryOptionsPanel.colorSet(ColorPickerFrame:GetColorRGB());
        ArmoryOptionsPanel.colorPicker:GetNormalTexture():SetVertexColor(ColorPickerFrame:GetColorRGB());
    end;
    info.cancelFunc = function()
        ArmoryOptionsPanel.colorSet(ColorPicker_GetPreviousValues());
        ArmoryOptionsPanel.colorPicker:GetNormalTexture():SetVertexColor(ColorPicker_GetPreviousValues());
    end;

    OpenColorPicker(info);
end

function ArmoryOptionsPanel_ApplyEncoding(control)
    if ( control.value ~= control.currValue ) then
        Armory:ConvertDb();
    end
end

function ArmoryOptionsPanel_CheckModule(control, module)
    if ( control.value == control.currValue ) then
        return;
    
    elseif ( control.value ) then
        if ( module == "Inventory" ) then
            for i = 1, #ArmoryInventoryContainers do
                Armory:SetContainer(ArmoryInventoryContainers[i]);
            end

        elseif ( module == "Mounts" ) then
            Armory:SetContainer(ARMORY_MOUNT_CONTAINER);

        elseif ( module == "Companions" ) then
            Armory:SetContainer(ARMORY_COMPANION_CONTAINER);

        elseif ( module == "QuestLog" ) then
            Armory:UpdateQuests();

        elseif ( module == "SpellBook" ) then
            Armory:SetSpells();
            Armory:UpdateGlyphs();
            
        elseif ( module == "Achievements" ) then
            Armory:UpdateAchievements();
            Armory:UpdateStatistics();
            
        elseif ( module == "Social" ) then
            Armory:UpdateFriends();
            Armory:UpdateEvents();
            
        elseif ( module == "Pets" ) then
            if ( HasPetUI() ) then
                ArmoryPetFrame_Update(1);
            end
            
        elseif ( module == "Talents" ) then
            Armory:SetTalents();
            if ( HasPetUI() ) then
                Armory:SetTalents(1);
            end

        elseif ( module == "PVP" ) then
            Armory:UpdateArenaTeams();
            
        elseif ( module == "Reputation" ) then
            Armory:UpdateFactions();
            
        elseif ( module == "Skills" ) then
            Armory:UpdateSkills();
            
        elseif ( module == "Raid" ) then
            Armory:UpdateInstances();
            
        elseif ( module == "Currency" ) then
            Armory:UpdateCurrency();
            
        elseif ( module == "Buffs" ) then
            Armory:SetBuffs("player");
            if ( HasPetUI() ) then
                Armory:SetBuffs("pet");
            end
        
        end
    else
        local currentProfile = Armory:CurrentProfile();
        for _, realm in ipairs(Armory:RealmList()) do
            if ( realm ~= ARMORY_LOOKUP_REALM_ALIAS ) then
                for _, character in ipairs(Armory:CharacterList(realm)) do
                    Armory:LoadProfile(realm, character);
                    
                    if ( module == "Inventory" ) then
                        Armory:ClearInventory();

                    elseif ( module == "Mounts" ) then
                        Armory:ClearInventory(ARMORY_MOUNT_CONTAINER);

                    elseif ( module == "Companions" ) then
                        Armory:ClearInventory(ARMORY_COMPANION_CONTAINER);

                    elseif ( module == "QuestLog" ) then
                        Armory:ClearQuests();
                        Armory:ClearQuestHistory();

                    elseif ( module == "SpellBook" ) then
                        Armory:ClearSpells();
                        Armory:ClearGlyphs();
                        
                    elseif ( module == "Achievements" ) then
                        Armory:ClearAchievements();
                        Armory:ClearStatistics();
                        
                    elseif ( module == "TradeSkills" ) then
                        Armory:ClearTradeSkills();
                        
                    elseif ( module == "Social" ) then
                        Armory:ClearFriends();
                        Armory:ClearEvents();
                        
                    elseif ( module == "Pets" ) then
                        Armory:ClearPets();
                        
                    elseif ( module == "Talents" ) then
                        Armory:ClearTalents();
                        local pets = Armory:GetPets();
                        for i = 1, #pets do
                            Armory:ClearTalents(pets[i]);
                        end

                    elseif ( module == "PVP" ) then
                        Armory:ClearArenaTeams();
                        
                    elseif ( module == "Reputation" ) then
                        Armory:ClearFactions();
                        
                    elseif ( module == "Skills" ) then
                        Armory:ClearSkills();
                        
                    elseif ( module == "Raid" ) then
                        Armory:ClearInstances();
                        
                    elseif ( module == "Currency" ) then
                        Armory:ClearCurrency();
                        
                    elseif ( module == "Buffs" ) then
                        Armory:ClearBuffs();
                        local pets = Armory:GetPets();
                        for i = 1, #pets do
                            Armory:ClearBuffs(pets[i]);
                        end
                        
                    end    
                end
            end
        end
        Armory:SelectProfile(currentProfile);
    end
    
    if ( ArmoryFrame:IsVisible() ) then
        ArmoryCloseChildWindows();
        Armory:Toggle();
    end
end

function ArmoryOptionsPanel_SetChannel(value)
    local _, name = Armory:GetConfigChannelName();
    if ( name ~= value ) then
        ArmoryAddonMessageFrame_UpdateChannel(true);
    end
    Armory:SetConfigChannelName(value);
    ArmoryAddonMessageFrame_UpdateChannel();
end