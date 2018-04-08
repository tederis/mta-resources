--[[
	TEDERIs TerrainEditor
	Part of TEDERIs Construction Tools
	FastDff.lua
]]

local _mathMin = math.min
local _mathMax = math.max
local _mathSqrt = math.sqrt
local _mathFloor = math.floor

--[[
	FastDFFBuilder
]]
FastDFFBuilder = {

}

local DFF_VERTICES =  61048
local DFF_TRIANGLES = 21024
local DFF_UV = 216
--local DFF_MAXDIST = 39264

function FastDFFBuilder.setModelVertex ( sector, vertexIndex, level )
	local filePath = "sectors/" .. sector._index .. ".dff"
	
	-- Копируем файл модели-шаблона в файл сектора
	if fileExists ( filePath ) ~= true then
		fileCopy ( "pattern.dff", filePath, true )
	end
	
	local file = fileOpen ( filePath, false )
	if not file then
		outputDebugString ( "Файла модели сектора " .. sectorIndex .. " не существует!", 2 )
		return
	end
	
	-- Перемещаемся к интересующему нас вертексу
	fileSetPos ( file, DFF_VERTICES + (vertexIndex * 12) + 8 )
	-- Записываем в Z наш уровень
	dataToBytes ( file, "f", level )
	
	return fileClose ( file )
end

--[[
	Пишем напрямую в вертексный буфер файла модели
]]
function FastDFFBuilder.writeMap ( sector )
	local filePath = "sectors/" .. sector._index .. ".dff"
	
	-- Копируем файл модели-шаблона в файл сектора
	if fileExists ( filePath ) ~= true then
		fileCopy ( "pattern.dff", filePath, true )
	end
	
	local file = fileOpen ( filePath, false )
	if not file then
		outputDebugString ( "Файла модели сектора " .. sector._index .. " не существует!", 2 )
		return
	end
	
	-- Находим верхний левый пиксель сектора на карте высот
	local sectorColumn = _mathFloor ( (sector._index-1) % WORLD_SIZE_X )
	local sectorRow = _mathFloor ( (sector._index-1) / WORLD_SIZE_X )
	local pixelX, pixelY = sectorColumn * MAP_SIZE, sectorRow * MAP_SIZE
	
	local _fileSetPos = fileSetPos
	local _dataToBytes = dataToBytes
	local _getLevel = Heightfield.getLevel
	
	local totalOps = (MAP_SIZE+1)^2
	local passedOps = 0
	local limitOps = 0
	
	local halfElevation = ELEVATION_CORRECT and ( math.floor ( 299 * Heightfield.vertScale ) / 2 ) or 0
	local relX = WORLD_SIZE_X * MAP_SIZE
	local relY = WORLD_SIZE_X * MAP_SIZE
	
	for i = 0, MAP_SIZE do
		for j = 0, MAP_SIZE do
			-- Vertices
			local index = j * (MAP_SIZE+1) + i
			_fileSetPos ( file, DFF_VERTICES + (index*12) + 8 ) -- Inverted
			
			local level = _getLevel ( pixelX + j, pixelY + i )
			local height = Heightfield.vertScale * level - halfElevation
			
			_dataToBytes ( file, "f", height --[[(level * MAP_SPACING_Z) - halfElevation]] )
			
			-- UVs
			_fileSetPos ( file, DFF_UV + (index*8) )
			if SECTOR_RELATIVE then
				_dataToBytes ( file, "ff", j/MAP_SIZE, i/MAP_SIZE )
			else
				_dataToBytes ( file, "ff", (pixelX + j) / Heightfield.resolutionX, (pixelY + i) / Heightfield.resolutionY )
			end
			
			-- Если потоковость включена
			if THREADED then
				passedOps = passedOps + 1
				limitOps = limitOps + 1
				if limitOps > GEN_LIMIT then
					limitOps = 0
				
					coroutine.yield ( passedOps / totalOps )
				end
			end
		end
	end
	
	fileClose ( file )
	--outputDebugString ( "Файл *.dff сектора " .. sector._index .. " успешно построен", 3 )
end

--[[
	FastCOLBuilder
]]
FastCOLBuilder = {

}

local COL_BB = 32
local COL_VERTICES = 120
local COL_POLYS = 15728

