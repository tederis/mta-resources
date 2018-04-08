local shops = {
	--FDPIZA
	{ 5, 0, 0, 0, 0 },
	{ 5, 1, 0, 0, 0 },
	{ 5, 2, 0, 0, 0 },
	{ 5, 3, 0, 0, 0 },
	{ 5, 4, 0, 0, 0 },
	{ 5, 5, 0, 0, 0 },
	{ 5, 6, 0, 0, 0 },
	{ 5, 7, 0, 0, 0 },
	{ 5, 8, 0, 0, 0 },
	{ 5, 9, 0, 0, 0 },
	{ 5, 10, 0, 0, 0 },
	{ 5, 11, 0, 0, 0 },
	--FDCHICK
	{ 9, 0, -5.211, 112.784, 0.3 },
	{ 9, 1, -5.211, 112.784, 0.3 },
	{ 9, 2, -5.211, 112.784, 0.3 },
	{ 9, 3, -5.211, 112.784, 0.3 },
	{ 9, 4, -5.211, 112.784, 0.3 },
	{ 9, 5, -5.211, 112.784, 0.3 },
	{ 9, 6, -5.211, 112.784, 0.3 },
	{ 9, 7, -5.211, 112.784, 0.3 },
	{ 9, 8, -5.211, 112.784, 0.3 },
	{ 9, 9, -5.211, 112.784, 0.3 },
	{ 9, 10, -5.211, 112.784, 0.3 },
	{ 9, 11, -5.211, 112.784, 0.3 },
	--FDBURG
	{ 10, 0, 1.566, 51.419, 0.01 },
	{ 10, 1, 1.566, 51.419, 0.01 },
	{ 10, 2, 1.566, 51.419, 0.01 },
	{ 10, 3, 1.566, 51.419, 0.01 },
	{ 10, 4, 1.566, 51.419, 0.01 },
	{ 10, 5, 1.566, 51.419, 0.01 },
	{ 10, 6, 1.566, 51.419, 0.01 },
	{ 10, 7, 1.566, 51.419, 0.01 },
	{ 10, 8, 1.566, 51.419, 0.01 },
	{ 10, 9, 1.566, 51.419, 0.01 }
}

local foods = {
	[ 5 ] = {
		2,
		5,
		10,
		10
	},
	[ 9 ] = {
		2,
		5,
		10,
		10
	},
	[ 10 ] = {
		2,
		5,
		10,
		5
	}
}

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, shop in ipairs ( shops ) do
			local sellerX, sellerY, sellerZ = 374.0 + shop [ 3 ], -117.141 + shop [ 4 ], 1001.539 + shop [ 5 ]
			
			local seller = createPed ( 179, sellerX, sellerY, sellerZ, 180 )
			if seller then
				setElementFrozen ( seller, true )
				setElementInterior ( seller, shop [ 1 ] )
				setElementDimension ( seller, shop [ 2 ] )
			end
			
			local buyMarkerX, buyMarkerY, buyMarkerZ = 296.506 + shop [ 3 ], -38.168 + shop [ 4 ], 1000.547 + shop [ 5 ]
			local marker = createMarker ( sellerX, sellerY - 2.5, sellerZ - 1, "cylinder", 1, 255, 0, 0 )
			if marker then
				setElementInterior ( marker, shop [ 1 ] )
				setElementDimension ( marker, shop [ 2 ] )
				setElementParent ( marker, seller )
			end
		end
		
		for _, entry in ipairs ( getElementsByType ( "interiorEntry" ) ) do
			local id = getElementID ( entry )
			
			if id:find ( "FDPIZA" ) then
				local posX, posY, posZ = getElementData ( entry, "posX" ), getElementData ( entry, "posY" ), getElementData ( entry, "posZ" )
			
				createBlip ( posX, posY, posZ, 29, 2, 255, 0, 0, 255, 0, 250 )
			elseif id:find ( "FDCHICK" ) then
				local posX, posY, posZ = getElementData ( entry, "posX" ), getElementData ( entry, "posY" ), getElementData ( entry, "posZ" )
			
				createBlip ( posX, posY, posZ, 14, 2, 255, 0, 0, 255, 0, 250 )
			elseif id:find ( "FDBURG" ) then
				local posX, posY, posZ = getElementData ( entry, "posX" ), getElementData ( entry, "posY" ), getElementData ( entry, "posZ" )
			
				createBlip ( posX, posY, posZ, 10, 2, 255, 0, 0, 255, 0, 250 )
			end
		end
	end
)

addEvent ( "onMealBuy", true )
addEventHandler ( "onMealBuy", resourceRoot,
	function ( mealIndex )
		mealIndex = tonumber ( mealIndex )
		if not mealIndex then
			outputDebugString ( "Индекс продукта должен быть числом" )
		
			return
		end
		
		local interior = getElementInterior ( client )
		local mealCost = foods [ interior ] [ mealIndex ]
		if mealCost then
			if getPlayerMoney ( client ) < mealCost then
				outputChatBox ( "У вас недостаточно средств", client )
				
				return
			end
			
			setElementHealth ( client, getElementHealth ( client ) * 1.8 )
			
			takePlayerMoney ( client, mealCost )
		else
			outputChatBox ( "К сожалению вы не можете приобрести эту еду", client )
		end
	end
)