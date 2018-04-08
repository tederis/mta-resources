local sw, sh = guiGetScreenSize ( )

local workspaceTips = {
	_LD"NEWSTip1",
	_LD"NEWSTip2",
	_LD"NEWSTip2",
	_LD"NEWSTip4"
}

NEWorkspace = { }

local _settings = {
	watermarkColor = tocolor ( 255, 255, 255, 130 ),
	backColor = tocolor ( 50, 55, 60, 150 ),
	pointTextColor = tocolor ( 220, 220, 220, 255 ),
	pointInfoColor = tocolor ( 0, 0, 0, 200 )
}

local _drawRectangle = dxDrawRectangle
local _drawText = dxDrawText
local _drawLine = dxDrawLine
local _drawImageSection = dxDrawImageSection

local dialogs = {
	modify = {
		label = _LD"NEWSDialog1Lbl",
		items = {
			_LD"NEWSDialog1Itm1",
			_LD"NEWSDialogCopy"
		}
	},
	copyOnly = {
		label = _LD"NEWSDialog2Lbl",
		items = {
			_LD"NEWSDialog2Itm1",
			_LD"NEWSDialogCopy"
		}
	},
	save = {
		label = _LD"NEWSCatLbl",
		items = {
			_LD"NEWSCatSave",
			_LD"NEWSCatCancel"
		}
	},
	apply = {
		label = _LD"NEWSCatApplyLbl",
		items = {
			_LD"NEWSCatApply",
			_LD"NEWSCatApplyC"
		}
	}
}

