local NODE_DEBUG_LEVEL = 3

-- Флаги --
READ_ONLY = 0 -- Переменная нода не будет изменяться при работе схемы
CLEAR_TARGET = 11
PORT_SOURCE = 0

-- Защита от циклических вызовов --
local maxCallsPeriod = 100 -- Период(мс) в течении которого происходит подсчет количества срабатываний
local maxCalls = 100 -- Максимальное количество срабатываний порта в период

gNodeRefs = { }
gNodeRefGroups = { }

NodeReference = { }
NodeReference.__index = NodeReference

function NodeReference.create ( nodeDesc )
	if nodeDesc.events.inputs then
		nodeDesc.inputNames = { }
		for i, input in ipairs ( nodeDesc.events.inputs ) do
			local inputName = input [ 1 ]
			nodeDesc.inputNames [ inputName ] = i
		end
	end
	if nodeDesc.events.outputs then
		nodeDesc.outputNames = { }
		for i, output in ipairs ( nodeDesc.events.outputs ) do
			local outputName = output [ 1 ]
			nodeDesc.outputNames [ outputName ] = i
		end
	end
	
	return setmetatable ( nodeDesc, NodeReference )
end

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

function NodeReference:getPortIndexFromName ( name, isInput )
	if isInput then
		if self.inputNames then return self.inputNames [ name ] end;
	else
		if self.outputNames then return self.outputNames [ name ] end;
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
	if not gNodeRefGroups [ groupName ] then gNodeRefGroups [ groupName ] = { } end;
	gNodeRefGroups [ groupName ] [ nodeName ] = data
	
	if data.events.inputs then
		data.inputNames = { }
		for i, input in ipairs ( data.events.inputs ) do
			local inputName = input [ 1 ]
			data.inputNames [ inputName ] = i
		end
	end
	if data.events.outputs then
		data.outputNames = { }
		for i, output in ipairs ( data.events.outputs ) do
			local outputName = output [ 1 ]
			data.outputNames [ outputName ] = i
		end
	end
	
	setmetatable ( data, NodeReference )
end
function NodeRef ( name )
	_nodeCreateName = name
	return _createNode
end


ArgStream = {
	new = function ( self, ... )
		local stream = {
			0x12, ...
		}
		return stream
	end
}

------------------------
-- Event manager
------------------------
EventManager = { 
	items = { },
	eachItems = { },
	nodeBinds = { }
}

function EventManager.addHandler ( element, eventName, node )
	local elementEvent = EventManager.items [ element ]
	if not elementEvent then
		EventManager.items [ element ] = { events = { } }
		elementEvent = EventManager.items [ element ]
	end
	
	local eventBinds = elementEvent.events [ eventName ]
	if not eventBinds then
		elementEvent.events [ eventName ] = { }
		eventBinds = elementEvent.events [ eventName ]
	end
	
	-- Если функция уже была привязана раньше, отвязываем ее
	local nodeBindTo = EventManager.nodeBinds [ node ]
	if nodeBindTo then
		eventBinds [ node ] = nil
		--debugString ( "EventManager.addHandler " .. eventName .. " отвязывана от " .. tostring ( getElementID ( nodeBindTo ) ), 3 )
	end
	
	eventBinds [ node ] = true
	EventManager.nodeBinds [ node ] = element
	--debugString ( "EventManager.addHandler " .. eventName .. " привязана к " .. tostring ( getElementID ( element ) ), 3 )
end

--[[
	Добавляет обработчик события для всех элементов типа elementType в комнате для нода node
]]
function EventManager.addEachHandler ( elementType, eventName, node )
	local elementEvent = EventManager.eachItems [ elementType ]
	if elementEvent then
		local eventBinds = elementEvent.events [ eventName ]
		if eventBinds then
			eventBinds [ node ] = true
			
			--outputChatBox ( "Added each event handler[Reason: SET]" )
		else
			elementEvent.events [ eventName ] = { [ node ] = true }
			
			--outputChatBox ( "Added each event handler[Reason: ADD]" )
		end
	else
		EventManager.eachItems [ elementType ] = {
			events = {
				[ eventName ] = { [ node ] = true }
			}
		}
		
		--outputChatBox ( "Added each event handler[Reason: NEW](" .. elementType .. ", " .. eventName .. ")" )
	end
