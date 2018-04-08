MarkerEntity = GameEntity.create ( )

--[[
function MarkerEntity.create ( x, y, z )
	local entity = createElement ( "tct-blip" )
	
	setElementPosition ( entity, x, y, z )
	setElementData ( entity, "posX", x )
	setElementData ( entity, "posY", y )
	setElementData ( entity, "posZ", z )
	
	return entity
end

function MarkerEntity.destroy ( element )
	
end
]]

function MarkerEntity.streamIn ( element )
	MarkerEntity:addElement ( element )
	
	if MarkerEntity.refs == 1 then
		MarkerEntity.texture = dxCreateTexture ( "images/flag.png" )
		addEventHandler ( "onClientPreRender", root, MarkerEntity.update, false )
		
		outputDebugString ( "MarkerEntity: update created" )
	end
end

function MarkerEntity.streamOut ( element )
	MarkerEntity:removeElement ( element )
	
	if MarkerEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, MarkerEntity.update )
		destroyElement ( MarkerEntity.texture )
		outputDebugString ( "MarkerEntity: update removed" )
	end
end

function MarkerEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
	
	if collision then return element, collision end;
end

function MarkerEntity.update ( )
	if getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	for empty, _ in pairs ( MarkerEntity.elements ) do
		local x, y, z = getElementPosition ( empty )
		dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, MarkerEntity.texture, 0.5, color.white )
	end
end