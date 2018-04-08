addEvent ( "onCreateTCTObject", true )
addEvent ( "onDestroyTCTElement", true )
addEvent ( "onPlaceTCTElement", true )
addEvent ( "onChangeTCTAlpha", true )
addEvent ( "onChangeTCTScale", true )
addEvent ( "onSidedTCTElement", true )
addEvent ( "onFreezeTCTElement", true )
addEvent ( "onAttachTCTElement", true )
addEvent ( "onCreateTCTArea", true )
addEvent ( "onChangeTCTMaterial", true )

addEvent ( "onCreateWBOTrack", true )
addEvent ( "onCreateWBOPortal", true )
addEvent ( "onCreateWBOMagnet", true )
addEvent ( "onCreateWBOMarker", true )
addEvent ( "onLockTCTElement", true )

addEvent ( "onAreaInvite", true )
addEvent ( "onAreaKick", true )
addEvent ( "onAreaSell", true )
addEvent ( "onAreaBuy", true )

local CONSTRUCTOR_KEY = "f5"

local function insideBox ( x, y, bx, by, bw, bh )
	return ( x > bx ) and ( x <= bx + bw ) and ( y > by ) and ( y <= by + bh )
end
function isOwnerInsideArea ( player )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		return false
	end
	
	if isPlayerAdmin ( player ) then
		return true
	end
	
	
	local accountName = getAccountName ( account )
	
	local px, py = getElementPosition ( player )
	for _, area in ipairs ( getElementsByType ( "area", resourceRoot ) ) do
		local x, y = getElementPosition ( area )
		local width = tonumber (
			getElementData ( area, "sizeX", false )
		)
		local depth = tonumber (
			getElementData ( area, "sizeY", false )
		)
		local ownerName = getElementData ( area, "owner", false )
		
		if insideBox ( px, py, x - width/2, y - depth/2, width, depth ) and ownerName == accountName then
			return true
		end
	end
	
	return false
end

addEventHandler ( "onCreateTCTObject", resourceRoot,
	function ( model, posX, posY, posZ, rotX, rotY, rotZ, ... )
		if type ( model ) == "number" and type ( posZ ) == "number" then
			local account = getPlayerAccount ( client )
			
			if isGuestAccount ( account ) ~= true then
				-- Проверяем наличие средств
				if getPlayerMoney ( client ) < 50 then
					outputChatBox ( "TCT: Для создания объекта недостаточно средств", client, 255, 0, 0, true )
					return
				end
				
				if isOwnerInsideArea ( client ) ~= true then
					outputChatBox ( "TCT: Вы не можете здесь строить. Вообще, совсем не можете.", client, 255, 0, 0, true )					
					return
				end
			
				local element = createEntity ( model, posX, posY, posZ, rotX, rotY, rotZ )
				
				if element then
					setElementData ( element, "owner", getAccountName ( account ) )
					local dimension = getElementDimension ( client )
					setElementDimension ( element, dimension )
					
					local interior = getElementInterior ( client )
					setElementInterior ( element, interior )
    
					setElementData ( element, "model", tostring ( model ), false )
					setElementData ( element, "posX", posX, false )
					setElementData ( element, "posY", posY, false )
					setElementData ( element, "posZ", posZ, false )
					setElementData ( element, "rotX", rotX, false )
					setElementData ( element, "rotY", rotY, false )
					setElementData ( element, "rotZ", rotZ, false )
					setElementData ( element, "interior", tostring ( interior ) )
					setElementData ( element, "dimension", tostring ( dimension ), false )
					
					setElementParent ( element, mapRoot )
					
					for _, data in ipairs ( arg ) do
						if type ( data ) == "table" and type ( data [ 1 ] ) == "string" then
							setElementData ( element, data [ 1 ], data [ 2 ] )
						end
					end
				end
				
				-- Забираем бабки
				takePlayerMoney ( client, 50 )
				-- Сохраняем в аккаунте
				setAccountData ( account, "tct:money", tostring ( getPlayerMoney ( client ) ) )
			else
				outputChatBox ( "TCT: Для работы с объектом необходима авторизация.", client, 255, 0, 0, true )
			end
		end
	end 
)

