--[[
	Соглашения описания типов портов:
		target port - ^
		input port - $
		output port = #
	Символы ставятся перед типами портов в их описании
]]

gNodeRefs = { }
gNodeRefGroups = { }
local nodeRefGroupIndex = { }

NodeReference = { }
NodeReference.__index = NodeReference

function NodeReference.isValidTag ( tag )
	return gNodeRefs [ tag ] ~= nil
end

function NodeReference:getInputCount ( )
	return self.events.inputs and #self.events.inputs or 0
end

function NodeReference:getOutputCount ( )
	return self.events.outputs and #self.events.outputs or 0
end

function NodeReference:getPointsByType ( theType )
	return self.events [ theType ] or { }
end

function NodeReference:getIndexFromName ( name )
	local inputs = self.events.inputs
	for i, input in ipairs ( inputs ) do
		if input [ 1 ] == name then
			return i
		end
	end
end

function getComponentByTag ( tag )
	local foundComponent = gNodeRefs [ tag ]
	
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
	
	if gNodeRefs [ tag ] then
		return gNodeRefs [ tag ]
	end
	
	return false
end

function getComponentEvents ( element )
	local tag = getElementData ( element, "tag" )
	
	if gNodeRefs [ tag ] then
		return gNodeRefs [ tag ].events
	end
	
	return false
end

local _nodeCreateName
local function _createNode ( data )
	local groupName = gettok ( _nodeCreateName, 1, 58 )
	local nodeName = gettok ( _nodeCreateName, 2, 58 )
	if not nodeName then
		nodeName = groupName
		groupName = "Service"
	end
	
	data.group = groupName
	data.name = nodeName
	data.fullName = _nodeCreateName
	
	gNodeRefs [ _nodeCreateName ] = data
	
	-- Добавляем нод в индексированный список
	local groupIndex = nodeRefGroupIndex [ groupName ]
	if not groupIndex then
		local newIndex = #gNodeRefGroups + 1
	
		gNodeRefGroups [ newIndex ] = { name = groupName }
		nodeRefGroupIndex [ groupName ] = newIndex
		groupIndex = newIndex
	end
	
	table.insert ( gNodeRefGroups [ groupIndex ], data )
	
	setmetatable ( data, NodeReference )
end
local function NodeRef ( name )
	_nodeCreateName = name
	return _createNode
end

------------------------------------
-- World группа                   --
-- Мировые компоненты             --
------------------------------------

-- Button
NodeRef "Button" {
	events = {
		target = "object",
	
		outputs = {
			{ "onDown", "element",_LD"NEBtnDown" },
			{ "onUp", "element", _LD"NEBtnUp" },
			{ "Player", "element", _LD"NEPlayer" },
			{ "ActionIndex", "number", _LD"NEBtnIndex" },
		}
	}
}

--[[
	Marker
]]
--[[NodeRef "Marker" { 
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
}]]

--[[
	Laser
]]
NodeRef "Laser" {
	events = {
		target = "object",
		outputs = {
			{ "onHit", "any", _LD"NELaserHit" },
			{ "onLeave", "any", _LD"NELaserLeave" }
		}
	}
}

--[[
	Checkpoint
]]
NodeRef "Checkpoint" { 
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
PortCtrl "_sptype" {
	control = {
		"combobox",
			
		id = "type",
		text = "Type",
		items = { "vehicle", "ped" }
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) )
	end
}

NodeRef "Spawnpoint" {
	events = {
		target = "wbo:spawnpoint",
		inputs = {
			{ "doSpawn", "any", "Спавнит игрока" },
			{ "Player", "element", "Элемент игрока" },
			{ "Type", "_sptype" },
			{ "Model", "number" }
		},
		outputs = {
			{ "onSpawn", "element", "Вызывается каждый раз при спавне игрока и выдает его элемент в поток" }
		}
	}
}

--[[
local zone = NodeReference.create ( "zone", "Zone", true )
zone.events = {
	outputs = {
		{ "onHit", "element", "Вызывается всякий раз при входе в зону" },
		{ "onLeave", "element", "Вызывается всякий раз при выходе из зоны" }
	}
}]]

--[[
	World:Trigger
]]
NodeRef "Trigger" {
	events = {
		target = "wbo:trigger",
		inputs = {
			{ "doEnable", "any" },
			{ "doDisable", "any" }
		},
		outputs = {
			{ "onHit", "player", _LD"NETriggerHit" },
			{ "onLeave", "player", _LD"NETriggerLeave" },
			{ "Players", "number", _LD"NETriggerNum" }
		}
	}
}

--[[
	Sign
]]
NodeRef "Sign" {
	events = {
		target = "object",
		inputs = {
			{ "doSet", "any", _LD"NMSignSet" },
			{ "Text", "string", _LD"NEText" }
		}
	}
}

--[[
	Area
]]
NodeRef "Area" { 
	events = {
		target = "wbo:area",
		inputs = {
			{ "doFlashing", "any" },
			{ "doNormal", "any" },
			{ "doSetColor", "any" },
			{ "Color", "color" }
		},
		outputs = {
			{ "onHit", "player" },
			{ "onLeave", "player" },
			{ "onWasted", "player" },
			{ "Players", "array" },
			{ "Killer", "entity" }
		}
	}
}

--[[
	_ActionEnt
]]
NodeRef "_ActionEnt" { 
	events = {
		target = "entity",
		outputs = {
			{ "onDown", "player", _LD"NEBtnDown" },
			{ "onUp", "player", _LD"NEBtnUp" },
			{ "onHit", "player", "Вызывается при приближении игрока[#player] к действию объекта<^entity>" },
			{ "ActionIndex", "number", _LD"NEBtnIndex" }
		}
	}
}

--[[
	Blip
]]
NodeRef "Blip" { 
	events = {
		target = "tct-blip",
		inputs = {
			{ "doVisible", "any" },
			{ "doInvisible", "any" }
		}
	}
}

------------------------------------
-- Events группа                  --
-- Компоненты обработки событий   --
------------------------------------

-- Contact
NodeRef "Events:Contact" {
	events = {
		target = "object",
		outputs = {
			{ "onHit", "number", "Вызывается всякий раз при контакте с объектом" },
			{ "onLeave", "number", "Вызывается всякий когда игрок покидает объект" },
			{ "Player", "element", "Содержит элемент игрока" }
		}
	}
}

