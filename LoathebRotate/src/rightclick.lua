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
end

-- Configure healer frame right click behavior
function LoathebRotate:configureHealerFrameRightClick(healer)
	healer.frame:SetScript(
		"OnMouseUp",
		function(frame, button)
			if button == "RightButton" then

				local menuTitle = string.format(L["CONTEXT_ASSIGN_TITLE"], healer.name);
				local healer = frame.healer;
				local isHealer =  healer.isHealerRole or false;
				local isTankDps = healer.isTankDpsRole or false;
				local isUnknown = healer.isUnknownRole or (isHealer == false and isTankDps == false);

				MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
					rootDescription:CreateTitle(menuTitle);
					
					rootDescription:CreateButton(
						string.format("%s's role is Healer", healer.name), 
						function()
							local item = {};
							item.healer = healer.name;
							item.icon = LoathebRotate.constants.icons.healer;

							LoathebRotate:onMenuClick(self, item);
						end
					);
					
					rootDescription:CreateButton(
						string.format("%s's role is Tank/DPS", healer.name), 
						function()
							local item = {};
							item.healer = healer.name;
							item.icon = LoathebRotate.constants.icons.tankdps;

							LoathebRotate:onMenuClick(self, item);
						end
					);
					
					rootDescription:CreateButton(
						string.format("%s's role is unknown", healer.name), 
						function()
							local item = {};
							item.healer = healer.name;
							item.icon = LoathebRotate.constants.icons.unknown;

							LoathebRotate:onMenuClick(self, item);
						end
					);
					
					rootDescription:CreateDivider();

					-- Always end with "Cancel"
					-- We could display "<Cancel>" to distinguish with a player called "Cancel"
					-- But everyone expects to see "Cancel" since the dawn of time, so we keep it
					rootDescription:CreateButton(
						L["CONTEXT_CANCEL"], 
						function() end
					);

				end);
			end
		end
	)
end


function LoathebRotate:onMenuClick(sender, item, ...)
	local menuItem = item.icon;
	local enable = not item.checked;
	local healer = LoathebRotate:getHealer(item.healer);
	if not healer then return; end;

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
