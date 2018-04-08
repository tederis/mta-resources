---------------------------------------
-- Game группа                       --
-- Работа с внутриигровыми функциями --
---------------------------------------

--[[
	Game:Wasted
]]
--[[
NodeRef "Game:Wasted" { 
	name = "Wasted",
	group = "Game",
	dimension = "parent",
	events = {
		outputs = {
			{ "onWasted", "element" },
			{ "Killer", "element" }
		}
	}
}

addEventHandler ( "onPlayerWasted", root,
	function ( ammo, attacker, weapon, bodypart )
		local dimension = getElementDimension ( source )
		
		if dimension < 1 then
			--return
		end
	
		setTimer (
			function ( player, attacker, dimension )
				local dimensionStr = "room:" .. dimension
				EventManager.triggerEvent ( dimensionStr, "wstdevnt", 2, attacker )
				EventManager.triggerEvent ( dimensionStr, "wstdevnt", 1, player )
			end
		, 1000, 1, source, attacker, dimension )
	end
)]]

--[[
	Game:TextItem
]]
--[[
NodeRef "Game:TextItem" {
	events = {
		target = "player",
		inputs = {
			{ "doShow", "any" },
			{ "doHide", "any" },
			{ "Text", "string" },
			{ "Pos", "Vector2D" },
			{ "Scale", "number" },
			{ "Time", "number" }
		}
	}
}

local textItems = { }

function componentFnDef:txtitm ( input, value, args, cId )
	if input == 1 then
		if textItems [ cId ] then
			textItems [ cId ]:text ( tostring ( vars.Text ) )
			textItems [ cId ]:sync ( vars.target )
			return
		end
	
		local textPos = vars.Pos
	
		textItems [ cId ] = dxText:create( tostring ( vars.Text ), textPos.x, textPos.y, "default", vars.Scale )
		textItems [ cId ]:sync ( vars.target )
		
		if vars.Time > 50 then
			setTimer ( 
				function ( cId, player )
					if textItems [ cId ] then
						textItems [ cId ]:destroy ( )
						dxText.sync ( textItems [ cId ], player )
						textItems [ cId ] = nil
					end
				end
			, vars.Time, 1, cId, vars.target )
		end
	elseif input == 2 then
		if textItems [ cId ] then
			textItems [ cId ]:destroy ( )
			dxText.sync ( textItems [ cId ], vars.target )
			textItems [ cId ] = nil
		end
	end
end]]

--[[
	Game:ChatBox
]]
NodeRef "Game:ChatBox" { 
	doShow = function ( self, value )
		local vars = self.vars
		if isElement ( vars.Player ) then
			outputChatBox ( tostring ( vars.Message ), vars.Player )
		else
			outputChatBox ( tostring ( vars.Message ), root )
		end
	end,
	
	events = {
		--target = "player",
		inputs = {
			{ "doShow", "any", "outputChatBox(@Message,@Player);" },
			{ "Player", "player" },
			{ "Message", "string" }
		}
	}
}

--[[
	Game:GameRoom
]]
NodeRef "Game:GameRoom" {
	_target = function ( self, room )
		local players = RoomManager.getRoomPlayers ( room )
		self:triggerOutput ( 5, players )
	end,

	events = {
		target = "room",
		outputs = {
			{ "onPlayerJoin", "player" },
			{ "onPlayerQuit", "player" },
			{ "onPlayerWasted", "player" },
			{ "Player", "player" },
			{ "Players", "array" },
			{ "Killer", "player" }
		}
	}
}

addEventHandler ( "onPlayerWasted", root,
	function ( totalAmmo, killer, killerWeapon, bodypart, stealth )
		local room = RoomManager.getPlayerRoom ( source )
		if isElement ( killer ) then
			EventManager.triggerEvent ( room, "Game:GameRoom", 6, killer )
		end
		EventManager.triggerEvent ( room, "Game:GameRoom", 3, source )
	end
)

