------------------------------------
-- Events группа                  --
-- Компоненты обработки событий   --
------------------------------------

--[[
	Events:Contact
]]
NodeRef "Events:Contact" { 
	events = {
		target = "object",
		outputs = {
			{ "onHit", "any" },
			{ "onLeave", "any" },
			{ "Player", "element" }
		}
	}
}

local objectContacts = { }
addEventHandler ( "onPlayerContact", root,
	function ( prev, current )
		if objectContacts [ prev ] then
			EventManager.triggerEvent ( prev, "Events:Contact", 3, source )
			EventManager.triggerEvent ( prev, "Events:Contact", 2 )
			
			objectContacts [ prev ] = nil
			
			return
		end
		
		if current then
			EventManager.triggerEvent ( current, "Events:Contact", 3, source )
			EventManager.triggerEvent ( current, "Events:Contact", 1 )
			objectContacts [ current ] = true
		end
	end
)

--[[
	Events:Click
]]
NodeRef "Events:Click" { 
	events = {
		target = "object",
		outputs = {
			{ "onDown", "number" },
			{ "Player", "element" }
		}
	}
}

addEventHandler ( "onElementClicked", resourceRoot,
	function ( theButton, theState, thePlayer )
		EventManager.triggerEvent ( source, "Events:Click", 2, thePlayer )
		EventManager.triggerEvent ( source, "Events:Click", 1, theState == "down" and 1 or 0 )
	end
)