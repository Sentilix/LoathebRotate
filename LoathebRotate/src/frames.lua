local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Create main window
function LoathebRotate:createMainFrame()
	local mainFrame = CreateFrame("Frame", 'mainFrame', UIParent)

	mainFrame:SetWidth(LoathebRotate.db.profile.windows[1].width)
	mainFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight * 2 + LoathebRotate.constants.titleBarHeight + LoathebRotate.constants.modeBarHeight)

	if LoathebRotate.db.profile.alwaysShowWindow then
		mainFrame:Show();
	else
		mainFrame:Hide();
	end;

	mainFrame:RegisterForDrag("LeftButton")
	mainFrame:SetClampedToScreen(true)
	mainFrame:SetScript("OnDragStart", function() mainFrame:StartMoving() end)

	mainFrame:SetScript(
		"OnDragStop",
		function()
			mainFrame:StopMovingOrSizing()
			local config = LoathebRotate.db.profile.windows[1];
			config.point = 'TOPLEFT';
			config.y = mainFrame:GetTop();
			config.x = mainFrame:GetLeft();
		end
	)

	LoathebRotate.mainFrame = mainFrame;

    return mainFrame
end

-- Create history window
function LoathebRotate:createHistoryFrame()
    local historyFrame = CreateFrame("Frame", 'mainFrame', UIParent)

    historyFrame:SetWidth(LoathebRotate.db.profile.history.width)
    historyFrame:SetHeight(LoathebRotate.db.profile.history.height)
    historyFrame:Show()

    historyFrame:RegisterForDrag("LeftButton")
    historyFrame:SetClampedToScreen(true)
    historyFrame:SetScript("OnDragStart", function() historyFrame:StartMoving() end)

    historyFrame:SetScript(
        "OnDragStop",
        function()
            historyFrame:StopMovingOrSizing()

            local config = LoathebRotate.db.profile
            config.history.point = 'TOPLEFT'
            config.history.y = historyFrame:GetTop()
            config.history.x = historyFrame:GetLeft()
        end
    )

    LoathebRotate.historyFrame = historyFrame
    return historyFrame
end

-- Create Title frame
function LoathebRotate:createTitleFrame(baseFrame, subtitle)
	local titleFrame = CreateFrame("Frame", 'rotationFrame', baseFrame)
	titleFrame:SetPoint('TOPLEFT')
	titleFrame:SetPoint('TOPRIGHT')
	titleFrame:SetHeight(LoathebRotate.constants.titleBarHeight)

	titleFrame.texture = titleFrame:CreateTexture(nil, "BACKGROUND")
	titleFrame.texture:SetColorTexture(LoathebRotate.colors.headerBar:GetRGB())
	titleFrame.texture:SetAllPoints()

	titleFrame.text = titleFrame:CreateFontString(nil, "ARTWORK")
	titleFrame.text:SetFont("Fonts\\ARIALN.ttf", 12, "")
	titleFrame.text:SetShadowColor(0,0,0,0.5)
	titleFrame.text:SetShadowOffset(1,-1)
	titleFrame.text:SetPoint("LEFT",5,0)
	if subtitle then
		titleFrame.text:SetText(string.format('Loatheb Rotate - %s', subtitle));
	else
		titleFrame.text:SetText(string.format('Loatheb Rotate v%s', LoathebRotate.version));
	end
	titleFrame.text:SetTextColor(1,1,1,1)

	baseFrame.titleFrame = titleFrame
	return titleFrame
end

-- Create resizer for width and height
function LoathebRotate:createCornerResizer(baseFrame, windowConfig)
    baseFrame:SetResizable(true)

    local resizer = CreateFrame("Button", nil, baseFrame, "PanelResizeButtonTemplate")

    resizer:SetPoint("BOTTOMRIGHT")

    local minWidth = 200
    local minHeight = 50
    local maxWidth = 800
    local maxHeight = 1000
    resizer:Init(baseFrame, minWidth, minHeight, maxWidth, maxHeight)

    resizer:SetOnResizeStoppedCallback(function(frame)
        windowConfig.width = frame:GetWidth()
        windowConfig.height = frame:GetHeight()
    end)

    if not baseFrame.resizers then
        baseFrame.resizers = { ["BOTTOMRIGHT"] = resizer }
    else
        baseFrame.resizers["BOTTOMRIGHT"] = resizer
    end
    return resizer
