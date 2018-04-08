NEGUIEditor = { 
	guiBinds = { }
}
local nodeGUI = { }

local _settings = {
	frameColor = tocolor ( 255, 0, 0, 255 )
}

function NEGUIEditor.setup ( graph, new )
	if NEGUIEditor.active then return end;

	NEGUIEditor.graph = graph
	NEGUIEditor.new = new
	
	NEGUIEditor.wnd = guiCreateWindow ( sw * 0.3, sh * 0.3, 400, 400, "Window", false )
	
	local nodes = graph.nodes
	for id, node in pairs ( nodes ) do
		if node.abstr.gui ~= nil then
			NEGUIEditor.createNodeUI ( node )
		end
	end
	
	addEventHandler ( "onClientClick", root, NEGUIEditor.onClick, false )
	addEventHandler ( "onClientDoubleClick", root, NEGUIEditor.onDoubleClick, false )
	addEventHandler ( "onClientCursorMove", root, NEGUIEditor.onCursorMove, false )
	addEventHandler ( "onClientRender", root, NEGUIEditor.onRender, false )
	
	NEGUIEditor.active = true
end

function NEGUIEditor.close ( )
	if NEGUIEditor.active then
		removeEventHandler ( "onClientClick", root, NEGUIEditor.onClick )
		removeEventHandler ( "onClientDoubleClick", root, NEGUIEditor.onDoubleClick )
		removeEventHandler ( "onClientCursorMove", root, NEGUIEditor.onCursorMove )
		removeEventHandler ( "onClientRender", root, NEGUIEditor.onRender )

		destroyElement ( NEGUIEditor.wnd )
		
		NEGUIEditor.guiBinds = { }
		NEGUIEditor.graph = nil
		
		NEGUIEditor.active = nil
	end
end

function NEGUIEditor.addGUINode ( node )
	if node.abstr.gui ~= nil then
		NEGUIEditor.createNodeUI ( node )
	end
end

function NEGUIEditor.createNodeUI ( node )
	local this = NEGUIEditor
	local guiType = node.abstr.gui
	
	local position = node:getProperty ( "Position", true )
	local size = node:getProperty ( "Size", true )
	local sizex, sizey = size.x, size.y
	
	local guielement
	if guiType == "btn" then
		local text = node:getProperty ( "Text" )
		guielement = guiCreateButton ( position.x, position.y, sizex, sizey, tostring ( text ), true, this.wnd )
	elseif guiType == "checkbox" then
		local text = node:getProperty ( "Text" )
		guielement = guiCreateCheckBox ( position.x, position.y, sizex, sizey, tostring ( text ), false, true, this.wnd )
	elseif guiType == "combobox" then
		guielement = guiCreateComboBox ( position.x, position.y, sizex, sizey, "ComboBox", true, this.wnd )
	elseif guiType == "edit" then
		local text = node:getProperty ( "Text" )
		guielement = guiCreateEdit ( position.x, position.y, sizex, sizey, tostring ( text ), true, this.wnd )
	elseif guiType == "lbl" then
		local text = node:getProperty ( "Text" )
		guielement = guiCreateLabel ( position.x, position.y, sizex, sizey, tostring ( text ), true, this.wnd )
	end
	
	if guielement then
		--addEventHandler ( "onClientGUIMove", guielement, NEGUIEditor.onMove, false )
	
		this.guiBinds [ guielement ] = node
		nodeGUI [ node ] = guielement
	end
end

function NEGUIEditor.onClick ( button, state, x, y )
	if NEWorkspace.inputEnabled == true then
		return
	end

	if button ~= "left" then
		return
	end

	local this = NEGUIEditor
	if this.selectedElement then
		if state == "down" then
			local node = this.guiBinds [ this.selectedElement ]
			GraphProperties.setNode ( node )
			
		
			local flanges = this.getSizableFlanges ( this.selectedElement )
			for i, flange in ipairs ( flanges ) do
				if isPointInBox ( x, y, flange.x, flange.y, flange.width - 1, flange.height - 1 ) then
					this.resize = {
						element = this.selectedElement,
						flange = i
					}
					return
				end
			end
			
			local ex, ey = guiGetPosition ( this.selectedElement, false )
			this.move = { 
				element = this.selectedElement,
				offsetx = x - ex, 
				offsety = y - ey 
			}
		elseif state == "up" then
			local resize = NEGUIEditor.resize
			if resize then
				NEGUIEditor.updateNode ( resize.element, 1 )
			end
			NEGUIEditor.resize = nil
		
			local move = NEGUIEditor.move
			if move then
				NEGUIEditor.updateNode ( move.element, 0 )
			end
			NEGUIEditor.move = nil
		end
	end
end

function NEGUIEditor.onDoubleClick ( button, cx, cy, wx, wy, wz, element )
	if NEWorkspace.inputEnabled == true then
		return
	end

	local this = NEGUIEditor
	local element = this.selectedElement
	if element then
		local node = this.guiBinds [ element ]
		if node then
			NENodeManager.destroyComponent ( 0, node )
		end
		this.guiBinds [ element ] = nil
		destroyElement ( element )
	end
	this.selectedElement = nil
	this.resize = nil
	this.move = nil
	
	GraphProperties.setNode ( )
end

