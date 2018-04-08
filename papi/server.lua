addCommandHandler ( "firebin",
	function ( player )
		local x, y, z = getElementPosition ( player )
		local obj = createObject ( 3781, x, y + 1, z - 1 )
		triggerClientEvent ( "createFirebin", obj )
	end
)

addCommandHandler ( "ano1",
	function ( player )
		local x, y, z = getElementPosition ( player )
		triggerClientEvent ( "createAno1", root, x, y, z - 1 )
	end
)

addCommandHandler ( "ano2",
	function ( player )
		local x, y, z = getElementPosition ( player )
		triggerClientEvent ( "createAno2", root, x, y, z - 1 )
	end
)