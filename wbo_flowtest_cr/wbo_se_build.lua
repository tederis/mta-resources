addEvent ( "onCreateTCTObject", true )
addEvent ( "onDestroyTCTElement", true )
addEvent ( "onPlaceTCTElement", true )
addEvent ( "onChangeTCTAlpha", true )
addEvent ( "onChangeTCTScale", true )
addEvent ( "onSidedTCTElement", true )
addEvent ( "onFreezeTCTElement", true )
addEvent ( "onAttachTCTElement", true )
addEvent ( "onChangeTCTMaterial", true )
addEvent ( "onCreateWBOTrack", true )

-- Helper functions
local function createEntity ( model, x, y, z, rotx, roty, rotz )
	if model >= 0 and model <= 312 then
		return createPed ( model, x, y, z, rotz )
	elseif model >= 400 and model <= 611 then
		return createVehicle ( model, x, y, z, rotx, roty, rotz )
	else
		return createObject ( model, x, y, z, rotx, roty, rotz )
	end
end

addEventHandler ( "onCreateTCTObject", resourceRoot,
	function ( model, posX, posY, posZ, rotX, rotY, rotZ, scale, ... )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
			return 
		end
		
		local room = RoomManager.getPlayerRoom ( client )
		if isElement ( room ) ~= true then
			outputDebugString ( "The room was not found!", 2 )
			return
		end
		if isAllowedBuildInRoom ( client, room ) ~= true then
			outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
			return
		end
	
		if type ( model ) == "number" and scale then
			posX, posY, posZ = tonumber ( posX ), tonumber ( posY ), tonumber ( posZ )
			local element = createEntity ( model, posX, posY, posZ, rotX, rotY, rotZ )
			if element then
				local accountName = getAccountName ( account )
			
				setElementData ( element, "owner", accountName )
				local dimension = getElementDimension ( client )
				setElementDimension ( element, dimension )
					
				local interior = getElementInterior ( client )
				setElementInterior ( element, interior )
				
				local elementType = getElementType ( element )
				if elementType == "object" then
					scale = tonumber ( scale )
					setObjectScale ( element, scale or 1 )
					setElementData ( element, "scale", scale or "1" )
				elseif elementType == "vehicle" then
					--setElementData ( element, "tag", "Vehicle:Vehicle" )
				end
    
				setElementData ( element, "model", tostring ( model ), false )
				setElementData ( element, "posX", posX ) -- For check
				setElementData ( element, "posY", posY, false )
				setElementData ( element, "posZ", posZ, false )
				setElementData ( element, "rotX", rotX, false )
				setElementData ( element, "rotY", rotY, false )
				setElementData ( element, "rotZ", rotZ, false )
				setElementData ( element, "interior", tostring ( interior ) )
				setElementData ( element, "dimension", tostring ( dimension ), false )
					
				setElementParent ( element, room )
					
				for _, data in ipairs ( arg ) do
					if type ( data ) == "table" and type ( data [ 1 ] ) == "string" then
						setElementData ( element, data [ 1 ], data [ 2 ] )
					end
				end
				
				triggerClientEvent ( "onClientElementCreate", element )
			end
		end
	end 
)

addEventHandler ( "onDestroyTCTElement", resourceRoot,
	function ( onlyAttached )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end

		if onlyAttached then
			for _, element in ipairs ( getAttachedElements ( source ) ) do
				if isElement ( element ) and getElementType ( element ) ~= "player" then
					destroyElement ( element )
				end
			end
		else
			destroyElement ( source )
		end
	end 
)

addEventHandler ( "onPlaceTCTElement", resourceRoot,
	function ( posX, posY, posZ, rotX, rotY, rotZ )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end

		if type ( posX ) == "number" and type ( rotZ ) == "number" then
			setElementPosition ( source, posX, posY, posZ )
			setObjectRotation ( source, rotX, rotY, rotZ )
    
			setElementData ( source, "posX", posX ) -- For check
			setElementData ( source, "posY", posY, false )
			setElementData ( source, "posZ", posZ, false )
			setElementData ( source, "rotX", rotX, false )
			setElementData ( source, "rotY", rotY, false )
			setElementData ( source, "rotZ", rotZ, false )
		end
	end
)

addEventHandler ( "onChangeTCTAlpha", resourceRoot,
	function ( alpha )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
 
		if type ( alpha ) == "number" then
			setElementAlpha ( source, alpha ) 
			setElementData ( source, "alpha", tostring ( alpha ), false )
		end
	end 
)

addEventHandler ( "onChangeTCTScale", resourceRoot,
	function ( scale )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
 
		if type ( scale ) == "number" then
			setObjectScale ( source, scale )
			setElementData ( source, "scale", tostring ( scale ), false )
		end
	end 
)

