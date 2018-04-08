local mapName, mapPath
local saveDelay = tonumber ( 
	get ( "*saveDelay" ) 
)

setTimer (
	function ( )
		if getPlayerCount ( ) < 1 then
			return
		end
		
		local newMap = createMap ( mapPath )

		if newMap then
			saveMapData ( newMap, mapRoot, true )
		
			xmlSaveFile ( newMap )
			xmlUnloadFile ( newMap )
			
			outputChatBox ( "WBO: Карта успешно сохранена", root, 0, 255, 0 )
		end
	end
, saveDelay, 0 )

addCommandHandler ( "mapsave",
	function ( player )
		if hasObjectPermissionTo ( player, "command.tct", false ) then
			local newMap = createMap ( mapPath )

			if newMap then
				saveMapData ( newMap, mapRoot, true )
			
				xmlSaveFile ( newMap )
				xmlUnloadFile ( newMap )
				
				outputChatBox ( "WBO: Быстрое сохранени карты успешно выполнено", root, 0, 255, 0 )
			end
		end 
	end
)

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		mapName = tostring ( get ( "*mapName" ) ) .. ".map"
		mapPath = "maps/" .. mapName
		
		outputChatBox(mapPath)
		
		local mapFile = xmlLoadFile ( mapPath )
		
		if mapFile then
			mapRoot = loadMapData ( mapFile, resourceRoot )
		else
			mapRoot = createElement ( "map" )
		end
		
		outputDebugString ( "WBO: Карта загружена" )
		
		--Marker colshape fix
		local markers = getElementsByType ( "marker", mapRoot )
		for _, marker in ipairs ( markers ) do
			local markerType = getElementData ( marker, "type" )
			
			setMarkerType ( marker, "checkpoint" )
			setMarkerType ( marker, markerType )
		end
		
		outputDebugString ( "WBO: Маркеры обработаны" ) 
		outputChatBox ( "WBO: Карта успешно загружена", root, 0, 255, 0 )
	end 
)

function createMap ( file ) 
	local newMap = xmlCreateFile ( file, "map" )
	xmlSaveFile ( newMap )
	
	return newMap
end