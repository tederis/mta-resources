sw, sh = guiGetScreenSize ( )

local _textColor = tocolor ( 245, 250, 245, 255 )
local _textHColor = tocolor ( 255, 255, 200, 255 )

local _focused

DEBUG = false

local ui_frame_01 = {
	left_top = { "ui_frame_01/ui_frame_01_lt", width = 32, height = 32 },
	top = { "ui_frame_01/ui_frame_01_t", width = 32, height = 32 },
	right_top = { "ui_frame_01/ui_frame_01_rt", width = 32, height = 32 },
	left = { "ui_frame_01/ui_frame_01_l", width = 32, height = 32 },
	back = { "ui_frame_01/ui_frame_01_back", width = 32, height = 32 },
	right = { "ui_frame_01/ui_frame_01_r", width = 32, height = 32 },
	left_bottom = { "ui_frame_01/ui_frame_01_lb", width = 32, height = 32 },
	bottom = { "ui_frame_01/ui_frame_01_b", width = 32, height = 32 },
	right_bottom = { "ui_frame_01/ui_frame_01_rb", width = 32, height = 32 }
}
local ui_frame_02 = {
	left_top = { "ui_frame_02/ui_frame_02_lt", width = 64, height = 64 },
	top = { "ui_frame_02/ui_frame_02_t", width = 64, height = 64 },
	right_top = { "ui_frame_02/ui_frame_02_rt", width = 64, height = 64 },
	left = { "ui_frame_02/ui_frame_02_l", width = 64, height = 64 },
	back = { "ui_frame_02/ui_frame_02_back", width = 64, height = 64 },
	right = { "ui_frame_02/ui_frame_02_r", width = 64, height = 64 },
	left_bottom = { "ui_frame_02/ui_frame_02_lb", width = 64, height = 64 },
	bottom = { "ui_frame_02/ui_frame_02_b", width = 64, height = 64 },
	right_bottom = { "ui_frame_02/ui_frame_02_rb", width = 64, height = 64 }
}
local ui_frame_03 = {
	left_top = { "ui_frame_03/ui_frame_03_lt", width = 64, height = 64 },
	top = { "ui_frame_03/ui_frame_03_t", width = 128, height = 64 },
	right_top = { "ui_frame_03/ui_frame_03_rt", width = 64, height = 64 },
	left = { "ui_frame_03/ui_frame_03_l", width = 64, height = 128 },
	back = { "ui_frame_03/ui_frame_03_back", width = 64, height = 64 },
	right = { "ui_frame_03/ui_frame_03_r", width = 64, height = 128 },
	left_bottom = { "ui_frame_03/ui_frame_03_lb", width = 64, height = 64 },
	bottom = { "ui_frame_03/ui_frame_03_b", width = 128, height = 64 },
	right_bottom = { "ui_frame_03/ui_frame_03_rb", width = 64, height = 64 }
}
local ui_frame_dialog = {
	left_top = { "ui_frame_dialog/ui_frame_dialog_lt", width = 128, height = 128 },
	top = { "ui_frame_dialog/ui_frame_dialog_t", width = 128, height = 128 },
	right_top = { "ui_frame_dialog/ui_frame_dialog_rt", width = 128, height = 128 },
	left = { "ui_frame_dialog/ui_frame_dialog_l", width = 128, height = 128 },
	back = { "ui_frame_dialog/ui_frame_dialog_back", width = 128, height = 128 },
	right = { "ui_frame_dialog/ui_frame_dialog_r", width = 128, height = 128 },
	left_bottom = { "ui_frame_dialog/ui_frame_dialog_lb", width = 128, height = 128 },
	bottom = { "ui_frame_dialog/ui_frame_dialog_b", width = 128, height = 128 },
	right_bottom = { "ui_frame_dialog/ui_frame_dialog_rb", width = 128, height = 128 }
}

local ui_string_07 = {
	begin = { "ui_string/ui_string_07_b", width = 32, height = 24 },
	back = { "ui_string/ui_string_07_back", width = 32, height = 24 },
	end_ = { "ui_string/ui_string_07_e", width = 32, height = 24 }
}