addEventHandler ( "onSidedTCTElement", resourceRoot,
	function ( )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
		
		local isDoubleSided = not isElementDoubleSided ( source )
		
		setElementDoubleSided ( source, isDoubleSided )
		setElementData ( source, "doublesided", isDoubleSided, false )
	end
)

addEventHandler ( "onFreezeTCTElement", resourceRoot,
	function ( )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
 
		local isFrozen = not isElementFrozen ( source )
		
		setElementFrozen ( source, isFrozen )
		setElementData ( source, "frozen", isFrozen, false )
	end 
)

addEventHandler ( "onAttachTCTElement", root,
	function ( attachTo, x, y, z )
		if isElement ( attachTo ) ~= true then return end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
		
		if isPlayerElementOwner ( client, source, attachTo ) then
			local offsetPosX, offsetPosY, offsetPosZ, offsetRotX, offsetRotY, offsetRotZ = x, y, z, 0, 0, 0
			if tonumber ( x ) == nil or tonumber ( z ) == nil then
				offsetPosX, offsetPosY, offsetPosZ, offsetRotX, offsetRotY, offsetRotZ = getAttachRotationAdjusted ( source, attachTo )
			end

			attachElements ( source, attachTo, offsetPosX, offsetPosY, offsetPosZ, offsetRotX, offsetRotY, offsetRotZ )
			
			setElementData ( source, "attachTo", createElementID ( attachTo ) )
			setElementData ( source, "attachX", offsetPosX )
			setElementData ( source, "attachY", offsetPosY )
			setElementData ( source, "attachZ", offsetPosZ )
			
			setElementData ( source, "attachRZ", tostring ( offsetRotZ ) )
			
			-- Фикс потенциальной проблемы
			if getElementData ( attachTo, "attachTo" ) == getElementData ( source, "id" ) then
				removeElementData ( attachTo, "attachTo" )
			end
			
			outputChatBox ( "TCT: You have successfully attached objects", client )
		else
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
		end
	end 
)

