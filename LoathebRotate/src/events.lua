local LoathebRotate = select(2, ...)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if (event == "PLAYER_LOGIN") then
            LoathebRotate:init()
            self:UnregisterEvent("PLAYER_LOGIN")

            -- Delayed raid update because raid data is unreliable at PLAYER_LOGIN
            C_Timer.After(5, function()
                LoathebRotate:updateRaidStatus()
            end)
        else
            LoathebRotate[event](LoathebRotate, ...)
        end
    end
)

function LoathebRotate:COMBAT_LOG_EVENT_UNFILTERED()

    -- @todo : Improve this with register / unregister event to save ressources
    -- Avoid parsing combat log when not able to use it
    if not self.raidInitialized then return end
    -- Avoid parsing combat log when outside instance if test mode isn't enabled
    if not self:isActive() then return end

    -- All events have these
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    -- Spells and environment have additional info
    local spellId, spellName, spellSchool
    local environmentalType

    -- Damage events have these
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
    -- Other events may have some of the above (damage) or some of the below
    local missType, amountMissed, overhealing, absorbed, overEnergize, powerType, alternatePowerType, auraType, failedType
    local extraGUID, extraName, extraFlags, extraRaidFlags, extraSpellID, extraSpellName, extraSchool, extraAmount

    -- Special events
    local itemID, itemName, recapID, unconsciousOnDeath

    -- Analyze prefix
    local prefixOffset = 12
    local suffixOffset = 12
    if event:sub(0,5) == "SPELL" or event == "DAMAGE_SPLIT" or event == "DAMAGE_SHIELD" or event == "DAMAGE_SHIELD_MISSED" then
        spellId, spellName, spellSchool = select(prefixOffset, CombatLogGetCurrentEventInfo())
        suffixOffset = prefixOffset+3
    elseif event:sub(0,13) == "ENVIRONMENTAL" then
        environmentalType = select(prefixOffset, CombatLogGetCurrentEventInfo())
        suffixOffset = prefixOffset+1
    end

    -- Analyze suffix
    if     event:sub(-7) == "_DAMAGE"
        or event == "DAMAGE_SPLIT"
        or event == "DAMAGE_SHIELD" then
        amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-7) == "_MISSED" then
        missType, isOffHand, amountMissed, critical = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-5) == "_HEAL" then
        amount, overhealing, absorbed, critical = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-14) == "_HEAL_ABSORBED" then
        extraGUID, extraName, extraFlags, extraRaidFlags, extraSpellID, extraSpellName, extraSchool, amount = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-9) == "_ENERGIZE" then
        amount, overEnergize, powerType, alternatePowerType = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-6) == "_DRAIN"
        or event:sub(-6) == "_LEECH" then
        amount, powerType, extraAmount = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-10) == "_INTERRUPT"
        or event:sub(-14) == "_DISPEL_FAILED" then
        extraSpellID, extraSpellName, extraSchool = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-7) == "_DISPEL"
        or event:sub(-7) == "_STOLEN"
        or event:sub(-18) == "_AURA_BROKEN_SPELL" then
        extraSpellID, extraSpellName, extraSchool, auraType = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-14) == "_EXTRA_ATTACKS" then
        amount = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-13) == "_AURA_APPLIED"
        or event:sub(-13) == "_AURA_REMOVED"
        or event:sub(-18) == "_AURA_APPLIED_DOSE"
        or event:sub(-18) == "_AURA_REMOVED_DOSE"
        or event:sub(-13) == "_AURA_REFRESH" then
        auraType, amount = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-12) == "_AURA_BROKEN" then
        auraType = select(suffixOffset, CombatLogGetCurrentEventInfo())
    elseif event:sub(-12) == "_CAST_FAILED" then
        failedType = select(suffixOffset, CombatLogGetCurrentEventInfo())
    end

    -- Special events
    if event == "ENCHANT_APPLIED" or event == "ENCHANT_REMOVED" then
        spellName, itemID, itemName = select(prefixOffset, CombatLogGetCurrentEventInfo())
    elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "UNIT_DISSIPATES" then
        recapID, unconsciousOnDeath = select(prefixOffset, CombatLogGetCurrentEventInfo())
    end

    local mode = self:getMode()

    -- COMBAT_LOG_EVENT_UNFILTERED is used exclusively by spell-based modes
    if self:isSpellInteresting(mode, spellId, spellName) then
        local healer = self:getHealer(sourceGUID)
        if healer and event == "SPELL_CAST_SUCCESS" or (mode.canFail and event == "SPELL_MISSED") then
            local failed = event == "SPELL_MISSED"
            local targetGUID = type(mode.targetGUID) == 'function' and self:getPlayerGuid(mode.targetGUID(mode, sourceGUID, destGUID)) or nil
            local buffName = type(mode.buffName) == 'function' and mode.buffName(mode, spellId, spellName) or nil
            self:sendSyncTranq(healer, failed, timestamp)
            self:rotate(healer, failed, nil, nil, nil, targetGUID, buffName)
            self:addHistorySpellMessage(healer, sourceName, destName, spellName, failed, mode)
            if (sourceGUID == UnitGUID("player")) then
                self:sendSpellAnnounceMessage(mode, spellName, failed, healer, destName)
            end
        end
    end

    -- Custom combat log functions are possible, though extremely rare
    if type(mode.customCombatlogFunc) == 'function' then
        mode.customCombatlogFunc(mode, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, spellId, spellName)
    end
