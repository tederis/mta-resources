local _mathFloor = math.floor
local _mathSqrt = math.sqrt
local _mathMin = math.min
local _mathMax = math.max
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end
local _mathLog2 = function ( x )
	return math.log ( x ) / math.log ( 2 )
end
local _dist2d = getDistanceBetweenPoints2D

BrushModes = {
	RAISE = 1,
	LOWER = 2,
	SMOOTH = 3,
	FLATTEN = 4
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
	
	triggerClientEvent ( "onClientTerrainReady", resourceRoot,
		Heightfield.resolutionX, Heightfield.resolutionY,
		Heightfield.vertScale,
		Heightfield.vertOffset,
		Heightfield.horScale
	)
	
	setTimer ( xrEngine.onUpdate, 100, 0 )
	
	xrEngine.setupWater ( Heightfield.vertOffset )
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

function xrEngine.setupWater ( height )
	-- Setting water properties.
	local SizeVal = 2998
	-- Defining variables.
	local southWest_X = -SizeVal
	local southWest_Y = -SizeVal
	local southEast_X = SizeVal
	local southEast_Y = -SizeVal
	local northWest_X = -SizeVal
	local northWest_Y = SizeVal
	local northEast_X = SizeVal
	local northEast_Y = SizeVal
	 
	local water = createWater ( southWest_X, southWest_Y, height, southEast_X, southEast_Y, height, northWest_X, northWest_Y, height, northEast_X, northEast_Y, height )
	setWaterLevel ( height )
end

--[[
	HeaderParser
]]
local typeSized = {
	us = 2, ui = 4, b = 1, f = 4
}
local _parseFile
local _parseHeader = function ( data )
	local out = { }
	
	for _, data in ipairs ( data ) do
		local valueStr = fileRead ( _parseFile, typeSized [ data [ 2 ] ] )
		local value = bytesToData ( data [ 2 ], valueStr )
		if value then
			out [ data [ 1 ] ] = value
		else
			outputDebugString ( "Header parsing error", 2 )
			return false
		end
	end
	
	return out
end
HeaderParser = function ( file )
	_parseFile = file
	return _parseHeader
end

--[[
	Heightfield
]]
local DEF_FILE_HF300 = 300
local HFF_HEADER_DATA = {
	{ "dataOffset", "us" },
	{ "mapWidth", "ui" },
	{ "mapHeight", "ui" },
	{ "dataSize", "b" },
	{ "isFloating", "b" },
	{ "vertScale", "f" },
	{ "vertOffset", "f" },
	{ "horScale", "f" },
	{ "tileSize", "us" },
	{ "wrapFlag", "b" }
}

Heightfield = { 
	resolutionX = 0,
	resolutionY = 0,
	vertScale = 0,
	vertOffset = 0,
	horScale = 0
}
local heightData = { }

function Heightfield.setRawData ( file, startWith )
	Heightfield.raw = file
	Heightfield.rawStart = startWith
end

function Heightfield.grab ( x, y, width, height )
	local data = { }
	
	for j = 0, height-1 do
		for i = 0, width-1 do
			local level = Heightfield.getLevel ( x + i, y + j )
			local index = j * Heightfield.resolutionX + i
			data [ index + 1 ] = level
		end
	end
	
	return data
end

function Heightfield.loadFromBinary ( fileName, callback, ... )
	local hfFile = fileOpen ( fileName, true )
	local pixelsNum = 0
	local pixelsLimit = 0
	local pixelsTotal
	local _pause = function ( )
		local progress = pixelsNum / pixelsTotal
		outputDebugString ( "Load heightfield " .. math.floor ( progress * 100 ) .. "% ...", 3 )
	
		setTimer ( function ( ) coroutine.resume ( g_ProcessCrHF ) end, 50, 1 )
		coroutine.yield ( )
	end
	
	-- File marker
	if fileRead ( hfFile, 4 ) ~= "L3DT" then
		outputDebugString ( "File is not a valid HFF", 2 )
		return
	end
	
	-- Binary map-type marker
	local hffVersion = bytesToData ( "us", fileRead ( hfFile, 2 ) )
	if hffVersion ~= DEF_FILE_HF300 then
		outputDebugString ( "Invalid file version number", 2 )
		return
	end
	
	-- ASCII map-type marker
	if fileRead ( hfFile, 8 ) ~= "HFF_v1.0" then
		outputDebugString ( "Unknown file version in HFF", 2 )
		return
	end
	
	-- Header
	local headerData = HeaderParser ( hfFile ) ( HFF_HEADER_DATA )
	if type ( headerData ) ~= "table" then
		outputDebugString ( "Invalid file header", 2 )
		return
	end
	
	pixelsTotal = headerData.mapWidth * headerData.mapHeight
	local expectedSize = pixelsTotal * 4 + 64
	if fileGetSize ( hfFile ) ~= expectedSize then
		outputDebugString ( "Invalid file size", 2 )
		return
	end
	
	local expectedResX = WORLD_SIZE_X * MAP_SIZE
	local expectedResY = WORLD_SIZE_Y * MAP_SIZE
	if headerData.mapWidth < expectedResX or headerData.mapHeight < expectedResY then
		outputDebugString ( "Invalid map resolution. Please, rebuild heightfield with " .. 2 ^ math.ceil ( _mathLog2 ( expectedResX ) ) .. "x" .. 2 ^ math.ceil ( _mathLog2 ( expectedResY ) ) .. " resolution.", 2 )
		return
	end
	
	if headerData.horScale ~= HOR_SCALE then
		outputDebugString ( "Invalid horizontal scale. Please, rebuild heightfield with " .. HOR_SCALE .. " horizontal scale.", 2 )
		return
	end
	
	fileSetPos ( hfFile, headerData.dataOffset )
	
	outputDebugString ( "Starting of raw data parsing (" .. pixelsTotal .. " pixels)" )
	
	for i = 1, pixelsTotal do
		local level = bytesToData ( "f", fileRead ( hfFile, 4 ) )
		if level then
			heightData [ i ] = level
		else
			outputDebugString ( "Error pixel reading!", 2 )
		end
		
		pixelsNum = pixelsNum + 1
		pixelsLimit = pixelsLimit + 1
		if pixelsLimit > 80000 then
			pixelsLimit = 0

			_pause ( )
		end
	end
	
	Heightfield.resolutionX = headerData.mapWidth
	Heightfield.resolutionY = headerData.mapHeight
	Heightfield.vertScale = headerData.vertScale
	Heightfield.vertOffset = headerData.vertOffset
	Heightfield.horScale = headerData.horScale
	
	fileClose ( hfFile )
	
	outputDebugString ( "Файл высот успешно прочитан", 3 )
	
	if type ( callback ) == "function" then
		callback ( ... )
	end
end

function Heightfield.smooth ( cb, ... )
	local resolutionX = Heightfield.resolutionX
	local resolutionY = Heightfield.resolutionY
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

			Heightfield.setLevel ( x, y, smoothedHeight, true )
			
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
	local index = y * Heightfield.resolutionX + x
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

function Heightfield.setLevel ( x, y, level, withoutSave )
	local index = y * Heightfield.resolutionX + x
	
	heightData [ index + 1 ] = level
	
	if withoutSave ~= true then
		fileSetPos ( Heightfield.raw, Heightfield.rawStart + index*2 )
		if COMPACT_XTD then
			dataToBytes ( Heightfield.raw, "s", 128 * level )
		else
			dataToBytes ( Heightfield.raw, "f", level )
		end
	
		if isTimer ( Heightfield.timer ) then
			resetTimer ( Heightfield.timer )
			--outputChatBox("reset")
		else
			Heightfield.timer = setTimer ( _onRawSave, 500, 1 )
			--outputChatBox("create" .. tostring(Heightfield.timer ))
		end
	end
end

function Heightfield.getHeight ( px, py )
	local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
	local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
	local deltaX = ( px - xrStreamerWorld.worldX ) / worldSizeX
	local deltaY = ( xrStreamerWorld.worldY - py ) / worldSizeY
	local borderX = Heightfield.resolutionX - WORLD_SIZE_X * MAP_SIZE
	local borderY = Heightfield.resolutionY - WORLD_SIZE_Y * MAP_SIZE
	local pixelX, pixelY = deltaX * ( Heightfield.resolutionX - borderX ), deltaY * ( Heightfield.resolutionY - borderY )
	local fracX, fracY = pixelX - math.floor ( pixelX ), pixelY - math.floor ( pixelY )
	local h1, h2, h3
	
	if fracX + fracY >= 1 then
		h1 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) + 1 )
		h2 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) + 1 )
		h3 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) )
		
		fracX = 1 - fracX
		fracY = 1 - fracY
	else
		h1 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) )
		h2 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) )
		h3 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) + 1 )
	end
	
	return h1 * ( 1 - fracX - fracY ) + h2 * fracX + h3 * fracY
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
	x = _mathClamp ( 0, x, Heightfield.resolutionX - 1 )
	y = _mathClamp ( 0, y, Heightfield.resolutionY - 1 )
		
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
		local dimX = Heightfield.resolutionX
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

