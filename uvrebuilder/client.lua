local g_Islands
local g_IslandsMd5
local g_MatIsland

local SIZE = 512

local selectedMaterial

local sw, sh = guiGetScreenSize ( )
local viewerSize = math.min ( sw, sh ) - 50
local viewerX = sw / 2 - viewerSize / 2
local viewerY = sh / 2 - viewerSize / 2

Island = {
	make = function ( index, x, y, width, height, material )
		local island = {
			index = index,
			x = x, y = y,
			w = width, h = height,
			mat = material
		}
		return island
	end
}

--[[
	BinMap
]]
local _binMapBlocks
local _binMapBlocksWidth
local _binMapBlocksHeight
local function binMapNewBlock ( x, y, width, height )
	if _binMapBlocks then
		local block = {
			[ 1 ] = x,
			[ 2 ] = y,
			[ 3 ] = width, 
			[ 4 ] = height 
		}
	
		_binMapBlocks [ #_binMapBlocks + 1 ] = block
	
		return block
	else
		outputDebugString ( "Не была найдена таблица блоков", 2 )
	end
end
local function binMapIsIntersect ( x, y, width, height )
	if _binMapBlocks ~= nil then
		local blocksNum = #_binMapBlocks
		for i = 1, blocksNum do
			local block = _binMapBlocks [ i ]
			if ( x + width > block [ 1 ] and y + height > block [ 2 ] and x < block [ 1 ] + block [ 3 ] and y < block [ 2 ] + block [ 4 ] ) or x < 0 or y < 0 or x + width > _binMapBlocksWidth or y + height > _binMapBlocksHeight then
				return true
			end
		end
	else
		outputDebugString ( "Не была найдена таблица блоков", 2 )
	end
end
local _surroundingMap = {
	{ -1, -1 }, { 0, -1 }, { 1, -1 },
	{ -1, 0 },             { 1, 0 },
	{ -1, 1 },  { 0, 1 },  { 1, 1 }
}
local function binMapFindBlock ( width, height )
	if _binMapBlocks ~= nil then
		local blocksNum = #_binMapBlocks
		for i = 1, blocksNum do
			local block = _binMapBlocks [ i ]
			for _, data in ipairs ( _surroundingMap ) do
				local x = block [ 1 ] + block [ 3 ]*data [ 1 ]
				local y = block [ 2 ] + block [ 4 ]*data [ 2 ]
				
				if binMapIsIntersect ( x, y, width, height ) ~= true then
					return x, y
				end
			end
		end
		
		if #_binMapBlocks == 0 then
			return 0, 0
		end
	else
		outputDebugString ( "Не была найдена таблица блоков", 2 )
	end
end
local function binMapInsert ( width, height )
	if _binMapBlocks ~= nil then
		local x, y = binMapFindBlock ( width, height )
		if x then
			binMapNewBlock ( x, y, width, height )
			
			return x, y
		else
			outputDebugString ( "Не могу найти подходящий блок " .. width .. ", " .. height )
		end
	else
		outputDebugString ( "Не была найдена таблица блоков", 2 )
	end
end
local function binMapInit ( width, height )
	_binMapBlocks = { }
	
	_binMapBlocksWidth = width
	_binMapBlocksHeight = height
end

--[[
	BuildOrder
]]
BuildOrder = {
	threads = { },
	index = 0,
	current = 1,
	progress = 0
}

function BuildOrder.create ( readyCB, finishCB )
	BuildOrder.readyCB = readyCB
	BuildOrder.finishCB = finishCB
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
			if type ( BuildOrder.readyCB ) == "function" then
				BuildOrder.readyCB ( BuildOrder.current )
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
	if now - BuildOrder.lastTime < 1 then
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
		
		if type ( BuildOrder.readyCB ) == "function" then
			BuildOrder.readyCB ( BuildOrder.current )
		end
		
		-- Перескакиваем на следующий
		BuildOrder.current = BuildOrder.current + 1
		
		local threadData = BuildOrder.threads [ BuildOrder.current ]
		if threadData then
			BuildOrder.cr = coroutine.create ( threadData.fn )
			coroutine.resume ( BuildOrder.cr, unpack ( threadData.args ) )
		else
			removeEventHandler ( "onClientRender", root, BuildOrder.update )
			
			if type ( BuildOrder.finishCB ) == "function" then
				BuildOrder.finishCB ( )
			end
			
			BuildOrder.cr = nil
		end
	end
end

function updateMd5 ( )
	if fileExists ( "islands.xml" )  then
		local file = fileOpen ( "islands.xml", true )
		local content = fileRead ( file, 
			fileGetSize ( file )
		)
		fileClose ( file )
		
		return md5 ( content )
	end
	
	return false
end

function parseIslands ( filepath )
	local xml = xmlLoadFile ( filepath )
	if xml then
		islands = { }

		for i, node in ipairs ( xmlNodeGetChildren ( xml ) ) do
			local index = xmlNodeGetAttribute ( node, "index" )
			local posX = xmlNodeGetAttribute ( node, "posX" )
			local posY = xmlNodeGetAttribute ( node, "posY" )
			local sizeX = xmlNodeGetAttribute ( node, "sizeX" )
			local sizeY = xmlNodeGetAttribute ( node, "sizeY" )
			local material = xmlNodeGetAttribute ( node, "mat" )
		
			local island = Island.make (
				tonumber ( index ),
				tonumber ( posX ), tonumber ( posY ), 
				tonumber ( sizeX ), tonumber ( sizeY ), 
				tonumber ( material ) 
			)
			islands [ i ] = island
		end
		
		xmlUnloadFile ( xml )
		
		return islands
	end
end

function loadIslands ( )
	g_Islands = parseIslands ( "islands.xml" )
	if g_Islands and #g_Islands > 0 then
		g_MatIsland = { }
	
		for _, island in ipairs ( g_Islands ) do
			local data = g_MatIsland [ island.mat ]
			if data then
				table.insert ( data.islands, island )
			else
				local lmapTex = dxCreateTexture ( "lmap#" .. island.mat .. "_1.dds", "dxt5", false )
				assert ( isElement ( lmapTex ), "LightMap не был найден" )
					
				local hemiTex = dxCreateTexture ( "lmap#" .. island.mat .. "_2.dds", "dxt5", false )
				assert ( isElement ( hemiTex ), "HemiMap не был найден" )
					
				g_MatIsland [ island.mat ] = {
					islands = { island },
					lmap = lmapTex,
					hemi = hemiTex
				}
			end
				
			selectedMaterial = island.mat
		end
			
		g_List = guiCreateGridList 
	else
		outputDebugString ( "Ошибка при чтении файла островов", 2 )
		return
	end
	
	-- Создаем GUI
	local wndWidth, wndHeight = 150, 400
	g_Wnd = guiCreateWindow ( viewerX + viewerSize + 10, sh / 2 - wndHeight / 2, wndWidth, wndHeight, "Light map builder", false )
	g_List = guiCreateGridList ( 10, 25, wndWidth - 20, wndHeight - 35, false, g_Wnd )
	local column = guiGridListAddColumn ( g_List, "Map", 0.8 )
	for material, data in pairs ( g_MatIsland ) do
		local row = guiGridListAddRow ( g_List )
		guiGridListSetItemText ( g_List, row, column, "lmap#" .. material, false, false )
		guiGridListSetItemData ( g_List, row, column, tostring ( material ) )
	end
	addEventHandler ( "onClientGUIClick", g_List, onListClick, false )
	
	showCursor ( true )
end

Rectangle = {
	make = function ( x, y, width, height )
		return setmetatable ( {
			x = x, y = y,
			w = width, h = height
		}, { __index = Rectangle } )
	end,
	fitsIn = function ( self, outer )
		return outer.w >= self.w and outer.h >= self.h
	end,
	compareWith = function ( self, other )
		return self.w == other.w and self.h == other.h
	end,
	tostr = function ( self )
		return "x=" .. self.x .. ", y=" .. self.y .. ", w=" .. self.w .. ", h=" .. self.h
	end
}

Node = {
	make = function ( )
		local node = {
			
		}
		return setmetatable ( node, { __index = Node } )
	end,
	insertRect = function ( self, rect )
		if self.left then
			return self.left:insertRect ( rect ) or self.right:insertRect ( rect )
		end
		
		if self.filled then
			return false
		end
		
		-- Если наш прямоугольник не вмещается в прямоугольник нода
		if not rect:fitsIn ( self.rect ) then
			--outputDebugString ( rect:tostr ( ) .. " to " .. self.rect:tostr ( ) )
			return false
		end
		
		if rect:compareWith ( self.rect ) then
			self.filled = true
			return self
		end
		
		self.left = Node.make ( )
		self.right = Node.make ( )
		
		local widthDiff = self.rect.w - rect.w
		local heightDiff = self.rect.h - rect.h
		
		local me = self.rect
		
		if widthDiff > heightDiff then
			self.left.rect = Rectangle.make ( me.x, me.y, rect.w, me.h )
			self.right.rect = Rectangle.make ( me.x + rect.w, me.y, me.w - rect.w, me.h )
		else
			self.left.rect = Rectangle.make ( me.x, me.y, me.w, rect.h )
			self.right.rect = Rectangle.make ( me.x, me.y + rect.h, me.w, me.h - rect.h )
		end
		
		return self.left:insertRect ( rect )
	end
}

function processIsland ( island, nodex, nodey, nodew, nodeh )
	local data = g_MatIsland [ island.mat ]
	if data then
		local matSize = dxGetMaterialSize ( data.lmap )
		local posX, posY = island.x - 1, island.y - 1
		local sizeX, sizeY = island.w + 2, island.h + 2
		
		if posX < 0 or posX + sizeX > matSize then
			posX = math.max ( posX, 0 )
			sizeX = sizeX - 1
			outputDebugString("exp 1")
		end
		if posY < 0 or posY + sizeY > matSize then
			posY = math.max ( posY, 0 )
			sizeY = sizeY - 1
			outputDebugString("exp 2")
		end
		
		local lmapPixels = dxGetTexturePixels ( 
				data.lmap, 
				posX, posY, 
				sizeX, sizeY
			)
		coroutine.yield ( 0 )
		local hemiPixels = dxGetTexturePixels ( 
				data.hemi, 
				posX, posY, 
				sizeX, sizeY
			)
		
		local totalOps = sizeY * sizeX
		local passedOps = 0
		local limitOps = 0
		
		for j = 0, sizeY - 1 do
			for i = 0, sizeX - 1 do
				local _, _, _, la = dxGetPixelColor ( lmapPixels, i, j )
				local hr, _, _, ha = dxGetPixelColor ( hemiPixels, i, j )
			
				dxSetPixelColor ( hemiPixels, i, j, hr, ha, la, 255 )
				
				passedOps = passedOps + 1
				limitOps = limitOps + 1
				if limitOps > 10000 then
					limitOps = 0
				
					coroutine.yield ( passedOps / totalOps )
				end
			end
		end
		
		dxSetTexturePixels ( resultTex, hemiPixels, nodex, nodey, nodew, nodeh )
	
		--table.insert ( g_Nodes, node )
	else
		outputDebugString ( "Не был найден материал", 2 )
	end
end

function onBuildFinish ( )
	local pixels = dxGetTexturePixels ( resultTex )
	local png = dxConvertPixels ( pixels, "jpeg", 100 )
	
	local file = fileCreate ( "result.jpeg" )
	fileWrite ( file, png )
	fileClose ( file )
	
	--destroyElement ( resultTex )
	
	outputChatBox ( "Карта света успешно построена", 0, 255, 0 )
end

function buildIslands ( )
	local _sortFn = function ( a, b )
		local aSqrt = a.w * a.h
		local bSqrt = b.w * b.h
	
		return ( a.h > b.h )
	end

	--g_Node = Node.make ( )
	--g_Node.rect = Rectangle.make ( 0, 0, SIZE, SIZE )
	
	binMapInit ( SIZE, SIZE )
	
	g_Nodes = { }
	
	resultTex = dxCreateTexture ( SIZE, SIZE )
	
	local _dxGetTexturePixels = dxGetTexturePixels
	local _dxSetTexturePixels = dxSetTexturePixels
	
	BuildOrder.create ( 
		function ( index )
			-- TODO
		end,
		onBuildFinish
	)
	
	local xml = xmlCreateFile ( "result.xml", "islands" )
	xmlNodeSetAttribute ( xml, "sizeX", tostring ( SIZE ) )
	xmlNodeSetAttribute ( xml, "sizeY", tostring ( SIZE ) )
	
	--table.sort ( g_Islands, _sortFn )
	
	local totalNum, okNum = 0, 0
	
	for _, island in ipairs ( g_Islands ) do
		local data = g_MatIsland [ island.mat ]
		local matSize = dxGetMaterialSize ( data.lmap )
		
		-- Выбираем размер острова с бортиками по бокам, если это возможно
		local sizeX, sizeY = island.w + 2, island.h + 2
		if island.x < 1 or island.x + 1 > matSize then
			sizeX = sizeX - 1
			outputDebugString("exp 1")
		end
		if island.y < 1 or island.y + 1 > matSize then
			sizeY = sizeY - 1
			outputDebugString("exp 2")
		end
	
		--local node = g_Node:insertRect ( Rectangle.make ( 0, 0, sizeX, sizeY ) )
		local x, y = binMapInsert ( sizeX, sizeY )
		if x then
			local xmlChild = xmlCreateChild ( xml, "island" )
			xmlNodeSetAttribute ( xmlChild, "index", tostring ( island.index ) )
			xmlNodeSetAttribute ( xmlChild, "posX", tostring ( x + 1 ) )
			xmlNodeSetAttribute ( xmlChild, "posY", tostring ( y + 1 ) )
		
			BuildOrder.wrap ( processIsland, island, x, y, sizeX, sizeY )
			
			okNum = okNum + 1
		else
			outputDebugString ( "Не могу вместить" )
		end
		
		totalNum = totalNum + 1
	end
	
	outputChatBox ( "Готово " .. okNum ..  " из " .. totalNum )
	
	xmlSaveFile ( xml )
	xmlUnloadFile ( xml )
end

function onListClick ( )
	local selectedRow = guiGridListGetSelectedItem ( source )
	if selectedRow > -1 then
		local material = tonumber (
			guiGridListGetItemData ( source, selectedRow, 1 )
		)
		if material then
			selectedMaterial = material
		end
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		outputDebugString("START")
	
		g_IslandsMd5 = updateMd5 ( )
		if g_IslandsMd5 == false then
			outputDebugString ( "Не могу обнаружить файл островов", 2 )
			return
		end
	
		loadIslands ( )
		
		buildIslands ( )
		
		--[[g_Node = Node.make ( )
		g_Node.rect = Rectangle.make ( 0, 0, 256, 256 )
	
		g_Nodes = { }]]
	end
, false )

