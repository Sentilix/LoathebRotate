local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")


-- Send an annouce message to a given channel, including whisper (if targetname is set)
function LoathebRotate:sendAnnounceMessage(message, targetName)
	if LoathebRotate.db.profile.enableAnnounces then
        LoathebRotate:sendMessage(message, nil, LoathebRotate.db.profile.channelType, targetName);
	end
end

-- Write the rotation to a given channel (general prints - not whisper)
function LoathebRotate:sendRotationMessage(message)
    if LoathebRotate.db.profile.enableAnnounces then
        local channelType = LoathebRotate.db.profile.rotationReportChannelType;
        local targetChannel = LoathebRotate.db.profile.setupBroadcastTargetChannel;
        LoathebRotate:sendMessage(message, nil, channelType, targetChannel);
    end
end

-- Send a message to a given channel
function LoathebRotate:sendMessage(message, targetName, channelType, targetChannel)
	local channelNumber = (channelType == "CHANNEL") and GetChannelName(targetChannel) or nil
	if targetName then
		message = string.format(message, targetName);
	end
	SendChatMessage(message, channelType, nil, channelNumber or targetChannel)
end
