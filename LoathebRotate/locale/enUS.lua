local L = LibStub("AceLocale-3.0"):NewLocale("LoathebRotate", "enUS", true, false)
if not L then return end
L["LOADED_MESSAGE"] = "LoathebRotate loaded, type /LoathebRotate for options"
L["MAIN_WINDOW_HIDDEN"] = "window hidden. Use /loa toggle to get it back"

    -- Buttons
L["BUTTON_SETTINGS"] = "Settings"
L["BUTTON_RESET_ROTATION"] = "Reset Rotation"
L["BUTTON_PRINT_ROTATION"] = "Print Rotation"
L["BUTTON_HISTORY"] = "History"
L["BUTTON_RESPAWN_HISTORY"] = "Respawn old messages"
L["BUTTON_CLEAR_HISTORY"] = "Clear"

    -- Settings
L["SETTING_GENERAL"] = "General"
L["SETTING_GENERAL_REPORT"] = "Please report any issue at"
L["SETTING_GENERAL_DESC"] = "Work in Progress: LoathebRotate is an extension of TranqRotate but without the dedicated hunter tranqshots."

L["SETTING_DEBUG"] = "Debug"
L["SETTING_DEBUG_ENABLED"] = "Enable debug mode"
L["SETTING_DEBUG_ENABLED_DESC"] = "Debug mode: simulate Boss and Boss spells."
L["SETTING_DEBUG_BOSS"] = "Boss ID"
L["SETTING_DEBUG_BOSS_DESC"] = "Pretend this NPC is Loatheb!"
L["SETTING_DEBUG_SPELL"] = "Spell ID"
L["SETTING_DEBUG_SPELL_DESC"] = "Pretend this spell is Corrupted Mind!"


L["LOCK_WINDOW"] = "Lock window"
L["LOCK_WINDOW_DESC"] = "Lock window"
L["HIDE_WINDOW_NOT_IN_RAID"] = "Hide the window when not in a raid"
L["HIDE_WINDOW_NOT_IN_RAID_DESC"] = "Hide the window when not in a raid"
L["ALWAYS_SHOW_WINDOW"] = "Always show window"
L["ALWAYS_SHOW_WINDOW_DESC"] = "Check this if you want the window to show up at login - raid or not"
L["SHOW_WHEN_TARGETING_BOSS"] = "Show window when you target Loatheb"
L["SHOW_WHEN_TARGETING_BOSS_DESC"] = "Show window when you target the Loatheb boss"
L["WINDOW_LOCKED"] = "LoathebRotate: Window locked"
L["WINDOW_UNLOCKED"] = "LoathebRotate: Window unlocked"

    --- Announces
L["SETTING_ANNOUNCES"] = "Announces"
L["ENABLE_ANNOUNCES"] = "Enable announces"
L["ENABLE_ANNOUNCES_DESC"] = "Enable / disable the announcement."

    ---- Channels
L["ANNOUNCES_CHANNEL_HEADER"] = "Announce channel"
L["MESSAGE_CHANNEL_TYPE"] = "Send messages to"
L["MESSAGE_CHANNEL_TYPE_DESC"] = "Channel you want to send messages"
L["MESSAGE_CHANNEL_NAME"] = "Channel name"
L["MESSAGE_CHANNEL_NAME_DESC"] = "Set the name of the target channel"

    ----- Channels types
L["CHANNEL_CHANNEL"] = "Channel"
L["CHANNEL_RAID_WARNING"] = "Raid Warning"
L["CHANNEL_SAY"] = "Say"
L["CHANNEL_YELL"] = "Yell"
L["CHANNEL_PARTY"] = "Party"
L["CHANNEL_RAID"] = "Raid"
L["CHANNEL_GUILD"] = "Guild"
L["CHANNEL_WHISPER"] = "Whisper"

    ---- Messages
L["ANNOUNCES_MESSAGE_HEADER"] = "Announce messages"
L["NEUTRAL_MESSAGE_LABEL"] = "[%s] Effect announce message"
L["SUCCESS_MESSAGE_LABEL"] = "[%s] Successful announce message"
L["FAIL_MESSAGE_LABEL"] = "[%s] Fail announce message"
L["REACT_MESSAGE_LABEL"] = "[%s] Local alert if a player failed and you're next in the rotation"

L["ANNOUNCEMENT_CORRUPTED_MIND"] = "Corrupted Mind on %s"
L["ANNOUNCEMENT_NEXTHEALER"] = "I've healed - %s is next!"
L["ANNOUNCEMENT_YOU_ARE_NEXT"] = "YOU ARE NEXT to heal!!!"

L["BROADCAST_MESSAGE_HEADER"] = "Rotation setup text broadcast"
L["USE_MULTILINE_ROTATION_REPORT"] = "Use multiline for main rotation when reporting"
L["USE_MULTILINE_ROTATION_REPORT_DESC"] = "Check this option if you want more comprehensible order display"

    --- Modes
