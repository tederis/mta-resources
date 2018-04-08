sound3D = { 
	items = { }
}

function sound3D.createAndAttachTo ( filename, element, looped )
	local filepath = "sound/" .. filename

	if not fileExists ( filepath ) then
		return
	end
	
	if sound3D.isAttachedTo ( element ) then
		if looped then
			return
		end

		sound3D.detachFrom ( element )
	end
	
	local x, y, z = getElementPosition ( element )
	sound3D.items [ element ] = playSound3D ( filepath, x, y, z, looped or false )
	setElementDimension ( sound3D.items [ element ], 
		getElementDimension ( element ) 
	)
		setElementInterior ( sound3D.items [ element ], 
		getElementInterior ( element ) 
	)
	
	setSoundMinDistance ( sound3D.items [ element ], 10 )
	setSoundMaxDistance ( sound3D.items [ element ], 100 )
		
	attachElements ( sound3D.items [ element ], element )
		
	return sound3D.items [ element ]
end

function sound3D.isAttachedTo ( element )
	return sound3D.items [ element ] ~= nil
end

function sound3D.detachFrom ( element )
	if sound3D.isAttachedTo ( element ) then
		stopSound ( sound3D.items [ element ] )
		sound3D.items [ element ] = nil
		
		return true
	end
	
	return false
end

addEvent ( "onClientElementAttachSound", true )
addEventHandler ( "onClientElementAttachSound", resourceRoot,
	function ( filename, looped )
		sound3D.createAndAttachTo ( filename, source, looped )
	end
)

addEvent ( "onClientElementDetachSound", true )
addEventHandler ( "onClientElementDetachSound", resourceRoot,
	function ( filename )
		sound3D.detachFrom ( source )
	end
)