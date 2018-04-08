--------------------------------------
-- EditorGraph
-- 
--------------------------------------
EditorGraph = { }
EditorGraph.__index = EditorGraph

function EditorGraph.create ( id )
	local graph = setmetatable ( {
		id = id,
		nodes = { },
		edges = { }
	}, EditorGraph )
	
	return graph
end

function EditorGraph:addNode ( node )
	if node and node.id then
		self.nodes [ node.id ] = node
	end
end

function EditorGraph:addEdge ( edge )
	if edge and edge.id then
		self.edges [ edge.id ] = edge
	end
end

function EditorGraph:destroyEdge ( edge )
	self.edges [ edge.id ] = nil
end

function EditorGraph:destroyNode ( node )
	for _, edge in pairs ( self.edges ) do
		if edge.srcNode == node or edge.dstNode == node then
			self.edges [ edge.id ] = nil
		end
	end

	self.nodes [ node.id ] = nil
end

function EditorGraph:unpack ( packedGraph )
	local nodeIds = { }
	
	self.public = packedGraph [ 1 ]
	self.owner = packedGraph [ 2 ]
	self.name = packedGraph [ 3 ]
	
	for i = 4, #packedGraph do
		local item = packedGraph [ i ]
		local itemType = item [ 1 ]
		
		-- Node
		if itemType == 0 then
			local node = EditorNode.create (
				item [ 4 ], -- id,
				item [ 5 ], -- tag
				item [ 6 ] -- linked
			)
			if node then
				local properties = item [ 7 ]
				for j = 1, #properties do
					local property = properties [ j ]
				
					node:setProperty ( property [ 1 ], property [ 2 ] )
				end
				
				node:setPosition ( item [ 2 ], item [ 3 ] )
				node.graph = self
				self:addNode ( node )
			
				nodeIds [ item [ 4 ] ] = node
			end
		
		-- Edge
		elseif itemType == 1 then
			local nodeSrc = item [ 2 ]
			local nodeDst = item [ 4 ]
				
			local edge = EditorEdge.create ( 
				nodeIds [ nodeSrc ], item [ 3 ], nodeIds [ nodeDst ], item [ 5 ], item [ 6 ]
			)
			if edge then self:addEdge ( edge ) end;
			
			--nodeIds [ nodeSrc ]:addEdge ( item [ 3 ], edge )
		end
	end
end

function EditorGraph:unpackNode ( packedNode )
	local node = EditorNode.create (
		packedNode [ 4 ], -- id,
		packedNode [ 5 ], -- tag
		packedNode [ 6 ] -- linked
	)
	
	if node then
		local properties = packedNode [ 7 ]
		for j = 1, #properties do
			local property = properties [ j ]
				
			node:setProperty ( property [ 1 ], property [ 2 ] )
		end
	
		node:setPosition ( packedNode [ 2 ], packedNode [ 3 ] )
		node.graph = self
		self:addNode ( node )
	
		return node
	end
end

function EditorGraph:unpackEdge ( packedEdge )
	local nodeSrc = packedEdge [ 2 ]
	local nodeDst = packedEdge [ 4 ]

	local edge = EditorEdge.create ( 
		self.nodes [ nodeSrc ], packedEdge [ 3 ], self.nodes [ nodeDst ], packedEdge [ 5 ], packedEdge [ 6 ]
	)
	
	if edge then
		self:addEdge ( edge )
	
		return edge
	end
end

function EditorGraph:getConnectedToNodeEdge ( node, portIndex )
	portIndex = tonumber ( portIndex )

	for _, edge in pairs ( self.edges ) do
		if edge.dstNode == node and edge.dstPort == portIndex then
			return edge
		end
	end
end

--------------------------------------
-- EditorNode
-- Создается во время запуска скрипта, используется для обращения к методам описания и хранения переменных
--------------------------------------
EditorNode = { }
EditorNode.__index = EditorNode

