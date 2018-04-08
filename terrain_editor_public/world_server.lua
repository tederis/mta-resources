SECTOR_SIZE = 150
HALF_SECTOR_SIZE = SECTOR_SIZE / 2 --75 now
WORLD_WIDTH = 6000
WORLD_HEIGHT = 6000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE --40 now
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE --40 now
HOR_SCALE = 3
MAP_SIZE = SECTOR_SIZE / HOR_SCALE --50 now

SMOOTH_TERRAIN = false
COMPACT_XTD = false -- Если true - паковать высоту в short. Если false - хранить во float

LOD_LEVEL = 2

PATCH_Z = 0

MAP_SPACING_Z = 1
MAP_MAX_ELEVATION = math.floor ( 299 * MAP_SPACING_Z )
HALF_ELEVATION = MAP_MAX_ELEVATION / 2

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
	senders = { },
	
	hffMD5 = nil
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
	
	-- Вычисляем хэш-сумму для исходного файла высоты
	if fileExists ( "worlds/heightmap.hff" ) then
		local hmFile = fileOpen ( "worlds/heightmap.hff", true )
		local hmContent = fileRead ( hmFile, fileGetSize ( hmFile ) )
		xrStreamerWorld.hffMD5 = md5 ( hmContent )
		fileClose ( hmFile )
	else
		outputDebugString ( "Не был найден исходный файл ландшафта", 2 )
		return
	end
	
	-- Если файл секторов существует, загружаем данные из него
	if fileExists ( "worlds/patches.xtd" ) then
		local file = fileOpen ( "worlds/patches.xtd", false )
		if xrStreamerWorld.preLoadPatches ( file ) then
			outputChatBox ( "Идет загрузка ландшафта... Это может занять некоторое время.", root, 0, 200, 0 )
	
			g_ProcessCr = coroutine.create ( xrStreamerWorld.loadPatches )
			local ok, err = coroutine.resume ( g_ProcessCr, file )
			if err == false then
				outputDebugString ( "При загрузке произошла критическая ошибка" )
			end
			
			xrStreamerWorld.worldRaw = file
			
			return true
		end
		
		fileClose ( file )
	end

	-- Иначе создаем файл секторов из исходного
	outputChatBox ( "Идет создание ландшафта... Это может занять некоторое время.", root, 0, 200, 0 )
	xrStreamerWorld.processPatches ( 1 )
end

function xrStreamerWorld.stop ( )
	if xrStreamerWorld.worldRaw then
		fileClose ( xrStreamerWorld.worldRaw )
		xrStreamerWorld.worldRaw = nil
	end
end

function xrStreamerWorld.processPatches ( action )
	if action == 1 then
		g_ProcessCrHF = coroutine.create ( Heightfield.loadFromBinary )
		coroutine.resume ( g_ProcessCrHF, "worlds/heightmap.hff", xrStreamerWorld.processPatches, SMOOTH_TERRAIN == true and 2 or 3 )
	elseif action == 2 then
		g_ProcessCr = coroutine.create ( Heightfield.smooth )
		coroutine.resume ( g_ProcessCr, xrStreamerWorld.processPatches, 3 )
	elseif action == 3 then
		xrStreamerWorld.worldRaw = fileCreate ( "worlds/patches.xtd", false )
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
	
	if fileExists ( "worlds/patches.xtd" ) then
		local file = fileOpen ( "worlds/patches.xtd", false )
		
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
	
	if fileExists ( "worlds/patches.xtd" ) then
		local file = fileOpen ( "worlds/patches.xtd", false )
		
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
	local resolutionX = Heightfield.resolutionX
	local resolutionY = Heightfield.resolutionY
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
	
	fileWrite ( file, xrStreamerWorld.hffMD5 )
	
	-- Resolution
	dataToBytes ( file, "ui", resolutionX )
	dataToBytes ( file, "ui", resolutionY )
	
	dataToBytes ( file, "ui", COMPACT_XTD == true and 1 or 0 )
	
	-- And some
	dataToBytes ( file, "f", Heightfield.vertScale )
	dataToBytes ( file, "ui", Heightfield.vertOffset )
	dataToBytes ( file, "ui", Heightfield.horScale )
	
	-- Map saving hatch
	Heightfield.setRawData ( file, fileGetPos ( file ) )
	
	for i = 1, pixelsTotal do
		-- Запаковываем высоту и записываем ее в файл
		local level = map [ i ]
		if COMPACT_XTD then
			dataToBytes ( file, "s", 128 * level )
		else
			dataToBytes ( file, "f", level )
		end

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

function xrStreamerWorld.preLoadPatches ( file )
	local lastMD5 = fileRead ( file, 32 )
	return xrStreamerWorld.hffMD5 == lastMD5
end