addEventHandler ( "onDestroyTCTElement", resourceRoot,
	function ( onlyAttached )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
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
		
		-- Возвращаем бабки при удалении своего обжекта
		givePlayerMoney ( client, 25 )
		-- Сохраняем в аккаунте
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) ~= true then
			setAccountData ( account, "tct:money", tostring ( getPlayerMoney ( client ) ) )
		end
	end 
)

addEventHandler ( "onPlaceTCTElement", resourceRoot,
	function ( posX, posY, posZ, rotX, rotY, rotZ )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
			return 
		end

		if type ( posX ) == "number" and type ( rotZ ) == "number" then
			setElementPosition ( source, posX, posY, posZ )
			setObjectRotation ( source, rotX, rotY, rotZ )
    
			setElementData ( source, "posX", posX, false )
			setElementData ( source, "posY", posY, false )
			setElementData ( source, "posZ", posZ, false )
			setElementData ( source, "rotX", rotX, false )
			setElementData ( source, "rotY", rotY, false )
			setElementData ( source, "rotZ", rotZ, false )
			
			--Destroy all element triggers
			for _, marker in ipairs ( getElementsByType ( "marker", source ) ) do
				destroyElement ( marker )
			end
		end
	end
)

addEventHandler ( "onChangeTCTAlpha", resourceRoot,
	function ( alpha )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
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
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
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
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
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
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
			return 
		end
 
		local isFrozen = not isElementFrozen ( source )
		
		setElementFrozen ( source, isFrozen )
		setElementData ( source, "frozen", isFrozen, false )
	end 
)

addEventHandler ( "onAttachTCTElement", root,
	function ( attachTo )
		if isElement ( attachTo ) ~= true then
			return
		end
		
		if isPlayerElementOwner ( client, source, attachTo ) then
			attachRotationAdjusted ( source, attachTo )
			outputChatBox ( "WBO: Вы успешно скрепили объекты.", client )
		else
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
		end
	end 
)

addEventHandler ( "onCreateTCTArea", root,
	function ( x, y, width, depth, r, g, b, price )
		if isPlayerAdmin ( client ) ~= true then
			outputChatBox ( "WBO: У вас недостаточно прав!", client, 255, 0, 0, true )			
			return 
		end
	
		local element = createElement ( "area" )
		setElementPosition ( element, x, y, 0)
		
		local interior = getElementInterior ( client )		
		local dimension = getElementDimension ( client )
	
		local area = createRadarArea ( x - width/2, y - depth/2, width, depth, r, g, b, 200 )		
		setElementDimension ( area, dimension )					
		setElementInterior ( area, interior )
		
		setElementData ( element, "posX", tostring ( x ) )
		setElementData ( element, "posY", tostring  ( y ) )
		setElementData ( element, "sizeX", tostring  ( width ) )
		setElementData ( element, "sizeY", tostring  ( depth ) )
		--setElementData ( element, "red", tostring  ( r ) )
		--setElementData ( element, "green", tostring  ( g ) )
		--setElementData ( element, "blue", tostring  ( b ))
		setElementData ( element, "price", tostring  ( price ) )
		setElementData ( element, "dimension", tostring ( dimension ) )
		setElementData ( element, "interior", tostring ( interior ) )
		
		local account = getPlayerAccount ( client )
		local accountName = getAccountName ( account )
		setElementData ( element, "owner", accountName )
		
		setElementParent ( element, mapRoot )
	end 
)

