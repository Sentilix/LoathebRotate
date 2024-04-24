local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

function LoathebRotate:LoadDefaults()
	self.defaults = {
	    profile = {
			-- Main windows, at least one always exists
			windows = {
				{
					visible = true,
					width = 150,
				}
			},

			-- Messaging
			enableAnnounces = true,
			channelType = "WHISPER",
			rotationReportChannelType = "RAID",
			useMultilineRotationReport = false,

			-- Names
			useClassColor = true,
			useNameOutline = false,
			prependIndex = false,
			indexPrefixColor = {LoathebRotate.colors.lightCyan:GetRGB()},
			appendGroup = false,
			appendTarget = true,
			appendTargetBuffOnly = false,
			appendTargetNoGroup = true,
			groupSuffix = L["DEFAULT_GROUP_SUFFIX_MESSAGE"],
			groupSuffixColor = {LoathebRotate.colors.lightCyan:GetRGB()},

			-- Background
			neutralBackgroundColor = {LoathebRotate.colors.lightGray:GetRGB()},
			activeBackgroundColor  = {LoathebRotate.colors.purple:GetRGB()},
			deadBackgroundColor    = {LoathebRotate.colors.red:GetRGB()},
			offlineBackgroundColor = {LoathebRotate.colors.darkGray:GetRGB()},

			-- Sounds
			enableNextToHealSound = true,
			enableTranqNowSound = true,
			tranqNowSound = 'alarm1',

			-- History
			history = {
				visible = false,
				width = 400,
				height = 200,
				messages = {},
			},
			historyTimeVisible = 600, -- 10 minutes
			historyFontSize = 12,

			-- Miscellaneous
			lock = false,
			hideNotInRaid = false,
			alwaysShowWindow = false,
			showWindowWhenTargetingBoss = true,
			showBlindIcon = true,
			showBlindIconTooltip = true,
		},
	}

end
