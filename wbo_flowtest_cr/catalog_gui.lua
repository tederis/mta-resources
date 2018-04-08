local extraGui = { }

local textColor = tocolor ( 200, 200, 200, 255 )
local _controls = {
	lbl = { width = 400 },
	edit = { width = 220, height = 25 },
	btn = { width = 200, height = 25 },
	checkbox = { width = 250, height = 25 },
	list = { width = 200, height = 330 },
	tab = { width = 100, height = 10 },
	gridlist = { width = 150, height = 345 },
	combobox = { width = 100, height = 100 }
}

PageGUI = { }
PageGUI.__index = PageGUI

function PageGUI.attach ( tabelement )
	local page = {
		element = tabelement
	}
	
	local parent = getElementParent ( tabelement )
	local sizex, sizey = guiGetSize ( parent, false )
	page.width = sizex
	page.height = sizey
	
	return setmetatable ( page, PageGUI )
end

function PageGUI:setPage ( page )
	if self.page ~= nil then
		for id, ctrl in pairs ( self.page._controls ) do
			if isElement ( ctrl.element ) then
				destroyElement ( ctrl.element )
			end
			if isElement ( ctrl.label ) then
				destroyElement ( ctrl.label )
			end
		end
		
		self.page.active = nil
	end
	
	page.active = true
	page._controls = { }

	self.page = page
	self:plain ( page )
	self:build ( page )
end

local function getTextFullHeight ( width, ctrl )
	local textWidth = dxGetTextWidth ( getLStr ( ctrl.text ), ctrl.scale, "arial" )
	local textHeight = dxGetFontHeight ( ctrl.scale, "arial" )
	
	return math.floor ( ( textWidth / width ) + 1 + 0.5 ) * textHeight
end
function PageGUI:plain ( page )
	local parent = self
	if page.width then
		parent = page
	end
	
	for i, ctrl in ipairs ( page.controls ) do
		local ctrlType = ctrl [ 1 ]
		
		local controlData = _controls [ ctrlType ]
		if controlData then
			for key, value in pairs ( controlData ) do
				if ctrl [ key ] == nil then
					ctrl [ key ] = value
				end
			end
		end
		
		if ctrl.id then
			_controls [ ctrl.id ] = ctrl
		end
		
		if ctrlType == "lbl" then
			ctrl.height = getTextFullHeight ( self.width, ctrl )
			ctrl.width = self.width
		elseif ctrlType == "btn" then
			ctrl.width = dxGetTextWidth ( getLStr ( ctrl.text ), 1, "arial" ) + 14
		elseif ctrlType == "edit" then
			if ctrl.text then
				ctrl.height = ctrl.height + 20
			end
		end
		
		local _x = 10
		local _y = 10
		local prevCtrl = page.controls [ i - 1 ]
		if prevCtrl then
			_y = prevCtrl.y
		
			if ctrl.atp then
				_x = prevCtrl.x + prevCtrl.width + 10
			else
				_y = _y + prevCtrl.height + 10
			end
		end
		
		ctrl.x = ctrl.x or _x
		ctrl.y = ctrl.y or _y
		
		if ctrl.controls then
			self:plain ( ctrl )
		end
	end
end

function PageGUI:build ( page )
	local parent = self.element
	if page.element then
		parent = page.element
	end
	
	for i, ctrl in ipairs ( page.controls ) do
		local ctrlType = ctrl [ 1 ]
		local _y = ctrl.y
		
		local element
		if ctrlType == "lbl" then
			element = guiCreateLabel ( ctrl.x, _y, ctrl.width, ctrl.height, ctrl.text, false, parent )
			guiLabelSetHorizontalAlign ( element, "left", true )
		elseif ctrlType == "edit" then
			if ctrl.text then
				ctrl.label = guiCreateLabel ( ctrl.x, _y, ctrl.width, 20, ctrl.text, false, parent )
				_y = _y + 20
			end
			element = guiCreateEdit ( ctrl.x, _y, ctrl.width, 25, "", false, parent )
			if ctrl.onBlur then
				addEventHandler ( "onClientGUIBlur", element, ctrl.onBlur, false )
			end
			if ctrl.onChange then
				addEventHandler ( "onClientGUIChanged", element, ctrl.onChange, false )
			end
		elseif ctrlType == "checkbox" then
			element = guiCreateCheckBox ( ctrl.x, _y, ctrl.width, ctrl.height, ctrl.text, ctrl.selected == true, false, parent )
			if ctrl.onClick then
				addEventHandler ( "onClientGUIClick", element, ctrl.onClick, false )
			end
		elseif ctrlType == "btn" then
			element = guiCreateButton ( ctrl.x, _y, ctrl.width, ctrl.height, ctrl.text, false, parent )
			if ctrl.onClick then
				addEventHandler ( "onClientGUIClick", element, ctrl.onClick, false )
			end
		elseif ctrlType == "gridlist" then
			element = guiCreateGridList ( ctrl.x, _y, ctrl.width, ctrl.height, false, parent )
			guiGridListSetSortingEnabled ( element, false )
			for _, column in ipairs ( ctrl.columns ) do
				guiGridListAddColumn ( element, column.name or "", column.width or 1 )
			end
			if ctrl.onClick then
				addEventHandler ( "onClientGUIClick", element, ctrl.onClick, false )
			end
			if ctrl.onDoubleClick then
				addEventHandler ( "onClientGUIDoubleClick", element, ctrl.onDoubleClick, false )
			end
		elseif ctrlType == "combobox" then
			element = guiCreateComboBox ( ctrl.x, _y, ctrl.width, ctrl.height, ctrl.text or "", false, parent )
			if ctrl.items then
				for _, itemText in ipairs ( ctrl.items ) do
					guiComboBoxAddItem ( element, itemText )
				end
			end
			if ctrl.onAccepted then
				addEventHandler ( "onClientGUIComboBoxAccepted", element, ctrl.onAccepted, false )
			end
		end
		
		if ctrl.id then
			page._controls [ ctrl.id ] = ctrl
		else
			page._controls [ i ] = ctrl
		end
		
		ctrl.element = element
		
		if ctrl.controls then
			self:build ( ctrl )
		end
	end
	
	if self.page.onCreate then
		self.page:onCreate ( )
	end
end