function NEWorkspace.create ( graph, new )
	if NEWorkspace.visible then return false end;
	
	if new == nil then
		-- Моя схема?
		if graph.owner == Editor.accountName then
			DXDialog.create ( dialogs.modify, NEWorkspace.onDialog, 0 )
	
		-- Или чужая с публичным доступом?
		else
			DXDialog.create ( dialogs.copyOnly, NEWorkspace.onDialog, 1 )
		end
	end
	
	
	NEWorkspace.new = new
	NEWorkspace.graph = graph
	
	NEWorkspace.textureChecker = dxCreateTexture ( "images/checker.png" )

	addEventHandler ( "onClientRender", root, NEWorkspace.onRender, false, "high+4" )
	addEventHandler ( "onClientKey", root, NEWorkspace.onKey, false )
	--bindKeyDelay ( "e", 1000, NEWorkspace.closeAndSave, true )
	bindKey ( "e", "down", NEWorkspace.closeAndSave )
	
	GraphProperties.create ( new )
	NENodeList.create ( NEWorkspace.onServiceCallback, NEWorkspace.onCreateNode )
	NENodeList.setPublic ( graph.public == true )
	
	showCursor ( true )
	guiSetInputMode ( "no_binds_when_editing" )
	
	NEWorkspace.mode = "node"
	NEWorkspace.activeEditor = NENodeEditor
	NENodeEditor.setup ( graph, new )
	
	NEDebugForm.create ( graph )
	if new then
		NEDebugForm.outputString ( "Graph successfully created" )
	else
		NEDebugForm.outputString ( "Graph with the id '" .. tostring ( graph.id ) .. "' is successfully loaded" )
	end
	
	outputChatBox ( _L"NEWSMsg1", 100, 255, 0 )
	
	-- Show random tip
	local randTip = math.random ( 1, #workspaceTips )
	createHelpForm ( _L"NEWSBoxLbl" .. randTip , workspaceTips [ randTip ]:get ( )  )
	
	-- Check node reference
	local nodes = NEWorkspace.graph.nodes
	for _, node in pairs ( nodes ) do
		if node.abstr then
			local width, height = NENodeManager.getNodeSize ( node )
			node.width = width; node.height = height;
		else
			outputDebugString ( "Нода с тегом " .. node.tag .. " нет в референсе" )
		end
	end
	
	NEWorkspace.visible = true
	
	NEWorkspace.inputEnabled = nil
	
	
	
	-- TEST !
		destroyAllGUIs ( )
	-- TEST !
		
		
		
		
	
	return true
end

function NEWorkspace.destroy ( )
	if NEWorkspace.visible then
		removeEventHandler ( "onClientRender", root, NEWorkspace.onRender )
		removeEventHandler ( "onClientKey", root, NEWorkspace.onKey )
		unbindKeyDelay ( "e" )
		unbindKey ( "e", "down", NEWorkspace.closeAndSave )
		
		destroyElement ( NEWorkspace.textureChecker )
		
		NEWorkspace.activeEditor.close ( )
		
		GraphProperties.destroy ( )
		NENodeList.destroy ( )
		NEWorkspace.graph = nil
		NEWorkspace.target = nil
		
		showCursor ( false, true )
		
		NEWorkspace.visible = false
		NEWorkspace.targetPick = nil
		
		NEWorkspace.createCopy = nil
		
		DXDialog.destroy ( )
		
		NEDebugForm.destroy ( )
	end
end

function NEWorkspace.open ( graph, new )
	return NEWorkspace.create ( graph, new )
end

function NEWorkspace.closeAndSave ( key, timely )
	local self = NEWorkspace
	
	-- Если мы создаем новую схему или ее копию
	if self.new or self.createCopy then
		DXDialog.create ( dialogs.save, NEWorkspace.onDialog, 2 )
		return
	end
	
	if isElement ( self.target ) then
		local isPublic = NENodeList.isPublic ( )
		triggerServerEvent ( "onChangeElementGraph", resourceRoot, self.graph.id, self.target, isPublic )
		self.destroy ( )
	else
		DXDialog.create ( dialogs.apply, NEWorkspace.onDialog, 3 )
	end
end

function NEWorkspace.setInputEnabled ( enabled )
	NEWorkspace.inputEnabled = enabled
end

function NEWorkspace.setTarget ( element )
	NEWorkspace.target = element
end

function NEWorkspace.onRender ( )
	local self = NEWorkspace

	-- Рисуем фон
	_drawRectangle ( 0, 0, sw, sh, _settings.backColor )
	NEWorkspace.drawBackground ( )
	_drawText ( "FlowEditor", 0, 0, sw, sh, _settings.watermarkColor, 4, "default", "center", "center" )
	_drawText ( "by TEDERIs", sw / 2 + 25, sh / 2 - 40, sw, sh, _settings.watermarkColor, 1.5, "default", "left", "top" )
	_drawText ( "Part of Game Creation Kit", 0, sh / 2 + 25, sw, sh, _settings.watermarkColor, 1.7, "default", "center", "top" )
end

function NEWorkspace.onKey ( button, pressed )
	if NEWorkspace.inputEnabled == true then
		return
	end

	if button == "mouse2" then
		showCursor ( not pressed, true )
		NEWorkspace.pickState = pressed
	elseif button == "n" and pressed == true then
		local newState = not NEWorkspace.pickState
		--showCursor ( not newState, true )
		--NEWorkspace.pickState = newState
	end
end

function NEWorkspace.onCreateNode ( nodeRef )
	outputDebugString ( "TCT: Trying to create a node with tag " .. nodeRef.fullName .. " ..." )
	
	local x, y = 0, 0
	if NEWorkspace.mode == "node" then
		local scx, scy = sw / 2, sh / 2
		x, y = scx - NENodeEditor.centerX, scy - NENodeEditor.centerY
	end
	NENodeManager.createNode ( nodeRef.fullName, x, y )
end

function NEWorkspace.onServiceCallback ( str )
	if str == "Add Entity" then
		showCursor ( false )
		NEWorkspace.pickState = true
	end
end

function NEWorkspace.calcPosition ( )

end

function NEWorkspace.drawBackground ( )
	if NEWorkspace.pickState ~= true then
		local aspectRatio = sw / sh
		_drawImageSection ( 0, 0, sw, sh, 0, 0, 16 * ( 80 * aspectRatio ), 16 * 80, NEWorkspace.textureChecker, 0, 0, 0, tocolor ( 255, 255, 255, 100 ) )
	end
end

function NEWorkspace.onDialog ( itemIndex, dialogType )
	-- modify
	if dialogType == 0 then
		-- Создать копию
		if itemIndex == 2 then
			NEWorkspace.createCopy = true
		end
		
	-- copyOnly
	elseif dialogType == 1 then
		-- Создать копию
		if itemIndex == 2 then
			NEWorkspace.createCopy = true
		end
		
	-- save
	elseif dialogType == 2 then
		if itemIndex == 1 then
			local packedGraph = packGraph ( NEWorkspace.graph )
			local isPublic = NENodeList.isPublic ( )
			if NEWorkspace.createCopy then
				triggerServerEvent ( "onEditorCreateGraph", resourceRoot, NEWorkspace.graph.name, packedGraph, NEWorkspace.target, isPublic )
			else
				triggerServerEvent ( "onEditorCreateGraph", resourceRoot, NEWorkspace.new, packedGraph, NEWorkspace.target, isPublic )
			end
		end
		NEWorkspace.destroy ( )
	
	-- apply
	elseif dialogType == 3 then
		if itemIndex == 1 then
			local isPublic = NENodeList.isPublic ( )
			triggerServerEvent ( "onChangeElementGraph", resourceRoot, NEWorkspace.graph.id, APPLY_TO_ALL, isPublic )
		end
		NEWorkspace.destroy ( )
	end
end

function NEWorkspace.setEditMode ( mode )
	if mode == "node" or mode == "gui" then
		if NEWorkspace.mode ~= mode then
			NEWorkspace.mode = mode
			
			NEWorkspace.activeEditor.close ( )
			
			local newEditor = NENodeEditor
			if mode == "gui" then newEditor = NEGUIEditor end;
			NEWorkspace.activeEditor = newEditor
			
			newEditor.setup ( NEWorkspace.graph, NEWorkspace.new )
		end
	end
end

-- Копия на серверной стороне!
-- Повторить на сервере!
local guiDefaultProperty = {
	btn = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	checkbox = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	combobox = {
		Position = "0.5,0.5",
		Size = "0.3,0.3"
	},
	edit = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	},
	lbl = {
		Position = "0.5,0.5",
		Size = "0.3,0.1"
	}
}

