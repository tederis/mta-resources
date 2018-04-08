g_LoadedMods = { }
g_NameMods = { }

g_Files = { }

local _modFiles = {
	"texture.txd",
	"collision.col",
	"model.dff"
}
--[[
	Принимает файл мода
]]
addEvent ( "onClientReceiveFile", true )
addEventHandler ( "onClientReceiveFile", resourceRoot,
	function ( checksum, fileContent )
		local file = fileCreate ( "modfiles/" .. checksum )
		if file then
			fileWrite ( file, fileContent )
			fileClose ( file )
			
			outputDebugString ( "Файл мода " .. checksum .. " успешно принят и сохранен" )
		end
	end
, false )

local checkTimer
function _checkModFiles ( )
	local startedModsNum = 0
	local modsNum = 0
	for _, mod in ipairs ( g_LoadedMods ) do
		if mod.disabled ~= true then
			local filesOK = 0
			for _, file in ipairs ( mod.files ) do
				local filePath = "modfiles/" .. file.checksum
				if fileExists ( filePath ) then
					filesOK = filesOK + 1
				end
			end
			
			if filesOK == #mod.files then
				mod:start ( )
				startedModsNum = startedModsNum + 1
			end
			modsNum = modsNum + 1
		end
	end
	
	if startedModsNum == modsNum then
		killTimer ( checkTimer )
		checkTimer = nil
		outputDebugString ( "Загружено " .. modsNum .. " модов" )
	end
end

local _onModsApply = function ( )
	-- На всякий случай проверяем комнату игрока
	--[[if getElementData ( localPlayer, "room", false ) ~= g_Room then
		return
	end]]

	local receiveNum = 0
	-- Запрашиваем файлы, которых у нас нет
	for _, mod in ipairs ( g_LoadedMods ) do
		if mod.disabled ~= true then
			for i, file in ipairs ( mod.files ) do
				local filePath = "modfiles/" .. file.checksum
				if not fileExists ( filePath ) then
					triggerServerEvent ( "onPlayerModData", resourceRoot, mod.id, i )
					mod.status = "receiving"
					receiveNum = receiveNum + 1
				end
			end
		end
	end
	
	outputDebugString ( "Запрошено " .. receiveNum .. " файлов " )
	
	if checkTimer == nil then
		checkTimer = setTimer ( _checkModFiles, 1000, 0 )
	end
end
--[[
	Принимает список доступных модов
]]
addEvent ( "onClientSendModData", true )
addEventHandler ( "onClientSendModData", root,
	function ( packedMods )
		--[[local room = packedMods [ 1 ]
		if getElementData ( localPlayer, "room", false ) ~= room then
			return
		end
		g_Room = room]]
	
		for i = 1, #packedMods do
			local packedMod = packedMods [ i ]
			local mod = ClientMod.new ( 
				packedMod [ 2 ], 
				packedMod [ 1 ], 
				packedMod [ 3 ] 
			)
			g_LoadedMods [ i ] = mod
			g_NameMods [ packedMod [ 2 ] ] = mod
			
			local files = { }
			for n = 1, #packedMod [ 4 ] do
				local packedFile = packedMod [ 4 ] [ n ]
				local id = tonumber ( packedFile [ 5 ] )
				
				local modFile = mod:addFile ( 
					packedFile [ 1 ], 
					packedFile [ 2 ], 
					packedFile [ 3 ],
					packedFile [ 4 ],
					id
				)
				
				g_Files [ id ] = modFile
			end
		end
		
		if #g_LoadedMods > 0 then
			ModSelect.open ( _onModsApply )
		end
	end
)

ClientMod = { }
ClientMod.__index = ClientMod

function ClientMod.new ( name, id, size )
	local mod = {
		name = name,
		id = id,
		size = size,
		files = { },
		status = "waiting"
	}
	
	return setmetatable ( mod, ClientMod )
end

