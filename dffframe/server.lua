SECTOR_SIZE = 150
WORLD_WIDTH = 9000
WORLD_HEIGHT = 9000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE --40 now
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE --40 now
MAP_STEP = 3
MAP_SIZE = SECTOR_SIZE / MAP_STEP --50 now

EDITOR_BUILDER = 1
EDITOR_DESIGN = 2

INCLUDE_LMAPS = false

--[[
	xrNetSender
]]
xrNetSender = { }
xrNetSender.__index = xrNetSender

SENDER_WAIT = 1
SENDER_RUNNING = 2
SENDER_STOPPED = 3

function xrNetSender.new ( player )
	local sender = {
		player = player,
		fileNames = { },
		current = 1,
		state = SENDER_WAIT,
		lastTime = nil,
		handles = { }
	}
	
	return setmetatable ( sender, xrNetSender )
end

function xrNetSender:send ( fileIndex )
	fileIndex = tonumber ( fileIndex )
	if not fileIndex then
		if #self.fileNames < 1 or self.state ~= SENDER_WAIT then return end;
		
		self.state = SENDER_RUNNING
		fileIndex = 1
	end
	
	local currentFileName = self.fileNames [ fileIndex ]
	if currentFileName then
		if fileExists ( currentFileName ) then
			local file = fileOpen ( currentFileName, true )
			local fileSize = fileGetSize ( file )
			local fileContent = fileRead ( file, fileSize )
			fileClose ( file )
		
			triggerLatentClientEvent ( self.player, "onClientSenderFile", 1500000, false, resourceRoot, fileIndex, fileContent )
			
			local handles = getLatentEventHandles ( self.player )
			if handles and #handles > 0 then
				self.handles [ fileIndex ] = handles [ #handles ]
				if not self.handles [ fileIndex ] then
					outputDebugString ( "Обнаружен невалидный хендл", 1 )
				end
			else
				outputDebugString ( "Не было найдено хэндла события", 2 )
			end
			
			self.lastTime = getTickCount ( )
			
			outputDebugString ( "Файл " .. currentFileName .. " отправлен игроку " .. getPlayerName ( self.player ) )
		
			return true
		else
			outputDebugString ( "Файла с индексом " .. fileIndex .. " не существует", 2 )
		end
	end
end

function xrNetSender:update ( )
	if self.state == SENDER_RUNNING then
		local now = getTickCount ( )
		if now - self.lastTime > 100 then
			self.lastTime = now
			
			self.current = self.current + 1
			if self:send ( self.current ) ~= true then
				self.state = SENDER_STOPPED
			end
		end
	end
	
	local completeHandlesNum = 0
	local percentAdd = 0
	for fileIndex, handle in pairs ( self.handles ) do
		local handleStatus = getLatentEventStatus ( self.player, handle )
		if handleStatus then
			percentAdd = percentAdd + handleStatus.percentComplete
		else
			completeHandlesNum = completeHandlesNum + 1
		end
	end
	
	local totalPercent = #self.fileNames * 100
	local completePercent = completeHandlesNum*100 + percentAdd
	local progressFactor = completePercent / totalPercent
	
	triggerClientEvent ( self.player, "onClientFileStatus", resourceRoot, math.floor ( progressFactor * 100 ) )
	
	return completeHandlesNum ~= #self.fileNames
end

--[[
	xrLevelAggregator
]]
xrLevelAggregator = { 
	levels = { },
	senders = { },
	fileNames = { }
}

function xrLevelAggregator.init ( )
	local xml = xmlLoadFile ( "locations.xml" )
	if xml then
		xrLevelAggregator.parseList ( xml )
		xmlUnloadFile ( xml )
	else
		outputDebugString ( "Списка локаций не существует!", 2 )
		return
	end
	
	-- Строим список файлов
	for _, levelData in ipairs ( xrLevelAggregator.levels ) do
		table.insert ( xrLevelAggregator.fileNames, levelData [ 2 ] )
		table.insert ( xrLevelAggregator.fileNames, levelData [ 2 ] .. "_mask" )
		if INCLUDE_LMAPS then
			table.insert ( xrLevelAggregator.fileNames, levelData [ 2 ] .. "_lm" )
		end
	end
	
	-- Добавляем таймер для обновления сендеров
	setTimer ( xrLevelAggregator.update, 50, 0 )
end

function xrLevelAggregator.parseList ( xml )
	local revision = xmlNodeGetAttribute ( xml, "rev" )
	xrLevelAggregator.revision = tonumber ( revision ) or 0

	local nodes = xmlNodeGetChildren ( xml )
	for _, node in ipairs ( nodes ) do
		local levelName = xmlNodeGetAttribute ( node, "name" )
		local levelMap = xmlNodeGetAttribute ( node, "texture" )
		local posX = xmlNodeGetAttribute ( node, "posX" )
		local posY = xmlNodeGetAttribute ( node, "posY" )
		local texBiasX = xmlNodeGetAttribute ( node, "texBiasX" )
		local texBiasY = xmlNodeGetAttribute ( node, "texBiasY" )
		local redChannel = xmlNodeGetAttribute ( node, "redChannel" )
		local greenChannel = xmlNodeGetAttribute ( node, "greenChannel" )
		local blueChannel = xmlNodeGetAttribute ( node, "blueChannel" )
		local alphaChannel = xmlNodeGetAttribute ( node, "alphaChannel" )
		local rot = xmlNodeGetAttribute ( node, "rot" )
		local raise = xmlNodeGetAttribute ( node, "raise" )
		
		local file = fileOpen ( "locations/" .. levelName .. ".dat", true )
		if file then
			local mapWidth, mapHeight = xrLevelAggregator.readLevelHeader ( file )
			if mapWidth then
				local newIndex = #xrLevelAggregator.levels + 1
				local levelData = {
					[ 1 ] = levelName,
					[ 2 ] = levelMap,
					[ 3 ] = mapWidth,
					[ 4 ] = mapHeight,
					[ 5 ] = tonumber ( posX ) or 0,
					[ 6 ] = tonumber ( posY ) or 0,
					[ 7 ] = tonumber ( texBiasX ) or 0,
					[ 8 ] = tonumber ( texBiasY ) or 0,
					[ 9 ] = newIndex,
					[ 10 ] = tonumber ( redChannel ) or 1,
					[ 11 ] = tonumber ( greenChannel ) or 2,
					[ 12 ] = tonumber ( blueChannel ) or 3,
					[ 13 ] = tonumber ( alphaChannel ) or 4,
					[ 14 ] = tonumber ( rot ) or 0,
					[ 15 ] = tonumber ( raise ) or 0
				}
				
				xrLevelAggregator.levels [ newIndex ] = levelData
			else
				outputDebugString ( "Невозможно прочитать заголовок локации", 2 )
			end
			
			fileClose ( file )
		else
			outputDebugString ( "Файла локации не существует", 2 )
		end
	end
	
	outputDebugString ( "Загружено " .. #xrLevelAggregator.levels .. " локаций из " .. #nodes )
end

_buildPulse = function ( )
	if xrLevelAggregator.buildCR ~= nil and coroutine.status ( xrLevelAggregator.buildCR ) ~= "dead" then
		local ok, progress = coroutine.resume ( xrLevelAggregator.buildCR )
		if coroutine.status ( xrLevelAggregator.buildCR ) ~= "dead" then
			setTimer ( _buildPulse, 50, 1 )
			
			outputDebugString ( "Постройка идет ... " .. tostring ( math.floor ( progress * 100 ) ) .. "%" )
		else
			xrLevelAggregator.buildCR = nil
		
			outputDebugString ( "Карта успешно построена" )
		end
	else
		outputDebugString ( "Поток построения не был найден", 2 )
	end
end
function xrLevelAggregator.buildMap ( )
	if xrLevelAggregator.buildCR ~= nil then
		outputChatBox ( "Построение уже происходит! Дождитесь его окончания!" )
		
		return
	end

	xrLevelAggregator.buildCR = coroutine.create ( xrLevelAggregator._buildThread )
	
	setTimer ( _buildPulse, 50, 1 )
end

function xrLevelAggregator.saveList ( xml )
	xmlNodeSetAttribute ( xml, "rev", tostring ( xrLevelAggregator.revision ) )

	for _, levelData in ipairs ( xrLevelAggregator.levels ) do
		local node = xmlCreateChild ( xml, "loc" )
		xmlNodeSetAttribute ( node, "name", levelData [ 1 ] )
		xmlNodeSetAttribute ( node, "texture", levelData [ 2 ] )
		xmlNodeSetAttribute ( node, "posX", tostring ( levelData [ 5 ] ) )
		xmlNodeSetAttribute ( node, "posY", tostring ( levelData [ 6 ] ) )
		xmlNodeSetAttribute ( node, "texBiasX", tostring ( levelData [ 7 ] ) )
		xmlNodeSetAttribute ( node, "texBiasY", tostring ( levelData [ 8 ] ) )
		xmlNodeSetAttribute ( node, "redChannel", tostring ( levelData [ 10 ] ) )
		xmlNodeSetAttribute ( node, "greenChannel", tostring ( levelData [ 11 ] ) )
		xmlNodeSetAttribute ( node, "blueChannel", tostring ( levelData [ 12 ] ) )
		xmlNodeSetAttribute ( node, "alphaChannel", tostring ( levelData [ 13 ] ) )
		xmlNodeSetAttribute ( node, "rot", tostring ( levelData [ 14 ] ) )
		xmlNodeSetAttribute ( node, "raise", tostring ( levelData [ 15 ] ) )
	end
	
	outputDebugString ( "Сохранено " .. #xrLevelAggregator.levels .. " локаций" )
end

local _readFloat = function ( file )
	local floatBin = fileRead ( file, 4 )
	if floatBin then
		return bytesToData ( "f", floatBin )
	end
end
function xrLevelAggregator.readLevelHeader ( file )
	local mapWidth = _readFloat ( file )
	local mapHeight = _readFloat ( file )
	local minUVx = _readFloat ( file )
	local minUVy = _readFloat ( file )
	local maxUVx = _readFloat ( file )
	local maxUVy = _readFloat ( file )
	
	if mapWidth and maxUVy then
		return mapWidth, mapHeight
	end
end

function xrLevelAggregator.update ( )
	for player, sender in pairs ( xrLevelAggregator.senders ) do
		if isElement ( player ) then
			if not sender:update ( ) then
				xrLevelAggregator.senders [ player ] = nil
			end
		else
			xrLevelAggregator.senders [ player ] = nil
		end
	end
end

function xrLevelAggregator._buildThread ( param )
	local worldPixelsWidth = WORLD_SIZE_X * MAP_SIZE
	local worldPixelsHeight = WORLD_SIZE_Y * MAP_SIZE
	
	-- Обновим ревизию карты
	xrLevelAggregator.revision = xrLevelAggregator.revision + 1
	
	local worldFile = fileCreate ( ":terrain_editor/heightmap.xtg" )
	
	-- Пишем ревизию карты
	local revisionDataStr = dataToBytes ( "ui", xrLevelAggregator.revision )
	fileWrite ( worldFile, revisionDataStr )
	
	local rowPattetn = ""
	outputDebugString ( "Creating row pattetn..." )
	for i = 1, worldPixelsWidth do
		rowPattetn = rowPattetn .. dataToBytes ( "s", 128 * 50 )
	end
	for i = 1, worldPixelsHeight do
		fileWrite ( worldFile, rowPattetn )
	end
	
	outputDebugString ( "Building the world..." )
	
	-- Подсчитаем количество операция для вывода прогресса
	local totalOps = 0
	for _, elementRef in ipairs ( xrLevelAggregator.levels ) do
		if fileExists ( "locations/" .. elementRef [ 1 ] .. ".dat" ) then
			totalOps = totalOps + elementRef [ 4 ]
		else
			outputDebugString ( "Файла высот уровня не существует", 2 ) 
		end
	end
	
	local passedOps = 0 -- Операций выполнено
	local skipOps = 0
	
	for _, elementRef in ipairs ( xrLevelAggregator.levels ) do
		outputDebugString ( "Building " .. elementRef [ 1 ] .. " level(" .. elementRef [ 15 ] .. " raise)" )
		local file = fileOpen ( "locations/" .. elementRef [ 1 ] .. ".dat", true )
		if file then
			fileSetPos ( file, 24 )
		
			local exeption = false
		
			local elementIndex = elementRef [ 6 ] * worldPixelsWidth + elementRef [ 5 ]
			for i = 1, elementRef [ 4 ] do
				local rowData = fileRead ( file, elementRef [ 3 ] * 2 )
				local newData = ""
				
				-- Поднимаем ландшафт
				for i = 0, elementRef [ 3 ] - 1 do
					local byte = string.sub ( rowData, i*2 + 1, i*2 + 2 )
					local oldLevel = bytesToData ( "s", byte ) / 128
					local level = oldLevel + elementRef [ 15 ]
					
					if level < 0 then
						exeption = true
						newData = newData .. byte
					else
						newData = newData .. dataToBytes ( "s", level * 128 )
					end
				end
				
				local index = elementIndex + ( (i-1) * worldPixelsWidth )
				
				fileSetPos ( worldFile, 4 + index*2 )
				fileWrite ( worldFile, newData )
				
				passedOps = passedOps + 1
				
				skipOps = skipOps + 1
				if skipOps > 1000 then
					skipOps = 0
					coroutine.yield ( passedOps / totalOps )
				end
			end
			fileClose ( file )
			
			if exeption then
				outputChatBox ( "Вершина локации " .. elementRef [ 1 ] .. " слижком низко!" )
			end
		else
			outputDebugString ( "Файла высот уровня не существует", 2 ) 
		end
	end
	
	fileClose ( worldFile )
	
	-- Сохраняем список локаций
	local xml = xmlCreateFile ( "locations.xml", "locations" )
	xrLevelAggregator.saveList ( xml )
	xmlSaveFile ( xml )
	xmlUnloadFile ( xml )
	
	outputDebugString ( "Мир успешно скомпилирован под ревизию " .. tostring ( xrLevelAggregator.revision ) )
end

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		xrLevelAggregator.init ( )
	end
, false )

addEvent ( "onPlaceLevel", true )
addEventHandler ( "onPlaceLevel", resourceRoot,
	function ( index, x, y )
		local element = {
			index = index,
			x = x,
			y = y
		}
		table.insert ( xrLevelAggregator.elements, element )
		
		outputDebugString ( "Элемент создан", 3 )
		
		local xml = xmlCreateFile ( "elements.xml", "elements" )
		xrLevelAggregator.saveToXml ( xml )
		xmlSaveFile ( xml )
		xmlUnloadFile ( xml )
	end
, false )

addEvent ( "onLevelDrag", true )
addEventHandler ( "onLevelDrag", resourceRoot,
	function ( index, x, y )
		local element = xrLevelAggregator.levels [ index ]
		if element then
			element [ 5 ] = x
			element [ 6 ] = y
			
			outputDebugString ( "Элемент с индексом " .. index .. " перемещен", 3 )
			
			local xml = xmlCreateFile ( "locations.xml", "locations" )
			xrLevelAggregator.saveList ( xml )
			xmlSaveFile ( xml )
			xmlUnloadFile ( xml )
			
			-- Вызываем у всех кроме инициатора
			local players = getElementsByType ( "player" )
			for _, player in ipairs ( players ) do
				if player ~= client then
					triggerClientEvent ( player, "onClientLevelDrag", resourceRoot, index, x, y )
				end
			end
		else
			outputDebugString ( "Элемента с индексом " .. index .. " не существует", 2 )
		end
	end
, false )

addEvent ( "onLevelRotate", true )
addEventHandler ( "onLevelRotate", resourceRoot,
	function ( index, rot )
		local element = xrLevelAggregator.levels [ index ]
		if element then
			element [ 14 ] = tonumber ( rot ) or 0
			
			outputDebugString ( "Элемент с индексом " .. index .. " перевернут", 3 )
			
			local xml = xmlCreateFile ( "locations.xml", "locations" )
			xrLevelAggregator.saveList ( xml )
			xmlSaveFile ( xml )
			xmlUnloadFile ( xml )
			
			-- Вызываем у всех кроме инициатора
			local players = getElementsByType ( "player" )
			for _, player in ipairs ( players ) do
				if player ~= client then
					triggerClientEvent ( player, "onClientLevelRotate", resourceRoot, index, element [ 14 ] )
				end
			end
		else
			outputDebugString ( "Элемента с индексом " .. index .. " не существует", 2 )
		end
	end
, false )

addEvent ( "onChangeLevelProp", true )
addEventHandler ( "onChangeLevelProp", resourceRoot,
	function ( levelIndex, xBias, yBias, rChannel, gChannel, bChannel, aChannel, raise )
		local element = xrLevelAggregator.levels [ levelIndex ]
		if element then
			element [ 7 ] = tonumber ( xBias ) or 0
			element [ 8 ] = tonumber ( yBias ) or 0
			
			element [ 10 ] = tonumber ( rChannel ) or 1
			element [ 11 ] = tonumber ( gChannel ) or 2
			element [ 12 ] = tonumber ( bChannel ) or 3
			element [ 13 ] = tonumber ( aChannel ) or 4
			
			element [ 15 ] = tonumber ( raise ) or 0
			
			outputDebugString ( "Элемент с индексом " .. levelIndex .. " обновлен", 3 )
			
			local xml = xmlCreateFile ( "locations.xml", "locations" )
			xrLevelAggregator.saveList ( xml )
			xmlSaveFile ( xml )
			xmlUnloadFile ( xml )
		end
	end
, false )

addEvent ( "onXrFilesResponse", true )
addEventHandler ( "onXrFilesResponse", resourceRoot,
	function ( list )
		if type ( list ) ~= "table" then
			outputDebugString ( "Не найдено искомое значение", 2 )
			
			return
		end
		
		if #list > 0 then
			local sender = xrNetSender.new ( client )
			for _, fileIndex in ipairs ( list ) do
				local fileName = xrLevelAggregator.fileNames [ fileIndex ]
				if fileName then
					table.insert ( sender.fileNames, "maps/" .. fileName .. ".dds" )
				else
					outputDebugString ( "Не было найдено имени файла с индексом " .. fileIndex, 2 )
				end
			end
			sender:send ( )
			xrLevelAggregator.senders [ client ] = sender
		end
	end
, false )

addEvent ( "onStartWorldBuiling", true )
addEventHandler ( "onStartWorldBuiling", resourceRoot,
	function ( )
		xrLevelAggregator.buildMap ( )
	end
, false )

addCommandHandler ( "xreditor",
	function ( player, _, param )
		if xrLevelAggregator.senders [ player ] ~= nil then
			outputChatBox ( "Дождитесь окончания загрузки" )
			return
		end

		triggerClientEvent ( player, "onClientXrEditor", resourceRoot, param == "-builder" and EDITOR_BUILDER or EDITOR_DESIGN, xrLevelAggregator.levels, xrLevelAggregator.fileNames )
	end
)