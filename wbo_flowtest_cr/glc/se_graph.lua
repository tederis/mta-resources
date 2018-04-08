--[[
	EditorGraph
	Шаблон схемы. Создается только во время редактировании схемы.
]]

EditorGraph = { }
EditorGraph.__index = EditorGraph

function EditorGraph.create ( id, name )
	local graph = {
		nodes = { },
		nodeNum = 0,
		edges = { },
		name = tostring ( name ),
		id = tostring ( id )
	}
	
	setmetatable ( graph, EditorGraph )
	
	return graph
end

function EditorGraph:loadFromXml ( xml )
	local ownerName = xmlNodeGetAttribute ( xml, "owner" )
	local isPublic = xmlNodeGetAttribute ( xml, "public" ) == "1"
	local name = xmlNodeGetAttribute ( xml, "name" )
	
	self.owner = tostring ( ownerName )
	self.public = isPublic
	self.name = tostring ( name )

	local nodes = xmlNodeGetChildren ( xml )
	for i = 1, #nodes do
		local noden = nodes [ i ]
		
		local xmlNodeName = xmlNodeGetName ( noden )
		if xmlNodeName == "node" then
			local nodeId = xmlNodeGetAttribute ( noden, "id" )
			local tag = xmlNodeGetAttribute ( noden, "tag" )
			local linked = xmlNodeGetAttribute ( noden, "linkedID" )
		
			local node = EditorNode.create ( nodeId, tag, linked )
			if node then
				local posX = xmlNodeGetAttribute ( noden, "posX" )
				local posY = xmlNodeGetAttribute ( noden, "posY" )
				node:setPosition ( posX, posY )
			
				local properties = xmlNodeGetChildren ( noden )
				for j = 1, #properties do
					local propertyn = properties [ j ]
				
					local index = xmlNodeGetAttribute ( propertyn, "index" )
					local value = xmlNodeGetAttribute ( propertyn, "value" )
				
					node:setProperty ( index, value )
				end
			
				self.nodes [ nodeId ] = node
				self.nodeNum = self.nodeNum + 1
			end
		elseif xmlNodeName == "edge" then
			local nodeSrc = xmlNodeGetAttribute ( noden, "nodeSrc" )
			local portSrc = xmlNodeGetAttribute ( noden, "portSrc" )
			local nodeDst = xmlNodeGetAttribute ( noden, "nodeDst" )
			local portDst = xmlNodeGetAttribute ( noden, "portDst" )
			local edgeId = generateString ( 10 )
			
			local edge = EditorEdge.create ( nodeSrc, portSrc, nodeDst, portDst, edgeId )
			if edge then 
				self.edges [ edgeId ] = edge
				local _node = self.nodes [ nodeSrc ]
				if _node then _node:addEdge ( portSrc, edge ) end;
			end
		end
	end
end

function EditorGraph:saveToXml ( xml )
	xmlNodeSetAttribute ( xml, "owner", tostring ( self.owner ) )
	xmlNodeSetAttribute ( xml, "public", self.public and "1" or "0" )
	xmlNodeSetAttribute ( xml, "name", tostring ( self.name ) )

	for _, node in pairs ( self.nodes ) do
		local xmlnode = xmlCreateChild ( xml, "node" )
		xmlNodeSetAttribute ( xmlnode, "id", node.id )
		xmlNodeSetAttribute ( xmlnode, "tag", node.tag )
		xmlNodeSetAttribute ( xmlnode, "posX", tostring ( node.x ) )
		xmlNodeSetAttribute ( xmlnode, "posY", tostring ( node.y ) )
		if node.linked then
			xmlNodeSetAttribute ( xmlnode, "linkedID", node.linked )
		end
		
		local properties = node.properties
		for index, value in pairs ( properties ) do
			local propxml = xmlCreateChild ( xmlnode, "property" )
			xmlNodeSetAttribute ( propxml, "index", tostring ( index ) )
			xmlNodeSetAttribute ( propxml, "value", tostring ( value ) )
		end
	end
	
	for _, edge in pairs ( self.edges ) do
		local xmlnode = xmlCreateChild ( xml, "edge" )
		xmlNodeSetAttribute ( xmlnode, "id", edge.id )
		xmlNodeSetAttribute ( xmlnode, "nodeSrc", edge.nodeSrc )
		xmlNodeSetAttribute ( xmlnode, "portSrc", tostring ( edge.portSrc ) )
		xmlNodeSetAttribute ( xmlnode, "nodeDst", edge.nodeDst )
		xmlNodeSetAttribute ( xmlnode, "portDst", tostring ( edge.portDst ) )
	end
end

function EditorGraph:addNode ( node )
	self.nodes [ node.id ] = node
	self.nodeNum = self.nodeNum + 1
end

function EditorGraph:addEdge ( edge )
	self.edges [ edge.id ] = edge
end