end

function EventManager.removeHandler ( element, eventName, node )
	local elementEvent = EventManager.items [ element ]
	if not elementEvent then return end;
	
	local eventBinds = elementEvent.events [ eventName ]
	if not eventBinds then return end;
	
	eventBinds [ node ] = nil
	
	--debugString ( "EventManager.removeHandler " .. eventName .. " удален от " .. getElementID ( element ), 3 )
end

function EventManager.removeEachHandler ( elementType, eventName, node )
	local elementEvent = EventManager.eachItems [ elementType ]
	if not elementEvent then return end;
	
	local eventBinds = elementEvent.events [ eventName ]
	if not eventBinds then return end;
	
	eventBinds [ node ] = nil
	
	--outputChatBox ( "EventManager.removeEachHandler " .. eventName .. " удален от " .. elementType )
end

function EventManager.triggerEvent ( element, eventName, input, value )
	local elementType = getElementType ( element )
	local elementEvent = EventManager.eachItems [ elementType ]
	if elementEvent then
		local eventBinds = elementEvent.events [ eventName ]
		if eventBinds then
			for node, _ in pairs ( eventBinds ) do
				node:triggerOutput ( PORT_SOURCE, element )
				node:triggerOutput ( input, value )
			end
		end
	end
	
	elementEvent = EventManager.items [ element ]
	if elementEvent then
		local eventBinds = elementEvent.events [ eventName ]
		if eventBinds then
			for node, _ in pairs ( eventBinds ) do
				node:triggerOutput ( input, value )
			end
		end
	end
end

--------------------------------------
-- Graph
-- 
--------------------------------------
Graph = { }
Graph.__index = Graph

local nodeIds = { }

function Graph.create ( element, editorGraph )
	local graph = setmetatable ( {
		element = element,
		nodes = { },
		root = createElement ( "ne:root" ),
		id = editorGraph.id,
		room = RoomManager.getElementRoom ( element )
	}, Graph )
	
	graph:setup ( editorGraph )
	
	-- Вызываем событие при запуске
	for _, node in pairs ( graph.nodes ) do
		if node.tag == "Tool:Script" then
			node:triggerOutput ( 1 )
			node:triggerOutput ( 2, editorGraph.owner )
		end
	end
	
	return graph
end

function Graph:destroy ( )
	for id, node in pairs ( self.nodes ) do
		local targetElement = LogicComponent.getLinkedElement ( node.linkedId ) or self.element
		EventManager.removeHandler ( targetElement, node.tag, node )

		local nodeAbsrt = node.abstr
		local nodeTargetType = nodeAbsrt.events.target
		if nodeTargetType then
			EventManager.removeEachHandler ( nodeTargetType, node.tag, node )
		end
		
		if nodeAbsrt [ "~target" ] then
			local targetElement = node.vars.target
			--if isElement ( targetElement ) then
				nodeAbsrt [ "~target" ] ( node, targetElement )
			--end
		end
		
		nodeIds [ id ] = nil
	end

	destroyElement ( self.root )
end