-- Click
NodeRef "Events:Click" {
	events = {
		target = "object",
		outputs = {
			{ "onDown", "number", "Вызывается всякий раз при щелчке по объекту и выдает 1, если кнопка мыши зажата, и 0 - в противном случае" },
			{ "Player", "element", "Содержит элемент игрока" }
		}
	}
}

---------------------------------------
-- Entity группа                     --
-- Компоненты для работы с объектами --
---------------------------------------

--[[
	Entity:Entity
]]

--[[NodeRef "Entity:Entity" {
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
-- Список обязательно дублируется на сервере
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

PortCtrl "_easing" {
	control = {
		"combobox",
			
		id = "easing",
		text = "Easing",
		items = _easing 
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value and value - 1 or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) + 1 )
	end
}

NodeRef "Entity:Path" {
	desc = "Нод служит для перемещения родительского объекта по треку [target]",
	events = {
		target = "path",
		inputs = {
			{ "doMove", "any", "Начитает перемещение объекта из потока от текущей точки до целевой" },
			{ "doStop", "any", "Останавливает перемещение объекта из потока" },
			{ "Time", "number", "Скорость перемещения объекта" },
			{ "TargetNode", "number", "Номер точки которая будет целевой для объекта" },
			{ "Interruptible", "bool", "Можем ли мы прерывать текущее перемещение" },
			{ "Easing", "_easing" }
		},
		outputs = {
			{ "onNodeChange", "number", "Вызывается всякий раз при достижении точки и выдает ее индекс в поток" },
			{ "onStop", "number", "Вызывается один раз при остановке объекта" },
			{ "Nodes", "number", "Количество нодов в пути" }
		}
	}
}

--[[
	Entity:Move
]]
NodeRef "Entity:Move" {
	events = {
		target = "object",
		inputs = {
			{ "doMove", "any", "Начитает перемещение объекта" },
			{ "doStop", "any", "Останавливает перемещение объекта" },
			{ "Destination", "Vector3D", "Точка назначения" },
			{ "Rotation", "Vector3D", "Вращение" },
			{ "Time", "number", "Время за которое объект преодолеет дистанцию до точки назначения" },
			{ "Interruptible", "bool", "Возможность прервать движение объекта" },
			{ "Easing", "_easing" }
		},
		outputs = {
			{ "onStop", "number", "Вызывается один раз при остановке объекта" }
		}
	}
}

-- Attach
NodeRef "Entity:Attach" {
	events = {
		target = "entity",
		inputs = {
			{ "doAttachTo", "any", "Присоединяет объект[^entity] к [$Parent]" },
			{ "doDetach", "any", "Отсоединяет объект[^entity] от [$Parent]" },
			{ "Offset", "Vector3D", "Смещение объекта[^entity] относительно[$Parent]" },
			{ "Adjust", "number", "Выравнивание объекта[^entity] относительно[$Parent] (только для педов)" },
			{ "Parent", "element", "Родительский объект к которому крепится [^entity]" }
		}
	}
}

--[[
-- Position
local pos = NodeReference.create ( "pos", "Entity:Position" )
pos.events = {
	target = "entity",
	inputs = {
		{ "doSetPos", "Vector3D", "Устанавливает новое положение объекта" },
	},
	outputs = {
		{ "Pos", "vector", "Положение объекта" }
	}
}

-- Magnet
local magnet = NodeReference.create ( "magnet", "Entity:Magnet" )
magnet.events = {
	inputs = {
		{ "doAttach", "any", "Притягивает объекты" },
		{ "doDetach", "any", "Отпускает объекты" },
	}
}
]]
-- Material
NodeRef "Entity:Material" {
	events = {
		target = "object",
		inputs = {
			{ "doSetMaterial", "any", "Устанавливает материал для объекта <object>" },
			{ "Material", "number", "Номер материала" },
			{ "U", "number", "U" },
			{ "V", "number", "V" }
		}
	}
}

-- Light
NodeRef "Entity:Light" {
	events = {
		target = "entity",
		inputs = {
			{ "doOn", "any", "Прикрепляет корону на объект <entity>" },
			{ "doOff", "any", "Открепляет корону с объекта <entity>" },
			{ "Color", "color", "Цвет короны" },
			{ "Size", "number", "Размер короны" }
		}
	}
}

-- Frozen
NodeRef "Entity:Frozen" {
	events = {
		target = "entity",
		inputs = {
			{ "doToggle", "any", "Замораживает объект <entity> если он подвижен и размораживает в противном случае" },
			{ "doFreeze", "any", "Замораживает объект <entity>" },
			{ "doUnfreeze", "any", "Размораживает объект <entity>" },
		}
	}
}

-- Double sided
NodeRef "Entity:Double sided" {
	events = {
		target = "object",
		inputs = {
			{ "doToggle", "any", "Переключает состояние объекта <object>" },
			{ "doDoubleSided", "any", "Скрывает прозрачные области объекта <object>" },
			{ "doUnDoubleSided", "any", "Показывет прозрачные области объекта <object>" }
		}
	}
}

-- Scale
NodeRef "Entity:Scale" {
	events = {
		target = "object",
		inputs = {
			{ "doScale", "any", "Устанавливает масштаб объекта" },
			{ "Scale", "number", "Масштаб объекта" }
		}
	}
}

--[[
	Entity:Health
]]
NodeRef "Entity:Health" {
	events = {
		target = "entity",
		inputs = {
			{ "doSet", "any", "Задает количество здоровья для объекта" },
			{ "Health", "number", "Количество здоровья" }
		},
		outputs = {
			{ "Health", "number", "Количество здоровья" }
		}
	}
}

-- Alpha
NodeRef "Entity:Alpha" {
	events = {
		target = "entity",
		inputs = {
			{ "doSet", "any", "Задает объекту уровень прозрачности" },
			{ "Alpha", "number", "Уровень прозрачности" }
		}
	}
}

--[[
	Entity:Sound
]]
local _onSoundSelect = function ( name, id, button )
	if isElement ( button ) then
		guiSetText ( button, tostring ( id ) )
	end
	NEWorkspace.setInputEnabled ( false )
end

PortCtrl "_sound" {
	control = {
		"button",
		onClick = function ( )
			local loadedSounds = getLoadedFiles ( "ogg" )
			if #loadedSounds < 1 then
				outputChatBox ( "TCT: No loaded sounds", 200, 200, 0 )
				return 
			end
		
			SoundBrowser.open ( _onSoundSelect )
			for _, file in ipairs ( loadedSounds ) do
				SoundBrowser.insertSound ( ":wbo_modmanager/modfiles/" .. file.checksum, file.name, file.id, source )
			end
			
			NEWorkspace.setInputEnabled ( true )
		end
	},
	
	setData = function ( self, value )
		self.control:setData ( tostring ( value ) )
	end,
	getData = function ( self )
		return tonumber ( self.control:getData ( ) )
	end
}

NodeRef "Entity:Sound" {
	events = {
		target = "entity",
		inputs = {
			{ "doPlay", "any", "Создает и прикрепляет к объекту <entity> звук [Sound]" },
			{ "doStop", "any", _LD"NMEntSndStop" },
			{ "Sound", "_sound", "Звук" },
			{ "Looped", "bool", "Зациклить воспроизведение" },
			{ "Volume", "number", "Громкость звука(1-100)" }
		}
	}
}

-- Explode
NodeRef "Entity:Explode" {
	events = {
		target = "object",
		inputs = {
			{ "doExplode", "any", "Создает взрыв рядом с объектом" }
		}
	}
}

--[[
	Entity:ByType
]]
NodeRef "Entity:ByType" {
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
local gbtype = NodeReference.create ( "gbtype", "Entity:GetByType" )
gbtype.events = {
	inputs = {
		{ "doGet", "any", "Собирает все объекты в этом измерении в массив" },
		{ "Type", "string", "Тип объекта" }
	},
	outputs = {
		{ "Array", "array", "Массив" },
		{ "Count", "number", "Количество элементов в массиве" }
	}
}

-- EntityCounter
local encntr = NodeReference.create ( "encntr", "Entity:EntityCounter" )
encntr.events = {
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
--]]

--[[
	Entity:GetEntity
]]
NodeRef "Entity:GetEntity" {
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
-- Список обязательно дублируется на сервере
local _particles = { }

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local partlist = getResourceConfig ( "conf/partlist.xml" )
		local partnodes = xmlNodeGetChildren ( partlist )
		for i, partnode in ipairs ( partnodes ) do
			--local modelId = tonumber ( xmlNodeGetAttribute ( partnode, "id" ) )
			local partName = xmlNodeGetAttribute ( partnode, "name" )
			
			table.insert ( _particles, { partName } )
		end
		xmlUnloadFile ( partlist )
	end
, false, "low" )

PortCtrl "_particle" {
	control = {
		"combobox",
			
		id = "fx",
		text = "Эффект",
		items = _particles
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value and value - 1 or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) + 1 )
	end
}

NodeRef "Entity:Particles" {
	events = {
		target = "entity",
		inputs = {
			{ "doToggle", "any", "Прикрепляет эффект если его нет и открепляет в противном случае" },
			{ "doAttach", "any", "Прикрепляет эффект [Particle] к объекту <entity>" },
			{ "doDetach", "any", "Открепляет эффект [Particle] от объекта <entity>" },
			{ "Particle", "_particle", "Эффект" }
		}
	}
}

--[[
	Entity:AttachBlip
]]
local _blipicons = {
	{ "Marker" },
	{ "White_square" },
	{ "Centre" },
	{ "Map_here" },
	{ "North" },
	{ "Airyard" },
	{ "Gun" },
	{ "Barbers" },
	{ "Big_smoke" },
	{ "Boatyard" },
	{ "Burgershot" },
	{ "Bulldozer" },
	{ "Cat_pink" },
	{ "Cesar" },
	{ "Chicken" },
	{ "Cj" },
	{ "Crash1" },
	{ "Diner" },
	{ "Emmetgun" },
	{ "Enemyattack" },
	{ "Fire" },
	{ "Girlfriend" },
	{ "Hospital" },
	{ "Loco" },
	{ "Madd Dogg" },
	{ "Mafia" },
	{ "Mcstrap" },
	{ "Mod_garage" },
	{ "Ogloc" },
	{ "Pizza" },
	{ "Police" },
	{ "Property_green" },
	{ "Property_red" },
	{ "Race" },
	{ "Ryder" },
	{ "Savehouse" },
	{ "School" },
	{ "Mystery" },
	{ "Sweet" },
	{ "Tattoo" },
	{ "Truth" },
	{ "Waypoint" },
	{ "Toreno_ranch" },
	{ "Triads" },
	{ "Triads_casino" },
	{ "Tshirt" },
	{ "Woozie" },
	{ "Zero" },
	{ "Date_disco" },
	{ "Date_drink" },
	{ "Date_food" },
	{ "Truck" },
	{ "Cash" },
	{ "Flag" },
	{ "Gym" },
	{ "Impound" },
	{ "Runway_light" },
	{ "Runway" },
	{ "Gang_b" },
	{ "Gang_p" },
	{ "Gang_y" },
	{ "Gang_n" },
	{ "Gang_g" },
	{ "Spray" }
}

PortCtrl "_blip" {
	control = {
		"combobox",
			
		id = "icon",
		text = "Icon",
		items = _blipicons
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		if value then self.control:setData ( value ) end
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) )
	end
}

