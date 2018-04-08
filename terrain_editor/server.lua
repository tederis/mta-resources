local _mathFloor = math.floor
local _mathSqrt = math.sqrt
local _mathMin = math.min
local _mathMax = math.max
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end
local _dist2d = getDistanceBetweenPoints2D

BrushModes = {
	RAISE = 1,
	LOWER = 2,
	SMOOTH = 3,
	FLATTEN = 4
}

EasingTypes = {
	"Linear",
	"InQuad",
	"OutQuad",
	"InOutQuad",
	"OutInQuad",
	"InElastic",
	"OutElastic",
	"InOutElastic",
	"OutInElastic",
	"InBack",
	"OutBack",
	"InOutBack",
	"OutInBack",
	"InBounce",
	"OutBounce",
	"InOutBounce",
	"OutInBounce",
	"SineCurve",
	"CosineCurve"
}

xrEngine = { }

function xrEngine.init ( )
	-- Удаляем стандартную карту
	for i = 550, 20000 do
		removeWorldModel ( i, 10000, 0, 0, 0 )
	end
	setOcclusionsEnabled ( false )
	
	-- Создаем воду
	--[[local height = 0
	local SizeVal = 2998
	
	local southWest_X = -SizeVal
	local southWest_Y = -SizeVal
	local southEast_X = SizeVal
	local southEast_Y = -SizeVal
	local northWest_X = -SizeVal
	local northWest_Y = SizeVal
	local northEast_X = SizeVal
	local northEast_Y = SizeVal
	
	createWater ( southWest_X, southWest_Y, height, southEast_X, southEast_Y, height, northWest_X, northWest_Y, height, northEast_X, northEast_Y, height )
	
	setWaterLevel ( 0 )]]
	
	setCloudsEnabled ( false )
	
	xrStreamerWorld.init ( )
end

function xrEngine.stop ( )
	xrStreamerWorld.stop ( )
	outputDebugString ( "Движок редактора ландшафта остановлен" )
end

-- Вызывается когда мир загружен
function xrEngine.onWorldLoaded ( )
	-- Запоминаем что наш мир загружен
	xrEngine.loaded = true
	
	outputChatBox("on loaded 1")
	triggerClientEvent ( "onClientTerrainReady", resourceRoot )
	
	setTimer ( xrEngine.onUpdate, 100, 0 )
end

function xrEngine.getPlayerLODLevel ( player )
	local level = getElementData ( player, "lodlevel", false )
	return tonumber ( level ) or LOD_LEVEL
end

function xrEngine.onPlayerHitSector ( player, sector )

end

function xrEngine.onPlayerLeaveSector ( player, sector )
	
end

function xrEngine.onUpdate ( )
	xrStreamerWorld.onUpdatePulse ( )
end

--[[
	Heightfield
]]
Heightfield = { 
	resolution = 2048,
	--revision = 0
}
local heightData = { }

function Heightfield.setRawData ( file, startWith )
	Heightfield.raw = file
	Heightfield.rawStart = startWith
end

function Heightfield.grab ( x, y, width, height )
	local data = { }
	
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	
	for j = 0, height-1 do
		for i = 0, width-1 do
			local level = Heightfield.getLevel ( x + i, y + j )
			local index = j * resolutionX + i
			data [ index + 1 ] = level
		end
	end
	
	return data
end

function Heightfield.loadFromBinary ( fileName, callback, ... )
	local hfFile = fileOpen ( fileName, true )
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	local pixelsTotal = resolutionX * resolutionY
	local pixelsNum = 0
	local pixelsLimit = 0
	local _pause = function ( )
		local progress = pixelsNum / pixelsTotal
		outputDebugString ( "Load heightfield " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCrHF ) end, 50, 1 )
		coroutine.yield ( )
	end
	
	local heightmapSize = fileGetSize ( hfFile )
	if 4 + pixelsTotal*2 ~= heightmapSize then
		outputDebugString ( "Файл высоты не может быть загружен. Размер файла не соответствует ожидаемому.", 2 )
		return
	end
	
	-- Перепрыгиваем ревизию карты
	local heightfieldRev = bytesToData ( "ui", fileRead ( hfFile, 4 ) )
	
	for i = 1, pixelsTotal do
		-- Читаем высоту из буфера и заполняем таблицу
		local level = bytesToData ( "s", fileRead ( hfFile, 2 ) )
		
		if not tonumber ( level ) then
			outputDebugString ( "Ошибка при чтении карты высот", 2 )
		end
		
		heightData [ i ] = level / 128
		
		pixelsNum = pixelsNum + 1
		pixelsLimit = pixelsLimit + 1
		if pixelsLimit > 80000 then
			pixelsLimit = 0

			_pause ( )
		end
	end
	
	fileClose ( hfFile )
	
	outputDebugString ( "Файл высот успешно прочитан с ревизией " .. tostring ( heightfieldRev or 0 ), 3 )
	
	if type ( callback ) == "function" then
		callback ( ... )
	end
