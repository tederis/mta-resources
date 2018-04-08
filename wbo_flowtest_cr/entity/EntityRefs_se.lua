--[[
	TriggerEntity
]]
addEvent ( "onTriggerHit", false )
addEvent ( "onTriggerLeave", false )

TriggerEntity = { 
	bindColshape = { },
	bindTrigger = { }
}

function TriggerEntity.loadMap ( mapRoot )
	local triggers = getElementsByType ( "wbo:trigger", mapRoot )
	for _, trigger in ipairs ( triggers ) do
		TriggerEntity.setup ( trigger )
	end
end

function TriggerEntity.setup ( trigger )
	if TriggerEntity.bindColshape [ trigger ] then return end;

	local x, y, z = getElementPosition ( trigger )
	local dimension = getElementDimension ( trigger )
	local size = tonumber ( getElementData ( trigger, "size" ) )
	local halfSize = size/2
		
	x, y = x - halfSize, y - halfSize
		
	local colshape = createColCuboid ( x, y, z, size, size, size )
	setElementDimension ( colshape, dimension )
	TriggerEntity.bindColshape [ trigger ] = colshape
	TriggerEntity.bindTrigger [ colshape ] = trigger
	
	addEventHandler ( "onColShapeHit", colshape, TriggerEntity.onHit, false, "low" )
	addEventHandler ( "onColShapeLeave", colshape, TriggerEntity.onLeave, false, "low" )
	addEventHandler ( "onElementDestroy", trigger, TriggerEntity.onDestroy, false, "low" )
end

