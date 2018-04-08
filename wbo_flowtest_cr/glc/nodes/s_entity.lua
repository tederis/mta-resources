---------------------------------------
-- Entity группа                     --
-- Ноды для работы с объектами       --
---------------------------------------

--[[
	Entity:Entity
]]

--[[NodeRef "Entity:Entity" {
	doCreate = function ( self )
		local vars = self.vars
		if string.len ( vars.Type ) > 0 then
			local element = createElement ( vars.Type )
			if element then
				setElementParent ( element, self:getRootElement ( ) )
				self:triggerOutput ( 2, element )
				self:triggerOutput ( 1, element )
			end
		end
	end,
	
	events = {
		inputs = {
			{ "doCreate", "any" },
			{ "Type", "string", READ_ONLY }
		},
		outputs = {
			{ "onCreate", "element" },
			{ "Element", "element" }
		}
	}
}]]

--[[
	Entity:Path
]]
-- Список обязательно дублируется на клиенте
local _easing = {
	"Linear",
	"InQuad",
	"OutQuad",
	"InOutQuad",
	"OutInQuad",
	"InElastic",
	"OutElastic",
	"InOutElastic",
	"OutInElastic",
	"InBack",
	"OutBack",
	"InOutBack",
	"OutInBack",
	"InBounce",
	"OutBounce",
	"InOutBounce",
	"OutInBounce",
	"SineCurve",
	"CosineCurve"
}

NodeRef "Entity:Path" {
	_target = function ( self, value )
		local nodes = getElementChildren ( value, "path:node" )
		
		self:triggerOutput ( 3, #nodes )
		--outputDebugString ( "set to node " .. #nodes)
	end,
	doMove = function ( self, value )
		local vars = self.vars
		
		if getElementType ( self.bind ) == "ped" then
			-- TODO
			return
		end

		-- Если объект к которому прикреплен граф уже движется по треку, выходим из функции
		if vars.Interruptible ~= true and isObjectTrack ( self.bind ) then return end;

		local nodes = getElementChildren ( vars.target, "path:node" )
		if #nodes < 2 then outputDebugString ( "Path node: в пути должно быть больше 2 нодов", 2 ) return end;

		local currentNodeIndex = getElementData ( self.bind, "node" )
		if currentNodeIndex then
			currentNodeIndex = currentNodeIndex [ 1 ]
		else
			currentNodeIndex = 1
		end
		
		local nextNodeIndex = #nodes > currentNodeIndex and #nodes or 1
		if vars.TargetNode > 0 then
			nextNodeIndex = vars.TargetNode
			if nextNodeIndex > #nodes then nextNodeIndex = nextNodeIndex - #nodes end;
			--outputChatBox ( "Custom node: " .. nextNodeIndex )
		end
		
		local easingType = _easing [ tonumber ( vars.Easing ) ]

		trackObject ( self.bind, vars.target, nextNodeIndex, vars.Time, easingType or "Linear" )
	end,
	doStop = function ( self, value )
		local vars = self.vars

		-- Если объект к которому прикреплен граф уже движется по треку, выходим из функции
		if isObjectTrack ( self.bind ) then return end;

		stopObject ( self.bind )
	end,
	
	events = {
		target = "path",
		inputs = {
			{ "doMove", "any" },
			{ "doStop", "any" },
			{ "Time", "number" },
			{ "TargetNode", "number" },
			{ "Interruptible", "bool" },
			{ "Easing", "_easing" }
		},
		outputs = {
			{ "onNodeChange", "number" },
			{ "onStop", "number" },
			{ "Nodes", "number" }
		}
	}
}

--[[
	Entity:Move
]]
NodeRef "Entity:Move" { 
	doMove = function ( self, value )
		local vars = self.vars
		
		-- Если объект нельзя перебивать и он уже движется, выходим из функции
		if vars.Interruptible ~= true and isObjectMove ( vars.target ) then return end;
	
		local x, y, z = getElementPosition ( vars.target )
		local dstPos = vars.Destination
		if dstPos then
			x, y, z = x + dstPos.x, y + dstPos.y, z + dstPos.z
		end
		local rot = vars.Rotation
		
		local easingType = _easing [ tonumber ( vars.Easing ) ]
	
		moveObject ( vars.target, math.max ( vars.Time, 100 ), x, y, z, rot.x or 0, rot.y or 0, rot.z or 0, easingType or "Linear" )
	end,
	doStop = function ( self )
		local vars = self.vars
		if vars.Interruptible then
			stopObject ( vars.target )
		end
	end,
	
	events = {
		target = "object",
		inputs = {
			{ "doMove", "any" },
			{ "doStop", "any" },
			{ "Destination", "Vector3D" },
			{ "Rotation", "Vector3D" },
			{ "Time", "number" },
			{ "Interruptible", "bool" },
			{ "Easing", "_easing" }
		},
		outputs = {
			{ "onStop", "number" }
		}
	}
}

addEventHandler ( "onObjectMoveStop", resourceRoot,
	function ( )
		EventManager.triggerEvent ( source, "Entity:Move", 1 )
	end
)

--[[
	Entity:Attach
]]
NodeRef "Entity:Attach" {
	doAttachTo = function ( self, value )
		local vars = self.vars
		if isElement ( vars.Parent ) then
			local offset = vars.Offset
			if _isVector3D ( offset ) then
				attachElements ( vars.target, vars.Parent, offset.x, offset.y, offset.z )
				-- Включаем выравнивание если элемент является педом
				if _isElementPed ( vars.target ) then
					setPedAdjust ( vars.target, tonumber ( vars.Adjust ) or 0 )
				end
			end
		end
	end,
	doDetach = function ( self, value )
		local vars = self.vars
		detachElements ( vars.target )
		-- Отключаем выравнивание если элемент является педом
		if _isElementPed ( vars.target ) then
			setPedAdjust ( vars.target )
		end
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doAttachTo", "any", "if(isElement(@Parent))then attachElements(@target,@Parent); end" },
			{ "doDetach", "any" },
			{ "Offset", "Vector3D" },
			{ "Adjust", "number" },
			{ "Parent", "element" }
		}
	}
}

