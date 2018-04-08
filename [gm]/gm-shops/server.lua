local weaponShops = {
	--AMMUN1
	{ 1, 0, 0, 0, 0 },
	{ 1, 1, 0, 0, 0 },
	--AMMUN2
	{ 4, 0, -0.765, -42.311, -0.013 },
	{ 4, 1, -0.765, -42.311, -0.013 },
	{ 4, 2, -0.765, -42.311, -0.013 },
	{ 4, 3, -0.765, -42.311, -0.013 },
	--AMMUN3
	{ 6, 3, -6.264, -71.34, -0.002 },
	{ 6, 4, -6.264, -71.34, -0.002 },
	{ 6, 5, -6.264, -71.34, -0.002 },
	{ 6, 6, -6.264, -71.34, -0.002 },
	--AMMUN4
	--{ 7, 0, 11.642, -102.936, -1.929 },
	--AMMUN5
	{ 6, 0, 16.285, -127.781, -1.929 }
}

local mealShops = {
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


local weapons = { }

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, shop in ipairs ( weaponShops ) do
			local sellerX, sellerY, sellerZ = 296.506 + shop [ 3 ], -40.35 + shop [ 4 ], 1001.54 + shop [ 5 ]
			
			local seller = createPed ( 179, sellerX, sellerY, sellerZ )
			if seller then
				setElementFrozen ( seller, true )
				setElementInterior ( seller, shop [ 1 ] )
				setElementDimension ( seller, shop [ 2 ] )
			end
			
			local buyMarkerX, buyMarkerY, buyMarkerZ = 296.506 + shop [ 3 ], -38.168 + shop [ 4 ], 1000.547 + shop [ 5 ]
			--Смещение маркера: 0, 2.182, -0.99
			
			
			
			local marker = createMarker ( buyMarkerX, buyMarkerY, buyMarkerZ, "cylinder", 1, 255, 0, 0 )
			if marker then
				setElementInterior ( marker, shop [ 1 ] )
				setElementDimension ( marker, shop [ 2 ] )
				setElementData ( marker, "name", "AMMUN" )
				setElementData ( marker, "offsetX", shop [ 3 ] )
				setElementData ( marker, "offsetY", shop [ 4 ] )
				setElementData ( marker, "offsetZ", shop [ 5 ] )
				setElementParent ( marker, seller )
			end
		end
		
		for _, shop in ipairs ( mealShops ) do
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
				
				if shop [ 1 ] == 5 then
					setElementData ( marker, "name", "FDPIZA" )
				elseif shop [ 1 ] == 9 then
					setElementData ( marker, "name", "FDCHICK" )
				elseif shop [ 1 ] == 10 then
					setElementData ( marker, "name", "FDBURG" )
				end
				setElementData ( marker, "offsetX", shop [ 3 ] )
				setElementData ( marker, "offsetY", shop [ 4 ] )
				setElementData ( marker, "offsetZ", shop [ 5 ] )
				
				setElementParent ( marker, seller )
			end
		end
		
		for _, entry in ipairs ( getElementsByType ( "interiorEntry" ) ) do
			local id = getElementID ( entry )
			
			--WEAPON
			if id:find ( "AMMUN" ) then
				local posX, posY, posZ = getElementData ( entry, "posX" ), getElementData ( entry, "posY" ), getElementData ( entry, "posZ" )
			
				createBlip ( posX, posY, posZ, 6, 2, 255, 0, 0, 255, 0, 250 )
				
			--MEAL
			elseif id:find ( "FDPIZA" ) then
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
		
		--Цена на оружие
		loadFromXml ( "weapons.xml" )
	end
)

addEvent ( "onWeaponBuy", true )
addEventHandler ( "onWeaponBuy", resourceRoot,
	function ( weaponID )
		weaponID = tonumber ( weaponID )
		if not weaponID then
			outputDebugString ( "ID оружия должен быть числом" )
		
			return
		end
		
		local weaponCost = weapons [ weaponID ]
		if weaponCost then
			if getPlayerMoney ( client ) < weaponCost then
				outputChatBox ( "Для покупки этого оружия у вас недостаточно средств", client )
				
				return
			end
			
			if weaponID == -1 then
				if getPedArmor ( client ) > 90 then
					outputChatBox ( "На вас уже надет бронежилет", client )
				
					return
				end
			
				setPedArmor ( client, 100 )
			else
				giveWeapon ( client, weaponID, 30, true )
			end
			
			takePlayerMoney ( client, weaponCost )
		else
			outputChatBox ( "К сожалению вы не можете приобрести этот тип оружия", client )
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

function loadFromXml ( filepath )
	local xmlfile = xmlLoadFile ( filepath )
	if xmlfile then
		for _, group in ipairs ( xmlNodeGetChildren ( xmlfile ) ) do
			for _, weapon in ipairs ( xmlNodeGetChildren ( group ) ) do
				local weaponID = xmlNodeGetAttribute ( weapon, "id" )
				local weaponCost = xmlNodeGetAttribute ( weapon, "cost" )
				
				weapons [ tonumber ( weaponID ) ] = tonumber ( weaponCost )
			end
		end
		
		xmlUnloadFile ( xmlfile )
	end
end