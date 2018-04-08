addEvent ( "onClientEditorTargetChange", false )
addEvent ( "onClientTCTEditMode", false )

WBO_DEBUG_MODE = true

g_entityOffset = { 
	x = 0, y = 3, z = -1,
	rotx = 0, roty = 0, rotz = 0,
	scalex = 1, scaley = 1, scalez = 1,
	
	startx = 0, starty = 0, startz = 0,
	
	checkSum = 0,

	setStartPosition = function ( x, y, z )
		if x and z then
			g_entityOffset.startx = x
			g_entityOffset.starty = y
			g_entityOffset.startz = z
		end
	end,
	calcPosition = function ( startOrigin )
		if startOrigin then
			return g_entityOffset.startx + g_entityOffset.x, g_entityOffset.starty + g_entityOffset.y, g_entityOffset.startz + g_entityOffset.z
		else
			return getElementPositionByOffset ( localPlayer, g_entityOffset.x, g_entityOffset.y, g_entityOffset.z )
		end
	end,
	calcRotation = function ( addition )
		return g_entityOffset.rotx, g_entityOffset.roty, addition + g_entityOffset.rotz
	end,
	calcScale = function ( )
		return g_entityOffset.scalex, g_entityOffset.scaley, g_entityOffset.scalez
	end,
	calcMatrix = function ( self )
		local x, y, z = self.calcPosition ( )
		local rx, ry, rz = self.calcRotation ( getPedRotation ( localPlayer ) )
		
		return getMatrix ( x, y, z, rx, ry, rz )
	end,
	reset = function ( ox, oy, oz )
		g_entityOffset.x, g_entityOffset.y, g_entityOffset.z, g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz = ox, oy, oz, 0, 0, 0
		g_entityOffset.scalex, g_entityOffset.scaley, g_entityOffset.scalez = 1, 1, 1
		
		if Editor.target then
			--[[attachElements ( Editor.target, localPlayer, g_entityOffset.x, g_entityOffset.y, g_entityOffset.z, g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz )]]
		end
	end
}

Editor = { 
	gridVisible = true,
	editMode = false
}

editorSettings = {
	key_forward = "num_8",
	key_backward = "num_2",
	key_left = "num_4",
	key_right = "num_6",
	key_up = "num_add",
	key_down = "num_sub",
	key_place = "num_5",
	key_accept = "num_3",
	key_cancel = "num_dec",
	key_align = "z",
	key_editMode = "x",
	
	key_mode = "h",
	--key_snap = "space"
}

local lastCheck = getTickCount ( )

function Editor.onKey ( button, press )
	if button == editorSettings.key_editMode then
		showCursor ( press )
		Editor.editMode = press
		
		triggerEvent ( "onClientTCTEditMode", root, press )
		
		if press then
			g_entityOffset.x, g_entityOffset.y, g_entityOffset.z = 0, 0, 0
		elseif isElement ( Editor.target ) then
			local x, y, z = getElementPosition ( Editor.target )
			g_entityOffset.setStartPosition ( x, y, z )
		end
	elseif press == true or isMenuVisible ( ) then 
		return 
	end

	local freecam = getElementData ( localPlayer, "freecam:state" ) == true
	if Editor.target then
		if freecam and button == "mouse1" or button == editorSettings.key_place then
			-- Time protection and its exception for some tools(Grab)
			if getTickCount ( ) - lastCheck < 800 and getSelectedTool ( ).uninterrupted ~= true then
				outputChatBox ( "TCT: You must wait one second", 255, 0, 0 )
					
				return
			end
				
			getSelectedTool ( ):call ( "onPlace", Editor.target )
				
			if not getSettingByID ( "s_saveOffs" ):getData ( ) then
				if getElementData ( localPlayer, "freecam:state" ) then
					g_entityOffset.reset ( 0, 0, 0 )
				else
					g_entityOffset.reset ( 0, 3, -1 )
				end
			end
				
			lastCheck = getTickCount ( )
		elseif freecam and button == "mouse2" or button == editorSettings.key_cancel then
			setSelectedTool ( getToolFromName ( "Default" ) )
				
			for gridlist, _ in pairs ( bindedGridLists ) do
				guiGridListSetSelectedItem ( gridlist, -1, 0 )
			end
				
			guiGridListSetSelectedItem ( editorForm.toolsList, -1, 0 )
		elseif button == editorSettings.key_align then
			if isPedInVehicle ( localPlayer ) then
				return
			end
				
			setPedRotation ( localPlayer, getRotateValue ( getPedRotation ( localPlayer ) ) )
		end
			
		--if button == editorSettings.key_snap then
			--[[Editor.snappingMode = press
			EntitySnap.setTargetElement ( press and Editor.target or nil )]]
		--end
	elseif freecam and button == "mouse1" or button == editorSettings.key_accept then
		local target = GameManager.getTargetElement ( )
		if target then
			getSelectedTool ( ):call ( "onAccept", target )
		else
			getSelectedTool ( ):call ( "onWorldAccept" )
		end
	elseif button == editorSettings.key_mode then
		--toggleEditorMode ( not Tool.editorMode )
	end