end

function Heightfield.saveToBinary ( file, callback, ... )
	local calls = 0
	
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	
	-- Записываем в буфер размер
	dataToBytes ( file, "ui", Heightfield.resolution )

	local size = resolutionX*resolutionY
	for i = 1, size do
		-- Сохраняем в буфер высоту из таблицы
		local level = heightData [ i ]
		dataToBytes ( file, "s", 128 * level )
		
		if i == size and type ( callback ) == "function" then
			callback ( ... )
		end
		
		calls = calls + 1
		if calls > 100000 then
			calls = 0
			
			outputDebugString ( math.floor ( ( i / size ) * 100 ) .. "%" )
			
			setTimer ( function ( ) coroutine.resume ( g_SaveCr ) end, 50, 1 )
			coroutine.yield ( )
		end
	end
end

function Heightfield.smooth ( cb, ... )
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	
	local totalSize = resolutionX*resolutionY
	local count = 0
	local check = 0
	
	local function getRawHeight ( x, y )
		x = math.max ( math.min ( x, resolutionX-1 ), 0 )
		y = math.max ( math.min ( y, resolutionY-1 ), 0 )
		
		local height = Heightfield.getLevel ( x, y )
		return height
	end
	for y = 0, resolutionX - 1 do
		for x = 0, resolutionY - 1 do
			local smoothedHeight = (
				getRawHeight(x-1, y-1) + getRawHeight(x,y-1) * 2 + getRawHeight(x+1,y-1) +
				getRawHeight(x-1,y) * 2 + getRawHeight(x,y) * 4 + getRawHeight(x+1,y) * 2 +
				getRawHeight(x-1,y+1) + getRawHeight(x,y+1) * 2 + getRawHeight(x+1,y+1)
			) / 16

			Heightfield.setLevel ( y, x, smoothedHeight )
			
			count = count + 1
			
			if count == totalSize and type ( cb ) == "function" then
				cb ( ... )
			end
			
			
			check = check + 1
			if check > 10000 then
				check = 0
				
				outputDebugString ( "Smooth heightfield " .. math.floor ( ( count / totalSize ) * 100 ) .. "% ..." )
				
				setTimer ( function ( ) coroutine.resume ( g_ProcessCr ) end, 50, 1 )
				coroutine.yield ( )
			end
		end
	end
end

function Heightfield.getLevel ( x, y )
	local index = _mathMin ( y, MAP_RES_Y - 1 ) * MAP_RES_X + _mathMin ( x, MAP_RES_X - 1 )
	local level = heightData [ index + 1 ]
	
	if level == nil then
		outputDebugString ( "Не найдено позиции " .. x ..", " .. y .. " на сервере", 2 )
		return
	end
	
	return level
end

local function _onRawSave ( )
	fileFlush ( Heightfield.raw )
	Heightfield.timer = nil
	--outputDebugString ( "Сохранен" )
end

function Heightfield.setLevel ( x, y, level )
	local index = y * MAP_RES_X + x
	
	heightData [ index + 1 ] = level
	
	fileSetPos ( Heightfield.raw, Heightfield.rawStart + index*2 )
	dataToBytes ( Heightfield.raw, "s", 128 * level )
	
	if isTimer ( Heightfield.timer ) then
		resetTimer ( Heightfield.timer )
		--outputChatBox("reset")
	else
		Heightfield.timer = setTimer ( _onRawSave, 500, 1 )
		--outputChatBox("create" .. tostring(Heightfield.timer ))
	end
end

function Heightfield.set ( tbl )
	heightData = tbl
end

function Heightfield.get ( )
	return heightData
end

--[[
	Events
]]
local function getRawHeight ( x, y )
	local resX = WORLD_SIZE_X * MAP_SIZE
	local resY = WORLD_SIZE_Y * MAP_SIZE
	x = _mathClamp ( 0, x, resX - 1 )
	y = _mathClamp ( 0, y, resY - 1 )
		
	local height = Heightfield.getLevel ( x, y )
	return height
