local sw, sh = guiGetScreenSize ( )

local pickableObject

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		setTimer ( updatePulse, 250, 0 )
		bindKey ( "e", "down", actionKeyPressed )
	end
)

function actionKeyPressed ( )
	local cargo = getElementData ( localPlayer, "cargo" )
	if cargo then
		local vehicle = getNearestObject ( "vehicle", 408, 2.2, 0, -3, 0 )

		triggerServerEvent ( "onPlayerPickupObject", localPlayer, cargo, vehicle )
	else
		if not pickableObject then
			return
		end
	
		triggerServerEvent ( "onPlayerPickupObject", localPlayer, pickableObject )
		pickableObject = nil
		
		showTextLine ( "#FFFFFFПоложите мешок в #2121FFконтейнер мусоровоза" )
	end
end

function updatePulse ( )
	--Если мы несем груз
	if getElementData ( localPlayer, "cargo" ) then
		showTextBox ( "Нажмите E чтобы положить мешок" )
	
		return
	end

	pickableObject = getNearestObject ( "object", 1264, 1.6, 0, 0, 0 )
	if pickableObject then
		showTextBox ( "Нажмите E чтобы поднять мешок" )
	end
end

addEventHandler ( "onClientVehicleEnter", root,
	function ( player, seat )
		if getElementModel ( source ) ~= 408 then
			return
		end
		
		showTextBox ( "Нажмите 2 для переключения миссии мусорщика" )
	end
)

addEventHandler ( "onClientMissionStart", resourceRoot,
	function ( )
		for _, object in ipairs ( getElementsByType ( "object", resourceRoot ) ) do
			createBlipAttachedTo ( object )
		end
		
		showTextLine ( "#FFFFFFСобери #2121FFмешки с мусором #FFFFFFдо 16:00" )
	end
)

addEventHandler ( "onClientMissionStop", resourceRoot,
	function ( )
		for _, blip in ipairs ( getElementsByType ( "blip", resourceRoot ) ) do
			destroyElement ( blip )
		end
	end
)

addEventHandler ( "onClientElementDataChange", root,
	function ( dataName )
		if source ~= localPlayer or dataName ~= "bagCnt" then
			return
		end
		
		local bagCnt = getElementData ( source, dataName )
		setStatusText ( "Собрано пакетов: " .. bagCnt, 1 )
	end 
)

function getNearestObject ( elementType, model, radius, offX, offY, offZ )
	local playerX, playerY, playerZ = getElementPosition ( localPlayer )
	local minDist = radius
	local nearestObject
	
	local objects = getElementsByType ( elementType, resourceRoot, true )
	for _, object in ipairs ( objects ) do
		if getElementModel ( object ) == model then
			local posX, posY, posZ = getElementPositionByOffset ( object, offX, offY, offZ )

			if isLineOfSightClear ( playerX, playerY, playerZ, posX, posY, posZ, true, true, false, true, true, false, false, object ) then
				local distance = getDistanceBetweenPoints3D ( playerX, playerY, playerZ, posX, posY, posZ )

				if distance < minDist then
					minDist = distance
					nearestObject = object
				end
			end
		end
	end
	
	return nearestObject
end

function getTargetAngle ( px, py, pr, tx, ty )
	local relx = tx - px
	local rely = ty - py
	local dist = math.sqrt ( ( relx * relx ) + ( rely * rely ) )
	local dot = 0
	relx = relx / dist
	rely = rely / dist
	dot = ( ( math.sin ( math.rad ( 360 - pr ) ) ) * relx ) + ( ( math.cos ( math.rad ( 360 - pr ) ) ) * rely )
	
	return math.deg ( math.acos ( dot ) )
end

function getElementPositionByOffset ( element, offX, offY, offZ )
	local posX, posY, posZ = getElementPosition ( element )
	
	local center = getElementMatrix ( element )
	if center then
		posX = offX * center [ 1 ] [ 1 ] + offY * center [ 2 ] [ 1 ] + offZ * center [ 3 ] [ 1 ] + center [ 4 ] [ 1 ]
		posY = offX * center [ 1 ] [ 2 ] + offY * center [ 2 ] [ 2 ] + offZ * center [ 3 ] [ 2 ] + center [ 4 ] [ 2 ]
		posZ = offX * center [ 1 ] [ 3 ] + offY * center [ 2 ] [ 3 ] + offZ * center [ 3 ] [ 3 ] + center [ 4 ] [ 3 ]
	end
	
	return posX, posY, posZ
end