function EditorNode.create ( id, tag, linked )
	local nodeAbsrt = getComponentByTag ( tag )
	if not nodeAbsrt then
		outputDebugString ( "ClientEditorNode: Для нода " .. tostring ( tag ) .. "(" .. tostring ( id ) .. ") отсутствует описание", 1 )
		return
	end
	
	local scriptNode = {
		abstr = nodeAbsrt,
		tag = tag,
		id = id,
		edges = { 
			-- Связи с другими нодами
		},
		x = 0, y = 0,
		linked = linked,
		properties = { }
	}
	
	return setmetatable ( scriptNode, EditorNode )
end

function EditorNode:getPosition ( )
	return self.x, self.y
end

function EditorNode:setPosition ( x, y )
	self.x = tonumber ( x ) or 0.4; self.y = tonumber ( y ) or 0.4;
end

function EditorNode:addEdge ( port, edge )
	if self.edges [ port ] == nil then
		self.edges [ port ] = { }
	end
	
	table.insert ( self.edges [ port ], edge )
end

function EditorNode:setProperty ( index, value )
	if tonumber ( index ) == nil then
		local inputs = self.abstr.events.inputs
		for i, input in ipairs ( inputs ) do
			if input [ 1 ] == index then
				index = i
				break
			end
		end
	end
	
	index = tonumber ( index )
	if index then 
		self.properties [ index ] = value 
		--outputDebugString(index .. "=" .. tostring(value ))
	end
end

function EditorNode:getProperty ( index, convert )
	local inputs = self.abstr.events.inputs

	if tonumber ( index ) == nil then
		for i, input in ipairs ( inputs ) do
			if input [ 1 ] == index then
				index = i
				break
			end
		end
	end
	
	index = tonumber ( index )
	if index then 
		local inputData = self.properties [ index ]
		if convert then
			local inputType = inputs [ index ] [ 2 ]
			if inputType == "Vector2D" then
				local x = gettok ( inputData, 1, 44 )
				local y = gettok ( inputData, 2, 44 )
				
				x, y = tonumber ( x ), tonumber ( y )
				
				return { x = x or 0, y = y or 0 }
			end
		end
		return inputData
	end
end

-- Local mode only
local defaultValues = { 
	[ "number" ] = "0",
	[ "Vector2D" ] = "0,0",
	[ "Vector3D" ] = "0,0,0",
	[ "color" ] = "0,0,0,0",
	[ "string" ] = "",
	[ "bool" ] = "0",
	[ "_array" ] = "1=Item 1,2=Item 2",
	[ "color" ] = "0,0,0,0"
}
function EditorNode:setupProperties ( )
	local nodeInputs = self.abstr.events.inputs
	if nodeInputs == nil then return end;

	for i = 1, #nodeInputs do
		local input = nodeInputs [ i ]
		local inputName, inputType = input [ 1 ], input [ 2 ]
		
		if inputType ~= "any" then
			self.properties [ i ] = tostring ( defaultValues [ inputType ] )
		end
	end
end

--------------------------------------
-- EditorEdge
-- 
--------------------------------------
EditorEdge = { }
EditorEdge.__index = EditorEdge

function EditorEdge.create ( srcNode, srcPort, dstNode, dstPort, id )
	srcPort, dstPort = tonumber ( srcPort ), tonumber ( dstPort )
	
	if not srcPort or not dstPort then
		outputDebugString ( "ClientEditorEdge: Один из портов не указан", 2 )
		return
	end
	if not srcNode or not dstNode then
		outputDebugString ( "ClientEditorEdge: Один из нодов не указан(" .. tostring ( srcNode ) .. ", " .. tostring ( dstNode ) .. ")", 2 )
		return
	end
	
	local srcOutputs = srcNode.abstr.events.outputs
	local dstInputs = dstNode.abstr.events.inputs
	
	if ( srcPort == 0 or ( srcOutputs and srcOutputs [ srcPort ] ) ) and
		( dstPort == 0 or ( dstInputs and dstInputs [ dstPort ] ) ) then
		local scriptEdge = {
			srcNode = srcNode, srcPort = srcPort,
			dstNode = dstNode, dstPort = dstPort,
			id = tostring ( id )
		}
	
		setmetatable ( scriptEdge, EditorEdge )
	
		return scriptEdge
	end
end