function ClientMod:addFile ( model, type, checksum, name, id )
	local file = {
		model = model,
		type = type,
		checksum = checksum,
		name = name,
		id = id
	}
	self.files [ #self.files + 1 ] = file
	self.files [ name ] = file
	
	return file
end

function ClientMod:start ( )
	if self.started ~= true then
		outputDebugString ( "Мод " .. self.name .. " запускается..." )
	
		self.status = "starting"
		self:loadFiles ( )
		self.started = true
		self.status = "started"
	end
end

function ClientMod:stop ( )
	if self.started then
		outputDebugString ( "Мод " .. self.name .. " останавливается..." )
	
		self:unloadFiles ( )
		self.started = nil
	end
end

local typeWeights = {
	-- GTA
	txd = 0,
	col = 1,
	dff = 2,
	-- Звуки
	ogg = 3,
	wav = 3,
	mp3 = 3,
	-- Текстуры
	dds = 3,
	jpg = 3
}
local _sortFn = function ( a, b )
	return typeWeights [ a.type ] < typeWeights [ b.type ]
end
function ClientMod:loadFiles ( )
	outputDebugString ( "Пытаемся загрузить " .. #self.files .. " GTA файлов" )
	
	table.sort ( self.files, _sortFn )

	for _, file in ipairs ( self.files ) do
		if file.type == "txd" then
			local txd = engineLoadTXD ( "modfiles/" .. file.checksum )
			if txd then
				engineImportTXD ( txd, file.model )
				file.element = txd
			end
		elseif file.type == "col" then
			local col = engineLoadCOL ( "modfiles/" .. file.checksum )
			if col then
				engineReplaceCOL ( col, file.model )
				file.element = col
			end
		elseif file.type == "dff" then
			local dff = engineLoadDFF ( "modfiles/" .. file.checksum, file.model )
			if dff then
				engineReplaceModel ( dff, file.model )
				file.element = dff
			end
		end
		
		triggerEvent ( "onModFileLoaded", root, file.type, file.id, file.name, file.checksum )
		
		if isElement ( file.element ) then
			outputDebugString ( getElementType ( file.element ) .. " loaded" )
		else
			--outputDebugString ( "При замене файла с типом " .. file.type .. " произошла ошибка" )
		end
	end
end

function ClientMod:unloadFiles ( )
	for _, file in ipairs ( self.files ) do
		if file.type == "txd" then
		elseif file.type == "col" then
			engineRestoreCOL ( file.model )
		elseif file.type == "dff" then
			engineRestoreModel ( file.model )
		end
		if isElement ( file.element ) then
			outputDebugString ( getElementType ( file.element ) .. " unloaded" )
			destroyElement ( file.element )
		end
	end
end

--[[
	Выгружает все моды
]]
addEvent ( "doClientUnloadMods", true )
addEventHandler ( "doClientUnloadMods", resourceRoot,
	function ( )
		if isTimer ( checkTimer ) then
			killTimer ( checkTimer )
		end
	
		for i, mod in ipairs ( g_LoadedMods ) do
			mod:stop ( )
			g_LoadedMods [ i ] = nil
		end
		g_LoadedMods = { }
	end
, false )




local _mods = { }
local _modsIndexed = { }

addEvent ( "onClientModCreate", true )
addEventHandler ( "onClientModCreate", root,
	function ( packedMod )
		_mods [ packedMod [ 1 ] ] = packedMod [ 2 ]
		_modsIndexed [ #_modsIndexed + 1 ] = { packedMod [ 1 ], packedMod [ 2 ] }
	end
, false )

addEvent ( "onClientModDestroy", true )
addEventHandler ( "onClientModDestroy", root,
	function ( modId )
		_mods [ modId ] = nil
		for i = 1, #_modsIndexed do
			if _modsIndexed [ i ] [ 1 ] == modId then
				table.remove ( _modsIndexed, i )
			end
		end
	end
, false )

addEvent ( "onClientModsLoad", true )
addEventHandler ( "onClientModsLoad", resourceRoot,
	function ( packedMods )
		local dbModsNum = 0 -- DEBUG
		for _, packedMod in ipairs ( packedMods ) do
			local modId = packedMod [ 1 ]
			local modName = packedMod [ 2 ]
		
			_mods [ modId ] = modName
			_modsIndexed [ #_modsIndexed + 1 ] = { modId, modName }
			
			dbModsNum = dbModsNum + 1
		end
		
		outputDebugString ( "TCT Debug: WMM_CLIENT: Получено " .. dbModsNum .. " описаний для модов", 0 )
	end
, false )

--[[
	Export
]]
function getAvailableMods ( )
	return _modsIndexed
end
function getModsInRoom ( room )
	local mods = { }
	local elements = getElementsByType ( "mod", room )
	for _, element in ipairs ( elements ) do
		local modId = tonumber ( getElementData ( element, "name", false ) )
		local modName = _mods [ modId ]
		if modName then
			mods [ #mods + 1 ] = { modId, modName }
		end
	end
	
	return mods
end

function getLoadedMods ( )
	local loadedMods = { }

	for _, mod in ipairs ( g_LoadedMods ) do
		local modFiles = { }
		for _, file in ipairs ( mod.files ) do
			table.insert ( modFiles, { name = file.name, type = file.type, id = file.id, checksum = checksum } )
		end
		table.insert ( loadedMods, { files = modFiles, name = mod.name, id = mod.id } )
	end
	
	return loadedMods
end

function modFilesList ( ... )
	local args = { ... }
	local modFiles = { }
	for _, mod in ipairs ( g_LoadedMods ) do
		if mod.disabled ~= true then
			for _, file in ipairs ( mod.files ) do
				for i = 1, #args do
					if file.type == args [ i ] then
						table.insert ( modFiles, { file.checksum, file.name, file.id } )
					end
				end
			end
		end
	end
	
	return modFiles
end

function getChecksumByID ( id )
	local modFile = g_Files [ tonumber ( id ) ]
	if modFile then
		return modFile.checksum
	end
end

function getFileName ( id )
	local modFile = g_Files [ tonumber ( id ) ]
	if modFile then
		return modFile.name
	end
end