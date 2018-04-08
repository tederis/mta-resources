NENodeEditor = {
	centerX = sw / 2, centerY = sh / 2,
	posX = 0, posY = 0,
	
	selectedPointType = 0,

	calcScale = function ( x, y )
		if not y then
			return x * NENodeEditor.scale
		end
	
		return x * NENodeEditor.scale, y * NENodeEditor.scale
	end,
	calcAbsolutePosition = function ( x, y )
		return NENodeEditor.centerX + x, NENodeEditor.centerY + y
	end,
	
	pickState = false,
	
	-- Traceback
	markedNodes = { }
}

local _settings = {
	watermarkColor = tocolor ( 255, 255, 255, 130 ),
	backColor = tocolor ( 50, 55, 60, 150 ),
	labelBackColor = tocolor ( 112, 112, 112, 255 ),
	compBackColor = tocolor ( 62, 62, 62, 255 ),
	fontColor = tocolor ( 255, 201, 14, 255 ),
	pointColor = tocolor ( 0, 0, 0, 255 ),
	selectedColor = tocolor ( 255, 100, 0, 255 ),
	wireColor = tocolor ( 0, 220, 255, 255 ),
	wireHColor = tocolor ( 255, 157, 0, 255 ),
	pointTextColor = tocolor ( 220, 220, 220, 255 ),
	pointDataColor = tocolor ( 205, 51, 51, 255 ),
	pointPropColor = tocolor ( 0, 100, 0, 255 ),
	pointInfoColor = tocolor ( 0, 0, 0, 200 ),
	containerPointColor = tocolor ( 255, 165, 0, 150 ),
	
	pointWidth = 15,
	
	wireWidth = 2.5
}
NENodeEditor.halfPointWidth = _settings.pointWidth / 2

local portsColor = { 
	any = tocolor ( 0, 200, 0, 255 ),
	number = tocolor ( 200, 0, 0, 255 ),
	bool = tocolor ( 0, 0, 200, 255 ),
	string = tocolor ( 0, 255, 239, 255 ),
	Vector2D = tocolor ( 175, 0, 255, 255 ),
	Vector3D = tocolor ( 175, 0, 255, 255 )
}

local targetMenuItems = {
	"Pick",
	"Each",
	"Random"
}

local _drawRectangle = dxDrawRectangle
local _drawText = dxDrawText
local _drawLine = dxDrawLine
local _drawImage = dxDrawImage
local _drawImageSection = dxDrawImageSection

function NENodeEditor.setup ( graph, new )
	if NENodeEditor.actived then
		return
	end

	NENodeEditor.graph = graph
	NENodeEditor.new = new

	NENodeEditor.texturePort = dxCreateTexture ( "images/arrow.png" )
	NENodeEditor.texturePortS = dxCreateTexture ( "images/square.png" )
	NENodeEditor.textureArrow = dxCreateTexture ( "images/white_arrow.png" )
	
	NENodeEditor.scale = 1
	NENodeEditor.textScale = NENodeEditor.calcScale ( 1 )
	
	NENodeEditor.resetCenter ( )
	
	addEventHandler ( "onClientRender", root, NENodeEditor.onRender, false, "high+3" )
	addEventHandler ( "onClientCursorMove", root, NENodeEditor.onCursorMove, false )
	addEventHandler ( "onClientClick", root, NENodeEditor.onClick, false )
	addEventHandler ( "onClientDoubleClick", root, NENodeEditor.onDoubleClick, false )
	addEventHandler ( "onClientKey", root, NENodeEditor.onKey, false )
	
	NENodeEditor.actived = true
end

