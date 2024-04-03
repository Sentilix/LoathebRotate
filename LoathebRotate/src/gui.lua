local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Initialize GUI frames. Shouldn't be called more than once
function LoathebRotate:initGui()

    local mainFrame = LoathebRotate:createMainFrame()
    local titleFrame = LoathebRotate:createTitleFrame(mainFrame)
    LoathebRotate:createMainFrameButtons(titleFrame)
    LoathebRotate:createModeFrame(mainFrame)
    local rotationFrame = LoathebRotate:createRotationFrame(mainFrame)
    local backupFrame = LoathebRotate:createBackupFrame(mainFrame, rotationFrame)
    LoathebRotate:createHorizontalResizer(mainFrame, LoathebRotate.db.profile.windows[1], "LEFT", rotationFrame, backupFrame)
    LoathebRotate:createHorizontalResizer(mainFrame, LoathebRotate.db.profile.windows[1], "RIGHT", rotationFrame, backupFrame)

    local historyFrame = LoathebRotate:createHistoryFrame()
    local historyTitleFrame = LoathebRotate:createTitleFrame(historyFrame, L['SETTING_HISTORY'])
    LoathebRotate:createHistoryFrameButtons(historyTitleFrame)
    local historyBackgroundFrame = LoathebRotate:createBackgroundFrame(historyFrame, LoathebRotate.constants.titleBarHeight, LoathebRotate.db.profile.history.height)
    LoathebRotate:createTextFrame(historyBackgroundFrame)
    LoathebRotate:createCornerResizer(historyFrame, LoathebRotate.db.profile.history)

    LoathebRotate:drawHunterFrames(mainFrame)
    LoathebRotate:createDropHintFrame(mainFrame)

    LoathebRotate:updateDisplay()
end

-- Show/Hide main window based on user settings
function LoathebRotate:updateDisplay()
    for _, mainFrame in pairs(LoathebRotate.mainFrames) do
        if LoathebRotate:isActive() then
            mainFrame:Show()
        else
            if (LoathebRotate.db.profile.hideNotInRaid) then
                mainFrame:Hide()
            end
        end
    end
end

-- render / re-render hunter frames to reflect table changes.
function LoathebRotate:drawHunterFrames(mainFrame)

    -- Different height to reduce spacing between both groups
    mainFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight + LoathebRotate.constants.titleBarHeight)
    mainFrame.rotationFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight)

    LoathebRotate:drawList(LoathebRotate.rotationTables.rotation, mainFrame.rotationFrame, mainFrame)

    if (#LoathebRotate.rotationTables.backup > 0) then
        mainFrame:SetHeight(mainFrame:GetHeight() + LoathebRotate.constants.rotationFramesBaseHeight)
    end

    mainFrame.backupFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight)
    LoathebRotate:drawList(LoathebRotate.rotationTables.backup, mainFrame.backupFrame, mainFrame)

end

-- Method provided for convenience, until hunters will be dedicated to a specific mainFrame
function LoathebRotate:drawHunterFramesOfAllMainFrames()
    for _, mainFrame in pairs(LoathebRotate.mainFrames) do
        LoathebRotate:drawHunterFrames(mainFrame)
    end
end

