local _mathFloor = math.floor
local _mathSqrt = math.sqrt
local _mathMin = math.min
local _mathMax = math.max
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end
local _dist2d = getDistanceBetweenPoints2D
_withinRectangle = function ( px, py, rx, ry, rwidth, rheight )
	return ( px >= rx and px <= rx + rwidth ) and ( py >= ry and py <= ry + rheight )
end

function sphereCollisionTest ( lineStart, lineEnd, sphereCenter, sphereRadius )
	-- check if line intersects sphere around element
	local vec = Vector3(lineEnd.x - lineStart.x, lineEnd.y - lineStart.y, lineEnd.z - lineStart.z)

	local A = vec.x^2 + vec.y^2 + vec.z^2
	local B = ( (lineStart.x - sphereCenter.x) * vec.x + (lineStart.y - sphereCenter.y) * vec.y + (lineStart.z - sphereCenter.z) * vec.z ) * 2
	local C = ( (lineStart.x - sphereCenter.x)^2 + (lineStart.y - sphereCenter.y)^2 + (lineStart.z - sphereCenter.z)^2 ) - sphereRadius^2

	local delta = B^2 - 4*A*C

	if (delta >= 0) then
		delta = math.sqrt(delta)
		local t = (-B - delta) / (2*A)

		if (t > 0) then
			return Vector3(lineStart.x + vec.x * t, lineStart.y + vec.y * t, lineStart.z + vec.z * t)
		end
	end
end

function getWorldCursorPosition ( )
	if isCursorShowing ( ) then
		local screenx, screeny, worldx, worldy, worldz = getCursorPosition ( )
		local px, py, pz = getCameraMatrix ( )
		local hit, x, y, z, elementHit = processLineOfSight ( px, py, pz, worldx, worldy, worldz, false, false, false, true )
 
		if hit then
			return x, y, z, elementHit
		end
	end
end

local boxSides = {
	{ -1, 0 },
	{ 1, 0 },
	{ 0, -1 },
	{ 0, 1 }
}
local _drawSide = dxDrawMaterialLine3D
local _whiteColor = tocolor ( 255, 255, 255 )
function drawBox ( x, y, z, width, depth, height, texture )
	local halfWidth, halfDepth, halfHeight = width/2, depth/2, height/2
	x, y, z = x + halfWidth, y + halfDepth, z + halfHeight
	
	for i, side in ipairs ( boxSides ) do
		_drawSide ( 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z - halfHeight, 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z + halfHeight,
			texture, i > 2 and width or depth, _whiteColor, x, y, z
		)
	end
end

--[[
	Radio image
]]
addEvent ( "onClientGUIImageSwitch", false )

local _radioImgRefs = 0
local _radioImgSplit = { }
local _onRadioImageClick = function ( button )
	if button ~= "left" then
		return
	end
	
	local splitName = getElementData ( source, "split" )
	
	-- Сбрасываем выделение предыдущей кнопки
	local prevSplitBtn = _radioImgSplit [ splitName ]
	if isElement ( prevSplitBtn ) then
		local prevPath = getElementData ( prevSplitBtn, "path" )
		guiStaticImageLoadImage ( prevSplitBtn, prevPath .. "_n.png" )
	end
	
	-- Выделяем нашу новую кнопку
	local path = getElementData ( source, "path" )
	guiStaticImageLoadImage ( source, path .. "_d.png" )
	_radioImgSplit [ splitName ] = source
	
	triggerEvent ( "onClientGUIImageSwitch", source, splitName, prevSplitBtn )
end
local _onRadioImageEnter = function ( )
	if _radioImgSplit [ getElementData ( source, "split" ) ] ~= source then
		local path = getElementData ( source, "path" )
		guiStaticImageLoadImage ( source, path .. "_h.png" )
	end
end
local _onRadioImageLeave = function ( )
	if _radioImgSplit [ getElementData ( source, "split" ) ] ~= source then
		local path = getElementData ( source, "path" )
		guiStaticImageLoadImage ( source, path .. "_n.png" )
	end
end

