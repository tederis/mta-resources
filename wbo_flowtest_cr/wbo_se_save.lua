local mapName, mapPath
local saveDelay = tonumber ( 
	get ( "*saveDelay" ) 
)
local lastSaveTicks = getTickCount ( )

setTimer (
	function ( )
		if getPlayerCount ( ) < 1 then
			return
		end
		
		outputChatBox ( "TCT: Saving the game world...", root, 0, 255, 0 )
		
		local xmlfile = xmlCreateFile ( "graphs/graphs.xml", "graphs" )
		GraphManager.saveCatalogToXml ( xmlfile )
		xmlSaveFile ( xmlfile )
		xmlUnloadFile ( xmlfile )
		
		-- Сохраняем ACL для комнат
		xmlfile = xmlCreateFile ( "roomacl.xml", "objects" )
		RoomACL.saveRights ( xmlfile )
		xmlSaveFile ( xmlfile )
		xmlUnloadFile ( xmlfile )
		
		local newMap = createMap ( mapPath )
		if newMap then
			saveMapData ( newMap, mapRoot, true )
		
			xmlSaveFile ( newMap )
			xmlUnloadFile ( newMap )
		end
		
		lastSaveTicks = getTickCount ( )
	end
, saveDelay, 0 )

addCommandHandler ( "mapsave",
	function ( player )
		if hasObjectPermissionTo ( player, "command.tct", false ) then
			if getTickCount ( ) - lastSaveTicks > saveDelay - 1000 then
				outputChatBox ( "WBO: Вы не можете сохранить карту сейчас. Подождите несколько секунд.", player, 255, 0, 0 )
				return
			end
			
			outputChatBox ( "TCT: Saving the game world...", root, 0, 255, 0 )
			
			local xmlfile = xmlCreateFile ( "graphs/graphs.xml", "graphs" )
			GraphManager.saveCatalogToXml ( xmlfile )
			xmlSaveFile ( xmlfile )
			xmlUnloadFile ( xmlfile )
			
			-- Сохраняем ACL для комнат
			xmlfile = xmlCreateFile ( "roomacl.xml", "objects" )
			RoomACL.saveRights ( xmlfile )
			xmlSaveFile ( xmlfile )
			xmlUnloadFile ( xmlfile )
		
			local newMap = createMap ( mapPath )
			if newMap then
				saveMapData ( newMap, mapRoot, true )
			
				xmlSaveFile ( newMap )
				xmlUnloadFile ( newMap )
			end
		end 
	end
)

local graphTypes = {
	"object",
	"ped",
	"vehicle",
	"empty",
	"wbo:trigger",
	"room",
	"wbo:spawnpoint",
	"wbo:area"
}

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		serverStartTime = getTickCount ( )
	
		mapName = tostring ( get ( "*mapName" ) ) .. ".map"
		mapPath = "maps/" .. mapName
		
		outputChatBox ( "TCT: Loading the game world...", root, 0, 255, 0 )
		
		-- Грузим карту
		local mapFile = xmlLoadFile ( mapPath )
		if mapFile then
			mapRoot = loadMapData ( mapFile, resourceRoot )
		else
			mapRoot = createElement ( "map" )
		end
		
		outputDebugString ( "TCT: Map successfully loaded" )
		
		-- Инициализируем комнаты
		RoomManager.initRooms ( )
		
		-- Грузим графы
		local xmlfile = xmlLoadFile ( "graphs/graphs.xml" )
		if xmlfile then
			GraphManager.loadCatalogFromXml ( xmlfile )
			xmlUnloadFile ( xmlfile )
		end
		
		setTimer (
			function ( )
				for _, elementType in ipairs ( graphTypes ) do
					local num = 0
					local elements = getElementsByType ( elementType, mapRoot )
					for i = 1, #elements do
						local element = elements [ i ]
						
						local graphElements = findElementGraphs ( element )
						for j = 1, #graphElements do
							local id = getElementData ( graphElements [ j ], "id", false )
							local graph = GraphManager.getGraph ( id )
							if graph then 
								applyElementGraph ( element, graph )
								num = num + 1
							end
						end
					end
					--outputDebugString ( elementType .. " = " .. num )
				end
			end
		, 1000, 1 )
		
		outputDebugString ( "TCT: Graphs successfully loaded" )
		
		-- Загружаем ACL для комнат
		xmlfile = xmlLoadFile ( "roomacl.xml" )
		if xmlfile then
			RoomACL.loadRights ( xmlfile )
			xmlUnloadFile ( xmlfile )
		end
		
		outputDebugString ( "TCT: Room ACLs successfully loaded" )
		
		TriggerEntity.loadMap ( mapRoot )
		BlipEntity.loadMap ( mapRoot )
		MarkerEntity.loadMap ( mapRoot )
		loadAreaMap ( mapRoot )
		
		setupGamemodeCore ( )
	end 
)

function createMap ( file ) 
	local newMap = xmlCreateFile ( file, "map" )
	xmlSaveFile ( newMap )
	
	return newMap
end