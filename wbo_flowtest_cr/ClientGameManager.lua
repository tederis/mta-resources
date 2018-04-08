STREAMER_TIME = 300

GameManager = { }

-- Определения для кастомных сущностей
local entityReference

function GameManager.create ( )
	addEvent ( "onClientPlayerTCTTarget", false )

	-- Инициализируем стример для наших сущностей
	xrStreamerWorld.init ( )
	
	entityReference = {
		[ "empty" ] = EmptyEntity,
		[ "path:node" ] = PathEntity,
		[ "wbo:spawnpoint" ] = SpawnPointEntity,
		[ "wbo:trigger" ] = TriggerEntity,
		[ "tct-blip" ] = BlipEntity,
		[ "tct-marker" ] = MarkerEntity,
		[ "wbo:area" ] = AreaEntity,
		[ "wbo:generic" ] = GenericEntity,
		
		-- Wrappers
		[ "s_weapon" ] = WeaponEntity
	}
	
	for entityType, ref in pairs ( entityReference ) do
		if ref.wrapper ~= true then
			local elements = getElementsByType ( entityType, resourceRoot )
			for _, element in ipairs ( elements ) do
				xrStreamerWorld.addElement ( element )
			end
		end
	end
	
	addEventHandler ( "onClientRender", root, GameManager.updateStreamers, false )
end

function GameManager.updateStreamers ( )
	xrStreamerWorld.debugDraw ( )

	-- Обеспечиваем пульс с определенной частотой
	local now = getTickCount ( )
	if GameManager.lastTime and now - GameManager.lastTime < STREAMER_TIME then
		return
	end
	GameManager.lastTime = now

	-- Обновляем стример сущностей
	xrStreamerWorld.update ( )
	
	-- Вызываем событие при прицеливании на целевую сущность
	local target = GameManager.getTargetElement ( )
	if target ~= GameManager.lastTarget then
		GameManager.lastTarget = target
		triggerEvent ( "onClientPlayerTCTTarget", localPlayer, target )
	end
end

-- Вызывается из wbo_cl_util.lua
function GameManager.onElementChangePosition ( element )
	local elementType = getElementType ( element )
	local ref = entityReference [ elementType ]
	if ref and ref.wrapper ~= true then
		xrStreamerWorld.updateElement ( element )
	end
end

local _dist3d = getDistanceBetweenPoints3D
function GameManager.getTargetElement ( )
	local sx, sy, sz = getCameraMatrix ( )
	local lineStart = Vector3D:new ( sx, sy, sz )
	
	local tx, ty, tz
	local cdist
	local worstElement = getPedTarget ( localPlayer )
	if getElementData ( localPlayer, "freecam:state" ) then
		if isCursorShowing ( ) then
			local _, _, worldx, worldy, worldz = getCursorPosition ( )
			tx, ty, tz = worldx, worldy, worldz
			local hit, cx, cy, cz, elementHit = processLineOfSight ( sx, sy, sz, worldx, worldy, worldz )
			if hit then cdist = _dist3d ( sx, sy, sz, cx, cy, cz ) end;
			worstElement = elementHit
		end
	else
		tx, ty, tz = getPedTargetEnd ( localPlayer )
		local cx, cy, cz = getPedTargetCollision ( localPlayer )
		if cx then cdist = _dist3d ( sx, sy, sz, cx, cy, cz ) end;
	end
	local lineEnd = Vector3D:new ( tx, ty, tz )
	
	local dimension = getElementDimension ( localPlayer )
	
	for entityType, ref in pairs ( entityReference ) do
		for element, _ in pairs ( ref.elements ) do
			if ref.getDimension ( element ) == dimension then
				if ref.collisionTest then
					local pickedElement, collision = ref.collisionTest ( element, lineStart, lineEnd )
				
					--if ( cdist == nil and collision ) or ( collision and _dist3d ( sx, sy, sz, collision.x, collision.y, collision.z ) < cdist ) then
					if collision and ( cdist == nil or _dist3d ( sx, sy, sz, collision.x, collision.y, collision.z ) < cdist ) then
						return pickedElement
					end
				end
			end
		end
	end
	
	-- Если мы нашли объект, созданный в этом редакторе
	if isElement ( worstElement ) and getElementData ( worstElement, "posX", false ) ~= false then
		return worstElement
	end
