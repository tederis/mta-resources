-- Типы данных
DATA_ANY = 1

APPLY_TO_ALL = -1 -- Флаг для применения схемы ко всем объектам, на которых она уже находится

LogicComponent = {

}

local entityTypes = {
	object = true,
	ped = true,
	vehicle = true,
	player = true,
	[ "wbo:spawnpoint" ] = true,
	path = true,
	[ "wbo:area" ] = true
}

isEntityType = function ( strType )
	return entityTypes [ strType ] ~= nil
end

_isElementPed = function ( element )
	if isElement ( element ) then
		local elementType = getElementType ( element )
		return elementType == "ped" or elementType == "player"
	end
	
	return false
end

_isElementPlayer = function ( element )
	if isElement ( element ) then
		return getElementType ( element ) == "player"
	end
	
	return false
end

_isElementVehicle = function ( element )
	if isElement ( element ) then
		return getElementType ( element ) == "vehicle"
	end
	
	return false
end

_isVector3D = function ( vector )
	if type ( vector ) == "table" then
		return tonumber ( vector.x ) ~= nil and tonumber ( vector.z ) ~= nil
	end
end

local GTATypes = {
	object = true,
	ped = true,
	vehicle = true
}

function isGTAElement ( element )
	local elementType = getElementType ( element )
	return GTATypes [ elementType ] == true
end

function LogicComponent.getLinkedElement ( linkedID )
	if type ( linkedID ) == "string" then
		return getElementByID ( linkedID )
	end
end

function isPlayerGraphOwner ( player, graph )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) ~= true then
		local accountName = getAccountName ( account )
		if graph.owner ~= accountName and hasObjectPermissionTo ( player, "command.tct", false ) ~= true then
			return false
		end
  
		return true
	end
	
	return false
end

--[[
	Крепление схемы к элементу
]]
--[[addEvent ( "setElementGraph", true )
addEventHandler ( "setElementGraph", resourceRoot,
	function ( element, graphId )
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			if graph.public ~= true and isPlayerGraphOwner ( client, graph ) ~= true then
				outputChatBox ( "TCT: Вы не можете использовать эту схему", client, 255, 0, 0, true )
				return
			end
		
			if isElement ( element ) then
				createElementID ( element )
		
				if applyElementGraph ( element, graph ) then
					setElementData ( element, "graphID", graphId )
					outputChatBox ( "TCT: Схема успешно собрана и применена к объекту", client, 0, 255, 0 )
				else
					outputChatBox ( "TCT: Схема не может быть собрана [требуется не менее двух нодов]", client, 255, 0, 0 )
				end
			end
		end
	end
, false )]]