function Graph:setup ( editorGraph )
	local graphNodes = self.nodes
	
	-- Сначала создаем ноды
	local nodes = editorGraph.nodes
	for _, editorNode in pairs ( nodes ) do
		local node = ScriptNode.create ( editorNode )
		if node then
			node.graph = self
			node.bind = self.element -- Элемент, к которому прикреплен граф
			node.linkedId = editorNode.linked
			
			node:setupVars ( editorNode )
			
			local id = editorNode.id
			graphNodes [ id ] = node
			nodeIds [ id ] = node
		end
	end
	
	local edges = editorGraph.edges
	for _, editorEdge in pairs ( edges ) do
		local srcNode = graphNodes [ editorEdge.nodeSrc ]
		local srcPort = editorEdge.portSrc
		local dstNode = graphNodes [ editorEdge.nodeDst ]
		local dstPort = editorEdge.portDst
		
		local scriptEdge = ScriptEdge.create ( srcNode, srcPort, dstNode, dstPort )
		if scriptEdge then
			--scriptEdge.element = edge
			-- Если таблицы связей для порта srcPort нет, создаем ее
			if not srcNode.ports [ srcPort ] then srcNode.ports [ srcPort ] = { callsNum = 0 } end;
		
			table.insert ( srcNode.ports [ srcPort ], scriptEdge )
		else
			--debugString ( tostring ( editorEdge.nodeSrc ) .. ", " .. tostring ( editorEdge.nodeDst ) )
		end
	end
	
	-- Затем записываем их связи
	for _, node in pairs ( graphNodes ) do
		node:setupEdges ( editorGraph )
		--node:setupVars ( )
		
		local nodeEvents = node.abstr.events
		-- Инициализируем target, но не вызываем пока не будут созданы все связи
		if nodeEvents.target then
			targetElement = self.element
			-- Если уже есть элемент для бинда, устанавливаем его
			if type ( node.linkedId ) == "string" then
				if node.linkedId == "each" then
					EventManager.addEachHandler ( nodeEvents.target, node.tag, node )
				else
					targetElement = getElementByID ( node.linkedId )
				end
			end
			-- Если тип таргета комната, устанавливаем ее
			if nodeEvents.target == "room" then
				targetElement = self.room
			end
			
			node:setTarget ( targetElement, true )
		end
	end
	
	-- Вызываем методы для переменных и target'a после того как все связи созданы
	for _, node in pairs ( graphNodes ) do
		local vars = node.vars
		for name, value in pairs ( vars ) do
			if name == "target" then
				node:setTarget ( value )
			else
				node:callInput ( name, value )
			end
		end
	end
end

--------------------------------------
-- ScriptNode
-- Создается во время запуска скрипта, используется для обращения к методам описания и хранения переменных
--------------------------------------
ScriptNode = { }
ScriptNode.__index = ScriptNode

function ScriptNode.create ( editorNode )
	local nodeAbsrt = editorNode.abstr
	if not nodeAbsrt then
		--debugString ( "Для нода " .. tostring ( editorNode.tag ) .. " отсутствует описание", 1 )
		return
	end
	
	local nodeTag = editorNode.tag
	local nodeId = editorNode.id
	
	local scriptNode = {
		node = node,
		abstr = nodeAbsrt,
		tag = nodeTag,
		id = nodeId,
		vars = {
			-- Рабочие переменные
		},
		ports = {
			[ 0 ] = { callsNum = 0 }
			-- Связи с другими нодами
		},
		custom = { 
			-- Кастомные поля для использования внутри описания нодов
		}
	}
	
	return setmetatable ( scriptNode, ScriptNode )
end