end

function GameManager.getClickedElement ( )
	local sx, sy, sz = getCameraMatrix ( )
	local lineStart = Vector3D:new ( sx, sy, sz )
	
	local _, _, tx, ty, tz = getCursorPosition ( )
	local lineEnd = Vector3D:new ( tx, ty, tz )
	
	local hit, x, y, z, elementHit = processLineOfSight ( sx, sy, sz, tx, ty, tz )
	local cdist; if hit then cdist = _dist3d ( sx, sy, sz, x, y, z ) end;
	
	local dimension = getElementDimension ( localPlayer )
	
	for entityType, ref in pairs ( entityReference ) do
		for element, _ in pairs ( ref.elements ) do
			if ref.getDimension ( element ) == dimension then
				if ref.collisionTest then
					local pickedElement, collision = ref.collisionTest ( element, lineStart, lineEnd )

					--if ( cdist == nil and collision ) or ( collision and _dist3d ( sx, sy, sz, collision.x, collision.y, collision.z ) < cdist ) then
					if collision and ( cdist == nil or _dist3d ( sx, sy, sz, collision.x, collision.y, collision.z ) < cdist ) then
						return pickedElement
					end
				end
			end
		end
	end
	
	return elementHit
end

-- Функция для создания новой клиентской сущности
function GameManager.createEntity ( entityType, ... )
	local _entityRef = entityReference [ entityType ]
	if _entityRef == nil then return end;

	local entityElement = _entityRef.create ( ... )
	if entityElement then
		if _entityRef.wrapper ~= true then
			xrStreamerWorld.addElement ( entityElement )
		end
		
		return entityElement
	end
end

-- Вызывается при создании сущности на стороне сервера
addEvent ( "onClientElementCreate", true )
addEventHandler ( "onClientElementCreate", resourceRoot,
	function ( )
		local elementType = getElementType ( source )
		local ref = entityReference [ elementType ]
		if ref and ref.wrapper ~= true then
			xrStreamerWorld.addElement ( source )
		end
	end
)

-- Удаляем объект из стримера когда он нам уже не нужен
addEventHandler ( "onClientElementDestroy", resourceRoot,
	function ( )
		local elementType = getElementType ( source )
		local ref = entityReference [ elementType ]
		if ref and ref.wrapper ~= true then
			xrStreamerWorld.removeElement ( source )
		end
	end
)

function GameManager.isElementEntity ( element )
	return entityReference [ getElementType ( element ) ] ~= nil
end

function GameManager.streamInEntity ( element )
	if isElement ( element ) then
		local elementType = getElementType ( element )
		local ref = entityReference [ elementType ]
		if ref then
			ref.streamIn ( element )
		end
	end
end

function GameManager.streamOutEntity ( element )
	if isElement ( element ) then
		local elementType = getElementType ( element )
		local ref = entityReference [ elementType ]
		if ref then
			ref.streamOut ( element )
		end
	end
end


--[[
	DefaultStreamer
	Default MTA streamer wrapper
]]
DefaultStreamer = { 
	onUpdateStreamPosition = function ( ) end,
	subscribed = { }
}

function DefaultStreamer.addElement ( self, streamElement )
	if isElement ( streamElement.entity ) then
		self.subscribed [ streamElement.entity ] = streamElement
	end
end

function DefaultStreamer.removeElement ( self, streamElement )
	if isElement ( streamElement.entity ) then
		self.subscribed [ streamElement.entity ] = nil
	end
end

addEventHandler ( "onClientElementStreamIn", resourceRoot,
	function ( )
		local elementStreamer = DefaultStreamer.subscribed [ source ]
		if elementStreamer then
			elementStreamer:internalStreamIn ( )
		end
	end
)

addEventHandler ( "onClientElementStreamOut", resourceRoot,
	function ( )
		local elementStreamer = DefaultStreamer.subscribed [ source ]
		if elementStreamer then
			elementStreamer:internalStreamOut ( )
		end
	end
)

addEvent ( "onClientPlayerRoomChange", true )
addEventHandler ( "onClientPlayerRoomChange", localPlayer,
	function ( oldroom, newroom )
		if GameManager.entityStreamer then
			local dimension = getElementDimension ( newroom )
			GameManager.entityStreamer:setDimension ( dimension )
		end
	end
)