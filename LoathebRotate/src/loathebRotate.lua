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
	LoathebRotate.mainFrame = nil;
	LoathebRotate.openWindowRequestSent = false;
	LoathebRotate.ignoreRaidStatusUpdates = false;
	LoathebRotate.synchronizationDone = false;
	LoathebRotate.readyToReceiveSyncResponse = true;

	LoathebRotate:initGui()
	LoathebRotate:loadHistory()
	LoathebRotate:updateRaidStatus()
	LoathebRotate:applySettings()

	LoathebRotate:initComms();
	LoathebRotate:requestVersionCheck(true);
	LoathebRotate:requestSync();

	LoathebRotate:readRoleSettings();

	LoathebRotate:printMessage(L['LOADED_MESSAGE'])
end

-- Apply setting on profile change
function LoathebRotate:ProfilesChanged()
	self.db:RegisterDefaults(self.defaults);
    self:applySettings();
end


--	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
function LoathebRotate:readRoleSettings()
	local config = LoathebRotate.db.profile;

	if not config.roles then
		config.roles = { };
	end;

	--	Reset roles for all healers:
	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:readRoleFromConfig(healer);
	end

	for _, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:readRoleFromConfig(healer);
	end
end;

function LoathebRotate:readRoleFromConfig(healer)
	local config = LoathebRotate.db.profile;
	if not config.roles then
		config.roles = { };
	end;

	healer.isHealerRole  = false;
	healer.isTankDpsRole = false; 
	healer.isUnknownRole = false;
	healer.roleTimestamp = 0;
	
	local roleInfo = config.roles[healer.fullName];
	if roleInfo then
		if roleInfo.role == "Healer" then
			healer.isHealerRole = true;
			healer.roleTimestamp = roleInfo.timestamp or 0;
		elseif roleInfo.role == "TankDps" then
			healer.isTankDpsRole = true;
			healer.roleTimestamp = roleInfo.timestamp or 0;
		elseif roleInfo.role == "Unknown" then
			healer.isUnknownRole = true;
			healer.roleTimestamp = roleInfo.timestamp or 0;
		end;
	end;
end;

function LoathebRotate:applyRoleSettings()
	local config = LoathebRotate.db.profile;

	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:applyRoleSetting(healer, true);
	end
end;

function LoathebRotate:applyRoleSetting(healer)
	local config = LoathebRotate.db.profile;
	if not config.roles then
		config.roles = { };
	end;

	if healer.isHealerRole then
		config.roles[healer.fullName] = { ["role"] = "Healer", ["timestamp"] = healer.roleTimestamp; }
	elseif healer.isTankDpsRole then
		config.roles[healer.fullName] = { ["role"] = "TankDps", ["timestamp"] = healer.roleTimestamp; }
	elseif healer.isUnknownRole then
		config.roles[healer.fullName] = { ["role"] = "Unknown", ["timestamp"] = healer.roleTimestamp; }
	else
		config.roles[healer.fullName] = nil;
	end
end;



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
    elseif (cmd == 'report') then
        LoathebRotate:printRotationSetup()
    elseif (cmd == 'settings') then
        LoathebRotate:toggleSettings()
	elseif (cmd == 'sync') then
		LoathebRotate:syncRotation();
    elseif (cmd == 'history') then
        LoathebRotate:toggleHistory()
    elseif (cmd == 'check' or cmd== 'version') then
        LoathebRotate:checkVersions()
    else
        LoathebRotate:printHelp()
    end
end

function LoathebRotate:showDisplay()
	LoathebRotate.mainFrame:Show();
end

function LoathebRotate:hideDisplay()
	if LoathebRotate.mainFrame:IsShown() then
		LoathebRotate.mainFrame:Hide();
		LoathebRotate:printPrefixedMessage(L['MAIN_WINDOW_HIDDEN']);
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
	for _, healer in pairs(rotationTable) do
		LoathebRotate:sendRotationMessage(tostring(position) .. ' - ' .. healer.name)
		position = position + 1;
	end
end


function LoathebRotate:syncRotation()
	LoathebRotate.readyToReceiveSyncResponse = true;
	LoathebRotate.synchronizationDone = false;
	LoathebRotate:requestSync();
end;

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
    LoathebRotate:printMessage(spacing .. LoathebRotate:colorText('version') .. ' : Print user versions of LoathebRotate')
end

-- Adds color to given text
function LoathebRotate:colorText(text)
	return string.format('|c%s%s|r', LoathebRotate.constants.printColor, text);
end

-- Check if unit is promoted
function LoathebRotate:isHealerPromoted(name)
	local healer;
	local raidIndex = UnitInRaid(name);
	if (raidIndex) then
		local _, rank = GetRaidRosterInfo(raidIndex);

		if (rank > 0) then
			return true;
		end
	end

	--	Check if there are other promoted healers - if not, we should allow anyone to alter the rotation:
	for _, healer in pairs(LoathebRotate.rotationTable) do
		raidIndex = UnitInRaid(healer.name);
		if (raidIndex) then
			local name, rank, _, _, _, _, _, online = GetRaidRosterInfo(raidIndex);
			if (online and rank > 0) then
				healer = LoathebRotate:getHealer(name);
				if healer and (healer.version ~= '') then
					--	Another healer is promoted (and online) so current player is not allowed to modify rotation order.
					return false;
				end;
			end
		end		
	end
	--	Same for backup table:
	for _, healer in pairs(LoathebRotate.backupTable) do
		raidIndex = UnitInRaid(healer.name);
		if (raidIndex) then
			local name, rank, _, _, _, _, _, online = GetRaidRosterInfo(raidIndex);
			if (online and rank > 0) then
				healer = LoathebRotate:getHealer(name);
				if healer and (healer.version ~= '') then
					return false;
				end;
			end
		end		
	end

	--	No promoted people was found - let the current player alter rotation.
	return true;
end

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
