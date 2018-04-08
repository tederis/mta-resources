g_entityOffset = { 
	x = 0, y = 3, z = -1,
	rotx = 0, roty = 0, rotz = 0,
	
	checkSum = 0,
	
	calcPosition = function ( )
		return getElementPositionByOffset ( localPlayer, g_entityOffset.x, g_entityOffset.y, g_entityOffset.z )
	end,
	calcRotation = function ( )
		return g_entityOffset.rotx, g_entityOffset.roty, getPedRotation ( localPlayer ) + g_entityOffset.rotz
	end,
	reset = function ( )
		g_entityOffset.x, g_entityOffset.y, g_entityOffset.z, g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz = 0, 3, -1, 0, 0, 0
		
		if Tool.entity then
			attachElements ( Tool.entity, localPlayer, g_entityOffset.x, g_entityOffset.y, g_entityOffset.z, g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz )
		end
	end
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
	key_align = "z"
}

local lastCheck = getTickCount ( )

addEventHandler ( "onClientKey", root,
	function ( button, press )
		if press ~= true then return end
		
		if Tool.entity then
			if button == editorSettings.key_place then
				if getTickCount ( ) - lastCheck < 800 then
					outputChatBox ( "WBO: Вы должны подождать одну секунду", 255, 0, 0 )
					
					return
				end
				
				getSelectedTool ( ):call ( "onPlace", Tool.entity )
				
				if not getSettingByID ( "s_saveOffs" ):getData ( ) then
					g_entityOffset.reset ( )
				end
				
				lastCheck = getTickCount ( )
			elseif button == editorSettings.key_cancel then
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
		elseif button == editorSettings.key_accept then
			local target = getPedTarget ( localPlayer )
			if target then
				getSelectedTool ( ):call ( "onAccept", target )
			else
				getSelectedTool ( ):call ( "onWorldAccept" )
			end
		end
	end
)

local function onDefaultAffector ( key )
	local step = math.clamp ( getSettingByID ( "s_step" ):getData ( ), -100, 100 )
	if step then	
		local altState = getKeyState ( "lalt" ) or getKeyState ( "ralt" )
		
		if key == editorSettings.key_up then --Z
			if altState then
				g_entityOffset.rotz = g_entityOffset.rotz + ( step * 4 )
			else
				g_entityOffset.z = g_entityOffset.z + step
			end
		elseif key == editorSettings.key_down then
			if altState then
				g_entityOffset.rotz = g_entityOffset.rotz - ( step * 4 )
			else
				g_entityOffset.z = g_entityOffset.z - step
			end
		elseif key == editorSettings.key_forward then --Y
			if altState then
				g_entityOffset.roty = g_entityOffset.roty + ( step * 4 )
			else
				g_entityOffset.y = g_entityOffset.y + step
			end
		elseif key == editorSettings.key_backward then
			if altState then
				g_entityOffset.roty = g_entityOffset.roty - ( step * 4 )
			else
				g_entityOffset.y = g_entityOffset.y - step
			end
		elseif key == editorSettings.key_right then --X
			if altState then
				g_entityOffset.rotx = g_entityOffset.rotx + ( step * 4 )
			else
				g_entityOffset.x = g_entityOffset.x + step
			end
		elseif key == editorSettings.key_left then
			if altState then
				g_entityOffset.rotx = g_entityOffset.rotx - ( step * 4 )
			else
				g_entityOffset.x = g_entityOffset.x - step
			end
		end
		
		local checkSum = g_entityOffset.x + g_entityOffset.y + g_entityOffset.z + 
			g_entityOffset.rotx + g_entityOffset.roty + g_entityOffset.rotz
					
		if checkSum ~= g_entityOffset.checkSum then
			attachElements ( Tool.entity, localPlayer, 
				g_entityOffset.x, g_entityOffset.y, g_entityOffset.z,
				g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz )
							
			g_entityOffset.checkSum = checkSum
		end
	end
end

addEventHandler ( "onClientPreRender", root,
	function ( )
		if isElement ( Tool.entity ) then
			local elementType = getElementType ( Tool.entity )
			local elementModel = getElementModel ( Tool.entity )
  
			local x1, y1, z1 = getElementPosition ( Tool.entity )
				
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
  
			local tool = getSelectedTool ( )		
			for _, key in pairs ( editorSettings ) do
				if getKeyState ( key ) then
					if type ( tool.onAffect ) == "function" then
						tool:call ( "onAffect", key, onDefaultAffector )
					else
						onDefaultAffector ( key )
					end
				end
			end				
  
			--Rotation info
			dxDrawText( 
				math.floor ( g_entityOffset.rotx ) .. " / " .. 
				math.floor ( g_entityOffset.roty ) .. " / " .. 
				math.floor ( g_entityOffset.rotz ) , 0.02 * sw, 0.96 * sh, sw, sh, color.white, 1.5, "default-bold" )
		else
 
			--Target info
			local target = getPedTarget ( localPlayer ) or getPedWorldTarget ( )
 
			if target then
				local targetInfo = target
			
				if isElement ( targetInfo ) then
					local targetOwner = getElementData ( targetInfo, "owner" ) or "Console"
					local targetModel = getElementModel ( targetInfo ) or ""
				
					targetInfo = targetOwner .. " / " .. targetModel
				else
					targetInfo = "World / " .. targetInfo
				end
				
				dxDrawText ( targetInfo, 0.02 * sw, 0.96 * sh, sw, sh, color.white, 1.5, "default-bold" )
			end
		end
	end 
)

function setEditorTarget ( element )
	if isElement ( Tool.entity ) then
		if isElementLocal ( Tool.entity ) then
			destroyElement ( Tool.entity )
		else
			detachElements ( Tool.entity )
		end
		
		Tool.entity = nil
	end
	
	if not getSettingByID ( "s_saveOffs" ):getData ( ) then
		g_entityOffset.reset ( )
	end
	
	if isElement ( element ) then
		local dimension = getElementDimension ( localPlayer )
		setElementDimension ( element, dimension )
	
		local interior = getElementInterior ( localPlayer )
		setElementInterior ( element, interior )
	
		attachElements ( element, localPlayer, 
			g_entityOffset.x, g_entityOffset.y, g_entityOffset.z, 
			g_entityOffset.rotx, g_entityOffset.roty, g_entityOffset.rotz )
		Tool.entity = element
  
		return true
	end
	
	return false
end

function createEntity ( model, x, y, z, rotx, roty, rotz )
	if model >= 0 and model <= 312 then
		return createPed ( model, x, y, z, rotz )
	elseif model >= 400 and model <= 611 then
		--return createVehicle ( model, x, y, z, rotx, roty, rotz )
	else
		return createObject ( model, x, y, z, rotx, roty, rotz )
	end
end