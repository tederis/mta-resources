--Events
addEvent ( "onDestroyWBOWire", true )
addEvent ( "onCreateWBOWire", true )
addEvent ( "onButton", true )

------------------------
-- Custom data
------------------------
customData = { 
	items = { }
}

function customData.setElementData ( element, key, value )
	if not customData.items [ element ] then
		customData.items [ element ] = { }
	end
	
	customData.items [ element ] [ key ] = value
end

function customData.getElementData ( element, key )
	local elementData = customData.items [ element ]

	return elementData and elementData [ key ] or false
end

function customData.isElementDataEquals ( element, key, value )
	return customData.getElementData ( element, key ) == value
end

------------------------
-- Wire
------------------------
function wireTriggerOutput ( element, outputIndex, value, ... )
	local outputName = "out." .. outputIndex
	
	if customData.isElementDataEquals ( element, outputName, value ) then
		return
	end

	local wires = getElementsByType ( "wire", element )
	for _, wire in ipairs ( wires ) do
		local linkOut = tonumber ( 
			getElementData ( wire, "linkOut" )
		)
		if linkOut == outputIndex then
			wireTrigger ( wire, value, ... )
		end
	end
	
	customData.setElementData ( element, outputName, value )
	
	--outputChatBox(outputName .. "=" .. tostring ( value ) )
end

function wireTriggerInput ( element, inputIndex, value, ... )
	local inputName = "in." .. inputIndex

	if customData.isElementDataEquals ( element, inputName, value ) then
		return
	end

	local events = getComponentEvents ( element )
	if not events then
		return
	end

	if events.inputs and events.inputs [ inputIndex ] then
		value = convertValueByType ( value, events.inputs [ inputIndex ] [ 2 ] )
	end
			
	customData.setElementData ( element, inputName, value )
	
	if events.inputHandler then
		events.inputHandler ( element, inputIndex, value, ... )
	end
	
	--outputChatBox(inputName .. "=" .. tostring ( value ) )
end

function wireTrigger ( wire, value, ... )
	local linkTo = getElementData ( wire, "linkTo" )
	linkTo = type ( linkTo ) == "string" and getElementByID ( linkTo ) or false
		
	if linkTo then
		local linkIn = tonumber ( 
			getElementData ( wire, "linkIn" )
		)
		wireTriggerInput ( linkTo, linkIn, value, ... )
	end
end

addEventHandler ( "onElementDestroy", resourceRoot,
	function ( )
		local elementType = getElementType ( source )

		if elementType == "object" then
			local tag = getElementTag ( source )
			local component = getComponentByTag ( tag )
			if component then
				local inputs = component.events.inputs
			
				if tag == "gate" then
					local gate = Gate [ getElementData ( source, "gate" ) ]
					
					inputs = gate.inputs
				end
				
				if inputs then
					for i, input in ipairs ( inputs ) do
						local wireLinked = getElementData ( source, "linkFrom" .. i )
						wireLinked = type ( wireLinked ) == "string" and getElementByID ( wireLinked ) or false
			
						if wireLinked then
							destroyElement ( wireLinked )
						end
					end
				end
			end
		elseif elementType == "wire" then
			local linkTo = getElementData ( source, "linkTo" )
			linkTo = type ( linkTo ) == "string" and getElementByID ( linkTo ) or false
		
			if linkTo then
				local linkIn = tonumber ( 
					getElementData ( source, "linkIn" )
				)
				wireTriggerInput ( linkTo, linkIn, value )
				removeElementData ( linkTo, "linkFrom" .. linkIn )
			end
		end
	end
)