function ScriptNode:setupVars ( editorNode )
	local nodeInputs = self.abstr.events.inputs
	if nodeInputs == nil then return end;

	for i = 1, #nodeInputs do
		local input = nodeInputs [ i ]
		local inputName, inputType = input [ 1 ], input [ 2 ]
		
		if inputType ~= "any" then
			local inputData = tostring ( editorNode.properties [ i ] )
			if inputType == "Vector2D" then
				local x = gettok ( inputData, 1, 44 )
				local y = gettok ( inputData, 2, 44 )
				
				x, y = tonumber ( x ), tonumber ( y )
				
				inputData = { x = x or 0, y = y or 0 }
			elseif inputType == "Vector3D" then
				local x = gettok ( inputData, 1, 44 )
				local y = gettok ( inputData, 2, 44 )
				local z = gettok ( inputData, 3, 44 )
				
				x, y, z = tonumber ( x ), tonumber ( y ), tonumber ( z )
				
				inputData = { x = x or 0, y = y or 0, z = z or 0 }
			elseif inputType == "color" then
				local r = gettok ( inputData, 1, 44 )
				local g = gettok ( inputData, 2, 44 )
				local b = gettok ( inputData, 3, 44 )
				local a = gettok ( inputData, 4, 44 )
				
				r, g, b, a = tonumber ( r ), tonumber ( g ), tonumber ( b ), tonumber ( a )
				
				inputData = { r = r or 0, g = g or 0, b = b or 0, a = a or 0 }
			elseif inputType == "number" then
				inputData = tonumber ( inputData ) or 0
			elseif inputType == "bool" then
				inputData = tonumber ( inputData ) == 1
			elseif inputType == "array" or inputType == "_array" then
				local result = { }
				
				local items = split ( inputData, 44 )
				for i = 1, #items do
					local itemStr = items [ i ]
					
					local key = gettok ( itemStr, 1, 61 )
					local value = gettok ( itemStr, 2, 61 )
					
					result [ #result + 1 ] = {
						tostring ( key ), tostring ( value )
					}
				end
				
				inputData = result
			end
			
			self.vars [ inputName ] = inputData
			
			--outputChatBox ( "SET VAR: tag=" .. self.tag .. ", var=" .. tostring ( inputName ) .. " = data=" .. tostring ( inputData ) )
		end
	end
end

local _sortFn = function ( a, b )
	local aIndex = 0
	if a.dstPort > 0 then
		local dstInput = a.dstNode.abstr.events.inputs [ a.dstPort ]
		aIndex = dstInput [ 2 ] ~= "any" and 1 or 2
	end
	
	local bIndex = 0
	if b.dstPort > 0 then
		local dstInput = b.dstNode.abstr.events.inputs [ b.dstPort ]
		bIndex = dstInput [ 2 ] ~= "any" and 1 or 2
	end
	
	return aIndex < bIndex
end

function ScriptNode:setupEdges ( editorGraph )
	--[[local edges = editorGraph.edges
	for i = 1, #edges do
		local edge = edges [ i ]
		local srcNode = edge.nodeSrc
		local srcPort = edge.portSrc
		local dstNode = edge.nodeDst
		if dstNode then dstNode = nodeIds [ dstNode ] 
		else debugString ( "Неопределенный нод", 2 ) end;
		local dstPort = edge.portDst
		
		local scriptEdge = ScriptEdge.create ( self, srcPort, dstNode, dstPort )
		if scriptEdge then
			scriptEdge.element = edge
			-- Если таблицы связей для порта srcPort нет, создаем ее
			if not self.edges [ srcPort ] then self.edges [ srcPort ] = { } end;
		
			table.insert ( self.edges [ srcPort ], scriptEdge )
		end
	end]]
	
	for port, edges in pairs ( self.ports )  do
		table.sort ( edges, _sortFn )
		
		--[[outputChatBox ( self.tag .. " port " .. port )
		for _, edge in ipairs ( edges ) do
			if edge.dstPort > 0 then
				local dstInput = edge.dstNode.abstr.events.inputs [ edge.dstPort ]
				outputChatBox ( dstInput [ 1 ] )
			else
				outputChatBox ( "target" )
			end
		end]]
	end
end

function ScriptNode:setTarget ( element, silent )
	if self.linkedId == "each" or self.linkedId == "random" then
		return
	end

	if isElement ( element ) ~= true then
		--if element == false then
			if isElement ( self.vars.target ) then
				EventManager.removeHandler ( self.vars.target, self.tag, self )
			end
			self.vars.target = nil 
		--end
	
		return
	end

	local tarType = self.abstr.events.target
	local elType = getElementType ( element )

	local isEntityType = tarType == "entity" and isEntityType ( elType )
	local isPed = tarType == "ped" and ( elType == "ped" or elType == "player" )

	if tarType == "element" or tarType == elType or isEntityType or isPed then
		self.vars.target = element
		
		if silent == true then return end;
		
		if self.abstr._target then
			self.abstr._target ( self, element )
		end
		
		self:triggerOutput ( PORT_SOURCE, element )
		
		-- Создаем обработчик только когда у нода есть порты выхода
		local outputs = self.abstr.events.outputs
		if outputs and #outputs > 0 then
			EventManager.addHandler ( element, self.tag, self )
		end
	end
