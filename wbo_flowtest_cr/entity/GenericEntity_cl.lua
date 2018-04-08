GenericEntity = GameEntity.create ( )

function GenericEntity.create ( x, y, z, rx, ry, rz, rz, scale )
	local spawnpoint = createElement ( "wbo:generic" )
	
	setElementPosition ( spawnpoint, x, y, z )
	setElementData ( spawnpoint, "posX", x, false )
	setElementData ( spawnpoint, "posY", y, false )
	setElementData ( spawnpoint, "posZ", z, false )
	setElementData ( spawnpoint, "rotX", rx, false )
	setElementData ( spawnpoint, "rotY", ry, false )
	setElementData ( spawnpoint, "rotZ", rz, false )
	setElementData ( spawnpoint, "scale", scale, false )
	setElementData ( spawnpoint, "model", "0", false )
	setElementData ( spawnpoint, "dimension", getElementDimension ( localPlayer ), false )
	
	return spawnpoint
end

function GenericEntity.destroy ( element )
	
end

function GenericEntity.streamIn ( element )
	GenericEntity:addElement ( element )
	
	if GenericEntity.refs == 1 then
		GenericEntity.texture = dxCreateTexture ( "images/Farm-Fresh_tree.png" )
		GenericEntity.brick = dxCreateTexture ( "images/Brick.png" )
		addEventHandler ( "onClientPreRender", root, GenericEntity.update, false )
		
		outputDebugString ( "GenericEntity: update created" )
	end
end

function GenericEntity.streamOut ( element )
	GenericEntity:removeElement ( element )
	
	if GenericEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, GenericEntity.update )
		destroyElement ( GenericEntity.texture )
		destroyElement ( GenericEntity.brick )
		outputDebugString ( "GenericEntity: update removed" )
	end
end

function GenericEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )

	if collision then return element, collision end;
end

function GenericEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	local cx, cy, cz = getCameraMatrix ( )
	
	for gen, _ in pairs ( GenericEntity.elements ) do
		local x, y, z = getElementPosition ( gen )
		local name = getElementData ( gen, "model" )
		
		if name:find ( "trees\\" ) then
			dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, GenericEntity.texture, 0.5, color.white )
		else
			dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, GenericEntity.brick, 0.5, color.white )
		end
		
		if Editor.editMode and isLineOfSightClear ( cx, cy, cz, x, y, z, false, false, false, true, false ) then
			local sx, sy = getScreenFromWorldPosition ( x, y, z + 0.3 )
			if sx then
				local strHalfWidth = dxGetTextWidth ( name ) / 2
			
				--local dist = getDistanceBetweenPoints3D ( cx, cy, cz, x, y, z )
				--local scale = ( 80 - dist ) / 80
				
				dxDrawText ( name, sx - strHalfWidth, sy, sx + strHalfWidth, sy, color.white, 1, "default", "center" )
			end
		end
	end
end