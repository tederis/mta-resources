local sw, sh = guiGetScreenSize ( )

local _mathFloor = math.floor
local _mathSqrt = math.sqrt
local _mathMin = math.min
local _mathMax = math.max
local _mathClamp = function ( min, value, max )
	return _mathMax ( _mathMin ( value, max ), min )
end
local _mathLerp = function(v0, v1, t)
	return (1-t)*v0 + t*v1
end

local _dist2d = getDistanceBetweenPoints2D


local function getRawHeight ( x, y )
	local resX = Heightfield.resolutionX
	local resY = Heightfield.resolutionY
	x = _mathClamp ( 0, x, resX - 1 )
	y = _mathClamp ( 0, y, resY - 1 )
		
	local height = Heightfield.getLevel ( x, y )
	return height
end
local function getWorldHeight ( height )
	return PATCH_Z + height * Heightfield.vertScale
end
local function brushCircleFunc ( x, y, strength, size, mode )
	local updateSectors = { }

	local radius = size - 1
	local _rad = radius * radius
	for _x = -radius, radius do
		local mapx = x + _x
		local height = _mathFloor ( _mathSqrt ( _rad - _x * _x ) )

		for _y = -height, height do
			local mapy = y + _y
					
			if mode == BrushModes.SMOOTH then
				-- Проверим загружен ли сектор
				local sectorLT = xrStreamerWorld.findSector ( mapx - 1, mapy - 1, true )
				local sectorRB = xrStreamerWorld.findSector ( mapx + 1, mapy + 1, true )
				if xrStreamerWorld.activated [ sectorLT ] ~= nil and xrStreamerWorld.activated [ sectorRB ] ~= nil then
					for i = 1, SMOOTH_ITERS do
						local smoothedHeight = (
							getRawHeight(mapx-1, mapy-1) + getRawHeight(mapx,mapy-1) * 2 + getRawHeight(mapx+1,mapy-1) +
							getRawHeight(mapx-1,mapy) * 2 + getRawHeight(mapx,mapy) * 4 + getRawHeight(mapx+1,mapy) * 2 +
							getRawHeight(mapx-1,mapy+1) + getRawHeight(mapx,mapy+1) * 2 + getRawHeight(mapx+1,mapy+1)
						) / 16
						
						xrStreamerWorld.setMapPixel ( mapx, mapy, smoothedHeight, updateSectors )
					end
				else
					outputDebugString ( "TerrainDebug: Сработала защита I от изменения незагруженной области" )
				end
			else
				if xrStreamerWorld.activated [ xrStreamerWorld.findSector ( mapx, mapy, true ) ] ~= nil then
					local level = getRawHeight ( mapx, mapy )
					if mode == BrushModes.FLATTEN then
						xrStreamerWorld.setMapPixel ( mapx, mapy, strength, updateSectors )
					else
						if mode == BrushModes.RAISE then
							xrStreamerWorld.setMapPixel ( mapx, mapy, level + strength, updateSectors )
						elseif mode == BrushModes.LOWER then
							xrStreamerWorld.setMapPixel ( mapx, mapy, level - strength, updateSectors )
						end
					end
				else
					outputDebugString ( "TerrainDebug: Сработала защита II от изменения незагруженной области" )
				end
			end
		end
	end
			
	-- Перезагружаем все задействованные сектора
	for sector, _ in pairs ( updateSectors ) do
		sector:reload ( )
	end
end
local function brushBoxFunc ( x, y, width, height, strength, mode )
	local updateSectors = { }
	
	for _x = 0, width do
		local mapx = x + _x
		for _y = 0, height do
			local mapy = y + _y
			
			if mode == BrushModes.SMOOTH then
				local smoothedHeight = (
					getRawHeight(mapx-1, mapy-1) + getRawHeight(mapx,mapy-1) * 2 + getRawHeight(mapx+1,mapy-1) +
					getRawHeight(mapx-1,mapy) * 2 + getRawHeight(mapx,mapy) * 4 + getRawHeight(mapx+1,mapy) * 2 +
					getRawHeight(mapx-1,mapy+1) + getRawHeight(mapx,mapy+1) * 2 + getRawHeight(mapx+1,mapy+1)
				) / 16
						
				xrStreamerWorld.setMapPixel ( mapx, mapy, smoothedHeight, updateSectors )
			else
				local level = getRawHeight ( mapx, mapy )
				if mode == BrushModes.FLATTEN then
					xrStreamerWorld.setMapPixel ( mapx, mapy, strength, updateSectors )
				else
					if mode == BrushModes.RAISE then
						xrStreamerWorld.setMapPixel ( mapx, mapy, level + strength, updateSectors )
					elseif mode == BrushModes.LOWER then
						xrStreamerWorld.setMapPixel ( mapx, mapy, level - strength, updateSectors )
					end
				end
			end
		end
	end
	
	-- Перезагружаем все задействованные сектора
	for sector, _ in pairs ( updateSectors ) do
		sector:reload ( )
	end
end

BrushModes = {
	RAISE = 1,
	LOWER = 2,
	SMOOTH = 3,
	FLATTEN = 4,
}

BrushShape = {
	BOX = 1,
	CIRCLE = 2
}

--[[
	xrEngine
]]
xrEngine = { 
	brushSize = 1,
	brushMaxSize = 8,
	brushStrength = 1,
	brushMaxStrength = 10,
	
	snapStep = 2,
	gridSize = 10,
	maxSnapStep = 16,
	
	pointDefault = tocolor ( 0, 255, 0 ),
	pointCurrent = tocolor ( 255, 255, 0 ),
	pointSelected = tocolor ( 255, 0, 0 )
}

