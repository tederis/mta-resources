addEvent ( "onClientTCTToggle", true )

editorForm = {
	settings = { },
	permission = false
}

function createMainWindow ( )
	-- Проверяем разрешение экрана
	if sw < 800 or sh < 600 then
		outputChatBox ( "TCT: Your screen resolution is not supported!", 200, 200, 0 )
	end

	editorForm.wnd = guiCreateWindow ( ( sw / 2 ) - 370, ( sh / 2 ) - 283, 740, 565, "TCT GC by TEDERIs", false )
	guiWindowSetSizable ( editorForm.wnd, false )
	
	editorForm.leftPanel = guiCreateTabPanel ( 0.02, 0.05, 0.52, 0.86, true, editorForm.wnd )
	
	createEntityTab ( _LD"MF_TObjects", "objects.xml" )
	createEntityTab ( _LD"MF_TVehicles", "vehicles.xml" )
	createEntityTab ( _LD"MF_TPeds", "peds.xml" )
	
	-- Rooms tab
	editorForm.roomTab = guiCreateTab ( _LD"MF_TRooms", editorForm.leftPanel )
	RoomCatalog.create ( editorForm.roomTab )
	
	-- Graphs tab
	editorForm.graphTab = guiCreateTab ( _LD"MF_TGraphs", editorForm.leftPanel )
	GraphCatalog.create ( editorForm.graphTab )

	editorForm.createEdit = guiCreateEdit ( 0.02, 0.92, 0.32, 0.045, "", true, editorForm.wnd )
	editorForm.createBtn = guiCreateButton ( 0.35, 0.92, 0.19, 0.045, _LD"MFCreate", true, editorForm.wnd )
	
	editorForm.rightPanel = guiCreateTabPanel ( 0.55, 0.05, 0.43, 0.92, true, editorForm.wnd )

	editorForm.toolsTab = guiCreateTab ( _LD"MF_TTools", editorForm.rightPanel )
	editorForm.toolsList = guiCreateGridList ( 0.02, 0.02, 0.38, 0.96, true, editorForm.toolsTab )
	guiGridListAddColumn ( editorForm.toolsList, "Tool", 0.8 )
	guiGridListSetSortingEnabled ( editorForm.toolsList, false )
	guiGridListSetSelectionMode ( editorForm.toolsList, 0 )
     
	editorForm.optionsTab = guiCreateTab ( _LD"MF_TSettings", editorForm.rightPanel )
	editorForm.optionsScrollPane = guiCreateScrollPane ( 0.04, 0.02, 0.92, 0.96, true, editorForm.optionsTab )
 
	createSetting ( "s_step", { 
		"edit",
		
		text = _LD"MF_SStep", 
		value = 0.1
	} )
	createSetting ( "s_rotoffset", { 
		"edit",
		
		text = _LD"MF_SRot", 
		value = 0
	} )
	createSetting ( "s_saveOffs", { 
		"checkbox",
		
		text = _LD"MF_SSaveOff", 
		selected = true
	} )
	createSetting ( "s_thelp", { 
		"checkbox",
		
		text = _LD"MF_SHelp", 
		selected = true
	} )
	createSetting ( "s_emode", { 
		"checkbox",
		
		text = _LD"MF_SEditorM", 
		selected = true
	} )
	createSetting ( "s_tgl", { 
		"checkbox",
		
		text = _LD"MF_SToggle", 
		selected = true
	} )
	createSetting ( "s_objinfo", { 
		"checkbox",
		
		text = _LD"MF_SEInfo", 
		selected = false
	} )
	createSetting ( "s_lang", { 
		"combobox",
		
		text = _LD"MF_SLang", 
		items = availableLangs,
		onAccepted = function ( index )
			setActualLang ( index + 1 )
		end
	} )
	createSetting ( "s_resetOffs", { 
		"button",
		
		text = _LD"MF_SResetOff", 
		onClick = function ( )
			if getElementData ( localPlayer, "freecam:state" ) then
				g_entityOffset.reset ( 0, 0, 0 )
			else
				g_entityOffset.reset ( 0, 3, -1 )
			end
		end	
	} )
  
	addEventHandler ( "onClientGUIClick", editorForm.wnd, click )
	
	-- Инициализируем все интерфейсные события
	addEventHandler ( "onClientTCTToggle", resourceRoot, toggleEditorForm, false )
  
	guiSetVisible ( editorForm.wnd, false )
	
	TCTInformer.init ( )
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
			
			local x, y, z = g_entityOffset.calcPosition ( )
			local rx, ry, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
			local element = createEntity ( model, x, y, z, rx, ry, rz )
			if element then
				Editor.setTarget ( element )
			else
				outputChatBox ( _L"MFMsgOCreateWarn", 255, 0, 0 )
			end
		else
			outputChatBox ( _L"MFMsgOCreateWarn", 255, 0, 0 )
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

