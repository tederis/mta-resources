addEvent ( "onClientLevelDrag", true )
addEvent ( "onClientLevelRotate", true )

local sw, sh = guiGetScreenSize ( )

SECTOR_SIZE = 150
WORLD_WIDTH = 9000
WORLD_HEIGHT = 9000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE --40 now
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE --40 now
MAP_STEP = 3
MAP_SIZE = SECTOR_SIZE / MAP_STEP --50 now

EDITOR_BUILDER = 1
EDITOR_DESIGN = 2

CHECK_FILES = true
INCLUDE_LMAPS = false

function xrScreenToMap( x, y )
	local factorX = ( math.max ( x, xrLevelAggregator.canvasX ) - xrLevelAggregator.canvasX ) / xrLevelAggregator.canvasWidth
	local factorY = ( math.max ( y, xrLevelAggregator.canvasY ) - xrLevelAggregator.canvasY ) / xrLevelAggregator.canvasHeight
	
	local mapSizeX = MAP_SIZE * WORLD_SIZE_X
	local mapSizeY = MAP_SIZE * WORLD_SIZE_Y
	return math.floor ( math.min ( factorX * mapSizeX, mapSizeX ) ), math.floor ( math.min ( factorY * mapSizeY, mapSizeY ) )
end

function xrMapToScreen ( x, y )
	local mapSizeX = MAP_SIZE * WORLD_SIZE_X
	local mapSizeY = MAP_SIZE * WORLD_SIZE_Y
	local factorX = x / mapSizeX
	local factorY = y / mapSizeY
	
	local screenX = xrLevelAggregator.canvasX + factorX*xrLevelAggregator.canvasWidth
	local screenY = xrLevelAggregator.canvasY + factorY*xrLevelAggregator.canvasHeight
	
	return math.floor ( screenX ), math.floor ( screenY )
end

_withinRectangle = function ( px, py, rx, ry, rwidth, rheight )
	return ( px >= rx and px <= rx + rwidth ) and ( py >= ry and py <= ry + rheight )
end

--[[
	xrLevelAggregator
]]
xrLevelAggregator = { 
	levels = nil,
	textures = { },
	selectedLevel = nil
}

function xrLevelAggregator.init ( )
	if type ( xrLevelAggregator.levels ) ~= "table" then
		outputDebugString ( "Не было найдено таблицы уровней", 2 )
		return
	end

	xrLevelAggregator.started = true
	
	local worldSizeFactor = WORLD_WIDTH / WORLD_HEIGHT
	
	xrLevelAggregator.canvasHeight = math.min ( sw, sh )
	xrLevelAggregator.canvasWidth = xrLevelAggregator.canvasHeight * worldSizeFactor
	xrLevelAggregator.canvasX = sw / 2 - xrLevelAggregator.canvasWidth / 2
	xrLevelAggregator.canvasY = 0
	
	local wndWidth, wndHeight = 150, 400
	xrLevelAggregator.wnd = guiCreateWindow ( sw - wndWidth - 30, sh / 2 - wndHeight / 2, wndWidth, wndHeight, "XRAY World", false )
	xrLevelAggregator.btn = guiCreateButton ( 10, 30, wndWidth - 20, 50, "Build", false, xrLevelAggregator.wnd )
	xrLevelAggregator.cb = guiCreateCheckBox ( 10, 90, wndWidth - 20, 20, "Build textures", true, false, xrLevelAggregator.wnd )
	xrLevelAggregator.buildTerrCb = guiCreateCheckBox ( 10, 120, wndWidth - 20, 20, "Build terrain", true, false, xrLevelAggregator.wnd )
	xrLevelAggregator.selOnlyCb = guiCreateCheckBox ( 10, 150, wndWidth - 20, 20, "Selected only", false, false, xrLevelAggregator.wnd )
	addEventHandler ( "onClientGUIClick", xrLevelAggregator.btn,
		function ( )
			if xrLevelAggregator.editorType ~= EDITOR_BUILDER then
				outputChatBox ( "В режиме дизайна вы не можете строить карту" )
				return
			end
		
			outputChatBox ( "Постройка мира начата" )
			
			if guiCheckBoxGetSelected ( xrLevelAggregator.cb ) then
				local selectedOnlyMode = guiCheckBoxGetSelected ( xrLevelAggregator.selOnlyCb )
				if selectedOnlyMode ~= true then
					xrLevelAggregator.fillMap ( )
				end
			
				xrLevelAggregator.processImages = { }
			
				for i, levelData in ipairs ( xrLevelAggregator.levels ) do
					if selectedOnlyMode ~= true or i == xrLevelAggregator.selectedLevel then
						table.insert ( xrLevelAggregator.processImages, levelData [ 2 ] )
						BuildOrder.wrap ( processSectorImage, levelData, "" )
						table.insert ( xrLevelAggregator.processImages, levelData [ 2 ] .. "_mask" )
						BuildOrder.wrap ( processSectorImage, levelData, "_mask" )
					end
				end
			end
			
			if guiCheckBoxGetSelected ( xrLevelAggregator.buildTerrCb ) then
				triggerServerEvent ( "onStartWorldBuiling", resourceRoot )
			end
		end
	, false )
	
	for i, levelData in ipairs ( xrLevelAggregator.levels ) do
		local texture = dxCreateTexture ( "maps/" .. levelData [ 2 ] .. "_mask.dds" )
		local shader = dxCreateShader ( "shader.fx" )
		dxSetShaderValue ( shader, "Tex0", texture )
		
		xrLevelAggregator.textures [ i ] = { shader = shader, texture = texture }
		
		xrLevelAggregator.selectedLevel = i
	end
	
	BuildOrder.create ( 
		function ( index )
			-- TODO
		end
	)
	
	addEventHandler ( "onClientRender", root, xrLevelAggregator.onRender, false )
	addEventHandler ( "onClientClick", root, xrLevelAggregator.onClick, false )
	addEventHandler ( "onClientDoubleClick", root, xrLevelAggregator.onDoubleClick, false )
	addEventHandler ( "onClientCursorMove", root, xrLevelAggregator.onCursorMove, false )
	
	addEventHandler ( "onClientKey", root, xrLevelAggregator.onKey, false )
	
	addEventHandler ( "onClientLevelDrag", resourceRoot, xrLevelAggregator.onLevelDrag, false )
	addEventHandler ( "onClientLevelRotate", resourceRoot, xrLevelAggregator.onLevelRotate, false )
	
	showCursor ( true )
