BlipEntity = GameEntity.create ( )

function BlipEntity.create ( x, y, z )
	local entity = createElement ( "tct-blip" )
	
	setElementPosition ( entity, x, y, z )
	setElementData ( entity, "posX", x )
	setElementData ( entity, "posY", y )
	setElementData ( entity, "posZ", z )
	
	return entity
end

function BlipEntity.destroy ( element )
	
end

function BlipEntity.streamIn ( element )
	BlipEntity:addElement ( element )
	
	if BlipEntity.refs == 1 then
		BlipEntity.texture = dxCreateTexture ( "images/man.png" )
		addEventHandler ( "onClientPreRender", root, BlipEntity.update, false )
		
		outputDebugString ( "BlipEntity: update created" )
	end
end

function BlipEntity.streamOut ( element )
	BlipEntity:removeElement ( element )
	
	if BlipEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, BlipEntity.update )
		destroyElement ( BlipEntity.texture )
		outputDebugString ( "BlipEntity: update removed" )
	end
end

function BlipEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
	
	if collision then return element, collision end;
end

function BlipEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	for empty, _ in pairs ( BlipEntity.elements ) do
		local x, y, z = getElementPosition ( empty )
		dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, BlipEntity.texture, 0.5, color.white )
	end
end