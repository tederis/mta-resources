G_SECTOR_DELAY = 3000

function getElementRoot ( element )
	local parent = getElementParent ( element )
	repeat
		parent = getElementParent ( parent )
	until parent ~= false
	return parent
end

DEBUG_MODE = true
SHOW_TIMING = false

LOAD_ASYNC = true

--[[
	xrUsableList
]]
USABLE_SPLASH = 1
USABLE_EXISTS = 2
USABLE_HIDING = 3

xrUsableList = { 
	items = { },
	itemsNum = 0,
	keepTime = 4000
}

function xrUsableList.insert ( key )
	local now = getTickCount ( )
	local item = xrUsableList.items [ key ]
	if item then
		item.state = USABLE_SPLASH
		item.time = now
	else
		xrUsableList.items [ key ] = {
			state = USABLE_SPLASH,
			time = now
		}
		
		xrUsableList.itemsNum = xrUsableList.itemsNum + 1
	end
end

function xrUsableList.remove ( key )
	local item = xrUsableList.items [ key ]
	if item then
		item.state = USABLE_HIDING
		item.time = getTickCount ( )
	end
end

function xrUsableList.getItems ( )
	local now = getTickCount ( )
	local items = { }
	
	for key, item in pairs ( xrUsableList.items ) do
		if item.time ~= nil and now - item.time > xrUsableList.keepTime then
			if item.state == USABLE_SPLASH then
				item.state = USABLE_EXISTS
				item.time = nil
				
				table.insert ( items, { key, USABLE_EXISTS } )
			elseif item.state == USABLE_HIDING then
				xrUsableList.items [ key ] = nil
				xrUsableList.itemsNum = xrUsableList.itemsNum - 1
			end
		else
			table.insert ( items, { key, item.state } )
		end
	end
	
	return items
end

function xrUsableList.clear ( )
	xrUsableList.items = { }
	xrUsableList.itemsNum = 0
end

--[[
	xrLoader
]]
MESH_DEFAULT = 1 -- Модель просто существует
MESH_READY = 2 -- Модель готова к замене
MESH_DOWNLOADING = 3 -- Модель передается
MESH_LOADING = 4 -- Модель загружается(возможно асинхронно)
MESH_REPLACED = 5 -- Модель заменена и находится в памяти игры

xrLoader = { 
	packages = { },
	meshState = { },
	models = { },
	loading = { }
}

xrSupportedTypes = {
	[ "object" ] = true,
	[ "ped" ] = true,
	[ "vehicle" ] = true
}

