local mysqldb

g_PlayerFiles = { }
g_ModData = { }
g_NameMod = { }
g_Files = { }

local onDBFilesLoad = function ( qh )
	local files = dbPoll ( qh, -1 )
	local loadedFilesNum = 0
	for _, row in ipairs ( files ) do
		local modId = tonumber ( row.mod_id )
		local modData = g_ModData [ modId ]
		if modData then
			local fileSize = tonumber ( row.size ) or 0
			local id = tonumber ( row.id )
			local modFile = {
				id = id,
				model = tonumber ( row.model ),
				type = row.type,
				name = row.name,
				checksum = row.checksum,
				size = fileSize
			}
			modData.files [ #modData.files + 1 ] = modFile
			modData.files [ row.name ] = modFile
			modData.size = modData.size + fileSize
			g_Files [ id ] = modFile
			
			--outputDebugString ( "Добавлен файл " .. row.name )
			
			loadedFilesNum = loadedFilesNum + 1
		end
	end
	
	setTimer ( sendModsToClients, 1000, 1 )
	
	outputDebugString ( "Успешно загружено " .. loadedFilesNum .. " файлов." )
end
local onDBModsLoad = function ( qh )
	local mods = dbPoll ( qh, -1 )
	for _, row in ipairs ( mods ) do
		local modId = tonumber ( row.id )
		local mod = {
			id = modId,
			name = row.name,
			size = 0,
			files = { }
		}
		
		g_ModData [ modId ] = mod
		g_NameMod [ row.name ] = mod
	end
	
	dbQuery ( onDBFilesLoad, mysqldb, "SELECT * FROM files" )
	
	outputDebugString ( "Успешно загружено " .. #mods .. " модов." )
end
addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		if LOCALHOST then
			mysqldb = dbConnect ( "mysql", "dbname=modmanager;host=" .. MM_HOST, MM_USER )
		else
			mysqldb = dbConnect ( "mysql", "dbname=modmanager;host=" .. MM_HOST, MM_USER, MM_PASS )
		end
		if mysqldb then
			dbQuery ( onDBModsLoad, mysqldb, "SELECT * FROM mods" )
		end
	end
, false )

addEventHandler ( "onPlayerRoomJoin", root,
	function ( room )
		loadPlayerMods ( source, room )
	end
)

addEventHandler ( "onPlayerRoomQuit", root,
	function ( room )
		unloadPlayerMods ( source, room )
	end
)

function loadPlayerMods ( player, room )
	g_PlayerFiles [ player ] = { }
	
	local packedMods = { 
		--room
	}
	
	local modsNum = 0
	local filesNum = 0
	
	local roomMods = getElementsByType ( "mod", room )
	for _, mod in ipairs ( roomMods ) do
		local modId = tonumber ( getElementData ( mod, "name", false ) )
		local modData = g_ModData [ modId ]
		if modData then
			local packedMod = {
				[ 1 ] = modId,
				[ 2 ] = modData.name,
				[ 3 ] = modData.size,
				[ 4 ] = { } -- files
			}
				
			--outputDebugString ( #modData.files .. " файлов в моде " .. modData.name )
				
			for i = 1, #modData.files do
				local file = modData.files [ i ]
				local packedFile = {
					file.model,
					file.type,
					file.checksum,
					file.name,
					file.id
				}
					
				filesNum = filesNum + 1
					
				packedMod [ 4 ] [ #packedMod [ 4 ] + 1 ] = packedFile
			end
				
			packedMods [ #packedMods + 1 ] = packedMod
				
			modsNum = modsNum + 1
		end
	end
		
	--outputDebugString ( "Отправляем игроку " .. getPlayerName ( source ) .. " " .. filesNum .. " файлов из " .. modsNum .. " модов" )
		
	triggerClientEvent ( player, "onClientSendModData", resourceRoot, packedMods )
end

function unloadPlayerMods ( player, room )
	local playerFiles = g_PlayerFiles [ player ]
	if playerFiles then
		for i = 1, #playerFiles do
			local status = getLatentEventStatus ( player, playerFiles [ i ] [ 1 ] )
			if status and status.percentComplete < 100 then
				cancelLatentEvent ( player, playerFiles [ i ] [ 1 ] )
				outputDebugString ( "Отменена передача файла " .. tostring ( playerFiles [ i ] [ 1 ] ) )
			end
		end
	
		triggerClientEvent ( player, "doClientUnloadMods", resourceRoot )
	end
	g_PlayerFiles [ player ] = nil
end


--TEST ONLY!
addCommandHandler ( "reloadmods",
	function ( player )
		local room = getElementData ( player, "room", false )
		if room then
			unloadPlayerMods ( player, room )
			setTimer ( loadPlayerMods, 1000, 1, player, room )
			outputChatBox ( "Подождите пока идет отправка списка модов...", player )
		end
	end
)







function isPlayerInRoom ( player, room )
	local playerDimension = getElementDimension ( player )
	local roomDimension = getElementData ( room, "dimension", false )
	return playerDimension == tonumber ( roomDimension )
end

function getPlayerRoom ( player )
	local dimension = getElementDimension ( player )
	local rooms = getElementsByType ( "room" )
	for i = 1, #room do
		local roomDim = getElementData ( rooms [ i ], "dimension", false )
		if tonumber ( roomDim ) == dimension then
			return rooms [ i ]
		end
	end
end

setTimer (
	function ( )
		for player, handles in pairs ( g_PlayerFiles ) do
			local lastHandle = handles [ 1 ]
			if lastHandle then
				local status = getLatentEventStatus ( player, lastHandle [ 1 ] )
				if status then
					triggerClientEvent ( player, "onModTransferStatus", resourceRoot, lastHandle [ 2 ], status.percentComplete )
				else
					triggerClientEvent ( player, "onModTransferStatus", resourceRoot, lastHandle [ 2 ], 100 )
					table.remove ( handles, 1 )
				end
			end
		end
	end
, 1000, 0 )

addEvent ( "onPlayerModData", true )
addEventHandler ( "onPlayerModData", root,
	function ( modId, fileId )
		local modData = g_ModData [ modId ]
		if modData then
			local modFile = modData.files [ fileId ]
			if modFile then
				local file = fileOpen ( "modfiles/" .. modFile.checksum )
				if file then
					local fileContent = fileRead ( file, fileGetSize ( file ) )
					fileClose ( file )
					if triggerLatentClientEvent ( client, "onClientReceiveFile", 200000, false, resourceRoot, modFile.checksum, fileContent ) then
						local handles = getLatentEventHandles ( client )
						local lastHandle = handles [ #handles ]
						local playerFiles = g_PlayerFiles [ client ]
						playerFiles [ #playerFiles + 1 ] = { lastHandle, modId }
						outputDebugString ( "Файл " .. modFile.name .. " отправлен игроку " .. getPlayerName ( client ) )
					else
						outputDebugString ( "При отправке файла " .. modFile.name .. " игроку " .. getPlayerName ( client ) .. " обнаружена проблема" )
					end
				end
			end
		end
	end
)

local function packMod ( modData )
	local packedMod = {
		tonumber ( modData.id ), modData.name
	}
	return packedMod
end

function sendModsToClients ( )
	local packedMods = { }
	for id, modData in pairs ( g_ModData ) do
		local packedMod = packMod ( modData )
		packedMods [ #packedMods + 1 ] = packedMod
	end
	
	triggerClientEvent ( "onClientModsLoad", resourceRoot, packedMods )
	-- Когда информация о модах была отправлена клиентам, говорим конструктору что ресурс загружен
	setTimer ( function ( ) g_Ready = true; end, 1000, 1 )
end

addEventHandler ( "onPlayerJoin", root,
	function ( )
		local packedMods = { }
		for id, modData in pairs ( g_ModData ) do
			local packedMod = packMod ( modData )
			packedMods [ #packedMods + 1 ] = packedMod
		end
		
		triggerClientEvent ( source, "onClientModsLoad", resourceRoot, packedMods )
	end
)

--[[
	Web
]]
function onWebModCreate ( modId, modName, owner )
	modId = tonumber ( modId )
	g_ModData [ modId ] = {
		id = modId,
		name = modName,
		size = 0,
		owner = owner,
		files = { }
	}
	
	local packedMod = packMod ( g_ModData [ modId ] )
	triggerEvent ( "onModCreate", root, packedMod )
	triggerClientEvent ( "onClientModCreate", root, packedMod )
	
	outputDebugString ( "Добавлен новый мод " .. modName )
end

function onWebModDestroy ( modId )
	modId = tonumber ( modId )
	g_ModData [ modId ] = nil
	
	triggerEvent ( "onModDestroy", root, modId )
	triggerClientEvent ( "onClientModDestroy", root, modId )
	
	outputDebugString ( "Удален мод " .. modId )
end

function onWebFileCreate ( fileId, modId, fileName, model, fileType, fileMD5, fileSize )
	modId = tonumber ( modId )
	local modData = g_ModData [ modId ]
	if modData then
		fileSize = tonumber ( fileSize ) or 0
		local id = tonumber ( fileId )
		local modFile = {
			id = id,
			model = tonumber ( model ),
			type = fileType,
			name = fileName,
			checksum = fileMD5,
			size = fileSize
		}
		modData.files [ #modData.files + 1 ] = modFile
		modData.size = modData.size + fileSize
		g_Files [ id ] = modFile
		
		outputDebugString ( "Добавлен новый файл " .. tostring ( fileName ) .. " для мода " .. tostring ( modId ) )
	end
end

function onWebFileDestroy ( modId, fileId )
	modId = tonumber ( modId )
	local modData = g_ModData [ modId ]
	if modData then
		fileId = tonumber ( fileId )
		for i = 1, #modData.files do
			local fileData = modData.files [ i ]
			if fileData.id == fileId then
				table.remove ( modData.files, i )
				outputDebugString ( "Удален файл из мода " .. modId )
				break
			end
		end
	end
end

--[[
	Export
]]
function isReady ( )
	return g_Ready == true
end

function getAvailableMods ( )
	local mods = { }
	
	for id, modData in pairs ( g_ModData ) do
		mods [ #mods + 1 ] = { id, modData.name }
	end
	
	return mods
end

function isModValid ( id )
	return g_ModData [ id ] ~= nil
end

function getModFileChecksum ( modName, fileName )
	local mod = g_NameMod [ modName ]
	if mod then
		local modFile = mod.files [ fileName ]
		if modFile then return modFile.checksum end;
	end
end

function getFileType ( id )
	local modFile = g_Files [ tonumber ( id ) ]
	if modFile then
		return modFile.type
	end
end

function getFileChecksum ( id )
	local modFile = g_Files [ tonumber ( id ) ]
	if modFile then
		return modFile.checksum
	end
end