-- Список масок для каналов и их комбинаций
xrShaderMaskChannel = {
	{ channel = "r", file = "textures/rock3.jpg", value = "Tex1" },
	{ channel = "g", file = "textures/riverdalegrassdead.jpg", value = "Tex2" },
	{ channel = "b", file = "textures/redsand1a.jpg", value = "Tex3" },
	{ channel = "a", file = "textures/riverdalegrass.jpg", value = "Tex4" },
	--[[{ channel = "gb", file = "textures/detail_grnd_leaves.dds", value = "Tex6" },
	{ channel = "rb", file = "textures/detail_grnd_cracked.dds", value = "Tex7" },
	{ channel = "ba", file = "textures/detail_grnd_plates.dds", value = "Tex8" },]]
}

function xrEngine.init ( )
	if SECTOR_SIZE % 2 ~= 0 then
		outputDebugString ( "SECTOR_SIZE должено содержать четное число!", 2 )
		return
	end
	
	xrEngine.brushMode = BrushModes.RAISE
	xrEngine.brushShape = BrushShape.CIRCLE
	
	xrEngine.snapGrid = { } -- Сетка контрольных точек
	xrEngine.selectedPoints = { }
	
	xrEngine.squareTex = dxCreateShader ( "shaders/rect.fx" )
	
	-- Создаем текстуры
	--xrEngine.attrs = dxCreateTexture ( "textures/attributes.png" )
	xrEngine.baseTex = dxCreateTexture ( "worlds/heightmap.dds" )
	xrEngine.lmapTex = dxCreateTexture ( "worlds/heightmap_lmap.dds" )
	xrEngine.normalTex = dxCreateTexture ( "worlds/heightmap_normal.dds" )
	xrEngine.maskTex = dxCreateTexture ( "worlds/heightmap_mask.png" )
	
	xrEngine.shader = dxCreateShader ( "shader.fx" )
	dxSetShaderValue ( xrEngine.shader, "TexBase", xrEngine.baseTex )
	dxSetShaderValue ( xrEngine.shader, "TexLMap", xrEngine.lmapTex )
	dxSetShaderValue ( xrEngine.shader, "TexNormal", xrEngine.normalTex )
	dxSetShaderValue ( xrEngine.shader, "TexDet", xrEngine.maskTex )
	
	-- Создаем текстуры для блендинга ландшафта
	xrEngine.maskTextures = { }
	for _, channelData in ipairs ( xrShaderMaskChannel ) do
		xrEngine.maskTextures [ channelData.value ] = dxCreateTexture ( channelData.file )
		dxSetShaderValue ( xrEngine.shader, channelData.value, xrEngine.maskTextures [ channelData.value ] )
	end
	
	engineApplyShaderToWorldTexture ( xrEngine.shader, "_Texture_" )
		
	-- Грузим архивы текстур
	xrEngine.mainTXD = engineLoadTXD ( "pattern.txd" )
	
	-- Сообщаем серверу что у нас все готово
	addEvent ( "onClientTerrainReady", true )
	addEventHandler ( "onClientTerrainReady", resourceRoot, xrEngine.loadWorld, false )
	triggerServerEvent ( "onPlayerEngineReady", resourceRoot )
	
	if getLocalization ( ).code == "ru" then
		outputChatBox ( "Для получения информации нажмите F9.", 0, 255, 0 )
		outputChatBox ( "Нажмите и держите [X] для изменения ландшафта.", 255, 255, 0 )
	else
		outputChatBox ( "For more information press F9.", 0, 255, 0 )
		outputChatBox ( "Press and hold [X] to change the terrain level.", 255, 255, 0 )
	end
	
	exports["freecam"]:setFreecamDisabled ( )
end


function xrEngine.getMapFromWorldPosition ( x, y )
	local _x = _mathFloor ( x / HOR_SCALE ) * HOR_SCALE
	local _y = _mathFloor ( y / HOR_SCALE ) * HOR_SCALE
	local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
	local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
	local deltaX = ( _x - xrStreamerWorld.worldX ) / worldSizeX
	local deltaY = ( xrStreamerWorld.worldY - _y ) / worldSizeY
	local borderX = Heightfield.resolutionX - WORLD_SIZE_X * MAP_SIZE
	local borderY = Heightfield.resolutionY - WORLD_SIZE_Y * MAP_SIZE
	
	return _mathFloor ( deltaX * ( Heightfield.resolutionX - borderX ) ), _mathFloor ( deltaY * ( Heightfield.resolutionY - borderY ) )
end

function xrEngine.loadWorld ( resX, resY, vertScale, vertOffset, horScale )
	outputDebugString ( "Loading client world " .. resX .. "x" .. resY )

	-- Setup heightfield
	Heightfield.resolutionX = resX
	Heightfield.resolutionY = resY
	Heightfield.vertScale = vertScale
	Heightfield.vertOffset = vertOffset
	Heightfield.horScale = horScale

	xrStreamerWorld.init ( )
	
	 -- TCT integration
	addEvent ( "onClientTCTEditMode", false )
	addEventHandler ( "onClientTCTEditMode", root, xrEngine.toggleMode, false )
	
	addEventHandler ( "onClientRender", root, xrEngine.onRender, false )
	addEventHandler ( "onClientCursorMove", root, xrEngine.onCursorMove, false )
end

