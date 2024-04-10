local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Initialize GUI frames. Shouldn't be called more than once
function LoathebRotate:initGui()
	LoathebRotate.mainFrame = LoathebRotate:createMainFrame();

	local titleFrame = LoathebRotate:createTitleFrame(LoathebRotate.mainFrame);
	LoathebRotate:createMainFrameButtons(titleFrame);
	LoathebRotate:createModeFrame(LoathebRotate.mainFrame);
	local rotationFrame = LoathebRotate:createRotationFrame(LoathebRotate.mainFrame);
	local backupFrame = LoathebRotate:createBackupFrame(LoathebRotate.mainFrame, rotationFrame);
	LoathebRotate:createHorizontalResizer(LoathebRotate.mainFrame, LoathebRotate.db.profile.windows[1], "LEFT", rotationFrame, backupFrame);
	LoathebRotate:createHorizontalResizer(LoathebRotate.mainFrame, LoathebRotate.db.profile.windows[1], "RIGHT", rotationFrame, backupFrame);

	local historyFrame = LoathebRotate:createHistoryFrame();
	local historyTitleFrame = LoathebRotate:createTitleFrame(historyFrame, L['SETTING_HISTORY']);
	LoathebRotate:createHistoryFrameButtons(historyTitleFrame);
	local historyBackgroundFrame = LoathebRotate:createBackgroundFrame(historyFrame, LoathebRotate.constants.titleBarHeight, LoathebRotate.db.profile.history.height);
	LoathebRotate:createTextFrame(historyBackgroundFrame);
	LoathebRotate:createCornerResizer(historyFrame, LoathebRotate.db.profile.history);

	LoathebRotate:drawHealerFrames();
	LoathebRotate:createDropHintFrame(LoathebRotate.mainFrame);

	LoathebRotate:updateDisplay()
end

-- Show/Hide main window based on user settings
function LoathebRotate:updateDisplay()
	if LoathebRotate:isActive() then
		LoathebRotate.mainFrame:Show()
	else
		if (LoathebRotate.db.profile.hideNotInRaid) then
			LoathebRotate.mainFrame:Hide()
		end
	end
end

-- render / re-render healer frames to reflect table changes.
function LoathebRotate:drawHealerFrames()
	local MF = LoathebRotate.mainFrame;

	-- Different height to reduce spacing between both groups
	MF:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight + LoathebRotate.constants.titleBarHeight);
	MF.rotationFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight);
	LoathebRotate:drawList(LoathebRotate.rotationTable, MF.rotationFrame);


	if (#LoathebRotate.backupTable > 0) then
		MF:SetHeight(MF:GetHeight() + LoathebRotate.constants.rotationFramesBaseHeight);
	end

	MF.backupFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight);
	LoathebRotate:drawList(LoathebRotate.backupTable, MF.backupFrame);
end

-- Method provided for convenience, until hunters will be dedicated to a specific mainFrame
--function LoathebRotate:drawHunterFramesOfAllMainFrames()
--    for _, mainFrame in pairs(LoathebRotate.mainFrames) do
--        LoathebRotate:drawHunterFrames(mainFrame)
--    end
--end