NodeRef "Entity:AttachBlip" {
	events = {
		target = "entity",
		inputs = {
			{ "doAttach", "any" },
			{ "doDetach", "any" },
			{ "Icon", "_blip" }
		}
	}
}

--[[
	Entity:Data
]]
NodeRef "Entity:Data" {
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
	events = {
		target = "entity",
		inputs = {
			{ "doEnable", "any" },
			{ "doDisable", "any" }
		}
	}
}

---------------------------------------
-- Game группа                       --
-- Работа с внутриигровыми функциями --
---------------------------------------
--[[
-- Wasted event
local wstdevnt = NodeReference.create ( "wstdevnt", "Game:Wasted event" )
wstdevnt.events = {
	outputs = {
		{ "onWasted", "element", "Вызывает каждый раз при смерти игрока и выдает его элемент в поток" },
		{ "Killer", "element", "Элемент вызовший смерть игрока" }
	}
}

-- Text item
local txtitm = NodeReference.create ( "txtitm", "Game:Text item" )
txtitm.events = {
	target = "player",
	inputs = {
		{ "doShow", "any", "Показывает на экране текст" },
		{ "doHide", "any", "Скрывает текст" },
		{ "Text", "string", "Текст" },
		{ "Pos", "Vector2D", "Положение текста(0-1)" },
		{ "Scale", "number", "Масштаб текста" },
		{ "Time", "number", "Время показа текста(0 - бесконечно)" }
	}
}
]]