function xrEngine.toggleMode ( enabled )
	if enabled then
		if exports.wbo_flowtest_cr:getSelectedToolName ( ) == "Terrain" then
			EditorUI.showPanel ( )
			addEventHandler ( "onClientClick", root, xrEngine.onBrushApply, false )
			addEventHandler ( "onClientKey", root, xrEngine.onKey, false )
			xrEngine.editMode = true
		end
	else
		EditorUI.hidePanel ( )
		removeEventHandler ( "onClientClick", root, xrEngine.onBrushApply )
		removeEventHandler ( "onClientKey", root, xrEngine.onKey )
		xrEngine.editMode = nil
		
		xrEngine.boxSelect = nil
	end
end

local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3

function xrEngine.onRender ( )
	-- Рисуем полоску загрузки
	if BuildOrder.cr ~= nil then
		local barWidth, barHeight = 300, 20
		local barX, barY = sw / 2 - barWidth / 2, 50 + barHeight
			
		dxDrawRectangle ( barX, barY, barWidth, barHeight, tocolor ( 0, 0, 0, 130 ) )
		dxDrawRectangle ( barX, barY, barWidth * BuildOrder.progress, barHeight, tocolor ( 0, 150, 0, 255 ) )
		local sector = xrStreamerWorld.processSectors [ BuildOrder.current ]
		if sector then
			local ext = sector.processLeft == 1 and "COL" or "DFF"
					
			dxDrawText ( ext .. " " .. sector._index .. " building " .. math.floor ( 100 * BuildOrder.progress ) .. "% ...", barX, barY, barX + barWidth, barY + barHeight, tocolor ( 255, 255, 255 ), 1, "default", "center", "center" )
		end
	end
	
	--[[
		Обновляем освещение
	]]
	local ambr, ambg, ambb = exports.xrskybox:getEnvValue ( ENV_AMBIENT )
	local hemir, hemig, hemib, hemia = exports.xrskybox:getEnvValue ( ENV_HEMI )
	local sunr, sung, sunb = exports.xrskybox:getEnvValue ( ENV_SUNCOLOR )
		
	--dxSetShaderValue ( xrEngine.shader, "L_ambient", ambr, ambg, ambb, 1 )
	--dxSetShaderValue ( xrEngine.shader, "L_hemi_color", hemir, hemig, hemib, 1 )
	--dxSetShaderValue ( xrEngine.shader, "L_sun_color", sunr, sung, sunb )

	
	-- Если режим редактирования в данный момент не активирован, выходим из функции
	if xrEngine.editMode ~= true then
		return
	end
	

	local x, y, z, hitElement = getWorldCursorPosition ( )
	if x then
		local sector = xrStreamerWorld.findSector ( x, y )
		if sector and sector.loaded then
			dxDrawText ( sector._index, 500, 500 )
			
			
			local mxx, myy = xrEngine.getMapFromWorldPosition ( x, y )
			local normal = Heightfield.getRawNormal ( mxx, myy )
			
			local h = Heightfield.getHeight ( x, y )
			h = getWorldHeight ( h )
			
			local xx = xrStreamerWorld.worldX + mxx * HOR_SCALE
			local yy = xrStreamerWorld.worldY - myy * HOR_SCALE
			
			dxDrawLine3D ( xx, yy, h, xx + normal.x, yy + normal.y, h + normal.z, tocolor ( 255, 0, 0 ), 2 )
	
			-- Рисуем выделенные точки отдельно
			for index, vec in pairs ( xrEngine.selectedPoints ) do
				local zpos = getWorldHeight ( vec.z )
				dxDrawMaterialLine3D ( vec.x, vec.y, zpos - 0.25, vec.x, vec.y, zpos + 0.25, xrEngine.squareTex, 0.5, xrEngine.pointSelected )
			end
	
			-- Рисуем сетку контрольных точек (снизу вверх)
			local halfMapStep = HOR_SCALE/2
			local resolutionX = Heightfield.resolutionX
			for i, vec in ipairs ( xrEngine.snapGrid ) do
				-- Рисуем точку
				local mx, my = xrEngine.getMapFromWorldPosition ( vec.x + halfMapStep, vec.y + halfMapStep )
				local index = my * resolutionX + mx + 1
				local zpos
				
				local selectedVec = xrEngine.selectedPoints [ index ]
				if selectedVec then
					zpos = getWorldHeight ( selectedVec.z )
				else
					zpos = getWorldHeight ( vec.z )
					dxDrawMaterialLine3D ( vec.x, vec.y, zpos - 0.25, vec.x, vec.y, zpos + 0.25, xrEngine.squareTex, 0.5, i == xrEngine.cursorPoint and xrEngine.pointCurrent or xrEngine.pointDefault )
				end
				
				-- Если индекс не на краю сетки, рисуем горизонтальную линию
				if i % xrEngine.gridSize > 0 then
					local rightVec = xrEngine.snapGrid [ i + 1 ]
					local right = xrEngine.selectedPoints [ index + xrEngine.snapStep ]
					if right then
						dxDrawLine3D ( vec.x, vec.y, zpos, rightVec.x, rightVec.y, getWorldHeight ( right.z ) + 0.1, xrEngine.pointSelected, 6 )
					else
						dxDrawLine3D ( vec.x, vec.y, zpos, rightVec.x, rightVec.y, getWorldHeight ( rightVec.z ) + 0.1, selectedVec == nil and xrEngine.pointDefault or xrEngine.pointSelected, 6 )
					end
				end
				-- Если индекс выше последней строки, ресуем вертикальную линию
				if i <= xrEngine.gridSize^2 - xrEngine.gridSize then
					local topVec = xrEngine.snapGrid [ i + xrEngine.gridSize ]
					local top = xrEngine.selectedPoints [ index - (resolutionX*xrEngine.snapStep) ]
					if top then
						dxDrawLine3D ( vec.x, vec.y, zpos, topVec.x, topVec.y, getWorldHeight ( top.z ) + 0.1, xrEngine.pointSelected, 6 )
					else
						dxDrawLine3D ( vec.x, vec.y, zpos, topVec.x, topVec.y, getWorldHeight ( topVec.z ) + 0.1, selectedVec == nil and xrEngine.pointDefault or xrEngine.pointSelected, 6 )
					end
				end
			end
			
			-- Рисуем границы сектора
			local leftTopX, leftTopY = sector.x, sector.y
			local rightBottomX, rightBottomY = sector.x + SECTOR_SIZE, sector.y - SECTOR_SIZE
			
			local _z = z
			local hit, _, _, hitZ = processLineOfSight ( sector.x, sector.y, z + 256, sector.x, sector.y, z - 256, false, false, false, true )
			if hit then _z = hitZ end;
			dxDrawLine3D ( leftTopX, leftTopY, _z, rightBottomX, leftTopY, _z, tocolor ( 255, 255, 0 ), 20 )
			dxDrawLine3D ( rightBottomX, leftTopY, _z, rightBottomX, rightBottomY, _z, tocolor ( 255, 255, 0 ), 20 )
			dxDrawLine3D ( rightBottomX, rightBottomY, _z, leftTopX, rightBottomY, _z, tocolor ( 255, 255, 0 ), 20 )
			dxDrawLine3D ( leftTopX, rightBottomY, _z, leftTopX, leftTopY, _z, tocolor ( 255, 255, 0 ), 20 )
			--dxDrawLine3D ( leftTopX, leftTopY, _z, leftTopX, leftTopY, _z + 20, tocolor ( 0, 255, 255 ), 20 )
		end
	end
