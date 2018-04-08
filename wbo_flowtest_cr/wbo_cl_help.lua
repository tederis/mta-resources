local helpForm
local helpSetting = {
	x = 0.5 * sw,
	y = 0.7 * sh,
	height = 128 + 32,
	width = 512,
	headerHeight = 26,
	color = tocolor ( 0, 0, 0, 150 )
}

local _drawRectangle = dxDrawRectangle
local _drawText = dxDrawText

local function helpFormRender ( )
	local now = getTickCount ( )
	local elapsedTime = now - helpForm.startTime
	local duration = helpForm.endTime - helpForm.startTime
	local progress = elapsedTime / duration
 
	local eX
	if not helpForm.popdown then
		eX = interpolateBetween ( 0, 0, 0, helpSetting.width / 2, 0, 0, progress, "Linear" )
	else
		eX = interpolateBetween ( helpSetting.width / 2, 0, 0, 0, 0, 0, progress, "Linear" )
	end
	
	_drawRectangle ( helpSetting.x - eX, helpSetting.y, eX * 2, helpSetting.height, helpSetting.color, true )
	_drawRectangle ( helpSetting.x - eX, helpSetting.y, eX * 2, helpSetting.headerHeight, helpSetting.color, true )
	 
	if progress > 1 then
		if not helpForm.popdown  then
			_drawText ( helpForm.title, 
				helpSetting.x - eX, helpSetting.y, 
				helpSetting.x + eX, helpSetting.y + helpSetting.headerHeight,
				color.white, 1.3, "clear", "center", "center", false, true, true
			)
			
			_drawText ( helpForm.text, 
				helpSetting.x - eX, helpSetting.y + helpSetting.headerHeight, 
				helpSetting.x + eX, helpSetting.y - helpSetting.headerHeight + helpSetting.height, 
				color.white, 1.3, "clear", "left", "top", false, true, true
			)

			if elapsedTime > 8000 then
				helpForm.startTime = getTickCount ( )
				helpForm.endTime = helpForm.startTime + 650
				helpForm.popdown = true
			end
		else
			removeEventHandler ( "onClientRender", root, helpFormRender )
			helpForm = nil
		end
	end
end

function createHelpForm ( title, text )
	if helpForm == nil then
		addEventHandler ( "onClientRender", root, helpFormRender, false, "low" )
	end

	helpForm = { 
		title = title,
		text = text,
		popdown = false,
		startTime = getTickCount ( )
	}
	helpForm.endTime = helpForm.startTime + 650
end