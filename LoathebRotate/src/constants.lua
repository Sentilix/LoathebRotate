local LoathebRotate = select(2, ...)

LoathebRotate.colors = {
    ['white']       = CreateColor(1,1,1),
    ['lightRed']    = CreateColor(1.0, 0.4, 0.4),
    ['red']         = CreateColor(0.7, 0.3, 0.3),
    ['flashyRed']   = CreateColor(1, 0, 0),
    ['green']       = CreateColor(0.67, 0.83, 0.45),
    ['darkGreen']   = CreateColor(0.1, 0.4, 0.1),
    ['blue']        = CreateColor(0.3, 0.3, 0.7),
    ['darkBlue']    = CreateColor(0.1, 0.1, 0.4),
    ['lightGray']   = CreateColor(0.8, 0.8, 0.8),
    ['darkGray']    = CreateColor(0.3, 0.3, 0.3),
    ['lightCyan']   = CreateColor(0.5, 0.8, 1),
    ['purple']      = CreateColor(0.71, 0.45, 0.75),

	--	Colors used by LoathebRotate:
    ['headerBar']    = CreateColor(0.1, 0.1, 0.4),
    ['buttonBar']    = CreateColor(0.1, 0.2, 0.6),
    -- Below are user-defined colors
    ['groupSuffix'] = nil,
    ['indexPrefix'] = nil,
    ['neutral'] = nil,
    ['active'] = nil,
    ['dead'] = nil,
    ['offline'] = nil,
}

LoathebRotate.constants = {
    ['healerFrameHeight'] = 22,
    ['healerFrameSpacing'] = 4,
    ['titleBarHeight'] = 18,
    ['modeBarHeight'] = 18,
    ['bottomFrameFontSize'] = 12,
    ['bottomFrameMargin'] = 2,
    ['rotationFramesBaseHeight'] = 20,

	['healerClasses'] = {
		['Druid'] = 1,
		['Paladin'] = 2,
		['Priest'] = 3,
		['Shaman'] = 4,
	},

    ['printPrefix'] = 'Loatheb Rotate - ',
	['printColor'] = 'ffffbf00',	-- Color used for local output

    history = {
        fontFace = "Fonts\\ARIALN.ttf",
        fontSize = 12,
        margin = 4,
        defaultTimeVisible = 600, -- Fallback value in case the configuration is not a number
    },

    ['commsPrefix'] = 'loathebrotate',

    ['commsChannel'] = 'RAID',

    ['commsTypes'] = {
		['versionRequest']		= 'tx-version',
		['versionResponse']		= 'rx-version',
		['moveHealerRequest']	= 'tx-move',
		['moveHealerResponse']	= 'rx-move',		-- Dummy: There is no response to a tx-move
		['syncRequest']			= 'tx-sync',
		['syncResponse']		= 'rx-sync',
		['syncBeginRequest']	= 'tx-sync-begin',
		['syncBatchRequest']	= 'tx-batch',
		['syncBatchResponse']	= 'rx-batch',		-- Dummy: There is no response to a tx-batch
		['resetRequest']		= 'tx-reset',
		['resetResponse']		= 'rx-reset',		-- Dummy: There is no response to a tx-reset
		['showWindowRequest']	= 'tx-showWindow',
		['showWindowResponse']	= 'rx-showWindow',	-- Dummy: There is no response to a tx-showWindow
    },

    ['minimumCooldownElapsedForEligibility'] = 1,

    ['sounds'] = {
		['nextToHeal'] = 'Interface\\AddOns\\LoathebRotate\\sounds\\ding.ogg',
        ['alarms'] = {
            ['alarm1'] = 'Interface\\AddOns\\LoathebRotate\\sounds\\alarm.ogg',
            ['alarm2'] = 'Interface\\AddOns\\LoathebRotate\\sounds\\alarm2.ogg',
            ['alarm3'] = 'Interface\\AddOns\\LoathebRotate\\sounds\\alarm3.ogg',
            ['alarm4'] = 'Interface\\AddOns\\LoathebRotate\\sounds\\alarm4.ogg',
            ['flagtaken'] = 'Sound\\Spells\\PVPFlagTaken.ogg',
        }
    },

    ['healNowSounds'] = {
        ['alarm1'] = 'Loud BUZZ',
        ['alarm2'] = 'Gentle beeplip',
        ['alarm3'] = 'Gentle dong',
        ['alarm4'] = 'Light bipbip',
        ['flagtaken'] = 'Flag Taken (DBM)',
    },

}


-- Each mode has a specific Broadcast text so that it does not conflict with other modes
function LoathebRotate:getBroadcastHeaderText()
    return string.format(L['BROADCAST_HEADER_TEXT'], L["LOATHEB_MODE_FULL_NAME"]);
end

LoathebRotate.loathebMode = {
    oldModeName = 'healerz',
    default = true,
    raidOnly = true,
    color = 'ff3fe7cc', -- Green-ish gooey of Loatheb HS card
    wanted = {'PRIEST', 'PALADIN', 'SHAMAN', 'DRUID'},
    cooldown = 60,
    -- effectDuration = nil,
    -- canFail = nil,
    -- alertWhenFail = nil,
    -- spell = nil,
   -- auraTest = function(self, spellId, spellName)
   --     return false
			--or spellId == 29184 -- priest debuff
			--or spellId == 29195 -- druid debuff
			--or spellId == 29197 -- paladin debuff
			--or spellId == 29199 -- shaman debuff
			----or (LoathebRotate.db.profile.enableDebug and spellId == 1*(LoathebRotate.db.profile.emulatedSpellId or 0))
    --end,
    -- customCombatlogFunc = nil,
    -- effectDuration = nil,
    -- targetGUID = nil,
    -- buffName = nil,
    -- buffCanReturn = nil,
    -- customTargetName = nil,
    -- customHistoryFunc = nil,
    -- groupChangeFunc = nil,
    --announceArg = 'sourceName',
    -- tooltip = nil,
    -- assignable = nil,
    -- metadata = nil
}