local ui_button = {
	ui_button_01 = { "ui_button/ui_button_01", usize = 138, vsize = 47 }
}

local function isPointInRectangle ( x, y, rx, ry, rw, rh )
	return ( x >= rx and x <= rx + rw ) and ( y >= ry and y <= ry + rh )
end

--[[
	UIString
	Отрисовка поля для ввода текста
]]
UIString = { }
UIString.__index = UIString

function UIString.new ( x, y, width, height, pattern )
	local str = {
		x = x, y = y,
		width = math.max ( width, pattern.begin.width*2 ),
		pattern = pattern
	}
	
	return setmetatable ( str, UIString )
end

function UIString:destroy ( )
	
end

function UIString:draw ( )
	local pattern = self.pattern
	local x = self.x
	local y = self.y
	-- Start fragment
	local fragment = pattern.begin
	dxDrawImageSection ( x, y, fragment.width, fragment.height, 0, 0, fragment.width, fragment.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Back fragment
	x = x + fragment.width
	local width = self.width - fragment.width*2
	fragment = pattern.back
	dxDrawImageSection ( x, y, width, fragment.height, 0, 0, fragment.width*(width/fragment.width), fragment.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- End fragment
	x = x + width
	fragment = pattern.end_
	dxDrawImageSection ( x, y, fragment.width, fragment.height, 0, 0, fragment.width, fragment.height, "textures/" .. fragment [ 1 ] .. ".dds" )
end

--[[
	UIFrame
	Отрисовка рамки
]]
UIFrame = { }
UIFrame.__index = UIFrame

function UIFrame.new ( x, y, width, height, pattern )
	local frame = {
		x = x, y = y,
		width = math.max ( width, pattern.left_top.width*2 ), height = math.max ( height, pattern.left_top.height*2 ),
		pattern = pattern
	}
	
	return setmetatable ( frame, UIFrame )
end

function UIFrame:destroy ( )

end

function UIFrame:draw ( )
	local pattern = self.pattern
	local x = self.x
	local y = self.y
	local corner = pattern.left_top
	local horizontal = pattern.top
	local vertical = pattern.left
	local back = pattern.back
	-- Top left fragment
	local fragment = pattern.left_top
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Top fragment
	x = x + corner.width
	local width = self.width - corner.width*2
	fragment = pattern.top
	dxDrawImageSection ( x, y, width, corner.width, 0, 0, horizontal.width*(width/horizontal.width), horizontal.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Top right fragment
	x = x + width
	fragment = pattern.right_top
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Left fragment
	x = self.x
	y = y + corner.height
	local height = self.height - corner.height*2
	fragment = pattern.left
	dxDrawImageSection ( x, y, vertical.width, height, 0, 0, vertical.width, vertical.height * (height/vertical.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Back
	x = x + vertical.width
	fragment = pattern.back
	dxDrawImageSection ( x, y, width, height, 0, 0, back.width * (width/back.width), back.height * (height/back.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Right fragment
	x = x + width
	fragment = pattern.right
	dxDrawImageSection ( x, y, vertical.width, height, 0, 0, vertical.width, vertical.height * (height/vertical.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom left
	x = self.x
	y = y + height
	fragment = pattern.left_bottom
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom
	x = x + corner.width
	fragment = pattern.bottom
	dxDrawImageSection ( x, y, width, horizontal.height, 0, 0, horizontal.width * (width/horizontal.width), horizontal.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom right
	x = x + width
	fragment = pattern.right_bottom
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
end

--[[
	UIControl
]]
UIControl = { }
UIControl.__index = UIControl

function UIControl.new ( x, y, width, height, text, relative, parent )
	local control = {
		x = x, y = y,
		width = width, height = height,
		text = text or "",
		maxLength = 100,
		relative = relative,
		parent = parent,
		children = { 
			-- Дочерние контролы
		},
		handlers = { 
			-- Обработчики событий
		},
		toRemove = {
		
		}
	}
	
	return control
end

function UIControl:destroy ( )
	if self.parent then
		self.parent:removeChild ( self )
	end
	local children = self:getChildren ( )
	for _, child in ipairs ( children ) do
		child:destroy ( )
	end
end

function UIControl:setText ( text )
	if utfLen ( text ) > self.maxLength then
		text = utfSub ( text, 1, self.maxLength )
	end
	self.text = text
end

function UIControl:setPosition ( x, y )
	x = tonumber ( x )
	y = tonumber ( y )
	if x and y then
		self.x, self.y = x, y
	end
end

function UIControl:insertChild ( control )
	table.insert ( self.children, control )
end

function UIControl:removeChild ( control )
	for i, child in ipairs ( self.children ) do
		if child == control then
			table.remove ( self.children, i )
			break
		end
	end
end

function UIControl:getChildren ( )
	local children = { }
	for _, child in ipairs ( self.children ) do
		table.insert ( children, child )
	end
	return children
end

function UIControl:addHandler ( eventName, fn )
	local handlers = self.handlers
	if handlers [ eventName ] then
		table.insert ( handlers [ eventName ], fn )
	else
		handlers [ eventName ] = {
			fn
		}
	end
end

function UIControl:trigger ( eventName, base, ... )
	if DEBUG then
		outputDebugString ( "Trigger event " .. eventName .. "(" .. base.type .. ")" )
	end

	local handlers = self.handlers
	if handlers [ eventName ] then
		for _, fn in ipairs ( handlers [ eventName ] ) do
			fn ( base, ... )
		end
	end
	
	local parent = self.parent
	while parent do
		parent:trigger ( eventName, base, ... )
		parent = parent.parent
	end
end

function UIControl:draw ( )
	if self.selected and self.hint then
		local cx, cy = getCursorPosition ( )
		cx, cy = cx * sw, cy * sh
		
		local textWidth = dxGetTextWidth ( self.hint, 1, "default" )
		local fontHeight = dxGetFontHeight ( 1, "default" )
		dxDrawRectangle ( cx, cy, textWidth, fontHeight, tocolor ( 0, 0, 0, 200 ), true )
		dxDrawText ( self.hint, cx, cy, 0, 0, _textColor, 1, "default", "left", "top", false, false, true )
	end
end

function UIControl:click ( button, state, absoluteX, absoluteY )
	_focused = nil

	self:trigger ( "onClick", self, button, state, absoluteX, absoluteY )
end

function UIControl:cursor ( absoluteX, absoluteY )
	if isPointInRectangle (
		absoluteX, absoluteY, 
		self.x, self.y,
		self.width, self.height
	) then
		self:trigger ( "onMouseMove", self, absoluteX, absoluteY )
		self.selected = true
	else
		self.selected = nil
	end
end

--[[
	UICanvas
]]
UICanvas = setmetatable ( { }, { __index = UIControl } )
UICanvas.__index = UICanvas

function UICanvas.new ( x, y, width, height )
	local canvas = {
		type = "canvas"
	}

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( x, y, width, height, "", false, nil )
	setmetatable ( super, UICanvas ) 
	
	canvas.super = super
	
	return setmetatable ( canvas,
		{ __index = super }
	)
end

function UICanvas:draw ( control )
	control = control or self
	for _, child in ipairs ( control.children ) do
		child:draw ( )
		self:draw ( child )
	end
end

function UICanvas:click ( button, state, absoluteX, absoluteY, control )
	control = control or self
	for _, child in ipairs ( control.children ) do
		if child.selected then
			child:click ( button, state, absoluteX, absoluteY )
		end
		self:click ( button, state, absoluteX, absoluteY, child )
	end
end

function UICanvas:cursor ( absoluteX, absoluteY, control )
	control = control or self
	for _, child in ipairs ( control.children ) do
		child:cursor ( absoluteX, absoluteY )
		self:cursor ( absoluteX, absoluteY, child )
	end
end

--[[
	UIWindow
]]
UIWindow = setmetatable ( { }, UIControl )
UIWindow.__index = UIWindow

function UIWindow.new ( x, y, width, height, titleBarText, relative )
	local wnd = {
		type = "wnd",
		font = xrInterface.font,
		textScale = 0.65
	}
	
	wnd.frame = UIFrame.new ( x, y, width, height, 
		ui_frame_03 -- Default
	)
	
	g_Canvas:insertChild ( wnd )
	
	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( x, y, width, height, titleBarText, relative, g_Canvas )
	setmetatable ( super, UIWindow ) -- Добавляем в общую таблицу для более быстрого доступа
	
	wnd.super = super

	return setmetatable ( wnd,
		{ __index = super }
	)
end

function UIWindow:setPosition ( x, y )
	UIControl.setPosition ( self, x, y )
	
	self.frame.x = x
	self.frame.y = y
end

function UIWindow:draw ( )
	UIControl.draw ( self )

	self.frame:draw ( )
	dxDrawImage ( self.x + 15, self.y - 20, 256, 64, "textures/ui_inv_info_over_lt.dds" )
	dxDrawText ( self.text, self.x, self.y, self.x + 256, self.y, _textColor, self.textScale, self.font, "center", "center" )
	dxDrawImage ( self.x - 15, self.y + self.height - 128, 64, 128, "textures/ui_frame_over_lb.dds" )
end

--[[
	UIEdit
]]
UIEdit = setmetatable ( { }, { __index = UIControl } )
UIEdit.__index = UIEdit

function UIEdit.new ( x, y, width, height, text, relative, parent )
	local edit = {
		type = "edit",
		
		maxLength = 10,
		
		font = xrInterface.font,
		textScale = 0.6
	}
	
	parent = parent or g_Canvas
	
	edit.string = UIString.new ( parent.x + x, parent.y + y, width, 24, 
		ui_string_07 -- Default
	)

	parent:insertChild ( edit )

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( parent.x + x, parent.y + y, width, 24, text, relative, parent )
	setmetatable ( super, UIEdit )
	
	edit.super = super
	
	return setmetatable ( edit,
		{ __index = super }
	)
end

function UIEdit:setPosition ( x, y )
	UIControl.setPosition ( self, x, y )
	
	self.string.x = x
	self.string.y = y
end

local _textMask = function ( text )
	local result = ""
	for i = 1, utfLen ( text ) do
		result = result .. "*"
	end
	return result
end
function UIEdit:draw ( )
	UIControl.draw ( self )
	
	self.string:draw ( )
	local text = self.text
	if self.masked then
		text = _textMask ( text )
	end
	if self == _focused and getTickCount ( ) % 2000 >= 1000 then
		text = text .. "|"
	end
	dxDrawText ( text, self.x + 10, self.y, 0, self.y + self.height, _textColor, self.textScale, self.font, "left", "center" )
end

function UIEdit:click ( button, state, absoluteX, absoluteY )
	-- Вызываем метод базового класса
	UIControl.click ( self, button, state, absoluteX, absoluteY )
	
	_focused = self
end

--[[
	UIButton
]]
UIButton = setmetatable ( { }, { __index = UIControl } )
UIButton.__index = UIButton

function UIButton.new ( x, y, width, height, text, relative, parent )
	local btn = {
		type = "btn",
		pattern = ui_button.ui_button_01, -- Default
		font = xrInterface.font,
		textScale = 0.65
	}
	
	parent = parent or g_Canvas
	parent:insertChild ( btn )

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( parent.x + x, parent.y + y, width, height, text, relative, parent )
	setmetatable ( super, UIButton ) 
	
	btn.super = super
	
	return setmetatable ( btn,
		{ __index = super }
	)
end

function UIButton:draw ( )
	UIControl.draw ( self )

	local pattern = self.pattern
	dxDrawImageSection ( 
		self.x, self.y, self.width, self.height, 
		0, 0, pattern.usize, pattern.vsize, 
		"textures/" .. pattern [ 1 ] .. ".dds",
		0
	)
	dxDrawText ( self.text, self.x, self.y, self.x + self.width, self.y + self.height, self.selected and _textHColor or _textColor, self.textScale, self.font, "center", "center" )
end

--[[
	UILabel
]]
UILabel = setmetatable ( { }, { __index = UIControl } )
UILabel.__index = UILabel

function UILabel.new ( x, y, width, height, text, relative, parent )
	local lbl = {
		type = "lbl",
		font = xrInterface.font,
		textScale = 0.55
	}
	
	parent = parent or g_Canvas
	parent:insertChild ( lbl )

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( parent.x + x, parent.y + y, width, height, text, relative, parent )
	setmetatable ( super, UILabel ) 
	
	lbl.super = super
	
	return setmetatable ( lbl,
		{ __index = super }
	)
end

function UILabel:draw ( )
	UIControl.draw ( self )

	dxDrawText ( self.text, self.x, self.y, self.x + self.width, self.y + self.height, _textColor, self.textScale, self.font, self.alignment and "center" or "left" )
end

--[[
	UIImage
]]
UIImage = setmetatable ( { }, { __index = UIControl } )
UIImage.__index = UIImage

function UIImage.new ( x, y, width, height, filepath, relative, parent )
	local img = {
		type = "img",
		filepath = filepath,
		font = xrInterface.font
	}
	
	parent = parent or g_Canvas
	parent:insertChild ( img )

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( parent.x + x, parent.y + y, width, height, "", relative, parent )
	setmetatable ( super, UIImage ) 
	
	img.super = super
	
	return setmetatable ( img,
		{ __index = super }
	)
end

function UIImage:setSection ( u, v, usize, vsize )
	if u then
		self.section = {
			u = u, v = v,
			usize = usize, vsize = vsize
		}
	else
		self.section = nil
	end
end

function UIImage:draw ( )
	UIControl.draw ( self )

	local section = self.section
	if section then
		dxDrawImageSection ( 
			self.x, self.y, self.width, self.height, 
			section.u, section.v, section.usize, section.vsize, 
			"textures/" .. self.filepath .. ".dds" 
		)
	else
		dxDrawImage ( 
			self.x, self.y, self.width, self.height, 
			"textures/" .. self.filepath .. ".dds" 
		)
	end
end

--[[
	UIList
]]
UIList = setmetatable ( { }, { __index = UIControl } )
UIList.__index = UIList

function UIList.new ( x, y, width, height, relative, parent )
	local list = {
		type = "list",
		items = { }
	}
	
	parent = parent or g_Canvas
	parent:insertChild ( list )

	-- Экземпляр родительского класса для наследования
	local super = UIControl.new ( parent.x + x, parent.y + y, width, height, "", relative, parent )
	setmetatable ( super, UIList ) 
	
	list.super = super
	
	return setmetatable ( list,
		{ __index = super }
	)
end

function UIList:draw ( )
	UIControl.draw ( self )

	local _y = self.y
	
	for i, item in ipairs ( self.items ) do
		item:draw ( self.x, _y, self.width )
		local height = 50
		if item.image then height = 80 end;
		-- TODO
		_y = _y + height
	end
end

function UIList:addItem ( text )
	local item = UIListItem.new ( text )
	table.insert ( self.items, item )
	return item
end

function UIList:cursor ( ax, ay )
	UIControl.cursor ( self, ax, ay )

	local row = math.floor ( ( ay - self.y ) / 50 ) + 1
	
	self.current = self.items [ row ]
end

function UIList:click ( button, state, ax, ay )
	self.item = self.current
	
	UIControl.click ( self, button, state, ax, ay )
end

--[[
	UIListItem
]]
UIListItem = { }
UIListItem.__index = UIListItem

function UIListItem.new ( text )
	local item = {
		text = text,
		font = xrInterface.font,
		textScale = 0.55
	}
	
	return setmetatable ( item, UIListItem )
end

function UIListItem:setImage ( filepath, u, v, usize, vsize )
	if filepath then
		self.image = {
			filepath = filepath,
			u = u, v = v,
			usize = usize,
			vsize = vsize
		}
	else
		self.image = nil
	end
end

function UIListItem:draw ( x, y, width )
	-- TODO
	dxDrawText ( self.text, x + 10, y, 0, y + 50, _textColor, self.textScale, self.font, "left", "center" )
end

addEventHandler ( "onClientCharacter", root,
	function ( char )
		if _focused then
			_focused:setText ( _focused.text .. char )
		end
	end
, false )

addEventHandler ( "onClientKey", root,
	function ( button, press )
		if press ~= true then return end;
		
		if button == "backspace" then
			if _focused then
				_focused:setText ( 
					utfSub ( _focused.text, 1, utfLen ( _focused.text ) - 1 )
				)
			end
		end
	end 
, false )