-- ChatBox
NodeRef "Game:ChatBox" {
	events = {
		--target = "player",
		inputs = {
			{ "doShow", "any", _LD"NIChatBoxShow" },
			{ "Player", "player" },
			{ "Message", "string", _LD"NIChatBoxMsg" }
		}
	}
}

--[[
	Game:GameRoom
]]
NodeRef "Game:GameRoom" {
	events = {
		target = "room",
		outputs = {
			{ "onPlayerJoin", "player" },
			{ "onPlayerQuit", "player" },
			{ "onPlayerWasted", "player" },
			{ "Player", "player" },
			{ "Players", "array" },
			{ "Killer", "player", "Возвращается при срабатывании onPlayerWasted" }
		}
	}
}

NodeRef "Game:Countdown" {
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
local gmmode = NodeReference.create ( "", "Game:GameMode" )
gmmode.events = {
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
}]]

--[[
	Game:Time
]]
NodeRef "Game:Time" {
	events = {
		outputs = {
			{ "Hours", "number", "Часы" },
			{ "Minutes", "number", "Минуты" }
		}
	}
}

--[[
	Game:Race
]]
--[[
local gameRace = NodeReference.create ( "", "Game:Race" )
gameRace.events = {
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
}]]

--[[
	Game:List
]]

--[[
local gameList = NodeReference.create ( "", "Game:List" )
gameList.events = {
	target = "player",
	inputs = {
		{ "doShow", "any" },
		{ "List", "array" }
	}
}]]

--[[
	Game:Info
]]
NodeRef "Game:Info" {
	events = {
		target = "player",
		inputs = {
			{ "doSend", "any", "Показывает на экране игрока <player> текст [Text]" },
			{ "Text", "string", "Текст сообщения" }
		}
	}
}

InfoDrawer = { 
	items = { },
	refsNum = 0
}

function InfoDrawer.addString ( element, text )
	for i, item in ipairs ( InfoDrawer.items ) do
		if item.element == element then
			item.ticks = getTickCount ( )
			item.text = text
			return
		end
	end
	
	table.insert ( InfoDrawer.items, { element = element, text = text, ticks = getTickCount ( ) } )
	
	if #InfoDrawer.items == 1 then
		addEventHandler ( "onClientRender", root, InfoDrawer.onRender, false, "low" )
	end
end

function InfoDrawer.onRender ( )
	local width = 200
	local itemHeight = 40
	local x, y = sw - width - 10, sh * 0.5
	
	local now = getTickCount ( )
	
	for i, item in ipairs ( InfoDrawer.items ) do
		local _y = y + ( itemHeight * ( i - 1 ) )
		
		dxDrawRectangle ( x, _y + 5, width, itemHeight - 5, tocolor ( 0, 0, 0, 200 ) )
		dxDrawText ( item.text, x, _y, x + width, _y + itemHeight, tocolor ( 255, 255, 255, 255 ), 1.2, "clear", "center", "center" )
		
		if now - item.ticks > 2000 then
			table.remove ( InfoDrawer.items, i )
			if #InfoDrawer.items == 0 then
				removeEventHandler ( "onClientRender", root, InfoDrawer.onRender )
			end
		end
	end
end

addEvent ( "onClientChangeInfo", true )
addEventHandler ( "onClientChangeInfo", resourceRoot,
	function ( id, text )
		InfoDrawer.addString ( id, text )
	end
, false )