L["SETTING_MODES"] = "Modes"
L["FILTER_SHOW_TRANQSHOT"] = "Tranq"
L["FILTER_SHOW_LOATHEB"] = "Loatheb"
L["FILTER_SHOW_DISTRACT"] = "Distract"
L["FILTER_SHOW_FEARWARD"] = "FearWard"
L["FILTER_SHOW_AOETAUNT"] = "AoE Taunt"
L["FILTER_SHOW_MISDI"] = "Misdi"
L["FILTER_SHOW_BLOODLUST"] = "BL"
L["FILTER_SHOW_GROUNDING"] = "Ground"
L["FILTER_SHOW_BREZ"] = "B-Rez"
L["FILTER_SHOW_INNERV"] = "Innerv"
L["FILTER_SHOW_BOP"] = "BoP"
L["FILTER_SHOW_BOF"] = "Freedom"
L["FILTER_SHOW_SOULSTONE"] = "Soul"
L["FILTER_SHOW_SOULWELL"] = "Well"
L["FILTER_SHOW_SCORPID"] = "Scorpid"
L["NO_MODE_AVAILABLE"] = "<Choose modes in settings>"
L["MODE_INVISIBLE"] = "This is the currently selected mode and it will stay that way even though the button is not visible.\nYou may want to click a visible button mode in order to select another mode."

L["LOATHEB_MODE_FULL_NAME"] = "Loatheb"
L["LOATHEB_MODE_DETAILED_DESC"] = "This mode tracks Loatheb's ability that prevents healers from casting healing spells for 60 seconds."

L["MODE_BUTTON_DESC"] = "Show the button for activating the mode '%s'"
L["MODE_LABEL"] = "Button Text"
L["MODE_LABEL_DESC"] = "Text that appears in the button for activating the mode '%s'"
L["MODE_TRACK_FOCUS"] = "Match Focus with Assignement"
L["MODE_TRACK_FOCUS_DESC"] = "Detect when your assignment changes and suggest to match the focus with the new assignment"

    --- Names
L["SETTING_NAMES"] = "Names"
L["NAME_TAG_HEADER"] = "Name Tags"
L["USE_CLASS_COLOR"] = "Class color"
L["USE_CLASS_COLOR_DESC"] = "Colorize names based on class"
L["USE_NAME_OUTLINE"] = "Name outline"
L["USE_NAME_OUTLINE_DESC"] = "Display a thin black outline around the names"
L["PREPEND_INDEX"] = "Display row number"
L["PREPEND_INDEX_DESC"] = "Display the row number in the rotation before each player name"
L["INDEX_PREFIX_COLOR"] = "Row number color"
L["INDEX_PREFIX_COLOR_DESC"] = "Color of the number if 'Display row number' is enabled"
L["APPEND_GROUP"] = "Append group number"
L["APPEND_GROUP_DESC"] = "Append the group number next to each player name"
L["GROUP_SUFFIX_LABEL"] = "Group suffix"
L["GROUP_SUFFIX_LABEL_DESC"] = "Label used when appending group if 'Append group number' is enabled.\n%s indicates the number"
L["GROUP_SUFFIX_COLOR"] = "Group suffix color"
L["GROUP_SUFFIX_COLOR_DESC"] = "Color of the appended text if 'Append group number' is enabled"
L["DEFAULT_GROUP_SUFFIX_MESSAGE"] = "group %s"
L["APPEND_TARGET"] = "Append target name"
L["APPEND_TARGET_DESC"] = "When a player casts a spell or a buff on a single player target, append the name of the target next to the name of the caster; this option has no effect for AoE spells nor for non-player targets, e.g. mobs"
L["APPEND_TARGET_BUFFONLY"] = "Show the target name only while buffed"
L["APPEND_TARGET_BUFFONLY_DESC"] = "The target name is displayed as long as the buff is active on the target, then hide it when the buff fades; this option has no effect for non-buff modes"
L["APPEND_TARGET_NOGROUP"] = "Hide the group number when there is a target name"
L["APPEND_TARGET_NOGROUP_DESC"] = "When the target name is displayed, hide temporarily the group number in order to save space and reduce clutter"
L["BACKGROUND_HEADER"] = "Background"
L["NEUTRAL_BG"] = "Neutral"
L["NEUTRAL_BG_DESC"] = "Standard background color for units"
L["ACTIVE_BG"] = "Active"
L["ACTIVE_BG_DESC"] = "Background color for the unit who is the current focus in the rotation"
L["DEAD_BG"] = "Dead"
L["DEAD_BG_DESC"] = "Background color for dead units"
L["OFFLINE_BG"] = "Offline"
L["OFFLINE_BG_DESC"] = "Background color for offline units"

    --- Sounds
L["SETTING_SOUNDS"] = "Sounds"
L["ENABLE_NEXT_TO_HEAL_SOUND"] = "Play a sound when you are the next to heal"
L["ENABLE_TRANQ_NOW_SOUND"] = "Play a sound when you have to shoot your spell"
L["TRANQ_NOW_SOUND_CHOICE"] = "Select the sound you want to use for the 'cast now' alert"
L["DBM_SOUND_WARNING"] = "DBM is playing the 'flag taken' sound on each frenzy, it may prevent you from earing gentle sounds from LoathebRotate. I would either suggest to pick a strong sound or disable DBM frenzy sound."

    --- History
