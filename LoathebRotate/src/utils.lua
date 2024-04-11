local LoathebRotate = select(2, ...)

-- Check if a table contains the given element
function LoathebRotate:tableContains(table, element)

    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end

    return false
end

-- Checks if a healer is alive
function LoathebRotate:isHealerAlive(healer)
	if healer then
	    return not UnitIsDeadOrGhost(healer.name)
	end;

	return false;
end

-- Checks if a healer is offline
function LoathebRotate:isHealerOnline(healer)
	if healer then
		return UnitIsConnected(healer.name)
	end;

	return false;
end

-- Checks if a healer is online and alive
function LoathebRotate:isHealerAliveAndOnline(healer)
    return LoathebRotate:isHealerOnline(healer) and LoathebRotate:isHealerAlive(healer)
end

-- Checks if a healer heal is ready
function LoathebRotate:isHealerCooldownReady(healer)
    return healer.lastHealTime <= GetTime() - 20
end

-- Checks if a healer is eligible to heal next
function LoathebRotate:isEligibleForNextHeal(healer)

    local isCooldownShortEnough = healer.lastHealTime <= GetTime() - LoathebRotate.constants.minimumCooldownElapsedForEligibility

    return LoathebRotate:isHealerAliveAndOnline(healer) and isCooldownShortEnough;
end

-- Get the target name and the buff mode of a hunter
-- Returns nil, nil if hunter.targerGUID is nil or does not point to a player.
--
-- Buff mode is one of the following:
-- 'has_buff' - the hunter has buffed the target and the buff is still active
-- 'buff_lost' - the buff was lost before its full duration
-- 'buff_expired' - the buff is beyond its full duration
-- 'not_a_buff' - the target is not meant to be buffed by the hunter
--
-- It should be noted that 'buff_expired' is always returned if too much time has passed,
-- even if the buff was lost before the end
function LoathebRotate:getHunterTarget(hunter)
    local targetName = LoathebRotate:getPlayerGuid(hunter.targetGUID) and select(6, GetPlayerInfoByGUID(hunter.targetGUID))
    local buffMode

    if not targetName or targetName == '' then
        -- The target is not available anymore, maybe the player left the raid or it was a non-raid player who moved too far
        buffMode = nil
    elseif not UnitIsPlayer(targetName) or not hunter.buffName or hunter.buffName == "" or not hunter.endTimeOfEffect or hunter.endTimeOfEffect == 0 then
        buffMode = 'not_a_buff'
    elseif GetTime() > hunter.endTimeOfEffect  then
        buffMode = 'buff_expired'
    elseif not LoathebRotate:findAura(targetName, hunter.buffName) then
        buffMode = 'buff_lost'
    else
        buffMode = 'has_buff'
    end

    return targetName, buffMode
end


---- Get the current assignment of the hunter and when it was assigned
---- Returns nil if no assignment is done
---- May return the name of a player not in the raid group if the assignment left the raid
--function LoathebRotate:getHunterAssignment(hunter)
--    local mode = LoathebRotate:getMode() -- @todo get mode from hunter

--    local assignment, timestamp
--    if mode.assignment then
--        assignment = mode.assignment[hunter.name]
--    end
--    if mode.assignedAt then
--        timestamp = mode.assignedAt[hunter.name]
--    end

--    return assignment, timestamp
--end

-- Checks if a player is in a battleground
function LoathebRotate:isPlayerInBattleground()
    return UnitInBattleground('player') ~= nil
end

-- Checks if the addon bearer is in a PvE raid or dungeon
function LoathebRotate:isActive()
    if LoathebRotate.testMode then
        return true
    elseif LoathebRotate:isPlayerInBattleground() then
        return false
    elseif IsInRaid() then
        return true
    elseif IsInInstance() then
        local mode = LoathebRotate:getMode() -- @todo get all current active modes instead
        return mode and type(mode.raidOnly) == 'boolean' and not mode.raidOnly
    else
        return false
    end
end

function LoathebRotate:getPlayerNameFont()
    if (GetLocale() == "zhCN" or GetLocale() == "zhTW") then
        return "Fonts\\ARHei.ttf"
    end

    return "Fonts\\ARIALN.ttf"
end

function LoathebRotate:getIdFromGuid(guid)
    local unitType, _, _, _, _, mobId, _ = strsplit("-", guid or "")
    return unitType, tonumber(mobId)
end

-- Check if the GUID is a player and return the GUID, otherwise return nil
function LoathebRotate:getPlayerGuid(guid)
    local unitType, _ = strsplit("-", guid or "")
    return unitType == 'Player' and guid or nil
end

