--[[
	Типы грузов:
		This is a fragile load. Deliver the goods intact or lose cash for damages. | Goods must be delivered without damage to - 500 - $91 += 500
		Deliver the goods as quickly as possible. If you are late you'll lose cash. | Goods must be delivered quickly to - 750
		These goods are extremely fragile. | Extremely fragile goods to - 250 - $91 += 1000
		These goods are hot and will attract police interest. | Illegal goods to | 3 звезды - 750 - $91 += 1000
		You must deliver these fragile goods quickly and safely. | Goods must be delivered quickly without damage to - 500 - $91 += 3000
		These goods are very hot and will attract a lot of police interest. | Highly illegal goods to | 4 звезды $91 += 6000
	Плата за типы грузов:
		1, 5 - 500
		3 - 250
		остальное - 700
]]

local truckPoints = {
	{ -187.4041, -277.0196, 0.4219 },
	{ 58.0364, -256.7285, 0.5781 },
	{ 95.8675, -154.3627, 1.5751 },
	{ 809.7556, -598.0007, 15.1875 },
	
	{ 1403.833, 399.4294, 18.75 },
	{ 1338.289, 348.9004, 18.4062 },
	
	{ 1449.715, 2358.852, 9.8203 },
	{ 1037.475, 2131.344, 9.8203 },
	{ 987.9741, 2080.389, 9.8203 },
	{ 1288.671, 1195.232, 9.8656 },
	{ 2467.902, 1950.061, 9.2381 },
	{ 2792.744, 2578.336, 9.8203 },
	{ 2271.477, 2791.739, 9.8203 },
	{ 2596.519, 1738.582, 9.8281 },
	{ 2818.84, 912.5091, 9.75 },
	{ 2706.505, 827.3236, 9.2145 },
	{ 1627.723, 688.4043, 9.8281 },
	{ 1504.492, 981.141, 9.7187 },
	{ 1724.012, 1590.128, 9.2578 },
	{ 1727.833, 2338.017, 9.813 },
	
	{ 2413.683, -2113.674, 12.3881 },
	{ 2784.973, -2455.441, 12.625 },
	{ 2112.662, -2070.376, 12.5547 },
	{ 1763.641, -2070.371, 12.6195 },
	
	{ -1888.621, -1711.836, 20.7656 },
	{ -2117.227, -2380.507, 29.4688 },
	{ -1545.439, -2747.032, 47.5314 },
	
	{ -1407.375, 2645.957, 54.7031 },
	{ -2245.581, 2371.693, 3.9919 },
	{ -1360.633, 2068.094, 51.4589 },
	
	{ 274.2705, 1382.781, 9.6016 },
	{ 628.8638, 1714.891, 5.9922 },
	{ 635.0028, 1213.777, 10.7188 },
	{ -914.953, 2012.138, 59.9283 },
	{ 385.8214, 2595.55, 15.4843 },
	
	{ -1556.977, -441.3493, 5.0 },
	{ -2659.631, 1380.642, 6.1643 },
	{ -1650.928, 437.5679, 6.1797 },
	{ -1745.116, 37.8752, 2.5408 },
	
	{ 56.744, -268.404, 0.579 },
	{ 100.397, -155.05, 1.583 },
	{ 815.046, -605.128, 15.336 },
	{ 1401.109, 398.763, 18.756 },
	{ 1343.125, 345.667, 18.556 },
	{ -189.23, -273.013, 0.429 },
	
	{ 1042.15, 2130.46, 101.0 },
	{ 983.11, 2076.38, 101.0 },
	{ 1288.671, 1195.232, 9.8656 },
	{ 2469.57, 1949.52, 101.0 },
	{ 2807.83, 2609.94, 101.0 },
	{ 2248.71, 2775.12, 101.0 },
	{ 2603.22, 1730.48, 101.0 },
	{ 2818.84, 912.19, 101.0 },
	{ 2710.36, 850.12, 101.0 },
	{ 1588.9, 715.31, 101.0 },
	{ 1446.26, 1000.51, 101.0 },
	{ 1724.012, 1590.128, 9.2578 },
	{ 1713.79, 2329.05, 101.0 },
	{ 1450.8, 2360.69, 101.0 },
	
	--TODO TRUCK_14178
}

TRUCK_9431

local cargoTypes = {
	{ 500, 500 },
	{ 750, 1000 },
	{ 250, 1000 },
	{ 750, 1000 },
	{ 500, 3000 },
	{ 750, 6000 }
}

