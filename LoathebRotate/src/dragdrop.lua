local LoathebRotate = select(2, ...)

-- Enable drag & drop for all healer frames
function LoathebRotate:enableListSorting()
	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:enableHealerFrameDragging(healer, true)
	end

	for _, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:enableHealerFrameDragging(healer, true)
	end
end

-- Enable or disable drag & drop for the healer frame
function LoathebRotate:enableHealerFrameDragging(healer, movable)
	healer.movable = movable;
	healer.frame:EnableMouse(healer.movable);
	healer.frame:SetMovable(movable);
end

-- configure healer frame drag behavior
function LoathebRotate:configureHealerFrameDrag(healer)
	local MF = LoathebRotate.mainFrame;

	healer.frame:RegisterForDrag("LeftButton");
	healer.frame:SetClampedToScreen(true);

	healer.frame.blindIconFrame:RegisterForDrag("LeftButton");
	healer.frame.blindIconFrame:SetClampedToScreen(true);

	healer.frame:SetScript(
		"OnDragStart",
		function()
			if not LoathebRotate:isHealerPromoted(UnitName('player')) then
				return;
			end

			LoathebRotate.ignoreRaidStatusUpdates = true;

			healer.frame:StartMoving();
			healer.frame:SetFrameStrata("HIGH");

			healer.frame:SetScript(
				"OnUpdate",
				function ()
					LoathebRotate:setDropHintPosition(healer.frame, MF);
				end
			)

			MF.dropHintFrame:Show();
			MF.backupFrame:Show();
		end
	)

	healer.frame:SetScript(
		"OnDragStop",
		function()
			healer.frame:StopMovingOrSizing()
			healer.frame:SetFrameStrata(mainFrame:GetFrameStrata())
			MF.dropHintFrame:Hide()

			-- Removes the onUpdate event used for drag & drop
			healer.frame:SetScript("OnUpdate", nil)

			if (#LoathebRotate.backupTable < 1) then
				MF.backupFrame:Hide()
			end

			local group, position = LoathebRotate:getDropPosition(healer.frame, MF);
			LoathebRotate:handleDrop(healer, group, position);
			LoathebRotate.ignoreRaidStatusUpdates = false;
		end
	)
end

function LoathebRotate:getDragFrameHeight(healerFrame, mainFrame)
    return math.abs(healerFrame:GetTop() - mainFrame.rotationFrame:GetTop())
end

-- create and initialize the drop hint frame
function LoathebRotate:createDropHintFrame(mainFrame)

    local hintFrame = CreateFrame("Frame", nil, mainFrame.rotationFrame)

    hintFrame:SetPoint('TOP', mainFrame.rotationFrame, 'TOP', 0, 0)
    hintFrame:SetHeight(LoathebRotate.constants.healerFrameHeight)
    hintFrame:SetWidth(LoathebRotate.db.profile.windows[1].width - 10)

    hintFrame.texture = hintFrame:CreateTexture(nil, "BACKGROUND")
    hintFrame.texture:SetColorTexture(LoathebRotate.colors.white:GetRGB())
    hintFrame.texture:SetAlpha(0.7)
    hintFrame.texture:SetPoint('LEFT')
    hintFrame.texture:SetPoint('RIGHT')
    hintFrame.texture:SetHeight(2)

    hintFrame:Hide()

    mainFrame.dropHintFrame = hintFrame
end

-- Set the drop hint frame position to match dragged frame position
function LoathebRotate:setDropHintPosition(healerFrame, mainFrame)

    local healerFrameHeight = LoathebRotate.constants.healerFrameHeight
    local healerFrameSpacing = LoathebRotate.constants.healerFrameSpacing
    local hintPosition = 0

    local group, position = LoathebRotate:getDropPosition(healerFrame, mainFrame)

    if (group == 'ROTATION') then
        if (position == 0) then
            hintPosition = -2
        else
            hintPosition = (position) * (healerFrameHeight + healerFrameSpacing) - healerFrameSpacing / 2;
        end
    else
        hintPosition = mainFrame.rotationFrame:GetHeight()

        if (position == 0) then
            hintPosition = hintPosition - 2
        else
            hintPosition = hintPosition + (position) * (healerFrameHeight + healerFrameSpacing) - healerFrameSpacing / 2;
        end
    end

    mainFrame.dropHintFrame:SetPoint('TOP', 0 , -hintPosition)
end

-- Compute drop group and position
function LoathebRotate:getDropPosition(healerFrame, mainFrame)

	local height = LoathebRotate:getDragFrameHeight(healerFrame, mainFrame);
	local group = 'ROTATION';
	local position = 0;

	local healerFrameHeight = LoathebRotate.constants.healerFrameHeight;
	local healerFrameSpacing = LoathebRotate.constants.healerFrameSpacing;

	-- Dragged frame is above rotation frames
	if (healerFrame:GetTop() > mainFrame.rotationFrame:GetTop()) then
		height = 0;
	end

	position = floor(height / (healerFrameHeight + healerFrameSpacing));

	-- Dragged frame is below rotation frame
	if (height > mainFrame.rotationFrame:GetHeight()) then
		group = 'BACKUP';

		-- Removing rotation frame size from calculation, using it's height as base hintPosition offset
		height = height - mainFrame.rotationFrame:GetHeight();

		if (height > mainFrame.backupFrame:GetHeight()) then
			-- Dragged frame is below backup frame
			position = #LoathebRotate.backupTable
		else
			position = floor(height / (healerFrameHeight + healerFrameSpacing))
		end
	end

	return group, position
end

-- Compute the table final position from the drop position
function LoathebRotate:handleDrop(healer, group, position)

	local originTable = LoathebRotate:getHealerRotationTable(healer);
	local originIndex = LoathebRotate:getHealerIndex(healer, originTable);

	local destinationTable = LoathebRotate.rotationTable;
	local finalPosition = 1;

	if (group == "BACKUP") then
		destinationTable = LoathebRotate.backupTable;
	end

	if (destinationTable == originTable) then
		if (position == originIndex or position == originIndex - 1 ) then
			finalPosition = originIndex;
		else
		if (position > originIndex) then
			finalPosition = position;
		else
			finalPosition = position + 1;
		end
	end
	else
		finalPosition = position + 1;
	end

	LoathebRotate:moveHealer(healer, group, finalPosition);
	LoathebRotate:requestMoveHealer(healer, group, finalPosition);
end