end

-- Create resizers for width only
function LoathebRotate:createHorizontalResizer(baseFrame, windowConfig, side, backgroundFrame, dynamicBottomBackgroundFrame)
    baseFrame:SetResizable(true)

    local resizer = CreateFrame("Frame", nil, baseFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
    resizer:SetFrameStrata("HIGH")

    resizer:SetPoint(side)

    resizer:SetWidth(8)

    resizer:SetPoint("TOP", backgroundFrame or baseFrame, "TOP")
    resizer:SetPoint("BOTTOM", backgroundFrame or baseFrame, "BOTTOM")

    -- Special case if there is the bottom point is attached to a frame which can be shown/hidden
    if dynamicBottomBackgroundFrame then
        if dynamicBottomBackgroundFrame:IsVisible() then
            resizer:SetPoint("BOTTOM", dynamicBottomBackgroundFrame, "BOTTOM")
        end
        if not baseFrame.resizers then
            -- Attach to visibility if not done yet
            -- It assumes horizontal resizers are only stacked between each other
            -- (see footnote at the end of this method)
            -- It also assumes all resizers of the same base attach to the same sub-frames
            dynamicBottomBackgroundFrame:SetScript("OnShow", function(frame)
                for _side, _frame in pairs(baseFrame.resizers) do
                    _frame:SetPoint("BOTTOM", dynamicBottomBackgroundFrame, "BOTTOM")
                end
            end)
            dynamicBottomBackgroundFrame:SetScript("OnHide", function(frame)
                for _side, _frame in pairs(baseFrame.resizers) do
                    _frame:SetPoint("BOTTOM", backgroundFrame, "BOTTOM")
                end
            end)
        end
    end

    resizer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 3, right = 3, top = 5, bottom = 5 }
    })
    resizer:SetBackdropColor(1, 1, 1, 0)
    resizer:SetScript("OnEnter", function(frame)
        frame:SetBackdropColor(1, 1, 1, 0.8)
    end)
    resizer:SetScript("OnLeave", function(frame)
        frame:SetBackdropColor(1, 1, 1, 0)
    end)

    resizer:SetScript("OnMouseDown", function(frame)
        baseFrame:StartSizing(side)
    end)

    resizer:SetScript("OnMouseUp", function(frame)
        baseFrame:StopMovingOrSizing()

        windowConfig.x = baseFrame:GetLeft()
        windowConfig.width = baseFrame:GetWidth()
    end)

    if not baseFrame.resizers then
        local minWidth = 100
        local maxWidth = 500

        baseFrame:SetScript("OnSizeChanged", function(frame, width, height)
            -- Clamp width
            if width < minWidth then
                width = minWidth
                baseFrame:SetWidth(width)
            elseif width > maxWidth then
                width = maxWidth
                baseFrame:SetWidth(width)
            end

			-- Resize other UI elements which may depend on it
			if baseFrame.dropHintFrame then
				baseFrame.dropHintFrame:SetWidth(width - 10);
			end
        end)

        baseFrame.resizers = { [side] = resizer }
    else
        -- No need to re-attach to baseFrame's OnSizeChanged if a resizer is already here
        -- Nonetheless, it assumes that horizontal resizers can be stacked between each other
        -- But horizontal resizers are not stacked with corner resizers
        baseFrame.resizers[side] = resizer
    end
    return resizer
end

-- Create title bar buttons for main frame
function LoathebRotate:createMainFrameButtons(baseFrame)
    local buttons = {
        {
            texture = {
                normal = 'Interface/Buttons/UI-Panel-MinimizeButton-Up',
                pushed = 'Interface/Buttons/UI-Panel-MinimizeButton-Down',
                highlight = 'Interface/Buttons/UI-Panel-MinimizeButton-Highlight',
            },
            callback = LoathebRotate.toggleDisplay,
            texCoord = {0.08, 0.9, 0.1, 0.9},
        },
    }

    return LoathebRotate:createButtons(baseFrame, buttons)
end

