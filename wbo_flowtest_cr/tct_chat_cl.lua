local sw, sh = guiGetScreenSize ( )

GameChat = {
	posx = 0.0125, posy = 0.015,
	width = 320,
	textColor = tocolor ( 235, 221, 178, 255 ),
	text = ""
}
GameChat.backgroundX = sw * GameChat.posx
GameChat.backgroundY = sh * GameChat.posy
local chatFonts = {
	[ 0 ] = "default",
	[ 1 ] = "clear",
	[ 2 ] = "default-bold",
	[ 3 ] = "arial"
}

function GameChat.getFontHeight ( scale )
	return dxGetFontHeight ( scale, chatFonts [ getChatboxLayout ( ).chat_font ] )
end

function GameChat.update ( )
	local chatLayout = getChatboxLayout ( )
	
	GameChat.scaleX, GameChat.scaleY = chatLayout.chat_scale[1], chatLayout.chat_scale[2]
	GameChat.backgroundWidth = ( GameChat.width * chatLayout.chat_width ) * GameChat.scaleX
	GameChat.backgroundHeight = GameChat.getFontHeight ( GameChat.scaleY ) * ( chatLayout.chat_lines + 0.5 )
	GameChat.backgroundHeight = math.floor ( GameChat.backgroundHeight )
	
	GameChat.inputX = GameChat.backgroundX
	GameChat.inputY = GameChat.backgroundY + GameChat.backgroundHeight
	
	GameChat.fontName = chatFonts [ chatLayout.chat_font ]
	GameChat.inputTextColor = tocolor ( 255, 255, 255, 255 ) --tocolor ( unpack ( chatLayout.chat_text_color ) )
	GameChat.fontScale = 1
end

function GameChat.onRender ( )
	local this = GameChat
	
	local lineDifference = GameChat.getFontHeight ( this.scaleY )
	local posx = this.inputX + ( 5 * this.scaleX )
	local posy = this.inputY + ( lineDifference * 0.125 )
	
	
	--dxDrawRectangle ( this.inputX, this.inputY, this.backgroundWidth, this.backgroundHeight, tocolor ( 255, 0, 0, 200 ) )
	dxDrawText ( "Roomsay: " .. this.text, posx, posy, this.inputX + this.backgroundWidth, this.inputY + this.backgroundHeight, this.inputTextColor, this.fontScale, this.fontName )
end

function GameChat.onKey ( button, pressOrRelease )
	if pressOrRelease == true then
		return
	end
	
	if GameChat.inputState ~= true then
		if button == "u" and guiGetInputMode ( ) == "allow_binds" and isMTAWindowActive ( ) ~= true then
			GameChat.update ( )
			GameChat.inputState = true
		
			addEventHandler ( "onClientRender", root, GameChat.onRender, false )
			addEventHandler ( "onClientCharacter", root, GameChat.onCharacter, false )
			guiSetInputEnabled ( true )
			
			GameChat.text = ""
		end
	else
		if button == "tab" then
			GameChat.inputState = nil
		
			removeEventHandler ( "onClientRender", root, GameChat.onRender )
			removeEventHandler ( "onClientCharacter", root, GameChat.onCharacter )
			guiSetInputEnabled ( false )
		elseif button == "backspace" then
			local textLen = utfLen ( GameChat.text )
			if textLen > 0 then
				GameChat.text = utfSub ( GameChat.text, 1, textLen - 1 )
			end
		elseif button == "enter" then
			triggerServerEvent ( "onRoomChat", root, GameChat.text )
			
			GameChat.inputState = nil
		
			removeEventHandler ( "onClientRender", root, GameChat.onRender )
			removeEventHandler ( "onClientCharacter", root, GameChat.onCharacter )
			guiSetInputEnabled ( false )
		end
	end
end
addEventHandler ( "onClientKey", root, GameChat.onKey, false )

function GameChat.onCharacter ( character )
	if utfLen ( GameChat.text ) < 96 then
		GameChat.text = GameChat.text .. character
	end
end