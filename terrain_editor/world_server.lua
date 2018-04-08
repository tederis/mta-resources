SECTOR_SIZE = 150
HALF_SECTOR_SIZE = SECTOR_SIZE / 2
WORLD_WIDTH = 9000
WORLD_HEIGHT = 9000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE --45 now
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE --60 now
-- 2700 всего

-- 2048 = 8 секторов

MAP_STEP = 3
MAP_SIZE = SECTOR_SIZE / MAP_STEP --50 now

MAP_RES_X = WORLD_SIZE_X * MAP_SIZE
MAP_RES_Y = WORLD_SIZE_Y * MAP_SIZE

LOD_LEVEL = 2

FILE_HM = 1
FILE_TX = 2
FILE_MASK = 3

DEFAULT_PATTERN = [[]]

local REQUEST_SECTOR_FILES = 0

local _mathMin = math.min
local _mathMax = math.max
local _mathFloor = math.floor
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end

--[[
	xrPlayerSender
]]
xrPlayerSender = { }
xrPlayerSender.__index = xrPlayerSender

function xrPlayerSender.new ( player )
	local sender = {
		player = player,
		order = { }
	}
	
	return setmetatable ( sender, xrPlayerSender )
end

function xrPlayerSender:extendOrder ( fileType, sectorIndex, fn, ... )
	local file = {
		fileType, sectorIndex,
		fn, { ... }
	}
	table.insert ( self.order, file )
end

function xrPlayerSender:updatePulse ( )
	local file = self.order [ 1 ]
	if file == nil then
		return false
	end
	
	local content = file [ 3 ] ( unpack ( file [ 4 ] ) )
	triggerLatentClientEvent ( self.player, "onClientSectorResponse", 500000, resourceRoot, file [ 1 ], file [ 2 ], content )
	
	--outputDebugString ( "Файл " .. file [ 1 ] .. " отправлен" )
	
	table.remove ( self.order, 1 )
	
	return #self.order > 0
end

