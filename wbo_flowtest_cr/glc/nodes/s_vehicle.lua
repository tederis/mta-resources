--------------------------
-- Vehicle группа       --
-- Работа с авто        --
--------------------------
--[[
	Vehicle:Vehicle
]]
NodeRef "Vehicle:Vehicle" {
	_target = function ( self, value )
		local controller = getVehicleController ( value )
		self:triggerOutput ( 7, controller )
	end,
	doBlow = function ( self )
		local vars = self.vars
		blowVehicle ( vars.target, true )
	end,
	doFix = function ( self )
		local vars = self.vars
		fixVehicle ( vars.target )
	end,
	doFlip = function ( self )
		local vars = self.vars
		local rX, rY, rZ = getElementRotation ( vars.target )
		setElementRotation ( vars.target, 0, 0, (rX > 90 and rX < 270) and (rZ + 180) or rZ )
	end,
	doSave = function ( self )
		local vars = self.vars
		local x, y, z = getElementPosition ( vars.target )
		setElementData ( vars.target, "posX", x )
		setElementData ( vars.target, "posY", y )
		setElementData ( vars.target, "posZ", z )
		local rx, ry, rz = getElementRotation ( vars.target )
		setElementData ( vars.target, "rotX", rx )
		setElementData ( vars.target, "rotY", ry )
		setElementData ( vars.target, "rotZ", rz )
	end,
	
	events = {
		target = "vehicle",
		inputs = {
			{ "doBlow", "any" },
			{ "doFix", "any" },
			{ "doFlip", "any" },
			{ "doSave", "any" }
		},
		outputs = {
			{ "onEnter", "player" },
			{ "onExit", "player" },
			{ "onStartEnter", "player" },
			{ "onStartExit", "player" },
			{ "Player", "player" },
			{ "Speed", "number" },
			{ "Controller", "player" }
		}
	}
}

local vehicleTimers = { }

local function getVehicleSpeed ( element )
	local vx, vy, vz = getElementVelocity ( element )
	return math.floor ( ( ( vx^2 + vy^2 + vz^2 ) ^ 0.5 ) * 161 )
end

local function onVehicleSpeedUpdate ( vehicle )
	if isElement ( vehicle ) ~= true or getVehicleController ( vehicle ) == false then
		killTimer ( vehicleTimers [ vehicle ] )
		vehicleTimers [ vehicle ] = nil
		return
	end
	local speed = getVehicleSpeed ( vehicle )
	EventManager.triggerEvent ( vehicle, "Vehicle:Vehicle", 6, speed )
end

addEventHandler ( "onVehicleEnter", resourceRoot,
	function ( thePlayer, seat, jacked )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 5, thePlayer )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 1, thePlayer )
		--vehicleTimers [ source ] = setTimer ( onVehicleSpeedUpdate, 1000, 0, source )
	end
)

addEventHandler ( "onVehicleExit", resourceRoot,
	function ( thePlayer, seat, jacker )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 5, thePlayer )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 2, thePlayer )
		if vehicleTimers [ source ] then
			--killTimer ( vehicleTimers [ source ] )
			--vehicleTimers [ source ] = nil
		end
	end
)

addEventHandler ( "onVehicleStartEnter", resourceRoot,
	function ( player, seat, jacked, door )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 5, player )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 3, player )
	end
)

addEventHandler ( "onVehicleStartExit", resourceRoot,
	function ( player, seat, jacked, door )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 5, player )
		EventManager.triggerEvent ( source, "Vehicle:Vehicle", 4, player )
	end
)

addEventHandler ( "onElementDestroy", resourceRoot,
	function ( )
		if getElementType ( source ) == "vehicle" then
			if vehicleTimers [ source ] then
				--killTimer ( vehicleTimers [ source ] )
				--vehicleTimers [ source ] = nil
			end
		end
	end
)

--[[
	Vehicle:Doors
]]

