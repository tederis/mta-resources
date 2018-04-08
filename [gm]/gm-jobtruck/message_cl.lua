local sw, sh = guiGetScreenSize ( )

local textBox, textLine

addEventHandler ( "onClientRender", root,
	function ( )
		local now = getTickCount ( )
	
		if textLine then
			dxDrawText ( textLine.text,
				0, sh * 0.785, 
				sw, dxGetFontHeight ( 1.8, "sans" ), 
				tocolor ( 255, 255, 255, 255 ), 1.8, "sans", "center", "top", false, false, false, true
			)
			
			if now - textLine.time > 5000 then
				textLine = nil
			end
		end
		
		if textBox then
			local chatX, chatY = 0.0125 * sw, 0.015 * sh
			local chatboxLayout = getChatboxLayout ( )
			local chatHeight, chatWidth = getChatFontHeight ( ) * ( chatboxLayout.chat_lines + 0.5 ), 320 * chatboxLayout.chat_width
		
			local linesNum = 2
			local height = dxGetFontHeight ( 1.5, "sans" ) * linesNum + 20
		
			dxDrawRectangle ( chatX, chatY*2 + chatHeight, chatWidth, height, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( textBox.text, 
				chatX + 10, chatY*2 + chatHeight + 10, 
				chatX + chatWidth - 20, chatY*2 + chatHeight + height - 10, 
				tocolor ( 255, 255, 255, 255 ), 1.5, "sans", "left", "top", false, true 
			)
			
			if now - textBox.time > 5000 then
				textBox = nil
			end
		end
	end
)

function showTextBox ( text, timer )
	text = tostring ( text )

	textBox = {
		text = text,
		time = getTickCount ( )
	}
end

function showTextLine ( text )
	text = tostring ( text )

	textLine = {
		text = text,
		time = getTickCount ( )
	}
end

--Helper functions
local chatboxFonts = {
	"default", "clear", "default-bold", "arial"
}

function getChatFontHeight ( )
	local chatboxLayout = getChatboxLayout ( )
	if chatboxLayout.chat_use_cegui then
		--TODO
	end
	
	return dxGetFontHeight ( chatboxLayout.chat_scale [ 2 ], chatboxFonts [ chatboxLayout.chat_font ] )
end