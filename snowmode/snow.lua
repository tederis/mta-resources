--[[local sw, sh = guiGetScreenSize ( )

SnowControl = {
	snow1 = dxCreateTexture ( "textures/Snow01.png" ),
	snow2 = dxCreateTexture ( "textures/Snow02.png" ),
	snow3 = dxCreateTexture ( "textures/Snow03.png" )
}

function SnowControl.create ( )
	SnowControl.shader = dxCreateShader ( "shaders/snow.fx" )
	dxSetShaderValue ( SnowControl.shader, "Tex01", SnowControl.snow1 )
	dxSetShaderValue ( SnowControl.shader, "Tex02", SnowControl.snow2 )
	dxSetShaderValue ( SnowControl.shader, "Tex03", SnowControl.snow3 )
	
	SnowControl.panners = {
		Panner.create ( Panner.setup ),
		Panner.create ( Panner.setup ),
		Panner.create ( Panner.setup )
	}
	
	addEventHandler ( "onClientPreRender", root, SnowControl.draw, false )
end

local lastCollisionCheck = getTickCount ( )
local lastCollisionState
function SnowControl.draw ( )
	local now = getTickCount ( )
	
	if now - lastCollisionCheck > 100 then
		local x, y, z = getElementPosition ( localPlayer )
	
		local collisionState = isLineOfSightClear ( x, y, z, x, y, z + 5, true, false, false, true, false, false, false, localPlayer )
		if collisionState ~= lastCollisionState then
			SnowControl.setSnowDepth ( collisionState and 1 or 0.008 )
			
			lastCollisionState = collisionState
		end
		
		lastCollisionCheck = now
	end


	local now = getTickCount ( ) / 1000
	
	for i = 1, 3 do
		local yoffset = -math.fmod ( now / 3.5 ,1 )
	
		local value = SnowControl.panners [ i ]:getValue ( ) * 0.4
		dxSetShaderValue ( SnowControl.shader, "snowOffset" .. i, rotX + ( value * 0.9 ), -rotY + yoffset )
	end
	
	dxDrawImage ( 0, 0, sw, sh, SnowControl.shader )
end

function SnowControl.setSnowDepth ( depth )
	SnowControl.depth = depth
	
	dxSetShaderValue ( SnowControl.shader, "snowDepth", depth )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		SnowControl.create ( )
	end
, false )



Panner = { }
Panner.__index = Panner

function Panner.create ( fnCallback )
	local panner = setmetatable ( { fn = fnCallback }, Panner ) 
	
	panner:setup ( 0 )
	
	return panner
end

function Panner:setup ( startValue )
	local now = getTickCount ( )
	
	self.startTime = now
	self.endTime = now + 40000
	self.startValue = startValue
	self.endValue = math.random ( 1, 10 )
end

function Panner:getValue ( )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	local progress = elapsedTime / duration
	
	if progress > 1 then
		if self.fnCallback then
			self.fnCallback ( self, self.endValue )
		end
		
		return self.endValue
	end
	
	return interpolateBetween ( self.startValue, 0, 0, self.endValue, 0, 0, progress, "CosineCurve" )
end

local PI = math.pi
local mouseFrameDelay = 0
local options = {
	invertMouseLook = false,
	mouseSensitivity = 0.2
}
rotX, rotY = 0, 0
function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
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
	
	--outputChatBox ( rotX )
 
	rotY = math.clamp ( -PI / 2.05, rotY, PI / 2.05 )
end
addEventHandler ( "onClientCursorMove", root, mousecalc )]]