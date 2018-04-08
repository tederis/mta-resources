local sw, sh = guiGetScreenSize ( )

--[[
	Баги:
		- Неверно работает defaultRotate на примере campfire_flame с -90,0,0
]]

--[[
	PAPI
	Particle Actions
]]
local _rand = function ( )
	return math.random ( 100 ) / 100
end

function utilXmlReadFloat3 ( node, nodeName )
	local value = xmlNodeGetAttribute ( node, nodeName )
	
	if value == false then
		return
	end
	
	local x = gettok ( value, 1, 44 )
	local y = gettok ( value, 2, 44 )
	local z = gettok ( value, 3, 44 )
	
	return { x = tonumber ( x ), y = tonumber ( y ), z = tonumber ( z ) }
end

function utilXmlFindChild ( node, tagName )
	for _, child in ipairs ( xmlNodeGetChildren ( node ) ) do
		if xmlNodeGetName ( child ) == tagName then
			return child
		end
	end
end

PActionEnum = {
	Avoid = 1,
	Bounce = 2,
	CopyVertexB = 3,
	Damping = 4,
	Explosion = 5,
	Follow = 6,
	Gravitate = 7,
	Gravity = 8,
	Jet = 9,
	KillOld = 10,
	MatchVelocity = 11,
	Move = 12,
	OrbitLine = 13,
	OrbitPoint = 14,
	RandomAccel = 15,
	RandomDisplace = 16,
	RandomVelocity = 17,
	Restore = 18,
	Scatter = 19,
	Sink = 20,
	SinkVelocity = 21,
	Source = 22,
	SpeedLimit = 23,
	TargetColor = 24,
	TargetRotate = 25,
	TargetSize = 26,
	TargetVelocity = 27,
	Turbulence = 28,
	Vortex = 29
}

domainTypes = {
	point = 1,
	line = 2,
	box = 5,
	disc = 10,
	cone = 8
}

DT_STEP = 0.033


