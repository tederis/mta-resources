local MAP_SIZE = 6000
local HALF_MAP_SIZE = MAP_SIZE / 2
local SECTOR_SIZE = 9
local HALF_SECTOR_SIZE = SECTOR_SIZE / 2
local mapX, mapY = -HALF_MAP_SIZE, HALF_MAP_SIZE

local fillMatrix = {
	{ -1, 1 }, { 0, 1 }, { 1, 1 },
	{ -1, 0 }, { 0, 0 }, { 1, 0 },
	{ -1, -1 }, { 0, -1 }, { 1, -1 }
}

IceFiller = { }

function IceFiller.create ( )
	if IceFiller.created then
		return
	end
	
	IceFiller.created = true
	
	IceFiller.players = { }
	
	--IceFiller.updateTimer = setTimer ( IceFiller.update, 50, 0 )
	addEventHandler ( "onClientRender", root, IceFiller.update, false )
	
	addEventHandler ( "onClientElementStreamIn", root, IceFiller.streamIn )
	addEventHandler ( "onClientElementStreamOut", root, IceFiller.streamOut )
	addEventHandler ( "onClientPlayerQuit", root, IceFiller.streamOut )
	
	local streamedInPlayers = getElementsByType ( "player", root, true )
	for _, player in ipairs ( streamedInPlayers ) do
		IceFiller.addPlayer ( player )
	end
end

function IceFiller.destroy ( )
	if IceFiller.created then
		IceFiller.created = false
		
		removeEventHandler ( "onClientElementStreamIn", root, IceFiller.streamIn )
		removeEventHandler ( "onClientElementStreamOut", root, IceFiller.streamOut )
		removeEventHandler ( "onClientPlayerQuit", root, IceFiller.streamOut )
	
		--killTimer ( IceFiller.updateTimer )
		removeEventHandler ( "onClientRender", root, IceFiller.update )
		
		for player, filler in pairs ( IceFiller.players ) do
			filler:destroy ( )
		end
		
		IceFiller.players = nil
	end
end

function IceFiller.addPlayer ( player )
	if IceFiller.players [ player ] then
		return
	end

	IceFiller.players [ player ] = PlayerIceFiller.create ( player )
end

function IceFiller.removePlayer ( player )
	local playerFiller = IceFiller.players [ player ]
	if playerFiller then
		playerFiller:destroy ( )
		
		IceFiller.players [ player ] = nil
	end
end

function IceFiller.update ( )
	for player, filler in pairs ( IceFiller.players ) do
		filler:update ( )
	end
end

function IceFiller.streamIn ( )
	if getElementType ( source ) == "player" then
		IceFiller.addPlayer ( source )
	end
end

function IceFiller.streamOut ( )
	if getElementType ( source ) == "player" then
		IceFiller.removePlayer ( source )
	end
end

------------------------------
-- PlayerIceFiller
------------------------------
PlayerIceFiller = { }
PlayerIceFiller.__index = PlayerIceFiller

function PlayerIceFiller.create ( player )
	outputDebugString ( "created " .. getPlayerName ( player ) .. " filler" )

	return setmetatable ( { player = player }, PlayerIceFiller )
end

function PlayerIceFiller:destroy ( )
	if self.objects then
		for i, object in ipairs ( self.objects ) do
			destroyElement ( object )
		end
		
		self.objects = nil
	end
	
	outputDebugString ( "destroyed " .. getPlayerName ( self.player ) .. " filler" )
	
	setmetatable ( self, self )
end

function PlayerIceFiller:update ( )
	local x, y = getElementPosition ( self.player )
	local column, row = math.floor ( ( x - mapX ) / SECTOR_SIZE ), math.floor ( ( mapY - y ) / SECTOR_SIZE )
		
	local sector = row + column
	if sector ~= self.sector then
		self:restream ( column, row )
			
		self.sector = sector
	end
end

function PlayerIceFiller:restream ( column, row )
	if self.objects then
		for i, object in ipairs ( self.objects ) do
			destroyElement ( object )
		end
		
		self.objects = nil
	end
	
	local x, y, z = getElementPosition ( self.player )
	local tz = getWaterLevel ( x, y, z, false )
	
	if not tz then
		return
	end
	
	self.objects = { }
	
	local tx, ty = mapX + ( SECTOR_SIZE * column ) + HALF_SECTOR_SIZE, mapY - ( SECTOR_SIZE * row ) - HALF_SECTOR_SIZE
	
	for i, offset in ipairs ( fillMatrix ) do
		local x, y = tx + ( SECTOR_SIZE * ( offset [ 1 ] ) ), ty + ( SECTOR_SIZE * ( offset [ 2 ] ) )
	
		local object = createObject ( 3095, x, y, tz - 0.6 )
		setElementAlpha ( object, 0 )
		
		table.insert ( self.objects, object )
	end
end