local sw, sh = guiGetScreenSize ( )

local upgradeWnd = { }

function upgradeWnd.create ( )
	if upgradeWnd.wnd then
		return
	end

	upgradeWnd.wnd = guiCreateWindow ( sw * 0.04, sh * 0.3, 250, 500, "Настройка", false )
	
	upgradeWnd.tabPanel = guiCreateTabPanel ( 0.02, 0.1, 0.96, 0.82, true, upgradeWnd.wnd )
	
	upgradeWnd.partsTab = guiCreateTab ( "Части", upgradeWnd.tabPanel )
	
	--upgradeWnd.slotList = guiListBox.create ( 0.02, 0.02, 0.96, 0.3, true, upgradeWnd.partsTab )
	upgradeWnd.slotList = guiCreateGridList ( 0.02, 0.02, 0.96, 0.3, true, upgradeWnd.partsTab )
	guiGridListAddColumn ( upgradeWnd.slotList, "Slot", 0.7)
	addEventHandler ( "onClientGUIClick", upgradeWnd.slotList,
		function ( )
			local selectedItem = guiGridListGetSelectedItem ( upgradeWnd.slotList )
			if selectedItem > -1 then
				local slotName = guiGridListGetItemText ( upgradeWnd.slotList, selectedItem, 1 )
				
				upgradeWnd.loadVehicleSlotParts ( upgradeWnd.vehicle, getSlotIDByName ( slotName ) )
			end
		end
	, false )
	
	--upgradeWnd.partList = guiListBox.create ( 0.02, 0.42, 0.96, 0.5, true, upgradeWnd.partsTab )
	upgradeWnd.partList = guiCreateGridList ( 0.02, 0.42, 0.96, 0.5, true, upgradeWnd.partsTab )
	guiGridListAddColumn ( upgradeWnd.partList, "Part", 0.7 )
	addEventHandler ( "onClientGUIClick", upgradeWnd.partList,
		function ( )
			local selectedItem = guiGridListGetSelectedItem ( upgradeWnd.partList )
			if selectedItem > -1 then
				local partName = guiGridListGetItemText ( upgradeWnd.partList, selectedItem, 1 )
				
				addVehicleUpgrade ( upgradeWnd.vehicle, partName )
			end
		end
	, false )
	
	upgradeWnd.paintTab = guiCreateTab ( "Покраска", upgradeWnd.tabPanel )
	
	upgradeWnd.cancelBtn = guiCreateButton ( 0.02, 0.93, 0.45, 0.05, "Отмена", true, upgradeWnd.wnd )
	addEventHandler ( "onClientGUIClick", upgradeWnd.cancelBtn,
		function ( )
			upgradeWnd.destroy ( )
			triggerServerEvent ( "onVehicleCustomizeCancel", upgradeWnd.vehicle, upgradeWnd.garage )
		end
	, false )
	upgradeWnd.saveBtn = guiCreateButton ( 0.51, 0.93, 0.45, 0.05, "Сохранить", true, upgradeWnd.wnd )
	addEventHandler ( "onClientGUIClick", upgradeWnd.saveBtn,
		function ( )
			upgradeWnd.destroy ( )
			
			--TODO
		end
	, false )
	
	showCursor ( true )
end

function upgradeWnd.destroy ( )
	if not upgradeWnd.wnd then
		return
	end
	
	destroyElement ( upgradeWnd.wnd )
	upgradeWnd.wnd = nil
	
	showCursor ( false )
end

function upgradeWnd.loadVehicleSlotParts ( vehicle, slot )
	guiGridListClear ( upgradeWnd.partList )
	
	local installedUpgrade = getVehicleUpgradeOnSlot ( vehicle, slot )
	
	for _, upgrade in ipairs ( getVehicleCompatibleUpgrades ( vehicle, slot ) ) do
		local row = guiGridListAddRow ( upgradeWnd.partList )
		guiGridListSetItemText ( upgradeWnd.partList, row, 1, tostring ( upgrade ), false, false )
		
		if upgrade == installedUpgrade then
			guiGridListSetSelectedItem ( upgradeWnd.partList, row, 1 )
		end
	end
end

addEvent ( "onClientVehicleCustomize", true )
addEventHandler ( "onClientVehicleCustomize", root,
	function ( garage )
		upgradeWnd.create ( )
		
		local compatibleSlots = { }
			
		for i, upgrade in ipairs ( getVehicleCompatibleUpgrades ( source ) ) do
			local slot = getVehicleUpgradeSlotName ( upgrade )
				
			if not compatibleSlots [ slot ] then
				compatibleSlots [ slot ] = true
					
				local row = guiGridListAddRow ( upgradeWnd.slotList )
				guiGridListSetItemText ( upgradeWnd.slotList, row, 1, slot, false, false )
			end
		end
			
		guiGridListSetSelectedItem ( upgradeWnd.slotList, 0, 1 )
		local slotName = guiGridListGetItemText ( upgradeWnd.slotList, 0, 1 )
		upgradeWnd.loadVehicleSlotParts ( source, getSlotIDByName ( slotName ) )
		
		upgradeWnd.vehicle = source
		upgradeWnd.garage = garage
	end
)

local upgradeSlots = {
	[ "Vent" ] = 1,
	[ "Spoiler" ] = 2,
	[ "Sideskirt" ] = 3,
	[ "Front Bullbars" ] = 4,
	[ "Rear Bullbars" ] = 5,
	[ "Headlights" ] = 6,
	[ "Roof" ] = 7,
	[ "Nitro" ] = 8,
	[ "Hydraulics" ] = 9,
	[ "Stereo" ] = 10,
	[ "Unknown" ] = 11,
	[ "Wheels" ] = 12,
	[ "Exhaust" ] = 13,
	[ "Front Bumper" ] = 14,
	[ "Rear Bumper" ] = 15,
	[ "Misc" ] = 16
}

function getSlotIDByName ( slotName )
	return upgradeSlots [ slotName ]
end