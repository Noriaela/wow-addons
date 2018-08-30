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

function ArmoryTalentFrameDownArrow_OnClick(self)
    local parent = self:GetParent();
    parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2));
end

function ArmoryTalentFrameTalent_Click(TalentFrame, id)
    if ( IsModifiedClick("CHATLINK") ) then
        local link = Armory:GetTalentLink(TalentFrame.selectedTab, id, false, TalentFrame.pet, TalentFrame.talentGroup);
        if ( link ) then
            ChatEdit_InsertLink(link);
        end
    end
end

function ArmoryTalentFrameTalent_Enter(TalentFrame, id)
    Armory:SetTalent(TalentFrame.selectedTab, id, false, TalentFrame.pet, TalentFrame.talentGroup);
end

function ArmoryTalentFrame_ConditionalUpdate(TalentFrame)
    Armory:ExecuteConditional(
        function() 
            return GetNumTalentTabs(false, TalentFrame.pet) > 0; 
        end, 
        function() 
            Armory:SetTalents(TalentFrame.pet); 
            if ( TalentFrame.updateFunc ) then
                TalentFrame.updateFunc();
            end
        end
    );
end

function ArmoryTalentFrame_Load(TalentFrame)
    TalentFrame.TALENT_BRANCH_ARRAY = {};
    for i = 1, MAX_NUM_TALENT_TIERS do
        TalentFrame.TALENT_BRANCH_ARRAY[i] = {};
        for j=1, NUM_TALENT_COLUMNS do
            TalentFrame.TALENT_BRANCH_ARRAY[i][j] = {id=nil, up=0, left=0, right=0, down=0, leftArrow=0, rightArrow=0, topArrow=0};
        end
    end

    _G[TalentFrame:GetName().."ScrollFrameScrollBarScrollDownButton"]:SetScript("OnClick", ArmoryTalentFrameDownArrow_OnClick);
end