--[[
	Game:SpawnPosition
]]
NodeRef "Game:SpawnPosition" {
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
--[[NodeRef "Game:Inventory" {
	events = {
		target = "entity",
		inputs = {
			{ "doGiveItem", "any" },
			{ "doTakeItem", "any" },
			{ "Item", "string" },
			{ "Amount", "number" }
		}
	}
}]]

--[[
	Game:Keypad
]]
NodeRef "Game:Keypad" {
	events = {
		target = "player",
		inputs = {
			{ "doShow", "player", _LD"NMKeypadShow" }
		},
		outputs = {
			{ "onInput", "string", _LD"NEKeypadInput" },
			{ "Player", "player", _LD"NEPlayer" }
		}
	}
}

local keypadCb = function ( inputStr )
	triggerServerEvent ( "onKeypadAction", resourceRoot, inputStr )
end

addEvent ( "onClientKeypadAction", true )
addEventHandler ( "onClientKeypadAction", resourceRoot,
	function ( )
		AdvancedKeypad.create ( keypadCb )
	end
, false )

--[[
	Game:Menu
]]
NodeRef "Game:Menu" {
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
local function menuCallback ( index )
	toggleAllControls ( true, true, false )
	triggerServerEvent ( "onGameMenu", resourceRoot, index )
end

addEvent ( "onClientShowMenu", true )
addEventHandler ( "onClientShowMenu", resourceRoot,
	function ( items, name, keep )
		SAMenu.create ( items, name, menuCallback, keep )
		toggleAllControls ( false, true, false )
	end
, false )

--[[
	Game:Dialog
]]
NodeRef "Game:Dialog" {
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

local _onDialogCallback = function ( index )
	triggerServerEvent ( "onGameDialog", resourceRoot, index )
end
addEvent ( "onClientShowDialog", true )
addEventHandler ( "onClientShowDialog", resourceRoot,
	function ( items, name )
		GameDialog.create ( items, name, _onDialogCallback )
		toggleAllControls ( false, true, false )
	end
, false )

--[[
	Game:BindKey
]]
NodeRef "Game:BindKey" {
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
--[[NodeRef "Game:Spawn" {
	events = {
		--target = "player",
		inputs = {
			{ "doSpawn", "any" },
			{ "Position", "Vector3D" },
			{ "Rotation", "number" },
			{ "Skin", "number" }
		}
	}
}]]

--[[
	Game:CommandHandler
]]
NodeRef "Game:CommandHandler" {
	events = {
		target = "player",
		inputs = {
			--{ "doAdd", "any" },
			--{ "doRemove", "any" },
			{ "CommandName", "string" }
		},
		outputs = {
			{ "onEvent", "stream", "Arguments" }
		}
	}
}

--------------------------
-- Gate группа          --
-- Гейты                --
--------------------------
-- Not
NodeRef "Gate:Not" {
	events = {
		inputs = {
			{ "doOp", "bool", "Операнд" }
		},
		outputs = {
			{ "onResult", "bool", "Результат" }
		}
	}
}

-- And
NodeRef "Gate:And" {
	events = {
		inputs = {
			{ "doOperation", "any" },
			{ "Op1", "bool", "Операнд 1" },
			{ "Op2", "bool", "Операнд 2" }
		},
		outputs = {
			{ "onTrue", "any", "Вызывается при выполнении условий"  },
			{ "onFalse", "any", "Вызывается при невыполнении условий" }
		}
	}
}

--------------------------
-- Math группа          --
-- Математика           --
--------------------------

-- Math Random
NodeRef "Math:Random" {
	events = {
		inputs = {
			{ "doRandom", "any" },
			{ "Min", "number", "Минимальное значение" },
			{ "Max", "number", "Максимальное значение" }
		},
		outputs = {
			{ "onResult", "number" }
		}
	}
}

--Math Less
NodeRef "Math:Less" {
	events = {
		inputs = {
			{ "doMath", "any" },
			{ "A", "number", "Минимальное значение" },
			{ "B", "number", "Максимальное значение" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Math:Add
	Сложение
]]
NodeRef "Math:Add" { 
	events = {
		inputs = {
			{ "doMath", "any" },
			{ "Op1", "number" },
			{ "Op2", "number" }
		},
		outputs = {
			{ "onMath", "any" },
			{ "Result", "number" }
		}
	}
}

--[[
	Math:Sub
]]
NodeRef "Math:Sub" { 
	events = {
		inputs = {
			{ "doMath", "any" },
			{ "Op1", "number" },
			{ "Op2", "number" }
		},
		outputs = {
			{ "onMath", "any" },
			{ "Result", "number" }
		}
	}
}

--[[
	Math:ToBoolean
	Выдача bool значения
]]
NodeRef "Math:ToBoolean" { 
	events = {
		inputs = {
			{ "doTrue", "any" },
			{ "doFalse", "any" }
		},
		outputs = {
			{ "onBool", "bool" }
		}
	}
}

--[[
	Math:FromBoolean
]]
NodeRef "Math:FromBoolean" { 
	events = {
		inputs = {
			{ "Bool", "bool" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--------------------------
-- String группа        --
-- Работа со строками   --
--------------------------

-- String concat
NodeRef "String:Concat" {
	events = {
		inputs = {
			{ "doConcat", "any" },
			{ "String1", "string", "Первая строка" },
			{ "String2", "string", "Вторая строка" }
		},
		outputs = {
			{ "onResult", "string" }
		}
	}
}

--[[
	String:Equal
]]
NodeRef "String:Equal" { 
	events = {
		inputs = {
			{ "doСompare", "any" },
			{ "String1", "string", "Первая строка" },
			{ "String2", "string", "Вторая строка" }
		},
		outputs = {
			{ "onTrue", "any", "Вызывается если строки равны" },
			{ "onFalse", "any", "Вызывается если строки не равны" }
		}
	}
}

------------------------
-- Tool группа        --
-- Утилиты            --
------------------------

--[[
	Tool:KeyToChannel
]]
local _outputs = { }
for i = 1, 10 do
	_outputs [ i ] = { "onEvent" .. i, "any" }
end

NodeRef "Tool:KeyToChannel" {
	events = {
		inputs = {
			{ "doEvent", "any" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:ChannelToKey
]]
local _inputs = { }
for i = 1, 10 do
	_inputs [ i ] = { "doWork" .. i, "any" }
end

NodeRef "Tool:ChannelToKey" {
	events = {
		inputs = _inputs,
		outputs = {
			{ "onKey", "number" }
		}
	}
}

--[[
	Tool:Hub
]]
local _inputs = { }
for i = 1, 6 do
	_inputs [ i ] = { "doIn" .. i, "any" }
end

local _outputs = { }
for i = 1, 6 do
	_outputs [ i ] = { "onOut" .. i, "any" }
end

NodeRef "Tool:Hub" { 
	events = {
		inputs = _inputs,
		outputs = _outputs
	}
}

-- Script
NodeRef "Tool:Script" {
	events = {
		outputs = {
			{ "onStart", "number", "Вызывается один раз при запуске скрипта" },
			{ "OwnerName", "string", _LD"NEToolScriptOwner" }
		}
	}
}

--[[
	Tool:Random
]]
local _outputs = { }
for i = 1, 6 do
	_outputs [ i ] = { "onOut" .. i, "any" }
end

NodeRef "Tool:RandomPort" {
	events = {
		inputs = {
			{ "doIn", "any" },
			{ "Min", "number" },
			{ "Max", "number" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:Switch
]]
NodeRef "Tool:Switch" {
	events = {
		inputs = { 
			{ "doSwitch", "any", "Переключить состояние с On на Off или наоборот с Off на On" }
		},
		outputs = {
			{ "onOn", "any", "Событие происходит всякий раз при переходе нода в состояние On" },
			{ "onOff", "any", "Событие происходит всякий раз при переходе нода в состояние Off" }
		}
	}
}

--[[
	Tool:Event
]]
NodeRef "Tool:Event" {
	events = {
		target = "element",
		inputs = { 
			{ "doTrigger", "any", "Вызывает событие для нодов прикрепленных к элементу <element>" },
			{ "EventName", "string" }
		},
		outputs = {
			{ "onEvent", "any", "Событие происходит всякий раз при вызове нода прикрепленного к элементу <element>"  },
		}
	}
}

--[[
	Tool:Timer
]]
NodeRef "Tool:Timer" {
	events = {
		target = "element",
		inputs = { 
			{ "doSet", "any" },
			{ "doKill", "any" },
			{ "Interval", "number" },
			{ "Times", "number" }
		},
		outputs = {
			{ "onEvent", "element" },
			{ "Element", "element" }
		}
	}
}

--[[
	Tool:IsElement
]]
NodeRef "Tool:IsElement" {
	events = {
		target = "element",
		inputs = { 
			{ "isElement", "any" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Tool:MultiData
]]
local _outputs = { }
for i = 1, 10 do
	_outputs [ i ] = { "onData" .. i, "any" }
end

NodeRef "Tool:MultiData" { 
	events = {
		inputs = {
			{ "doSeparate", "stream" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:Gate
]]
NodeRef "Tool:Gate" {
	events = {
		inputs = { 
			{ "doInput", "any" },
			{ "doOn", "any" },
			{ "doOff", "any" },
			{ "State", "bool" }
		},
		outputs = {
			{ "onOutput", "any" }
		}
	}
}

--[[
	Tool:Counter
]]
NodeRef "Tool:Counter" {
	events = {
		inputs = { 
			{ "doAdd", "any" },
			{ "doReset", "any" }
		},
		outputs = {
			{ "onAdd", "number" },
			{ "Count", "number" }
		}
	}
}

------------------------
-- Ped группа
-- Работа с педами
------------------------
NodeRef "Ped:Ped" {
	events = {
		target = "ped",
		outputs = {
			{ "onWasted", "any", "Вызывается при убийстве педа" }
		}
	}
}

-- Animation
NodeRef "Ped:Animation" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any", "Задает анимацию педу [ped]" },
			{ "doStop", "any", "Останавливает анимацию для педа [ped]" },
			{ "Block", "string", "Название блока анимации" },
			{ "Anim", "string", "Название анимации" },
			{ "Loop", "bool", "Зациклить анимацию[$Block|$Anim] для педа[^ped]" }
		},
		outputs = {
			{ "onStop", "any" }
		}
	}
}

--[[
	Ped:Weapon
]]
-- Список обязательно дублируется на сервере
local _weapons = {
	{ "Brass Knuckles" },
	
	{ "Golf Club" },
	{ "Nightstick" },
	{ "Knife" },
	{ "Baseball Bat" },
	{ "Shovel" },
	{ "Pool Cue" },
	{ "Katana" },
	{ "Chainsaw" },
	
	{ "Pistol" },
	{ "Silenced Pistol" },
	{ "Desert Eagle" },
	
    { "Shotgun" },
	{ "Sawn-Off Shotgun" },
	{ "SPAZ-12 Combat Shotgun" },
	
	{ "Uzi" },
	{ "MP5" },
	{ "TEC-9" },
	
	{ "AK-47" },
	{ "M4" },
	
	{ "Country Rifle" },
	{ "Sniper Rifle" },
	
	{ "Rocket Launcher" },
	{ "Heat-Seeking RPG" },
	{ "Flamethrower" },
	{ "Minigun" },
	
	{ "Grenade" },
	{ "Tear Gas" },
	{ "Molotov Cocktails" },
	{ "Satchel Charges" },
	
	{ "Spraycan" },
	{ "Fire Extinguisher" },
	{ "Camera" },
	
	{ "Long Purple Dildo" },
	{ "Short tan Dildo" },
	{ "Vibrator" },
	{ "Flowers" },
	{ "Cane" },
	
	{ "Night-Vision Goggles" },
	{ "Infrared Goggles" },
	{ "Parachute" },
	
	{ "Satchel Detonator" }
}

PortCtrl "_weapon" {
	control = {
		"combobox",
			
		id = "wpn",
		text = "Оружие",
		items = _weapons
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value and value - 1 or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) + 1 )
	end
}

NodeRef "Ped:Weapon" {
	events = {
		target = "ped",
		inputs = {
			{ "doGive", "any", "Выдает педу <ped> оружие [Weapon]" },
			{ "Weapon", "_weapon", "Оружие" },
			{ "AmmoAmount", "number", "Количество боеприпасов" },
			{ "SetAsCurrent", "bool", "Сделать оружие текущим" }
		}
	}
}

-- Armor
NodeRef "Ped:Armor" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any", "Устанавливает педу значение брони" },
			{ "Armor", "number", "Значение брони" }
		}
	}
}

-- Headless
NodeRef "Ped:Headless" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any", "Показывает или скрывает голову педу [ped], в зависимости от значение [Headless]" },
			{ "Headless", "bool", "Если TRUE - скрывает голову, если FALSE - показывает" }
		}
	}
}

--[[
	Ped:OnFire
]]
NodeRef "Ped:OnFire" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any", "Поджигает или тушит педа [ped], в зависимости от значение [OnFire]" },
			{ "OnFire", "bool", "Если TRUE - поджигает, если FALSE - тушит" }
		}
	}
}

--[[
	Ped:InVehicle
]]
NodeRef "Ped:InVehicle" {
	events = {
		target = "ped",
		inputs = {
			{ "doCheck", "any" },
			{ "Vehicle", "vehicle" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Ped:OccupiedVehicle
]]
NodeRef "Ped:OccupiedVehicle" {
	events = {
		target = "ped",
		inputs = {
			{ "doGet", "any" }
		},
		outputs = {
			{ "onTrue", "vehicle" },
			{ "onFalse", "any" },
			{ "Vehicle", "vehicle" },
			{ "Seat", "number" }
		}
	}
}


--[[
	Ped:Warp
]]
NodeRef "Ped:Warp" {
	events = {
		target = "ped",
		inputs = {
			{ "doWarp", "any" },
			{ "Position", "Vector3D" }
		}
	}
}

WarpWarnUI = { }

function WarpWarnUI.create ( ownerName, x, y, z )
	if WarpWarnUI.visible then return end;
	
	WarpWarnUI.wnd = guiCreateWindow ( sw / 2 - 200, sh / 2 - 70, 400, 140, "Подтвердить перемещение", false )
	guiCreateLabel ( 10, 30, 380, 240, "Игрок " .. ownerName .. " требует вашего перемещения в точку с\nкоординатами (" .. x .. ", " .. y .. ", " .. z .. ").", false, WarpWarnUI.wnd )
	MoneyTransferWarnUI.accept = guiCreateButton ( 10, 100, 180, 30, "Переместиться", false, WarpWarnUI.wnd )
	addEventHandler ( "onClientGUIClick", MoneyTransferWarnUI.accept,
		function ( )
			triggerServerEvent ( "onPlayerConfirmWarp", resourceRoot )
			WarpWarnUI.destroy ( )
		end
	, false )
	WarpWarnUI.cancel = guiCreateButton ( 220, 100, 180, 30, "Отказаться", false, WarpWarnUI.wnd )
	addEventHandler ( "onClientGUIClick", WarpWarnUI.cancel, WarpWarnUI.destroy, false )
	
	showCursor ( true )
	
	WarpWarnUI.visible = true
end

function WarpWarnUI.destroy ( )
	destroyElement ( WarpWarnUI.wnd )
	WarpWarnUI.visible = nil
	
	showCursor ( false )
end

addEvent ( "onClientConfirmWarp", true )
addEventHandler ( "onClientConfirmWarp", resourceRoot,
	function ( ownerName, x, y, z )
		WarpWarnUI.create ( ownerName, x, y, z )
	end
, false )

--[[
	Ped:Skin
]]
NodeRef "Ped:Skin" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any", "Устанавливает педу скин" },
			{ "Skin", "number", "Скин" }
		}
	}
}

--[[
	Ped:WalkingStyle
]]
-- Список обязательно дублируется на сервере
local _wstyle = {
	"DEFAULT",
	"PLAYER",
	"PLAYER_F",
	"PLAYER_M",
	"ROCKET",
	"ROCKET_F",
	"ROCKET_M",
	"ARMED",
	"ARMED_F",
	"ARMED_M",
	"BBBAT",
	"BBBAT_F",
	"BBBAT_M",
	"CSAW",
	"CSAW_F",
	"CSAW_M",
	"SNEAK",
	"JETPACK",
	"MAN",
	"SHUFFLE",
	"OLDMAN",
	"GANG1",
	"GANG2",
	"OLDFATMAN",
	"FATMAN",
	"JOGGER",
	"DRUNKMAN",
	"BLINDMAN",
	"SWAT",
	"WOMAN",
	"SHOPPING",
	"BUSYWOMAN",
	"SEXYWOMAN",
	"PRO",
	"OLDWOMAN",
	"FATWOMAN",
	"JOGWOMAN",
	"OLDFATWOMAN",
	"SKATE"
}

PortCtrl "_wstyle" {
	control = {
		"combobox",
			
		id = "style",
		text = "Style",
		items = _wstyle
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value and value - 1 or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) + 1 )
	end
}

NodeRef "Ped:WalkingStyle" {
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "Style", "_wstyle" }
		},
		outputs = {
			{ "Style", "_wstyle" }
		}
	}
}


