--[[
	Оффсеты камеры игрока:
		x, y, z = 0, -3.495, 0.774
		lx, ly, lz = 0, -2.496, 0.724
	Оффсеты авто игрока:
		x, y, z = 0, -8.100, 1.494
		lx, ly, lz = 0, -7.104, 1.398
]]


local cameraTask

addEventHandler ( "onClientPreRender", root,
	function ( )
		if not cameraTask then
			return
		end
		
		local now = getTickCount ( )
		local elapsedTime = now - cameraTask.startTime
		local duration = cameraTask.endTime - cameraTask.startTime
		local progress = elapsedTime / duration
		
		if cameraTask.isEnd ~= true then
			local x, y, z = interpolateBetween ( 
				cameraTask.startMatrix [ 1 ], cameraTask.startMatrix [ 2 ], cameraTask.startMatrix [ 3 ], 
				cameraTask.endMatrix [ 1 ], cameraTask.endMatrix [ 2 ], cameraTask.endMatrix [ 3 ], 
				progress, "Linear" 
			)
		
			local lx, ly, lz = getElementPosition ( localPlayer )
			
			setCameraMatrix ( x, y, z, lx, ly, lz )
		else
			local vx, vy, vz, lx, ly, lz
			
			local target = getPedOccupiedVehicle ( localPlayer ) or localPlayer
			
			if getElementType ( target ) == "vehicle" then
				--vx, vy, vz = getElementPositionByOffset ( vehicle, 0, -8.100, 1.494 )
				lx, ly, lz = getElementPositionByOffset ( target, 0, -7.104, 1.398 )
			else
				--vx, vy, vz = getElementPositionByOffset ( localPlayer, 0, -3.495, 0.774 )
				lx, ly, lz = getElementPositionByOffset ( target, 0, -2.496, 0.724 )
			end
		
			local ox, oy, oz = interpolateBetween ( 
				cameraTask.startPos [ 1 ], cameraTask.startPos [ 2 ], cameraTask.startPos [ 3 ], 
				cameraTask.endPos [ 1 ], cameraTask.endPos [ 2 ], cameraTask.endPos [ 3 ], 
				progress, "Linear" 
			)
			
			local x, y, z = getElementPositionByOffset ( target, ox, oy, oz )
			
			if progress > 1 then
				setCameraTarget ( localPlayer )
				cameraTask = nil
			else
				setCameraMatrix ( x, y, z, lx, ly, lz )
			end
		end
	end
)

function startCameraTask ( garage )
	local x, y, z, lx, ly, lz = getCameraMatrix ( )

	local gx, gy, gz = getElementPosition ( garage )
	garage = getElementParent ( garage )
	local gsx = tonumber ( getElementData ( garage, "width" ) )
	
	cameraTask = {
		startMatrix = { x, y, z, lx, ly, lz },
		endMatrix = { gx + (gsx/2), gy - 15, gz + 5 },
		startTime = getTickCount ( )
	}
	cameraTask.endTime = cameraTask.startTime + 1000
end

function stopCameraTask ( )
	if not cameraTask then
		return
	end
	
	local target = getPedOccupiedVehicle ( localPlayer ) or localPlayer
	
	local x, y, z = getElementPosition ( target )
	local cx, cy, cz = getCameraMatrix ( )
	
	cameraTask = { 
		startPos = { cx - x, cy - y, cz - z },
		startTime = getTickCount ( ),
		isEnd = true
	}
	cameraTask.endTime = cameraTask.startTime + 1000
	
	if isPedInVehicle ( localPlayer ) then
		cameraTask.endPos = { 0, -8.100, 1.494 }
	else
		cameraTask.endPos = { 0, -3.495, 0.774 }
	end
end

addEventHandler ( "onClientColShapeHit", resourceRoot,
	function ( element, matchingDimension )
		if getElementData ( source, "type" ) ~= 0 then
			return
		end
		
		if element ~= localPlayer then
			return
		end
	
		startCameraTask ( source )
	end
)

addEventHandler ( "onClientColShapeLeave", resourceRoot,
	function ( element, matchingDimension )
		if getElementData ( source, "type" ) ~= 0 then
			return
		end
		
		if element ~= localPlayer then
			return
		end
		
		stopCameraTask ( )
	end
)

function getElementPositionByOffset ( element, xOffset, yOffset, zOffset )
	local pX, pY, pZ

	local matrix = getElementMatrix ( element )
	
	if matrix then
		pX = xOffset * matrix [ 1 ] [ 1 ] + yOffset * matrix [ 2 ] [ 1 ] + zOffset * matrix [ 3 ] [ 1 ] + matrix [ 4 ] [ 1 ]
		pY = xOffset * matrix [ 1 ] [ 2 ] + yOffset * matrix [ 2 ] [ 2 ] + zOffset * matrix [ 3 ] [ 2 ] + matrix [ 4 ] [ 2 ]
		pZ = xOffset * matrix [ 1 ] [ 3 ] + yOffset * matrix [ 2 ] [ 3 ] + zOffset * matrix [ 3 ] [ 3 ] + matrix [ 4 ] [ 3 ]
	else
		pX, pY, pZ = getElementPosition ( element )
	end
	
	return pX, pY, pZ
end

setCameraTarget ( localPlayer )
