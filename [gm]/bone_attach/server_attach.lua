local collection = { }

function attachElementToBone ( element, ped, bone, x, y, z, rx, ry, rz )
	if ( isElement ( element ) and getElementType ( element ) == "object" ) and ( isElement ( ped ) and getElementType ( ped ) == "player" ) then
		bone = tonumber ( bone )
		if bone and ( bone > 0 and bone < 21 ) then
			x, y, z, rx, ry, rz = tonumber ( x ) or 0,
								  tonumber ( y ) or 0,
								  tonumber ( z ) or 0,
								  tonumber ( rx ) or 0,
								  tonumber ( ry ) or 0,
								  tonumber ( rz ) or 0
			if x and y and z and rx and ry and rz then
				setElementPosition ( element, getElementPosition ( ped ) )
    
				collection [ element ] = { ped, bone, x, y, z, rx, ry, rz }
    
				triggerClientEvent ( "onClientAttachElementToBone", element, ped, bone, x, y, z, rx, ry, rz )
				
				return true
			end
		end
	end
	
	return false
end

function isElementAttachedToBone ( element )
	if isElement ( element ) and getElementType ( element ) == "object" then
		if collection [ element ] then
			return true
		end
	end
	
	return false
end

function detachElementFromBone ( element )
	if isElement ( element ) and getElementType ( element ) == "object" then  
		if collection [ element ] then
			collection [ element ] = nil
   
			triggerClientEvent ( "onClientAttachElementToBone", element )
			
			return true
		end
	end
	
	return false
end

addEventHandler ( "onElementDestroy", root,
	function ( )
		if collection [ source ] then
			collection [ source ] = nil
		end
	end
)