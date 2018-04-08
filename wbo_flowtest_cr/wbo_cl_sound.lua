sound3D = { 
	items = { }
}

local loadedSounds = { } -- Загруженные звуки готовые к использованию
local fileSounds = { } -- Пул звуков ожидающих загрузки

function sound3D.createAndAttachTo ( filename, element, looped )
	if fileExists ( filename ) ~= true then
		return
	end
	
	if sound3D.isAttachedTo ( element ) then
		sound3D.detachFrom ( element )
	end
	
	local x, y, z = getElementPosition ( element )
	local sound = playSound3D ( filename, x, y, z, looped )
	if sound then
		setElementDimension ( sound, 
			getElementDimension ( element ) 
		)
		setElementInterior ( sound, 
			getElementInterior ( element ) 
		)
	
		setSoundMinDistance ( sound, 10 )
		setSoundMaxDistance ( sound, 100 )
		
		attachElements ( sound, element )
		sound3D.items [ element ] = sound
	
		return sound
	end
end

function sound3D.setVolume ( element, volume )
	if isElement ( sound3D.items [ element ] ) then
		volume = tonumber ( volume ) or 100
		setSoundVolume ( sound3D.items [ element ], volume / 100 )
	end
end

function sound3D.isAttachedTo ( element )
	return sound3D.items [ element ] ~= nil
end

function sound3D.detachFrom ( element )
	if isElement ( sound3D.items [ element ] ) then
		stopSound ( sound3D.items [ element ] )
	end
	sound3D.items [ element ] = nil
	
	return true
end

addModFileHandler ( 
	function ( fileType, fileId, fileName, fileChecksum )
		fileId = tonumber ( fileId )
		loadedSounds [ fileId ] = true
		
		local elements = fileSounds [ fileId ]
		if elements then
			for _, data in ipairs ( elements ) do
				sound3D.createAndAttachTo ( ":wbo_modmanager/modfiles/" .. fileChecksum, data [ 1 ], true )
				sound3D.setVolume ( element, data [ 2 ] )
			end
		end
	end
, "ogg" )

addEvent ( "onClientElementAttachSound", true )
addEventHandler ( "onClientElementAttachSound", resourceRoot,
	function ( fileId, looped, volume )
		-- Если звук уже загружен, создаем его и проигрываем
		if loadedSounds [ fileId ] then
			local file = getFileByID ( tonumber ( fileId ) )
			if file then
				sound3D.createAndAttachTo ( ":wbo_modmanager/modfiles/" .. file.checksum, source, looped )
				sound3D.setVolume ( source, volume )
			end
			
		-- В противном случае добавляем в пул
		else
			if fileSounds [ fileId ] then
				-- Если материал уже есть в пуле, выходим
				for _, element in ipairs ( fileSounds [ fileId ] ) do
					if element == source then
						return
					end
				end
				
				table.insert ( fileSounds [ fileId ], { element, volume } )
			else
				fileSounds [ fileId ] = { { element, volume } }
			end
		end
	end
)

addEvent ( "onClientElementDetachSound", true )
addEventHandler ( "onClientElementDetachSound", resourceRoot,
	function ( filename )
		sound3D.detachFrom ( source )
	end
)

addEvent ( "onClientElementVolumeSound", true )
addEventHandler ( "onClientElementVolumeSound", resourceRoot,
	function ( volume )
		sound3D.setVolume ( source, volume )
	end
)

--[[
	Принимаем звуки из комнаты
]]
addEvent ( "onClientRoomSoundPacket", true )
addEventHandler ( "onClientRoomSoundPacket", resourceRoot,
	function ( packedSounds )
		fileSounds = { }
		
		--local str = ""
		
		local soundNum = packedSounds [ 1 ]
		for i = 1, soundNum do
			local index = i * 3
			local element = packedSounds [ index - 1 ]
			local fileId = packedSounds [ index ]
			local volume = packedSounds [ index + 1 ]
			
			if fileSounds [ fileId ] then
				table.insert ( fileSounds [ fileId ], { element, volume } )
			else
				fileSounds [ fileId ] = { { element, volume } }
			end
			
			--str = str .. tostring ( element ) .. ", " .. tostring ( fileId ) .. ", " .. tostring ( volume ) .. "; "
		end
		
		--outputChatBox ( str )
	end
, false )

-- Для теста
addEvent ( "onClientPlayerRoomQuit", true )
addEventHandler ( "onClientPlayerRoomQuit", localPlayer,
	function ( room )
		local soundsNum = 0
		for element, sound in pairs ( sound3D.items ) do
			if isElement ( sound ) then
				stopSound ( sound )
				soundsNum = soundsNum + 1
			end
		end
		sound3D.items = { }
		fileSounds = { }
		outputDebugString ( "Выгружено " .. soundsNum .. " звуков" )
	end
)