--[[
	Создание связи
]]
addEvent ( "createEdge", true )
addEventHandler ( "createEdge", resourceRoot,
	function ( graphId, srcPoint, dstPoint )
		local graph = GraphManager.getGraph ( graphId )
		if not graph then return end;
		
		if isPlayerGraphOwner ( client, graph ) ~= true then
			outputChatBox ( "TCT: You can not change the graph", client, 255, 0, 0, true )
			return
		end
	
		if type ( srcPoint ) ~= "table" or type ( dstPoint ) ~= "table" then outputDebugString ( "[FATAL ERROR] Клиент отправил невалидное описание портов!", 1 ) return end;
		
		if srcPoint [ 1 ] == dstPoint [ 2 ] then outputChatBox ( "TCT: You can not connect a node to itself", client, 255, 0, 0 ) return end;
		if srcPoint [ 2 ] == dstPoint [ 2 ] then outputChatBox ( "TCT: You can not connect the ports of the same type", client, 255, 0, 0 ) return end;
	
		-- Если последовательность подключения неправильная исправляем ее
		if dstPoint [ 2 ] > 1 then
			local src = srcPoint
		
			srcPoint = dstPoint
			dstPoint = src
		end
		
		local nodeSrc = graph.nodes [ srcPoint [ 1 ] ]
		local nodeDst = graph.nodes [ dstPoint [ 1 ] ]
		
		if nodeSrc == nil or nodeDst == nil then
			outputDebugString ( "[FATAL ERROR] При создании связи не были указаны ноды!", 1 )
			return
		end
		
		local srcNodeAbstr = nodeSrc.abstr
		local dstNodeAbstr = nodeDst.abstr
		
		local srcPointType = srcPoint [ 3 ] > 0 and srcNodeAbstr.events.outputs [ srcPoint [ 3 ] ] [ 2 ] or dstNodeAbstr.events.container
		local dstPointType = dstPoint [ 3 ] > 0 and dstNodeAbstr.events.inputs [ dstPoint [ 3 ] ] [ 2 ] or dstNodeAbstr.events.container
		
		--[[if dstPointType ~= "any" and dstPointType ~= srcPointType then
			outputChatBox ( "WBO: Вы не можете соединить точки с разными типами", client, 255, 0, 0 )
			return
		end]]
		
		-- Если к этому порту уже подключена связь, удаляем ее
		local edge = graph:getConnectedToNodeEdge ( nodeDst, dstPoint [ 3 ] )
		if edge then
			graph:destroyEdge ( edge )
			triggerClientEvent ( "onClientGraphAction", resourceRoot, graph.id, 1, 1, edge.id )
		end
		
		local edgeId = generateString ( 10 )
		edge = EditorEdge.create ( nodeSrc.id, tostring ( srcPoint [ 3 ] ), nodeDst.id, tostring ( dstPoint [ 3 ] ), edgeId )
		if edge then
			graph:addEdge ( edge )
		
			local packedEdge = packEdge ( edge )
			triggerClientEvent ( "onClientGraphAction", resourceRoot, graph.id, 2, packedEdge )
		end
	end
, false )

--[[
	Создание нода
]]
-- Копия на клиенте!
local guiDefaultProperty = {
	btn = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	checkbox = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	combobox = {
		Position = "0.5,0.5",
		Size = "0.3,0.3"
	},
	edit = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	lbl = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	}
}

addEvent ( "onCreateGLCComponent", true )
addEventHandler ( "onCreateGLCComponent", resourceRoot,
	function ( id, tag, x, y, linked )
		local graph = GraphManager.getGraph ( id )
		if graph then
			if isPlayerGraphOwner ( client, graph ) ~= true then
				outputChatBox ( "TCT: You can not change the graph", client, 255, 0, 0, true )
				return
			end
		
			local nodeId = generateString ( 10 )
			local node = EditorNode.create ( nodeId, tag, linked )
			if node then
				node:setupProperties ( )
				node:setPosition ( x, y )
				
				local guiType = node.abstr.gui
				if guiType ~= nil then
					for name, value in pairs ( guiDefaultProperty [ guiType ] ) do
						node:setProperty ( name, value )
					end
				end
				
				graph:addNode ( node )
				
				local packedNode = packNode ( node )
				triggerClientEvent ( "onClientGraphAction", resourceRoot, id, 0, packedNode )
			end
		end
	end
)

--[[
	Удаление нода / связи
]]
addEvent ( "onDestroyGLCComponent", true )
addEventHandler ( "onDestroyGLCComponent", resourceRoot,
	function ( graphId, itype, id )
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			if isPlayerGraphOwner ( client, graph ) ~= true then
				outputChatBox ( "TCT: You can not change the graph", client, 255, 0, 0, true )
				return
			end
		
			-- Нод
			if itype == 0 then
				graph:destroyNode ( graph.nodes [ id ] )
			
			-- Связь
			elseif itype == 1 then
				graph:destroyEdge ( graph.edges [ id ] )
			end
			triggerClientEvent ( "onClientGraphAction", resourceRoot, graphId, 1, itype, id )
		end
	end
)

