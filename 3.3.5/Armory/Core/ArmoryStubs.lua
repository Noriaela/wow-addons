--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 287 2010-06-30T22:21:28Z
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

function Armory:GetActiveTalentGroup(inspect, pet)
    if ( pet ) then
        return self:SetGetPetValue("ActiveTalentGroup", _G.GetActiveTalentGroup(false, true));
    end
    return self:SetGetCharacterValue("ActiveTalentGroup", _G.GetActiveTalentGroup()) or 1;
end

function Armory:GetAdjustedSkillPoints()
    return self:SetGetCharacterValue("AdjustedSkillPoints", _G.GetAdjustedSkillPoints());
end

function Armory:GetArenaCurrency()
    return self:SetGetCharacterValue("ArenaCurrency", _G.GetArenaCurrency());
end

function Armory:GetArmorPenetration()
    return self:SetGetCharacterValue("ArmorPenetration", _G.GetArmorPenetration());
end

function Armory:GetBlockChance()
    return self:SetGetCharacterValue("BlockChance", _G.GetBlockChance());
end

 function Armory:GetCombatRating(index)
    if ( index ) then
        return self:SetGetCharacterValue("CombatRating"..index, _G.GetCombatRating(index)) or 0;
    end
end

function Armory:GetCombatRatingBonus(index)
    if ( index ) then
        return self:SetGetCharacterValue("CombatRatingBonus"..index, _G.GetCombatRatingBonus(index)) or 0;
    end
end

function Armory:GetCritChance()
    return self:SetGetCharacterValue("CritChance", _G.GetCritChance());
end

