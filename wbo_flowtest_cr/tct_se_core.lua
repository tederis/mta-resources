local CONSTRUCTOR_KEY = "f5"
WBO_DEBUG = false

local corePlayers = { }
local isCoreRun = false

--[[
	Spawn system
]]
function spawnPlayerOnSpawnpoint ( player, spawnpoint )
	local model = getElementData ( spawnpoint, "model", false )
	local stype = getElementData ( spawnpoint, "type", false ) or 0
	local x, y, z = getElementPosition ( spawnpoint )
	local dimension = getElementData ( spawnpoint, "dimension", false )
	
	x, y = x + math.random ( -2, 2 ), y + math.random ( -2, 2 )
	
	-- ped
	if tonumber ( stype ) > 0 then
		spawnPlayerSafe ( player, x, y, z, 0, tonumber ( model ) or randomPedModel ( ), 0, tonumber ( dimension ) or 0 )

	-- vehicle
	else
		spawnPlayerSafe ( player, x + 4, y, z, 0, 0, 0, tonumber ( dimension ) or 0 )
	
		--[[local vehicle = createVehicle ( tonumber ( model ) or randomVehicleModel ( ), x, y, z )
		if vehicle then
			setElementDimension ( vehicle, tonumber ( dimension ) or 0 )
			setElementSyncer ( vehicle, false )
			warpPedIntoVehicle ( player, vehicle )
		end]]
	end
	
	EventManager.triggerEvent ( spawnpoint, "Spawnpoint", 1, player )
end


function spawn(player)
	if isElement ( player ) ~= true then
		return
	end
	
	local room = RoomManager.getPlayerRoom ( player )
	if isElement ( room ) then
		local spawnpoints = RoomManager.getElementsInRoomByType ( room, "wbo:spawnpoint" )
		for i, spawnpoint in ipairs ( spawnpoints ) do
			if RoomManager.isElementInRoom ( spawnpoint, room ) ~= true or getElementData ( spawnpoint, "type", false ) == false then
				table.remove ( spawnpoints, i )
			end
		end
		
		if #spawnpoints > 0 then
			local randomIndex = math.random ( 1, #spawnpoints )
			spawnPlayerOnSpawnpoint ( player, spawnpoints [ randomIndex ] )
		else
			local dimension = getElementData ( room, "dimension", false )
			local x, y = math.random ( -2, 2 ), math.random ( -2, 2 )
			spawnPlayerSafe ( player, x, y, 4, 0, math.random ( 9, 288 ), 0, tonumber ( dimension ) or 0 )
		end

		fadeCamera(player, true)
		setCameraTarget(player, player)
		showChat(player, true)
		
		if spawnpoint then
			EventManager.triggerEvent ( spawnpoint, "Spawnpoint", 1, player )
		end
	else
		-- TEST MSG
		outputDebugString ( "Для игрока " .. getPlayerName ( player ) .. " нет комнаты", 2 )
	end
end

addEventHandler("onPlayerWasted", root,
	function()
		-- Terrain integration
		--setTimer(spawn, 1800, 1, source)
		
		local room = RoomManager.getPlayerRoom ( source )
		RoomManager.addPlayerToRoom ( source, room, true )
	end
)

--[[
	Init
]]
local function transmitPlayerGraphs ( player )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) ~= true then
		local accountName = getAccountName ( account )
		local graphs = GraphManager.findPlayerGraphs ( accountName )

		--triggerClientEvent ( player, "onClientGraphsTransmit", resourceRoot, graphs )
		EditorStartPacket.send ( player, "Start_Graphs", graphs )
	end
end

local function toggleEditor ( player, _, keyState )
	keyState = keyState == "down"

	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		if keyState then
			outputChatBox ( "TCT: You must be logged in!", player, 255, 0, 0, true )
		end
		
		return
	end

	local permission = hasObjectPermissionTo ( player, "command.tct", false )
		
	triggerClientEvent ( player, "onClientTCTToggle", resourceRoot, keyState, permission, getAccountName ( account ) )
	--transmitPlayerGraphs ( player )
end

-- Инициализируем ядро редактора
function setupGamemodeCore ( )
	exports.scoreboard:scoreboardAddColumn ( "room_name", root, 70, "Room" )

	-- 
	setTimer (
		function ( )
			for player, _ in pairs ( corePlayers ) do
				local account = getPlayerAccount ( player )
				if isGuestAccount ( account ) ~= true then
					setupPlayerMoney ( player )
					transmitPlayerGraphs ( player )
					
					bindKey ( player, CONSTRUCTOR_KEY, "both", toggleEditor )
					
					RoomManager._onlyJoined ( player )
				end
				
				-- Terrain integration
				--spawn ( player )
			end
		end
	, 150, 1 )
	
	isCoreRun = true
end

addEvent ( "onTCTClientReady", true )
addEventHandler ( "onTCTClientReady", resourceRoot,
	function ( )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) ~= true then
			corePlayers [ client ] = true
			
			if isCoreRun then
				setupPlayerMoney ( client )
				transmitPlayerGraphs ( client )
					
				bindKey ( client, CONSTRUCTOR_KEY, "both", toggleEditor )
					
				RoomManager._onlyJoined ( client )
			end
		end
	end
, false )

addEventHandler ( "onPlayerJoin", root,
	function ( )
		outputChatBox ( "TCT: Пожалуйста авторизуйтесь для доступа к редактору мира", source, 10, 200, 200 )
		outputChatBox ( "TCT: Please log in to access the World Editor", source, 10, 200, 200 )
	end
)
addEventHandler ( "onPlayerQuit", root,
	function ( )
		RoomManager.removePlayerFromRoom ( source )
	
		local room = RoomManager.getElementRoom ( source )
		if room then
			RoomManager.onPlayerLeave ( source, room )
		end
		
		corePlayers [ source ] = nil
	end
)

addEventHandler ( "onPlayerLogin", root,
	function ( _, account )
		setupPlayerMoney ( source )
		transmitPlayerGraphs ( source )

		bindKey ( source, CONSTRUCTOR_KEY, "both", toggleEditor )
		RoomManager._onlyJoined ( source )
		
		corePlayers [ source ] = true
		
		outputChatBox ( "TCT: Нажмите F5 для перехода в режим редактирования", source, 10, 200, 200 )
		outputChatBox ( "TCT: Press the F5 to enter the edit mode", source, 10, 200, 200 )
	end
)
addEventHandler ( "onPlayerLogout", root,
	function ( _, account )
		if isElement ( account ) ~= true or isGuestAccount ( account ) then
			corePlayers [ source ] = nil
		end
	end
)


addEvent ( "onRoomChat", true )
addEventHandler ( "onRoomChat", root,
	function ( text )
		local room = RoomManager.getPlayerRoom ( client )
		if room then
			text = "(ROOM) " .. getPlayerName ( client ) .. ": " .. text
			local players = RoomManager.getRoomPlayers ( room )
			for _, player in ipairs ( players ) do
				outputChatBox ( text, player )
			end
		end
	end
, false )

function setupPlayerMoney ( player )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then return end;

	local money = getAccountData ( account, "tct:money" )
	if money then
		setPlayerMoney ( player, tonumber ( money ) )
	else
		setAccountData ( account, "tct:money", "5000" )
		setPlayerMoney ( player, 5000 )
	end
end

EditorStartPacket = {
	send = function ( player, packetName, ... )
		triggerClientEvent ( player, "onClientTCTStartPacket", resourceRoot, packetName, ... )
	end
}