end

function ScriptNode:setVar ( port, value )
	local nodeAbsrt = self.abstr
	local input = nodeAbsrt.events.inputs [ port ]
	local inputName = input [ 1 ]
	local inputType = input [ 2 ]
	
	if inputType == "string" then
		value = tostring ( value )
	elseif inputType == "number" then
		value = tonumber ( value ) or 0
	end
	
	self.vars [ inputName ] = value
	
	--debugString ( "Set var " .. self.tag, 3 )
end

function ScriptNode:triggerOutput ( port, value )
	--debugString ( "ScriptNode: вызов события " .. self.tag .. ", " .. tostring ( port ) .. ", " .. tostring ( value ), 3 )
	
	-- Для защиты некоторых нодов(таких как GameRoom)
	--[[if port == PORT_SOURCE and self.linkedId ~= "each" then
		return
	end]]
	
	local triggerPort = self.ports [ port ]
	if not triggerPort then 
		--debugString ( "Нет связей для такого порта(" .. self.id .. ", " .. port .. ")", 2 )
		return 
	end

	local now = getTickCount ( )
	if triggerPort.ticks and now - triggerPort.ticks < maxCallsPeriod then
		triggerPort.callsNum = triggerPort.callsNum + 1
		-- Если кол-во вызовов порта превышает допустимое, выходим из функции
		if triggerPort.callsNum > maxCalls then
			return
		end
	else
		triggerPort.callsNum = 0
	end
	triggerPort.ticks = now
	
	--[[local nodeOutputs = self.abstr.events.outputs
	if nodeOutputs [ port ] [ 2 ] == "any" or triggerPort.value ~= value or type ( value ) == "table" then]]
		--triggerPort.value = value
		
		for i = 1, #triggerPort do
			local edge = triggerPort [ i ]
			--debugString ( "ScriptNode: вызов связи tag=" .. edge.dstNode.tag ..", port=" .. edge.dstPort .. ", value=" .. tostring ( value ), 3 )
			edge:trigger ( value )
		end
		
		--self:clientTraceback ( port, value )
	--[[elseif WBO_DEBUG then
		outputChatBox ( "повтор вызова. отклонить.(" .. self.tag .. ", " .. port .. ")" )
	end]]
end

function ScriptNode:callInput ( varName, value, port )
	local nodeAbstr = self.abstr
	
	--outputChatBox ( "callInput: in=" .. tostring ( varName ) .. ", port=" .. tostring ( port ) .. ", self=" .. tostring ( self.tag ) )
	
	if nodeAbstr._input then
		if not port then
			port = nodeAbstr:getPortIndexFromName ( varName )
		end
		nodeAbstr._input ( self, value, port )
	end

	if nodeAbstr [ varName ] then
		nodeAbstr [ varName ] ( self, value )
	end
end

function ScriptNode:getRootElement ( )
	return self.graph.root
end

function ScriptNode:getRoom ( )
	return self.graph.room
end

function ScriptNode:_getOwner ( )
	local element = self.graph.element
	if getElementType ( element ) == "player" then
		local account = getPlayerAccount ( element )
		if isGuestAccount ( account ) then
			return ""
		else
			return getAccountName ( account )
		end
	end
	
	return getElementData ( element, "owner" )
end

function ScriptNode:clientTraceback ( port, value )
	triggerClientEvent ( "onClientNodeTraceback", resourceRoot, self.graph.id, self.id, port, value )