local spawnx, spawny, spawnz = 0, 0, 0
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
			triggerClientEvent ( client, "onClientTerrainReady", resourceRoot, 
				Heightfield.resolutionX, Heightfield.resolutionY,
				Heightfield.vertScale,
				Heightfield.vertOffset,
				Heightfield.horScale
			)
		end
	end
, false )

addCommandHandler ( "prebuild",
	function ( player )
		triggerLatentClientEvent ( player, "onClientTerrainPreBuild", resourceRoot, heightData )
	end
)

addCommandHandler ( "xrvertscale",
	function ( player, _, value )
		value = tonumber ( value )
		if value then
			if value < 0 then
				value = 0
			end
		
			Heightfield.vertScale = value
			
			if xrStreamerWorld.worldRaw then
				fileSetPos ( Heightfield.raw, 8 )
				dataToBytes ( Heightfield.raw, "f", value )
			end
			
			outputChatBox ( "VertScale " .. value )
		else
			outputChatBox ( "Incorrect" )
		end
	end
)

-- Stuff
local treeModels = {
	"trees/new_trees/trees_rostki_2_05",
	"trees/new_trees/trees_sosna_1_01",
	"trees/new_trees/trees_2_02",
	"trees/new_trees/trees_rostki_1_sux_03",
	"trees/new_trees/trees_rostki_1_sux_04",
	"trees/new_trees/trees_rostki_1_sux_02",
	"trees/new_trees/trees_rostki_1_sux_01",
	"trees/new_trees/trees_rostki_2_02",
	"trees/new_trees/trees_rostki_2_03",
	"trees/new_trees/bush_2_02",
	"trees/new_trees/trees_2_01",
	"trees/new_trees/trees_2_sux_01",
	"trees/new_trees/trees_2_04",
	"trees/new_trees/trees_2_03",
	"trees/new_trees/trees_topol_1_sux_01",
	"trees/new_trees/trees_rostki_1_sux_05",
	"trees/new_trees/bush_2_01",
	"trees/new_trees/trees_topol_1_01"
}

