function IfElse ( condition, trueReturn, falseReturn )
    if condition then 
		return trueReturn
    else 
		return falseReturn 
	end
end

function attachRotationAdjusted ( from, to )
    local frPosX, frPosY, frPosZ = getElementPosition ( from )
    local frRotX, frRotY, frRotZ = getElementRotation ( from )
    local toPosX, toPosY, toPosZ = getElementPosition ( to )
    local toRotX, toRotY, toRotZ = getElementRotation ( to )
    local offsetPosX = frPosX - toPosX
    local offsetPosY = frPosY - toPosY
    local offsetPosZ = frPosZ - toPosZ
    local offsetRotX = frRotX - toRotX
    local offsetRotY = frRotY - toRotY
    local offsetRotZ = frRotZ - toRotZ
 
    offsetPosX, offsetPosY, offsetPosZ = applyInverseRotation ( offsetPosX, offsetPosY, offsetPosZ, toRotX, toRotY, toRotZ )
	
    attachElements ( from, to, offsetPosX, offsetPosY, offsetPosZ, offsetRotX, offsetRotY, offsetRotZ )
end
 
 
function applyInverseRotation ( x, y, z, rx, ry, rz )
    local DEG2RAD = ( math.pi * 2 ) / 360
    rx = rx * DEG2RAD
    ry = ry * DEG2RAD
    rz = rz * DEG2RAD
 
    local tempY = y
    y =  math.cos ( rx ) * tempY + math.sin ( rx ) * z
    z = -math.sin ( rx ) * tempY + math.cos ( rx ) * z
 
    local tempX = x
    x =  math.cos ( ry ) * tempX - math.sin ( ry ) * z
    z =  math.sin ( ry ) * tempX + math.cos ( ry ) * z
 
    tempX = x
    x =  math.cos ( rz ) * tempX + math.sin ( rz ) * y
    y = -math.sin ( rz ) * tempX + math.cos ( rz ) * y
 
    return x, y, z
end

function RGBToHex ( red, green, blue, alpha )
	if ( red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 ) or ( alpha and ( alpha < 0 or alpha > 255 ) ) then
		return
    end
    
	if alpha then
		return string.format ( "#%.2X%.2X%.2X%.2X", red, green, blue, alpha )
	else
		return string.format ( "#%.2X%.2X%.2X", red, green, blue )
	end
end

function isPlayerElementOwner ( player, ... )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) ~= true then
		local accountName = getAccountName ( account )
        
		for _, element in ipairs ( arg ) do
			if getElementData ( element, "owner" ) ~= accountName and hasObjectPermissionTo ( player, "command.tct", false ) ~= true then
				return false
			end
		end
  
		return true
	end
	
	return false
end

function isPlayerAdmin ( player )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) ~= true then       
		return hasObjectPermissionTo ( player, "command.tct", false )
	end
	
	return false
end