end

function xrLevelAggregator.close ( )
	if xrLevelAggregator.started then
		destroyElement ( xrLevelAggregator.wnd )
		
		for _, material in ipairs ( xrLevelAggregator.textures ) do
			destroyElement ( material.shader )
			destroyElement ( material.texture )
		end
		
		removeEventHandler ( "onClientRender", root, xrLevelAggregator.onRender )
		removeEventHandler ( "onClientClick", root, xrLevelAggregator.onClick )
		removeEventHandler ( "onClientDoubleClick", root, xrLevelAggregator.onDoubleClick )
		removeEventHandler ( "onClientCursorMove", root, xrLevelAggregator.onCursorMove )
		
		removeEventHandler ( "onClientKey", root, xrLevelAggregator.onKey )
		
		removeEventHandler ( "onClientLevelDrag", resourceRoot, xrLevelAggregator.onLevelDrag )
		removeEventHandler ( "onClientLevelRotate", resourceRoot, xrLevelAggregator.onLevelRotate )
		
		if xrLevelAggregator.target ~= nil then
			destroyElement ( xrLevelAggregator.targetWnd )
		end
		xrLevelAggregator.target = nil
		
		showCursor ( false )
	end
	
	xrLevelAggregator.started = nil
end

function xrLevelAggregator.setTargetLevel ( level )
	if not level then
		if xrLevelAggregator.target ~= nil then
			destroyElement ( xrLevelAggregator.targetWnd )
		end
		xrLevelAggregator.target = nil
		
		return
	end

	if xrLevelAggregator.target then
		guiSetText ( xrLevelAggregator.targetWnd, tostring ( level [ 1 ] ) )
		guiSetText ( xrLevelAggregator.targetXEdt, tostring ( level [ 7 ] ) )
		guiSetText ( xrLevelAggregator.targetYEdt, tostring ( level [ 8 ] ) )
	else
		local wndWidth, wndHeight = 400, 500
		xrLevelAggregator.targetWnd = guiCreateWindow ( sw / 2 - wndWidth / 2, sh / 2 - wndHeight / 2, wndWidth, wndHeight, level [ 1 ], false )
		guiCreateLabel ( 10, 30, wndWidth - 20, 20, "X Bias", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.targetXEdt = guiCreateEdit ( 10, 60, wndWidth - 20, 30, tostring ( level [ 7 ] ), false, xrLevelAggregator.targetWnd )
		guiCreateLabel ( 10, 100, wndWidth - 20, 20, "Y Bias", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.targetYEdt = guiCreateEdit ( 10, 130, wndWidth - 20, 30, tostring ( level [ 8 ] ), false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.targetBtn = guiCreateButton ( 10, wndHeight - 60, wndWidth - 20, 50, "OK", false, xrLevelAggregator.targetWnd )
		
		local masks = exports [ "terrain_editor" ]:getChannelMasks ( )
		
		xrLevelAggregator.redChannelCB = guiCreateComboBox ( 10, 170, wndWidth - 20, 100, "R2-R", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.greenChannelCB = guiCreateComboBox ( 10, 200, wndWidth - 20, 100, "R2-G", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.blueChannelCB = guiCreateComboBox ( 10, 230, wndWidth - 20, 100, "R2-B", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.alphaChannelCB = guiCreateComboBox ( 10, 260, wndWidth - 20, 100, "R2-A", false, xrLevelAggregator.targetWnd )
		
		guiCreateLabel ( 10, 290, wndWidth - 20, 20, "Raise", false, xrLevelAggregator.targetWnd )
		xrLevelAggregator.targetRaise = guiCreateEdit ( 10, 320, wndWidth - 20, 30, tostring ( level [ 15 ] ), false, xrLevelAggregator.targetWnd )
		
		for _, maskData in ipairs ( masks ) do
			guiComboBoxAddItem ( xrLevelAggregator.redChannelCB, maskData [ 2 ] )
			guiComboBoxAddItem ( xrLevelAggregator.greenChannelCB, maskData [ 2 ] )
			guiComboBoxAddItem ( xrLevelAggregator.blueChannelCB, maskData [ 2 ] )
			guiComboBoxAddItem ( xrLevelAggregator.alphaChannelCB, maskData [ 2 ] )
		end
		
		guiComboBoxSetSelected ( xrLevelAggregator.redChannelCB, level [ 10 ] - 1 )
		guiComboBoxSetSelected ( xrLevelAggregator.greenChannelCB, level [ 11 ] - 1 )
		guiComboBoxSetSelected ( xrLevelAggregator.blueChannelCB, level [ 12 ] - 1 )
		guiComboBoxSetSelected ( xrLevelAggregator.alphaChannelCB, level [ 13 ] - 1 )
		
		addEventHandler ( "onClientGUIClick", xrLevelAggregator.targetBtn,
			function ( )
				local xBias = tonumber ( guiGetText ( xrLevelAggregator.targetXEdt ) )
				local yBias = tonumber ( guiGetText ( xrLevelAggregator.targetYEdt ) )
				local raise = tonumber ( guiGetText ( xrLevelAggregator.targetRaise ) )
				
				if xBias == nil or yBias == nil or raise == nil then
					outputChatBox ( "Один из параметров не является числом!" )
					return
				end
				
				level [ 7 ] = xBias
				level [ 8 ] = yBias
				
				level [ 10 ] = guiComboBoxGetSelected ( xrLevelAggregator.redChannelCB ) + 1
				level [ 11 ] = guiComboBoxGetSelected ( xrLevelAggregator.greenChannelCB ) + 1
				level [ 12 ] = guiComboBoxGetSelected ( xrLevelAggregator.blueChannelCB ) + 1
				level [ 13 ] = guiComboBoxGetSelected ( xrLevelAggregator.alphaChannelCB ) + 1
				
				level [ 15 ] = raise

				triggerServerEvent ( "onChangeLevelProp", resourceRoot,
					xrLevelAggregator.target [ 9 ],
					level [ 7 ],
					level [ 8 ],
					
					level [ 10 ],
					level [ 11 ],
					level [ 12 ],
					level [ 13 ],
					
					level [ 15 ]
				)
			
				xrLevelAggregator.setTargetLevel ( )
			end
		, false )
	end
	
	xrLevelAggregator.target = level
end

function xrLevelAggregator.onTargetChannelChange ( )
	local state = getElementData ( source, "state" )
	state = state + 1
	if state > 4 then
		state = 1
	end
	setElementData ( source, "state", state )
	guiSetText ( source, channelTypes [ state ] )
end

function xrLevelAggregator.onKey ( button, pressOrRelease )
	if getKeyState ( "lalt" ) and button == "x" and pressOrRelease then
		xrLevelAggregator.mapMode = not xrLevelAggregator.mapMode
	
		for i, levelData in ipairs ( xrLevelAggregator.levels ) do
			destroyElement ( xrLevelAggregator.textures [ i ].texture )
			
			local texture = dxCreateTexture ( "maps/" .. levelData [ 2 ] .. ( xrLevelAggregator.mapMode ~= true and "_mask.dds" or ".dds" ) )
			dxSetShaderValue (  xrLevelAggregator.textures [ i ].shader, "Tex0", texture )
			xrLevelAggregator.textures [ i ].texture = texture
		end
	end
end

function xrLevelAggregator.onRender ( )
	dxDrawRectangle ( xrLevelAggregator.canvasX, xrLevelAggregator.canvasY, xrLevelAggregator.canvasWidth, xrLevelAggregator.canvasHeight, tocolor ( 0, 0, 0, 150 ) )

	for i, levelData in ipairs ( xrLevelAggregator.levels ) do
		local sx, sy = xrMapToScreen ( levelData [ 5 ], levelData [ 6 ] )
		local sex, sey = xrMapToScreen ( levelData [ 5 ] + levelData [ 3 ], levelData [ 6 ] + levelData [ 4 ] )
		local elementWidth, elementHeight = sex - sx, sey - sy
		
		local levelSectorsWidth = math.ceil ( levelData [ 3 ] / MAP_SIZE )
		local levelSectorsHeight = math.ceil ( levelData [ 4 ] / MAP_SIZE )
		sex, sey = xrMapToScreen ( levelData [ 5 ] + levelSectorsWidth * MAP_SIZE, levelData [ 6 ] + levelSectorsHeight * MAP_SIZE )
		--[[local widthFactor = ( levelData [ 3 ] * MAP_STEP ) / ( levelSectorsWidth * SECTOR_SIZE )
		local heightFactor = ( levelData [ 4 ] * MAP_STEP ) / ( levelSectorsHeight * SECTOR_SIZE )]]
		
		dxDrawRectangle ( sx, sy, sex - sx, sey - sy, tocolor ( 100, 100, 100, 130 ) )
		
		dxDrawImage ( 
			sx, sy, elementWidth, elementHeight,
			xrLevelAggregator.textures [ i ].shader,
			levelData [ 14 ] * 90
		)
		dxDrawText ( levelData [ 1 ], sx, sy )
		dxDrawText ( levelData [ 3 ] .. ", " .. levelData [ 4 ], sx, sy + 15 )
		
		if i == xrLevelAggregator.selectedLevel then
			dxDrawLine ( sx, sy, sx + elementWidth, sy, tocolor ( 255, 255, 0 ), 4 )
			dxDrawLine ( sx, sy + elementHeight, sx + elementWidth, sy + elementHeight, tocolor ( 255, 255, 0 ), 4 )
			dxDrawLine ( sx, sy, sx, sy + elementHeight, tocolor ( 255, 255, 0 ), 4 )
			dxDrawLine ( sx + elementWidth, sy, sx + elementWidth, sy + elementHeight, tocolor ( 255, 255, 0 ), 4 )
		end
	end
	
	-- Рисуем полоску загрузки
	if BuildOrder.cr ~= nil then
		local barWidth, barHeight = 300, 20
		local barX, barY = sw / 2 - barWidth / 2, 80 + barHeight
			
		dxDrawRectangle ( barX, barY, barWidth, barHeight, tocolor ( 0, 0, 0, 130 ) )
		dxDrawRectangle ( barX, barY, barWidth * BuildOrder.progress, barHeight, tocolor ( 150, 150, 0, 255 ) )
		dxDrawText ( "building " .. math.floor ( 100 * BuildOrder.progress ) .. "% ...", barX, barY, barX + barWidth, barY + barHeight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
	end
end

function xrLevelAggregator.onClick ( button, state, cx, cy )
	local selectedLevel
	local selectedIndex
	
	for i, levelData in ipairs ( xrLevelAggregator.levels ) do
		local sx, sy = xrMapToScreen ( levelData [ 5 ], levelData [ 6 ] )
		local sex, sey = xrMapToScreen ( levelData [ 5 ] + levelData [ 3 ], levelData [ 6 ] + levelData [ 4 ] )
		local elementWidth, elementHeight = sex - sx, sey - sy
		if _withinRectangle ( cx, cy, sx, sy, elementWidth, elementHeight ) then
			selectedLevel = levelData
			selectedIndex = i
			break
		end
	end
	
	if button ~= "left" then
		if state == "down" and selectedLevel and xrLevelAggregator.target == nil then
			-- Вращаем уровень
			selectedLevel [ 14 ] = selectedLevel [ 14 ] + 1
			if selectedLevel [ 14 ] > 3 then selectedLevel [ 14 ] = 0 end;
			
			triggerServerEvent ( "onLevelRotate", resourceRoot, selectedIndex, selectedLevel [ 14 ] )
		end
		
		return
	end
	
	if state == "down" then
		if selectedLevel and xrLevelAggregator.target == nil then
			clickedLevel = {
				level = selectedLevel,
				index = selectedIndex
			}
			local ex, ey = xrMapToScreen ( selectedLevel [ 5 ], selectedLevel [ 6 ] )
			offsetPos = { cx - ex, cy - ey }
			
			xrLevelAggregator.selectedLevel = selectedIndex
		end
	else
		if clickedLevel then
			triggerServerEvent ( "onLevelDrag", resourceRoot, clickedLevel.index, clickedLevel.level [ 5 ], clickedLevel.level [ 6 ] )
		end
		clickedLevel = nil
	end
end

function xrLevelAggregator.onDoubleClick ( button, cx, cy )
	if button ~= "left" then
		return
	end
	
	local selectedLevel
	local selectedIndex
	
	for i, levelData in ipairs ( xrLevelAggregator.levels ) do
		local sx, sy = xrMapToScreen ( levelData [ 5 ], levelData [ 6 ] )
		local sex, sey = xrMapToScreen ( levelData [ 5 ] + levelData [ 3 ], levelData [ 6 ] + levelData [ 4 ] )
		local elementWidth, elementHeight = sex - sx, sey - sy
		if _withinRectangle ( cx, cy, sx, sy, elementWidth, elementHeight ) then
			selectedLevel = levelData
			selectedIndex = i
			break
		end
	end
	
	xrLevelAggregator.setTargetLevel ( selectedLevel )
end

function xrLevelAggregator.onCursorMove ( _, _, cx, cy )
	if clickedLevel then
		local mx, my = xrScreenToMap ( cx - offsetPos[ 1 ], cy - offsetPos[ 2 ] )
		
		local x = (math.floor(mx / 50) * 50)
		local y = (math.floor(my / 50) * 50)
		
		clickedLevel.level [ 5 ] = x
		clickedLevel.level [ 6 ] = y
	end
end

function xrLevelAggregator.buildResponseList ( fileNames )
	local response = { }
	
	for i, fileName in ipairs ( fileNames ) do
		local filePath = "maps/" .. fileName .. ".dds"
		if CHECK_FILES ~= true or fileExists ( filePath ) ~= true then
			table.insert ( response, i )
		end
	end
	
	return response
end

function xrLevelAggregator.onExternTransferRender ( )
	local width, height = 300, 100
	local x = sw / 2 - width / 2
	local y = sh / 2 - height / 2
	
	dxDrawRectangle ( x, y, width, height, tocolor ( 100, 100, 100, 200 ) )
	dxDrawRectangle ( x, y, width * (xrLevelAggregator.transferPercent/100), height, tocolor ( 100, 255, 100, 200 ) )
	dxDrawText ( "Идет передача " .. math.floor ( xrLevelAggregator.transferPercent ) .. "% ...", x, y, x + width, y + height, tocolor ( 255, 255, 255 ), 2, "default", "center", "center" )
end

function xrLevelAggregator.fillMap ( )
	-- Создаем текстуру-заглушку
	if fileExists ( "placeholder.png" ) ~= true then
		local placeholderTexture = dxCreateTexture ( "placeholder.dds" )
		local pixels = dxGetTexturePixels ( placeholderTexture, 0, 0, 256, 256 )
		destroyElement ( placeholderTexture )
		local pngPixels = dxConvertPixels ( pixels, "png" )
		local file = fileCreate ( "placeholder.png" )
		fileWrite ( file, pngPixels )
		fileClose ( file )
	end
	
	-- Создаем маску-заглушку
	if fileExists ( "placeholder_mask.png" ) ~= true then
		local placeholderTexture = dxCreateTexture ( 256, 256 )
		local pixels = dxGetTexturePixels ( placeholderTexture )
		for j = 0, 255 do
			for i = 0, 255 do
				dxSetPixelColor ( pixels, i, j, 255, 0, 0, 0 )
			end
		end
		destroyElement ( placeholderTexture )
		local pngPixels = dxConvertPixels ( pixels, "png" )
		local file = fileCreate ( "placeholder_mask.png" )
		fileWrite ( file, pngPixels )
		fileClose ( file )
	end
	
	local totalSectors = WORLD_SIZE_X * WORLD_SIZE_Y
	for i = 1, totalSectors do
		fileCopy ( "placeholder.png", ":terrain_editor/sectors/sector" .. i .. ".png", true )
		fileCopy ( "placeholder_mask.png", ":terrain_editor/sectors/sector" .. i .. "_mask.png", true )
	end
	
	outputDebugString ( "Скопировано " .. totalSectors .. " базовых текстур" )
end

function xrLevelAggregator.onLevelDrag ( index, x, y )
	local level = xrLevelAggregator.levels [ index ]
	if level then
		level [ 5 ] = x
		level [ 6 ] = y
		
		outputDebugString ( "Уровень " .. index .. " перемещен на клиенте" )
	else
		outputDebugString ( "Уровня с индексом " .. index .. " не существует" )
	end
end

function xrLevelAggregator.onLevelRotate ( index, rot )
	local level = xrLevelAggregator.levels [ index ]
	if level then
		level [ 14 ] = tonumber ( rot ) or 0
	
		outputDebugString ( "Уровень " .. index .. " повернут на клиенте" )
	else
		outputDebugString ( "Уровня с индексом " .. index .. " не существует" )
	end
end

addEvent ( "onClientXrEditor", true )
addEventHandler ( "onClientXrEditor", resourceRoot,
	function ( editorType, levels, fileNames )
		if xrLevelAggregator.started then
			xrLevelAggregator.close ( )
			return
		end
			
		xrLevelAggregator.levels = levels
		xrLevelAggregator.fileNames = fileNames
			
		xrLevelAggregator.editorType = editorType
		
		local responseList = xrLevelAggregator.buildResponseList ( fileNames )
		if #responseList > 0 then
			xrLevelAggregator.receiveList = responseList
			xrLevelAggregator.filesObtainedNum = 0
			
			xrLevelAggregator.transferPercent = 0
			addEventHandler ( "onClientRender", root, xrLevelAggregator.onExternTransferRender, false )
				
			triggerServerEvent ( "onXrFilesResponse", resourceRoot, responseList )
			return
		end
		
		xrLevelAggregator.init ( )
	end
, false )

addEvent ( "onClientSenderFile", true )
addEventHandler ( "onClientSenderFile", resourceRoot,
	function ( fileIndex, fileContent )
		if xrLevelAggregator.started then
			outputDebugString ( "Редактор уже запущен" )
			return
		end
		
		local fileNameIndex = xrLevelAggregator.receiveList [ fileIndex ]
		if not fileNameIndex then
			outputDebugString ( "Не было найдено индекса файла", 2 )
			return
		end
		
		local fileName = xrLevelAggregator.fileNames [ fileNameIndex ]
		if fileName then
			local file = fileCreate ( "maps/" .. fileName .. ".dds" )
			fileWrite ( file, fileContent )
			fileClose ( file )
			
			outputDebugString ( "Файл " .. fileName .. " был принят и создан" )
			
			xrLevelAggregator.filesObtainedNum = xrLevelAggregator.filesObtainedNum + 1
			if xrLevelAggregator.filesObtainedNum >= #xrLevelAggregator.receiveList then
				xrLevelAggregator.receiveList = nil
				xrLevelAggregator.filesObtainedNum = nil
				
				removeEventHandler ( "onClientRender", root, xrLevelAggregator.onExternTransferRender )
				xrLevelAggregator.transferPercent = nil
				
				xrLevelAggregator.init ( )
			end
		else
			outputDebugString ( "Файл с индексом " .. fileIndex .. " не был найден", 2 )
		end
	end
, false )

addEvent ( "onClientFileStatus", true )
addEventHandler ( "onClientFileStatus", resourceRoot,
	function ( percent )
		xrLevelAggregator.transferPercent = percent
	end
, false )

--[[
	R -> G
	B -> A
]]

--[[
	xrMapBuildOrder
]]
local channelIndices = {
	"r", "g", "b", "a"
}

local channelMul2 = {
	r = { 1 },
	g = { 2 },
	b = { 3 },
	a = { 4 },
	rg = { 1, 2 },
	gb = { 2, 3 },
	rb = { 1, 3 },
	ba = { 3, 4 }
}

function processSectorImage ( element, prefix )
	if fileExists ( "maps/" .. element [ 2 ] .. prefix .. ".dds" ) then
		local sectorX = element [ 5 ] / MAP_SIZE
		local sectorY = element [ 6 ] / MAP_SIZE
				
		local column = math.floor ( sectorX )
		local row = math.floor ( sectorY )
		local _index = row * WORLD_SIZE_X + column + 1
				
		local levelSectorsWidth = math.ceil ( element [ 3 ] / MAP_SIZE )
		local levelSectorsHeight = math.ceil ( element [ 4 ] / MAP_SIZE )
		
		local totalWidth = levelSectorsWidth * 256
		local totalHeight = levelSectorsHeight * 256
		
		-- Подготовим fake-текстуру
		local fakeTex = dxCreateTexture ( totalWidth, totalHeight )
		local phPixels
		if prefix == "" and fileExists ( "placeholder.png" ) then
			local phTex = dxCreateTexture ( "placeholder.png" )
			phPixels = dxGetTexturePixels ( phTex )
			destroyElement ( phTex )
		elseif prefix == "_mask" and fileExists ( "placeholder_mask.png" ) then
			local phTex = dxCreateTexture ( "placeholder_mask.png" )
			phPixels = dxGetTexturePixels ( phTex )
			destroyElement ( phTex )
		end
		if phPixels then
			for j = 0, levelSectorsHeight-1 do
				for i = 0, levelSectorsWidth-1 do
					dxSetTexturePixels ( fakeTex, phPixels, i * 256, j * 256, 256, 256 )
				end
			end
		end
		
		
		local testTexture = dxCreateTexture ( "maps/" .. element [ 2 ] .. prefix .. ".dds" )
		local texWidth, texHeight = dxGetMaterialSize ( testTexture )
		local pixels = dxGetTexturePixels ( testTexture, 
			math.max ( -element [ 7 ], 0 ),
			math.max ( -element [ 8 ], 0 ),
			math.min ( texWidth, texWidth + element [ 7 ] ),
			math.min ( texHeight, texHeight + element [ 8 ] )
		)
		destroyElement ( testTexture )
		dxSetTexturePixels ( fakeTex, pixels, 
			math.max ( element [ 7 ], 0 ), math.max ( element [ 8 ], 0 ), 
			math.min ( totalWidth - element [ 7 ], texWidth ),
			math.min ( totalHeight - element [ 8 ], texHeight )
		)
		
		local masks = exports [ "terrain_editor" ]:getChannelMasks ( )
		
		local START_CHANNEL_INDEX = 10
		
		local affectedChannelNum = 0
		if prefix == "_mask" then
			for g = 1, 4 do
				local texIndex = element [ START_CHANNEL_INDEX + (g-1) ]
				if texIndex ~= g then
					affectedChannelNum = affectedChannelNum + 1
				end
			end
		end
		
		local totalOps = ( levelSectorsHeight * levelSectorsWidth ) * ( affectedChannelNum * ( 256^2 ) )
		local passedOps = 0
		local limitOps = 0
		
		for i = 0, levelSectorsHeight-1 do
			for j = 0, levelSectorsWidth-1 do
				local pixels = dxGetTexturePixels ( fakeTex, j * 256, i * 256, 256, 256 )
				if pixels then
					if prefix == "_mask" then
						local copyOfPixels = dxConvertPixels ( pixels, "plain" )
				
						for g = 1, 4 do
							local texIndex = element [ START_CHANNEL_INDEX + (g-1) ]
							if texIndex ~= g then
								local channelMark = masks [ texIndex ] [ 1 ]
								--outputChatBox ( "ЗАМЕНА " .. masks [ g ] [ 1 ] .. " НА " .. channelMark )
							
								for ip = 0, 255 do
									for jp = 0, 255 do
										local pr, pg, pb, pa = dxGetPixelColor ( copyOfPixels, jp, ip )
										local value
										if g == 1 then
											value = pr
										elseif g == 2 then
											value = pg
										elseif g == 3 then
											value = pb
										elseif g == 4 then
											value = pa
										end
									
										if value > 100 then
											local pixelArgs = { pr, pg, pb, pa }
											for _, argIndex in ipairs ( channelMul2 [ channelMark ] ) do
												pixelArgs [ argIndex ] = value
											end
									
											dxSetPixelColor ( pixels, jp, ip, unpack ( pixelArgs ) )
										end
										
										passedOps = passedOps + 1
										limitOps = limitOps + 1
										if limitOps > 100000 then
											limitOps = 0
				
											coroutine.yield ( passedOps / totalOps )
										end
									end
								end
							end
						end
					end
				
					local pngPixels = dxConvertPixels ( pixels, "png" )
					local file = fileCreate ( ":terrain_editor/sectors/sector" .. (_index + j + (i*WORLD_SIZE_X)) .. prefix .. ".png" )
					fileWrite ( file, pngPixels )
					fileClose ( file )
				else
					outputDebugString ( "Ошибка при создании карты (" .. j .. ", " .. i .. ")", 2 )
				end
			end
		end
		
		destroyElement ( fakeTex )
	else
		outputDebugString ( "Текстуры " .. element [ 2 ] .. " не существует", 2 )
	end
end

xrMapBuildOrder = {
	elements = { },
	lastTime = getTickCount ( ),
	addElement = function ( levelData, prefix )
		local elementDesc = {
			levelData,
			prefix
		}
		table.insert ( xrMapBuildOrder.elements, elementDesc )
		
		if #xrMapBuildOrder.elements == 1 then
			addEventHandler ( "onClientRender", root, xrMapBuildOrder.onUpdate, false )
		end
	end,
	onUpdate = function ( )
		local now = getTickCount ( )
		if now - xrMapBuildOrder.lastTime > 1025 then
			xrMapBuildOrder.lastTime = now
			
			local elementDesc = xrMapBuildOrder.elements [ 1 ]
			if elementDesc then
				processSectorImage ( elementDesc [ 1 ], elementDesc [ 2 ] )
				table.remove ( xrMapBuildOrder.elements, 1 )
				
				outputDebugString ( elementDesc [ 1 ] [ 2 ] .. elementDesc [ 2 ] .. ".dds построена" )
			else
				removeEventHandler ( "onClientRender", root, xrMapBuildOrder.onUpdate )
				outputDebugString ( "Все текстуры построены" )
				outputChatBox ( "Мир успешно построен" )
			end
		end
	end
}

--[[
	BuildOrder
]]
BuildOrder = {
	threads = { },
	index = 0,
	current = 1,
	progress = 0
}

function BuildOrder.create ( callback )
	BuildOrder.callback = callback
end

function BuildOrder.wrap ( fn, ... )
	BuildOrder.index = BuildOrder.index + 1

	-- Если рабочий поток у нас свободен, используем его для обработки
	if BuildOrder.cr == nil then
		BuildOrder.cr = coroutine.create ( fn )
		local ok, progress = coroutine.resume ( BuildOrder.cr, ... )
		if coroutine.status ( BuildOrder.cr ) ~= "dead" then
			BuildOrder.lastTime = getTickCount ( )
			BuildOrder.threads [ BuildOrder.index ] = true
			addEventHandler ( "onClientRender", root, BuildOrder.update, false )
		else
			BuildOrder.cr = nil
			if type ( BuildOrder.callback ) == "function" then
				BuildOrder.callback ( BuildOrder.current )
			end
			
			-- Перескакиваем на следующий
			BuildOrder.current = BuildOrder.current + 1
		end
	else
		local threadData = {
			fn = fn,
			args = { ... }
		}
		BuildOrder.threads [ BuildOrder.index ] = threadData
	end
	
	return BuildOrder.index
end

function BuildOrder.update ( )
	local now = getTickCount ( )
	if now - BuildOrder.lastTime < 5 then
		return
	end
	BuildOrder.lastTime = now
	
	if coroutine.status ( BuildOrder.cr ) ~= "dead" then
		local ok, progress = coroutine.resume ( BuildOrder.cr )
		if coroutine.status ( BuildOrder.cr ) ~= "dead" then
			BuildOrder.progress = progress
		end
	else
		-- Удаляем текущий поток
		BuildOrder.threads [ BuildOrder.current ] = nil
		
		if type ( BuildOrder.callback ) == "function" then
			BuildOrder.callback ( BuildOrder.current )
		end
		
		-- Перескакиваем на следующий
		BuildOrder.current = BuildOrder.current + 1
		
		local threadData = BuildOrder.threads [ BuildOrder.current ]
		if threadData then
			BuildOrder.cr = coroutine.create ( threadData.fn )
			coroutine.resume ( BuildOrder.cr, unpack ( threadData.args ) )
		else
			removeEventHandler ( "onClientRender", root, BuildOrder.update )
			BuildOrder.cr = nil
		end
	end
end