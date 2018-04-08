local sw, sh = guiGetScreenSize ( )

local statusSettings = {
	textScale = 1.5,
	font = "sans",
	textColor = tocolor ( 255, 255, 255, 255 ),
	x = sw * 0.8,
	y = sh * 0.5
}
statusSettings.textHeight = dxGetFontHeight ( statusSettings.textScale, statusSettings.font )

local statusLines = { 

}

addEventHandler ( "onClientRender", root,
	function ( )
		for i, line in pairs ( statusLines ) do
			local offy = ( i - 1 ) * statusSettings.textHeight
		
			dxDrawText ( line,
				statusSettings.x, statusSettings.y + offy, 
				100, 100, 
				statusSettings.textColor, statusSettings.textScale, statusSettings.font, "left", "top", false, false, false, true
			)
		end
	end
)

function setStatusText ( text, line )
	line = tonumber ( line )
	if not line then
		return false
	end
	
	statusLines [ line ] = tostring ( text )
end