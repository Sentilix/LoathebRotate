local LoathebRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("LoathebRotate")

-- Enable/disable right click for all healer frames
function LoathebRotate:enableRightClick()
	for _, healer in pairs(LoathebRotate.rotationTable) do
		LoathebRotate:enableHealerFrameRightClick(healer);
	end

	for _, healer in pairs(LoathebRotate.backupTable) do
		LoathebRotate:enableHealerFrameRightClick(healer);
	end
end

-- Enable or disable right click for one healer frame
function LoathebRotate:enableHealerFrameRightClick(healer)
	healer.frame:EnableMouse(true)
	if healer.frame.context then
		-- Close any remaining context menu
		healer.frame.context:Hide();
		healer.frame.context = nil;
	end
end

-- Configure healer frame right click behavior
function LoathebRotate:configureHealerFrameRightClick(healer)
	healer.frame:SetScript(
		"OnMouseUp",
		function(frame, button)
			if button == "RightButton" then
				-- Create the context menu
				-- If already created, re-create it from scratch
				if frame.context then
					frame.context:Hide();
					frame.context = nil;
				end
				frame.context = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate");
				local menu = LoathebRotate:populateMenu(frame);
				EasyMenu(menu, frame.context, "cursor", 0 , 0, "MENU");
			end
		end
	)
end

-- Fill menu items, filtered by the value of mode.assignable:
-- - those who fit the class/role are "main players"
-- - those who don't are listed in a submenu "other players"
-- The "other players" is not a submenu in dungeons because a 5-player list is short enough
-- But they still are listed after the main players (i.e. main players appear on top)
function LoathebRotate:populateMenu(frame)
	local healer = frame.healer;

	local menu = {
		{ text = string.format(L["CONTEXT_ASSIGN_TITLE"], healer.name), isTitle = true }
	}

    local addMenuItem = function(menu, menuText, isChecked, iconId)
		table.insert(menu, {
			name = itemName,
			text = menuText,
			checked = isChecked,
			icon = iconId,
			arg1 = healer.fullName,
			func = function(item)
				if frame.context then 
					frame.context:Hide();
				end
				LoathebRotate:onMenuClick(self, item);
			end
		})
    end

	local isHealer =  healer.isHealerRole or false;
	local isTankDps = healer.isTankDpsRole or false;
	local isUnknown = healer.isUnknownRole or (isHealer == false and isTankDps == false);

	addMenuItem(menu, string.format("%s's role is Healer", healer.name), isHealer, LoathebRotate.constants.icons.healer);
	addMenuItem(menu, string.format("%s's role is Tank/DPS", healer.name), isTankDps, LoathebRotate.constants.icons.tankdps);
	addMenuItem(menu, string.format("%s's role is unknown", healer.name), isUnknown, LoathebRotate.constants.icons.unknown);


    -- Always end with "Cancel"
    -- We could display "<Cancel>" to distinguish with a player called "Cancel"
    -- But everyone expects to see "Cancel" since the dawn of time, so we keep it
    -- Also, the "other players" submenu acts as a separator, which makes it less ambiguous
    table.insert(menu, {
        text = L["CONTEXT_CANCEL"],
        func = function() frame.context:Hide() end
    })

    return menu
end


function LoathebRotate:onMenuClick(sender, item, ...)
	local menuItem = item.icon;
	local enable = not item.checked;
	local healer = LoathebRotate:getHealer(item.arg1);

	local isHealer  = (item.icon == LoathebRotate.constants.icons.healer);
	local isTankDps = (item.icon == LoathebRotate.constants.icons.tankdps);
	local isUnknown = (item.icon == LoathebRotate.constants.icons.unknown);

	healer.isHealerRole  = (isHealer and enable);
	healer.isTankDpsRole = (isTankDps and enable); 
	healer.isUnknownRole = (isUnknown and enable); 
	healer.roleTimestamp = GetServerTime();

	LoathebRotate:applyRoleSetting(healer);
	LoathebRotate:requestUpdateRole(healer);
end;