function NENodeEditor.close ( )
	if NENodeEditor.actived then
		removeEventHandler ( "onClientRender", root, NENodeEditor.onRender )
		removeEventHandler ( "onClientCursorMove", root, NENodeEditor.onCursorMove )
		removeEventHandler ( "onClientClick", root, NENodeEditor.onClick )
		removeEventHandler ( "onClientDoubleClick", root, NENodeEditor.onDoubleClick )
		removeEventHandler ( "onClientKey", root, NENodeEditor.onKey )
		
		destroyElement ( NENodeEditor.texturePort )
		destroyElement ( NENodeEditor.texturePortS )
		destroyElement ( NENodeEditor.textureArrow )
		
		NENodeEditor.graph = nil
		
		NENodeEditor.actived = nil
	end
end

function NENodeEditor.resetCenter ( )
	NENodeEditor.centerX = sw / 2
	NENodeEditor.centerY = sh / 2
end

function NENodeEditor.onRender ( )
	local this = NENodeEditor
	
	local nodes = this.graph.nodes
	for _, node in pairs ( nodes ) do
		NENodeManager.onNodeDraw ( node )
	end
	
	local edges = this.graph.edges
	for _, edge in pairs ( edges ) do
		NENodeManager.onDrawNodeEdge ( edge )
	end
	
	local edgeCreator = this.edgeCreator
	if edgeCreator then
		local startX, startY = NENodeManager.getNodePortPosition ( edgeCreator.node, edgeCreator.port, edgeCreator.portType )
		_drawLine ( startX, startY, edgeCreator.x, edgeCreator.y, _settings.wireColor, 2 )
	end
end

function NENodeEditor.onCursorMove ( _, _, cx, cy )
	-- Предотвращаем излишне частый вызов
	local now = getTickCount ( )
	if NENodeEditor.cursorTime ~= nil and now - NENodeEditor.cursorTime < 25 then
		return
	end
	NENodeEditor.cursorTime = now

	if NEWorkspace.inputEnabled == true then
		return
	end

	local this = NENodeEditor
	if this.saveDialog then return end;
	if this.pickState or GraphProperties.isMouseOn ( cx, cy ) then return end;
	
	local headerHeight = this.calcScale ( 15 )
	local portSize = this.calcScale ( _settings.pointWidth )
	
	if this.targetModeList then
		local nx, ny = NENodeManager.getNodePosition ( this.selectedNode )
		local selectedRow = math.floor ( ( cy - ( ny + headerHeight + portSize ) ) / portSize ) + 1
		this.selectedTargetMode = math.clamp ( 1, selectedRow, 3 )
		return
	end

	-- Перемещаем что то?
	if this.movable then
		-- Нод?
		if this.movable.node then
			this.movable.node:setPosition ( cx - this.movable.offset [ 1 ], cy - this.movable.offset [ 2 ] )
			
		-- Или рабочее пространство?
		else
			this.centerX = cx - this.movable.offset [ 1 ]
			this.centerY = cy - this.movable.offset [ 2 ]
		end
		
		return
	end
	
	-- Создаем связь?
	if this.edgeCreator then
		this.edgeCreator.x = cx
		this.edgeCreator.y = cy
	end

	this.selectedNode = nil
	this.selectedPort = nil
	this.selectedPortType = nil
	this.targetSelected = nil

	local nodes = this.graph.nodes
	for _, node in pairs ( nodes ) do
		local nx, ny = NENodeManager.getNodePosition ( node )
		local nw, nh = NENodeEditor.calcScale ( node.width, node.height )
	
		if isPointInBox ( cx, cy, nx, ny, nw, nh ) then
			this.selectedNode = node
			
			local posy = ny + headerHeight
			local selectedRow = math.floor ( ( cy - posy ) / portSize ) + 1

			local nodeAbstr = node.abstr
			if nodeAbstr.events.target then
				if selectedRow == 1 then -- target port
					this.targetSelected = true
					if cx < nx + portSize then
						this.selectedPortType = 1
						this.selectedPort = 0
					elseif cx > nx + nw - portSize then
						--if node.linked == "each" then
							this.selectedPortType = 2
							this.selectedPort = 0
						--end
					end
					return
				end
				
				selectedRow = selectedRow - 1
			end
			
			if cx < nx + portSize then -- input port
				if nodeAbstr.events.inputs and nodeAbstr.events.inputs [ selectedRow ] then
					this.selectedPortType = 1
					this.selectedPort = selectedRow
				end
			elseif cx > nx + nw - portSize then -- output port
				if nodeAbstr.events.outputs and nodeAbstr.events.outputs [ selectedRow ] then
					this.selectedPortType = 2
					this.selectedPort = selectedRow
				end
			end
			
			return
		end
	end
