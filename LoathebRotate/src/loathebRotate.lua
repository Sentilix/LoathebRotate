LoathebRotate = select(2, ...)

local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

local parent = ...
LoathebRotate.version = GetAddOnMetadata(parent, "Version")

-- Initialize addon - Shouldn't be call more than once
function LoathebRotate:init()

	self:LoadDefaults()

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("LoathebRotateDb", self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "ProfilesChanged")

	self:CreateConfig()

	--	Healers in rotation:
	LoathebRotate.rotationTable = {};
	--	Healers outside rotation (backup):
	LoathebRotate.backupTable = {};

	LoathebRotate.enableDrag = true;
	LoathebRotate.raidInitialized = false;
	LoathebRotate.testMode = false;
	LoathebRotate.mainFrame = nil;
	LoathebRotate.openWindowRequestSent = false;
	LoathebRotate.ignoreRaidStatusUpdates = false;

	LoathebRotate:initGui()
	LoathebRotate:loadHistory()
	LoathebRotate:updateRaidStatus()
	LoathebRotate:applySettings()

	LoathebRotate:initComms()

	LoathebRotate:requestSync();

	LoathebRotate:printMessage(L['LOADED_MESSAGE'])
end

-- Apply setting on profile change
function LoathebRotate:ProfilesChanged()
	self.db:RegisterDefaults(self.defaults)
    self:applySettings()
end

-- Apply position, size, and visibility
local function applyWindowSettings(frame, windowConfig)

    frame:ClearAllPoints()
    if windowConfig.point then
        frame:SetPoint(windowConfig.point, UIParent, 'BOTTOMLEFT', windowConfig.x, windowConfig.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    if windowConfig.width then
        frame:SetWidth(windowConfig.width)
    end
    if windowConfig.height then
        frame:SetHeight(windowConfig.height)
    end
    if type(windowConfig.visible) == 'boolean' and not windowConfig.visible then
        frame:Hide()
    end

    local unlocked = not LoathebRotate.db.profile.lock
    frame:EnableMouse(unlocked)
    frame:SetMovable(unlocked)
    for _, resizer in pairs(frame.resizers) do
        resizer:SetShown(unlocked)
    end
end

-- Apply settings
function LoathebRotate:applySettings()
	local config = LoathebRotate.db.profile;

	applyWindowSettings(LoathebRotate.mainFrame, config.windows[1]);

	applyWindowSettings(LoathebRotate.historyFrame, config.history);
	LoathebRotate:setHistoryTimeVisible(config.historyTimeVisible);
	LoathebRotate:setHistoryFontSize(config.historyFontSize);

	LoathebRotate:updateDisplay();
end

-- Print wrapper, just in case
function LoathebRotate:printMessage(msg)
    print(msg)
end

-- Print message with colored prefix
function LoathebRotate:printPrefixedMessage(msg)
    LoathebRotate:printMessage(LoathebRotate:colorText(LoathebRotate.constants.printPrefix) .. msg)
end

SLASH_LOATHEBROTATE1 = "/loa"  -- because /lr conflicts with LootReserve
SLASH_LOATHEBROTATE2 = "/loathebrotate"
SlashCmdList["LOATHEBROTATE"] = function(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if (cmd == 'toggle') then
        LoathebRotate:toggleDisplay()
    elseif (cmd == 'show') then
        LoathebRotate:showDisplay()
    elseif (cmd == 'hide') then
        LoathebRotate:hideDisplay()
    elseif (cmd == 'lock') then
        LoathebRotate:lock(true)
    elseif (cmd == 'unlock') then
        LoathebRotate:lock(false)
    elseif (cmd == 'rotate') then -- @todo decide if this should be removed or not
        LoathebRotate:testRotation()
    elseif (cmd == 'test') then -- @todo: remove this
        LoathebRotate:test()
    elseif (cmd == 'report') then
        LoathebRotate:printRotationSetup()
    elseif (cmd == 'settings') then
        LoathebRotate:toggleSettings()
    elseif (cmd == 'history') then
        LoathebRotate:toggleHistory()
    elseif (cmd == 'check' or cmd== 'version') then
        LoathebRotate:checkVersions()
    else
        LoathebRotate:printHelp()
    end
end

function LoathebRotate:showDisplay()
--	if not LoathebRotate.mainFrame:IsShown() then
		LoathebRotate.mainFrame:Show();
--	end
end

function LoathebRotate:hideDisplay()
	if LoathebRotate.mainFrame:IsShown() then
		LoathebRotate.mainFrame:Hide();
		LoathebRotate:printMessage(L['TRANQ_WINDOW_HIDDEN']);
	end
end

function LoathebRotate:toggleDisplay()
	if LoathebRotate.mainFrame:IsShown() then
		LoathebRotate:hideDisplay();
	else
		LoathebRotate.showDisplay();
	end
end

function LoathebRotate:toggleHistory()
    if LoathebRotate.historyFrame:IsShown() then
        LoathebRotate.historyFrame:Hide()
        LoathebRotate.db.profile.history.visible = false
    else
        LoathebRotate.historyFrame:Show()
        LoathebRotate.db.profile.history.visible = true
    end
end

-- @todo: remove this
function LoathebRotate:test()
    LoathebRotate:printMessage('test')
    LoathebRotate:toggleArcaneShotTesting()
end

-- Toggle Ace settings
function LoathebRotate:toggleSettings()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local aceConfigAppName = "LoathebRotate"
    if AceConfigDialog.OpenFrames[aceConfigAppName] then
        AceConfigDialog:Close(aceConfigAppName)
    else
        AceConfigDialog:Open(aceConfigAppName)
    end
end

-- Sends rotation setup to raid channel
function LoathebRotate:printRotationSetup()
	if LoathebRotate:isActive() then
		LoathebRotate:sendRotationMessage('--- ' .. LoathebRotate.constants.printPrefix .. LoathebRotate:getBroadcastHeaderText() .. ' ---')

		if (LoathebRotate.db.profile.useMultilineRotationReport) then
			LoathebRotate:printMultilineRotation(LoathebRotate.rotationTable);
		else
			LoathebRotate:sendRotationMessage(LoathebRotate:buildGroupMessage(L['BROADCAST_ROTATION_PREFIX'] .. ' : ', LoathebRotate.rotationTable));
		end

		if (#LoathebRotate.backupTable > 0) then
			LoathebRotate:sendRotationMessage(LoathebRotate:buildGroupMessage(L['BROADCAST_BACKUP_PREFIX'] .. ' : ', LoathebRotate.backupTable));
		end
	end
end

-- Print the main rotation on multiple lines
function LoathebRotate:printMultilineRotation(rotationTable, channel)
    local position = 1;
    for key, hunt in pairs(rotationTable) do
        LoathebRotate:sendRotationMessage(tostring(position) .. ' - ' .. hunt.name)
        position = position + 1;
    end
end

-- Serialize healers names of a given rotation group
function LoathebRotate:buildGroupMessage(prefix, rotationTable)
    local healers = {}

    for key, healer in pairs(rotationTable) do
        table.insert(healers, healer.name)
    end

    return prefix .. table.concat(healers, ', ')
end

-- Print command options to chat
function LoathebRotate:printHelp()
    local spacing = '   '
    LoathebRotate:printMessage(LoathebRotate:colorText('/loathebrotate, /loa') .. ' commands options :')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('toggle') .. ' : Show/Hide the main window')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('settings') .. ' : Show/hide LoathebRotate settings')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('history') .. ' : Show/hide history window')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('lock') .. ' : Lock the main window position')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('unlock') .. ' : Unlock the main window position')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('report') .. ' : Print the rotation setup to the configured channel')
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('check') .. ' : Print user versions of LoathebRotate')
end