end

function Editor.onPreRender ( )
	--[[local x, y, z, rx, ry, rz = getSnapPosition ( Editor.target )
	if getKeyState ( "b" ) or not x then
		x, y, z = g_entityOffset.calcPosition ( )
		rx, ry, rz = g_entityOffset.calcRotation ( )
	end]]
	
	if getElementData ( localPlayer, "freecam:state" ) then
		local x, y, z
		if isCursorShowing ( ) then
			x, y, z = getWorldCursorPosition ( )
		else
			x, y, z = g_entityOffset.calcPosition ( true )
		end
		setElementPosition ( Editor.target, x, y, z )
		local rx, ry, rz = g_entityOffset.calcRotation ( 0 )
		setElementRotation ( Editor.target, rx, ry, rz )
	else
		local x, y, z = g_entityOffset.calcPosition ( false )
		setElementPosition ( Editor.target, x, y, z )
		local rx, ry, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
		setElementRotation ( Editor.target, rx, ry, rz )
	end
	
	--local _off = g_entityOffset
	--local checkSum = _off.x + _off.y + _off.z + _off.rotx + _off.roty + _off.rotz + _off.scalex + _off.scaley + _off.scalez
	--if checkSum ~= g_entityOffset.checkSum then
		getSelectedTool ( ):call ( "onChangeOffset", Editor.target )
		--g_entityOffset.checkSum = checkSum
	--end
	
	if isElement ( Editor.target ) then
		if Editor.gridVisible then
			local x1, y1, z1 = getElementPosition ( Editor.target )
				
			--X
			dxDrawLine3D ( x1 - 10, y1, z1, x1 + 10, y1, z1, color.red, 2 )
			dxDrawLine3D ( x1 + 1, y1 - 0.2, z1, x1 + 1, y1 + 0.2, z1, color.red, 2 )
			dxDrawLine3D ( x1 + 2, y1 - 0.2, z1, x1 + 2, y1 + 0.2, z1, color.red, 2 )
			dxDrawLine3D ( x1 - 1, y1 - 0.2, z1, x1 - 1, y1 +  0.2, z1, color.red, 2 )
			dxDrawLine3D ( x1 - 2, y1 - 0.2, z1, x1 - 2, y1 + 0.2, z1, color.red, 2 )
			--Y
			dxDrawLine3D ( x1, y1 - 10, z1, x1, y1 + 10, z1, color.green, 2 )
			dxDrawLine3D ( x1 - 0.2, y1 + 1, z1, x1 + 0.2, y1 + 1, z1, color.green, 2 )
			dxDrawLine3D ( x1 - 0.2, y1 + 2, z1, x1 + 0.2, y1 + 2, z1, color.green, 2 )
			dxDrawLine3D ( x1 - 0.2, y1 - 1, z1, x1 + 0.2, y1 - 1, z1, color.green, 2 )
			--Z
			dxDrawLine3D ( x1, y1, z1 - 10, x1, y1, z1 + 10, color.blue, 2 )
			dxDrawLine3D ( x1 - 0.2, y1, z1 + 1, x1 + 0.2, y1, z1 + 1, color.blue, 2 )
			dxDrawLine3D ( x1 - 0.2, y1, z1 + 2, x1 + 0.2, y1, z1 + 2, color.blue, 2 )
			dxDrawLine3D ( x1 - 0.2, y1, z1 - 1, x1 + 0.2, y1, z1 - 1, color.blue, 2 )
		end
  
		local step = math.clamp ( getSettingByID ( "s_step" ):getData ( ), -100, 100 )
		if step then
			local altState = getKeyState ( "lalt" ) or getKeyState ( "ralt" )
			local zState = getKeyState ( "z" )
   
			if getKeyState ( editorSettings.key_up ) then --Z
				if altState then
					g_entityOffset.rotz = g_entityOffset.rotz + ( step * 4 )
				elseif zState then
					g_entityOffset.scalez = g_entityOffset.scalez + step
				else
					g_entityOffset.z = g_entityOffset.z + step
				end
			elseif getKeyState ( editorSettings.key_down ) then
				if altState then
					g_entityOffset.rotz = g_entityOffset.rotz - ( step * 4 )
				elseif zState then
					g_entityOffset.scalez = math.max ( g_entityOffset.scalez - step, 0 )
				else
					g_entityOffset.z = g_entityOffset.z - step
				end
			elseif getKeyState ( editorSettings.key_forward ) then --Y
				if altState then
					g_entityOffset.roty = g_entityOffset.roty + ( step * 4 )
				elseif zState then
					g_entityOffset.scaley = g_entityOffset.scaley + step
				else
					g_entityOffset.y = g_entityOffset.y + step
				end
			elseif getKeyState ( editorSettings.key_backward ) then
				if altState then
					g_entityOffset.roty = g_entityOffset.roty - ( step * 4 )
				elseif zState then
					g_entityOffset.scaley = math.max ( g_entityOffset.scaley - step, 0 )
				else
					g_entityOffset.y = g_entityOffset.y - step
				end
			elseif getKeyState ( editorSettings.key_right ) then --X
				if altState then
					g_entityOffset.rotx = g_entityOffset.rotx + ( step * 4 )
				elseif zState then
					g_entityOffset.scalex = g_entityOffset.scalex + step
				else
					g_entityOffset.x = g_entityOffset.x + step
				end
			elseif getKeyState ( editorSettings.key_left ) then
				if altState then
					g_entityOffset.rotx = g_entityOffset.rotx - ( step * 4 )
				elseif zState then
					g_entityOffset.scalex = math.max ( g_entityOffset.scalex - step, 0 )
				else
					g_entityOffset.x = g_entityOffset.x - step
				end
			end
		end
  
		--Rotation info
		dxDrawText( 
			math.floor ( g_entityOffset.rotx ) .. " / " .. 
			math.floor ( g_entityOffset.roty ) .. " / " .. 
			math.floor ( g_entityOffset.rotz ) , 0.02 * sw, 0.96 * sh, sw, sh, color.white, 1.5, "default-bold" )
	end