end

--------------------------------------
-- ScriptEdge
-- 
--------------------------------------
ScriptEdge = { }
ScriptEdge.__index = ScriptEdge

function ScriptEdge.create ( srcNode, srcPort, dstNode, dstPort )
	if srcNode == nil or dstNode == nil then
		--debugString ( "ScriptEdge: Ошибка при создании связи(" .. tostring ( srcNode ) .. ", " .. tostring ( dstNode ) .. ")", 1 )

		return
	end
	
	local srcOutputs = srcNode.abstr.events.outputs
	local dstInputs = dstNode.abstr.events.inputs
	
	if ( srcPort == 0 or ( srcOutputs and srcOutputs [ srcPort ] ) ) and
		( dstPort == 0 or ( dstInputs and dstInputs [ dstPort ] ) ) then
		local scriptEdge = {
			srcNode = srcNode, srcPort = srcPort,
			dstNode = dstNode, dstPort = dstPort
		}
	
		setmetatable ( scriptEdge, ScriptEdge )
	
		return scriptEdge
	end
end

function ScriptEdge:trigger ( value )
	local dstNode = self.dstNode

	--local WBO_DEBUG =true
	-- Если это target тип порта
	if self.dstPort == 0 then
		dstNode:setTarget ( value )
		--debugString ( "Set target " .. dstNode.tag, 3 )
		return
	end
	
	local dstNodeAbstr = dstNode.abstr
	local input = dstNodeAbstr.events.inputs [ self.dstPort ]
	local inputName = input [ 1 ]
	local inputType = input [ 2 ]
	local inputProperty = input [ 3 ]
	
	if inputType ~= "any" then
		if inputProperty ~= READ_ONLY then
			--dstNode.vars [ inputName ] = value
			dstNode:setVar ( self.dstPort, value )
			--debugString ( "Set var " .. dstNode.tag, 3 )
		end
	end
	
	-- Если у нода прописан таргет и он при этом не забинден, выходим из функции
	local nodeTargetType = dstNodeAbstr.events.target
	if nodeTargetType then
		if isElement ( dstNode.vars.target ) ~= true then
			--debugString ( "У нода [" .. dstNode.tag .. "] отсутствует бинд. Выход из триггера.", 3 )
			
			if inputType == "any" then
				if dstNode.linkedId == "each" then
					
					--[[local elements = getElementsByType ( nodeTargetType, resourceRoot )
					for _, element in ipairs ( elements ) do
						dstNode:setTarget ( element )
						dstNode:callInput ( inputName, value, self.dstPort )
					end
					dstNode:setTarget ( )]]
					
				end
			end
			
			return
		end
	end

	--outputChatBox ( "ВЫЗОВ: tag=" .. dstNode.tag .. ", id=" .. dstNode.id .. ", in=" .. inputName .. ", from " .. self.srcNode.tag )
	
	--outputChatBox ( "ВЫЗОВ: tag=" .. dstNode.tag .. ", id=" .. dstNode.id .. ", in=" .. inputName .. ", from " .. self.srcNode.tag )
	
	dstNode:callInput ( inputName, value, self.dstPort )
	
	--[[if input [ 3 ] == CLEAR_TARGET then
		dstNode:setTarget ( false )
	end]]
end

----------------------
-- GraphManager
---------------------
local elementGraphs = { } -- Схемы, которые прикреплены к элементу [element] = { graphs }
local graphElements = { } -- Элементы, к которым прикреплена схема [graph] = { elements }
--local MG_PLAYER_ONLY = false

--[[
function destroyNodeRef ( node )
	local id = getElementID ( node )
	local nodeRef = nodeIds [ id ]
	if nodeRef then
		local graph = nodeRef.graph
		local targetElement = LogicComponent.getLinkedElement ( node ) or graph.element
		
		EventManager.removeHandler ( targetElement, nodeRef.tag, nodeRef )
		
		graphItems [ graph.element ].nodes [ id ] = nil
		nodeIds [ id ] = nil
	end
end]]

