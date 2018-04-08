local targetComponent
local selectedRow = 1
local rows = { }

local wirePool = { }

local color = { 
	background = tocolor ( 0, 0, 0, 160 ),
	selected = tocolor ( 70, 140, 30, 150 ),
	used = tocolor ( 255, 0, 0, 150 ),
	text = tocolor ( 255, 255, 255, 255 ),
	wire = tocolor ( 89, 89, 89, 255 ),
	wireActive = tocolor ( 214, 49, 49, 255 ),
	add = tocolor ( 89, 89, 89, 150 ),
	info = tocolor ( 0, 0, 200, 160 )
	
}

wire = { }

Wire = { 
	
}

addEvent ( "onClientWireTarget", true )
addEventHandler ( "onClientWireTarget", resourceRoot,
	function ( inputIndex, inputValue )
		--Wire.target = source
		--Wire.
	end
)

function wireLink ( element, hidden )
	if wire.dst then
		if element then
			triggerServerEvent ( "onCreateWBOWire", resourceRoot, wire.dst, { 
				element = element, input = selectedRow
			}, hidden )
		else
			triggerServerEvent ( "onDestroyWBOWire", resourceRoot, wire.dst )
		end
		
		wire.dst = nil
	else
		if element then
			wire.dst = { 
				element = element,
				input = selectedRow
			}
		
			Wire.setTarget ( )
		end
	end
end
 
function wireGetSelectedPin ( )
 if targetComponent then
  return rows [ selectedRow ]
 end
 return false
end

function getMaxWidth ( tbl, element )
	local width = 0
	
	for _, row in ipairs ( tbl ) do
		if element then
			row = row .. " : " .. tostring ( getElementData ( element, row ) )
		end
		
		local textWidth = dxGetTextWidth ( row, 1.5 )
		
		if textWidth > width then
			width = textWidth
		end
	end
	
	return width
end

function isInputAlreadyUsed ( element, inputIndex )
	return getElementData ( element, "linkFrom" .. inputIndex ) ~= false
end

function getInputValue ( element, inputIndex )
	local inputPrefix = wire.dst and "out" or "in"
	local inputName = inputPrefix .. inputIndex
	
	return getElementData ( element, inputName )
end

function isInputExists ( element, index )
	local inputs
	if wire.dst then
		inputs = getElementsByType ( "output", element )
	else
		inputs = getElementsByType ( "input", element )
	end
	
	for _, input in ipairs ( inputs ) do
		local inputIndex = tonumber ( getElementData ( input, "index" ) )
	
		if inputIndex == index then
			return true
		end
	end


	--if getElementData ( element, "link" ) then
		--return true
	--end
	
	return false
end

addEventHandler ( "onClientRender", root,
	function ( )
		if not wire.target then
			return
		end
	
		Wire.drawUI ( )
	end 
)

