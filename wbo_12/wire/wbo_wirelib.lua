Component = { 
	collection = { } }
Component.__index = Component

function Component.create ( name, desc )
	local component = { 
		name = name,
		desc = desc
	}
	
	Component.collection [ name ] = component
	
	return setmetatable ( component, Component )
end

function getComponentByTag ( tag )
	local foundComponent = Component.collection [ tag ]
	
	return foundComponent
end

function isComponent ( element )
	local tag = getElementData ( element, "tag" )
	
	return tag and getComponentByTag ( tag )
end

function getElementTag ( element )
	if isElement ( element ) then
		return getElementData ( element, "tag" )
	end
	
	return false
end

function getElementComponent ( element )
	local tag = getElementData ( element, "tag" )
	
	if Component.collection [ tag ] then
		return Component.collection [ tag ]
	end
	
	return false
end

function getComponentEvents ( element )
	local tag = getElementData ( element, "tag" )
	
	if Component.collection [ tag ] then
		return Component.collection [ tag ].events
	end
	
	return false
end

util = { }
function util.pack ( ... )
	return { ... }
end

function util.unpack ( tbl )
	return type ( tbl ) == "table" and unpack ( tbl ) or nil
end

------------------------------------
-- Button
------------------------------------
local sbutton = Component.create ( "sbutton", "Button" )

sbutton.events = {
	inputs = {
		{ "doPress", "number" }
	},
	
	outputs = {
		{ "onPressed", "number" }
	},
	
	inputHandler = function ( element, input, value )
		wireTriggerOutput ( element, 1, value )
	end
}

------------------------------------
-- Marker control
------------------------------------
local smarker = Component.create ( "smarker", "Marker control" )

smarker.events = {
	outputs = {
		{ "onHit", "number" }
	}
}

------------------------------------
-- Teleport
------------------------------------
local teleport = Component.create ( "teleport", "Teleport" )

function teleport.eventTeleport ( element, input, value )
	if value < 1 then return end

	local warpTo = getElementData ( element, "wrpTo" )
	if not warpTo then outputDebugString ( "Не существует параметра warpTo", 1 ) return end
                          
	warpTo = getElementByID ( warpTo )
	if not warpTo then outputDebugString ( "Целевого портала не существует", 1 ) return end
                          
	local posX, posY, posZ = getElementPosition ( warpTo )
	local dimension = getElementDimension ( warpTo )
                         
	local elementX, elementY, elementZ = getElementPosition ( element )
	local colshape = createColTube ( elementX, elementY, elementZ, 1.5, 2 )
                         
	for _, player in ipairs ( getElementsWithinColShape ( colshape, "player" ) ) do
		fadeCamera ( player, false, 1, 0, 0, 0 )
                          
		setTimer ( 
		function ( player, posX, posY, posZ, dimension )
			setElementDimension ( player, dimension )
			setElementPosition ( player, posX, posY, posZ + 1.5, true )
			fadeCamera ( player, true, 1 )
		end, 1000, 1, player, posX, posY, posZ, dimension )
		
		break
	end
                         
	destroyElement ( colshape )
end

teleport.events = {
	inputs = {
		{ "doTeleport", "number" }
	},
	
	inputHandler = teleport.eventTeleport
}

------------------------------------
-- Track control
------------------------------------
local track = Component.create ( "track", "Track control" )