function LoathebRotate:createBottomFrameButtons(baseFrame)
    local buttons = {
        {
			name = 'BtnMain_Settings',
            texture = 'Interface/GossipFrame/BinderGossipIcon',
            callback = LoathebRotate.toggleSettings,
            tooltip = L["BUTTON_SETTINGS"],
        },
        {
			name = 'BtnMain_ShowHistory',
            texture = 'Interface/Buttons/UI-GuildButton-OfficerNote-Up',
            callback = LoathebRotate.toggleHistory,
            tooltip = L["BUTTON_HISTORY"],
        },
        {
			name = 'BtnMain_PrintRotation',
            texture = 'Interface/Buttons/UI-GuildButton-MOTD-Up',
            callback = LoathebRotate.printRotationSetup,
            tooltip = L["BUTTON_PRINT_ROTATION"],
        },
        {
			name = 'BtnMain_ResetRotation',
			texture = 'Interface/Buttons/UI-RefreshButton',
			callback = function()
				if not LoathebRotate:isHealerPromoted(UnitName('player')) then
					return;
				end;
				LoathebRotate:updateRaidStatus();
				LoathebRotate:resetRotation();
				LoathebRotate:requestResetRotation();
			end,
			tooltip = L["BUTTON_RESET_ROTATION"],
        },
        {
			name = 'BtnMain_ApplyAzRotation',
            texture = 'Interface/Buttons/UI-SortArrow',
            callback = LoathebRotate.applyAzRotation,
            tooltip = L["BUTTON_APPLY_AZ_ROTATION"],
        },
    }

    return LoathebRotate:createButtons(baseFrame, buttons)
end;

-- Create title bar buttons for main frame
function LoathebRotate:createHistoryFrameButtons(baseFrame)
    local buttons = {
        {
			name = 'BtnHistory_ToggleHistory',
            texture = {
                normal = 'Interface/Buttons/UI-Panel-MinimizeButton-Up',
                pushed = 'Interface/Buttons/UI-Panel-MinimizeButton-Down',
                highlight = 'Interface/Buttons/UI-Panel-MinimizeButton-Highlight',
            },
            callback = LoathebRotate.toggleHistory,
            texCoord = {0.08, 0.9, 0.1, 0.9},
        },
        {
			name = 'BtnHistory_Settings',
            texture = 'Interface/GossipFrame/BinderGossipIcon',
            callback = LoathebRotate.toggleSettings,
            tooltip = L["BUTTON_SETTINGS"],
        },
        {
			name = 'BtnHistory_RespawnHistory',
            texture = 'Interface/Buttons/UI-RefreshButton',
            callback = LoathebRotate.respawnHistory,
            tooltip = L["BUTTON_RESPAWN_HISTORY"],
        },
        {
			name = 'BtnHistory_ClearHistory',
            texture = {
                normal = 'Interface/Buttons/CancelButton-Up',
                pushed = 'Interface/Buttons/CancelButton-Down',
                highlight = 'Interface/Buttons/CancelButton-Highlight',
            },
            callback = LoathebRotate.clearHistory,
            texCoord = {0.2, 0.8, 0.2, 0.8},
            tooltip = L["BUTTON_CLEAR_HISTORY"],
        },
    }

    return LoathebRotate:createButtons(baseFrame, buttons)
end

-- Create title bar buttons
function LoathebRotate:createButtons(baseFrame, buttons)
    local position = 5

    for key, button in pairs(buttons) do
        LoathebRotate:createButton(baseFrame, position, button.name, button.texture, button.callback, button.texCoord, button.tooltip)
        position = position + 15
    end
end

-- Create a single button in the title bar
function LoathebRotate:createButton(baseFrame, position, name, texture, callback, texCoord, tooltip)

    local button = CreateFrame("Button", name, baseFrame)
    button:SetPoint('RIGHT', -position, 0)
    button:SetWidth(14)
    button:SetHeight(14)

    if type(texture) == 'string' then
        texture = {
            normal = texture,
            highlight = texture,
            pushed = texture,
        }
    end

    local normal = button:CreateTexture()
    normal:SetTexture(texture.normal)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)

    local highlight = button:CreateTexture()
    highlight:SetTexture(texture.highlight)
    highlight:SetAllPoints()
    button:SetHighlightTexture(highlight)

    local pushed = button:CreateTexture()
    pushed:SetTexture(texture.pushed)
    pushed:SetAllPoints()
    button:SetPushedTexture(pushed)

    if (texCoord) then
        normal:SetTexCoord(unpack(texCoord))
        highlight:SetTexCoord(unpack(texCoord))
        pushed:SetTexCoord(unpack(texCoord))
    end

    button:SetScript("OnClick", callback)

    if tooltip then
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, tooltip)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return button
end

