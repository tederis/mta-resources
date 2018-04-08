local inlineForm = { }

function testCode ( )
	local fn, err  = loadstring ( guiGetText ( inlineForm.edit ) )
	
	if not fn then
		guiPushText ( inlineForm.debug , err )
	end
	
	fn = nil
end


function createInlineEditor ( )
	if inlineForm.wnd then
		outputDebugScript ( "Inline editor is already created", 2 )
	
		return
	end
	
	local width, height = 500, 450
	
	inlineForm.wnd = guiCreateWindow ( sw * .5 - (width * .5), sh * .5 - (height * .5), width, height, "Inline editor", false )
	inlineForm.edit = guiCreateMemo ( 0.02, 0.06, 0.96, 0.56, "", true, inlineForm.wnd )
	inlineForm.debug = guiCreateMemo ( 0.02, 0.64, 0.96, 0.25, "", true, inlineForm.wnd )
	guiMemoSetReadOnly ( inlineForm.debug, true )
	inlineForm.btnOk = guiCreateButton ( 0.73, 0.91, 0.25, 0.06, "OK", true, inlineForm.wnd )
	inlineForm.btnCancel = guiCreateButton ( 0.46, 0.91, 0.25, 0.06, "Cancel", true, inlineForm.wnd )
	addEventHandler ( "onClientGUIClick", inlineForm.btnOk, testCode )
	
	guiSetVisible ( inlineForm.wnd, false )
end

function setInlineEditorVisible ( visible )
	guiSetVisible ( inlineForm.wnd, visible )
end

---createInlineEditor ( )
--setInlineEditorVisible ( true )
showCursor(false)

local TESTCODE = [[
	function createInlineEditor ( )
	if inlineForm.wnd then
		outputDebugScript ( "Inline editor is already created", 2 )
	
		return
	end
	
	local width, height = 500, 450
	
	inlineForm.wnd = guiCreateWindow ( sw * .5 - (width * .5), sh * .5 - (height * .5), width, height, "Inline editor", false )
	inlineForm.edit = guiCreateMemo ( 0.02, 0.06, 0.96, 0.56, "", true, inlineForm.wnd )
	inlineForm.debug = guiCreateMemo ( 0.02, 0.64, 0.96, 0.25, "", true, inlineForm.wnd )
	guiMemoSetReadOnly ( inlineForm.debug, true )
	inlineForm.btn = guiCreateButton ( 0.73, 0.91, 0.25, 0.06, "OK", true, inlineForm.wnd )
	addEventHandler ( "onClientGUIClick", inlineForm.btn, testCode )
	
	guiSetVisible ( inlineForm.wnd, false )
end
]]
--guiSetText ( inlineForm.edit, TESTCODE )

--Helper functions
function guiPushText ( guiElement, text )
	return guiSetText ( guiElement, guiGetText ( guiElement ) .. text )
end