function track.eventMove ( element, input, value )
	if value < 1 then 
		return 
	end
	
	local entity = getElementParent ( element )
	
	if input == 1 then
		if isObjectTrack ( entity ) then return end

		local nodes = getElementsByType ( "node", element )
		if #nodes < 2 then return end
	
		local currentNode = tonumber ( getElementData ( element, "node" ) ) or 1
		if #nodes > currentNode then
			trackObject ( entity, element, #nodes )
		else
			trackObject ( entity, element, 1 )
		end
	elseif input == 2 then
		if isObjectTrack ( entity ) then return end

		local nodes = getElementsByType ( "node", element )
		if #nodes < 1 or not nodes [ value ] then return end
	
		trackObject ( entity, element, value )
	elseif input == 3 then
		--if isObjectMove ( entity ) then return end

		--stopObject ( entity )
	end
end

track.events = {
	inputs = {
		{ "doMove", "number" },
		{ "doMoveNode", "number" },
		--{ "doMoveStop", "number" }
	},
	outputs = {
		{ "onNodeChange", "number" }
	},
	
	inputHandler = track.eventMove
}



------------------------------------
-- Magnet
------------------------------------
local magnet = Component.create ( "magnet", "Magnet" )
magnet.supportedTypes = { [ "vehicle" ] = true, [ "player" ] = true, [ "ped" ] = true }

function magnet.eventMagnet ( element, input, value )
	if value > 0 then
		local x, y, z = getElementPosition ( element )
		local rotvX, rotvY, rotvZ = getElementRotation ( element )
		local colshape = createColTube ( x, y, z - 3.5, 2.5, 3.5 )

		for _, elementCol in ipairs ( getElementsWithinColShape ( colshape ) ) do
			if magnet.supportedTypes [ getElementType ( elementCol ) ] then
				local rotpX, rotpY, rotpZ = getElementRotation ( elementCol )
                            
				attachElements ( elementCol, element, 0, 0, -1.3, rotpX - rotvX, rotpY - rotvY, rotpZ - rotvZ )
				break
			end
		end
                           
		destroyElement ( colshape )
	else
		for _, elAttach in ipairs ( getAttachedElements ( element ) ) do
			if isElement ( elAttach ) and magnet.supportedTypes [ getElementType ( elAttach ) ] then
				detachElements ( elAttach )
			end
		end
	end
end

magnet.events = {
	inputs = {
		{ "doMagnet", "number" }
	},
	
	inputHandler = magnet.eventMagnet
}

------------------------------------
-- Laser
------------------------------------
local laser = Component.create ( "laser", "Laser" )

laser.events = { 
	outputs = {
		{ "onHit", "number" }
	}
}

------------------------------------
-- Gate
------------------------------------
local gate = Component.create ( "gate", "Gate" )

function gate.getDesc ( element )
	return "Gate: " .. getElementData ( element, "gate" ) 
end

function gate.eventGateInput ( element, input, value )
	local gateType = getElementData ( element, "gate" )
	
	if not Gate [ gateType ] then
		outputDebugString ( "Такого гейта не существует или он не указан при создании", 2 )
		
		return
	end
	
	local ops = { }
	for i, _ in ipairs ( Gate [ gateType ].inputs ) do
		local inputValue = customData.getElementData ( element, "in." .. i )

		table.insert ( ops, 
			convertValueByType ( inputValue, "number" ) 
		)
	end
	
	local result = Gate [ gateType ].input ( element, unpack ( ops ) )
	
	wireTriggerOutput ( element, 1, result )
end

gate.events = {
	outputs = {
		{ "onResult", "number" }
	},
	
	inputHandler = gate.eventGateInput
}

------------------------------------
-- Dynamite
------------------------------------
local dynamite = Component.create ( "dynamite", "Dynamite" )

function dynamite.eventDetonate ( element, input, value )
	if value > 0 then
		local posX, posY, posZ = getElementPosition ( element )
		createExplosion ( posX, posY, posZ, 2 )
	end
end

dynamite.events = {
	inputs = {
		{ "doDetonate", "number" }
	},
	
	inputHandler = dynamite.eventDetonate
}

------------------------------------
-- Effect emitter
------------------------------------
local effectEmitter = Component.create ( "fxemitter", "Effect emitter" )

function effectEmitter.eventEffect ( element, input, value )
	if value > 0 then
		setElementData ( element, "emit", true )
	else
		setElementData ( element, "emit", false )
	end
end

effectEmitter.events = {
	inputs = {
		{ "doEffect", "number" }
	},
	
	inputHandler = effectEmitter.eventEffect
}

------------------------------------
-- Sound
------------------------------------
local sounds = {
	"siren2.ogg",
	"door_bell.ogg",
	"CB_Clap.wav",
	"CB_Hat.wav",
	"CB_Kick.wav",
	"CB_Snare.wav",
	"Clap Basic.wav",
	"Hat Basic.wav",
	"Kick Basic.wav",
	"Snare Basic.wav"
}

local sound = Component.create ( "sound", "Sound emitter" )

sound.events = {
	inputs = {
		{ "doEmit", "number" }
	},
	
	inputHandler = function ( element, input, value )
		if value < 1 then
			return
		end

		local looped = tonumber ( getElementData ( element, "lpd" ) ) == 1
		
		if looped and sound3D.isAttachedTo ( element ) then
			sound3D.detachFrom ( element )
			outputDebugString ( "sound detached")
			return
		end
		
		local soundIndex = tonumber ( 
			getElementData ( element, "snd" ) 
		)
		if sounds [ soundIndex ] then
			local filename = sounds [ soundIndex ]
			
			sound3D.createAndAttachTo ( filename, element, looped )
		else
			outputDebugString ( "звука не существует " .. tostring ( soundIndex ) )
		end
	end
}

------------------------------------
-- Monitor
------------------------------------
local monitor = Component.create ( "monitor", "Monitor" )

monitor.events = {
	inputs = {
		{ "doSetValue", "number" }
	},
	
	inputHandler = function ( element, input, value )
		setElementData ( element, "value", 
			util.pack ( tostring ( value ) ) 
		)
	end
}

------------------------------------
-- Door
------------------------------------
local door = Component.create ( "door", "Door" )

door.events = {
	inputs = {
		{ "doLock", "number" }
	},
	
	inputHandler = function ( element, input, value )
		setElementFrozen ( element, value > 0 )
	end
}

------------------------------------
-- Lamp
------------------------------------
local lamps = { }

local lamp = Component.create ( "lamp", "Lamp" )

lamp.events = {
	inputs = {
		{ "doOn", "number" }
	},
	
	inputHandler = function ( element, input, value )
		if value > 0 then
			if not lamps [ element ] then
				local x, y, z = getElementPosition ( element )
				local r, g, b = getElementData ( element, "cr" ),
					getElementData ( element, "cg" ),
					getElementData ( element, "cb" )
				
				lamps [ element ] = createMarker ( x, y, z, "corona", 0.8, r, g, b )
				attachElements ( lamps [ element ], element, 0, 0, -0.2 )
			end
		else
			if lamps [ element ] then
				destroyElement ( lamps [ element ] )
				lamps [ element ] = nil
			end
		end
	end
}

------------------------------------
-- Channel
------------------------------------
local keyToChannel = Component.create ( "kTChnel", "Channel: KeyToChannel" )

keyToChannel.outputs = { }
for i = 1, 10 do
	keyToChannel.outputs [ i ] = { "onEvent" .. i, "number" }
end

keyToChannel.events = {
	inputs = {
		{ "doEvent", "number" }
	},
	outputs = keyToChannel.outputs,
	
	inputHandler = function ( element, input, value, actionIndex )
		actionIndex = tonumber ( actionIndex )
		if actionIndex then
			if actionIndex < 1 or actionIndex > 10 then
				return
			end
			
			wireTriggerOutput ( element, actionIndex, value )
		end
	end
}

local channelToKey = Component.create ( "chnelTK", "Channel: ChannelToKey" )

channelToKey.inputs = { }
for i = 1, 10 do
	channelToKey.inputs [ i ] = { "doWork" .. i, "number" }
end

channelToKey.events = {
	inputs = channelToKey.inputs,
	outputs = {
		{ "onKey", "number" }
	},
	
	inputHandler = function ( element, input, value )
		wireTriggerOutput ( element, 1, value, input )
	end
}