end

-- Raid group has changed
function LoathebRotate:GROUP_ROSTER_UPDATE()
    self:updateRaidStatus()
end

-- Player left combat
function LoathebRotate:PLAYER_REGEN_ENABLED()
    self:updateRaidStatus()
    self:callAllSecureFunctions()
end

-- Player changed its main target
function LoathebRotate:PLAYER_TARGET_CHANGED()
    if (LoathebRotate.db.profile.showWindowWhenTargetingBoss) then
        if (self:isTranqableBoss(UnitGUID("target")) and not UnitIsDead('target')) then
            self.mainFrame:Show()
        end
    end
end

-- One of the auras of the unitID has changed (gained, faded)
function LoathebRotate:UNIT_AURA(unitID, isEcho)
    if not self:isActive() then return end

    local mode = self:getMode()

    -- UNIT_AURA is used exclusively by aura-based modes
    if not mode or type(mode.auraTest) ~= 'function' then return end

    -- Whether the unit really got the debuff or not, it's pointless if the unit is not tracked (e.g. not a healer)
    local healer = self:getHealer(UnitGUID(unitID))
    if not hunter then return end
    local previousExpirationTime = healer.expirationTime

    if not isEcho then
        -- Try again in 1 second to secure lags between UNIT_AURA and the actual aura applied
        -- But set the isEcho flag so that the repetition will not be repeated over and over
        C_Timer.After(1, function()
            self:UNIT_AURA(unitID, true)
        end)
    end

    -- Loop through the unit's debuffs to check if s/he is affected by a specific debuff, e.g. Loatheb's Corrupted Mind
    local maxNbDebuffs = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and 16 or 40
    for i=1,maxNbDebuffs do
        local name, _,_,_,_, endTime ,_,_,_, spellId = UnitDebuff(unitID, i)
        if not name then
            -- name is not defined, meaning there is no other debuff left
            break
        end
        -- At this point:
        -- name and spellId correspond to the debuff at index i
        -- endTime knows exactly when the debuff ends if unitID is the player, i.e. if UnitIsUnit(unitID, "player")
        -- endTime is set to 0 is unitID is not the player ; this is a known limitation in WoW Classic that makes buff/debuff duration much harder to track
        if mode:auraTest(spellId, name) then
            if (endTime and endTime > 0 and previousExpirationTime == endTime) then
                -- If the endTime matches exactly the previous expirationTime of the status bar, it means we are duplicating an already registered rotation
                return
            end
            if (previousExpirationTime and GetTime() < previousExpirationTime) then
                -- If the current time is before the previously seen expirationTime for this player, it means the debuff was already registered
                return
            end
            -- Send the rotate order, this is the most important part of the addon
            self:rotate(healer, false, nil, endTime)
            self:addHistoryDebuffMessage(healer, healer.name, name, mode)
            if (UnitIsUnit(unitID, "player")) then
                -- Announce to the channel selected in the addon options, but announce only ourselves
                self:sendAuraAnnounceMessage(mode, name, healer)
            end
            return
        end
    end

    -- The unit is not affected by Corrupted Mind: reset its expiration time
    if previousExpirationTime and previousExpirationTime > 0 then
        healer.expirationTime = 0
    end
end

-- Register single unit events for a given healer
function LoathebRotate:registerUnitEvents(healer)

	if healer.frame then
		healer.frame:RegisterUnitEvent("PARTY_MEMBER_DISABLE", healer.name)
		healer.frame:RegisterUnitEvent("PARTY_MEMBER_ENABLE", healer.name)
		healer.frame:RegisterUnitEvent("UNIT_HEALTH", healer.name)
		healer.frame:RegisterUnitEvent("UNIT_CONNECTION", healer.name)
		healer.frame:RegisterUnitEvent("UNIT_FLAGS", healer.name)

		healer.frame:SetScript(
			"OnEvent",
			function(self, event, ...)
				LoathebRotate:updateHealerStatus(healer)
			end
		)
	end;

end

-- Unregister single unit events for a given healer
function LoathebRotate:unregisterUnitEvents(healer)
	if healer.frame then
		healer.frame:UnregisterEvent("PARTY_MEMBER_DISABLE")
		healer.frame:UnregisterEvent("PARTY_MEMBER_ENABLE")
		healer.frame:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		healer.frame:UnregisterEvent("UNIT_CONNECTION")
		healer.frame:UnregisterEvent("UNIT_FLAGS")
	end;
end