addEventHandler ( "onCreateWBOWire", resourceRoot,
	function ( child, parent, hidden )
		if isPlayerElementOwner ( client, child.element, parent.element ) ~= true then 
			outputChatBox ( "WBO: Вы не можете работать с этими объектами.", client, 255, 0, 0, true )
			
			return 
		end
		
		--Если нашли провод, удаляем его
		local wireLinked = getElementData ( child.element, "linkFrom" .. child.input )
		wireLinked = type ( wireLinked ) == "string" and getElementByID ( wireLinked ) or false
			
		if wireLinked then
			destroyElement ( wireLinked )
		end
 
		--Создаем новый провод
		local wire = createElement ( "wire" )
		
		local id = createElementID ( child.element )
		setElementData ( wire, "linkTo", id )
		setElementData ( wire, "linkIn", tostring ( child.input ) )
		setElementData ( wire, "linkOut", tostring ( parent.input ) )
		setElementParent ( wire, parent.element )
		
		setElementData ( child.element, "linkFrom" .. child.input, createElementID ( wire ) )
		
		--При подключении передаем приемнику значение источника
		local parentValue = customData.getElementData ( parent.element, "out." .. parent.input )
		wireTriggerInput ( child.element, child.input,
			convertValueByType ( parentValue, "number" ) 
		)
		
		--Если провод должен быть скрытым
		if hidden then
			setElementData ( wire, "hidden", "1" )
		else
			triggerClientEvent ( "onClientWireCreate", wire )
		end
 
		outputChatBox ( "WBO: Провод успешно создан", client )
	end
)

addEventHandler ( "onDestroyWBOWire", resourceRoot,
	function ( child )
		if isPlayerElementOwner ( client, child.element ) ~= true then 
			outputChatBox ( "WBO: Вы не можете удалить этот провод.", client, 255, 0, 0, true ) 
			
			return 
		end

		local wireLinked = getElementData ( child.element, "linkFrom" .. child.input )
		wireLinked = type ( wireLinked ) == "string" and getElementByID ( wireLinked ) or false
			
		if wireLinked then
			destroyElement ( wireLinked )
		end

		outputChatBox ( "WBO: Провод успешно удален", client )
	end
)

addEventHandler ( "onButton", root,
	function ( player, state, actionIndex )
		--local onValue = tonumber ( getElementData ( source, "onv" ) ) or 0 
		--local offValue = tonumber ( getElementData ( source, "offv" ) ) or 0
		
		--state = IfElse ( state, onValue, offValue )
		state = state and actionIndex or 0
			
		local toggle = tonumber ( getElementData ( source, "tgl" ) ) or 0
		if toggle > 0 then
			local lastState = customData.getElementData ( source, "out.1" )
				
			--state = IfElse ( lastState ~= state, onValue, offValue )
			state = lastState ~= state and actionIndex or 0
		end

		wireTriggerOutput ( source, 1, state, actionIndex )
	end 
)

addEventHandler ( "onMarkerHit", root, 
	function ( player, matchingDimension )
		if getElementType ( player ) == "player" and matchingDimension then
			local block = getElementParent ( source )
			
			if getElementData ( source, "tag" ) == "smarker" then
				wireTriggerOutput ( block, 1, 1 )
			end
		end
	end 
)

addEventHandler ( "onMarkerLeave", root, 
	function ( player, matchingDimension )
		if getElementType ( player ) == "player" and matchingDimension then
			local block = getElementParent ( source )
			
			if getElementData ( source, "tag" ) == "smarker" then
				wireTriggerOutput ( block, 1, 0 )
			end
		end
	end 
)

addEvent ( "onLasetStateChange", true )
addEventHandler ( "onLasetStateChange", resourceRoot,
	function ( newState )
		wireTriggerOutput ( source, 1, newState and 1 or 0 )
	end
)

function isOutput ( element, output )
	local events = getComponentEvents ( element )
	
	if events then
		return events.outputs and events.outputs [ output ] ~= nil
	end
	
	return false
end

function isElementPointInput ( element, pointName )
	local componentModel = getElementModel ( element )
	
	if Component [ componentModel ] and Component [ componentModel ].inputs [ pointName ] then
	
		return true
	end
	
	return false
end

function convertValueByType ( value, vType )
	if vType == "boolean" then
		return value ~= false and value ~= nil
	elseif vType == "number" then
		local newValue = tonumber ( value )
		if newValue then
			return newValue
		end
		
		return value and 1 or 0
	end
	
	outputDebugString ( "Неизвестный тип события" )
	
	return false
end

function toboolean ( value )
	local valueType = type ( value )
	
	if valueType == "string" or valueType == "number" then
		value = tonumber ( value )

		return value and value > 0
	end
	
	return value ~= false and value ~= nil
end

function bool2int ( value )
	if type ( value ) == "number" then return value end

	if value then
		return 1
	end
	
	return 0
end

function int2bool ( value )
	value = tonumber ( value )
	
	if value > 0 then
	
		return true
	end
	
	return false
end