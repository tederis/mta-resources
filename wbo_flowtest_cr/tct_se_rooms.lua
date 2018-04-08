GameRoom = { }
GameRoom.__index = GameRoom

function GameRoom.new ( element )
	local room = {
		element = element,
		name = getElementData ( element, "name", false ),
		players = { }
	}
	return setmetatable ( room, GameRoom )
end

--[[
	Rooms
]]
RoomManager = { }

local playerRoom = { }
local roomPlayers = { }
local dimensionRoom = { }

addEvent ( "onPlayerRoomJoin" )
addEvent ( "onPlayerRoomQuit" )

function RoomManager.addPlayerToRoom ( player, room, silent )
	if isElement ( room ) ~= true then return end;

	local prevRoom = getElementData ( player, "room", false )
	if prevRoom then
		if prevRoom == room then return end;
		
		table.removevalue ( roomPlayers [ prevRoom ], player )
		
		RoomManager.onPlayerLeave ( player, prevRoom )
	end
	
	local name = getElementData ( room, "name" )
	
	setElementData ( player, "room", room )
	-- Для scoreboard только
	setElementData ( player, "room_name", name )
	
	if roomPlayers [ room ] == nil then
		roomPlayers [ room ] = { }
	end
	table.insert ( roomPlayers [ room ], player )
	
	local dimension = getElementData ( room, "dimension" )
	setElementDimension ( player, tonumber ( dimension ) )
	
	if silent ~= true then
		outputChatBox ( "* " .. getPlayerName ( player ) .. " has joined the room " .. name, root, 255, 100, 100 )
	end
		
	RoomManager.onPlayerJoin ( player, room )
	RoomManager.onPlayerRoomChange ( player, prevRoom, room )
	
	--spawn ( player )
end

function RoomManager.removePlayerFromRoom ( player )
	local prevRoom = getElementData ( player, "room", false )
	if prevRoom then
		table.removevalue ( roomPlayers [ prevRoom ], player )
		
		RoomManager.onPlayerLeave ( player, prevRoom )
	end
end

function RoomManager.getPlayerRoom ( player )
	return getElementData ( player, "room", false ) or g_GuestRoom
end

function RoomManager.getRoomPlayers ( room )
	return roomPlayers [ room ] or { }
end

function RoomManager.isPlayerInRoom ( player, room )
	return getElementData ( player, "room", false ) == room
end

