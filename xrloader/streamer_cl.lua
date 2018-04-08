addEvent ( "onClientSectorStreamIn", false )
addEvent ( "onClientSectorStreamOut", false )

SECTOR_SIZE = 750
HALF_SECTOR_SIZE = SECTOR_SIZE / 2
WORLD_WIDTH = 6750
WORLD_HEIGHT = 9000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE
LOD_LEVEL = 1 -- Не работает

local _mathMin = math.min
local _mathMax = math.max
local _mathFloor = math.floor
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end

EVENT_IN = 1
EVENT_OUT = 2

--[[
	xrStreamerWorld
]]
xrStreamerWorld = { 
	sectors = { },
	activated = { },
	elements = { --[[ element = sectorIndex ]] },
	await = { }
}

SECTOR_INACTIVE = 1
SECTOR_ACTIVE = 2

xrModelCollection = {
	models = { },
	
	extend = function ( model, sector )
		local data = xrModelCollection.models [ model ]
		if data then
			-- Предохраняемся от лишнего инкремента количества
			if data.sectors [ sector ] == nil then
				data.sectors [ sector ] = SECTOR_INACTIVE
				data.sectorsNum = data.sectorsNum + 1
			end
		else
			xrModelCollection.models [ model ] = {
				sectors = { 
					[ sector ] = SECTOR_INACTIVE
				}, -- Таблица секторов, которые хранят данную модель
				sectorsNum = 1, -- Количество секторов в таблице 'sectors'
				refs = 0 -- Количество ссылок на модель только от активных секторов
			}
		end
	end,
	free = function ( model, sector )
		local data = xrModelCollection.models [ model ]
		-- Предохраняемся от лишнего декремента количества
		if data and data.sectors [ sector ] ~= nil then
			data.sectors [ sector ] = nil
			data.sectorsNum = data.sectorsNum - 1
			
			-- Удаляем данные модели если она больше не нужна
			if data.sectorsNum < 1 then
				xrModelCollection.models [ model ] = nil
			end
		end
	end,
	incrementRefs = function ( model, sector )
		local data = xrModelCollection.models [ model ]
		if data then
			data.sectors [ sector ] = SECTOR_ACTIVE
			data.refs = data.refs + 1
			return data.refs
		end
	end,
	decrementRefs = function ( model, sector )
		local data = xrModelCollection.models [ model ]
		if data then
			data.sectors [ sector ] = SECTOR_INACTIVE
			data.refs = data.refs - 1
			return data.refs
		end
	end,
	isActivated = function ( model, sector )
		local data = xrModelCollection.models [ model ]
		if data then
			return data.sectors [ sector ] == SECTOR_ACTIVE
		end
	end
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
	
	setTimer ( xrStreamerWorld.update, 500, 0 )
end

function xrStreamerWorld.insertElement ( element )
	if xrStreamerWorld.elements [ element ] then
		return
	end
	
	local x, y = getElementPosition ( element )
	local sector = xrStreamerWorld.findSector ( x, y )
	if sector then
		local model = getElementModel ( element )
		
		-- Если сектор получил данную модель, добавляем ее в коллецию
		if sector:extendModels ( model ) == 1 then
			xrModelCollection.extend ( model, sector )
		end
		
		xrStreamerWorld.elements [ element ] = sector
		
		return sector
	end
end

function xrStreamerWorld.removeElement ( element )
	local sector = xrStreamerWorld.elements [ element ]
	if sector then
		local model = getElementModel ( element )
		
		-- Если сектор больше не содержит данную модель, удаляем его из коллекции
		if sector:removeModel ( model ) == 0 then
			xrModelCollection.free ( model, sector )
		end
		
		xrStreamerWorld.elements [ element ] = nil
		
		return sector
	end
end

function xrStreamerWorld.findSector ( x, y )
	x = ( x - xrStreamerWorld.worldX ) / SECTOR_SIZE
	y = ( xrStreamerWorld.worldY - y ) / SECTOR_SIZE
	
	local column = _mathFloor ( x )
	local row = _mathFloor ( y )
	local _index = row * WORLD_SIZE_X + column + 1 -- Пакуем координаты для быстрого поиска
	
	return xrStreamerWorld.sectors [ _index ]
end

function xrStreamerWorld.update ( )
	local x, y = getCameraMatrix ( localPlayer )
	local sector = xrStreamerWorld.findSector ( x, y )
	
	if sector ~= xrStreamerWorld.sector then
		xrStreamerWorld.onSectorEnter ( sector )
	end
	
	local now = getTickCount ( )
	for sector, data in pairs ( xrStreamerWorld.await ) do
		if data.event == EVENT_IN and now - data.startTime > 500 then
			if xrStreamerWorld.activated [ sector ] then
				sector:streamIn ( true )
			end
			xrStreamerWorld.await [ sector ] = nil
		elseif data.event == EVENT_OUT and now - data.startTime > G_SECTOR_DELAY then
			if xrStreamerWorld.activated [ sector ] == nil then
				sector:streamOut ( true )
			end
			xrStreamerWorld.await [ sector ] = nil
		end
	end
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
		_, uncommon = xrStreamerWorld.sector:compareSurroundings ( sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				xrStreamerWorld.activated [ _sector ] = true
			end
		end
	else
		local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
		table.insert ( surrounding, 1, sector )
		for i, _sector in ipairs ( surrounding ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				xrStreamerWorld.activated [ _sector ] = true
			end
		end
	end
	
	xrStreamerWorld.sector = sector
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
		models = {
			-- [ model ] = refsNum
		}
	}
	
	return setmetatable ( sector, xrStreamerSector )
end

function xrStreamerSector:extendModels ( model )
	model = tonumber ( model )
	if model then
		local modelRefs = self.models [ model ]
		if modelRefs then
			self.models [ model ] = modelRefs + 1
			return modelRefs + 1
		else
			self.models [ model ] = 1 -- Устанавливаем количество ссылок равное одной
			return 1
		end
	else
		outputDebugString ( "Модель должна быть числом", 2 )
	end
end

function xrStreamerSector:removeModel ( model )
	model = tonumber ( model )
	if model then
		local modelRefs = self.models [ model ]
		if modelRefs and modelRefs > 1 then
			self.models [ model ] = modelRefs - 1
			return modelRefs - 1
		else
			self.models [ model ] = nil
			return 0
		end
	else
		outputDebugString ( "Модель должна быть числом", 2 )
	end
end

--[[
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
end]]

function xrStreamerSector:getSurroundingSectors ( )
	--[[
		1 | 2 | 3
		4 |   | 5
		6 | 7 | 8
		
		Собирает окружаюшие сектора
	]]


	local array = {
		[ 2 ] = self._top,
		[ 4 ] = self._left,
		[ 5 ] = self._right,
		[ 7 ] = self._bottom
	}
	
	if self._top then
		array [ 1 ] = self._top._left
		array [ 3 ] = self._top._right
	else
		if self._left then array [ 1 ] = self._left._top end
        if self._right then array [ 3 ] = self._right._top end
	end
	if self._bottom then
		array [ 6 ] = self._bottom._left
		array [ 8 ] = self._bottom._right
	else
		if self._left then array [ 6 ] = self._left._bottom end
        if self._right then array [ 8 ] = self._right._bottom end
	end
	
	return array
end

function xrStreamerSector:isMySurroundingSector ( sector )
	local surrounding = self:getSurroundingSectors ( LOD_LEVEL )
	
	--[[for _, _sector in ipairs ( surrounding ) do
		if _sector == sector then
			return true
		end
	end]]
	
	for i = 1, 8 do
		if surrounding [ i ] and surrounding [ i ] == sector then
			return true
		end
	end
end

function xrStreamerSector:compareSurroundings ( sector, includeCenter )
	local common = { }
    local uncommon = { }

    local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
	--[[for _, _sector in ipairs ( surrounding ) do
		if self:isMySurroundingSector ( _sector ) then
			table.insert ( common, _sector )
		else 
			table.insert ( uncommon, _sector )
		end
	end]]
   for i = 1, 8 do
        if surrounding [ i ] then
            if self:isMySurroundingSector ( surrounding [ i ] ) then
				table.insert ( common, surrounding [ i ] )
            else 
				table.insert ( uncommon, surrounding [ i ] )
			end
        end
    end
	
	if includeCenter then
        if self:isMySurroundingSector ( sector ) then
			table.insert ( common, sector )
        else
			table.insert ( uncommon, sector )
		end
    end
	
	return common, uncommon
end

-- Принуждаем сектор загружаться
function xrStreamerSector:forceMeshLoading ( mesh )
	local meshModel = tonumber (
		getElementData ( mesh, "model", false )
	)
	-- Содержит ли сектор данную модель
	if self.models [ meshModel ] and xrModelCollection.isActivated ( meshModel, self ) ~= true then
		-- Увеличиваем количество ссылок на модель
		-- это нужно для защиты от выгрузки моделей на других секторах
		if xrModelCollection.incrementRefs ( meshModel, self ) == 1 then
			-- Если модель еще не загружена или не загружется - сделаем это
			if xrLoader.getMeshState ( mesh ) <= MESH_READY then
				xrLoader.loadMesh ( mesh )
			end
		end
	end
end

-- Принуждаем сектор выгружаться
function xrStreamerSector:forceMeshRestore ( mesh )
	local meshModel = tonumber (
		getElementData ( mesh, "model", false )
	)
	-- Содержит ли сектор данную модель
	if self.models [ meshModel ] and xrModelCollection.isActivated ( meshModel, self ) then
		-- Увеличиваем количество ссылок на модель
		-- это нужно для защиты от выгрузки моделей на других секторах
		if xrModelCollection.decrementRefs ( meshModel, self ) == 0 then
			if xrLoader.getMeshState ( mesh ) >= MESH_LOADING then
				xrLoader.restoreMesh ( mesh )
			end
		end
	end
end

function xrStreamerSector:streamIn ( force )
	local awaitData = xrStreamerWorld.await [ self ]
	if awaitData == nil then
		xrStreamerWorld.await [ self ] = {
			startTime = getTickCount ( ),
			event = EVENT_IN
		}
		outputChatBox ( "Wait to load " .. self._index )
		return
	end
	
	if awaitData.event == EVENT_IN and force then
		outputChatBox ( "Load " .. self._index )
	
		for model, refs in pairs ( self.models ) do
			if xrModelCollection.isActivated ( model, self ) ~= true then
				-- Увеличиваем количество ссылок на модель
				-- это нужно для защиты от выгрузки моделей на других секторах
				local mesh = getElementByID ( "m" .. model )
				if mesh ~= false and xrModelCollection.incrementRefs ( model, self ) == 1 then
					-- Если модель еще не загружена или не загружется - сделаем это
					if xrLoader.getMeshState ( mesh ) <= MESH_READY then
						--local meshGeom = getElementData ( mesh, "geom", false )
						--if meshGeom:find ( "_lod" ) then
						xrLoader.loadMesh ( mesh )
					end
				end
			end
		end
		
		xrLoader.onSectorStreamIn ( self )
	end
end

function xrStreamerSector:streamOut ( force )
	local awaitData = xrStreamerWorld.await [ self ]
	if awaitData == nil then
		xrStreamerWorld.await [ self ] = {
			startTime = getTickCount ( ),
			event = EVENT_OUT
		}
		outputChatBox ( "Wait to unload " .. self._index )
		return
	end

	if awaitData.event == EVENT_OUT and force then
		outputChatBox ( "Unload " .. self._index )
	
		-- Выгружаем модели
		for model, refs in pairs ( self.models ) do
			if xrModelCollection.isActivated ( model, self ) then
				-- Уменьшаем количество ссылок на модель
				-- это нужно для защиты от выгрузки моделей на других секторах
				local mesh = getElementByID ( "m" .. model )
				if mesh ~= false and xrModelCollection.decrementRefs ( model, self ) == 0 then
					if xrLoader.getMeshState ( mesh ) >= MESH_LOADING then
						xrLoader.restoreMesh ( mesh )
					end
				end
			end
		end
		
		self.forcedModels = { 
			-- Сбрасываем таблицу принудительных моделей
		}
		
		xrLoader.onSectorStreamOut ( self )
	end
end