--[[
	Entity:Position
]]
NodeRef "Entity:Position" {
	doSetPos = function ( self, value )
		local vars = self.vars
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doSetPos", "Vector3D" },
		},
		outputs = {
			{ "Pos", "Vector3D" }
		}
	}
}

--[[ Magnet
local magnet = { 
	name = "Magnet",
	group = "Entity",
	events = {
		inputs = {
			{ "doAttach", "any", "Притягивает объекты" },
			{ "doDetach", "any", "Отпускает объекты" },
		}
	}
}

magnet.supportedTypes = { [ "vehicle" ] = true, [ "player" ] = true, [ "ped" ] = true }

function componentFnDef:magnet ( input, value )
	if value > 0 then
		local x, y, z = getElementPosition ( vars.this )
		local rotvX, rotvY, rotvZ = getElementRotation ( vars.this )
		local colshape = createColTube ( x, y, z - 3.5, 2.5, 3.5 )

		for _, elementCol in ipairs ( getElementsWithinColShape ( colshape ) ) do
			if magnet.supportedTypes [ getElementType ( elementCol ) ] then
				local rotpX, rotpY, rotpZ = getElementRotation ( elementCol )
                            
				attachElements ( elementCol, vars.this, 0, 0, -1.3, rotpX - rotvX, rotpY - rotvY, rotpZ - rotvZ )
				
				break
			end
		end
		
		destroyElement ( colshape )
	else
		for _, elAttach in ipairs ( getAttachedElements ( vars.this ) ) do
			if isElement ( elAttach ) and magnet.supportedTypes [ getElementType ( elAttach ) ] then
				detachElements ( elAttach )
			end
		end
	end
end]]

