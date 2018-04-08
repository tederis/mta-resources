local BAG_COST = 100
local bagMap
local bagMission

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		bagMission = exports.missionmanager:createMission ( "scavenger" )
		addEventHandler ( "onMissionStart", bagMission, missionStart )
		addEventHandler ( "onMissionStop", bagMission, missionStop )
	
		bagMap = getResourceMapRootElement ( resource, "main.map" )
		setTimer ( updatePulse, 1000, 0 )
		
		local bags = getElementsByType ( "bag", bagMap )
		for _, bag in ipairs ( bags ) do
			spawnBagEntity ( bag )
		end
		
		--Делаем все маркеры невидимыми
		local markers = getElementsByType ( "marker", bagMap )
		for _, marker in ipairs ( markers ) do
			setElementVisibleTo ( marker, root, false )
		end
		
		local players = getElementsByType ( "player" )
		for _, player in ipairs ( players ) do
			removeElementData ( player, "mission" )
			removeElementData ( player, "cargo" )
		
			bindKey ( player, "2", "down", toggleMission )
		end
		
		addEventHandler ( "onMarkerHit", bagMap, markerHit ) 
	end
)

local lastHour
function updatePulse ( )
	local hour = getTime ( )
	if hour == lastHour then
		return
	end
	lastHour = hour
	
	if hour ~= 8 then
		return
	end
	
	local bags = getElementsByType ( "bag", bagMap )
	for _, bag in ipairs ( bags ) do
		if getElementChildrenCount ( bag ) < 1 then
			spawnBagEntity ( bag )
		end
	end
end

function spawnBagEntity ( bag )
	local x, y, z = getElementPosition ( bag )
			
	local object = createObject ( 1264, x, y, z )
	setElementCollisionsEnabled ( object, false )
	setElementParent ( object, bag )
	
	return object
end

function toggleMission ( player )
	local vehicle = getPedOccupiedVehicle ( player )
	if not vehicle or getElementModel ( vehicle ) ~= 408 then
		return
	end
	
	local mission = exports.missionmanager:getPlayerMission ( player )
	if mission then
		if mission ~= bagMission then
			return
		end
		
		exports.missionmanager:setPlayerMission ( player, false )
	else
		exports.missionmanager:setPlayerMission ( player, bagMission )
	end
end

function missionStart ( player )
	--Количество собранных пакетов с мусором
	setElementData ( player, "bagCnt", 0 )
	
	--Делаем все маркеры видимыми
	local markers = getElementsByType ( "marker", bagMap )
	for _, marker in ipairs ( markers ) do
		setElementVisibleTo ( marker, player, true )
	end
end

function missionStop ( player )
	--Количество собранных пакетов с мусором
	setElementData ( player, "bagCnt", 0 )

	--Делаем все маркеры невидимыми
	local markers = getElementsByType ( "marker", bagMap )
	for _, marker in ipairs ( markers ) do
		setElementVisibleTo ( marker, player, false )
	end
end

function markerHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	if getElementType ( element ) ~= "player" or exports.missionmanager:isPlayerMission ( element ) ~= true then
		return
	end
	
	local vehicle = getPedOccupiedVehicle ( element )
	if vehicle and getElementModel ( vehicle ) == 408 then
		local bagCnt = getElementData ( element, "bagCnt" ) or 0
		if bagCnt > 0 then
			givePlayerMoney ( element, bagCnt * BAG_COST )
			
			setElementData ( element, "bagCnt", 0 )
		end
	end
end

----------------------------
--Utils
----------------------------
local missionTimers = { }

function startPlayerMissionTimer ( player, interval )
	missionTimers [ player ] = setTimer ( timeElapsed, interval, 1, player )
	
	return true
end

function stopPlayerMissionTimer ( player )
	if not missionTimers [ player ] then
		return false
	end
	
	stopTimer ( missionTimers [ player ] )
	missionTimers [ player ] = nil
	
	return true
end

function timeElapsed ( player )
	

	missionTimers [ player ] = nil
end