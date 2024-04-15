local LoathebRotate = select(2, ...)


function LoathebRotate:calculateVersionNumber()
	local _, _, major, minor, patch = string.find(LoathebRotate.version, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 10000 + minor * 100 + patch;
	end
	
	return version;
end;

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
	if not healer then
		return false;
	end;

    local isCooldownShortEnough = healer.lastHealTime <= GetTime() - LoathebRotate.constants.minimumCooldownElapsedForEligibility;

    return LoathebRotate:isHealerAliveAndOnline(healer) and isCooldownShortEnough;
end

-- Checks if a player is in a battleground
function LoathebRotate:isPlayerInBattleground()
    return UnitInBattleground('player') ~= nil
end

-- Checks if the addon bearer is in a PvE raid or dungeon
function LoathebRotate:isActive()
	if LoathebRotate.db.profile.enableDebug then
		return true;
	elseif not LoathebRotate:isHealerClass(UnitName('player')) then
		return false;
	elseif LoathebRotate:isPlayerInBattleground() then
		return false;
	elseif IsInRaid() then
		return true;
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

-- Checks if this is Loatheb!
function LoathebRotate:isLoathebBoss(guid)
    local type, mobId = LoathebRotate:getIdFromGuid(guid);

	if (type == "Creature") and (mobId == 16011) then
        return true;
    end

	if (LoathebRotate.db.profile.enableDebug) and (1*(LoathebRotate.db.profile.emulatedBossId or 0) == mobId) then
		return true;
	end;

    return false
end

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
	if (playerName or '') == '' then return ''; end;

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