NodeRef "Vehicle:Doors" {
	doToggle = function ( self )
		local vars = self.vars
		local doorIndex = tonumber ( vars.Door )
		if doorIndex then
			doorIndex = math.clamp ( 0, doorIndex, 5 )
			local newState = getVehicleDoorOpenRatio ( vars.target, doorIndex ) > 0 and 0 or 1
			setVehicleDoorOpenRatio ( vars.target, doorIndex, newState, 1000 )
		end
	end,
	doOpen = function ( self )
		local vars = self.vars
		local doorIndex = tonumber ( vars.Door )
		if doorIndex then
			setVehicleDoorOpenRatio ( vars.target, math.clamp ( 0, doorIndex, 5 ), 1, 1000 )
		end
	end,
	doClose = function ( self )
		local vars = self.vars
		local doorIndex = tonumber ( vars.Door )
		if doorIndex then
			setVehicleDoorOpenRatio ( vars.target, math.clamp ( 0, doorIndex, 5 ), 0, 1000 )
		end
	end,
	
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any" },
			{ "doOpen", "any" },
			{ "doClose", "any" },
			{ "Door", "_door" }
		}
	}
}

--[[
	Vehicle:Locked
]]
NodeRef "Vehicle:Locked" {
	doToggle = function ( self )
		local vars = self.vars
		local newState = not isVehicleLocked ( vars.target )
		setVehicleLocked ( vars.target, newState )
		if newState then
			for i = 0, 5 do
				setVehicleDoorState ( vars.target, i, 0 )
			end
		end
		self:triggerOutput ( newState and 1 or 2 )
	end,
	doLock = function ( self )
		local vars = self.vars
		setVehicleLocked ( vars.target, true )
		for i = 0, 5 do
			setVehicleDoorState ( vars.target, i, 0 )
		end
		self:triggerOutput ( 1 )
	end,
	doUnlock = function ( self )
		local vars = self.vars
		setVehicleLocked ( vars.target, false )
		self:triggerOutput ( 2 )
	end,
	isLocked = function ( self )
		self:triggerOutput ( isVehicleLocked ( self.vars.target ) and 1 or 2 )
	end,
	
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any" },
			{ "doLock", "any" },
			{ "doUnlock", "any" },
			{ "isLocked", "any" }
		},
		outputs = {
			{ "onLocked", "any" },
			{ "onUnlocked", "any" }
		}
	}
}

--[[
	Vehicle:Sirens
]]
NodeRef "Vehicle:Sirens" {
	doToggle = function ( self )
		local vars = self.vars
		local newState = not getVehicleSirensOn ( vars.target )
		setVehicleSirensOn ( vars.target, newState )
	end,
	doOn = function ( self )
		local vars = self.vars
		setVehicleSirensOn ( vars.target, true )
	end,
	doOff = function ( self )
		local vars = self.vars
		setVehicleSirensOn ( vars.target, false )
	end,
	
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any" },
			{ "doOn", "any" },
			{ "doOff", "any" }
		}
	}
}

--[[
	Vehicle:Controls
]]
NodeRef "Vehicle:Controls" {
	events = {
		target = "vehicle",
		outputs = {
			{ "onKeyPress", "string" },
			{ "onKeyRelease", "string" }
		}
	}
}

local keyTable = { "mouse1", "mouse2", "mouse3", "mouse4", "mouse5", "mouse_wheel_up", "mouse_wheel_down", "arrow_l", "arrow_u",
 "arrow_r", "arrow_d", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
 "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "num_0", "num_1", "num_2", "num_3", "num_4", "num_5",
 "num_6", "num_7", "num_8", "num_9", "num_mul", "num_add", "num_sep", "num_sub", "num_div", "num_dec", "F1", "F2", "F3", "F4", "F5",
 "F6", "F7", "F8", "F9", "F10", "F11", "F12", "backspace", "tab", "lalt", "ralt", "enter", "space", "pgup", "pgdn", "end", "home",
 "insert", "delete", "lshift", "rshift", "lctrl", "rctrl", "[", "]", "pause", "capslock", "scroll", ";", ",", "-", ".", "/", "#", "\\", "=" }

