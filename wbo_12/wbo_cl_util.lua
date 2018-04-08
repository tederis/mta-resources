sw, sh = guiGetScreenSize ( )

color = { 
	green = tocolor ( 0, 255, 0, 230 ),
	orangeLight = tocolor ( 255, 187, 0, 100 ),
	red = tocolor ( 255, 0, 0, 230 ),
	blue = tocolor ( 0, 0, 255, 230 ),
	text = tocolor ( 240, 248, 255, 240 ),
	black = tocolor ( 0, 0, 0, 255 ),
	white = tocolor ( 255, 255, 255, 255 ),
	aqua = tocolor ( 0, 255, 255, 255 ) 
}

function math.lerp ( from, alpha, to )
    return from + ( to - from ) * alpha
end

function math.unlerp ( from, pos, to )
	if to == from then
		return 1
	end
	return ( pos - from ) / ( to - from )
end

function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
end

function math.unlerpclamped ( from, pos, to )
	return math.clamp ( 0, math.unlerp ( from, pos, to ), 1 )
end

function math.round ( number, decimals, method )
    decimals = decimals or 0
    local factor = 10 ^ decimals
	
    if method == "ceil" or method == "floor" then 
		return math [ method ] ( number * factor ) / factor
    else 
		return tonumber ( ( "%." .. decimals .. "f" ):format ( number ) ) 
	end
end

function realToGui ( tlo, thi, value, bInt )
	local pos = math.unlerpclamped ( tlo, value, thi )
	local tvalue = math.lerp ( 0, pos, 100 )
	
	if bInt then
		tvalue = math.floor ( tvalue + 0.5 )
	end
	
	return tvalue
end

function guiToReal ( tlo, thi, value, bInt )
	local pos = math.unlerpclamped ( 0, value, 100 )
	local tvalue = math.lerp( tlo, pos, thi )

	if bInt then
		tvalue = math.floor ( tvalue + 0.5 )
	end
	
	return tvalue
end

function getRotateValue ( value )
	value = tonumber ( value )
	
	if not value then return false end
	
	local offset = tonumber ( 
		getSettingByID ( "s_rotoffset" ):getData ( ) 
	) or 0
	
	value = value + offset
	
	if value > 0 and value < 45 then
		value = 45
	elseif value > 46 and value < 90 then
		value = 90
	elseif value > 91 and value < 135 then
		value = 135
	elseif value > 136 and value < 180 then
		value = 180
	elseif value > 181 and value < 225 then
		value = 225
	elseif value > 226 and value < 270 then
		value = 270
	elseif value > 271 and value < 315 then
		value = 315
	elseif value > 316 and value < 360 then
		value = 360
	end
		
	return value
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		createMainWindow ( )
		initTools ( )
	end 
)

bindedGridLists = { }

function loadList ( file )
	local xml = getResourceConfig ( file )
	
	if xml then
		local result = { }
		
		for i, groupNode in pairs ( xmlNodeGetChildren ( xml ) ) do
			local group = { 
				name = xmlNodeGetAttribute ( groupNode, "name" )
			}
			
			for _, childNode in pairs ( xmlNodeGetChildren ( groupNode ) ) do
				local child = { 
					name = xmlNodeGetAttribute ( childNode, "name" ),
					model = xmlNodeGetAttribute ( childNode, "model" )
				}
				
				table.insert ( group, child )
			end
			
			table.insert ( result, group )
		end
		
		xmlUnloadFile ( xml )
		
		return result
	end
end

function guiGridListLoadTable ( gridlist, tbl, fn )
	bindedGridLists [ gridlist ] = tbl
	
	updateGridList ( gridlist, true )
	
	addEventHandler ( "onClientGUIClick", gridlist,
		function ( )
			local selectedRow = guiGridListGetSelectedItem ( source )
			
			if selectedRow > -1 then
				local name = guiGridListGetItemText ( source, selectedRow, 1 )
				
				if name == "..." then
					updateGridList ( source, true )
				else
					if guiGridListGetItemText ( source, 0, 1 ) ~= "..." then
						updateGridList ( source, false, selectedRow + 1 )
					else
						local model = guiGridListGetItemData ( source, selectedRow, 1 )
						fn ( source, model )
					end
				end
			end
		end
	, false )
end

function updateGridList ( gridlist, isGroup, index )
	guiGridListClear ( gridlist )
	
	if isGroup then
		for _, group in ipairs ( bindedGridLists [ gridlist ] ) do
			guiGridListSetItemText ( gridlist, guiGridListAddRow ( gridlist ), 1, group.name, false, false )
		end
	else
		if index then
			local row = guiGridListAddRow ( gridlist )
			guiGridListSetItemText ( gridlist, row, 1, "...", false, false )
			guiGridListSetItemColor ( gridlist, row, 1, 238, 216, 174, 255 )
			
			for _, child in ipairs ( bindedGridLists [ gridlist ] [ index ] ) do
				local row = guiGridListAddRow ( gridlist )
				guiGridListSetItemText ( gridlist, row, 1, child.name, false, false )
				guiGridListSetItemData ( gridlist, row, 1, child.model )
			end
		end
	end
end

addEventHandler ( "onClientElementDestroy", root, 
	function ( )
		local elementType = getElementType ( source )
		if ( elementType == "object" or elementType == "vehicle" ) and isElementLocal ( source ) then
			for _, element in ipairs ( getAttachedElements ( source ) ) do
				if isElement ( element ) then
					destroyElement ( element )
				end
			end
		end
	end
)

function getPedWorldTarget ( )
	local tx, ty, tz = getPedTargetEnd ( localPlayer )
		
	if tx then
		local sx, sy, sz = getCameraMatrix ( )
		local _, _, _, _, _, _, _, _, _, _, _, worldModelID = processLineOfSight ( sx, sy, sz, tx, ty, tz, true, false, false, false, false, true, false, true, localPlayer, true )
			
		if worldModelID then
			return worldModelID
		end
	end
end

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