local Addon = select(1, ...)
local LoathebRotate = select(2, ...)

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

function LoathebRotate:CreateConfig()

	local function get(info)
		return LoathebRotate.db.profile[info[#info]]
	end

	local function set(info, value)
		LoathebRotate.db.profile[info[#info]] = value
        LoathebRotate:applySettings()
	end

    local function refreshNames()
        for _, healer in pairs(LoathebRotate.healerTable) do
            LoathebRotate:setHealerName(healer)
        end
    end

    local function refreshFrameColors()
        for _, healer in pairs(LoathebRotate.healerTable) do
            LoathebRotate:setHealerFrameColor(healer)
        end
    end

    local function getColor(info)
        return LoathebRotate.db.profile[info[#info]][1], LoathebRotate.db.profile[info[#info]][2], LoathebRotate.db.profile[info[#info]][3]
    end

    local function setColor(info, r, g, b, suffix)
        local colorName = info[#info]
        local suffixIndex = string.find(colorName, suffix)
        if suffixIndex > 0 then
            -- Exclude the trailing suffix string
            colorName = string.sub(colorName, 1, suffixIndex-1)
        end
        LoathebRotate.colors[colorName] = CreateColor(r, g, b)
        set(info, {r,g,b})
    end

    local function setFgColor(info, r, g, b)
        setColor(info, r, g, b, "Color")
        refreshNames()
    end

    local function setBgColor(info, r, g, b)
        setColor(info, r, g, b, "BackgroundColor")
        refreshFrameColors()
    end

    local function setNameTag(...)
        set(...)
        refreshNames()
    end

	local function getEmulatedBossId(info)
		local value = LoathebRotate.db.profile[info[#info]];
		return value or 5112;		-- Gwenna Firebrew
	end
	local function setEmulatedBossId(info, val)
		LoathebRotate.db.profile[info[#info]] = val;
	end

	local function getEmulatedSpellId(info)
		local value = LoathebRotate.db.profile[info[#info]];
		return value or 6788;		-- Weakened Soul
	end
	local function setEmulatedSpellId(info, val)
		LoathebRotate.db.profile[info[#info]] = val;
	end

	local options = {
		name = "LoathebRotate",
		type = "group",
		get = get,
		set = set,
		icon = "",
		args = {
            general = {
                name = L['SETTING_GENERAL'],
                type = "group",
                order = 1,
                args = {
					descriptionText = {
						name = "LoathebRotate " .. LoathebRotate.version .. " by Mimma-PyrewoodVillage.\nAddon is based on SilentRotate by Vinny-Illidan and TranqRotate by Slivo-Sulfuron\n",
						type = "description",
						width = "full",
						order = 1,
					},
					repoLink = {
						name = L['SETTING_GENERAL_REPORT'] .. " https://github.com/sentilix/LoathebRotate\n",
						type = "description",
						width = "full",
						order = 2,
					},
                    -- @todo : find a way to space widget properly
					spacer3 = {
						name = ' ',
						type = "description",
						width = "full",
						order = 3,
					},
					baseVersion = {
						name = L['SETTING_GENERAL_DESC'],
						type = "description",
						width = "full",
						order = 4,
					},
                    -- @todo : find a way to space widget properly
					spacer4 = {
						name = ' ',
						type = "description",
						width = "full",
						order = 5,
					},
                    lock = {
                        name = L["LOCK_WINDOW"],
                        desc = L["LOCK_WINDOW_DESC"],
                        type = "toggle",
                        order = 6,
                        width = "double",
                    },
                    hideNotInRaid = {
                        name = L["HIDE_WINDOW_NOT_IN_RAID"],
                        desc = L["HIDE_WINDOW_NOT_IN_RAID_DESC"],
                        type = "toggle",
                        order = 7,
                        width = "double",
                    },
                    alwaysShowWindow = {
                        name = L["ALWAYS_SHOW_WINDOW"],
                        desc = L["ALWAYS_SHOW_WINDOW_DESC"],
                        type = "toggle",
                        order = 8,
                        width = "full",
                    },
                    showWindowWhenTargetingBoss = {
                        name = L["SHOW_WHEN_TARGETING_BOSS"],
                        desc = L["SHOW_WHEN_TARGETING_BOSS_DESC"],
                        type = "toggle",
                        order = 9,
                        width = "full",
                    },
                    showBlindIcon = {
                        name = L["DISPLAY_BLIND_ICON"],
                        desc = L["DISPLAY_BLIND_ICON_DESC"],
                        type = "toggle",
                        order = 24,
                        width = "full",
                        set = function(info, value) set(info,value) LoathebRotate:refreshBlindIcons() end
                    },
                    showBlindIconTooltip = {
                        name = L["DISPLAY_BLIND_ICON_TOOLTIP"],
                        desc = L["DISPLAY_BLIND_ICON_TOOLTIP_DESC"],
                        type = "toggle",
                        order = 25,
                        width = "full",
                    },
                }
            },
            announces = {
                name = L['SETTING_ANNOUNCES'],
                type = "group",
                order = 2,
                args = {
                    enableAnnounces = {
                        name = L["ENABLE_ANNOUNCES"],
                        desc = L["ENABLE_ANNOUNCES_DESC"],
                        type = "toggle",
                        order = 1,
                        width = "double",
                    },
                    announceHeader = {
                        name = L["ANNOUNCES_MESSAGE_HEADER"],
                        type = "header",
                        order = 20,
                    },
                    channelType = {
                        name = L["MESSAGE_CHANNEL_TYPE"],
                        desc = L["MESSAGE_CHANNEL_TYPE_DESC"],
                        type = "select",
                        order = 21,
                        values = {
                            ["RAID_WARNING"] = L["CHANNEL_RAID_WARNING"],
                            ["SAY"] = L["CHANNEL_SAY"],
                            ["YELL"] = L["CHANNEL_YELL"],
                            ["PARTY"] = L["CHANNEL_PARTY"],
                            ["RAID"] = L["CHANNEL_RAID"],
                            ["GUILD"] = L["CHANNEL_GUILD"],
                            ["WHISPER"] = L["CHANNEL_WHISPER"]
                        },
                    },
                    spacer22 = {
                        name = ' ',
                        type = "description",
                        width = "normal",
                        order = 22,
                    },
                    -- Items of order 30+ will be filled by the end of this script
                    setupBroadcastHeader = {
                        name = L["BROADCAST_MESSAGE_HEADER"],
                        type = "header",
                        order = 50,
                    },
                    rotationReportChannelType = {
                        name = L["MESSAGE_CHANNEL_TYPE"],
                        type = "select",
                        order = 51,
                        values = {
                            ["CHANNEL"] = L["CHANNEL_CHANNEL"],
                            ["RAID_WARNING"] = L["CHANNEL_RAID_WARNING"],
                            ["SAY"] = L["CHANNEL_SAY"],
                            ["YELL"] = L["CHANNEL_YELL"],
                            ["PARTY"] = L["CHANNEL_PARTY"],
                            ["RAID"] = L["CHANNEL_RAID"],
                            ["GUILD"] = L["CHANNEL_GUILD"]
                        },
                        set = function(info, value) set(info,value) LibStub("AceConfigRegistry-3.0", true):NotifyChange("LoathebRotate") end
                    },
                    setupBroadcastTargetChannel = {
                        name = L["MESSAGE_CHANNEL_NAME"],
                        desc = L["MESSAGE_CHANNEL_NAME_DESC"],
                        type = "input",
                        order = 52,
                        hidden = function() return not (LoathebRotate.db.profile.rotationReportChannelType == "CHANNEL") end,
                    },
                    useMultilineRotationReport = {
                        name = L["USE_MULTILINE_ROTATION_REPORT"],
                        desc = L["USE_MULTILINE_ROTATION_REPORT_DESC"],
                        type = "toggle",
                        order = 53,
                        width = "full",
                    },
                }
            },
            names = {
                name = L['SETTING_NAMES'],
                type = "group",
                order = 3,
                args = {
                    nameTagHeader = {
                        name = L["NAME_TAG_HEADER"],
                        type = "header",
                        order = 1,
                    },
                    useClassColor = {
                        name = L["USE_CLASS_COLOR"],
                        desc = L["USE_CLASS_COLOR_DESC"],
                        type = "toggle",
                        order = 2,
                        width = "full",
                        set = setNameTag,
                    },
                    useNameOutline = {
                        name = L["USE_NAME_OUTLINE"],
                        desc = L["USE_NAME_OUTLINE_DESC"],
                        type = "toggle",
                        order = 3,
                        width = "full",
                        set = setNameTag,
                    },
                    prependIndex = {
                        name = L["PREPEND_INDEX"],
                        desc = L["PREPEND_INDEX_DESC"],
                        type = "toggle",
                        order = 4,
                        width = "full",
                        set = setNameTag,
                    },
                    indexPrefixColor = {
                        name = L["INDEX_PREFIX_COLOR"],
                        desc = L["INDEX_PREFIX_COLOR_DESC"],
                        type = "color",
                        order = 5,
                        get = getColor,
                        set = setFgColor,
                        hidden = function() return not LoathebRotate.db.profile.prependIndex end,
                    },
                    backgroundHeader = {
                        name = L["BACKGROUND_HEADER"],
                        type = "header",
                        order = 20,
                    },
                    neutralBackgroundColor = {
                        name = L["NEUTRAL_BG"],
                        desc = L["NEUTRAL_BG_DESC"],
                        type = "color",
                        order = 21,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    activeBackgroundColor = {
                        name = L["ACTIVE_BG"],
                        desc = L["ACTIVE_BG_DESC"],
                        type = "color",
                        order = 22,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    deadBackgroundColor = {
                        name = L["DEAD_BG"],
                        desc = L["DEAD_BG_DESC"],
                        type = "color",
                        order = 23,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    offlineBackgroundColor = {
                        name = L["OFFLINE_BG"],
                        desc = L["OFFLINE_BG_DESC"],
                        type = "color",
                        order = 24,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                }
            },
            sounds = {
                name = L['SETTING_SOUNDS'],
                type = "group",
                order = 4,
                args = {
					enableNextToHealSound = {
						name = L["ENABLE_NEXT_TO_HEAL_SOUND"],
						desc = L["ENABLE_NEXT_TO_HEAL_SOUND"],
						type = "toggle",
						order = 1,
						width = "full",
					},
                    enableTranqNowSound = {
                        name = L["ENABLE_TRANQ_NOW_SOUND"],
                        desc = L["ENABLE_TRANQ_NOW_SOUND"],
                        type = "toggle",
                        order = 2,
                        width = "full",
                    },
                    tranqNowSound = {
                        name = L["TRANQ_NOW_SOUND_CHOICE"],
                        desc = L["TRANQ_NOW_SOUND_CHOICE"],
                        type = "select",
                        style = "dropdown",
                        order = 3,
                        values = LoathebRotate.constants.healNowSounds,
                        set = function(info, value)
                            set(info, value)
                            PlaySoundFile(LoathebRotate.constants.sounds.alarms[value])
                        end
                    },
                    baseVersion = {
                        name = L['DBM_SOUND_WARNING'],
                        type = "description",
                        width = "full",
                        order = 4,
                    },
                }
            },
            history = {
                name = L['SETTING_HISTORY'],
                type = "group",
                order = 5,
                args = {
                    historyTimeVisible = {
                        name = L["HISTORY_FADEOUT"],
                        desc = L["HISTORY_FADEOUT_DESC"],
                        type = "range",
                        min = 5,
                        max = 3600,
                        order = 1,
                        width = "full",
                    },
                    historyFontSize = {
                        name = L["HISTORY_FONTSIZE"],
                        type = "range",
                        min = 8,
                        max = 24,
                        order = 2,
                        width = "full",
                    },
                }
            },
            debug = {
                name = L['SETTING_DEBUG'],
                type = "group",
                order = 6,
                args = {
                    enableDebug = {
                        name = L["SETTING_DEBUG_ENABLED"],
                        desc = L["SETTING_DEBUG_ENABLED_DESC"],
                        type = "toggle",
                        order = 1,
                        width = "full",
                    },
                    emulatedBossId = {
						name = L["SETTING_DEBUG_BOSS"],
						desc = L["SETTING_DEBUG_BOSS_DESC"],
						type = "input",
						order = 2,
						width = "half",
						get = getEmulatedBossId,
						set = setEmulatedBossId,
                    },
                    emulatedSpellId = {
						name = L["SETTING_DEBUG_SPELL"],
						desc = L["SETTING_DEBUG_SPELL_DESC"],
						type = "input",
						order = 3,
						width = "half",
						get = getEmulatedSpellId,
						set = setEmulatedSpellId,
                    },
                }
            },
        }
	}


    AceConfigRegistry:RegisterOptionsTable(Addon, options, true)
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    AceConfigDialog:AddToBlizOptions(Addon, nil, nil, "general")
    AceConfigDialog:AddToBlizOptions(Addon, L['SETTING_ANNOUNCES'], Addon, "announces")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_NAMES"], Addon, "names")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_SOUNDS"], Addon, "sounds")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_HISTORY"], Addon, "history")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_DEBUG"], Addon, "debug")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_PROFILES"], Addon, "profile")

    AceConfigDialog:SetDefaultSize(Addon, 895, 570)

end

