local BLT = LibStub("AceAddon-3.0"):GetAddon("BLT")
local L = LibStub("AceLocale-3.0"):GetLocale("BLT")
local AC = LibStub("AceConfig-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local LibDualSpec = LibStub("LibDualSpec-1.0")
BLT.version = "BLT v"..GetAddOnMetadata("BLT", "Version")

local math, max, random, floor = _G.math, _G.max, _G.random, _G.floor
local select, pairs, strupper = _G.select, _G.pairs, _G.strupper
local tinsert, tremove, tsort, tconcat = table.insert, table.remove, table.sort, table.concat
local format, upper, find = string.format, string.upper, string.find
local contains, clearList = BLT.contains, BLT.clearList

-- Local variables --
local db
local defaults = {
    profile = {
        enable              = true,
        scale               = 50,
        offset              = 50,
        posX                = 300,
        posY                = 800,
        iconSize            = 50,
        iconOffsetY         = 10,
        iconBorderSize      = 2,
        iconFont            = "Friz Quadrata TT",
        iconTextSize        = 28,
        iconTextAnchor      = "CENTER",
        iconTextColor       = {r = 1, g = 1, b = 1, a = 1},
        barWidth            = 50,
        barHeight           = 50,
        barOffset           = 50,
        barOffsetX          = 50,
        barFont             = "Friz Quadrata TT",
        barPlayerTextSize   = 11,
        barTargetTextSize   = 9,
        barCDTextSize       = 11,
        barTargetTextCutoff = -30,
        barTargetTextAnchor = "LEFT",
        barTargetTextColor  = {r = 1, g = 1, b = 1, a = 1},
        barPlayerTextColor  = {r = 1, g = 1, b = 1, a = 1},
        barCDTextColor      = {r = 1, g = 1, b = 1, a = 1},
        barTargetTextPosX   = 50,
        barTargetTextPosY   = 10,
        split    	        = 2,
        texture  	        = "Blizzard",
        cooldowns 	 	    = {
            [29166] = true, -- Innervate
            [48477] = true, -- Rebirth
            [34477] = true, -- Misdirection
            [31821] = true, -- Aura Mastery
            [64205] = true, -- Divine Sacrifice
            [6940]  = true, -- Hand of Sacrifice
            [47788] = true, -- Guardian Spirit
            [64901] = true, -- Hymn of Hope
            [33206] = true, -- Pain Suppression
            [57934] = true, -- Tricks of the Trade
            [16190] = true, -- Mana Tide Totem
            [47883] = true, -- Soulstone Resurrection
            [54589] = true  -- Glowing Twilight Scale
        }
    }
}

local sortNr = {}
local trackCooldownClasses = {}
local trackCooldownSpecs = {}
local trackCooldownSpells = {}
local trackCooldownSpellIDs = {}
local trackCooldownSpellCooldown = {}
local trackTalents = {}
local talentRequired = {}
local trackCooldownAlternativeSpellCooldown = {}
local trackItems = {}
local trackItemSpellIDs = {}
local trackItemSpellIDsHC = {}
local trackItemID = {}
local trackItemCooldown = {}
local trackLvlRequirement = {}
local trackGlyphs = {}
local trackGlyphCooldown = {}
local trackCooldownTargets = {}
local trackCooldownAllUniqueSpellNames = {}
local trackCooldownAllUniqueSpellEnabledStatuses = {}
local trackCooldownAllUniqueItemNames = {}
local trackCooldownAllUniqueItemEnabledStatuses = {}
local mainFrame
local cooldown_Frames = {}
local icon_Frames = {}
local classesInGroup = {}
local playersInGroup = {}
local targetTable = {}
local scaleUI
local iconTextSize_Scale
local iconSize_Scale
local offsetBetweenCooldowns_Scale
local cooldownXOffset_Scale
local barPlayerTextSize_Scale
local barCDTextSize_Scale
local barTargetTextSize_Scale
local cooldownWidth_Scale
local cooldownHeight_Scale
local offsetBetweenIcons_Scale
local edgeOffset_Scale
local cooldownForegroundBorderOffset = 4
local iconTextSize = 0
local iconSize = 0
local offsetBetweenCooldowns = 0
local cooldownXOffset = 0
local barPlayerTextSize = 0
local barCDTextSize = 0
local barTargetTextSize = 0
local cooldownWidth = 0
local cooldownHeight = 0
local offsetBetweenIcons = 0
local edgeOffset = 0
local foundAtLeastOne = false
local isOnRightSide = false
local yOffsetMaximum = 0
local currentXOffset = 0
local currentYOffset = 0
local cooldownBottomMostElementY = 0
local cooldownCurrentXOffset = 0
local cooldownCurrentYOffset = 0
local cooldownCurrentXOffsetStart = 0
local cooldownCurrentYOffsetStart = 0
local cooldownCurrentCounter = 0
local frameColorLocked = { r=0.0, g=0.0, b=0.0, a=0.0 }
local frameColor = { r=0.0, g=0.0, b=0.0, a=0.4 }
local itemColor = { r=0.5, g=0, b=0.9, a=1.0 }
local classColors = {
    ["DEATHKNIGHT"] = "C41F3B",
    ["DRUID"] = "FF7D0A",
    ["HUNTER"] = "ABD473",
    ["MAGE"] = "69CCF0",
    ["PALADIN"] = "F58CBA",
    ["PRIEST"] = "FFFFFF",
    ["ROGUE"] = "FFF569",
    ["SHAMAN"] = "0070DE",
    ["WARLOCK"] = "9482C9",
    ["WARRIOR"] = "C79C6E"
}


-- Helper functions --
function BLT:Unit(name)
    if name then
        local class = select(2, UnitClass(name))
        if class then
            return format("|r|cFF%s|Hplayer:%s|h[%s]|h|r|cFFbebebe",classColors[strupper(class)],name,name)
        else
            return format("|r|cFFffffff%s|r|cFFbebebe",name)
        end
    else
        return "Unknown"
    end
end

function BLT:Spell(id, group)
    if group then return GetSpellLink(id) end
    if type(id) ~= "number" then return id end
    if select(3, GetSpellInfo(id)) then
        return format("\124T%s:12:12:0:0:64:64:5:59:5:59\124t|r%s|cFFbebebe",select(3, GetSpellInfo(id)), GetSpellLink(id))
    else
        return format("|r%s|cFFbebebe", GetSpellLink(id))
    end
end

function BLT:Item(id)
    if type(id) ~= "number" then return id end
    local itemLink = select(2, GetItemInfo(id))
    if itemLink then
        return itemLink
    end
end

local function Sort(list)
    tsort(list, function(a,b)
        if a.num and b.num and a.num ~= b.num then
            return a.num < b.num
        end
    end)
end

local function ConvertSliderValueToPercentageValue(value)
    -- 1 to 100, to 0.1 - 5, where 50 is 1
    local sliderPercentageValue_Min = 1
    local sliderPercentageValue_Max = 100
    local sliderPercentageValue_Middle = 50
    local retValue = 0
    if value == sliderPercentageValue_Middle then
        retValue = 1.0
    elseif value == sliderPercentageValue_Min then
        retValue = 0.1
    elseif value > sliderPercentageValue_Middle then
        local percentage = (value - sliderPercentageValue_Middle) / (sliderPercentageValue_Max - sliderPercentageValue_Middle)
        local percentageMin = 1
        local percentageMax = 5
        retValue = percentageMin + ((percentageMax - percentageMin) * percentage)
    elseif value < sliderPercentageValue_Middle then
        local percentage = (value - sliderPercentageValue_Min) / (sliderPercentageValue_Max - sliderPercentageValue_Middle)
        local percentageMin = 0.1
        local percentageMax = 1
        retValue = percentageMin + ((percentageMax - percentageMin) * percentage)
    end

    return retValue
end

local function FormatCooldownText(cooldownLeft, printText)
    local minutes = math.floor(cooldownLeft / 60.0)
    cooldownLeft = cooldownLeft - (minutes * 60.0)
    local seconds = math.floor(cooldownLeft + 1)
    if seconds >= 60 then
        seconds = seconds - 60
        minutes = minutes + 1
    end
    local secondsStr = seconds
    if seconds <= 9 then
        secondsStr = "0" .. secondsStr
    end

    if printText then
        if minutes > 0 and seconds > 0 then
            return minutes .. "min " .. seconds .. "sec"
        elseif minutes > 0 then
            return minutes .. "min"
        else
            return seconds .. "sec"
        end
    else
        return minutes .. ":" .. secondsStr
    end
end

local function SetMainFrameLockedStatus(lockedStatus)
    if lockedStatus == true then
        mainFrame.isSetToMovable = false
        mainFrame:EnableMouse(false)
        mainFrame.texture:SetTexture(frameColorLocked.r, frameColorLocked.g, frameColorLocked.b, frameColorLocked.a)
    else
        mainFrame.isSetToMovable = true
        mainFrame:EnableMouse(true)
        mainFrame.texture:SetTexture(frameColor.r, frameColor.g, frameColor.b, frameColor.a)
    end
end

local function SetupNewScale()
    local resizeFromPixelPerfect = 1.25
    iconSize = 40 * resizeFromPixelPerfect * scaleUI * iconSize_Scale    
    iconTextSize = math.ceil(40 * resizeFromPixelPerfect * scaleUI * iconTextSize_Scale)
    barPlayerTextSize = math.ceil(40 * resizeFromPixelPerfect * scaleUI * barPlayerTextSize_Scale)
    barCDTextSize = math.ceil(40 * resizeFromPixelPerfect * scaleUI * barCDTextSize_Scale)
    barTargetTextSize = math.ceil(40 * resizeFromPixelPerfect * scaleUI * barTargetTextSize_Scale)
    cooldownWidth = 130 * resizeFromPixelPerfect * scaleUI * cooldownWidth_Scale
    cooldownHeight = 18 * resizeFromPixelPerfect * scaleUI * cooldownHeight_Scale
    cooldownXOffset = 5 * resizeFromPixelPerfect * scaleUI * cooldownXOffset_Scale
    offsetBetweenIcons = 5 * resizeFromPixelPerfect * scaleUI * offsetBetweenIcons_Scale
    offsetBetweenCooldowns = 2.4 * resizeFromPixelPerfect * scaleUI * offsetBetweenCooldowns_Scale
    edgeOffset = 3 * resizeFromPixelPerfect * scaleUI * edgeOffset_Scale
end

local function IsOnRightSide()
    if not mainFrame then return end

    local point, _, _, xOfs = mainFrame:GetPoint()

    if point == "TOPRIGHT" or point == "RIGHT" or point == "BOTTOMRIGHT" then
        return true
    end

    if point == "TOPLEFT" then  -- We might be dragging the frame
        if xOfs * mainFrame:GetScale() > UIParent:GetWidth() * 0.5 then
            return true
        end
    end

    if point == "TOP" or point == "CENTER" or point == "BOTTOM" then
        if xOfs > 0 then
            return true
        end
    end

    return false
end

local function CreateBorder(parentFrame, offset, pixels, r, g, b, a, frameLevel, frameReuse)
    local frame = frameReuse or CreateFrame("Frame", nil, parentFrame)
    local texture1 = frame:CreateTexture(nil, "BACKGROUND")
    texture1:SetAllPoints()
    texture1:SetTexture(0, 0, 0, 0)
    frame.texture = texture1
    frame:SetFrameLevel(frameLevel)

    frame:SetBackdrop({nil, edgeFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0, edgeSize = pixels, insets = { left = 0, right = 0, top = 0, bottom = 0}})
    frame:SetBackdropBorderColor(r, g, b, a)
    frame:SetPoint("TOPLEFT", -offset, offset)
    frame:SetPoint("BOTTOMRIGHT", offset, -offset)

    if parentFrame.borders == nil then
        parentFrame.borders = {}
    end
    tinsert(parentFrame.borders, frame)
    return frame
end

local function ModifyFontString(fontString, font, fontSize, fontOutline, textColor, point1, point2, relativeFrame, relativePoint1, relativePoint2, ofsx1, ofsy1, ofsx2, ofsy2, posH, posV, setShadow)
    fontString:SetFont(font, fontSize, fontOutline)
    fontString:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    if point1 then
        fontString:SetPoint(point1, relativeFrame, relativePoint1, ofsx1, ofsy1)
    end
    if point2 then
        fontString:SetPoint(point2, relativeFrame, relativePoint2, ofsx2, ofsy2)
    end
    if posH then
        fontString:SetJustifyH(posH)
    end
    if posV then
        fontString:SetJustifyV(posV)
    end
    if setShadow then
        fontString:SetShadowOffset(0, 0)
        fontString:SetShadowColor(0, 0, 0, 0)
    end
end

local function CooldownFrame_OnEnter(self)
    -- Check if the caller is valid
    if self then
        -- Set the tooltip
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 2, iconSize + 2)
        GameTooltip:SetText(self.name)

        -- Loop through all classes
        for i=1, #classesInGroup do
            -- Check if the current player has a valid name
            local playerName = playersInGroup[i]
            if playerName and playerName ~= UNKNOWNOBJECT then
                local function AddTooltip(text, r, g, b)
                    if BLT.playerClass[playerName] then
                        GameTooltip:AddLine(playerName .. ": " .. "Level " .. BLT.playerLevel[playerName] .. " " .. BLT.playerClass[playerName] .. " (" .. BLT.playerSpecs[playerName] .. ", " .. BLT.playerTalentPoints[playerName] .. ")" .. text, r, g, b)
                    end
                end
                -- Make sure the spell icon exists and is shown for the current class
                for n=1, #trackCooldownClasses do
                    -- Check if the current player is the class we are looking for
                    if trackCooldownClasses[n] == classesInGroup[i] then
                        -- Check if the current spell is the one we are looking for
                        if trackCooldownSpells[n] == self.name then
                            -- Check if the role of the current player is what we are looking for
                            if BLT:IsPlayerValidForSpellCooldown(playerName, n) then
                                local hasCD
                                for j=1, #cooldown_Frames do
                                    if cooldown_Frames[j].name == self.name and cooldown_Frames[j].playerName == playerName and cooldown_Frames[j].isUsed then
                                        hasCD = true
                                        break
                                    end
                                end
                                if hasCD then
                                    AddTooltip("",1, 0, 0)
                                elseif UnitIsDeadOrGhost(playerName) then
                                    AddTooltip(" [Dead]", 0.4, 0.4, 0.4)
                                elseif not UnitInRange(playerName) then
                                    AddTooltip(" [not in Range]", 0.2, 0.4, 1)
                                else
                                    AddTooltip("",1, 1, 1)
                                end
                            end
                        end
                    end
                end
                for n=1, #trackItems do
                    if trackItems[n] == self.name then
                        if BLT:IsPlayerValidForItemCooldown(playerName, n) then
                            local hasCD
                            for j=1, #cooldown_Frames do
                                if cooldown_Frames[j].name == self.name and cooldown_Frames[j].playerName == playerName and cooldown_Frames[j].isUsed then
                                    hasCD = true
                                    break
                                end
                            end
                            if hasCD then
                                AddTooltip("",1, 0, 0)
                            elseif UnitIsDeadOrGhost(playerName) then
                                AddTooltip(" [Dead]", 0.4, 0.4, 0.4)
                            elseif not UnitInRange(playerName) then
                                AddTooltip(" [not in Range]", 0.2, 0.4, 1)
                            else
                                AddTooltip("",1, 1, 1)
                            end
                        end
                    end
                end
            end
        end
        GameTooltip:Show()
    end