end

local lastCursorMove = getTickCount ( )
function xrEngine.onCursorMove ( _, _, cx, cy )
	-- Предотвращаем излишне частый вызов функции при быстром перемещении курсора
	local now = getTickCount ( )
	if now - lastCursorMove < 60 then
		return
	end
	lastCursorMove = now

	-- Предотвращаем изменения когда курсор на панели редактора
	if EditorUI.isHoverOn ( ) then
		return
	end
	
	local x, y, z, hitElement = getWorldCursorPosition ( )
	if x then
		local cx, cy, cz = getCameraMatrix ( )
		local camPosVec = Vector3 ( cx, cy, cz )
		local camLookVec = Vector3 ( x, y, z )
		local pointIndex
	
		local bias = HOR_SCALE * xrEngine.snapStep
		local snapX, snapY = _mathFloor ( x / bias ) * bias, _mathFloor ( y / bias ) * bias
		local halfGridSize = xrEngine.gridSize / 2
		local leftX = snapX - bias*halfGridSize
		local bottomY = snapY - bias*halfGridSize
		local halfMapStep = HOR_SCALE/2
		local isEmpty = #xrEngine.snapGrid == 0
	
		local gridSide = xrEngine.gridSize - 1
		for i = 0, gridSide do
			local gy = bottomY + i*bias
			for j = 0, gridSide do
				local gx = leftX + j*bias
				
				local mx, my = xrEngine.getMapFromWorldPosition ( gx + halfMapStep, gy + halfMapStep )
				local height = Heightfield.getLevel ( mx, my )
				if not height then
					outputDebugString ( "Height error: " .. tostring ( mx ) .. ", " .. tostring ( my ) .. ", " .. tostring ( gx ) .. ", " .. tostring ( gy ) .. ", " .. tostring ( x ) .. ", " .. tostring ( y ) )
					return
				end
				local level = getWorldHeight ( height )
				
				local index = i * xrEngine.gridSize + j
				
				-- Предотвращаем повтороное создание вектора
				local vec = xrEngine.snapGrid [ index + 1 ]
				if vec then
					vec.x = gx
					vec.y = gy
					vec.z = height
				else
					vec = Vector3 ( gx, gy, height )
					xrEngine.snapGrid [ index + 1 ] = vec
				end
				
				if sphereCollisionTest ( camPosVec, camLookVec, Vector3 ( gx, gy, level ), 0.8 ) then
					pointIndex = index + 1
				end
			end
		end
		
		xrEngine.cursorPoint = pointIndex
		
		-- Если мы нашли точку под курсором
		--[[if pointIndex then
			xrEngine.cursorPoint = poi
		
			local mapVec = xrEngine.getMapFromWorldPosition ( Vector2 ( xrEngine.snapGrid [ pointIndex ] + HOR_SCALE/2 )

			local resolutionX = Heightfield.resolutionX
			xrEngine.cursorPoint = mapVec.y * resolutionX + mapVec.x
		end]]
	end
end

-- onClientClick
function xrEngine.onBrushApply ( button, keyState )
	if EditorUI.isHoverOn ( ) then
		return
	end
	
	if button == "right" then
		if xrEngine.cursorPoint and keyState ~= "down" then
			-- Выделяем или скрываем контрольную точку
			local vec = xrEngine.snapGrid [ xrEngine.cursorPoint ]
			local mx, my = xrEngine.getMapFromWorldPosition ( vec.x + HOR_SCALE/2, vec.y + HOR_SCALE/2 )
			local resolutionX = Heightfield.resolutionX
			local index = my * resolutionX + mx + 1
			
			if xrEngine.selectedPoints [ index ] then
				xrEngine.selectedPoints [ index ] = nil
			else
				-- Temp!
				local num = 0
				for _, _ in pairs ( xrEngine.selectedPoints ) do
					num = num + 1
				end
				
				if num < 6 then
					xrEngine.selectedPoints [ index ] = Vector3 ( vec.x, vec.y, vec.z ) -- Копируем вектор
					outputDebugString ( "Selected control point " .. index )
				else
					outputChatBox ( "Вы не можете выбрать больше 6 точек! Для сброса нажмите [A]" )
				end
			end
		end
		
		return
	end
	
	local x, y, z, hitElement = getWorldCursorPosition ( )
	if not x then
		return
	end
		
	local sector = xrStreamerWorld.findSector ( x, y )
	if sector then
		local _x = math.floor ( ( x + 1.5 ) / HOR_SCALE ) * HOR_SCALE
		local _y = math.floor ( ( y + 1.5 ) / HOR_SCALE ) * HOR_SCALE
		local worldSizeX = SECTOR_SIZE * WORLD_SIZE_X
		local worldSizeY = SECTOR_SIZE * WORLD_SIZE_Y
		local deltaX = ( _x - xrStreamerWorld.worldX ) / worldSizeX
		local deltaY = ( xrStreamerWorld.worldY - _y ) / worldSizeY
		local mapSizeX = Heightfield.resolutionX
		local mapSizeY = Heightfield.resolutionY
		local _pointx, _pointy = math.floor ( deltaX * mapSizeX ), math.floor ( deltaY * mapSizeY )
		
		--[[
			BOX shape
		]]
		if xrEngine.brushShape == BrushShape.BOX then
			local boxSelect = xrEngine.boxSelect
			if boxSelect then
				local width = math.abs ( _pointx - boxSelect.startX )
				local height = math.abs ( _pointy - boxSelect.startY )
				if width == 0 or height == 0 then
					outputChatBox ( "Вы должны выбрать как минимум один квадрат!", 255, 0, 0 )
					xrEngine.boxSelect = nil
					return
				end
				
				if boxSelect.startX > _pointx then
					boxSelect.startX = boxSelect.startX - width
				end
				if boxSelect.startY > _pointy then
					boxSelect.startY = boxSelect.startY - height
				end
			
				local strength = xrEngine.brushMode == BrushModes.FLATTEN and xrEngine.flattenLevel or xrEngine.brushStrength
				brushBoxFunc ( boxSelect.startX, boxSelect.startY, width, height, strength, xrEngine.brushMode )
				
				-- Приращаем ревизию сектора
				sector.rev = sector.rev + 1
				xrStreamerWorld.updateSectorRev ( sector._index - 1, sector.rev )
			
				triggerServerEvent ( "onApplyBrushBox", resourceRoot, boxSelect.startX, boxSelect.startY, width, height, strength, xrEngine.brushMode )
				
				xrEngine.boxSelect = nil
				xrEngine.flattenLevel = nil
				
				if isElement ( xrEngine.areaShader ) then
					destroyElement ( xrEngine.areaShader )
				end
			else
				local level = Heightfield.getLevel ( _pointx, _pointy )
				
				xrEngine.boxSelect = {
					startX = _pointx,
					startY = _pointy,
					worldX = _x,
					worldY = _y,
					level = level
				}
				
				-- Забираем уровень сначала, если нужно
				if xrEngine.brushMode == BrushModes.FLATTEN then
					xrEngine.flattenLevel = level or 0
				end
				
				xrEngine.areaShader = dxCreateShader ( "area.fx" )
				dxSetShaderValue ( xrEngine.areaShader, "Color", 0.8, 0.1, 0, 0.2 )
			end
			
			return
		elseif keyState ~= "down" then
			return
		end
		
		--[[
			CIRCLE shape
		]]
		-- Забираем уровень сначала, если нужно
		if xrEngine.brushMode == BrushModes.FLATTEN and xrEngine.pickLevel then
			local level = Heightfield.getLevel ( _pointx, _pointy )
			xrEngine.flattenLevel = level or 0
			xrEngine.pickLevel = nil
			
			return
		end
		
		local strength = xrEngine.brushMode == BrushModes.FLATTEN and xrEngine.flattenLevel or xrEngine.brushStrength
		brushCircleFunc ( _pointx, _pointy, strength, xrEngine.brushSize, xrEngine.brushMode )
			
		-- Приращаем ревизию сектора
		sector.rev = sector.rev + 1
		xrStreamerWorld.updateSectorRev ( sector._index - 1, sector.rev )
			
		triggerServerEvent ( "onApplyBrushCircle", resourceRoot, _pointx, _pointy, strength, xrEngine.brushSize, xrEngine.brushMode )
	end
end

function xrEngine.onKey ( button, pressOrRelease )
	if not pressOrRelease then
		return
	end

	if button == "mouse_wheel_up" then
		xrEngine.snapStep = math.min ( xrEngine.snapStep * 2, xrEngine.maxSnapStep )
	elseif button == "mouse_wheel_down" then
		xrEngine.snapStep = math.max ( xrEngine.snapStep / 2, 2 )
	
	elseif button == "num_add" then
		for index, vec in pairs ( xrEngine.selectedPoints ) do
			--[[local dimX = Heightfield.resolutionX
		
			local mapx = math.floor ( (index-1) % dimX )
			local mapy = math.floor ( (index-1) / dimX )
		
			local level = getRawHeight ( mapx, mapy )
			xrEngine.adjustMapPixel ( mapx, mapy, level + xrEngine.brushStrength )
			
			vec.z = PATCH_Z + (level + xrEngine.brushStrength)*MAP_SPACING_Z - HALF_ELEVATION]]
			vec.z = vec.z + xrEngine.brushStrength
		end
	elseif button == "num_sub" then
		for index, vec in pairs ( xrEngine.selectedPoints ) do
			--[[local dimX = Heightfield.resolutionX
		
			local mapx = math.floor ( (index-1) % dimX )
			local mapy = math.floor ( (index-1) / dimX )
		
			local level = getRawHeight ( mapx, mapy )
			xrEngine.adjustMapPixel ( mapx, mapy, level - xrEngine.brushStrength )
			
			vec.z = PATCH_Z + (level - xrEngine.brushStrength)*MAP_SPACING_Z - HALF_ELEVATION]]
			vec.z = vec.z - xrEngine.brushStrength
		end
	elseif button == "num_5" then
		local dimX = Heightfield.resolutionX
		local pointsToSend = { }
		for index, vec in pairs ( xrEngine.selectedPoints ) do
			local mapx = math.floor ( (index-1) % dimX )
			local mapy = math.floor ( (index-1) / dimX )
		
			xrEngine.adjustMapPixel ( mapx, mapy, vec.z, xrEngine.snapStep )
			
			pointsToSend [ index ] = vec.z
		end
		
		triggerServerEvent ( "onApplyGrid", resourceRoot, pointsToSend, xrEngine.snapStep )
	elseif button == "a" then
		xrEngine.selectedPoints = { }
	end
end

function xrEngine.interpolateCell ( lx, ty, rx, by, updateSectors )
	local width = rx - lx
	local height = by - ty
	
	local y1 = getRawHeight ( lx, ty )
	local y2 = getRawHeight ( lx, by )
	local y3 = getRawHeight ( rx, ty )
	local y4 = getRawHeight ( rx, by )
	
	for i = 0, height do
		local h1 = interpolateBetween ( y1, 0, 0, y2, 0, 0, i / height, "Linear" )
		local h2 = interpolateBetween ( y3, 0, 0, y4, 0, 0, i / height, "Linear" )
	
		for j = 0, width do
			local height = interpolateBetween ( h1, 0, 0, h2, 0, 0, j / width, "Linear" )
			xrStreamerWorld.setMapPixel ( lx + j, ty + i, height, updateSectors )
		end
	end
end

function xrEngine.adjustMapPixel ( x, y, level, _step )
	-- Сначала меняем высоту точки
	Heightfield.setLevel ( x, y, level )

	local updateSectors = { }
	
	local leftX = x - _step
	local topY = y - _step
	
	-- Интерполируем квадраты к этой точке
	for i = 0, 1 do
		local ty = topY + _step*i
		local by = ty + _step
		
		for j = 0, 1 do
			local lx = leftX + _step*j
			local rx = lx + _step
			
			xrEngine.interpolateCell ( lx, ty, rx, by, updateSectors )
		end
	end
	
	-- Перезагружаем все задействованные сектора
	for sector, _ in pairs ( updateSectors ) do
		sector:reload ( )
	end
end

--[[
	EditorUI
]]
EditorUI = { 
	width = 600,
	height = 200
}

function EditorUI.showPanel ( )
	if isElement ( EditorUI.wnd ) then
		outputDebugString ( "Панель уже создана", 2 )
		return
	end

	EditorUI.wnd = guiCreateWindow ( sw / 2 - EditorUI.width / 2, sh - EditorUI.height - 100, EditorUI.width, EditorUI.height, "TerrainEditor", false )
	EditorUI.panel = guiCreateTabPanel ( 10, 30, EditorUI.width - 20, EditorUI.height - 40, false, EditorUI.wnd )
	EditorUI.terrainTab = guiCreateTab ( "Terrain", EditorUI.panel )
	EditorUI.settingsTab = guiCreateTab ( "Settings", EditorUI.panel )
	
	--[[
		Terrain tab
	]]
	
	-- Brush mode
	guiRadioImageSetSplit ( "BrushMode" )
	
	EditorUI.modeCtrl = {
		guiCreateRadioImage ( 20, 40, 50, 50, "images/raiseHeight", false, EditorUI.terrainTab ),
		guiCreateRadioImage ( 80, 40, 50, 50, "images/lowerHeight", false, EditorUI.terrainTab ),
		guiCreateRadioImage ( 140, 40, 50, 50, "images/smoothHeight", false, EditorUI.terrainTab ),
		guiCreateRadioImage ( 200, 40, 50, 50, "images/flattenHeight", false, EditorUI.terrainTab )
	}
	
	setElementData ( EditorUI.modeCtrl [ 1 ], "mode", BrushModes.RAISE, false )
	setElementData ( EditorUI.modeCtrl [ 2 ], "mode", BrushModes.LOWER, false )
	setElementData ( EditorUI.modeCtrl [ 3 ], "mode", BrushModes.SMOOTH, false )
	setElementData ( EditorUI.modeCtrl [ 4 ], "mode", BrushModes.FLATTEN, false )
	
	guiRadioImageSetSelected ( EditorUI.modeCtrl [ xrEngine.brushMode ], true )
	
	-- Brush strength
	local rightX = EditorUI.width - 60
	local maxCtrlSize = EditorUI.height - 100
	EditorUI.brushStrScr = guiCreateScrollBar ( rightX, 20, 20, maxCtrlSize, false, false, EditorUI.terrainTab )
	guiScrollBarSetScrollPosition ( EditorUI.brushStrScr, ( xrEngine.brushStrength / xrEngine.brushMaxStrength ) * 100 )
	addEventHandler ( "onClientGUIScroll", EditorUI.brushStrScr, EditorUI.onScroll, false )
	
	-- Brush size
	rightX = rightX - 30
	local brushFactor = xrEngine.brushSize / xrEngine.brushMaxSize
	EditorUI.brushSizeScr = guiCreateScrollBar ( rightX, 20, 20, maxCtrlSize, false, false, EditorUI.terrainTab )
	guiScrollBarSetScrollPosition ( EditorUI.brushSizeScr, brushFactor * 100 )
	addEventHandler ( "onClientGUIScroll", EditorUI.brushSizeScr, EditorUI.onScroll, false )
	
	rightX = rightX - maxCtrlSize - 10
	local size = math.ceil ( maxCtrlSize * brushFactor )
	local centerX, centerY = rightX + ( maxCtrlSize / 2 ), 20 + ( maxCtrlSize / 2 )
	EditorUI.brushSizeImg = guiCreateStaticImage ( centerX - size / 2, centerY - size / 2, size, size, "images/circle-filled.png", false, EditorUI.terrainTab )
	EditorUI.brushSizeLbl = guiCreateLabel ( centerX - size / 2, centerY - size / 2, size, size, tostring ( xrEngine.brushSize ), false, EditorUI.terrainTab )
	guiLabelSetHorizontalAlign ( EditorUI.brushSizeLbl, "center" )
	guiLabelSetVerticalAlign ( EditorUI.brushSizeLbl, "center" )
	guiLabelSetColor ( EditorUI.brushSizeLbl, 255, 0, 0 )
	
	-- Brush shape
	guiRadioImageSetSplit ( "BrushShape" )
	
	rightX = rightX - 60
	EditorUI.shapeCtrl = {
		guiCreateRadioImage ( rightX, 15, 50, 50, "images/boxBrush", false, EditorUI.terrainTab ),
		guiCreateRadioImage ( rightX, 75, 50, 50, "images/circleBrush", false, EditorUI.terrainTab )
	}
	setElementData ( EditorUI.shapeCtrl [ 1 ], "shape", BrushShape.BOX )
	setElementData ( EditorUI.shapeCtrl [ 2 ], "shape", BrushShape.CIRCLE )
	
	guiRadioImageSetSelected ( EditorUI.shapeCtrl [ xrEngine.brushShape ], true )
	
	addEventHandler ( "onClientGUIImageSwitch", EditorUI.terrainTab, EditorUI.onImageSwitch )
	
	showCursor ( true )
end

function EditorUI.hidePanel ( )
	if isElement ( EditorUI.wnd ) then
		destroyElement ( EditorUI.wnd )
		showCursor ( false )
	end
	
	EditorUI.mouseHoverOn = nil
end

function EditorUI.isHoverOn ( )
	if isElement ( EditorUI.wnd ) and isCursorShowing ( ) then
		local cx, cy = getCursorPosition ( )
		local x, y = guiGetPosition ( EditorUI.wnd, false )
		local width, height = guiGetSize ( EditorUI.wnd, false )
		return _withinRectangle ( cx * sw, cy * sh, x, y, width, height )
	end
end

function EditorUI.onImageSwitch ( splitName, prevImg )
	if splitName == "BrushMode" then
		local modeIndex = getElementData ( source, "mode", false )
		
		-- Если мы выбрали режим плоскости, говорим движку что нужно собрать контрольный уровень
		if xrEngine.brushShape == BrushShape.CIRCLE then
			if modeIndex == BrushModes.FLATTEN then
				xrEngine.pickLevel = true
			
				if getLocalization ( ).code == "ru" then
					outputChatBox ( "Сначала выберите контрольную точку", 0, 255, 0 )
				else
					outputChatBox ( "First, select a control point", 0, 255, 0 )
				end
			else
				xrEngine.pickLevel = nil
				xrEngine.flattenLevel = nil
			end
		end
		
		xrEngine.brushMode = modeIndex
	elseif splitName == "BrushShape" then
		local shapeIndex = getElementData ( source, "shape", false )
		
		xrEngine.brushShape = shapeIndex
	end
end

function EditorUI.onScroll ( )
	-- Brush size
	if source == EditorUI.brushSizeScr then
		local pos = guiScrollBarGetScrollPosition ( source ) / 100
			
		xrEngine.brushSize = math.max ( math.ceil ( pos * xrEngine.brushMaxSize ), 1 )
			
		local brushFactor = xrEngine.brushSize / xrEngine.brushMaxSize
		local maxCtrlSize = EditorUI.height - 100
		local size = math.max ( math.ceil ( maxCtrlSize * brushFactor ), 1 )
		local centerX, centerY = EditorUI.width - 90 - maxCtrlSize - 10 + ( maxCtrlSize / 2 ), 20 + ( maxCtrlSize / 2 )
			
		guiSetPosition ( EditorUI.brushSizeImg, centerX - size / 2, centerY - size / 2, false )
		guiSetSize ( EditorUI.brushSizeImg, size, size, false )
			
		guiSetText ( EditorUI.brushSizeLbl, tostring ( xrEngine.brushSize ) )
		
	-- Brush strength
	elseif source == EditorUI.brushStrScr then
		local pos = guiScrollBarGetScrollPosition ( source ) / 100
	
		xrEngine.brushStrength = math.max ( math.ceil ( pos * xrEngine.brushMaxStrength ), 1 )
	end
end

addCommandHandler ( "lodlevel",
	function ( _, level )
		level = tonumber ( level )
		if not level then
			outputChatBox ( "Вы должны указать уровень лода!" )
			return
		end
		level = math.floor ( level )
		
		if level < 1 or level > 3 then
			outputChatBox ( "Уровень лода может варьироваться от 1 до 3!" )
			return
		end
		
		LOD_LEVEL = level
		
		setElementData ( localPlayer, "lodlevel", level )
		
		xrStreamerWorld.unloadAll ( )
		
		outputChatBox ( "Вы изменили уровень лода на " .. level )
	end
)

addCommandHandler ( "genrate",
	function ( _, rate )
		rate = tonumber ( rate )
		if not rate then
			outputChatBox ( "Вы должны указать скорость!" )
			return
		end
		rate = math.floor ( rate )
		
		if rate < 0 or rate > 1000 then
			outputChatBox ( "Скорость может варьироваться от 0 до 1000!" )
			rate = _mathClamp ( 0, rate, 1000 )
		end
		
		outputChatBox ( "Вы изменили скорость построения до " .. rate .. " тиков" )
		
		GEN_LIMIT = rate
	end
)

addCommandHandler ( "gentime",
	function ( _, time )
		time = tonumber ( time )
		if not time then
			outputChatBox ( "Вы должны указать скорость!" )
			return
		end
		time = math.floor ( time )
		
		if time < 1 or time > 10000 then
			outputChatBox ( "Время может варьироваться от 1 до 10000!" )
			time = _mathClamp ( 1, time, 10000 )
		end
		
		outputChatBox ( "Вы изменили время построения до " .. time .. " мс" )
		
		GEN_TIME = time
	end
)

local mapVisible = false
addCommandHandler ( "showmap",
	function ( )
		mapVisible = not mapVisible
	end
)

addCommandHandler ( "xrfreecam",
	function ( )
		if xrEngine.freecamMode then
			exports["freecam"]:setFreecamDisabled ( )
			setCameraTarget ( localPlayer )
			xrEngine.freecamMode = nil
		else
			exports["freecam"]:setFreecamEnabled ( )
			xrEngine.freecamMode = true
		end
	end
)

addCommandHandler ( "smoothiter",
	function ( _, iters )
		iters = tonumber ( iters )
		if iters then
			SMOOTH_ITERS = _mathClamp ( 1, iters, 50 )
			outputChatBox ( "Вы изменили количество итераций до " .. iters )
		else
			outputChatBox ( "Вы должны количество итераций!" )
		end
	end
)

addEvent ( "onClientApplyBrushCircle", true )
addEventHandler ( "onClientApplyBrushCircle", resourceRoot,
	function ( x, y, strength, size, mode )
		brushCircleFunc ( x, y, strength, size, mode )
	end
, false )

addEvent ( "onClientApplyBrushBox", true )
addEventHandler ( "onClientApplyBrushBox", resourceRoot,
	function ( x, y, width, height, strength, mode )
		brushBoxFunc ( x, y, width, height, strength, mode )
	end
, false )

addEvent ( "onClientApplyGrid", true )
addEventHandler ( "onClientApplyGrid", resourceRoot,
	function ( points, step )
		local dimX = Heightfield.resolutionX
		for index, level in pairs ( points ) do
			local mapx = math.floor ( (index-1) % dimX )
			local mapy = math.floor ( (index-1) / dimX )
		
			xrEngine.adjustMapPixel ( mapx, mapy, level, step )
		end
	end
, false )

addEvent ( "onClientTerrainPreBuild", true )
addEventHandler ( "onClientTerrainPreBuild", resourceRoot,
	function ( data )
		outputDebugString ( "Начинаем построение" )
	
		Heightfield.set ( data )
		
		xrStreamerWorld.rebuildAllSectors ( )
	end
, false )

addCommandHandler ( "clearterrain",
	function ( )
		local filesNum = 0
		local sectorsNum = 0
	
		for i = 0, WORLD_SIZE_Y-1 do
			for j = 0, WORLD_SIZE_X-1 do
				local _index = i * WORLD_SIZE_X + j + 1
				local count = 0
				local dffPath = "sectors/" .. _index .. ".dff"
				if fileExists ( dffPath ) then
					fileDelete ( dffPath )
					count = count + 1
				end
				local colPath = "sectors/" .. _index .. ".col"
				if fileExists ( colPath ) then
					fileDelete ( colPath )
					count = count + 1
				end
				local pngPath = "sectors/" .. _index .. ".png"
				if fileExists ( pngPath ) then
					fileDelete ( pngPath )
					count = count + 1
				end
				
				if count > 0 then
					filesNum = filesNum + count
					sectorsNum = sectorsNum + 1
				end
			end
		end
		
		outputChatBox ( "Успешно удалено " .. filesNum .. " файлов из " .. sectorsNum .. " секторов" )
	end
)

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		xrEngine.init ( )
	end
)

-- EXPORT
function getTerrainHeight ( x, y )
	local level = PATCH_Z + Heightfield.getHeight ( x, y )*Heightfield.vertScale
	
	return level
end

function getTerrainSector ( x, y )
	local sector = xrStreamerWorld.findSector ( x, y, false )
	if sector then
		return sector._index
	end
	
	return false
end

function isTerrainSectorStreamedIn ( sectorIndex )
	local sector = xrStreamerWorld.sectors [ sectorIndex ]
	if sector then
		return xrStreamerWorld.activated [ sector ] == true
	else
		outputDebugString ( "Сектора с таким индексом не существует", 2 )
	end
	
	return false
end

function getChannelMasks ( )
	local masks = { }
	for _, channelData in ipairs ( xrShaderMaskChannel ) do
		table.insert ( masks, { channelData.channel, channelData.file } )
	end
	
	return masks
end