--[[
	Entity:Material
]]
NodeRef "Entity:Material" { 
	doSetMaterial = function ( self, value )
		local vars = self.vars
		--setElementMaterial ( vars.target, vars.Material, 1, 1, 1 )
		setElementMaterial ( vars.target, 0, vars.Material, vars.U, vars.V )
	end,
	
	events = {
		target = "object",
		inputs = {
			{ "doSetMaterial", "any" },
			{ "Material", "number" },
			{ "U", "number" },
			{ "V", "number" }
		}
	}
}

--[[
	Entity:Light
]]
local lamps = { }

NodeRef "Entity:Light" { 
	doOn = function ( self, value )
		local vars = self.vars
		if isElement ( lamps [ vars.target ] ) ~= true then
			local color = vars.Color
			local x, y, z = getElementPosition ( vars.target )

			lamps [ vars.target ] = createMarker ( x, y, z, "corona", vars.Size, color.r, color.g, color.b, math.max ( color.a, 100 ) )
			setElementParent ( lamps [ vars.target ], self:getRootElement ( ) )
			setElementDimension ( lamps [ vars.target ],
				getElementDimension ( vars.target )
			)
			attachElements ( lamps [ vars.target ], vars.target, 0, 0, 0 )
		end
	end,
	doOff = function ( self, value )
		local vars = self.vars
		if lamps [ vars.target ] then
			destroyElement ( lamps [ vars.target ] )
			lamps [ vars.target ] = nil
		end
	end,
	Color = function ( self, value )
		local vars = self.vars
		if isElement ( lamps [ vars.target ] ) then
			local color = vars.Color
			setMarkerColor ( lamps [ vars.target ], color.r, color.g, color.b, math.max ( color.a, 100 ) )
		end
	end,
	Size = function ( self )
		local vars = self.vars
		if isElement ( lamps [ vars.target ] ) then
			setMarkerSize ( lamps [ vars.target ], math.clamp ( 1, vars.Size, 10 ) )
		end
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doOn", "any" },
			{ "doOff", "any" },
			{ "Color", "color" },
			{ "Size", "number" }
		}
	}
}

--[[
	Entity:Frozen
]]
NodeRef "Entity:Frozen" { 
	doToggle = function ( self )
		local vars = self.vars
		local newState = not isElementFrozen ( vars.target )
		setElementFrozen ( vars.target, newState )
	end,
	doFreeze = function ( self, value )
		local vars = self.vars
		setElementFrozen ( vars.target, true )
	end,
	doUnfreeze = function ( self, value )
		local vars = self.vars
		setElementFrozen ( vars.target, false )
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doToggle", "any" },
			{ "doFreeze", "any" },
			{ "doUnfreeze", "any" },
		}
	}
}

--[[
	Entity:Double sided
]]
NodeRef "Entity:Double sided" { 
	doToggle = function ( self )
		local vars = self.vars
		local newState = not isElementDoubleSided ( vars.target )
		setElementDoubleSided ( vars.target, newState )
	end,
	doDoubleSided = function ( self, value )
		local vars = self.vars
		setElementDoubleSided ( vars.target, true )
	end,
	doUnDoubleSided = function ( self, value )
		local vars = self.vars
		setElementDoubleSided ( vars.target, false )
	end,
	
	events = {
		target = "object",
		inputs = {
			{ "doToggle", "any" },
			{ "doDoubleSided", "any" },
			{ "doUnDoubleSided", "any" }
		}
	}
}

--[[
	Entity:Scale
]]
NodeRef "Entity:Scale" { 
	doScale = function ( self, value )
		local vars = self.vars
		local scale = math.max ( vars.Scale, 0.1 )
	
		setObjectScale ( vars.target, scale == 1 and 1.000001 or scale )
	end,
	
	events = {
		target = "object",
		inputs = {
			{ "doScale", "any" },
			{ "Scale", "number" }
		}
	}
}