function Armory:GetCritChanceFromAgility(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
    end
    return self:SetGetCharacterValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
end

function Armory:GetCurrentPet()
    local pets = self:GetPets();
    local pet = self:UnitName("pet") or UNKNOWN;
    if ( not self.selectedPet ) then
        self.selectedPet = pet;
    end
    if ( not self:PetExists(self.selectedPet) ) then
        if ( #pets > 0 ) then
            self.selectedPet = pets[1];
        else
            self.selectedPet = pet;
        end
    end
    return self.selectedPet;
end

function Armory:GetDodgeChance()
    return self:SetGetCharacterValue("DodgeChance", _G.GetDodgeChance());
end

function Armory:GetExpertise()
    return self:SetGetCharacterValue("Expertise", _G.GetExpertise());
end

function Armory:GetExpertisePercent()
    return self:SetGetCharacterValue("ExpertisePercent", _G.GetExpertisePercent());
end

function Armory:GetGuildInfo(unit)
    return self:SetGetCharacterValue("Guild", _G.GetGuildInfo("player"));
end

function Armory:GetHonorCurrency()
    return self:SetGetCharacterValue("HonorCurrency", _G.GetHonorCurrency());
end

function Armory:GetInventoryAlertStatus(index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryAlertStatus"..index, _G.GetInventoryAlertStatus(index));
    end
end

function Armory:GetInventoryItemBroken(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemBroken"..index, _G.GetInventoryItemBroken("player", index));
    end
end

function Armory:GetInventoryItemCount(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemCount"..index, _G.GetInventoryItemCount("player", index));
    end
end

function Armory:GetInventoryItemLink(unit, index)
    if ( index ) then
        local link = _G.GetInventoryItemLink("player", index);
        local gemString = self:GetItemGemString(link);
        return self:SetGetCharacterValue("InventoryItemLink"..index, link), self:SetGetCharacterValue("InventoryItemGems"..index, gemString);
    end
end

function Armory:GetInventoryItemTexture(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemTexture"..index, _G.GetInventoryItemTexture("player", index));
    end
end

function Armory:GetInventoryItemQuality(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemQuality"..index, _G.GetInventoryItemQuality("player", index));
    end
end

function Armory:GetLatestThreeSenders()
    return self:SetGetCharacterValue("LatestThreeSenders", _G.GetLatestThreeSenders());
end

function Armory:GetManaRegen()
    return self:SetGetCharacterValue("ManaRegen", _G.GetManaRegen());
end

function Armory:GetMaxCombatRatingBonus(index)
    if ( index ) then
        return self:SetGetCharacterValue("MaxCombatRatingBonus"..index, _G.GetMaxCombatRatingBonus(index)) or 0;
    end
end

function Armory:GetMoney()
    return self:SetGetCharacterValue("Money", _G.GetMoney()) or 0;
end

function Armory:GetParryChance()
    return self:SetGetCharacterValue("ParryChance", _G.GetParryChance());
end

function Armory:GetPetExperience()
    return self:SetGetPetValue("Experience", _G.GetPetExperience());
end

function Armory:GetPetFoodTypes()
    return self:SetGetPetValue("FoodTypes", _G.GetPetFoodTypes());
end

function Armory:GetPetHappiness()
    return self:SetGetPetValue("Happiness", _G.GetPetHappiness());
end

function Armory:GetPetIcon()
    local _, isHunterPet = self:HasPetUI();
    if ( isHunterPet ) then
        return self:SetGetPetValue("Icon", _G.GetPetIcon());
    end

    local _, className = self:UnitClass("player");
    if ( strupper(className) == "DEATHKNIGHT" ) then
        return "Interface\\Icons\\Spell_Shadow_RaiseDead"; --Spell_Shadow_AnimateDead";
    elseif ( self:UnitCreatureFamily("pet") ) then
        return "Interface\\Icons\\Spell_Shadow_Summon"..self:UnitCreatureFamily("pet");
    else
        return "Interface\\Icons\\INV_Misc_QuestionMark";
    end
end

local pets = {};
local oldPets = {};
function Armory:GetPets(unit)
    table.wipe(pets);
    table.wipe(oldPets);
   
    if ( self:PetsEnabled() ) then 
        local dbEntry = self.selectedDbBaseEntry;

        if ( unit == "player" ) then
            dbEntry = self.playerDbBaseEntry;
        end

        if ( dbEntry:Contains("Pets") ) then
            for pet, values in pairs(dbEntry:GetValue("Pets")) do
                -- sanity check
                if ( pet == UNKNOWN or not values.Family ) then
                    table.insert(oldPets, pet);
                else
                    table.insert(pets, pet);
                end
            end
            table.sort(pets);

            -- should never happen, but better save than sorry
            for _, pet in ipairs(oldPets) do
                self:DeletePet(pet, unit);
                self:PrintDebug("Pet", pet, "removed");
            end
        end
    end

    return pets;
end

function Armory:GetPetSpellBonusDamage()
    return self:SetGetPetValue("SpellBonusDamage", _G.GetPetSpellBonusDamage());
end

function Armory:GetPortraitTexture(unit)
    local portrait = "Interface\\CharacterFrame\\TemporaryPortrait";

    if ( strlower(unit) == "pet" ) then
        portrait = portrait .. "-Pet";
    else
        local sex = self:UnitSex(unit);
        local _, raceEn = self:UnitRace(unit);
        if ( sex == 2 ) then
            portrait = portrait .. "-Male-" .. raceEn;
        elseif ( sex == 3 ) then
            portrait = portrait .. "-Female-" .. raceEn;
        end
    end

    return portrait;
end

function Armory:GetRangedCritChance()
    return self:SetGetCharacterValue("RangedCritChance", _G.GetRangedCritChance());
end

function Armory:GetRestState()
    return self:SetGetCharacterValue("RestState", _G.GetRestState());
end

function Armory:GetShieldBlock()
    return self:SetGetCharacterValue("ShieldBlock", _G.GetShieldBlock());
end

function Armory:GetSpellBonusDamage(holySchool)
    if ( holySchool ) then
        return self:SetGetCharacterValue("SpellBonusDamage"..holySchool, _G.GetSpellBonusDamage(holySchool));
    end
end

function Armory:GetSpellBonusHealing()
    return self:SetGetCharacterValue("SpellBonusHealing", _G.GetSpellBonusHealing());
end

function Armory:GetSpellCritChance(holySchool)
    if ( holySchool ) then
        return self:SetGetCharacterValue("SpellCritChance"..holySchool, _G.GetSpellCritChance(holySchool));
    end
end

function Armory:GetSpellCritChanceFromIntellect(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
    end
    return self:SetGetCharacterValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
end

function Armory:GetSpellPenetration()
    return self:SetGetCharacterValue("SpellPenetration", _G.GetSpellPenetration());
end

function Armory:GetTotalAchievementPoints()
    return self:SetGetCharacterValue("TotalAchievementPoints", _G.GetTotalAchievementPoints()) or 0;
end

function Armory:GetUnitHealthModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthModifier", _G.GetUnitHealthModifier(unit));
    end
    return self:SetGetCharacterValue("HealthModifier", _G.GetUnitHealthModifier(unit));
end

function Armory:GetUnitHealthRegenRateFromSpirit(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthRegenRateFromSpirit", _G.GetUnitHealthRegenRateFromSpirit(unit));
    end
    return self:SetGetCharacterValue("HealthRegenRateFromSpirit", _G.GetUnitHealthRegenRateFromSpirit(unit));
end

function Armory:GetUnitManaRegenRateFromSpirit(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("ManaRegenRateFromSpirit", _G.GetUnitManaRegenRateFromSpirit(unit));
    end
    return self:SetGetCharacterValue("ManaRegenRateFromSpirit", _G.GetUnitManaRegenRateFromSpirit(unit));
end

function Armory:GetUnitMaxHealthModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("MaxHealthModifier", _G.GetUnitMaxHealthModifier(unit));
    end
    return self:SetGetCharacterValue("MaxHealthModifier", _G.GetUnitMaxHealthModifier(unit));
end

function Armory:GetUnitPowerModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("PowerModifier", _G.GetUnitPowerModifier(unit));
    end
    return self:SetGetCharacterValue("PowerModifier", _G.GetUnitPowerModifier(unit));
end

function Armory:GetUnspentTalentPoints(inspect, pet, talentGroup)
    if ( pet ) then
        return self:SetGetPetValue("UnspentTalentPoints", _G.GetUnspentTalentPoints(inspect, pet, talentGroup));
    end
    return self:SetGetCharacterValue("UnspentTalentPoints", _G.GetUnspentTalentPoints(inspect, pet, talentGroup)) or 0;
end

function Armory:GetPVPLifetimeStats()
    return self:SetGetCharacterValue("PVPLifetimeStats", _G.GetPVPLifetimeStats());
end

function Armory:GetPVPSessionStats()
    local time, hk, cp = self:SetGetCharacterValue("PVPSessionStats", time(), _G.GetPVPSessionStats());

    if ( not self:IsToday(time) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetPVPYesterdayStats()
    local time, hk, cp = self:SetGetCharacterValue("PVPYesterdayStats", time(), _G.GetPVPYesterdayStats());

    if ( not self:IsToday(time) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetSubZoneText()
    return self:SetGetCharacterValue("SubZone", _G.GetSubZoneText());
end

function Armory:GetXPExhaustion()
    return self:SetGetCharacterValue("XPExhaustion", _G.GetXPExhaustion(), time());
end

function Armory:GetZoneText()
    return self:SetGetCharacterValue("Zone", _G.GetZoneText());
end

function Armory:HasNewMail()
    return self:SetGetCharacterValue("HasMail", _G.HasNewMail());
end

function Armory:HasPetSpells()
    return self:SetGetPetValue("HasSpells", _G.HasPetSpells());
end

function Armory:HasPetUI()
    if ( self:PetsEnabled() ) then
        local pets = self:GetPets();
        if ( #pets == 0 and self.character == self.player ) then
            return _G.HasPetUI();
        end
        local _, unitClass = self:UnitClass("player");
        return #pets > 0, strupper(unitClass) == "HUNTER";
    end
end

function Armory:HasWandEquipped()
    return self:SetGetCharacterValue("HasWandEquipped", _G.HasWandEquipped());
end

function Armory:IsPersistentPet()
    return (_G.UnitName("pet") or UNKNOWN) ~= UNKNOWN and _G.UnitCreatureFamily("pet");
end

function Armory:InRepairMode()
   return self:SetGetCharacterValue("InRepairMode", _G.InRepairMode());
end

function Armory:IsResting()
   return self:SetGetCharacterValue("IsResting", _G.IsResting());
end

function Armory:IsXPUserDisabled()
   return self:SetGetCharacterValue("IsXPUserDisabled", _G.IsXPUserDisabled());
end

function Armory:PetExists(pet, unit)
    local dbEntry = self.selectedDbBaseEntry;

    if ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    return dbEntry:Contains("Pets", pet);
end

----------------------------------------------------------

function Armory:SetBagItem(id, index)
    local link = self:GetContainerItemLink(id, index);
    if ( link ) then
        GameTooltip:SetHyperlink(link);

        if ( id == ARMORY_MAIL_CONTAINER ) then
            local daysLeft = Armory:GetContainerInboxItemDaysLeft(id, index);
            if ( daysLeft ) then
                if ( daysLeft >= 1 ) then
                    daysLeft = LIGHTYELLOW_FONT_COLOR_CODE.."  "..format(DAYS_ABBR, floor(daysLeft)).." "..FONT_COLOR_CODE_CLOSE;
                else
                    daysLeft = RED_FONT_COLOR_CODE.."  "..SecondsToTime(floor(daysLeft * 24 * 60 * 60))..FONT_COLOR_CODE_CLOSE;
                end
                GameTooltip:AppendText(daysLeft);
                GameTooltip:Show();
            end

        elseif ( id == ARMORY_AUCTIONS_CONTAINER or id == ARMORY_NEUTRAL_AUCTIONS_CONTAINER ) then
            local timeLeft, timestamp = self:GetInventoryContainerValue(id, "TimeLeft"..index);
            if ( timeLeft ) then
                local timeLeftScanned = SecondsToTime(time() - timestamp, true);
                if ( timeLeftScanned ~= "" ) then
                    timeLeftScanned = " "..string.format(GUILD_BANK_LOG_TIME, timeLeftScanned);
                end

                local tooltipLines = self:Tooltip2Table(GameTooltip);
                local remaining = "?";
                if ( _G["AUCTION_TIME_LEFT"..timeLeft] ) then
                    remaining = _G["AUCTION_TIME_LEFT"..timeLeft];
                end
                table.insert(tooltipLines, 2, self:Text2String(remaining..timeLeftScanned, 1.0, 1.0, 0.6));
                self:Table2Tooltip(GameTooltip, tooltipLines);
                GameTooltip:Show();
            end
        
        elseif ( not self:IsDummyContainer(id) ) then
            self:AddEquipmentSet(GameTooltip);
        
        end
    end
end

function Armory:SetInventoryItem(unit, index, dontShow, tooltip, link)
    if ( index ) then
        local hasItem, hasCooldown, repairCost;
        if ( link ) then
            hasItem = true;
        else
            hasItem, hasCooldown, repairCost = self:SetInventoryItemInfo(unit, index);
        end
        if ( hasItem and not dontShow ) then
            link = link or self:GetInventoryItemLink("player", index);
            if ( link ) then
                if ( not tooltip ) then
                    GameTooltip:SetHyperlink(link);
                    self:AddEquipmentSet(GameTooltip);
                else
                    tooltip:SetHyperlink(link);
                    if ( PawnUpdateTooltip ) then
                         PawnUpdateTooltip(tooltip:GetName(), "SetHyperlink", link);
                         if ( PawnAttachIconToTooltip ) then
                            PawnAttachIconToTooltip(tooltip, true, link);
                         end
                    end

                    local tooltipLines = self:Tooltip2Table(tooltip, true);
                    local realm, character = self:GetPaperDollLastViewed();
                    table.insert(tooltipLines, 1, self:Text2String(character.." "..realm, 0.5, 0.5, 0.5));
                    self:Table2Tooltip(tooltip, tooltipLines, 4);
                    tooltip:Show();
                end
            end
        end
        return hasItem, hasCooldown, repairCost;
    end
end

function Armory:SetInventoryItemInfo(unit, index)
    if ( index ) then
        local hasItem, hasCooldown, repairCost;
        self:PrepareTooltip();
        hasItem, hasCooldown, repairCost = self.tooltip:SetInventoryItem("player", index);
        self:ReleaseTooltip();
        return self:SetGetCharacterValue("InventoryItem"..index, hasItem, hasCooldown, repairCost);
    end
end

function Armory:SetItemLink(button, link)
    -- to enable hooks
    button.link = link;
end

function Armory:SetPortraitTexture(frame, unit)
    frame:SetTexture(self:GetPortraitTexture(unit));
    return "Portrait1";
end

function Armory:SetGlyph(id, talentGroup)
    local link = self:GetGlyphLink(id, talentGroup);
    if ( (link or "") ~= "" ) then
        GameTooltip:SetHyperlink(link);
    end
end

function Armory:SetQuestLogItem(itemType, id)
    local link = self:GetQuestLogItemLink(itemType, id);
    if ( link ) then
        GameTooltip:SetHyperlink(link);
    end
end

function Armory:SetQuestLogRewardSpell()
    local link = self:GetQuestLogSpellLink();
    if ( link ) then
        GameTooltip:SetHyperlink(link);
    end
end

function Armory:SetSpell(id, bookType)
    local link = self:GetSpellLink(id, bookType);
    if ( link ) then
        GameTooltip:SetHyperlink(link);
    end
end

function Armory:SetTalent(index, id, inspect, pet, talentGroup, preview)
    local link = self:GetTalentLink(index, id, inspect, pet, talentGroup);
    if ( link ) then
        GameTooltip:SetHyperlink(link);
    end
end

function Armory:SetTradeSkillItem(index, reagent)
    if ( index ) then
        local link;
        if ( reagent ) then
            link = self:GetTradeSkillReagentItemLink(index, reagent);
        else
            link = self:GetTradeSkillItemLink(index);
        end
        if ( link ) then
            GameTooltip:SetHyperlink(link);
        end
    end
end

function Armory:SetUnitAura(unit, index, filter)
    local tooltipLines = self:GetBuffTooltip(unit, index, filter);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines, 1);
    else
        local name = self:UnitAura(unit, index, filter);
        GameTooltip:SetText(name);
    end
    GameTooltip:Show();
end

----------------------------------------------------------

function Armory:UnitArmor(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Armor", _G.UnitArmor(unit));
    end
    return self:SetGetCharacterValue("Armor", _G.UnitArmor(unit));
end

function Armory:UnitAttackBothHands(unit)
    return self:SetGetCharacterValue("AttackBothHands", _G.UnitAttackBothHands("player"));
end

function Armory:UnitAttackPower(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackPower", _G.UnitAttackPower(unit));
    end
    return self:SetGetCharacterValue("AttackPower", _G.UnitAttackPower(unit));
end

function Armory:UnitAttackSpeed(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackSpeed", _G.UnitAttackSpeed(unit));
    end
    return self:SetGetCharacterValue("AttackSpeed", _G.UnitAttackSpeed(unit));
end

function Armory:UnitAura(unit, index, filter)
    return self:GetBuff(unit, index, filter);
end

function Armory:UnitCharacterPoints(unit)
    return self:SetGetCharacterValue("CharacterPoints", _G.UnitCharacterPoints("player"));
end

function Armory:UnitClass(unit)
    return self:SetGetCharacterValue("Class", _G.UnitClass("player"));
end

function Armory:UnitCreatureFamily(unit)
    return self:SetGetPetValue("Family", _G.UnitCreatureFamily("pet"));
end

function Armory:UnitDamage(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Damage", _G.UnitDamage(unit));
    end
    return self:SetGetCharacterValue("Damage", _G.UnitDamage(unit));
end

function Armory:UnitDefense(unit)
   return self:SetGetCharacterValue("Defense", _G.UnitDefense("player"));
end

function Armory:UnitFactionGroup(unit)
    return self:SetGetCharacterValue("FactionGroup", _G.UnitFactionGroup("player"));
end

function Armory:UnitHasMana(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HasMana", _G.UnitHasMana(unit));
    end
    return self:SetGetCharacterValue("HasMana", _G.UnitHasMana(unit));
end

function Armory:UnitHasRelicSlot(unit)
    return self:SetGetCharacterValue("HasRelicSlot", _G.UnitHasRelicSlot("player"));
end

function Armory:UnitHasResSickness(unit)
    local hasResSickness = false;
    local texture;
    local index = 1;

    unit = "player";

    if ( _G.UnitDebuff(unit, index) ) then
        while ( _G.UnitDebuff(unit, index) ) do
            texture = _G.UnitDebuff(unit, index);
            if ( texture == "Interface\\Icons\\Spell_Shadow_DeathScream" ) then
                hasResSickness = true;
                break;
            end
            index = index + 1;
        end
    end

    return self:SetGetCharacterValue("HasResSickness", hasResSickness);
end

function Armory:UnitHealth(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Health", _G.UnitHealth(unit));
    end
    return self:SetGetCharacterValue("Health", _G.UnitHealth(unit));
end

function Armory:UnitHealthMax(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthMax", _G.UnitHealthMax(unit));
    end
    return self:SetGetCharacterValue("HealthMax", _G.UnitHealthMax(unit));
end

function Armory:UnitIsDeadOrGhost(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("IsDead", _G.UnitIsDeadOrGhost(unit));
    end
    return self:SetGetCharacterValue("IsDead", _G.UnitIsDeadOrGhost(unit));
end

function Armory:UnitLevel(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Level", _G.UnitLevel(unit));
    end
    return self:SetGetCharacterValue("Level", _G.UnitLevel(unit));
end

function Armory:UnitMana(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Mana", _G.UnitMana(unit));
    end
    return self:SetGetCharacterValue("Mana", _G.UnitMana(unit));
end

function Armory:UnitManaMax(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("ManaMax", _G.UnitManaMax(unit));
    end
    return self:SetGetCharacterValue("ManaMax", _G.UnitManaMax(unit));
end

function Armory:UnitName(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetCharacterValue("Pet", _G.UnitName(unit));
    end
    return self.character; --:SetGetCharacterValue("Name", _G.UnitName(unit));
end

function Armory:UnitPowerType(unit)
    return self:SetGetCharacterValue("PowerType", _G.UnitPowerType("player"));
end

function Armory:UnitPVPName(unit)
    return self:SetGetCharacterValue("PVPName", _G.UnitPVPName("player"));
end

function Armory:UnitRace(unit)
    return self:SetGetCharacterValue("Race", _G.UnitRace("player"));
end

function Armory:UnitRangedAttack(unit)
    return self:SetGetCharacterValue("RangedAttack", _G.UnitRangedAttack("player"));
end

function Armory:UnitRangedAttackPower(unit)
    return self:SetGetCharacterValue("RangedAttackPower", _G.UnitRangedAttackPower("player"));
end

function Armory:UnitRangedDamage(unit)
    return self:SetGetCharacterValue("RangedDamage", _G.UnitRangedDamage("player"));
end

function Armory:UnitResistance(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Resistance"..index,  _G.UnitResistance(unit, index));
        end
        return self:SetGetCharacterValue("Resistance"..index,  _G.UnitResistance(unit, index));
    end
end

function Armory:UnitSex(unit)
    return self:SetGetCharacterValue("Sex", _G.UnitSex("player"));
end

function Armory:UnitStat(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Stat"..index,  _G.UnitStat(unit, index));
        end
        return self:SetGetCharacterValue("Stat"..index,  _G.UnitStat(unit, index));
    end
end

function Armory:UnitXP(unit)
    return self:SetGetCharacterValue("XP", _G.UnitXP("player"));
end

function Armory:UnitXPMax(unit)
    return self:SetGetCharacterValue("XPMax", _G.UnitXPMax("player"));
end

----------------------------------------------------------
-- Miscellaneous stubs
----------------------------------------------------------

function Armory:ComputePetBonus(stat, value)
    local _, unitClass = Armory:UnitClass("player");
    unitClass = strupper(unitClass);
    if( unitClass == "WARLOCK" ) then
        if( WARLOCK_PET_BONUS[stat] ) then
            return value * WARLOCK_PET_BONUS[stat];
        else
            return 0;
        end
    elseif( unitClass == "HUNTER" ) then
        if( HUNTER_PET_BONUS[stat] ) then
            return value * HUNTER_PET_BONUS[stat];
        else
            return 0;
        end
    end

    return 0;
end

function Armory:GetDodgeBlockParryChanceFromDefense()
    local base, modifier = Armory:UnitDefense("player");
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (Armory:UnitLevel("player")*5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

function Armory:GetKeyRingSize()
    local numKeyringSlots = self:GetContainerNumSlots(KEYRING_CONTAINER);
    local maxSlotNumberFilled = 0;
    local numItems = 0;
    for i=1, numKeyringSlots do
        local texture = self:GetContainerItemInfo(KEYRING_CONTAINER, i);
        -- Update max slot
        if ( texture and i > maxSlotNumberFilled) then
            maxSlotNumberFilled = i;
        end
        -- Count how many items you have
        if ( texture ) then
            numItems = numItems + 1;
        end
    end

    -- Round to the nearest 4 rows that will hold the keys
    local modulo = maxSlotNumberFilled % 4;
    local size;
    if ( (modulo == 0) and (numItems < maxSlotNumberFilled) ) then
        size = maxSlotNumberFilled;
    else
        -- Only expand if the number of keys in the keyring exceed or equal the max slot filled
        size = maxSlotNumberFilled + (4 - modulo);
    end
    size = min(size, numKeyringSlots);

    return size;
end
