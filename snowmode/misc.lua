local sw, sh = guiGetScreenSize ( )

local grassEnabled = false

local shaderCollection = { }

local diffuseColors = {
 [ 0 ] = 0.35,
 [ 1 ] = 0.37,
 [ 2 ] = 0.39,
 [ 3 ] = 0.41,
 [ 4 ] = 0.43,
 [ 5 ] = 0.45,
 [ 6 ] = 0.51,
 [ 7 ] = 0.65,
 [ 8 ] = 0.68,
 [ 9 ] = 0.71,
 [ 10 ] = 0.71,
 [ 11 ] = 0.73,
 [ 12 ] = 0.75,
 [ 13 ] = 0.77,
 [ 14 ] = 0.78,
 [ 15 ] = 0.79,
 [ 16 ] = 0.69,
 [ 17 ] = 0.685,
 [ 18 ] = 0.675,
 [ 19 ] = 0.688,
 [ 20 ] = 0.513,
 [ 21 ] = 0.405,
 [ 22 ] = 0.316,
 [ 23 ] = 0.325 }
 
function getRelativeTimeColor ( )
	local hour, mins = getTime ( )
 
	local previousHour = hour - 1
	if previousHour < 0 then
	previousHour = 23
	end
 
	return interpolateBetween ( diffuseColors [ hour ], 0, 0, diffuseColors [ previousHour ], 0, 0, ( 60 - mins ) / 60, "Linear" )
end

local lastTick = getTickCount ( )

addEventHandler ( "onClientRender", root,
	function ( )
		if getTickCount ( ) - lastTick > getMinuteDuration ( ) then
			for i, shader in ipairs ( shaderCollection ) do
				if isElement ( shader ) then
					local color = getRelativeTimeColor ( )
					dxSetShaderValue ( shader, "DiffuseColor", color, color, color, 1 )
				else
					shaderCollection [ i ] = nil
				end
			end
			
			local grassTextureNames = engineGetVisibleTextureNames ( "txgrass*" )
			grassEnabled = #grassTextureNames > 0
			
			lastTick = getTickCount ( )
		end
 
		--Если трава включена
		if isGrassEnabled ( ) then
			local x, y, w, h = 0.25 * sw, 0.4 * sh, 0.5 * sw, 0.2 * sh
			dxDrawRectangle ( x, y, w, h, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( "ОТКЛЮЧИТЕ ОТРИСОВКУ ТРАВЫ\n\n\nДля обеспечения одинаково высокой производительности у всех игроков, пожалуйста, отключите отрисовку травы в опциях клиента.\n\nПройдите в главное меню клиента, откройте раздел настроек 'SETTINGS' и на вкладке 'Video' уберите галочку с поля 'Grass еffect'.", x, y, x + w, y + h, tocolor ( 255, 255, 255, 255 ), 0.001 * sh, "default-bold", "center", "center", false, true )
		end
	end 
)

function setShaderPrelight ( shader )
	dxSetShaderValue ( shader, "DiffuseColor", 0.76, 0.76, 0.76, 1 )
	table.insert ( shaderCollection, shader )
end

function isGrassEnabled ( )
	return snowmodeStarted and grassEnabled
end