end
addEventHandler ( "onClientKey", root, Editor.onKey, false )

function Editor.onRender ( )
	if Editor.target then return end;
	
	local target = getPedTarget ( localPlayer )
	if target then
		local targetOwner = getElementData ( target, "owner" ) or "Console"
		local targetModel = getElementModel ( target ) or ""
		local targetInfo = targetOwner .. " / " .. targetModel
				
		dxDrawText ( targetInfo, 0.02 * sw, 0.96 * sh, sw, sh, color.white, 1.5, "default-bold" )
	end
end
addEventHandler ( "onClientRender", root, Editor.onRender, false )

function Editor.setTarget ( element )
	if Editor.target then
		destroyElement ( Editor.target )
		Editor.target = nil
		
		removeEventHandler ( "onClientPreRender", root, Editor.onPreRender )
	end
	
	if not getSettingByID ( "s_saveOffs" ):getData ( ) then
		if getElementData ( localPlayer, "freecam:state" ) then
			g_entityOffset.reset ( 0, 0, 0 )
		else
			g_entityOffset.reset ( 0, 3, -1 )
		end
	end
	
	if isElement ( element ) then
		local dimension = getElementDimension ( localPlayer )
		setElementDimension ( element, dimension )
	
		local interior = getElementInterior ( localPlayer )
		setElementInterior ( element, interior )
		
		setElementCollisionsEnabled ( element, false )
		
		Editor.target = element
		
		addEventHandler ( "onClientPreRender", root, Editor.onPreRender, false )
		
		triggerEvent ( "onClientEditorTargetChange", element )
	end
	
	EntitySnap.setTarget ( element )
