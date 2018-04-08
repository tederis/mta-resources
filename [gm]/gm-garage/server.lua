--[[
	Transfender - все тачки
		1042.013 -1019.927 31.127 radius 4.0 4.0 2.0 - LC на окраине
		-1935.528 247.029 33.561 radius 4.0 4.0 2.0 - SF рядом с вокзалом
		2387.075 1050.511 9.812 radius 4.0 4.0 2.0 - NW
	Лоурайдеры
		2645.112 -2045.745 12.607 radius 4.0 4.0 4.0 - LC
	Wheel Arch Angels - только спортивные авто
		-2723.845 217.804 3.585 radius 4.0 4.0 1.0 - SF
		
	Обычные авто перемещаем его в 1 интерьер:
		617.536, -1.99, 999.98 и 90 градусов - для авто
		617.536, -1.99, 999.98 - для камеры
	Лоурайдеров перемещаем в 2 интерьер:
		616.783, -74.815, 997.014 и 90 градусов - для авто
		616.783, -74.815, 997.014 - для камеры
	Спортиные авто перемещаем в 3 интерьер:
		615.286, -124.239, 996.995 и 90 градусов - для авто
		615.286, -124.239, 996.995 - для камеры
]]

local GARAGE_OFFSET = 5

local garageType = {
	[ 8 ] = "pns",
	[ 11 ] = "pns",
	[ 12 ] = "pns",
	[ 19 ] = "pns",
	[ 24 ] = "pns",
	[ 27 ] = "pns",
	[ 32 ] = "pns",
	[ 36 ] = "pns",
	[ 40 ] = "pns",
	[ 41 ] = "pns",
	[ 47 ] = "pns",

	[ 7 ] = "mod",
	[ 10 ] = "mod",
	[ 15 ] = "mod",
	[ 18 ] = "mod",
	[ 33 ] = "mod"
}

local garages = {

}

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		local garageMap = getResourceMapRootElement ( resource, "garages.map" )
		initGarages ( garageMap )
	end
)

function initGarages ( garageRoot )
	local garages = getElementsByType ( "garage", garageRoot )
	for _, garage in ipairs ( garages ) do
		local posX, posY, posZ = getElementData ( garage, "posX" ), getElementData ( garage, "posY" ), getElementData ( garage, "posZ" )
		local width, depth, height = getElementData ( garage, "width" ), getElementData ( garage, "depth" ), getElementData ( garage, "height" )
		local id = tonumber ( getElementData ( garage, "garage" ) )
		
		createGarage ( id, posX, posY, posZ, width, depth, height, garage )
	end
	
	addEventHandler ( "onColShapeHit", garageRoot, garageHit )
	addEventHandler ( "onColShapeLeave", garageRoot, garageLeave )
	
	addEventHandler ( "onMarkerHit", garageRoot, garageMarkerHit )
end

function createGarage ( id, x, y, z, width, depth, height, garage )
	local insideColShape = createColCuboid ( x, y, z, width, depth, height )
	setElementData ( insideColShape, "type", 0 )
	setElementParent ( insideColShape, garage )
	
	local garageType = garageType [ id ]
	if garageType ~= "pns" then
		local outsideColShape = createColCuboid ( x - GARAGE_OFFSET, y - GARAGE_OFFSET, z, 
			width + GARAGE_OFFSET*2, depth + GARAGE_OFFSET*2, height )
		setElementData ( outsideColShape, "type", 1 )
		setElementParent ( outsideColShape, garage )
	end
	
	local middleX, middleY = x + ( width / 2 ), y + ( depth / 2 )
		
	if garageType == "pns" then
		local marker = createMarker ( middleX, middleY, z, "cylinder", 4, 255, 0, 0 )
		setElementParent ( marker, garage )
	
		createBlip ( x, y, z, 63, 2, 255, 0, 0, 255, 0, 250 )
			
		setGarageOpen ( id, true )
	elseif garageType == "mod" then
		local marker = createMarker ( middleX, middleY, z, "cylinder", 4, 255, 0, 0 )
		setElementParent ( marker, garage )
	
		createBlip ( x, y, z, 27, 2, 255, 0, 0, 255, 0, 250 )
				
		setGarageOpen ( id, false )
	end