--[[
	Крепление уже созданной схемы к элементу и сохранение ее схемы
]]
addEvent ( "onChangeElementGraph", true )
addEventHandler ( "onChangeElementGraph", resourceRoot,
	function ( graphId, element, isPublic )
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			if isPlayerGraphOwner ( client, graph ) ~= true then
				outputChatBox ( "TCT: You can not change the graph", client, 255, 0, 0, true )
				return
			end
			
			graph.public = isPublic
		
			-- Применить схему к объекту, если он указан
			if isElement ( element ) then
				createElementID ( element )
		
				if applyElementGraph ( element, graph ) then
					--setElementData ( element, "graphID", graphId )
					saveElementGraph ( element, graph )
					outputChatBox ( "TCT: The graph has successfully compiled and applied to the object", client, 0, 255, 0 )
				else
					outputChatBox ( "TCT: The graph can not be compiled [requires at least two nodes]", client, 255, 0, 0 )
				end
				
			-- Обновить схему на всех объектах, к которым она прикреплена
			elseif element == APPLY_TO_ALL then
				local numOfElements = refreshGraphElements ( graph )
				outputChatBox ( "TCT: The graph is applied to the " .. numOfElements .. " objects", client, 0, 255, 0 )
			end
			
			-- Сохраняем схему
			local filename = "graphs/" .. tostring ( graphId ) .. ".xml"
			local xmlfile = xmlCreateFile ( filename, "graph" )
			graph:saveToXml ( xmlfile )
			xmlSaveFile ( xmlfile )
			xmlUnloadFile ( xmlfile )
		end
	end
, false )

addEvent ( "onElementDetachGraph", true )
addEventHandler ( "onElementDetachGraph", resourceRoot,
	function ( graphId )
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			removeElementGraph ( source, graph )
		end
		
		destroyElementGraph ( source, graphId )
		
		outputChatBox ( "TCT: You have successfully removed the graph from the object", client, 0, 200, 0 )
	end
)

local supportedTargetTypes = {
	ped = true,
	vehicle = true,
	object = true,
	path = true,
	s_weapon = true,
	[ "wbo:trigger" ] = true,
	[ "wbo:spawnpoint" ] = true,
	[ "wbo:area" ] = true
}

--[[
	Изменение целевого элемента у нода
]]
addEvent ( "onChangeElementTarget", true )
addEventHandler ( "onChangeElementTarget", resourceRoot,
	function ( graphId, nodeId, element )
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			if isPlayerGraphOwner ( client, graph ) ~= true then
				outputChatBox ( "TCT: You can not change the graph", client, 255, 0, 0, true )
				return
			end
		
			local node = graph.nodes [ nodeId ]
			if node then
				if isElement ( element ) then
					local elementType = getElementType ( element )
					if supportedTargetTypes [ elementType ] ~= true then 
						outputChatBox ( "TCT: Node can not be attached to an object with this type", client, 255, 0, 0 )
						return 
					end
					local targetType = node.abstr.events.target
					if elementType == targetType or ( targetType == "entity" and isEntityType ( elementType ) ) or targetType == "element" then
						local linkedID = createElementID ( element )
						node.linked = linkedID
						outputChatBox ( "TCT: You have successfully attached the node to the object", client, 50, 255, 50 )
					end
				elseif element == 0x01 or 0x02 then
					node.linked = element == 0x01 and "each" or "random"
					outputChatBox ( "TCT: Вы успешно изменили режим бинда таргета", client, 50, 255, 50 )
				end
			end
		end
	end
)

--[[
	Создание новой схемы и добавление ее в каталог
]]
function saveElementGraph ( element, graph )
	local graphId = graph.id
	local graphs = getElementChildren ( element, "graph" )
	local graphElement
	for i = 1, #graphs do
		graphElement = graphs [ i ]
		if getElementID ( graphElement ) == graphId then
			return
		end
	end
	
	graphElement = createElement ( "graph" )
	setElementID ( graphElement, graphId )
	setElementParent ( graphElement, element )
	
	return true
end

function destroyElementGraph ( element, graph )
	local graphId
	if type ( graph ) == "table" then
		graphId = graph.id
	elseif type ( graph ) == "string" then
		graphId = graph
	else
		return
	end

	local graphs = getElementChildren ( element, "graph" )
	for i = 1, #graphs do
		local graphElement = graphs [ i ]
		if getElementID ( graphElement ) == graphId then
			destroyElement ( graphElement )
		end
	end