function NEGUIEditor.onCursorMove ( _, _, x, y )
	if NEWorkspace.inputEnabled == true then
		return
	end

	local resize = NEGUIEditor.resize
	if resize then
		local wx, wy = guiGetPosition ( NEGUIEditor.wnd, false )
		local ex, ey = guiGetPosition ( resize.element, false )
		local ewidth, eheight = guiGetSize ( resize.element, false )
		
		if resize.flange == 5 then
			guiSetSize ( resize.element, math.max ( x - ( ex + wx ), 20 ), eheight, false )
		elseif resize.flange == 7 then
			guiSetSize ( resize.element, ewidth, math.max ( y - ( ey + wy ), 20 ), false )
		elseif resize.flange == 8 then
			guiSetSize ( resize.element, math.max ( x - ( ex + wx ), 20 ), math.max ( y - ( ey + wy ), 20 ), false )
		end
		
		return
	end

	local move = NEGUIEditor.move
	if move then
		guiSetPosition ( move.element, math.max ( x - move.offsetx, 0 ), math.max ( y - move.offsety, 0 ), false )
		
		return
	end
	
	NEGUIEditor.selectedElement = NEGUIEditor.getElementNearPoint ( x, y )
end

function NEGUIEditor.onRender ( )
	local this = NEGUIEditor
	if this.selectedElement then
		local wx, wy = guiGetPosition ( this.wnd, false )
		local ex, ey = guiGetPosition ( this.selectedElement, false )
		local ewidth, eheight = guiGetSize ( this.selectedElement, false )

		dxDrawRectangleFrame ( wx + ex, wy + ey, ewidth, eheight, _settings.frameColor, 1, true )
	end
end

function NEGUIEditor.updateNode ( guielement, updateType )
	local this = NEGUIEditor

	local node = this.guiBinds [ guielement ]
	if not node then
		return
	end
	
	-- Position only
	if updateType == 0 then
		local x, y = guiGetPosition ( guielement, true )
		--if this.new ~= nil then
			local index = node.abstr:getIndexFromName ( "Position" )
			local propStr = math.round ( x, 3 ) .. "," .. math.round ( y, 3 )
			node:setProperty ( index, propStr )
			GraphProperties.updateProperty ( index, propStr )
		--else
		
		--end
	
	-- Size only
	elseif updateType == 1 then
		local width, height = guiGetSize ( guielement, true )
		--if this.new ~= nil then
			local index = node.abstr:getIndexFromName ( "Size" )
			local propStr = math.round ( width, 3 ) .. "," .. math.round ( height, 3 )
			node:setProperty ( index, propStr )
			GraphProperties.updateProperty ( index, propStr )
		--else
		
		--end
	end
end

function NEGUIEditor.onNodePropertyChange ( propertyControl )
	if NEGUIEditor.active then
		local guielement = nodeGUI [ propertyControl.node ]
		if not guielement then
			return
		end
	
		local controlData = propertyControl:getData ( )
		local controlName = propertyControl.name
		if controlName == "Text" then
			guiSetText ( guielement, tostring ( controlData ) )
		elseif controlName == "Position" then
			local x = gettok ( controlData, 1, 44 )
			local y = gettok ( controlData, 2, 44 )
				
			x, y = tonumber ( x ), tonumber ( y )
			if x and y then
			guiSetPosition ( guielement, x, y, true )
			end
		elseif controlName == "Size" then
			local width = gettok ( controlData, 1, 44 )
			local height = gettok ( controlData, 2, 44 )
				
			width, height = tonumber ( width ), tonumber ( height )
			if width and height then
				guiSetSize ( guielement, width, height, true )
			end
		end
	end
end

function NEGUIEditor.getElementNearPoint ( x, y )
	local wx, wy = guiGetPosition ( NEGUIEditor.wnd, false )
	local elements = NEGUIEditor.guiBinds
	for element, _ in pairs ( elements ) do
		local ex, ey = guiGetPosition ( element, false )
		local ewidth, eheight = guiGetSize ( element, false )
		
		if isPointInBox ( x, y, wx + ex, wy + ey, ewidth, eheight ) then
			return element
		end
	end
end

function NEGUIEditor.getSizableFlanges ( guielement )
	local wx, wy = guiGetPosition ( NEGUIEditor.wnd, false )
	local x, y = guiGetPosition ( guielement, false )
	x, y = wx + x, wy + y
	local width, height = guiGetSize ( guielement, false )

	local fSize = 10
	local fDoubleSize = fSize * 2
	local flanges = {
		-- Left corner, top, right corner
		{ x = x, y = y, width = fSize, height = fSize },
		{ x = x + fSize, y = y, width = width - fDoubleSize, height = fSize },
		{ x = x + width - fSize, y = y, width = fSize, height = fSize },
		
		-- Left / right
		{ x = x, y = y + fSize, width = fSize, height = height - fDoubleSize },
		{ x = x + width - fSize, y = y + fSize, width = fSize, height = height - fDoubleSize },
		
		-- Left corner, bottom, right corner
		{ x = x, y = y + height - fSize, width = fSize, height = fSize },
		{ x = x + fSize, y = y + height - fSize, width = width - fDoubleSize, height = fSize },
		{ x = x + width - fSize, y = y + height - fSize, width = fSize, height = fSize }
	}
	
	return flanges
end