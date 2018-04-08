local function fileStrHash ( str )
	return md5 ( str )
end

function getElementRoot ( element )
	local parent = getElementParent ( element )
	repeat
		parent = getElementParent ( parent )
	until parent ~= false
	return parent
end

--[[
	xrLoader
]]
xrLoader = {
	packages = { }, -- Ресурсы, которые содержат модели сталкера(пакеты)
	elementPackage = { }
}

xrLoaderErrors = {
	NOT_NUMBER = 1,
	MODEL_EXISTS = 2,
	INCORRECT_LEN = 3,
	DFF_NOTFOUND = 4,
	COL_NOTFOUND = 5,
	TXD_NOTFOUND = 6,
	TXT_NOTFOUND = 7,
	UNK_ERR = 8,
	
	LODM_NOTFOUND = 9
}

function xrLoader.init ( )
	addEventHandler ( "onResourceStart", root, xrLoader.onPackageStart )
	addEventHandler ( "onResourceStop", root, xrLoader.onPackageStop )

	-- Создаем пакеты
	for _, res in ipairs ( getResources ( ) ) do
		if res ~= resource then
			local packageName = getResourceInfo ( res, "package" )
			if packageName then
				local resState = getResourceState ( res )
				if resState ~= "failed to load" then
					local packageFiles = xrLoader.buildPackageFileList ( res )
				
					xrLoader.packages [ res ] = { 
						files = packageFiles
					}
				
					if resState == "running" then
						xrLoader.restorePackage ( res )
						
						local resRoot = getResourceRootElement ( res )
						xrLoader.elementPackage [ resRoot ] = res
					elseif resState == "loaded" then
						startResource ( res, true, false )
					end
					
					outputDebugString ( "Пакет " .. getResourceName ( res ) .. " загружен с " .. #packageFiles .. " файлами" )
				else
					outputChatBox ( "Пакет " .. getResourceName ( res ) .. " не может быть загружен (" .. getResourceLoadFailureReason ( res ) .. ")" )
				end
			end
		end
	end
	
	addEvent ( "doMeshChangeProperty", true )
	addEvent ( "doCreateMesh", true )
	addEvent ( "onPackageUpdate", true )
	
	addEventHandler ( "doMeshChangeProperty", root, xrLoader.onMeshChangeProperties )
	addEventHandler ( "doCreateMesh", root, xrLoader.onPackageCreateMesh )
	addEventHandler ( "onPackageUpdate", root, xrLoader.onPackageRefresh )
end

function xrLoader.restorePackage ( pkg )
	local modelsLookup = { } -- Для поиска дубликатов

	-- Восстановим id
	local restoredNum = 0
	local resRoot = getResourceRootElement ( pkg )
	for _, mesh in ipairs ( getElementsByType ( "mesh", resRoot ) ) do
		local model = getElementData ( mesh, "model", false )
		local meshId = getElementID ( mesh )
		if meshId == "" then
			meshId = "m" .. model
			setElementData ( mesh, "id", meshId )
			setElementID ( mesh, meshId )
			restoredNum = restoredNum + 1
		elseif getElementByID ( meshId, 1 ) then
			outputDebugString ( "Обнаружена копия модели с ID m" .. tostring ( model ) .. "!", 2 )
		end
		
		-- Ишем дубликаты модели
		if modelsLookup [ model ] then
			outputDebugString ( "Обнаружена копия модели с Model " .. tostring ( model ) .. "!", 2 )
		else
			modelsLookup [ model ] = true
		end
	end
	if restoredNum > 0 then
		outputDebugString ( "Восстановлено " .. restoredNum .. " моделей" )
	end
end

function xrLoader.buildPackageFileList ( package )
	local files = { }
	
	local metaFilePath = ":" .. getResourceName ( package ) .. "/meta.xml"
	local xml = xmlLoadFile ( metaFilePath )
	if xml then
		-- Ищем ноды файлов
		local index = 0
		local node = xmlFindChild ( xml, "file", index )
		while node ~= false do
			-- Если это файл с ручной отправкой
			if xmlNodeGetAttribute ( node, "download" ) == "false" then
				local fileSrc = xmlNodeGetAttribute ( node, "src" )
				table.insert ( files, fileSrc )
			end
			
			index = index + 1
			node = xmlFindChild ( xml, "file", index )
		end
		
		xmlUnloadFile ( xml )
	else
		outputDebugString ( "meta.xml файла пакета " .. getResourceName ( package ) .. " не существует", 3 )
	end
	
	return files
end

function xrLoader.packageDeclareFile ( package, filename )
	-- Еще раз на всякий случай проверяем отсутствие декларации
	if xrLoader.isPackageFileDeclared ( package, filename ) ~= true then
		local metaFilePath = ":" .. getResourceName ( package ) .. "/meta.xml"
		local xml = xmlLoadFile ( metaFilePath )
		if xml then
			-- И просто добавляем новый нод в самом низу
			local fileNode = xmlCreateChild ( xml, "file" )
			xmlNodeSetAttribute ( fileNode, "src", filename )
			xmlNodeSetAttribute ( fileNode, "download", "false" )
			
			-- Добавляем файл в список
			table.insert ( xrLoader.packages [ package ].files, filename )
		
			xmlSaveFile ( xml )
			return xmlUnloadFile ( xml )
		else
			outputDebugString ( "meta.xml файла пакета " .. getResourceName ( package ) .. " не существует", 3 )
		end
	end
end

function xrLoader.isPackageFileDeclared ( package, filename )
	local packageData = xrLoader.packages [ package ]
	if packageData then
		for _, file in ipairs ( packageData.files ) do
			if file == filename then
				return true
			end
		end
	else
		outputDebugString ( "Пакет не был найден", 3 )
	end
	return false
end

function xrLoader.onPackageStart ( res )
	if xrLoader.packages [ res ] then
		-- Проверяем пакет
		xrLoader.restorePackage ( res )
	
		local resRoot = getResourceRootElement ( res )
		xrLoader.elementPackage [ resRoot ] = res
	end
end

function xrLoader.onPackageStop ( res )
	if xrLoader.packages [ res ] then
		local resRoot = getResourceRootElement ( res )
		xrLoader.elementPackage [ resRoot ] = nil
	end
end

--[[
function xrLoader.refreshPackage ( package )
	local resourcesFilePath = ":" .. getResourceName ( package.resource ) .. "/resources.xml"
	if fileExists ( resourcesFilePath ) ~= true then
		outputDebugString ( "Не было найдено файла конфигурации пакета " .. package.name, 2 )
		return
	end
	
	local newFilesCount = 0
	local changedFilesCount = 0
	
	local modelAssociate = { }
	
	-- Собираем все файлы пакета в таблицу
	local xml = xmlLoadFile ( resourcesFilePath )
	for _, node in ipairs ( xmlNodeGetChildren ( xml ) ) do	
		local resourceFile = { }
		resourceFile.model = tonumber ( xmlNodeGetAttribute ( node, "model" ) )
		resourceFile.geomName = xmlNodeGetAttribute ( node, "geometry" )
		resourceFile.texName = xmlNodeGetAttribute ( node, "texture" )
		resourceFile.lodModel = tonumber ( xmlNodeGetAttribute ( node, "lod" ) )
		resourceFile.lodDist = tonumber ( xmlNodeGetAttribute ( node, "loddist" ) ) or 300
		resourceFile.pckg = package.index
		
		local invalidAttribute = xrPackage.validateFile ( resourceFile )
		if not invalidAttribute then
			local compareToFile = xrLoader.models [ resourceFile.model ]
			-- Если файл с похожим признаком уже есть в пакете, сравниваем с ним наш
			if compareToFile then
				if compareToFile.pckg == package.index then
					local changes = xrPackage.compareFiles ( compareToFile, resourceFile )
					for _, key in ipairs ( changes ) do
						-- TODO
			
						-- Применяем изменения
						compareToFile [ key ] = resourceFile [ key ]
					end
					if #changes > 0 then changedFilesCount = changedFilesCount + 1 end
					
					modelAssociate [ resourceFile.model ] = true
				else
					outputDebugString ( "Обнаружен файл с схожей моделью в другом пакете!", 2 )
				end
		
			-- В противном случае просто добавлем новый
			else
				xrLoader.models [ resourceFile.model ] = resourceFile
				
				table.insert ( package.files, resourceFile.model )
				
				modelAssociate [ resourceFile.model ] = true
						
				newFilesCount = newFilesCount + 1
			end
		else
			outputDebugString ( "Один из файлов с атрибутом " .. invalidAttribute .. " пакета " .. package.name .. " не может быть загружен", 2 )
		end		
	end	
	
	local deletedFilesCount = 0
	
	-- Удаляем незадействованные файлы
	for i = #package.files, 1, -1 do
		local fileModel = package.files [ i ]
		if modelAssociate [ fileModel ] == nil then
			table.remove ( package.files, i )
			xrLoader.models [ fileModel ] = nil
			
			deletedFilesCount = deletedFilesCount + 1
		end
	end
	
	for i = 1, #package.files do
		local fileModel = package.files [ i ]
		outputChatBox(fileModel)
	end
	
	outputDebugString ( "Пакет " .. package.name .. " обновлен(" .. newFilesCount .. " новых, " .. deletedFilesCount .. " удалено, " .. changedFilesCount .. " изменено)" )
end]]

function xrLoader.packageFileExists ( package, filename )
	--outputChatBox(":" .. getResourceName ( package ) .. "/models/" .. filename )
	local isExists = fileExists ( ":" .. getResourceName ( package ) .. "/models/" .. filename )
	return isExists
end

function xrLoader.checkMeshProperties ( package, properties )
	local errors = { }

	for _, property in ipairs ( properties ) do
		-- Model
		if property [ 1 ] == 1 then
			if type ( property [ 2 ] ) ~= "number" or getElementByID ( "m" .. property [ 2 ] ) then
				table.insert ( errors, { 1, xrLoaderErrors.MODEL_EXISTS } )
			end
		
		-- Geom name
		elseif property [ 1 ] == 2 then
			if type ( property [ 2 ] ) ~= "string" or property [ 2 ]:len ( ) < 3 then
				table.insert ( errors, { 2, xrLoaderErrors.INCORRECT_LEN } )
			elseif xrLoader.packageFileExists ( package, property [ 2 ] .. ".dff" ) ~= true then
				table.insert ( errors, { 2, xrLoaderErrors.DFF_NOTFOUND } )
			elseif xrLoader.packageFileExists ( package, property [ 2 ] .. ".col" ) ~= true then
				table.insert ( errors, { 2, xrLoaderErrors.COL_NOTFOUND } )
			elseif xrLoader.packageFileExists ( package, property [ 2 ] .. ".txt" ) ~= true and xrLoader.packageFileExists ( package, property [ 2 ] .. ".xml" ) ~= true then
				table.insert ( errors, { 2, xrLoaderErrors.TXT_NOTFOUND } )
			end
		-- Texture name
		elseif property [ 1 ] == 3 then
			if type ( property [ 2 ] ) ~= "string" or property [ 2 ]:len ( ) < 3 then
				table.insert ( errors, { 3, xrLoaderErrors.INCORRECT_LEN } )
			elseif xrLoader.packageFileExists ( package, property [ 2 ] .. ".txd" ) ~= true then
				table.insert ( errors, { 3, xrLoaderErrors.TXD_NOTFOUND } )
			end
		elseif property [ 1 ] == 4 then
			if tonumber ( property [ 2 ] ) ~= nil and getElementByID ( "m" .. property [ 2 ] ) == false then
				table.insert ( errors, { 4, xrLoaderErrors.LODM_NOTFOUND } )
			end
		end
	end
	
	return errors
end

function xrLoader.savePackage ( package )
	local mapRoot = getResourceMapRootElement ( package, "meshes.map" )
	local file = xmlCreateFile ( ":" .. getResourceName ( package ) .. "/meshes.map", "map" )
	if file then
		saveMapData ( file, mapRoot, true )
		xmlSaveFile ( file )
		return xmlUnloadFile ( file )
	end
end

function xrLoader.onMeshChangeProperties ( properties )
	local meshRoot = getElementRoot ( source ) -- Найдем корневой элемент модели
	-- Извлечем ресурс из его корневого элемента
	local resourceName = getElementID ( meshRoot )
	local package = getResourceFromName ( resourceName )
	if getResourceName ( package ) == false or package == resource then
		outputDebugString ( "Не был найден пакет", 2 )
		return
	end
	
	-- В начале проверяем все наши параметры
	local errors = xrLoader.checkMeshProperties ( package, properties )
	if #errors == 0 then
		-- А теперь, когда мы убедились что ошибок нет
		-- применяем все новые свойства
		for _, property in ipairs ( properties ) do
			-- Model
			if property [ 1 ] == 1 then
				local idStr = "m" .. property [ 2 ]
				setElementData ( source, "id", idStr  )
				setElementID ( source, idStr )
				setElementData ( source, "model", tostring ( property [ 2 ] ) )
				
			-- Geom name
			elseif property [ 1 ] == 2 then
				setElementData ( source, "geom", property [ 2 ] )
				
			-- Texture name
			elseif property [ 1 ] == 3 then
				setElementData ( source, "tex", property [ 2 ] )
			elseif property [ 1 ] == 4 then
				if tonumber ( property [ 2 ] ) == nil then
					removeElementData ( source, "lod" )
					outputDebugString ( "LOD удален" )
				else
					setElementData ( source, "lod", property [ 2 ] )
				end
			end
		end
		
		-- Сохраняем изменения в .map файле пакета
		xrLoader.savePackage ( package )
		
		triggerClientEvent ( client, "onClientMeshResponse", source )
		
	-- В противном случае отправляем ошибки клиенту
	else
		triggerClientEvent ( client, "onClientMeshResponse", source, errors )
	end
end

function xrLoader.onPackageCreateMesh ( properties )
	-- Извлечем ресурс из его корневого элемента
	local resourceName = getElementID ( source )
	local package = getResourceFromName ( resourceName )
	if getResourceName ( package ) == false or package == resource then
		outputDebugString ( "Не был найден пакет", 2 )
		return
	end
	
	-- В начале проверяем все наши параметры
	local errors = xrLoader.checkMeshProperties ( package, properties )
	if #errors == 0 then
		-- Если параметры в норме, создаем новую модель
		local meshModel = properties [ 1 ] [ 2 ]
		local meshGeom = properties [ 2 ] [ 2 ]
		local meshTex = properties [ 3 ] [ 2 ]
		local meshId = "m" .. meshModel
		
		if xrLoaderExtendPkg ( resourceName, meshGeom, meshTex, meshModel, 0, false, false, true ) then
			triggerClientEvent ( client, "onClientMeshResponse", source )
		else
			triggerClientEvent ( client, "onClientMeshResponse", source, { UNK_ERR } )
		end
		
	-- В противном случае отправляем ошибки клиенту
	else
		triggerClientEvent ( client, "onClientMeshResponse", source, errors )
	end
end

function xrLoader.onPackageRefresh ( )
	-- Извлечем ресурс из его корневого элемента
	local resourceName = getElementID ( source )
	local package = getResourceFromName ( resourceName )
	if getResourceName ( package ) == false or package == resource then
		outputDebugString ( "Не был найден пакет", 2 )
		return
	end

	if restartResource ( package ) then
		outputDebugString ( "Пакет " .. resourceName .. " был успешно перезагружен" )
	else
		outputDebugString ( "Пре перезагрузке пакета " .. resourceName .. " была обнаружена ошибка! Пакет остановлен." , 2 )
	end
end

--[[
	xrPackage
]]
xrPackage = { }
xrPackage.__index = xrPackage

function xrPackage.new ( res, packageName )
	local package = {
		resource = res,
		name = packageName,
		files = { }
	}
	
	return setmetatable ( package, xrPackage )
end

function xrPackage.validateFile ( fileData )
	if type ( fileData.model ) ~= "number" then
		return "model"
	elseif type ( fileData.geomName ) ~= "string" or string.len ( fileData.geomName ) == 0 then
		return "geometry"
	elseif type ( fileData.texName ) ~= "string" or string.len ( fileData.texName ) == 0 then
		return "texture"
	end
end

function xrPackage.compareFiles ( firstFile, secondFile )
	if firstFile.type == secondFile.type then
		local changes = { }		
		
		for key, value in pairs ( firstFile ) do
			if ( key ~= "type" and key ~= "model" and key ~= "pckg" ) and secondFile [ key ] ~= value then
				table.insert ( changes, key )
			end
		end
		
		return changes
	else
		outputDebugString ( "У сравниваемых файлов должен быть один тип", 2 )
	end
end

-- Поиск файла в пакете по ключам присущим их типу
function xrPackage:findFile ( fileData )
	for _, file in ipairs ( self.files ) do
		if fileData.type == file.type then
			if fileData.model == file.model then
				return file
			end
		end
	end
end

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		xrLoader.init ( )
	end
, false )

