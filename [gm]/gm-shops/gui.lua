local sw, sh = guiGetScreenSize ( )

tradeGUI = { }

function tradeGUI.create ( trade )
	tradeGUI.trade = trade

	tradeGUI.wnd = guiCreateWindow ( sw * 0.04, sh * 0.3, 250, 400, trade.name, false )
	
	tradeGUI.cmbGroup = guiCreateComboBox ( 0.02, 0.06, 0.96, 0.4, "Group", true, tradeGUI.wnd )
	for i, group in ipairs ( trade.items ) do
		guiComboBoxAddItem ( tradeGUI.cmbGroup, group.name )
	end
	guiComboBoxSetSelected ( tradeGUI.cmbGroup, 0 )
	addEventHandler ( "onClientGUIComboBoxAccepted", tradeGUI.cmbGroup, tradeGUI.changeGroup, false )
	
	tradeGUI.lstItems = guiCreateGridList ( 0.02, 0.13, 0.96, 0.76, true, tradeGUI.wnd )
	guiGridListSetSortingEnabled ( tradeGUI.lstItems, false )
	guiGridListAddColumn ( tradeGUI.lstItems, "Item", 0.5 )
	guiGridListAddColumn ( tradeGUI.lstItems, "Cost", 0.4 )
	tradeGUI.initItems ( 1 )
	
	tradeGUI.btnCancel = guiCreateButton ( 0.02, 0.9, 0.46, 0.07, "Пропустить", true, tradeGUI.wnd )
	tradeGUI.btnBuy = guiCreateButton ( 0.5, 0.9, 0.46, 0.07, "Купить", true, tradeGUI.wnd )
	
	addEventHandler ( "onClientGUIClick", tradeGUI.wnd, tradeGUI.traderClick )
	
	showCursor ( true )
	guiSetInputEnabled ( true )
end

function tradeGUI.initItems ( index )
	guiGridListClear ( tradeGUI.lstItems )

	for _, item in ipairs ( tradeGUI.trade.items [ index ] ) do
		local row = guiGridListAddRow ( tradeGUI.lstItems )
		guiGridListSetItemText ( tradeGUI.lstItems, row, 1, item.name, false, false )
		guiGridListSetItemText ( tradeGUI.lstItems, row, 2, tostring ( item.cost ), false, false )
	end
end

function tradeGUI.changeGroup ( )
	local selectedGroup = guiComboBoxGetSelected ( tradeGUI.cmbGroup )
	if selectedGroup < 0 then
		return
	end
	
	tradeGUI.initItems ( selectedGroup + 1 )
end

function tradeGUI.traderClick ( )
	if source == tradeGUI.lstItems then
		local selectedGroup = guiComboBoxGetSelected ( tradeGUI.cmbGroup )
	
		local selectedItem = guiGridListGetSelectedItem ( tradeGUI.lstItems )
		if selectedItem < 0 then
			return
		end
		
		local item = tradeGUI.trade.items [ selectedGroup + 1 ] [ selectedItem + 1 ]
		tradeGUI.trade.onSelected ( item )
	elseif source == tradeGUI.btnCancel then
		tradeGUI.trade.onCancel ( )
		tradeGUI.destroy ( )
	elseif source == tradeGUI.btnBuy then
		local selectedGroup = guiComboBoxGetSelected ( tradeGUI.cmbGroup )
	
		local selectedItem = guiGridListGetSelectedItem ( tradeGUI.lstItems )
		if selectedItem < 0 then
			return
		end
		
		local item = tradeGUI.trade.items [ selectedGroup + 1 ] [ selectedItem + 1 ]
		tradeGUI.trade.onApply ( item )
	end
end

function tradeGUI.destroy ( )
	destroyElement ( tradeGUI.wnd )
	showCursor ( false )
	guiSetInputEnabled ( false )
end