-- Find a buff or debuff on the specified unit
-- Return the index of the first occurence, if found, otherwise return nil
function LoathebRotate:findAura(unitID, spellName)
    local maxNbAuras = 99
    for i=1,maxNbAuras do
        local name = UnitAura(unitID, i)

        if not name then
            -- name is not defined, meaning there are no other buffs/debuffs left
            return nil
        end
        
        if name == spellName then
            return i
        end
    end

    return nil
end

---- Checks if the spell and the mob match a boss frenzy
--function LoathebRotate:isBossFrenzy(spellName, guid)

--    local bosses = LoathebRotate.constants.tranqableBosses
--    local type, mobId = LoathebRotate:getIdFromGuid(guid)

--    if (type == "Creature") then
--        for bossId, frenzy in pairs(bosses) do
--            if (bossId == mobId and spellName == GetSpellInfo(frenzy)) then
--                return true
--            end
--        end
--    end

--    return false
--end

-- Checks if this is Loatheb!
function LoathebRotate:isLoathebBoss(guid)
    local type, mobId = LoathebRotate:getIdFromGuid(guid);

	if (type == "Creature") and (mobId == 16011) then
	--if (mobId == 5112) then		-- Gwenna Firebrew in Ironforge Inn - dangerous boss :-)
        return true
    end

    return false
end

---- Checks if a mob GUID is a boss from a specific list of IDs
--function LoathebRotate:isBossInList(guid, bosses)
--    local type, mobId = LoathebRotate:getIdFromGuid(guid)

--    if type == "Creature" then
--        for _, bossId in ipairs(bosses) do
--            if bossId == mobId then
--                return true
--            end
--        end
--    end

--    return false
--end

---- Checks if the spell is a boss frenzy
--function LoathebRotate:isFrenzy(spellName)

--    local bosses = LoathebRotate.constants.tranqableBosses

--    for bossId, frenzy in pairs(bosses) do
--        if (spellName == GetSpellInfo(frenzy)) then
--            return true
--        end
--    end

--    return false
--end

-- Get a user-defined color or create it now
function LoathebRotate:getUserDefinedColor(colorName)

    local color = LoathebRotate.colors[colorName]

    if (not color) then
        -- Create the color based on profile
        -- This should happen once, at start
        local profileColorName
        if (colorName == "groupSuffix") then
            profileColorName = "groupSuffixColor"
        elseif (colorName == "indexPrefix") then
            profileColorName = "indexPrefixColor"
        else
            profileColorName = (colorName or "").."BackgroundColor"
        end

        if (LoathebRotate.db.profile[profileColorName]) then
            color = CreateColor(
                LoathebRotate.db.profile[profileColorName][1],
                LoathebRotate.db.profile[profileColorName][2],
                LoathebRotate.db.profile[profileColorName][3]
            )
        else
            print("[LoathebRotate] Unknown color constant "..(colorName or "''"))
        end

        LoathebRotate.colors[colorName] = color
    end

    return color
end

function LoathebRotate:printAll(object, name, level)
	if not name then name = ""; end;
	if not level then level = 0; end;

	local indent = "";
	for n= 1, level, 1 do
		indent = indent .."  ";
	end;

	if type(object) == "string" then
		print(string.format("%s%s => %s", indent, name, object));
	elseif type(object) == "number" then
		print(string.format("%s%s => %s", indent, name, object));
	elseif type(object) == "boolean" then
		if object then
			print(string.format("%s%s => %s", indent, name, "true"));
		else
			print(string.format("%s%s => %s", indent, name, "false"));
		end;
	elseif type(object) == "function" then
		print(string.format("%s%s => %s", indent, name, "FUNCTION"));
	elseif type(object) == "nil" then
		print(string.format("%s%s => %s", indent, name, "NIL"));
	elseif type(object) == "table" then
		print(string.format("%s%s => {", indent, name));

		for key, value in next, object do
			self:printAll(value, key, level + 1);
		end;

		print(string.format("%s}", indent));
	end;
end;


function LoathebRotate:getFullPlayerName(playerName)
	local _, _, name, realm = string.find(playerName, "([^-]*)-(%S*)");
	
	if realm then
		if string.find(realm, " ") then
			local _, _, name1, name2 = string.find(realm, "([a-zA-Z]*) ([a-zA-Z]*)");
			realm = name1 .. name2; 
		end;
	else
		name = playerName;
		realm = self:getMyRealm();
	end;

	return name .."-".. realm;
end;

function LoathebRotate:getPlayerAndRealm(unitid)
	local playername, realmname = UnitName(unitid);
	if not playername then return nil; end;

	if not realmname or realmname == "" then
		realmname = self:getMyRealm();
	end;

	return playername.."-".. realmname;
end;

function LoathebRotate:getMyRealm()
	local realmname = GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