function TriggerEntity.onHit ( player, matchingDimension )
	if getElementType ( player ) ~= "player" or matchingDimension ~= true then return end;
	
	if isPedInVehicle ( player ) and getPedOccupiedVehicleSeat ( player ) > 0 then
		return
	end
	
	local trigger = TriggerEntity.bindTrigger [ source ]
	if trigger then
		local players = getElementsWithinColShape ( source, "player" )

		EventManager.triggerEvent ( trigger, "Trigger", 3, #players )
		EventManager.triggerEvent ( trigger, "Trigger", 1, player )
		
		triggerEvent ( "onTriggerHit", trigger, player )
	end
end

function TriggerEntity.onLeave ( player, matchingDimension )
	if getElementType ( player ) ~= "player" or matchingDimension ~= true then return end;
	
	if isPedInVehicle ( player ) and getPedOccupiedVehicleSeat ( player ) > 0 then
		return
	end
	
	local trigger = TriggerEntity.bindTrigger [ source ]
	if trigger then
		local players = getElementsWithinColShape ( source, "player" )
	
		EventManager.triggerEvent ( trigger, "Trigger", 3, #players )
		EventManager.triggerEvent ( trigger, "Trigger", 2, player )
		
		triggerEvent ( "onTriggerLeave", trigger, player )
	end
end

function TriggerEntity.onDestroy ( )
	local colshape = TriggerEntity.bindColshape [ source ]
	if colshape then
		destroyElement ( colshape )
		TriggerEntity.bindColshape [ source ] = nil
	end
end

--[[
	BlipEntity
]]
BlipEntity = { 
	bindEntity = { }
}

function BlipEntity.loadMap ( mapRoot )
	local blips = getElementsByType ( "tct-blip", mapRoot )
	for _, blip in ipairs ( blips ) do
		BlipEntity.setup ( blip )
	end
end

function BlipEntity.setup ( blip )
	if BlipEntity.bindEntity [ blip ] ~= nil then return end;

	local x, y, z = getElementPosition ( blip )
	local icon = tonumber ( getElementData ( blip, "icon", false ) )
	local dimension = tonumber ( getElementData ( blip, "dimension", false ) ) or 0
		
	local element = createBlip ( x, y, z, icon or 0, 2, 255, 0, 0, 255, 0, 99999, root )
	setElementDimension ( element, dimension )
	BlipEntity.bindEntity [ blip ] = element

	addEventHandler ( "onElementDestroy", blip, BlipEntity.onDestroy, false, "low" )
end

function BlipEntity.getBindedElement ( blip )
	return BlipEntity.bindEntity [ blip ]
end

function BlipEntity.onDestroy ( )
	local element = BlipEntity.bindEntity [ source ]
	if element then
		destroyElement ( element )
	end
	BlipEntity.bindEntity [ source ] = nil
end

--[[
	Weapon management
]]
local weaponTypes = {
	[ "colt 45" ] = true,
	silenced = true,
	deagle = true,
	uzi = true,
	mp5 = true,
	[ "ak-47" ] = true,
	m4 = true,
	[ "tec-9" ] = true,
	rifle = true,
	sniper = true,
	[ "rocket launcher" ] = true,
	[ "rocket launcher hs" ] = true,
	flamethrower = true,
	minigun = true,
	satchel = true,
	bomb = true,
	spraycan = true,
	[ "fire extinguisher" ] = true,
	camera = true
}

local weapons = { }
local setupWeapon = function ( weapon )
	weapons [ weapon ] = {
		state = "ready"
	}
end

function createWeapon ( weaponType, x, y, z, rx, ry, rz )
	local account = getPlayerAccount ( client )
	if isGuestAccount ( account ) then
		outputChatBox ( "TCT: You must be logged in.", client, 255, 0, 0, true )
		return
	end

	x, rz = tonumber ( x ), tonumber ( rz )
	if weaponTypes [ weaponType ] == nil or x == nil or rz == nil then return end;
	
	--[[if isPointInPlayerArea ( x, y, z, client ) ~= true then
		outputChatBox ( "WBO: Вы не можете строить вне своего участка", client, 255, 0, 0 )
		return
	end]]
	
	local room = RoomManager.getPlayerRoom ( client )
	if isElement ( room ) ~= true then
		outputDebugString ( "The room was not found!", 2 )
		return
	end
	if isAllowedBuildInRoom ( client, room ) ~= true then
		outputChatBox ( "TCT: You can not build in that room!", client, 200, 0, 0, true )
		return
	end
	
	local weapon = createElement ( "s_weapon" )
	setElementData ( weapon, "type", weaponType )
	setElementData ( weapon, "posX", x )
	setElementData ( weapon, "posY", y )
	setElementData ( weapon, "posZ", z )
	setElementData ( weapon, "rotX", tostring ( rx ) )
	setElementData ( weapon, "rotY", tostring ( ry ) )
	setElementData ( weapon, "rotZ", tostring ( rz ) )
	setElementData ( weapon, "tag", "Weapon:Weapon" )
	setElementData ( weapon, "dimension", tostring ( getElementDimension ( client ) ) )
	setElementData ( weapon, "owner", getAccountName ( account ) )
	
	setElementPosition ( weapon, x, y, z )
	
	setupWeapon ( weapon )
	setElementParent ( weapon, room )
	triggerClientEvent ( "_e" .. g_EventBase.WEAPON, weapon, 0 )
end

function setWeaponState ( weapon, state )
	local weaponData = weapons [ weapon ]
	if weaponData then
		if state ~= weaponData.state then
			weaponData.state = state
			
			triggerClientEvent ( "_e" .. g_EventBase.WEAPON, weapon, 1, state )
		end
	end
end

function getWeaponState ( weapon )
	local weaponData = weapons [ weapon ]
	if weaponData then
		return weaponData.state
	end
end

function setWeaponTarget ( weapon, element )
	local weaponData = weapons [ weapon ]
	if weaponData then
		if element ~= weaponData.target then
			weaponData.target = element
			
			triggerClientEvent ( "_e" .. g_EventBase.WEAPON, weapon, 2, element )
		end
	end
end

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		local weapons = getElementsByType ( "s_weapon", resourceRoot )
		for i = 1, #weapons do
			setupWeapon ( weapons [ i ] )
		end
	end
, false, "low" )

--[[
	MarkerEntity
]]
MarkerEntity = { 
	bindEntity = { },
	bindMarker = { }
}

function MarkerEntity.loadMap ( mapRoot )
	local markers = getElementsByType ( "tct-marker", mapRoot )
	for _, marker in ipairs ( markers ) do
		MarkerEntity.setup ( marker )
	end
end

function MarkerEntity.setup ( marker )
	if MarkerEntity.bindEntity [ marker ] ~= nil then return end;

	local x, y, z = getElementPosition ( marker )
	local markerType = getElementData ( marker, "type" )
	local size = tonumber ( getElementData ( marker, "size" ) ) or 1
		
	local element = createMarker ( x, y, z, markerType, size, 255, 0, 0, 200 )
	MarkerEntity.bindEntity [ marker ] = element
	MarkerEntity.bindMarker [ element ] = marker

	addEventHandler ( "onMarkerHit", element, MarkerEntity.onHit, false, "low" )
	addEventHandler ( "onMarkerLeave", element, MarkerEntity.onLeave, false, "low" )
	addEventHandler ( "onElementDestroy", marker, MarkerEntity.onDestroy, false, "low" )
end

function MarkerEntity.getBindedElement ( marker )
	return MarkerEntity.bindEntity [ marker ]
end

function MarkerEntity.onHit ( player, matchingDimension )
	if getElementType ( player ) ~= "player" then return end;
	
	if isElementVisibleTo ( source, player ) ~= true then
		return
	end
	
	if isPedInVehicle ( player ) and getPedOccupiedVehicleSeat ( player ) > 0 then
		return
	end
	
	local marker = MarkerEntity.bindMarker [ source ]
	if marker then
		--local players = getElementsWithinColShape ( marker, "player" )

		EventManager.triggerEvent ( marker, "Marker", 1, player )
		--EventManager.triggerEvent ( trigger, "Trigger", 4, #players )
		--EventManager.triggerEvent ( trigger, "Trigger", 1, player )
	end
end

function MarkerEntity.onLeave ( player, matchingDimension )
	if getElementType ( player ) ~= "player" then return end;
	
	if isElementVisibleTo ( source, player ) ~= true then
		return
	end
	
	if isPedInVehicle ( player ) and getPedOccupiedVehicleSeat ( player ) > 0 then
		return
	end
	
	local marker = MarkerEntity.bindMarker [ source ]
	if marker then
		--local players = getElementsWithinColShape ( marker, "player" )
	
		EventManager.triggerEvent ( marker, "Marker", 2, player )
		--EventManager.triggerEvent ( trigger, "Trigger", 4, #players )
		--EventManager.triggerEvent ( trigger, "Trigger", 2, player )
	end
end

function MarkerEntity.onDestroy ( )
	local element = MarkerEntity.bindEntity [ source ]
	if element then
		destroyElement ( element )
		MarkerEntity.bindMarker [ element ] = nil
	end
	MarkerEntity.bindEntity [ source ] = nil
end

--[[
	Area
]]
addEvent ( "onAreaHit", false )
addEvent ( "onAreaLeave", false )

local areaRef = { }
local areaCol = { } -- Хранит зону для колшейпа [colshape] = area
local areaPlayer = { } -- Хранит зону для игрока [player] = area

function createArea ( x, y, z, width, depth, r, g, b )
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

	local area = createElement ( "wbo:area" )
	setElementData ( area, "posX", x )
	setElementData ( area, "posY", y )
	setElementData ( area, "posZ", z )
	setElementData ( area, "width", width )
	setElementData ( area, "depth", depth )
	setElementData ( area, "tag", "Area" )
	setElementData ( area, "owner", getAccountName ( account ) )
	setElementData ( area, "dimension", tostring ( getElementDimension ( client ) ) )
	
	setElementPosition ( area, x, y, z )
	setElementParent ( area, room )
	
	setupArea ( area )
	triggerClientEvent ( "onClientElementCreate", area )
	
	return area
end

function loadAreaMap ( mapRoot )
	local areas = getElementsByType ( "wbo:area", mapRoot )
	for _, area in ipairs ( areas ) do
		setupArea ( area )
	end
end

local onAreaHit = function ( element, matchingDimension )
	if matchingDimension ~= true then
		return
	end
	
	local area = areaCol [ source ]
	if area then
		local players = getElementsWithinColShape ( source, "player" )
	
		EventManager.triggerEvent ( area, "Area", 4, players )
		EventManager.triggerEvent ( area, "Area", 1, element )
		
		areaPlayer [ element ] = area
		
		triggerEvent ( "onAreaHit", area, element )
	end
end
local onAreaLeave = function ( element, matchingDimension )
	if matchingDimension ~= true then
		return
	end
	
	local area = areaCol [ source ]
	if area then
		local players = getElementsWithinColShape ( source, "player" )
	
		EventManager.triggerEvent ( area, "Area", 4, players )
		EventManager.triggerEvent ( area, "Area", 2, element )
		
		if areaPlayer [ element ] == area then
			areaPlayer [ element ] = nil
		end
		
		triggerEvent ( "onAreaLeave", area, element )
	end
end
local onAreaDestroy = function ( )
	local areaData = areaRef [ source ]
	if areaData then
		destroyElement ( areaData [ 1 ] ) -- Удаляем зону на радаре
		areaCol [ areaData [ 2 ] ] = nil
		destroyElement ( areaData [ 2 ] ) -- Удаляем колшейп
	end
	areaRef [ source ] = nil
end
function setupArea ( area )
	local x, y = getElementPosition ( area )
	local width, depth = getElementData ( area, "width", false ), getElementData ( area, "depth", false )
	width, depth = tonumber ( width ) or 1, tonumber ( depth ) or 1
	local dimension = tonumber ( getElementData ( area, "dimension", false ) ) or 0
	local radararea = createRadarArea ( x - width / 2, y - ( depth / 2 ), width, depth, 255, 0, 0, 175 )
	setElementDimension ( radararea, dimension )
	local colshape = createColRectangle ( x - width / 2, y - ( depth / 2 ), width, depth )
	setElementDimension ( colshape, dimension )
	-- Сохраняем отношение колшейпа к зоне
	areaCol [ colshape ] = area
	-- Сохраняем зону на радаре и колшейп в таблице для работы с ними в будущем
	areaRef [ area ] = { radararea, colshape }
	
	addEventHandler ( "onColShapeHit", colshape, onAreaHit, false )
	addEventHandler ( "onColShapeLeave", colshape, onAreaLeave, false )
	addEventHandler ( "onElementDestroy", area, onAreaDestroy, false, "low" )
end

function setAreaFlashing ( area, flash )
	local areaData = areaRef [ area ]
	if areaData then
		setRadarAreaFlashing ( areaData [ 1 ], flash )
	end
end

function setAreaColor ( area, r, g, b, a )
	local areaData = areaRef [ area ]
	if areaData then
		setRadarAreaColor ( areaData [ 1 ], r, g, b, a )
	end
end

function getPlayerArea ( player )
	return areaPlayer [ player ]
end

function isPlayerWithinArea ( player, area )
	return areaPlayer [ player ] == area
end

function getPlayersWithinArea ( area )
	local areaData = areaRef [ area ]
	if areaData then
		return getElementsWithinColShape ( areaData [ 2 ], "player" )
	end
end