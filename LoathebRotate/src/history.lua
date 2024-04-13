local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Add one message to current history and save it to config
-- @param message   Message to add
function LoathebRotate:addHistoryMessage(msg)
	local modeName = WrapTextInColorCode(L["FILTER_SHOW_LOATHEB"], LoathebRotate.loathebMode.color)
	local timestamp = GetTime()
	local hrTime = date("%H:%M:%S", GetServerTime())
	LoathebRotate.historyFrame.backgroundFrame.textFrame:AddMessage(string.format("%s [%s] %s", modeName, hrTime, msg))
	table.insert(LoathebRotate.db.profile.history.messages, {
		mode = 'Loatheb',
		timestamp = timestamp,
		humanReadableTime = hrTime,
		text = msg
	})
end

-- Add one message for a debuff applied
function LoathebRotate:addHistoryDebuffMessage(unitName, spellName)
    local msg
    msg = string.format(self:getHistoryPattern("HISTORY_DEBUFF_RECEIVED"), unitName, spellName)
    self:addHistoryMessage(msg)
end

function LoathebRotate:getHistoryPattern(localeKey)
    local colorBegin = "|cffb3b3b3"
    local colorEnd = "|r"
    return colorBegin..L[localeKey]:gsub("(%%s)", colorEnd.."%1"..colorBegin):gsub("||([^|]*)||", colorEnd.."%1"..colorBegin)..colorEnd
end

-- Load history messages from config
function LoathebRotate:loadHistory()
    for _, item in pairs(LoathebRotate.db.profile.history.messages) do
        local modeName = WrapTextInColorCode(L["FILTER_SHOW_LOATHEB"], LoathebRotate.loathebMode.color)
        local hrTime = item.humanReadableTime
        local msg = item.text
        LoathebRotate.historyFrame.backgroundFrame.textFrame:AddMessage(string.format("%s [%s] %s", modeName, hrTime, msg))
        -- Hack the timestamp so that fading actually relates to when the message was added
        LoathebRotate.historyFrame.backgroundFrame.textFrame.historyBuffer:GetEntryAtIndex(1).timestamp = item.timestamp
    end
end

-- Clear messages on screen and in config
function LoathebRotate:clearHistory()
    LoathebRotate.historyFrame.backgroundFrame.textFrame:Clear()
    LoathebRotate.db.profile.history.messages = {}
end

-- Set time until fadeout starts, in seconds
function LoathebRotate:setHistoryTimeVisible(duration)
    if type(duration) ~= 'number' then
        duration = tonumber(duration)
    end
    if type(duration) == 'number' and duration >= 0 then
        LoathebRotate.historyFrame.backgroundFrame.textFrame:SetTimeVisible(duration)
    end
end

-- Show again messages that were hidden due to fading after a certain time
function LoathebRotate:respawnHistory()
    LoathebRotate.historyFrame.backgroundFrame.textFrame:ResetAllFadeTimes()
end

-- Set the font size for displaying log messages
function LoathebRotate:setHistoryFontSize(fontSize)
    local fontFace = LoathebRotate.constants.history.fontFace
    LoathebRotate.historyFrame.backgroundFrame.textFrame:SetFont(fontFace, fontSize, "")
end