end

function Editor.isElementOwner ( element, checkPermission )
	local owner = getElementData ( element, "owner" )
	
	return owner == Editor.accountName or ( checkPermission == true and Editor.permissionStatus )
end

function Editor.setVisibleGrid ( visible )
	Editor.gridVisible = visible
end

function toggleEditorMode ( enabled )
	if Tool.editorMode == enabled then
		return
	end
	
	Tool.editorMode = enabled
	
	for name, tool in pairs ( Tool.collection ) do
		tool:call ( "onEditorModeChange", enabled )
	end
end



function Editor.start ( )
	if Editor.started ~= true then
		loadTranslations ( "conf/translations.xml" )
		EntitySnap.loadModelsFromXml ( "conf/snapmodels.xml" )
			
		setTimer ( ModelReplacer.replace, 1000, 1, 1 )
		
		server = createServerCallInterface ( )
	
		createMainWindow ( )
		initTools ( )
		
		initObjectLODs ( )
		
		GameManager.create ( )
	
		Editor.started = true
	end
end


function createEntity ( model, x, y, z, rotx, roty, rotz )
	if model >= 0 and model <= 312 then
		return createPed ( model, x, y, z, rotz )
	elseif model >= 400 and model <= 611 then
		return createVehicle ( model, x, y, z, rotx, roty, rotz )
	else
		return createObject ( model, x, y, z, rotx, roty, rotz )
	end
end

addEventHandler ( "onClientPlayerTarget", localPlayer,
	function ( target )
		if Editor.started ~= true or getSettingByID ( "s_objinfo" ):getData ( ) ~= true then
			return
		end
		
		if not target then
			return
		end
		
		local model = getElementModel ( target )
		local x, y, z = getElementPosition ( target )
		local rx, ry, rz = getElementRotation ( target )
		local id = getElementID ( target )
		
		local strModel = "Model: " .. model .. ";"
		local strPos = "Pos: " .. x .. " ," .. y .. ", " .. z .. ";"
		local strRot = "Rot: " .. rx .. ", " .. ry .. ", " .. rz .. ";" 
		
		outputChatBox ( strModel )
		outputChatBox ( strPos )
		outputChatBox ( strRot )
	end
, false )

addCommandHandler ( "buildon",
	function ( _, x, y, z, rx, ry, rz )
		if tonumber ( x ) ~= nil and tonumber ( y ) ~= nil and tonumber ( z ) ~= nil then
			if isElement ( Editor.target ) then
				triggerServerEvent ( "onCreateTCTObject", resourceRoot, getElementModel ( Editor.target ), x, y, z, tonumber ( rx ) or 0, tonumber ( ry ) or 0, tonumber ( rz ) or 0, "1" )
			end
			Editor.setTarget ( )
		else
			outputChatBox ( "TCT: The correct syntax: /buildon x y z [rx ry rz]" )
		end
	end
)






