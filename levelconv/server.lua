CLUSTER_RAD = 50

local _mathInf = 999999
local _mathMin = math.min
local _mathMax = math.max
local _mathFloor = math.floor
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end

local fileSeek = function ( file, offset )
	local pos = fileGetPos ( file )
	fileSetPos ( file, pos + offset )
end

--[[
	xrTXD
]]
xrTXD = { }
xrTXD.__index = xrTXD

function xrTXD.new ( index )
	local txd = { 
		textures = { },
		texNum = 0,
		index = index
	}
	
	return setmetatable ( txd, xrTXD )
end

function xrTXD:hasTexture ( texName )
	return self.textures [ texName ] ~= nil
end

function xrTXD:extend ( texName )
	if self.textures [ texName ] == nil then
		self.textures [ texName ] = true
		self.texNum = self.texNum + 1
		return true
	end
	return false
end

function xrTXD:build ( file )
	outputDebugString ( "Building of " .. self.index .. " texture dict" )

	-- Пишем заголовок
	fileWrite ( file, dataToBytes ( "i", 0x16 ) )
	fileWrite ( file, dataToBytes ( "i", 0 ) ) -- Потом запишем размер
	fileWrite ( file, dataToBytes ( "i", 0x1803FFFF ) )
	
	-- Пишем структуру
	fileWrite ( file, dataToBytes ( "i", 0x01 ) )
	fileWrite ( file, dataToBytes ( "i", 4 ) )
	fileWrite ( file, dataToBytes ( "i", 0x1803FFFF ) )
	fileWrite ( file, dataToBytes ( "s", 0 ) ) -- Потом запишем кол-во текстур
	fileWrite ( file, dataToBytes ( "s", 2 ) )
	
	-- Функция-помощник для поиска и загрузки файла словаря
	local _openDicts = { }
	local function getTextureDict ( texName )
		local _file = _openDicts [ texName ]
		if _file == nil then
			_file = fileOpen ( "txds\\" .. texName .. ".txd" )
			_openDicts [ texName ] = _file
		end
		return _file
	end
	
	-- Пишем текстуры
	local writtedNum = 0
	local totalSize = 16
	local _dictInfo = xrTXDManager.dictInfo
	for texName, _ in pairs ( self.textures ) do
		local texInfo = _dictInfo [ string.lower ( texName ) ]
		if texInfo then
			local dictRaw = getTextureDict ( texInfo.name )
			fileSetPos ( dictRaw, texInfo.offset )
			local data = fileRead ( dictRaw, texInfo.size )
			fileWrite ( file, data )
			
			totalSize = totalSize + texInfo.size
			
			writtedNum = writtedNum + 1
		else
			outputDebugString ( "Texture " .. texName .. " not found" )
		end
	end
	
	-- Пишем пустое расширение
	fileWrite ( file, dataToBytes ( "i", 0x03 ) )
	fileWrite ( file, dataToBytes ( "i", 0 ) )
	fileWrite ( file, dataToBytes ( "i", 0x1803FFFF ) )
	totalSize = totalSize + 12
	
	-- Возвращаемся и записываем размер
	fileSetPos ( file, 4 )
	fileWrite ( file, dataToBytes ( "i", totalSize ) )
	
	-- Возвращаемся и записываем кол-вот текстур
	fileSetPos ( file, 24 )
	fileWrite ( file, dataToBytes ( "s", writtedNum ) )
	
	-- Выгружаем словари
	for _, file in pairs ( _openDicts ) do
		fileClose ( file )
	end
	
	outputDebugString ( self.index .. " texture dict was successfully built" )
	
	return writtedNum
end

--[[
	xrTXDManager
]]
local TXD_MAX_TEXTURES = 6

local TXD_DICTS = {
	"trees",
	"trees_bark",
	"stones"
}

xrTXDManager = { 
	dicts = { },
	dictInfo = { }
}

function xrTXDManager.init ( )
	local totalCount = 0
	for _, name in ipairs ( TXD_DICTS ) do
		local count = xrTXDManager.parseDict ( name, xrTXDManager.dictInfo )
		totalCount = totalCount + count
	end
	
	outputDebugString ( "Loaded " .. totalCount .. " texture dicts" )
end

