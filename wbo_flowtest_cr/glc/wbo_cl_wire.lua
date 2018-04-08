APPLY_TO_ALL = -1 -- Флаг для применения схемы ко всем объектам, на которых она уже находится(neWorkspaceClient.lua)

addEvent ( "onClientEditorCreateGraph", true )

local createFn
local function onCreateCallback ( id )
	if createFn then
		removeEventHandler ( "onClientEditorCreateGraph", resourceRoot, onCreateCallback )
		createFn ( id )
	end
	
	createFn = nil
end

function createGraph ( callbackFn, name )
	if createFn == nil then
		createFn = callbackFn
		addEventHandler ( "onClientEditorCreateGraph", resourceRoot, onCreateCallback, false )
		triggerServerEvent ( "onEditorCreateGraph", resourceRoot, name )
	end
end

addEvent ( "onClientGraphRequest", true )

local requestData
local function onRequestCallback ( id, packedGraph )
	if requestData then
		removeEventHandler ( "onClientGraphRequest", resourceRoot, onRequestCallback )
		requestData [ 1 ] ( id, packedGraph )
	end
	requestData = nil
end
function requestGraph ( id, callbackFn )
	local now = getTickCount ( )
	if requestData == nil then
		requestData = { callbackFn, now }
		addEventHandler ( "onClientGraphRequest", resourceRoot, onRequestCallback, false )
		triggerServerEvent ( "onGraphRequest", resourceRoot, id )
	elseif now - requestData [ 2 ] > 1000 then
		requestData = { callbackFn, now }
		triggerServerEvent ( "onGraphRequest", resourceRoot, id )
	end
end

local lastApply = getTickCount ( )
function applyGraph ( graphId )
	local now = getTickCount ( )
	if now - lastApply > 500 then
		lastApply = now
		triggerServerEvent ( "onGraphApply", resourceRoot, graphId )
	end
end

function destroyGraph ( graphId )
	triggerServerEvent ( "doGraphDestroy", resourceRoot, graphId )
end

function unpackNode ( packedNode )
	local node = EditorNode.create (
		packedNode [ 4 ], -- id,
		packedNode [ 5 ], -- tag
		packedNode [ 6 ] -- linked
	)
	
	if node then
		--node.graph = graph
		node:setPosition ( packedNode [ 2 ], packedNode [ 3 ] )
		--graph:addNode ( node )
	
		--nodeIds [ packedNode [ 4 ] ] = node
	
		return node
	end
end

function unpackEdge ( packedEdge )
	local edge = EditorEdge.create ( 
		nodeIds [ nodeSrc ], item [ 3 ], nodeIds [ nodeDst ], item [ 5 ], item [ 6 ]
	)
	return edge
end

function unpackGraph ( packedGraph )
	local nodeIds = { }
	
	local graph = EditorGraph.create ( 
		packedGraph [ 1 ] -- id
	)

	for i = 2, #packedGraph do
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
				node:setPosition ( item [ 2 ], item [ 3 ] )
				
				node.graph = graph
				graph:addNode ( node )
			
				nodeIds [ item [ 4 ] ] = node
			end
		
		-- Edge
		elseif itemType == 1 then
			local nodeSrc = item [ 2 ]
			local nodeDst = item [ 4 ]
		
			local edge = EditorEdge.create ( 
				nodeIds [ nodeSrc ], item [ 3 ], nodeIds [ nodeDst ], item [ 5 ], item [ 6 ]
			)
			
			if edge then graph:addEdge ( edge ) end;
		end
	end
	
	return graph
end

function packNode ( node )
	local outpack = { 
		0, -- флаг нода
			
		node.x, node.y,
		node.id, node.tag,
		node.linked,
		{ }
	}
	
	local properties = outpack [ 7 ]
	for index, value in pairs ( node.properties ) do
		properties [ #properties + 1 ] = { 
			index, value
		}
		--outputChatBox("pack prop " .. index .. "=" .. value)
	end

	return outpack
end

function packEdge ( edge )
	local outpack = {
		1, -- флаг связи
			
		edge.srcNode.id, edge.srcPort,
		edge.dstNode.id, edge.dstPort,
		edge.id
	}
	
	return outpack
end