--[[
	xrStreamerWorld
]]
xrStreamerWorld = { 
	sectors = { },
	senders = { }
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
			--[[local maskPath = "sectors/" .. _index .. ".png"
			if fileExists ( maskPath ) then
				local file = fileOpen ( maskPath, true )
				local content = fileRead ( file, 
					fileGetSize ( file ) 
				)
				fileClose ( file )
				
				sector.maskMd5 = md5 ( content )
			else
				local patternFile = fileOpen ( "mask.png", true )
				local pattern = fileRead ( patternFile, fileGetSize ( patternFile ) )
				fileClose ( patternFile )
				
				local file = fileCreate ( maskPath )
				fileWrite ( file, patternFile )
				fileClose ( file )
				
				sector.maskMd5 = DEFAULT_PATTERN
			end]]
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
	
	if fileExists ( "heightmap.xtg" ) ~= true then
		outputDebugString ( "Не существует файла высот. Невозможно создать файл секторов.", 2 )
		return
	end
	local heightmapRev = xrStreamerWorld.pullFileRev ( "heightmap.xtg" )
	
	-- Если файл секторов существует, загружаем данные из него
	if fileExists ( "patches.xtd" ) and xrStreamerWorld.pullFileRev ( "patches.xtd" ) == heightmapRev then
		outputChatBox ( "Идет загрузка ландшафта... Это может занять некоторое время.", root, 0, 200, 0 )
	
		xrStreamerWorld.worldRaw = fileOpen ( "patches.xtd", false )
		g_ProcessCr = coroutine.create ( xrStreamerWorld.loadPatches )
		local ok, err = coroutine.resume ( g_ProcessCr, xrStreamerWorld.worldRaw )
		if err == false then
			outputDebugString ( "При загрузке произошла критическая ошибка" )
		end
	-- В противном случае пытаемся создать файл секторов
	else
		outputChatBox ( "Идет создание ландшафта... Это может занять некоторое время.", root, 0, 200, 0 )
	
		xrStreamerWorld.worldRev = heightmapRev
		xrStreamerWorld.processPatches ( 1 )
	end
end

function xrStreamerWorld.stop ( )
	fileClose ( xrStreamerWorld.worldRaw )
end

function xrStreamerWorld.processPatches ( action )
	if action == 1 then
		g_ProcessCrHF = coroutine.create ( Heightfield.loadFromBinary )
		coroutine.resume ( g_ProcessCrHF, "heightmap.xtg", xrStreamerWorld.processPatches, 3 )
	elseif action == 2 then
		g_ProcessCr = coroutine.create ( Heightfield.smooth )
		coroutine.resume ( g_ProcessCr, xrStreamerWorld.processPatches, 3 )
	elseif action == 3 then
		xrStreamerWorld.worldRaw = fileCreate ( "patches.xtd", false )
		g_ProcessCr = coroutine.create ( xrStreamerWorld.fillPatches )
		coroutine.resume ( g_ProcessCr, xrStreamerWorld.worldRaw )
	end
end

function xrStreamerWorld.updateSectorRev ( index, rev )
	rev = tonumber ( rev )
	if rev == nil then
		outputDebugString ( "Ревизия должна быть числом", 2 )
		return
	end
	
	if fileExists ( "patches.xtd" ) then
		local file = fileOpen ( "patches.xtd", false )
		
		local pixelsTotal = 2048^2
		local offset = 4 + (pixelsTotal*2)
		
		fileSetPos ( file, offset + 4 + 4*index )
		dataToBytes ( file, "ui", rev )
		
		fileClose ( file )
	else
		outputDebugString ( "Файла ревизий не существует", 2 )
	end
end

function xrStreamerWorld.updateSectorPixel ( x, y, level )
	level = tonumber ( level )
	if level == nil then
		outputDebugString ( "Уровень должен быть числом", 2 )
		return
	end
	
	if fileExists ( "patches.xtd" ) then
		local file = fileOpen ( "patches.xtd", false )
		
		local pixelsTotal = 2048^2
		local offset = 4 + (pixelsTotal*2)
		
		fileSetPos ( file, offset + 4 + 4*index )
		dataToBytes ( file, "ui", rev )
		
		fileClose ( file )
	else
		outputDebugString ( "Файла ревизий не существует", 2 )
	end
end

function xrStreamerWorld.fillPatches ( file )
	local patchesTotal = WORLD_SIZE_X * WORLD_SIZE_Y
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	local pixelsTotal = resolutionX*resolutionY
	local opsTotal = patchesTotal + pixelsTotal
	local opsNum = 0
	local opsLimit = 0
	local _pause = function ( )
		local progress = opsNum / opsTotal
		outputDebugString ( "Fill patches " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCr ) end, 50, 1 )
		coroutine.yield ( )
	end
	local map = Heightfield.get ( )
	
	-- Пишем ревизию мира
	dataToBytes ( file, "ui", xrStreamerWorld.worldRev )
	
	
	-- Сначала пишем высоту
	dataToBytes ( file, "ui", pixelsTotal )
	
	Heightfield.setRawData ( file, fileGetPos ( file ) )
	
	for i = 1, pixelsTotal do
		-- Запаковываем высоту и записываем ее в файл
		local level = map [ i ]
		dataToBytes ( file, "s", 128 * level )

		opsNum = opsNum + 1
		opsLimit = opsLimit + 1
		if opsLimit > 40000 then
			opsLimit = 0
			
			_pause ( )
		end
	end
	
	-- Затем пишем ревизии
	dataToBytes ( file, "ui", patchesTotal )
	for i = 1, patchesTotal do
		dataToBytes ( file, "ui", 1 )
		
		local sector = xrStreamerWorld.sectors [ i ]
		if sector then
			sector.rev = 1
		else
			outputDebugString ( "Сектора по индексу " .. i .. " не существует!", 2 )
		end
		
		opsNum = opsNum + 1
		opsLimit = opsLimit + 1
		if opsLimit > 40000 then
			opsLimit = 0
			
			_pause ( )
		end
	end
	
	xrEngine.onWorldLoaded ( )
	outputDebugString ( "Подготовка секторов завершена. Система готова к работе.", 3 )