function NENodeManager.createNode ( tag, x, y, linked )
	if WBO_DEBUG then outputDebugString ( "Creating node tagged as " .. tag ) end;
	
	if NEWorkspace.new or NEWorkspace.createCopy then
		local newId = generateString ( 10 )
		local node = EditorNode.create ( newId, tag, linked )
		node:setupProperties ( )
		local width, height = NENodeManager.getNodeSize ( node )
		node.width = width; node.height = height;
		node:setPosition ( x, y )
		
		local guiType = node.abstr.gui
		if guiType ~= nil then
			for name, value in pairs ( guiDefaultProperty [ guiType ] ) do
				node:setProperty ( name, value )
			end
		end
		
		NEWorkspace.graph:addNode ( node )
		
		if NEWorkspace.mode == "gui" then
			NEGUIEditor.addGUINode ( node )
		end
	else
		triggerServerEvent ( "onCreateGLCComponent", resourceRoot, NEWorkspace.graph.id, tag, x, y, linked )
	end
end

function NENodeManager.destroyComponent ( itype, component )
	if NEWorkspace.new or NEWorkspace.createCopy then
		-- Нод
		if itype == 0 then
			NEWorkspace.graph:destroyNode ( component )
			
		-- Связь
		elseif itype == 1 then
			NEWorkspace.graph:destroyEdge ( component )
		end
	else
		triggerServerEvent ( "onDestroyGLCComponent", resourceRoot, NEWorkspace.graph.id, itype, component.id )
	end
end

function NENodeManager.createNodeEdge ( src, dst )
	if WBO_DEBUG then
		outputDebugString ( "Creating edge " .. getElementID ( src [ 1 ] ) .. ":" .. src [ 3 ] .. " to " .. getElementID ( dst [ 1 ] ) .. ":" .. dst [ 3 ] .. " ..." )
	end
	-- Создаем новый или копируем?
	if NEWorkspace.new or NEWorkspace.createCopy then
		if src [ 1 ] == dst [ 1 ] then outputChatBox ( _L"NEWSWarnMsg1", 255, 0, 0 ) return end;
		if src [ 2 ] == dst [ 2 ] then outputChatBox ( _L"NEWSWarnMsg2", 255, 0, 0 ) return end;
		
		-- Если последовательность подключения неправильная, исправляем ее
		if dst [ 2 ] > 1 then
			local srcPoint = src
		
			src = dst
			dst = srcPoint
		end
		
		local edge = NEWorkspace.graph:getConnectedToNodeEdge ( dst [ 1 ], dst [ 3 ] )
		if edge then
			NEWorkspace.graph:destroyEdge ( edge )
		end
		
		local newId = generateString ( 10 )
		edge = EditorEdge.create ( 
			src [ 1 ], src [ 3 ], dst [ 1 ], dst [ 3 ], newId
		)
		if edge then
			NEWorkspace.graph:addEdge ( edge )
		end
	else
		src [ 1 ] = src [ 1 ].id
		dst [ 1 ] = dst [ 1 ].id
		triggerServerEvent ( "createEdge", resourceRoot, NEWorkspace.graph.id, src, dst )
	end