function guiCreateRadioImage ( x, y, width, height, path, relative, parent )
	-- Делаем несколько проверок на наличие необходимых файлов
	if fileExists ( path .. "_d.png" ) ~= true or fileExists ( path .. "_h.png" ) ~= true or fileExists ( path .. "_n.png" ) ~= true then
		outputDebugString ( "Не было найдено изображений для " .. tostring ( path ), 2 )
		return
	end
	
	-- Проверяем наличие группы кнопок
	if type ( g_RadioImageSplit ) ~= "string" then
		outputDebugString ( "Не было найдено группы кнопок", 2 )
		return
	end

	local radioImg = guiCreateStaticImage ( x, y, width, height, path .. "_d.png", relative, parent )
	if radioImg then
		setElementData ( radioImg, "path", path )
		setElementData ( radioImg, "split", g_RadioImageSplit )
	
		addEventHandler ( "onClientGUIClick", radioImg, _onRadioImageClick, false )
		addEventHandler ( "onClientMouseEnter", radioImg, _onRadioImageEnter, false )
		addEventHandler ( "onClientMouseLeave", radioImg, _onRadioImageLeave, false )
	
		-- Сбрасываем выделение предыдущей кнопки
		local prevSplitBtn = _radioImgSplit [ g_RadioImageSplit ]
		if isElement ( prevSplitBtn ) then
			local prevPath = getElementData ( prevSplitBtn, "path" )
			guiStaticImageLoadImage ( prevSplitBtn, prevPath .. "_n.png" )
		end
		_radioImgSplit [ g_RadioImageSplit ] = radioImg
	
		return radioImg
	end
end
function guiRadioImageSetSplit ( name )
	g_RadioImageSplit = name
end
function guiRadioImageSetSelected ( image, silence )
	local splitName = getElementData ( image, "split" )
	
	-- Сбрасываем выделение предыдущей кнопки
	local prevSplitBtn = _radioImgSplit [ splitName ]
	if isElement ( prevSplitBtn ) then
		local prevPath = getElementData ( prevSplitBtn, "path" )
		guiStaticImageLoadImage ( prevSplitBtn, prevPath .. "_n.png" )
	end
	
	-- Выделяем нашу новую кнопку
	local path = getElementData ( image, "path" )
	guiStaticImageLoadImage ( image, path .. "_d.png" )
	_radioImgSplit [ splitName ] = image
	
	if silence ~= true then
		triggerEvent ( "onClientGUIImageSwitch", image, splitName, prevSplitBtn )
	end
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
			if type ( BuildOrder.callback ) == "function" then
				BuildOrder.callback ( BuildOrder.current )
			end
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
	if now - BuildOrder.lastTime < GEN_TIME then
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

--[[
	Heightfield
]]
Heightfield = { 
	resolution = 2048
}
local heightData = { }

function Heightfield.fill ( x, y, width, height, data )
	local resolutionX = WORLD_SIZE_X * MAP_SIZE

	for j = 0, height-1 do
		for i = 0, width-1 do
			local index = j * resolutionX + i
			local level = data [ index + 1 ]
			Heightfield.setLevel ( x + i, y + j, level )
		end
	end
end

function Heightfield.loadFromBinary ( file )
	local content = fileRead ( file, fileGetSize ( file ) )

	-- Читаем размер буфера
	local resolution = bytesToData ( "ui", string.sub ( content, 1, 4 ) )
	
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	local size = resolutionX * resolutionY
	for i = 1, size do
		-- Читаем высоту из буфера и заполняем таблицу
		local pos = 4 + (i-1)*2
		local level = bytesToData ( "s", string.sub ( content, pos, pos + 4 ) )
		heightData [ i ] = level / 128
	end
end

function Heightfield.saveToBinary ( file, callback, ... )
	local calls = 0
	
	-- Записываем в буфер размер
	dataToBytes ( file, "ui", Heightfield.resolution )
	
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	local size = resolutionX * resolutionY
	for i = 1, size do
		-- Сохраняем в буфер высоту из таблицы
		local level = heightData [ i ]
		dataToBytes ( file, "s", 128 * level )
		
		if i == size and type ( callback ) == "function" then
			callback ( ... )
		end
		
		calls = calls + 1
		if calls > 100000 then
			calls = 0
			
			outputDebugString ( math.floor ( ( i / size ) * 100 ) .. "%" )
			
			setTimer ( function ( ) coroutine.resume ( g_SaveCr ) end, 50, 1 )
			coroutine.yield ( )
		end
	end
end

function Heightfield.fillFromPlain ( plain )
	local res = dxGetPixelsSize ( plain )

	local size = res^2
	for i = 1, size do
		local x = math.floor ( (i-1) % res )
		local y = math.floor ( (i-1) /  res )
		
		local level = dxGetPixelColor ( plain, x, y )
		heightData [ i ] = level
	end
end

