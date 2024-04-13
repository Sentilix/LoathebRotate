local LoathebRotate = select(2, ...)

local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Register comm prefix at initialization steps
function LoathebRotate:initComms()
	LoathebRotate.syncVersion = 0;
	LoathebRotate.syncLastSender = '';

	AceComm:RegisterComm(LoathebRotate.constants.commsPrefix, LoathebRotate.OnCommReceived);
end

-- Handle message reception and
function LoathebRotate.OnCommReceived(prefix, data, channel, sender)
    if not UnitIsUnit('player', sender) then

		local success, message = AceSerializer:Deserialize(data);
		if (success) then
			local myFullName = LoathebRotate:getPlayerAndRealm('player');
			local receiverFullName = LoathebRotate:getFullPlayerName(message.to);

			if (message.to ~= '' and myFullName ~= receiverFullName) then
				--	Skip if message is not for me!
				return;
			end;

			--	Version:
			if (message.type == LoathebRotate.constants.commsTypes.versionRequest) then
				LoathebRotate:receiveVersionRequest(prefix, message, channel, sender)
			elseif (message.type == LoathebRotate.constants.commsTypes.versionResponse) then
				LoathebRotate:receiveVersionResponse(prefix, message, channel, sender)
			--	MoveHealer:
			elseif (message.type == LoathebRotate.constants.commsTypes.moveHealerRequest) then
				LoathebRotate:receiveMoveHealerRequest(prefix, message, channel, sender)
			--	Sync:
			elseif (message.type == LoathebRotate.constants.commsTypes.syncRequest) then
				LoathebRotate:receiveSyncRequest(prefix, message, channel, sender)
			elseif (message.type == LoathebRotate.constants.commsTypes.syncResponse) then
				LoathebRotate:receiveSyncResponse(prefix, message, channel, sender)
			elseif (message.type == LoathebRotate.constants.commsTypes.syncBeginRequest) then
				LoathebRotate:receiveBeginSyncRequest(prefix, message, channel, sender)
			--	Reset:
			elseif (message.type == LoathebRotate.constants.commsTypes.resetRequest) then
				LoathebRotate:receiveResetRotation(prefix, message, channel, sender)
			--	showWindow:
			elseif (message.type == LoathebRotate.constants.commsTypes.showWindowRequest) then
				LoathebRotate:receiveShowWindowRequest(prefix, message, channel, sender)
			end;
		else
			LoathebRotate:printPrefixedMessage('could not serialize data');
        end
    end
end

-- Checks if a given version from a given sender should be applied
function LoathebRotate:isVersionEligible(version, sender)
	return version > LoathebRotate.syncVersion or (version == LoathebRotate.syncVersion and sender < LoathebRotate.syncLastSender)
end



-----------------------------------------------------------------------------------------------------------------------
-- Messaging functions
-----------------------------------------------------------------------------------------------------------------------

-- Proxy to send raid addon message
function LoathebRotate:sendRaidAddonMessage(message)
    LoathebRotate:sendAddonMessage(message, LoathebRotate.constants.commsChannel)
end

-- Proxy to send whisper addon message
function LoathebRotate:sendWhisperAddonMessage(message, name)
    LoathebRotate:sendAddonMessage(message, 'WHISPER', name)
end

-- Broadcast a given message to the commsChannel with the commsPrefix
function LoathebRotate:sendAddonMessage(message, channel, name)
    AceComm:SendCommMessage(
        LoathebRotate.constants.commsPrefix,
        AceSerializer:Serialize(message),
        channel,
        name
    )
end

function LoathebRotate:createAddonMessage(requestType, target)
    local request = {
        ['type'] = requestType,
        ['from'] = UnitName('player'),
        ['to'] = target or '',
    }

	return request;
end;



-----------------------------------------------------------------------------------------------------------------------
-- VERSION request/response
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestVersionCheck()
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.versionRequest);
    LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveVersionRequest(prefix, message, channel, sender)
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.versionResponse, sender);
	message['version'] = LoathebRotate.version;

    LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveVersionResponse(prefix, message, channel, sender)
    LoathebRotate:printPrefixedMessage(string.format(L["VERSION_INFO"], sender, message.version));
end;


-----------------------------------------------------------------------------------------------------------------------
-- MOVEHEALER request/response
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestMoveHealer(healer, group, position)
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.moveHealerRequest);
	message['GUID'] = healer.GUID;
	message['group'] = group;
	message['position'] = position;

	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveMoveHealerRequest(prefix, message, channel, sender)
	local healer = LoathebRotate:getHealer(message.GUID);
	if healer then
		LoathebRotate:moveHealer(healer, message.group, message.position);
	end;
end;


-----------------------------------------------------------------------------------------------------------------------
-- SYNC request/response
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestSync()
	if not UnitInRaid(UnitName('player')) then return; end
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncRequest);
	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveSyncRequest(prefix, message, channel, sender)
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncResponse);
	LoathebRotate.readyToReceiveSyncResponse = true;
	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveSyncResponse(prefix, message, channel, sender)
	if (LoathebRotate.readyToReceiveSyncResponse == true) then
		LoathebRotate.readyToReceiveSyncResponse = false;
		LoathebRotate.synchronizationDone = true

		--	This person kindly offered to synchronize all data. Begin synchronizing.
		local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncBeginRequest);
		LoathebRotate:sendRaidAddonMessage(message);
	end;
end;

function LoathebRotate:receiveBeginSyncRequest(prefix, message, channel, sender)
	for position, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:requestMoveHealer(healer, 'ROTATION', position);
	end

	for position, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:requestMoveHealer(healer, 'BACKUP', position);
	end
end;



-----------------------------------------------------------------------------------------------------------------------
-- RESET ROTATION SYNC request (no response)
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestResetRotation()
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.resetRequest);
	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveResetRotation(prefix, message, channel, sender)
	LoathebRotate:resetRotation();

	LoathebRotate:printPrefixedMessage(string.format('Rotation was reset by %s.', sender));
end;


-----------------------------------------------------------------------------------------------------------------------
-- OPEN ROTATION WINDOW request (no response)
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestOpenWindow()
	if not LoathebRotate:isActive() then
		return;
	end;

	if not LoathebRotate.openWindowRequestSent then
		LoathebRotate.openWindowRequestSent = true;
		local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.showWindowRequest);
		LoathebRotate:sendRaidAddonMessage(message);
	end;
end;

function LoathebRotate:receiveShowWindowRequest()
	if LoathebRotate:isActive() then
		LoathebRotate.openWindowRequestSent = true;
		LoathebRotate.mainFrame:Show();
	end;
end;


