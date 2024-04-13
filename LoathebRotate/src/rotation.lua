local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")


function LoathebRotate:isHealerClass(name)
	if LoathebRotate.constants.healerClasses[UnitClass(name)] then
		return true;
	end;

	return false;
end


function LoathebRotate:registerHealer(name)
	if not LoathebRotate:isHealerClass(name) then
		return nil;
	end;

	local healer = LoathebRotate:getHealer(name);
	if not healer then
		healer = {};
		healer.name = name;
		healer.class = UnitClass(name);
		healer.GUID = UnitGUID(name);
		healer.nextHeal = false;
		healer.lastHealTime = 0;
		healer.frame = nil;

		-- New healers are automatically moved to backup table:
		table.insert(LoathebRotate.backupTable, healer)
	end;

	LoathebRotate:drawHealerFrames();

    return healer
end;

function LoathebRotate:removeHealer(deletedHealer)

	for key, healer in pairs(LoathebRotate.rotationTable) do
		if (healer.name == deletedHealer.name) then
			LoathebRotate:hideHealer(healer);
			table.remove(LoathebRotate.rotationTable, key);
			break;
		end
	end

	for key, healer in pairs(LoathebRotate.backupTable) do
		if (healer.name == deletedHealer.name) then
			LoathebRotate:hideHealer(healer);
			table.remove(LoathebRotate.backupTable, key)
			break
		end
	end

	LoathebRotate:drawHealerFrames();
end