function Heightfield.smooth ( cb )
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local resolutionY = WORLD_SIZE_Y * MAP_SIZE
	
	local totalSize = size^2
	local count = 0
	local check = 0
	
	local function getRawHeight ( x, y )
		x = math.max ( math.min ( x, resolutionX-1 ), 0 )
		y = math.max ( math.min ( y, resolutionY-1 ), 0 )
		
		local height = Heightfield.getLevel ( x, y )
		return height
	end
	for y = 0, resolutionY - 1 do
		for x = 0, resolutionX - 1 do
			local smoothedHeight = (
				getRawHeight(x-1, y-1) + getRawHeight(x,y-1) * 2 + getRawHeight(x+1,y-1) +
				getRawHeight(x-1,y) * 2 + getRawHeight(x,y) * 4 + getRawHeight(x+1,y) * 2 +
				getRawHeight(x-1,y+1) + getRawHeight(x,y+1) * 2 + getRawHeight(x+1,y+1)
			) / 16

			Heightfield.setLevel ( y, x, smoothedHeight )
			
			count = count + 1
			
			if count == totalSize and type ( cb ) == "function" then
				cb ( )
			end
			
			
			check = check + 1
			if check > 10000 then
				check = 0
				
				outputChatBox ( math.floor ( ( count / totalSize ) * 100 ) .. "%" )
				
				setTimer ( function ( ) coroutine.resume ( g_SmoothCr ) end, 50, 1 )
				coroutine.yield ( )
			end
		end
	end
end

function Heightfield.getLevel ( x, y )
	local index = _mathMin ( y, MAP_RES_Y - 1 ) * MAP_RES_X + _mathMin ( x, MAP_RES_X - 1 )
	local level = heightData [ index + 1 ]
	
	if level == nil then
		outputDebugString ( "Не найдено позиции " .. x ..", " .. y .. ". Возможно карта еще не принята.", 2 )
		return
	end
	
	return level
end

function Heightfield.setLevel ( x, y, level )
	local resolutionX = WORLD_SIZE_X * MAP_SIZE
	local index = y * resolutionX + x
	
	heightData [ index + 1 ] = level
end

function Heightfield.getHeight ( px, py )
	local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
	local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
	local deltaX = ( px - xrStreamerWorld.worldX ) / worldSizeX
	local deltaY = ( xrStreamerWorld.worldY - py ) / worldSizeY
	local mapSizeX = MAP_SIZE*WORLD_SIZE_X
	local mapSizeY = MAP_SIZE*WORLD_SIZE_Y
	local pixelX, pixelY = deltaX * mapSizeX, deltaY * mapSizeY
	local fracX, fracY = pixelX - math.floor ( pixelX ), pixelY - math.floor ( pixelY )
	local h1, h2, h3
	
	if fracX + fracY >= 1 then
		h1 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) + 1 )
		h2 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) + 1 )
		h3 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) )
		
		fracX = 1 - fracX
		fracY = 1 - fracY
	else
		h1 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) )
		h2 = Heightfield.getLevel ( math.floor ( pixelX ) + 1, math.floor ( pixelY ) )
		h3 = Heightfield.getLevel ( math.floor ( pixelX ), math.floor ( pixelY ) + 1 )
	end
	
	local height = h1 * ( 1 - fracX - fracY ) + h2 * fracX + h3 * fracY
	
	return height
end

function Heightfield.set ( tbl )
	heightData = tbl
end

LIP = {};

function LIP.load(fileName)
	local file = fileOpen ( fileName, true )
	if not file then
		outputDebugString ( "Error loading file : " .. fileName, 2 )
		return
	end
	
	local fileContent = fileRead ( file, fileGetSize ( file ) )
	local fileLines = split ( fileContent, "\n" )
	local data = {};
	local section;
	for _, line in ipairs ( fileLines ) do
		local tempSection = string.match(line, '^%[([%w%p]+)%][%s]*')
		if tempSection ~= nil then
			section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
			data[section] = data[section] or {}
		else
			local param, value = string.match(line, '^%s-([%w|_:]+)%s-=%s-([^%s].+)[%s-]')
			if param ~= nil and value ~= nil then
				if(tonumber(value))then
					value = tonumber(value);
				elseif(value == 'true')then
					value = true;
				elseif(value == 'false')then
					value = false;
				elseif gettok ( value, 2, 44 ) ~= false then
					local values = split ( value, 44 )
					value = { }
					for i, vl in ipairs ( values ) do
						value [ i ] = tonumber ( vl )
					end
				end
			
				if(tonumber(param))then
					param = tonumber(param);
				end
				data[section][param] = value;
			end
		end
	end
	fileClose ( file )
	return data;
end

function LIP.save(fileName, data)
	local file = fileCreate ( fileName )
	local contents = '';
	for section, param in pairs(data) do
		contents = contents .. ('[%s]\n'):format(section);
		for key, value in pairs(param) do
			contents = contents .. ('%s=%s\n'):format(key, tostring(value));
		end
		contents = contents .. '\n';
	end
	fileWrite ( file, contents )
	fileClose ( file )
end