end

local function CooldownFrame_OnLeave()
    -- Hide the tooltip
    GameTooltip:Hide()
end


-- Core functions --
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(_, elapsed)
    if not mainFrame then return end
    -- Update the Backend
    BLT:UpdateBackend(elapsed)
    -- Update the UI
    BLT:UpdateUI()
end)

local function HandleEvent(_, event, ...)
    -- If addon is disabled don't process any events
    if not db.enable then return end
    -- Check if we received a combat log event
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- Get the variables needed from the event
        local _, combatEvent, _, sourceName, _, _, destName = ...

        -- Check if we have a source for the event
        if sourceName and sourceName ~= "" then
            -- Check if we dealt damage with a spell
            local targetSpellId, targetSpellName
            -- Check if a spell was missed/resisted
            if combatEvent == "SPELL_MISSED" then
                local spellId, spellName = select(9,...)
                targetSpellId, targetSpellName = spellId, spellName

                -- Check if a spell was evaded
            elseif combatEvent == "DAMAGE_SHIELD_MISSED" then
                local spellId, spellName = select(9,...)
                targetSpellId, targetSpellName = spellId, spellName

                -- Check if we cast a spell
            elseif combatEvent == "SPELL_CAST_SUCCESS" then
                local spellId, spellName = select(9,...)
                if spellName == "Tricks of the Trade" or spellName == "Misdirection" then
                    targetTable[sourceName] = destName
                else
                    targetSpellId, targetSpellName = spellId, spellName
                end
                if spellName == "Readiness" then
                    for i=1, #cooldown_Frames do
                        if cooldown_Frames[i].playerName == sourceName and cooldown_Frames[i].name == "Misdirection" then
                            BLT:UpdateCooldownFrame(cooldown_Frames[i], false)
                            break
                        end
                    end
                elseif spellName == "Cold Snap" then
                    for i=1, #cooldown_Frames do
                        if cooldown_Frames[i].playerName == sourceName and cooldown_Frames[i].name == "Ice Block" then
                            BLT:UpdateCooldownFrame(cooldown_Frames[i], false)
                            break
                        end
                    end
                end

                -- Check if we got a spell aura applied
            elseif combatEvent == "SPELL_AURA_APPLIED" then
                local spellId, spellName = select(9,...)
                if spellName == "Guardian Spirit" then
                    if BLT:TimeLeft(BLT.gsTimer) ~= 0 then
                        BLT:CancelTimer(BLT.gsTimer)
                    end
                    BLT.gsTimer = BLT:ScheduleTimer("GuardianSpiritTimer", 9.5)
                elseif not (spellName == "Hymn of Hope" or spellName == "Divine Hymn" or spellName == "Anti-Magic Zone" or spellName == "Misdirection" or spellName == "Tricks of the Trade") then
                    targetSpellId, targetSpellName = spellId, spellName
                end

            elseif combatEvent == "SPELL_AURA_REMOVED" then
                local spellId, spellName = select(9,...)
                -- 'Misdirection' and 'Tricks of the Trade' CDs should only be triggered when successfully procced or cancelled
                if (spellName == "Misdirection" and spellId == 34477) or
                        (spellName == "Tricks of the Trade" and spellId == 57934) then
                    targetSpellId, targetSpellName = spellId, spellName
                    if contains(targetTable, sourceName, true) then
                        destName = targetTable[sourceName]
                        targetTable[sourceName] = nil
                    end
                elseif spellName == "Guardian Spirit" then
                    for i=1, #cooldown_Frames do
                        local frame = cooldown_Frames[i]
                        if frame.name == spellName and frame.playerName == sourceName and BLT:TimeLeft(BLT.gsTimer) == 0 then
                            frame.spellTimestamp = GetTime() + 60
                            frame.maximumCooldown = 60
                            break
                        end
                    end
                end

            elseif combatEvent == "SPELL_HEAL" then
                local spellName = select(10,...)
                if spellName == "Guardian Spirit" then
                    BLT:CancelTimer(BLT.gsTimer)
                end

            elseif combatEvent == "SPELL_RESURRECT" then
                local spellId, spellName = select(9,...)
                if spellName == "Rebirth" then
                    targetSpellId, targetSpellName = spellId, spellName
                end
            end

            -- Check if the spell cast is in the list of track cooldowns
            if targetSpellName ~= "" and (contains(trackCooldownSpells, targetSpellName) or (contains(trackItemSpellIDs, targetSpellId) or contains(trackItemSpellIDsHC, targetSpellId))) then
                -- Check if the caster is in our party/raid
                if contains(playersInGroup, sourceName) then
                    -- Check if the role of the caster is what we are looking for
                    for i=1, #trackCooldownSpells do
                        if trackCooldownSpells[i] == targetSpellName then
                            if BLT:IsPlayerValidForSpellCooldown(sourceName, i) and BLT:IsCooldownSpellEnabled(targetSpellName) then
                                if not trackCooldownTargets[i] then
                                    destName = nil
                                end
                                BLT:CreateCooldownFrame(sourceName, targetSpellName, targetSpellId, destName)
                                break
                            end
                        end
                    end
                    for i=1, #trackItems do
                        if trackItemSpellIDs[i] == targetSpellId or trackItemSpellIDsHC[i] == targetSpellId then
                            if BLT:IsPlayerValidForItemCooldown(sourceName, i) and BLT:IsCooldownItemEnabled(trackItems[i]) then
                                BLT:CreateCooldownFrame(sourceName, trackItems[i], trackItemID[i], nil, true)
                                break
                            end
                        end
                    end
                end
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "arena" then
            local hasAtLeastOneCooldownFrameUp = false
            for i=1, #cooldown_Frames do
                local frame = cooldown_Frames[i]
                if frame.isUsed then
                    hasAtLeastOneCooldownFrameUp = true
                end
            end
            if hasAtLeastOneCooldownFrameUp then
                -- Set all cooldown frames to not be used anymore
                for i=1, #cooldown_Frames do
                    local frame = cooldown_Frames[i]
                    if frame.isUsed then
                        frame.spellTimestamp = GetTime()
                        frame.maximumCooldown = 0
                    end
                end
            end
        end
    end