end

function findElementGraphs ( element )
	local graphs = getElementChildren ( element, "graph" )
	return graphs
end


--[[
	Создание новой схемы или ее копии
]]
addEvent ( "onEditorCreateGraph", true )
addEventHandler ( "onEditorCreateGraph", resourceRoot,
	function ( name, packedGraph, element, isPublic )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in", client, 255, 0, 0, true )
			return
		end
	
		local newId = generateString ( 10 )
		local graph = EditorGraph.create ( newId, name )
		if graph then
			graph.owner = getAccountName ( account )
			graph.public = isPublic
			graph:unpack ( packedGraph )
		
			-- Если передан элемент, применяем для него схему
			if isElement ( element ) then
				if isPlayerElementOwner ( client, element ) then 
					applyElementGraph ( element, graph )
					saveElementGraph ( element, graph )
				
					outputDebugString ( "TCT: Создана новая схема и применена к элементу" )
				else
					outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
				end
			else
				outputDebugString ( "TCT: Создана новая схема", client, 0, 255, 0, true )
			end
		
			GraphManager.addGraphToCatalog ( graph )
			triggerClientEvent ( "onClientCatalogAddGraph", resourceRoot, { newId, tostring ( graph.owner ), false, tostring ( graph.name ) } )
		end
	end
, false )

--[[
	Запрос схемы
]]
addEvent ( "onGraphRequest", true )
addEventHandler ( "onGraphRequest", resourceRoot,
	function ( id )
		local graph = GraphManager.getGraph ( id )
		if graph then
			if graph.public or isPlayerGraphOwner ( client, graph ) then
				local packedGraph = packGraph ( graph )
				triggerClientEvent ( client, "onClientGraphRequest", resourceRoot, id, packedGraph )
			else
				outputChatBox ( "TCT: You can not open this graph", client, 255, 0, 0, true )
			end
		else
			outputChatBox ( "TCT: A graph for the object not found", client, 255, 0, 0 )
		end
	end
, false )

