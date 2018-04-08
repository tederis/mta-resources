local g_Obj
local g_Shader

DEBUG = true
COP_GAME = true

DAY_LENGTH = 86400

--[[
	xrEnvironment
]]
xrEnvironment = { 
	weatherCycles = { } -- Временные циклы для каждой погоды
}

function xrEnvironment.new ( )
	xrEnvironment.currentEnv = xrEnvDescriptor.new ( ) -- Миксер
	
	local txd = engineLoadTXD ( "models/skybox.txd" )
	local col = engineLoadCOL ( "models/skybox.col" )
	local dff = engineLoadDFF ( "models/skybox.dff", 0 )
		
	engineImportTXD ( txd, 3001 )
	engineReplaceCOL ( col, 3001 )
	engineReplaceModel ( dff, 3001, true )
	
	local x, y, z = getCameraMatrix ( )
	xrEnvironment.skyObj = createObject ( 3001, x, y, z )
	setElementDoubleSided ( xrEnvironment.skyObj, true )
	setObjectScale ( xrEnvironment.skyObj, 299 )

	xrEnvironment.skyShader = dxCreateShader ( "shaders/default.fx" )
		
	engineApplyShaderToWorldTexture ( xrEnvironment.skyShader, "_Textur2_", xrEnvironment.skyObj )
end

function xrEnvironment.timeDiff ( prev, cur )
	if prev > cur then 
		return ( DAY_LENGTH - prev ) + cur
	else
		return	cur - prev
	end
end

function xrEnvironment.timeWeight ( val, min_t, max_t )
	local weight = 0
	local length = xrEnvironment.timeDiff ( min_t, max_t )
	if length > 0 then
		if min_t > max_t then
			if val >= min_t or val <= max_t then weight = xrEnvironment.timeDiff ( min_t, val ) / length end
		else
			if val >= min_t and val <= max_t then weight = xrEnvironment.timeDiff ( min_t, val ) / length end
		end
		weight = math.clamp ( 0, weight, 1 )
	end
	return weight
end

function xrEnvironment.load ( )
	local cycles = xrEnvironment.weatherCycles
	
	local _sortFn = function ( a, b )
		return a.execTimeLoaded < b.execTimeLoaded
	end

	local firstWeatherName
	for wName, wSectionName in pairs ( gSettings.sections [ "weathers" ].items ) do
		local wSection = gSettings.sections [ wSectionName ]
		if wSection then
			firstWeatherName = wName
			cycles [ wName ] = { }
			for execTime, envName in pairs ( wSection.items ) do
				local envSection = gSettings.sections [ envName ]
				local envDesc = xrEnvDescriptor.new ( )
				envDesc:load ( execTime, envSection )
				table.insert ( cycles [ wName ], envDesc )
			end
			table.sort ( cycles [ wName ], _sortFn )
		else
			outputDebugString ( "Не была найдена секция погоды " .. wSectionName )
		end
	end
	xrEnvironment.setWeather ( firstWeatherName )
end

function xrEnvironment.setWeather ( weatherName )
	local weather = xrEnvironment.weatherCycles [ weatherName ]
	if weather then
		xrEnvironment.currentWeather = weather
		outputDebugString ( "Установлена погода " .. weatherName )
	else
		outputDebugString ( "Погода с именем " .. weatherName .. " не была найдена", 2 )
	end
end

function xrEnvironment.setGameTime ( time )
	xrEnvironment.gameTime = time
end

