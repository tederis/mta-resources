Control = { }
Control.__index = Control

local guiControls = {
	[ "checkbox" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = { 
				element = guiCreateCheckBox ( 0.02, ypos, 0.96, 0.032, tbl.text, tbl.selected, true, parent ) 
			}
			
			return control
		end,
		get = function ( self )
			return guiCheckBoxGetSelected ( self.element )
		end,
		set = function ( self, selected )
			guiCheckBoxSetSelected ( self.element, selected )
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
						tbl.onScroll ( value )
					end
				end
			, false )
			
			return control
		end,
		get = function ( self )
			return guiToReal ( self.min, self.max, guiScrollBarGetScrollPosition ( self.element ), true )
		end,
		set = function ( self, value )
			guiScrollBarSetScrollPosition ( self.element, realToGui ( self.min, self.max, value ) )
		end
	},
	[ "edit" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateEdit ( 0.02, ypos + 0.045, 1, 0.044, tbl.value or "", true, parent )
			}
			
			if tbl.maxLength then
				guiEditSetMaxLength ( control.element, tbl.maxLength )
			end
			
			return control
		end,
		get = function ( self )
			return guiGetText ( self.element )
		end,
		set = function ( self, text )
			guiSetText ( self.element, text )
		end
	},
	[ "memo" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateMemo ( 0.02, ypos + 0.045, 1, 0.044 * 6, "", true, parent )
			}
			
			if tbl.readOnly then
				guiMemoSetReadOnly ( control.element, true )
			end
			
			return control
		end,
		get = function ( self )
			return guiGetText ( self.element )
		end,
		set = function ( self, text )
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
		end
	},
	[ "combobox" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				header = guiCreateLabel ( 0.02, ypos, 0.96, 0.05, tbl.text, true, parent ),
				element = guiCreateComboBox ( 0.02, ypos + 0.045, 1, 0.044 * 6, "", true, parent )
			}
			
			for _, item in ipairs ( tbl.items ) do
				guiComboBoxAddItem ( control.element, item [ 1 ] )
			end
			
			guiComboBoxSetSelected ( control.element, 0 )
			
			if tbl.onAccepted then
				addEventHandler ( "onClientGUIComboBoxAccepted", control.element, tbl.onAccepted, false )
			end
			
			return control
		end,
		get = function ( self )
			local selectedItem = guiComboBoxGetSelected ( self.element )
			
			return selectedItem--guiComboBoxGetItemText ( self.element, selectedItem )
		end
	},
	[ "gridlist" ] = {
		create = function ( tbl, parent )
			local ypos = calcControlsOffset ( parent )
			
			local control = {
				element = guiCreateGridList ( 0.02, ypos, 1, 0.044 * 6, true, parent )
			}
			
			guiGridListSetSortingEnabled ( control.element, false )
			
			local column = guiGridListAddColumn ( control.element, tbl.text, 0.5 )
			
			for groupName, group in pairs ( tbl.item ) do
				local row = guiGridListAddRow ( control.element )
				guiGridListSetItemText ( control.element, row, column, groupName, true, false )
			
				for _, item in ipairs ( group ) do
					row = guiGridListAddRow ( control.element )
					guiGridListSetItemText ( control.element, row, column, item, false, false )
				end
			end
			
			return control
		end,
		get = function ( self )
			local row = guiGridListGetSelectedItem ( self.element )
			if row > -1 then
				return guiGridListGetItemText ( self.element, row, 1 )
			end
		
			return false
		end
	}
}

function createControl ( args, parent )
	local controlType = args [ 1 ]
	
	local control = guiControls [ controlType ].create ( args, parent )
	
	return setmetatable ( control, { __index = {
		getData = guiControls [ controlType ].get,
		setData = guiControls [ controlType ].set
	} } )
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