TriggerEntity = GameEntity.create ( )

function TriggerEntity.create ( x, y, z, size )
	local trigger = createElement ( "wbo:trigger" )
	
	setElementPosition ( trigger, x, y, z )
	setElementData ( trigger, "posX", x )
	setElementData ( trigger, "posY", y )
	setElementData ( trigger, "posZ", z )
	setElementData ( trigger, "size", tostring ( size ) )
	
	return trigger
end

function TriggerEntity.destroy ( element )
	
end

function TriggerEntity.streamIn ( element )
	TriggerEntity:addElement ( element )
	
	if TriggerEntity.refs == 1 then
		TriggerEntity.texture = dxCreateTexture ( "images/Modular Editor.png" )
		TriggerEntity.shader = dxCreateShader ( "shaders/garage.fx" )
		dxSetShaderValue ( TriggerEntity.shader, "Color", 0, 0, 0.6, 0.1 )
		addEventHandler ( "onClientPreRender", root, TriggerEntity.update, false, "low" )
		
		outputDebugString ( "TriggerEntity: update created" )
	end
end

function TriggerEntity.streamOut ( element )
	TriggerEntity:removeElement ( element )
	
	if TriggerEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, TriggerEntity.update )
		destroyElement ( TriggerEntity.texture )
		destroyElement ( TriggerEntity.shader )
		outputDebugString ( "TriggerEntity: update removed" )
	end
end

function TriggerEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
	
	if collision then return element, collision end;
end

local boxSides = {
	{ -1, 1 },
	{ 1, 1 },
	{ 1, -1 },
	{ -1, -1 }
}
local _drawSide = dxDrawMaterialLine3D

local function drawBox ( x, y, z, width, depth, height )
	local halfWidth, halfDepth, halfHeight = width/2, depth/2, height/2
	--x, y, z = x + halfWidth, y + halfDepth, z + halfHeight
	z = z + halfHeight
	
	for i, side in ipairs ( boxSides ) do
		local nextSide = i < 4 and boxSides [ i + 1 ] or boxSides [ 1 ]
		_drawSide ( 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z, 
			x + halfWidth*nextSide [ 1 ], y + halfDepth*nextSide [ 2 ], z,
			TriggerEntity.shader, height, color.white, x, y, z
		)
	end
end

function TriggerEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end

	for trigger, _ in pairs ( TriggerEntity.elements ) do
		local x, y, z = getElementPosition ( trigger )
		local size = tonumber ( getElementData ( trigger, "size" ) )
		
		drawBox ( x, y, z, size, size, size )
			
		_drawSide ( x, y, z + 0.25, x, y, z - 0.25, TriggerEntity.texture, 0.5, color.white )
	end
end