addEvent ( "onClientTCTToggle", true )

editorForm = {
	settings = { },
	permission = true
}

function createMainWindow ( )
	editorForm.wnd = guiCreateWindow ( sw / 2 - 360, sh / 2 - 282.5, 740, 565, "WBO 12 Preview", false )
	guiWindowSetSizable ( editorForm.wnd, false )
	
	editorForm.leftPanel = guiCreateTabPanel ( 0.02, 0.05, 0.52, 0.86, true, editorForm.wnd )
	
	createEntityTab ( "Объекты", "objects.xml" )

	
	editorForm.createEdit = guiCreateEdit ( 0.02, 0.92, 0.32, 0.045, "", true, editorForm.wnd )
	editorForm.createBtn = guiCreateButton ( 0.35, 0.92, 0.19, 0.045, "Создать", true, editorForm.wnd )
	
	editorForm.rightPanel = guiCreateTabPanel ( 0.55, 0.05, 0.43, 0.92, true, editorForm.wnd )

	editorForm.toolsTab = guiCreateTab ( "Инструменты", editorForm.rightPanel )
	editorForm.toolsList = guiCreateGridList ( 0.02, 0.02, 0.38, 0.96, true, editorForm.toolsTab )
	guiGridListAddColumn ( editorForm.toolsList, "Инструмент", 0.8 )
	guiGridListSetSortingEnabled ( editorForm.toolsList, false )
	guiGridListSetSelectionMode ( editorForm.toolsList, 0 )
     
	editorForm.optionsTab = guiCreateTab ( "Опции", editorForm.rightPanel )
	editorForm.optionsScrollPane = guiCreateScrollPane ( 0.04, 0.02, 0.92, 0.96, true, editorForm.optionsTab )
 
	createSetting ( "s_step", { 
		"edit",
		
		text = "Шаг", 
		value = 0.1
	} )
	createSetting ( "s_rotoffset", { 
		"edit",
		
		text = "Смещение выравнивания", 
		value = 0
	} )
	createSetting ( "s_saveOffs", { 
		"checkbox",
		
		text = "Сохранять смещение", 
		selected = true
	} )
	createSetting ( "s_thelp", { 
		"checkbox",
		
		text = "Помощник", 
		selected = true
	} )
	createSetting ( "s_tgl", { 
		"checkbox",
		
		text = "Удержание окна", 
		selected = true
	} )
	createSetting ( "s_wire", { 
		"checkbox",
		
		text = "Рисовать провода*", 
		selected = true
	} )
	createSetting ( "s_area", { 
		"checkbox",
		
		text = "Рисовать участки", 
		selected = true
	} )
	createSetting ( "s_resetOffs", { 
		"button",
		
		text = "Сбросить смещение", 
		onClick = function ( )
			g_entityOffset.reset ( )
		end
	} )
  
	addEventHandler ( "onClientGUIClick", editorForm.wnd, click )
	--addEventHandler ( "onClientKey", root, toggleEditor )
  
	guiSetVisible ( editorForm.wnd, false )
end

function toggleEditor ( key, pressed )
	if key ~= "F5" then
		return
	end
	
	local editorVisible = pressed
	
	if getSettingByID ( "s_tgl" ):getData ( ) then
		if pressed ~= true then
			return
		end
		
		editorVisible = not guiGetVisible ( editorForm.wnd )
	end
	
	guiSetVisible ( editorForm.wnd, editorVisible )
	showCursor ( editorVisible )
end

function click ( )
	if getElementType ( source ) == "gui-gridlist" then
		local selectedRow = guiGridListGetSelectedItem ( source )
		
		if selectedRow < 0 then
			setSelectedTool ( getToolFromName ( "Default" ) )
				
			for element, _ in pairs ( bindedGridLists ) do
				guiGridListSetSelectedItem ( element, -1, 0 )
			end
						
			guiGridListSetSelectedItem ( editorForm.toolsList, -1, 0 )
			
			return
		end
	end
	
	if source == editorForm.createBtn then
		local model = tonumber ( guiGetText ( editorForm.createEdit ) )
		
		if model then
			setSelectedTool ( getToolFromName ( "Default" ) )
			
			for gridlist, _ in pairs ( bindedGridLists ) do
				guiGridListSetSelectedItem ( gridlist, -1, 0 )
			end
			
			guiGridListSetSelectedItem ( editorForm.toolsList, -1, 0 )
   
			local element = createEntity ( model, g_entityOffset.calcPosition ( ) )
			if element then
				setEditorTarget ( element )
			else
				outputChatBox ( "WBO: Объект с такой моделью не может быть создан", 255, 0, 0 )
			end
		else
			outputChatBox ( "WBO: Объект с такой моделью не может быть создан", 255, 0, 0 )
		end
	elseif source == editorForm.toolsList then  
		for gridlist, _ in pairs ( bindedGridLists ) do
			guiGridListSetSelectedItem ( gridlist, -1, 0 )
		end
  
		local selectedItem = guiGridListGetSelectedItem ( source )
		if selectedItem > -1 then
			local toolName = guiGridListGetItemText ( source, selectedItem, 1 )
			setSelectedTool ( getToolFromName ( toolName ) )
		end
	end
end

addEventHandler ( "onClientTCTToggle", resourceRoot,
	function ( pressed, permission )
		local editorVisible = pressed
	
		if getSettingByID ( "s_tgl" ):getData ( ) then
			if pressed ~= true then
				return
			end
		
			editorVisible = not guiGetVisible ( editorForm.wnd )
		end
		
		--Разрешаем кнопку создания объекта, если у игрока есть на это права
		editorForm.permission = permission
		guiSetEnabled ( editorForm.createBtn, permission )
		
		--Показываем или скрываем окно
		guiSetVisible ( editorForm.wnd, editorVisible )
		showCursor ( editorVisible )
	end
, false )

function editorCreateEntity ( gridlist, model )
	setSelectedTool ( getToolFromName ( "Default" ) )
						
	for element, _ in pairs ( bindedGridLists ) do
		if element ~= gridlist then
			guiGridListSetSelectedItem ( element, -1, 0 )
		end
	end
						
	guiGridListSetSelectedItem ( editorForm.toolsList, -1, 0 )
					
	local element = createEntity ( tonumber ( model ), g_entityOffset.calcPosition ( ) )
	if element then
		setEditorTarget ( element )
	end
end

function createEntityTab ( name, xmlfile )
	local entityTab = { 
		tab = guiCreateTab ( name, editorForm.leftPanel )
	}
	entityTab.gridlist = guiCreateGridList ( 0.02, 0.02, 0.96, 0.96, true, entityTab.tab )
	
	guiGridListSetSortingEnabled ( entityTab.gridlist, false )
	guiGridListSetSelectionMode ( entityTab.gridlist, 0 )
	guiGridListAddColumn ( entityTab.gridlist, "Название", 0.8 )
	
	
	guiGridListLoadTable ( entityTab.gridlist, loadList ( "conf\\" .. xmlfile ), editorCreateEntity )
	
	return entityTab
end

function createSetting ( id, tbl )
	editorForm.settings [ id ] = createControl ( tbl, editorForm.optionsScrollPane )
	
	return editorForm.settings [ id ]
end

function getSettingByID ( id )
	return editorForm.settings [ id ]
end