-- Create scroll frame with text button
function LoathebRotate:createTextFrame(baseFrame)
    local constants = LoathebRotate.constants.history
    local textFrame = CreateFrame("ScrollingMessageFrame", nil, baseFrame)

    local margin = constants.margin
    textFrame:SetPoint('BOTTOMLEFT', margin, margin)
    textFrame:SetPoint('TOPRIGHT', -margin, -margin)

    local fontFace = constants.fontFace
    local fontSize = constants.fontSize
    textFrame:SetFont(fontFace, fontSize, "")
    textFrame:SetTextColor(1,1,1,1)
    textFrame:SetShadowColor(0,0,0,1)
    textFrame:SetShadowOffset(1,-1)
    textFrame:SetJustifyH("LEFT")

    textFrame:SetTimeVisible(LoathebRotate.constants.history.defaultTimeVisible)

    baseFrame.textFrame = textFrame
    return textFrame
end

-- Create bottom frame
function LoathebRotate:createBottomFrame(baseFrame)
    local bottomFrame = CreateFrame("Frame", 'bottomFrame', baseFrame)
    bottomFrame:SetPoint('LEFT')
    bottomFrame:SetPoint('RIGHT')
    bottomFrame:SetPoint('TOP', 0, -LoathebRotate.constants.titleBarHeight)
    bottomFrame:SetHeight(LoathebRotate.constants.modeBarHeight)

    bottomFrame.texture = bottomFrame:CreateTexture(nil, "BACKGROUND")
    bottomFrame.texture:SetColorTexture(LoathebRotate.colors.buttonBar:GetRGB())
    bottomFrame.texture:SetAllPoints()

    baseFrame.bottomFrame = bottomFrame

    return bottomFrame;
end

-- Create background frame
function LoathebRotate:createBackgroundFrame(baseFrame, offsetY, height, noAnchorBottom, frameName)
    if not frameName then frameName = 'backgroundFrame' end

    local backgroundFrame = CreateFrame("Frame", frameName, baseFrame)
    backgroundFrame:SetPoint('LEFT')
    backgroundFrame:SetPoint('RIGHT')
    backgroundFrame:SetPoint('TOP', 0, -offsetY)
    if not noAnchorBottom then
        backgroundFrame:SetPoint('BOTTOM')
    end
    backgroundFrame:SetHeight(height-offsetY)

    backgroundFrame.texture = backgroundFrame:CreateTexture(nil, "BACKGROUND")
    backgroundFrame.texture:SetColorTexture(0,0,0,0.5)
    backgroundFrame.texture:SetAllPoints()

    baseFrame[frameName] = backgroundFrame
    return backgroundFrame
end

-- Create rotation frame
function LoathebRotate:createRotationFrame(baseFrame)
    local offsetY = LoathebRotate.constants.titleBarHeight+LoathebRotate.constants.modeBarHeight
    local height = LoathebRotate.constants.rotationFramesBaseHeight
    local noAnchorBottom = true
    return LoathebRotate:createBackgroundFrame(baseFrame, offsetY, height, noAnchorBottom, 'rotationFrame')
end

-- Create backup frame
function LoathebRotate:createBackupFrame(baseFrame, rotationFrame)
    -- Backup frame
    local backupFrame = CreateFrame("Frame", 'backupFrame', baseFrame)
    backupFrame:SetPoint('TOPLEFT', rotationFrame, 'BOTTOMLEFT', 0, 0)
    backupFrame:SetPoint('TOPRIGHT', rotationFrame, 'BOTTOMRIGHT', 0, 0)
    backupFrame:SetHeight(LoathebRotate.constants.rotationFramesBaseHeight)

    -- Set Texture
    backupFrame.texture = backupFrame:CreateTexture(nil, "BACKGROUND")
    backupFrame.texture:SetColorTexture(0,0,0,0.5)
    backupFrame.texture:SetAllPoints()

    -- Visual separator
    backupFrame.texture = backupFrame:CreateTexture(nil, "BACKGROUND")
    backupFrame.texture:SetColorTexture(0.8,0.8,0.8,0.8)
    backupFrame.texture:SetHeight(1)
    backupFrame.texture:SetWidth(60)
    backupFrame.texture:SetPoint('TOP')

    baseFrame.backupFrame = backupFrame
    return backupFrame