function refreshGraphElements ( graph )
	local graphId = graph.id
	local elements = graphElements [ graphId ]
	if elements then
		local numOfElements = 0
		
		for element, _ in pairs ( elements ) do
			local graphs = elementGraphs [ element ]
			local attachedGraph = graphs [ graphId ]
			if attachedGraph then
				attachedGraph:destroy ( )
				graphs [ graphId ] = Graph.create ( element, graph )
				numOfElements = numOfElements + 1
			end
		end
		collectgarbage ( )
	
		return numOfElements
	end
	
	return 0
end

function applyElementGraph ( element, graph )
	if graph.nodeNum < 2 then return end;

	local graphs = elementGraphs [ element ]
	if graphs then
		local attachedGraph = graphs [ graph.id ]
		-- Если граф с таким id уже был прикреплен к элементу, сначала удаляем его
		if attachedGraph then
			attachedGraph:destroy ( )
			graphs [ attachedGraph.id ] = nil
			graphs.refs = graphs.refs - 1

			-- Удаляем данные о элементе, к которому крепилась схема
			local elements = graphElements [ graph.id ]
			if elements then
				elements [ element ] = nil
			end
			
			collectgarbage ( )
			--debugString ( "Removed the graph attached to the element [" .. getElementType ( element ) .. "]" )
			
		-- Удаляем все графы если стоит флаг
		--[[elseif getElementType ( element ) ~= "player" and MG_PLAYER_ONLY then
			for id, attachedGraph in pairs ( elementGraphs ) do
				if id ~= "refs" then
					attachedGraph:destroy ( )
					elementGraphs [ id ] = nil
					elementGraphs.refs = elementGraphs.refs - 1
				end
			end
			collectgarbage ( "collect" )
			debugString ( "Remove all graphs for the element [" .. getElementType ( element ) .. "]" )]]
		end
	else
		graphs = { refs = 0 }
		elementGraphs [ element ] = graphs
	end
	
	graphs [ graph.id ] = Graph.create ( element, graph )
	graphs.refs = graphs.refs + 1
	
	-- Сохраняем данные о элементе, к которому крепится схема
	local elements = graphElements [ graph.id ]
	if elements then
		elements [ element ] = true
	else
		graphElements [ graph.id ] = {
			[ element ] = true
		}
	end
	
	--debugString ( "Now the element with type '" .. getElementType ( element ) .. "' has " .. elementGraphs.refs .. " graphs" )
	
	return true
end

function removeElementGraph ( element, graph )
	local graphs = elementGraphs [ element ]
	if graphs then
		local attachedGraph = graphs [ graph.id ]
		if attachedGraph then
			attachedGraph:destroy ( )
			graphs [ attachedGraph.id ] = nil
			graphs.refs = graphs.refs - 1
			
			-- Удаляем данные о элементе, к которому крепилась схема
			local elements = graphElements [ graph.id ]
			if elements then
				elements [ element ] = nil
			end
			
			collectgarbage ( )
			--debugString ( "Removed the graph for the element [" .. getElementType ( element ) .. "]" )
			
			return true
		end
	end
end

function getElementGraphs ( element )
	return elementGraphs [ element ]
end

function getGraphElements ( graphId )
	if type ( graphId ) == "table" then
		graphId = graphId.id
	end
	
	return graphElements [ graphId ]
end

addEventHandler ( "onElementDestroy", resourceRoot,
	function ( )
		local graphs = elementGraphs [ source ]
		if graphs then
			for id, attachedGraph in pairs ( graphs ) do
				if id ~= "refs" then
					attachedGraph:destroy ( )
					
					-- Удаляем данные о элементе, к которому крепилась схема
					local elements = graphElements [ id ]
					if elements then
						elements [ source ] = nil
					end
				end
			end
			--collectgarbage ( )
		end
		elementGraphs [ source ] = nil
	end
)