end
local function brushCircleFunc ( x, y, strength, size, mode, buildSet )
	local radius = size - 1
	local _rad = radius * radius
	for _x = -radius, radius do
		local mapx = x + _x
		local height = _mathFloor ( _mathSqrt ( _rad - _x * _x ) )

		for _y = -height, height do
			local mapy = y + _y
					
			if mode == BrushModes.SMOOTH then
				local smoothedHeight = (
					getRawHeight(mapx-1, mapy-1) + getRawHeight(mapx,mapy-1) * 2 + getRawHeight(mapx+1,mapy-1) +
					getRawHeight(mapx-1,mapy) * 2 + getRawHeight(mapx,mapy) * 4 + getRawHeight(mapx+1,mapy) * 2 +
					getRawHeight(mapx-1,mapy+1) + getRawHeight(mapx,mapy+1) * 2 + getRawHeight(mapx+1,mapy+1)
				) / 16
				
				Heightfield.setLevel ( mapx, mapy, smoothedHeight )
			else
				local level = getRawHeight ( mapx, mapy )
				if mode == BrushModes.FLATTEN then
					Heightfield.setLevel ( mapx, mapy, strength )
				else
					if mode == BrushModes.RAISE then
						Heightfield.setLevel ( mapx, mapy, level + strength )
					elseif mode == BrushModes.LOWER then
						Heightfield.setLevel ( mapx, mapy, level - strength )
					end
				end
			end
		end
	end
	
	-- Заносим в таблицу секторов
	if mode == BrushModes.SMOOTH then
		radius = radius + 1
	end
	local crosswise = {
		[ 1 ] = xrStreamerWorld.findSector ( x - radius, y - radius, true ),
		[ 2 ] = xrStreamerWorld.findSector ( x + radius, y + radius, true ),
		[ 3 ] = xrStreamerWorld.findSector ( x - radius, y + radius, true ),
		[ 4 ] = xrStreamerWorld.findSector ( x + radius, y - radius, true )
	}
	for i = 1, 4 do
		local sector = crosswise [ i ]
		if sector then
			buildSet [ sector ] = true
		end
	end
end
local function brushBoxFunc ( x, y, width, height, strength, mode )
	for _x = 0, width do
		local mapx = x + _x
		for _y = 0, height do
			local mapy = y + _y
			
			if mode == BrushModes.SMOOTH then
				local smoothedHeight = (
					getRawHeight(mapx-1, mapy-1) + getRawHeight(mapx,mapy-1) * 2 + getRawHeight(mapx+1,mapy-1) +
					getRawHeight(mapx-1,mapy) * 2 + getRawHeight(mapx,mapy) * 4 + getRawHeight(mapx+1,mapy) * 2 +
					getRawHeight(mapx-1,mapy+1) + getRawHeight(mapx,mapy+1) * 2 + getRawHeight(mapx+1,mapy+1)
				) / 16
				
				Heightfield.setLevel ( mapx, mapy, smoothedHeight )
			else
				local level = getRawHeight ( mapx, mapy )
				if mode == BrushModes.FLATTEN then
					Heightfield.setLevel ( mapx, mapy, strength )
				else
					if mode == BrushModes.RAISE then
						Heightfield.setLevel ( mapx, mapy, level + strength )
					elseif mode == BrushModes.LOWER then
						Heightfield.setLevel ( mapx, mapy, level - strength )
					end
				end
			end
		end
	end
end
local function brushDozerFunc ( x, y, length, width, horizontal, height, height2, easingType )
	local invert
	if length < 0 then
		length = math.abs ( length )
		invert = true
	end
	
	for _y = 0, width do
		for _x = 0, length do
			local mapx = invert and x - _x or x + _x
			
			local progress = _x / length
			local level = interpolateBetween ( height, 0, 0, height2, 0, 0, progress, EasingTypes [ easingType ] )
			if horizontal then
				Heightfield.setLevel ( invert and x - _x or x + _x, y + _y, level )
			else
				Heightfield.setLevel ( x + _y, invert and y - _x or y + _x, level )
			end
		end
	end
end


local function interpolateCell ( lx, ty, rx, by )
	local width = rx - lx
	local height = by - ty
	
	local y1 = getRawHeight ( lx, ty )
	local y2 = getRawHeight ( lx, by )
	local y3 = getRawHeight ( rx, ty )
	local y4 = getRawHeight ( rx, by )
	
	for i = 0, height do
		local h1 = interpolateBetween ( y1, 0, 0, y2, 0, 0, i / height, "Linear" )
		local h2 = interpolateBetween ( y3, 0, 0, y4, 0, 0, i / height, "Linear" )
	
		for j = 0, width do
			local height = interpolateBetween ( h1, 0, 0, h2, 0, 0, j / width, "Linear" )
			Heightfield.setLevel ( lx + j, ty + i, height )
		end
	end