EntitySnap = { 
	elements = { }
}
local snapmodels = { }
local getElementSnapPnts = function ( element )
	if isElement ( element ) then
		local model = getElementModel ( element )
		return snapmodels [ model ]
	end
end

function EntitySnap.loadModelsFromXml ( xmlpath )
	local xmlfile = getResourceConfig ( xmlpath )
	
	if not xmlfile then
		outputDebugString ( "Ошибка при загрузке " .. xmlpath, 2 )
	
		return
	end
	
	local i = 0
	local modelNode = xmlFindChild ( xmlfile, "model", 0 )
	while modelNode do
		local model = tonumber ( 
			xmlNodeGetAttribute ( modelNode, "model" ) 
		)
		
		snapmodels [ model ] = { }
		
		local j = 0
		local pointNode = xmlFindChild ( modelNode, "point", 0 )
		while pointNode do
			local x = xmlNodeGetAttribute ( pointNode, "x" )
			local y = xmlNodeGetAttribute ( pointNode, "y" )
			local z = xmlNodeGetAttribute ( pointNode, "z" )
			
			j = j + 1
			
			snapmodels [ model ] [ j ] = { 
				tonumber ( x ), tonumber ( y ), tonumber ( z ) 
			}
			
			pointNode = xmlFindChild ( modelNode, "point", j )
		end
		
		i = i + 1
		modelNode = xmlFindChild ( xmlfile, "model", i )
	end
end

function EntitySnap.setTarget ( element )
	--[[EntitySnap.target = nil
	if snapmodels [ getElementModel ( element ) ] ~= nil then
		EntitySnap.target = element
	end]]
end

local _dist3d = getDistanceBetweenPoints3D
function getSnapPosition ( element )
	local targetPnts = getElementSnapPnts ( element )
	if not targetPnts then 
		return false
	end
	EntitySnap.target = element
	
	local snapPosition = EntitySnap.snapPosition
	if snapPosition then
		return snapPosition [ 1 ], snapPosition [ 2 ], snapPosition [ 3 ], snapPosition [ 4 ], snapPosition [ 5 ], snapPosition [ 6 ]
	end
	
	return false
end

