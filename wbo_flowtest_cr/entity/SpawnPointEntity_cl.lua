SpawnPointEntity = GameEntity.create ( )

function SpawnPointEntity.create ( x, y, z, rz )
	local spawnpoint = createElement ( "wbo:spawnpoint" )
	
	setElementPosition ( spawnpoint, x, y, z )
	setElementData ( spawnpoint, "posX", x, false )
	setElementData ( spawnpoint, "posY", y, false )
	setElementData ( spawnpoint, "posZ", z, false )
	setElementData ( spawnpoint, "rotZ", rz, false )
	setElementData ( spawnpoint, "type", "0", false )
	setElementData ( spawnpoint, "dimension", getElementDimension ( localPlayer ), false )
	
	return spawnpoint
end

function SpawnPointEntity.destroy ( element )
	
end

function SpawnPointEntity.streamIn ( element )
	SpawnPointEntity:addElement ( element )
	
	if SpawnPointEntity.refs == 1 then
		SpawnPointEntity.texturePlayer = dxCreateTexture ( "images/Character Editor.png" )
		SpawnPointEntity.textureVehicle = dxCreateTexture ( "images/Vehicle Editor.png" )
		addEventHandler ( "onClientPreRender", root, SpawnPointEntity.update, false )
		
		outputDebugString ( "SpawnPointEntity: update created" )
	end
end

function SpawnPointEntity.streamOut ( element )
	SpawnPointEntity:removeElement ( element )
	
	if SpawnPointEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, SpawnPointEntity.update )
		destroyElement ( SpawnPointEntity.texturePlayer )
		destroyElement ( SpawnPointEntity.textureVehicle )
		outputDebugString ( "SpawnPointEntity: update removed" )
	end
end

function SpawnPointEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )

	if collision then return element, collision end;
end

function SpawnPointEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	for spawnpoint, _ in pairs ( SpawnPointEntity.elements ) do
		local x, y, z = getElementPosition ( spawnpoint )
		local rz = tonumber ( 
			getElementData ( spawnpoint, "rotZ" ) 
		)
		
		local spawnpointType = getElementData ( spawnpoint, "type" )
		local texture = spawnpointType == "1" and SpawnPointEntity.texturePlayer or SpawnPointEntity.textureVehicle
		
		local tx, ty = getPointFromDistanceRotation ( x, y, 1, rz )
		
		dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, texture, 0.5, color.white, tx, ty, z )
	end
end