local function _unbindAllKeys ( player )
	for _, keyName in ipairs ( keyTable ) do
		unbindKey ( player, keyName, "both", onVehicleKey )
	end
end
 
function onVehicleKey ( player, key, keyState, vehicle )
	if isElement ( vehicle ) then
		EventManager.triggerEvent ( vehicle, "Vehicle:Controls", keyState == "down" and 1 or 2, key )
	else
		_unbindAllKeys ( player )
	end
end

addEventHandler ( "onVehicleEnter", resourceRoot,
	function ( player, seat, jacked )
		if seat > 0 then return end;
		
		for _, keyName in ipairs ( keyTable ) do
			bindKey ( player, keyName, "both", onVehicleKey, source )
		end
	end
)

addEventHandler ( "onVehicleExit", resourceRoot,
	function ( player, seat, jacker )
		if seat > 0 then return end;
		
		_unbindAllKeys ( player )
	end
)

addEventHandler ( "onElementDestroy", resourceRoot,
	function ( )
		if getElementType ( source ) == "vehicle" then
			local player = getVehicleController ( source )
			if player then
				_unbindAllKeys ( player )
			end
		end
	end
)

--[[
	Vehicle:EngineState
]]
NodeRef "Vehicle:EngineState" {
	_target = function ( self, element )
		local state = getVehicleEngineState ( element )
		self:triggerOutput ( 1, state )
	end,
	doToggle = function ( self )
		local vars = self.vars
		local newState = not getVehicleEngineState ( vars.target )
		setVehicleEngineState ( vars.target, newState )
		self:triggerOutput ( 1, newState )
	end,
	doOn = function ( self )
		local vars = self.vars
		setVehicleEngineState ( vars.target, true )
		self:triggerOutput ( 1, true )
	end,
	doOff = function ( self )
		local vars = self.vars
		setVehicleEngineState ( vars.target, false )
		self:triggerOutput ( 1, false )
	end,

	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any" },
			{ "doOn", "any" },
			{ "doOff", "any" }
		},
		outputs = {
			{ "State", "bool" }
		}
	}
}

--[[
	Vehicle:OverrideLights
]]
NodeRef "Vehicle:OverrideLights" {
	doToggle = function ( self )
		local vars = self.vars
		local newState = getVehicleOverrideLights ( vars.target ) > 1 and 1 or 2
		setVehicleOverrideLights ( vars.target, newState )
	end,
	doOn = function ( self )
		local vars = self.vars
		setVehicleOverrideLights ( vars.target, 2 )
	end,
	doOff = function ( self )
		local vars = self.vars
		setVehicleOverrideLights ( vars.target, 1 )
	end,
	doReset = function ( self )
		local vars = self.vars
		setVehicleOverrideLights ( vars.target, 0 )
	end,

	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any" },
			{ "doOn", "any" },
			{ "doOff", "any" },
			{ "doReset", "any" }
		}
	}
}

--[[
	Vehicle:Paintjob
]]
NodeRef "Vehicle:Paintjob" {
	doSet = function ( self )
		local vars = self.vars
		local paintjobId = tonumber ( vars.Id )
		if paintjobId then
			setVehiclePaintjob ( vars.target, paintjobId )
		end
	end,

	events = {
		target = "vehicle",
		inputs = {
			{ "doSet", "any" },
			{ "Id", "number" }
		}
	}
}

