--[[
	Иерархия:
		-Объект или автомобиль
			-Blank 1
				-Tile 1
				-Tile 2
				-Tile 3
			-Blank 2
				-Tile 1
]]

--[[
	parent - родительский элемент бланка. должен быть объектов или автомобилем.
]]
function createBlank ( parent )
	local blank = createElement ( "blank" )
	
	setElementParent ( blank, parent )
	
	return blank
end

--[[
	type - тип плитки. должно быть строкой. when или do.
	name - имя плитки из таблицы.
	parent - родительский элемент. должен быть бланком.
]]
function createTile ( type, name, parent )
	local tile = createElement ( "tile-" .. type )
	
	setElementData ( tile, "name", name )
	setElementParent ( tile, parent )
	
	return tile
end

object = createObject ( 1234, -1636.29761, -1160.55432, 50.89762 )
local blank = createBlank ( object )
local tile = createTile ( "when", "button", blank )
local tile = createTile ( "do", "chat", blank )

components = { }
components.button = {
	name = "Кнопка",
	sub = {
		"e",
		"b"
	}
}

components.chat = {
	name = "Чат",
	sub = {
		"Первое сообщение",
		"Второе сообщение"
	}
	onTriggered = function ( )
		outputChatBox ( "Эта хуйня работает!" )
	end
}

bindKey ( "e", "down",
	function ( )
		for _, tile in ipairs ( getElementsByType ( "tile-when" ) ) do
			local name = getElementData ( tile, "name" )
			if name == "button" then
				local parent = getElementParent ( tile )
				for _, dotile in ipairs ( getElementsByType ( "tile-do", parent ) ) do
					local name = getElementData ( dotile, "name" )
					
					components [ name ].onTriggered ( )
				end
			end
		end
	end
)