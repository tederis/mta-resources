addEvent ( "onClientSectorStreamIn", false )
addEvent ( "onClientSectorStreamOut", false )

SECTOR_SIZE = 150
WORLD_WIDTH = 6000
WORLD_HEIGHT = 6000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE -- 45
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE -- 60

HALF_SECTOR_SIZE = SECTOR_SIZE / 2
HOR_SCALE = 3
MAP_SIZE = SECTOR_SIZE / HOR_SCALE --50 now
MAP_SPACING_Z = 1
BUILD_PATCHES = true
MAP_MAX_ELEVATION = math.floor ( 299 * MAP_SPACING_Z )
HALF_ELEVATION = MAP_MAX_ELEVATION / 2
PATCH_Z = 0
THREADED = true
TREES_ENABLED = false

GEN_LIMIT = 500 -- Лимит операций за промежуток времени в потоке
SECTOR_RELATIVE = false -- Не изменять! В публичной версии не работает.
ELEVATION_CORRECT = false -- Не изменять! Влияет на среднюю точку карты высоты


GEN_TIME = 3
SMOOTH_ITERS = 1

-- Выгрузка шейдеров
SHADER_UNLOAD_ENABLED = true

IMG_UNLOAD_TIME = 150000

INCLUDE_LMAPS = false

spawnSectorIndex = 1

LOD_LEVEL = 2

IMG_BASE = 1
IMG_MASK = 2

FILE_HM = 1
FILE_TX = 2
FILE_MASK = 3

local _mathMin = math.min
local _mathMax = math.max
local _mathFloor = math.floor
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end

local REQUEST_SECTOR_FILES = 0

local allowedModels = {
	18310, 18311, 18312, 18313, 18314, 18345, 18346,
	18315, 18316, 18317, 18318, 18319, 18347, 18348,
	18320, 18321, 18322, 18323, 18324, 18349, 18350,
	18325, 18326, 18327, 18328, 18329, 18351, 18352,
	18330, 18331, 18332, 18333, 18334, 18353, 18354,
	18335, 18336, 18337, 18338, 18339, 18355, 18356,
	18340, 18341, 18342, 18343, 18344, 18357, 18358,
}

local reservedModels = { }
local takeModel = function ( )
	for i = 1, #allowedModels do
		local model = allowedModels [ i ]
		if reservedModels [ model ] ~= true then
			reservedModels [ model ] = true
			return model - 100
		end
	end
end
local freeModel = function ( model )
	reservedModels [ model + 100 ] = nil
end

local loadErrors = {
	[ 0 ] = "Incorrect model",
	[ 1 ] = "Model does not exist",
	[ 2 ] = "Incorrect collision",
	[ 3 ] = "Collision does not exist",
	[ 4 ] = "Model already loaded"
}

--[[
	xrStreamerWorld
]]
xrStreamerWorld = { 
	sectors = { },
	activated = { },
	images = { },
	imagesNum = 0
}