function xrTXDManager.parseDict ( fileName, tbl )
	local file = fileOpen ( "txds\\" .. fileName .. ".txd" )
	if file then
		fileSeek ( file, 24 ) -- Пропускаем заголовок TXD и структуры
		local buffer = fileRead ( file, 2 )
		local texCount = bytesToData ( "s", buffer )
		fileSeek ( file, 2 ) -- Пропускаем два байта версии
		
		-- Читаем текстуры
		for i = 1, texCount do
			local pos = fileGetPos ( file )
			buffer = fileRead ( file, 4 )
			local sectionType = bytesToData ( "i", buffer )
			if sectionType == 0x15 then
				buffer = fileRead ( file, 4 )
				local sectionSize = bytesToData ( "i", buffer )
				local endOfSection = pos + 12 + sectionSize
	
				fileSeek ( file, 24 ) -- Пропускаем заголовок + флаги
				buffer = fileRead ( file, 36 )
				local texName = ""
				for j = 1, 36 do
					local charStr = buffer:sub ( j, j )
					-- Исключаем все кроме символов
					if string.byte ( charStr ) > 32 then
						texName = texName .. charStr
					end
				end
			
				local info = {
					name = fileName,
					offset = pos,
					size = sectionSize + 12
				}
				tbl [ texName ] = info
			
				fileSetPos ( file, endOfSection )
			end
		end
		
		fileClose ( file )
		
		return texCount
	else
		outputDebugString ( "Texture dict " .. fileName .. " not found", 2 )
	end
end

--[[
	xrTXD, bool = find ( string texNames )
	Возвращает объект xrTXD если он существует и true если был найден объект полностью покрывающий список
	или false если частично покрывающий с количеством недостающих текстур <= 3
]]
function xrTXDManager.find ( texNames )
	local maxMatchesCount = 0
	local mostMatchedTxd

	for _, txd in ipairs ( xrTXDManager.dicts ) do
		local matches = 0
		for _, name in ipairs ( texNames ) do
			if txd:hasTexture ( name ) then
				matches = matches + 1
			end
		end
		if matches == #texNames then
			return txd, true
		else
			if matches > maxMatchesCount and txd.texNum <= TXD_MAX_TEXTURES then
				maxMatchesCount = matches
				mostMatchedTxd = txd
			end
		end
	end
	
	if mostMatchedTxd ~= nil and #texNames - maxMatchesCount <= 3 then
		return mostMatchedTxd, false
	end
	
	return false, false
end

