local sw, sh = guiGetScreenSize ( )
local halfScreenX, halfScreenY = sw / 2, sh / 2

GraphProperties = { 
	control = { }
}


GraphPropertyControl = { }
local function onControlEvent ( control )
	local propertyControl = control.gpc
	
	NEGUIEditor.onNodePropertyChange ( propertyControl )
end
local _controlListener = {
	__index = function ( t, key )
		if key == "onChanged" then
			return onControlEvent
		end
		
		local controlRef = rawget ( t, "ref" )
		return controlRef.control [ key ]
	end
}

function GraphPropertyControl.constructor ( ctrlName, ctrlType )
	local controlRef = GraphProperties.control [ ctrlType ]
	if controlRef == nil then return end;
	
	local propertyControl = {
		name = ctrlName,
		type = ctrlType
	}
	
	local controlMT = setmetatable ( { ref = controlRef }, _controlListener )
	local control = createControl ( controlMT, GraphProperties.scrollPane )
	control.gpc = propertyControl
	if type ( control.setLabelText ) == "function" then 
		control:setLabelText ( ctrlName )
	end
	propertyControl.control = control

	return setmetatable ( propertyControl, { __index = controlRef } )
end



function GraphProperties.create ( new )
	if GraphProperties.wnd == nil then
		GraphProperties.new = new

		GraphProperties.wnd = guiCreateWindow ( sw - 200 - 10, sh * 0.25, 200, 500, "Node Inspector", false )
		guiWindowSetSizable ( GraphProperties.wnd, false )
	end
end

function GraphProperties.setNode ( node )
	if GraphProperties.node then
		GraphProperties.saveNode ( GraphProperties.node )
		destroyElement ( GraphProperties.scrollPane )
	end
	
	if node then
		GraphProperties.controls = { }
	
		local nodeAbstr = node.abstr
	
		GraphProperties.scrollPane = guiCreateScrollPane ( 0.05, 0.05, 0.9, 0.9, true, GraphProperties.wnd )
		GraphProperties.header = guiCreateLabel ( 0.02, 0.02, 0.96, 0.04, nodeAbstr.fullName .. " ('" .. node.id .. "')", true, GraphProperties.scrollPane )
		guiSetFont ( GraphProperties.header, "default-bold-small" )
		
		local inputs = nodeAbstr.events.inputs
		if not inputs then
			return
		end
		
		local properties = node.properties
		for i, input in ipairs ( inputs ) do
			local inputType = input [ 2 ]
			if inputType ~= "any" and inputType ~= "element" then
				local control = GraphPropertyControl.constructor ( input [ 1 ], inputType )
				if control then
					control:setData ( tostring ( properties [ i ] ) )
					control.node = node
					GraphProperties.controls [ i ] = control
				end
			end
		end
	end
	
	GraphProperties.node = node
end

function GraphProperties.updateProperty ( index, value )
	local properties = GraphProperties.controls
	if properties [ index ] then
		properties [ index ]:setData ( tostring ( value ) )
	end
end

function GraphProperties.saveNode ( node )
	-- Если мы создаем новую схему не отправляем данные на сервер
	if GraphProperties.new or NEWorkspace.createCopy then
		for i, control in pairs ( GraphProperties.controls ) do
			local inputData = control:getData ( )
		
			node:setProperty ( i, inputData )
		end
	else
		local outpack = { }

		for i, control in pairs ( GraphProperties.controls ) do
			local inputData = control:getData ( )
			
			node:setProperty ( i, inputData )
			outpack [ #outpack + 1 ] = {
				i, inputData
			}
		end
	
		triggerServerEvent ( "onGraphAction", resourceRoot, node.graph.id, 0, node.id, outpack )
	end
end

function GraphProperties.onComponentDestroy ( component )
	if GraphProperties.component == component then
		destroyElement ( GraphProperties.scrollPane )
		GraphProperties.scrollPane = nil
	end
end

function GraphProperties.onMouseEnter ( x, y )
	-- TODO
end

function GraphProperties.isMouseOn ( mx, my )
	if GraphProperties.wnd then
		local x, y = guiGetPosition ( GraphProperties.wnd, false )
		
		return ( mx > x and mx < x + 200 ) and ( my > y and my < y + 500 )
	end
end

function GraphProperties.destroy ( )
	if GraphProperties.wnd then
		if GraphProperties.node then
			GraphProperties.saveNode ( GraphProperties.node )
		end
		GraphProperties.node = nil
	
		destroyElement ( GraphProperties.wnd )
		GraphProperties.wnd = nil
		GraphProperties.new = nil
	end
end

local _portCtrlName
local _createPortCtrl = function ( data )
	GraphProperties.control [ _portCtrlName ] = data
end
function PortCtrl ( name )
	_portCtrlName = name
	return _createPortCtrl
end

--[[
	Create most controls
]]
PortCtrl "number" {
	control = {
		"edit",
			
		id = "num",
		text = "",
		value = "0",
		maxLength = 10,
		onChange = GraphProperties.onControlChange
	},
	setData = function ( self, value )
		self.control:setData ( tostring ( value ) )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

PortCtrl "Vector2D" {
	control = {
		"edit",
			
		id = "vec2d",
		text = "",
		value = "0,0",
		onChange = GraphProperties.onControlChange
	},
	setData = function ( self, value )
		self.control:setData ( tostring ( value ) )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

PortCtrl "Vector3D" {
	control = {
		"edit",
			
		id = "vec3d",
		text = "",
		value = "0,0,0",
		onChange = GraphProperties.onControlChange
	},
	setData = function ( self, value )
		self.control:setData ( tostring ( value ) )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

PortCtrl "color" {
	control = {
		"edit",
			
		id = "clr",
		text = "",
		value = "0,0,0,0"
	},
	setData = function ( self, value )
		self.control:setData ( value )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

PortCtrl "string" {
	control = {
		"edit",
			
		id = "str",
		text = "",
		value = "",
		maxLength = 50,
		onChange = GraphProperties.onControlChange
	},
	setData = function ( self, value )
		self.control:setData ( value )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}

PortCtrl "bool" {
	control = {
		"checkbox",
			
		id = "bool",
		text = "",
		selected = false
	},
	setData = function ( self, value )
		self.control:setData ( tonumber ( value ) == 1 )
	end,
	getData = function ( self )
		return self.control:getData ( ) and "1" or "0"
	end
}

PortCtrl "_array" {
	control = {
		"memo",
			
		id = "bool",
		text = "",
		value = ""
	},
	setData = function ( self, value )
		self.control:setData ( tostring ( value ) )
	end,
	getData = function ( self )
		return self.control:getData ( )
	end
}