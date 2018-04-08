g_RPCFunctions = {
	createEmpty = true,
	createTrigger = true,
	toggleEntityProtect = true,
	createArea = true,
	setEntityAction = true,
	createWeapon = true,
	createEditorBlip = true,
	createEditorMarker = true,
	createSpawnpoint = true,
	setObjectLODModel = true,
	setEntityData = true
}

g_EventBase = {
	WEAPON = 1
}

function table.removevalue(t, val)
	for i,v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function table.find(t, ...)
	local args = { ... }
	if #args == 0 then
		for k,v in pairs(t) do
			if v then
				return k
			end
		end
		return false
	end
	
	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k,v in pairs(t) do
		for i,index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			return k
		end
	end
	return false
end

local function applyInverseRotation ( x, y, z, rx, ry, rz )
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

function getAttachRotationAdjusted ( from, to )
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
	
	return offsetPosX, offsetPosY, offsetPosZ, offsetRotX, offsetRotY, offsetRotZ
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
        
		local args = { ... }
		for _, element in ipairs ( args ) do
			if getElementData ( element, "owner" ) ~= accountName and hasObjectPermissionTo ( player, "command.tct", false ) ~= true then
				return false
			end
		end
  
		return true
	end
	
	return false
end

local letters = { "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" }
local numbers = { "0","1","2","3","4","5","6","7","8","9" }
 