--[[
	Ped:JetPack
]]
NodeRef "Ped:JetPack" {
	events = {
		target = "ped",
		inputs = {
			{ "doGive", "any" },
			{ "doRemove", "any" }
		}
	}
}

------------------------
-- Vehicle группа     --
-- Работа с авто      --
------------------------
--[[
	Vehicle:Vehicle
]]
NodeRef "Vehicle:Vehicle" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doBlow", "any", "Взрывает авто <vehicle>" },
			{ "doFix", "any", "Ремонтирует авто <vehicle>" },
			{ "doFlip", "any", "Переворачивает авто <vehicle> на колеса" },
			{ "doSave", "any" }
		},
		outputs = {
			{ "onEnter", "any", "Вызывается когда игрок входит в авто <vehicle>" },
			{ "onExit", "any", "Вызывается когда игрок выходит из авто <vehicle>" },
			{ "onStartEnter", "player", _LD"NEVehVehStEnt" },
			{ "onStartExit", "player", _LD"NEVehVehStExit" },
			{ "Player", "player", "Элемент игрока" },
			{ "Speed", "number", "Текущая скорость" },
			{ "Controller", "player" }
		}
	}
}

--[[
	Vehicle:Doors
]]
local _doors = {
	{ "hood", 0 },
	{ "trunk", 1 },
	{ "front left", 2 },
	{ "front right", 3 },
	{ "rear left", 4 },
	{ "rear right", 5 }
}

