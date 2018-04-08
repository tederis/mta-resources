local sw, sh = guiGetScreenSize ( )
local halfsw, halfsh = sw / 2, sh / 2 

ModSelect = { 
	fwidth = 500,
	fheight = 500,
	fbias = 10,
	fmodnum = 8,
	fpanelheight = 30
}

local modTransferStatus = {
	
}

function ModSelect.open ( fn )
	local this = ModSelect
	if this.visible == nil then
		this.fx = halfsw - this.fwidth / 2
		this.fy = halfsh - this.fheight / 2
		this.fdoublebias = this.fbias * 2
		this.fmodheight = ( this.fheight - this.fpanelheight - this.fbias * ( this.fmodnum + 1 ) ) / this.fmodnum
		this.fn = fn
	
		addEventHandler ( "onClientRender", root, ModSelect.onRender, false )
		addEventHandler ( "onClientCursorMove", root, ModSelect.onCursorMove, false )
		addEventHandler ( "onClientClick", root, ModSelect.onClick, false )
	
		showCursor ( true )
	
		this.visible = true
	end
end

function ModSelect.close ( )
	local this = ModSelect
	if this.visible then
		removeEventHandler ( "onClientRender", root, ModSelect.onRender )
		removeEventHandler ( "onClientCursorMove", root, ModSelect.onCursorMove )
		removeEventHandler ( "onClientClick", root, ModSelect.onClick )
	
		showCursor ( false )
	
		this.visible = nil
	end
end

function ModSelect.onRender ( )
	local this = ModSelect
	dxDrawRectangle ( this.fx, this.fy, this.fwidth, this.fheight, tocolor ( 50, 53, 60 ) )
	
	local x = this.fx + this.fbias
	local y = this.fy + this.fbias
	
	for i, mod in ipairs ( g_LoadedMods ) do
		local _y = y + ( ( this.fmodheight + this.fbias ) * ( i - 1 ) )
		local color = tocolor ( 70, 90, 70 )
		if mod.disabled then
			color = i == this.fselectedItem and tocolor ( 100, 100, 100 ) or tocolor ( 70, 70, 70 )
		elseif i == this.fselectedItem then
			color = tocolor ( 100, 120, 100 )
		end
		
		dxDrawRectangle ( x, _y, this.fwidth - this.fdoublebias, this.fmodheight, color )
		
		local transferStatus = modTransferStatus [ mod.id ]
		if transferStatus then
			local progress = transferStatus / 100
			local progressWidth = ( this.fwidth - this.fdoublebias ) * progress
			color = i == this.fselectedItem and tocolor ( 80, 80, 180 ) or tocolor ( 50, 50, 150 )
			dxDrawRectangle ( x, _y, progressWidth, this.fmodheight, color )
		end
		
		local _x = x + 10
		_y = _y + 10
		dxDrawImage ( _x, _y, this.fmodheight - this.fdoublebias, this.fmodheight - this.fdoublebias, "Widget_icon.png" )
		
		_x = _x + this.fmodheight - this.fdoublebias + this.fbias
		dxDrawText ( mod.name, _x, _y )
		dxDrawText ( math.floor ( mod.size / 1048576 ) .. "MB", _x + 200, _y )
		local textVBias = dxGetFontHeight ( --[[ TODO ]] )
		_y = _y + textVBias
		dxDrawText ( mod.status, _x, _y )
		dxDrawText ( ( tonumber ( transferStatus ) or 0 ) .. "%", _x + 200, _y )
		--[[_y = _y + textVBias
		if mod.progress < 100 then
			dxDrawText ( mod.progress .. "%", _x, _y )
		else
			dxDrawText ( "Загружено", _x, _y )
		end]]
	end
	
	y = y + this.fheight - this.fpanelheight - this.fbias
	local btnheight = this.fpanelheight - this.fbias
	
	local _x = x
	local color = this.fbtnSelAll and tocolor ( 100, 100, 100 ) or tocolor ( 70, 70, 70 )
	dxDrawRectangle ( _x, y, 100, btnheight, color )
	dxDrawText ( "Select all", _x, y, _x + 100, y + btnheight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
	_x = _x + 100 + this.fbias
	color = this.fbtnHideAll and tocolor ( 100, 100, 100 ) or tocolor ( 70, 70, 70 )
	dxDrawRectangle ( _x, y, 100, btnheight, color )
	dxDrawText ( "Deselect all", _x, y, _x + 100, y + btnheight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
	_x = _x + 100 + this.fbias
	dxDrawText ( "Press [F6] to close", _x, y, _x + 100, y + btnheight, tocolor ( 255, 255, 255 ), 1, "default", "left", "center" )
	_x = x + this.fwidth - 100 - this.fdoublebias
	color = this.fbtnApply and tocolor ( 100, 100, 100 ) or tocolor ( 70, 70, 70 )
	dxDrawRectangle ( _x, y, 100, btnheight, color )
	dxDrawText ( "Apply", _x, y, _x + 100, y + btnheight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
end

function ModSelect.onCursorMove ( _, _, absoluteX, absoluteY )
	local this = ModSelect
	if not isPointInRectangle ( absoluteX, absoluteY, this.fx, this.fy, this.fwidth, this.fheight ) then return end;
	
	local realHeight = this.fheight - this.fpanelheight
	local itemIndex = math.floor ( ( absoluteY - this.fy ) / ( realHeight / this.fmodnum ) )
	this.fselectedItem = itemIndex + 1
	
	local x = this.fx + this.fbias
	local y = this.fy + this.fbias
	
	y = y + this.fheight - this.fpanelheight - this.fbias
	local btnheight = this.fpanelheight - this.fbias
	
	local _x = x
	this.fbtnSelAll = isPointInRectangle ( absoluteX, absoluteY, _x, y, 100, btnheight )
	_x = _x + 100 + this.fbias
	this.fbtnHideAll = isPointInRectangle ( absoluteX, absoluteY, _x, y, 100, btnheight )
	_x = x + this.fwidth - 100 - this.fdoublebias
	this.fbtnApply = isPointInRectangle ( absoluteX, absoluteY, _x, y, 100, btnheight )
end

function ModSelect.onClick ( button, state, absoluteX, absoluteY )
	if state ~= "down" then return end;
	local this = ModSelect
	
	local selectedItem = g_LoadedMods [ this.fselectedItem ]
	if selectedItem then
		selectedItem.disabled = not selectedItem.disabled == true
	end
	
	-- Выбрать все
	if this.fbtnSelAll then
		for i = 1, #g_LoadedMods do
			g_LoadedMods [ i ].disabled = nil
		end
		
	-- Снять выбор
	elseif this.fbtnHideAll then
		for i = 1, #g_LoadedMods do
			g_LoadedMods [ i ].disabled = true
		end
		
	-- Применить
	elseif this.fbtnApply then
		if this.fn then
			this.fn ( )
		end
		this.fn = nil
	
		--ModSelect.close ( )
	end
end

bindKey ( "f6", "down",
	function ( )
		if ModSelect.visible then
			ModSelect.close ( )
		else
			ModSelect.open ( )
		end
	end
)

addEvent ( "onModTransferStatus", true )
addEventHandler ( "onModTransferStatus", resourceRoot,
	function ( modId, progress )
		modTransferStatus [ modId ] = progress
	end
, false )

function math.round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end

function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
end

function isPointInRectangle ( x, y, rx, ry, rwidth, rheight )
	return ( x > rx and x < rx + rwidth ) and ( y > ry and y < ry + rheight )
end