-- Handle the render of a single hunter frames group
function LoathebRotate:drawList(hunterList, parentFrame, mainFrame)

    local index = 1
    local hunterFrameHeight = LoathebRotate.constants.hunterFrameHeight
    local hunterFrameSpacing = LoathebRotate.constants.hunterFrameSpacing

    if (#hunterList < 1 and parentFrame == mainFrame.backupFrame) then
        parentFrame:Hide()
    else
        parentFrame:Show()
    end

    for key,hunter in pairs(hunterList) do

        -- Using existing frame if possible
        if (hunter.frame == nil) then
            LoathebRotate:createHunterFrame(hunter, parentFrame, mainFrame)
        else
            hunter.frame:SetParent(parentFrame)
        end

        hunter.frame:ClearAllPoints()
        hunter.frame:SetPoint('LEFT', 10, 0)
        hunter.frame:SetPoint('RIGHT', -10, 0)

        -- Setting top margin
        local marginTop = 10 + (index - 1) * (hunterFrameHeight + hunterFrameSpacing)
        hunter.frame:SetPoint('TOP', parentFrame, 'TOP', 0, -marginTop)

        -- Handling parent windows height increase
        if (index == 1) then
            parentFrame:SetHeight(parentFrame:GetHeight() + hunterFrameHeight)
            mainFrame:SetHeight(mainFrame:GetHeight() + hunterFrameHeight)
        else
            parentFrame:SetHeight(parentFrame:GetHeight() + hunterFrameHeight + hunterFrameSpacing)
            mainFrame:SetHeight(mainFrame:GetHeight() + hunterFrameHeight + hunterFrameSpacing)
        end

        -- SetColor
        LoathebRotate:setHunterFrameColor(hunter)

        hunter.frame:Show()
        hunter.frame.hunter = hunter

        index = index + 1
    end
end

-- Hide the hunter frame
function LoathebRotate:hideHunter(hunter)
    if (hunter.frame ~= nil) then
        hunter.frame:Hide()
    end
end

-- Refresh a single hunter frame
function LoathebRotate:refreshHunterFrame(hunter)
    LoathebRotate:setHunterFrameColor(hunter)
    LoathebRotate:setHunterName(hunter)
    LoathebRotate:updateBlindIcon(hunter)
end

-- Toggle blind icon display based on addonVersion
function LoathebRotate:updateBlindIcon(hunter)
    if (
        not LoathebRotate.db.profile.showBlindIcon or
        hunter.addonVersion ~= nil or
        hunter.name == UnitName('player') or
        not LoathebRotate:isHunterOnline(hunter)
    ) then
        hunter.frame.blindIconFrame:Hide()
    else
        hunter.frame.blindIconFrame:Show()
    end
end

-- Refresh all blind icons
function LoathebRotate:refreshBlindIcons()
    for _, hunter in pairs(LoathebRotate.hunterTable) do
        LoathebRotate:updateBlindIcon(hunter)
    end
end

-- Set the hunter frame color regarding it's status
function LoathebRotate:setHunterFrameColor(hunter)

    local color = LoathebRotate:getUserDefinedColor('neutral')

    if (not LoathebRotate:isHunterOnline(hunter)) then
        color = LoathebRotate:getUserDefinedColor('offline')
    elseif (not LoathebRotate:isHunterAlive(hunter)) then
        color = LoathebRotate:getUserDefinedColor('dead')
    elseif (hunter.nextTranq) then
        color = LoathebRotate:getUserDefinedColor('active')
    end

    hunter.frame.texture:SetVertexColor(color:GetRGB())
end

-- Set the hunter's name regarding its class and group index
function LoathebRotate:setHunterName(hunter)

    local currentText = hunter.frame.text:GetText()
    local currentFont, _, currentOutline = hunter.frame.text:GetFont()

    local newText = hunter.name
    local newFont = LoathebRotate:getPlayerNameFont()
    local newOutline = LoathebRotate.db.profile.useNameOutline and "OUTLINE" or ""
    local hasClassColor = false
    local shadowOpacity = 1.0

    if (LoathebRotate.db.profile.useClassColor) then
        local _, _classFilename, _ = UnitClass(hunter.name)
        if (_classFilename) then
            if _classFilename == "PRIEST" then
                shadowOpacity = 1.0
            elseif _classFilename == "ROGUE" or _classFilename == "PALADIN" then
                shadowOpacity = 0.8
            elseif _classFilename == "SHAMAN" then
                shadowOpacity = 0.4
            else
                shadowOpacity = 0.6
            end
            local _, _, _, _classColorHex = GetClassColor(_classFilename)
            newText = WrapTextInColorCode(hunter.name, _classColorHex)
            hasClassColor = true
        end
    end

    if (LoathebRotate.db.profile.prependIndex) then
        local rowIndex = 0
        local rotationTable = LoathebRotate.rotationTables.rotation
        for index = 1, #rotationTable, 1 do
            local candidate = rotationTable[index]
            if (candidate ~= nil and candidate.name == hunter.name) then
                rowIndex = index
                break
            end
        end
        if (rowIndex > 0) then
            local indexText = string.format("%s.", rowIndex)
            local color = LoathebRotate:getUserDefinedColor('indexPrefix')
            newText = color:WrapTextInColorCode(indexText)..newText
        end
    end

    local targetName, buffMode, assignedName, assignedAt
    if LoathebRotate.db.profile.appendTarget then
        if hunter.targetGUID then
            targetName, buffMode = self:getHunterTarget(hunter)
            if targetName == "" then targetName = nil end
        end
        assignedName, assignedAt = self:getHunterAssignment(hunter)
        if assignedName == "" then assignedName = nil end
    end
    local showTarget
    if assignedName then
        showTarget = true
    elseif not targetName then
        showTarget = false
    else
        showTarget = buffMode and (buffMode == 'not_a_buff' or buffMode == 'has_buff' or not LoathebRotate.db.profile.appendTargetBuffOnly)
    end
    hunter.showingTarget = showTarget

    if (LoathebRotate.db.profile.appendGroup and hunter.subgroup) then
        if not showTarget or not LoathebRotate.db.profile.appendTargetNoGroup then -- Do not append the group if the target name hides the group for clarity
            local groupText = string.format(LoathebRotate.db.profile.groupSuffix, hunter.subgroup)
            local color = LoathebRotate:getUserDefinedColor('groupSuffix')
            newText = newText.." "..color:WrapTextInColorCode(groupText)
        end
    end

    if showTarget then
        local targetColorName
        local blameAssignment
        if assignedName and targetName and (assignedName ~= targetName) then
            blameAssignment = hunter.cooldownStarted and assignedAt and assignedAt < hunter.cooldownStarted
        end
        if     blameAssignment then                 targetColorName = 'flashyRed'
        elseif assignedName and not targetName then targetColorName = 'white'
        elseif buffMode == 'buff_expired' then      targetColorName = assignedName and 'white' or 'darkGray'
        elseif buffMode == 'buff_lost' then         targetColorName = 'lightRed'
        elseif buffMode == 'has_buff' then          targetColorName = 'white'
        else                                        targetColorName = 'white'
        end
        local mode = self:getMode()
        if assignedName and (not targetName or buffMode == 'buff_expired') then
            targetName = assignedName
        elseif type(mode.customTargetName) == 'function' then
            targetName = mode.customTargetName(mode, hunter, targetName)
        end
        if targetName then
            newText = newText..LoathebRotate.colors['white']:WrapTextInColorCode(" > ")
            newText = newText..LoathebRotate.colors[targetColorName]:WrapTextInColorCode(targetName)
        end
    end

    if (newFont ~= currentFont or newOutline ~= currentOutline) then
        hunter.frame.text:SetFont(newFont, 12, newOutline)
    end
    if (newText ~= currentText) then
        hunter.frame.text:SetText(newText)
    end
    if (newText ~= currentText or newOutline ~= currentOutline) then
        if (LoathebRotate.db.profile.useNameOutline) then
            hunter.frame.text:SetShadowOffset(0, 0)
        else
            hunter.frame.text:SetShadowColor(0, 0, 0, shadowOpacity)
            hunter.frame.text:SetShadowOffset(1, -1)
        end
    end

end

function LoathebRotate:startHunterCooldown(hunter, endTimeOfCooldown, endTimeOfEffect, targetGUID, buffName)
    if not endTimeOfCooldown or endTimeOfCooldown == 0 then
        local cooldown = LoathebRotate:getModeCooldown()
        if cooldown then
            endTimeOfCooldown = GetTime() + cooldown
        end
    end

    if not endTimeOfEffect or endTimeOfEffect == 0 then
        local effectDuration = LoathebRotate:getModeEffectDuration()
        if effectDuration then
            endTimeOfEffect = GetTime() + effectDuration
        else
            endTimeOfEffect = 0
        end
    end
    hunter.endTimeOfEffect = endTimeOfEffect

    hunter.cooldownStarted = GetTime()

    hunter.frame.cooldownFrame.statusBar:SetMinMaxValues(GetTime(), endTimeOfCooldown or GetTime())
    hunter.expirationTime = endTimeOfCooldown
    if endTimeOfCooldown and endTimeOfEffect and GetTime() < endTimeOfCooldown and GetTime() < endTimeOfEffect and endTimeOfEffect < endTimeOfCooldown then
        local tickWidth = 3
        local x = hunter.frame.cooldownFrame:GetWidth()*(endTimeOfEffect-GetTime())/(endTimeOfCooldown-GetTime())
        if x < 5 then
            -- If the tick is too early, it is graphically undistinguishable from the beginning of the cooldown bar, so don't bother displaying the tick
            hunter.frame.cooldownFrame.statusTick:Hide()
        else
            local xmin = x-tickWidth/2
            local xmax = xmin + tickWidth
            hunter.frame.cooldownFrame.statusTick:ClearAllPoints()
            hunter.frame.cooldownFrame.statusTick:SetPoint('TOPLEFT', xmin, 0)
            hunter.frame.cooldownFrame.statusTick:SetPoint('BOTTOMRIGHT', xmax-hunter.frame.cooldownFrame:GetWidth(), 0)
            hunter.frame.cooldownFrame.statusTick:Show()
        end
    else
        -- If there is no tick or the tick is beyond the cooldown bar, do not display the tick
        hunter.frame.cooldownFrame.statusTick:Hide()
    end
    hunter.frame.cooldownFrame:Show()

    hunter.targetGUID = targetGUID
    hunter.buffName = buffName
    if targetGUID and LoathebRotate.db.profile.appendTarget then
        LoathebRotate:setHunterName(hunter)
        if buffName and endTimeOfEffect > GetTime() then

            -- Create a ticker to refresh the name on a regular basis, for as long as the target name is displayed
            if not hunter.nameRefreshTicker or hunter.nameRefreshTicker:IsCancelled() then
                local nameRefreshInterval = 0.5
                hunter.nameRefreshTicker = C_Timer.NewTicker(nameRefreshInterval, function()
                    LoathebRotate:setHunterName(hunter)
                    -- hunter.showingTarget is computed in the setHunterName() call; use this variable to tell when to stop refreshing
                    if not hunter.showingTarget and not LoathebRotate:getMode().buffCanReturn then
                        hunter.nameRefreshTicker:Cancel()
                        hunter.nameRefreshTicker = nil
                    end
                end)
            end

            -- Also create a timer that will be triggered shortly after the expiration time of the buff
            if hunter.nameRefreshTimer and not hunter.nameRefreshTimer:IsCancelled() then
                hunter.nameRefreshTimer:Cancel()
            end
            hunter.nameRefreshTimer = C_Timer.NewTimer(endTimeOfEffect - GetTime() + 1, function()
                LoathebRotate:setHunterName(hunter)
                hunter.nameRefreshTimer = nil
            end)
        end
    end

    if hunter.buffName and hunter.endTimeOfEffect > GetTime() then
        LoathebRotate:trackHistoryBuff(hunter)
    end
end

-- Lock/Unlock the mainFrame position
function LoathebRotate:lock(lock)
    LoathebRotate.db.profile.lock = lock
    LoathebRotate:applySettings()

    if (lock) then
        LoathebRotate:printMessage(L['WINDOW_LOCKED'])
    else
        LoathebRotate:printMessage(L['WINDOW_UNLOCKED'])
    end
end