-- Adds color to given text
function LoathebRotate:colorText(text)
    return '|cffffbf00' .. text .. '|r'
end

-- Check if unit is promoted
function LoathebRotate:isHealerPromoted(name)

	local raidIndex = UnitInRaid(name);

    if (raidIndex) then
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(raidIndex)

        if (rank > 0) then
            return true
        end
    end

    return false
end

-- Toggle arcane shot testing mode
function LoathebRotate:toggleArcaneShotTesting(disable)

    if (not disable and not LoathebRotate.testMode) then
        LoathebRotate:printPrefixedMessage(L['ARCANE_SHOT_TESTING_ENABLED'])
        LoathebRotate.testMode = true

        -- Disable testing after 60 minutes
        C_Timer.After(3600, function()
            LoathebRotate:toggleArcaneShotTesting(true)
        end)
    else
        LoathebRotate.testMode = false
        LoathebRotate:printPrefixedMessage(L['ARCANE_SHOT_TESTING_DISABLED'])
    end

    LoathebRotate:updateRaidStatus()
end

--function LoathebRotate:updatePlayerAddonVersion(playerName, version)

--    LoathebRotate.addonVersions[playerName] = version

--    local hunter = LoathebRotate:getHunter(playerName)
--    if (hunter) then
--        hunter.addonVersion = version
--        LoathebRotate:updateBlindIcon(hunter)
--    end

--    local updateRequired, breakingUpdate = LoathebRotate:isUpdateRequired(version)
--    if (updateRequired) then
--        LoathebRotate:notifyUserAboutAvailableUpdate(breakingUpdate)
--    end
--end

function LoathebRotate:checkVersions()
    LoathebRotate:printPrefixedMessage(string.format(L["VERSION_INFO"], UnitName('player'), LoathebRotate.version));
	LoathebRotate:requestVersionCheck();
end


-- Parse version string
-- @return major, minor, fix, isStable
function LoathebRotate:parseVersionString(versionString)

    if versionString == nil then
        return 0, 0, 0, false
    end

    local version, versionType = strsplit("-", versionString)
    local major, minor, fix = strsplit(".", version)

    return tonumber(major), tonumber(minor), tonumber(fix), versionType == nil
end

---- Check if the given version would require updating
---- @return requireUpdate, breakingUpdate
--function LoathebRotate:isUpdateRequired(versionString)

--    local remoteMajor, remoteMinor, remoteFix, isRemoteStable = self:parseVersionString(versionString)
--    local localMajor, localMinor, localFix, isLocalStable = self:parseVersionString(LoathebRotate.version)

--    if (isRemoteStable) then

--        if (remoteMajor > localMajor) then
--            return true, true
--        elseif (remoteMajor < localMajor) then
--            return false, false
--        end

--        if (remoteMinor > localMinor) then
--            return true, false
--        elseif (remoteMinor < localMinor) then
--            return false, false
--        end

--        if (remoteFix > localFix) then
--            return true, false
--        end
--    end

--    return false, false
--end

---- Notify user about a new version available
--function LoathebRotate:notifyUserAboutAvailableUpdate(isBreakingUpdate)
--    if (isBreakingUpdate) then
--        if (LoathebRotate.notifiedBreakingUpdate ~= true) then
--            LoathebRotate:printPrefixedMessage('|cffff3d3d' .. L['BREAKING_UPDATE_AVAILABLE'] .. '|r')
--            LoathebRotate.notifiedBreakingUpdate = true
--        end
--    else
--        if (LoathebRotate.notifiedUpdate ~= true and LoathebRotate.notifiedBreakingUpdate ~= true) then
--            LoathebRotate:printPrefixedMessage(L['UPDATE_AVAILABLE'])
--            LoathebRotate.notifiedUpdate = true
--        end
--    end
--end
