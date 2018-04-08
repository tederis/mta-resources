local sw, sh = guiGetScreenSize ( )

EnvEditor = { }

function EnvEditor.defineLine ( name )
	EnvEditor.shaders_ [ name ] = { }
	
	for i, env in ipairs ( xrEnvironment.currentWeather ) do
		local shader = dxCreateShader ( "shaders/gradient.fx" )
		if i > 1 then
			local prevEnv = xrEnvironment.currentWeather [ i - 1 ]
			dxSetShaderValue ( shader, "startColor", prevEnv[name].x, prevEnv[name].y, prevEnv[name].z, 1 )
		else
			dxSetShaderValue ( shader, "startColor", env[name].x, env[name].y, env[name].z, 1 )
		end
		dxSetShaderValue ( shader, "endColor", env[name].x, env[name].y, env[name].z, 1 )
		
		EnvEditor.shaders_ [ name ][ i ] = shader
	end
end

function EnvEditor.open ( )
	if xrEnvironment.currentWeather == nil then
		outputDebugString ( "Не было найдено текущей погоды", 2 )
		return
	end
	
	EnvEditor.shaders_ = { }
	
	EnvEditor.defineLine ( "ambient" )
	EnvEditor.defineLine ( "hemiColor" )
	EnvEditor.defineLine ( "sunColor" )

	addEventHandler ( "onClientRender", root, EnvEditor.onRender, false )
end

function EnvEditor.onRender ( )
	if xrEnvironment.currentWeather == nil then
		return
	end

	local lineY = sh / 2
	local lineWidth = sw / #xrEnvironment.currentWeather
	local lineHeight = 50
	
	for i, env in ipairs ( xrEnvironment.currentWeather ) do
		local lineX = (i-1) * lineWidth
		dxDrawImage ( lineX, lineY, lineWidth, lineHeight, EnvEditor.shaders_.ambient [ i ] )
		dxDrawImage ( lineX, lineY + lineHeight, lineWidth, lineHeight, EnvEditor.shaders_.hemiColor [ i ] )
		dxDrawImage ( lineX, lineY + lineHeight*2, lineWidth, lineHeight, EnvEditor.shaders_.sunColor [ i ] )
		
		dxDrawText ( i, lineX, lineY )
	end
	
	local time = getEnvironmentGameDayTimeSec ( 1000 )
	local weight = time / 86400
	
	dxDrawRectangle ( sw * weight - 10, lineY - 10, 20, lineHeight*3 + 20, tocolor ( 0, 0, 200, 150 ) )
end