function xrTXDManager.findOrCreate ( texNames )
	-- Если нет ни одного словаря, тогда создаем новый
	if #xrTXDManager.dicts == 0 then
		local txd = xrTXD.new ( 1 )
		for _, name in ipairs ( texNames ) do
			txd:extend ( name )
		end
		
		table.insert ( xrTXDManager.dicts, txd )
		
		return txd
	end
	
	local txd, isTotal = xrTXDManager.find ( texNames )
	-- Если txd лишь частично покрывает список текстур, тогда расширяем его
	if txd ~= false and isTotal ~= true then
		for _, name in ipairs ( texNames ) do
			txd:extend ( name )
		end
		
	-- Или создаем новый
	elseif txd == false then
		txd = xrTXD.new ( #xrTXDManager.dicts + 1 )
		for _, name in ipairs ( texNames ) do
			txd:extend ( name )
		end
		
		table.insert ( xrTXDManager.dicts, txd )
	end
	
	return txd
end

function xrTXDManager.clearAll ( )
	xrTXDManager.dicts = { }
end

function xrTXDManager.buildAll ( )
	local num = 0

	for _, txd in ipairs ( xrTXDManager.dicts ) do
		local file = fileCreate ( "clusters/" .. txd.index .. ".txd" )
		num = num + txd:build ( file )
		fileClose ( file )
	end
	
	outputDebugString ( "Building of " .. num .. " texture dicts completed" )
	
	return num
end

--[[
	TCluster
]]
local function _getMeshTextures ( mesh )
	local names = { }
	local i = 0
	local tname = xrGetMeshTextures ( mesh, i )
	while tname ~= false do
		i = i + 1
		
		names [ i ] = tname
		
		tname = xrGetMeshTextures ( mesh, i )
	end
	
	return names
end

TCluster = { }
TCluster.__index = TCluster

function TCluster.new ( index )
	local cluster = {
		elements = { },
		index = index
	}
	
	return setmetatable ( cluster, TCluster )
end

function TCluster:getBBox ( )
	local minx, miny, minz = _mathInf, _mathInf, _mathInf
	local maxx, maxy, maxz = -_mathInf, -_mathInf, -_mathInf
	
	for _, generic in ipairs ( self.elements ) do
		local x, y, z = getElementPosition ( generic )
		minx, miny, minz = _mathMin ( minx, x ), _mathMin ( miny, y ), _mathMin ( minz, z )
		maxx, maxy, maxz = _mathMax ( maxx, x ), _mathMax ( maxy, y ), _mathMax ( maxz, z )
	end
	
	return minx, miny, minz, maxx, maxy, maxz
end

function TCluster:build ( )
	outputDebugString ( "Building of cluster " .. tostring ( self.index ) )

	local minx, miny, minz, maxx, maxy, maxz = self:getBBox ( )
	local sizex, sizey, sizez = maxx - minx, maxy - miny, maxz - minz
	local meshes = { }
	local included = 0
	
	local mainMesh = xrCreateMesh ( )
	
	for _, generic in ipairs ( self.elements ) do
		local meshModel = getElementData ( generic, "model", false )
		if fileExists ( meshModel .. ".dff" ) then
			local mesh = meshes [ meshModel ]
			if mesh == nil then
				outputDebugString(tostring(meshModel ) .. " creating...")
				mesh = xrCreateMesh ( meshModel .. ".dff" )
				if not mesh then
					outputDebugString ( "Error mesh creating " .. tostring ( meshModel ), 2 )
					break
				end
					outputDebugString(tostring(meshModel ) .. " created")
				meshes [ meshModel ] = mesh
			end
	
			local gx, gy, gz = getElementPosition ( generic )
			local x = ( gx - minx ) - sizex/2
			local y = sizey/2 - ( maxy - gy )
			local z = ( gz - minz ) - sizez/2
		
			outputDebugString(tostring(meshModel ) .. " including...")
			xrIncludeMesh ( mesh, mainMesh, x, y, z )
			outputDebugString(tostring(meshModel ) .. " included")
			included = included + 1
		else
			outputDebugString ( "Does not found generic for " .. tostring ( meshModel ), 2 )
		end
	end
	
	if included > 0 then
		outputDebugString("Writing " .. tostring(self.index ))
		xrWriteMeshDFF ( mainMesh, "clusters/" .. self.index .. ".dff" )
		
		local texNames = _getMeshTextures ( mainMesh )
		self.txdIndex = xrTXDManager.findOrCreate ( texNames ).index
		
		outputDebugString ( "Included " .. included .. " meshes for cluster " .. self.index .. " (" .. #texNames .. " texs)" )
	else
		outputDebugString ( "Was not included any mesh", 2 )
	end
	
	xrDestroyMesh ( mainMesh )
	
	-- Удаляем остальные мэши
	for _, mesh in pairs ( meshes ) do
		xrDestroyMesh ( mesh )
	end
	
	self.buildx = minx + sizex/2
	self.buildy = miny + sizey/2
	self.buildz = minz + sizez/2
	
	return included
end

function TCluster:buildLOD ( )
	outputDebugString ( "Building of cluster LOD " .. tostring ( self.index ) )

	local minx, miny, minz, maxx, maxy, maxz = self:getBBox ( )
	local sizex, sizey, sizez = maxx - minx, maxy - miny, maxz - minz
	local meshes = { }
	local included = 0
	
	local mainMesh = xrCreateMesh ( )
	
	for _, generic in ipairs ( self.elements ) do
		local meshModel = getElementData ( generic, "model", false )
		if fileExists ( meshModel .. "_lod.dff" ) then
			local mesh = meshes [ meshModel ]
			if mesh == nil then
				mesh = xrCreateMesh ( meshModel .. "_lod.dff" )
				if not mesh then
					outputDebugString ( "Error mesh creating " .. tostring ( meshModel ) .. "_lod", 2 )
					break
				end
				meshes [ meshModel ] = mesh
			end
	
			local gx, gy, gz = getElementPosition ( generic )
			local x = ( gx - minx ) - sizex/2
			local y = sizey/2 - ( maxy - gy )
			local z = ( gz - minz ) - sizez/2
		
			xrIncludeMesh ( mesh, mainMesh, x, y, z )
			included = included + 1
		end
	end
	
	if included > 0 then
		xrWriteMeshDFF ( mainMesh, "clusters/" .. self.index .. "_lod.dff"  )
		xrWriteMeshCOL ( mainMesh, "clusters/" .. self.index .. "_lod.col", true )
		outputDebugString ( "Included " .. included .. " meshes for " .. "clusters/" .. self.index .. "_lod" )
		
		self.hasLOD = true
	else
		self.hasLOD = false
	end

	xrDestroyMesh ( mainMesh )
	
	-- Удаляем остальные мэши
	for _, mesh in pairs ( meshes ) do
		xrDestroyMesh ( mesh )
	end
	
	return included
end

function TCluster:buildCOL ( )
	outputDebugString ( "Building of cluster COL " .. tostring ( self.index ) )

	local minx, miny, minz, maxx, maxy, maxz = self:getBBox ( )
	local sizex, sizey, sizez = maxx - minx, maxy - miny, maxz - minz
	local meshes = { }
	local included = 0
	
	local mainMesh = xrCreateMesh ( )
	
	for _, generic in ipairs ( self.elements ) do
		local meshModel = getElementData ( generic, "model", false )
		local mesh = meshes [ meshModel ]
		local withoutGeom = fileExists ( meshModel .. "_col.dff" ) ~= true
		if not mesh then
			-- Ищем файл коллизии
			if fileExists ( meshModel .. "_col.dff" ) then
				mesh = xrCreateMesh ( meshModel .. "_col.dff" )
				if not mesh then
					outputDebugString ( "Error mesh creating " .. tostring ( meshModel ) .. "_col", 2 )
					break
				end
			
			-- Если ничего не нашли, используем основную модель без геометрии
			elseif fileExists ( meshModel .. ".dff" ) then
				withoutGeom = true
				
				mesh = xrCreateMesh ( meshModel .. ".dff" )
				if not mesh then
					outputDebugString ( "Error mesh creating " .. tostring ( meshModel ), 2 )
					break
				end
			else
				outputDebugString ( "Nothing was found for collision " .. tostring ( meshModel ), 2 )
				break
			end
			meshes [ meshModel ] = mesh
		end
	
		local gx, gy, gz = getElementPosition ( generic )
		local x = ( gx - minx ) - sizex/2
		local y = sizey/2 - ( maxy - gy )
		local z = ( gz - minz ) - sizez/2
		
		xrIncludeMesh ( mesh, mainMesh, x, y, z, withoutGeom )
		included = included + 1
	end
	
	if included > 0 then
		xrWriteMeshCOL ( mainMesh, "clusters/" .. self.index .. ".col" )
		outputDebugString ( "Included " .. included .. " meshes for " .. "clusters/" .. self.index .. "_col" )
		
		self.hasCOL = true
	else
		self.hasCOL = false
	end

	xrDestroyMesh ( mainMesh )
	
	-- Удаляем остальные мэши
	for _, mesh in pairs ( meshes ) do
		xrDestroyMesh ( mesh )
	end
	
	return included
end

function TCluster:place ( xml )
	if self.hasCOL ~= true then
		outputDebugString ( "Cluster " .. self.index .. " does not contain the COL", 2 )
		return false
	end

	outputDebugString ( "Exporting " .. self.index .. " cluster to loader" )

	local baseName = "clusters/" .. self.index
	if fileExists ( baseName .. ".dff" ) and fileExists ( baseName .. ".col" ) and fileExists ( "clusters/" .. self.txdIndex .. ".txd" ) then
		-- Копируем файлы в пакет
		fileCopy ( baseName .. ".dff", ":veg_package/models/" .. self.index .. ".dff", true )
		fileCopy ( baseName .. ".col", ":veg_package/models/" .. self.index .. ".col", true )
		fileCopy ( "clusters/" .. self.txdIndex .. ".txd", ":veg_package/models/" .. self.txdIndex .. ".txd", true )

		-- Копируем лоды в пакет
		if self.hasLOD then
			if fileExists ( baseName .. "_lod.dff" ) and fileExists ( baseName .. "_lod.col" ) then
				fileCopy ( baseName .. "_lod.dff", ":veg_package/models/" .. self.index .. "_lod.dff", true )
				fileCopy ( baseName .. "_lod.col", ":veg_package/models/" .. self.index .. "_lod.col", true )
				if fileExists ( ":veg_package/models/lods.txd" ) ~= true then
					fileCopy ( "lods.txd", ":veg_package/models/lods.txd", false )
				end
			else
				outputDebugString ( "LOD files for " .. self.index .. " cluster not founded", 2 )
				return false
			end
		end
		
		local model = allocateModel ( ) -- Выделяем модель
		
		-- Тут происходит крэш сервера
		call ( getResourceFromName ( "xrloader" ), "xrLoaderExtendPkg", "veg_package", tostring ( self.index ), tostring ( self.txdIndex ), model, 0, true, false, false )

		-- Добавляем объект в файл карты
		local node = xmlCreateChild ( xml, "object" )
		xmlNodeSetAttribute ( node, "posX", tostring ( self.buildx ) )
		xmlNodeSetAttribute ( node, "posY", tostring ( self.buildy ) )
		xmlNodeSetAttribute ( node, "posZ", tostring ( self.buildz ) )
		xmlNodeSetAttribute ( node, "model", tostring ( model ) )
		
		if self.hasLOD then
			model = allocateModel ( ) -- Выделяем модель
			call ( getResourceFromName ( "xrloader" ), "xrLoaderExtendPkg", "veg_package", tostring ( self.index ) .. "_lod", "lods", model, 0, true, true, false )
			
			xmlNodeSetAttribute ( node, "lod", tostring ( model ) )
		end
	else
		outputDebugString ( "One of the files of the cluster " .. self.index .. " does not exists!", 3 )
	end
	
	outputDebugString ( self.index .. " cluster was successfully exported" )
	
	return true
end


--[[
	TForest
]]
local STAGE_EXTEND = 1
local STAGE_BUILD = 2
local STAGE_TEXTURE = 3
local STAGE_WRITE = 4

TForest = { }

function TForest.init ( )
	xrTXDManager.init ( )
	TForest.clear ( )
end

function TForest.clear ( )
	TForest.elements = { }
	TForest.hasCluster = { }
	TForest.clusters = { }
end

function TForest.sortGenerics ( cx, cy )
	local _dist2d = getDistanceBetweenPoints2D
	local _getPos = getElementPosition
	local points = TForest.elements
	local temp
	for i = 1, #points - 1 do
		for j = i, #points do
			local x, y = _getPos ( points [ i ] )
			local x2, y2 = _getPos ( points [ j ] )
				
			if _dist2d ( cx, cy, x, y ) > _dist2d ( cx, cy, x2, y2 ) then
				temp = points [ i ]
				points [ i ] = points [ j ]
				points [ j ] = temp
			end
		end
	end
end

function TForest.inRadius ( cx, cy, radius, cluster )
	local _dist2d = getDistanceBetweenPoints2D
	local num = 0
	for i, generic in ipairs ( TForest.elements ) do
		local gx, gy = getElementPosition ( generic )
		if _dist2d ( gx, gy, cx, cy ) <= radius then
			table.insert ( cluster.elements, generic )
			TForest.hasCluster [ generic ] = true
			num = num + 1
			if num > 20 then
				break
			end
		end
	end
	
	return num
end

function TForest.onBuildProcess ( stage, xml )
	local clusters = TForest.clusters

	if stage == STAGE_EXTEND then
		if TForest.lastGenericIndex == nil then
			TForest.lastGenericIndex = 1
		else
			TForest.lastGenericIndex = TForest.lastGenericIndex + 1
		end
	
		-- Переходим к дженерику без кластера
		local generic = TForest.elements [ TForest.lastGenericIndex ]
		while TForest.hasCluster [ generic ] do
			TForest.totalOps = TForest.totalOps - 1
			TForest.lastGenericIndex = TForest.lastGenericIndex + 1
			generic = TForest.elements [ TForest.lastGenericIndex ]
		end
		
		if generic then
			-- Сортируем дженерики относительно данного
			local gx, gy = getElementPosition ( generic )
			TForest.sortGenerics ( gx, gy )
					
			-- Создаем новый кластер
			local clusterIndex = #clusters + 1
			local cluster = TCluster.new ( clusterIndex )
					
			-- Ищем кластеры на заданном радиусе
			local num = TForest.inRadius ( gx, gy, CLUSTER_RAD, cluster )
			outputDebugString ( "Cluster " .. clusterIndex .. " extended to " .. num .. " generics" )
					
			clusters [ clusterIndex ] = cluster
			
			setTimer ( TForest.onBuildProcess, 50, 1, STAGE_EXTEND )
			
			TForest.currentOps = TForest.currentOps + 1
		else
			outputDebugString ( "STAGE_BUILD" )
			TForest.onBuildProcess ( STAGE_BUILD )
		end
	elseif stage == STAGE_BUILD then
		if TForest.lastClusterIndex == nil then
			TForest.lastClusterIndex = 1
		else
			TForest.lastClusterIndex = TForest.lastClusterIndex + 1
		end
	
		local cluster = TForest.clusters [ TForest.lastClusterIndex ]
		if cluster then
			cluster:build ( )
			cluster:buildLOD ( )
			cluster:buildCOL ( )
			
			setTimer ( TForest.onBuildProcess, 50, 1, STAGE_BUILD )
			
			TForest.currentOps = TForest.currentOps + 1
		else
			outputDebugString ( "STAGE_TEXTURE" )
		
			TForest.lastClusterIndex = nil
			TForest.onBuildProcess ( STAGE_TEXTURE )
		end
	elseif stage == STAGE_TEXTURE then
		xrTXDManager.buildAll ( )
		
		local xml_ = xmlCreateFile ( ":xrworld/generic.map", "map" )
		if xml_ then
			outputDebugString ( "STAGE_WRITE" )
		
			setTimer ( TForest.onBuildProcess, 50, 1, STAGE_WRITE, xml_ )
			
			TForest.currentOps = TForest.currentOps + 1
		else
			outputDebugString ( "Map file not founded!", 2 )
		end
	elseif stage == STAGE_WRITE then
		if TForest.lastClusterIndex == nil then
			TForest.lastClusterIndex = 1
		else
			TForest.lastClusterIndex = TForest.lastClusterIndex + 1
		end
		
		local cluster = TForest.clusters [ TForest.lastClusterIndex ]
		if cluster then
			cluster:place ( xml )
			
			setTimer ( TForest.onBuildProcess, 50, 1, STAGE_WRITE, xml )
			
			TForest.currentOps = TForest.currentOps + 1
		else
			TForest.lastClusterIndex = nil
			
			xmlSaveFile ( xml )
			xmlUnloadFile ( xml )
			
			local worldRes = getResourceFromName ( "xrworld" )
			if worldRes == false then
				outputDebugString ( "xrworld resource does not founded. Building stopping...", 3 )
				return
			end
			
			restartResource ( worldRes )
	
			-- Перезапускаем пакет чтобы обновить
			call ( getResourceFromName ( "xrloader" ), "xrLoaderUpdatePkg", "veg_package" )
			
			outputDebugString ( "Building of " .. #TForest.clusters .. " clusters completed" )
		end
	end
	
	local progress = math.floor ( 100 * ( TForest.currentOps / TForest.totalOps ) )
	outputChatBox ( progress .. "%" )
end

function TForest.buildRadius ( cx, cy, cz, radius )
	local startTime = getTickCount ( )


	local _fastDist3D = getDistanceBetweenPoints3D
	
	TForest.clear ( )
	
	-- Находим генерики
	for _, generic in ipairs ( getElementsByType ( "wbo:generic" ) ) do
		local x, y, z = getElementPosition ( generic )
		if _fastDist3D ( x, y, z, cx, cy, cz ) <= radius then
			local modelName = getElementData ( generic, "model", false )
			if fileExists ( modelName .. ".dff" ) then
				table.insert ( TForest.elements, generic )
			end
		end
	end
	
	if fileExists ( ":xrworld/generic.map" ) then
		allocateReset ( )
		xrTXDManager.clearAll ( )
		-- Чистим пакет
		exports["xrloader"]:xrLoaderCleanPkg ( "veg_package" )
		
		-- Рассчитаем количество операций всего
		TForest.totalOps = #TForest.elements + #TForest.clusters * 2 + 1
		TForest.currentOps = 0
		
		outputDebugString ( "STAGE_EXTEND" )
		TForest.onBuildProcess ( STAGE_EXTEND )


		--[[outputChatBox ( "TForest: Построение успешно завершено за " .. getTickCount ( ) - startTime .. " мс" )
		outputChatBox ( "=====================================" )
		outputChatBox ( "Построено " .. #clusters .. " кластеров для радиуса " .. radius .. " юнитов"  )
		outputChatBox ( "Геометрии использовано " .. dffNum )
		outputChatBox ( "LOD использовано " .. lodNum )
		outputChatBox ( "Коллизий использовано " .. colNum )
		outputChatBox ( "Текстур использовано " .. txdNum .. " для " .. #xrTXDManager.dicts .. " словарей"  )
		outputChatBox ( "=====================================" )]]
	else
		outputDebugString ( "generic.map map does not founded. Building stopping...", 3 )
	end
end

addCommandHandler ( "tforest", 
	function ( player, _, radius )
		radius = tonumber ( radius )
		if radius then
			local x, y, z = getElementPosition ( player )
			outputChatBox ( "TForest: Начато построение" )
			TForest.buildRadius ( x, y, z, radius )
		else
			outputChatBox ( "TForest: Неправильный синтаксис. Команда /tforest radius" )
		end
	end
)

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		TForest.init ( )
	end
, false )