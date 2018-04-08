local vehs = {
	[ "DFT30" ] = "DFT-30",
	[ "RDTRAIN" ] = "Roadtrain",
	[ "DUNERIDE" ] = "Dune",
	[ "PCJ600" ] = "PCJ-600",
	[ "MTBIKE" ] = "Mountain Bike",
	[ "RAINDANC" ] = "Raindance",
	[ "LEVIATHN" ] = "Leviathan",
	[ "AT400" ] = "AT-400",
	[ "POLMAV" ] = "Police Maverick",
	[ "SEASPAR" ] = "Seasparrow",
	[ "BLOODRA" ] = "Bloodring Banger",
	[ "SUPERGT" ] = "Super GT",
	[ "COMBINE" ] = "Combine Harvester",
	[ "ZR350" ] = "ZR-350",
	[ "BFINJECT" ] = "BF Injection",
	[ "FCR900" ] = "FCR-900",
	[ "BLISTAC" ] = "Blista Compact",
	[ "PETRO" ] = "Linerunner",
	[ "REMINGTN" ] = "Remington",
	[ "COPCARRU" ] = "Police Ranger",
	[ "MONSTERB" ] = "Monster 3",
	[ "BOXBURG" ] = "Boxville",
	[ "GREENWOO" ] = "Greenwood",
	[ "AMBULAN" ] = "Ambulance",
	[ "FIRETRUK" ] = "Fire Truck",
	[ "FIRELA" ] = "Fire Truck Ladder",
	[ "NRG500" ] = "NRG-500",
	[ "HOTRING" ] = "Hotring Racer",
	[ "MONSTERA" ] = "Monster 2",
	[ "STUNT" ] = "Stuntplane"
}

function createMapFromTxt ( filepath )
	local file = fileOpen ( filepath, true )
	if not file then
		return
	end
	
	local mapRoot = createElement ( "map" )
	
	local fileStr = fileRead ( file, fileGetSize ( file ) )
	
	for i, line in ipairs ( split ( fileStr, "\n" ) ) do
		local opcode = gettok ( line, 1, string.byte ( " " ) )
		if opcode == "014B:" then
			local lineParts = split ( line, string.byte ( " " ) )
			
			local name = gettok ( lineParts [ 5 ], 1, string.byte ( "#" ) )
			local model = getVehicleModelFromName ( name )
			if not model then
				model = getVehicleModelFromName ( vehs [ name ] )
			end
			
			if not tonumber ( lineParts [ 17 ] ) then
				outputChatBox ( lineParts [ 17 ] )
			end	
			
			local vehicle = createVehicle ( model, tonumber ( lineParts [ 17 ] ), tonumber ( lineParts [ 18 ] ), tonumber ( lineParts [ 19 ] ) + 1, 0, 0, tonumber ( lineParts [ 21 ] ) )
			setElementData ( vehicle, "model", tostring ( model ) )
			setElementData ( vehicle, "posX", lineParts [ 17 ] )
			setElementData ( vehicle, "posY", lineParts [ 18 ] )
			setElementData ( vehicle, "posZ", lineParts [ 19 ] )
			setElementData ( vehicle, "rotZ", lineParts [ 21 ] )
			setElementParent ( vehicle, mapRoot )
		elseif opcode == "09E2:" then
			local lineParts = split ( line, string.byte ( " " ) )
			
			local name = gettok ( lineParts [ 5 ], 1, string.byte ( "#" ) )
			local model = getVehicleModelFromName ( name )
			if not model then
				model = getVehicleModelFromName ( vehs [ name ] )
			end
			
			if not model then
				outputChatBox ( name )
			end
			
			local vehicle = createVehicle ( model, tonumber ( lineParts [ 18 ] ), tonumber ( lineParts [ 19 ] ), tonumber ( lineParts [ 20 ] ) + 1, 0, 0, tonumber ( lineParts [ 22 ] ) )
			setElementData ( vehicle, "model", tostring ( model ) )
			setElementData ( vehicle, "posX", lineParts [ 18 ] )
			setElementData ( vehicle, "posY", lineParts [ 19 ] )
			setElementData ( vehicle, "posZ", lineParts [ 20 ] )
			setElementData ( vehicle, "rotZ", lineParts [ 22 ] )
			setElementParent ( vehicle, mapRoot )
		end
	end
	
	local file = xmlCreateFile ( "vehicles.map", "map" )
	saveMapData ( file, mapRoot, true )
	xmlSaveFile ( file )
	xmlUnloadFile ( file )
end

--createMapFromTxt ( "cars.txt" )