local weapons = {
	[ "#MOLOTOV" ] = 18,
	[ "#SPRAYCAN" ] = 41,
	[ "#TEARGAS" ] = 17,
	[ "#FLAME" ] = 37,
	[ "#FIRE_EX" ] = 42,
	[ "#CHROMEGUN" ] = 26,
	[ "#AK47" ] = 30,
	[ "#SAWNOFF" ] = 26,
	[ "#ROCKETLA" ] = 35,
	[ "#SNIPER" ] = 34,
	[ "#M4" ] = 31,
	[ "#MP5LNG" ] = 29,
	[ "#MINIGUN" ] = 38,
	[ "#TEC9" ] = 32,
	[ "#GRENADE" ] = 16,
	[ "#SHOTGSPA" ] = 27,
	[ "#MICRO_UZI" ] = 28,
	[ "#SILENCED" ] = 23,
	[ "#HEATSEEK" ] = 36,
	[ "#COLT45" ] = 22,
	[ "#CAMERA" ] = 43,
	[ "#SATCHEL" ] = 39,
	[ "#DESERT_EAGLE" ] = 24,
	[ "#CUNTGUN" ] = 33,
	
	[ "#BRIBE" ] = 1247,
	[ "#BODYARMOUR" ] = 1242,
	
	[ "#FLOWERA" ] = 14,
	[ "#KATANA" ] = 8,
	[ "#GUN_CANE" ] = 15,
	[ "#SHOVEL" ] = 6,
	[ "#KNIFECUR" ] = 4,
	[ "#BAT" ] = 5,
	[ "#BRASSKNUCKLE" ] = 1,
	[ "#CHNSAW" ] = 9,
	[ "#GUN_PARA" ] = 46,
	[ "#NITESTICK" ] = 3,
	[ "#GUN_DILDO2" ] = 11,
	[ "#POOLCUE" ] = 7,
	[ "#GOLFCLUB" ] = 2,
	[ "#GUN_DILDO1" ] = 10
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
		if opcode == "032B:" then
			local lineParts = split ( line, string.byte ( " " ) )
			
			local pickup = createPickup ( tonumber ( lineParts [ 11 ] ), tonumber ( lineParts [ 12 ] ), tonumber ( lineParts [ 13 ] ), 
				2, weapons [ lineParts [ 5 ] ], 30000, tonumber ( lineParts [ 9 ] ) )
			setElementData ( pickup, "posX", lineParts [ 11 ] )
			setElementData ( pickup, "posY", lineParts [ 12 ] )
			setElementData ( pickup, "posZ", lineParts [ 13 ] )
			setElementData ( pickup, "type", tostring ( weapons [ lineParts [ 5 ] ] ) )
			setElementData ( pickup, "amount", lineParts [ 9 ] )
			setElementParent ( pickup, mapRoot )
		else
			local codepart = gettok ( line, 2, string.byte ( "(" ) )
			codepart = gettok ( codepart, 1, string.byte ( ")" ) )
			
			local lineParts = split ( codepart, ", " )
			
			if lineParts [ 1 ] == "#BODYARMOUR" then
				local pickup = createPickup ( tonumber ( lineParts [ 3 ] ), tonumber ( lineParts [ 4 ] ), tonumber ( lineParts [ 5 ] ), 1, 0 )
				setElementData ( pickup, "posX", lineParts [ 3 ] )
				setElementData ( pickup, "posY", lineParts [ 4 ] )
				setElementData ( pickup, "posZ", lineParts [ 5 ] )
				setElementData ( pickup, "type", "armor" )
				setElementData ( pickup, "amount", "100" )
				setElementParent ( pickup, mapRoot )
			elseif lineParts [ 1 ] == "#BRIBE" then
				
			else
				local pickup = createPickup ( tonumber ( lineParts [ 3 ] ), tonumber ( lineParts [ 4 ] ), tonumber ( lineParts [ 5 ] ), 
					2, weapons [ lineParts [ 1 ] ] )
				setElementData ( pickup, "posX", lineParts [ 3 ] )
				setElementData ( pickup, "posY", lineParts [ 4 ] )
				setElementData ( pickup, "posZ", lineParts [ 5 ] )
				setElementData ( pickup, "type", tostring ( weapons [ lineParts [ 1 ] ] ) )
				setElementData ( pickup, "amount", "1" )
				setElementParent ( pickup, mapRoot )
			end
		end
	end
	
	local file = xmlCreateFile ( "weapons.map", "map" )
	saveMapData ( file, mapRoot, true )
	xmlSaveFile ( file )
	xmlUnloadFile ( file )
end

--createMapFromTxt ( "weapons.txt" )