end

-- Create single healer frame
function LoathebRotate:createHealerFrame(healer, parentFrame)
	healer.frame = CreateFrame("Frame", nil, parentFrame);
	healer.frame:SetHeight(LoathebRotate.constants.healerFrameHeight);
	healer.frame.fullName = healer.fullName;

	-- Set Texture
	healer.frame.texture = healer.frame:CreateTexture(nil, "ARTWORK");
	healer.frame.texture:SetTexture("Interface\\AddOns\\LoathebRotate\\textures\\steel.tga");
	healer.frame.texture:SetAllPoints();

	-- Tooltip
	healer.frame:SetScript("OnEnter", LoathebRotate.onHealerEnter);
	healer.frame:SetScript("OnLeave", LoathebRotate.onHealerLeave);

	-- Set Text
	healer.frame.text = healer.frame:CreateFontString(nil, "ARTWORK");
	healer.frame.text:SetPoint("LEFT",5,0);
	LoathebRotate:setHealerName(healer);

	LoathebRotate:createCooldownFrame(healer);
	LoathebRotate:createBlindIconFrame(healer);
	LoathebRotate:configureHealerFrameDrag(healer);
	--LoathebRotate:configureHealerFrameRightClick(healer);

	if (LoathebRotate.enableDrag) then
		LoathebRotate:enableHealerFrameDragging(healer, true);
	end

--	LoathebRotate:enableHealerFrameRightClick(healer, true);
end

-- Create the cooldown frame
function LoathebRotate:createCooldownFrame(healer)

    -- Frame
    healer.frame.cooldownFrame = CreateFrame("Frame", nil, healer.frame)
    healer.frame.cooldownFrame:SetPoint('LEFT', 5, 0)
    healer.frame.cooldownFrame:SetPoint('RIGHT', -5, 0)
    healer.frame.cooldownFrame:SetPoint('TOP', 0, -17)
    healer.frame.cooldownFrame:SetHeight(3)

    -- background
    healer.frame.cooldownFrame.background = healer.frame.cooldownFrame:CreateTexture(nil, "ARTWORK")
    healer.frame.cooldownFrame.background:SetColorTexture(0,0,0,1)
    healer.frame.cooldownFrame.background:SetAllPoints()

    local statusBar = CreateFrame("StatusBar", nil, healer.frame.cooldownFrame)
    statusBar:SetAllPoints()
    statusBar:SetMinMaxValues(0,1)
    statusBar:SetStatusBarTexture("Interface\\AddOns\\LoathebRotate\\textures\\steel.tga")
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    statusBar:GetStatusBarTexture():SetVertTile(false)
    statusBar:SetStatusBarColor(1, 0, 0)
    healer.frame.cooldownFrame.statusBar = statusBar

    healer.frame.cooldownFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.statusBar:SetValue(GetTime())

            local healer = LoathebRotate:getHealer(self:GetParent().fullName);
            if healer and healer.expirationTime and GetTime() > healer.expirationTime then
                self:Hide()
            end
        end
    )

    local statusTick = healer.frame.cooldownFrame:CreateTexture(nil, "OVERLAY")
    statusTick:SetColorTexture(1,0.8,0,1)
    statusTick:SetAllPoints()
    statusTick:Hide()
    healer.frame.cooldownFrame.statusTick = statusTick

    healer.frame.cooldownFrame:Hide()
end