end

function xrStreamerWorld.pullFileRev ( fileName )
	local file = fileOpen ( fileName, true )
	if file then
		local worldRevNum = bytesToData (
			"ui",
			fileRead ( file, 4 )
		)
		
		fileClose ( file )
		
		return tonumber ( worldRevNum ) or 0
	else
		outputDebugString ( "Невозможно открыть файл мира", 2 )
	end
end

function xrStreamerWorld.loadPatches ( file )
	local patchesTotal = WORLD_SIZE_X * WORLD_SIZE_Y
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	local pixelsTotal = resolutionX*resolutionY
	
	local expectedSize = 4 + (pixelsTotal*2) + 4 + (patchesTotal*4) + 4
	if expectedSize ~= fileGetSize ( file ) then
		outputDebugString ( "Файл секторов не может быть загружен. Размер файла не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
	end
	
	local opsTotal = patchesTotal + pixelsTotal
	local opsNum = 0
	local opsLimit = 0
	local _pause = function ( )
		--local progress = opsNum / opsTotal
		--outputDebugString ( "Load patches " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCr ) end, 50, 1 )
		coroutine.yield ( )
	end
	
	outputDebugString ( "Грузим ландшафт " .. pixelsTotal .. " точек" )
	
	-- Перепрыгиваем через ревизию
	fileSetPos ( file, 4 )

	-- В первую очередь загружаем карту высот
	local tempMap = { }
	
	local mapSize = bytesToData (
		"ui",
		fileRead ( file, 4 )
	)
	if mapSize ~= pixelsTotal then
		outputDebugString ( "Файл секторов не может быть загружен. Количество пикселей не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
		return
	end
	
	Heightfield.setRawData ( file, fileGetPos ( file ) )
	
	for i = 1, pixelsTotal do
		local level = bytesToData (
			"s",
			fileRead ( file, 2 )
		)
		
		if not tonumber ( level ) then
			outputDebugString ( "При чтении высоты возникла ошибка.", 2 )
		end
		
		-- Распаковываем высоту
		tempMap [ i ] = level / 128
		
		opsNum = opsNum + 1
		opsLimit = opsLimit + 1
		if opsLimit > 100000 then
			opsLimit = 0

			_pause ( )
		end
	end
	
	Heightfield.set ( tempMap )
	
	-- Затем грузим ревизии
	local sectorsNum = bytesToData (
		"ui",
		fileRead ( file, 4 )
	)
	if sectorsNum ~= patchesTotal then
		outputDebugString ( "Файл секторов не может быть загружен. Количество секторов не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
		return
	end
	
	for i = 1, patchesTotal do
		local revNum = bytesToData (
			"ui",
			fileRead ( file, 4 )
		)
		
		if not tonumber ( revNum ) then
			outputDebugString ( "При чтении ревизии сектора " .. i .. " возникла ошибка.", 2 )
			coroutine.yield ( false )
		end
		
		local sector = xrStreamerWorld.sectors [ i ]
		if sector then
			sector.rev = revNum
		else
			outputDebugString ( "Сектора по индексу " .. i .. " не существует!", 2 )
			coroutine.yield ( false )
		end
		
		opsNum = opsNum + 1
		opsLimit = opsLimit + 1
		if opsLimit > 100000 then
			opsLimit = 0
			
			_pause ( )
		end
	end
	
	xrEngine.onWorldLoaded ( )
	outputChatBox ( "Загрузка ландшафта завершена. Система готова к работе.", root, 0, 200, 0 )
end

function xrStreamerWorld.findSector ( x, y, mapped )
	if mapped then
		local mapSizeX = WORLD_SIZE_X * MAP_SIZE
		local mapSizeY = WORLD_SIZE_Y * MAP_SIZE
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

function xrStreamerWorld.definePlayerSender ( player )
	local sender = xrStreamerWorld.senders [ player ]
	if sender == nil then
		sender = xrPlayerSender.new ( player )
		xrStreamerWorld.senders [ player ] = sender
	end
	
	return sender
end

-- Из xrEngine.onUpdate ( ) server.lua
function xrStreamerWorld.onUpdatePulse ( )
	for player, sender in pairs ( xrStreamerWorld.senders ) do
		if isElement ( player ) ~= true or sender:updatePulse ( ) ~= true then
			xrStreamerWorld.senders [ player ] = nil
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

function xrStreamerSector:isMySurroundingSector ( sector, radius )
	local surrounding = self:getSurroundingSectors ( tonumber ( radius ) or LOD_LEVEL )
	
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

function xrStreamerSector:compareSurroundings ( sector, includeCenter, radius )
	local common = { }
    local uncommon = { }

    local surrounding = sector:getSurroundingSectors ( tonumber ( radius ) or LOD_LEVEL )
	for _, _sector in ipairs ( surrounding ) do
		if self:isMySurroundingSector ( _sector, radius ) then
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
        if self:isMySurroundingSector ( sector, radius ) then
			table.insert ( common, sector )
        else
			table.insert ( uncommon, sector )
		end
    end
	
	return common, uncommon
end

function xrStreamerSector:fileExists ( fileType )
	local filePath = "sectors/" .. self._index .. "." .. fileType
	if fileExists ( filePath ) then
		local file = fileOpen ( filePath, true )
		local content = fileRead ( file, fileGetSize ( file ) )
		fileClose ( file )
		return md5 ( content )
	end
end

local _getFileContent = function ( filename )
	if fileExists ( filename ) then
		local file = fileOpen ( filename, true )
		local content = fileRead ( file, fileGetSize ( file ) )
		fileClose ( file )
		
		return content
	end
end

addEvent ( "onSectorRequest", true )
addEventHandler ( "onSectorRequest", resourceRoot,
	function ( requestType, arg0 )
		if requestType == REQUEST_SECTOR_FILES then
			local sender = xrStreamerWorld.definePlayerSender ( client )
		
			for _, data in ipairs ( arg0 ) do
				local sectorIndex = data [ 1 ]
				--local sectorRev = data [ 2 ]
				local needToTexture = data [ 2 ] ~= true
				
				local sector = xrStreamerWorld.sectors [ sectorIndex ]
				if sector then
					local posX = sector.x - xrStreamerWorld.worldX
					local posY = xrStreamerWorld.worldY - sector.y
	
					local mapSizeX = SECTOR_SIZE * WORLD_SIZE_X
					local mapSizeY = SECTOR_SIZE * WORLD_SIZE_Y
					local mapX, mapY = posX / mapSizeX, posY / mapSizeY
					local resX = WORLD_SIZE_X * MAP_SIZE
					local resY = WORLD_SIZE_Y * MAP_SIZE
					local pixelX, pixelY = math.floor ( resX * mapX ), math.floor ( resY * mapY )
					
					-- Сразу же отправляем ревизию клиенту, чтобы при наличии актуальной версии не ждать карту высот и загрузить модель
					triggerClientEvent ( client, "onClientSectorRevision", resourceRoot, sectorIndex, sector.rev, needToTexture and 3 or 1 )
					
					-- Добавляем в очередь на отправку файлы
					sender:extendOrder ( FILE_HM, sectorIndex, Heightfield.grab, pixelX, pixelY, MAP_SIZE + 1, MAP_SIZE + 1 )
					
					--if sectorRev ~= sector.rev then
					if needToTexture then
						sender:extendOrder ( FILE_TX, sectorIndex, _getFileContent, "sectors/sector" .. sectorIndex .. ".png" )
						sender:extendOrder ( FILE_MASK, sectorIndex, _getFileContent, "sectors/sector" .. sectorIndex .. "_mask.png" )
					end
					
					--outputDebugString ( "Отправляем " .. filesToSend .. " файлов" )
				else
					outputDebugString ( "Сектора с индексом " .. sectorIndex .. " не существует", 1 )
				end
			end
		end
	end
, false )