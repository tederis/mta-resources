local vehicleIdleTime = { 
	items = { }
}

function vehicleIdleTime.update ( self, vehicle )
	if not self.items [ vehicle ] then
		self.items [ vehicle ] = { }
	end
	
	local vx, vy, vz = getElementVelocity ( vehicle )
	local isIdle = vx + vy + vz == 0 or getVehicleController ( vehicle ) == false
	
	if self.items [ vehicle ].status ~= isIdle then
		self.items [ vehicle ].status = isIdle
		
		setElementData ( vehicle, "idle", isIdle )
	end
end

setTimer (
	function ( )
		local vehicles = getElementsByType ( "vehicle", root )
		for _, vehicle in ipairs ( vehicles ) do
			vehicleIdleTime:update ( vehicle )
		end
	end
, 1000, 0 )

addEventHandler ( "onElementDestroy", root,
	function ( )
		if vehicleIdleTime.items [ source ] then
			vehicleIdleTime.items [ source ] = nil
		end
	end
)