-- Create the blind icon frame
function LoathebRotate:createBlindIconFrame(healer)

    -- Frame
    healer.frame.blindIconFrame = CreateFrame("Frame", nil, healer.frame)
    healer.frame.blindIconFrame:SetPoint('RIGHT', -5, 0)
    healer.frame.blindIconFrame:SetPoint('CENTER', 0, 0)
    healer.frame.blindIconFrame:SetWidth(16)
    healer.frame.blindIconFrame:SetHeight(16)

    -- Set Texture
    healer.frame.blindIconFrame.texture = healer.frame.blindIconFrame:CreateTexture(nil, "ARTWORK")
	local blind_filename = ""
	local relativeHeight = select(2,GetCurrentScaledResolution())*UIParent:GetEffectiveScale()

	if relativeHeight <= 1080 then
		blind_filename = "blind_32px.tga"
	else
		blind_filename = "blind_256px.tga"
	end
    healer.frame.blindIconFrame.texture:SetTexture("Interface\\AddOns\\LoathebRotate\\textures\\"..blind_filename)
    healer.frame.blindIconFrame.texture:SetAllPoints()
    healer.frame.blindIconFrame.texture:SetTexCoord(0, 1, 0, 1);

    -- Tooltip
    healer.frame.blindIconFrame:SetScript("OnEnter", LoathebRotate.onBlindIconEnter)
    healer.frame.blindIconFrame:SetScript("OnLeave", LoathebRotate.onBlindIconLeave)

    -- Drag & drop handlers
    healer.frame.blindIconFrame:SetScript("OnDragStart", function(self, ...)
        ExecuteFrameScript(self:GetParent(), "OnDragStart", ...);
    end)
    healer.frame.blindIconFrame:SetScript("OnDragStop", function(self, ...)
        ExecuteFrameScript(self:GetParent(), "OnDragStop", ...);
    end)

    healer.frame.blindIconFrame:Hide()
end

-- Blind icon tooltip show
function LoathebRotate.onBlindIconEnter(frame)
	if (LoathebRotate.db.profile.showBlindIconTooltip) then
		GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(L["TOOLTIP_PLAYER_WITHOUT_ADDON"])
		GameTooltip:AddLine(L["TOOLTIP_MAY_RUN_OUDATED_VERSION"])
		GameTooltip:AddLine(L["TOOLTIP_DISABLE_SETTINGS"])
		GameTooltip:Show()
	end
end

-- Blind icon tooltip hide
function LoathebRotate.onBlindIconLeave(frame, motion)
	GameTooltip:Hide()
end

-- Healer frame tooltip show
function LoathebRotate.onHealerEnter(frame)
	local healer = LoathebRotate:getHealer(frame.fullName)
	if healer then
		if (healer.endTimeOfEffect and GetTime() < healer.endTimeOfEffect) or (healer.expirationTime and GetTime() < healer.expirationTime) then
			local tooltipRefreshFunc = function()
				local effectRemaining = healer and healer.endTimeOfEffect-GetTime() or 0
				local cooldownRemaining = healer and healer.expirationTime-GetTime() or 0

				local text = ''
				local appendText = function(newtext)
					if text ~= '' then
						text = text..'\n'
					end
					text = text..newtext
				end

				if effectRemaining > 0 or cooldownRemaining > 0 then
					local hrEffect
					if effectRemaining > 60 then
						hrEffect = string.format(L['TOOLTIP_DURATION_MINUTES'], ceil(effectRemaining/60))
					elseif effectRemaining > 0 then
						hrEffect = string.format(L['TOOLTIP_DURATION_SECONDS'], ceil(effectRemaining))
					end

					local hrCooldown
					if cooldownRemaining > 60 then
						hrCooldown = string.format(L['TOOLTIP_DURATION_MINUTES'], ceil(cooldownRemaining/60));
					elseif cooldownRemaining > 0 then
						hrCooldown = string.format(L['TOOLTIP_DURATION_SECONDS'], ceil(cooldownRemaining));
					end

					if hrEffect then
						appendText(string.format(L['TOOLTIP_EFFECT_REMAINING'], hrEffect));
					end
					if hrCooldown then
						appendText(string.format(L['TOOLTIP_COOLDOWN_REMAINING'], hrCooldown));
					end 
                end
				if text ~= '' then
					GameTooltip:SetText(text);
				else
					frame.tooltipRefreshTicker:Cancel();
					frame.tooltipRefreshTicker = nil;
					GameTooltip:Hide();
				end
			end

			if not frame.tooltipRefreshTicker or frame.tooltipRefreshTicker:IsCancelled() then
				local refreshInterval = 0.5;
				frame.tooltipRefreshTicker = C_Timer.NewTicker(refreshInterval, tooltipRefreshFunc);
			end

			GameTooltip:SetOwner(frame, "ANCHOR_TOP")
			tooltipRefreshFunc()
			GameTooltip:Show()
        end
    end
end

-- Healer frame tooltip hide
function LoathebRotate.onHealerLeave(frame, motion)
    GameTooltip:Hide() -- @TODO hide only if it was shown
    if frame.tooltipRefreshTicker then
        frame.tooltipRefreshTicker:Cancel()
        frame.tooltipRefreshTicker = nil
    end
end
