_withinRectangle = function ( px, py, rx, ry, rwidth, rheight )
	return ( px >= rx and px <= rx + rwidth ) and ( py >= ry and py <= ry + rheight )
end

--[[
	xrPackageFrame
]]
xrPackageFrame = { 
	info = "Чтобы добавить новый пакет введите в поле ниже имя пакета и нажмите 'Добавить'."
}

function xrPackageFrame.open ( wnd )
	-- Строка добавления ресурса
	guiCreateLabel ( 10, 70, 40, 20, "Пакет", false, wnd )
	xrPackageFrame.packageCombo = guiCreateComboBox ( 60, 70, 100, 100, "Пакет", false, wnd )
	addEventHandler ( "onClientGUIComboBoxAccepted", xrPackageFrame.packageCombo, xrPackageFrame.onChangePackage, false )
	xrPackageFrame.addpackageEdt = guiCreateEdit ( 170, 70, 80, 20, "", false, wnd )
	xrPackageFrame.addpackageBtn = guiCreateButton ( 260, 70, 80, 20, "Добавить", false, wnd )
	addEventHandler ( "onClientGUIClick", xrPackageFrame.addpackageBtn, xrPackageFrame.onButtonClick, false )
	xrPackageFrame.refreshBtn = guiCreateButton ( 350, 70, 80, 20, "Обновить", false, wnd )
	addEventHandler ( "onClientGUIClick", xrPackageFrame.refreshBtn, xrPackageFrame.onButtonClick, false )
	
	-- Список ресурсов
	local wndWidth = guiGetSize ( wnd, false )
	xrPackageFrame.resLst = guiCreateGridList ( 10, 100, wndWidth - 20, 400, false, wnd )
	guiGridListSetSortingEnabled ( xrPackageFrame.resLst, false )
	guiGridListAddColumn ( xrPackageFrame.resLst, "Модель", 0.15 )
	guiGridListAddColumn ( xrPackageFrame.resLst, "Имя", 0.25 )
	guiGridListAddColumn ( xrPackageFrame.resLst, "Текстура", 0.25 )
	guiGridListAddColumn ( xrPackageFrame.resLst, "LOD", 0.15 )
	guiGridListAddColumn ( xrPackageFrame.resLst, "Дальность", 0.15 )
	
	-- Строка кнопок для работы с ресурсами
	local buttonsNum = 3
	local buttonWidth = ( wndWidth - 10 + 10*buttonsNum ) / buttonsNum
	local btnPos = 10
	xrPackageFrame.removeBtn = guiCreateButton ( btnPos, 510, buttonWidth, 25, "Удалить", false, wnd ); btnPos = btnPos + buttonWidth + 10;
	addEventHandler ( "onClientGUIClick", xrPackageFrame.removeBtn, xrPackageFrame.onButtonClick, false )
	xrPackageFrame.editBtn = guiCreateButton ( btnPos, 510, buttonWidth, 25, "Изменить", false, wnd ); btnPos = btnPos + buttonWidth + 10;
	addEventHandler ( "onClientGUIClick", xrPackageFrame.editBtn, xrPackageFrame.onButtonClick, false )
	xrPackageFrame.addBtn = guiCreateButton ( btnPos, 510, buttonWidth, 25, "Добавить", false, wnd ); btnPos = btnPos + buttonWidth + 10;
	addEventHandler ( "onClientGUIClick", xrPackageFrame.addBtn, xrPackageFrame.onButtonClick, false )
	
	-- Подгрузим список пакетов
	for _, packageName in ipairs ( xrLoader.packages ) do
		guiComboBoxAddItem ( xrPackageFrame.packageCombo, packageName )
	end
	guiComboBoxSetSelected ( xrPackageFrame.packageCombo, #xrLoader.packages - 1 )
	xrPackageFrame.loadPackage ( xrLoader.packages [ #xrLoader.packages ] )
end

function xrPackageFrame.close ( )
	xrPackageFrame.indexed = nil
end

function xrPackageFrame.onButtonClick ( )
	-- Добавление пакета
	if source == xrPackageFrame.addpackageBtn then
		local pkgName = guiGetText ( xrPackageFrame.addpackageEdt )
		if utfLen ( pkgName ) >= 3 then
			local package = xrLoader.createPackage ( pkgName )
			
			guiComboBoxAddItem ( xrPackageFrame.packageCombo, pkgName )
			guiComboBoxSetSelected ( xrPackageFrame.packageCombo, 0 )
			xrPackageFrame.loadPackage ( package )
		else
			outputChatBox ( "Имя пакета должно иметь по крайней мере 3 символа!", 255, 0, 0 )
		end
	
		return
	end
	
	-- Изменить модель
	if source == xrPackageFrame.editBtn then
		local row = guiGridListGetSelectedItem ( xrPackageFrame.resLst )
		if row > -1 then
			local mesh = xrPackageFrame.indexed [ row + 1 ]
			if mesh then
				xrLoaderMenu.loadFrame ( xrEditFrame, mesh )
			else
				outputDebugString ( "Вызываемая модель была удалена", 3 )
			end
		else
			outputChatBox ( "Вы должны выбрать модель чтобы ее изменить", 255, 0, 0 )
		end
		
		return
	end
	
	-- Добавить модель
	if source == xrPackageFrame.addBtn then
		xrLoaderMenu.loadFrame ( xrEditFrame, true )
		
		return
	end
	
	-- Обновить модель
	if source == xrPackageFrame.refreshBtn then
		local pkg = getResourceFromName ( xrPackageFrame.currentPkg )
		if pkg then
			local packageRoot = getResourceRootElement ( pkg )
			triggerServerEvent ( "onPackageUpdate", packageRoot )
		else
			outputDebugString ( "Такого пакета не существует", 2 )
		end
	end
end

function xrPackageFrame.onChangePackage ( )
	local index = guiComboBoxGetSelected ( source )
	if index > -1 then
		local pkgName = guiComboBoxGetItemText ( source, index )
		xrPackageFrame.loadPackage ( pkgName )
	end
end

function xrPackageFrame.loadPackage ( pkgName )
	guiGridListClear ( xrPackageFrame.resLst )
	
	-- Для корректной индексации при работе со строками создадим таблицу
	xrPackageFrame.indexed = { }
	
	local pkg = getResourceFromName ( pkgName )
	local packageRoot = getResourceRootElement ( pkg )
	for i, mesh in ipairs ( getElementsByType ( "mesh", packageRoot ) ) do
		local meshModel = getElementData ( mesh, "model", false )
		local meshGeom = getElementData ( mesh, "geom", false )
		local meshTex = getElementData ( mesh, "tex", false )
		if meshTex == false then
			meshTex = meshGeom
		end
		local meshLod = getElementData ( mesh, "lod", false )
	
		local row = guiGridListAddRow ( xrPackageFrame.resLst )
		guiGridListSetItemText ( xrPackageFrame.resLst, row, 1, tostring ( meshModel ), false, true )
		guiGridListSetItemText ( xrPackageFrame.resLst, row, 2, meshGeom, false, false )
		guiGridListSetItemText ( xrPackageFrame.resLst, row, 3, meshTex, false, false )
		if meshLod then
			local meshLodDist = getElementData ( mesh, "loddist", false )
			guiGridListSetItemText ( xrPackageFrame.resLst, row, 4, tostring ( meshLod ), false, true )
			guiGridListSetItemText ( xrPackageFrame.resLst, row, 5, tostring ( meshLodDist ), false, true )
		else
			guiGridListSetItemText ( xrPackageFrame.resLst, row, 4, "", false, false )
			guiGridListSetItemText ( xrPackageFrame.resLst, row, 5, "", false, false )
		end
		
		xrPackageFrame.indexed [ i ] = mesh
	end
	
	xrPackageFrame.currentPkg = pkgName
end

function xrPackageFrame.onPackageStart ( pkg )
	local pkgName = getResourceName ( pkg )
	local index = guiComboBoxAddItem ( xrPackageFrame.packageCombo, pkgName )
	if guiComboBoxGetSelected ( xrPackageFrame.packageCombo ) == -1 then
		xrPackageFrame.loadPackage ( pkgName )
	end
end

function xrPackageFrame.onPackageStop ( pkg )
	local pkgName = getResourceName ( pkg )
	
	-- Находим и удаляем пакет из списка
	local index = 0
	local item = guiComboBoxGetItemText ( xrPackageFrame.packageCombo, index )
	while item ~= false do
		if item == pkgName then
			guiComboBoxRemoveItem ( xrPackageFrame.packageCombo, index )
			break
		end
		
		index = index + 1
		item = guiComboBoxGetItemText ( xrPackageFrame.packageCombo, index )
	end
	
	-- Выделяем первый элемент если он есть
	item = guiComboBoxGetItemText ( xrPackageFrame.packageCombo, 0 )
	if item and item ~= "" then
		guiComboBoxSetSelected ( xrPackageFrame.packageCombo, 0 )
		xrPackageFrame.loadPackage ( item )
	end
end

--[[
	xrEditFrame
]]
xrEditErrors = {
	[ 1 ] = "Должен быть числом!",
	[ 2 ] = "Такая модель уже объявлена!",
	[ 3 ] = "Должно быть не менее 3х символов!",
	[ 4 ] = "DFF не найден!",
	[ 5 ] = "COL не найден!",
	[ 6 ] = "TXD не найден!",
	[ 7 ] = "TXT или XML не найден!",
	[ 8 ] = "Модель не была добавлена!",
	[ 9 ] = "Модель LOD не найдена!"
}

xrEditFrame = {
	info = "Введите в соответствуюшие поля настройки модели"
}

function xrEditFrame.open ( wnd, mesh )
	if mesh ~= true and isElement ( mesh ) ~= true then
		outputDebugString ( "Неверный аргумент фрейма xrEditFrame (" .. tostring ( mesh ) .. ")", 3 )
		return
	end

	xrEditFrame.mesh = mesh

	-- Model
	xrEditFrame.modelLbl = guiCreateLabel ( 25, 70, 270, 20, "Модель", false, wnd )
	setElementData ( xrEditFrame.modelLbl, "srcText", "Модель" )
	local meshModel = mesh == true and "" or getElementData ( mesh, "model", false )
	xrEditFrame.modelEdt = guiCreateEdit ( 25, 95, 150, 25, tostring ( meshModel ), false, wnd )
	setElementData ( xrEditFrame.modelEdt, "isnumber", true )
	
	-- Geometry
	xrEditFrame.geomLbl = guiCreateLabel ( 25, 140, 270, 20, "Файл геометрии", false, wnd )
	setElementData ( xrEditFrame.geomLbl, "srcText", "Файл геометрии" )
	local meshGeom = mesh == true and "" or getElementData ( mesh, "geom", false )
	xrEditFrame.geomEdt = guiCreateEdit ( 25, 165, 150, 25, tostring ( meshGeom ), false, wnd )
	setElementData ( xrEditFrame.geomEdt, "minlen", 3 )
	
	-- Texture
	xrEditFrame.texLbl = guiCreateLabel ( 25, 210, 270, 20, "Файл текстуры", false, wnd )
	setElementData ( xrEditFrame.texLbl, "srcText", "Файл текстуры" )
	local meshTex = mesh == true and "" or getElementData ( mesh, "tex", false )
	xrEditFrame.texEdt = guiCreateEdit ( 25, 235, 150, 25, tostring ( meshTex ), false, wnd )
	setElementData ( xrEditFrame.texEdt, "minlen", 3 )
	
	-- Lod model
	xrEditFrame.lodLbl = guiCreateLabel ( 25, 280, 270, 20, "Модель LOD", false, wnd )
	setElementData ( xrEditFrame.lodLbl, "srcText", "Файл текстуры" )
	local meshLod = ""
	if isElement ( mesh ) then
		meshLod = getElementData ( mesh, "lod", false ) or ""
	end
	xrEditFrame.lodEdt = guiCreateEdit ( 25, 305, 150, 25, tostring ( meshLod ), false, wnd )
	setElementData ( xrEditFrame.lodEdt, "minlen", 4 )
	
	-- Сохраняем значения по умолчанию только при редактировании
	if isElement ( mesh ) then
		xrEditFrame.defaultValues = { }
	
		for i, edit in ipairs ( getElementsByType ( "gui-edit", xrLoaderMenu.wnd ) ) do
			xrEditFrame.defaultValues [ i ] = guiGetText ( edit )
		end
	end
	
	xrEditFrame.applyBtn = guiCreateButton ( 10, 510, 100, 25, "Применить", false, wnd )
	addEventHandler ( "onClientGUIClick", xrEditFrame.applyBtn, xrEditFrame.onButtonClick, false )
	xrPackageFrame.cancelBtn = guiCreateButton ( 120, 510, 100, 25, "Отмена", false, wnd )
	addEventHandler ( "onClientGUIClick", xrPackageFrame.cancelBtn, xrEditFrame.onButtonClick, false )
end

function xrEditFrame.close ( )
	xrEditFrame.mesh = nil
	xrEditFrame.defaultValues = nil
end

function xrEditFrame.onButtonClick ( )
	if source == xrEditFrame.applyBtn then
		local labels = getElementsByType ( "gui-label", xrLoaderMenu.wnd )
		-- Возвращаем стандартные цвета и имена
		for i, lbl in ipairs ( labels ) do
			-- Пропускаем info лейбл
			if i > 2 then
				guiLabelSetColor ( lbl, 255, 255, 255 )
				local defaultText = getElementData ( lbl, "srcText", false )
				if defaultText then
					guiSetText ( lbl, defaultText )
				end
			end
		end
		
		local ok = true
		local properties = { }
		for i, edit in ipairs ( getElementsByType ( "gui-edit", xrLoaderMenu.wnd ) ) do
			local value = guiGetText ( edit )
			if guiGetEnabled ( edit ) and ( xrEditFrame.mesh == true or value ~= xrEditFrame.defaultValues [ i ] ) then
				local minlen = getElementData ( edit, "minlen", false )
				if minlen and value:len ( ) < minlen then
					ok = false
					guiLabelSetColor ( labels [ i + 2 ], 255, 0, 0 )
					guiSetText ( labels [ i + 2 ], xrEditErrors [ 3 ] )
				end
				
				local isnumber = getElementData ( edit, "isnumber", false )
				if isnumber then
					value = tonumber ( value )
					if value == nil then
						ok = false
						guiLabelSetColor ( labels [ i + 2 ], 255, 0, 0 )
						guiSetText ( labels [ i + 2 ], xrEditErrors [ 1 ] )
					end
				end
				
				table.insert ( properties, {
					i, value
				} )
			end
		end
		
		if ok then
			if #properties > 0 then
				addEventHandler ( "onClientMeshResponse", root, xrEditFrame.onMeshResponse )
				-- Если редактируем
				if isElement ( xrEditFrame.mesh ) then
					triggerServerEvent ( "doMeshChangeProperty", xrEditFrame.mesh, properties )
					
				-- Если создаем
				else
					if xrPackageFrame.currentPkg then
						local pkgRoot = getElementByID ( xrPackageFrame.currentPkg )
						triggerServerEvent ( "doCreateMesh", pkgRoot, properties )
					else
						outputDebugString ( "Не было найдено пакета", 3 )
					end
				end
			else
				xrLoaderMenu.loadFrame ( xrPackageFrame )
			end
		else
			outputChatBox ( "Обнаружены ошибки заполнения настроек", 255, 0, 0 )
		end
	else
		xrLoaderMenu.loadFrame ( xrPackageFrame )
	end
end

function xrEditFrame.onMeshResponse ( errors )
	if errors then
		local labels = getElementsByType ( "gui-label", xrLoaderMenu.wnd )
		for _, error in ipairs ( errors ) do
			guiLabelSetColor ( labels [ error [ 1 ] + 2 ], 255, 0, 0 )
			guiSetText ( labels [ error [ 1 ] + 2 ], xrEditErrors [ error [ 2 ] ] )
		end
		
		outputChatBox ( "Обнаружены ошибки заполнения настроек", 255, 0, 0 )
	else
		xrLoaderMenu.loadFrame ( xrPackageFrame )
	end
	
	removeEventHandler ( "onClientMeshResponse", root, xrEditFrame.onMeshResponse )
end

--[[
	xrLoaderMenu
]]
xrLoaderMenu = {
	width = 500,
	height = 575
}

function xrLoaderMenu.open ( )
	if xrLoaderMenu.opened then
		return
	end
	
	local sw, sh = guiGetScreenSize ( )
	
	xrLoaderMenu.wnd = guiCreateWindow ( sw / 2 - xrLoaderMenu.width / 2, sh / 2 - xrLoaderMenu.height / 2, xrLoaderMenu.width, xrLoaderMenu.height, "X-Ray Resource Loader", false )
	
	-- Информация
	xrLoaderMenu.infoLbl = guiCreateLabel ( 10, 30, xrLoaderMenu.width - 20, 50, "", false, xrLoaderMenu.wnd )
	setElementData ( xrLoaderMenu.infoLbl, "native", true )
	guiLabelSetHorizontalAlign ( xrLoaderMenu.infoLbl, "left", true )
	
	-- Информация
	xrLoaderMenu.infoLbl2 = guiCreateLabel ( 10, 545, xrLoaderMenu.width - 20, 50, "Кликните за пределами окна чтобы закрыть его.", false, xrLoaderMenu.wnd )
	setElementData ( xrLoaderMenu.infoLbl2, "native", true )
	
	-- Грузим первый фрейм
	xrLoaderMenu.loadFrame ( xrPackageFrame )
	
	showCursor ( true )
	guiSetInputMode ( "no_binds" )
	
	addEventHandler ( "onClientClick", root, xrLoaderMenu.onClick, false )
	
	xrLoaderMenu.opened = true
end

function xrLoaderMenu.close ( )
	if xrLoaderMenu.opened then
		destroyElement ( xrLoaderMenu.wnd )
		
		showCursor ( false )
		guiSetInputMode ( "allow_binds" )
		
		removeEventHandler ( "onClientClick", root, xrLoaderMenu.onClick )
		
		xrLoaderMenu.frame = nil
	
		xrLoaderMenu.opened = nil
	end
end

function xrLoaderMenu.onClick ( button, state, x, y )
	if state ~= "down" then
		return
	end
	
	local wx, wy = guiGetPosition ( xrLoaderMenu.wnd, false )
	local wwidth, wheight = guiGetSize ( xrLoaderMenu.wnd, false )
	if _withinRectangle ( x, y, wx, wy, wwidth, wheight ) ~= true then
		xrLoaderMenu.close ( )
	end
end

function xrLoaderMenu.onPackageStart ( pkg )
	if xrLoaderMenu.frame and xrLoaderMenu.frame.onPackageStart ~= nil then
		xrLoaderMenu.frame.onPackageStart ( pkg )
	end
end

function xrLoaderMenu.onPackageStop ( pkg )
	if xrLoaderMenu.frame and xrLoaderMenu.frame.onPackageStop ~= nil then
		xrLoaderMenu.frame.onPackageStop ( pkg )
	end
end

function xrLoaderMenu.loadFrame ( frame, ... )
	if frame ~= xrLoaderMenu.frame then
		if xrLoaderMenu.frame then
			for _, guielement in ipairs ( getElementChildren ( xrLoaderMenu.wnd ) ) do
				if getElementData ( guielement, "native", false ) ~= true then
					destroyElement ( guielement )
				end
			end
			xrLoaderMenu.frame.close ( )
		end
	
		guiSetText ( xrLoaderMenu.infoLbl, frame.info )
		frame.open ( xrLoaderMenu.wnd, ... )
		xrLoaderMenu.frame = frame
	end
end