function EditorGraph:destroyNode ( node )
	if node and node.id then
		local nodeId = node.id
		for _, edge in pairs ( self.edges ) do
			if edge.nodeSrc == nodeId or edge.nodeDst == nodeId then
				self.edges [ edge.id ] = nil
			end
		end

		self.nodes [ nodeId ] = nil
		self.nodeNum = self.nodeNum - 1
	end
end

function EditorGraph:destroyEdge ( edge )
	if edge and edge.id then
		self.edges [ edge.id ] = nil
	end
end

function EditorGraph:getConnectedToNodeEdge ( node, portIndex )
	portIndex = tonumber ( portIndex )
	local nodeId = node.id
	for _, edge in pairs ( self.edges ) do
		if edge.nodeDst == nodeId and edge.portDst == portIndex then
			return edge
		end
	end
end

function EditorGraph:unpack ( packedGraph )
	local nodeIds = { }
	
	for i = 1, #packedGraph do
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
				
					--outputChatBox("unpack prop " .. property [ 1 ] .. "=" .. property [ 2 ])
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
				nodeSrc, item [ 3 ], nodeDst, item [ 5 ], item [ 6 ]
			)
			
			self:addEdge ( edge )
			
			nodeIds [ nodeSrc ]:addEdge ( item [ 3 ], edge )
		end
	end
end

EditorNode = { }
EditorNode.__index = EditorNode

function EditorNode.create ( id, tag, linked )
	local nodeAbstr = getComponentByTag ( tag )
	if not nodeAbstr then
		return
	end
	
	local node = { 
		x = 0, y = 0,
		id = tostring ( id ),
		tag = tostring ( tag ),
		edges = { },
		abstr = nodeAbstr,
		properties = { }
	}
	if linked then 
		if isElement ( linked ) then
			node.linked = createElementID ( linked )
		else
			node.linked = tostring ( linked ) 
		end
	end
	
	setmetatable ( node, EditorNode )
	
	return node
end

function EditorNode:setPosition ( x, y )
	self.x = tonumber ( x ) or 0; self.y = tonumber ( y ) or 0;
end

function EditorNode:addEdge ( port, edge )
	port = tonumber ( port )

	if not self.edges [ port ] then
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


EditorEdge = { }
EditorEdge.__index = EditorEdge

function EditorEdge.create ( nodeSrc, portSrc, nodeDst, portDst, id )
	local edge = { 
		nodeSrc = nodeSrc, portSrc = tonumber ( portSrc ),
		nodeDst = nodeDst, portDst = tonumber ( portDst ),
		id = tostring ( id )
	}
	
	setmetatable ( edge, EditorEdge )
	
	return edge
end




GraphManager = { 
	available = { }
}

function GraphManager.loadCatalogFromXml ( xmlfile )
	local catalog = GraphManager.available
	local xmlnodes = xmlNodeGetChildren ( xmlfile )
	for i = 1, #xmlnodes do
		local xmlnode = xmlnodes [ i ]
		
		local id = xmlNodeGetAttribute ( xmlnode, "id" )
		local filename = "graphs/" .. id .. ".xml"
		local xmlfile = xmlLoadFile ( filename )
		if xmlfile then
			local graph = EditorGraph.create ( id )
			graph:loadFromXml ( xmlfile )
			catalog [ id ] = graph
			
			xmlUnloadFile ( xmlfile )
		end
	end
end

function GraphManager.saveCatalogToXml ( xmlfile )
	local catalog = GraphManager.available
	for id, _ in pairs ( catalog ) do
		local xmlnode = xmlCreateChild ( xmlfile, "graph" )
		xmlNodeSetAttribute ( xmlnode, "id", id )
	end
end

function GraphManager.findPlayerGraphs ( accountName )
	local playerGraphs = { }

	local catalog = GraphManager.available
	for id, graph in pairs ( catalog ) do
		if graph.public or graph.owner == accountName then
			playerGraphs [ #playerGraphs + 1 ] = {
				id,
				graph.owner,
				graph.public,
				graph.name
			}
		end
	end
	
	return playerGraphs
end

function GraphManager.findRoomGraphs ( room )
	local roomGraphs = { }
	
	local roomId = getElementID ( room )
	local catalog = GraphManager.available
	for id, graph in pairs ( catalog ) do
		if graph.room == roomId then
			roomGraphs [ #roomGraphs + 1 ] = {
				id,
				graph.name,
				graph.owner
			}
		end
	end
	
	return roomGraphs
end

function GraphManager.addGraphToCatalog ( graph )
	local catalog = GraphManager.available
	if catalog [ graph.id ] then return end;
	catalog [ graph.id ] = graph
	
	-- Сохраняем в файл
	local filename = "graphs/" .. graph.id .. ".xml"
	local xmlfile = xmlCreateFile ( filename, "graph" )
	graph:saveToXml ( xmlfile )
	xmlSaveFile ( xmlfile )
	xmlUnloadFile ( xmlfile )
end

function GraphManager.getGraph ( id )
	return GraphManager.available [ id ]
end