function EntitySnap.onUpdate ( )
	local elements = { }
	
	local px, py, pz = getElementPosition ( localPlayer )
	local objects = getElementsByType ( "object", resourceRoot, true )
	for i = 1, #objects do
		local object = objects [ i ] 
		local x, y, z = getElementPosition ( object )
		local snapPnts = getElementSnapPnts ( object )
		if _dist3d ( px, py, pz, x, y, z ) < 10 and snapPnts ~= nil then
			elements [ #elements + 1 ] = { element = object, pnts = snapPnts }
		end
	end
	EntitySnap.elements = elements
	
	if isElement ( EntitySnap.target ) ~= true then
		return
	end
	
	local minDist = 3000
	local minElement
	local minPnt
	local targetIndex
	local targetMatrix = g_entityOffset:calcMatrix ( )
	
	local targetPnts = getElementSnapPnts ( EntitySnap.target )
	for i = 1, #targetPnts do
		local targetPnt = targetPnts [ i ]
		local tx, ty, tz = getMatrixOffset ( targetMatrix, targetPnt [ 1 ], targetPnt [ 2 ], targetPnt [ 3 ] )
		
		for n = 1, #elements do
			local snap = elements [ n ]
			if snap.element ~= EntitySnap.target then
				for j = 1, #snap.pnts do
					local point = snap.pnts [ j ]
					local x, y, z = getElementPositionByOffset ( snap.element, point [ 1 ], point [ 2 ], point [ 3 ] )
			
					local dist = _dist3d ( tx, ty, tz, x, y, z )
					if dist < minDist then
						minDist = dist
						minElement = snap.element
						minPnt = j
						targetIndex = i
					end
				end
			end
		end
	end
	
	EntitySnap.snapPosition = nil
	if minDist < 0.5 then
		local trx, try, trz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
		local minMatrix = getElementMatrix ( minElement )

		targetMatrix [ 3 ] [ 1 ] = targetMatrix [ 3 ] [ 1 ] - minMatrix [ 3 ] [ 1 ]
		targetMatrix [ 3 ] [ 2 ] = targetMatrix [ 3 ] [ 2 ] - minMatrix [ 3 ] [ 2 ]
		targetMatrix [ 3 ] [ 3 ] = targetMatrix [ 3 ] [ 3 ] - minMatrix [ 3 ] [ 3 ]
			
		_, _, trv = getEulerAnglesFromMatrix ( 
			targetMatrix [ 1 ] [ 1 ] , targetMatrix [ 1 ] [ 2 ] , targetMatrix [ 1 ] [ 3 ], 
			targetMatrix [ 2 ] [ 1 ] , targetMatrix [ 2 ] [ 2 ] , targetMatrix [ 2 ] [ 3 ],
			targetMatrix [ 3 ] [ 3 ] , targetMatrix [ 3 ] [ 2 ] , targetMatrix [ 3 ] [ 3 ] 
		)
		
		local point = getElementSnapPnts ( minElement ) [ minPnt ]
		local tPoint = targetPnts [ targetIndex ]
		
		local px, py, pz = getElementPositionByOffset ( minElement, point [ 1 ], point [ 2 ], point [ 3 ] )
		
		local mat = getMatrix ( px, py, pz, trx, try, trv )
		gx, gy, gz = getMatrixOffset ( mat, -tPoint [ 1 ], -tPoint [ 2 ], -tPoint [ 3 ] )

		EntitySnap.snapPosition = {
			gx, gy, gz, trx, try, trv
		}
	end
end
setTimer ( EntitySnap.onUpdate, 100, 0 )

local _drawMaterialLine3D = dxDrawMaterialLine3D
local shader = dxCreateShader ( "shaders/snapbuffer.fx" )
local material = dxCreateTexture ( "textures/2425_nav_plain_green.png" )
dxSetShaderValue ( shader, "Tex", material )
function EntitySnap.onRender ( )
	--local objects = getElementsByType ( "object", resourceRoot, true )
	--dxDrawText ( #objects, 500, 500 )

	if isElement ( EntitySnap.target ) ~= true then
		return
	end

	local elements = EntitySnap.elements
	for i = 1, #elements do
		local snap = elements [ i ]
		if isElement ( snap.element ) then
			for j = 1, #snap.pnts do
				local point = snap.pnts [ j ]
				local x, y, z = getElementPositionByOffset ( snap.element, point [ 1 ], point [ 2 ], point [ 3 ] )
				_drawMaterialLine3D ( x, y - 0.05, z, x, y + 0.05, z, shader, 0.1 )
			end
		end
	end
end
addEventHandler ( "onClientPreRender", root, EntitySnap.onRender, false )


addEventHandler ( "onClientPedDamage", resourceRoot,
	function ( )
		if getElementData ( source, "protect" ) == "1" then
			cancelEvent ( )
		end
	end
)
addEventHandler ( "onClientPedChoke", resourceRoot,
	function ( )
		if getElementData ( source, "protect" ) == "1" then
			cancelEvent ( )
		end
	end
)

--[[
	EditorStartPacket
	Определяет набор функций, после инициализации которых запускается редактор
	Синтаксис: 
		EditorStartPacket "packetName" {
			handler = function ( acls )
				-- Something
			end
		}
]]
local startPacketDefs = { }
local startPacketsNum = 0

local _packedName
local _createStartPacket = function ( packetData )
	startPacketDefs [ _packedName ] = packetData
	-- Определяем количество пакетов, которые обязаны загрузиться перед запуском редактора
	startPacketsNum = startPacketsNum + 1
end
EditorStartPacket = function ( packetName )
	_packedName = packetName
	return _createStartPacket
end

local packetsReceived = 0
local function _onStartPacket ( packetName, ... )
	local startPacket = startPacketDefs [ packetName ]
	if startPacket then
		startPacket.handler ( ... )
		packetsReceived = packetsReceived + 1
		
		-- Если все зарегистрированные пакеты приняты
		if packetsReceived == startPacketsNum then
			removeEventHandler ( "onClientTCTStartPacket", resourceRoot, _onStartPacket )
			
			-- Запускаем все системы редактора
			Editor.start ( )
		end
	else
		outputDebugString ( "Пакета с именем " .. packetName .. " не существует", 2 )
	end
end
addEvent ( "onClientTCTStartPacket", true )
addEventHandler ( "onClientTCTStartPacket", resourceRoot, _onStartPacket, false )

local waterHeight = 0
local waterSize = 2998
local waterPlane = {
	swx = -waterSize,
	swy = -waterSize,
	sex = waterSize,
	sey = -waterSize,
	nwx = -waterSize,
	nwy = waterSize,
	nex = waterSize,
	ney = waterSize
}
local _water
local function removeAllWorldModels ( )
	for i = 550, 20000 do
		removeWorldModel ( i, 100000, 0, 0, 0 )
	end
	--setOcclusionsEnabled ( false )
	
	_water = createWater ( waterPlane.swx, waterPlane.swy, waterHeight, waterPlane.sex, waterPlane.sey, waterHeight, waterPlane.nwx, waterPlane.nwy, waterHeight, waterPlane.nex, waterPlane.ney, waterHeight )
	setWaterLevel ( waterHeight )
end

addEvent ( "onClientPlayerRoomChange", true )
addEventHandler ( "onClientPlayerRoomChange", localPlayer,
	function ( oldroom, newroom )
		local oldRoomWM 
		if isElement ( oldroom ) then
			oldRoomWM = getElementData ( oldroom, "no-wm", false )
		end
		local newRoomWM = getElementData ( newroom, "no-wm", false )
		if oldRoomWM ~= newRoomWM then
			if newRoomWM == "1" then
				removeAllWorldModels ( )
			else
				restoreAllWorldModels ( )
				if isElement ( _water ) then
					destroyElement ( _water )
				end
				resetWaterLevel ( )
				--setOcclusionsEnabled ( true )
			end
		end
	end
)

--[[
	Object LOD
]]
local _setupObjectLOD = function ( object )
	if getLowLODElement ( object ) ~= nil then
		return
	end

	local lodModel = tonumber ( getElementData ( object, "lod", false ) )
	if lodModel ~= nil then
		local x, y, z = getElementPosition ( object )
		local rx, ry, rz = getElementRotation ( object )
		local dimension = getElementDimension ( object )

		local lodObject = createObject ( lodModel, x, y, z, rx, ry, rz--[[, true]] )
		if lodObject then
			setElementDimension ( lodObject, dimension )
			setLowLODElement ( object, lodObject )
				
			--local lodDistance = getElementData ( object, "loddist", false )
			--engineSetModelLODDistance ( lodModel, tonumber ( lodDistance ) or 300 )
		end
	end
end

addEvent ( "onClientObjectLOD", true )
addEventHandler ( "onClientObjectLOD", resourceRoot,
	function ( )
		local lodModel = getElementData ( source, "lod", false )
		if lodModel then
			_setupObjectLOD ( source )
		else
			local lodObject = getLowLODElement ( source )
			if lodObject then
				destroyElement ( lodObject )
			end
		end
	end
)

function initObjectLODs ( )
	local objects = getElementsByType ( "object", resourceRoot )
	for i = 1, #objects do
		local object = objects [ i ]
		_setupObjectLOD ( object )
	end
end