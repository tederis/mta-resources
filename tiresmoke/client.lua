--[[
	Filename: client.lua
	Description: Реализация эффекта дыма
	Author: TEDERIs <xcplay@gmail.com>
	Revision: 6 from 14.03.16
]]

local DRIFT_MINIMAL_ANGLE = math.rad( 5 )
local DRIFT_MINIMAL_SPEED = 0.05
local EFFECT_NAME = "exhaust_workshop_1_small"
local VELOCITY_FACTOR = 25 -- Коэффициент ускорения частиц по отношению к тачке
local BURN_TIME = 3000 -- Время, необходимое для зажигания резины

local gTireDef

--[[
	VEHICLE STATE
]]
local affectedVehicles = { }
local _onVelocityCorrect = function ( vehicle, _, particle )
	local vel = vehicle:getVelocity ( )
	particle.vel.x = vel.x * VELOCITY_FACTOR
	particle.vel.y = vel.y * VELOCITY_FACTOR
	particle.vel.z = vel.z * VELOCITY_FACTOR
	
	local data = affectedVehicles [ vehicle ]
	if data then
		local now = getTickCount ( )
		local factor = math.min ( ( now - data.startTime ) / BURN_TIME, 1 )
		--particle.color.a = particle.color.a * factor
	end
end
local StateVehicles = function ( vehicle )
	local data = affectedVehicles [ vehicle ]
	return data ~= nil and data.state ~= false
end
local ExtendVehicles = function ( vehicle )
	local data = affectedVehicles [ vehicle ]
	if data then
		data.le:play ( )
		data.re:play ( )
		data.state = true
		data.startTime = getTickCount ( )
	else
		local leftEmitter = CParticleEffect.new ( )
		leftEmitter:compile ( gTireDef )
		leftEmitter:setBirthDeadCB ( _onVelocityCorrect, nil, vehicle )
		registerEffect(leftEmitter)
		
		local rightEmitter = CParticleEffect.new ( )
		rightEmitter:compile ( gTireDef )
		rightEmitter:setBirthDeadCB ( _onVelocityCorrect, nil, vehicle )
		registerEffect(rightEmitter)
		
		leftEmitter:play()
		rightEmitter:play()
		
		affectedVehicles [ vehicle ] = {
			le = leftEmitter,
			re = rightEmitter,
			state = true,
			startTime = getTickCount ( )
		}
	end
end
local CollapseVehicles = function ( vehicle )
	local data = affectedVehicles [ vehicle ]
	if data then
		data.le:stop(true)
		data.re:stop(true)
		data.state = false
	end
end
local UpdateVehicles = function ( vehicle )
	local data = affectedVehicles [ vehicle ]
	if data then
		if data.state then
			local x, y, z = getVehicleComponentPosition( vehicle, 'wheel_lb_dummy', 'world' )
			local mat = Matrix(Vector3(x, y, z-0.1) + vehicle.matrix.forward*0.3, vehicle.rotation + Vector3(90, 0, -10))
			data.le:setMatrix(mat)
			
			x, y, z = getVehicleComponentPosition( vehicle, 'wheel_rb_dummy', 'world' )
			mat = Matrix(Vector3(x, y, z-0.1) + vehicle.matrix.forward*0.3, vehicle.rotation + Vector3(90, 0, -10))
			data.re:setMatrix(mat)
		else
			-- Ждем пока все частицы не исчезнут, а затем уже удаляем эффект
			if data.le:getParticlesCount ( ) == 0 and data.re:getParticlesCount ( ) == 0 then
				unregisterEffect ( data.le )
				unregisterEffect ( data.re )
			
				affectedVehicles [ vehicle ] = nil
			end
		end
	end
end

--[[
	WORKER
]]
local mathPi = math.pi
addEventHandler( 'onClientPreRender', root, 
	function ( )
		for key, vehicle in pairs( getElementsByType( 'vehicle', root, true ) ) do
			if isElementStreamedIn ( vehicle ) then
				if vehicle:getVehicleType() == 'Automobile' and vehicle:isOnGround() then
					local vRotation = vehicle:getRotation( )
					local vVelocity = vehicle:getVelocity( ) getElementVelocity( vehicle )
					local speed = ( vVelocity.x^2 + vVelocity.y^2 + vVelocity.z^2 ) ^ 0.5

					local rZ = math.atan2( vVelocity.x, vVelocity.y )
					rZ = rZ < 0 and -rZ or 2 * mathPi - rZ
					local vRotZ = math.rad( vRotation.z )
					local driftAngle = math.abs( rZ - vRotZ )
					if driftAngle > mathPi -0.1 then
						if rZ > mathPi and vRotZ > 0 and vRotZ < mathPi then
							driftAngle = mathPi * 2 - rZ + vRotZ;
						elseif rZ < mathPi and rZ > 0 and vRotZ > mathPi and vRotZ < mathPi * 2 then
							driftAngle = ( mathPi * 2 - vRotZ ) + rZ;
						end
					end
					local newState = (driftAngle > DRIFT_MINIMAL_ANGLE and DRIFT_MINIMAL_SPEED < speed and driftAngle < mathPi/2) or (getControlState("accelerate") and getControlState("handbrake"))
					if newState ~= StateVehicles ( vehicle ) then
						if newState then
							ExtendVehicles ( vehicle )
						else
							CollapseVehicles ( vehicle )
						end
					end
				end
			end
		end
		
		-- Обновляем позицию эффектов
		for vehicle, data in pairs ( affectedVehicles ) do
			UpdateVehicles ( vehicle )
		end
	end
)

addEventHandler("onClientResourceStart", resourceRoot,
	function()
		gTireDef = createDefinition ( EFFECT_NAME )
		
		local tIndex = 15
		outputChatBox( 5 % 5)
	end
, false)