function xrEnvironment.selectEnvs ( gt )
	if xrEnvironment.envStart == nil or xrEnvironment.envEnd == nil then
		local index
		for i, env in ipairs ( xrEnvironment.currentWeather ) do
			if env.execTime > gt then
				index = i
				break
			end
		end
		if index ~= nil then
			xrEnvironment.envEnd = xrEnvironment.currentWeather [ index ]
			xrEnvironment.envStart = xrEnvironment.currentWeather [ index - 1 ]
		else
			xrEnvironment.envEnd = xrEnvironment.currentWeather [ 1 ]
			xrEnvironment.envStart = xrEnvironment.currentWeather [ #xrEnvironment.currentWeather ]
		end
		xrEnvironment.envStart:onLoad ( )
		xrEnvironment.envEnd:onLoad ( )
	else
		local select = false
		if xrEnvironment.envStart.execTime > xrEnvironment.envEnd.execTime then
			select = gt > xrEnvironment.envEnd.execTime and gt < xrEnvironment.envStart.execTime
		else
			select = gt > xrEnvironment.envEnd.execTime
		end
		
		if select then
			xrEnvironment.envStart:onUnload ( )
			xrEnvironment.envStart = xrEnvironment.envEnd
			local index
			for i, env in ipairs ( xrEnvironment.currentWeather ) do
				if env.execTime > gt then
					index = i
					break
				end
			end
			if index ~= nil then
				xrEnvironment.envEnd = xrEnvironment.currentWeather [ index ]
			else
				xrEnvironment.envEnd = xrEnvironment.currentWeather [ 1 ]
			end
			xrEnvironment.envEnd:onLoad ( )
		end
	end
end

local rot = 0
function xrEnvironment.update ( )
	-- Замораживаем SA время
	setTime ( 0, 0 )
	setSkyGradient ( 0, 0, 0, 0, 0, 0 )
	setSunColor ( 0, 0, 0, 0, 0, 0 )
	setMoonSize ( 0 )
	setHeatHaze ( 0 )
	setSunSize ( 0 )
	setCloudsEnabled ( false )
	setBirdsEnabled ( false )
	
	
	local x, y, z = getCameraMatrix ( )
	setElementPosition ( xrEnvironment.skyObj, x, y, z, false )

	xrEnvironment.selectEnvs ( xrEnvironment.gameTime )
	
	local weight = xrEnvironment.timeWeight ( xrEnvironment.gameTime, xrEnvironment.envStart.execTime, xrEnvironment.envEnd.execTime )
	
	xrEnvironment.currentEnv:lerp ( xrEnvironment.envStart, xrEnvironment.envEnd, weight )
	
	dxSetShaderValue ( xrEnvironment.skyShader, "tSkyTex0", xrEnvironment.envStart.skyTexture )
	dxSetShaderValue ( xrEnvironment.skyShader, "tSkyTex1", xrEnvironment.envEnd.skyTexture )
	dxSetShaderValue ( xrEnvironment.skyShader, "vecColor", xrEnvironment.currentEnv.skyColor.x, xrEnvironment.currentEnv.skyColor.y, xrEnvironment.currentEnv.skyColor.z )
	dxSetShaderValue ( xrEnvironment.skyShader, "fFactor", weight )
	
	setFogDistance ( xrEnvironment.currentEnv.fogDistance ) 
	setFarClipDistance ( xrEnvironment.currentEnv.farPlane )
	
	setElementRotation ( xrEnvironment.skyObj, 0, 0, math.deg ( xrEnvironment.currentEnv.skyRotation ) + rot )
	rot = rot + 0.01
end

--[[
	xrEnvDescriptor
]]
xrEnvDescriptor = { }
xrEnvDescriptorMT = { __index = xrEnvDescriptor }

function xrEnvDescriptor.new ( )
	local desc = { 
		execTime 			= 0,
		execTimeLoaded 		= 0,
	
		cloudsColor 		= Vector4 ( 1, 1, 1, 1 ),
		skyColor 			= Vector3 ( 1, 1, 1 ),
		skyRotation 		= 0,

		farPlane 			= 400,

		fogColor 			= Vector3 ( 1, 1, 1 ),
		fogDensity 			= 0,
		fogDistance 		= 400,

		rainDensity 		= 0,
		rainColor 			= Vector3 ( 0, 0, 0 ),

		boltPeriod 			= 0,
		boltDuration		= 0,

		windVelocity 		= 0,
		windDirection		= 0,
    
		ambient 			= Vector3 ( 0, 0, 0 ),
		hemiColor 			= Vector4 ( 1, 1, 1, 1 ),
		sunColor 			= Vector3 ( 1, 1, 1 ),
		sunDir				= Vector3 ( 0, -1, 0 ),

		lensFlareId			= -1,
		tbId				= -1
	}
	
	return setmetatable ( desc, xrEnvDescriptorMT )
end

function xrEnvDescriptor:load ( timeStr, section )
	if section == nil then
		outputChatBox(timeStr)
	end

	local tx = gettok ( timeStr, 1, ":" )
	local ty = gettok ( timeStr, 2, ":" )
	local tz = gettok ( timeStr, 3, ":" )
	local time = Vector3 ( tonumber ( tx ), tonumber ( ty ), tonumber ( tz ) )
	if time.x < 0 or time.x >= 24 or time.y < 0 or time.y >= 60 or time.z < 0 or time.z >= 60 then
		outputDebugString ( "Некорректное погодное время: " .. execTime, 1 )
		return
	end
	if DEBUG then self.timeStr = timeStr end;
	
	self.execTime = time.x*3600 + time.y*60 + time.z
	self.execTimeLoaded = self.execTime
	self.skyTextureName = section:readString ( "sky_texture" )
	self.skyTextureEnvName = self.skyTextureName .. "+small"
	self.cloudsTextureName = section:readString ( "clouds_texture" )
	self.cloudsColor = section:readVector4 ( "clouds_color" )
	local multiplier = tonumber ( gettok ( section:readString ( "clouds_color" ), 5, "," ) ) or 0
	local wsave = self.cloudsColor.w; self.cloudsColor = self.cloudsColor * ( 0.5 * multiplier ); self.cloudsColor.w = wsave
	self.skyColor = section:readVector3 ( "sky_color" ) * 0.5
	if section.items [ "sky_rotation" ] ~= nil then
		self.skyRotation = math.rad ( section:readNumber ( "sky_rotation" ) )
	else
		self.skyRotation = 0
	end
	self.farPlane = section:readNumber ( "far_plane" )
	self.fogColor = section:readVector3 ( "fog_color" )
	self.fogDensity = section:readNumber ( "fog_density" )
	self.fogDistance = section:readNumber ( "fog_distance" )
	self.rainDensity = math.clamp ( 0, section:readNumber ( "rain_density" ), 1 )
	self.rainColor = section:readVector3 ( "rain_color" )
	self.windVelocity = section:readNumber ( "wind_velocity" )
	self.windDirection = math.rad ( section:readNumber ( "wind_direction" ) )
	self.ambient = section:readVector3 ( section.ver == "cop" and "ambient_color" or "ambient" )
	self.hemiColor = section:readVector4 ( section.ver == "cop" and "hemisphere_color" or "hemi_color" )
	self.sunColor = section:readVector3 ( "sun_color" )
	local sunDir
	if section.ver == "cop" then
		sunDir = Vector2 ( 
			
			section:readNumber ( "sun_longitude" ),
			section:readNumber ( "sun_altitude" )
		)
	else
		sunDir = section:readVector2 ( "sun_dir" )
	end
	setVector3HP ( self.sunDir, math.rad ( sunDir.y ), math.rad ( sunDir.x ) )
	outputChatBox(self.sunDir.x .. ", " .. self.sunDir.y .. ", " .. self.sunDir.z )
	if self.sunDir.y >= 0 then
		outputDebugString ( "Некорректное направление солнца", 2 )
	end
end

function xrEnvDescriptor:lerp ( envA, envB, f )
	local fi = 1 - f

	self.cloudsColor:lerp ( envA.cloudsColor, envB.cloudsColor, f )
	self.skyRotation = fi*envA.skyRotation + f*envB.skyRotation
	self.farPlane = ( fi*envA.farPlane + f*envB.farPlane + 0 )*2*1
	self.fogColor:lerp ( envA.fogColor, envB.fogColor, f )
	self.fogDensity = (fi*envA.fogDensity + f*envB.fogDensity + 0)*1
	self.fogDistance = fi*envA.fogDistance + f*envB.fogDistance
	--self.fogNear
	--self.fogFar
	self.rainDensity = fi*envA.rainDensity + f*envB.rainDensity
	self.rainColor:lerp ( envA.rainColor, envB.rainColor, f )
	self.boltPeriod = fi*envA.boltPeriod + f*envB.boltPeriod
	self.boltDuration = fi*envA.boltDuration + f*envB.boltDuration
	
	self.windVelocity = fi*envA.windVelocity + f*envB.windVelocity
	self.windDirection = fi*envA.windDirection + f*envB.windDirection
	
	self.skyColor:lerp ( envA.skyColor, envB.skyColor, f )
	self.ambient:lerp ( envA.ambient, envB.ambient, f )
	self.hemiColor:lerp ( envA.hemiColor, envB.hemiColor, f )
	self.sunColor:lerp ( envA.sunColor, envB.sunColor, f )
	self.sunDir:lerp ( envA.sunDir, envB.sunDir, f )
	if self.sunDir.y > 0 then
		outputDebugString ( "Некорректное направление солнца", 2 )
	end
end

function xrEnvDescriptor:onLoad ( )
	if DEBUG then
		outputDebugString ( self.timeStr .. " loaded" )
	end
	
	self.skyTexture = dxCreateTexture ( self.skyTextureName .. ".dds" )
end

function xrEnvDescriptor:onUnload ( )
	if DEBUG then
		outputDebugString ( self.timeStr .. " unloaded" )
	end
	
	destroyElement ( self.skyTexture )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		gSettings = xrSettings.new ( "config\\system.ltx" )
		
		xrEnvironment.new ( )
		
		xrEnvironment.load ( )
		
		if COP_GAME then
			xrEnvironment.setWeather ( "cop_default" )
		else
			xrEnvironment.setWeather ( "default" )
		end
		
		outputChatBox ( "XrEnv: Вы всегда можете заморозить время /xrtf" )
		
		--EnvEditor.open ( )
	end
, false )