end
function BLT:GuardianSpiritTimer() end

function BLT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BLT_DB", defaults, "Default")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    LibDualSpec:EnhanceDatabase(self.db, "BLT");
    db = self.db.profile

    self:SetupOptions()
    self.OnInitialize = nil
end

function BLT:OnEnable()
    for k,_ in pairs(self.spells) do
        for k2, v2 in pairs(self.spells[k]) do
            self:AddTrackCooldownSpell(v2.nr, k, v2.spec, k2, v2.id, v2.cd, v2.talent, v2.talReq, v2.altCd, v2.lvlReq, v2.tar, v2.glyph, v2.glyphCd)
        end
    end
    for k,_ in pairs(self.items) do
        for k2, v2 in pairs(self.items[k]) do
            self:AddTrackCooldownItem(v2.nr, k2, v2.spellId, v2.spellIdHc, v2.itemId, v2.cd)
        end
    end
    self:CreateMainFrame()
    self:CreateBackendFrame()
    self:SetAnchors(true)
    self:SetOptions()
end

function BLT:OnDisable()
    mainFrame:UnregisterAllEvents()
    mainFrame = nil
    self:ClearLists()
end

function BLT:OnProfileChanged(event, database, newProfileKey)
    db = database.profile

    self:SetAnchors(true, true)
    self:SetOptions()
