PathEntity = GameEntity.create ( )
PathEntity.paths = { }

function PathEntity.create ( x, y, z )
	local node = createElement ( "path:node" )
	
	setElementPosition ( node, x, y, z )
	
	setElementData ( node, "posX", x )
	setElementData ( node, "posY", y )
	setElementData ( node, "posZ", z )
	setElementData ( node, "dimension", getElementDimension ( localPlayer ), false )
	
	--GameManager.setupElementStreamer ( node, PathEntity )
	
	return node
end

function PathEntity.destroy ( element )
	
end

function PathEntity.getPosition ( element )
	
end

function PathEntity.getDimension ( element )
	local parent = getElementParent ( element )
	return getElementDimension ( parent )
end

function PathEntity.streamIn ( element )
	local elementParent = getElementParent ( element )
	if getElementType ( elementParent ) ~= "path" then
		outputDebugString ( "PathEntity: элемент должен быть типа path", 2 )
		
		return
	end
	
	if not PathEntity.paths [ elementParent ] then PathEntity.paths [ elementParent ] = { } end;
	
	local index = tonumber ( 
		getElementData ( element, "index" )
	)

	PathEntity:addElement ( element )
	PathEntity.paths [ elementParent ] [ index ] = element
	
	if PathEntity.refs == 1 then
		PathEntity.startTexture = dxCreateTexture ( "images/2425_nav_plain_green.png" )
		PathEntity.texture = dxCreateTexture ( "images/2424_nav_plain_blue.png" )
		PathEntity.color = tocolor ( 0, 97, 188, 255 )
		addEventHandler ( "onClientPreRender", root, PathEntity.update, false, "low" )
		outputDebugString ( "PathEntity: update created" )
	end
end

function PathEntity.streamOut ( element )
	local elementParent = getElementParent ( element )
	if getElementType ( elementParent ) ~= "path" then
		outputDebugString ( "PathEntity: элемент должен быть типа path", 2 )
		
		return
	end
	
	if not PathEntity.paths [ elementParent ] then return end;

	local index = tonumber ( 
		getElementData ( element, "index" )
	)

	PathEntity:removeElement ( element )
	PathEntity.paths [ elementParent ] [ index ] = nil
	
	if PathEntity.refs < 1 then
		removeEventHandler ( "onClientPreRender", root, PathEntity.update )
		destroyElement ( PathEntity.startTexture )
		destroyElement ( PathEntity.texture )
		PathEntity.color = nil
		outputDebugString ( "PathEntity: update removed" )
		PathEntity.paths [ elementParent ] = nil
	end
end

function PathEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )
	local elementParent = getElementParent ( element )
	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.35 )
		
	if collision then return elementParent, collision end;
end

local _drawLine3D = dxDrawLine3D
local _drawMaterialLine3D = dxDrawMaterialLine3D
function PathEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
		
	for path, nodes in pairs ( PathEntity.paths ) do
		if isElement ( path ) then
			local looped = getElementData ( path, "loop" ) == "1"
		
			for i, node in pairs ( nodes ) do
				local x, y, z = getElementPosition ( node )
			
				local nextIndex = getElementData ( node, "nextIndex" )
				if nextIndex then
					nextIndex = tonumber ( nextIndex )
					if nodes [ nextIndex ] then
						local nx, ny, nz = getElementPosition ( nodes [ nextIndex ] )
						_drawLine3D ( x, y, z, nx, ny, nz, PathEntity.color, 3 )
					end
				
				-- Если это последний нод
				elseif looped and nodes [ 1 ] then
					local nx, ny, nz = getElementPosition ( nodes [ 1 ] )
					_drawLine3D ( x, y, z, nx, ny, nz, PathEntity.color, 3 )
				end

				_drawMaterialLine3D ( x, y, z + 0.25, x, y, z - 0.25, i > 1 and PathEntity.texture or PathEntity.startTexture, 0.5, color.white )
			
				--[[x, y = getScreenFromWorldPosition ( x, y, z )
				if x then
					dxDrawText ( getElementData ( node, "index" ), x, y )
				end]]
			end
		end
	end
end