local freezeValue

addEventHandler ( "onClientPreRender", root,
	function ( timeSlice )
		local time = getEnvironmentGameDayTimeSec ( 800 )
		if freezeValue ~= nil then
			time = freezeValue
		end
		xrEnvironment.setGameTime ( time )
		xrEnvironment.update ( )
		
		--[[dxDrawText ( time, 500, 400, 100, 100, tocolor ( 255, 255, 255 ), 3 )
		if xrEnvironment.envStart then
			dxDrawText ( xrEnvironment.envStart.timeStr .. "(" ..xrEnvironment.envStart.execTime .. ") >> " .. xrEnvironment.envEnd.timeStr .. "(" .. xrEnvironment.envEnd.execTime .. ")", 500, 500, 100, 100, tocolor ( 255, 255, 255 ), 3 )
		end]]
		
		local sw = guiGetScreenSize ( )
		dxDrawText ( math.floor ( time / 3600 ) .. " hours", sw / 2 - 50, 0, 100, 100, tocolor ( 255, 255, 255 ), 3 )
	end
, false )

addCommandHandler ( "xrtf",
	function ( )
		if freezeValue == nil then
			freezeValue = getEnvironmentGameDayTimeSec ( 1000 )
			outputChatBox ( "XrEnv: Вы заморозили время для " ..  math.floor ( freezeValue / 3600 ) .. " часов" )
		else
			freezeValue = nil
			outputChatBox ( "XrEnv: Вы разморозили время" )
		end
	end
)

