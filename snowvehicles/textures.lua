local VehicleSnow = { }
VehicleSnow.__index = VehicleSnow

local TIME = 10000

local textureNames = {
	"vehiclegrunge256", "*emap*", "vlg_misc1",
	"@hite", "*body*", "capbag", "side", "99_opal", "criminal*", "vpv_099*", "3cd561cb", "aerogaz", "bandito92interior128", 
	"combinetexpage128", "liaz677d_red", "*logos128", "*num128", "belarus", "patriot92interior128",
	
	"vehiclegeneric256",
	"cr_lob"
}

function VehicleSnow.create ( vehicle, callback )
	local vehicleSnow = setmetatable ( { fn = callback }, VehicleSnow )
	
	vehicleSnow:setup ( 0, 1 )
	
	vehicleSnow.shader = dxCreateShader ( "shaders/shader.fx", 0, 0, false, "vehicle" )
	dxSetShaderValue ( vehicleSnow.shader, "TexMsk", VehicleSnow.texture )
	
	for _, matchName in ipairs ( textureNames ) do
		engineApplyShaderToWorldTexture ( vehicleSnow.shader, matchName, vehicle )
	end
	
	return vehicleSnow
end

function VehicleSnow:setup ( startLevel, endLevel )
	local now = getTickCount ( )
	
	self.startTime = now
	self.endTime = now + TIME
	
	self.startLevel = startLevel
	self.endLevel = endLevel
	
	self.status = "running"
end

function VehicleSnow:destroy ( )
	destroyElement ( self.shader )
	
	setmetatable ( self, self )
end

local snowedVehicles = {
	items = { },
	add = function ( self, vehicle )
		if self:isExists ( vehicle ) then
			return
		end
		
		self.items [ vehicle ] = VehicleSnow.create ( vehicle, onVehicleSnowChange )
	end,
	remove = function ( self, vehicle )
		if self:isExists ( vehicle ) then
			self.items [ vehicle ]:destroy ( )
			self.items [ vehicle ] = nil

		end
	end,
	isExists = function ( self, vehicle )
		return self.items [ vehicle ] ~= nil
	end
}

function onVehicleSnowChange ( vehicle, level )
	level = math.floor ( level + 0.5 )
	
	if level < 1 then
		snowedVehicles:remove ( vehicle )
	end
end

addEventHandler ( "onClientPreRender", root,
	function ( )
		local now = getTickCount ( )
	
		for vehicle, vehSnow in pairs ( snowedVehicles.items ) do
			-- Обновляем вектор
			local tx, ty, tz = getElementPositionByOffset ( vehicle, 0, 0, 1 )
			local x, y, z = getElementPosition ( vehicle )
		
			local upX, upY, upZ = tx - x, ty - y, tz - z
		
			dxSetShaderValue ( vehSnow.shader, "topVector", upX, upY, upZ )
			
			-- Обновляем прелайт
			local color = getRelativeTimeColor ( )
			
			dxSetShaderValue ( vehSnow.shader, "DiffuseColor", color )
			
			-- Обновляем уровень заснеженности
			local elapsedTime = now - vehSnow.startTime
			local duration = vehSnow.endTime - vehSnow.startTime
			local progress = elapsedTime / duration

			if progress > 1 then
				if vehSnow.status ~= "stopped" then
					vehSnow.status = "stopped"
					
					if vehSnow.fn then vehSnow.fn ( vehicle, vehSnow.level ) end
				end
			else
				vehSnow.level = interpolateBetween ( vehSnow.startLevel, 0, 0, vehSnow.endLevel, 0, 0, progress, "OutInQuad" )
				
				dxSetShaderValue ( vehSnow.shader, "progress", vehSnow.level )
			end
		end
	end
)