end

function BLT:SetupOptions()
    AC:RegisterOptionsTable("BLT", self.options)
    AC:RegisterOptionsTable("BLT Commands", self.commands, "blt")
    ACR:RegisterOptionsTable(L["Icons"], self.options.args.icons)
    ACR:RegisterOptionsTable(L["Bars"], self.options.args.bars)
    ACR:RegisterOptionsTable(L["Cooldowns"], self.options.args.cooldowns)
    ACR:RegisterOptionsTable(L["Profiles"], LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    LibDualSpec:EnhanceOptions(LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), self.db)

    self.optionsFrames = {}
    self.optionsFrames.BLT = ACD:AddToBlizOptions("BLT", self.version, nil, "general")
    self.optionsFrames.Icon = ACD:AddToBlizOptions(L["Icons"], L["Icons"], self.version)
    self.optionsFrames.Bar = ACD:AddToBlizOptions(L["Bars"], L["Bars"], self.version)
    self.optionsFrames.Spells = ACD:AddToBlizOptions(L["Cooldowns"], L["Cooldowns"], self.version)
    self.optionsFrames.Profiles = ACD:AddToBlizOptions(L["Profiles"], L["Profiles"], self.version)

    self.SetupOptions = nil
end

function BLT:ShowConfig()
    -- Open the profiles tab before, so the menu expands
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Profiles)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.BLT)
end

function BLT:AddTrackCooldownSpell(nr, class, spec, spellName, spellId, maxCd, talent, talReq, altCd, lvlReq, tar, glyph, glyphCd)
    tinsert(sortNr, nr)
    tinsert(trackCooldownClasses, class)
    tinsert(trackCooldownSpecs, spec)
    tinsert(trackCooldownSpells, spellName)
    tinsert(trackCooldownSpellIDs, spellId)
    tinsert(trackCooldownSpellCooldown, maxCd)
    tinsert(trackTalents, talent)
    tinsert(talentRequired, talReq)
    tinsert(trackCooldownAlternativeSpellCooldown, altCd)
    tinsert(trackLvlRequirement, lvlReq)
    tinsert(trackCooldownTargets, tar)
    tinsert(trackGlyphs, glyph)
    tinsert(trackGlyphCooldown, glyphCd)

    if not contains(trackCooldownAllUniqueSpellNames, spellName) then
        tinsert(trackCooldownAllUniqueSpellNames, spellName)
        tinsert(trackCooldownAllUniqueSpellEnabledStatuses, true)
    end
end

function BLT:AddTrackCooldownItem(nr, itemName, spellId, spellIdHc, itemId, cd)
    tinsert(sortNr, nr)
    tinsert(trackItems, itemName)
    tinsert(trackItemSpellIDs, spellId)
    tinsert(trackItemSpellIDsHC, spellIdHc)
    tinsert(trackItemID, itemId)
    tinsert(trackItemCooldown, cd)

    if not contains(trackCooldownAllUniqueItemNames, itemName) then
        tinsert(trackCooldownAllUniqueItemNames, itemName)
        tinsert(trackCooldownAllUniqueItemEnabledStatuses, true)
    end
end

