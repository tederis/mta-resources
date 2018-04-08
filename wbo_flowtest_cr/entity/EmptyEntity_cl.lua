EmptyEntity = GameEntity.create ( )

function EmptyEntity.create ( x, y, z )
	local empty = createElement ( "empty" )
	
	setElementPosition ( empty, x, y, z )
	setElementData ( empty, "posX", x )
	setElementData ( empty, "posY", y )
	setElementData ( empty, "posZ", z )
	setElementData ( empty, "md", "1" )
	
	return empty
end

function EmptyEntity.destroy ( element )
	
end

function EmptyEntity.streamIn ( element )
	EmptyEntity:addElement ( element )
	
	if EmptyEntity.refs == 1 then
		EmptyEntity.texture = dxCreateTexture ( "images/VisualBudgetSystemAnalyzeOne.png" )
		addEventHandler ( "onClientPreRender", root, EmptyEntity.update, false )
		
		outputDebugString ( "EmptyEntity: update created" )
	end
end

function EmptyEntity.streamOut ( element )
	EmptyEntity:removeElement ( element )
	
	if EmptyEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, EmptyEntity.update )
		destroyElement ( EmptyEntity.texture )
		outputDebugString ( "EmptyEntity: update removed" )
	end
end

function EmptyEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
	
	if collision then return element, collision end;
end

function EmptyEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	for empty, _ in pairs ( EmptyEntity.elements ) do
		local x, y, z = getElementPosition ( empty )
			
		--[[local sx, sy = getScreenFromWorldPosition ( x, y, z + 0.3 )
		if sx then
			local name = getElementData ( empty, "name" ) or ""
			local strHalfWidth = dxGetTextWidth ( name ) / 2
				
			local cx, cy, cz = getCameraMatrix ( )
			local dist = getDistanceBetweenPoints3D ( cx, cy, cz, x, y, z )
			local scale = ( 80 - dist ) / 80
				
			dxDrawText ( name, sx - strHalfWidth, sy, sx + strHalfWidth, sy, color.white, scale * 1.5, "default", "center" )
		end]]
			
		dxDrawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, EmptyEntity.texture, 0.5, color.white )
	end
end