function packGraph ( graph )
	local outpack = { }

	-- Пакуем ноды
	local nodes = graph.nodes
	for _, node in pairs ( nodes ) do
		outpack [ #outpack + 1 ] = packNode ( node )
	end
	
	-- Пакуем связи
	local edges = graph.edges
	for _, edge in pairs ( edges ) do
		outpack [ #outpack + 1 ] = packEdge ( edge )
	end
	
	return outpack
end

SoundBrowser = { 
	items = { }
}
function SoundBrowser.open ( callback )
	if SoundBrowser.visible ~= true then
		local width, height = 300, 400
		SoundBrowser.callback = callback

		SoundBrowser.wnd = guiCreateWindow ( sw/2 - width/2, sh/2 - height/2, width, height, "Sound browser", false )
		SoundBrowser.playBtn = guiCreateButton ( 0.04, 0.06, 0.25, 0.06, "Play/Stop", true, SoundBrowser.wnd )
		SoundBrowser.progress = guiCreateProgressBar ( 0.3, 0.06, 0.66, 0.06, true, SoundBrowser.wnd )
		SoundBrowser.list = guiCreateGridList ( 0.04, 0.13, 0.92, 0.74, true, SoundBrowser.wnd )
		guiGridListAddColumn ( SoundBrowser.list, "Sound", 0.9 )
		SoundBrowser.cancelBtn = guiCreateButton ( 0.04, 0.89, 0.44, 0.08, "Cancel", true, SoundBrowser.wnd )
		SoundBrowser.okBtn = guiCreateButton ( 0.52, 0.89, 0.44, 0.08, "OK", true, SoundBrowser.wnd )
	
		addEventHandler ( "onClientGUIClick", SoundBrowser.wnd, SoundBrowser.onClick )
		showCursor ( true )
		
		SoundBrowser.items = { }
		SoundBrowser.sound = nil
		SoundBrowser.visible = true
	end
end

function SoundBrowser.close ( )
	if SoundBrowser.visible then
		destroyElement ( SoundBrowser.wnd )
		showCursor ( false )
		SoundBrowser.visible = nil
		SoundBrowser.items = nil
		
		if SoundBrowser.sound then
			killTimer ( SoundBrowser.timer )
			stopSound ( SoundBrowser.sound )
		end
	end
end

function SoundBrowser.onTimer ( )
	if isElement ( SoundBrowser.sound ) then
		local length = getSoundLength ( SoundBrowser.sound )
		local position = getSoundPosition ( SoundBrowser.sound )
		local progress = position / length
		guiProgressBarSetProgress ( SoundBrowser.progress, 100 * progress )
	end
end

function SoundBrowser.onClick ( )
	if source == SoundBrowser.okBtn then
		local selectedItem = guiGridListGetSelectedItem ( SoundBrowser.list )
		if selectedItem > -1 then
			local item = SoundBrowser.items [ selectedItem + 1 ]
			if item then
				SoundBrowser.callback ( item.name, unpack ( item.args ) )
			end
		end
		SoundBrowser.close ( )
	elseif source == SoundBrowser.cancelBtn then
		SoundBrowser.close ( )
	elseif source == SoundBrowser.playBtn then
		local selectedItem = guiGridListGetSelectedItem ( SoundBrowser.list )
		if selectedItem > -1 then
			local item = SoundBrowser.items [ selectedItem + 1 ]
			if item then
				if SoundBrowser.sound then
					killTimer ( SoundBrowser.timer )
					stopSound ( SoundBrowser.sound )
					SoundBrowser.sound = nil
					guiProgressBarSetProgress ( SoundBrowser.progress, 0 )
				else
					SoundBrowser.sound = playSound ( item.filepath, true )
					SoundBrowser.timer = setTimer ( SoundBrowser.onTimer, 50, 0 )
				end
			end
		end
	end
end

local _soundTypes = {
	ogg = true, wav = true, mp3 = true
}
function SoundBrowser.insertSound ( filePath, fileName, ... )
	local item = {
		filepath = filePath,
		name = fileName,
		args = { ... }
	}
	table.insert ( SoundBrowser.items, item )
	
	local row = guiGridListAddRow ( SoundBrowser.list )
	guiGridListSetItemText ( SoundBrowser.list, row, 1, fileName, false, false )
end