function FastCOLBuilder.setModelVertex ( sector, vertexIndex, level )
	local filePath = "sectors/" .. sector._index .. ".col"
	
	-- Копируем файл модели-шаблона в файл сектора
	if fileExists ( filePath ) ~= true then
		fileCopy ( "pattern.col", filePath, true )
	end
	
	local file = fileOpen ( filePath, false )
	if not file then
		outputDebugString ( "Файла столкновений сектора " .. sectorIndex .. " не существует!", 2 )
		return
	end
	
	-- Перемещаемся к интересующему нас вертексу
	fileSetPos ( file, COL_VERTICES + (vertexIndex * 6) + 4 )
	-- Записываем в Z наш уровень
	dataToBytes ( file, "s", 128 * level )
	
	-- Читаем minz и maxz
	fileSetPos ( file, COL_BB + 8 )
	local minz = bytesToData ( 
		"f",
		fileRead ( file, 4 )
	)
	minz = _mathMin ( minz, level )
	
	fileSetPos ( file, COL_BB + 20 )
	local maxz = bytesToData ( 
		"f",
		fileRead ( file, 4 )
	)
	maxz = _mathMax ( maxz, level )
	
	if minz < -299.9 or maxz > 299.9 then
		outputDebugString ( "Модель имеет недопустимую высоту!(" .. minz .. ", " .. maxz .. "," .. level .. ")", 2 )
	end
	
	-- Обновляем minz
	fileSetPos ( file, COL_BB + 8 )
	dataToBytes ( file, "f", minz )
	
	-- Обновляем maxz
	fileSetPos ( file, COL_BB + 20 )
	dataToBytes ( file, "f", maxz )

	-- Обновляем centerz
	fileSetPos ( file, COL_BB + 32 )
	local cz = 0.5 * ( minz + maxz )
	dataToBytes ( file, "f", cz )
	
	-- Обновляем радиус
	fileSetPos ( file, COL_BB + 36 )
	local distz = 0.5 * _mathSqrt ( (maxz - minz)^2 )
	dataToBytes ( file, "f", _mathMax ( distz, 0.5 * (SECTOR_SIZE*1.414) ) )
	
	return fileClose ( file )
end

--[[
	Пишем напрямую в вертексный буфер файла модели
]]
function FastCOLBuilder.writeMap ( sector )
	local filePath = "sectors/" .. sector._index .. ".col"
	
	-- Копируем файл модели-шаблона в файл сектора
	if fileExists ( filePath ) ~= true then
		fileCopy ( "pattern.col", filePath, true )
	end
	
	local file = fileOpen ( filePath, false )
	if not file then
		outputDebugString ( "Файла модели сектора " .. sector._index .. " не существует!", 2 )
		return
	end
	
	-- Находим верхний левый пиксель сектора на карте высот
	local sectorColumn = _mathFloor ( (sector._index-1) % WORLD_SIZE_X )
	local sectorRow = _mathFloor ( (sector._index-1) / WORLD_SIZE_X )
	local pixelX, pixelY = sectorColumn * MAP_SIZE, sectorRow * MAP_SIZE
	
	local _fileSetPos = fileSetPos
	local _dataToBytes = dataToBytes
	local _getLevel = Heightfield.getLevel
	
	local minz, maxz = 299.9, -299.9
	
	local totalOps = (MAP_SIZE+1)^2
	local passedOps = 0
	local limitOps = 0

	local halfElevation = ELEVATION_CORRECT and ( math.floor ( 299 * Heightfield.vertScale ) / 2 ) or 0
	
	for i = 0, MAP_SIZE do
		for j = 0, MAP_SIZE do
			-- Vertices
			local index = j * (MAP_SIZE+1) + i -- Inverted
			_fileSetPos ( file, COL_VERTICES + (index*6) + 4 )
			
			local level = _getLevel ( pixelX + j, pixelY + i )
			--local zpos = (level * MAP_SPACING_Z) - halfElevation
			local zpos = Heightfield.vertScale * level - halfElevation

			_dataToBytes ( file, "s", 128 * zpos )
			
			minz = _mathMin ( minz, zpos )
			maxz = _mathMax ( maxz, zpos )
			
			-- Если потоковость включена
			if THREADED then
				passedOps = passedOps + 1
				limitOps = limitOps + 1
				if limitOps > GEN_LIMIT then
					limitOps = 0
				
					coroutine.yield ( passedOps / totalOps )
				end
			end
		end
	end
	
	if minz < -299.9 or maxz > 299.9 then
		outputDebugString ( "Модель имеет недопустимую высоту!(" .. minz .. ", " .. maxz .. ")", 2 )
	end

	-- Обновляем minz
	fileSetPos ( file, COL_BB + 8 )
	dataToBytes ( file, "f", minz )
	
	-- Обновляем maxz
	fileSetPos ( file, COL_BB + 20 )
	dataToBytes ( file, "f", maxz )
	
	-- Обновляем centerz
	fileSetPos ( file, COL_BB + 32 )
	local cz = 0.5 * ( minz + maxz )
	dataToBytes ( file, "f", cz )
	
	-- Обновляем радиус
	fileSetPos ( file, COL_BB + 36 )
	local distz = 0.5 * _mathSqrt ( (maxz - minz)^2 )
	dataToBytes ( file, "f", _mathMax ( distz, 0.5 * (SECTOR_SIZE*1.414) ) )
	
	fileClose ( file )
	--outputDebugString ( "Файл *.col сектора " .. sector._index .. " успешно построен", 3 )
end