end
local function adjustMapPixel ( x, y, level, _step )
	-- Сначала меняем высоту точки
	Heightfield.setLevel ( x, y, level )
	
	local leftX = x - _step
	local topY = y - _step
	
	-- Интерполируем квадраты к этой точке
	for i = 0, 1 do
		local ty = topY + _step*i
		local by = ty + _step
		
		for j = 0, 1 do
			local lx = leftX + _step*j
			local rx = lx + _step
			
			interpolateCell ( lx, ty, rx, by )
		end
	end
end

-- Вызывается когда игрок применяет твердую кисть
addEvent ( "onApplyBrushCircle", true )
addEventHandler ( "onApplyBrushCircle", resourceRoot,
	function ( x, y, strength, size, mode )
		local sector = xrStreamerWorld.findSector ( x, y, true )
		if sector then
			local buildSet = { }
			brushCircleFunc ( x, y, strength, size, mode, buildSet )
	
			for _, player in ipairs ( getElementsByType ( "player" ) ) do
				--[[local sectorIndex = getElementData ( player, "sector", false )
				local playerSector = xrStreamerWorld.sectors [ sectorIndex ]
				if playerSector and player ~= client then
					-- Отправляем игроку данные только если изменения произошли в соседних к нем секторах
					local lodLevel = xrEngine.getPlayerLODLevel ( player )
					for sector, _ in pairs ( buildSet ) do
						outputDebugString ( "check 1 ")
						if playerSector:isMySurroundingSector ( sector, lodLevel ) then
							triggerClientEvent ( player, "onClientApplyBrushCircle", resourceRoot, x, y, strength, size, mode )
							outputDebugString ( "Игроку " .. getPlayerName ( player ) .. " отправлены изменения" )
							return
						end
					end
					
					outputDebugString ( "Игроку " .. getPlayerName ( player ) .. " не требуется присылать изменения" )
				end]]
				
				if player ~= client then
					triggerClientEvent ( player, "onClientApplyBrushCircle", resourceRoot, x, y, strength, size, mode )
				end
			end
		else
			outputDebugString ( "Не был найден сектор", 2 )
		end
	end
)

-- Вызывается когда игрок применяет твердую кисть
addEvent ( "onApplyBrushBox", true )
addEventHandler ( "onApplyBrushBox", resourceRoot,
	function ( x, y, width, height, strength, mode )
		local sector = xrStreamerWorld.findSector ( x, y, true )
		if sector then
			brushBoxFunc ( x, y, width, height, strength, mode )
	
			for _, player in ipairs ( getElementsByType ( "player" ) ) do
				--[[local sectorIndex = getElementData ( player, "sector", false )
				local playerSector = xrStreamerWorld.sectors [ sectorIndex ]
				if playerSector and player ~= client then
					-- Отправляем игроку данные только если изменения произошли в соседних к нем секторах
					local lodLevel = xrEngine.getPlayerLODLevel ( player )
					local common = playerSector:compareSurroundings ( sector, true, lodLevel )
					if #common > 0 then
						triggerClientEvent ( player, "onClientApplyBrushBox", resourceRoot, x, y, width, height, strength, mode )
					end
				end]]
				
				if player ~= client then
					triggerClientEvent ( player, "onClientApplyBrushBox", resourceRoot, x, y, width, height, strength, mode )
				end
			end
		end
	end
)

addEvent ( "onBrushStroke", true )
addEventHandler ( "onBrushStroke", resourceRoot,
	function ( strokeList, brushtype, brushsize, index )
		local players = getElementsByType ( "player" )
		for _, player in ipairs ( players ) do
			if player ~= client then
				triggerClientEvent ( player, "onClientBrushStroke", resourceRoot, strokeList, brushtype, brushsize, index,
					client -- только для дебага
				)
			end
		end
	end
, false )

addEvent ( "onApplyGrid", true )
addEventHandler ( "onApplyGrid", resourceRoot,
	function ( points, step )
		local dimX = MAP_SIZE * WORLD_SIZE_X
		for index, level in pairs ( points ) do
			local mapx = math.floor ( (index-1) % dimX )
			local mapy = math.floor ( (index-1) / dimX )
		
			adjustMapPixel ( mapx, mapy, level, step )
		end
		
		for _, player in ipairs ( getElementsByType ( "player" ) ) do
			if player ~= client then
				triggerClientEvent ( player, "onClientApplyGrid", resourceRoot, points, step )
			end
		end
	end
, false )

