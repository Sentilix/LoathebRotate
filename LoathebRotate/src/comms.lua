local LoathebRotate = select(2, ...)

local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Register comm prefix at initialization steps
function LoathebRotate:initComms()
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
			elseif (message.type == LoathebRotate.constants.commsTypes.syncBatchRequest) then
				LoathebRotate:receiveSyncBatchRequest(prefix, message, channel, sender)
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
        ['from'] = LoathebRotate:getPlayerAndRealm('player'),
        ['to'] = target or '',
		['ver'] = LoathebRotate.version,
		['vernum'] = LoathebRotate:calculateVersionNumber(),
    }

	return request;
end;



-----------------------------------------------------------------------------------------------------------------------
-- VERSION request/response
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestVersionCheck(silentMode)
	local request = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.versionRequest);
	request.silentMode = silentMode or false;
    LoathebRotate:sendRaidAddonMessage(request);
end;

function LoathebRotate:receiveVersionRequest(prefix, message, channel, sender)
	local response = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.versionResponse, sender);
	response.silentMode = message.silentMode or false;
    LoathebRotate:sendRaidAddonMessage(response);

	--	Get this by checking the fullName:
	local healer = LoathebRotate:getHealer(message.from);
	if not healer then
		--	Before 0.4.5 only local name was stored in message.
		--	If healer was not found using fullName we can try the Sender:
		healer = LoathebRotate:getHealer(sender);
	end
	if healer then
		healer.version = message.ver;
	end
end;

function LoathebRotate:receiveVersionResponse(prefix, message, channel, sender)
	if not message.silentMode then
		LoathebRotate:printPrefixedMessage(string.format(L["VERSION_INFO"], sender, message.ver));
	else
		local healer = LoathebRotate:getHealer(message.from);
		if not healer then
			healer = LoathebRotate:getHealer(sender);
		end
		if healer then
			healer.version = message.ver;
		end;
	end;
end;


-----------------------------------------------------------------------------------------------------------------------
-- MOVEHEALER request/response
-----------------------------------------------------------------------------------------------------------------------

function LoathebRotate:requestMoveHealer(healer, group, position)
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.moveHealerRequest);
	message['fullName'] = healer.fullName;
	message['group'] = group;
	message['position'] = position;

	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveMoveHealerRequest(prefix, message, channel, sender)
	if readyToReceiveSyncResponse then return end;

	local healer = LoathebRotate:getHealer(message.fullName);
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
	--	Only respond to sync requests from clients version 0.4.0 or above:
	if not message.vernum or message.vernum < 400 then return end;
	
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncResponse);
	message.to = sender;
	LoathebRotate.readyToReceiveSyncResponse = true;
	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveSyncResponse(prefix, message, channel, sender)
	--	Only accept sync requests from version 0.4.0 or above:
	if not message.vernum or message.vernum < 400 then return end;

	if (LoathebRotate.readyToReceiveSyncResponse == true) then
		LoathebRotate.readyToReceiveSyncResponse = false;
		LoathebRotate.synchronizationDone = true

		--	This person kindly offered to synchronize all data. Begin synchronizing.
		local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncBeginRequest);
		message.to = sender;
		LoathebRotate:sendRaidAddonMessage(message);
	end;
end;

--	Send healer table to the requesting client. However, due to throttling we package
--	healers into batches to keep number of messages down.
function LoathebRotate:receiveBeginSyncRequest(prefix, message, channel, sender)
	--	Only accept sync requests from clients version 0.4.0 or above:
	if not message.vernum or message.vernum < 400 then return end;

	local position, healer;
	local healersPerBatch = 5;
	local batch = {
		['g'] = 'R',		-- R=ROTATION,B=BACKUP - need to keep message short
		['h'] = {}
	}

	--	ROTATION table:
	for position = 1, #LoathebRotate.rotationTable, 1 do
		healer = LoathebRotate.rotationTable[position];
		table.insert(batch.h, { ['F'] = healer.fullName, ['I'] = position });

		if #batch.h >= healersPerBatch then
			LoathebRotate:requestSyncBatch(sender, batch);
			batch.h = { };
		end;
	end;
	if #batch.h > 0 then
		LoathebRotate:requestSyncBatch(sender, batch);
	end;

	--	BACKUP table:
	batch.g = 'B';
	batch.h = { };
	for position = 1, #LoathebRotate.backupTable, 1 do
		healer = LoathebRotate.backupTable[position];
		table.insert(batch.h, { ['F'] = healer.fullName, ['I'] = position });

		if #batch.h >= healersPerBatch then
			LoathebRotate:requestSyncBatch(sender, batch);
			batch.h = {};
		end;
	end;
	if #batch.h > 0 then
		LoathebRotate:requestSyncBatch(sender, batch);
	end;
end;

function LoathebRotate:requestSyncBatch(receiver, batch)
	local message = LoathebRotate:createAddonMessage(LoathebRotate.constants.commsTypes.syncBatchRequest);
	message.to = receiver;
	message.batch = batch;

	LoathebRotate:sendRaidAddonMessage(message);
end;

function LoathebRotate:receiveSyncBatchRequest(prefix, message, channel, sender)
	local position, heal, healer;
	local group = 'ROTATION';
	if message.batch.g == 'B' then
		group = 'BACKUP';
	end;
	for position, heal in pairs(message.batch.h) do
		healer = LoathebRotate:getHealer(heal.F);
		if healer and heal.I then
			LoathebRotate:setHealerPosition(healer, group, heal.I);
		end;
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