function getElementPositionByOffset ( element, xOffset, yOffset, zOffset )
	local pX, pY, pZ

	local matrix = getElementMatrix ( element )
	
	if matrix then
		pX = xOffset * matrix [ 1 ] [ 1 ] + yOffset * matrix [ 2 ] [ 1 ] + zOffset * matrix [ 3 ] [ 1 ] + matrix [ 4 ] [ 1 ]
		pY = xOffset * matrix [ 1 ] [ 2 ] + yOffset * matrix [ 2 ] [ 2 ] + zOffset * matrix [ 3 ] [ 2 ] + matrix [ 4 ] [ 2 ]
		pZ = xOffset * matrix [ 1 ] [ 3 ] + yOffset * matrix [ 2 ] [ 3 ] + zOffset * matrix [ 3 ] [ 3 ] + matrix [ 4 ] [ 3 ]
	else
		pX, pY, pZ = getElementPosition ( element )
	end
	
	return pX, pY, pZ
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		VehicleSnow.texture = dxCreateTexture ( "single.mtacrmat" )
	
		local vehicles = getElementsByType ( "vehicle", root, true )
		for _, vehicle in ipairs ( vehicles ) do
			local isIdle = getElementData ( vehicle, "idle" )
			if isIdle then
				snowedVehicles:add ( vehicle )
			end
		end
	end
)

addEventHandler ( "onClientElementDataChange", root,
	function ( dataName, oldValue, value )
		if getElementType ( source ) ~= "vehicle" or dataName ~= "idle" then
			return
		end
		
		-- Если авто простаивает, начинаем наносить снег
		if value then
			-- Если нанесение уже происходит(в обратном порядке), ставим новые параметры
			if snowedVehicles:isExists ( source ) then
				snowedVehicles.items [ source ]:setup ( snowedVehicles.items [ source ].level, 1 )
			else
				snowedVehicles:add ( source )
			end
		else
			-- Если напыление уже происходит, начинаем постепенно убирать снег
			if snowedVehicles:isExists ( source ) then
				snowedVehicles.items [ source ]:setup ( snowedVehicles.items [ source ].level, 0 )
			end
		end
	end
)

addEventHandler ( "onClientElementStreamIn", root,
    function ( )
		if getElementType ( source ) ~= "vehicle" then
			return
		end
		
		local isIdle = getElementData ( source, "idle" )
		if isIdle then
			snowedVehicles:add ( source )
		end
    end
)

addEventHandler ( "onClientElementStreamOut", root,
    function ( )
		if snowedVehicles:isExists ( source ) then
			snowedVehicles:remove ( source )
		end
    end
)

addEventHandler ( "onClientElementDestroy", root,
	function ( )
		if snowedVehicles:isExists ( source ) then
			snowedVehicles:remove ( source )
		end
	end
)

local diffuseColors = {
 [ 0 ] = 0.55,
 [ 1 ] = 0.57,
 [ 2 ] = 0.59,
 [ 3 ] = 0.61,
 [ 4 ] = 0.63,
 [ 5 ] = 0.65,
 [ 6 ] = 0.71,
 [ 7 ] = 0.85,
 [ 8 ] = 0.88,
 [ 9 ] = 0.91,
 [ 10 ] = 0.91,
 [ 11 ] = 0.93,
 [ 12 ] = 0.95,
 [ 13 ] = 0.97,
 [ 14 ] = 0.98,
 [ 15 ] = 0.99,
 [ 16 ] = 0.89,
 [ 17 ] = 0.885,
 [ 18 ] = 0.875,
 [ 19 ] = 0.888,
 [ 20 ] = 0.713,
 [ 21 ] = 0.605,
 [ 22 ] = 0.516,
 [ 23 ] = 0.525 }
 
function getRelativeTimeColor ( )
	local hour, mins = getTime ( )
 
	local previousHour = hour - 1
	if previousHour < 0 then
	previousHour = 23
	end
 
	return interpolateBetween ( diffuseColors [ hour ], 0, 0, diffuseColors [ previousHour ], 0, 0, ( 60 - mins ) / 60, "Linear" )
end