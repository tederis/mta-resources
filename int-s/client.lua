----------------------------------------------
-- Взаимодействие с объектами               --
-- by XRAY                                  --
----------------------------------------------
local sw, sh = guiGetScreenSize ( )
local playerName = getPlayerName ( localPlayer )

local interactiveEntities = { }

color = {
	black = tocolor ( 0, 0, 0, 160 ),
	white = tocolor ( 255, 255, 255, 255 ),
	green = tocolor ( 0, 100, 0, 160 ),
	orange = tocolor ( 100, 100, 0, 255 )
}

local MIN_DIST = 1.7
local MAX_DIST = 10

local MAX_ITEMS = 5
local itemsMaxWidth = 0

local usableModels = { }
local selectedAction = 1
local caretIndex = 1
local lastEntity
local usableActions

addEventHandler ( "onClientRender", root,
	function ( )
		for _, entity in ipairs ( interactiveEntities ) do
			if isElement ( entity ) then
				local usable = getElementUsable ( entity )
				
				local posX, posY, posZ = getElementPosition ( entity )
				local usableOffset = usable.offset
				if usableOffset then
					local ox, oy, oz
					local offsetType = type ( usableOffset )
					if offsetType == "function" then
						ox, oy, oz = usableOffset ( entity )
					elseif offsetType == "table" then
						ox, oy, oz = usableOffset [ 1 ], usableOffset [ 2 ], usableOffset [ 3 ]
					end
				
					posX, posY, posZ = getElementPositionByOffset ( entity, ox or 0, oy or 0, oz or 0 )
				end
				posX, posY = getScreenFromWorldPosition ( posX, posY, posZ )

				if posX then
					--Если это ближайший к игроку элемент
					if entity == interactiveEntities.entity then
						local actions = usableActions or usable.actions
						
						local actionsNum = math.min ( MAX_ITEMS, #actions )
						local height = 25 * actionsNum
						
						dxDrawRectangle ( posX, posY + 5, #actions > MAX_ITEMS and itemsMaxWidth + 10 or itemsMaxWidth, height, color.black )
						for i = 1, actionsNum do
							local y = posY + 5 + ( 25 * (i-1) )
							
							if i == selectedAction then
								dxDrawRectangle ( posX, y, itemsMaxWidth, 25, color.green )
							end
							
							local itemIndex = ( i - 1 ) + caretIndex
							
							local actionName = actions [ itemIndex ]
							dxDrawText ( actionName, posX + 20, y, posX, y + 25, color.white, 1.5, "default-bold", "left", "center" )
						end
						
						if #actions > MAX_ITEMS then
							local itemIndex = caretIndex - 1
							local itemsNum = #actions - MAX_ITEMS
							local factor = itemIndex / itemsNum
							
							local scrollHeight = 25
							local scrollOffset = ( height - scrollHeight ) * factor
							
							dxDrawRectangle ( posX + itemsMaxWidth, posY + 5, 10, height, color.black )
							dxDrawRectangle ( posX + itemsMaxWidth, posY + 5 + scrollOffset, 10, scrollHeight, color.orange )
						end
					end

					dxDrawImage ( posX - 17.5, posY, 35, 35, "image/interactive.png", 0, 0, 0 )
				end
			end
		end
	end
)

function makeUsable ( model, tbl )
	--local args = { ... }

	usableModels [ model ] = tbl
end

function isUsable ( element )
	if getElementData ( element, "itms" ) or usableModels [ getElementModel ( element ) ] then
		return true
	end
	
	return false
end

function getElementUsable ( element )
	if getElementData ( element, "itms" ) ~= false then
		return g_usableEntity
	end
	
	return usableModels [ getElementModel ( element ) ]
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		setupUsable ( )
	end
)
 
function getElementsByTypes ( ... )
	local elements = { }

	for _, prop in ipairs ( arg ) do
		for _, element in ipairs ( getElementsByType ( prop, root, true ) ) do
			if isUsable ( element ) then
				table.insert ( elements, element )
			end
		end
	end
	
	return elements
end

function update ( )
	local playerX, playerY, playerZ = getElementPosition ( localPlayer )
	local minDist = MAX_DIST
	local nearestEntity
		
	interactiveEntities = { 
		--Чистим таблицу активных элементов
	}
		
	if isPedInVehicle ( localPlayer ) then
		return
	end
		
	for _, entity in ipairs ( getElementsByTypes ( "object", "vehicle", "ped" ) ) do
		local usable = getElementUsable ( entity )
		if usable then
			local posX, posY, posZ = getElementPosition ( entity )
			
			local usableOffset = usable.offset
			if usableOffset then
				local ox, oy, oz
				local offsetType = type ( usableOffset )
				if offsetType == "function" then
					ox, oy, oz = usableOffset ( entity )
				elseif offsetType == "table" then
					ox, oy, oz = usableOffset [ 1 ], usableOffset [ 2 ], usableOffset [ 3 ]
				end
				
				posX, posY, posZ = getElementPositionByOffset ( entity, ox or 0, oy or 0, oz or 0 )
			end
			
			if isLineOfSightClear ( playerX, playerY, playerZ, posX, posY, posZ, true, true, false, true, true, false, false, entity ) then
				local distance = getDistanceBetweenPoints3D ( playerX, playerY, playerZ, posX, posY, posZ )
				if distance < MAX_DIST then
					if distance < minDist then
						minDist = distance
						nearestEntity = entity
					end
					
					table.insert ( interactiveEntities, entity )
				end
			end
		end
	end
	
	if minDist > MIN_DIST then nearestEntity = nil end;
		
	--if minDist < MIN_DIST then
		if lastEntity ~= nearestEntity then
			lastEntity = nearestEntity
			selectedAction = 1
			caretIndex = 1
			
			if nearestEntity then
				local usableModel = getElementUsable ( nearestEntity )
				if usableModel then
					usableActions = usableModel.getActions and usableModel.getActions ( nearestEntity ) or nil
				
					local actions = usableActions or usableModel.actions
					itemsMaxWidth = calcMaxWidth ( actions )
				
					triggerServerEvent ( "onEntityActionHit", nearestEntity )
				end
			end
		end
		
		interactiveEntities.entity = nearestEntity
	--end
end
setTimer ( update, 300, 0 )

addEventHandler ( "onClientKey", root,
	function ( key, state )
		if isMTAWindowActive ( ) or isCursorShowing ( ) then return end;
		if not interactiveEntities.entity then return end;
		
		if key == "e" then
			local itemIndex = ( selectedAction - 1 ) + caretIndex
			
			triggerServerEvent ( "onPlayerEntityUse", resourceRoot, interactiveEntities.entity, itemIndex, state )
		elseif state ~= true then
			return
		end
 
		if key == "mouse_wheel_up" then
			if selectedAction < 2 then
				caretIndex = math.max ( caretIndex - 1, 1 )
			end
			selectedAction = math.max ( selectedAction - 1, 1 )
		elseif key == "mouse_wheel_down" then
			local usableModel = usableModels [ getElementModel ( interactiveEntities.entity ) ]
			local actions = usableActions or usableModel.actions
			
			local visibleItemsNum = math.min ( #actions, MAX_ITEMS )
			
			if selectedAction == MAX_ITEMS and caretIndex + MAX_ITEMS <= #actions then
				caretIndex = math.min ( caretIndex + 1, #actions )
			end
			selectedAction = math.min ( selectedAction + 1, visibleItemsNum )
		end
	end 
)

function calcMaxWidth ( tbl )
	local maxWidth = 0

	for i, actionName in ipairs ( tbl ) do
		local width = dxGetTextWidth ( actionName, 1.5, "default-bold" )
		
		maxWidth = math.max ( maxWidth, width )
	end
	
	return maxWidth + 40
end

function getElementPositionByOffset ( element, offX, offY, offZ )
	local posX, posY, posZ = getElementPosition ( element )
	
	local center = getElementMatrix ( element )
	if center then
		posX = offX * center [ 1 ] [ 1 ] + offY * center [ 2 ] [ 1 ] + offZ * center [ 3 ] [ 1 ] + center [ 4 ] [ 1 ]
		posY = offX * center [ 1 ] [ 2 ] + offY * center [ 2 ] [ 2 ] + offZ * center [ 3 ] [ 2 ] + center [ 4 ] [ 2 ]
		posZ = offX * center [ 1 ] [ 3 ] + offY * center [ 2 ] [ 3 ] + offZ * center [ 3 ] [ 3 ] + center [ 4 ] [ 3 ]
	end
	
	return posX, posY, posZ
end

function getEasingProgress ( startTime, endTime )
	startTime, endTime = tonumber ( startTime ), tonumber ( endTime )
	
	if startTime and endTime then
		local now = getTickCount ( )
		local elapsedTime = now - startTime
		local duration = endTime - startTime
		
		return elapsedTime / duration
	end
	
	return false
end