addEventHandler ( "onAreaInvite", resourceRoot,
	function ( player )
		if isPlayerElementOwner ( client, source ) ~= true then
			outputChatBox ( "WBO: У вас недостаточно прав!", client, 255, 0, 0, true )			
			return 
		end
	
		local inviteNamesStr = getElementData ( source, "invited", false )
		local inviteNames = split ( inviteNamesStr, 44 )
		local playerName = getPlayerName ( player )
		for _, name in ipairs ( inviteNames ) do
			if name == playerName then
				outputChatBox ( "Этот игрок уже есть в списке", client, 255, 0, 0, true )
				return
			end
		end
		
		if string.len ( inviteNamesStr ) > 0 then
			inviteNamesStr = inviteNamesStr .. "," .. playerName
		else
			inviteNamesStr = inviteNamesStr .. playerName
		end
		setElementData ( source, "invited", inviteNamesStr, true )
		outputChatBox ( "Игрок " .. getPlayerName ( client ) .. " пригласил вас жить к себе", player, 0, 255, 0, true )
		outputChatBox ( "Теперь игрок " .. playerName .. " будет жить с вами", client, 0, 255, 0, true )
	end
)

addEventHandler ( "onAreaKick", resourceRoot,
	function ( player )
		if isPlayerElementOwner ( client, source ) ~= true then
			outputChatBox ( "WBO: У вас недостаточно прав!", client, 255, 0, 0, true )			
			return 
		end
	
		local inviteNamesStr = getElementData ( source, "invited", false )
		local inviteNames = split ( inviteNamesStr, 44 )
		local playerName = getPlayerName ( player )
		inviteNamesStr = ""
		for i, name in ipairs ( inviteNames ) do
			if name ~= playerName then
				if string.len ( inviteNamesStr ) > 0 then
					inviteNamesStr = inviteNamesStr .. ", " .. name
				else
					inviteNamesStr = inviteNamesStr .. name
				end
			end
		end
		if string.len ( inviteNamesStr ) > 0 then
			setElementData ( source, "invited", inviteNamesStr, true )
		else
			removeElementData ( source, "invited" )
		end
		outputChatBox ( "Игрок " .. getPlayerName ( client ) .. " больше не желает с вами жить", player, 0, 255, 0, true )
		outputChatBox ( "Теперь игрок " .. playerName .. " с вами не живет", client, 0, 255, 0, true )
	end
)

addEventHandler ( "onAreaSell", resourceRoot,
	function ( price )
		if isPlayerElementOwner ( client, source ) ~= true then
			outputChatBox ( "WBO: У вас недостаточно прав!", client, 255, 0, 0, true )			
			return 
		end
		
		if type ( price ) == "number" then
			setElementData ( source, "price", tostring ( price ), true )
			outputChatBox ( "Участок выставлен на продажу за " .. price, client, 0, 255, 0, true )
		else
			removeElementData ( source, "price" )
			outputChatBox ( "Участок больше не продается", client, 0, 255, 0, true )
		end
	end
)

addEventHandler ( "onAreaBuy", resourceRoot,
	function ( )
		local account = getPlayerAccount ( client )			
		if isGuestAccount ( account ) ~= true then
			local price = tonumber ( getElementData ( source, "price", false ) )
			if price then
				-- Проверяем наличие средств
				if getPlayerMoney ( client ) < price then
					outputChatBox ( "TCT: Для покупки недостаточно средств", client, 255, 0, 0, true )
					return
				end
				
				removeElementData ( source, "price" )
				
				local oldOwner = getElementData ( source, "owner", false )
				local oldOwnerAccount = getAccount ( oldOwner )
				if oldOwnerAccount then			
					local oldOwnerPlayer = getAccountPlayer ( oldOwnerAccount )
					if oldOwnerPlayer then
						outputChatBox ( "Ваш участок только что приобрели. Не пропейте все вырученные деньги сразу.", oldOwnerPlayer, 0, 255, 0, true )
						givePlayerMoney ( oldOwnerPlayer, price )
						
						setAccountData ( oldOwnerAccount, "tct:money", tostring ( getPlayerMoney ( oldOwnerPlayer ) ) )
					else
						local oldOwnerMoney = tonumber ( getAccountData ( oldOwnerAccount, "tct:money" ) )
						setAccountData ( oldOwnerAccount, "tct:money", oldOwnerMoney ~= nil and tostring ( oldOwnerMoney + price ) or tostring ( price ) )
					end
				
					setElementData ( source, "owner", getAccountName ( account ) )
					
					-- Забираем бабки
					takePlayerMoney ( client, price )
					-- Сохраняем в аккаунте
					setAccountData ( account, "tct:money", tostring ( getPlayerMoney ( client ) ) )
					
					outputChatBox ( "Поздравляем с покупкой! Теперь этот замечательный участок ваш.", client, 0, 255, 0, true )
				end
			end
		else
			outputChatBox ( "WBO: Вы должны быть авторизованы!", client, 255, 0, 0, true )
		end
	end
)