function xrLoader.init ( )
	addEvent ( "onClientMeshResponse", true )
	addEvent ( "onClientMeshDownloadComplete", false )
	addEvent ( "onClientMeshCreated", true )
	addEvent ( "onClientEditorTargetChange", false ) -- Интеграция с TCT
	addEvent ( "onClientElementCreate", true ) -- Интеграция с TCT
	
	addEventHandler ( "onClientResourceStart", root, xrLoader.onPackageStart )
	addEventHandler ( "onClientResourceStop", root, xrLoader.onPackageStop )
	addEventHandler ( "onClientRender", root, xrLoader.onRender, false )
	addEventHandler ( "onClientMeshDownloadComplete", root, xrLoader.onMeshDownloadComplete )
	addEventHandler ( "onClientMeshCreated", root, xrLoader.onMeshCreated )
	addEventHandler ( "onClientEditorTargetChange", root, xrLoader.onEditorTargetChange ) -- Интеграция с TCT
	addEventHandler ( "onClientElementCreate", root, xrLoader.onEditorElementCreate ) -- Интеграция с TCT
	addEventHandler ( "onClientElementDestroy", root, xrLoader.onElementDestroy )
	--addEventHandler ( "onClientElementStreamIn", root, xrLoader.onElementStreamIn )
	--addEventHandler ( "onClientElementStreamOut", root, xrLoader.onElementStreamOut )
	
	-- Шейдер статического освещения
	xrLoader.staticShader = dxCreateShader ( "shader.fx" )
	
	
	-- Ищем корни пакетов
	for _, map in ipairs ( getElementsByType ( "map" ) ) do
		if getElementID ( map ) == "meshes.map" then
			local pkgRoot = getElementParent ( map )
			local pkgName = getElementID ( pkgRoot )
			table.insert ( xrLoader.packages, pkgName )
		end
	end
	
	--setTimer ( xrLoader.onUpdate, 50, 0 )
	
	xrStreamerWorld.init ( )
	
	local numOfElements = 0
	local elements = getElementsByType ( "object" )
	for _, element in ipairs ( elements ) do
		local elementModel = getElementModel ( element )
		if isElementLocal ( element ) ~= true and getElementByID ( "m" .. elementModel ) ~= false and xrStreamerWorld.insertElement ( element ) then
			numOfElements = numOfElements + 1
		end
	end
	outputDebugString ( "Выполнена декларация " .. numOfElements .. " объектов из " .. #elements )
	
	addCommandHandler ( "loadermanager", xrLoaderMenu.open )
	addCommandHandler ( "xrsectordelay",
		function ( _, cmd )
			cmd = tonumber ( cmd )
			if cmd then
				G_SECTOR_DELAY = math.max ( cmd, 0 )
				outputChatBox ( "Теперь параметр xrsectordelay задан на " .. G_SECTOR_DELAY )
			else
				outputChatBox ( "Неверный синтаксис. Используйте /xrsectordelay 0-600000" )
			end
		end
	)
	
	--xrLoader.toggleDebugMap ( true )
	
	-- Применяем тип для поиска модели в списке редактора
	local editorResource = getResourceFromName ( "wbo_flowtest_cr" )
	if editorResource ~= false and getResourceState ( editorResource ) == "running" then
		exports.wbo_flowtest_cr:applyModelLookupType ( "mesh" )
		outputDebugString ( "Mesh type has been applied" )
	end
	
	engineSetAsynchronousLoading ( true, true )
end

function xrLoader.isPackage ( pkg )
	if getResourceName ( pkg ) ~= false then
		return xrLoader.getPackageMapRoot ( pkg ) ~= nil
	end
	
	return false
end

function xrLoader.getPackageMapRoot ( pkg )
	if getResourceName ( pkg ) ~= false then
		local children = getElementChildren ( getResourceRootElement ( pkg ), "map" )
		for _, child in ipairs ( children ) do
			if getElementID ( child ) == "meshes.map" then
				return child
			end
		end
	end
end

function xrLoader.onPackageStart ( pkg )
	-- Если ресурс это редактор, применяем тип для поиска
	if getResourceName ( pkg ) == "wbo_flowtest_cr" then
		exports.wbo_flowtest_cr:applyModelLookupType ( "mesh" )
		outputDebugString ( "Mesh type has been applied" )
	end

	if xrLoader.isPackage ( pkg ) then
		local pkgName = getResourceName ( pkg )
		local pkgMapRoot = xrLoader.getPackageMapRoot ( pkg )
		table.insert ( xrLoader.packages, pkgName ) -- Добавляем имя в список
		
		-- Отправляем событие в редактор ресурсов
		if xrLoaderMenu.opened then
			xrLoaderMenu.onPackageStart ( pkg )
		end
		
		-- Добавляем элементы в сектора
		local numOfElements = 0
		local elements = getElementsByType ( "object" )
		for _, element in ipairs ( elements ) do
			if isElementLocal ( element ) ~= true then
				local elementModel = getElementModel ( element )
				local mesh = getElementByID ( "m" .. elementModel )
				if mesh ~= false and getElementParent ( mesh ) == pkgMapRoot then
					if xrStreamerWorld.insertElement ( element ) then
						numOfElements = numOfElements + 1
					end
				end
			end
		end
		
		-- Форсим загрузку моделей в текущие сектора
		for _, mesh in ipairs ( getElementsByType ( "mesh", pkgRoot ) ) do
			for sector, _ in pairs ( xrStreamerWorld.activated ) do
				sector:forceMeshLoading ( mesh )
			end
		end
	
		
		outputDebugString ( "Выполнена декларация " .. numOfElements .. " объектов для пакета " .. pkgName )
	end
end

function xrLoader.onPackageStop ( pkg )
	if xrLoader.isPackage ( pkg ) then
		local pkgName = getResourceName ( pkg )
		local pkgRoot = getResourceRootElement ( pkg )
		local pkgMapRoot = xrLoader.getPackageMapRoot ( pkg )
	
		-- Удаляем пакет из списка
		for i, _pkgNm in ipairs ( xrLoader.packages ) do
			if _pkgNm == pkgName then
				table.remove ( xrLoader.packages, i )
				break
			end
		end
		
		-- Отправляем событие в редактор ресурсов
		if xrLoaderMenu.opened then
			xrLoaderMenu.onPackageStop ( pkg )
		end
		
		for _, mesh in ipairs ( getElementsByType ( "mesh", pkgRoot ) ) do
			for sector, _ in pairs ( xrStreamerWorld.activated ) do
				sector:forceMeshRestore ( mesh )
			end
			xrLoader.meshState [ mesh ] = nil
		end
		
		local numOfElements = 0
		local elements = getElementsByType ( "object" )
		for _, element in ipairs ( elements ) do
			if isElementLocal ( element ) ~= true then
				local elementModel = getElementModel ( element )
				local mesh = getElementByID ( "m" .. elementModel )
				if mesh ~= false and getElementParent ( mesh ) == pkgMapRoot then
					if xrStreamerWorld.removeElement ( element ) then
						numOfElements = numOfElements + 1
					end
				end
			end
		end

		outputDebugString ( "Успешно выгружено " .. numOfElements .. " элементов" )
		
		-- Удаляем все модели пакета из секторов
		--[[local sectorsNum = 0
		local unloadedSectors = { }
		
		for _, mesh in ipairs ( getElementsByType ( "mesh", pkgRoot ) ) do
			local model = tonumber (
				getElementData ( mesh, "model", false )
			)
			-- Ищем сектора занятые этой моделью
			local modelData = xrModelCollection.models [ model ]
			if modelData then
				for sector, _ in pairs ( modelData.sectors ) do
					if xrStreamerWorld.activated [ sector ] then
						sector:forceMeshRestore ( mesh )
					end
					sector.models [ model ] = nil -- Удаляем модель из сектора
					sectorsNum = sectorsNum + 1
					
					unloadedSectors [ sector._index ] = true
				end
			end
			xrModelCollection.models [ model ] = nil -- За ненадобностью удаляем данные модели
			xrLoader.meshState [ mesh ] = nil
		end
		
		-- Теперь удаляем элементы из таблицы
		local numOfElements = 0
		
		for _, element in ipairs ( getElementsByType ( "object" ) ) do
			local sector = xrStreamerWorld.elements [ element ] 
			if sector ~= nil and unloadedSectors [ sector ] then
				xrStreamerWorld.elements [ element ] = nil
				numOfElements = numOfElements + 1
			end
		end]]
		
		--outputDebugString ( "Успешно выгружено " .. sectorsNum .. " секторов и " .. numOfElements .. " элементов" )
	elseif pkg == resource then
		for _, mesh in ipairs ( getElementsByType ( "mesh" ) ) do
			for sector, _ in pairs ( xrStreamerWorld.activated ) do
				sector:forceMeshRestore ( mesh )
			end
			xrLoader.meshState [ mesh ] = nil
		end
	end
end

-- Вызывается когда в TCT выбран целевой временный элемент
function xrLoader.onEditorTargetChange ( )
	if getElementType ( source ) == "object" then
		local elementModel = getElementModel ( source )
		local mesh = getElementByID ( "m" .. elementModel )
		if mesh ~= false then
			-- Если временная модель еще не загружена, делаем это мануально
			local modelData = xrModelCollection.models [ elementModel ]
			if ( modelData == nil or modelData.refs == 0 ) and xrLoader.getMeshState ( mesh ) <= MESH_READY then
				xrLoader.loadMesh ( mesh )
			end
		end
		
		xrLoader.tempElement = source
	end
end

-- Вызывается когда в TCT создается новый элемент
function xrLoader.onEditorElementCreate ( )
	if isElementLocal ( source ) ~= true and getElementType ( source ) == "object" then
		local elementModel = getElementModel ( source )
		local mesh = getElementByID ( "m" .. elementModel )
		if mesh ~= false then
			local sector = xrStreamerWorld.insertElement ( source )
			if sector then
				-- Если объект создан на активном секторе, выполняем принудительную загрузку
				if xrStreamerWorld.activated [ sector ] then
					sector:forceMeshLoading ( mesh )
				end
			else
				outputDebugString ( "Элемент с моделью " .. elementModel .. " не был создан", 3 )
			end
		end
	end
end

-- Вызывается когда удаляется любой элемент
function xrLoader.onElementDestroy ( )
	if getElementType ( source ) == "object" then
		local elementModel = getElementModel ( source )
		local mesh = getElementByID ( "m" .. elementModel )
		if mesh then
			if source ~= xrLoader.tempElement then
				local sector = xrStreamerWorld.elements [ source ]
				if sector and xrStreamerWorld.activated [ sector ] and sector.models [ elementModel ] < 2 then
					sector:forceMeshRestore ( mesh )
				end
				xrStreamerWorld.removeElement ( source )
			else
				local modelData = xrModelCollection.models [ elementModel ]
				if ( modelData == nil or modelData.refs == 0 ) and xrLoader.getMeshState ( mesh ) >= MESH_LOADING then
					xrLoader.restoreMesh ( mesh )
				end
				xrLoader.tempElement = nil
			end
		end
	end
end

local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3
local ENV_SUNDIR = 4
local stateColors = {
	[ USABLE_SPLASH ] = tocolor ( 0, 255, 0 ),
	[ USABLE_EXISTS ] = tocolor ( 255, 255, 255 ),
	[ USABLE_HIDING ] = tocolor ( 255, 0, 0 )
}
local lastUpdateTime = getTickCount ( )
function xrLoader.onRender ( )
	local now = getTickCount ( )
	if now - lastUpdateTime > 5 then
		xrLoader.onUpdate ( )
		lastUpdateTime = now
	end
	
	-- Обновляем освещение
	local ambr, ambg, ambb = exports.xrskybox:getEnvValue ( ENV_AMBIENT )
	local hemir, hemig, hemib, hemia = exports.xrskybox:getEnvValue ( ENV_HEMI )
	local sunr, sung, sunb = exports.xrskybox:getEnvValue ( ENV_SUNCOLOR )
	local sunx, suny, sunz = exports.xrskybox:getEnvValue ( ENV_SUNDIR )
	
	dxSetShaderValue ( xrLoader.staticShader, "L_ambient", ambr, ambg, ambb )
	dxSetShaderValue ( xrLoader.staticShader, "L_hemi_color", hemir, hemig, hemib, hemia )
	dxSetShaderValue ( xrLoader.staticShader, "L_sun_color", sunr*0.4, sung*0.4, sunb*0.4 )
	dxSetShaderValue ( xrLoader.staticShader, "L_sun_dir_w", sunx, suny, sunz )
	
	local sw, sh = guiGetScreenSize ( )
	if #xrLoader.loading > 0 then
		dxDrawRectangle ( 0, 0, sw, sh, tocolor ( 0, 0, 0, 200 ) )
		dxDrawText ( "Идет загрузка мира...\n" .. getElementData ( xrLoader.loading [ 1 ].mesh, "geom", false ), 0, 0, sw, sh, tocolor ( 255, 255, 255 ), 2, "default", "center", "center" )
	end

	-- Рендерим дебаг-карту
	if xrLoader.debugMap and xrStreamerWorld.sector ~= nil then
		local size = math.floor ( math.min ( sw, sh ) * 0.8 )
		local mapx = sw / 2 - size / 2
		local mapy = sh / 2 - size / 2
		local elementSize = size / 3
	
		local surrounding = xrStreamerWorld.sector:getSurroundingSectors ( )
		
		-- Вычисляем положение игрока в центральном секторе
		local playerX, playerY = getElementPosition ( localPlayer )
		local playerRelX, playerRelY = ( playerX - xrStreamerWorld.sector.x ) / SECTOR_SIZE, ( xrStreamerWorld.sector.y - playerY ) / SECTOR_SIZE
		
		for i = 1, 9 do
			local tx = ( i - 1 ) % 3
			local ty = math.floor ( ( i - 1 ) / 3 )
			local x = mapx + elementSize*tx
			local y = mapy + elementSize*ty
			
			-- Рисуем квадрат сектора
			dxDrawRectangle ( x, y, elementSize, elementSize, tocolor ( 0, 0, 0, 200 ) )
			
			local sector
			if i == 5 then
				sector = xrStreamerWorld.sector
			else
				sector = i > 5 and surrounding [ i - 1 ] or surrounding [ i ]
			end
			
			if sector then
				-- Если сектор центральный рисуем в нем игрока
				if sector == xrStreamerWorld.sector then
					dxDrawImage ( x + playerRelX*elementSize - 20, y + playerRelY*elementSize - 20, 40, 40, "images/target.png" )
				end
			
				local elements = xrLoader.sectorElements [ sector ]
				if elements then
					for _, element in ipairs ( elements ) do
						local elementX, elementY = getElementPosition ( element )
						local relX, relY = ( elementX - sector.x ) / SECTOR_SIZE, ( sector.y - elementY ) / SECTOR_SIZE
					
						local model = getElementModel ( element )
						dxDrawRectangle ( x + relX*elementSize - 5, y + relY*elementSize - 5, 10, 10, xrLoader.debugModels [ model ].color )
					end
				end
			end
		end
		
		dxDrawText ( "Current sector " .. xrStreamerWorld.sector._index, mapx, mapy - 20 )
		
		local modelItems = xrUsableList.getItems ( )
		local maxItemsInColumn = math.floor ( size / 15 )
		local columns = math.ceil ( xrUsableList.itemsNum / maxItemsInColumn )
		local columnWidth = 150
		local itemsStart = 0
		for j = 1, columns do
			for i = 1, maxItemsInColumn do
				local index = itemsStart + i
				local item = modelItems [ index ]
				if item then
					dxDrawRectangle ( mapx + size + 20 + (j-1)*columnWidth, mapy + i*15, 10, 10, xrLoader.debugModels [ item [ 1 ] ].color )
			
					local sectorRefs = xrStreamerWorld.models [ item [ 1 ] ] or 0
					dxDrawText ( item [ 1 ] .. " (" .. sectorRefs .. " sectors)", mapx + size + 20 + 15 + (j-1)*columnWidth, mapy + i*15, 50, 15, stateColors [ item [ 2 ] ] )
				end
			end
			itemsStart = maxItemsInColumn
		end
	end
	
	
end

function xrLoader.onSectorStreamIn ( sector )
	if DEBUG_MODE and xrLoader.debugMap then
		local sectorElements = { }
	
		local elements = getElementsByType ( "object", root )
		for _, element in ipairs ( elements ) do
			if isElementLocal ( element ) ~= true and xrStreamerWorld.elements [ element ] == sector then
				table.insert ( sectorElements, element )
				
				local model = getElementModel ( element )
				if xrLoader.debugModels [ model ] == nil then
					xrLoader.debugModels [ model ] = {
						color = tocolor ( math.random ( 0, 255 ), math.random ( 0, 255 ), math.random ( 0, 255 ) )
					}
				end
			end
		end
		
		xrLoader.sectorElements [ sector ] = sectorElements
	end
end

function xrLoader.onSectorStreamOut ( sector )
	if DEBUG_MODE and xrLoader.debugMap then
		xrLoader.sectorElements [ sector ] = nil
	end
end

function xrLoader.onElementStreamIn ( )
	local model = getElementModel ( source )
	-- Создаем шейдер и применяем
	local mesh = getElementByID ( "m" .. model )
	if isElement ( mesh ) and xrLoader.meshState [ mesh ] == MESH_REPLACED then
		local shader = getElementData ( mesh, "shader", false )
		if isElement ( shader ) then
			engineApplyShaderToWorldTexture ( shader, "*", source, false )
			outputChatBox("Shader applied")
		else
			outputDebugString ( "Шейдера для " .. model .. " не существует!", 3 )
		end
	end
end

function xrLoader.onElementStreamOut ( )
	local model = getElementModel ( source )
	-- Создаем шейдер и применяем
	local mesh = getElementByID ( "m" .. model )
	if isElement ( mesh ) and xrLoader.meshState [ mesh ] == MESH_REPLACED then
		local shader = getElementData ( mesh, "shader", false )
		if isElement ( shader ) then
			engineRemoveShaderFromWorldTexture ( shader, "*", source )
			outputChatBox("Removed applied")
		else
			outputDebugString ( "Шейдера для " .. model .. " не существует!", 3 )
		end
	end
end

function xrLoader.onMeshCreated ( )
	-- Находим все элементы с данной моделью и добавляем их в стример
	local numOfElements = 0
	local meshModel = tonumber ( 
		getElementData ( source, "model" )
	)
	local elements = getElementsByType ( "object" )
	for _, element in ipairs ( elements ) do
		if isElementLocal ( element ) ~= true then
			local elementModel = getElementModel ( element )
			if elementModel == meshModel and xrStreamerWorld.insertElement ( element ) then
				numOfElements = numOfElements + 1
			end
		end
	end
	
	-- Ищем модель среди активных секторов и загружаем
	for sector, _ in pairs ( xrStreamerWorld.activated ) do
		sector:forceMeshLoading ( source )
	end
	
	if DEBUG_MODE then
		outputDebugString ( "Выполнена декларация " .. numOfElements .. " объектов для модели " .. meshModel )
	end
end

function xrLoader.toggleDebugMap ( enabled )
	if xrLoader.debugMap ~= enabled then
		xrLoader.debugMap = enabled
		
		if enabled then
			-- Подготовим таблицу
			xrLoader.sectorElements = { }
			xrLoader.debugModels = { }
			
			local elements = getElementsByType ( "object", root )
			for _, element in ipairs ( elements ) do
				if isElementLocal ( element ) ~= true then
					local sector = xrStreamerWorld.elements [ element ]
					if sector and xrStreamerWorld.activated [ sector ] then
						local sectorElements = xrLoader.sectorElements [ sector ]
						if sectorElements then
							table.insert ( sectorElements, element )
						else
							xrLoader.sectorElements [ sector ] = { element }
						end
					
						local model = getElementModel ( element )
						if xrLoader.debugModels [ model ] == nil then
							xrLoader.debugModels [ model ] = {
								color = tocolor ( math.random ( 0, 255 ), math.random ( 0, 255 ), math.random ( 0, 255 ) )
							}
						end
					end
				end
			end
		else
			xrLoader.sectorElements = nil
			xrLoader.debugModels = nil
		end
	end
end

function xrLoader.getMeshState ( mesh )
	return xrLoader.meshState [ mesh ] or MESH_DEFAULT
end

function xrLoader.loadMesh ( mesh )
	local state = xrLoader.getMeshState ( mesh )
	-- Скачиваем модель
	if state == MESH_DEFAULT then
		local meshRoot = getElementRoot ( mesh )
		if meshRoot and getElementType ( meshRoot ) == "resource" then
			local pkgName = getElementID ( meshRoot )
			local meshGeom = getElementData ( mesh, "geom", false )
			local meshTex = getElementData ( mesh, "tex", false )
			if meshTex == false then
				meshTex = meshGeom
			end
			local hasXml = getElementData ( mesh, "hasxml", false ) == "true"
			-- Если все файлы на месте - говорим движку о загрузке
			local xmlExists = hasXml ~= true or xrLoader.packageFileExists ( pkgName, meshGeom .. ".xml" )
			if xrLoader.packageFileExists ( pkgName, meshGeom .. ".dff" ) and 
			   xrLoader.packageFileExists ( pkgName, meshGeom .. ".col" ) and
			   xrLoader.packageFileExists ( pkgName, meshTex .. ".txd" ) and xmlExists then

				xrLoader.meshState [ mesh ] = MESH_READY
				xrLoader.replaceMesh ( mesh )
			
			-- В противном случае скачиваем их
			else
				xrLoader.meshState [ mesh ] = MESH_DOWNLOADING
				if triggerEvent ( "doClientMeshDownload", mesh ) ~= true then
					xrLoader.meshState [ mesh ] = nil
					outputDebugString ( "Модель не может быть отправлена", 3 )
				end
			end
		end
		
	-- Грузим модель
	elseif state == MESH_READY then
		xrLoader.replaceMesh ( mesh )
	else
		outputDebugString ( "Запрещенное состояние " .. tostring ( state ), 2 )
	end
	
	if DEBUG_MODE then
		local model = tonumber ( 
			getElementData ( mesh, "model", false )
		)
		xrUsableList.insert ( model )
	end
end

function xrLoader.onMeshDownloadComplete ( )
	local meshModel = tonumber (
		getElementData ( source, "model", false )
	)
	
	xrLoader.meshState [ source ] = MESH_READY
	
	outputDebugString ( "Модель " .. meshModel .. " успешно передана" )
	
	-- Если в данный момент модель еще нужна, то загружаем ее в память
	local modelData = xrModelCollection.models [ meshModel ]
	if modelData and modelData.refs > 0 then
		xrLoader.replaceMesh ( source )
	end
end

function xrLoader.onUpdate ( )
	if #xrLoader.loading == 0 then
		return
	end
	
	-- Берем валидный мэш
	local data = xrLoader.loading [ 1 ]
	if xrLoader.getMeshState ( data.mesh ) ~= MESH_LOADING then
		outputDebugString ( "Мэш не готов к загрузке!", 2 )
		return
	end
	
	local model = tonumber ( 
		getElementData ( data.mesh, "model", false )
	)
	local meshGeom = getElementData ( data.mesh, "geom", false )
	local meshTex = getElementData ( data.mesh, "tex", false )
	if meshTex == false then
		meshTex = meshGeom
	end
	local hasXml = getElementData ( data.mesh, "hasxml", false ) == "true"
	local isInternalLighting = getElementData ( data.mesh, "internal", false ) == "true"
	
	-- Загружаем TXD
	if data.step == 1 then
		if xrLoader.models [ meshTex .. ".txd" ] == nil then
			local txd = engineLoadTXD ( ":" .. data.pkgName .. "/models/" .. meshTex .. ".txd", true )
			if txd then
				xrLoader.models [ meshTex .. ".txd" ] = {
					data = txd,
					ref = 0
				}
			else
				outputDebugString ( "Ошибка при загрузке *.txd файла", 3 )
			end
		end
		
	-- Импортируем TXD в модель
	elseif data.step == 2 then
		local modelRes = xrLoader.models [ meshTex .. ".txd" ]
		if modelRes then
			engineImportTXD ( modelRes.data, model )
			modelRes.ref = modelRes.ref + 1
		else
			outputDebugString ( "Ошибка при загрузке *.txd файла", 3 )
		end
		
	-- Загружаем COL
	elseif data.step == 3 then
		if xrLoader.models [ meshGeom .. ".col" ] == nil then
			local col = engineLoadCOL ( ":" .. data.pkgName .. "/models/" .. meshGeom .. ".col" )
			if col then
				xrLoader.models [ meshGeom .. ".col" ] = col
			else
				outputDebugString ( "Ошибка при загрузке *.col файла", 3 )
			end
		end
			
	-- Заменяем COL
	elseif data.step == 4 then
		local modelRes = xrLoader.models [ meshGeom .. ".col" ]
		if modelRes then
			engineReplaceCOL ( modelRes, model )
		else
			outputDebugString ( "Ошибка при загрузке *.col файла", 3 )
		end
			
	-- Загружаем и заменяем DFF
	elseif data.step == 5 then
		if xrLoader.models [ meshGeom .. ".dff" ] == nil then
			local dff = engineLoadDFF ( ":" .. data.pkgName .. "/models/" .. meshGeom .. ".dff" )
			if dff then
				local alpha = getElementData ( data.mesh, "alpha" ) == "true"
				engineReplaceModel ( dff, model, alpha )
				xrLoader.models [ meshGeom .. ".dff" ] = dff
			else
				outputDebugString ( "Ошибка при загрузке *.dff файла", 3 )
			end
		end
			
	-- Загружаем шейдер
	elseif data.step == 6 then
		-- Создаем шейдер и запоминаем его для дескриптора модели
		if isElement ( getElementData ( data.mesh, "shader", false ) ) ~= true then
			if isInternalLighting then
				local shader = exports["mapdff"]:xrDefineInternal ( )
				setElementData ( data.mesh, "shader", shader, false )
			else
				local shader = exports["mapdff"]:xrDefineMeshShader ( data.mesh )
				setElementData ( data.mesh, "shader", shader, false )
			end
		else
			outputDebugString ( "Шейдер для " .. model .. " уже создан!", 3 )
		end
			
	-- Применяем шейдер
	elseif data.step == 7 then
		local objects = getElementsByType ( "object", root )
		for _, object in ipairs ( objects ) do
			if getElementModel ( object ) == model then
				local shader = getElementData ( data.mesh, "shader", false )
				if isElement ( shader ) then
					engineApplyShaderToWorldTexture ( shader, "*", object, false )
					
					if hasXml then
						local xml = xmlLoadFile ( ":" .. data.pkgName .. "/models/" .. meshGeom .. ".xml" )
						if xml then
							for _, node in ipairs ( xmlNodeGetChildren ( xml ) ) do
								local name = xmlNodeGetAttribute ( node, "name" )
								engineRemoveShaderFromWorldTexture ( shader, name, object )
								engineApplyShaderToWorldTexture ( xrLoader.staticShader, name, object, false )
							end
							
							xmlUnloadFile ( xml )
						else
							outputDebugString ( "Не был найден XML для модели " .. meshGeom, 2 )
						end
					end
				else
					outputDebugString ( "Шейдера для " .. model .. " не существует!", 3 )
				end
			end
		end
		
		xrLoader.meshState [ data.mesh ] = MESH_REPLACED
		table.remove ( xrLoader.loading, 1 )
			
		outputDebugString ( "Модель " .. model .. " загружена в игру" )
			
		return
	end
	data.step = data.step + 1
end

function xrLoader.getMeshLoader ( mesh )
	for _, data in ipairs ( xrLoader.loading ) do
		if data.mesh == mesh then
			return data
		end
	end
	return false
end

function xrLoader.loadMeshInOrder ( mesh, pkgName )
	if xrLoader.getMeshLoader ( mesh ) == false then
		local meshGeom = getElementData ( mesh, "geom", false )
		-- Если мэш является лодом - вставляем его в начало очереди
		if meshGeom:find ( "_lod" ) then
			-- Если в данный момент очередь пуста или первый элемент ожидает загрузки - вставляем мэш в начало очереди
			if #xrLoader.loading == 0 or xrLoader.loading [ 1 ].step == 1 then
				table.insert ( xrLoader.loading, 1, { mesh = mesh, step = 1, pkgName = pkgName } )

			-- В противном случае чтобы не сломать загрузку первого мэша - вставляем прямо за ним
			else
				table.insert ( xrLoader.loading, 2, { mesh = mesh, step = 1, pkgName = pkgName } )
			end
		else
			table.insert ( xrLoader.loading, {
				mesh = mesh,
				step = 1,
				pkgName = pkgName
			} )
		end
	end
end

function xrLoader.destroyMeshLoader ( mesh )
	for i, data in ipairs ( xrLoader.loading ) do
		if data.mesh == mesh then
			table.remove ( xrLoader.loading, i )
			return true
		end
	end
	return false
end

function xrLoader.replaceMesh ( mesh )
	local state = xrLoader.meshState [ mesh ]
	if state ~= MESH_READY then
		return
	end
	
	local meshRoot = getElementRoot ( mesh )
	if meshRoot and getElementType ( meshRoot ) == "resource" then
		local pkgName = getElementID ( meshRoot )
	
		local model = tonumber ( 
			getElementData ( mesh, "model", false )
		)
		local meshGeom = getElementData ( mesh, "geom", false )
		local meshTex = getElementData ( mesh, "tex", false )
		if meshTex == false then
			meshTex = meshGeom
		end
		
		engineSetModelLODDistance ( model, 100 )
		
		xrLoader.meshState [ mesh ] = MESH_LOADING
	
		if LOAD_ASYNC then
			xrLoader.loadMeshInOrder ( mesh, pkgName )
		else
			-- TXD
			local now = getTickCount ( )
			local modelRes = xrLoader.models [ meshTex .. ".txd" ]
			if modelRes then
				engineImportTXD ( modelRes.data, model )
				modelRes.ref = modelRes.ref + 1
			
				if SHOW_TIMING then
					outputDebugString ( "TXD Import " .. getTickCount ( ) - now .. " msec(" .. meshTex .. ")"  )
				end
			else
				local txd = engineLoadTXD ( ":" .. pkgName .. "/models/" .. meshTex .. ".txd", true )
				if txd then
					xrLoader.models [ meshTex .. ".txd" ] = {
						data = txd,
						ref = 1
					}
				
					engineImportTXD ( txd, model )
				
					if SHOW_TIMING then
						outputDebugString ( "TXD Load and import " .. getTickCount ( ) - now .. " msec(" .. meshTex .. ")"  )
					end
				else
					outputDebugString ( "Ошибка при загрузке *.txd файла", 3 )
				end
			end
		
			-- COL
			now = getTickCount ( )
			local col = engineLoadCOL ( ":" .. pkgName .. "/models/" .. meshGeom .. ".col" )
			if col then
				engineReplaceCOL ( col, model )
				xrLoader.models [ meshGeom .. ".col" ] = col
			
				if SHOW_TIMING then
					outputDebugString ( "COL Load and replace " .. getTickCount ( ) - now .. " msec(" .. meshGeom .. ")"  )
				end
			else
				outputDebugString ( "Ошибка при загрузке *.col файла", 3 )
			end
		
			-- DFF
			now = getTickCount ( )
			local dff = engineLoadDFF ( ":" .. pkgName .. "/models/" .. meshGeom .. ".dff" )
			if dff then
				local alpha = getElementData ( mesh, "alpha" ) == "true"
				engineReplaceModel ( dff, model, alpha )
				xrLoader.models [ meshGeom .. ".dff" ] = dff
			
				if SHOW_TIMING then
					outputDebugString ( "DFF Load and replace " .. getTickCount ( ) - now .. " msec(" .. meshGeom .. ")" )
				end
			else
				outputDebugString ( "Ошибка при загрузке *.dff файла", 3 )
			end
			
			-- Создаем шейдер и запоминаем его для дескриптора модели
			if isElement ( getElementData ( mesh, "shader", false ) ) ~= true then
				local shader = exports["mapdff"]:xrDefineMeshShader ( mesh )
				setElementData ( mesh, "shader", shader, false )
			else
				outputDebugString ( "Шейдер для " .. model .. " уже создан!", 3 )
			end
		
			xrLoader.meshState [ mesh ] = MESH_REPLACED
			
			outputDebugString ( "Модель " .. model .. " загружена в игру" )
		end
		
		return true
	else
		outputDebugString ( "Не было найдено дерево", 3 )
	end
end

function xrLoader.restoreMesh ( mesh )
	if xrLoader.getMeshState ( mesh ) < MESH_LOADING then
		return
	end
	
	local model = tonumber ( 
		getElementData ( mesh, "model", false )
	)
	local meshGeom = getElementData ( mesh, "geom", false )
	local meshTex = getElementData ( mesh, "tex", false )
	if meshTex == false then
		meshTex = meshGeom
	end
	
	local now = getTickCount ( )
	
	local loader = xrLoader.getMeshLoader ( mesh )
	if loader and LOAD_ASYNC then
		if loader.step > 1 then
			local modelRes = xrLoader.models [ meshTex .. ".txd" ]
			if modelRes then
				modelRes.ref = modelRes.ref - 1 -- Декремент ссылок
				-- Если никто больше не обращается к текстуре, удаляем ее
				if modelRes.ref < 1 then
					if isElement ( modelRes.data ) then
						destroyElement ( modelRes.data )
					end
					xrLoader.models [ meshTex .. ".txd" ] = nil
				end
			end
		end
		
		if loader.step > 3 then
			if loader.step > 4 then
				engineRestoreCOL ( model )
			end
			
			local col = xrLoader.models [ meshGeom .. ".col" ]
			if col then
				if isElement ( col ) then
					destroyElement ( col )
				end
				xrLoader.models [ meshGeom .. ".col" ] = nil
			end
		end
		
		if loader.step > 5 then
			engineRestoreModel ( model )
	
			local dff = xrLoader.models [ meshGeom .. ".dff" ]
			if dff then
				if isElement ( dff ) then
					destroyElement ( dff )
				end
				xrLoader.models [ meshGeom .. ".dff" ] = nil
			end
		end
		
		if loader.step > 6 then
			local shader = getElementData ( mesh, "shader", false )
			if isElement ( shader ) then
				exports["mapdff"]:xrDestroyMeshShader ( mesh )
				setElementData ( mesh, "shader", false, false )
			else
				outputDebugString ( "Шейдера для " .. model .. " не существует!", 3 )
			end
		end
		
		xrLoader.destroyMeshLoader ( mesh )
	else
		-- TXD
		local modelRes = xrLoader.models [ meshTex .. ".txd" ]
		if modelRes then
			modelRes.ref = modelRes.ref - 1 -- Декремент ссылок
			-- Если никто больше не обращается к текстуре, удаляем ее
			if modelRes.ref < 1 then
				if isElement ( modelRes.data ) then
					destroyElement ( modelRes.data )
				end
				xrLoader.models [ meshTex .. ".txd" ] = nil
			end
		end
	
		-- COL
		engineRestoreCOL ( model )
	
		local col = xrLoader.models [ meshGeom .. ".col" ]
		if col then
			if isElement ( col ) then
				destroyElement ( col )
			end
			xrLoader.models [ meshGeom .. ".col" ] = nil
		end
	
		-- DFF
		engineRestoreModel ( model )
	
		local dff = xrLoader.models [ meshGeom .. ".dff" ]
		if dff then
			if isElement ( dff ) then
				destroyElement ( dff )
			end
			xrLoader.models [ meshGeom .. ".dff" ] = nil
		end
		
		-- Удаляем шейдер
		local shader = getElementData ( mesh, "shader", false )
		if isElement ( shader ) then
			exports["mapdff"]:xrDestroyMeshShader ( mesh )
			setElementData ( mesh, "shader", false, false )
		else
			outputDebugString ( "Шейдера для " .. model .. " не существует!", 3 )
		end
	end
	
	xrLoader.meshState [ mesh ] = MESH_READY

	outputDebugString ( "Модель " .. model .. " выгружена из игры за " .. getTickCount ( ) - now .. " мс" )
	
	if DEBUG_MODE then
		xrUsableList.remove ( model )
	end
	
	return true
end

function xrLoader.packageFileExists ( pkgName, filename )
	return fileExists ( ":" .. pkgName .. "/models/" .. filename )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		xrLoader.init ( )
	end
, false )