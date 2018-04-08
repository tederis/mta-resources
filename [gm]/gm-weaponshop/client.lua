local sw, sh = guiGetScreenSize ( )

local traderWindow
local weapons = { }

function createTraderWindow ( )
	if traderWindow then
		guiSetVisible ( traderWindow.wnd, true )
		showCursor ( true )
		guiSetInputEnabled ( true )
	
		return
	end
	
	traderWindow = {
		wnd = guiCreateWindow ( sw * 0.04, sh * 0.3, 250, 400, "Торговец", false )
	}
	traderWindow.cmbGroup = guiCreateComboBox ( 0.02, 0.06, 0.96, 0.4, "Группа", true, traderWindow.wnd )
	addEventHandler ( "onClientGUIComboBoxAccepted", traderWindow.cmbGroup, changeGroup, false )
	
	traderWindow.lstItems = guiCreateGridList ( 0.02, 0.13, 0.96, 0.76, true, traderWindow.wnd )
	guiGridListSetSortingEnabled ( traderWindow.lstItems, false )
	guiGridListAddColumn ( traderWindow.lstItems, "Оружие", 0.5 )
	guiGridListAddColumn ( traderWindow.lstItems, "Цена", 0.4 )
	
	loadFromXml ( "weapons.xml" )
	
	traderWindow.btnCancel = guiCreateButton ( 0.02, 0.9, 0.46, 0.07, "Пропустить", true, traderWindow.wnd )
	traderWindow.btnBuy = guiCreateButton ( 0.5, 0.9, 0.46, 0.07, "Купить", true, traderWindow.wnd )
	
	addEventHandler ( "onClientGUIClick", traderWindow.wnd, traderClick )
	
	showCursor ( true )
	guiSetInputEnabled ( true )
end

function changeGroup ( )
	local selectedGroup = guiComboBoxGetSelected ( traderWindow.cmbGroup )
	if selectedGroup < 0 then
		return
	end
	
	guiGridListClear ( traderWindow.lstItems )
	
	for _, weapon in ipairs ( weapons [ selectedGroup + 1 ] ) do
		local row = guiGridListAddRow ( traderWindow.lstItems )
		guiGridListSetItemText ( traderWindow.lstItems, row, 1, weapon.name, false, false )
		guiGridListSetItemText ( traderWindow.lstItems, row, 2, tostring ( weapon.cost ), false, false )
	end
end

function traderClick ( )
	if source == traderWindow.lstItems then
		local selectedGroup = guiComboBoxGetSelected ( traderWindow.cmbGroup )
	
		local selectedWeapon = guiGridListGetSelectedItem ( traderWindow.lstItems )
		if selectedWeapon < 0 then
			return
		end
		
		local weapon = weapons [ selectedGroup + 1 ] [ selectedWeapon + 1 ]
		local weaponID = tonumber ( weapon.id )
		
		local model
		if weaponID == 16 then
			model = 342
		elseif weaponID == -1 then
			model = 373
		else
			model = getOriginalWeaponProperty ( weaponID, "pro", "model" )
		end
		
		if traderWindow.object then
			ClientTaskWeaponShop.start ( traderWindow.ped, traderWindow.object, "TO_CHANGE", model )
		else
			traderWindow.object = createObject ( model, getElementPosition ( traderWindow.ped ) )
			
			local interior = getElementInterior ( traderWindow.ped )
			setElementInterior ( traderWindow.object, interior )
			local dimension = getElementDimension ( traderWindow.ped )
			setElementDimension ( traderWindow.object, dimension )
			
			ClientTaskWeaponShop.start ( traderWindow.ped, traderWindow.object, "TO_GRAB" )
		end
	elseif source == traderWindow.btnCancel then
		if traderWindow.object then
			ClientTaskWeaponShop.start ( traderWindow.ped, traderWindow.object, "TO_DROP" )
			traderWindow.object = nil
		end
	
		guiSetVisible ( traderWindow.wnd, false )
		showCursor ( false )
		guiSetInputEnabled ( false )
	elseif source == traderWindow.btnBuy then
		local selectedGroup = guiComboBoxGetSelected ( traderWindow.cmbGroup )
	
		local selectedWeapon = guiGridListGetSelectedItem ( traderWindow.lstItems )
		if selectedWeapon < 0 then
			return
		end
		
		local weapon = weapons [ selectedGroup + 1 ] [ selectedWeapon + 1 ]
	
		triggerServerEvent ( "onWeaponBuy", resourceRoot, weapon.id )
	end
end

addEventHandler ( "onClientMarkerHit", resourceRoot,
	function ( player, matchingDimension )
		if not matchingDimension then
			return
		end
		
		--Получаем продавца
		local seller = getElementParent ( source )
		
		createTraderWindow ( )
		traderWindow.ped = seller
	end
)

addEventHandler ( "onClientPedDamage", resourceRoot,
	function ( )
		cancelEvent ( )
	end
)

function loadFromXml ( filepath )
	local xmlfile = xmlLoadFile ( filepath )
	if xmlfile then
		for i, group in ipairs ( xmlNodeGetChildren ( xmlfile ) ) do
			local groupData = {
				name = xmlNodeGetAttribute ( group, "name" )
			}
			
			guiComboBoxAddItem ( traderWindow.cmbGroup, groupData.name )
			
			table.insert ( weapons, groupData )
			
			for _, weapon in ipairs ( xmlNodeGetChildren ( group ) ) do
				local weaponData = {
					id = xmlNodeGetAttribute ( weapon, "id" ),
					name = xmlNodeGetAttribute ( weapon, "name" ),
					cost = xmlNodeGetAttribute ( weapon, "cost" )
				}
				
				if i < 2 then
					local row = guiGridListAddRow ( traderWindow.lstItems )
					guiGridListSetItemText ( traderWindow.lstItems, row, 1, weaponData.name, false, false )
					guiGridListSetItemText ( traderWindow.lstItems, row, 2, tostring ( weaponData.cost ), false, false )
				end
				
				table.insert ( weapons [ i ], weaponData )
			end
		end
		
		guiComboBoxSetSelected ( traderWindow.cmbGroup, 0 )
		
		xmlUnloadFile ( xmlfile )
	end
end