--[[
	Entity:Health
]]
NodeRef "Entity:Health" { 
	doSet = function ( self )
		local vars = self.vars
		local health = math.clamp ( 0, vars.Health, 1000 )
	
		setElementHealth ( vars.target, health )
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doSet", "any" },
			{ "Health", "number" }
		},
		outputs = {
			{ "Health", "number" }
		}
	}
}

--[[
	Entity:Alpha
]]
NodeRef "Entity:Alpha" { 
	doSet = function ( self )
		local vars = self.vars
		setElementAlpha ( vars.target, math.clamp ( 0, vars.Alpha, 255 ) )
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doSet", "any" },
			{ "Alpha", "number" }
		}
	}
}

--[[
	Entity:Sound
]]
NodeRef "Entity:Sound" { 
	doPlay = function ( self, value )
		local vars = self.vars
		local fileId = tonumber ( vars.Sound )
		if fileId then
			local volume = tonumber ( vars.Volume ) or 100
			sound3D.createAndAttachTo ( fileId, vars.target, vars.Looped == true, math.clamp ( 0, volume, 100 ) )
		end
	end,
	doStop = function ( self )
		local vars = self.vars
		sound3D.detachFrom ( vars.target )
	end,
	Volume = function ( self, value )
		local vars = self.vars
		sound3D.setVolume ( vars.target, tonumber ( value ) or 100 )
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doPlay", "any" },
			{ "doStop", "any" },
			{ "Sound", "_sound" },
			{ "Looped", "bool" },
			{ "Volume", "number" }
		}
	}
}

--[[
	Entity:Explode
]]
NodeRef "Entity:Explode" {
	doExplode = function ( self, value )
		local vars = self.vars
		local posX, posY, posZ = getElementPosition ( vars.target )
		createExplosion ( posX, posY, posZ, 2 )
	end,
	
	events = {
		target = "object",
		inputs = {
			{ "doExplode", "any" }
		}
	}
}