L["SETTING_HISTORY"] = "History"
L["HISTORY_FADEOUT"] = "Time to Fade"
L["HISTORY_FADEOUT_DESC"] = "Time, in seconds, to keep messages visible in the History window.\n" ..
        "Old messages can be displayed back, using the Respawn button.\n" ..
        "Hitting the Clear button erases all messages, current and past, forever."
L["HISTORY_FONTSIZE"] = "Font Size"

L["HISTORY_DEBUFF_RECEIVED"] = "%s is afflicted by %s."
L["HISTORY_SPELLCAST_NOTARGET"] = "%s casts %s."
L["HISTORY_SPELLCAST_SUCCESS"] = "%s casts %s on %s."
L["HISTORY_SPELLCAST_FAILURE"] = "%s FAILS to cast %s on %s."
L["HISTORY_SPELLCAST_EXPIRE"] = "%s expires on %s."
L["HISTORY_SPELLCAST_CANCEL"] = "%s fades on %s before the end."
L["HISTORY_TRANQSHOT_FRENZY"] = "%s enters %s."
L["HISTORY_GROUNDING_SUMMON"] = "Totem of %s is protecting ||group|| %s."
L["HISTORY_GROUNDING_CHANGE"] = "%s joins ||group|| %s."
L["HISTORY_GROUNDING_ORPHAN"] = "%s has died."
L["HISTORY_GROUNDING_CANCEL"] = "Totem of %s has been cancelled early because of %s."
L["HISTORY_GROUNDING_EXPIRE"] = "Totem of %s expires."
L["HISTORY_GROUNDING_ABSORB"] = "Totem of %s absorbs %s from %s."
L["HISTORY_GROUNDING_ABSORB_NOSPELL"] = "Totem of %s absorbs attack from %s."
L["HISTORY_ASSIGN_PLAYER"] = "%s assigned %s to focus on %s."
L["HISTORY_ASSIGN_NOBODY"] = "%s un-assigned %s."

    --- Icons
L["DISPLAY_BLIND_ICON"] = "Show an icon for players without LoathebRotate"
L["DISPLAY_BLIND_ICON_DESC"] = "Adds a blind icon next to the player names who have not installed the addon. S/he will not be aware of the rotation and won't be synced if s/he's far from every other LoathebRotate user."
L["DISPLAY_BLIND_ICON_TOOLTIP"] = "Show the blind icon tooltip"
L["DISPLAY_BLIND_ICON_TOOLTIP_DESC"] = "You can disable this options to disable the tooltip while still having the icon"

    --- Tooltips
L["TOOLTIP_PLAYER_WITHOUT_ADDON"] = "This player does not use LoathebRotate"
L["TOOLTIP_MAY_RUN_OUDATED_VERSION"] = "Or runs an outdated version"
L["TOOLTIP_DISABLE_SETTINGS"] = "(You can disable the icon and/or the tooltip in the settings)"
L["TOOLTIP_EFFECT_REMAINING"] = "Effect remaining: %s"
L["TOOLTIP_COOLDOWN_REMAINING"] = "Cooldown remaining: %s"
L["TOOLTIP_DURATION_SECONDS"] = "%s sec"
L["TOOLTIP_DURATION_MINUTES"] = "%s min"
L["TOOLTIP_ASSIGNED_TO"] = "Assigned to: %s"
L["TOOLTIP_EFFECT_CURRENT"] = "Currently on: %s"
L["TOOLTIP_EFFECT_PAST"] = "Last used on: %s"

    --- Context Menu
L["CONTEXT_ASSIGN_TITLE"] = "Assign %s to:"
L["CONTEXT_NOBODY"] = "Nobody"
L["CONTEXT_CANCEL"] = "Cancel"
L["CONTEXT_OTHERS"] = "Other players"

    --- Dialog Box
L["DIALOG_ASSIGNMENT_QUESTION1"] = "Your focus does not match your assignment."
L["DIALOG_ASSIGNMENT_QUESTION2"] = "Do you want to set the focus to %s?"
L["DIALOG_ASSIGNMENT_CHANGE_FOCUS"] = "Change Focus"

    --- Notifications
L["UPDATE_AVAILABLE"] = "A new version is available, please update to get the latest features."
L["BREAKING_UPDATE_AVAILABLE"] = "A new, CRITICAL update is available, you MUST update AS SOON AS possible! LoathebRotate may not work correctly between you and up-to-date players."

L["VERSION_INFO"] = "%s: version %s"

    --- Profiles
L["SETTING_PROFILES"] = "Profiles"

    --- Raid broadcast messages
L["BROADCAST_HEADER_TEXT"] = "[%s] Setup"
L["BROADCAST_ROTATION_PREFIX"] = "Rotation"
L["BROADCAST_BACKUP_PREFIX"] = "Backup"
