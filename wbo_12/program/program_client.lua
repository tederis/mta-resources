--[[
	Концепция работы логических схем:
		Схемы строятся из блоков-компонентов
		
		
	В WHEN части располагается условие выполнения блока. В DO части располагается последовательность действий выбранного объекта.
	
	Каждый блок-компонент может иметь вложения. Например {Видит{Объект}} или {Передвигаться{По треку}{Медленно}}.
	
	Чтобы добавить на объект логику, нужно выбрать утилиту Logic, применить на объекте и создать последовательность действий в окне построения логики.
]]

local sw, sh = guiGetScreenSize ( )
local scx, sxy = sw / 2, sh / 2

local programManager = {
	width = 800,
	height = 600,
	selectedBlank = 1,
	blankWidth = 800,
	blankHeight = 600 / 8
}
programManager.x = sw*0.5 - programManager.width*0.5
programManager.y = sh*0.5 - programManager.height*0.5

function programManager.clickTile ( button, tile )
	outputChatBox ( getElementData(tile, "name") )

	if button == "right" then
		--Уничтожаем плитку
		destroyElement ( tile )
		
		return
	end
end

function programManager.newTile ( blank, type )
	local tile = createTile ( type, "whenT", blank )
end

addEventHandler ( "onClientRender", root,
	function ( )
		local blankHeight = programManager.blankHeight + 10
		
		local blanks = getElementsByType ( "blank", object )
		for i, blank in ipairs ( blanks ) do
			local blankX, blankY = programManager.x, sxy + blankHeight*i - programManager.blankHeight*0.5
			blankY = blankY - blankHeight * programManager.selectedBlank
			
			dxDrawRectangle ( blankX, blankY, programManager.blankWidth, programManager.blankHeight, 
				i == programManager.selectedBlank and tocolor ( 0, 0, 0, 210 ) or tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( i, 
				blankX, blankY, 
				blankX + programManager.blankHeight, blankY + programManager.blankHeight,
				tocolor ( 255, 255, 255, 255 ),	2, "default",
				"center", "center"
			)
			
			--------------------------
			-- Tile WHEN
			--------------------------
			local tileX = blankX + programManager.blankHeight + 10
			
			dxDrawRectangle ( tileX - 10, blankY, 10, programManager.blankHeight, tocolor ( 0, 255, 0, 150 ) )
			
			local tiles = getElementsByType ( "tile-when", blank )
			for i = 1, #tiles + 1 do
				local name = "+\nНовая"
				if tiles [ i ] then
					name = components [ getElementData ( tiles [ i ], "name" ) ].name
				end
			
				local tileX = tileX + (programManager.blankHeight * (i-1))
			
				dxDrawRectangle ( tileX, blankY, programManager.blankHeight, programManager.blankHeight, tocolor ( 50, 50, 50, 150 ) )
				dxDrawLine ( tileX, blankY - 1, tileX, blankY + programManager.blankHeight - 1, tocolor ( 0, 0, 0, 255 ) )
				dxDrawText ( name, 
					tileX, blankY, 
					tileX + programManager.blankHeight, blankY + programManager.blankHeight,
					tocolor ( 255, 255, 255, 255 ),	1.5, "default",
					"center", "center"
				)
			end
			
			--------------------------
			-- Tile DO
			--------------------------
			tileX = tileX + programManager.blankHeight * #tiles + 10 + programManager.blankHeight
			
			dxDrawRectangle ( tileX - 10, blankY, 10, programManager.blankHeight, tocolor ( 255, 255, 0, 150 ) )
			
			tiles = getElementsByType ( "tile-do", blank )
			for i = 1, #tiles + 1 do
				local name = "+\nНовая"
				if tiles [ i ] then
					name = components [ getElementData ( tiles [ i ], "name" ) ].name
				end
			
				local tileX = tileX + (programManager.blankHeight * (i-1))
			
				dxDrawRectangle ( tileX, blankY, programManager.blankHeight, programManager.blankHeight, tocolor ( 50, 50, 50, 150 ) )
				dxDrawLine ( tileX, blankY - 1, tileX, blankY + programManager.blankHeight - 1, tocolor ( 0, 0, 0, 255 ) )
				dxDrawText ( name, 
					tileX, blankY, 
					tileX + programManager.blankHeight, blankY + programManager.blankHeight,
					tocolor ( 255, 255, 255, 255 ),	1.5, "default",
					"center", "center"
				)
			end
		end
	end
, false )

addEventHandler ( "onClientClick", root,
	function ( button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement )
		if state ~= "down" then
			return
		end
	
		local blankX, blankY = programManager.x, sxy - programManager.blankHeight*0.5
		
		if isPointInRectangle ( absoluteX, absoluteY, blankX, blankY, programManager.blankWidth, programManager.blankHeight ) ~= true then
			return
		end
		
		local blanks = getElementsByType ( "blank", object )
		
		--------------------------
		-- Tile WHEN
		--------------------------
		local tileX = blankX + 10

		local tileIndex = math.floor ( ( absoluteX - tileX ) / programManager.blankHeight )
		
		local tiles = getElementsByType ( "tile-when", blanks [ programManager.selectedBlank ] )
		
		if tiles [ tileIndex ] then
			programManager.clickTile ( button, tiles [ tileIndex ] )
			
			return
		elseif tileIndex == #tiles + 1 then
			programManager.newTile ( blanks [ programManager.selectedBlank ], "when" )
		
			return
		end
		
		--------------------------
		-- Tile DO
		--------------------------
		tileX = tileX + programManager.blankHeight * #tiles + 10 + programManager.blankHeight
		
		tileIndex = math.floor ( ( absoluteX - tileX ) / programManager.blankHeight )
		
		tiles = getElementsByType ( "tile-do", blanks [ programManager.selectedBlank ] )
		
		if tiles [ tileIndex ] then
			programManager.clickTile ( button, tiles [ tileIndex ] )
		
			return
		elseif tileIndex == #tiles + 1 then
			programManager.newTile ( blanks [ programManager.selectedBlank ], "do" )
		
			return
		end
	end
, false )

addEventHandler ( "onClientKey", root,
	function ( key, state )
		if key == "mouse_wheel_up" then
			programManager.selectedBlank = math.max ( programManager.selectedBlank-1, 1 )
		elseif key == "mouse_wheel_down" then
			programManager.selectedBlank = math.min ( programManager.selectedBlank+1, #getElementsByType ( "blank", object ) )
		end
	end 
)

function isPointInRectangle ( x, y, rx, ry, rwidth, rheight )
	return ( x > rx and x < rx + rwidth ) and ( y > ry and y < ry + rheight )
end

showCursor ( true )