--[[
	Entity:ByType
]]
NodeRef "Entity:ByType" {
	doGet = function ( self )
		local vars = self.vars
		local _getData = getElementData
		local dimension = _getData ( vars.target, "dimension", false )
		local elements = getElementsByType ( vars.Type, resourceRoot )
		local array = { }
		for i = 1, #elements do
			local element = elements [ i ]
			if _getData ( element, "dimension", false ) == dimension then
				array [ #array + 1 ] = element 
			end
		end
		
		self:triggerOutput ( 2, #array )
		self:triggerOutput ( 1, array )
	end,
	
	events = {
		target = "room",
		inputs = {
			{ "doGet", "any" },
			{ "Type", "string" }
		},
		outputs = {
			{ "Array", "array" },
			{ "Count", "number" }
		}
	}
}

--[[
-- GetByType
local gbtype = { 
	name = "GetByType",
	group = "Entity",
	events = {
		inputs = {
			{ "doGet", "any", "Собирает все объекты в этом измерении в массив" },
			{ "Type", "string", "Тип объекта" }
		},
		outputs = {
			{ "Array", "array", "Массив" },
			{ "Count", "number", "Количество элементов в массиве" }
		}
	}
}

function componentFnDef:gbtype ( input, value, args, thisNodeID )
	local elements = { }
	
	for _, element in ipairs ( getElementsByType ( vars.Type, resourceRoot ) ) do
		local dimension = tonumber (
			getElementData ( element, "dimension" )
		) or getElementDimension ( element )

		--if dimension == vars.room then
			table.insert ( elements, element )
			--outputChatBox("ggvehic")
		--end
	end
		
	EventManager.triggerEvent ( thisNodeID, "gbtype", 2, #elements )
	EventManager.triggerEvent ( thisNodeID, "gbtype", 1, elements )
end

-- EntityCounter
local encntr = { 
	name = "EntityCounter",
	group = "Entity",
	events = {
		target = "element",
		inputs = {
			{ "doNext", "any", "Устанавливает следующее значение счетчика для объекта" },
			{ "doPrev", "any", "Устанавливает предыдущее значение счетчика для объекта" },
			{ "doReset", "any", "Сброс счетчика в начальное положение для объекта" }
		},
		outputs = {
			{ "onNext", "number", "Событие вызывается всякий раз при установке нового значения счетчика для объекта и возвращает в поток его текущее значение" }
		}
	}
}

local counters = {
	
}

function componentFnDef:encntr ( input, value, args, nodeID, dNode )
	if not counters [ nodeID ] then
		counters [ nodeID ] = { 
			[ vars.target ] = 0
		}
	elseif not counters [ nodeID ] [ vars.target ] then
		counters [ nodeID ] [ vars.target ] = 0
	end
	
	if input == 1 then
		counters [ nodeID ] [ vars.target ] = counters [ nodeID ] [ vars.target ] + 1
	elseif input == 2 then
		counters [ nodeID ] [ vars.target ] = counters [ nodeID ] [ vars.target ] - 1
	elseif input == 3 then
		counters [ nodeID ] [ vars.target ] = 0
	end
	
	EventManager.triggerEvent ( nodeID, "encntr", 1, counters [ nodeID ] [ vars.target ] )
end]]

--[[
	Entity:GetEntity
]]
NodeRef "Entity:GetEntity" {
	_target = function ( self, value )
		--outputChatBox("получаем интити")
		self:triggerOutput ( 1, value )
	end,
	
	events = {
		target = "entity",
		outputs = {
			{ "Entity", "entity" }
		}
	}
}

--[[
	Entity:Particles
]]
-- Список обязательно дублируется на клиенте
local _particles = { }

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		local partlist = xmlLoadFile ( "conf/partlist.xml" )
		local partnodes = xmlNodeGetChildren ( partlist )
		for i, partnode in ipairs ( partnodes ) do
			local modelId = tonumber ( xmlNodeGetAttribute ( partnode, "id" ) )
			--local partName = xmlNodeGetAttribute ( partnode, "name" )
			
			table.insert ( _particles, modelId )
		end
		xmlUnloadFile ( partlist )
	end
, false, "low" )

local objectParticles = { }

NodeRef "Entity:Particles" {
	doToggle = function ( self )
		local vars = self.vars
		if isElement ( objectParticles [ vars.target ] ) then
			self.abstr.doDetach ( self )
		else
			self.abstr.doAttach ( self )
		end
	end,
	doAttach = function ( self )
		local vars = self.vars
		if isElement ( objectParticles [ vars.target ] ) then return end;
	
		local fxModel = _particles [ tonumber ( vars.Particle ) ]
		if fxModel then
			local x, y, z = getElementPosition ( vars.target )
			objectParticles [ vars.target ] = createObject ( fxModel, x, y, z )
			local dimension = getElementDimension ( vars.target )
			setElementDimension ( objectParticles [ vars.target ], dimension )
			setElementParent ( objectParticles [ vars.target ], self:getRootElement ( ) )
			setElementCollisionsEnabled ( objectParticles [ vars.target ], false )
			attachElements ( objectParticles [ vars.target ], vars.target )
		end
	end,
	doDetach = function ( self )
		local vars = self.vars
		if isElement ( objectParticles [ vars.target ] ) then
			destroyElement ( objectParticles [ vars.target ] )
		end
		objectParticles [ vars.target ] = nil
	end,

	events = {
		target = "entity",
		inputs = {
			{ "doToggle", "any" },
			{ "doAttach", "any" },
			{ "doDetach", "any" },
			{ "Particle", "_particle" }
		}
	}
}

addEventHandler ( "onElementDestroy", resourceRoot, 
	function ( )
		if isElement ( objectParticles [ source ] ) then
			destroyElement ( objectParticles [ source ] )
			objectParticles [ source ] = nil
		end
	end 
)

--[[
	Entity:AttachBlip
]]
local entityBlip = { }

NodeRef "Entity:AttachBlip" {
	doAttach = function ( self )
		local vars = self.vars
		local iconIndex = tonumber ( vars.Icon )
		if not iconIndex then
			return
		end
		if entityBlip [ vars.target ] == nil then
			local x, y, z = getElementPosition ( vars.target )
			local blip = createBlip ( x, y, z, math.clamp ( 0, iconIndex, 63 ), 2, 255, 0, 0, 255, 0, 3000 )
			--local blip = createBlipAttachedTo ( vars.target, math.clamp ( 0, iconIndex, 63 ), 2, 255, 0, 0, 255, 0, 3000 )
			if blip then
				local dimension = getElementData ( vars.target, "dimension", false )
				setElementDimension ( blip, tonumber ( dimension ) or 0 )
				entityBlip [ vars.target ] = blip
			end
		end
	end,
	doDetach = function ( self )
		local vars = self.vars
		if entityBlip [ vars.target ] then
			destroyElement ( entityBlip [ vars.target ] )
		end
		entityBlip [ vars.target ] = nil
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doAttach", "any" },
			{ "doDetach", "any" },
			{ "Icon", "_blip" }
		},
		outputs = {
			{ "onAttach", "blip" }
		}
	}
}