function BLT:CreateMainFrame()
    mainFrame = nil
    -- Create the main frame
    mainFrame = CreateFrame("Frame", "BLT_MainFrame", UIParent)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(false)
    mainFrame:SetClampedToScreen(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetPoint("CENTER")
    mainFrame:SetScript("OnDragStart", function(s) s:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(s) s:StopMovingOrSizing(); BLT:SetAnchors() end)
    mainFrame:SetWidth(200)
    mainFrame:SetHeight(200)
    local texture1 = mainFrame:CreateTexture("ARTWORK")
    texture1:SetAllPoints()
    texture1:SetTexture(frameColorLocked.r, frameColorLocked.g, frameColorLocked.b, frameColorLocked.a)
    mainFrame.texture = texture1
    mainFrame:SetFrameLevel(1)
    mainFrame.isSetToHidden = false
    mainFrame.isSetToMovable = false

    -- Register all events we need
    mainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:SetScript("OnEvent", HandleEvent)
end

function BLT:CreateIconFrame(name, id, class, isItem)
    -- Check if we do not already have a frame with this name
    local frame
    for i=1, #icon_Frames do
        if icon_Frames[i].name == name then
            frame = icon_Frames[i]
            return i
        end
    end
    if frame == nil then
        -- Create a new frame
        frame = CreateFrame("Frame", "TrackCooldownIconFrame_" .. #icon_Frames, mainFrame)
        frame:SetWidth(iconSize)
        frame:SetHeight(iconSize)
        local texture1 = frame:CreateTexture(nil, "BACKGROUND")
        texture1:SetAllPoints()
        frame.texture = texture1
        frame.name = name
        frame.id = id
        frame.isItem = isItem
        frame.class = class
        frame.count = 0
        frame:SetPoint("TOPLEFT", 0, 0)
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", CooldownFrame_OnEnter)
        frame:SetScript("OnLeave", CooldownFrame_OnLeave)

        frame.innerBorder = CreateBorder(frame, -1 - db.iconBorderSize, 1, 0, 0, 0, 0.7, frame:GetFrameLevel() + 2)
        frame.outerBorder = CreateBorder(frame, 0, 1, 0, 0, 0, 0.8, frame:GetFrameLevel() + 2)
        if class then
            local playerClassColor = RAID_CLASS_COLORS[upper(class):gsub(" ", "")]
            if playerClassColor then
                frame.colorBorder = CreateBorder(frame, -1, db.iconBorderSize,  playerClassColor.r,  playerClassColor.g, playerClassColor.b, 1, frame:GetFrameLevel() + 1)
            end
        else
            frame.colorBorder = CreateBorder(frame, -1, db.iconBorderSize, itemColor.r, itemColor.g, itemColor.b, itemColor.a, frame:GetFrameLevel() + 1)
        end

        local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ModifyFontString(fontString, Media:Fetch("font", db.iconFont), iconTextSize, "OUTLINE", db.iconTextColor)
        fontString:SetPoint(db.iconTextAnchor)
        frame.fontString = fontString

        -- Set the new texture of the frame
        local icon
        icon = isItem and GetItemIcon(id) or select(3, GetSpellInfo(self:GetSpellIDFromName(name)))
        if icon then
            texture1:SetTexture(icon)
            texture1:SetTexCoord(unpack({.08, .92, .08, .92}))
            texture1:SetPoint('TOPLEFT', 2, -2)
            texture1:SetPoint('BOTTOMRIGHT', -2, 2)
        end

        tinsert(icon_Frames, frame)
    end

    return #icon_Frames
end

function BLT:CreateCooldownFrame(playerName, name, id, target, isItem)
    -- Check if we do not already have a frame with this name
    local frame
    for i=1, #cooldown_Frames do
        if cooldown_Frames[i].playerName == playerName and cooldown_Frames[i].name == name then
            frame = cooldown_Frames[i]
            tremove(cooldown_Frames, i)
            tinsert(cooldown_Frames, frame)
            break
        end
    end
    local cooldownColor = { r=0.8, g=0.8, b=0.8, a=1.0 }
    local cooldownBackgroundColor = { r=0.2, g=0.2, b=0.2, a=1.0 }
    if frame == nil then
        -- Create a new frame
        frame = CreateFrame("Frame", "TrackCooldownFrame_" .. #cooldown_Frames, mainFrame)
        frame:SetWidth(cooldownWidth - cooldownForegroundBorderOffset)
        frame:SetHeight(cooldownHeight - cooldownForegroundBorderOffset)
        local texture1 = frame:CreateTexture("ARTWORK")
        texture1:SetTexture(Media:Fetch("statusbar", db.texture))
        texture1:SetAllPoints()
        texture1:SetVertexColor(cooldownColor.r, cooldownColor.g, cooldownColor.b, cooldownColor.a)
        frame.texture = texture1
        frame.playerName = playerName
        frame.name = name
        frame.id = id
        frame:SetPoint("TOPLEFT", 0, 0)
        frame:SetFrameLevel(2)

        local frameBackground = CreateFrame("Button", "TrackCooldownFrameBackground_" .. #cooldown_Frames, mainFrame)
        frameBackground:SetWidth(cooldownWidth)
        frameBackground:SetHeight(cooldownHeight)
        local texture2 = frameBackground:CreateTexture("ARTWORK")
        texture2:SetTexture(Media:Fetch("statusbar", db.texture))
        texture2:SetAllPoints()
        texture2:SetVertexColor(cooldownBackgroundColor.r, cooldownBackgroundColor.g, cooldownBackgroundColor.b, cooldownBackgroundColor.a)
        frameBackground.texture = texture2
        frameBackground:SetFrameLevel(1)
        frameBackground:EnableMouse(true)
        frame.frameBackground = frameBackground

        CreateBorder(frameBackground, -2, 1, 0, 0, 0, 0.7, frame:GetFrameLevel() + 1)
        CreateBorder(frameBackground, -1, 1, cooldownColor.r, cooldownColor.g, cooldownColor.b, cooldownColor.a, frame:GetFrameLevel() + 1)
        CreateBorder(frameBackground, 0, 1, 0, 0, 0, 0.8, frame:GetFrameLevel() + 1)

        local fontFrame = CreateFrame("Frame", "TrackCooldownFontFrame_" .. #cooldown_Frames, frameBackground)

        local texture3 = fontFrame:CreateTexture(nil, "BACKGROUND")
        texture3:SetAllPoints()
        texture3:SetTexture(0, 0, 0, 0)
        fontFrame.texture = texture3
        fontFrame:SetFrameLevel(4)
        frame.fontFrame = fontFrame
        fontFrame:SetPoint("TOPLEFT", -0, 0)
        fontFrame:SetPoint("BOTTOMRIGHT", 0, -0)

        -- Player name font string
        local fontString = fontFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ModifyFontString(fontString, Media:Fetch("font", db.barFont), barPlayerTextSize, "OUTLINE", db.barPlayerTextColor, "TOPLEFT", "BOTTOMRIGHT", fontFrame,"TOPLEFT", "BOTTOMRIGHT", 4, 0, -40, 0, "LEFT", "MIDDLE", true)
        frame.fontString = fontString

        -- CD time font string
        local fontString2 = fontFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ModifyFontString(fontString2, Media:Fetch("font", db.barFont), barCDTextSize, "OUTLINE", db.barCDTextColor, "TOPLEFT", "BOTTOMRIGHT", fontFrame,"TOPLEFT", "BOTTOMRIGHT", 4, 0, -3, 0, "RIGHT", "MIDDLE", true)
        fontString2.cooldownLeft = 0
        frame.fontString2 = fontString2

        -- Target name font string
        local fontString3 = fontFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        ModifyFontString(fontString3, Media:Fetch("font", db.barFont), barTargetTextSize, "OUTLINE", db.barTargetTextColor, "TOPLEFT", "BOTTOMRIGHT", fontFrame,"TOPLEFT", "BOTTOMRIGHT", db.barTargetTextPosX, db.barTargetTextPosY-10, db.barTargetTextCutoff, db.barTargetTextPosY+10, db.barTargetTextAnchor, "MIDDLE", true)
        frame.fontString3 = fontString3

        tinsert(cooldown_Frames, frame)
    end
    local maximumCooldown
    if db.debugBars then
        maximumCooldown = random(5, 80)
    else
        maximumCooldown = self:GetMaximumCooldown(name, playerName, isItem)
    end
    frame.spellTimestamp = GetTime() + maximumCooldown
    frame.maximumCooldown = maximumCooldown
    frame:Show()
    frame.frameBackground:Show()
    frame.fontFrame:Show()
    frame.isUsed = true
    frame.target = target

    local class
    for i=1, #trackCooldownSpells do
        if trackCooldownSpells[i] == name then
            class = trackCooldownClasses[i]
            break
        end
    end
    if not class then
        class = UnitClass(playerName)
    end
    if class then
        local playerClassColor = RAID_CLASS_COLORS[upper(class):gsub(" ", "")]
        if playerClassColor then
            frame.texture:SetVertexColor(cooldownColor.r * playerClassColor.r, cooldownColor.g * playerClassColor.g, cooldownColor.b * playerClassColor.b, cooldownColor.a)
            frame.frameBackground.texture:SetVertexColor(cooldownBackgroundColor.r * playerClassColor.r, cooldownBackgroundColor.g * playerClassColor.g, cooldownBackgroundColor.b * playerClassColor.b, cooldownBackgroundColor.a)
            frame.frameBackground.borders[2]:SetBackdropBorderColor(playerClassColor.r, playerClassColor.g, playerClassColor.b, 1)
        end
    else
        frame.texture:SetVertexColor(cooldownColor.r * itemColor.r, cooldownColor.g * itemColor.g, cooldownColor.b * itemColor.b, cooldownColor.a * itemColor.a)
        frame.frameBackground.texture:SetVertexColor(cooldownBackgroundColor.r * itemColor.r, cooldownBackgroundColor.g * itemColor.g, cooldownBackgroundColor.b * itemColor.b, cooldownBackgroundColor.a * itemColor.a)
        frame.frameBackground.borders[2]:SetBackdropBorderColor(itemColor.r, itemColor.g, itemColor.b, itemColor.a)
    end

    return frame
end

function BLT:UpdateUI()
    -- Get a list of all classes we have in our party/raid (including ourself)
    clearList(classesInGroup)
    clearList(playersInGroup)

    local selfPlayerName = UnitName("player")

    local unitTarget = "player"
    local class, classFileName = UnitClass(unitTarget)
    if class then
        tinsert(classesInGroup, classFileName)
        tinsert(playersInGroup, selfPlayerName)
    end

    if UnitExists("raid1") then
        for i=1, 40 do
            local unitTarget = "raid" .. i
            local unitName = UnitName(unitTarget)
            if unitName ~= selfPlayerName then
                local class, classFileName = UnitClass(unitTarget)
                if class then
                    tinsert(classesInGroup, classFileName)
                    tinsert(playersInGroup, unitName)
                end
            end
        end
    elseif UnitExists("party1") then
        for i=1, 4 do
            local unitTarget = "party" .. i
            local unitName = UnitName(unitTarget)
            if unitName ~= selfPlayerName then
                local class, classFileName = UnitClass(unitTarget)
                if class then
                    tinsert(classesInGroup, classFileName)
                    tinsert(playersInGroup, unitName)
                end
            end
        end
    end

    -- Hide all spell icon frames
    for i=1, #icon_Frames do
        local frame = icon_Frames[i]
        frame:Hide()
        frame.count = 0
    end

    -- Loop through all classes
    for i=1, #classesInGroup do
        -- Check if the current player has a valid name
        local playerName = playersInGroup[i]
        if playerName and playerName ~= UNKNOWNOBJECT then
            -- Make sure the icon exists and is shown for the current class
            for n=1, #trackCooldownClasses do
                -- Check if the current track cooldown is enabled
                if self:IsCooldownSpellEnabled(trackCooldownSpells[n]) then
                    -- Check if the current player is the class we are looking for
                    if trackCooldownClasses[n] == classesInGroup[i] then
                        -- Check if the current player is valid for the cooldown
                        if self:IsPlayerValidForSpellCooldown(playerName, n) then
                            -- Create or get an icon index for it
                            local index = self:CreateIconFrame(trackCooldownSpells[n], trackCooldownSpellIDs[n], trackCooldownClasses[n])
                            local frame = icon_Frames[index]
                            frame.num = sortNr[n]
                            frame:Show()
                            if not UnitIsDeadOrGhost(playerName) then
                                frame.count = frame.count + 1
                            end
                        end
                    end
                end
            end
            for n=1, #trackItems do
                if self:IsCooldownItemEnabled(trackItems[n]) and self:IsPlayerValidForItemCooldown(playerName, n) then
                    -- Create or get an icon index for it
                    local index = self:CreateIconFrame(trackItems[n], trackItemID[n], nil, true)
                    local frame = icon_Frames[index]
                    frame.num = sortNr[#sortNr-#trackItems + n]
                    frame:Show()
                    if not UnitIsDeadOrGhost(playerName) then
                        frame.count = frame.count + 1
                    end
                end
            end
        end
    end

    if db.debugIcons == true then
        for n=1, #trackCooldownClasses do
            -- Check if the current track cooldown is enabled
            if self:IsCooldownSpellEnabled(trackCooldownSpells[n]) then
                local index = self:CreateIconFrame(trackCooldownSpells[n], trackCooldownSpellIDs[n], trackCooldownClasses[n])
                local frame = icon_Frames[index]
                frame.num = sortNr[n]
                frame:Show()
            end
        end
        for n=1, #trackItems do
            if self:IsCooldownItemEnabled(trackItems[n]) then
                local index = self:CreateIconFrame(trackItems[n], trackItemID[n], nil, true)
                local frame = icon_Frames[index]
                frame.num = sortNr[#sortNr-#trackItems + n]
                frame:Show()
            end
        end
    end

    if db.debugBars == true then
        local isInUse = false
        for i=1,#cooldown_Frames do
            if cooldown_Frames[i].isUsed and cooldown_Frames[i].isTest then
                isInUse = true
                break
            end
        end
        if isInUse == false then
            db.debugBars = false
            ACR:NotifyChange(L["Bars"])
        end
    end

    -- Loop through all spell icon frames
    isOnRightSide = IsOnRightSide()
    yOffsetMaximum = edgeOffset * 2.0
    currentXOffset = edgeOffset
    currentYOffset = edgeOffset
    foundAtLeastOne = false
    for i=1, #icon_Frames do
        -- Update the current spell icon frame
        self:UpdateIconFrame(i)
    end
    yOffsetMaximum = yOffsetMaximum - offsetBetweenIcons

    -- Update the frame visibility
    if foundAtLeastOne then
        if mainFrame.isSetToHidden == false then
            mainFrame:Show()
        end

        -- Make sure the frame is only scaled to the bottom
        local diff = yOffsetMaximum - mainFrame:GetHeight()
        local point, _, _, xOfs, yOfs = mainFrame:GetPoint()
        if point == "LEFT" or point == "RIGHT" or point == "CENTER" then
            yOfs = yOfs - (diff * 0.5)
        elseif point == "BOTTOM" or point == "BOTTOMLEFT" or point == "BOTTOMRIGHT" then
            yOfs = yOfs - diff
        end
        mainFrame:SetPoint(point, xOfs, yOfs)

        -- Set the new width and height of the main frame
        local xOffsetMaximum = (edgeOffset * 2.0) + iconSize
        mainFrame:SetWidth(xOffsetMaximum)
        mainFrame:SetHeight(yOffsetMaximum)
    else
        mainFrame:Hide()
    end

    Sort(icon_Frames)
end

function BLT:UpdateUISize()
    SetupNewScale()

    -- Loop through all spell icon frames
    for i=1, #icon_Frames do
        -- Update the size of the current frame
        local frame = icon_Frames[i]

        frame:SetWidth(iconSize)
        frame:SetHeight(iconSize)

        ModifyFontString(frame.fontString, Media:Fetch("font", db.iconFont), iconTextSize, "OUTLINE", db.iconTextColor)
    end

    -- Loop through all cooldown frames
    for i=1, #cooldown_Frames do
        -- Update the size of the current frame
        local frame = cooldown_Frames[i]

        frame:SetWidth(cooldownWidth - cooldownForegroundBorderOffset)
        frame:SetHeight(cooldownHeight - cooldownForegroundBorderOffset)

        frame.frameBackground:SetWidth(cooldownWidth)
        frame.frameBackground:SetHeight(cooldownHeight)
        ModifyFontString(frame.fontString, Media:Fetch("font", db.barFont), barPlayerTextSize, "OUTLINE", db.barPlayerTextColor)
        ModifyFontString(frame.fontString2, Media:Fetch("font", db.barFont), barCDTextSize, "OUTLINE", db.barCDTextColor)
        ModifyFontString(frame.fontString3, Media:Fetch("font", db.barFont), barTargetTextSize, "OUTLINE", db.barTargetTextColor, "TOPLEFT", "BOTTOMRIGHT", frame.fontFrame, "TOPLEFT", "BOTTOMRIGHT", db.barTargetTextPosX, db.barTargetTextPosY-10, db.barTargetTextCutoff, db.barTargetTextPosY+10, db.barTargetTextAnchor)
    end
end

function BLT:GetPlayerCooldowns(frame)
    local players = {}
    for i=1, #classesInGroup do
        local playerName = playersInGroup[i]
        if playerName and playerName ~= UNKNOWNOBJECT then
            for n=1, #trackCooldownClasses do
                if trackCooldownClasses[n] == classesInGroup[i] then
                    if trackCooldownSpells[n] == frame.name then
                        if BLT:IsPlayerValidForSpellCooldown(playerName, n) then
                            local hasCD
                            for j=1, #cooldown_Frames do
                                if cooldown_Frames[j].name == frame.name and cooldown_Frames[j].playerName == playerName and cooldown_Frames[j].isUsed then
                                    hasCD = true
                                    break
                                end
                            end
                            if not hasCD then
                                tinsert(players, UnitIsDeadOrGhost(playerName) and playerName .. " [Dead!]" or playerName)
                            end
                        end
                    end
                end
            end
            for n=1, #trackItems do
                if trackItems[n] == frame.name then
                    if BLT:IsPlayerValidForItemCooldown(playerName, n) then
                        local hasCD
                        for j=1, #cooldown_Frames do
                            if cooldown_Frames[j].name == frame.name and cooldown_Frames[j].playerName == playerName and cooldown_Frames[j].isUsed then
                                hasCD = true
                                break
                            end
                        end
                        if not hasCD then
                            tinsert(players, UnitIsDeadOrGhost(playerName) and playerName .. " [Dead!]" or playerName)
                        end
                    end
                end
            end
        end
    end
    return players
end

function BLT:UpdateIconFrame(index)
    -- Check if the current frame is used
    local frame = icon_Frames[index]
    local name = frame.name

    -- Update the cooldown frames of the spell icon
    cooldownBottomMostElementY = 0
    cooldownCurrentCounter = 0
    cooldownCurrentXOffset = currentXOffset + iconSize + cooldownXOffset
    if isOnRightSide then
        cooldownCurrentXOffset = currentXOffset - cooldownXOffset - cooldownWidth
    end
    cooldownCurrentYOffset = currentYOffset
    cooldownCurrentXOffsetStart = cooldownCurrentXOffset
    cooldownCurrentYOffsetStart = cooldownCurrentYOffset

    local count = 0
    for i=1, #cooldown_Frames do
        local cooldownFrame = cooldown_Frames[i]
        if cooldownFrame.isUsed then
            if cooldownFrame.name == name then
                if frame:IsShown() then
                    self:UpdateCooldownFrame(cooldownFrame, true)
                else
                    self:UpdateCooldownFrame(cooldownFrame, false)
                end
                count = count + 1
            end
        end
    end

    -- Check if the current frame is used
    if frame:IsShown() then
        foundAtLeastOne = true

        -- Set the position of the current frame
        frame:SetPoint("TOPLEFT", currentXOffset, -currentYOffset)

        -- Set the text of the current frame
        local fontString = frame.fontString
        if frame.count - count < 0 then
            fontString:SetText("" .. 0)
        else
            fontString:SetText("" .. (frame.count - count))
        end

        -- Shift-Click on an icon will print whose cooldowns are ready to be used
        frame:SetScript("OnMouseDown", function()
            if IsShiftKeyDown() then
                local players = self:GetPlayerCooldowns(frame)
                if GetNumPartyMembers() ~= 0 then
                    SendChatMessage("BLT: " .. L["%s is ready to be used by %s"]:format(contains(trackCooldownSpellIDs, frame.id) and self:Spell(frame.id, true) or self:Item(frame.id, true), next(players) and tconcat(players, ", ") or "—"), BLT:GetGroupState())
                else
                    self:Print(L["%s is ready to be used by %s"]:format(contains(trackCooldownSpellIDs, frame.id) and self:Spell(frame.id or self:Item(frame.id)), next(players) and tconcat(players, ", ") or "—"))
                end
            end
        end)

        -- Go to the next position
        local diff = 0
        if cooldownBottomMostElementY + cooldownHeight - iconSize > currentYOffset then
            diff = diff + ((cooldownBottomMostElementY + cooldownHeight - iconSize) - currentYOffset)
        end
        diff = diff + iconSize + offsetBetweenIcons
        currentYOffset = currentYOffset + diff
        yOffsetMaximum = yOffsetMaximum + diff
    end
end

function BLT:UpdateCooldownFrame(frame, show)
    local frameBackground = frame.frameBackground
    local fontFrame = frame.fontFrame

    -- Check if we should show the frame
    if show and (UnitIsConnected(frame.playerName) or db.debugBars) then
        -- Check if the current frame is used
        if frame.isUsed and (UnitInRaid(frame.playerName) or UnitInParty(frame.playerName) or UnitName("player") == frame.playerName or db.debugBars) then
            -- Set the position of the current frame
            frameBackground:SetPoint("TOPLEFT", cooldownCurrentXOffset, -cooldownCurrentYOffset)
            frame:SetPoint("TOPLEFT", cooldownCurrentXOffset + (cooldownForegroundBorderOffset * 0.5), -cooldownCurrentYOffset - (cooldownForegroundBorderOffset * 0.5))
            frameBackground:Show()
            fontFrame:Show()
            frame:Show()
            cooldownBottomMostElementY = max(cooldownBottomMostElementY, cooldownCurrentYOffset)

            -- Set the width of the current frame
            local cooldownLeft = frame.spellTimestamp - GetTime()
            local percentage = cooldownLeft / frame.maximumCooldown
            if percentage == 0 then
                percentage = 0.000001
            end
            frame:SetWidth((cooldownWidth - cooldownForegroundBorderOffset) * percentage)

            -- Set the text of the current frame
            frame.fontString:SetText(frame.playerName)
            frame.fontString2:SetText(FormatCooldownText(cooldownLeft))
            if db.displayTargets and frame.target then
                frame.fontString3:SetText(frame.target)
            else
                frame.fontString3:SetText("")
            end

            -- Shift-Click on the current frame will print when the cooldown will be ready in chat
            frameBackground:SetScript("OnMouseDown", function()
                if IsShiftKeyDown() then
                    if GetNumPartyMembers() ~= 0 then
                        SendChatMessage("BLT: " .. L["%s's %s will be ready in %s"]:format(frame.playerName, contains(trackCooldownSpellIDs, frame.id) and self:Spell(frame.id, true) or self:Item(frame.id, true), FormatCooldownText(cooldownLeft,true)), BLT:GetGroupState())
                    else
                        self:Print(L["%s's %s will be ready in %s"]:format(self:Unit(frame.playerName), contains(trackCooldownSpellIDs, frame.id) and self:Spell(frame.id) or self:Item(frame.id), FormatCooldownText(cooldownLeft,true)))
                    end
                end
            end)

            -- Check if the current frame has no cooldown left
            if cooldownLeft < 0 then
                -- Set that the frame is not used anymore
                frame.isUsed = false
                frameBackground:Hide()
                fontFrame:Hide()
                frame:Hide()

                if db.message then
                    self:Print(L["%s's %s is ready!"]:format(self:Unit(frame.playerName), contains(trackCooldownSpellIDs, frame.id) and self:Spell(frame.id) or self:Item(frame.id)))
                end
            else
                -- Go to the next position
                cooldownCurrentCounter = cooldownCurrentCounter + 1
                if cooldownCurrentCounter == db.split then
                    cooldownCurrentYOffset = cooldownCurrentYOffsetStart
                    if isOnRightSide then
                        cooldownCurrentXOffset = cooldownCurrentXOffset - cooldownWidth - offsetBetweenCooldowns
                    else
                        cooldownCurrentXOffset = cooldownCurrentXOffset + cooldownWidth + offsetBetweenCooldowns
                    end
                    cooldownCurrentCounter = 0
                else
                    cooldownCurrentYOffset = cooldownCurrentYOffset + cooldownHeight + offsetBetweenCooldowns
                end
            end
        end
    else
        -- Hide the cooldown frame
        frame.isUsed = false
        frameBackground:Hide()
        fontFrame:Hide()
        frame:Hide()
    end
end

function BLT:UpdateIconBorders()
    for i=1, #icon_Frames do
        local frame = icon_Frames[i]
        self.clearList(frame.borders)

        CreateBorder(frame, -1 - db.iconBorderSize, 1, 0, 0, 0, 0.7, frame:GetFrameLevel() + 2, frame.outerBorder)
        CreateBorder(frame, 0, 1, 0, 0, 0, 0.8, frame:GetFrameLevel() + 2, frame.innerBorder)

        if frame.class then
            local playerClassColor = RAID_CLASS_COLORS[upper(frame.class):gsub(" ", "")]
            if playerClassColor then
                CreateBorder(frame, -1, db.iconBorderSize, playerClassColor.r, playerClassColor.g, playerClassColor.b, 1, frame:GetFrameLevel() + 1, frame.colorBorder)
            end
        else
            CreateBorder(frame, -1, db.iconBorderSize, itemColor.r, itemColor.g, itemColor.b, itemColor.a, frame:GetFrameLevel() + 1, frame.colorBorder)
        end
    end
end

function BLT:DebugCooldownBars()
    local hasAtLeastOneCooldownFrameUp = false
    for i=1, #cooldown_Frames do
        local frame = cooldown_Frames[i]
        if frame.isUsed and frame.isTest then
            hasAtLeastOneCooldownFrameUp = true
        end
    end
    if hasAtLeastOneCooldownFrameUp then
        -- Set all test cooldown frames to not be used anymore
        for i=1, #cooldown_Frames do
            local frame = cooldown_Frames[i]
            if frame.isUsed and frame.isTest then
                frame.isUsed = false
                frame.frameBackground:Hide()
                frame.fontFrame:Hide()
                frame:Hide()
            end
        end
    else
        -- Debug code to see how it looks with multiple cooldowns up
        for n=1, #icon_Frames do
            local frame = icon_Frames[n]
            local name = frame.name
            local id = frame.id
            local isItem = frame.isItem

            for i=1, 7 do
                local testFrame = self:CreateCooldownFrame("Test" .. i, name, id, db.displayTargets and "Target" .. i+1 or nil, isItem)
                testFrame.isTest = true
            end
        end
    end
end

function BLT:IsCooldownSpellEnabled(spellName)
    for i=1, #trackCooldownAllUniqueSpellNames do
        if trackCooldownAllUniqueSpellNames[i] == spellName then
            return trackCooldownAllUniqueSpellEnabledStatuses[i]
        end
    end
    return true
end

function BLT:IsCooldownItemEnabled(itemName)
    for i=1, #trackCooldownAllUniqueItemNames do
        if trackCooldownAllUniqueItemNames[i] == itemName then
            return trackCooldownAllUniqueItemEnabledStatuses[i]
        end
    end
    return true
end

function BLT:IsPlayerValidForSpellCooldown(playerName, index)
    if self.playerSpecs[playerName] and self.playerLevel[playerName] >= trackLvlRequirement[index] then
        if trackCooldownSpecs[index] == self.playerSpecs[playerName] or trackCooldownSpecs[index] == "Any" then
            if trackTalents[index] == "nil" or (trackTalents[index] ~= "nil" and talentRequired[index] == false) then
                return true
            elseif self.playerTalentsSpecced[playerName] and contains(self.playerTalentsSpecced[playerName], trackTalents[index], true) then
                return true
            end
        end
    end
    return false
end

function BLT:IsPlayerValidForItemCooldown(playerName, index)
    if self.playerEquipment[playerName] and contains(self.playerEquipment[playerName], trackItems[index]) then
        return true
    end
    return false
end

function BLT:GetMaximumCooldown(name, playerName, isItem)
    if isItem then
        for i=1, #trackItems do
            if trackItems[i] == name then
                return trackItemCooldown[i]
            end
        end
    else
        local cooldown = 0
        for i=1, #trackCooldownSpells do
            if trackCooldownSpells[i] == name and
                    (trackCooldownSpecs[i] == "Any" or trackCooldownSpecs[i] == self.playerSpecs[playerName]) then
                if self.playerTalentsSpecced[playerName] and contains(self.playerTalentsSpecced[playerName],trackTalents[i],true) then
                    for talent,rank in pairs(self.playerTalentsSpecced[playerName]) do
                        if talent == trackTalents[i] then
                            if trackCooldownAlternativeSpellCooldown[i] ~= "nil" then
                                cooldown = trackCooldownSpellCooldown[i] - (trackCooldownAlternativeSpellCooldown[i] * rank)
                                break
                            else
                                cooldown = trackCooldownSpellCooldown[i]
                                break
                            end
                        end
                    end
                else
                    cooldown = trackCooldownSpellCooldown[i]
                end
                if self.playerGlyphs[playerName] and find(self.playerGlyphs[playerName], trackGlyphs[i]) then
                    cooldown = cooldown - trackGlyphCooldown[i]
                end
            end
        end
        return cooldown
    end
    return 0
end

function BLT:GetSpellIDFromName(spellName)
    for i=1, #trackCooldownSpells do
        if trackCooldownSpells[i] == spellName then
            return trackCooldownSpellIDs[i]
        end
    end
    return ""
end

function BLT:SetOptions()
    scaleUI = ConvertSliderValueToPercentageValue(db.scale)
    cooldownXOffset_Scale = ConvertSliderValueToPercentageValue(db.barOffsetX)
    barPlayerTextSize_Scale = ConvertSliderValueToPercentageValue(db.barPlayerTextSize)
    barCDTextSize_Scale = ConvertSliderValueToPercentageValue(db.barCDTextSize)
    barTargetTextSize_Scale = ConvertSliderValueToPercentageValue(db.barTargetTextSize)
    cooldownWidth_Scale = ConvertSliderValueToPercentageValue(db.barWidth)
    cooldownHeight_Scale = ConvertSliderValueToPercentageValue(db.barHeight)
    offsetBetweenIcons_Scale = ConvertSliderValueToPercentageValue(db.iconOffsetY)
    offsetBetweenCooldowns_Scale = ConvertSliderValueToPercentageValue(db.barOffset)
    edgeOffset_Scale = ConvertSliderValueToPercentageValue(db.offset)
    iconTextSize_Scale = ConvertSliderValueToPercentageValue(db.iconTextSize)
    iconSize_Scale = ConvertSliderValueToPercentageValue(db.iconSize)

    for i=1, #cooldown_Frames do
        cooldown_Frames[i].texture:SetTexture(Media:Fetch("statusbar", db.texture))
    end

    for i=1, #trackCooldownAllUniqueSpellNames do
        trackCooldownAllUniqueSpellEnabledStatuses[i] = db.cooldowns[trackCooldownSpellIDs[i]]
    end
    for i=1, #trackCooldownAllUniqueItemNames do
        trackCooldownAllUniqueItemEnabledStatuses[i] = db.cooldowns[trackItemID[i]]
    end

    for i=1, #icon_Frames do
        icon_Frames[i].fontString:ClearAllPoints()
        icon_Frames[i].fontString:SetPoint(db.iconTextAnchor)
    end

    if db.enable then
        mainFrame:Show()
        mainFrame.isSetToHidden = false
    else
        mainFrame:Hide()
        mainFrame.isSetToHidden = true
    end

    SetMainFrameLockedStatus(db.locked)

    self:UpdateUISize()
end

function BLT:SetAnchors(useDB, conf)
    local x, y
    if useDB then
        if conf then
            x, y = db.posX, db.posY-yOffsetMaximum
        else
            x, y = db.posX, db.posY-200
        end
        if x and y then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("BOTTOMLEFT", x, y)
        else
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("CENTER", 0, 0)
        end
    else
        x, y = floor(mainFrame:GetLeft() + 0.5), floor(mainFrame:GetTop() + 0.5)
        db.posX, db.posY = x, y
    end
    ACR:NotifyChange("BLT")
end

function BLT:Toggle(setting)
    if setting then
        if setting == true then
            db.enable = true
        else
            db.enable = false
        end
    else
        db.enable = not db.enable
    end
    ACR:NotifyChange("BLT")
    self:SetOptions()
end

function BLT:Lock()
    db.locked = not db.locked
    ACR:NotifyChange("BLT")
    self:SetOptions()
end