local chars = 
{ "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d",
 "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m",
 "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

function createElementID ( element )
	local elementID = getElementID ( element )
	local isIDNew = false
	
	if elementID == "" then
		for i = 0, 10 do
			elementID = elementID .. chars [ math.random ( 1, #chars ) ]
		end
		setElementID ( element, elementID )
  
		--Для сохранения
		setElementData ( element, "id", elementID )
  
		isIDNew = true
	end
	
	return elementID, isIDNew
end

-------------------------------------
-- Move manager
-------------------------------------
local _moveObject, _stopObject = moveObject, stopObject

local objectMoveTimers = { }

function moveObject ( object, time, targetx, targety, targetz, moverx, movery, moverz, easingType, easingPeriod, easingAmplitude, easingOvershoot )
	_moveObject ( object, time, targetx, targety, targetz, moverx, movery, moverz, easingType, easingPeriod, easingAmplitude, easingOvershoot )
	
	if isTimer ( objectMoveTimers [ object ] ) then
		killTimer ( objectMoveTimers [ object ] )
	end
	
	objectMoveTimers [ object ] = setTimer ( 
	function ( object )
		objectMoveTimers [ object ] = nil
		
		if isElement ( object ) then
			triggerEvent ( "onObjectMoveStop", object, false )
		end
	end, time, 1, object )
	
	for _, block in ipairs ( getElementChildren ( object, "object" ) ) do
		stopObject ( block )
	end
end

function isObjectMove ( object )
	return objectMoveTimers [ object ] ~= nil
end

function stopObject ( object )
	_stopObject ( object )
	
	if isTimer ( objectMoveTimers [ object ] ) then
		killTimer ( objectMoveTimers [ object ] )
		objectMoveTimers [ object ] = nil
		
		triggerEvent ( "onObjectMoveStop", object, true )
	end
end

-------------------------------------
-- Track manager
-------------------------------------
local tracks = { }

function trackObject ( object, nodeRoot, moveNode )
	local nodes = getElementsByType ( "node", nodeRoot )
	
	--Если количество узлов меньше двух, возвращаем false
	if #nodes < 2 then
		outputDebugString ( "Движение объекта невозможно когда в пути меньшее двух узлов", 2 )
		
		return false
	end
	
	--Если переданный индекс узла не указывает на реальный элемент в таблице, возвращаем false
	if moveNode < 1 or moveNode > #nodes then
		outputDebugString ( "Переданный индекс не может быть использован для пуска трека", 2 )
		
		return false
	end
	
	local currentNode = tonumber ( getElementData ( nodeRoot, "node" ) ) or 1
	
	if currentNode == moveNode then
		return
	end
	
	local nextNode = IfElse ( moveNode > currentNode, currentNode + 1, currentNode - 1 )
	local nextNodeElement = nodes [ nextNode ]

	if nextNodeElement then
		tracks [ object ] = { nodeRoot, moveNode }
		
		local posX, posY, posZ = getElementData ( nextNodeElement, "pX" ), 
								getElementData ( nextNodeElement, "pY" ), 
								getElementData ( nextNodeElement, "pZ" )
		local speed = getElementData ( nextNodeElement, "spd" ) or 1000
		
		moveObject ( object, speed, posX, posY, posZ )
		
		setElementData ( nodeRoot, "node", nextNode )
		
		--Wire
		wireTriggerOutput ( nodeRoot, 1, nextNode )
	end
end

function isObjectTrack ( object )
	return tracks [ object ] ~= nil
end

function stopObjectTrack ( object )
	tracks [ object ] = nil
end

addEvent ( "onObjectMoveStop", false )
addEventHandler ( "onObjectMoveStop", resourceRoot,
	function ( )
		if isObjectTrack ( source ) then
			local nodeRoot = tracks [ source ] [ 1 ]
			local moveNode = tracks [ source ] [ 2 ]
			local currentNode = getElementData ( nodeRoot, "node" )
			
			if currentNode == moveNode then
				stopObjectTrack ( source )
				
				return
			end
			
			local nodes = getElementsByType ( "node", nodeRoot )
			
			local nextNode = IfElse ( moveNode > currentNode, currentNode + 1, currentNode - 1 )
			local nextNodeElement = nodes [ nextNode ]
			
			if nextNodeElement then
				local posX, posY, posZ = getElementData ( nextNodeElement, "pX" ), 
								         getElementData ( nextNodeElement, "pY" ), 
								         getElementData ( nextNodeElement, "pZ" )
				local speed = getElementData ( nextNodeElement, "spd" ) or 1000
		
				moveObject ( source, speed, posX, posY, posZ )
				
				setElementData ( nodeRoot, "node", nextNode )
				
				--Wire
				wireTriggerOutput ( nodeRoot, 1, nextNode )
			end
		end
	end
)

----------------------------------
-- Sound
----------------------------------
sound3D = { 
	items = { }
}

function sound3D.createAndAttachTo ( filename, element, looped )
	if not fileExists ( "sound/" .. filename ) then
		return
	end

	if not sound3D.isAttachedTo ( element ) then
		triggerClientEvent ( "onClientElementAttachSound", element, filename, looped )
		
		if looped then
			sound3D.items [ element ] = filename
		end
	end
end

function sound3D.isAttachedTo ( element )
	return sound3D.items [ element ] ~= nil
end

function sound3D.detachFrom ( element )
	if not sound3D.isAttachedTo ( element ) then
		return
	end
	
	triggerClientEvent ( "onClientElementDetachSound", element )
	sound3D.items [ element ] = nil
end

addEventHandler ( "onPlayerJoin", root,
	function ( )
		for element, filename in pairs ( sound3D.items ) do
			triggerClientEvent ( "onClientElementAttachSound", element, filename, true )
		end
	end
)