-- Handle the render of a single healer frames group
function LoathebRotate:drawList(healerList, parentFrame)
	local MF = LoathebRotate.mainFrame;
    local index = 1;
    local healerFrameHeight = LoathebRotate.constants.healerFrameHeight;
    local healerFrameSpacing = LoathebRotate.constants.healerFrameSpacing;

    if (#healerList < 1 and parentFrame == MF.backupFrame) then
        parentFrame:Hide();
    else
        parentFrame:Show();
    end

    for key,healer in pairs(healerList) do
		-- Using existing frame if possible
		if healer.frame then
			healer.frame:SetParent(parentFrame);
		else
			LoathebRotate:createHealerFrame(healer, parentFrame);
		end

		healer.frame:ClearAllPoints();
		healer.frame:SetPoint('LEFT', 10, 0);
		healer.frame:SetPoint('RIGHT', -10, 0);

		-- Setting top margin
		local marginTop = 10 + (index - 1) * (healerFrameHeight + healerFrameSpacing);
		healer.frame:SetPoint('TOP', parentFrame, 'TOP', 0, -marginTop);

		-- Handling parent windows height increase
		if (index == 1) then
			parentFrame:SetHeight(parentFrame:GetHeight() + healerFrameHeight);
			mainFrame:SetHeight(mainFrame:GetHeight() + healerFrameHeight);
		else
			parentFrame:SetHeight(parentFrame:GetHeight() + healerFrameHeight + healerFrameSpacing);
			mainFrame:SetHeight(mainFrame:GetHeight() + healerFrameHeight + healerFrameSpacing);
		end

		-- SetColor
		LoathebRotate:setHealerFrameColor(healer);

		healer.frame:Show();
		healer.frame.healer = healer;

		index = index + 1;
    end
end

-- Hide the healer frame
function LoathebRotate:hideHealer(healer)
    if (healer.frame ~= nil) then
        healer.frame:Hide()
    end
end

-- Refresh a single healer frame
function LoathebRotate:refreshHealerFrame(healer)
	LoathebRotate:setHealerFrameColor(healer);
	LoathebRotate:setHealerName(healer);
	LoathebRotate:updateBlindIcon(healer);
end

-- Toggle blind icon display based on addonVersion
function LoathebRotate:updateBlindIcon(healer)
    if (
        not LoathebRotate.db.profile.showBlindIcon or
        healer.addonVersion ~= nil or
        healer.name == UnitName('player') or
        not LoathebRotate:isHealerOnline(healer)
    ) then
        healer.frame.blindIconFrame:Hide()
    else
        healer.frame.blindIconFrame:Show()
    end
end

-- Refresh all blind icons
function LoathebRotate:refreshBlindIcons()
	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:updateBlindIcon(healer);
	end

	for _, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:updateBlindIcon(healer);
	end
end

-- Set the healer frame color regarding it's status
function LoathebRotate:setHealerFrameColor(healer)
	local color = LoathebRotate:getUserDefinedColor('neutral');

	if (not LoathebRotate:isHealerOnline(healer)) then
		color = LoathebRotate:getUserDefinedColor('offline');
	elseif (not LoathebRotate:isHealerAlive(healer)) then
		color = LoathebRotate:getUserDefinedColor('dead');
	elseif (healer.nextHeal) then
		color = LoathebRotate:getUserDefinedColor('active');
	end

	healer.frame.texture:SetVertexColor(color:GetRGB());
end

-- Set the healer's name regarding its class and group index
function LoathebRotate:setHealerName(healer)
	local currentText = healer.frame.text:GetText() or '';
	local currentFont, _, currentOutline = healer.frame.text:GetFont();

	local newText = healer.name;
	local newFont = LoathebRotate:getPlayerNameFont();
	local newOutline = LoathebRotate.db.profile.useNameOutline and "OUTLINE" or "";
	local hasClassColor = false;
	local shadowOpacity = 1.0;

	if (LoathebRotate.db.profile.useClassColor) then
		local _, _classFilename, _ = UnitClass(healer.name)
		if (_classFilename) then
			if _classFilename == "PRIEST" then
				shadowOpacity = 1.0;
			elseif _classFilename == "PALADIN" then
				shadowOpacity = 0.8;
			elseif _classFilename == "SHAMAN" then
				shadowOpacity = 0.4;
			else
				shadowOpacity = 0.6;
			end

			local _, _, _, _classColorHex = GetClassColor(_classFilename);
			newText = WrapTextInColorCode(newText, _classColorHex);
			hasClassColor = true;
		end
	end

	if (LoathebRotate.db.profile.prependIndex) then
		local rowIndex = 0;
		local rotationTable = LoathebRotate.rotationTable;
		for index = 1, #rotationTable, 1 do
			local candidate = rotationTable[index];
			if (candidate ~= nil and candidate.name == healer.name) then
				rowIndex = index;
				break
			end
		end

		if (rowIndex > 0) then
			local indexText = string.format("%s.", rowIndex);
			local color = LoathebRotate:getUserDefinedColor('indexPrefix');
			newText = color:WrapTextInColorCode(indexText)..newText;
		end
	end

    --local targetName, buffMode, assignedName, assignedAt
    --if LoathebRotate.db.profile.appendTarget then
    --    if healer.targetGUID then
    --        targetName, buffMode = self:getHealerTarget(healer)
    --        if targetName == "" then targetName = nil end
    --    end
    --    assignedName, assignedAt = self:getHunterAssignment(hunter)
    --    if assignedName == "" then assignedName = nil end
    --end
    --local showTarget
    --if assignedName then
    --    showTarget = true
    --elseif not targetName then
    --    showTarget = false
    --else
    --    showTarget = buffMode and (buffMode == 'not_a_buff' or buffMode == 'has_buff' or not LoathebRotate.db.profile.appendTargetBuffOnly)
    --end
    --hunter.showingTarget = showTarget

    --if (LoathebRotate.db.profile.appendGroup and hunter.subgroup) then
    --    if not showTarget or not LoathebRotate.db.profile.appendTargetNoGroup then -- Do not append the group if the target name hides the group for clarity
    --        local groupText = string.format(LoathebRotate.db.profile.groupSuffix, hunter.subgroup)
    --        local color = LoathebRotate:getUserDefinedColor('groupSuffix')
    --        newText = newText.." "..color:WrapTextInColorCode(groupText)
    --    end
    --end

    --if showTarget then
    --    local targetColorName
    --    local blameAssignment
    --    if assignedName and targetName and (assignedName ~= targetName) then
    --        blameAssignment = hunter.cooldownStarted and assignedAt and assignedAt < hunter.cooldownStarted
    --    end
    --    if     blameAssignment then                 targetColorName = 'flashyRed'
    --    elseif assignedName and not targetName then targetColorName = 'white'
    --    elseif buffMode == 'buff_expired' then      targetColorName = assignedName and 'white' or 'darkGray'
    --    elseif buffMode == 'buff_lost' then         targetColorName = 'lightRed'
    --    elseif buffMode == 'has_buff' then          targetColorName = 'white'
    --    else                                        targetColorName = 'white'
    --    end
    --    local mode = self:getMode()
    --    if assignedName and (not targetName or buffMode == 'buff_expired') then
    --        targetName = assignedName
    --    elseif type(mode.customTargetName) == 'function' then
    --        targetName = mode.customTargetName(mode, hunter, targetName)
    --    end
    --    if targetName then
    --        newText = newText..LoathebRotate.colors['white']:WrapTextInColorCode(" > ")
    --        newText = newText..LoathebRotate.colors[targetColorName]:WrapTextInColorCode(targetName)
    --    end
    --end

	if (newFont ~= currentFont or newOutline ~= currentOutline) then
		healer.frame.text:SetFont(newFont, 12, newOutline);
	end
	if (newText ~= currentText) then
		healer.frame.text:SetText(newText);
	end
	if (newText ~= currentText or newOutline ~= currentOutline) then
		if (LoathebRotate.db.profile.useNameOutline) then
			healer.frame.text:SetShadowOffset(0, 0);
		else
			healer.frame.text:SetShadowColor(0, 0, 0, shadowOpacity);
			healer.frame.text:SetShadowOffset(1, -1);
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
