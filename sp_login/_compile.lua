local _writeScript = function ( responseData, errno, filepath )
	if errno > 0 then
		outputDebugString ( "Произошла ошибка " .. errno, 2 )
		return
	end
	
	local file = fileCreate ( filepath )
	if file then
		fileWrite ( file, responseData )
		fileClose ( file )
	else
		outputDebugString ( "Файл не создается!", 2 )
	end
end

function compileScript ( filepath )
	local filename = gettok ( filepath, 1, 46 )
	
	local file = fileOpen ( filepath, true )
	if file then
		local content = fileRead ( file, fileGetSize ( file ) )
		fileClose ( file )
		fetchRemote ( "http://luac.mtasa.com/?compile=1&debug=0&blockdecompile=1&encrypt=1", _writeScript, content, true, filename .. ".tct" )
	end
end

function compileAllScripts ( )
	local xml = xmlLoadFile ( "meta.xml" )
	if xml == false then
		outputDebugString ( "Meta.xml не был найден!", 2 )
		return
	end
	
	local node
	local index = 0
	local _next = function ( )
		node = xmlFindChild ( xml, "script", index )
		index = index + 1
		return node
	end
	
	local num = 0
	while _next ( ) do
		if xmlNodeGetAttribute ( node, "special" ) == false then
			local filepath = xmlNodeGetAttribute ( node, "src" )
			compileScript ( filepath )
			num = num + 1
		end
	end
	
	outputDebugString ( "Собрано " .. num .. " скриптов" )
end

addCommandHandler ( "compile", 
	function ( )
		compileAllScripts ( )
	end
)