-----------------------------
-- EXPORT
-----------------------------
--[[
	xrLoaderExtendPkg
	Добавляет в пакет новую модель
]]
function xrLoaderExtendPkg ( pkgName, geomName, texName, model, lodModel, isAlpha, isTreeLod, restartAfter )
	local package = getResourceFromName ( pkgName )
	if getResourceName ( package ) == false then
		outputDebugString ( "Пакета с именем " .. pkgName .. " не существует", 2 )
		return false
	end
	
	local meshId = "m" .. model
	
	if getElementByID ( meshId ) then
		outputDebugString ( "Дескриптор с моделью " .. model .. " уже существует", 2 )
		return false
	end
	
	
	if xrLoader.packageFileExists ( package, geomName .. ".dff" ) ~= true or 
		xrLoader.packageFileExists ( package, geomName .. ".col" ) ~= true or
		xrLoader.packageFileExists ( package, texName .. ".txd" ) ~= true then
		outputDebugString ( "Один или несколько файлов не было найдено для пакета " .. pkgName, 2 )
		return false
	end
	
	local meshLightFlag = 0
	local isInternalLighting = false
	local hasXML = false
	
	-- Парсим XML и находим флаг для лайтмапов
	if fileExists ( ":" .. pkgName .. "/models/" .. geomName .. ".xml" ) then
		local xml = xmlLoadFile ( ":" .. pkgName .. "/models/" .. geomName .. ".xml" )
		meshLightFlag = xmlNodeGetAttribute ( xml, "flags" ) or 0
		isInternalLighting = xmlNodeGetAttribute ( xml, "internal" ) == "true"
		xmlUnloadFile ( xml )
		hasXML = true
	
	-- Парсим TXT и находим флаг для лайтмапов ( Для поддержки старых моделей )
	elseif fileExists ( ":" .. pkgName .. "/models/" .. geomName .. ".txt" ) then
		local file = fileOpen ( ":" .. pkgName .. "/models/" .. geomName .. ".txt", true )
		-- Читаем только первые 80 байтов
		local buffer = fileRead ( file, 80 )
		local flagStr = gettok ( buffer, 4, 10 )
		if flagStr and flagStr:sub ( 1, 9 ) == "lighttype" then
			meshLightFlag = gettok ( flagStr, 2, 61 )
		else
			outputDebugString ( "Не было найдено флага в файле описания " .. geomName .. ".txt", 2 )
		end
			
		fileClose ( file )
	end
		
	-- Безопасное добавление элемента в карту
	local xml = xmlLoadFile ( ":" .. pkgName .. "/meshes.map" )
	if xml then
		local meshNode = xmlCreateChild ( xml, "mesh" )
		xmlNodeSetAttribute ( meshNode, "id", meshId )
		xmlNodeSetAttribute ( meshNode, "model", tostring ( model ) )
		xmlNodeSetAttribute ( meshNode, "geom", geomName )
		xmlNodeSetAttribute ( meshNode, "tex", texName )
		xmlNodeSetAttribute ( meshNode, "flag", tostring ( tonumber ( meshLightFlag ) ) )
		if isAlpha then
			xmlNodeSetAttribute ( meshNode, "alpha", "true" )
		end
		if isTreeLod then
			xmlNodeSetAttribute ( meshNode, "treelod", "1" )
		end
		if hasXML then
			xmlNodeSetAttribute ( meshNode, "hasxml", "true" )
		end
		if isInternalLighting then
			xmlNodeSetAttribute ( meshNode, "internal", "true" )
		end
			
		xmlSaveFile ( xml )
		xmlUnloadFile ( xml )
	else
		outputDebugString ( "Карта пакета " .. pkgName .. " не была найдена!", 2 )
	end
	
	-- Добавляем декларацию файлов в meta.xml, если их там еще нет
	local colWasDeclared = xrLoader.packageDeclareFile ( package, "models/" .. geomName .. ".col" )
	local dffWasDeclared = xrLoader.packageDeclareFile ( package, "models/" .. geomName .. ".dff" )
	local txdWasDeclared = xrLoader.packageDeclareFile ( package, "models/" .. texName .. ".txd" )
	local xmlWasDeclared = true
	if hasXML then
		xmlWasDeclared = xrLoader.packageDeclareFile ( package, "models/" .. geomName .. ".xml" )
	end
	
	if colWasDeclared ~= true or dffWasDeclared ~= true or txdWasDeclared ~= true or xmlWasDeclared ~= true then
		outputDebugString ( "Файлы не были задекларированы", 2 )
		return false
	end
	
	if restartAfter then
		if restartResource ( package ) then
			outputDebugString ( "Пакет " .. pkgName .. " был успешно перезагружен" )
		else
			outputDebugString ( "Пре перезагрузке пакета " .. pkgName .. " была обнаружена ошибка! Пакет остановлен." , 2 )
			return false
		end
	end
	
	return true