end

function NENodeEditor.onClick ( button, state, cx, cy )
	if NEWorkspace.inputEnabled == true then
		return
	end

	local this = NENodeEditor
	if this.saveDialog then return end;
	if this.pickState or GraphProperties.isMouseOn ( cx, cy ) then return end;
	
	if state == "down" then
		if this.selectedNode then
			if this.selectedPort then
				-- Если мы выбрали input порт
				if this.selectedPortType < 2 then -- input or target port
					-- Если этот порт уже присоединен
					local connectedEdge = this.graph:getConnectedToNodeEdge ( this.selectedNode, this.selectedPort )
					if connectedEdge then
						local startNode = connectedEdge.srcNode
						local startPort = connectedEdge.srcPort
					
						this.edgeCreator = {
							node = startNode,
							port = tonumber ( startPort ),
							portType = 2,
							x = cx,
							y = cy
						}
						
						NENodeManager.destroyComponent ( 1, connectedEdge )
						
						return
					end
				end
			
				this.edgeCreator = {
					node = NENodeEditor.selectedNode,
					port = NENodeEditor.selectedPort,
					portType = NENodeEditor.selectedPortType,
					x = cx,
					y = cy
				}
			
				return
			end
			
			if this.selectedNode then
				if this.targetSelected == true then
					this.targetModeList = true
					
					return
				end
			end
			
			local x, y = this.selectedNode:getPosition ( )
			this.movable = {
				node = this.selectedNode,
				offset = { cx - x, cy - y }
			}
			
			-- Собираем и выводим свойства компонента
			GraphProperties.setNode ( this.selectedNode )
		else
			this.movable = {
				offset = { cx - this.centerX, cy - this.centerY  }
			}
			GraphProperties.setNode ( )
		end
	else
		if this.targetModeList then
			-- Pick
			if this.selectedTargetMode == 1 then
				outputChatBox ( _L"NEWSMsg2", 50, 255, 50 )
				this.targetPick = this.selectedNode
			
			-- Each
			elseif this.selectedTargetMode == 2 then
				--this.selectedNode.linked = "each"
				if this.new or this.createCopy then
					this.selectedNode.linked = "each"
				else
					triggerServerEvent ( "onChangeElementTarget", resourceRoot, this.graph.id, this.selectedNode.id, 0x01 )
				end
				
			-- Random
			--[[elseif this.selectedTargetMode == 3 then
				--this.selectedNode.linked = "random"
				if this.new or this.createCopy then
					this.selectedNode.linked = "random"
				else
					triggerServerEvent ( "onChangeElementTarget", resourceRoot, this.graph.id, this.selectedNode.id, 0x02 )
				end]]
			end
		end
		this.targetModeList = nil
	
		if this.new == nil and this.createCopy == nil then
			local movable = this.movable
			if movable and movable.node then
				NENodeManager.updatePosition ( movable.node )
			end
		end
		this.movable = nil
		
		if this.edgeCreator then
			if this.selectedPort then
				NENodeManager.createNodeEdge ( 
					{ this.edgeCreator.node, this.edgeCreator.portType, this.edgeCreator.port }, 
					{ this.selectedNode, this.selectedPortType, this.selectedPort } 
				)
			end
			
			this.edgeCreator = nil
		end
	end
end