function RoomManager.getElementsInRoomByType ( room, elementType )
	local dimension = tonumber ( getElementData ( room, "dimension", false ) )
	local elementsInRoom = { }
	local elements = getElementsByType ( elementType )
	for i = 1, #elements do
		if getElementDimension ( elements [ i ] ) == dimension then
			elementsInRoom [ #elementsInRoom + 1 ] = elements [ i ]
		end
	end
	return elementsInRoom
end

function RoomManager.onPlayerJoin ( player, room )
	removeElementData ( player, "undam" )

	EventManager.triggerEvent ( room, "Game:GameRoom", 4, player )
	EventManager.triggerEvent ( room, "Game:GameRoom", 5, roomPlayers [ room ] )
	EventManager.triggerEvent ( room, "Game:GameRoom", 1, player )
	triggerEvent ( "onPlayerRoomJoin", player, room )
	triggerClientEvent ( "onClientPlayerRoomJoin", player, room )
end

function RoomManager.onPlayerLeave ( player, room )
	EventManager.triggerEvent ( room, "Game:GameRoom", 4, player )
	EventManager.triggerEvent ( room, "Game:GameRoom", 5, roomPlayers [ room ] )
	EventManager.triggerEvent ( room, "Game:GameRoom", 2, player )
	triggerEvent ( "onPlayerRoomQuit", player, room )
	triggerClientEvent ( "onClientPlayerRoomQuit", player, room )
end

function RoomManager.onPlayerRoomChange ( player, oldroom, newroom )
	triggerEvent ( "onPlayerRoomChange", player, oldroom, newroom )
	triggerClientEvent ( "onClientPlayerRoomChange", player, oldroom, newroom )
end

function RoomManager.kickPlayer ( player )
	RoomManager.addPlayerToRoom ( player, g_GuestRoom, true )
end

function RoomManager._onlyJoined ( player )
	removeElementData ( player, "room" )

	-- Перемещаем игрока в гостевую комнату
	RoomManager.addPlayerToRoom ( player, g_GuestRoom, true )

	-- Отправляем список ACL игроку
	local acls = RoomACL.getACLList ( )
	EditorStartPacket.send ( player, "Start_ACLs", acls )
end

function RoomManager.registerRoom ( room )
	local dimension = tonumber ( getElementData ( room, "dimension", false ) )
	if dimension then
		dimensionRoom [ dimension ] = room
	end
end

function RoomManager.getElementRoom ( element )
	local dimension = getElementDimension ( element )
	return dimensionRoom [ tonumber ( dimension ) ] or g_GuestRoom
end

function RoomManager.isElementInRoom ( element, room )
	local dimension = getElementDimension ( element )
	return dimensionRoom [ tonumber ( dimension ) ] == room
end

function RoomManager.initRooms ( )
	-- Создаем гостевую комнату если она не создана
	g_GuestRoom = getElementByID ( "guest-room" )
	if not g_GuestRoom then
		g_GuestRoom = createElement ( "room", "guest-room" )
			
		setElementData ( g_GuestRoom, "id", "guest-room" )
		setElementData ( g_GuestRoom, "name", "Guest room" )
		setElementData ( g_GuestRoom, "owner", "Console" )
		setElementData ( g_GuestRoom, "dimension", "0" )
		setElementData ( g_GuestRoom, "no-objs", "1" )
			
		setElementParent ( g_GuestRoom, mapRoot )
	end
		
	local rooms = getElementsByType ( "room", resourceRoot )
	for _, room in ipairs ( rooms ) do
		RoomManager.registerRoom ( room )
	end
end

addEventHandler ( "onPedWasted", resourceRoot,
	function ( )
		setTimer ( destroyElement, 10000, 1, source )
	end
)

addEvent ( "onRoomAdminAction", true )
addEventHandler ( "onRoomAdminAction", root,
	function ( player, actionIndex, arg )
		if RoomManager.isPlayerInRoom ( player, source ) ~= true then
			return
		end
		
		if source == g_GuestRoom then
			outputChatBox ( "TCT: You can not modify the Guest room!", client, 200, 0, 0 )
			return
		end
	
		-- Kick
		if actionIndex == 0 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.kick" ) then
				if hasObjectPermissionTo ( player, "function.alcDestroy", false ) then
					outputChatBox ( "You can not kick this player!", client, 255, 0, 0 )
				else
					RoomManager.kickPlayer ( player )
					outputChatBox ( getPlayerName ( player ) .. " was kicked from the room " .. getElementData ( source, "name" ) )
				end
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
		
		-- Ban
		elseif actionIndex == 1 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.ban" ) then
				-- TODO
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
		
		-- Mute
		elseif actionIndex == 2 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.mute" ) then
				-- TODO
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
			
		-- Set ACL
		elseif actionIndex == 3 then
			local playerAccount = getPlayerAccount ( player )
			if isGuestAccount ( playerAccount ) ~= true then
				if getAccountName ( playerAccount ) == getElementData ( source, "owner", false ) then
					outputChatBox ( "TCT: You can not change the rights for himself!", client, 200, 0, 0, true )
					return
				end
			end
		
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.setacl" ) then
				RoomACL.setPlayerRoomACL ( player, source, arg )
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
		end
	end
)

-- Запрос клиента на получение ALC игрока
addEvent ( "onRoomGetPlayerACL", true )
addEventHandler ( "onRoomGetPlayerACL", resourceRoot,
	function ( player )
		if RoomManager.isPlayerInRoom ( player, source ) ~= true then
			return
		end
	
		local playerACL = RoomACL.getPlayerRoomACL ( player, source )
		triggerClientEvent ( client, "onClientRoomPlayerACL", source, player, playerACL or "Everyone" )
	end
)

addEvent ( "onRoomSettingAction", true )
addEventHandler ( "onRoomSettingAction", resourceRoot,
	function ( actionIndex, arg )
		if source == g_GuestRoom then
			outputChatBox ( "TCT: You can not modify the Guest room!", client, 200, 0, 0 )
			return
		end
	
		-- Change pass
		if actionIndex == 0 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.setpass" ) then
				if utfLen ( arg ) > 0 then
					setElementData ( source, "pass", arg )
				else
					removeElementData ( source, "pass" )
				end
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
			
		-- No Everyone objects
		elseif actionIndex == 1 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.settings" ) then
				if arg == true then
					setElementData ( source, "no-objs", "1" )
				else
					removeElementData ( source, "no-objs" )
				end
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
			
		-- No world models
		elseif actionIndex == 2 then
			if RoomACL.hasPlayerPermissionTo ( client, source, "room.settings" ) then
				if arg == true then
					setElementData ( source, "no-wm", "1" )
				else
					removeElementData ( source, "no-wm" )
				end
			else
				outputChatBox ( "TCT: Access denied", client, 200, 0, 0, true )
			end
		end
	end
)

function isAllowedBuildInRoom ( player, room )
	local noObjs = getElementData ( room, "no-objs", false )
	if noObjs == "1" then
		local playerACL = RoomACL.getPlayerRoomACL ( player, room )
		return ( playerACL ~= nil and playerACL ~= "Everyone" )
	end
	
	return true
end

--[[
	RoomACL System
]]
RoomACL = { 
	objects = { 
		--['object']={['room1']='acl1',['room2']='acl2'}
	},
	ACLs = { 
		--['acl']={'right1','right2'}
	}
}

-- Вызывется для загрузки объектов и прав из XML
function RoomACL.loadRights ( xml )
	local objects = RoomACL.objects
	local ACLs = RoomACL.ACLs

	local xmlNodes = xmlNodeGetChildren ( xml )
	for _, node in ipairs ( xmlNodes ) do
		local nodeType = xmlNodeGetName ( node )
		local nodeName = xmlNodeGetAttribute ( node, "name" )
		if nodeType == "object" then
			local aclName = xmlNodeGetAttribute ( node, "acl" )
			objects [ nodeName ] = { }
			local roomNodes = xmlNodeGetChildren ( node )
			for _, roomNode in ipairs ( roomNodes ) do
				local roomId = xmlNodeGetAttribute ( roomNode, "id" )
				local roomAcl = xmlNodeGetAttribute ( roomNode, "acl" )
				objects [ nodeName ] [ roomId ] = roomAcl
			end
		elseif nodeType == "acl" then
			ACLs [ nodeName ] = { }
			local rightNodes = xmlNodeGetChildren ( node )
			for _, rightNode in ipairs ( rightNodes ) do
				local rightName = xmlNodeGetAttribute ( rightNode, "name" )
				table.insert ( ACLs [ nodeName ], rightName )
			end
		end
	end
end

-- Вызывется для сохранения объектов и прав в XML
function RoomACL.saveRights ( xml )
	local objects = RoomACL.objects
	local ACLs = RoomACL.ACLs
	
	for objName, objRooms in pairs ( objects ) do
		local objNode = xmlCreateChild ( xml, "object" )
		xmlNodeSetAttribute ( objNode, "name", objName )
		for roomId, aclName in pairs ( objRooms ) do
			local roomNode = xmlCreateChild ( objNode, "room" )
			xmlNodeSetAttribute ( roomNode, "id", roomId )
			xmlNodeSetAttribute ( roomNode, "acl", aclName )
		end
	end
	for aclName, aclRights in pairs ( ACLs ) do
		local aclNode = xmlCreateChild ( xml, "acl" )
		xmlNodeSetAttribute ( aclNode, "name", aclName )
		for _, rightName in ipairs ( aclRights ) do
			local rightNode = xmlCreateChild ( aclNode, "right" )
			xmlNodeSetAttribute ( rightNode, "name", rightName )
		end
	end
end

-- Выдает все права игрока в комнате
function RoomACL.getPlayerRoomRights ( player, room )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		return
	end
	local accountName = getAccountName ( account )
	local accountRooms = RoomACL.objects [ accountName ]
	if accountRooms then
		local accountACL = accountRooms [ getElementData ( room, "id", false ) ]
		if accountACL then
			return RoomACL.ACLs [ accountACL ]
		end
	end
end

-- Проверяет наличие права у игрока на действие в комнате
function RoomACL.hasPlayerPermissionTo ( player, room, action )
	local rights = RoomACL.getPlayerRoomRights ( player, room )
	if rights then
		for i = 1, #rights do
			if rights [ i ] == action then return true end;
		end
	end
	
	return hasObjectPermissionTo ( player, "command.tct", false )
end

-- Задает игроку ACL
function RoomACL.setPlayerRoomACL ( player, room, aclName )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		return
	end
	
	if not RoomACL.ACLs [ aclName ] then
		return
	end
	
	local accountName = getAccountName ( account )
	local accountRooms = RoomACL.objects [ accountName ]
	if accountRooms then
		accountRooms [ getElementData ( room, "id", false ) ] = aclName
	else
		RoomACL.objects [ accountName ] = {
			[ getElementData ( room, "id", false ) ] = aclName
		}
	end
end

function RoomACL.getPlayerRoomACL ( player, room )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		return
	end
	local accountName = getAccountName ( account )
	local accountRooms = RoomACL.objects [ accountName ]
	if accountRooms then
		return accountRooms [ getElementData ( room, "id", false ) ]
	end
end

-- Выдает список всех ACL
function RoomACL.getACLList ( )
	local ACLs = { }
	for aclName, _ in pairs ( RoomACL.ACLs ) do
		ACLs [ #ACLs + 1 ] = aclName
	end
	
	return ACLs
end