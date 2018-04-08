if true then return end

MAP_SIZE = 6000
HALF_MAP_SIZE = MAP_SIZE / 2
SECTOR_COUNT = 20
SECTOR_SIZE = MAP_SIZE / SECTOR_COUNT
HALF_SECTOR_SIZE = SECTOR_SIZE / 2

mapX, mapY = -HALF_MAP_SIZE, HALF_MAP_SIZE

SectorManager = { 
	sectors = { }
}

local elementSectors = { }

function SectorManager.create ( )
	for column = 0, SECTOR_COUNT do
		for row = 0, SECTOR_COUNT do
			local sector = SectorManager.createSector ( column, row )
			sector:loadPixels ( )
		end
	end
	
	setTimer ( SectorManager.onUpdate, 1000, 0 )
end

function SectorManager.onUpdate ( )
	local players = getElementsByType ( "player" )
	for _, player in ipairs ( players ) do
		local x, y = getElementPosition ( player )
		local column, row = math.floor ( ( x - mapX ) / SECTOR_SIZE ), math.floor ( ( mapY - y ) / SECTOR_SIZE )
		
		local sector = SectorManager.getSector  ( column, row )
		--outputChatBox(sector)
		if sector ~= elementSectors [ player ] then
			SectorManager.onElementEnterSector ( player, sector )
			
			elementSectors [ player ] = sector
		end
	end
end

function SectorManager.onElementEnterSector ( element, sector )
	-- Если элемент был раньше в одном из секторов, удалаем его оттуда
	if elementSectors [ element ] then
		elementSectors [ element ]:removeElement ( element )
	end

	-- Добавляем элемент в новый сектор
	if sector then
		sector:addElement ( element )
		sector:sync ( element )
	end
end

function SectorManager.getOrCreateSector ( column, row )
	local sector = SectorManager.getSector ( column, row )
	if sector then
		return sector
	end
	
	return SectorManager.createSector ( column, row )
end

function SectorManager.createSector ( column, row )
	local sector = Sector.create ( column, row )
	table.insert ( SectorManager.sectors, sector )
	
	return sector
end

function SectorManager.getSector ( column, row )
	for _, sector in ipairs ( SectorManager.sectors ) do
		if sector.column == column and sector.row == row then
			--outputChatBox ( sector.column)
			--outputChatBox("hgjghjhjghj")
			return sector
		end
	end
end

Sector = { }
Sector.__index = Sector

local sectorMatrix = { 
	{ -1, 1 }, { 0, 1 }, { 1, 1 },
	{ -1, 0 }, { 0, 0 }, { 1, 0 },
	{ -1, -1 }, { 0, -1 }, { 1, -1 }
}

function Sector.create ( column, row )
	local sector = {
		column = column,
		row = row,
		--index = column - row,
		elements = { },
		
		--rt = dxCreateRenderTarget ( size, size, true )
	}
	
	return setmetatable ( sector, Sector )
end

function Sector:addElement ( element )
	outputChatBox ( getPlayerName ( element ) .. " добавлен в [" .. self.column .. ", " .. self.row .. "]")

	self.elements [ element ] = true
end

function Sector:removeElement ( element )
	outputChatBox ( getPlayerName ( element ) .. " удален из [" .. self.column .. ", " .. self.row .. "]")

	self.elements [ element ] = nil
end

function Sector:sync ( player )
	for i = 1, 9 do
		local mat = sectorMatrix [ i ]
		local column, row = self.column + mat [ 1 ], self.row - mat [ 2 ]
		local sector = SectorManager.getSector ( column, row )
		
		if sector.pixels then
			triggerLatentClientEvent ( player, "sector:update", 50000, false, resourceRoot, column, row, sector.pixels )
		end
	end
end

function Sector:loadPixels ( )
	local sectorStr = self.column .. "+" .. self.row
	local filepath =  "sectors/" .. sectorStr .. ".png"

	if fileExists ( filepath ) then
		local fh = fileOpen ( filepath )
		local pixels = fileRead ( fh, fileGetSize ( fh ) )
		
		self.pixels = pixels
		
		outputChatBox ( filepath )
		
		fileClose ( fh )
	end
end

addEvent ( "sector:update", true )
addEventHandler ( "sector:update", resourceRoot, 
	function ( player, column, row, pixels )
		local sector = SectorManager.getSector ( column, row )
		sector.pixels = pixels
		
		local sectorStr = column .. "+" .. row
		local fh = fileCreate ( "sectors/" .. sectorStr .. ".png" )
		fileWrite ( fh, pixels )
		fileClose ( fh )
		
		outputChatBox ("принято")
	end
, false, "normal" )

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		SectorManager.create ( )
	end
, false )