--[[
	Vehicle:Upgrade
]]
NodeRef "Vehicle:Upgrade" {
	doAdd = function ( self )
		local vars = self.vars
		local upgradeId = tonumber ( vars.Id )
		if upgradeId then
			addVehicleUpgrade ( vars.target, upgradeId )
		end
	end,
	doRemove = function ( self )
		local vars = self.vars
		local upgradeId = tonumber ( vars.Id )
		if upgradeId then
			removeVehicleUpgrade ( vars.target, upgradeId )
		end
	end,

	events = {
		target = "vehicle",
		inputs = {
			{ "doAdd", "any" },
			{ "doRemove", "any" },
			{ "Id", "number" }
		}
	}
}

--[[
	Vehicle:Handling
]]
local _handlingProperties = {
	{ "mass" },
	{ "turnMass" },
	{ "dragCoeff" },
	--{ "centerOfMass" },
	{ "percentSubmerged" },
	{ "tractionMultiplier" },
	{ "tractionLoss" },
	{ "tractionBias" },
	{ "numberOfGears" },
	{ "maxVelocity" },
	{ "engineAcceleration" },
	{ "engineInertia" },
	--{ "driveType" },
	--{ "engineType" },
	{ "brakeDeceleration" },
	{ "brakeBias" },
	--{ "ABS" },
	{ "steeringLock" },
	{ "suspensionForceLevel" },
	{ "suspensionDamping" },
	{ "suspensionHighSpeedDamping" },
	{ "suspensionUpperLimit" },
	{ "suspensionLowerLimit" },
	{ "suspensionFrontRearBias" },
	{ "suspensionAntiDiveMultiplier" },
	{ "seatOffsetDistance" },
	{ "collisionDamageMultiplier" },
	--{ "monetary" },
	--{ "modelFlags" },
	--{ "handlingFlags" },
	--{ "headLight" },
	--{ "tailLight" },
	--{ "animGroup" }
}

NodeRef "Vehicle:Handling" {
	doSet = function ( self )
		local vars = self.vars
		local propertyIndex = tonumber ( vars.Property )
		if not propertyIndex then return end;
		
		local property = _handlingProperties [ propertyIndex ]
		if property then
			setVehicleHandling ( vars.target, property [ 1 ], tonumber ( vars.Value ) )
		end
	end,
	doReset = function ( self )
		local vars = self.vars
		local propertyIndex = tonumber ( vars.Property )
		if not propertyIndex then return end;
		
		local property = _handlingProperties [ propertyIndex ]
		if property then
			setVehicleHandling ( vars.target, property [ 1 ], nil, true )
		end
	end,

	events = {
		target = "vehicle",
		inputs = {
			{ "doSet", "any" },
			{ "doReset", "any" },
			{ "Property", "_handling" },
			{ "Value", "string" }
		}
	}
}

--[[
	Vehicle:Trailer
]]
NodeRef "Vehicle:Trailer" {
	_target = function ( self, element )
		local vehicle = getVehicleTowingVehicle ( element )
		if vehicle then self:triggerOutput ( 1, vehicle ) end;
		vehicle = getVehicleTowedByVehicle ( element )
		if vehicle then self:triggerOutput ( 2, vehicle ) end;
	end,
	doAttach = function ( self )
		local vars = self.vars
		if _isElementVehicle ( vars.Trailer ) then
			attachTrailerToVehicle ( vars.target, vars.Trailer )
		end
	end,
	doDetach = function ( self )
		local vars = self.vars
		detachTrailerFromVehicle ( vars.target )
	end,
	
	events = {
		target = "vehicle",
		inputs = {
			{ "doAttach", "any" },
			{ "doDetach", "any" },
			{ "Trailer", "vehicle" }
		},
		outputs = {
			{ "Towing", "vehicle" },
			{ "TowedBy", "vehicle" }
		}
	}
}

--[[
	Vehicle:Component
]]
NodeRef "Vehicle:Component" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doSetPos", "any" },
			{ "doSetRot", "any" },
			{ "Trailer", "vehicle" }
		},
		outputs = {
			{ "Towing", "vehicle" },
			{ "TowedBy", "vehicle" }
		}
	}
}