function NENodeEditor.onDoubleClick ( button, cx, cy, wx, wy, wz, element )
	if NEWorkspace.inputEnabled == true then
		return
	end

	local this = NENodeEditor
	if this.saveDialog then return end;

	if this.selectedNode then
		NENodeManager.destroyComponent ( 0, this.selectedNode )
		
		return
	end
	
	--if not element then
		element = GameManager.getClickedElement ( )
	--end
	
	if element and isElementLocal ( element ) ~= true and getElementType ( element ) ~= "player" then
		if this.targetPick then
			-- Если мы создаем новую схему
			if this.new or this.createCopy then
				this.targetPick.linked = element
			else
				triggerServerEvent ( "onChangeElementTarget", resourceRoot, this.graph.id, this.targetPick.id, element )
			end
			this.targetPick = nil
		else
			local tag = getElementData ( element, "tag" )
			if tag then NENodeManager.createNode ( tag, 0, 0, element ) end;
		end
	end
end

function NENodeEditor.onKey ( button, pressOrRelease )
	if pressOrRelease ~= true then
		return
	end

	if button == "mouse_wheel_up" then
		NENodeEditor.scale = math.min ( NENodeEditor.scale + 0.1, 1 )
		NENodeEditor.textScale = NENodeEditor.calcScale ( 1 )
	elseif button == "mouse_wheel_down" then
		NENodeEditor.scale = math.max ( NENodeEditor.scale - 0.1, 0.1 )
		NENodeEditor.textScale = NENodeEditor.calcScale ( 1 )
	end
end

function NENodeEditor.markNode ( nodeId, port, str, time )
	if NENodeEditor.visible then
		local node = NENodeEditor.graph.nodes [ nodeId ]
		if node then
			if not NENodeEditor.markedNodes [ node ] then NENodeEditor.markedNodes [ node ] = { } end;
			NENodeEditor.markedNodes [ node ] [ port ] = { 
				str = str,
				endTime = getTickCount ( ) + time
			}
		end
	end
end

----------------------------
-- Node manager
----------------------------
NENodeManager = { }

function NENodeManager.draw ( node )

end

