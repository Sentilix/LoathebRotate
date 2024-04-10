local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")


function LoathebRotate:registerHealer(name)
	local class = UnitClass(name);

	if not LoathebRotate.constants.healerClasses[class] then
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
			--LoathebRotate:hideHealer(healer)
			table.remove(LoathebRotate.rotationTable, key)
			break;
		end
	end

	for key, healer in pairs(LoathebRotate.backupTable) do
		if (healer.name == deletedHealer.name) then
			table.remove(LoathebRotate.backupTable, key)
			break
		end
	end

	LoathebRotate:drawHealerFrames();
end



---- Adds hunter to global table and one of the two rotation tables
--function LoathebRotate:registerHunter(hunterName)

--    -- Initialize hunter 'object'
--    local hunter = {}
--    hunter.name = hunterName
--    hunter.GUID = UnitGUID(hunterName)
--    hunter.frame = nil
--    hunter.nextTranq = false
--    hunter.lastTranqTime = 0
--    hunter.addonVersion = nil

--    -- Add to global list
--    table.insert(LoathebRotate.hunterTable, hunter)

--    -- Add to rotation or backup group depending on rotation group size
--    if (#LoathebRotate.rotationTables.rotation > 2) then
--        table.insert(LoathebRotate.rotationTables.backup, hunter)
--    else
--        table.insert(LoathebRotate.rotationTables.rotation, hunter)
--    end

--    -- @TODO apply only to the relevant mainFrame
--    LoathebRotate:drawHunterFramesOfAllMainFrames()

--    return hunter
--end

---- Removes a hunter from all lists
--function LoathebRotate:removeHunter(deletedHunter)

--    -- Clear from global list
--    for key, hunter in pairs(LoathebRotate.hunterTable) do
--        if (hunter.name == deletedHunter.name) then
--            LoathebRotate:hideHunter(hunter)
--            table.remove(LoathebRotate.hunterTable, key)
--            break
--        end
--    end

--    -- clear from rotation lists
--    for key, hunterTable in pairs(LoathebRotate.rotationTables) do
--        for subkey, hunter in pairs(hunterTable) do
--            if (hunter.name == deletedHunter.name) then
--                table.remove(hunterTable, subkey)
--            end
--        end
--    end

--    -- @TODO apply only to the relevant mainFrame
--    LoathebRotate:drawHunterFramesOfAllMainFrames()
--end


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
	end
end

-- Removes all nextHeal flags and set it true for next healer
function LoathebRotate:setNextTranq(nextHealer)
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


---- Update the rotation list once a tranq has been done.
---- @param lastHunter            player that used its tranq (successfully or not)
---- @param fail                  flag that tells if the spell failed (false by default, i.e. success by default)
---- @param rotateWithoutCooldown flag for unavailable players who are e.g. dead or disconnected
---- @param endTimeOfCooldown     time when the cooldown ends (by default the time is calculated as now+cooldown)
---- @param endTimeOfEffect       time when the effect on the targetGUID fades (by default, time is now+duration)
---- @param targetGUID            GUID of the only target or main target of the rotation, if such target exists
---- @param buffName              name of the buff given to targetGUID
--function LoathebRotate:rotate(lastHunter, fail, rotateWithoutCooldown, endTimeOfCooldown, endTimeOfEffect, targetGUID, buffName)

--    -- Default value to false
--    fail = fail or false

--    local playerName, realm = UnitName("player")
--    local hunterRotationTable = LoathebRotate:getHunterRotationTable(lastHunter)
--    local hasPlayerFailed = playerName == lastHunter.name and fail

--    lastHunter.lastTranqTime = GetTime()

--    -- Do not trigger cooldown when rotation from a dead or disconnected status
--    if (rotateWithoutCooldown ~= true) then
--        LoathebRotate:startHunterCooldown(lastHunter, endTimeOfCooldown, endTimeOfEffect, targetGUID, buffName)
--    end

--    if (hunterRotationTable == LoathebRotate.rotationTables.rotation) then
--        local nextHunter = LoathebRotate:getNextRotationHunter(lastHunter)

--        if (nextHunter ~= nil) then

--            LoathebRotate:setNextTranq(nextHunter)

--            if (LoathebRotate:isHunterTranqCooldownReady(nextHunter)) then
--                if (#LoathebRotate.rotationTables.backup < 1) then
--                    if (fail and nextHunter.name == playerName) then
--                        LoathebRotate:alertReactNow(lastHunter.modeName)
--                    end
--                end
--            end
--        end
--    end

--    if (fail) then
--        if (LoathebRotate:getHunterRotationTable(LoathebRotate:getHunter(playerName)) == LoathebRotate.rotationTables.backup) then
--            LoathebRotate:alertReactNow(lastHunter.modeName)
--        end
--    end
--end

---- Removes all nextTranq flags and set it true for next shooter
--function LoathebRotate:setNextTranq(nextHunter)
--    for key, hunter in pairs(LoathebRotate.rotationTables.rotation) do
--        if (hunter.name == nextHunter.name) then
--            hunter.nextTranq = true

--            if (nextHunter.name == UnitName("player")) and LoathebRotate.db.profile.enableNextToTranqSound then
--                PlaySoundFile(LoathebRotate.constants.sounds.nextToTranq)
--            end
--        else
--            hunter.nextTranq = false
--        end

--        LoathebRotate:refreshHunterFrame(hunter)
--    end
--end

---- Check if the player is the next in position to tranq
--function LoathebRotate:isPlayerNextTranq()

--    local player = LoathebRotate:getHunter(UnitGUID("player"))

--    -- Non hunter user
--    if (player == nil) then
--        return false
--    end

--    if (not player.nextTranq) then

--        local isRotationInitialized = false;
--        local rotationTable = LoathebRotate.rotationTables.rotation

--        -- checking if a hunter is flagged nextTranq
--        for key, hunter in pairs(rotationTable) do
--            if (hunter.nextTranq) then
--                isRotationInitialized = true;
--                break
--            end
--        end

--        -- First in rotation has to tranq if not one is flagged
--        if (not isRotationInitialized and LoathebRotate:getHunterIndex(player, rotationTable) == 1) then
--            return true
--        end

--    end

--    return player.nextTranq
--end

---- Find and returns the next hunter that will tranq base on last shooter
--function LoathebRotate:getNextRotationHunter(lastHunter)

--    local rotationTable = LoathebRotate.rotationTables.rotation
--    local nextHunter
--    local lastHunterIndex = 1

--    -- Finding last hunter index in rotation
--    for key, hunter in pairs(rotationTable) do
--        if (hunter.name == lastHunter.name) then
--            lastHunterIndex = key
--            break
--        end
--    end

--    -- Search from last hunter index if not last on rotation
--    if (lastHunterIndex < #rotationTable) then
--        for index = lastHunterIndex + 1 , #rotationTable, 1 do
--            local hunter = rotationTable[index]
--            if (LoathebRotate:isEligibleForNextTranq(hunter)) then
--                nextHunter = hunter
--                break
--            end
--        end
--    end

--    -- Restart search from first index
--    if (nextHunter == nil) then
--        for index = 1 , lastHunterIndex, 1 do
--            local hunter = rotationTable[index]
--            if (LoathebRotate:isEligibleForNextTranq(hunter)) then
--                nextHunter = hunter
--                break
--            end
--        end
--    end

--    -- If no hunter in the rotation match the alive/online/CD criteria
--    -- Pick the hunter with the lowest cooldown
--    if (nextHunter == nil and #rotationTable > 0) then
--        local latestTranq = GetTime() + 1
--        for key, hunter in pairs(rotationTable) do
--            if (LoathebRotate:isHunterAliveAndOnline(hunter) and hunter.lastTranqTime < latestTranq) then
--                nextHunter = hunter
--                latestTranq = hunter.lastTranqTime
--            end
--        end
--    end

--    return nextHunter
--end

---- Init/Reset rotation status, next tranq is the first hunter on the list
--function LoathebRotate:resetRotation()
--    for key, hunter in pairs(LoathebRotate.rotationTables.rotation) do
--        hunter.nextTranq = false
--        LoathebRotate:refreshHunterFrame(hunter)
--    end
--end

---- @todo: remove this | TEST FUNCTION - Manually rotate hunters for test purpose
--function LoathebRotate:testRotation()

--    for key, hunter in pairs(LoathebRotate.rotationTables.rotation) do
--        if (hunter.nextTranq) then
--            LoathebRotate:rotate(hunter, false)
--            break
--        end
--    end
--end

---- Check if a hunter is already registered
--function LoathebRotate:isHunterRegistered(GUID)

--    -- @todo refactor this using LoathebRotate:getHunter(GUID)
--    for key,hunter in pairs(LoathebRotate.hunterTable) do
--        if (hunter.GUID == GUID) then
--            return true
--        end
--    end

--    return false
--end

--function LoathebRotate:getHealer(searchTerm)
--	if searchTerm ~= nil then
--		for _, healer in pairs(LoathebRotate.healerTable) do
--			if (healer.GUID == searchTerm or healer.name == searchTerm) then
--				return healer
--			end
--		end
--	end

--    return nil
--end;


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


---- Return our hunter object from name or GUID
--function LoathebRotate:getHunter(searchTerm)

--    -- @todo optimize with a reverse table
--    for _, hunter in pairs(LoathebRotate.hunterTable) do
--        if (searchTerm ~= nil and (hunter.GUID == searchTerm or hunter.name == searchTerm)) then
--            return hunter
--        end
--    end

--    return nil
--end

---- Iterate over hunter list and purge hunter that aren't in the group anymore
--function LoathebRotate:purgeHunterList()

--    local change = false
--    local huntersToRemove = {}

--    local mode = LoathebRotate:getMode() -- @todo parse all modes

--    for key,hunter in pairs(LoathebRotate.hunterTable) do

--        if  (
--                -- Is unit in the party? "player" is always accepted
--                ( not UnitInParty(hunter.name) and not UnitIsUnit(hunter.name, "player") )
--            or
--                not LoathebRotate:isPlayerWanted(mode, hunter.name, nil)
--            ) then
--            table.insert(huntersToRemove, hunter)
--        end
--    end

--    if (#huntersToRemove > 0) then
--        for key,hunter in ipairs(huntersToRemove) do
--            LoathebRotate:unregisterUnitEvents(hunter)
--            LoathebRotate:removeHunter(hunter)
--        end
--        -- @TODO apply only to the relevant mainFrame
--        LoathebRotate:drawHunterFramesOfAllMainFrames()
--    end
--end


--function LoathebRotate:addHealer(name)
--	local class = UnitClass(name);

--	if LoathebRotate.constants.healerClasses[class] then
--		local healer = LoathebRotate:getHealer(name);
		
--		-- Add healer to list if s/he doesnt exist already:
--		if not healer then
--			LoathebRotate:registerHealer(name);
--		end;
--	end;
--end;


-- Update the status of one healer
function LoathebRotate:updateUnitStatus(name)
	local GUID = UnitGUID(name);
    local healer = LoathebRotate:getHealer(GUID);

	if not healer then
		healer = LoathebRotate:registerHealer(name)
	end;
end


-- Iterate over all raid members to find healers and update their status
function LoathebRotate:updateRaidStatus()

	if LoathebRotate:isActive() then
		local playerCount = GetNumGroupMembers();

		if (playerCount > 0) then
			for index = 1, playerCount, 1 do
				--local name, rank, subgroup, level, class, classFilename, zone, online, isDead, role, isML = GetRaidRosterInfo(index)
				local name = GetRaidRosterInfo(index);
				if (name) then
					--LoathebRotate:addHealer(name);
					LoathebRotate:registerHealer(name);
				end
			end
		else
			local name = UnitName("player");
			--local classFilename = select(2,UnitClass("player"))
			--LoathebRotate:addHealer(name);
			LoathebRotate:registerHealer(name);
			for i = 1, 4 do
				local name = UnitName("party"..i)
				if (name) then
					--classFilename = select(2,UnitClass("party"..i))
					--LoathebRotate:updateUnitStatus(name, classFilename, 1)
					--LoathebRotate:addHealer(name);
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



---- Update hunter status
--function LoathebRotate:updateHunterStatus(hunter)

--    -- Jump to the next hunter if the current one is dead or offline
--    if (hunter.nextTranq and (not LoathebRotate:isHunterAliveAndOnline(hunter))) then
--        LoathebRotate:rotate(hunter, false, true)
--    end

--    LoathebRotate:refreshHunterFrame(hunter)
--end

---- Moves given hunter to the given position in the given group (ROTATION or BACKUP)
--function LoathebRotate:moveHunter(hunter, group, position)

--    local originTable = LoathebRotate:getHunterRotationTable(hunter)
--    local originIndex = LoathebRotate:getHunterIndex(hunter, originTable)

--    local destinationTable = LoathebRotate.rotationTables.rotation
--    local finalIndex = position

--    if (group == 'BACKUP') then
--        destinationTable = LoathebRotate.rotationTables.backup
--        -- Remove nextTranq flag when moved to backup
--        hunter.nextTranq = false
--    end

--    -- Setting originalIndex
--    local sameTableMove = originTable == destinationTable

--    -- Defining finalIndex
--    if (sameTableMove) then
--        if (position > #destinationTable or position == 0) then
--            if (#destinationTable > 0) then
--                finalIndex = #destinationTable
--            else
--                finalIndex = 1
--            end
--        end
--    else
--        if (position > #destinationTable + 1 or position == 0) then
--            if (#destinationTable > 0) then
--                finalIndex = #destinationTable  + 1
--            else
--                finalIndex = 1
--            end
--        end
--    end

--    if (sameTableMove) then
--        if (originIndex ~= finalIndex) then
--            table.remove(originTable, originIndex)
--            table.insert(originTable, finalIndex, hunter)
--        end
--    else
--        table.remove(originTable, originIndex)
--        table.insert(destinationTable, finalIndex, hunter)
--    end

--    -- @TODO apply only to the relevant mainFrame
--    LoathebRotate:drawHunterFramesOfAllMainFrames()
--end

---- Find the table that contains given hunter (rotation or backup)
--function LoathebRotate:getHunterRotationTable(hunter)
--    if (LoathebRotate:tableContains(LoathebRotate.rotationTables.rotation, hunter)) then
--        return LoathebRotate.rotationTables.rotation
--    end
--    if (LoathebRotate:tableContains(LoathebRotate.rotationTables.backup, hunter)) then
--        return LoathebRotate.rotationTables.backup
--    end
--end

---- Returns a hunter's index in the given table
--function LoathebRotate:getHunterIndex(hunter, table)
--    local originIndex = 0

--    for key, loopHunter in pairs(table) do
--        if (hunter.name == loopHunter.name) then
--            originIndex = key
--            break
--        end
--    end

--    return originIndex
--end

---- Builds simple rotation tables containing only hunters names
--function LoathebRotate:getSimpleRotationTables()

--    local simpleTables = { rotation = {}, backup = {} }

--    for key, rotationTable in pairs(LoathebRotate.rotationTables) do
--        for _, hunter in pairs(rotationTable) do
--            table.insert(simpleTables[key], hunter.GUID)
--        end
--    end

--    return simpleTables
--end

---- Apply a simple rotation configuration
--function LoathebRotate:applyRotationConfiguration(rotationsTables)

--    for key, rotationTable in pairs(rotationsTables) do

--        local group = 'ROTATION'
--        if (key == 'backup') then
--            group = 'BACKUP'
--        end

--        for index, GUID in pairs(rotationTable) do
--            local hunter = LoathebRotate:getHunter(GUID)
--            if (hunter) then
--                LoathebRotate:moveHunter(hunter, group, index)
--            end
--        end
--    end
--end

---- Display an alert and play a sound when the player should immediatly tranq
--function LoathebRotate:alertReactNow(modeName)
--    local mode = LoathebRotate:getMode(modeName)

--    if mode and mode.canFail and mode.alertWhenFail then
--        RaidNotice_AddMessage(RaidWarningFrame, LoathebRotate.db.profile["announce"..mode.modeNameFirstUpper.."ReactMessage"], ChatTypeInfo["RAID_WARNING"])

--        if LoathebRotate.db.profile.enableTranqNowSound then
--            PlaySoundFile(LoathebRotate.constants.sounds.alarms[LoathebRotate.db.profile.tranqNowSound])
--        end
--    end
--end