--[[
	Аттач / Детач схемы для игрока
]]
local graphsList = {
	unpack = function ( var )
		if type ( var ) == "string" then
			local materials = { }
		
			local items = split ( var, 44 )
			for i = 1, #items do
				materials [ #materials + 1 ] = items [ i ]
			end
		
			return materials
		end
	end,
	pack = function ( tbl )
		if type ( tbl ) == "table" then
			local materialsStr = ""
		
			for i = 1, #tbl do
				materialsStr = materialsStr .. tbl [ i ] .. ","
			end
		
			return materialsStr
		end
	end
}

--[[
	Действия над схемой с клиента
]]
addEvent ( "onGraphAction", true )
addEventHandler ( "onGraphAction", resourceRoot,
	function ( graphId, action, arg1, arg2, arg3 )
		local graph = GraphManager.getGraph ( graphId )
		if not graph then return end;
		
		if isPlayerGraphOwner ( client, graph ) ~= true then
			outputChatBox ( "TCT: You can not open this graph", client, 255, 0, 0, true )
			return
		end
	
		-- Изменение свойств нода
		if action == 0 then
			local node = graph.nodes [ arg1 ]
			if node then
				for i = 1, #arg2 do
					local property = arg2 [ i ]
					node:setProperty ( property [ 1 ], property [ 2 ] )
					--outputChatBox ( property [ 1 ] .. " = " .. property [ 2 ])
				end
				triggerClientEvent ( "onClientGraphAction", resourceRoot, graphId, 3, arg1, arg2 )
			end
			
		-- Обновление положения
		elseif action == 1 then
			local node = graph.nodes [ arg1 ]
			if node then
				node:setPosition ( arg2, arg3 )
			end
		end
	end
, false )

function packNode ( node )
	local outpack = { 
		0, -- флаг нода
			
		node.x, node.y,
		node.id, node.tag,
		node.linked,
		{ }
	}
	
	local properties = outpack [ 7 ]
	for index, value in pairs ( node.properties ) do
		properties [ #properties + 1 ] = { 
			index, value
		}
	end

	return outpack
end

function packEdge ( edge )
	local outpack = {
		1, -- флаг связи
			
		edge.nodeSrc, edge.portSrc,
		edge.nodeDst, edge.portDst,
		edge.id
	}
	
	return outpack
end

function packGraph ( graph )
	local outpack = { 
		graph.public,
		graph.owner,
		graph.name
	}

	-- Пакуем ноды
	local nodes = graph.nodes
	for _, node in pairs ( nodes ) do
		outpack [ #outpack + 1 ] = packNode ( node )
	end
	
	-- Пакуем связи
	local edges = graph.edges
	for _, edge in pairs ( edges ) do
		outpack [ #outpack + 1 ] = packEdge ( edge )
	end
	
	return outpack
end


addEvent ( "doGraphDestroy", true )
addEventHandler ( "doGraphDestroy", resourceRoot,
	function ( graphId )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in", client, 255, 0, 0, true )
			return
		end
	
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			-- TODO
		end
	end
, false )

--[[
	Rooms
]]
addEvent ( "doAddRoomGraph", true )
addEventHandler ( "doAddRoomGraph", resourceRoot,
	function ( graphId )
		if RoomACL.hasPlayerPermissionTo ( client, source, "room.graph" ) ~= true then
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
			return
		end
	
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			applyElementGraph ( source, graph )
			saveElementGraph ( source, graph )
			
			--triggerClientEvent ( "onClientAddRoomGraph", source, { graph.id, graph.owner, graph.public, graph.name } )
			outputDebugString ( graphId .. " прикреплен на " .. getElementID ( source ) .. " комнату" )
		end
	end
)

addEvent ( "doRemoveRoomGraph", true )
addEventHandler ( "doRemoveRoomGraph", resourceRoot,
	function ( graphId )
		if RoomACL.hasPlayerPermissionTo ( client, source, "room.graph" ) ~= true then
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
			return
		end
		
		local graph = GraphManager.getGraph ( graphId )
		if graph then
			removeElementGraph ( source, graph )
		end
		
		destroyElementGraph ( source, graphId )
	end
)

addEvent ( "doAddRoomScript", true )
addEventHandler ( "doAddRoomScript", resourceRoot,
	function ( scriptId )
		if RoomACL.hasPlayerPermissionTo ( client, source, "room.graph" ) ~= true then
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
			return
		end
		
		local script = ScriptCollection.find ( scriptId )
		if script then
			script:applyToElement ( source )
			saveElementScript ( source, script )
			
			outputDebugString ( scriptId .. " прикреплен на " .. getElementID ( source ) .. " комнату" )
		end
	end
)

function getDimensionFromName ( name )
	local dimension = 0
	local len = utfLen ( name )
	for i = 1, len do
		local char = utfSub ( name, i, i )
		local code = utfCode ( char )
		dimension = dimension + code
	end
	
	return dimension
end

addEvent ( "doWarpPlayerToRoom", true )
addEventHandler ( "doWarpPlayerToRoom", resourceRoot,
	function ( pass )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in", client, 255, 0, 0, true )
			return
		end
		
		local roomPass = getElementData ( source, "pass", false )
		if roomPass == false or pass == roomPass then
			RoomManager.addPlayerToRoom ( client, source )
		else
			outputChatBox ( "TCT: Incorrect password", client, 255, 0, 0, true )
		end
	end
)

addEvent ( "doCreateRoom", true )
addEventHandler ( "doCreateRoom", resourceRoot,
	function ( roomName )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in", client, 255, 0, 0, true )
			return
		end
	
		local room = createElement ( "room" )
		createElementID ( room )
		setElementData ( room, "name", tostring ( roomName ) )
		setElementData ( room, "owner", getAccountName ( account ) )
		local dimension = tostring ( getDimensionFromName ( roomName ) )
		setElementData ( room, "dimension", dimension )
		
		-- Выдаем владельцу комнаты права админа на нее
		RoomACL.setPlayerRoomACL ( client, room, "Admin" )
		
		-- Регистрируем комнату
		RoomManager.registerRoom ( room )
		
		setElementParent ( room, mapRoot )
		
		triggerClientEvent ( "onClientRoomCreate", room )
	end
, false )

local roomDestroyTypes = {
	"object",
	"ped",
	"vehicle",
	"empty",
	"wbo:trigger",
	"wbo:spawnpoint",
	"path"
}
addEvent ( "doRemoveRoom", true )
addEventHandler ( "doRemoveRoom", resourceRoot,
	function ( )
		if RoomACL.hasPlayerPermissionTo ( client, source, "room.remove" ) then
			if source == g_GuestRoom then
				outputChatBox ( "TCT: You can not remove the Guest room!", client, 200, 0, 0 )
				return
			end
		
			-- Удаляем все объекты в комнате
			local destroyNum = 0
			for _, elementType in ipairs ( roomDestroyTypes ) do
				local elements = getElementsByType ( elementType, resourceRoot )
				for i = 1, #elements do
					if RoomManager.isElementInRoom ( elements [ i ], source ) then
						destroyElement ( elements [ i ] )
						destroyNum = destroyNum + 1
					end
				end
			end
			
			outputChatBox ( "TCT: Room has been removed(" .. destroyNum .. " elements)", client )
			outputDebugString ( "Игрок " .. getPlayerName ( client ) .. " удалил комнату " .. getElementData ( source, "dimension" ) )
			
			triggerClientEvent ( "onClientRoomDestroy", source )
			destroyElement ( source )
		else
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
		end
	end
)

addEvent ( "doRoomChangePassword", true )
addEventHandler ( "doRoomChangePassword", resourceRoot,
	function ( pass )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in", client, 255, 0, 0, true )
			return
		end
		
		local owner = getElementData ( source, "owner", false )
		if owner == getAccountName ( account ) then
			if utfLen ( pass ) > 0 then
				setElementData ( source, "pass", tostring ( pass ) )
				outputChatBox ( "TCT: A new password has been accepted", client, 0, 255, 0, true )
			else
				removeElementData ( source, "pass" )
				outputChatBox ( "TCT: Password has been removed", client, 0, 255, 0, true )
			end
		else
			outputChatBox ( "TCT: You can not work in that room!", client, 255, 0, 0, true )
		end
	end
)

--[[
	Room mods
]]
local function addModToRoom ( modId, room )
	modId = tostring ( modId )
	local mods = getElementChildren ( room, "mod" )
	for i = 1, #mods do
		if getElementData ( mods [ i ], "name", false ) == modId then
			return
		end
	end
	
	local modElement = createElement ( "mod" )
	setElementData ( modElement, "name", modId )
	setElementParent ( modElement, room )
	
	return true
end

local function removeModFromRoom ( modId, room )
	modId = tostring ( modId )
	local mods = getElementChildren ( room, "mod" )
	for _, mod in ipairs ( mods ) do
		if getElementData ( mod, "name", false ) == modId then
			destroyElement ( mod )
			return true
		end
	end
end

addEvent ( "doRoomAddMod", true )
addEventHandler ( "doRoomAddMod", resourceRoot,
	function ( modId )
		modId = tonumber ( modId )
		if exports.wbo_modmanager:isModValid ( modId ) ~= true then
			outputDebugString ( "Мода с индексом " .. modId .. " не существует", 2 )
			return
		end

		if RoomACL.hasPlayerPermissionTo ( client, source, "room.mod" ) ~= true then
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
			return
		end
		
		if addModToRoom ( modId, source ) ~= true then
			outputChatBox ( "A mod with the same name already exists", client, 255, 0, 0, true )
		end
	end
)

addEvent ( "doRoomRemoveMod", true )
addEventHandler ( "doRoomRemoveMod", resourceRoot,
	function ( modId )
		if RoomACL.hasPlayerPermissionTo ( client, source, "room.mod" ) ~= true then
			outputChatBox ( "TCT: Access denied", client, 255, 0, 0, true )
			return
		end
		
		removeModFromRoom ( modId, source )
	end
)