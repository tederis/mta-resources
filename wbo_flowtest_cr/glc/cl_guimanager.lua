--[[
	GraphGUI
]]
GraphGUI = { }
GraphGUI.__index = GraphGUI

function GraphGUI.create ( graphId )
	local gui = {
		id = graphId
	}
	
	gui.wnd = guiCreateWindow ( sw * 0.3, sh * 0.3, 400, 400, "Window", false  )
	
	setmetatable ( gui, GraphGUI )
	return gui
end

function GraphGUI:destroy ( )
	destroyElement ( self.wnd )
end

--[[
	GraphGUIControl
]]
GraphGUIControl = { }
GraphGUIControl.__index = GraphGUIControl

local guiControls = { }

function GraphGUIControl.create ( graphGUI )
	local ctrl = { 
		gui = graphGUI
	}

	return setmetatable ( ctrl, GraphGUIControl )
end

function GraphGUIControl:unpack ( packedNode )
	local guiType = packedNode [ 1 ]
	self.type = guiType
	self.id = packedNode [ 2 ]
	
	local x, y = packedNode [ 3 ] or 0, packedNode [ 4 ] or 0
	local width, height = packedNode [ 5 ] or 1, packedNode [ 6 ] or 1
	
	local guielement
	if guiType == "btn" then
		guielement = guiCreateButton ( x, y, width, height, tostring ( packedNode [ 7 ] ), true, self.gui.wnd )
		addEventHandler ( "onClientGUIClick", guielement, GraphGUIControl.onClick, false )
	elseif guiType == "checkbox" then
		guielement = guiCreateCheckBox ( x, y, width, height, tostring ( packedNode [ 7 ] ), packedNode [ 8 ] == true, true, self.gui.wnd )
		addEventHandler ( "onClientGUIClick", guielement, GraphGUIControl.onClick, false )
	elseif guiType == "combobox" then
		guielement = guiCreateComboBox ( x, y, width, height, tostring ( packedNode [ 7 ] ), true, self.gui.wnd )
		
		local items = packedNode [ 8 ]
		for i = 1, #items do
			guiComboBoxAddItem ( guielement, tostring ( items [ i ] ) )
		end
		
		guiComboBoxSetSelected ( guielement, 0 )
		addEventHandler ( "onClientGUIComboBoxAccepted", guielement, GraphGUIControl.onComboBoxAccepted, false )
	elseif guiType == "edit" then
		guielement = guiCreateEdit ( x, y, width, height, tostring ( packedNode [ 7 ] ), true, self.gui.wnd )
		addEventHandler ( "onClientGUIChanged", guielement, GraphGUIControl.onChange, false )
	elseif guiType == "lbl" then
		guielement = guiCreateLabel ( x, y, width, height, tostring ( packedNode [ 7 ] ), true, self.gui.wnd )
	end
	
	self.element = guielement
	guiControls [ guielement ] = self
end

function GraphGUIControl.onClick ( )
	local ctrl = guiControls [ source ]
	if ctrl then
		if ctrl.type == "btn" then
			triggerServerEvent ( "onGraphGUIAction", resourceRoot, ctrl.gui.id, ctrl.id )
		elseif ctrl.type == "checkbox" then
			local selected = guiCheckBoxGetSelected ( source )
			triggerServerEvent ( "onGraphGUIAction", resourceRoot, ctrl.gui.id, ctrl.id, selected )
		end
	end
end

function GraphGUIControl.onComboBoxAccepted ( )
	local ctrl = guiControls [ source ]
	if ctrl then
		if ctrl.type == "combobox" then
			local selectedItem = guiComboBoxGetSelected ( source )
			if selectedItem > -1 then
				triggerServerEvent ( "onGraphGUIAction", resourceRoot, ctrl.gui.id, ctrl.id, selectedItem+1 )
			end
		end
	end
end

function GraphGUIControl.onChange ( )
	local ctrl = guiControls [ source ]
	if ctrl then
		if ctrl.type == "edit" then
			local text = guiGetText ( source )
			triggerServerEvent ( "onGraphGUIAction", resourceRoot, ctrl.gui.id, ctrl.id, text )
		end
	end
end

local GraphGUIs = { }
local guiRefs = 0

function destroyAllGUIs ( )
	for id, gui in pairs ( GraphGUIs ) do
		gui:destroy ( )
	end
	GraphGUIs = { }
	guiControls = { }
	guiRefs = 0
end

function isInsideGUIs ( x, y )
	for id, gui in pairs ( GraphGUIs ) do
		local wx, wy = guiGetPosition ( gui.wnd, false )
		local wwidth, wheight = guiGetSize ( gui.wnd, false )
		
		if isPointInBox ( x, y, wx, wy, wwidth, wheight ) then
			return true
		end
	end
end

local function onClick ( button, state, absoluteX, absoluteY )
	if button ~= "left" or state ~= "up" then
		return
	end
	
	if isInsideGUIs ( absoluteX, absoluteY ) ~= true then
		destroyAllGUIs ( )
		removeEventHandler ( "onClientClick", root, onClick )
		showCursor ( false )
		triggerServerEvent ( "onGraphGUIHide", resourceRoot )
	end
end

addEvent ( "onClientGUIReceive", true )
addEventHandler ( "onClientGUIReceive", resourceRoot,
	function ( packedGUI )
		local graphId = packedGUI [ 1 ]
		if GraphGUIs [ graphId ] then
			GraphGUIs [ graphId ]:destroy ( )
			guiRefs = guiRefs - 1
		end
		
		local gui = GraphGUI.create ( graphId )
		for i = 2, #packedGUI do
			local ctrl = GraphGUIControl.create ( gui )
			ctrl:unpack ( packedGUI [ i ] )
		end
		
		guiRefs = guiRefs + 1
		GraphGUIs [ graphId ] = gui
		
		if guiRefs == 1 then
			addEventHandler ( "onClientClick", root, onClick, false )
		end
		
		showCursor ( true )
	end
, false )

addEvent ( "onClientGUIHide", true )
addEventHandler ( "onClientGUIHide", resourceRoot,
	function ( graphId )
		local gui = GraphGUIs [ graphId ]
		if gui then
			gui:destroy ( )
			showCursor ( false )
		end
		GraphGUIs [ graphId ] = nil
	end
, false )