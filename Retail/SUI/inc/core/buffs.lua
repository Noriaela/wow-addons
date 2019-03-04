local SUI=CreateFrame("Frame")
SUI:RegisterEvent("ADDON_LOADED")
SUI:SetScript("OnEvent", function(self, event)

if not SUIDB.A_DARKFRAMES == true then return end

--font
local FONT = nil
if SUIDB.A_FONTS == true then
FONT = SUIDB.FONTS.NORMAL
else
FONT = STANDARD_TEXT_FONT
end

--rCreateDragFrame func
  function rCreateDragFrame(self, dragFrameList, inset, clamp)
    if not self or not dragFrameList then return end
    self.defaultPoint = rGetPoint(self)
    table.insert(dragFrameList,self)

    local df = CreateFrame("Frame",nil,self)
    df:SetAllPoints(self)
    df:SetFrameStrata("HIGH")
    df:SetHitRectInsets(inset or 0,inset or 0,inset or 0,inset or 0)
    df:EnableMouse(true)
    df:RegisterForDrag("LeftButton")
    df:SetScript("OnDragStart", function(self) if IsAltKeyDown() and IsShiftKeyDown() then self:GetParent():StartMoving() end end)
    df:SetScript("OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)
    df:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine(self:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
      GameTooltip:AddLine("Hold down ALT+SHIFT to drag!", 1, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end)
    df:SetScript("OnLeave", function(s) GameTooltip:Hide() end)
    df:Hide()

    local t = df:CreateTexture(nil,"OVERLAY",nil,6)
    t:SetAllPoints(df)
    t:SetColorTexture(0,1,0)
    t:SetAlpha(0.2)
    df.texture = t

    self.dragFrame = df
    self:SetClampedToScreen(clamp or false)
    self:SetMovable(true)
    self:SetUserPlaced(true)
  end

--rewrite the oneletter shortcuts
  if SUIDB.adjustOneletterAbbrev then
    HOUR_ONELETTER_ABBR = "%dh"
    DAY_ONELETTER_ABBR = "%dd"
    MINUTE_ONELETTER_ABBR = "%dm"
    SECOND_ONELETTER_ABBR = "%ds"
  end

--backdrop debuff
  local backdropDebuff = {
    bgFile = nil,
    edgeFile = SUIDB.debuffFrame.background.edgeFile,
    tile = false,
    tileSize = 32,
    edgeSize = SUIDB.debuffFrame.background.inset,
    insets = {
      left = SUIDB.debuffFrame.background.inset,
      right = SUIDB.debuffFrame.background.inset,
      top = SUIDB.debuffFrame.background.inset,
      bottom = SUIDB.debuffFrame.background.inset,
    },
  }

--backdrop buff
  local backdropBuff = {
    bgFile = nil,
    edgeFile = SUIDB.buffFrame.background.edgeFile,
    tile = false,
    tileSize = 32,
    edgeSize = SUIDB.buffFrame.background.inset,
    insets = {
      left = SUIDB.buffFrame.background.inset,
      right = SUIDB.buffFrame.background.inset,
      top = SUIDB.buffFrame.background.inset,
      bottom = SUIDB.buffFrame.background.inset,
    },
  }

  local ceil, min, max = ceil, min, max
  local ShouldShowConsolidatedBuffFrame = ShouldShowConsolidatedBuffFrame

  local buffFrameHeight = 0

--apply aura frame texture func
  local function applySkin(b)
    if not b or (b and b.styled) then return end

    local name = b:GetName()

    local tempenchant, consolidated, debuff, buff = false, false, false, false
    if (name:match("TempEnchant")) then
      tempenchant = true
    elseif (name:match("Consolidated")) then
      consolidated = true
    elseif (name:match("Debuff")) then
      debuff = true
    else
      buff = true
    end

    if debuff then
      SUI = SUIDB.debuffFrame
      backdrop = backdropDebuff
    else
      SUI = SUIDB.buffFrame
      backdrop = backdropBuff
    end

--check class coloring options
    --button
    b:SetSize(SUI.button.size, SUI.button.size)

    --icon
    local icon = _G[name.."Icon"]
    if consolidated then
	  if select(1,UnitFactionGroup("player")) == "Alliance" then
     		icon:SetTexture(select(3,GetSpellInfo(61573)))
	  elseif select(1,UnitFactionGroup("player")) == "Horde" then
		icon:SetTexture(select(3,GetSpellInfo(61574)))
  	end
    end
    icon:SetTexCoord(0.1,0.9,0.1,0.9)
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", b, "TOPLEFT", -SUI.icon.padding, SUI.icon.padding)
    icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", SUI.icon.padding, -SUI.icon.padding)
    icon:SetDrawLayer("BACKGROUND",-8)
    b.icon = icon

    --border
    local border = _G[name.."Border"] or b:CreateTexture(name.."Border", "BACKGROUND", nil, -7)
    border:SetTexture(SUI.border.texture)
    border:SetTexCoord(0,1,0,1)
    border:SetDrawLayer("BACKGROUND",-7)
    if tempenchant then
      border:SetVertexColor(0.7,0,1)
    elseif not debuff then
      border:SetVertexColor(SUI.border.color.r,SUI.border.color.g,SUI.border.color.b)
    end
    border:ClearAllPoints()
    border:SetAllPoints(b)
    b.border = border

    --duration
    b.duration:SetFont(FONT, SUI.duration.size, "THINOUTLINE")
    b.duration:ClearAllPoints()
    b.duration:SetPoint(SUI.duration.pos.a1,SUI.duration.pos.x,SUI.duration.pos.y)

    --count
    b.count:SetFont(SUI.count.font, SUI.count.size, "THINOUTLINE")
    b.count:ClearAllPoints()
    b.count:SetPoint(SUI.count.pos.a1,SUI.count.pos.x,SUI.count.pos.y)

    --shadow
    if SUI.background.show then
      local back = CreateFrame("Frame", nil, b)
      back:SetPoint("TOPLEFT", b, "TOPLEFT", -SUI.background.padding, SUI.background.padding)
      back:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", SUI.background.padding, -SUI.background.padding)
      back:SetFrameLevel(b:GetFrameLevel() - 1)
      back:SetBackdrop(backdrop)
      back:SetBackdropBorderColor(SUI.background.color.r,SUI.background.color.g,SUI.background.color.b,SUI.background.color.a)
      b.bg = back
    end

    --set button styled variable
    b.styled = true
    end

--update debuff anchors
  local function updateDebuffAnchors(buttonName,index)
    local button = _G[buttonName..index]
    if not button then return end
    --apply skin
    if not button.styled then applySkin(button) end
    --position button
    button:ClearAllPoints()
    if index == 1 then
      if SUIDB.combineBuffsAndDebuffs then
        button:SetPoint("TOPRIGHT", rBFS_BuffDragFrame, "TOPRIGHT", 0, -buffFrameHeight)
      else
        --debuffs and buffs are not combined anchor the debuffs to its own frame
        button:SetPoint("TOPRIGHT", rBFS_DebuffDragFrame, "TOPRIGHT", 0, 0)
      end
    elseif index > 1 and mod(index, SUIDB.debuffFrame.buttonsPerRow) == 1 then
      button:SetPoint("TOPRIGHT", _G[buttonName..(index-SUIDB.debuffFrame.buttonsPerRow)], "BOTTOMRIGHT", 0, -SUIDB.debuffFrame.rowSpacing)
    else
      button:SetPoint("TOPRIGHT", _G[buttonName..(index-1)], "TOPLEFT", -SUIDB.debuffFrame.colSpacing, 0)
    end
  end

--update buff anchors
  local function updateAllBuffAnchors()
    --variables
    local buttonName  = "BuffButton"
    local numEnchants = BuffFrame.numEnchants
    local numBuffs    = BUFF_ACTUAL_DISPLAY
    local offset      = numEnchants
    local realIndex, previousButton, aboveButton
    --position the tempenchant button depending on the consolidated button status
   -- if ShouldShowConsolidatedBuffFrame() then
     -- TempEnchant1:ClearAllPoints()
     -- TempEnchant1:SetPoint("TOPRIGHT", ConsolidatedBuffs, "TOPLEFT", -SUIDB.buffFrame.colSpacing, 0)
      --offset = offset + 1
   -- else
      TempEnchant1:ClearAllPoints()
      TempEnchant1:SetPoint("TOPRIGHT", rBFS_BuffDragFrame, "TOPRIGHT", 0, 0)
    --end

    --calculate the previous button in case tempenchant or consolidated buff are loaded
    if BuffFrame.numEnchants > 0 then
      previousButton = _G["TempEnchant"..numEnchants]
    end
   -- elseif ShouldShowConsolidatedBuffFrame() then
     -- previousButton = ConsolidatedBuffs
   -- end
    --calculate the above button in case tempenchant or consolidated buff are loaded
   -- if ShouldShowConsolidatedBuffFrame() then
    --  aboveButton = ConsolidatedBuffs
    if numEnchants > 0 then
      aboveButton = TempEnchant1
    end
    --loop on all active buff buttons
    local buffCounter = 0
    for index = 1, numBuffs do
      local button = _G[buttonName..index]
      if not button then return end
      if not button.consolidated then
        buffCounter = buffCounter + 1
        --apply skin
        if not button.styled then applySkin(button) end
        --position button
        button:ClearAllPoints()
        realIndex = buffCounter+offset
        if realIndex == 1 then
          button:SetPoint("TOPRIGHT", rBFS_BuffDragFrame, "TOPRIGHT", 0, 0)
          aboveButton = button
        elseif realIndex > 1 and mod(realIndex, SUIDB.buffFrame.buttonsPerRow) == 1 then
          button:SetPoint("TOPRIGHT", aboveButton, "BOTTOMRIGHT", 0, -SUIDB.buffFrame.rowSpacing)
          aboveButton = button
        else
          button:SetPoint("TOPRIGHT", previousButton, "TOPLEFT", -SUIDB.buffFrame.colSpacing, 0)
        end
        previousButton = button

      end
    end
    --calculate the height of the buff rows for the debuff frame calculation later
    local rows = ceil((buffCounter+offset)/SUIDB.buffFrame.buttonsPerRow)
    local height = SUIDB.buffFrame.button.size*rows + SUIDB.buffFrame.rowSpacing*rows + SUIDB.buffFrame.gap*min(1,rows)
    buffFrameHeight = height
    --make sure the debuff frames update the position asap
    if DebuffButton1 and SUIDB.combineBuffsAndDebuffs then
      updateDebuffAnchors("DebuffButton", 1)
    end
  end

--buff drag frame
  local bf = CreateFrame("Frame", "rBFS_BuffDragFrame", UIParent)
  bf:SetSize(SUIDB.buffFrame.button.size,SUIDB.buffFrame.button.size)
  bf:SetPoint(SUIDB.buffFrame.pos.a1,SUIDB.buffFrame.pos.af,SUIDB.buffFrame.pos.a2,SUIDB.buffFrame.pos.x,SUIDB.buffFrame.pos.y)
  if SUIDB.buffFrame.userplaced then
    rCreateDragFrame(bf, dragFrameList, -2 , true) --frame, dragFrameList, inset, clamp
  end

  if not SUIDB.combineBuffsAndDebuffs then

--debuff drag frame
  local df = CreateFrame("Frame", "rBFS_DebuffDragFrame", UIParent)
  df:SetSize(SUIDB.debuffFrame.button.size,SUIDB.debuffFrame.button.size)
  df:SetPoint(SUIDB.debuffFrame.pos.a1,SUIDB.debuffFrame.pos.af,SUIDB.debuffFrame.pos.a2,SUIDB.debuffFrame.pos.x,SUIDB.debuffFrame.pos.y)
  if SUIDB.debuffFrame.userplaced then
    rCreateDragFrame(df, dragFrameList, -2 , true) --frame, dragFrameList, inset, clamp
  end
  end

  --temp enchant stuff
  applySkin(TempEnchant1)
  applySkin(TempEnchant2)
  applySkin(TempEnchant3)

  --position the temp enchant buttons
  TempEnchant1:ClearAllPoints()
  TempEnchant1:SetPoint("TOPRIGHT", rBFS_BuffDragFrame, "TOPRIGHT", 0, 0) --button will be repositioned later in case temp enchant and consolidated buffs are both available
  TempEnchant2:ClearAllPoints()
  TempEnchant2:SetPoint("TOPRIGHT", TempEnchant1, "TOPLEFT", -SUIDB.buffFrame.colSpacing, 0)
  TempEnchant3:ClearAllPoints()
  TempEnchant3:SetPoint("TOPRIGHT", TempEnchant2, "TOPLEFT", -SUIDB.buffFrame.colSpacing, 0)

  --consolidated buff stuff
  --ConsolidatedBuffs:SetScript("OnLoad", nil) --do not fuck up the icon anymore
  --applySkin(ConsolidatedBuffs)
  --position the consolidate buff button
  --ConsolidatedBuffs:ClearAllPoints()
  --ConsolidatedBuffs:SetPoint("TOPRIGHT", rBFS_BuffDragFrame, "TOPRIGHT", 0, 0)
  --ConsolidatedBuffsTooltip:SetScale(SUIDB.consolidatedTooltipScale)

  --hook Blizzard functions
  hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", updateAllBuffAnchors)
  hooksecurefunc("DebuffButton_UpdateAnchors", updateDebuffAnchors)
end)