function xrStreamerWorld.loadPatches ( file )
	local resX = bytesToData ( "ui", fileRead ( file, 4 ) )
	local resY = bytesToData ( "ui", fileRead ( file, 4 ) )
	if type ( resX ) ~= "number" or type ( resY ) ~= "number" then
		outputDebugString ( "Invalid patch file header", 2 )
		return
	end
	
	local pixelsTotal = resX*resY
	local patchesTotal = WORLD_SIZE_X * WORLD_SIZE_Y
	
	local isCompact = bytesToData ( "ui", fileRead ( file, 4 ) ) == 1
	if isCompact ~= COMPACT_XTD then
		outputDebugString ( "Файл секторов не может быть загружен. Тип пикселя не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
	end
	
	local pixelSize = COMPACT_XTD == true and 2 or 4
	local expectedSize = 24 + 32 + (pixelsTotal*pixelSize) + 4 + (patchesTotal*4)
	if expectedSize ~= fileGetSize ( file ) then
		outputDebugString ( "Файл секторов не может быть загружен. Размер файла не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
	end
	
	local opsTotal = patchesTotal + pixelsTotal
	local opsNum = 0
	local opsLimit = 0
	local _pause = function ( )
		local progress = opsNum / opsTotal
		outputDebugString ( "Load patches " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCr ) end, 50, 1 )
		coroutine.yield ( )
	end
	
	outputDebugString ( "Грузим ландшафт " .. pixelsTotal .. " точек" )
	
	local vertScale = bytesToData ( "f", fileRead ( file, 4 ) )
	local vertOffset = bytesToData ( "ui", fileRead ( file, 4 ) )
	local horScale = bytesToData ( "ui", fileRead ( file, 4 ) )
	
	local mapSize = resX * resY
	if mapSize ~= pixelsTotal then
		outputDebugString ( "Файл секторов не может быть загружен. Количество пикселей не соответствует ожидаемому.", 2 )
		coroutine.yield ( false )
		return
	end
	
	Heightfield.setRawData ( file, fileGetPos ( file ) )
	
	-- В первую очередь загружаем карту высот
	local tempMap = { }
	
	for i = 1, pixelsTotal do
		if COMPACT_XTD then
			local level = bytesToData (
				"s",
				fileRead ( file, 2 )
			)
			-- Распаковываем высоту
			tempMap [ i ] = level / 128
		else
			local level = bytesToData (
				"f",
				fileRead ( file, 4 )
			)
		
			tempMap [ i ] = level
		end
		
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
	
	Heightfield.resolutionX = resX
	Heightfield.resolutionY = resY
	Heightfield.vertScale = vertScale
	Heightfield.vertOffset = vertOffset
	Heightfield.horScale = horScale
	
	xrEngine.onWorldLoaded ( )
	outputChatBox ( "Загрузка ландшафта завершена. Система готова к работе.", root, 0, 200, 0 )
end

function xrStreamerWorld.findSector ( x, y, mapped )
	if mapped then
		x = _mathClamp ( 0, x, Heightfield.resolutionX ) / MAP_SIZE
		y = _mathClamp ( 0, y, Heightfield.resolutionY ) / MAP_SIZE
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
	
					local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
					local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
					local mapX, mapY = posX / worldSizeX, posY / worldSizeY
					local borderX = Heightfield.resolutionX - WORLD_SIZE_X * MAP_SIZE
					local borderY = Heightfield.resolutionY - WORLD_SIZE_Y * MAP_SIZE
					local pixelX, pixelY = math.floor ( ( Heightfield.resolutionX - borderX ) * mapX ), math.floor ( ( Heightfield.resolutionY - borderY ) * mapY )
					
					-- Сразу же отправляем ревизию клиенту, чтобы при наличии актуальной версии не ждать карту высот и загрузить модель
					triggerClientEvent ( client, "onClientSectorRevision", resourceRoot, sectorIndex, sector.rev, --[[needToTexture and 3 or]] 1 )
					
					-- Добавляем в очередь на отправку файлы
					sender:extendOrder ( FILE_HM, sectorIndex, Heightfield.grab, pixelX, pixelY, MAP_SIZE + 1, MAP_SIZE + 1 )
					
					--if sectorRev ~= sector.rev then
					--[[if needToTexture then
						sender:extendOrder ( FILE_TX, sectorIndex, _getFileContent, "sectors/sector" .. sectorIndex .. ".png" )
						sender:extendOrder ( FILE_MASK, sectorIndex, _getFileContent, "sectors/sector" .. sectorIndex .. "_mask.png" )
					end]]
					
					--outputDebugString ( "Отправляем " .. filesToSend .. " файлов" )
				else
					outputDebugString ( "Сектора с индексом " .. sectorIndex .. " не существует", 1 )
				end
			end
		end
	end
, false )