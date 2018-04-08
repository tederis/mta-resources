------------------------------------
-- World группа                   --
-- Мировые компоненты             --
------------------------------------

--[[
	Button
]]
NodeRef "Button" { 
	events = {
		target = "object",
		outputs = {
			{ "onDown", "any" },
			{ "onUp", "any" },
			{ "Player", "player" },
			{ "ActionIndex", "number" }
		}
	}
}

addEvent ( "onButton", true )
addEventHandler ( "onButton", root,
	function ( player, state, actionIndex )
		--state = state and actionIndex or 0
			
		--[[local toggle = tonumber ( getElementData ( source, "tgl" ) ) or 0
		if toggle > 0 then
			local lastState = customData.getElementData ( source, "out.1" )
				
			state = lastState ~= state-- and actionIndex or 0
		end]]
		
		EventManager.triggerEvent ( source, "Button", 3, player )
		EventManager.triggerEvent ( source, "Button", 4, actionIndex )
		EventManager.triggerEvent ( source, "Button", state and 1 or 2, player )
	end 
)

--[[
	Marker
]]

NodeRef "Marker" {
	doVisible = function ( self )
		if _isElementPlayer ( self.bind ) then
			local vars = self.vars
			local blip = MarkerEntity.getBindedElement ( vars.target )
			if blip then setElementVisibleTo ( blip, self.bind, true ) end;
		end
	end,
	doInvisible = function ( self )
		if _isElementPlayer ( self.bind ) then
			local vars = self.vars
			local blip = MarkerEntity.getBindedElement ( vars.target )
			if blip then setElementVisibleTo ( blip, self.bind, false ) end;
		end
	end,

	events = {
		target = "tct-marker",
		inputs = {
			{ "doVisible", "any" },
			{ "doInvisible", "any" }
		},
		outputs = {
			{ "onHit", "player" },
			{ "onLeave", "player" }
		}
	}
}

--[[
	Laser
]]
NodeRef "Laser" { 
	events = {
		target = "object",
		outputs = {
			{ "onHit", "any" },
			{ "onLeave", "any" }
		}
	}
}

addEvent ( "onLaserStateChange", true )
addEventHandler ( "onLaserStateChange", resourceRoot,
	function ( newState )
		EventManager.triggerEvent ( source, "Laser", newState and 1 or 2 )
	end
)

--[[
	Checkpoint
]]
NodeRef "Checkpoint" { 
	doShow = function ( self )
		local vars = self.vars
		if vars.Player then
			CheckpointControl.create ( vars.target, vars.Player )
		end
	end,
	doHide = function ( self )
		local vars = self.vars
		
		if vars.Player then
			--CheckpointControl.destroy ( vars.target, vars.Player )
		end
	end,
	
	events = {
		target = "path",
		inputs = {
			{ "doShow", "any" },
			{ "doHide", "any" },
			{ "Player", "player" }
		},
		outputs = {
			{ "onReach", "number" },
			{ "onFinish", "player" },
			{ "Player", "element" }
		}
	}
}

--[[
	Spawnpoint
]]
local spawnedVehicles = { }
setTimer ( 
	function ( )
		for i = 1, #spawnedVehicles do
			local vehicle = spawnedVehicles [ i ]
			if isElement ( vehicle ) and getVehicleController ( vehicle ) == false  then
				destroyElement ( vehicle )
			end
		end
	end
, 1000, 0 )

local function spawnPlayerOnSpawnpoint ( player, spawnpoint, model )
	local x, y, z = getElementPosition ( spawnpoint )
	local rotz = tonumber ( 
		getElementData ( spawnpoint, "rotZ", false )
	)
	local dimension = tonumber (
		getElementData ( spawnpoint, "dimension", false )
	)
	setElementModel ( player, tonumber ( model ) or 0 )
	setElementPosition ( player, x, y, z )
	setPedRotation ( player, rotz or 0 )
	
	fadeCamera ( player, true, 1 )
end