--[[
	Entity:Data
]]
local dataChars = { 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 81, 87, 69, 82, 84, 89, 85, 73, 79, 80, 65, 83, 68, 70, 71, 72, 74, 75, 76, 90, 88, 67, 86, 66, 78, 77 }
local function checkDataStr ( dataStr, isKey )
	if type ( dataStr ) == "string" then
		if utfLen ( dataStr ) < 1 then
			return
		end
	
		-- Если первый символ является числом, выходим из функции
		if isKey and tonumber ( utfSub ( dataStr, 1, 1 ) ) then
			return
		end
	
		-- Если строка содержит недопустимые знаки, выходим из функции
		for i = 1, utfLen ( dataStr ) do
			local char = utfSub ( dataStr, i, i )
			if not table.find ( dataChars, utfCode ( char ) ) then
				--outputChatBox(dataStr)
				return
			end
		end
		
		return true
	end
end

local CustomData = { 
	elements = { }
}

function CustomData.setData ( element, key, value )
	if CustomData.elements [ element ] ~= nil then
		CustomData.elements [ element ] [ key ] = value
	else
		CustomData.elements [ element ] = {
			[ key ] = value
		}
	end
end

function CustomData.getData ( element, key )
	if CustomData.elements [ element ] then
		return CustomData.elements [ element ] [ key ]
	end
end

local function getEntityData ( element, key )
	if getElementType ( element ) == "player" then
		local account = getPlayerAccount ( element )
		if isGuestAccount ( account ) then
			return
		end
		
		local dimension = getElementDimension ( element )
		return getAccountData ( account, "tct:" .. dimension .. ":" .. key )
	else
		return getElementData ( element, "_" .. key, false )
	end
end