function xrStreamerWorld.init ( )
	-- Вычислим положение мира относительно начала координат(LEFT TOP)
	local sizeX = SECTOR_SIZE * WORLD_SIZE_X
	local sizeY = SECTOR_SIZE * WORLD_SIZE_Y
	xrStreamerWorld.worldX = -sizeX / 2
	xrStreamerWorld.worldY = sizeY / 2
	
	-- Создадим сектора
	for i = 0, WORLD_SIZE_Y-1 do
		local _y = xrStreamerWorld.worldY - SECTOR_SIZE*i
		for j = 0, WORLD_SIZE_X-1 do
			local _x = xrStreamerWorld.worldX + SECTOR_SIZE*j
			
			local sector = xrStreamerSector.new ( _x, _y, SECTOR_SIZE )
			local _index = i * WORLD_SIZE_X + j + 1 -- Пакуем координаты для быстрого поиска
			
			-- Служебные поля для удобной работы
			sector._column = j + 1
			sector._row = i + 1
			sector._index = _index
			
			xrStreamerWorld.sectors [ _index ] = sector
			
			-- Сразу же создаем чек-суммы для масок
			local maskPath = "sectors/" .. _index .. ".png"
			if fileExists ( maskPath ) then
				--local file = fileOpen ( maskPath, true )
				--local content = fileRead ( file, 
					--fileGetSize ( file ) 
				--)
				--fileClose ( file )
				
				--sector.maskMd5 = md5 ( content )
			end
		end
	end

	-- Обозначим соседние сектора
	for i, sector in ipairs ( xrStreamerWorld.sectors ) do
		if sector._column > 1 then -- left sector
			sector._left = xrStreamerWorld.sectors [ i - 1 ]
			sector._left._right = sector
		end
		if sector._column < WORLD_SIZE_X then -- right sector
			sector._right = xrStreamerWorld.sectors [ i + 1 ]
			sector._right._left = sector
		end
		if sector._row > 1 then -- top sector
			sector._top = xrStreamerWorld.sectors [ i - WORLD_SIZE_X ]
			sector._top._bottom = sector
		end
		if sector._row < WORLD_SIZE_Y then -- bottom sector
			sector._bottom = xrStreamerWorld.sectors [ i + WORLD_SIZE_X ]
			sector._bottom._top = sector
		end
	end
	
	-- Если существует файл ревизий, загружаем из него номера ревизий
	if fileExists ( "patches.xtd" ) and BUILD_PATCHES ~= true then
		local file = fileOpen ( "patches.xtd", true )
		xrStreamerWorld.loadRevs ( file )
		fileClose ( file )
		
	-- В противном случае создаем файл ревизий и заполняем его нулями
	else
		g_ProcessCr = coroutine.create ( xrStreamerWorld.fillRevs )
		coroutine.resume ( g_ProcessCr, "patches.xtd" )
	end
	
	if THREADED then
		xrStreamerWorld.processSectors = { }
	
		-- Инициализируем систему очереди построения
		BuildOrder.create ( xrStreamerWorld.onSectorFileBuild )
	end
	
	xrStreamerWorld.imgUpdTime = getTickCount ( )
	
	--setTimer ( xrStreamerWorld.update, 50, 0 )
	addEventHandler ( "onClientRender", root, xrStreamerWorld.update, false )
end

function xrStreamerWorld.updateSectorRev ( index, rev )
	rev = tonumber ( rev )
	if rev == nil then
		outputDebugString ( "Ревизия должна быть числом", 2 )
		return
	end
	
	if fileExists ( "patches.xtd" ) then
		local file = fileOpen ( "patches.xtd", false )	
		fileSetPos ( file, 4 + 4*index )
		dataToBytes ( file, "ui", rev )
		
		fileClose ( file )
	else
		outputDebugString ( "Файла ревизий не существует", 2 )
	end
end

function xrStreamerWorld.loadRevs ( file )
	local count = WORLD_SIZE_X * WORLD_SIZE_Y
	
	local sectorsNum = bytesToData (
		"ui",
		fileRead ( file, 4 )
	)
	if sectorsNum ~= count then
		outputDebugString ( "Файл ревизий принадлежит устаревшей версии", 3 )
		return
	end
	
	for i = 1, count do
		local revNum = bytesToData (
			"ui",
			fileRead ( file, 4 )
		)
		
		local sector = xrStreamerWorld.sectors [ i ]
		if sector then
			sector.rev = revNum
		else
			outputDebugString ( "Сектора по индексу " .. i .. " не существует!", 2 )
		end
	end
	
	outputDebugString ( "Файл ревизий был успешно прочитан", 3 )
end

