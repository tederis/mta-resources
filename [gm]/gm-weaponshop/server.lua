local shops = {
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

local weapons = { }

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, shop in ipairs ( shops ) do
			local sellerX, sellerY, sellerZ = 296.506 + shop [ 3 ], -40.35 + shop [ 4 ], 1001.54 + shop [ 5 ]
			
			local seller = createPed ( 179, sellerX, sellerY, sellerZ )
			if seller then
				setElementFrozen ( seller, true )
				setElementInterior ( seller, shop [ 1 ] )
				setElementDimension ( seller, shop [ 2 ] )
			end
			
			local buyMarkerX, buyMarkerY, buyMarkerZ = 296.506 + shop [ 3 ], -38.168 + shop [ 4 ], 1000.547 + shop [ 5 ]
			local marker = createMarker ( buyMarkerX, buyMarkerY, buyMarkerZ, "cylinder", 1, 255, 0, 0 )
			if marker then
				setElementInterior ( marker, shop [ 1 ] )
				setElementDimension ( marker, shop [ 2 ] )
				setElementParent ( marker, seller )
			end
		end
		
		for _, entry in ipairs ( getElementsByType ( "interiorEntry" ) ) do
			local id = getElementID ( entry )
			
			if id:find ( "AMMUN" ) then
				local posX, posY, posZ = getElementData ( entry, "posX" ), getElementData ( entry, "posY" ), getElementData ( entry, "posZ" )
			
				createBlip ( posX, posY, posZ, 6, 2, 255, 0, 0, 255, 0, 250 )
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