function Wire.drawUI ( )
	local sx, sy = getScreenFromWorldPosition ( 
		getElementPosition ( wire.target ) 
	)
	if not sx then
		return
	end
  
	dxDrawRectangle ( sx, sy + 25, wire.rowWidth, #rows * 25, color.background )
	
	dxDrawRectangle ( sx, sy, wire.rowWidth, 25, color.info )
	dxDrawText ( wire.desc, 
			sx, sy, sx + wire.rowWidth, sy + 25, color.text, 1.5, "default", "center", "center"
		)
   
	for i, row in ipairs ( rows ) do
		local ry = sy + ( 25 * i )
    
		--Если этот контакт выбран в меню
		if i == selectedRow then
			dxDrawRectangle ( sx, ry, wire.rowWidth, 25, color.selected )
		end
		
		--Если этот контакт уже подключен
		if isInputAlreadyUsed ( wire.target, i ) and not wire.dst then
			dxDrawRectangle ( sx, ry, wire.rowWidth, 25, color.used )
		end
		
		--local inputValue = getInputValue ( wire.target, i )
		--inputValue = tonumber ( inputValue ) and inputValue or "0"

		dxDrawText ( row [ 1 ], 
			sx + 20, ry, sx + wire.rowWidth, ry + 25, color.text, 1.5, "default" 
		)
	end
	
	
end

addEventHandler ( "onClientPlayerTarget", localPlayer,
	function ( target )
		Wire.setTarget ( target )
	end
)

function Wire.setTarget ( target )
	wire.target = nil
	rows = { }
	selectedRow = 1
	
	if not target then
		return
	end
	
	if getSelectedTool ( ):getName ( ) ~= "Wire" then
		return
	end
	
	local tag = getElementTag ( target )
	
	local component = getComponentByTag ( tag )
	if not component then
		return
	end
	local events = component.events
	
	--Если мы уже выбрали компонет для подключения
	if wire.dst then
		rows = events.outputs
		wire.desc = component.desc
	else
		if tag ~= "gate" then
			rows = events.inputs
			wire.desc = component.desc
		else
			local gateName = getElementData ( target, "gate" )
			local gate = Gate [ gateName ]
			if gate == nil then
				return
			end
			
			for _, inputName in ipairs ( gate.inputs ) do
				table.insert ( rows, { inputName } )
			end
			wire.desc = "Gate: " .. gateName
		end
	end
	
	if not rows then
		return
	end
			
	local width = 0
	for _, row in ipairs ( rows ) do
		--local index = getElementData ( row, "index" )
		local textWidth = 250--dxGetTextWidth ( name, 1.5 )
		
		if textWidth > width then
			width = textWidth
		end
	end
			
	if #rows > 0 then
		wire.rowWidth = width + 30
			
		wire.target = target
	end
end

function selectRow ( key )
	if not rows then return end
	
	if key == "mouse_wheel_up" then
		if ( selectedRow - 1 ) > 0 then
			selectedRow = selectedRow - 1
		end
	elseif key == "mouse_wheel_down" then
		if ( selectedRow + 1 ) <= #rows then
			selectedRow = selectedRow + 1
		end
	end
end
bindKey ( "mouse_wheel_up", "down", selectRow )
bindKey ( "mouse_wheel_down", "down", selectRow )

---------------------------
-- StreamedInWire
---------------------------
streamedInWire = { 
	items = { },
	color = tocolor ( 255, 0, 0, 255 )
}

addEventHandler ( "onClientRender", root,
	function ( )
		for _, item in ipairs ( streamedInWire.items ) do
			local px, py, pz = getElementPosition ( item.src )
			local lx, ly, lz = getElementPosition ( item.dst )
			
			dxDrawLine3D ( px, py, pz, lx, ly, lz, streamedInWire.color )
		end
	end
, false )

addEventHandler ( "onClientElementStreamIn", resourceRoot,
	function ( )
		if getSettingByID ( "s_wire" ):getData ( ) ~= true then
			return
		end
	
		if not isComponent ( source ) then
			return
		end
		
		local wires = getElementsByType ( "wire", source )
		for _, wire in ipairs ( wires ) do
			local visible = getElementData ( wire, "hidden" ) ~= "1"
			
			if visible then
				dst = getElementByID ( 
					getElementData ( wire, "linkTo" ) 
				)
			
				if dst then
					table.insert ( streamedInWire.items, {
						wire = wire,
						src = source,
						dst = dst }
					)
				end
			end
		end
    end
)

addEventHandler ( "onClientElementStreamOut", resourceRoot,
    function ( )
		if not isComponent ( source ) then
			return
		end
		
		for i, item in ipairs ( streamedInWire.items ) do
			if item.src == source then
				table.remove ( streamedInWire.items, i )
			elseif item.dst == source then
				table.remove ( streamedInWire.items, i )
			end
		end
    end
)

addEventHandler ( "onClientElementDestroy", resourceRoot,
	function ( )
		if getElementType ( source ) ~= "wire" then
			return
		end
		
		for i, item in ipairs ( streamedInWire.items ) do
			if item.wire == source then
				table.remove ( streamedInWire.items, i )
			end
		end
	end
)

addEvent ( "onClientWireCreate", true )
addEventHandler ( "onClientWireCreate", resourceRoot,
	function ( )
		if getSettingByID ( "s_wire" ):getData ( ) ~= true then
			return
		end
	
		local src = getElementParent ( source )
		
		if isElementStreamedIn ( src ) then
			table.insert ( streamedInWire.items, {
				wire = source,
				src = src,
				dst = getElementByID ( 
					getElementData ( source, "linkTo" ) 
				) }
			)
		end
	end
)