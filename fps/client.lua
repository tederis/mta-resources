local sw, sh = guiGetScreenSize ( )
local rotX, rotY = 0, 0
local mouseFrameDelay = 0
local PI = math.pi

local options = {
	invertMouseLook = false,
	mouseSensitivity = 0.1
}

bindKey ( "k", "up",
	function ( )
		if isElement ( getCameraTarget ( ) ) then
			rotX, rotY = 0, 0
		
			addEventHandler ( "onClientPreRender", root, render )
			addEventHandler ( "onClientCursorMove", root, mousecalc )
		else
			removeEventHandler ( "onClientPreRender", root, render )
			removeEventHandler ( "onClientCursorMove", root, mousecalc )
			setCameraTarget ( localPlayer )
		end
	end 
)


function render ( )
	local cameraAngleX = rotX 
	local cameraAngleY = rotY
	
	if isPedInVehicle ( localPlayer ) then
		local dist = math.rad ( -getPedRotation ( localPlayer ) )
	
		if dist > PI then
			dist = dist - 2 * PI
		elseif rotX < -PI then
			dist = dist + 2 * PI
		end
	
		cameraAngleX = cameraAngleX + dist
	end
	
	local freeModeAngleZ = math.sin ( cameraAngleY )
	local freeModeAngleY = math.cos ( cameraAngleY ) * math.cos ( cameraAngleX )
	local freeModeAngleX = math.cos ( cameraAngleY ) * math.sin ( cameraAngleX )
	
	local camPosX, camPosY, camPosZ = getPedBonePosition ( localPlayer, 6 )
	
	camTargetX = camPosX + freeModeAngleX * 100
	camTargetY = camPosY + freeModeAngleY * 100
	camTargetZ = camPosZ + freeModeAngleZ * 100
  
	setCameraMatrix ( camPosX, camPosY, camPosZ, camTargetX, camTargetY, camTargetZ )
end

function mousecalc ( _, _, aX, aY )
	if isCursorShowing ( ) or isMTAWindowActive ( ) then
		mouseFrameDelay = 5
		
		return
	elseif mouseFrameDelay > 0 then
		mouseFrameDelay = mouseFrameDelay - 1
		
		return
	end
	
	aX = aX - sw / 2 
	aY = aY - sh / 2
 
	if options.invertMouseLook then
		aY = -aY
	end
 
	rotX = rotX + aX * options.mouseSensitivity * 0.01745
	rotY = rotY - aY * options.mouseSensitivity * 0.01745
 
	if rotX > PI then
		rotX = rotX - 2 * PI
	elseif rotX < -PI then
		rotX = rotX + 2 * PI
	end
	
	if rotY > PI then
		rotY = rotY - 2 * PI
	elseif rotY < -PI then
		rotY = rotY + 2 * PI
	end
 
	rotY = math.clamp ( -PI / 2.05, rotY, PI / 2.05 )
end

function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
end