function NENodeManager.onNodeDraw ( node )
	local gx, gy = NENodeManager.getNodePosition ( node )
	local width, height = NENodeEditor.calcScale ( node.width ), NENodeEditor.calcScale ( node.height )
	local headerHeight = NENodeEditor.calcScale ( 15 )
	local portSize = NENodeEditor.calcScale ( _settings.pointWidth )
	local halfPortSize = portSize / 2
		
	local nodeAbstr = node.abstr

	_drawRectangle ( gx, gy, width, headerHeight, _settings.labelBackColor )
	_drawText ( nodeAbstr.fullName, gx + halfPortSize, gy, gx, gy + headerHeight, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
	
	_drawRectangle ( gx, gy + headerHeight, width, height - headerHeight, _settings.compBackColor )
	
	local ypos = gy + headerHeight
	
	local cx, cy = getCursorPosition ( )
	if cx then
		cx = cx * sw
		cy = cy * sh
	else
		cx, cy = 0, 0
	end
	
	local isSelected = node == NENodeEditor.selectedNode
	if isSelected then
		local lineWidth = NENodeEditor.calcScale ( 2 )
		
		dxDrawRectangleFrame ( gx, gy, width, height, _settings.selectedColor, lineWidth )
	end
		
	-- Рисуем порт контейнера
	local targetStr = nodeAbstr.events.target
	if targetStr then
		_drawRectangle ( gx, ypos, width, portSize, _settings.containerPointColor )
		
		local isPointSelected = NENodeEditor.selectedPort == 0 and NENodeEditor.selectedPortType == 1 and isSelected
		local portColor = portsColor [ targetStr ] or _settings.watermarkColor
		local color = isPointSelected and _settings.selectedColor or portColor
		
		_drawImage ( gx, ypos, portSize, portSize, NENodeEditor.texturePort, 90, 0, 0, color )
		if node.linked then 
			if isElement ( node.linked ) then
				targetStr = getElementID ( node.linked )
				if targetStr == "" then targetStr = "binded" end;
			else
				targetStr = tostring ( node.linked )
			end
		end
		_drawText ( "<" .. targetStr .. ">", gx + portSize, ypos, 100, ypos + portSize, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
		
		if isPointSelected then
			dxDrawHelperString ( "[" .. nodeAbstr.events.target .. "] " .. _L"NEWSTargerPort", gx, cy - halfPortSize, true )
		end
		
		--if node.linked == "each" then
			isPointSelected = NENodeEditor.selectedPort == 0 and NENodeEditor.selectedPortType == 2 and isSelected
			color = isPointSelected and _settings.selectedColor or portColor
		
			local portx = gx + width - portSize
			_drawImage ( portx, ypos, portSize, portSize, NENodeEditor.texturePortS, 90, 0, 0, color )
			--_drawText ( "source", portx - dxGetTextWidth ( "source", NENodeEditor.textScale ), ypos, 100, ypos + portSize, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
			
			if isPointSelected then
				dxDrawHelperString ( "[" .. nodeAbstr.events.target .. "] Source", gx + width, cy - halfPortSize )
			end
		--end
		
		ypos = ypos + portSize
	end
	
	-- Рисуем порты входа
	for i, port in ipairs ( nodeAbstr:getPointsByType ( "inputs" ) ) do
		local py = ypos + ( portSize * ( i - 1 ) )
		
		local isPointSelected = i == NENodeEditor.selectedPort and NENodeEditor.selectedPortType == 1 and isSelected
		local portColor = portsColor [ port [ 2 ] ] or _settings.watermarkColor
		local color = isPointSelected and _settings.selectedColor or portColor
			
		local portx = gx + portSize
		_drawImage ( gx, py, portSize, portSize, NENodeEditor.texturePort, 90, 0, 0, color )
		local portValue = NENodeManager.getNodePortValue ( node, i )
		local portStr = port [ 1 ]; if port [ 2 ] ~= "any" then portStr = portStr .. "=" .. ( tonumber ( portValue ) and portValue or ".." ) end;
		_drawText ( portStr, portx, py, 100, py + portSize, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
		
		if isPointSelected then
			local langStr = type ( port [ 3 ] ) == "table" and  port [ 3 ]:get ( ) or port [ 3 ]
			local helpStr = "[" .. port [ 2 ] .. "] " .. ( langStr or "" )
			dxDrawHelperString ( helpStr, gx, cy - halfPortSize, true )
		end
	end
	
	-- Рисуем порты выхода
	local mark = NENodeEditor.markedNodes [ node ]
	
	for i, port in ipairs ( nodeAbstr:getPointsByType ( "outputs" ) ) do
		local py = ypos + ( portSize * ( i - 1 ) )
		
		local isPointSelected = i == NENodeEditor.selectedPort and NENodeEditor.selectedPortType == 2 and isSelected
		local portColor = portsColor [ port [ 2 ] ] or _settings.watermarkColor
		local color = isPointSelected and _settings.selectedColor or portColor
			
		local portx = gx + width - portSize
		_drawImage ( portx, py, portSize, portSize, NENodeEditor.texturePort, 90, 0, 0, color )
		_drawText ( port [ 1 ], portx - dxGetTextWidth ( port [ 1 ], NENodeEditor.textScale ), py, 100, py + portSize, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
		
		if isPointSelected then
			local langStr = type ( port [ 3 ] ) == "table" and port [ 3 ]:get ( ) or port [ 3 ]
			local helpStr = "[" .. port [ 2 ] .. "] " .. ( langStr or "" )
			dxDrawHelperString ( helpStr, gx + width, cy - halfPortSize )
		end
		
		if mark and mark [ i ] then
			local now = getTickCount ( )
			if now > mark [ i ].endTime then
				mark [ i ] = nil
			else
				dxDrawHelperString ( mark [ i ].str, gx + width, py )
			end
		end
	end
	
	-- Рисуем меню выбора target
	if isSelected and NENodeEditor.targetModeList then
		dxDrawRectangle ( gx, ypos, width, portSize * #targetMenuItems, tocolor ( 0, 0, 0, 200 ) )
	
		local selectedMode = NENodeEditor.selectedTargetMode
		for i = 1, #targetMenuItems do
			local py = ypos + ( portSize * ( i - 1 ) )
			
			if i == selectedMode then
				dxDrawRectangle ( gx, py, width, portSize, tocolor ( 200, 157, 0, 255 ) )
			end
			
			_drawText ( targetMenuItems [ i ], gx + 10, py, 0, py + portSize, _settings.pointTextColor, NENodeEditor.textScale, "default", "left", "center", false, false )
		end
	end
end

local NUM_SEGMENTS = 20
local function drawBezierSpline ( anchor1, control1, control2, anchor2, color )
	local points = {
		{ x = anchor1.x, y = anchor1.y }
	}
 
	--loop through 100 steps of the curve
	for currentIndex = 1, NUM_SEGMENTS do
		local u = ( currentIndex - 1 ) / NUM_SEGMENTS
	
		local posx = math.pow(u,3)*(anchor2.x+3*(control1.x-control2.x)-anchor1.x)+3*math.pow(u,2)*(anchor1.x-2*control1.x+control2.x)+3*u*(control1.x-anchor1.x)+anchor1.x
		local posy = math.pow(u,3)*(anchor2.y+3*(control1.y-control2.y)-anchor1.y)+3*math.pow(u,2)*(anchor1.y-2*control1.y+control2.y)+3*u*(control1.y-anchor1.y)+anchor1.y
 
		table.insert ( points, { x = posx, y = posy } )
	end
 
	--Let the curve end on the second anchorPoint
	table.insert ( points, { x = anchor2.x, y = anchor2.y } )
 
	local width = NENodeEditor.calcScale ( _settings.wireWidth )
	for currentIndex = 1, NUM_SEGMENTS+1 do
		local nextIndex = currentIndex + 1;

		_drawLine ( points[currentIndex].x, points[currentIndex].y, points[nextIndex].x, points[nextIndex].y,
			color, width
		)
	end
	
	local arrowX, arrowY = points [ 1 ].x - ( 12 * NENodeEditor.scale ), points [ 1 ].y - ( 4 * NENodeEditor.scale )
	local arrowWidth, arrowHeight = 16 * NENodeEditor.scale, 8 * NENodeEditor.scale
	local rot = ( 360 - math.deg ( math.atan2 ( ( points [ 1 ].x - points [ 4 ].x ), ( points [ 1 ].y - points [ 4 ].y ) ) ) ) % 360
	_drawImage ( arrowX, arrowY, arrowWidth, arrowHeight, NENodeEditor.textureArrow, rot, 0, 0, color )
end

function NENodeManager.onDrawNodeEdge ( edge )
	local srcNode = edge.srcNode
	local srcAbstr = srcNode.abstr
	local srcPortIndex = edge.srcPort
	local srcPortX, srcPortY = NENodeManager.getNodePortPosition ( srcNode, srcPortIndex, 2 )
	local srcOutputs = srcAbstr.events.outputs
		
	local dstNode = edge.dstNode
	local dstAbstr = dstNode.abstr
	local dstPortIndex = edge.dstPort
	local dstPortX, dstPortY = NENodeManager.getNodePortPosition ( dstNode, dstPortIndex, 1 )
	local dstInputs = dstAbstr.events.inputs
	
	--_drawLine ( srcPortX, srcPortY, dstPortX, dstPortY, _settings.wireColor, 2 )
		
	if ( srcPortIndex == 0 or ( srcOutputs and srcOutputs [ srcPortIndex ] ) ) and 
		( dstPortIndex == 0 or ( dstInputs and dstInputs [ dstPortIndex ] ) ) then
		local color = _settings.wireColor
		
		local selected = NENodeEditor.selectedNode == srcNode and NENodeEditor.selectedPort == srcPortIndex
		local mark = NENodeEditor.markedNodes [ srcNode ]
		if selected or ( mark and mark [ srcPortIndex ] ) then
			color = _settings.wireHColor
		end
			
		drawBezierSpline ( 
			{ x = dstPortX, y = dstPortY },
			{ x = srcPortX, y = dstPortY },
			{ x = dstPortX, y = srcPortY },
			{ x = srcPortX, y = srcPortY },
			color
		)
	end
end

function NENodeManager.getNodePosition ( node )
	local x, y = node:getPosition ( )
	local gx, gy = NENodeEditor.calcAbsolutePosition ( x, y )
	
	return NENodeEditor.calcScale ( gx, gy )
end

function NENodeManager.getNodeSize ( node )
	local nodeAbstr = node.abstr

	local workPointsNum = nodeAbstr.events.inputs and #nodeAbstr.events.inputs or 0
	local valuePointsNum = nodeAbstr.events.outputs and #nodeAbstr.events.outputs or 0
	local maxProcedurePointsNum = math.max ( workPointsNum, valuePointsNum )
	
	local width = dxGetTextWidth ( nodeAbstr.fullName, 1, "default" )
	
	-- Считаем ширину нода по длине имен вводов-выводов
	for i = 1, maxProcedurePointsNum do
		local inWidth = 0
		local outWidth = 0
	
		local ports = nodeAbstr.events.inputs
		if ports and ports [ i ] then
			local portValue = NENodeManager.getNodePortValue ( node, i )
			local portStr = ports [ i ] [ 1 ]; if ports [ i ] [ 2 ] ~= "any" then portStr = portStr .. "=" .. ( tonumber ( portValue ) and portValue or ".." ) end;
			
			inWidth = dxGetTextWidth ( portStr, 1, "default" ) + 15
		end
		
		ports = nodeAbstr.events.outputs
		if ports and ports [ i ] then
			outWidth = dxGetTextWidth ( ports [ i ] [ 1 ], 1, "default" ) + 15
		end
		
		width = math.max ( width, inWidth + outWidth )
	end
	
	local height = 15 + ( _settings.pointWidth * maxProcedurePointsNum )
	
	-- Если есть таргет-порт расширяем высоту нода
	if nodeAbstr.events.target then
		height = height + _settings.pointWidth
	end
		
	width, height = width + _settings.pointWidth, height
		
	return width, height
end

function NENodeManager.getNodePortPosition ( node, portIndex, portType )
	local x, y = NENodeManager.getNodePosition ( node )
	local width, height = NENodeEditor.calcScale ( node.width ), NENodeEditor.calcScale ( node.height )
	local nodeAbstr = node.abstr
	
	local portSize = NENodeEditor.calcScale ( _settings.pointWidth )
	local halfPortSize = portSize / 2
	local headerHeight = NENodeEditor.calcScale ( 15 )
	
	if portType == 2 then -- output port
		x = x + width
	end
	
	if not nodeAbstr.events.target then portIndex = portIndex - 1 end;
	
	y = y + headerHeight + halfPortSize + ( portSize * portIndex )
	
	return x, y
end

function NENodeManager.getNodePortValue ( node, portIndex )
	local portValue = node.properties [ portIndex ]
	
	return tostring ( portValue )
end

addEvent ( "onClientNodeTraceback", true )
addEventHandler ( "onClientNodeTraceback", resourceRoot,
	function ( graphId, nodeId, port, value )
		if not NENodeEditor.actived or NENodeEditor.graph.id ~= graphId then return end;
	
		if isElement ( value ) then
			local elementType = getElementType ( value )
			if elementType == "player" then
				value = "player:" .. getPlayerName ( value )
			else
				value = "element"
			end
		elseif value == nil then
			value = "none"
		end

		NENodeEditor.markNode ( nodeId, port, tostring ( value ), 1000 )
	end
, false, "low" )