--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 314 2010-08-30T19:38:57Z
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

ARMORY_MAX_RAID_INFOS = 20;
ARMORY_MAX_RAID_INFOS_DISPLAYED = 9;

function ArmoryRaidInfoFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UPDATE_INSTANCE_INFO");
end

function ArmoryRaidInfoFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        RequestRaidInfo();
    elseif ( event == "UPDATE_INSTANCE_INFO" ) then
        Armory:Execute(ArmoryRaidInfoFrame_UpdateInfo);
    end
end

function ArmoryRaidInfoScrollFrame_OnLoad(self)
	HybridScrollFrame_OnLoad(self);
	self.update = ArmoryRaidInfoFrame_Update;
	HybridScrollFrame_CreateButtons(self, "ArmoryRaidInfoInstanceTemplate");
end

function ArmoryRaidInfoFrame_OnShow(self)
    ArmoryRaidInfoFrame_Update();
end

function ArmoryRaidInfoFrame_Update(scrollToSelected)
    if ( Armory:UpdateInstancesInProgress() ) then
        return;
    end
    ArmoryRaidInfoFrame_UpdateSelectedIndex();

    local scrollFrame = ArmoryRaidInfoScrollFrame;
    local savedInstances = Armory:GetNumSavedInstances();
    local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName;
    local frameName, frameNameText, frameID, frameReset, width;
    local offset = HybridScrollFrame_GetOffset(scrollFrame);
    local buttons = scrollFrame.buttons;
    local numButtons = #buttons;
    local buttonHeight = buttons[1]:GetHeight();

    if ( scrollToSelected == true and ArmoryRaidInfoFrame.selectedIndex ) then --Using == true in case the HybridScrollFrame .update is changed to pass in the parent.
        local button = buttons[ArmoryRaidInfoFrame.selectedIndex - offset]
        if ( not button or (button:GetTop() > scrollFrame:GetTop()) or (button:GetBottom() < scrollFrame:GetBottom()) ) then
            local buttonHeight = scrollFrame.buttons[1]:GetHeight();
            local scrollValue = min(((ArmoryRaidInfoFrame.selectedIndex - 1) * buttonHeight), scrollFrame.range)
            if ( scrollValue ~= scrollFrame.scrollBar:GetValue() ) then
                scrollFrame.scrollBar:SetValue(scrollValue);
            end
        end
    end

    offset = HybridScrollFrame_GetOffset(scrollFrame);	--May have changed in the previous section to move selected parts into view.

    local mouseIsOverScrollFrame = scrollFrame:IsVisible() and scrollFrame:IsMouseOver();
    local frame, index, id;
    for i = 1, numButtons do
        frame = buttons[i];
        index = i + offset;

        if ( index <= savedInstances) then
            id = Armory:GetInstanceLineId(index);
            instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = Armory:GetSavedInstanceInfo(id);

            frame.instanceID = instanceID;
            frame.longInstanceID = string.format("%x%x", instanceIDMostSig, instanceID);
            frame:SetID(index);

            if ( ArmoryRaidInfoFrame.selectedRaidID == frame.longInstanceID ) then
                frame:LockHighlight();
            else
                frame:UnlockHighlight();
            end

            frame.difficulty:SetText(difficultyName);

            if ( extended or locked ) then
                frame.reset:SetText(SecondsToTime(instanceReset, true, nil, 3));
                frame.name:SetText(instanceName);
            else
                frame.reset:SetFormattedText("|cff808080%s|r", RAID_INSTANCE_EXPIRES_EXPIRED);
                frame.name:SetFormattedText("|cff808080%s|r", instanceName);
            end

            if ( extended ) then
                frame.extended:Show();
            else
                frame.extended:Hide();
            end

            frame:Show();

            if ( mouseIsOverScrollFrame and frame:IsMouseOver() ) then
                ArmoryRaidInfoInstance_OnEnter(frame);
            end
        else
            frame:Hide();
        end	
    end
    HybridScrollFrame_Update(scrollFrame, savedInstances * buttonHeight, scrollFrame:GetHeight());
end

function ArmoryRaidInfoFrame_UpdateInfo()
    Armory:UpdateInstances();
    ArmoryRaidInfoFrame_Update(true);
end

function ArmoryRaidInfoInstance_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(self.name:GetText());
    GameTooltip:AddLine(self.difficulty:GetText(), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(format(INSTANCE_ID, self.instanceID), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    Armory:TooltipAddHints(GameTooltip, ARMORY_LINK_HINT);
    GameTooltip:Show();
end

function ArmoryRaidInfoInstance_OnClick(self)
    if ( IsModifiedClick("CHATLINK") ) then
        local id = Armory:GetInstanceLineId(self:GetID());
        local instanceName, instanceID, _, _, _, _, _, _, _, difficultyName = Armory:GetSavedInstanceInfo(id);
        local text = format("%s (%s) "..INSTANCE_ID, instanceName, difficultyName, instanceID);
        if ( not ChatEdit_InsertLink(text) ) then
            ChatEdit_GetLastActiveWindow():Show();
            ChatEdit_InsertLink(text);
        end
    end
end

function ArmoryRaidInfoFrame_UpdateSelectedIndex()
    local savedInstances = Armory:GetNumSavedInstances();
    for index = 1, savedInstances do
        local id = Armory:GetInstanceLineId(index);
        local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig = Armory:GetSavedInstanceInfo(id);
        if ( format("%x%x", instanceIDMostSig, instanceID) == ArmoryRaidInfoFrame.selectedRaidID ) then
            ArmoryRaidInfoFrame.selectedIndex = index;
            return;
        end
    end
    ArmoryRaidInfoFrame.selectedIndex = nil;
end