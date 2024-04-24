local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript(
	"OnEvent",
	function(self, event, ...)
		if (event == "PLAYER_LOGIN") then
			LoathebRotate:init();
			self:UnregisterEvent("PLAYER_LOGIN")

			C_Timer.After(5, function()
				LoathebRotate:updateRaidStatusTask();
			end);
		else
			LoathebRotate[event](LoathebRotate, ...)
		end
	end
)

--	Called when a player (healer) joined a group.
--	The player must broadcast version to other players:
function LoathebRotate:GROUP_JOINED()
	if LoathebRotate:isHealerClass('player') then
		LoathebRotate:requestVersionCheck(true);
	end;
end

-- Raid group has changed
function LoathebRotate:GROUP_ROSTER_UPDATE()
	if not UnitInRaid(UnitName('player')) then
		LoathebRotate.synchronizationDone = false;
		LoathebRotate.readyToReceiveSyncResponse = true;
		return;
	end;

	if not LoathebRotate.synchronizationDone then
		LoathebRotate.synchronizationDone = true;
		LoathebRotate:requestSync();
	end

	self:updateRaidStatus();
	LoathebRotate:refreshHealerFrames();
end

-- Player left combat
function LoathebRotate:PLAYER_REGEN_ENABLED()
	self:updateRaidStatus();
	self:callAllSecureFunctions();
end

-- Player changed its main target.
--	If Loatheb is targetted then open the main window:
function LoathebRotate:PLAYER_TARGET_CHANGED()
	if not LoathebRotate:isHealerClass(UnitName('player')) then return end

	if (LoathebRotate.db.profile.showWindowWhenTargetingBoss) then
		if (LoathebRotate:isLoathebBoss(UnitGUID('target')) and not UnitIsDead('target')) then
			LoathebRotate:requestOpenWindow();
			self.mainFrame:Show();
		end
	end
end

-- One of the auras of the unitID has changed (gained, faded)
function LoathebRotate:UNIT_AURA(unitID, isEcho)
	if not self:isActive() then return end

	-- Whether the unit really got the debuff or not, it's pointless if the unit is not tracked (e.g. not a healer)
	local healer = self:getHealer(LoathebRotate:getPlayerAndRealm(unitID));
	if not healer then 
		return ;
	end

	local previousExpirationTime = healer.expirationTime;

    if not isEcho then
        -- Try again in 1 second to secure lags between UNIT_AURA and the actual aura applied
        -- But set the isEcho flag so that the repetition will not be repeated over and over
        C_Timer.After(1, function()
            self:UNIT_AURA(unitID, true)
        end)
    end

	local simulatedSpellId = -1;
	if LoathebRotate.db.profile.enableDebug and LoathebRotate.db.profile.emulatedSpellId then
		simulatedSpellId = 1 * LoathebRotate.db.profile.emulatedSpellId;
	end

    -- Loop through the unit's debuffs to check if s/he is affected by a specific debuff, e.g. Loatheb's Corrupted Mind
	local maxNbDebuffs = 16;
	for i=1,maxNbDebuffs do
		local name, _,_,_,_, endTime ,_,_,_, spellId = UnitDebuff(unitID, i);
		if not name then
			-- name is not defined, meaning there is no other debuff left
			break
		end

        -- At this point:
        -- name and spellId correspond to the debuff at index i
        -- endTime knows exactly when the debuff ends if unitID is the player, i.e. if UnitIsUnit(unitID, "player")
        -- endTime is set to 0 is unitID is not the player ; this is a known limitation in WoW Classic that makes buff/debuff duration much harder to track
		-- priest / druid / paladin / shaman / simjlated buff:
		if	(spellId == 29184)
		 or (spellId == 29195)
		 or (spellId == 29197)
		 or (spellId == 29199)
		 or (spellId == simulatedSpellId) then
			if (endTime and endTime > 0 and previousExpirationTime == endTime) then
				-- If the endTime matches exactly the previous expirationTime of the status bar, it means we are duplicating an already registered rotation
				return
			end
			if (previousExpirationTime and GetTime() < previousExpirationTime) then
				-- If the current time is before the previously seen expirationTime for this player, it means the debuff was already registered
				return
			end

			-- Send the rotate order, this is the most important part of the addon
			self:rotate(healer, false, nil, endTime);
			self:addHistoryDebuffMessage(healer.name, name);

			if (UnitIsUnit(unitID, "player")) then
				--	Only shown locally:
				LoathebRotate:printPrefixedMessage(string.format(L["ANNOUNCEMENT_CORRUPTED_MIND"], healer.name));
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
