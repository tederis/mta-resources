--[[
	Радиация:
		Имеет три разновидности - average, strong и weak. Выполняется в виде сферы произвольного размера. Уровень облучения считается от центра сферы с момента входа в нее.
]]

local triggeredAnomalies = { }

anomaliesList = {
	[ "field_radioactive_weak" ] = {
		create = function ( x, y, z )
			--createColSphere ( x, y, z, 5 )
		end
	},
	[ "electra" ] = {
		onHit = function ( anomaly, target )
			
		end,
		onLeave = function ( anomaly, target )
			
		end,
		onEntrance = function ( anomaly, colshape, target )
			for _, element in ipairs ( getElementsWithinColShape ( colshape ) ) do
				local health = getElementHealth ( element )
				
				setElementHealth ( element, health > 25 and health - 25 or 0 )
				outputChatBox ( health > 25 and health - 25 or 0 )
				
				setPedAnimation ( element, "CHAINSAW", "CSAW_Hit_1" )
				setTimer ( setPedAnimation, 800, 1, element, false )
			end
		end
	},
}

Anomaly = { }
Anomaly.__index = Anomaly

function Anomaly.create ( name, x, y, z, size )
	local anomaly = createElement ( "anomaly" )
	setElementData ( anomaly, "posX", x )
	setElementData ( anomaly, "posY", y )
	setElementData ( anomaly, "posZ", z )
	setElementData ( anomaly, "name", name )
	setElementPosition ( anomaly, x, y, z )

	--local colshape = createColSphere ( x, y, z, size )
	--addEventHandler( "onClientColShapeHit", colshape, anomalyEntry )
	--addEventHandler ( "onClientColShapeLeave", colshape, anomalyExit )
	--setElementParent ( colshape, anomaly )
	
	--anomaliesList [ name ].create ( x, y, z )
	
	return anomaly
end

function Anomaly.entranceEvent ( anomaly, colshape, target )
	local name = getElementData ( anomaly, "name" )
	if anomaliesList [ name ].onEntrance then
		anomaliesList [ name ].onEntrance ( anomaly, colshape, target )
	end

	triggerClientEvent ( "onClientAnomalyEntrance", anomaly, target )
end

addEventHandler ( "onColShapeHit", resourceRoot,
	function ( element )
		local anomaly = getElementParent ( source )
		local name = getElementData ( anomaly, "name" )
			
		if anomaliesList [ name ].onHit then
			anomaliesList [ name ].onHit ( anomaly, element )
		end
		
		--Событие для нанесения урона игроку, пока он находится в аномалии
		if not triggeredAnomalies [ anomaly ] then
			triggeredAnomalies [ anomaly ] = setTimer ( Anomaly.entranceEvent, 2500, 0, anomaly, source, element )
			
			if anomaliesList [ name ].onEntrance then
				anomaliesList [ name ].onEntrance ( anomaly, source, element )
			end
			triggerClientEvent ( "onClientAnomalyEntrance", anomaly, element )
		end
	end
)

addEventHandler ( "onColShapeLeave", resourceRoot,
	function ( element )
		local anomaly = getElementParent ( source )
		local name = getElementData ( anomaly, "name" )
			
		if anomaliesList [ name ].onLeave then
			anomaliesList [ name ].onLeave ( anomaly, element )
		end
		
		--Событие для нанесения урона игроку, пока он находится в аномалии
		if triggeredAnomalies [ anomaly ] then
			killTimer ( triggeredAnomalies [ anomaly ] ) 
			triggeredAnomalies [ anomaly ] = nil
		end
	end
)

Anomaly.create ( "electra", 6133.36572, -22.78357, 49.65337, 4 )