NodeRef "Spawnpoint" { 
	doSpawn = function ( self )
		local vars = self.vars
		local x, y, z = getElementPosition ( vars.target )
		local dimension = getElementData ( vars.target, "dimension", false )
		
		-- Спавнить игрока?
		if _isElementPlayer ( vars.Player ) then
			-- ped
			if tonumber ( vars.Type ) > 0 then
				spawnPlayerSafe ( vars.Player, x, y, z, 0, tonumber ( vars.Model ) or randomPedModel ( ), 0, tonumber ( dimension ) or 0 )
			
			-- vehicle
			else
				--spawnPlayerSafe ( vars.Player, x + 4, y, z, 0, 0, 0, tonumber ( dimension ) or 0 )
	
				--[[local vehicle = createVehicle ( tonumber ( vars.Model ) or randomVehicleModel ( ), x, y, z )
				if vehicle then
					setElementDimension ( vehicle, tonumber ( dimension ) or 0 )
					setElementSyncer ( vehicle, false )
					warpPedIntoVehicle ( vars.Player, vehicle )
				end]]
			end
			--[[fadeCamera ( vars.Player, false, 1, 0, 0, 0 )
			setTimer ( 
				function ( )
					spawnPlayerOnSpawnpoint ( vars.Player, vars.target, vars.Model )
					self:triggerOutput ( 1, vars.Player )
				end
			, 1000, 1 )]]
			fadeCamera ( vars.Player, true )
			setCameraTarget ( vars.Player, vars.Player )
			showChat ( vars.Player, true )
		else
			
		end
	end,
	
	events = {
		target = "wbo:spawnpoint",
		inputs = {
			{ "doSpawn", "any", "Спавнит игрока" },
			{ "Player", "player", "Элемент игрока" },
			{ "Type", "_sptype" },
			{ "Model", "number" }
		},
		outputs = {
			{ "onSpawn", "element", "Вызывается каждый раз при спавне игрока и выдает его элемент в поток" }
		}
	}
}

--[[
	Zone
]]
--[[
NodeRef "Zone" { 
	events = {
		outputs = {
			{ "onHit", "element" },
			{ "onLeave", "element" }
		}
	}
}

addEventHandler ( "onColShapeHit", resourceRoot,
	function ( element, matchingDimension )
		--if not matchingDimension then return end;
		EventManager.triggerEvent ( source, "Zone", 1, element )
	end
, false )

addEventHandler ( "onElementColShapeLeave", root,
	function ( colShapeHit, matchingDimension )
		--if not matchingDimension then return end;
	
		EventManager.triggerEvent ( colShapeHit, "Zone", 2, source )
	end
, false )]]

local elementEnabledTo = { }

function setElementEnabledTo ( element, player, enabled )
	local players = elementEnabledTo [ element ]
	if players == nil then
		players = { }
		elementEnabledTo [ element ] = players
	end
	
	
end
function setElementDisabledTo ( element, player )
	local players = elementEnabledTo [ element ]
	if players then
		players [ player ] = nil
		triggerClientEvent ( player, "onClientElementEnabled", element, false )
	end
end
function isElementEnabledTo ( element, player )
	local players = elementEnabledTo [ element ]
	if players then
		return players [ player ] == true
	end
	
	return false
end

--[[
	Trigger
]]
NodeRef "Trigger" {
	doEnable = function ( self )
		if getElementType ( self.bind ) == "player" then
			local vars = self.vars
			setElementEnabledTo ( vars.target, self.bind )
		end
	end,
	doDisable = function ( self )
		if getElementType ( self.bind ) == "player" then
			local vars = self.vars
			setElementDisabledTo ( vars.target, self.bind )
		end
	end,
	
	events = {
		target = "wbo:trigger",
		inputs = {
			{ "doEnable", "any" },
			{ "doDisable", "any" }
		},
		outputs = {
			{ "onHit", "player" },
			{ "onLeave", "player" },
			{ "Players", "number" }
		}
	}
}