function xrStreamerWorld.fillRevs ( fileName )
	local file = fileCreate ( fileName )
	local patchesTotal = WORLD_SIZE_X * WORLD_SIZE_Y
	local patchesNum = 0
	local patchesLimit = 0
	
	local _pause = function ( )
		local progress = patchesNum / patchesTotal
		outputDebugString ( "Fill revs " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCr ) end, 50, 1 )
		coroutine.yield ( )
	end
	
	dataToBytes ( file, "ui", patchesTotal )
	
	for i = 1, patchesTotal do
		dataToBytes ( file, "ui", 0 )
		
		local sector = xrStreamerWorld.sectors [ i ]
		if sector then
			sector.rev = 0
		else
			outputDebugString ( "Сектора по индексу " .. i .. " не существует!", 2 )
		end
		
		patchesNum = patchesNum +  1
		patchesLimit = patchesLimit + 1
		if patchesLimit > 100 then
			patchesLimit = 0
			
			--_pause ( )
		end
	end
	
	fileClose ( file )
	outputDebugString ( "Файл ревизий был успешно создан", 3 )
end

if THREADED then
	function xrStreamerWorld.onSectorFileBuild ( processIndex )
		local sector = xrStreamerWorld.processSectors [ processIndex ]
		if not sector then
			outputDebugString ( "Для процесса " .. processIndex .. " не было найдено сектора!", 2 )
			return
		end
		xrStreamerWorld.processSectors [ processIndex ] = nil
	
		sector.processLeft = sector.processLeft - 1
		
		if sector.processLeft == 0 and sector.targetRev then
			sector.rev = sector.targetRev
		end
		
		-- Если сектор не загружен, выходим из функции
		if xrStreamerWorld.activated [ sector ] ~= true or sector.loaded then
			return
		end
		
		-- Если все файлы построены, мы можем загрузить сектор
		if sector.processLeft == 0 then
			local err = sector:load ( )
			if err ~= true then
				outputDebugString ( "При загрузке сектора " .. sector._index .. " возникла ошибка! (" .. loadErrors [ err ] .. ")", 2 )
			end
			
			setElementAlpha ( sector.base, 255 )
			setElementAlpha ( sector.lod, 255 )
			
			--outputDebugString ( "Сектор " .. sector._index .. " был загружен после построения", 3 )
		end
	end
end

function xrStreamerWorld.rebuildAllSectors ( )
	local totalSectors = WORLD_SIZE_X * WORLD_SIZE_Y
	for i = 1, totalSectors do
		local sector = xrStreamerWorld.sectors [ i ]
		
		-- Ожидаем завершения построения двух файлов
		if sector.processLeft == 0 then
			sector.processLeft = 2
			local index = BuildOrder.wrap ( FastDFFBuilder.writeMap, sector )
			local index2 = BuildOrder.wrap ( FastCOLBuilder.writeMap, sector )
		
			xrStreamerWorld.processSectors [ index ] = sector
			xrStreamerWorld.processSectors [ index2 ] = sector
		end
	end
end

function xrStreamerWorld.findSector ( x, y, mapped )
	if mapped then
		local mapSizeX = Heightfield.resolutionX
		local mapSizeY = Heightfield.resolutionY
		x = _mathClamp ( 0, x, mapSizeX ) / MAP_SIZE
		y = _mathClamp ( 0, y, mapSizeY ) / MAP_SIZE
	else
		x = ( x - xrStreamerWorld.worldX ) / SECTOR_SIZE
		y = ( xrStreamerWorld.worldY - y ) / SECTOR_SIZE
	end
	
	local column = _mathFloor ( x )
	local row = _mathFloor ( y )
	local _index = row * WORLD_SIZE_X + column + 1 -- Пакуем координаты для быстрого поиска
	
	return xrStreamerWorld.sectors [ _index ]
end

function xrStreamerWorld.update ( )
	local x, y = getElementPosition ( localPlayer )
	if xrEngine.freecamMode then
		x, y = getCameraMatrix ( )
	end
	
	local sector = xrStreamerWorld.findSector ( x, y )
	if sector ~= xrStreamerWorld.sector then
		xrStreamerWorld.onSectorEnter ( sector )
	end
end

function xrStreamerWorld.unloadAll ( )
	for sector, _ in pairs ( xrStreamerWorld.activated ) do
		sector:streamOut ( )
		xrStreamerWorld.activated [ sector ] = nil
	end
	
	xrStreamerWorld.sector = nil
