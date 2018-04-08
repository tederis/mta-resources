if true then return end


-- DO NOT CHANGE!
SECTOR_SIZE = 300
HALF_SECTOR_SIZE = SECTOR_SIZE / 2
WORLD_WIDTH = 6000
WORLD_HEIGHT = 6000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE

LOD_LEVEL = 1

local _mathFloor = math.floor

--[[
	xrStreamerWorld
]]
xrStreamerWorld = { 
	sectors = { },
	activated = { },
	activeElements = { },
	dimension = 0
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
	local x, y = getCameraMatrix ( )
	local sector = xrStreamerWorld.findSector ( x, y )
	if sector ~= xrStreamerWorld.sector then
		xrStreamerWorld.onSectorEnter ( sector )
	end
end

function xrStreamerWorld.onSectorEnter ( sector )
	if xrStreamerWorld.sector then
		-- Выгружаем ненужные сектора
		local _, uncommon = sector:compareSurroundings ( xrStreamerWorld.sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if _sector ~= sector then
				if xrStreamerWorld.activated [ _sector ] then
					_sector:streamOut ( )
					
					_sector.activated = nil
					xrStreamerWorld.activated [ _sector ] = nil
				end
			end
		end
		
		-- Загружаем новые вхождения
		_, uncommon = xrStreamerWorld.sector:compareSurroundings ( sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				
				_sector.activated = true
				xrStreamerWorld.activated [ _sector ] = true
			end
		end
	else
		-- Загружаем уровень в первый раз
		local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
		table.insert ( surrounding, 1, sector )
		for i, _sector in ipairs ( surrounding ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector:streamIn ( )
				
				_sector.activated = true
				xrStreamerWorld.activated [ _sector ] = true
			end
		end
	end
	
	--proj:setMatrix ( sector.x + SECTOR_SIZE/2, sector.y - SECTOR_SIZE/2, 0, 0, 0, 0 )
	
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

function xrStreamerSector:isMySurroundingSector ( sector )
	local surrounding = self:getSurroundingSectors ( LOD_LEVEL )
	
	for _, _sector in ipairs ( surrounding ) do
		if _sector == sector then
			return true
		end
	end
end

function xrStreamerSector:compareSurroundings ( sector, includeCenter )
	local common = { }
    local uncommon = { }

    local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
	for _, _sector in ipairs ( surrounding ) do
		if self:isMySurroundingSector ( _sector ) then
			table.insert ( common, _sector )
		else 
			table.insert ( uncommon, _sector )
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

function xrStreamerSector:streamIn ( player )

end

function xrStreamerSector:streamOut ( player )
	
end