local function getPointFromDistanceRotation(x, y, dist, angle)
 
    local a = math.rad(90 - angle);
 
    local dx = math.cos(a) * dist;
    local dy = math.sin(a) * dist;
 
    return x+dx, y+dy;
 
end

function getTerrainHeight ( x, y )
	local level = PATCH_Z + Heightfield.getHeight ( x, y )*Heightfield.vertScale - HALF_ELEVATION
	
	return level
end

function placeTrees ( x, y, xml )
	local randNum = math.random ( 1, 100 )
	
	for i = 1, randNum do
		local rx, ry = getPointFromDistanceRotation ( x, y, math.random ( 0, HALF_SECTOR_SIZE - HOR_SCALE ), math.random ( 0, 360 ) )
		local randName = treeModels [ math.random ( 1, #treeModels ) ]
		local rz = getTerrainHeight ( rx, ry )
		if rz > 0 then
			local node = xmlCreateChild ( xml, "wbo:generic" )
			xmlNodeSetAttribute ( node, "model", randName )
			xmlNodeSetAttribute ( node, "posX", tostring ( rx ) )
			xmlNodeSetAttribute ( node, "posY", tostring ( ry ) )
			xmlNodeSetAttribute ( node, "posZ", tostring ( rz or 0 ) )
		end
	end
end

function treeGeneration ( )
	local xml = xmlCreateFile ( "output.map", "map" )
	local node = xmlCreateChild ( xml, "room" )
	xmlNodeSetAttribute ( node, "dimension", "0" )
	xmlNodeSetAttribute ( node, "id", "guest-room" )
	xmlNodeSetAttribute ( node, "name", "Guest room" )
	xmlNodeSetAttribute ( node, "no-objs", "0" )
	xmlNodeSetAttribute ( node, "no-wm", "1" )
	xmlNodeSetAttribute ( node, "owner", "Console" )

	for j = 1, WORLD_SIZE_Y do
		for i = 1, WORLD_SIZE_X do
			local cx = xrStreamerWorld.worldX + SECTOR_SIZE*(i-1) + HALF_SECTOR_SIZE
			local cy = xrStreamerWorld.worldY - SECTOR_SIZE*(j-1) - HALF_SECTOR_SIZE
			
			placeTrees ( cx, cy, node )
		end
	end
	
	xmlSaveFile ( xml )
	xmlUnloadFile ( xml )
end

addCommandHandler ( "treesGen", treeGeneration )