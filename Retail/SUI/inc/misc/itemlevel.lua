--[[SUI ITEMLEVEL v1.0]]

--FIX LIBSTUB

local CF=CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

if not SUIDB.A_ITEMLEVEL == true then return end 

local MAJOR, MINOR = "ItemLevel", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then
    return
end

local ItemLevelPattern = gsub(ITEM_LEVEL, "%%d", "(%%d+)")

local tooltip = CreateFrame("GameTooltip", "LibItemLevelTooltip1", UIParent, "GameTooltipTemplate")
local unittip = CreateFrame("GameTooltip", "LibItemLevelTooltip2", UIParent, "GameTooltipTemplate")

function lib:hasLocally(ItemID)
    if (not ItemID or ItemID == "" or ItemID == "0") then
        return true
    end
    return select(10, GetItemInfo(tonumber(ItemID)))
end

function lib:itemLocally(ItemLink)
    local id, gem1, gem2, gem3 = string.match(ItemLink, "item:(%d+):[^:]*:(%d-):(%d-):(%d-):")
    return (self:hasLocally(id) and self:hasLocally(gem1) and self:hasLocally(gem2) and self:hasLocally(gem3))
end

function lib:GetItemInfo(ItemLink)
    if (not ItemLink or ItemLink == "") then
        return 0, 0
    end
    if (not string.match(ItemLink, "item:%d+:")) then
        return -1, 0
    end
    if (not self:itemLocally(ItemLink)) then
        return 1, 0
    end
    local level, text
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(ItemLink)
    for i = 2, 5 do
        text = _G[tooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
        level = string.match(text, ItemLevelPattern)
        if (level) then
            break
        end
    end
    return 0, tonumber(level) or 0, GetItemInfo(ItemLink)
end

LibItemLevel = LibStub:GetLibrary("ItemLevel")

function lib:GetUnitItemInfo(unit, index)
    if (not UnitExists(unit)) then
        return 1, 0
    end
    unittip:SetOwner(UIParent, "ANCHOR_NONE")
    unittip:ClearLines()
    unittip:SetInventoryItem(unit, index)
    local ItemLink = select(2, unittip:GetItem())
    if (not ItemLink or ItemLink == "") then
        return 0, 0
    end
    if (not self:itemLocally(ItemLink)) then
        return 1, 0
    end
    local level, text
    for i = 2, 5 do
        text = _G[unittip:GetName() .. "TextLeft" .. i]:GetText() or ""
        level = string.match(text, ItemLevelPattern)
        if (level) then
            break
        end
    end
    return 0, tonumber(level) or 0, GetItemInfo(ItemLink)
end

function lib:GetUnitItemLevel(unit)
    local total, counts = 0, 0
    local _, count, level
    for i = 1, 15 do
        if (i ~= 4) then
            count, level = self:GetUnitItemInfo(unit, i)
            total = total + level
            counts = counts + count
        end
    end
    local mcount, mlevel, mquality, mslot, ocount, olevel, oquality, oslot
    mcount, mlevel, _, _, mquality, _, _, _, _, _, mslot = self:GetUnitItemInfo(unit, 16)
    ocount, olevel, _, _, oquality, _, _, _, _, _, oslot = self:GetUnitItemInfo(unit, 17)
    counts = counts + mcount + ocount

    if
        (mquality == 6 or oslot == "INVTYPE_2HWEAPON" or mslot == "INVTYPE_2HWEAPON" or mslot == "INVTYPE_RANGED" or
            mslot == "INVTYPE_RANGEDRIGHT")
     then
        total = total + max(mlevel, olevel) * 2
    else
        total = total + mlevel + olevel
    end
    return counts, total / (16 - counts), total
end

function ShowPaperDollItemLevel(self, unit)
    result = ""
    id = self:GetID()
    if id == 4 or id > 17 then
        return
    end
    if not self.levelString then
        self.levelString = self:CreateFontString(nil, "OVERLAY")
        self.levelString:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        self.levelString:SetPoint("TOP")
        self.levelString:SetTextColor(1, 0.82, 0)
    end
    if unit and self.hasItem then
        _, level, _, _, quality = LibItemLevel:GetUnitItemInfo(unit, id)
        if level > 0 and quality > 2 then
            self.levelString:SetText(level)
            result = true
        end
    else
        self.levelString:SetText("")
        result = true
    end
    if id == 16 or id == 17 then
        _, offhand, _, _, quality = LibItemLevel:GetUnitItemInfo(unit, 17)
        if quality == 6 then
            _, mainhand = LibItemLevel:GetUnitItemInfo(unit, 16)
            self.levelString:SetText(math.max(mainhand, offhand))
        end
    end
    return result
end
hooksecurefunc(
    "PaperDollItemSlotButton_Update",
    function(self)
        ShowPaperDollItemLevel(self, "player")
    end
)

function SetContainerItemLevel(button, ItemLink)
    if not button then
        return
    end
    if not button.levelString then
        button.levelString = button:CreateFontString(nil, "OVERLAY")
        button.levelString:SetFont(STANDARD_TEXT_FONT, 12, "THICKOUTLINE")
        button.levelString:SetPoint("TOP")
    end
    if button.origItemLink ~= ItemLink then
        button.origItemLink = ItemLink
    else
        return
    end
    if ItemLink then
        count, level, _, _, quality, _, _, class, subclass, _, _ = LibItemLevel:GetItemInfo(ItemLink)
        name, _ = GetItemSpell(ItemLink)
        _, equipped, _ = GetAverageItemLevel()
        if level >= (98 * equipped / 100) then
            button.levelString:SetTextColor(0, 1, 0)
        else
            button.levelString:SetTextColor(1, 1, 1)
        end
        if count == 0 and level > 0 and quality > 1 then
            button.levelString:SetText(level)
        else
            button.levelString:SetText("")
        end
    else
        button.levelString:SetText("")
    end
end
hooksecurefunc(
    "ContainerFrame_Update",
    function(self)
        local name = self:GetName()
        for i = 1, self.size do
            local button = _G[name .. "Item" .. i]
            SetContainerItemLevel(button, GetContainerItemLink(self:GetID(), button:GetID()))
        end
    end
)

end)