-- Update the rotation list once a heal has been cast.
-- @param lastHealer            player that used its tranq (successfully or not)
-- @param rotateWithoutCooldown flag for unavailable players who are e.g. dead or disconnected
-- @param endTimeOfCooldown     time when the cooldown ends (by default the time is calculated as now+cooldown)
function LoathebRotate:rotate(lastHealer, rotateWithoutCooldown, endTimeOfCooldown)
	local playerName, realm = UnitName("player");

	lastHealer.lastHealTime = GetTime();

	-- Do not trigger cooldown when rotation from a dead or disconnected status
	if (rotateWithoutCooldown ~= true) then
		LoathebRotate:startHealerCooldown(lastHealer, endTimeOfCooldown);
	end

	local nextHealer = LoathebRotate:getNextRotationHealer(lastHealer);
	if (nextHealer ~= nil) then
		LoathebRotate:setNextHeal(nextHealer);

		if (LoathebRotate:isHealerCooldownReady(nextHealer)) then
			if (#LoathebRotate.backupTable < 1) then
				if (nextHealer.name == playerName) then
					LoathebRotate:alertReactNow();
				end
			end
		end

		if nextHealer.name ~= UnitName('player') then
			local playerFullName = LoathebRotate:getFullPlayerName(nextHealer.name);
			if playerFullName then
				LoathebRotate:sendAnnounceMessage(L["ANNOUNCEMENT_YOU_ARE_NEXT"], playerFullName);
			end
		end
	end
end

-- Removes all nextHeal flags and set it true for next healer
function LoathebRotate:setNextHeal(nextHealer)
	for key, healer in pairs(LoathebRotate.rotationTable) do
		if (healer.name == nextHealer.name) then
			healer.nextHeal = true

			if (nextHealer.name == UnitName("player")) and LoathebRotate.db.profile.enableNextToHealSound then
				PlaySoundFile(LoathebRotate.constants.sounds.nextToHeal)
			end
		else
			healer.nextHeal = false
		end

		LoathebRotate:refreshHealerFrame(healer);
    end
end

-- Check if the player is the next in position to heal
function LoathebRotate:isPlayerNextHeal()
	local player = LoathebRotate:getHealer(UnitGUID("player"))

	if (not player.nextHeal) then
		local isRotationInitialized = false;

		-- checking if a healer is flagged nextHeal
		for key, healer in pairs(LoathebRotate.rotationTable) do
			if (healer.nextHeal) then
				isRotationInitialized = true;
				break
			end
		end

		-- First in rotation has to tranq if not one is flagged
		if (not isRotationInitialized and LoathebRotate:getHealerIndex(player, LoathebRotate.rotationTable) == 1) then
			return true;
		end
	end

	return player.nextHeal;
end

-- Find and returns the next hunter that will tranq base on last shooter
function LoathebRotate:getNextRotationHealer(lastHealer)
	local nextHealer;
	local lastHealerIndex = 1;

	-- Finding last healer index in rotation
	for key, healer in pairs(LoathebRotate.rotationTable) do
		if (healer.name == lastHealer.name) then
			lastHealerIndex = key
			break
		end
	end

	-- Search from last healer index if not last on rotation
	if (lastHealerIndex < #LoathebRotate.rotationTable) then
		for index = lastHealerIndex + 1 , #LoathebRotate.rotationTable, 1 do
			local healer = LoathebRotate.rotationTable[index];
			if (LoathebRotate:isEligibleForNextHeal(healer)) then
				nextHealer = healer
				break
			end
		end
	end

	-- Restart search from first index
	if (nextHealer == nil) then
		for index = 1 , lastHealerIndex, 1 do
			local healer = LoathebRotate.rotationTable[index];
			if (LoathebRotate:isEligibleForNextHeal(healer)) then
				nextHealer = healer;
				break
			end
		end
	end

	-- If no healer in the rotation match the alive/online/CD criteria
	-- Pick the healer with the lowest cooldown
	if (nextHealer == nil and #LoathebRotate.rotationTable > 0) then
		local latestHeal = GetTime() + 1;
		for key, healer in pairs(LoathebRotate.rotationTable) do
			if (LoathebRotate:isHealerAliveAndOnline(healer) and healer.lastHealTime < latestHeal) then
				nextHealer = healer;
				latestHealer = healer.lastHealTime;
			end
		end
	end

	return nextHealer;
end

-- Init/Reset rotation status, next heal is the first healer on the list
function LoathebRotate:resetRotation()
	for key, healer in pairs(LoathebRotate.rotationTable) do
		healer.nextHeal = false;
		LoathebRotate:refreshHealerFrame(healer);
	end
end

-- @todo: remove this | TEST FUNCTION - Manually rotate hunters for test purpose
function LoathebRotate:testRotation()
	for key, healer in pairs(LoathebRotate.rotationTable) do
		if (healer.nextHeal) then
			LoathebRotate:rotate(healer, false);
			break
		end
	end
end

function LoathebRotate:getHealer(searchTerm)
	if searchTerm ~= nil then
		for _, healer in pairs(LoathebRotate.rotationTable) do
			if (healer.GUID == searchTerm or healer.name == searchTerm) then
				healer.group = 'ROTATION';
				return healer;
			end
		end

		for _, healer in pairs(LoathebRotate.backupTable) do
			if (healer.GUID == searchTerm or healer.name == searchTerm) then
				healer.group = 'BACKUP';
				return healer;
			end
		end
	end

	return nil;
end

-- Iterate over healer list and purge healers that aren't in the group anymore
function LoathebRotate:purgeHealerList()
	local change = false
	local healersToRemove = {}

	for key,healer in pairs(LoathebRotate.rotationTable) do
		if (not UnitInParty(healer.name) and not UnitIsUnit(healer.name, "player")) then
			table.insert(healersToRemove, healer)
		end
	end
	
	for key,healer in pairs(LoathebRotate.backupTable) do
		if (not UnitInParty(healer.name) and not UnitIsUnit(healer.name, "player")) then
			table.insert(healersToRemove, healer);
		end
	end
	
	if (#healersToRemove > 0) then
		for key,healer in ipairs(healersToRemove) do
			LoathebRotate:unregisterUnitEvents(healer);
			LoathebRotate:removeHealer(healer);
		end

		LoathebRotate:drawHealerFrames();
	end
end

--	Force an update every second. This endures disconnects etc. are shown correct.
function LoathebRotate:updateRaidStatusTask()
	if not LoathebRotate.ignoreRaidStatusUpdates then
		LoathebRotate:updateRaidStatus(true);
	end

	local timerInterval = 10;
	if LoathebRotate:isActive() then
		timerInterval = 1;
	end

	C_Timer.After(timerInterval, function()
		LoathebRotate:updateRaidStatusTask();
	end);
end;

-- Iterate over all raid members to find healers and update their status
function LoathebRotate:updateRaidStatus(forcedUpdate)

	if LoathebRotate:isActive() or forcedUpdate then
		local playerCount = GetNumGroupMembers();

		if (playerCount > 0) then
			for index = 1, playerCount, 1 do
				local name = GetRaidRosterInfo(index);
				if (name) then
					LoathebRotate:registerHealer(name);
				end
			end
		else
			local name = UnitName("player");
			LoathebRotate:registerHealer(name);
			for i = 1, 4 do
				local name = UnitName("party"..i)
				if (name) then
					LoathebRotate:registerHealer(name);
				end
			end
		end

		if (not LoathebRotate.raidInitialized) then
			if (not LoathebRotate.db.profile.doNotShowWindowOnRaidJoin) then
				LoathebRotate:updateDisplay();
			end
			LoathebRotate.raidInitialized = true;
		end
	else
		if(LoathebRotate.raidInitialized == true) then
			LoathebRotate:updateDisplay();
			LoathebRotate.raidInitialized = false
		end
	end

	LoathebRotate:purgeHealerList();
end

-- Update healer status
function LoathebRotate:updateHealerStatus(healer)
	-- Jump to the next healer if the current one is dead or offline
	if (healer.nextHeal and (not LoathebRotate:isHealerAliveAndOnline(healer))) then
		LoathebRotate:rotate(healer, false, true);
	end

	LoathebRotate:refreshHealerFrame(healer);
end

-- Moves given healer to the given position in the given group (ROTATION or BACKUP)
function LoathebRotate:moveHealer(healer, group, position)
	local originTable = LoathebRotate.rotationTable;
	local destinationTable = LoathebRotate.rotationTable;

	local curHealer = LoathebRotate:getHealer(healer.GUID);
	if curHealer.group == 'BACKUP' then
		originTable = LoathebRotate.backupTable;
	end;

	if group == 'BACKUP' then
		destinationTable = LoathebRotate.backupTable;
		healer.nextHeal = false;
	end;

	local originIndex = LoathebRotate:getHealerIndex(healer, originTable);
	local finalIndex = position;
	local sameTableMove = originTable == destinationTable;

	-- Defining finalIndex
	if (sameTableMove) then
		if (position > #destinationTable or position == 0) then
			if (#destinationTable > 0) then
				finalIndex = #destinationTable
			else
				finalIndex = 1
			end
		end

	else
		if (position > #destinationTable + 1 or position == 0) then
			if (#destinationTable > 0) then
				finalIndex = #destinationTable  + 1
			else
				finalIndex = 1
			end
		end
	end

	if (sameTableMove) then
		if (originIndex ~= finalIndex) then
			table.remove(originTable, originIndex)
			table.insert(originTable, finalIndex, healer)
		end
	else
		table.remove(originTable, originIndex)
		table.insert(destinationTable, finalIndex, healer)
	end

	LoathebRotate:drawHealerFrames()
end

-- Find the table that contains given healer (rotation or backup)
function LoathebRotate:getHealerRotationTable(healer)
	if (LoathebRotate:tableContains(LoathebRotate.rotationTable, healer)) then
		return LoathebRotate.rotationTable;
	end
	if (LoathebRotate:tableContains(LoathebRotate.backupTable, healer)) then
		return LoathebRotate.backupTable;
	end
end

-- Returns a healer's index in the given table
function LoathebRotate:getHealerIndex(healer, table)
	local originIndex = 0

	for key, loopHealer in pairs(table) do
		if (healer.name == loopHealer.name) then
			originIndex = key;
			break
		end
	end

	return originIndex;
end


-- Display an alert and play a sound when the player should immediatly tranq
function LoathebRotate:alertReactNow(modeName)
	RaidNotice_AddMessage(RaidWarningFrame, LoathebRotate.db.profile["announceReactMessage"], ChatTypeInfo["RAID_WARNING"])

	if LoathebRotate.db.profile.enableHealNowSound then
		PlaySoundFile(LoathebRotate.constants.sounds.alarms[LoathebRotate.db.profile.healNowSound])
	end
end