PortCtrl "_door" {
	control = {
		"combobox",
			
		id = "door",
		text = "Дверь",
		items = _doors
	},
	
	setData = function ( self, value )
		self.control:setData ( value )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

NodeRef "Vehicle:Doors" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any", "Переключает состояние двери [Door] авто <vehicle>" },
			{ "doOpen", "any", "Открывает дверь авто <vehicle>" },
			{ "doClose", "any", "Закрывает дверь авто <vehicle>" },
			{ "Door", "_door", "Дверь" }
		}
	}
}

--[[
	Vehicle:Locked
]]
NodeRef "Vehicle:Locked" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any", "Переключает состояние блокировки авто <vehicle>" },
			{ "doLock", "any", "Блокирует двери авто <vehicle>" },
			{ "doUnlock", "any", "Разблокирует двери авто <vehicle>" },
			{ "isLocked", "any", _LD"NMVehLockIsLock" }
		},
		outputs = {
			{ "onLocked", "any", _LD"NEVehLockLocked" },
			{ "onUnlocked", "any", _LD"NEVehLockUnlocked" }
		}
	}
}

--[[
	Vehicle:Sirens
]]
NodeRef "Vehicle:Sirens" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any", "Переключает состояние сирены авто <vehicle>" },
			{ "doOn", "any", "Включает сирену авто <vehicle>" },
			{ "doOff", "any", "Выключает сирену авто <vehicle>" }
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
			{ "onKeyPress", "string", "Вызывается когда водитель авто <vehicle> нажимает клавишу и выдает ее в поток" },
			{ "onKeyRelease", "string", "Вызывается когда водитель авто <vehicle> отпускает клавишу и выдает ее в поток" }
		}
	}
}

--[[
	Vehicle:EngineState
]]
NodeRef "Vehicle:EngineState" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any", "Переключает состояние двигатель авто <vehicle>" },
			{ "doOn", "any", "Запускает двигатель авто <vehicle>" },
			{ "doOff", "any", "Останавливает двигатель авто <vehicle>" }
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
	events = {
		target = "vehicle",
		inputs = {
			{ "doToggle", "any", "Переключает состояние фар авто <vehicle>" },
			{ "doOn", "any", "Включает фары авто <vehicle>"  },
			{ "doOff", "any", "Выключает фары авто <vehicle>" },
			{ "doReset", "any", "Сброс состояния фар авто <vehicle>" }
		}
	}
}

