Control = { }
Control.__index = Control

local guiControls = {
	[ "checkbox" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = { 
				element = guiCreateCheckBox ( 0.02, ypos, 0.96, 0.032, tbl.text, tbl.selected, true, parent ) 
			}
			
			if tbl.onClick then
				addEventHandler ( "onClientGUIClick", control.element, 
					function ( button, state )
						tbl.onClick ( control )
					end
				, false )
			end
			
			return control
		end,
		getData = function ( self )
			return guiCheckBoxGetSelected ( self.element )
		end,
		setData = function ( self, selected )
			guiCheckBoxSetSelected ( self.element, selected )
		end,
		setLabelText = function ( self, str )
			guiSetText ( self.element, str )
		end
	},
	[ "scrollbar" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text .. "(" .. tbl.value [ 1 ] .. ")", true, parent ),
				element = guiCreateScrollBar ( 0.02, ypos + 0.045, 1, 0.04, true, true, parent ),
				min = tbl.value.min,
				max = tbl.value.max
			}
  
			guiScrollBarSetScrollPosition ( control.element, realToGui ( tbl.value.min, tbl.value.max, tbl.value [ 1 ] ) )
			
			addEventHandler ( "onClientGUIScroll", control.element, 
				function ( )
					local value = guiToReal ( control.min, control.max, guiScrollBarGetScrollPosition ( control.element ), true )
					value = math.round ( value, 1 )
					
					guiSetText ( control.header, tbl.text .. "(" .. value .. ")" )
				
					if tbl.onScroll then
						tbl.onScroll ( value, control )
					end
				end
			, false )
			
			return control
		end,
		getData = function ( self )
			return guiToReal ( self.min, self.max, guiScrollBarGetScrollPosition ( self.element ), true )
		end,
		setData = function ( self, value )
			guiScrollBarSetScrollPosition ( self.element, realToGui ( self.min, self.max, value ) )
		end,
		setLabelText = function ( self, str )
			guiSetText ( self.header, str )
		end
	},
	[ "edit" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateEdit ( 0.02, ypos + 0.045, 1, 0.044, tbl.value or "", true, parent ),
				type = "edit"
			}
			
			if tbl.maxLength then
				guiEditSetMaxLength ( control.element, tbl.maxLength )
			end
			
			if tbl.onChanged then
				addEventHandler ( "onClientGUIChanged", control.element, 
					function ( )
						local text = guiGetText ( source )
						tbl.onChanged ( control, text )
					end
				, false )
			end
			
			return control
		end,
		getData = function ( self )
			return guiGetText ( self.element )
		end,
		setData = function ( self, text )
			guiSetText ( self.element, text )
		end,
		setLabelText = function ( self, str )
			guiSetText ( self.header, str )
		end
	},
	[ "memo" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateMemo ( 0.02, ypos + 0.045, 1, 0.044 * 6, tbl.value or "", true, parent )
			}
			
			if tbl.readOnly then
				guiMemoSetReadOnly ( control.element, true )
			end
			
			return control
		end,
		getData = function ( self )
			return guiGetText ( self.element )
		end,
		setData = function ( self, text )
			guiSetText ( self.element, text )
		end
	},
	[ "button" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				element = guiCreateButton ( 0.02, ypos, 1, 0.044, tbl.text, true, parent )
			}
			
			if tbl.onClick then
				addEventHandler ( "onClientGUIClick", control.element, tbl.onClick, false )
			end
			
			return control
		end,
		getData = function ( self )
			return guiGetText ( self.element )
		end,
		setData = function ( self, text )
			guiSetText ( self.element, text )
		end,
	},
	[ "combobox" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateComboBox ( 0.02, ypos + 0.045, 1, 0.044 * 6, "", true, parent )
			}
			
			if tbl.items then
				for _, item in ipairs ( tbl.items ) do
					guiComboBoxAddItem ( control.element, type ( item ) == "table" and tostring ( item [ 1 ] ) or tostring ( item ) )
				end
			end
			guiComboBoxSetSelected ( control.element, 0 )
			
			if type ( tbl.onAccepted ) == "function" then
				addEventHandler ( "onClientGUIComboBoxAccepted", control.element, 
					function ( )
						local selectedItem = guiComboBoxGetSelected ( source )
						if selectedItem > -1 then
							tbl.onAccepted ( selectedItem )
						end
					end
				, false )
			end
			
			return control
		end,
		setData = function ( self, itemIndex )
			guiComboBoxSetSelected ( self.element, itemIndex )
		end,
		getData = function ( self )
			local selectedItem = guiComboBoxGetSelected ( self.element )
			
			return selectedItem
		end
	},
	[ "gridlist" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateGridList ( 0.02, ypos + 0.045, 1, 0.044 * 6, true, parent )
			}
			
			if tbl.selectionMode then
				guiGridListSetSelectionMode ( control.element, tbl.selectionMode )
			end
			
			if tbl.columns then
				guiGridListSetSortingEnabled ( control.element, false )
				for i, column in ipairs ( tbl.columns ) do
					guiGridListAddColumn ( control.element, column.text or column.attr or "", column.width or 0.5 )
				end
			end
			
			if tbl.onClick then
				addEventHandler ( "onClientGUIClick", control.element,
					function ( )
						tbl.onClick ( control )
					end
				, false )
			end
			
			return control
		end,
		setData = function ( self, ... )
			local row = guiGridListAddRow ( self.element )
			
			local args = { ... }
			for i, arg in ipairs ( args ) do
				guiGridListSetItemText ( self.element, row, i, tostring ( arg ), false, false )
			end
		end,
		getData = function ( self )
			local row, column = guiGridListGetSelectedItem ( self.element )
		
			return row, column
		end,
		setLabelText = function ( self, str )
			guiSetText ( self.header, str )
		end
	}
}

function createControl ( args, parent, name )
	local controlType = args [ 1 ]
	
	local control = guiControls [ controlType ].create ( args, parent )
	control.name = name
	
	return setmetatable ( control, { __index = guiControls [ controlType ] } )
end

--Helper functions
function calcControlsOffset ( element )
	local offset = 0.018
	
	local guiTop = getElementChildren ( element )
	guiTop = guiTop [ #guiTop ]
	
	if guiTop then
		local _, py = guiGetPosition ( guiTop, true )
		local _, sy = guiGetSize ( guiTop, true )
			
		if getElementType ( guiTop ) == "gui-combobox" then
			sy = 0.05
		end
			
		offset = offset + py + sy
	end
	
	return offset
end