end

function garageHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementData ( source, "type" ) ~= 1 then
		return
	end
	
	if getElementType ( element ) ~= "player" then
		return
	end
	
	local garage = getElementParent ( source )
	local id = tonumber ( getElementData ( garage, "garage" ) )
	
	--Если это гараж для тюнинга
	if garageType [ id ] == "mod" then
		if getElementData ( garage, "ready" ) and getElementData ( garage, "ready" ) ~= element then
			outputChatBox ( "Подожите пока гараж освободиться" )
		
			return
		end
	
		setGarageOpen ( id, true )
	end
end

function garageLeave ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementData ( source, "type" ) ~= 1 then
		return
	end
	
	if getElementType ( element ) ~= "player" then
		return
	end
	
	outputChatBox ( #getElementsWithinColShape ( source, "player" ) )
	
	if #getElementsWithinColShape ( source, "player" ) > 0 then
		return
	end
	
	local garage = getElementParent ( source )
	local id = tonumber ( getElementData ( garage, "garage" ) )
	
	--Если это гараж для тюнинга
	if garageType [ id ] == "mod" then
		setGarageOpen ( id, false )
	end
end

local _setGarageOpen = setGarageOpen
function setGarageOpen ( garage, open )
	if isElement ( garage ) then
		local garageID = getElementData ( garage, "garage" )
		_setGarageOpen ( garageID, open )
		
		return
	end
	
	_setGarageOpen ( garage, open )
end

function garageMarkerHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementType ( element ) ~= "player" then
		return
	end
	
	local vehicle = getPedOccupiedVehicle ( element )
	if not vehicle then
		return
	end
	
	local garage = getElementParent ( source )
	local garageID = tonumber ( getElementData ( garage, "garage" ) )
	
	if garageType [ garageID ] == "pns" or garageType [ garageID ] == "bomb" then
		setGarageOpen ( garageID, false )
		setTimer (
			function ( )
				if garageType [ garageID ] == "pns" then
					fixVehicle ( element )
					
					local randomColor = math.random ( 0, 126 )
					setVehicleColor ( vehicle, randomColor, randomColor, randomColor, randomColor )
					
					setGarageOpen ( garageID, true )
				elseif garageType [ type ] == "bomb" then
					--TODO
				end
			end
		, 3000, 1 )
	elseif garageType [ garageID ] == "mod" then
		if getElementData ( garage, "ready" ) then
			return
		end
	
		setElementData ( garage, "ready", element )
	
		setElementInterior ( vehicle, 1 )
		for _, player in pairs ( getVehicleOccupants ( vehicle ) ) do
			setElementInterior ( player, 1 )
		end
		setElementFrozen ( vehicle, true )
		setElementPosition ( vehicle, 617.536, -1.99, 1000.98 )
		setElementRotation ( vehicle, 0, 0, 90 )
		
		triggerClientEvent ( element, "onClientVehicleCustomize", vehicle, garage )
	end
end

addEvent ( "onVehicleCustomizeCancel", true )
addEventHandler ( "onVehicleCustomizeCancel", root,
	function ( garage )
		setElementInterior ( source, 0 )
		
		for _, player in pairs ( getVehicleOccupants ( source ) ) do
			setElementInterior ( player, 0 )
		end
		
		setElementPosition ( source, -1935.78723, 245.44017, 35.46094 )
		setElementRotation ( source, 0, 0, 0 )
		
		setTimer ( 
			function ( vehicle, garage )
				setElementFrozen ( vehicle, false )
				removeElementData ( garage, "ready" )
			end
		, 1000, 1, source, garage )
	end
)