--[[
	Vehicle:Paintjob
]]
NodeRef "Vehicle:Paintjob" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doSet", "any", "Изменяет покраску авто <vehicle> на [Id]" },
			{ "Id", "number", "Номер покраски" }
		}
	}
}

--[[
	Vehicle:Upgrade
]]
NodeRef "Vehicle:Upgrade" {
	events = {
		target = "vehicle",
		inputs = {
			{ "doAdd", "any", "Устанавливает апгрейд [Id] на авто <vehicle>" },
			{ "doRemove", "any", "Снимает апгрейд [Id] с авто <vehicle>" },
			{ "Id", "number", "Номер апгрейда (https://wiki.multitheftauto.com/wiki/Vehicle_Upgrades) " }
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

PortCtrl "_handling" {
	control = {
		"combobox",
			
		id = "hadl",
		text = "Handling",
		items = _handlingProperties
	},
	
	setData = function ( self, value )
		value = tonumber ( value )
		self.control:setData ( value and value - 1 or 0 )
	end,
	getData = function ( self )
		return tostring ( self.control:getData ( ) + 1 )
	end
}

NodeRef "Vehicle:Handling" {
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

------------------------
-- Array группа       --
-- Массивы            --
------------------------

--[[
	Array
]]
NodeRef "Array:Array" {
	events = {
		inputs = {
			{ "doAdd", "any" },
			{ "Array", "array" }
		}
	}
}

--[[
	Array:Enum
]]
NodeRef "Array:Enum" {
	events = {
		inputs = {
			{ "doEnum", "any", "Начинает перебор всех элементов массива" },
			{ "Array", "array" }
		},
		outputs = {
			{ "onItem", "any", "Выдает в поток очередной элемент массива" },
			{ "onStop", "any" },
			{ "Item", "any" }
		}
	}
}

--[[
-- ArrayRW
local arrrw = NodeReference.create ( "arrrw", "Array:ReadWrite" )
arrrw.events = {
	target = "array",
	inputs = {
		{ "doRead", "any", "Читает элемент массива" },
		{ "Index", "number", "Индекс для чтения" }
	},
	outputs = {
		{ "onItem", "any", "Выдает в поток элемент массива" }
	}
}]]

--[[
	Array:Length
]]
NodeRef "Array:Length" {
	events = {
		inputs = {
			{ "doGet", "any" },
			{ "Array", "array" }
		},
		outputs = {
			{ "onLength", "number" },
			{ "Length", "number" }
		}
	}
}

--------------------------
-- Weapon группа        --
-- Работа с оружием     --
--------------------------
--[[
	Weapon:Weapon
]]
NodeRef "Weapon:Weapon" {
	events = {
		target = "s_weapon",
		inputs = {
			{ "doToggle", "any" },
			{ "doSetFire", "any" },
			{ "doSetReady", "any" },
			{ "Target", "entity" }
		}
	}
}

--------------------------
-- Player группа        --
-- Работа с игроками    --
--------------------------
--[[
	Player:Player
]]
NodeRef "Player:Player" {
	events = {
		target = "player",
		outputs = {
			{ "Name", "string", "Имя игрока <player>" },
			{ "TeamName", "string", "Имя команды игрока <player>" },
			{ "onJoin", "any" },
			{ "onWasted", "any" },
			{ "onKill", "any" },
			{ "onStartSpawn", "any" },
			{ "onVehicleEnter", "stream", "1=vehicle, 2=seat, 3=jacker" },
			{ "onVehicleExit", "stream", "1=vehicle, 2=seat, 3=jacker" }
		}
	}
}


--[[
	Player:WantedLevel
]]
NodeRef "Player:WantedLevel" {
	events = {
		target = "player",
		inputs = {
			{ "doSet", "any" },
			{ "doGiveStar", "any" },
			{ "doTakeStar", "any" },
			{ "Stars", "number" }
		}
	}
}

--[[
	Player:InArea
]]
NodeRef "Player:InArea" {
	events = {
		target = "player",
		inputs = {
			{ "doCheck", "any" },
			{ "Area", "wbo:area" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Player:OccupiedArea
]]
NodeRef "Player:OccupiedArea" {
	events = {
		target = "player",
		inputs = {
			{ "doGet", "any" }
		},
		outputs = {
			{ "onTrue", "wbo:area" },
			{ "onFalse", "any" },
			{ "Area", "wbo:area" }
		}
	}
}

--[[
	Player:Money
]]
NodeRef "Player:Money" {
	events = {
		target = "player",
		inputs = {
			{ "doGive", "any" },
			{ "doTake", "any" },
			{ "doSet", "any" },
			{ "Amount", "number" }
		},
		outputs = {
			{ "onSuccess", "any" },
			{ "onFail", "any" }
		}
	}
}

--------------------------
-- Gui группа           --
-- Интерфейс            --
--------------------------

--[[
	GUI:GUI
]]
NodeRef "GUI:GUI" {
	events = {
		target = "player",
		inputs = {
			{ "doToggle", "any" },
			{ "doShow", "any" },
			{ "doHide", "any" },
			{ "doSetText", "any" },
			{ "Text", "string" }
		}
	}
}

--[[
	GUI:Button
]]
NodeRef "GUI:Button" {
	gui = "btn",

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onPressed", "any" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:CheckBox
]]
NodeRef "GUI:CheckBox" {
	gui = "checkbox",

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" },
			{ "Selected", "bool" }
		},
		outputs = {
			{ "onChange", "bool" },
			{ "onSelected", "any" },
			{ "onUnselected", "any" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:ComboBox
]]
NodeRef "GUI:ComboBox" {
	gui = "combobox",

	events = {
		inputs = {
			{ "Caption", "string" },
			{ "Items", "_array" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onSelect", "any" },
			{ "Key", "string" },
			{ "Value", "string" },
			{ "Index", "number" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:Edit
]]
NodeRef "GUI:Edit" {
	gui = "edit",

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onChange", "string" },
			{ "Text", "string" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:Label
]]
NodeRef "GUI:Label" {
	gui = "lbl",

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		}
	}
}