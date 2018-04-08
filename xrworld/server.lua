addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, object in ipairs ( getElementsByType ( "object", resourceRoot ) ) do
			local lodModel = getElementData ( object, "lod", false )
			if lodModel then
				local x, y, z = getElementPosition ( object )
				local rx, ry, rz = getElementRotation ( object )
				local lodObj = createObject ( tonumber ( lodModel ), x, y, z, rx, ry, rz, true )
				setLowLODElement ( object, lodObj )
			end
		end
	end
, false )