--[[
addEventHandler ( "onClientClick", root,
	function ( key, state )
		if state ~= "up" then
			local node = g_Node:insertRect ( Rectangle.make ( 0, 0, math.random ( 10, 100 ), math.random ( 10, 100 ) ) )
			if node then
				table.insert ( g_Nodes, node )
				g_LastNode = node
			elseif node == nil then
				outputDebugString ("не вмещается", 2)
			end
		end
	end
, false )]]

addEventHandler ( "onClientRender", root,
	function ( )
	
		--[[if g_Islands == nil then
			return
		end
		
		local materialData = g_MatIsland [ selectedMaterial ]
		if materialData then
			dxDrawRectangle ( viewerX, viewerY, viewerSize, viewerSize, tocolor ( 0, 0, 0, 180 ) )
			dxDrawImage ( viewerX, viewerY, viewerSize, viewerSize, materialData.hemi )
			
			local materialSize = dxGetMaterialSize ( materialData.lmap )
			local sizeFactor = viewerSize / materialSize
			
			for _, island in ipairs ( materialData.islands ) do
				dxDrawRectangle ( 
					viewerX + math.floor ( island.posX * sizeFactor ),
					viewerY + math.floor ( island.posY * sizeFactor ),
					math.floor ( island.sizeX * sizeFactor ),
					math.floor ( island.sizeY * sizeFactor ),
					tocolor ( 255, 0, 0, 200 )
				)
			end
		end]]
		
		-- Рисуем полоску загрузки
		if BuildOrder.cr ~= nil then
			local barWidth, barHeight = 300, 20
			local barX, barY = sw / 2 - barWidth / 2, 80 + barHeight
			
			dxDrawRectangle ( barX, barY, barWidth, barHeight, tocolor ( 0, 0, 0, 130 ) )
			dxDrawRectangle ( barX, barY, barWidth * BuildOrder.progress, barHeight, tocolor ( 150, 150, 0, 255 ) )
			dxDrawText ( "building " .. math.floor ( 100 * BuildOrder.progress ) .. "% ...", barX, barY, barX + barWidth, barY + barHeight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
		end
		
		if isElement ( resultTex ) then
			dxDrawRectangle ( viewerX, viewerY, SIZE, SIZE, tocolor ( 10, 0, 0, 180 ) )
			dxDrawImage ( viewerX, viewerY, SIZE, SIZE, resultTex )
		end
		
		--[[dxDrawRectangle ( viewerX, viewerY, 256, 256, tocolor ( 10, 0, 0, 180 ) )
		for _, node in ipairs ( g_Nodes ) do
			dxDrawRectangle ( viewerX + node.rect.x, viewerY + node.rect.y, node.rect.w, node.rect.h, node == g_LastNode and tocolor ( 255, 255, 0, 50 ) or tocolor ( 255, 0, 0, 50 ) )
		end]]
	end
, false )