addEventHandler ( "onChangeTCTMaterial", resourceRoot,
	function ( modelTextureIndex, textureId, uScale, vScale )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return
		end
		if getElementData ( source, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
 
		setElementMaterial ( source, modelTextureIndex, textureId, uScale, vScale )
	end 
)

local textureTypes = {
	dds = true--[[, jpg = true]]
}
function setElementMaterial ( element, modelTextureIndex, textureId, uScale, vScale )
	if type ( modelTextureIndex ) ~= "number" then
		return
	end
	
	local room = RoomManager.getElementRoom ( element )
	local players = RoomManager.getRoomPlayers ( room )
	
	if textureId then
		if textureTypes [ exports.wbo_modmanager:getFileType ( textureId ) ] ~= true then
			outputChatBox ( "TCT: Invalid material", client, 200, 0, 0 )
			return
		end
	
		local material = findOrCreateMaterial ( element, modelTextureIndex )
		setElementData ( material, "_id", tostring ( textureId ) )
		setElementData ( material, "u", tostring ( uScale ) )
		setElementData ( material, "v", tostring ( vScale ) )
		
		-- Отправляем материал только тем игрокам, которые находятся в одной комнате с элементом
		for _, player in ipairs ( players ) do
			triggerClientEvent ( player, "onClientElementMaterialChange", element, modelTextureIndex, material )
		end
	else
		local material = findMaterial ( element, modelTextureIndex )
		if material then
			destroyElement ( material )
		end
		
		-- Отправляем материал только тем игрокам, которые находятся в одной комнате с элементом
		for _, player in ipairs ( players ) do
			triggerClientEvent ( player, "onClientElementMaterialChange", element, modelTextureIndex )
		end
	end
end

--Выдает материал по его индексу
function findOrCreateMaterial ( element, modelTextureIndex )
	modelTextureIndex = tostring ( modelTextureIndex )
	local materials = getElementsByType ( "material", element )
	for i = 1, #materials do
		if getElementData ( materials [ i ], "side", false ) == modelTextureIndex then
			return materials [ i ]
		end
	end
	
	local material = createElement ( "material" )
	setElementData ( material, "side", modelTextureIndex )
	setElementParent ( material, element )
	outputDebugString("Новый шаблон материала")
	
	return material
end

function findMaterial ( element, modelTextureIndex )
	modelTextureIndex = tostring ( modelTextureIndex )
	local materials = getElementsByType ( "material", element )
	for i = 1, #materials do
		if getElementData ( materials [ i ], "side", false ) == modelTextureIndex then
			return materials [ i ]
		end
	end
end

addEventHandler ( "onCreateWBOTrack", resourceRoot,
	function ( nodes )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then 
			outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
			return
		end
		
		local room = RoomManager.getPlayerRoom ( client )
		if isElement ( room ) ~= true then
			outputDebugString ( "The room was not found!", 2 )
			return
		end
		if isAllowedBuildInRoom ( client, room ) ~= true then
			outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
			return
		end
		
		if type ( nodes ) == "table" and #nodes > 1 then
			local nodesNum = #nodes
			
			local path = createElement ( "path" )
		
			setElementData ( path, "tag", "Entity:Path" )
			setElementData ( path, "dimension",
				tostring ( getElementDimension ( client ) )
			)
			setElementData ( path, "owner", getAccountName ( account ) )
		
			for i = 1, nodesNum do
				local node = nodes [ i ]
				
				local trackNode = createElement ( "path:node" )
			
				setElementPosition ( trackNode, node [ 1 ], node [ 2 ], node [ 3 ] )
				setElementData ( trackNode, "posX", node [ 1 ] )
				setElementData ( trackNode, "posY", node [ 2 ] )
				setElementData ( trackNode, "posZ", node [ 3 ] )
				if node [ 4 ] and node [ 6 ] then
					setElementRotation ( trackNode, node [ 4 ], node [ 5 ], node [ 6 ] )
					
					setElementData ( trackNode, "rotX", tostring ( node [ 4 ] ) )
					setElementData ( trackNode, "rotY", tostring ( node [ 5 ] ) )
					setElementData ( trackNode, "rotZ", tostring ( node [ 6 ] ) )
				end
			
				-- Пишем индексы для работы с нодами
				setElementData ( trackNode, "index", tostring ( i ) )
				if i < nodesNum then
					setElementData ( trackNode, "nextIndex", tostring ( i + 1 ) )
				end
			
				setElementParent ( trackNode, path )
			
				triggerClientEvent ( "onClientElementCreate", trackNode )
			end
		
			setElementParent ( path, room )
		end
	end
)

function createEmpty ( x, y, z, name )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end
	
	if x and name then
		local empty = createElement ( "empty" )
	
		setElementPosition ( empty, x, y, z )
		setElementData ( empty, "posX", x )
		setElementData ( empty, "posY", y )
		setElementData ( empty, "posZ", z )
		--setElementData ( empty, "name", name )
		--setElementData ( empty, "md", "1" )
		setElementData ( empty, "dimension", tostring ( getElementDimension ( client ) ) )
		setElementData ( empty, "owner", getAccountName ( account ) )
	
		setElementParent ( empty, room )
	
		triggerClientEvent ( "onClientElementCreate", empty )
	
		return empty
	end
end

function createTrigger ( x, y, z, size, enabled )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end

	if x and size then
		--[[if isPointInPlayerArea ( x, y, z, client ) ~= true then
			outputChatBox ( "WBO: Вы не можете строить вне своего участка", client, 255, 0, 0 )
			return
		end]]
	
		local trigger = createElement ( "wbo:trigger" )
	
		setElementPosition ( trigger, x, y, z )
		setElementData ( trigger, "posX", x )
		setElementData ( trigger, "posY", y )
		setElementData ( trigger, "posZ", z )
		setElementData ( trigger, "size", tostring ( size ) )
		setElementData ( trigger, "dimension", tostring ( getElementDimension ( client ) ) )
		setElementData ( trigger, "enabled", enabled == true and "1" or "0" )
		setElementData ( trigger, "tag", "Trigger" )
		setElementData ( trigger, "owner", getAccountName ( account ) )
	
		setElementParent ( trigger, room )
	
		TriggerEntity.setup ( trigger )
		triggerClientEvent ( "onClientElementCreate", trigger )
		
		setElementEnabledTo ( trigger, enabled == true )
	
		return trigger
	end
end

function createEditorBlip ( x, y, z, icon )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end
	
	local blip = createElement ( "tct-blip" )
	
	setElementPosition ( blip, x, y, z )
	setElementData ( blip, "posX", x )
	setElementData ( blip, "posY", y )
	setElementData ( blip, "posZ", z )
	setElementData ( blip, "icon", tostring ( icon ) )
	setElementData ( blip, "tag", "Blip" )
	setElementData ( blip, "dimension", tostring ( getElementDimension ( client ) ) )
	setElementData ( blip, "owner", getAccountName ( account ) )
	
	setElementParent ( blip, room )
	
	BlipEntity.setup ( blip )
	triggerClientEvent ( "onClientElementCreate", blip )
	
	return blip
end

function createEditorMarker ( x, y, z, markerType, size, r, g, b )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end
	
	local marker = createElement ( "tct-marker" )
	
	setElementPosition ( marker, x, y, z )
	setElementData ( marker, "posX", x )
	setElementData ( marker, "posY", y )
	setElementData ( marker, "posZ", z )
	setElementData ( marker, "type", markerType )
	setElementData ( marker, "size", tonumber ( size ) )
	setElementData ( marker, "tag", "Marker" )
	setElementData ( marker, "owner", getAccountName ( account ) )
	
	setElementParent ( marker, room )
	
	MarkerEntity.setup ( marker )
	triggerClientEvent ( "onClientElementCreate", marker )
	
	return marker
end

function createSpawnpoint ( x, y, z, rz, model, type )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end
	
	local spawnpoint = createElement ( "wbo:spawnpoint" )
	
	setElementPosition ( spawnpoint, x, y, z )
	setElementData ( spawnpoint, "owner", tostring ( getAccountName ( account ) ) )
	setElementData ( spawnpoint, "posX", x )
	setElementData ( spawnpoint, "posY", y )
	setElementData ( spawnpoint, "posZ", z )
	setElementData ( spawnpoint, "rotZ", rz )
	if tonumber ( model ) ~= nil then
		setElementData ( spawnpoint, "model", tostring ( model ) )
	end
	if tonumber ( type ) ~= nil then
		setElementData ( spawnpoint, "type", tostring ( type ) )
	end
	setElementData ( spawnpoint, "dimension", tostring ( getElementDimension ( client ) ) )
	setElementData ( spawnpoint, "tag", "Spawnpoint" )
	
	setElementParent ( spawnpoint, room )
	
	triggerClientEvent ( "onClientElementCreate", spawnpoint )
	
	return spawnpoint
end

function toggleEntityProtect ( element )
	if isElement ( element ) then
		if isPlayerElementOwner ( client, element ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
	
		local protectState = getElementData ( element, "protect" ) == "1"
		if protectState then
			setElementData ( element, "protect", "0" )
			outputChatBox ( "TCT: Protection is disabled", client, 0, 255, 0 )
		else
			setElementData ( element, "protect", "1" )
			outputChatBox ( "TCT: Protection is enabled", client, 0, 255, 0 )
		end
	end
end

function setEntityAction ( element, itemsStr, offsetX, offsetY, offsetZ )
	if isElement ( element ) then
		if isPlayerElementOwner ( client, element ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( element, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end
		
		local tag = getElementData ( element, "tag" )
		if tag == "_ActionEnt" then
			removeElementData ( element, "itms" )
			removeElementData ( element, "tag" )
			removeElementData ( element, "offsetX" )
			removeElementData ( element, "offsetY" )
			removeElementData ( element, "offsetZ" )
			
			outputChatBox ( "TCT: Action has been removed", client, 0, 255, 0, true )
		else
			if tag == false then
				setElementData ( element, "itms", itemsStr )
				setElementData ( element, "tag", "_ActionEnt" )
		
				offsetX, offsetZ = tonumber ( offsetX ), tonumber ( offsetZ )
				if offsetX and offsetZ then
					setElementData ( element, "offsetX", offsetX )
					setElementData ( element, "offsetY", offsetY )
					setElementData ( element, "offsetZ", offsetZ )
				end
				
				outputChatBox ( "TCT: Action has been attached", client, 0, 255, 0, true )
			else
				outputChatBox ( "TCT: This object already has an service action", client, 255, 0, 0, true )
			end
		end
	end
end

function setEntityData ( element, key, value )
	if isElement ( element ) then
		if isPlayerElementOwner ( client, element ) ~= true then 
			outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
			return 
		end
		if getElementData ( element, "protect" ) == "1" then 
			outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
			return
		end

		if utfLen ( value ) > 0 then
			setElementData ( element, "_" .. key, value, false )
			outputChatBox ( "TCT: Data has been changed", client, 0, 255, 0, true )
		else
			removeElementData ( element, "_" .. key )
			outputChatBox ( "TCT: Data has been removed", client, 0, 255, 0, true )
		end
	end
end

function setObjectLODModel ( object, model, distance )
	if isElement ( object ) ~= true and getElementType ( object ) ~= "object" then
		return
	end
	
	if isPlayerElementOwner ( client, object ) ~= true then 
		outputChatBox ( "TCT: You can not work with this object!", client, 255, 0, 0, true )
		return 
	end
	if getElementData ( object, "protect" ) == "1" then 
		outputChatBox ( "TCT: This object is being protected from changes", client, 255, 255, 0 )
		return
	end
	
	if getElementData ( object, "lod", false ) ~= false then
		removeElementData ( object, "lod" )
		--removeElementData ( object, "loddist" )
		
		triggerClientEvent ( "onClientObjectLOD", object )
		
		outputChatBox ( "TCT: LOD successfully removed", client, 0, 200, 0 )
	else
		model = tonumber ( model )
		if model == nil or model < 595 then
			model = getElementModel ( object )
		end
		
		setElementData ( object, "lod", tostring ( model ) )
		--setElementData ( object, "loddist", tostring ( distance ) )
		
		triggerClientEvent ( "onClientObjectLOD", object )
		
		outputChatBox ( "TCT: LOD successfully created", client, 0, 200, 0 )
	end
end