function ArmoryTalentFrame_UpdateFrame(TalentFrame)
    local isActiveTalentGroup = ArmoryTalentFrame.talentGroup == Armory:GetActiveTalentGroup(false, TalentFrame.pet);
    
    ArmoryTalentFrame_UpdateTalentPoints(TalentFrame);

    -- Setup Frame
    local base;
    local name, texture, points, background, previewPointsSpent = Armory:GetTalentTabInfo(TalentFrame.selectedTab, false, TalentFrame.pet, TalentFrame.talentGroup);
    if ( name ) then
        base = "Interface\\TalentFrame\\"..background.."-";
    else
        -- temporary default for classes without talents poor guys
        base = "Interface\\TalentFrame\\MageFire-";
    end

    local talentFrameName = TalentFrame:GetName();

    -- desaturate the background if this isn't the active talent group
    local backgroundPiece = _G[talentFrameName.."BackgroundTopLeft"];
    backgroundPiece:SetTexture(base.."TopLeft");
    SetDesaturation(backgroundPiece, not isActiveTalentGroup);
    backgroundPiece = _G[talentFrameName.."BackgroundTopRight"];
    backgroundPiece:SetTexture(base.."TopRight");
    SetDesaturation(backgroundPiece, not isActiveTalentGroup);
    backgroundPiece = _G[talentFrameName.."BackgroundBottomLeft"];
    backgroundPiece:SetTexture(base.."BottomLeft");
    SetDesaturation(backgroundPiece, not isActiveTalentGroup);
    backgroundPiece = _G[talentFrameName.."BackgroundBottomRight"];
    backgroundPiece:SetTexture(base.."BottomRight");
    SetDesaturation(backgroundPiece, not isActiveTalentGroup);

    local numTalents = Armory:GetNumTalents(TalentFrame.selectedTab, false, TalentFrame.pet);
    -- Just a reminder error if there are more talents than available buttons
    if ( numTalents > MAX_NUM_TALENTS ) then
        message("Too many talents in talent frame!");
    end

    TalentFrame_ResetBranches(TalentFrame);
    local talentFrameTalentName = talentFrameName.."Talent";
    local tier, column, rank, maxRank, isExceptional, isLearnable;
    local forceDesaturated, tierUnlocked;
    for i=1, MAX_NUM_TALENTS do
        local buttonName = talentFrameTalentName..i;
        local button = _G[buttonName];
        if ( i <= numTalents ) then
            -- Set the button info
            local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq, previewRank, meetsPreviewPrereq = 
                Armory:GetTalentInfo(TalentFrame.selectedTab, i, false, TalentFrame.pet, TalentFrame.talentGroup);
            if ( name ) then
                _G[buttonName.."Rank"]:SetText(rank);
                SetTalentButtonLocation(button, tier, column);
                TalentFrame.TALENT_BRANCH_ARRAY[tier][column].id = button:GetID();

                -- If player has no talent points then show only talents with points in them
                if ( (TalentFrame.talentPoints <= 0 or not isActiveTalentGroup) and rank == 0 ) then
                    forceDesaturated = 1;
                else
                    forceDesaturated = nil;
                end

                -- If the player has spent at least 5 talent points in the previous tier
                if ( ( (tier - 1) * (TalentFrame.pet and PET_TALENTS_PER_TIER or PLAYER_TALENTS_PER_TIER) <= TalentFrame.pointsSpent ) ) then
                    tierUnlocked = 1;
                else
                    tierUnlocked = nil;
                end
                SetItemButtonTexture(button, iconTexture);

                -- Talent must meet prereqs or the player must have no points to spend
                local prereqsSet =
                    TalentFrame_SetPrereqs(TalentFrame, tier, column, forceDesaturated, tierUnlocked, false,
                    Armory:GetTalentPrereqs(TalentFrame.selectedTab, i, false, TalentFrame.pet, TalentFrame.talentGroup));
                    
                if ( prereqsSet and meetsPrereq ) then
                    SetItemButtonDesaturated(button, nil);

                    if ( rank < maxRank ) then
                        -- Rank is green if not maxed out
                        _G[buttonName.."Slot"]:SetVertexColor(0.1, 1.0, 0.1);
                        _G[buttonName.."Rank"]:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                    else
                        _G[buttonName.."Slot"]:SetVertexColor(1.0, 0.82, 0);
                        _G[buttonName.."Rank"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
                    end
                    _G[buttonName.."RankBorder"]:Show();
                    _G[buttonName.."Rank"]:Show();
                else
                    SetItemButtonDesaturated(button, 1, 0.65, 0.65, 0.65);
                    _G[buttonName.."Slot"]:SetVertexColor(0.5, 0.5, 0.5);
                    if ( rank == 0 ) then
                        _G[buttonName.."RankBorder"]:Hide();
                        _G[buttonName.."Rank"]:Hide();
                    else
                        _G[buttonName.."RankBorder"]:SetVertexColor(0.5, 0.5, 0.5);
                        _G[buttonName.."Rank"]:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
                    end
                end
                button:Show();
            else    
                button:Hide();
            end
        else
            button:Hide();
        end
    end

    -- Draw the prereq branches
    local node;
    local textureIndex = 1;
    local xOffset, yOffset;
    -- Variable that decides whether or not to ignore drawing pieces
    local ignoreUp;
    local tempNode;
    TalentFrame_ResetBranchTextureCount(TalentFrame);
    TalentFrame_ResetArrowTextureCount(TalentFrame);
    for i=1, MAX_NUM_TALENT_TIERS do
        for j=1, NUM_TALENT_COLUMNS do
            node = TalentFrame.TALENT_BRANCH_ARRAY[i][j];

            -- Setup offsets
            xOffset = ((j - 1) * 63) + INITIAL_TALENT_OFFSET_X + 2;
            yOffset = -((i - 1) * 63) - INITIAL_TALENT_OFFSET_Y - 2;

            if ( node.id ) then
                -- Has talent
                if ( node.up ~= 0 ) then
                    if ( not ignoreUp ) then
                        TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset + TALENT_BUTTON_SIZE, TalentFrame);
                    else
                        ignoreUp = nil;
                    end
                end
                if ( node.down ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - TALENT_BUTTON_SIZE + 1, TalentFrame);
                end
                if ( node.left ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset - TALENT_BUTTON_SIZE, yOffset, TalentFrame);
                end
                if ( node.right ~= 0 ) then
                    -- See if any connecting branches are gray and if so color them gray
                    tempNode = TalentFrame.TALENT_BRANCH_ARRAY[i][j+1];    
                    if ( tempNode.left ~= 0 and tempNode.down < 0 ) then
                        TalentFrame_SetBranchTexture(i, j-1, TALENT_BRANCH_TEXTURECOORDS["right"][tempNode.down], xOffset + TALENT_BUTTON_SIZE, yOffset, TalentFrame);
                    else
                        TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE + 1, yOffset, TalentFrame);
                    end

                end
                -- Draw arrows
                if ( node.rightArrow ~= 0 ) then
                    TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["right"][node.rightArrow], xOffset + TALENT_BUTTON_SIZE/2 + 5, yOffset, TalentFrame);
                end
                if ( node.leftArrow ~= 0 ) then
                    TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["left"][node.leftArrow], xOffset - TALENT_BUTTON_SIZE/2 - 5, yOffset, TalentFrame);
                end
                if ( node.topArrow ~= 0 ) then
                    TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["top"][node.topArrow], xOffset, yOffset + TALENT_BUTTON_SIZE/2 + 5, TalentFrame);
                end
            else
                -- Doesn't have a talent
                if ( node.up ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tup"][node.up], xOffset , yOffset, TalentFrame);
                elseif ( node.down ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tdown"][node.down], xOffset , yOffset, TalentFrame);
                elseif ( node.left ~= 0 and node.down ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topright"][node.left], xOffset , yOffset, TalentFrame);
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, TalentFrame);
                elseif ( node.left ~= 0 and node.up ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomright"][node.left], xOffset , yOffset, TalentFrame);
                elseif ( node.left ~= 0 and node.right ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE, yOffset, TalentFrame);
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset + 1, yOffset, TalentFrame);
                elseif ( node.right ~= 0 and node.down ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topleft"][node.right], xOffset , yOffset, TalentFrame);
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, TalentFrame);
                elseif ( node.right ~= 0 and node.up ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomleft"][node.right], xOffset , yOffset, TalentFrame);
                elseif ( node.up ~= 0 and node.down ~= 0 ) then
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset , yOffset, TalentFrame);
                    TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, TalentFrame);
                    ignoreUp = 1;
                end
            end
        end
    end
    -- Hide any unused branch textures
    for i=TalentFrame_GetBranchTextureCount(TalentFrame), MAX_NUM_BRANCH_TEXTURES do
        _G[talentFrameName.."Branch"..i]:Hide();
    end
    -- Hide and unused arrowl textures
    for i=TalentFrame_GetArrowTextureCount(TalentFrame), MAX_NUM_ARROW_TEXTURES do
        _G[talentFrameName.."Arrow"..i]:Hide();
    end
end

-- Helper functions
function ArmoryTalentFrame_UpdateTalentPoints(TalentFrame)
    TalentFrame.talentPoints = Armory:GetUnspentTalentPoints(false, TalentFrame.pet, TalentFrame.talentGroup);
end

local sortedTabPointsSpentBuf = {};
function ArmoryTalentFrame_GetSpecInfo(talentGroup)
    local talentPoints = {};
    local primaryTabIndex = 0;
    local totalPointsSpent = 0;
    local iconTexture;
    
    local highPointsSpent = 0;
    local highPointsSpentIndex;
    local lowPointsSpent = math.huge;
    local lowPointsSpentIndex;
    
    local numTabs = 0;

    for i = 1, Armory:GetNumTalentTabs() do
        local name, _, pointsSpent = Armory:GetTalentTabInfo(i, false, false, talentGroup);
        if ( not pointsSpent ) then
            pointsSpent = 0;
        elseif ( pointsSpent > 0 ) then
            numTabs = numTabs + 1;
        end
        
        talentPoints[i] = {name=name, pointsSpent=pointsSpent};

        -- update total points
        totalPointsSpent = totalPointsSpent + pointsSpent;

        -- update the high and low points spent info
        if ( pointsSpent > highPointsSpent ) then
            highPointsSpent = pointsSpent;
            highPointsSpentIndex = i;
        elseif ( pointsSpent < lowPointsSpent ) then
            lowPointsSpent = pointsSpent;
            lowPointsSpentIndex = i;
        end

        -- initialize the points spent buffer element
        sortedTabPointsSpentBuf[i] = 0;
        -- insert the points spent into our buffer in ascending order
        local insertIndex = i;
        for j = 1, i, 1 do
            local currPointsSpent = sortedTabPointsSpentBuf[j];
            if ( currPointsSpent > pointsSpent ) then
                insertIndex = j;
                break;
            end
        end
        for j = i, insertIndex + 1, -1 do
            sortedTabPointsSpentBuf[j] = sortedTabPointsSpentBuf[j - 1];
        end
        sortedTabPointsSpentBuf[insertIndex] = pointsSpent;
    end
    
    if ( highPointsSpentIndex and lowPointsSpentIndex ) then
        -- now that our points spent buffer is filled, we can compute the mid points spent
        local midPointsSpentIndex = bit.rshift(Armory:GetNumTalentTabs(), 1) + 1;
        local midPointsSpent = sortedTabPointsSpentBuf[midPointsSpentIndex];
        -- now let's use our crazy formula to determine which tab is the primary one
        if ( 3*(midPointsSpent-lowPointsSpent) < 2*(highPointsSpent-lowPointsSpent) ) then
            primaryTabIndex = highPointsSpentIndex;
        end
    end

    if ( primaryTabIndex > 0 ) then
        -- the spec had a primary tab, set the icon to that tab's icon
        _, iconTexture = Armory:GetTalentTabInfo(primaryTabIndex, false, false, talentGroup);
    elseif ( numTabs > 1 and totalPointsSpent > 0 ) then
        -- the spec is only considered a hybrid if the spec had more than one tab and at least
        -- one point was spent in one of the tabs
        iconTexture = TALENT_HYBRID_ICON;
    else
        iconTexture = "Interface\\Icons\\Ability_Marksmanship";
    end

    return primaryTabIndex, iconTexture, talentPoints;
end