--[[
	PAPI::PATargetRotate
]]
PATargetRotate = {
	new = function ( self )
		local targetRotate = {
			scale = nil, -- float
			rot = nil, -- float3
		}
		
		return setmetatable ( targetRotate, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = self.scale * dt
		
		local absx = math.abs ( self.rot.x )
		local absy = math.abs ( self.rot.y )
		local absz = math.abs ( self.rot.z )
		
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
				
			local rotx = ( absx - math.abs ( particle.rot.x ) ) * scale
			local roty = ( absx - math.abs ( particle.rot.y ) ) * scale
			local rotz = ( absx - math.abs ( particle.rot.z ) ) * scale
				
			particle.rot.x = rotx + particle.rot.x
			particle.rot.y = rotx + particle.rot.y
			particle.rot.z = rotx + particle.rot.z
		end
	end,
	load = function ( self, xml )
		self.rot = utilXmlReadFloat3 ( xml, "rotation" )
		self.rot.x = math.rad ( self.rot.x )
		self.rot.y = math.rad ( self.rot.y )
		self.rot.z = math.rad ( self.rot.z )
		self.scale = tonumber ( 
			xmlNodeGetAttribute ( xml, "scale" )
		)
	end
}

--[[
	PAPI::PATargetSize
]]
PATargetSize = {
	new = function ( self )
		local targetSize = {
			scale = nil, -- float3
			size = nil, -- float3
		}
		
		return setmetatable ( targetSize, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scalex = self.scale.x * dt
		local scaley = self.scale.y * dt
		local scalez = self.scale.z * dt
		
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
				
			local sizex = self.size.x - particle.size.x
			local sizey = self.size.y - particle.size.y
			local sizez = self.size.z - particle.size.z
				
			particle.size.x = particle.size.x + ( sizex * scalex )
			particle.size.y = particle.size.y + ( sizey * scaley )
			particle.size.z = particle.size.z + ( sizez * scalez )
		end
	end,
	load = function ( self, xml )
		self.size = utilXmlReadFloat3 ( xml, "size" )
		self.scale = utilXmlReadFloat3 ( xml, "scale" )
	end
}

--[[
	PAPI::PATargetVelocity
]]
PATargetVelocity = {
	new = function ( self )
		local targetVel = {
			scale = nil, -- float
			velocity = nil, -- float3
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( targetVel, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = self.scale * dt
		
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]

			local velx = self.velocity.x - particle.vel.x
			local vely = self.velocity.y - particle.vel.y
			local velz = self.velocity.z - particle.vel.z
				
			particle.vel.x = particle.vel.x + ( velx * scale )
			particle.vel.y = particle.vel.y + ( vely * scale )
			particle.vel.z = particle.vel.z + ( velz * scale )
		end
	end,
	load = function ( self, xml )
		self.velocity = utilXmlReadFloat3 ( xml, "velocity" )
		self.scale = tonumber ( 
			xmlNodeGetAttribute ( xml, "scale" )
		)
		self.flagAllowRotate = xmlNodeGetAttribute ( xml, "allowRotate" ) == "true"
		
		self.velocityL = {
			x = self.velocity.x,
			y = self.velocity.y,
			z = self.velocity.z
		}
	end
}

--[[
	PAPI::PATargetColor
]]
PATargetColor = {
	new = function ( self )
		local targetColor = {
			color = nil, -- domain
			alpha = nil, -- float
			scale = nil, -- float
		}
		
		return setmetatable ( targetColor, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local dta = dt * self.scale
	
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
			
			local particleColor = particle.color
				
			particleColor.r = ( self.color.x - particleColor.r ) * dta + particleColor.r
			particleColor.g = ( self.color.y - particleColor.g ) * dta + particleColor.g
			particleColor.b = ( self.color.z - particleColor.b ) * dta + particleColor.b
			particleColor.a = ( self.alpha - particleColor.a ) * dta + particleColor.a
			
			--particleColor.r = self.color.x
			--particleColor.g = self.color.y
			--particleColor.b = self.color.z
			--particleColor.a = self.alpha
			
		end
	end,
	load = function ( self, xml )
		self.color = utilXmlReadFloat3 ( xml, "color" )
		self.alpha = tonumber (
			xmlNodeGetAttribute ( xml, "alpha" )
		)
		self.scale = tonumber (
			xmlNodeGetAttribute ( xml, "scale" )
		)
	end
}

--[[
	PAPI::PARandomAccel
]]
PARandomAccel = {
	new = function ( self )
		local randAccel = {
			
		}
		
		return setmetatable ( randAccel, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
				
			local acceleration = self.gen_acc:generate ( )
			
			particle.vel.x = particle.vel.x + ( acceleration.x * dt )
			particle.vel.y = particle.vel.y + ( acceleration.y * dt )
			particle.vel.z = particle.vel.z + ( acceleration.z * dt )
		end
	end,
	load = function ( self, xml )
		local node = utilXmlFindChild ( xml, "accelerate" )
		self.gen_acc = pDomain:new ( node )
	end
}

--[[
	PAPI::PAGravity
]]
PAGravity = {
	new = function ( self )
		local gravity = {
			direction = nil, -- float3
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( gravity, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local dirx = self.direction.x * dt
		local diry = self.direction.y * dt
		local dirz = self.direction.z * dt
	
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
				
			particle.vel.x = dirx + particle.vel.x
			particle.vel.y = diry + particle.vel.y
			particle.vel.z = dirz + particle.vel.z
		end
	end,
	load = function ( self, xml )
		self.direction = utilXmlReadFloat3 ( xml, "direction" )
		self.flagAllowRotate = xmlNodeGetAttribute ( xml, "allowRotate" ) == "true"
		
		self.directionL = {
			x = self.direction.x,
			y = self.direction.y,
			z = self.direction.z
		}
	end
}

--[[
	PAPI::PAScatter
]]
PAScatter = {
	new = function ( self )
		local scatter = {
			magnitude = nil, -- float
			maxRadius = nil, -- float
			center = nil, -- float3
			epsilon = nil, -- float
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( scatter, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local magnitude = self.magnitude * dt
		local maxRadiusSq = self.maxRadius * self.maxRadius
		if maxRadiusSq >= 1.0e16 then
			for i = 1, effect.p_count do
				local particle = effect.particles [ i ]
					
				local posx = particle.pos.x - self.center.x
				local posy = particle.pos.y - self.center.y
				local posz = particle.pos.z - self.center.z
					
				local effecta = posz*posz + posy*posy + posx*posx
					
				local rSqrt = 1 / math.sqrt ( effecta )
				local mag = magnitude / ( self.epsilon + effecta )
					
				particle.vel.x = particle.vel.x + ( ( posx * rSqrt ) * mag )
				particle.vel.y = particle.vel.y + ( ( posy * rSqrt ) * mag )
				particle.vel.z = particle.vel.z + ( ( posz * rSqrt ) * mag )
			end
		else
			for i = 1, effect.p_count do
				local particle = effect.particles [ i ]
					
				local posx = particle.pos.x - self.center.x
				local posy = particle.pos.y - self.center.y
				local posz = particle.pos.z - self.center.z
					
				local effecta = posz*posz + posy*posy + posx*posx
				if maxRadiusSq > effecta then
					local rSqrt = 1 / math.sqrt ( effecta )
					local mag = magnitude / ( self.epsilon + effecta )
					
					particle.vel.x = particle.vel.x + ( ( posx * rSqrt ) * mag )
					particle.vel.y = particle.vel.y + ( ( posy * rSqrt ) * mag )
					particle.vel.z = particle.vel.z + ( ( posz * rSqrt ) * mag )
				end
			end
		end
	end,
	load = function ( self, xml )
		self.center = utilXmlReadFloat3 ( xml, "center" )
		self.magnitude = tonumber ( 
			xmlNodeGetAttribute ( xml, "magnitude" )
		)
		self.epsilon = tonumber ( 
			xmlNodeGetAttribute ( xml, "epsilon" )
		)
		self.maxRadius = tonumber ( 
			xmlNodeGetAttribute ( xml, "maxRadius" )
		)
		self.flagAllowRotate = xmlNodeGetAttribute ( xml, "allowRotate" ) == "true"
		
		self.centerL = {
			x = self.center.x,
			y = self.center.y,
			z = self.center.z,
		}
	end
}

--[[
	PAPI::PASink
]]
PASink = {
	new = function ( self )
		local sink = {
			
		}
		
		return setmetatable ( sink, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local i = effect.p_count
		while i > 0 do
			local particle = effect.particles [ i ]
			
			if self.killInside == self.position:within ( particle.pos ) and effect.p_count > 0 then
				local callback = effect.d_cb
				if callback then
					callback ( effect.owner, effect.param, particle, i )
				end
				effect.p_count = effect.p_count - 1
				Particle.operator ( particle, effect.particles [ effect.p_count + 1 ] )
			end
			
			i = i - 1
		end
	end,
	load = function ( self, xml )
		self.killInside = xmlNodeGetAttribute ( xml, "killInside" ) == "true"
		local node = utilXmlFindChild ( xml, "domain" )
		self.position = pDomain:new ( node )
	end
}

--[[
	PAPI::PASpeedLimit
]]
PASpeedLimit = {
	new = function ( self )
		local speedLimit = {
			
		}
		
		return setmetatable ( speedLimit, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local min_sqr = self.min_speed * self.min_speed
		local max_sqr = self.max_speed * self.max_speed
	
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
			
			local spd = particle.vel.x*particle.vel.x + particle.vel.y*particle.vel.y + particle.vel.z*particle.vel.z
			if spd < min_sqr then
				if spd > 0 then break end;
			end
			if spd > max_sqr then
				local factor = self.max_speed / math.sqrt ( spd )
				particle.vel.x = factor * particle.vel.x
				particle.vel.y = factor * particle.vel.y
				particle.vel.z = factor * particle.vel.z
			end
		end
	end,
	load = function ( self, xml )
		self.min_speed = tonumber ( 
			xmlNodeGetAttribute ( xml, "minSpeed" )
		)
		self.max_speed = tonumber ( 
			xmlNodeGetAttribute ( xml, "maxSpeed" )
		)
	end
}

--[[
	PAPI::PADamping
]]
PADamping = {
	new = function ( self )
		local damping = {
			damping = nil, -- float3
			vlowSqr = nil, -- float
			vhighSqr = nil, -- float
		}
		
		return setmetatable ( damping, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local dampx = 1 - ( 1 - self.damping.x ) * dt
		local dampy = 1 -( 1 - self.damping.y ) * dt
		local dampz = 1 - ( 1 - self.damping.z ) * dt
		
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]
				
			local effecta = particle.vel.x*particle.vel.x + particle.vel.y*particle.vel.y + particle.vel.z*particle.vel.z
			if effecta >= self.vlowSqr then
				if effecta <= self.vhighSqr then
					particle.vel.x = particle.vel.x * dampx
					particle.vel.y = particle.vel.y * dampy
					particle.vel.z = particle.vel.z * dampz
				end
			end
		end
	end,
	load = function ( self, xml )
		self.damping = utilXmlReadFloat3 ( xml, "damping" )
		self.vlowSqr = tonumber ( 
			xmlNodeGetAttribute ( xml, "vlow" )
		)
		self.vhighSqr = tonumber ( 
			xmlNodeGetAttribute ( xml, "vhigh" )
		)
	end
}

--[[
	PAPI::PAKillOld
]]
PAKillOld = {
	new = function ( self )
		local killOld = {
			ageLimit = nil, -- float
			killLessThan = nil, -- bool
		}
		
		return setmetatable ( killOld, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local i = effect.p_count
		while i > 0 do
			local particle = effect.particles [ i ]
			
			local isAlive = self.ageLimit > particle.age
			if isAlive == self.killLessThan and effect.p_count > 0 then
				local callback = effect.d_cb
				if callback then
					callback ( effect.owner, effect.param, particle, i )
				end
				effect.p_count = effect.p_count - 1
				Particle.operator ( particle, effect.particles [ effect.p_count + 1 ] )
			end
			i = i - 1
		end
	end,
	load = function ( self, xml )
		self.ageLimit = tonumber ( 
			xmlNodeGetAttribute ( xml, "ageLimit" )
		)
		self.killLessThan = xmlNodeGetAttribute ( xml, "killLessThan" ) == "true"
	end
}

--[[
	PAPI::PAOrbitPoint
]]
PAOrbitPoint = {
	new = function ( self )
		local orbitPoint = {
			
		}
		
		return setmetatable ( orbitPoint, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local magdt = dt * self.magnitude
		local dta = self.max_radius * self.max_radius
		if dta >= 1.0e16 then
			for i = 1, effect.p_count do
				local particle = effect.particles [ i ]
				
				local vecx = self.center.x - particle.pos.x
				local vecy = self.center.y - particle.pos.y
				local vecz = self.center.z - particle.pos.z
				
				local spd = vecz*vecz + vecy*vecy + vecx*vecx
				local effecta = magdt / ( math.sqrt ( spd ) + spd + self.epsilon )
				
				particle.vel.x = vecx*effecta + particle.vel.x
				particle.vel.y = vecy*effecta + particle.vel.y
				particle.vel.z = vecz*effecta + particle.vel.z
			end
		else
			for i = 1, effect.p_count do
				local particle = effect.particles [ i ]
				
				local vecx = self.center.x - particle.pos.x
				local vecy = self.center.y - particle.pos.y
				local vecz = self.center.z - particle.pos.z
				
				local spd = vecz*vecz + vecy*vecy + vecx*vecx
				if spd < dta then
					local effecta = magdt / ( math.sqrt ( spd ) + spd + self.epsilon )
				
					particle.vel.x = vecx*effecta + particle.vel.x
					particle.vel.y = vecy*effecta + particle.vel.y
					particle.vel.z = vecz*effecta + particle.vel.z
				end
			end
		end
	end,
	load = function ( self, xml )
		self.center = utilXmlReadFloat3 ( xml, "center" )
		self.magnitude = tonumber ( 
			xmlNodeGetAttribute ( xml, "magnitude" )
		)
		self.epsilon = tonumber ( 
			xmlNodeGetAttribute ( xml, "epsilon" )
		)
		self.max_radius = tonumber ( 
			xmlNodeGetAttribute ( xml, "maxRadius" )
		)
	end
}

--[[
	PAPI::PATurbulence
]]
PATurbulence = {
	new = function ( self )
		local turbulence = {
			frequency = nil, -- float
			octaves = nil, -- float
			magnitude = nil, -- float
			epsilon = nil, -- float
			offset = nil, -- float3
			
			age = 0
		}
		
		return setmetatable ( turbulence, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		self.age = dt * self.age
	
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]

			local pV = {
				x = self.age*self.offset.x + particle.pos.x,
				y = self.age*self.offset.y + particle.pos.y,
				z = self.age*self.offset.z + particle.pos.z
			}
			local vX = {
				x = pV.x + self.epsilon,
				y = pV.y,
				z = pV.z
			}
			local vY = {
				x = pV.x,
				y = pV.y + self.epsilon,
				z = pV.z
			}
			local vZ = {
				x = pV.x,
				y = pV.y,
				z = pV.z + self.epsilon
			}
			
			local dta = fractalsum3 ( pV.x, pV.y, pV.z, self.frequency, self.octaves )
			local v14 = ( fractalsum3 ( vX.x, vX.y, vX.z, self.frequency, self.octaves ) - dta ) * self.magnitude
			local v17 = ( fractalsum3 ( vY.x, vY.y, vY.z, self.frequency, self.octaves ) - dta ) * self.magnitude
			local v20 = ( fractalsum3 ( vZ.x, vZ.y, vZ.z, self.frequency, self.octaves ) - dta ) * self.magnitude
			
			local v21 = particle.vel.x * particle.vel.x + particle.vel.y * particle.vel.y + particle.vel.z * particle.vel.z
			
			particle.vel.x = v14 + particle.vel.x
			particle.vel.y = v17 + particle.vel.y
			particle.vel.z = v20 + particle.vel.z
			
			local v22 = particle.vel.x * particle.vel.x + particle.vel.y * particle.vel.y + particle.vel.z * particle.vel.z
			local sqr = math.sqrt ( v21 ) / math.sqrt ( v22 )
			
			particle.vel.x = sqr + particle.vel.x
			particle.vel.y = sqr + particle.vel.y
			particle.vel.z = sqr + particle.vel.z
		end
	end,
	load = function ( self, xml )
		self.frequency = tonumber (
			xmlNodeGetAttribute ( xml, "frequency")
		)
		self.octaves = tonumber (
			xmlNodeGetAttribute ( xml, "octaves")
		)
		self.magnitude = tonumber (
			xmlNodeGetAttribute ( xml, "magnitude")
		)
		self.epsilon = tonumber (
			xmlNodeGetAttribute ( xml, "delta")
		)
		self.offset = utilXmlReadFloat3 ( xml, "movement" )
	end
}

--[[
	PAPI::PAMove
]]
PAMove = {
	new = function ( self )
		local move = {
			
		}
		
		return setmetatable ( move, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		for i = 1, effect.p_count do
			local particle = effect.particles [ i ]

			particle.age = dt + particle.age
			particle.posB.x = particle.pos.x
			particle.posB.y = particle.pos.y
			particle.posB.z = particle.pos.z
				
			particle.pos.x = particle.pos.x + ( dt * particle.vel.x )
			particle.pos.y = particle.pos.y + ( dt * particle.vel.y )
			particle.pos.z = particle.pos.z + ( dt * particle.vel.z )
		end
	end,
	load = function ( self, xml )
	end
}

--[[
	PAPI::PASource
]]
PASource = {
	new = function ( self )
		local source = {
			position = nil, -- domain
			size = nil, -- domain
			rot = nil, -- domain
			velocity = nil, -- domain
			color = nil, -- domain
			age = nil, -- float
			age_sigma = nil, -- float
			alpha = nil, -- float
			particle_rate = nil, -- float
			parent_motion = nil, -- float
			flagAllowRotate = nil, -- bool
			flagSingleSize = nil, -- bool
		}
		
		return setmetatable ( source, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		--if bitAnd ( self.flags, 0x40 ) > 0 then
			local rate = math.floor ( dt * self.particle_rate )
			local rand = _rand ( )
			local counter = rate
			if dt*self.particle_rate - rate > rand then
				counter = counter + 1
			end
			if effect.p_count + counter > effect.max_particles then
				counter = effect.max_particles - effect.p_count
			end
		
			--if bitAnd ( self.flags, 0x80000000 ) == 0x80000000 then
				while counter > 0 do
					local pos = self.position:generate ( )
					local size = self.size:generate ( )
					if self.flagSingleSize then
						size.y = size.x
						size.z = size.x
					end
					local rot = self.rot:generate ( )
					rot.x = math.rad ( rot.x )
					rot.y = math.rad ( rot.y )
					rot.z = math.rad ( rot.z )
					local vel = self.velocity:generate ( )
					
					--[[vel.x = vel.x + self.parent_vel.x
					vel.y = vel.y + self.parent_vel.y
					vel.z = vel.z + self.parent_vel.z]]
				
					local color = self.color:generate ( )
					color = {
						r = color.x,
						g = color.y,
						b = color.z,
						a = self.alpha
					}
					
					local age = --[[PAPI::NRand(pThis->age_sigma)]]self.age_sigma + self.age
				
					effect:add ( pos, pos, size, rot, vel, color, age, 0, 0 )
			
					counter = counter - 1
				end
			--else
				-- TODO
			--end
		--end
	end,
	load = function ( self, xml )
		local node = utilXmlFindChild ( xml, "domain" )
		self.position = pDomain:new ( node )
		
		node = utilXmlFindChild ( xml, "velocity" )
		self.velocity = pDomain:new ( node )
		
		node = utilXmlFindChild ( xml, "rotation" )
		self.rot = pDomain:new ( node )
		
		node = utilXmlFindChild ( xml, "size" )
		self.size = pDomain:new ( node )
		self.flagSingleSize = xmlNodeGetAttribute ( xml, "singleSize" ) == "true"
		node = utilXmlFindChild ( xml, "color" )
		self.color = pDomain:new ( node )
		
		self.alpha = tonumber (
			xmlNodeGetAttribute ( node, "alpha" )
		)
		self.particle_rate = tonumber (
			xmlNodeGetAttribute ( xml, "rate" )
		)
		self.age = tonumber (
			xmlNodeGetAttribute ( xml, "startingAge" )
		)
		self.age_sigma = tonumber (
			xmlNodeGetAttribute ( xml, "ageSigma" )
		)
		self.parent_motion = tonumber (
			xmlNodeGetAttribute ( xml, "parentMotion" )
		)
		self.flagAllowRotate = xmlNodeGetAttribute ( xml, "allowRotate" ) == "true"
		
		--self.positionL = self.position:clone ( )
		--self.velocityL = self.velocity:clone ( )
	end
}

--[[
	PAPI::pDomain
]]
pDomain = {
	new = function ( self, xml )
		local domain = {
			type = nil,
			p1 = nil, -- float3
			p2 = nil, -- float
		}
		
		if xml then
			domain.type = domainTypes [ xmlNodeGetAttribute ( xml, "type" ) ]
			-- Disc
			if domain.type == 10 then
				domain.center = utilXmlReadFloat3 ( xml, "center" )
				domain.normal = utilXmlReadFloat3 ( xml, "normal" )
				domain.radiusInner = tonumber (
					xmlNodeGetAttribute ( xml, "radiusInner" )
				)
				domain.radiusOuter = tonumber (
					xmlNodeGetAttribute ( xml, "radiusOuter" )
				)
			else
				domain.p1 = utilXmlReadFloat3 ( xml, "point1" )
				local p2 = utilXmlReadFloat3 ( xml, "point2" )
				if p2 then domain.p2 = p2 end
			end
		end

		return setmetatable ( domain, { __index = pDomain } )
	end,
	--[[clone = function ( self )
		local domain = pDomain:new ( )
		domain.type = self.type
		domain.p1 = { x = self.p1.x, y = self.p1.y, z = self.p1.z }
		if self.p2 then
			domain.p2 = { x = self.p2.x, y = self.p2.y, z = self.p2.z }
		end
		
		return domain
	end,]]
	generate = function ( self )
	-- Type 0 Point
		if self.type == 1 then
			local pos = {
				x = self.p1.x,
				y = self.p1.y,
				z = self.p1.z
			}
			
			return pos
			
		-- Type 1 Line
		elseif self.type == 2 then
			local factor = _rand ( )
			--[[local pos = {
				x = ( self.p2.x * factor ) + self.p1.x,
				y = ( self.p2.y * factor ) + self.p1.y,
				z = ( self.p2.z * factor ) + self.p1.z
			}]]
			local x, y, z = interpolateBetween ( self.p1.x, self.p1.y, self.p1.z, self.p2.x, self.p2.y, self.p2.z, factor, "Linear" )
			local pos = { x = x, y = y, z = z }
			
			return pos
			
		-- Type 4 Box
		elseif self.type == 5 then
			local pos = {
				x = ( ( self.p2.x - self.p1.x ) * _rand ( ) ) + self.p1.x,
				y = ( ( self.p2.y - self.p1.y ) * _rand ( ) ) + self.p1.y,
				z = ( ( self.p2.z - self.p1.z ) * _rand ( ) ) + self.p1.z
			}
			
			return pos
		-- Type 9 Disc
		elseif self.type == 10 then
			local radius = math.random ( self.radiusInner, self.radiusOuter )
			local angle = math.random ( 0, 360 )
			
			local pos = { 
				x = self.center.x + radius*math.cos ( angle ), 
				y = self.center.y + radius*math.sin ( angle ), 
				z = self.center.z
			}
			return pos
		
		-- Type 7 Cone
		elseif self.type == 8 then
			
		-- TODO
		else
		end
	end,
	within = function ( self, pos )
		-- Type 4 Box
		if self.type == 5 then
			if ( self.p1.x > pos.x or pos.x > self.p2.x ) or ( self.p1.y > pos.y or pos.y > self.p2.y ) or ( self.p1.z > pos.z or pos.z > self.p2.z ) then
				return false
			end
			return true
		
		-- TODO
		else
		end
	end
}

--[[
	Particle
]]
Particle = {
	new = function ( )
		local particle = {
			pos = { x = 0, y = 0, z = 0 },
			posB = { x = 0, y = 0, z = 0 },
			size = { x = 0, y = 0, z = 0 },
			rot = { x = 0, y = 0, z = 0 },
			vel = { x = 0, y = 0, z = 0 },
			color = { r = 0, g = 0, b = 0, a = 0 }
		}
		
		return particle
	end,
	operator = function ( self, a2 )
		self.pos.x = a2.pos.x
		self.pos.y = a2.pos.y
		self.pos.z = a2.pos.z
		self.posB.x = a2.posB.x
		self.posB.y = a2.posB.y
		self.posB.z = a2.posB.z
		self.vel.x = a2.vel.x
		self.vel.y = a2.vel.y
		self.vel.z = a2.vel.z
		self.size.x = a2.size.x
		self.size.y = a2.size.y
		self.size.z = a2.size.z
		self.rot.x = a2.rot.x
		self.rot.y = a2.rot.y
		self.rot.z = a2.rot.z
		self.color = a2.color
		self.age = a2.age
		self.frame = a2.frame
	end
}

--[[
	PAPI::ParticleEffect
]]
ParticleEffect = { }
ParticleEffect.__index = ParticleEffect

function ParticleEffect.new ( )
	local effect = { 
		max_particles = 0,
		particles_allocated = 0,
		owner = nil,
		param = nil,
		b_cb = nil, -- callback Birth
		d_cb = nil, -- callback Dead
		p_count = 0,
		particles = { }, -- table
	}
	
	return setmetatable ( effect, ParticleEffect )
end

function ParticleEffect:add ( pos, posB, size, rot, vel, color, age, frame, flags )
	if self.p_count < self.max_particles then
		local particle = self.particles [ self.p_count + 1 ]
		
		particle.pos.x = pos.x
		particle.pos.y = pos.y
		particle.pos.z = pos.z
		particle.posB.x = posB.x
		particle.posB.y = posB.y
		particle.posB.z = posB.z
		particle.size.x = size.x
		particle.size.y = size.y
		particle.size.z = size.z
		particle.rot.x = rot.x
		particle.rot.y = rot.y
		particle.rot.z = rot.z
		particle.vel.x = vel.x
		particle.vel.y = vel.y
		particle.vel.z = vel.z
		particle.color = color
		particle.age = age
		particle.frame = frame
		
		local callback = self.b_cb
		if callback then
			callback ( self.owner, self.param, particle, self.p_count )
		end
		
		self.p_count = self.p_count + 1
		
		return true
	end
end


function ParticleEffect:resize ( max_count )
	if self.particles_allocated <= max_count then
		local num = max_count - self.particles_allocated
		for i = 1, num do
			local particle = Particle:new ( )
			table.insert ( self.particles, particle )
		end
		
		self.max_particles = max_count
		self.particles_allocated = max_count
	else
		local num = self.particles_allocated - max_count
		for i = 1, num do
			table.remove ( self.particles, #self.particles )
		end
	end
end

--[[
	PAPI::ParticleManager
]]
ParticleManager = { }
ParticleManager.__index = ParticleManager

function ParticleManager.new ( )
	local manager = { 
		effect_vec = { }, -- effects
		alist_vec = { --[[
			[ 1 ] = { ... }, -- action list 1
			[ 2 ] = { ... }, -- action list 2
			...
		]] }, -- actions list
	}
	
	return setmetatable ( manager, ParticleManager )
end

function ParticleManager:getParticlesCount ( effectId )
	if self.effect_vec [ effectId ] then
		return self.effect_vec [ effectId ].p_count
	end
end

function ParticleManager:getParticles ( effectId )
	local effect = self.effect_vec [ effectId ]
	if effect then
		return effect.particles, effect.p_count
	end
end

function ParticleManager:setCallback ( effectId, bFn, dFn, owner, param )
	local effect = self.effect_vec [ effectId ]
	if effect then
		effect.b_cb = bFn -- Birth
		effect.d_cb = dFn -- Dead
		effect.owner = owner
		effect.param = param
	end
end

function ParticleManager:createActionList ( )
	local particleActions = {
		
	}
	
	local newIndex = table.getn ( self.alist_vec ) + 1
	self.alist_vec [ newIndex ] = particleActions
	
	return newIndex
end

function ParticleManager:destroyActionList ( )
	-- TOOD
end

function ParticleManager:loadActions ( alist_id, xml )
	local actions = { }
	
	for _, node in ipairs ( xmlNodeGetChildren ( xml ) ) do
		local actionName = xmlNodeGetAttribute ( node, "name" )
		local action = self:createAction ( PActionEnum [ actionName ] )
		if action then
			action:load ( node )
			table.insert ( actions, action )
			
			outputDebugString ( actionName .. " loaded" )
		end
	end
	
	self.alist_vec [ alist_id ] = actions
end

function ParticleManager:createAction ( actionType )
	local result
	if actionType == PActionEnum.TargetRotate then
		result = PATargetRotate:new ( )
	elseif actionType == PActionEnum.TargetSize then
		result = PATargetSize:new ( )
	elseif actionType == PActionEnum.TargetVelocity then
		return PATargetVelocity:new ( )
	elseif actionType == PActionEnum.TargetColor then
		return PATargetColor:new ( )
	elseif actionType == PActionEnum.Gravity then
		return PAGravity:new ( )
	elseif actionType == PActionEnum.Scatter then
		return PAScatter:new ( )
	elseif actionType == PActionEnum.Sink then
		return PASink:new ( )
	elseif actionType == PActionEnum.Damping then
		return PADamping:new ( )
	elseif actionType == PActionEnum.KillOld then
		return PAKillOld:new ( )
	elseif actionType == PActionEnum.Move then
		return PAMove:new ( )
	elseif actionType == PActionEnum.Source then
		return PASource:new ( )
	elseif actionType == PActionEnum.RandomAccel then
		return PARandomAccel:new ( )
	elseif actionType == PActionEnum.Turbulence then
		return PATurbulence:new ( )
	elseif actionType == PActionEnum.OrbitPoint then
		return PAOrbitPoint:new ( )
	elseif actionType == PActionEnum.SpeedLimit then
		return PASpeedLimit:new ( )
	end
	
	if result then
		result.type = actionType
		return result
	end
end

function ParticleManager:getEffectPtr ( effect_id )
	return self.effect_vec [ effect_id ]
end

function ParticleManager:getActionListPtr ( a_list_num )
	return self.alist_vec [ a_list_num ]
end

function ParticleManager:playEffect ( effect_id, alist_id )
	local actions = self.alist_vec [ alist_id ]
	for _, action in ipairs ( actions ) do
		if action.type == PActionEnum.Explosion then
			-- TODO
		elseif action.type == PActionEnum.Source then
			--action.flags = bitAnd ( action.flags, 0xBFFFFFFF )
			action.flagEnabled = true
		elseif action.type == PActionEnum.Turbulence then
			--action.flags = 0
		end
	end
end

function ParticleManager:stopEffect ( effect_id, alist_id, deffered )
	local actions = self.alist_vec [ alist_id ]
	if actions then
		for _, action in ipairs ( actions ) do
			if action.type == PActionEnum.Source then
				action.flagEnabled = false
			end
		end
		
		if not deffered then
			self.effect_vec [ effect_id ].p_count = 0
		end
	end
end

function ParticleManager:update ( effect_id, alist_id, dt )
	local effect = self.effect_vec [ effect_id ]
	local actions = self.alist_vec [ alist_id ]
	for _, action in ipairs ( actions ) do
		action:execute ( effect, dt )
	end
end

function ParticleManager:createEffect ( max_particles )
	local effect = ParticleEffect:new ( )
	effect.max_particles = max_particles
	effect.particles_allocated = max_particles
	
	for i = 1, max_particles do
		local particle = Particle:new ( )
		table.insert ( effect.particles, particle )
	end
	
	local newIndex = table.getn ( self.effect_vec ) + 1
	self.effect_vec [ newIndex ] = effect
	
	return newIndex
end

function ParticleManager:setMaxParticles ( effect_id, max_particles )
	local effect = self.effect_vec [ effect_id ]
	effect:resize ( max_particles )
end

--[[
	PS
]]

--[[
	PS::CParticleEffect
]]
CParticleEffect = { }
CParticleEffect.__index = CParticleEffect

function CParticleEffect.new ( )
	local particleMngr = getParticleManager ( )
	local particleEffect = {
		handleEffect = particleMngr:createEffect ( 1 ),
		handleActionList = particleMngr:createActionList ( ),
		def = 0,
		elapsedLimit = nil,
		memDT = 0,
		initialPosition = { x = 0, y = 0, z = 0 }
	}
	
	-- TEST
	local x, y, z = getElementPosition ( localPlayer )
	particleEffect.xform = makeMatrix(x, y, z-1, 0, 0, 0 )
	
	return setmetatable ( particleEffect, CParticleEffect )
end

function CParticleEffect:setBirthDeadCB ( bc, dc, def, param )
	local particleMngr = getParticleManager ( )
	particleMngr:setCallback ( self.handleEffect, bc, dc, def, param )
end

function CParticleEffect:play ( )
	--self.RT_Flags = bitAnd ( self.RT_Flags, 0xFD )
	--self.RT_Flags = bitOr ( self.RT_Flags, 1 )
	
	local particleMngr = getParticleManager ( )
	particleMngr:playEffect ( self.handleEffect, self.handleActionList )
	
	self.flagEnabled = true
end

function CParticleEffect:stop ( defferedStop )
	local particleMngr = getParticleManager ( )
	particleMngr:stopEffect ( self.handleEffect, self.handleActionList, defferedStop )
	--[[if defferedStop then
		self.RT_Flags = bitOr ( self.RT_Flags, 2 )
		self.RT_Flags = bitAnd ( self.RT_Flags, 0xFE )
	end]]
	
	self.flagEnabled = nil
end

function CParticleEffect:isPlaying ( )
	return bitAnd ( self.RT_Flags, 1 ) == 1
end

function CParticleEffect:getTimeLimit ( )
	if bitAnd ( self.def.flags, 0x40 ) > 0 then
		return self.def.timeLimit
	else
		return -1
	end
end

function CParticleEffect:onFrame ( frame_dt )
	-- TEST
	if self.flagEnabled ~= true then
		return
	end

	self.memDT = self.memDT + frame_dt
	if self.memDT >= 33 then
		local stepCount = self.memDT / 33
		self.memDT = self.memDT % 33
		
		if self.elapsedLimit then
			self.elapsedLimit = self.elapsedLimit - DT_STEP
			if self.elapsedLimit < 0 then
				self.elapsedLimit = self.def.timeLimit
				self:stop ( true )
				return
			end
		end
		
		local particleMngr = getParticleManager ( )
		particleMngr:update ( self.handleEffect, self.handleActionList, DT_STEP )
		local particles, p_count = particleMngr:getParticles ( self.handleEffect )
		
		if self.def.flagAnimated then
			self.def:executeAnimate ( particles, p_count, DT_STEP )
		end
	end
end

local DEBUG = false
local RT = dxCreateRenderTarget ( sw, sh )

local _drawSprite = function ( up, right, pos, lt, rb, r1, r2, color, angle, shader, screen )
	local angleSin = math.sin ( angle )
	local angleCos = math.cos ( angle )
	local v12 = ( angleSin * up.x + angleCos * right.x ) * r1
	local v13 = ( angleCos * right.y + angleSin * up.y ) * r1
	local v14 = ( angleCos * right.z + angleSin * up.z ) * r1
		
	local v15 = angleCos * up.x * r2 - angleSin * r2 * right.x;
	local v16 = angleCos * up.y * r2 - angleSin * right.y * r2
	local v17 = angleCos * up.z * r2 - angleSin * right.z * r2
		
	local v18 = v15 - v12
	local v19 = v16 - v13
	local v20 = v17 - v14
	local v1SubX = v15 + v12
	local v1SubY = v16 + v13
	local v1SubZ = v17 + v14
	local v3NegX = -v18
	local v3NegY = -v19
	local v3NegZ = -v20
	local v1NegX = -v1SubX
	local v1NegY = -v1SubY
	local v1NegZ = -v1SubZ

	local x1, y1, z1 = interpolateBetween ( pos.x + v18, pos.y + v19, pos.z + v20, pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ, 0.5, "Linear" )
	local x2, y2, z2 = interpolateBetween ( pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, 0.5, "Linear" )
	local width = getDistanceBetweenPoints3D ( pos.x + v18, pos.y + v19, pos.z + v20, pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ )
	
	--
	local x3, y3, z3 = interpolateBetween ( pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ, pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, 0.5, "Linear" )
	local spriteVec = Vector3D:new ( x1 - pos.x, y1 - pos.y, z1 - pos.z )
	spriteVec:Normalize ( )
	local rightVec = Vector3D:new ( x3 - pos.x, y3 - pos.y, z3 - pos.z )
	rightVec:Normalize ( )
	local faceToward = spriteVec:CrossV ( rightVec )
	faceToward:Normalize ( )
	--
	
	--if screen then
		--[[dxSetRenderTarget ( RT, true ) 
		
		local x, y = getScreenFromWorldPosition ( pos.x, pos.y, pos.z )
		if x then
			local leftTopX, leftTopY = getScreenFromWorldPosition ( pos.x + v18, pos.y + v19, pos.z + v20, 99999999, false )
			local rightTopX, rightTopY = getScreenFromWorldPosition ( pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ, 99999999, false )
			local leftBottomX, leftBottomY = getScreenFromWorldPosition ( pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, 99999999, false )
			local width = getDistanceBetweenPoints2D ( leftTopX, leftTopY, rightTopX, rightTopY )
			local height = getDistanceBetweenPoints2D ( leftTopX, leftTopY, leftBottomX, leftBottomY )
		
			dxDrawImage ( math.min ( x - width/2, sw - width - 10 ), math.min ( y - height/2, sh - height - 10 ), width, height, shader )
		end
		
		dxSetRenderTarget ( )]]
	--else
		dxDrawMaterialSectionLine3D ( 
			x1, y1, z1, x2, y2, z2,
			lt.x, lt.y, rb.x - lt.x, rb.y - lt.y,
			shader, width, color,
			pos.x + faceToward.x, pos.y + faceToward.y, pos.z + faceToward.z -- TEST
		)
	--end
	
	if DEBUG then
		dxDrawLine3D ( pos.x + v18, pos.y + v19, pos.z + v20, pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ, tocolor ( 255, 255, 0 ) )
		dxDrawLine3D ( pos.x + v1SubX, pos.y + v1SubY, pos.z + v1SubZ, pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, tocolor ( 255, 255, 0 ) )
		dxDrawLine3D ( pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, tocolor ( 255, 255, 0 ) )
		dxDrawLine3D ( pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, pos.x + v18, pos.y + v19, pos.z + v20, tocolor ( 255, 255, 0 ) )
		
		dxDrawLine3D ( x1, y1, z1, x2, y2, z2, tocolor ( 0, 255, 255 ) )
	end
end

local stdNumericLimitMin = 1.17549e-38
local _drawSprite2 = function ( pos, dir, lt, rb, r1, r2, color, angle, shader )
	local cx, cy, cz, lx, ly, lz = getCameraMatrix ( )
	local camDirX, camDirY, camDirZ = lx - cx, ly - cy, lz - cz
	
	local sinAngle = math.sin ( angle )
	local cosAngle = math.cos ( angle )

	a = camDirZ * dir.y - camDirY * dir.z
	a_4 = camDirX * dir.z - dir.x * camDirZ -- 652 = vCameraDirection
	v10 = dir.x * camDirY - camDirX * dir.y
	dira = v10 * v10 + a_4 * a_4 + a * a
	if stdNumericLimitMin < dira then
		v11 = math.sqrt ( 1 / dira )
		a = a * v11
		a_4 = a_4 * v11
		v10 = v11 * v10
	end
	v12 = ( sinAngle * dir.x + a * cosAngle ) * r1
	v13 = ( a_4 * cosAngle + sinAngle * dir.y ) * r1
	v14 = ( sinAngle * dir.z + v10 * cosAngle ) * r1
	v15 = cosAngle * dir.x * r2 - a * sinAngle * r2
	v16 = cosAngle * r2 * dir.y - a_4 * sinAngle * r2
	v17 = cosAngle * dir.z * r2 - v10 * sinAngle * r2
	v2DifX = v15 - v12
	v2DifY = v16 - v13
	v2DifZ = v17 - v14
	v1SumX = v15 + v12
	v1SumY = v16 + v13
	v1SumZ = v17 + v14
	v3NegX = -v2DifX
	v3NegY = -v2DifY
	v3NegZ = -v2DifZ
	v1NegX = -v1SumX
	v1NegY = -v1SumY
	v1NegZ = -v1SumZ
	
	local x1, y1, z1 = interpolateBetween ( pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ, 0.5, "Linear" )
	local x2, y2, z2 = interpolateBetween ( pos.x + v1SumX, pos.y + v1SumY, pos.z + v1SumZ, pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, 0.5, "Linear" )
	local width = getDistanceBetweenPoints3D ( pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ )
	
	x1, y1, z1 = interpolateBetween ( pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ, pos.x + v1SumX, pos.y + v1SumY, pos.z + v1SumZ, 0.5, "Linear" )
	x2, y2, z2 = interpolateBetween ( pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, 0.5, "Linear" )
	width = getDistanceBetweenPoints3D ( pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ, pos.x + v1SumX, pos.y + v1SumY, pos.z + v1SumZ )
	
	--
	local spriteVec = Vector3D:new ( ( pos.x + v2DifX ) - ( pos.x + v1NegX ), ( pos.y + v2DifY ) - ( pos.y + v1NegY ), ( pos.z + v2DifZ ) - ( pos.z + v1NegZ ) )
	spriteVec:Normalize ( )
	local rightVec = Vector3D:new ( ( pos.x + v3NegX ) - ( pos.x + v1NegX ), ( pos.y + v3NegY ) - ( pos.y + v1NegY ), ( pos.z + v3NegZ ) - ( pos.z + v1NegZ ) )
	rightVec:Normalize ( )
	local faceToward = spriteVec:CrossV ( rightVec )
	faceToward:Normalize ( )
	--
	
	--[[dxDrawMaterialLine3D ( x1, y1, z1, x2, y2, z2, shader, width, color, 
		pos.x + faceToward.x, pos.y + faceToward.y, pos.z + faceToward.z -- TEST
	)]]
	dxDrawMaterialSectionLine3D ( 
		x1, y1, z1, x2, y2, z2,
		lt.x, lt.y, rb.x - lt.x, rb.y - lt.y,
		shader, width, color,
		pos.x + faceToward.x, pos.y + faceToward.y, pos.z + faceToward.z -- TEST
	)

	if DEBUG then
		dxDrawLine3D ( pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ, tocolor ( 0, 255, 0 ) )
		dxDrawLine3D ( pos.x + v2DifX, pos.y + v2DifY, pos.z + v2DifZ, pos.x + v1SumX, pos.y + v1SumY, pos.z + v1SumZ, tocolor ( 0, 255, 0 ) )
		dxDrawLine3D ( pos.x + v1SumX, pos.y + v1SumY, pos.z + v1SumZ, pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, tocolor ( 0, 255, 0 ) )
		dxDrawLine3D ( pos.x + v3NegX, pos.y + v3NegY, pos.z + v3NegZ, pos.x + v1NegX, pos.y + v1NegY, pos.z + v1NegZ, tocolor ( 0, 255, 0 ) )
		
		dxDrawLine3D ( x1, y1, z1, x2, y2, z2, tocolor ( 0, 255, 255 ) )
	end
end

UNKNOWN_FLAG_4 = true
local function _matrixSetXYZ ( matrix, xyz )
	local ypos = xyz.y
	local zpos = xyz.z
	local siny = math.sin(xyz.y)
	local xpos = xyz.x
	matrix[1][4] = 0
	local siny_ = siny
	local cosy = math.cos(ypos)
	local sinx = math.sin(xpos)
	local cosx = math.cos(xpos)
	local sinz = math.sin(zpos)
	local cosz = math.cos(zpos)
	local v11 = cosz * cosy
	local v12 = cosz * siny_
	local v13 = sinz * siny_
	local v14 = v13
	matrix[1][1] = v11 - v13 * sinx
	matrix[1][2] = -(sinz * cosx)
	matrix[1][3] = sinz * cosy * sinx + v12
	matrix[2][1] = v12 * sinx + sinz * cosy
	matrix[2][2] = cosz * cosx
	matrix[2][3] = v14 - v11 * sinx
	matrix[3][1] = -(cosx * siny_)
	matrix[3][2] = sinx
	matrix[3][3] = cosx * cosy
	matrix[4][1] = 0
	
	matrix[4][2] = 0
	
	matrix[4][3] = 0
	matrix[4][4] = 1065353216
end

local ii = 0

setTimer ( function ( ) ii = ii + 1 if ii > 76 then ii = 0 end end, 50, 0 )

function CParticleEffect:_renderParticle ( particle, lod )
	local def = self.def

	local lt = { x = 0, y = 0 }
	local rb = { x = 0, y = 0 }
	local pos = { x = 2041.32983 + particle.pos.x, y = 1367.62109 + particle.pos.y, z = 10.67188 + particle.pos.z }

	local right = { x = 1, y = 0, z = 0 }
	local up = { x = 0, y = 0, z = 1 }
	local color = tocolor ( particle.color.r, particle.color.g, particle.color.b, particle.color.a )
	
	-- Frame существует?
	if UNKNOWN_FLAG_4 then
		local frame = particle.frame
		local width, height = dxGetMaterialSize ( def.textureElement )
		local partWidth, partHeight = width * def.frameTexSizeX , height * def.frameTexSizeY
		local dimX = math.floor ( width / partWidth )
		
		lt.x = math.floor ( frame % dimX ) * partWidth
		lt.y = math.floor ( frame / dimX ) * partHeight
	
		rb.x = lt.x + partWidth
		rb.y = lt.y + partHeight
	end
	
	local r_x = particle.size.x * 0.5
	local r_y = particle.size.z * 0.5
	if def.velocityScale ~= nil then
		local speed = math.sqrt ( particle.vel.x*particle.vel.x + particle.vel.y*particle.vel.y + particle.vel.z*particle.vel.z )
		r_x = speed * def.velocityScale.x + r_x
		r_y = speed * def.velocityScale.z + r_y
	end
	
	-- Если секция Movement отключена
	if def.APDefaultRotation == nil then
		if UNKNOWN_FLAG_4 then -- Флаг обычно стоит всегда
			pos.x = self.xform[3][1]*particle.pos.z + self.xform[2][1]*particle.pos.y + self.xform[1][1]*particle.pos.x + self.xform[4][1]
			pos.y = self.xform[1][2]*particle.pos.x + self.xform[3][2]*particle.pos.z + self.xform[2][2]*particle.pos.y + self.xform[4][2]
			pos.z = self.xform[1][3]*particle.pos.x + self.xform[3][3]*particle.pos.z + self.xform[2][3]*particle.pos.y + self.xform[4][3]
		else
			pos = particle.pos
		end
		
		local cx, cy, cz = getCameraMatrix ( )
		local vecToCam = Vector3D:new ( cx - pos.x, cy - pos.y, cz - pos.z )
		vecToCam:Normalize ( )
		local upVector = Vector3D:new ( 0, 1, 0 )
		
		right = vecToCam:CrossV ( upVector )
		right:Normalize ( )
		up = right:CrossV ( vecToCam )
		up:Normalize ( )
	else
		local speed = math.sqrt ( particle.vel.x*particle.vel.x + particle.vel.y*particle.vel.y + particle.vel.z*particle.vel.z )
		if speed < 0.0000001 and UNKNOWN_FLAG_9999  then
			local M = {{},{},{},{}}
			_matrixSetXYZ ( M, def.APDefaultRotation )
			 
			if UNKNOWN_FLAG_4 then -- Флаг обычно стоит всегда
				local v16 = self.xform[2][1] * particle.pos.y
				local v17 = self.xform[3][1] * particle.pos.z
				local v115 = M[1][3]
				local v116 = M[2][2]
				local v18 = v16 + v17
				local v19 = self.xform[1][1] * particle.pos.x
				local v117 = M[3][2]
				M[1][4] = 0
				pos.x = v18 + v19 + self.xform[4][1]
				pos.y = self.xform[2][2] * particle.pos.y + self.xform[1][2] * particle.pos.x + self.xform[3][2] * particle.pos.z + self.xform[4][2]
				pos.z = self.xform[2][3] * particle.pos.y + self.xform[1][3] * particle.pos.x + self.xform[3][3] * particle.pos.z + self.xform[4][3]
				local v20 = M[1][1]
				local v21 = M[1][2]
				local v22 = M[2][1]
				local v23 = M[3][1]
				M[1][1] = M[1][1] * self.xform[1][1] + M[3][1] * self.xform[1][3] + M[2][1] * self.xform[1][2]
				M[1][2] = M[1][2] * self.xform[1][1] + M[3][2] * self.xform[1][3] + M[2][2] * self.xform[1][2]
				M[1][3] = M[1][3] * self.xform[1][1] + M[3][3] * self.xform[1][3] + M[2][3] * self.xform[1][2]
				M[2][1] = M[3][1] * self.xform[2][3] + M[2][1] * self.xform[2][2] + v20 * self.xform[2][1]
				local v25 = v21 * self.xform[2][1]
				M[2][4] = 0
				local v27 = M[3][2] * self.xform[2][3]
				M[3][4] = 0
				M[4][4] = 1065353216
				M[2][2] = v25 + v27 + M[2][2] * self.xform[2][2]
				M[2][3] = v115 * self.xform[2][1] + M[3][3] * self.xform[2][3] + M[2][3] * self.xform[2][2]
				M[3][1] = M[3][1] * self.xform[3][3] + v22 * self.xform[3][2] + v20 * self.xform[3][1]
				M[3][2] = v21 * self.xform[3][1] + M[3][2] * self.xform[3][3] + v116 * self.xform[3][2]
				M[3][3] = v115 * self.xform[3][1] + M[3][3] * self.xform[3][3] + (v116 + 1) * self.xform[3][2]
				M[4][1] = v22 * self.xform[4][2] + v23 * self.xform[4][3] + v20 * self.xform[4][1] + M[4][1]
				M[4][2] = v21 * self.xform[4][1] + v116 * self.xform[4][2] + v117 * self.xform[4][3] + M[4][2]
				M[4][3] = v115 * self.xform[4][1] + (v116 + 1) * self.xform[4][2] + (v117 + 1) * self.xform[4][3] + M[4][3]
				
				right = { x = M [1][1], y = M[1][2], z = M[1][3] }
				up = { x = M[3][1], y = M[3][2], z = M[3][3] }
			else
				pos = particle.pos
				right = { x = M [1][1], y = M[1][2], z = M[1][3] }
				up = { x = M[3][1], y = M[3][2], z = M[3][3] }
			end
		else 
			if speed < 0.0000001 then
				local defRotX = -def.APDefaultRotation.x
				local defRotY = -def.APDefaultRotation.y
				local cosRot = math.cos ( defRotX )
				local dir = Vector3D:new (
					-( math.sin ( defRotY ) * cosRot ),
					math.cos ( defRotY ) * cosRot, -- Z перемешано
					math.sin ( defRotX ) -- Y перемешано
				)
	
				if not UNKNOWN_FLAG_4 then -- Флаг обычно стоит всегда
					_drawSprite2 ( pos, dir, lt, rb, r_x, r_y, color, particle.rot.x,
						def.cachedShader-- TEST
					)
				else
					pos.x = self.xform[2][1]*particle.pos.y + self.xform[3][1]*particle.pos.z + self.xform[1][1]*particle.pos.x + self.xform[4][1]
					pos.y = self.xform[2][2]*particle.pos.y + self.xform[1][2]*particle.pos.x + self.xform[3][2]*particle.pos.z + self.xform[4][2]
					pos.z = self.xform[2][3]*particle.pos.y + self.xform[1][3]*particle.pos.x + self.xform[3][3]*particle.pos.z + self.xform[4][3]
	
					dir.x = dir.z*self.xform[3][1] + dir.y*self.xform[2][1] + dir.x*self.xform[1][1]
					dir.y = dir.x*self.xform[1][2] + dir.z*self.xform[3][2] + dir.y*self.xform[2][2]
					dir.z = dir.x*self.xform[1][3] + dir.z*self.xform[3][3] + dir.y*self.xform[2][3]
					
					_drawSprite2 ( pos, dir, lt, rb, r_x, r_y, color, particle.rot.x,
						def.cachedShader-- TEST
					)
				end
				return
			end
		
			local speedInv = 1 / speed
			local dir = {
				x = speedInv * particle.vel.x,
				y = speedInv * particle.vel.y,
				z = speedInv * particle.vel.z
			}
		
			if def.velocityScale ~= nil then -- velocity scale??
				pos.x = self.xform[2][1]*particle.pos.y + self.xform[3][1]*particle.pos.z + self.xform[1][1]*particle.pos.x + self.xform[4][1]
				pos.y = self.xform[2][2]*particle.pos.y + self.xform[1][2]*particle.pos.x + self.xform[3][2]*particle.pos.z + self.xform[4][2]
				pos.z = self.xform[2][3]*particle.pos.y + self.xform[1][3]*particle.pos.x + self.xform[3][3]*particle.pos.z + self.xform[4][3]
	
				dir.x = dir.z*self.xform[3][1] + dir.y*self.xform[2][1] + dir.x*self.xform[1][1]
				dir.y = dir.x*self.xform[1][2] + dir.z*self.xform[3][2] + dir.y*self.xform[2][2]
				dir.z = dir.x*self.xform[1][3] + dir.z*self.xform[3][3] + dir.y*self.xform[2][3]
	
				_drawSprite2 ( pos, dir, lt, rb, r_x, r_y, color, particle.rot.x,
					def.cachedShader-- TEST
				)
				return
			end
		
			local v30 = 1
			local v31 = 0
			if math.abs ( dir.y ) > 0.99000001 then
				v30 = 0
				v31 = 1
			end
			
			local right_ = {
				x = v30 * dir.z - v31 * dir.y,
				y = v31 * dir.x,
				z = v30 * dir.x
			}
			local factor = math.sqrt ( 1 / ( right_.x * right_.x + right_.z * right_.z + right_.y * right_.y ) )
			right_.x = right_.x * factor
			right_.y = right_.y * factor
			right_.z = right_.z * factor
			
			local up_ = {
				x = right_.z * dir.y - right_.y * dir.z,
				y = dir.z * right_.x - right_.z * dir.x,
				z = right_.y * dir.x - dir.y * right_.x
			}
			factor = math.sqrt ( 1.0 / ( up_.x * up_.x + up_.z * up_.z + up_.y * up_.y ) )
			up_.x = factor * up_.x
			up_.y = up_.y * factor
			up_.z = up_.z * factor
			
			if not UNKNOWN_FLAG_4 then
				up = up_
				right = right_
			else
				local v92 = 0
				local v94 = 0
				local v95 = 0
				local v97 = 0
				local v98 = 0
				local v90 = 0
				local v91 = 0
				local v93 = 0
				local v96 = 0
				local v99 = 0
				local v100 = 0
				local v101 = 0
				
			
				local v38 = self.xform[2][1]*particle.pos.y
				local v39 = self.xform[3][1]*particle.pos.z
				local v118 = v92
				local v119 = v94
				local v40 = v38 + v39
				local v41 = self.xform[1][1]
				local v120 = v95
				local v42 = v41*particle.pos.x
				local v121 = v97
				local v122 = v98
				local v106 = v40 + v42 + self.xform[4][1]
				local v107 = self.xform[2][2]*particle.pos.y + self.xform[1][2]*particle.pos.x + self.xform[3][2]*particle.pos.z + self.xform[4][2]
				local v108 = self.xform[2][3]*particle.pos.y + self.xform[1][3]*particle.pos.x + self.xform[3][3]*particle.pos.z + self.xform[4][3]
				local v43 = v90
				local v44 = v91
				local v45 = v93
				local v46 = v96
				local v90 = v90*self.xform[1][1] + v96*self.xform[1][3] + v93*self.xform[1][2]
				local v91 = v97*self.xform[1][3] + v94*self.xform[1][2] + v91*self.xform[1][1]
				local v92 = v98*self.xform[1][3] + v95*self.xform[1][2] + v92*self.xform[1][1]
				local v93 = v93*self.xform[2][2] + v43*self.xform[2][1] + v96*self.xform[2][3]
				
				local v94 = v94*self.xform[2][2] + v44*self.xform[2][1] + v97*self.xform[2][3]
				local v95 = v95*self.xform[2][2] + v118*self.xform[2][1] + v98*self.xform[2][3]
				local v96 = v45*self.xform[3][2] + v43*self.xform[3][1] + v96*self.xform[3][3]
				local v97 = v119*self.xform[3][2] + v44*self.xform[3][1] + v97*self.xform[3][3]
				local v98 = v120*self.xform[3][2] + v118*self.xform[3][1] + v98*self.xform[3][3]
				local v99 = v45*self.xform[4][2] + v43*self.xform[4][1] + v46*self.xform[4][3] + v99
				local v100 = v119*self.xform[4][2] + v44*self.xform[4][1] + v121*self.xform[4][3] + v100
				local v101 = v120*self.xform[4][2] + v118*self.xform[4][1] + v122*self.xform[4][3] + v101
				
				pos = {
					x = v106,
					y = v107,
					z = v108
				}
				
				up = up_
				right = right_
			end
		end
	end
	_drawSprite ( up, right, pos, lt, rb, r_x, r_y, color, particle.rot.x, 
		def.cachedShader,-- TEST
		def.shaderName == "xdistort"
	)
end
function CParticleEffect:render ( lod )
	-- TEST
	if self.flagEnabled ~= true then
		return
	end

	local particleMngr = getParticleManager ( )
	local particles, p_count = particleMngr:getParticles ( self.handleEffect )
	
	for i = 1, p_count do
		local particle = particles [ i ]
		self:_renderParticle ( particle, lod )
	end
end

function CParticleEffect:compile ( def )
	self.def = def
	if def then
		local particleMngr = getParticleManager ( )
		
		local xml = xmlLoadFile ( "effects/" .. def.name .. ".xml" )
		local actionsNode = xmlNodeGetChildren ( xml, def.actionsIndex - 1 )
		particleMngr:loadActions ( self.handleActionList, actionsNode )
		particleMngr:setMaxParticles ( self.handleEffect, def.maxParticles )
		xmlUnloadFile ( xml )
		
		if def.timeLimit ~= nil then
			self.elapsedLimit = def.timeLimit
		end
	end
end

--[[
	CParticleGroup
]]
CParticleGroup = { }
CParticleGroup.__index = CParticleGroup

function CParticleGroup.new ( )
	local group = {
	
	}
	
	return setmetatable ( group, CParticleGroup )
end

--[[
	xrGame::CParticlesObject
]]
CParticlesObject = { }
CParticlesObject.__index = CParticlesObject

function CParticlesObject.new ( name, autoRemove )
	local obj = {
		
	}
	
	return setmetatable ( obj, CParticlesObject )
end

function CParticlesObject:init ( name, autoRemove )
	self.looped = false
	self.stopped = false
	
end


--[[

xrGame::CBaseMonster::PlayParticles
xrGame::CParticlesObject::SetXFORM
xrRender_R2::CParticleGroup::UpdateParent

xrGame::CCustomZone - аномалии

]]

--[[
	PS::CPEDef
]]
CPEDef = { }
CPEDef.__index = CPEDef

function CPEDef.new ( )
	local def = {
		name = nil,
		shaderName = nil,
		textureName = nil,
		cachedShader = nil,
		actionsIndex = nil,
		frameTexSizeX = 1,--0.125,
		frameTexSizeY = 1,--0.125,
		frameDimX = 1,
		frameCount = 1,
		frameSpeed = 24,
		maxParticles = 0,
		timeLimit = nil,
		collideResilience = 0,
		collideSqrCutoff = 0,
		collideOneMinusFriction = 1,
		velocityScale = nil,
		APDefaultRotation = nil
	}
	
	return setmetatable ( def, CPEDef )
end

-- Загрузка определения эффекта из XML файла
function CPEDef:load ( xml )
	self.name = xmlNodeGetAttribute ( xml, "name" )
	self.maxParticles = tonumber ( 
		xmlNodeGetAttribute ( xml, "maxParticles" ) 
	)
	for i, node in ipairs ( xmlNodeGetChildren ( xml ) ) do
		local nodeName = xmlNodeGetName ( node )
		if nodeName == "timeLimit" then
			self.timeLimit = tonumber (
				xmlNodeGetAttribute ( node, "value" )
			)
		elseif nodeName == "sprite" then
			self.textureName = xmlNodeGetAttribute ( node, "texture" )
			self.shaderName = xmlNodeGetAttribute ( node, "shader" )
			
			for _, node in ipairs ( xmlNodeGetChildren ( node ) ) do
				nodeName = xmlNodeGetName ( node )
				if nodeName == "culling" then
					self.flagCCW = xmlNodeGetAttribute ( node, "ccw" ) == "true"
				elseif nodeName == "frame" then
					self.flagRandomInit = xmlNodeGetAttribute ( node, "randomInit" ) == "true"
					self.frameCount = tonumber (
						xmlNodeGetAttribute ( node, "count" )
					)
					self.frameTexSizeX = tonumber (
						xmlNodeGetAttribute ( node, "sizeU" )
					)
					self.frameTexSizeY = tonumber (
						xmlNodeGetAttribute ( node, "sizeV" )
					)
				elseif nodeName == "animated" then
					self.flagRandomPlayback = xmlNodeGetAttribute ( node, "randomPlayback" ) == "true"
					self.frameSpeed = tonumber (
						xmlNodeGetAttribute ( node, "speed" )
					)
					self.flagAnimated = true
				end
			end
		elseif nodeName == "movement" then
			for _, node in ipairs ( xmlNodeGetChildren ( node ) ) do
				nodeName = xmlNodeGetName ( node )
				if nodeName == "alignToPath" then
					self.flagFaceAlign = xmlNodeGetAttribute ( node, "faceAlign" ) == "true"
					self.flagWorldAlign = xmlNodeGetAttribute ( node, "defaultWorldAlign" ) == "true"
					self.APDefaultRotation = utilXmlReadFloat3 ( node, "defaultRotate" )
					self.APDefaultRotation.x = math.rad ( self.APDefaultRotation.x )
					self.APDefaultRotation.y = math.rad ( self.APDefaultRotation.y )
					self.APDefaultRotation.z = math.rad ( self.APDefaultRotation.z )
				elseif nodeName == "velocityScale" then
					self.velocityScale = utilXmlReadFloat3 ( node, "value" )
				elseif nodeName == "collision" then
					self.flagCollideDynamic = xmlNodeGetAttribute ( node, "collideWithDynamic" ) == "true"
					self.flagDestroyContact = xmlNodeGetAttribute ( node, "destroyOnContact" ) == "true"
					self.friction = tonumber (
						xmlNodeGetAttribute ( node, "friction" )
					)
					self.resilence = tonumber (
						xmlNodeGetAttribute ( node, "resilence" )
					)
					self.cutoff = tonumber (
						xmlNodeGetAttribute ( node, "cutoff" )
					)
				end
			end
		elseif nodeName == "actions" then
			self.actionsIndex = i
		end
	end
	
	-- FOR TEST
	self.cachedShader = dxCreateShader ( "shaders/" .. self.shaderName .. ".fx" )
	self.textureElement = dxCreateTexture ( "textures/" .. self.textureName .. ".dds" )
	dxSetShaderValue ( self.cachedShader, "Tex0", self.textureElement )
end

function CPEDef:executeAnimate ( particles, p_cnt, dt )
	local speedFac = dt * self.frameSpeed;
	
	for i = 1, p_cnt do
		local particle = particles [ i ]
		
		-- Random playback TODO
		particle.frame = particle.frame + speedFac
		if particle.frame >= self.frameCount then
			particle.frame = 0
		end
	end
end

local particleMngr = ParticleManager:new ( )
function getParticleManager ( )
	return particleMngr
end

local effects = { }
local defs = { }

function createDefinition ( name )
	local xml = xmlLoadFile ( "effects/" .. name .. ".xml" )
	if xml then
		local def = CPEDef.new ( )
		def:load ( xml )
		xmlUnloadFile ( xml )
		
		return def
	else
		outputDebugString ( "Файла " .. name .. " не существует!", 1 )
	end
end

function createParticleEffect ( def )
	local effect = CParticleEffect.new ( )
	effect:compile ( def )
	effect:play ( )
		
	return effect
end

local createElectraAnomaly = function ( x, y, z )
	if defs [ "anomaly_electra_idle_sparks" ] == nil then
		defs [ "anomaly_electra_idle_sparks" ] = createDefinition ( "anomaly_electra_idle_sparks" )
	end
	if defs [ "electra_disk" ] == nil then
		defs [ "electra_disk" ] = createDefinition ( "electra_disk" )
	end
	
	local effect = createParticleEffect ( defs [ "anomaly_electra_idle_sparks" ] )
	effect.xform [ 4 ] [ 1 ] = x; effect.xform [ 4 ] [ 2 ] = y; effect.xform [ 4 ] [ 3 ] = z;
	table.insert ( effects, effect )
	
	effect = createParticleEffect ( defs [ "electra_disk" ] )
	effect.xform [ 4 ] [ 1 ] = x; effect.xform [ 4 ] [ 2 ] = y; effect.xform [ 4 ] [ 3 ] = z;
	table.insert ( effects, effect )
end


local _onEffectParticleBirth = function ( def, param, particle, idx )
	particle.frame = math.random ( 0, def.frameCount - 1 )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		
	end
, false )

addEventHandler ( "onClientResourceStop", resourceRoot,
	function ( )
		exports["sp_world"]:clearAllPoints ( )
	end
, false )

local _dist3d = getDistanceBetweenPoints3D
function effect_sort ( cx, cy, cz )
	local tbl = effects
	local temp
	for i = 1, #tbl - 1 do
		for j = i, #tbl do
			local x, y, z = tbl [ i ].xform[4][1], tbl [ i ].xform[4][2], tbl [ i ].xform[4][3]
			local x2, y2, z2 = tbl [ j ].xform[4][1], tbl [ j ].xform[4][2], tbl [ j ].xform[4][3]
				
			if _dist3d ( cx, cy, cz, x, y, z ) > _dist3d ( cx, cy, cz, x2, y2, z2 ) then
				temp = tbl [ i ]
				tbl [ i ] = tbl [ j ]
				tbl [ j ] = temp
			end
		end
	end
end

local FX_MAX = 20

addCommandHandler ("particlelimit",
	function ( _, num )
		FX_MAX = tonumber ( num ) or 20
	end
)

local lastSort = getTickCount ( )
addEventHandler ( "onClientPreRender", root,
	function ( tpf )
		local now = getTickCount ( )
		if now - lastSort > 500 then
			lastSort = now
			
			local cx, cy, cz = getCameraMatrix ( )
			effect_sort ( cx, cy, cz )
		end
	
		local cnt = 0
	
		for i = 1, FX_MAX do
			local effect = effects [ i ]
			if effect then
				effect:onFrame ( tpf )
				effect:render ( 0 )
				
				cnt = cnt + 1
			end
		end
		
		dxDrawText ( "Particle effects :" .. cnt, sw - 150, sh / 2 )
		
		DEBUG = getKeyState ( "z" ) == true
	end
, false )


addEvent ( "createFirebin", true )
addEventHandler ( "createFirebin", root,
	function ( )
		local x, y, z = getElementPosition ( source )

		local dump = 0.1
		
		def = createDefinition ( "campfire_flame" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		effect:setBirthDeadCB ( _onEffectParticleBirth, nil, def, nil )
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_smoke" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_sparks" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_vacum" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_glow" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		exports["mapdff"]:createPointLight ( x, y, z + dump, 240, 103, 67 )
		
		playSound3D ( "sounds/fire2.ogg", x, y, z, true )
	end
)

addEvent ( "createAno1", true )
addEventHandler ( "createAno1", root,
	function ( x, y, z )
		createElectraAnomaly ( x, y, z )
		
		playSound3D ( "sounds/electra_idle1.ogg", x, y, z, true )
		
		addAnomalyDetector ( x, y, z )
		
		exports["mapdff"]:createPointLight ( x, y, z, 137, 154, 189 )
	end
)

addEvent ( "createAno2", true )
addEventHandler ( "createAno2", root,
	function ( x, y, z )
		local dump = 0.4
		
		local def = createDefinition ( "studen/hit_studen_hit_distort_01" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "studen/studen_idle_bottom" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "studen/studen_idle_glow_01" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		playSound3D ( "sounds/buzz_idle.ogg", x, y, z, true )
		
		addAnomalyDetector ( x, y, z )
		
		exports["mapdff"]:createPointLight ( x, y, z, 45, 107, 63 )
	end
)


--[[bindKey ( "x", "down",
	function ( )
		local x, y, z = getPositionFromElementOffset ( localPlayer, 0, 0, -1 )

		local dump = 0
		
		def = createDefinition ( "campfire_flame" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		effect:setBirthDeadCB ( _onEffectParticleBirth, nil, def, nil )
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_smoke" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_sparks" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_vacum" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "campfire_glow" )
		effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		exports["sp_world"]:createPointLight ( x, y, z + dump, 240, 103, 67 )
		
		createObject ( 3781, x, y, z )
		
		playSound3D ( "sounds/fire2.ogg", x, y, z, true )
	end
)

bindKey ( "n", "down",
	function ( )
		local x, y, z = getPositionFromElementOffset ( localPlayer, 0, 1, -1 )
		
		createElectraAnomaly ( x, y, z )
		
		playSound3D ( "sounds/electra_idle1.ogg", x, y, z, true )
		
		addAnomalyDetector ( x, y, z )
		
		exports["sp_world"]:createPointLight ( x, y, z, 137, 154, 189 )
	end
)

bindKey ( "b", "down",
	function ( )
		local x, y, z = getPositionFromElementOffset ( localPlayer, 0, 1, -1 )
		
		local dump = 0.4
		
		local def = createDefinition ( "studen/hit_studen_hit_distort_01" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "studen/studen_idle_bottom" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		def = createDefinition ( "studen/studen_idle_glow_01" )
		local effect = createParticleEffect ( def )
		effect.xform[4][1] = x; effect.xform[4][2] = y; effect.xform[4][3] = z + dump;
		table.insert ( effects, effect )
		
		playSound3D ( "sounds/buzz_idle.ogg", x, y, z, true )
		
		addAnomalyDetector ( x, y, z )
		
		exports["sp_world"]:createPointLight ( x, y, z, 45, 107, 63 )
	end
)]]

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		-- TEST
		local col_floors = engineLoadCOL ( "models/prop_barrel2_fire.col" )
		engineReplaceCOL ( col_floors, 3781 )
		local txd_floors = engineLoadTXD ( "models/prop_barrel2_fire.txd" )
		engineImportTXD ( txd_floors, 3781 )
		local dff_floors = engineLoadDFF ( "models/prop_barrel2_fire.dff", 3781 )
		engineReplaceModel ( dff_floors, 3781 )
	end
, false )