local function generateLetter ( upper )
    if upper then 
		return letters [ math.random ( #letters ) ]:upper ( ) 
	end
	
    return letters [ math.random ( #letters ) ]
end
 
local function generateNumber ( ) 
	return tostring ( math.random ( 0, 9 ) )
end

function generateString ( length )
    if not length or type ( length ) ~= "number" or math.ceil ( length ) < 2 then 
		return false 
	end
	
    local result = ""
	
    for i = 1, math.ceil ( length ) do
		local upper = math.random ( 2 ) == 1 and true or false
		result = result .. ( math.random ( 2 ) == 1 and generateLetter ( upper ) or generateNumber ( ) )
    end
	
    return tostring ( result )
end

function createElementID ( element )
	local elementID = getElementID ( element )
	if elementID == "" then
		elementID = generateString ( 10 )
		setElementID ( element, elementID )
	end
	return elementID
end

local _getElementID = getElementID
function getElementID ( element )
	if isElement ( element ) then
		local id = getElementData ( element, "id", false )
		if id then return id end;
	end

	return _getElementID ( element )
end

local _setElementID = setElementID
function setElementID ( element, idStr )
	idStr = tostring ( idStr )
	_setElementID ( element, idStr )
	setElementData ( element, "id", idStr )
end

local _getElementRotation = getElementRotation
function getElementRotation ( element )
	local rotX = getElementData ( element, "rotX" )
	local rotY = getElementData ( element, "rotY" )
	local rotZ = getElementData ( element, "rotZ" )
	
	rotX, rotY, rotZ = tonumber ( rotX ), tonumber ( rotY ), tonumber ( rotZ )
	if rotX and rotZ then
		return rotX, rotY, rotZ
	end
	
	return _getElementRotation ( element )
end

local _attachElements = attachElements
local isAttachType = function ( element )
	local elementType = getElementType ( element )
	return elementType == "object" or elementType == "vehicle" or elementType == "ped" or elementType == "player"
end
function attachElements ( theElement, theAttachToElement, xPosOffset, yPosOffset, zPosOffset, xRotOffset, yRotOffset, zRotOffset )
	-- Custom attach
	if isAttachType ( theElement ) ~= true and isAttachType ( theAttachToElement ) then
		triggerClientEvent ( "onClientCustomAttach", theElement, theAttachToElement, xPosOffset, yPosOffset, zPosOffset, zRotOffset )
		
		return
	end
	
	return _attachElements ( theElement, theAttachToElement, xPosOffset, yPosOffset, zPosOffset, xRotOffset, yRotOffset, zRotOffset )
end

-------------------------------------
-- Move manager
-------------------------------------
local _moveObject, _stopObject = moveObject, stopObject
local objectMoveTimers = { }

function moveObject ( object, time, targetx, targety, targetz, moverx, movery, moverz, easingType, easingPeriod, easingAmplitude, easingOvershoot )
	-- Если такой таймер уже существует, удаляем его
	if isTimer ( objectMoveTimers [ object ] ) then
		killTimer ( objectMoveTimers [ object ].timer )
	end

	objectMoveTimers [ object ] = { 
		--[[rx = moverx,
		ry = movery,
		rz = moverz]]
	}
	-- Создаем новый таймер
	objectMoveTimers [ object ].timer = setTimer ( 
		function ( object )
			objectMoveTimers [ object ] = nil
		
			if isElement ( object ) then
				triggerEvent ( "onObjectMoveStop", object, false )
			end
		end
	, time, 1, object )
	
	--[[setTimer ( function ( obj )
		local x, y, z = getElementRotation ( obj )
		outputChatBox ( x .. ", " .. y .. ", " .. z)
	end, 100, 0, object )]]
	
	_moveObject ( object, time, targetx, targety, targetz, moverx, movery, moverz, easingType, easingPeriod, easingAmplitude, easingOvershoot )
end

function isObjectMove ( object )
	return objectMoveTimers [ object ] ~= nil
end

function stopObject ( object )
	if isTimer ( objectMoveTimers [ object ] ) then
		killTimer ( objectMoveTimers [ object ].timer )
		objectMoveTimers [ object ] = nil

		triggerEvent ( "onObjectMoveStop", object, true )
	end
	
	_stopObject ( object )
end

-------------------------------------
-- Track manager
-------------------------------------
local objectNode = { }
local tracks = { }

local _dist3d = getDistanceBetweenPoints3D
local function omgRotate(a,b)
  local turn = b - a
  if turn < -180 then 
    turn = turn + 360
  elseif turn > 180 then  
    turn = turn - 360
  end
  return turn
end

function trackObject ( object, nodeRoot, targetNodeIndex, speed, easingType )
	local nodes = getElementsByType ( "path:node", nodeRoot )
	
	--Если количество узлов меньше двух, возвращаем false
	if #nodes < 2 then
		outputDebugString ( "Движение объекта невозможно когда в пути меньшее двух узлов", 2 )
		return false
	end
	
	--Если переданный индекс узла не указывает на реальный элемент в таблице, возвращаем false
	if targetNodeIndex < 1 or targetNodeIndex > #nodes then
		outputDebugString ( "Переданный индекс не может быть использован для пуска трека", 2 )
		return false
	end
	
	local currentNodeIndex = objectNode [ object ] or 1

	--Если объект уже находится на целевом узле, выходим из функции
	if currentNodeIndex == targetNodeIndex then return end;
	
	local nextNodeIndex = targetNodeIndex > currentNodeIndex and currentNodeIndex + 1 or currentNodeIndex - 1
	local nextNode = nodes [ nextNodeIndex ]

	if nextNode then
		tracks [ object ] = { 
			nodeRoot,
			targetNodeIndex,
			speed,
			easingType
		}
		
		--outputChatBox ( "current=" .. currentNodeIndex .. ", next=" .. nextNodeIndex )
		
		local pNode = nodes [ currentNodeIndex ]
		local pPosX, pPosY, pPosZ = getElementPosition ( object )
		local pRotX, pRotY, pRotZ = _getElementRotation ( object )
		pRotX, pRotY, pRotZ = _getElementRotation ( object ) -- Фикс
		
		local posX, posY, posZ = getElementPosition ( nextNode )
		local rotX, rotY, rotZ = tonumber ( getElementData ( nextNode, "rotX" ) ), tonumber ( getElementData ( nextNode, "rotY" ) ), tonumber ( getElementData ( nextNode, "rotZ" ) )
		
		local dist = _dist3d ( pPosX, pPosY, pPosZ, posX, posY, posZ )
		speed = math.max ( speed * math.max ( dist, 1 ), 100 )
		
		--outputChatBox("двигаем " .. getElementID(object))
		
		if rotX then
			local rotx = omgRotate(pRotX, rotX)
			local roty = omgRotate(pRotY, rotY)
			local rotz = omgRotate(pRotZ, rotZ)
		
			moveObject ( object, speed, posX, posY, posZ, rotx, roty, rotz, easingType )
			
		-- Только перемещение без вращения
		else
			moveObject ( object, speed, posX, posY, posZ, 0, 0, 0, easingType )
		end
	
		objectNode [ object ] = nextNodeIndex
		setElementData ( object, "node", { nextNodeIndex }, false )
	end
end

function _trackObject ( )
	-- TODO
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
		--Если объект не двигался по треку, выходим из функции
		local objectTrack = tracks [ source ]
		if not objectTrack then
			return
		end
		
		local nodeRoot = objectTrack [ 1 ]
		local targetNodeIndex = objectTrack [ 2 ]
		local speed = objectTrack [ 3 ]
		local easingType = objectTrack [ 4 ]
		local currentNodeIndex = objectNode [ source ]
		
		EventManager.triggerEvent ( nodeRoot, "Entity:Path", 1, currentNodeIndex )
		
		--Если объект уже находится на целевом узле, останавливаем трек и выходим из функции
		if currentNodeIndex == targetNodeIndex then
			tracks [ source ] = nil
			
			EventManager.triggerEvent ( nodeRoot, "Entity:Path", 2, currentNodeIndex )
				
			return
		end
		
		local nodes = getElementsByType ( "path:node", nodeRoot )
	
		local nextNodeIndex = targetNodeIndex > currentNodeIndex and currentNodeIndex + 1 or currentNodeIndex - 1
		local nextNode = nodes [ nextNodeIndex ]
			
		if nextNode then
			--outputChatBox ( "current=" .. currentNodeIndex .. ", next=" .. nextNodeIndex )
		
			local pNode = nodes [ currentNodeIndex ]
			local pPosX, pPosY, pPosZ = getElementPosition ( source )
			local pRotX, pRotY, pRotZ = _getElementRotation ( source )
			pRotX, pRotY, pRotZ = _getElementRotation ( source ) -- Фикс
			
			local posX, posY, posZ = getElementPosition ( nextNode )
			local rotX, rotY, rotZ = tonumber ( getElementData ( nextNode, "rotX" ) ), tonumber ( getElementData ( nextNode, "rotY" ) ), tonumber ( getElementData ( nextNode, "rotZ" ) )
			
			local dist = _dist3d ( pPosX, pPosY, pPosZ, posX, posY, posZ )
			speed = math.max ( speed * math.max ( dist, 1 ), 100 )
			
			if rotX then
				local rotx = omgRotate(pRotX, rotX)
				local roty = omgRotate(pRotY, rotY)
				local rotz = omgRotate(pRotZ, rotZ)
		
				moveObject ( source, speed, posX, posY, posZ, rotx, roty, rotz, easingType )
				
			-- Только перемещение без вращения
			else
				moveObject ( source, speed, posX, posY, posZ, 0, 0, 0, easingType )
			end
				
			objectNode [ source ] = nextNodeIndex 
			setElementData ( source, "node", { nextNodeIndex }, false )
		end
	end
)

----------------------------------
-- Sound
----------------------------------
sound3D = { 
	items = { }
}

function sound3D.createAndAttachTo ( fileId, element, looped, volume )
	--[[if fileExists ( filename ) ~= true then
		return
	end]]
	
	sound3D.items [ element ] = nil
	if looped then
		sound3D.items [ element ] = { fileId, volume }
	end
	
	-- Передаем звук только игрокам в комнате, в которой находится элемент
	local room = RoomManager.getElementRoom ( element )
	local players = RoomManager.getRoomPlayers ( room )
	for _, player in ipairs ( players ) do
		triggerClientEvent ( player, "onClientElementAttachSound", element, fileId, looped, volume )
	end
end

function sound3D.setVolume ( element, volume )
	local soundData = sound3D.items [ element ]
	if soundData then
		soundData [ 2 ] = volume
	
		local room = RoomManager.getElementRoom ( element )
		local players = RoomManager.getRoomPlayers ( room )
		for _, player in ipairs ( players ) do
			triggerClientEvent ( player, "onClientElementVolumeSound", element, volume )
		end
	end
end

-- Только для зацикленных звуков
function sound3D.isAttachedTo ( element )
	return sound3D.items [ element ] ~= nil
end

function sound3D.detachFrom ( element )
	if sound3D.items [ element ] then
		local room = RoomManager.getElementRoom ( element )
		local players = RoomManager.getRoomPlayers ( room )
		for _, player in ipairs ( players ) do
			triggerClientEvent ( player, "onClientElementDetachSound", element )
		end
	end
	sound3D.items [ element ] = nil
end

addEvent ( "onPlayerRoomChange", false )
addEventHandler ( "onPlayerRoomChange", root,
	function ( oldroom, newroom )
		local packedSounds = { 
			--[[
				soundNum,
				
				element1,
				filename1,
				element2,
				filename2,
				...
			]]
		}
		local soundNum = 0
	
		for element, data in pairs ( sound3D.items ) do
			if RoomManager.isElementInRoom ( element, newroom ) then
				local index = #packedSounds
				packedSounds [ index + 1 ] = element
				packedSounds [ index + 2 ] = data [ 1 ] -- id
				packedSounds [ index + 3 ] = data [ 2 ] -- volume
				
				soundNum = soundNum + 1
			end
		end
		
		table.insert ( packedSounds, 1, soundNum )
		
		triggerClientEvent ( source, "onClientRoomSoundPacket", resourceRoot, packedSounds )
		
		outputDebugString ( "Передано " .. soundNum .. " звуков игроку " .. getPlayerName ( source ) )
	end
)

addEventHandler ( "onPlayerJoin", root,
	function ( )
		--[[for element, filename in pairs ( sound3D.items ) do
			triggerClientEvent ( "onClientElementAttachSound", element, filename, true )
		end]]
	end
)

function string:split(separator)
	if separator == '.' then
		separator = '%.'
	end
	local result = {}
	for part in self:gmatch('(.-)' .. separator) do
		result[#result+1] = part
	end
	result[#result+1] = self:match('.*' .. separator .. '(.*)$') or self
	return result
end

function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
end

addEvent('onServerCall', true)
addEventHandler('onServerCall', root,
	function(fnName, ...)
		local fnInfo = g_RPCFunctions[fnName]
		if fnInfo and ((type(fnInfo) == 'boolean' and fnInfo) or (type(fnInfo) == 'table' and getOption(fnInfo.option))) then
			local fn = _G
			for i,pathpart in ipairs(fnName:split('.')) do
				fn = fn[pathpart]
			end
			fn(...)
		elseif type(fnInfo) == 'table' then
			errMsg(fnInfo.descr .. ' is not allowed', source)
		end
	end
)

function clientCall(player, fnName, ...)
	--triggerClientEvent(onlyJoined(player), 'onClientCall_race', resourceRoot, fnName, ...)
	
	player = player or root
	
	triggerClientEvent(player, 'onClientCall', resourceRoot, fnName, ...)
end

local _getElementDimension = getElementDimension
function getElementDimension ( element )
	local dimension = tonumber ( getElementData ( element, "dimension" ) ) or _getElementDimension ( element )
	return dimension
end

--[[
	Key delayed
]]
local keyBinds = { 

}

function bindKeyDelay ( player, key, time, handlerFunction, ... )
	if keyBinds [ player ] == nil then
		keyBinds [ player ] = {
			key = key,
			time = time,
			fn = handlerFunction,
			args = { ... }
		}
		bindKey ( player, key, "both", _onPlayerKey )
	end
end

function unbindKeyDelay ( player )
	local bind = keyBinds [ player ]
	if bind then
		unbindKey ( player, bind.key, "both", _onPlayerKey )
		if isTimer ( bind.timer ) then
			killTimer ( bind.timer )
		end
	end
	keyBinds [ player ] = nil
end

function _onPlayerKey ( player, key, keyState )
	local bind = keyBinds [ player ]
	if bind then
		if keyState == "down" then
			bind.timer = setTimer ( _onPlayerKeyDelay, bind.time, 1, player )
		elseif keyState == "up" then
			if isTimer ( bind.timer ) then
				killTimer ( bind.timer )
			end
		end
	end
end

function _onPlayerKeyDelay ( player )
	local bind = keyBinds [ player ]
	if bind then
		bind.fn ( player, bind.key, unpack ( bind.args ) )
	end
end

function debugString ( str, level )
	if TCT_DEBUG then
		outputDebugString ( str, level )
	end
end

function isValidSkin ( model )
	model = tonumber ( model )
	local allSkins = getValidPedModels ( )
	for _, skin in ipairs ( allSkins ) do
		if skin == model then return true end;
	end
end

local _setPedAnimation = setPedAnimation
local pedAnimation = {
	--[ped] = { ..data.. }
}
local function _onPedDestroy ( )
	pedAnimation [ source ] = nil
end
function setPedAnimation ( ped, block, anim, time, loop, updatePosition, interruptable, freezeLastFrame )
	--if _setPedAnimation ( ped, block, anim, time, loop, updatePosition, interruptable, freezeLastFrame ) then
		pedAnimation [ ped ] = {
			block,
			anim,
			time,
			loop,
			updatePosition,
			interruptable,
			freezeLastFrame
		}
		triggerClientEvent ( "PedAnimStart", ped, pedAnimation [ ped ] )
		addEventHandler ( "onElementDestroy", ped, _onPedDestroy, false )
	--end
end

addEventHandler ( "onPlayerJoin", root,
	function ( )
		for ped, animData in pairs ( pedAnimation ) do
			triggerClientEvent ( "PedAnimStart", ped, unpack ( animData ) )
		end
	end
)

local vehicleIDS = { 602, 545, 496, 517, 401, 410, 518, 600, 527, 436, 589, 580, 419, 439, 533, 549, 526, 491, 474, 445, 467, 604, 426, 507, 547, 585,
405, 587, 409, 466, 550, 492, 566, 546, 540, 551, 421, 516, 529, 592, 553, 577, 488, 511, 497, 548, 563, 512, 476, 593, 447, 425, 519, 520, 460,
417, 469, 487, 513, 581, 510, 509, 522, 481, 461, 462, 448, 521, 468, 463, 586, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 485, 552, 431, 
438, 437, 574, 420, 525, 408, 416, 596, 433, 597, 427, 599, 490, 432, 528, 601, 407, 428, 544, 523, 470, 598, 499, 588, 609, 403, 498, 514, 524, 
423, 532, 414, 578, 443, 486, 515, 406, 531, 573, 456, 455, 459, 543, 422, 583, 482, 478, 605, 554, 530, 418, 572, 582, 413, 440, 536, 575, 534, 
567, 535, 576, 412, 402, 542, 603, 475, 449, 537, 538, 441, 464, 501, 465, 564, 568, 557, 424, 471, 504, 495, 457, 539, 483, 508, 571, 500, 
444, 556, 429, 411, 541, 559, 415, 561, 480, 560, 562, 506, 565, 451, 434, 558, 494, 555, 502, 477, 503, 579, 400, 404, 489, 505, 479, 442, 458, 
606, 607, 610, 590, 569, 611, 584, 608, 435, 450, 591, 594 }
function randomVehicleModel ( )
	return vehicleIDS [ math.random ( 1, #vehicleIDS ) ]
end
function randomPedModel ( )
	local pedValidModels = getValidPedModels ( )
	return pedValidModels [ math.random ( 1, #pedValidModels ) ]
end
function getModelType ( model )
	model = tonumber ( model )
	for _, vehmodel in ipairs ( vehicleIDS ) do
		if vehmodel == model then
			return "vehicle"
		end
	end
	local pedValidModels = getValidPedModels ( )
	for _, pedmodel in ipairs ( pedValidModels ) do
		if pedmodel == model then
			return "ped"
		end
	end
end


function spawnPlayerSafe ( player, x, y, z, rotation, skinID, interior, dimension, team )
	local ok
	for i = 1, 20 do
		ok = spawnPlayer ( player, x, y, z, rotation, skinID, interior, dimension, team )
		if ok then break end
	end
	if not ok then
		spawnPlayer ( player, x, y, z, rotation, skinID, interior, dimension, team )
	end
end

--[[
	Выравнивание педа относительно родительского объекта(только если пед прикреплен)
]]
local adjustPeds = { }

function setPedAdjust ( ped, adjust )
	adjust = tonumber ( adjust )
	if isElementAttached ( ped ) then
		--adjustPeds [ ped ] = adjust
		--triggerClientEvent ( "onClientPedAdjust", ped, adjust )
		--setElementData ( ped, )
		local attachedTo = getElementAttachedTo ( ped )
		local _, _, rot = getElementRotation ( attachedTo )
		setElementRotation ( ped, 0, 0, rot + adjust )
	end
end