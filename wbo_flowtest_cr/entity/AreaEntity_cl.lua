AreaEntity = GameEntity.create ( )

function AreaEntity.create ( x, y, z, width, depth )
	local area = createElement ( "wbo:area" )
	
	local radararea = createRadarArea ( x - ( width / 2 ), y - ( depth / 2 ), width, depth, 255, 0, 0, 175 )
	setElementParent ( radararea, area )
	
	setElementPosition ( area, x, y, z )
	setElementData ( area, "posX", x )
	setElementData ( area, "posY", y )
	setElementData ( area, "posZ", z )
	setElementData ( area, "width", width )
	setElementData ( area, "depth", depth )
	
	return area
end

function AreaEntity.destroy ( element )
	
end

function AreaEntity.setSize ( area, width, depth )
	setElementData ( area, "width", width, false )
	setElementData ( area, "depth", depth, false )
	local radararea = getElementChild ( area, 0 )
	local x, y = getElementPosition ( area )
	setElementPosition ( radararea, x - ( width / 2 ), y - ( depth / 2 ), 0 )
	setRadarAreaSize ( radararea, width, depth )
end

local areaProjectors = { }

function AreaEntity.streamIn ( element )
	AreaEntity:addElement ( element )
	
	if AreaEntity.refs == 1 then
		--AreaEntity.texture = dxCreateTexture ( "textures/zabor1.dds", "dxt3" )
		AreaEntity.texture = dxCreateShader ( "shaders/garage.fx" )
		dxSetShaderValue ( AreaEntity.texture, "Color", 0, 0.6, 0, 0.1 )
		AreaEntity.iconTexture = dxCreateTexture ( "images/Asset Browser.png" )
		addEventHandler ( "onClientPreRender", root, AreaEntity.update, false )
		
		outputDebugString ( "AreaEntity: update created" )
	end
end

function AreaEntity.streamOut ( element )
	AreaEntity:removeElement ( element )
	
	if AreaEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, AreaEntity.update )
		destroyElement ( AreaEntity.texture )
		destroyElement ( AreaEntity.iconTexture )
		outputDebugString ( "AreaEntity: update removed" )
	end
end

function AreaEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
	
	if collision then return element, collision end;
end

local boxSides = {
	{ -1, 0 },
	{ 1, 0 },
	{ 0, -1 },
	{ 0, 1 }
}
local _drawSide = dxDrawMaterialSectionLine3D

local function drawBox ( x, y, z, width, depth, height )
	local halfWidth, halfDepth, halfHeight = width/2, depth/2, height/2
	--x, y, z = x + halfWidth, y + halfDepth, z + halfHeight
	z = z + halfHeight
	
	for i, side in ipairs ( boxSides ) do
		local nextSide = i < 4 and boxSides [ i + 1 ] or boxSides [ 1 ]
		
		_drawSide ( 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z - halfHeight, 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z + halfHeight,
			1, 1, 256 * ( i > 2 and width or depth ), 256,
			AreaEntity.texture, i > 2 and width or depth, color.white, x, y, z
		)
	end
end

function AreaEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end

	for area, _ in pairs ( AreaEntity.elements ) do
		local x, y, z = getElementPosition ( area )
		local width, depth = tonumber ( getElementData ( area, "width" ) ), tonumber ( getElementData ( area, "depth" ) )
		
		if getElementData ( area, "no-fence" ) ~= "1" then
			drawBox ( x, y, z, width, depth, 1.2 )
		end
		dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, AreaEntity.iconTexture, 0.5, color.white )
	end
end