--[[
	Game:Countdown
]]
local roomCountdowns = { }
local onCountdownEnd = function ( room )
	local roomData = roomCountdowns [ room ]
	if roomData then
		roomData.node:triggerOutput ( 1 )
	end
	roomCountdowns [ room ] = nil
end

NodeRef "Game:Countdown" {
	doShow = function ( self )
		local vars = self.vars
		local currentRoom = self.graph.room
		
		if roomCountdowns [ currentRoom ] == nil then
			local countdown = Countdown.create ( 6, onCountdownEnd, nil, nil, nil, nil, nil, nil, nil, currentRoom )
			countdown:useImages ( 'images/countdown_%d.png', 474, 204 )
			countdown:enableFade(true)
			countdown:addClientHook(3, 'playSoundFrontEnd', 44)
			countdown:addClientHook(2, 'playSoundFrontEnd', 44)
			countdown:addClientHook(1, 'playSoundFrontEnd', 44)
			countdown:addClientHook(0, 'playSoundFrontEnd', 45)
			
			local players = RoomManager.getRoomPlayers ( currentRoom )
			for i = 1, #players do
				countdown:start ( players [ i ] )
			end
			
			roomCountdowns [ currentRoom ] = {
				countdown = countdown,
				node = self
			}
		end
	end,

	events = {
		inputs = {
			{ "doShow", "any" },
			{ "StartValue", "number" }
		},
		outputs = {
			{ "onStop", "any" }
		}
	}
}

--[[
	Game:GameMode
]]
--[[
local gameMode = { }

NodeRef "Game:GameMode" { 
	doStart = function ( self )
		if gameMode [ self.id ] then
			
		end
	end,
	
	doAddPlayer = function ( self )
		if not gameMode [ self.id ] then
			gameMode [ self.id ] = { 
				players = { },
				isStarted = false
			}
		end
		
		gameMode [ self.id ].players [ self.Player ] = true
	end,
	
	events = {
		inputs = {
			{ "doStart", "any" },
			{ "doStop", "any" },
			{ "doAddPlayer", "any" },
			{ "doRemovePlayer", "any" },
			{ "Player", "player" }
		},
		outputs = {
			{ "onStart", "any" },
			{ "onStop", "any" },
			{ "Players", "array" },
			{ "IsStarted", "bool" }
		}
	}
}

gamemodeItems = { }

function componentFnDef:gmmode ( input, value, args, thisNodeID )
	if input == 1 then
		if not gamemodeItems [ vars.target ] then
			gamemodeItems [ vars.target ] = { 
				playersNum = 0
			}
		end
		
		--outputChatBox("jjjjjjjjjjjj")
		if gamemodeItems [ vars.target ].playersNum < 1 then
			--outputChatBox("j")
			EventManager.triggerEvent ( thisNodeID, "gmmode", 1, 1 )
			EventManager.triggerEvent ( thisNodeID, "gmmode", 3, true )
		end
		
		if gamemodeItems [ vars.target ] [ value ] ~= nil then
			gamemodeItems [ vars.target ].playersNum = gamemodeItems [ vars.target ].playersNum + 1
		end
		
		gamemodeItems [ vars.target ] [ value ] = true
	elseif input == 2 then
		if not gamemodeItems [ vars.target ] then
			return
		end
		
		if gamemodeItems [ vars.target ] [ value ] then
			gamemodeItems [ vars.target ].playersNum = gamemodeItems [ vars.target ].playersNum - 1
		end
		
		if gamemodeItems [ vars.target ].playersNum < 1 then
			EventManager.triggerEvent ( thisNodeID, "gmmode", 2, 1 )
			EventManager.triggerEvent ( thisNodeID, "gmmode", 3, false )
		end
		
		gamemodeItems [ vars.target ] [ value ] = nil
	end
end]]

--[[
	Game:Time
]]
NodeRef "Game:Time" {
	_target = function ( self )
		local hours, minutes = getTime ( )
	
		self:triggerOutput ( 1, hours )
		self:triggerOutput ( 2, minutes )
	end,
	
	events = {
		outputs = {
			{ "Hours", "number" },
			{ "Minutes", "number" }
		}
	}
}