end

--[[
	xrLoaderCleanPkg
	Очищает пакет
]]
function xrLoaderCleanPkg ( pkgName )
	local package = getResourceFromName ( pkgName )
	if getResourceName ( package ) == false or xrLoader.packages [ package ] == nil then
		outputDebugString ( "Пакета с именем " .. pkgName .. " не существует", 2 )
		return false
	end
	
	-- Удаляем элементы
	local mapRoot = getResourceMapRootElement ( package, "meshes.map" )
	if mapRoot then
		for _, mesh in ipairs ( getElementsByType ( "mesh", mapRoot ) ) do
			destroyElement ( mesh )
		end
	else
		outputDebugString ( "Карта пакета " .. pkgName .. " не была найдена!", 2 )
	end

	-- Удаляем файлы из нода
	local metaXml = xmlLoadFile ( ":" .. pkgName .. "/meta.xml" )
	if metaXml then
		for _, node in ipairs ( xmlNodeGetChildren ( metaXml ) ) do
			if xmlNodeGetAttribute ( node, "download" ) == "false" and xmlNodeGetAttribute ( node, "pkgLock" ) ~= "true" then
				xmlDestroyNode ( node )
			end
		end
		
		xmlSaveFile ( metaXml )
		xmlUnloadFile ( metaXml )
	else
		outputDebugString ( "meta.xml пакета " .. pkgName .. " не был найден!", 2 )
	end
	
	-- Создаем пустой файл карты
	local xml = xmlCreateFile ( ":" .. pkgName .. "/meshes.map", "map" )
	xmlSaveFile ( xml )
	xmlUnloadFile ( xml )
	
	-- Очищаем список файлов
	xrLoader.packages [ package ].files = { }
	
	outputDebugString ( "Пакет " .. pkgName .. " успешно очищен" )
end

--[[
	xrLoaderUpdatePkg
	Перезагружает пакет и применят изменения
]]
function xrLoaderUpdatePkg ( pkgName )
	local package = getResourceFromName ( pkgName )
	if getResourceName ( package ) == false or xrLoader.packages [ package ] == nil then
		outputDebugString ( "Пакета с именем " .. pkgName .. " не существует", 2 )
		return false
	end

	if restartResource ( package ) then
		outputDebugString ( "Пакет " .. pkgName .. " был успешно перезагружен" )
	else
		outputDebugString ( "Пре перезагрузке пакета " .. pkgName .. " была обнаружена ошибка! Пакет остановлен." , 2 )
	end
end

-- Временное решение для обхода крэша сервер
addEvent ( "onLoaderExtendPkg", false )
addEventHandler ( "onLoaderExtendPkg", root,
	function ( pkgName, geomName, texName, model, lodModel, isAlpha, isTreeLod, restartAfter )
		xrLoaderExtendPkg ( pkgName, geomName, texName, model, lodModel, isAlpha, isTreeLod, restartAfter )
	end
, false )