addEventHandler ( "onChangeTCTMaterial", resourceRoot,
	function ( materialIndex, textureMaterial )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
			return
		end
 
		if type ( materialIndex ) == "number" then
			triggerClientEvent ( "onClientElementMaterialChange", source, materialIndex, textureMaterial )
			
			if materialIndex > 1 then
				setElementData ( source, "material", tostring ( materialIndex ) )
			else
				removeElementData ( source, "material" )
			end
		end
	end 
)

addEventHandler ( "onCreateWBOTrack", resourceRoot,
	function ( nodesData, blockData )
		--Если игрок владелец объектов
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом.", client, 255, 0, 0, true ) 
			return 
		end
	
		if ( type ( nodesData ) == "table" and #nodesData < 11 ) and ( type ( blockData ) == "table" and #blockData == 6 ) then
			--Блок управления
			local block = createObject ( 10245, blockData [ 1 ], blockData [ 2 ], blockData [ 3 ], blockData [ 4 ], blockData [ 5 ], blockData [ 6 ] )
			if block then
				setElementData ( block, "owner", getAccountName ( getPlayerAccount ( client ) ) )
				setElementDimension ( block, getElementDimension ( client ) )
				setElementData ( block, "tag", "track" )
				--setElementData ( block, "intrtbl", blockData [ 6 ], false )
				
				--Для сохранения
				setElementData ( block, "model", "10245", false )
				setElementData ( block, "posX", blockData [ 1 ], false )
				setElementData ( block, "posY", blockData [ 2 ], false )
				setElementData ( block, "posZ", blockData [ 3 ], false )
				setElementData ( block, "rotX", blockData [ 4 ], false )
				setElementData ( block, "rotY", blockData [ 5 ], false )
				setElementData ( block, "rotZ", blockData [ 6 ], false )
				setElementData ( block, "dimension", tostring ( getElementDimension ( client ) ), false )
				
				local posX, posY, posZ = getElementPosition ( source )
				local nodeElement = createElement ( "node" )
				setElementData ( nodeElement, "spd", 1000 )
				setElementData ( nodeElement, "pX", posX )
				setElementData ( nodeElement, "pY", posY )
				setElementData ( nodeElement, "pZ", posZ )
				setElementParent ( nodeElement, block )
					
				for _, node in ipairs ( nodesData ) do
					local nodeElement = createElement ( "node" )
					setElementData ( nodeElement, "spd", node [ 1 ], false )
					setElementData ( nodeElement, "pX", node [ 2 ], false )
					setElementData ( nodeElement, "pY", node [ 3 ], false )
					setElementData ( nodeElement, "pZ", node [ 4 ], false )
					
					setElementParent ( nodeElement, block )
				end
				
				setElementParent ( block, source )
				
				outputChatBox ( "WBO: Путь из " .. #nodesData .. " узлов успешно создан", client, 255, 255, 0 )
			end
		end
	end 
)

addEventHandler ( "onCreateWBOPortal", root,
	function ( data )
		if type ( data ) == "table" and #data == 14 then
			local account = getPlayerAccount ( client )
			if isGuestAccount ( account ) ~= true then
  
				local dimension = getElementDimension ( client )
				local accountName = getAccountName ( account )
   
				local portal = { }
   
				portal [ 1 ] = createObject ( 2978, data [ 1 ], data [ 2 ], data [ 3 ], data [ 4 ], data [ 5 ], data [ 6 ] )
				portal [ 2 ] = createObject ( 2978, data [ 8 ], data [ 9 ], data [ 10 ], data [ 11 ], data [ 12 ], data [ 13 ] )
   
				if portal [ 1 ] and portal [ 2 ] then
					setElementData ( portal [ 1 ], "wrpTo", createElementID ( portal [ 2 ] ), false )
					setElementData ( portal [ 2 ], "wrpTo", createElementID ( portal [ 1 ] ), false )
    
					for i = 1, 2 do
						setElementData ( portal [ i ], "owner", accountName )
						setElementData ( portal [ i ], "tag", "teleport" )
     
						local iKey = ( i * 7 ) - 7
     
						setElementDimension ( portal [ i ], data [ iKey + 7 ] )
     
						--Для сохранения
						setElementData ( portal [ i ], "model", "2978", false )
						setElementData ( portal [ i ], "posX", data [ iKey + 1 ], false )
						setElementData ( portal [ i ], "posY", data [ iKey + 2 ], false )
						setElementData ( portal [ i ], "posZ", data [ iKey + 3 ], false )
						setElementData ( portal [ i ], "rotX", data [ iKey + 4 ], false )
						setElementData ( portal [ i ], "rotY", data [ iKey + 5 ], false )
						setElementData ( portal [ i ], "rotZ", data [ iKey + 6 ] , false)
						setElementData ( portal [ i ], "dimension", tostring ( data [ iKey + 7 ] ), false )
						setElementParent ( portal [ i ], mapRoot )
					end
    
					outputChatBox ( "WBO: Вы успешно установили порталы", client, 255, 255, 0 )
				end
			else
				outputChatBox ( "WBO: Для работы с объектом необходима авторизация.", client, 255, 0, 0, true )
			end
		end
	end 
)

addEventHandler ( "onCreateWBOMagnet", root,
	function ( posX, posY, posZ )
		if type ( posX ) == "number" then
			local account = getPlayerAccount ( client )
			if isGuestAccount ( account ) ~= true then
				local magnet = createObject ( 3053, posX, posY, posZ )
				if magnet then
					setElementData ( magnet, "owner", getAccountName ( account ) )
					setElementDimension ( magnet, getElementDimension ( client ) )
					setElementData ( magnet, "tag", "magnet" )
    
					--Для сохранения
					setElementData ( magnet, "model", 3053, false )
					setElementData ( magnet, "posX", posX, false )
					setElementData ( magnet, "posY", posY, false )
					setElementData ( magnet, "posZ", posZ, false )
					setElementData ( magnet, "dimension", getElementDimension ( client ), false )
					setElementParent ( magnet, mapRoot )
    
					setElementFrozen ( magnet, true )
    
					--Для сохранения
					setElementData ( magnet, "frozen", true, false )
				end
			else
				outputChatBox ( "WBO: Для работы с объектом необходима авторизация.", client, 255, 0, 0, true )
			end
		end
	end 
)

addEventHandler ( "onCreateWBOMarker", root,
	function ( data )
		if type ( data ) == "table" and #data == 14 then
			local account = getPlayerAccount ( client )
			if isGuestAccount ( account ) ~= true then
				local block = createObject ( 2969, data [ 9 ], data [ 10 ], data [ 11 ], data [ 12 ], data [ 13 ], data [ 14 ] )
				if block then
					local dimension = getElementDimension ( client )
					setElementDimension ( block, dimension )
					setElementData ( block, "owner", getAccountName ( account ) )
	
					setElementData ( block, "tag", "smarker" )
    
					--Для сохранения
					setElementData ( block, "model", "2969", false )
					setElementData ( block, "posX", data [ 9 ], false )
					setElementData ( block, "posY", data [ 10 ], false )
					setElementData ( block, "posZ", data [ 11 ], false )
					setElementData ( block, "rotX", data [ 12 ], false )
					setElementData ( block, "rotY", data [ 13 ], false )
					setElementData ( block, "rotZ", data [ 14 ], false )
					setElementData ( block, "dimension", tostring ( dimension ), false )
					setElementParent ( block, mapRoot )
    
					local marker = createMarker ( data [ 1 ], data [ 2 ], data [ 3 ], data [ 4 ], data [ 5 ], data [ 6 ], data [ 7 ], data [ 8 ] )
					if marker then
						setElementDimension ( marker, dimension )
						setElementParent ( marker, block )
     
						--Для сохранения
						setElementData ( marker, "posX", data [ 1 ], false )
						setElementData ( marker, "posY", data [ 2 ], false )
						setElementData ( marker, "posZ", data [ 3 ], false )
						setElementData ( marker, "type", data [ 4 ], false )
						setElementData ( marker, "size", tostring ( data [ 5 ] ), false )
						setElementData ( marker, "color", string.format ( "#%.2X%.2X%.2X", data [ 6 ], data [ 7 ], data [ 8 ] ), false )
						setElementData ( marker, "dimension", tostring ( dimension ), false )
					end
				end
			else
				outputChatBox ( "WBO: Для создания маркера необходима авторизация.", client, 255, 0, 0, true )
			end
		end
	end 
)

addEventHandler ( "onLockTCTElement", resourceRoot,
	function ( pass )
		--If player is owner of object
		if isPlayerElementOwner ( client, source ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этим объектом!", client, 255, 0, 0, true )
			
			return 
		end
 
		if utfLen ( pass ) > 0 then
			setElementData ( source, "pass", pass )
			outputChatBox ( "WBO: Вы успешно установили пароль", client, 0, 255, 0, true )
		else
			removeElementData ( source, "pass" )
			outputChatBox ( "WBO: Вы успешно удалили пароль", client, 0, 255, 0, true )
		end
	end 
)

--[[addEventHandler ( "onElementDestroy", root, 
	function ( )
		local elementType = getElementType ( source )
		
		if elementType == "object" or elementType == "vehicle" then
			for _, element in ipairs ( getAttachedElements ( source ) ) do
				destroyElement ( element )
			end
		end 
		
		wireDestroyPulse ( source )
	end
)]]

addEventHandler ( "onPedWasted", resourceRoot,
	function ( )
		setTimer ( destroyElement, 5000, 1, source )
	end
)

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, player in ipairs ( getElementsByType ( "player" ) ) do
			bindKey ( player, CONSTRUCTOR_KEY, "both", toggleEditor )
			
			-- Выдаем бабки
			local account = getPlayerAccount ( player )
			if isGuestAccount ( account ) ~= true then
				local money = getAccountData ( account, "tct:money" )
				setPlayerMoney ( player, tonumber ( money ) )
			end
		end
	end
, false )

addEventHandler ( "onPlayerLogin", root,
	function ( _, account )
		-- Выдаем бабки
		if isGuestAccount ( account ) ~= true then
			local money = getAccountData ( account, "tct:money" )
			setPlayerMoney ( source, tonumber ( money ) )
		end
	end
)

addEventHandler ( "onPlayerJoin", root,
	function ( )
		bindKey ( source, CONSTRUCTOR_KEY, "both", toggleEditor )
	end
)

function toggleEditor ( player, _, keyState )
	keyState = keyState == "down"

	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		if keyState then
			outputChatBox ( "WBO: Вы должны быть авторизованы.", player, 255, 0, 0, true )
		end
		
		return
	end

	if isPedInVehicle ( player ) ~= true then
		local permission = hasObjectPermissionTo ( player, "command.tct", false )
		
		triggerClientEvent ( player, "onClientTCTToggle", resourceRoot, keyState, permission )
	else
		outputChatBox ( "Вы не можете строить в транспортном средстве", player, 255, 0, 0 )
	end
end

-- Helper functions
function createEntity ( model, x, y, z, rotx, roty, rotz )
	if model >= 0 and model <= 312 then
		return createPed ( model, x, y, z, rotz )
	elseif model >= 400 and model <= 611 then
		--return createVehicle ( model, x, y, z, rotx, roty, rotz )
	else
		return createObject ( model, x, y, z, rotx, roty, rotz )
	end
end