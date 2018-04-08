ActionList = {
	items = { },
	rowWidth = 100,
	selectedRow = 1
}

function ActionList.setTargetElement ( element )
	if ActionList.element then
		removeEventHandler ( "onClientRender", root, ActionList.render )
		unbindKey ( "mouse_wheel_up", "down", ActionList.binds )
		unbindKey ( "mouse_wheel_down", "down", ActionList.binds )
		ActionList.element = nil
	end
	
	if element then
		ActionList.element = element
	
		addEventHandler ( "onClientRender", root, ActionList.render )
		bindKey ( "mouse_wheel_up", "down", ActionList.binds )
		bindKey ( "mouse_wheel_down", "down", ActionList.binds )
	end
end

function ActionList.setItems ( items )
	if type ( items ) ~= "table" then
		return
	end
	
	ActionList.selectedRow = 1
	ActionList.items = items
	
	for _, itemStr in ipairs ( ActionList.items ) do
		if type ( itemStr ) == "table" then
			itemStr = itemStr.name
		end
		
		local textWidth = dxGetTextWidth ( itemStr, 1.5, "default" )
		ActionList.rowWidth = math.max ( ActionList.rowWidth, textWidth + 40 )
	end
end

function ActionList.getSelectedItem ( )
	return ActionList.selectedRow
end

function ActionList.render ( )
	local sx, sy = getScreenFromWorldPosition ( 
		getElementPosition ( ActionList.element ) 
	)
	
	if not sx then
		return
	end
	
	dxDrawRectangle ( sx, sy + 25, ActionList.rowWidth, #ActionList.items * 25, color.background )
	
	for i, itemStr in ipairs ( ActionList.items ) do
		local ry = sy + ( 25 * i )
    
		--Если этот пункт выбран в списке
		if i == ActionList.selectedRow then
			dxDrawRectangle ( sx, ry, ActionList.rowWidth, 25, color.selected )
		end
		
		if type ( itemStr ) == "table" then
			itemStr = itemStr.name
		end
		
		dxDrawText ( tostring ( itemStr ), 
			sx + 20, ry, sx + ActionList.rowWidth, ry + 25, color.text, 1.5, "default" 
		)
	end
end

function ActionList.binds ( key )
	if key == "mouse_wheel_up" then
		ActionList.selectedRow = math.max ( ActionList.selectedRow - 1, 1 )
	elseif key == "mouse_wheel_down" then
		ActionList.selectedRow = math.min ( ActionList.selectedRow + 1, #ActionList.items )
	end
end

--[[
	GraphBrowser
]]

GraphBrowser = { }

function GraphBrowser.create ( )
	GraphBrowser._loadItems ( )
	
	addEventHandler ( "onClientRender", root, GraphBrowser.onRender, false )
end

function GraphBrowser._loadItems ( )
	GraphBrowser.items = { }
	
	local graphs = getElementsByType ( "ne:graph", resourceRoot )
	for _, graph in ipairs ( graphs ) do
		if Editor.isElementOwner ( graph ) then
			table.insert ( GraphBrowser.items, graph )
		end
	end
end

function GraphBrowser.onRender ( )
	
end