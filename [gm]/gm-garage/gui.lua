local guiListBoxItems = { }

function guiCreateListBox ( x, y, width, height, relative, parent )
	local scrollPane = guiCreateScrollPane ( x, y, width, height, relative, parent )
	
	addEventHandler ( "onClientGUIClick", scrollPane, guiListBox.onClick )
	addEventHandler ( "onClientMouseEnter", scrollPane, guiListBox.onMouseEnter )
	addEventHandler ( "onClientMouseLeave", scrollPane, guiListBox.onMouseLeave )
	
	guiListBoxItems [ scrollPane ] = {
		
	}
	
	return scrollPane
end

function guiListBoxAddItem ( listBox, text )
	local panePosX, panePosY = guiGetPosition ( listBox, false )
	local paneWidth, paneHeight = guiGetSize ( listBox, false )

	local staticImage = guiCreateStaticImage ( panePosX + 1, panePosY + self.topPos + 1, paneWidth - 2, 50 - 2, "background.png", false, listBox )
	
		label = guiCreateLabel ( 0.1, 0, 0.8, 1, text, true, staticImage )
end

function onClick ( )
	if getElementType ( source ) ~= "gui-staticimage" then
		return
	end
	
	
end

function onMouseEnter ( )
	if getElementType ( source ) ~= "gui-staticimage" then
		return
	end
	
	
end

function onMouseLeave ( )
	if getElementType ( source ) ~= "gui-staticimage" then
		return
	end
	
	
end

--[[addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local sw, sh = guiGetScreenSize ( )
		
		local wnd = guiCreateWindow ( sw * 0.04, sh * 0.3, 250, 500, "Настройка", false )
		local tabPanel = guiCreateTabPanel ( 0.02, 0.1, 0.96, 0.96, true, wnd )
		local partsTab = guiCreateTab ( "Части", tabPanel )
		local slotList = guiListBox.create ( 0.02, 0.02, 0.96, 0.3, true, partsTab )
		
		local upgrades = getVehicleCompatibleUpgrades ( getPedOccupiedVehicle ( localPlayer ) )
		for _, upgradesID in ipairs ( upgrades ) do
			local upgradeName = getVehicleUpgradeSlotName ( upgradesID )
			slotList:addItem ( upgradeName )
		end
		
		local partList = guiListBox.create ( 0.02, 0.42, 0.96, 0.5, true, partsTab )
		
		local upgrades = getVehicleCompatibleUpgrades ( getPedOccupiedVehicle ( localPlayer ) )
		for _, upgradesID in ipairs ( upgrades ) do
			local upgradeName = getVehicleUpgradeSlotName ( upgradesID )
			partList:addItem ( upgradeName )
		end
		
		local paintTab = guiCreateTab ( "Покраска", tabPanel )
		
		showCursor ( true )
	end
)]]