addCommandHandler ( "xrst",
	function ( _, value )
		freezeValue = tonumber ( value ) * 3600
	end
)

--[[
	TEMP EXPORT
]]
local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3
local ENV_SUNDIR = 4

function getEnvValue ( type )
	if xrEnvironment.currentEnv then
		if type == ENV_AMBIENT then
			return xrEnvironment.currentEnv.ambient.x, xrEnvironment.currentEnv.ambient.y, xrEnvironment.currentEnv.ambient.z
		elseif type == ENV_HEMI then
			return xrEnvironment.currentEnv.hemiColor.x, xrEnvironment.currentEnv.hemiColor.y, xrEnvironment.currentEnv.hemiColor.z, xrEnvironment.currentEnv.hemiColor.w
		elseif type == ENV_SUNCOLOR then
			return xrEnvironment.currentEnv.sunColor.x, xrEnvironment.currentEnv.sunColor.y, xrEnvironment.currentEnv.sunColor.z
		elseif type == ENV_SUNDIR then
			return xrEnvironment.currentEnv.sunDir.x, xrEnvironment.currentEnv.sunDir.y, xrEnvironment.currentEnv.sunDir.z
		end
	end
end

function getXrSetting ( sectionName, itemName, dataType )
	local section = gSettings.sections [ sectionName ]
	if section then
		if dataType == "number" then
			return section:readNumber ( itemName )
		end
	end
end