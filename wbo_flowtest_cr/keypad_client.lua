w, h = guiGetScreenSize ( )

AdvancedKeypad = { }

function AdvancedKeypad.create ( callbackFn )
	if AdvancedKeypad.visible then
		return
	end
	
	AdvancedKeypad.fn = callbackFn
	
	AdvancedKeypad.gui = { }
	
	AdvancedKeypad.gui.window = guiCreateWindow ( w/2-71, h/2-138, 142, 276, "Введите код", false )
	guiWindowSetSizable ( AdvancedKeypad.gui.window, false )
	
	AdvancedKeypad.gui.edit = guiCreateEdit ( 13, 25, 117, 33, "", false, AdvancedKeypad.gui.window )
	guiEditSetMaxLength ( AdvancedKeypad.gui.edit, 10 )
	guiEditSetReadOnly ( AdvancedKeypad.gui.edit, true )
	
	guiCreateButton ( 13, 68, 37, 36, "1", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 53, 68, 37, 36, "2", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 93, 68, 37, 36, "3", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 13, 108, 37, 36, "4", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 53, 108, 37, 36, "5", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 93, 108, 37, 36, "6", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 13, 148, 37, 36, "7", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 53, 148, 37, 36, "8", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 93, 148, 37, 36, "9", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 53, 188, 37, 36, "0", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 13, 188, 37, 36, "*", false, AdvancedKeypad.gui.window )
	guiCreateButton ( 93, 188, 37, 36, "#", false, AdvancedKeypad.gui.window )
	
	AdvancedKeypad.gui.btnAbort = guiCreateButton ( 13, 228, 56.5, 36, "Отмена", false, AdvancedKeypad.gui.window )
	AdvancedKeypad.gui.btnOk = guiCreateButton ( 73.5, 228, 56.5, 36, "OK", false, AdvancedKeypad.gui.window )
	
	addEventHandler ( "onClientGUIClick", AdvancedKeypad.gui.window, AdvancedKeypad.onClick )
	
	showCursor ( true )
	
	AdvancedKeypad.visible = true
end

function AdvancedKeypad.destroy ( )
	if AdvancedKeypad.visible then
		destroyElement ( AdvancedKeypad.gui.window )
		showCursor ( false )
		AdvancedKeypad.visible = nil
	end
end

function AdvancedKeypad.onClick ( )
	if source == AdvancedKeypad.gui.btnOk then
		local displayString = guiGetText ( AdvancedKeypad.gui.edit )
		
		if type ( AdvancedKeypad.fn ) == "function" then
			AdvancedKeypad.fn ( displayString )
		end
		
		AdvancedKeypad.destroy ( )
	elseif source == AdvancedKeypad.gui.btnAbort then
		AdvancedKeypad.destroy ( )
	else
		local text = guiGetText ( source )
		local isNumber = tonumber ( text )
		
		if isNumber or text == "*" or text == "#" then
			guiSetText ( AdvancedKeypad.gui.edit, guiGetText ( AdvancedKeypad.gui.edit ) .. text )
		end
	end
end