--[[
	Sign
]]
NodeRef "Sign" {
	doSet = function ( self )
		local vars = self.vars
		setElementData ( vars.target, "txt", tostring ( vars.Text ) )
	end,

	events = {
		target = "object",
		inputs = {
			{ "doSet", "any" },
			{ "Text", "string" }
		}
	}
}

--[[
	Area
]]
NodeRef "Area" {
	_target = function ( self, element )
		local players = getPlayersWithinArea ( element )
		self:triggerOutput ( 4, players )
	end,
	doFlashing = function ( self )
		local vars = self.vars
		setAreaFlashing ( vars.target, true )
	end,
	doNormal = function ( self )
		local vars = self.vars
		setAreaFlashing ( vars.target, false )
	end,
	doSetColor = function ( self )
		local vars = self.vars
		local color = vars.Color
		setAreaColor ( vars.target, color.r or 255, color.g or 0, color.b or 0, color.a or 170 )
	end,

	events = {
		target = "wbo:area",
		inputs = {
			{ "doFlashing", "any", "setAreaFlashing(@target,true);" },
			{ "doNormal", "any", "setAreaFlashing(@target,false);" },
			{ "doSetColor", "any" },
			{ "Color", "color" }
		},
		outputs = {
			{ "onHit", "player", "onAreaHit __element" },
			{ "onLeave", "player" },
			{ "onWasted", "player", "onPlayerWasted Killer" },
			{ "Players", "array" },
			{ "Killer", "entity" }
		}
	}
}

addEventHandler ( "onPlayerWasted", root,
	function ( totalAmmo, killer, killerWeapon, bodypart, stealth )
		local area = getPlayerArea ( source )
		if area then
			--[[local players = getPlayersWithinArea ( area )
			for i, player in ipairs ( players ) do
				if player == source then
					table.remove ( players, i )
				end
			end
			EventManager.triggerEvent ( area, "Area", 4, players )]]
			--if isElement ( killer ) then
				EventManager.triggerEvent ( area, "Area", 5, killer )
			--end
			EventManager.triggerEvent ( area, "Area", 3, source )
		end
	end
)

--[[
	_ActionEnt
]]
NodeRef "_ActionEnt" { 
	events = {
		target = "entity",
		outputs = {
			{ "onDown", "player" },
			{ "onUp", "player" },
			{ "onHit", "player" },
			{ "ActionIndex", "number" }
		}
	}
}

addEvent ( "onEntityAction", true )
addEventHandler ( "onEntityAction", resourceRoot,
	function ( player, state, actionIndex )
		--state = state and actionIndex or 0
			
		--[[local toggle = tonumber ( getElementData ( source, "tgl" ) ) or 0
		if toggle > 0 then
			local lastState = customData.getElementData ( source, "out.1" )
				
			state = lastState ~= state-- and actionIndex or 0
		end]]
		
		EventManager.triggerEvent ( source, "_ActionEnt", 4, actionIndex )
		EventManager.triggerEvent ( source, "_ActionEnt", state and 1 or 2, player )
	end 
)

--[[
	Вызывается при приближении игрока(client) к действию объекта
]]
addEventHandler ( "onEntityActionHit", resourceRoot,
	function ( )
		EventManager.triggerEvent ( source, "_ActionEnt", 3, client )
	end
)

--[[
	Blip
]]
NodeRef "Blip" {
	doVisible = function ( self )
		if _isElementPlayer ( self.bind ) then
			local vars = self.vars
			local blip = BlipEntity.getBindedElement ( vars.target )
			if blip then setElementVisibleTo ( blip, self.bind, true ) end;
		end
	end,
	doInvisible = function ( self )
		if _isElementPlayer ( self.bind ) then
			local vars = self.vars
			local blip = BlipEntity.getBindedElement ( vars.target )
			if blip then setElementVisibleTo ( blip, self.bind, false ) end;
		end
	end,

	events = {
		target = "tct-blip",
		inputs = {
			{ "doVisible", "any" },
			{ "doInvisible", "any" }
		}
	}
}