end

-- УДАЛИТЬ ПОСЛЕ ВВЕДЕНИЯ РИСОВАНИЯ!
function xrStreamerWorld._tempTextureCheck ( index )
	local path = "sectors/sector" .. index
	return fileExists ( path .. ".png" ) and fileExists ( path .. "_mask.png" )
end
function xrStreamerWorld.onSectorEnter ( sector )
	-- Строим список нужных секторов
	if xrStreamerWorld.sector then
		-- Выгружаем ненужные сектора
		local _, uncommon = sector:compareSurroundings ( xrStreamerWorld.sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if _sector ~= sector then
				if xrStreamerWorld.activated [ _sector ] then
					_sector:streamOut ( )
					xrStreamerWorld.activated [ _sector ] = nil
				end
			end
		end
		
		-- Теперь загружаем сектора
		local sectorsRequest = { --[[
			{ sectorIndex, textureMapChecksum },
			...
		]] }
		_, uncommon = xrStreamerWorld.sector:compareSurroundings ( sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				
				-- Добавляем в список загрузки если сектор еще не загружается
				if _sector.busy == nil and ( _sector.processLeft == nil or _sector.processLeft == 0 ) then
					table.insert ( sectorsRequest, { 
						_sector._index,
						xrStreamerWorld._tempTextureCheck ( _sector._index )
					} )
					
					_sector.busy = true
				end
				
				xrStreamerWorld.activated [ _sector ] = true
			end
		end
		
		if #sectorsRequest > 0 then
			triggerServerEvent ( "onSectorRequest", resourceRoot, REQUEST_SECTOR_FILES, sectorsRequest )
		end
	else
		local sectorsRequest = { --[[
			{ sectorIndex, textureMapChecksum },
			...
		]] }
		local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
		table.insert ( surrounding, 1, sector )
		for i, _sector in ipairs ( surrounding ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				
				table.insert ( sectorsRequest, { 
					_sector._index,
					xrStreamerWorld._tempTextureCheck ( _sector._index )
				} )
				
				_sector.busy = true

				xrStreamerWorld.activated [ _sector ] = true
			end
		end
		
		triggerServerEvent ( "onSectorRequest", resourceRoot, REQUEST_SECTOR_FILES, sectorsRequest )
	end
	
	-- Сообщаем серверу о вхождении в сектор
	setElementData ( localPlayer, "sector", sector._index )
	
	xrStreamerWorld.sector = sector
end

-- Обновляем пиксель на карте высот и вершину на модели
function xrStreamerWorld.setMapPixel ( x, y, level, buildSet )
	Heightfield.setLevel ( x, y, level )

	local sector = xrStreamerWorld.findSector ( x, y, true )
	if sector and xrStreamerWorld.activated [ sector ] and sector.loaded then
		local involvedSectors = { 
			sector
		}
	
		local worldSizeX = WORLD_SIZE_X * SECTOR_SIZE
		local worldSizeY = WORLD_SIZE_Y * SECTOR_SIZE
		local mapSizeX = Heightfield.resolutionX
		local mapSizeY = Heightfield.resolutionY
	
		if x % MAP_SIZE == 0 or y % MAP_SIZE == 0 then
			local surrounding = sector:getSurroundingSectors ( 1 )
			for _, surround in pairs ( surrounding ) do
				local deltaX = ( surround.x - xrStreamerWorld.worldX ) / worldSizeX
				local deltaY = ( xrStreamerWorld.worldY - surround.y ) / worldSizeY
				local mapX, mapY = _mathFloor ( deltaX * mapSizeX ), _mathFloor ( deltaY * mapSizeY )
	
				-- Если сектор касается пикселя
				if _withinRectangle ( x, y, mapX, mapY, MAP_SIZE, MAP_SIZE ) then
					involvedSectors [ #involvedSectors + 1 ] = surround
				end
			end
		end
	
		for i = 1, #involvedSectors do
			local involved = involvedSectors [ i ]
			local deltaX = ( involved.x - xrStreamerWorld.worldX ) / worldSizeX
			local deltaY = ( xrStreamerWorld.worldY - involved.y ) / worldSizeY
			local mapX, mapY = _mathFloor ( deltaX * mapSizeX ), _mathFloor ( deltaY * mapSizeY )
		
			local zpos = Heightfield.vertScale * level - HALF_ELEVATION
			involved:updateVertex ( x - mapX, y - mapY, zpos --[[(level * MAP_SPACING_Z) - HALF_ELEVATION]] )
			buildSet [ involved ] = true
		end
	end
end

--[[
	xrStreamerSector
]]
xrStreamerSector = { }
xrStreamerSector.__index = xrStreamerSector

--[[
	1, 2, 3,
	4,    5,
	6, 7, 8
]]

function xrStreamerSector.new ( x, y, size )
	local sector = {
		x = x, y = y,
		size = size,
		files = {
			
		}
	}
	
	if THREADED then
		sector.processLeft = 0
	end
	
	return setmetatable ( sector, xrStreamerSector )
end

local _lookup = {
	"_top", "_right", "_bottom", "_left"
}
function xrStreamerSector:getSurroundingSectors ( radius )
	local sectors = { self._left, self._top, self._right, self._bottom }
	local surround = { }
	
	for i = 1, radius do
		local steps = i * 2
		
		local _sectors = { sectors [ 1 ], sectors [ 2 ], sectors [ 3 ], sectors [ 4 ] }
		for i = 1, 4 do
			local sector = _sectors [ i ]
			for j = 1, steps do
				surround [ #surround + 1 ] = sector
				if sector then
					sector = sector [ _lookup [ i ] ]
					if i < 4 then
						sectors [ i + 1 ] = sector
					else
						sectors [ 1 ] = sector
					end
				end
			end
		end
	end
	
	return surround
end

function xrStreamerSector:isMySurroundingSector ( sector )
	local surrounding = self:getSurroundingSectors ( LOD_LEVEL )
	
	for _, _sector in ipairs ( surrounding ) do
		if _sector == sector then
			return true
		end
	end
	
	--[[for i = 1, 8 do
		if surrounding [ i ] and surrounding [ i ] == sector then
			return true
		end
	end]]
end

function xrStreamerSector:compareSurroundings ( sector, includeCenter )
	local common = { }
    local uncommon = { }

    local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
	for _, _sector in ipairs ( surrounding ) do
		if self:isMySurroundingSector ( _sector ) then
			--outputDebugString("common " .. surrounding[i].x .. ", " .. surrounding[i].y)
			table.insert ( common, _sector )
		else 
			--outputDebugString("uncommon " .. surrounding[i].x .. ", " .. surrounding[i].y)
			table.insert ( uncommon, _sector )
		end
	end
    --[[for i = 1, 8 do
        if surrounding [ i ] then
            if self:isMySurroundingSector ( surrounding [ i ] ) then
				--outputDebugString("common " .. surrounding[i].x .. ", " .. surrounding[i].y)
				table.insert ( common, surrounding [ i ] )
            else 
				--outputDebugString("uncommon " .. surrounding[i].x .. ", " .. surrounding[i].y)
				table.insert ( uncommon, surrounding [ i ] )
			end
        end
    end]]
	
	if includeCenter then
        if self:isMySurroundingSector ( sector ) then
			table.insert ( common, sector )
        else
			table.insert ( uncommon, sector )
		end
    end
	
	return common, uncommon
end

function xrStreamerSector:streamIn ( player )
	self.model = takeModel ( ) -- Резервируем модель для объекта

	self.base = createObject ( self.model, self.x + HALF_SECTOR_SIZE, self.y - HALF_SECTOR_SIZE, PATCH_Z )
	self.lod = createObject ( self.model, self.x + HALF_SECTOR_SIZE, self.y - HALF_SECTOR_SIZE, PATCH_Z - 0.1, 0, 0, 0, true )
	setLowLODElement ( self.base, self.lod )
	
	setElementAlpha ( self.base, 0 )
	setElementAlpha ( self.lod, 0 )
	
	triggerEvent ( "onClientSectorStreamIn", resourceRoot, self._index )
end

function xrStreamerSector:streamOut ( player )
	self:unload ( )

	freeModel ( self.model ) -- Освобождаем модель
	
	destroyElement ( self.base )
	destroyElement ( self.lod )
	
	triggerEvent ( "onClientSectorStreamOut", resourceRoot, self._index )
end

function xrStreamerSector:rebuild ( )
	-- Если потоковость включена, добавляем наши функции в очередь на выполнение
	if THREADED then
		-- Ожидаем завершения построения двух файлов
		if self.processLeft == 0 then
			self.processLeft = 2
	
			local index = BuildOrder.wrap ( FastDFFBuilder.writeMap, self )
			local index2 = BuildOrder.wrap ( FastCOLBuilder.writeMap, self )
		
			xrStreamerWorld.processSectors [ index ] = self
			xrStreamerWorld.processSectors [ index2 ] = self
		else
			outputDebugString ( "Сектор " .. self._index .. " уже строится!", 2 )
		end
		
	-- В противном случае просто выполняем их
	else
		local ticks = getTickCount ( )
		FastDFFBuilder.writeMap ( self )
		FastCOLBuilder.writeMap ( self )
		
		outputDebugString ( "[FAST]Sector " .. self._index .. " rebuilded in " .. getTickCount ( ) - ticks .. " ms" )
	end
end

function xrStreamerSector:updateVertex ( x, y, level )
	if ( x < 0 or x > MAP_SIZE ) or ( y < 0 or y > MAP_SIZE ) then
		return
	end

	level = _mathClamp ( -299.9, level, 299.9 )
	
	local vertexIndex =  x * (MAP_SIZE+1) + y

	-- Перестраиваем модель и коллизию
	FastDFFBuilder.setModelVertex ( self, vertexIndex, level )
	FastCOLBuilder.setModelVertex ( self, vertexIndex, level )
end

function xrStreamerSector:load ( )
	if self.loaded then
		outputDebugString ( "Модель уже загружена!", 2 )
		return 4
	end
	
	engineImportTXD ( xrEngine.mainTXD, self.model )

	local path = "sectors/" .. self._index .. ".dff"
	if fileExists ( path ) then
		self.dff = engineLoadDFF ( path, 0 )
		
		if self.dff == false or engineReplaceModel ( self.dff, self.model, false ) ~= true then
			self:unload ( )
			return 0
		end
	else
		self:unload ( )
		return 1
	end
	
	local path = "sectors/" .. self._index .. ".col"
	if fileExists ( path ) then
		self.col = engineLoadCOL ( path )
		if self.col == false or engineReplaceCOL ( self.col, self.model ) ~= true then
			self:unload ( )
			return 2
		end
	else
		self:unload ( )
		return 3
	end
	
	engineSetModelLODDistance ( self.model, 600 )
	
	self.loaded = true
	
	--if self._index == spawnSectorIndex then
		triggerServerEvent ( "onPlayerSectorLoaded", resourceRoot, self._index, true )
	--end
	
	return true
end

function xrStreamerSector:unload ( )
	if self.loaded then
		engineRestoreModel ( self.model )
		if isElement ( self.dff ) then
			destroyElement ( self.dff )
		end
		engineRestoreCOL ( self.model )
		if isElement ( self.col ) then
			destroyElement ( self.col )
		end
	
		--if self._index == spawnSectorIndex then
			triggerServerEvent ( "onPlayerSectorLoaded", resourceRoot, self._index )
		--end
	
		self.loaded = false
	else
		--outputDebugString ( "Модель должна быть загружена!", 2 )
	end
end

function xrStreamerSector:reload ( )
	self:unload ( )
	local err = self:load ( )
	if err ~= true then
		outputDebugString ( "Модель сектора " .. self._index .. " не может быть загружена! (" .. loadErrors [ err ] .. ")", 2 )
	end
end

function xrStreamerSector:getMaskChecksum ( )
	local checksum = self.maskMd5
	if checksum then
		return checksum
	end
	
	return ""
end

local treeModels = {
	615, 616, 617, 618, 707, 778, 782, 760
}
local grassModels = {
	707, 760, 761, 759
}

addEvent ( "onClientSectorRevision", true )
addEventHandler ( "onClientSectorRevision", resourceRoot,
	function ( index, revision, filesNum )
		local sector = xrStreamerWorld.sectors [ index ]
		if sector == nil then
			outputDebugString ( tostring ( index ) .. " сектора не существует!", 2 )
			return
		end
		
		--[[if xrStreamerWorld.activated [ sector ] ~= true then
			outputDebugString ( "Сектор должен быть загружен!", 2 )
			return
		end]]
		
		sector.filePending = filesNum
		
		-- Если ревизия сектора не совпадает с фактической, выходим и ждем карты высот
		if sector.rev ~= revision or filesNum > 1 then
			sector.needToRebuild = true
			sector.targetRev = revision
			return
		end
		
		if xrStreamerWorld.activated [ sector ] then
			setElementAlpha ( sector.base, 255 )
			setElementAlpha ( sector.lod, 255 )
		
			-- В противном случае мы можем ей сразу же загрузить
			local err = sector:load ( )
			if err ~= true then
				outputDebugString ( "При загрузке сектора " .. index .. " возникла ошибка! (" .. loadErrors [ err ] .. ")", 2 )
				return
			end
		
			--outputDebugString ( "Сектор " .. index .. " загружен из актуальной модели", 3 )
		end
	end
, false )

addEvent ( "onClientSectorResponse", true )
addEventHandler ( "onClientSectorResponse", resourceRoot,
	function ( fileType, index, content, arg )
		local sector = xrStreamerWorld.sectors [ index ]
		if sector == nil then
			outputDebugString ( tostring ( index ) .. " сектора не существует!", 2 )
			return
		end
		
		-- Heightfield
		if fileType == FILE_HM then
			local posX = sector.x - xrStreamerWorld.worldX
			local posY = xrStreamerWorld.worldY - sector.y
		
			local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
			local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
			local mapX, mapY = posX / worldSizeX, posY / worldSizeY
			local borderX = Heightfield.resolutionX - WORLD_SIZE_X * MAP_SIZE
			local borderY = Heightfield.resolutionY - WORLD_SIZE_Y * MAP_SIZE
			local pixelX, pixelY = math.floor ( ( Heightfield.resolutionX - borderX ) * mapX ), math.floor ( ( Heightfield.resolutionY - borderY ) * mapY )
		
			Heightfield.fill ( pixelX, pixelY, MAP_SIZE + 1, MAP_SIZE + 1, content )
		end
		
		sector.filePending = sector.filePending - 1
		
		--[[if sector.loaded ~= true then
			if sector.rev ~= revision then
				sector:rebuild ( )
				sector.rev = revision
				xrStreamerWorld.updateSectorRev ( index - 1, revision )
				outputDebugString ( "Ревизия сектора " .. index .. " обновлена до " .. revision )
			end
			local err = sector:load ( )
			-- Если возникла ошибка, пробуем еще раз перестроить и заменить
			if err ~= true then
				sector:rebuild ( )
				err = sector:load ( )
				if err ~= true then
					outputDebugString ( "Модель сектора " .. index .. " не может быть загружена! (" .. loadErrors [ err ] .. ")", 2 )
				end
			end
			
			setElementAlpha ( sector.base, 255 )
			setElementAlpha ( sector.lod, 255 )
			
			outputDebugString ( "Сектор " .. index .. " создан по карте высот", 3 )
		end]]
		
		if sector.filePending == 0 then
			sector.busy = nil
		
			if xrStreamerWorld.activated [ sector ] and sector.needToRebuild then
				sector:rebuild ( )
			end
			sector.needToRebuild = nil
		end
	end
, false )