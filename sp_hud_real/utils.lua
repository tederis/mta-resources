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

function isPointInRectangle ( px, py, rx, ry, rw, rh )
	return ( px >= rx and px <= rx + rw ) and ( py >= ry and py <= ry + rh )
end

function getRealTextHeight ( text, scale, font, width )
	local words = split ( text, 32 ) -- space
	local lineWidth = 0
	local height = dxGetFontHeight ( scale, font )
	for _, word in ipairs ( words ) do
		local wordWidth = dxGetTextWidth ( word, scale, font )
		local spaceWidth = dxGetTextWidth ( " ", scale, font )
		lineWidth = lineWidth + wordWidth + spaceWidth
		if lineWidth > width then
			height = height + dxGetFontHeight ( scale, font )
			lineWidth = 0
		end
	end
	
	return height
end

_scale = function ( x, y )
	x = tonumber ( x ) or 0
	y = tonumber ( y ) or 0
	
	return x * g_FactorH, y * g_FactorV
end