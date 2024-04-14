local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Initialize GUI frames. Shouldn't be called more than once
function LoathebRotate:initGui()
	LoathebRotate.mainFrame = LoathebRotate:createMainFrame();

	local titleFrame = LoathebRotate:createTitleFrame(LoathebRotate.mainFrame);
	LoathebRotate:createMainFrameButtons(titleFrame);
	
	local bottomFrame = LoathebRotate:createBottomFrame(LoathebRotate.mainFrame);
	LoathebRotate:createBottomFrameButtons(bottomFrame);

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
	if LoathebRotate.db.profile.alwaysShowWindow then
		LoathebRotate.mainFrame:Show();
		return;
	end

	if not LoathebRotate:isActive() then
		if LoathebRotate.db.profile.hideNotInRaid then
			LoathebRotate.mainFrame:Hide();
		end
	end;
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

--  Refresh all healer frames
function LoathebRotate:refreshHealerFrames()
	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:refreshHealerFrame(healer);
	end

	for _, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:refreshHealerFrame(healer);
	end
end

-- Refresh a single healer frame
function LoathebRotate:refreshHealerFrame(healer)
	LoathebRotate:setHealerFrameColor(healer);
	LoathebRotate:setHealerName(healer);
	--LoathebRotate:updateBlindIcon(healer);
end

-- Toggle blind icon display based on addonVersion
--function LoathebRotate:updateBlindIcon(healer)
--    if (
--        not LoathebRotate.db.profile.showBlindIcon or
--        healer.addonVersion ~= nil or
--        healer.name == UnitName('player') or
--        not LoathebRotate:isHealerOnline(healer)
--    ) then
--        healer.frame.blindIconFrame:Hide()
--    else
--        healer.frame.blindIconFrame:Show()
--    end
--end

-- Refresh all blind icons
--function LoathebRotate:refreshBlindIcons()
--	for _, healer in pairs(LoathebRotate.rotationTable) do
--		LoathebRotate:updateBlindIcon(healer);
--	end

--	for _, healer in pairs(LoathebRotate.backupTable) do
--		LoathebRotate:updateBlindIcon(healer);
--	end
--end

-- Set the healer frame color regarding it's status
function LoathebRotate:setHealerFrameColor(healer)
	if not healer then
		return;
	end

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
	if not healer then
		return;
	end

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

function LoathebRotate:startHealerCooldown(healer, endTimeOfCooldown, endTimeOfEffect, targetGUID, buffName)
	if not endTimeOfCooldown or endTimeOfCooldown == 0 then
		local cooldown = LoathebRotate.loathebMode.cooldown;
		if cooldown then
			endTimeOfCooldown = GetTime() + cooldown;
		end
	end

	if not endTimeOfEffect or endTimeOfEffect == 0 then
		endTimeOfEffect = 0;
	end
	healer.endTimeOfEffect = endTimeOfEffect;

	healer.cooldownStarted = GetTime();

	healer.frame.cooldownFrame.statusBar:SetMinMaxValues(GetTime(), endTimeOfCooldown or GetTime());
	healer.expirationTime = endTimeOfCooldown;
	if endTimeOfCooldown and endTimeOfEffect and GetTime() < endTimeOfCooldown and GetTime() < endTimeOfEffect and endTimeOfEffect < endTimeOfCooldown then
		local tickWidth = 3;
		local x = healer.frame.cooldownFrame:GetWidth()*(endTimeOfEffect-GetTime())/(endTimeOfCooldown-GetTime());
		if x < 5 then
			-- If the tick is too early, it is graphically undistinguishable from the beginning of the cooldown bar, so don't bother displaying the tick
			healer.frame.cooldownFrame.statusTick:Hide();
		else
			local xmin = x - tickWidth/2;
			local xmax = xmin + tickWidth;
			healer.frame.cooldownFrame.statusTick:ClearAllPoints();
			healer.frame.cooldownFrame.statusTick:SetPoint('TOPLEFT', xmin, 0);
			healer.frame.cooldownFrame.statusTick:SetPoint('BOTTOMRIGHT', xmax - healer.frame.cooldownFrame:GetWidth(), 0);
			healer.frame.cooldownFrame.statusTick:Show();
		end
		else
			-- If there is no tick or the tick is beyond the cooldown bar, do not display the tick
			healer.frame.cooldownFrame.statusTick:Hide();
		end
	healer.frame.cooldownFrame:Show();
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