local lastTime
setTimer (
	function ( )
		local hours, minutes = getTime ( )
		
		if minutes ~= lastTime then
			lastTime = minutes

			--EventManager.triggerEvent ( mapRoot, "Time", 1, hours )
			--EventManager.triggerEvent ( mapRoot, "Time", 2, minutes )
		end
	end
, 1000, 0 )

--[[
	Game:Race
]]
--[[
NodeRef "Game:Race" {
	doStart = function ( self )
		local custom = self.custom
		if not custom.race then
			custom.race = RaceGamemode.create ( )
			
			local vars = self.vars
			
			local dimension = getElementData ( vars.target, "dimension" )
			local players = getPlayersInRoom ( dimension )
			
			if #vars.Spawnpoints > 0 and #players > 0 then
				custom.race:start ( vars.target, vars.Spawnpoints, { players [ 1 ] } )
			else
				outputDebugString ( "Мало спавнпоинтов или игроков")
			end
		end
	end,
	doAddPlayer = function ( self )
		local custom = self.custom
		local vars = self.vars
		
		if custom.race then
			custom.race:addPlayer ( vars.Player )
		end
	end,
	doRemovePlayer = function ( self )
		local custom = self.custom
		if custom.race then
			custom.race:removePlayer ( self.vars.Player )
		end
	end,
	
	events = {
		target = "path",
		inputs = {
			{ "doStart", "any" },
			{ "doStop", "any" },
			{ "doAddPlayer", "any" },
			{ "doRemovePlayer", "any" },
			{ "Spawnpoints", "array" },
			{ "Player", "player" }
		},
		outputs = {
			{ "onReachCheckpoint", "number" },
			{ "onFinish", "any" },
			{ "Player", "player" }
		}
	}
}

addEventHandler ( "onPlayerReachCheckpoint", root,
	function ( checkpointNum, path )
		EventManager.triggerEvent ( path, "Race", 3, source )
		EventManager.triggerEvent ( path, "Race", 1, checkpointNum )
	end
)

addEventHandler ( "onPlayerFinish", root,
	function ( path )
		EventManager.triggerEvent ( path, "Race", 3, source )
		EventManager.triggerEvent ( path, "Race", 2 )
	end
)]]

--[[
	Game:List
]]
--[[
NodeRef "Game:List" {
	events = {
		target = "player",
		inputs = {
			{ "doShow", "any" },
			{ "List", "array" }
		}
	}
}]]

--[[
	Game:Checkpoints
]]
NodeRef "Game:Checkpoints" {
	doShow = function ( self )
		
	end,
	doHide = function ( self )
		
	end,
	
	events = {
		target = "path",
		inputs = {
			{ "doShow", "any" },
			{ "doHide", "any" }
		},
		outputs = {
			{ "onReachCheckpoint", "number" },
			{ "onFinish", "any" },
			{ "Player", "player" }
		}
	}
}

addEventHandler ( "onPlayerReachCheckpoint", root,
	function ( checkpointNum, path )
		EventManager.triggerEvent ( path, "Race", 3, source )
		EventManager.triggerEvent ( path, "Race", 1, checkpointNum )
	end
)

addEventHandler ( "onPlayerFinish", root,
	function ( path )
		EventManager.triggerEvent ( path, "Race", 3, source )
		EventManager.triggerEvent ( path, "Race", 2 )
	end
)

--[[
	Game:Info
]]
NodeRef "Game:Info" {
	doSend = function ( self )
		local vars = self.vars
		triggerClientEvent ( vars.target, "onClientChangeInfo", resourceRoot, self.id, tostring ( vars.Text ) )
	end,

	events = {
		target = "player",
		inputs = {
			{ "doSend", "any", "showInfo(@Text);" },
			{ "Text", "string" }
		}
	}
}