local truckJobMission
local truckJobMarker, truckJobBlip, truckJobColShape
local truckMarkersRoot

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		truckJobMission = exports.missionmanager:createMission ( "truck" )
	
		truckJobMarker = createMarker ( -77.6456, -1136.401, 0.0781, "cylinder", 1.5, 255, 0, 0 )
		addEventHandler ( "onMarkerHit", truckJobMarker, missionMarkerHit )
		
		truckJobBlip = createBlip ( -77.6456, -1136.401, 0.0781, 51, 2, 255, 0, 0, 255, 0, 99999 )
		
		truckJobColShape = createColSphere ( -76.1692, -1128.963, 0.0781, 6 )
		
		--[[truckMarkersRoot = getResourceMapRootElement ( resource, "markers.map" )
		local markers = getElementsByType ( "marker", truckMarkersRoot )
		for _, marker in ipairs ( markers ) do
			local x, y, z = getElementPosition ( marker )
			local blip = createBlip ( x, y, z, 0, 2, 0, 0, 255, 255 )
			setElementParent ( blip, marker )
		end
		setElementVisibleTo ( truckMarkersRoot, root, false )
		addEventHandler ( "onMarkerHit", truckMarkersRoot, truckMarkerHit )]]
	end
)

--Вызывается при входе на маркер миссии для ее начала
function missionMarkerHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementType ( element ) ~= "player" then
		return
	end
	
	if isTruckAreaReady ( ) ~= true then
		outputChatBox ( "Дождитесь пока площадка перед выходом освободиться" )
	
		return
	end
	
	exports.missionmanager:setPlayerMission ( element, truckJobMission )
	
	missionStart ( element )
end

--Вызывается когда игрок в грузовике достигает склада заказчика
--[[function truckMarkerHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementType ( element ) ~= "player" then
		return
	end
	
	--Если мы не видим маркер, выходим из функции события
	if not isElementVisibleTo ( source, element ) then
		return
	end
	
	outputChatBox ( "Ура!" )
end]]

function missionStart ( player )
	--Скрываем для игрока элементы
	setElementVisibleTo ( truckJobMarker, player, true )
	setElementVisibleTo ( truckJobMarker, player, false )
	setElementVisibleTo ( truckJobBlip, player, true )
	setElementVisibleTo ( truckJobBlip, player, false )
	
	local truck = spawnRandomTruck ( )
	--local truckPoint = getRandomTruckPoint ( )
	--setElementVisibleTo ( truckPoint, player, true )
end

addEvent ( "onPlayerDeliveredCargo", true )
addEventHandler ( "onPlayerDeliveredCargo", root,
	function ( )
		if exports.missionmanager:getPlayerMission ( client ) ~= truckJobMission then
			outputDebugString ( "Игрок не выполняет доставку груза. Возможно попытка обмана сервера." )
			
			return
		end
		
		local vehicle = getPedOccupiedVehicle ( client )
		if not vehicle then
			outputDebugString ( "Игрок должен находиться в грузовике. Возможно попытка обмана сервера." )
			
			return
		end
		
		--TODO
	end
)

function isTruckAreaReady ( )
	local vehicles = getElementsWithinColShape ( truckJobColShape, "vehicle" )
	for _, vehicle in ipairs ( vehicles ) do
		return false
	end
	
	return true
end

local trucks = {
	514, 403, 515
}

local trailers = {
	584, 435, 450, 591
}

function spawnRandomTruck ( )
	local truck = createVehicle ( trucks [ math.random ( 1, #trucks ) ], -76.1692, -1128.963, 2.0781, 0, 0, 69.9957 )
	local trailer = createVehicle ( trailers [ math.random ( 1, #trailers ) ], -60.6033, -1136.899, 2.0781, 0, 0, 69.9957 )
	attachTrailerToVehicle ( truck, trailer )
	
	return truck
end

function getRandomTruckPoint ( )
	local pointCount = getElementChildrenCount ( truckMarkersRoot )

	return getElementChild ( truckMarkersRoot, math.random ( 0, pointCount-1 )  )
end

local cargoType = 1

local truckHealth = 1000
local value = 750

truckHealth = truckHealth - 250
--
truckHealth = truckHealth * 100
truckHealth = truckHealth / cargoTypes [ cargoType ] [ 1 ]
local money = cargoTypes [ cargoType ] [ 2 ] * truckHealth
money = money / 100

outputChatBox(money)

--[[
50@ -= 250 
0085: 51@ = 50@ // (int) 
51@ *= 100 
0072: 51@ /= 90@ // (int) 
006A: 83@ *= 51@ // (int) 
83@ /= 100

TRUCK_7597
]]

--Если здоровье грузовика меньше 250, игрок нифига не получит