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
        
Armory.LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Armory", 
    { type = "data source", 
      icon = "Interface\\CharacterFrame\\TemporaryPortrait", 
      text = UNKNOWN,
      label = ARMORY_TITLE
     }
);

function Armory.LDB:OnClick(button)
    GameTooltip:Hide();
    Armory:HideSummary();
    if ( button == "LeftButton" ) then
        Armory:Toggle();
    elseif ( button == "RightButton" ) then
        ArmoryToggleDropDownMenu(1, nil, Armory.menu, self, 0, 0);
    end
end

function Armory.LDB:OnEnter()
    if ( not ArmoryDropDownList1:IsVisible() ) then
        GameTooltip:SetOwner(self, "ANCHOR_NONE");
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
        GameTooltip:ClearLines();

        local realm, character = Armory:GetPaperDollLastViewed();
        if ( Armory.summary and Armory.summary:IsShown() ) then
            GameTooltip:SetFrameLevel(Armory.summary:GetFrameLevel() + 2);
        end
        GameTooltip:AddLine(ARMORY_TITLE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(ARMORY_TOOLTIP1, character, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddDoubleLine(ARMORY_TOOLTIP2, realm, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        Armory:TooltipAddHints(GameTooltip, ARMORY_TOOLTIP_HINT1, ARMORY_TOOLTIP_HINT2);

        GameTooltip:Show();

        Armory.summaryEnabled = true;
        Armory:ShowSummary(self);
    end
end

function Armory.LDB:OnLeave()
    Armory.summaryEnabled = false;
    GameTooltip:Hide();
end