--[[
	Game:SpawnPosition
]]
NodeRef "Game:SpawnPosition" {
	doSet = function ( self )
		local vars = self.vars
		local position = vars.Position
		if type ( position ) == "table" then
			--setPlayerSpawnPosition ( vars.target, tonumber ( position.x ) or 0, tonumber ( position.y ) or 0, tonumber ( position.z ) or 0 )
		end
	end,

	events = {
		target = "player",
		inputs = {
			{ "doSet", "any" },
			{ "Position", "Vector3D" }
		}
	}
}

--[[
	Game:Inventory
]]
NodeRef "Game:Inventory" {
	doGiveItem = function ( self )
		local vars = self.vars
		--exports.inventory_new:giveElementItem ( vars.target, vars.Item, vars.Amount )
	end,

	events = {
		target = "entity",
		inputs = {
			{ "doGiveItem", "any" },
			{ "doTakeItem", "any" },
			{ "Item", "string" },
			{ "Amount", "number" }
		}
	}
}

--[[
	Game:Keypad
]]
local keypadPending = { }

NodeRef "Game:Keypad" {
	doShow = function ( self, value )
		local vars = self.vars
		if _isElementPlayer ( vars.target ) then
			keypadPending [ vars.target ] = self
			triggerClientEvent ( vars.target, "onClientKeypadAction", resourceRoot )
		end
	end,

	events = {
		target = "player",
		inputs = {
			{ "doShow", "player" }
		},
		outputs = {
			{ "onInput", "string" },
			{ "Player", "player" }
		}
	}
}

addEvent ( "onKeypadAction", true )
addEventHandler ( "onKeypadAction", resourceRoot,
	function ( inputStr )
		local keypadNode = keypadPending [ client ]
		if type ( keypadNode ) == "table" and keypadNode.tag == "Game:Keypad" then
			keypadNode:triggerOutput ( 2, client )
			keypadNode:triggerOutput ( 1, inputStr )
		end
		keypadPending [ client ] = nil
	end
, false )

