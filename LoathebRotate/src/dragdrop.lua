local LoathebRotate = select(2, ...)

-- Enable drag & drop for all hunter frames
function LoathebRotate:enableListSorting()
    for key,hunter in pairs(LoathebRotate.hunterTable) do
        LoathebRotate:enableHunterFrameDragging(hunter, true)
    end
end

-- Enable or disable drag & drop for the hunter frame
function LoathebRotate:enableHunterFrameDragging(hunter, movable)
    hunter.movable = movable
    hunter.frame:EnableMouse(hunter.movable or hunter.assignable)
    hunter.frame:SetMovable(movable)
end

-- configure hunter frame drag behavior
function LoathebRotate:configureHunterFrameDrag(hunter, mainFrame)

    hunter.frame:RegisterForDrag("LeftButton")
    hunter.frame:SetClampedToScreen(true)

    hunter.frame.blindIconFrame:RegisterForDrag("LeftButton")
    hunter.frame.blindIconFrame:SetClampedToScreen(true)

    hunter.frame:SetScript(
        "OnDragStart",
        function()
            hunter.frame:StartMoving()
            hunter.frame:SetFrameStrata("HIGH")

            hunter.frame:SetScript(
                "OnUpdate",
                function ()
                    LoathebRotate:setDropHintPosition(hunter.frame, mainFrame)
                end
            )

            mainFrame.dropHintFrame:Show()
            mainFrame.backupFrame:Show()
        end
    )

    hunter.frame:SetScript(
        "OnDragStop",
        function()
            hunter.frame:StopMovingOrSizing()
            hunter.frame:SetFrameStrata(mainFrame:GetFrameStrata())
            mainFrame.dropHintFrame:Hide()

            -- Removes the onUpdate event used for drag & drop
            hunter.frame:SetScript("OnUpdate", nil)

            if (#LoathebRotate.rotationTables.backup < 1) then
                mainFrame.backupFrame:Hide()
            end

            local group, position = LoathebRotate:getDropPosition(hunter.frame, mainFrame)
            LoathebRotate:handleDrop(hunter, group, position)
            LoathebRotate:sendSyncOrder()
        end
    )
end

function LoathebRotate:getDragFrameHeight(hunterFrame, mainFrame)
    return math.abs(hunterFrame:GetTop() - mainFrame.rotationFrame:GetTop())
end

-- create and initialize the drop hint frame
function LoathebRotate:createDropHintFrame(mainFrame)

    local hintFrame = CreateFrame("Frame", nil, mainFrame.rotationFrame)

    hintFrame:SetPoint('TOP', mainFrame.rotationFrame, 'TOP', 0, 0)
    hintFrame:SetHeight(LoathebRotate.constants.hunterFrameHeight)
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
function LoathebRotate:setDropHintPosition(hunterFrame, mainFrame)

    local hunterFrameHeight = LoathebRotate.constants.hunterFrameHeight
    local hunterFrameSpacing = LoathebRotate.constants.hunterFrameSpacing
    local hintPosition = 0

    local group, position = LoathebRotate:getDropPosition(hunterFrame, mainFrame)

    if (group == 'ROTATION') then
        if (position == 0) then
            hintPosition = -2
        else
            hintPosition = (position) * (hunterFrameHeight + hunterFrameSpacing) - hunterFrameSpacing / 2;
        end
    else
        hintPosition = mainFrame.rotationFrame:GetHeight()

        if (position == 0) then
            hintPosition = hintPosition - 2
        else
            hintPosition = hintPosition + (position) * (hunterFrameHeight + hunterFrameSpacing) - hunterFrameSpacing / 2;
        end
    end

    mainFrame.dropHintFrame:SetPoint('TOP', 0 , -hintPosition)
end

-- Compute drop group and position
function LoathebRotate:getDropPosition(hunterFrame, mainFrame)

    local height = LoathebRotate:getDragFrameHeight(hunterFrame, mainFrame)
    local group = 'ROTATION'
    local position = 0

    local hunterFrameHeight = LoathebRotate.constants.hunterFrameHeight
    local hunterFrameSpacing = LoathebRotate.constants.hunterFrameSpacing

    -- Dragged frame is above rotation frames
    if (hunterFrame:GetTop() > mainFrame.rotationFrame:GetTop()) then
        height = 0
    end

    position = floor(height / (hunterFrameHeight + hunterFrameSpacing))

    -- Dragged frame is bellow rotation frame
    if (height > mainFrame.rotationFrame:GetHeight()) then

        group = 'BACKUP'

        -- Removing rotation frame size from calculation, using it's height as base hintPosition offset
        height = height - mainFrame.rotationFrame:GetHeight()

        if (height > mainFrame.backupFrame:GetHeight()) then
            -- Dragged frame is bellow backup frame
            position = #LoathebRotate.rotationTables.backup
        else
            position = floor(height / (hunterFrameHeight + hunterFrameSpacing))
        end
    end

    return group, position
end

-- Compute the table final position from the drop position
function LoathebRotate:handleDrop(hunter, group, position)

    local originTable = LoathebRotate:getHunterRotationTable(hunter)
    local originIndex = LoathebRotate:getHunterIndex(hunter, originTable)

    local destinationTable = LoathebRotate.rotationTables.rotation
    local finalPosition = 1

    if (group == "BACKUP") then
        destinationTable = LoathebRotate.rotationTables.backup
    end

    if (destinationTable == originTable) then

        if (position == originIndex or position == originIndex - 1 ) then
            finalPosition = originIndex
        else
            if (position > originIndex) then
                finalPosition = position
            else
                finalPosition = position + 1
            end
        end

    else
        finalPosition = position + 1
    end

    LoathebRotate:moveHunter(hunter, group, finalPosition)
end
