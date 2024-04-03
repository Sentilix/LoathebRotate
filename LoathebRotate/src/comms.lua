local LoathebRotate = select(2, ...)

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Register comm prefix at initialization steps
function LoathebRotate:initComms()

    LoathebRotate.syncVersion = 0
    LoathebRotate.syncLastSender = ''

    AceComm:RegisterComm(LoathebRotate.constants.commsPrefix, LoathebRotate.OnCommReceived)
end

-- Handle message reception and
function LoathebRotate.OnCommReceived(prefix, data, channel, sender)

    if not UnitIsUnit('player', sender) then

        local success, message = AceSerializer:Deserialize(data)

        if (success) then
            if message.type == LoathebRotate.constants.commsTypes.syncOrder
            or message.type == LoathebRotate.constants.commsTypes.syncRequest then
                -- Get addon version from messages who have this information
                LoathebRotate:updatePlayerAddonVersion(sender, message.addonVersion)
            end

            if (message.mode ~= LoathebRotate.db.profile.currentMode) then
                -- Received a message from another mode
                -- This may also happen if the message comes from an old version of the addon but it causes many problems so it's best to ignore the message
                -- In a future version, all modes will be working simultaneously, but that will be in a distant future (probably not before v1.0)

                -- Special case for assignments: accept assignments from other modes because assignments can be set within another mode
                if message.type == LoathebRotate.constants.commsTypes.syncOrder and message.assignment then
                    LoathebRotate:applyAssignmentConfiguration(message.assignment, sender, message.mode)
                end

                return
            end

            if (message.type == LoathebRotate.constants.commsTypes.tranqshotDone) then
                LoathebRotate:receiveSyncTranq(prefix, message, channel, sender)
            elseif (message.type == LoathebRotate.constants.commsTypes.syncOrder) then
                LoathebRotate:receiveSyncOrder(prefix, message, channel, sender)
            elseif (message.type == LoathebRotate.constants.commsTypes.syncRequest) then
                LoathebRotate:receiveSyncRequest(prefix, message, channel, sender)
            end
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

-----------------------------------------------------------------------------------------------------------------------
-- OUTPUT
-----------------------------------------------------------------------------------------------------------------------

-- Broadcast a tranqshot event
function LoathebRotate:sendSyncTranq(hunter, fail, timestamp, targetGUID)
    local message = {
        ['type'] = LoathebRotate.constants.commsTypes.tranqshotDone,
        ['mode'] = LoathebRotate.db.profile.currentMode,
        ['timestamp'] = timestamp,
        ['player'] = hunter.GUID,
        ['fail'] = fail,
        ['target'] = targetGUID,
    }

    LoathebRotate:sendRaidAddonMessage(message)
end

-- Broadcast current rotation configuration
function LoathebRotate:sendSyncOrder(whisperName)

    LoathebRotate.syncVersion = LoathebRotate.syncVersion + 1
    LoathebRotate.syncLastSender = UnitName("player")

    local message = {
        ['type'] = LoathebRotate.constants.commsTypes.syncOrder,
        ['mode'] = LoathebRotate.db.profile.currentMode,
        ['version'] = LoathebRotate.syncVersion,
        ['rotation'] = LoathebRotate:getSimpleRotationTables(),
        ['assignment'] = LoathebRotate:getAssignmentTable(LoathebRotate.db.profile.currentMode),
        ['addonVersion'] = LoathebRotate.version,
    }

    if whisperName and whisperName ~= '' then
        LoathebRotate:sendWhisperAddonMessage(message, whisperName)
    else
        LoathebRotate:sendRaidAddonMessage(message)
    end
end

-- Broadcast a request for the current rotation configuration
function LoathebRotate:sendSyncOrderRequest()

    local message = {
        ['type'] = LoathebRotate.constants.commsTypes.syncRequest,
        ['mode'] = LoathebRotate.db.profile.currentMode,
        ['addonVersion'] = LoathebRotate.version,
    }

    LoathebRotate:sendRaidAddonMessage(message)
end

-----------------------------------------------------------------------------------------------------------------------
-- INPUT
-----------------------------------------------------------------------------------------------------------------------

-- Tranqshot event received
function LoathebRotate:receiveSyncTranq(prefix, message, channel, sender)

    local hunter = LoathebRotate:getHunter(message.player)
    if (hunter == nil) then
        -- TODO maybe display a warning to the user because this should not happen in theory
        return
    end

    local notDuplicate = hunter.lastTranqTime <  GetTime() - LoathebRotate.constants.duplicateTranqshotDelayThreshold

    if (notDuplicate) then
        LoathebRotate:rotate(hunter, message.fail, nil, nil, message.targetGUID)
    end
end

-- Rotation configuration received
function LoathebRotate:receiveSyncOrder(prefix, message, channel, sender)

    LoathebRotate:updateRaidStatus()

    if (LoathebRotate:isVersionEligible(message.version, sender)) then
        LoathebRotate.syncVersion = (message.version)
        LoathebRotate.syncLastSender = sender

        LoathebRotate:printPrefixedMessage('Received new rotation configuration from ' .. sender)
        LoathebRotate:applyRotationConfiguration(message.rotation)
        LoathebRotate:applyAssignmentConfiguration(message.assignment, sender, message.mode)
    end
end

-- Request to send current roration configuration received
function LoathebRotate:receiveSyncRequest(prefix, message, channel, sender)
    LoathebRotate:sendSyncOrder(sender)
end