local spawnx, spawny, spawnz = 8.63993, -3672.70654, 139.01260
local spawnSectorIndex = 1

local playerSpawnSector = {
	
}

addEvent ( "onPlayerSectorLoaded", true )
addEventHandler ( "onPlayerSectorLoaded", resourceRoot,
	function ( index, state )
		local sector = xrStreamerWorld.findSector ( spawnx, spawny )
		if index == sector._index then
			playerSpawnSector [ client ] = state
			
			if state then
				setElementFrozen ( client, false )
			end
		end
		
		sector = xrStreamerWorld.sectors [ index ]
		if sector then
			if state then
				xrEngine.onPlayerHitSector ( client, sector )
			else
				xrEngine.onPlayerLeaveSector ( client, sector )
			end
		else
			outputDebugString ( "Не был найден сектор " .. tostring ( index ) )
		end
	end
, false )

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		xrEngine.init ( )
	
		for i,player in ipairs(getElementsByType("player")) do
			spawn(player)
		end
	end
, false )

addEventHandler ( "onResourceStop", resourceRoot,
	function ( )
		xrEngine.stop ( )
	end
, false )

addEventHandler ( "onPlayerJoin", root,
	function ( )
		spawn(source)
	end
)

function spawn(player)
	if not isElement(player) then return end
	spawnPlayer ( player, spawnx + math.random ( -3, 3 ), spawny + math.random ( -3, 3 ), spawnz )
	repeat until setElementModel(player,math.random(312))
	fadeCamera(player, true)
	setCameraTarget(player, player)
	showChat(player, true)
	
	if playerSpawnSector [ player ] ~= true then
		setElementFrozen ( player, true )
	end
end

addEventHandler("onPlayerWasted", root,
	function()
		setTimer(spawn, 1800, 1, source)
	end
)

-- Вызывается когда клиент готов к загрузке мира
addEvent ( "onPlayerEngineReady", true )
addEventHandler ( "onPlayerEngineReady", resourceRoot,
	function ( )
		-- Если наш мир готов, говорим клиенту что можно начать загрузку
		if xrEngine.loaded then
			outputChatBox("on loaded 2")
			triggerClientEvent ( client, "onClientTerrainReady", resourceRoot )
		end
	end
, false )

addCommandHandler ( "prebuild",
	function ( player )
		triggerLatentClientEvent ( player, "onClientTerrainPreBuild", resourceRoot, heightData )
	end
)

--[[
	CRAP
]]
addCommandHandler ( "buildxtg",
	function ( player, _, filename )
		--if fileExists ( filename ) then
			--local file = fileOpen ( filename, true )
			--local content = fileRead ( file, fileGetSize ( file ) )
			--fileClose ( file )
			
			local content = ""
			
			triggerLatentClientEvent ( player, "onClientBuildXTG", 100000, resourceRoot, content )
			g_BuildXTGProcess = true
			
			outputChatBox ( "Файл отправлен. Ждите окончания обработки...", player )
		--else
			--outputChatBox ( "Файла " .. filename .. " не существует!", player )
		--end
	end
)

addEvent ( "onBuildXTG", true )
addEventHandler ( "onBuildXTG", resourceRoot,
	function ( content )
		if g_BuildXTGProcess then
			local file = fileCreate ( "heightmap.xtg" )
			if file then
				fileWrite ( file, content )
				fileClose ( file )
				
				outputChatBox ( "Карта высот успешно обработана и сохранена", client )
			end
			
			g_BuildXTGProcess = nil
		end
	end
, false )

addEvent ( "onPatternFile", true )
addEventHandler ( "onPatternFile", resourceRoot,
	function ( index, content )
		local ext = index > 1 and ".col" or ".dff"
		local path = "pattern" .. ext
		local file = fileCreate ( path )
		fileWrite ( file, content )
		fileClose ( file )
	end
, false )

addCommandHandler ( "makemeta",
	function ( )
		local xml = xmlLoadFile ( "meta.xml" )
		
		local totalSectors = WORLD_SIZE_X * WORLD_SIZE_Y
		for i = 1, totalSectors do
			local node = xmlCreateChild ( xml, "file" )
			xmlNodeSetAttribute ( node, "src", "sectors/sector" .. i .. ".png" )
			xmlNodeSetAttribute ( node, "download", "false" )
			
			node = xmlCreateChild ( xml, "file" )
			xmlNodeSetAttribute ( node, "src", "sectors/sector" .. i .. "_mask.png" )
			xmlNodeSetAttribute ( node, "download", "false" )
		end
		
		xmlSaveFile ( xml )
		xmlUnloadFile ( xml )
	end
)