end

local lastUpdate = getTickCount ( )
function NENodeManager.updatePosition ( node )
	local now = getTickCount ( )
	if now - lastUpdate > 500 then
		lastUpdate = now
		
		triggerServerEvent ( "onGraphAction", resourceRoot, NEWorkspace.graph.id, 1, node.id, node.x, node.y )
	end
end

function NENodeManager.getEdgeConnectedToNode ( node, portIndex )
	portIndex = tonumber ( portIndex )
	local nodeID = node.id
	local nodes = NEWorkspace.graph.nodes
	
	for _, node in pairs ( nodes ) do
		local edges = node.edges [ portIndex ]
		if edges then
			for _, edge in pairs ( edges ) do
				if edge.dstNode.id == nodeID and tonumber ( edge.dstPort ) == portIndex then
					return edge
				end
			end
		end
	end
	
	return false
end

function dxDrawRectangleFrame ( x, y, width, height, color, thickness, postGUI )
	_drawLine ( x, y, x + width, y, color, thickness, postGUI )
	_drawLine ( x + width, y, x + width, y + height, color, thickness, postGUI )
	_drawLine ( x + width, y + height, x, y + height, color, thickness, postGUI )
	_drawLine ( x, y + height, x, y, color, thickness, postGUI )
end

function dxDrawHelperString ( str, x, y, move )
	local strWidth = dxGetTextWidth ( str, 1, "default" ) + 10
	local strHeight = dxGetFontHeight ( 1, "default" )
	
	if move then
		x = x - strWidth
	end
	
	_drawRectangle ( x, y, strWidth, strHeight, _settings.pointInfoColor, true )
	_drawText ( str, x, y, x + strWidth, y + strHeight, _settings.pointTextColor, 1, "default", "center", "center", false, false, true )
end

addEvent ( "onClientGraphAction", true )
addEventHandler ( "onClientGraphAction", resourceRoot,
	function ( id, action, arg, arg2 )
		if not NEWorkspace.graph or NEWorkspace.graph.id ~= id then return end;

		-- Создание нода
		if action == 0 then
			local node = NEWorkspace.graph:unpackNode ( arg )
			local width, height = NENodeManager.getNodeSize ( node )
			node.width = width; node.height = height;
			
			if NEWorkspace.mode == "gui" then
				NEGUIEditor.addGUINode ( node )
			end
		
		-- Удаление компонента
		elseif action == 1 then
			-- Нод
			if arg == 0 then
				NEWorkspace.graph:destroyNode ( NEWorkspace.graph.nodes [ arg2 ] )
				
			-- Связь
			elseif arg == 1 then
				NEWorkspace.graph:destroyEdge ( NEWorkspace.graph.edges [ arg2 ] )
			end
			
		-- Создание связи
		elseif action == 2 then
			local edge = NEWorkspace.graph:unpackEdge ( arg )
			
		-- Изменение свойств
		elseif action == 3 then
			local node = NEWorkspace.graph.nodes [ arg ]
			if node then
				for i = 1, #arg2 do
					local property = arg2 [ i ]
					
					node:setProperty ( property [ 1 ], property [ 2 ] )
					--NEDebugForm.outputString ( "Node with id " .. tostring ( node.id ) .. " changed the property " )
				end
			end
		end
	end
, false )

--[[
function onRequestGraph ( id, packedGraph )
	local graph = EditorGraph.create ( id )
	graph:unpack  ( packedGraph )
	NEWorkspace.open ( graph )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		requestGraph ( "VehicleCtrls", onRequestGraph )
	end
, false )]]