function toggleEditorForm ( pressed, permission, accountName )
	local editorVisible = pressed
	
	if getSettingByID ( "s_tgl" ):getData ( ) then
		if pressed ~= true then
			return
		end
		
		editorVisible = not guiGetVisible ( editorForm.wnd )
	end
		
	--Разрешаем кнопку создания объекта, если у игрока есть на это права
	editorForm.permission = permission
	--guiSetEnabled ( editorForm.createBtn, permission )
	Editor.permissionStatus = permission
	Editor.accountName = accountName
		
	--Показываем или скрываем окно
	guiSetVisible ( editorForm.wnd, editorVisible )
	showCursor ( editorVisible )
	guiSetInputEnabled ( editorVisible )
		
	Editor.selectGraph = nil
end

function editorCreateEntity ( gridlist, model )
	setSelectedTool ( getToolFromName ( "Default" ) )
						
	for element, _ in pairs ( bindedGridLists ) do
		if element ~= gridlist then
			guiGridListSetSelectedItem ( element, -1, 0 )
		end
	end
						
	guiGridListSetSelectedItem ( editorForm.toolsList, -1, 0 )
	
	local x, y, z = g_entityOffset.calcPosition ( )
	local rx, ry, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
	local element = createEntity ( tonumber ( model ), x, y, z, rx, ry, rz )
	if element then
		Editor.setTarget ( element )
	end
end

function createEntityTab ( name, xmlfile )
	local entityTab = { 
		tab = guiCreateTab ( name, editorForm.leftPanel )
	}
	entityTab.gridlist = guiCreateGridList ( 0.02, 0.02, 0.96, 0.96, true, entityTab.tab )
	
	
	guiGridListSetSortingEnabled ( entityTab.gridlist, false )
	guiGridListSetSelectionMode ( entityTab.gridlist, 0 )
	guiGridListAddColumn ( entityTab.gridlist, "Name", 0.8 )
	
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

function isMenuVisible ( )
	return isElement ( editorForm.wnd ) and guiGetVisible ( editorForm.wnd )
end

--[[
	Informer
]]
TCTInformer = {
	width = 400,
	height = 400
}

TCTInformer.x = sw / 2 - TCTInformer.width / 2
TCTInformer.y = sh / 2 - TCTInformer.height / 2

TCTInformer.duration = 3000

function TCTInformer.onRender ( )
	local _informer = TCTInformer

	local now = getTickCount ( )
	local elapsedTime = now - _informer.startTime
	local progress = elapsedTime / _informer.duration

	if progress > 1 then
		if _informer.popDown then
			removeEventHandler ( "onClientRender", root, _informer.onRender )
			
			progress = 0
		else
			if elapsedTime > _informer.duration*8 then
				_informer.popDown = true
				_informer.startTime = now
			end
			
			progress = 1
		end
	else
		if _informer.popDown then
			progress = 1 - progress
		end
	end
	
	dxDrawText ( "TEDERIs Construction Tools", 0, 0, sw, sh, tocolor ( 255, 255, 255, progress * 130 ), 4, "default", "center", "center" )
	local _width = dxGetTextWidth ( "TEDERIs Construction Tools", 4 )
	dxDrawText ( "Open Source game development environment", sw / 2 + _width/2 - dxGetTextWidth ( "Open Source game development environment", 1.5 ), sh / 2 - dxGetFontHeight ( 4 ) * 0.8, sw, sh, tocolor ( 255, 255, 255, progress * 130 ), 1.5, "default", "left", "top" )
end

function TCTInformer.init ( )
	setTimer (
		function ( )
			TCTInformer.startTime = getTickCount ( )
			addEventHandler ( "onClientRender", root, TCTInformer.onRender, false )
		end
	, 50, 1 )
end