--[[
	Game:Menu
]]
local menuPending = { }
NodeRef "Game:Menu" {
	doOpen = function ( self )
		local vars = self.vars
		if menuPending [ vars.target ] then return end;
		
		
		local items = vars.Items
		if type ( items ) == "table" and #items > 0 then
			local out = { }
			for i = 1, #items do
				out [ #out + 1 ] = tostring ( items [ i ] [ 2 ] )
			end
			menuPending [ vars.target ] = self
			setElementVelocity ( getPedOccupiedVehicle ( vars.target ) or vars.target, 0, 0, 0 )
			triggerClientEvent ( vars.target, "onClientShowMenu", resourceRoot, out, tostring ( vars.Name ), vars.Keep == true )
		end
	end,

	events = {
		target = "player",
		inputs = {
			{ "doOpen", "any" },
			{ "Name", "string" },
			{ "Items", "_array" },
			{ "Keep", "bool" }
		},
		outputs = {
			{ "Key", "string" },
			{ "Value", "string" },
			{ "Index", "number" },
			{ "Player", "player" }
		}
	}
}

addEvent ( "onGameMenu", true )
addEventHandler ( "onGameMenu", resourceRoot,
	function ( selectedItem )
		local menuNode = menuPending [ client ]
		if menuNode then
			local items = menuNode.vars.Items
			local item = items [ selectedItem ]
			if item then
				menuNode:triggerOutput ( 4, client )
				menuNode:triggerOutput ( 1, item [ 1 ] )
				menuNode:triggerOutput ( 2, item [ 2 ] )
				menuNode:triggerOutput ( 3, selectedItem )
			end
			
			if selectedItem == 0 or menuNode.vars.Keep ~= true then
				menuPending [ client ] = nil
			end
		end
	end
, false )

--[[
	Game:Dialog
]]
local dialogPending = { }
NodeRef "Game:Dialog" {
	doOpen = function ( self )
		local vars = self.vars
		if dialogPending [ vars.target ] ~= nil then return end;
		
		local items = vars.Items
		if type ( items ) == "table" and #items > 0 and #items < 7 then
			local out = { }
			for i = 1, #items do
				out [ #out + 1 ] = tostring ( items [ i ] [ 2 ] )
			end
			dialogPending [ vars.target ] = self
			setElementVelocity ( getPedOccupiedVehicle ( vars.target ) or vars.target, 0, 0, 0 )
			triggerClientEvent ( vars.target, "onClientShowDialog", resourceRoot, out, tostring ( vars.Text ) )
		end
	end,

	events = {
		target = "player",
		inputs = {
			{ "doOpen", "any" },
			{ "Text", "string" },
			{ "Items", "_array" }
		},
		outputs = {
			{ "onSelect", "player" },
			{ "Index", "number" },
			{ "Player", "player" }
		}
	}
}

addEvent ( "onGameDialog", true )
addEventHandler ( "onGameDialog", resourceRoot,
	function ( selectedItem )
		local dialogNode = dialogPending [ client ]
		if dialogNode then
			dialogNode:triggerOutput ( 3, client )
			dialogNode:triggerOutput ( 2, selectedItem )
			dialogNode:triggerOutput ( 1, selectedItem )
		end
		dialogPending [ client ] = nil
	end
, false )

--[[
	Game:BindKey
]]
local keyTable = { "mouse1", "mouse2", "mouse3", "mouse4", "mouse5", "mouse_wheel_up", "mouse_wheel_down", "arrow_l", "arrow_u",
 "arrow_r", "arrow_d", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
 "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "num_0", "num_1", "num_2", "num_3", "num_4", "num_5",
 "num_6", "num_7", "num_8", "num_9", "num_mul", "num_add", "num_sep", "num_sub", "num_div", "num_dec", "F1", "F2", "F3", "F4", "F5",
 "F6", "F7", "F8", "F9", "F10", "F11", "F12", "backspace", "tab", "lalt", "ralt", "enter", "space", "pgup", "pgdn", "end", "home",
 "insert", "delete", "lshift", "rshift", "lctrl", "rctrl", "[", "]", "pause", "capslock", "scroll", ";", ",", "-", ".", "/", "#", "\\", "=" }

local keyBinds = { }
local function onKeyEvent ( player, key, keyState )
	local room = RoomManager.getElementRoom ( player )
	
	local roomKeys = keyBinds [ room ]
	if roomKeys then
		for key, nodes in pairs ( roomKeys ) do
			for i = 1, #nodes do
				nodes [ i ]:triggerOutput ( 3, player )
				nodes [ i ]:triggerOutput ( keyState == "down" and 1 or 2 )
			end
		end
	end
end
local function addBindedKey ( key, node )
	local room = node.graph.room
	
	if keyBinds [ room ] == nil then
		keyBinds [ room ] = { }
	end
	
	if keyBinds [ room ] [ key ] then
		-- На всякий случай проверяем есть ли уже нод для клавиши
		for _, keynode in ipairs ( keyBinds [ room ] [ key ] ) do
			if node == keynode then return end;
		end
		table.insert ( keyBinds [ room ] [ key ], node )
	else
		keyBinds [ room ] [ key ] = {
			node
		}
	end

	local players = getElementsByType ( "player" )
	for _, player in ipairs ( players ) do
		if RoomManager.isElementInRoom ( player, room ) then
			if isKeyBound ( player, key, onKeyEvent ) ~= true then
				bindKey ( player, key, "both", onKeyEvent )
				--outputChatBox ( key .. " binded" )
			end
		end
	end
end
local function removeBindedKey ( key, node )
	local room = node.graph.room
	if keyBinds [ room ] == nil then
		return
	end
	
	local nodes = keyBinds [ room ] [ key ]
	if nodes then
		for i, keynode in ipairs ( nodes ) do
			if node == keynode then 
				table.remove ( nodes, i )
				--outputChatBox ( key .. " unbinded")
			end
		end
	end
end

addEventHandler ( "onPlayerRoomJoin", root,
	function ( room )
		local roomKeys = keyBinds [ room ]
		if roomKeys then
			for key, _ in pairs ( roomKeys ) do
				if isKeyBound ( source, key, onKeyEvent ) ~= true then
					bindKey ( source, key, "both", onKeyEvent )
					--outputChatBox ( key .. " binded" )
				end
			end
		end
	end
)

addEventHandler ( "onPlayerRoomQuit", root,
	function ( room )
		local roomKeys = keyBinds [ room ]
		if roomKeys then
			for key, _ in pairs ( roomKeys ) do
				if isKeyBound ( source, key, onKeyEvent ) then
					unbindKey ( source, key, "both", onKeyEvent )
					--outputChatBox ( key .. " unbinded" )
				end
			end
		end
	end
)

 
NodeRef "Game:BindKey" {
	Key = function ( self )
		local vars = self.vars
		addBindedKey ( vars.Key, self )
	end,
	[ "~target" ] = function ( self, element )
		local vars = self.vars
		removeBindedKey ( vars.Key, self )
	end,

	events = {
		inputs = {
			{ "Key", "string" }
		},
		outputs = {
			{ "onKeyPress", "string" },
			{ "onKeyRelease", "string" },
			{ "Player", "player" }
		}
	}
}

--[[
	Game:Spawn
]]
NodeRef "Game:Spawn" {
	doSpawn = function ( self )
		local vars = self.vars
		local x, y, z = vars.Position.x, vars.Position.y, vars.Position.z
		local rotation = tonumber ( vars.Rotation ) or 0
		local skin = tonumber ( vars.Skin ); if isValidSkin ( skin ) ~= true then skin = 0 end;
		--spawnPlayer ( vars.target, x or 0, y or 0, z or 0, rotation, skin )
		--fadeCamera ( vars.target, true )
		--setCameraTarget ( vars.target, vars.target )
		--showChat ( vars.target, true )
	end,
	
	events = {
		target = "player",
		inputs = {
			{ "doSpawn", "any" },
			{ "Position", "Vector3D" },
			{ "Rotation", "number" },
			{ "Skin", "number" }
		}
	}
}

--[[
	Game:CommandHandler
]]
local playerCommandHandlers = { 
	--command1 = { [player1] = true, [player2] = true }
}
local onPlayerCommand = function ( player, commandName, ... )
	local players = playerCommandHandlers [ commandName ]
	if players then
		for _, player in ipairs ( players ) do
			local out = ArgStream:new ( ... )
			EventManager.triggerEvent ( player, "Game:CommandHandler", 1, out ) -- onEvent
		end
	end
end

NodeRef "Game:CommandHandler" {
	--[[doAdd = function ( self )
	
	end,
	doRemove = function ( self )
	
	end,]]
	_target = function ( self, player )
		local vars = self.vars
		local commandName = tostring ( vars.CommandName )
		
		local players = playerCommandHandlers [ commandName ]
		if players == nil then
			addCommandHandler ( commandName, onPlayerCommand )
			players = { }; playerCommandHandlers [ commandName ] = players;
			--outputChatBox ( "added command handler " .. commandName )
		end
		
		for i = 1, #players do
			if players [ i ] == player then
				return
			end
		end
		
		table.insert ( players, player )
	end,
	[ "~target" ] = function ( self, player )
		local vars = self.vars
		local commandName = tostring ( vars.CommandName )
		
		local players = playerCommandHandlers [ commandName ]
		if players then
			for i = 1, #players do
				if players [ i ] == player then
					table.remove ( players, i )
				end
			end
			
			if #players < 1 then
				removeCommandHandler ( commandName, onPlayerCommand )
				playerCommandHandlers [ commandName ] = nil
				--outputChatBox ( "removed command handler " .. commandName )
			end
		end
	end,

	events = {
		target = "player",
		inputs = {
			--{ "doAdd", "any" },
			--{ "doRemove", "any" },
			{ "CommandName", "string" }
		},
		outputs = {
			{ "onEvent", "stream" }
		}
	}
}