NodeRef "Entity:Data" {
	doSet = function ( self )
		local vars = self.vars

		if checkDataStr ( vars.Key, true ) ~= true or checkDataStr ( vars.Value ) ~= true then
			return
		end

		-- Временное хранение данных в памяти?
		if vars.Temp == true then
			CustomData.setData ( vars.target, vars.Key, vars.Value )
		else
			if getElementType ( vars.target ) == "player" then
				local account = getPlayerAccount ( vars.target )
				if isGuestAccount ( account ) then
					return
				end
		
				local dimension = getElementDimension ( vars.target )
				setAccountData ( account, "tct:" .. dimension .. ":" .. vars.Key, vars.Value )
			else
				setElementData ( vars.target, "_" .. vars.Key, vars.Value, false )
			end
		end
		self:triggerOutput ( 3, vars.Value )
	end,
	doGet = function ( self )
		local vars = self.vars
		if checkDataStr ( vars.Key, true ) ~= true then
			return
		end
		
		if vars.Temp == true then
			local value = CustomData.getData ( vars.target, vars.Key )
			if value then
				self:triggerOutput ( 3, value )
				self:triggerOutput ( 1, value )
			else
				self:triggerOutput ( 2 )
			end
		else
			local value = getEntityData ( vars.target, vars.Key )
			if value then
				self:triggerOutput ( 3, value )
				self:triggerOutput ( 1, value )
			else
				self:triggerOutput ( 2 )
			end
		end
	end,
	doRemove = function ( self )
		local vars = self.vars
		if checkDataStr ( vars.Key, true ) ~= true then
			return
		end
		
		if vars.Temp == true then
			CustomData.setData ( vars.target, vars.Key, nil )
		else
			if getElementType ( vars.target ) == "player" then
				local account = getPlayerAccount ( vars.target )
				if isGuestAccount ( account ) then
					return
				end
		
				local dimension = getElementDimension ( vars.target )
				setAccountData ( account, "tct:" .. dimension .. ":" .. vars.Key, false )
			else
				removeElementData ( vars.target, "_" .. vars.Key )
			end
		end
		--self:triggerOutput ( 3, "" )
	end,
	
	events = {
		target = "element",
		inputs = {
			{ "doSet", "any" },
			{ "doGet", "any" },
			{ "doRemove", "any" },
			{ "Key", "string" },
			{ "Value", "string" },
			{ "Temp", "bool" }
		},
		outputs = {
			{ "onData", "string" },
			{ "onEmpty", "any" },
			{ "Value", "string" }
		}
	}
}

--[[
	Entity:DataCompare
]]
NodeRef "Entity:DataCompare" {
	doCompare = function ( self )
		local vars = self.vars
		if checkDataStr ( vars.Key, true ) ~= true then
			return
		end

		
		if vars.Temp == true then
			local oneValue = CustomData.getData ( vars.target, vars.Key )
			local twoValue = tostring ( vars.Value )
			if isElement ( vars.Element ) then
				twoValue = CustomData.getData ( vars.Element, vars.Key )
			end
			
			if oneValue and twoValue then
				self:triggerOutput ( oneValue == twoValue and 1 or 2 )
			else
				self:triggerOutput ( 2 )
			end
		else
			local oneValue = getEntityData ( vars.target, vars.Key )
			local twoValue = tostring ( vars.Value )
			if isElement ( vars.Element ) then
				twoValue = getEntityData ( vars.Element, vars.Key )
			end
			
			if oneValue and twoValue then
				self:triggerOutput ( oneValue == twoValue and 1 or 2 )
			else
				self:triggerOutput ( 2 )
			end
		end
	end,
	
	events = {
		target = "element",
		inputs = {
			{ "doCompare", "any" },
			{ "Element", "element" },
			{ "Value", "string" },
			{ "Key", "string" },
			{ "Temp", "bool" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Entity:Undamageable
]]
NodeRef "Entity:Undamageable" {
	doEnable = function ( self )
		local vars = self.vars
		local entityType = getElementType ( vars.target )
		if entityType == "player" then
			setElementData ( vars.target, "undam", true )
		elseif entityType == "vehicle" then
			setVehicleDamageProof ( vars.target, true )
		end
	end,
	doDisable = function ( self )
		local vars = self.vars
		local entityType = getElementType ( vars.target )
		if entityType == "player" then
			removeElementData ( vars.target, "undam" )
		elseif entityType == "vehicle" then
			setVehicleDamageProof ( vars.target, false )
		end
	end,
	
	events = {
		target = "entity",
		inputs = {
			{ "doEnable", "any" },
			{ "doDisable", "any" }
		}
	}
}