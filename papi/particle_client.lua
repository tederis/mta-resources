--[[
	Particles & XRAY & 24.06.2012

	Существует два типа эффектов:
		-Групповые, включающие в себя несколько эффектов. Аномалии работают исключительно с группами.
		-Одиночные, из которых соответственно формируются группы.
	Структура группового эффекта:
		-Group
			-Effect 1
				-Child 1 - одиночные эффекты могут иметь включения.
			-Effect 2
			-Effect 3
	
	Система частиц состоит из непосредственно класса частиц и менеджера частиц.
	
	Частица не имеет как такового времени жизни, она просто удаляется через некоторый промежуток времени независимо от прогресса ее трансформации.
]]

function tocolor2 ( r, g, b, a )
	r = math.max ( 100, r )
	g = math.max ( 100, g )
	b = math.max ( 100, b )
	
	return tocolor ( r, g, b, a )
end

-------------------------------------------
-- Particle
-- Отдельная частица
-------------------------------------------
Particle = { }
Particle.__index = Particle

function Particle.create ( effect, x, y, z, size )
	local now = getTickCount ( )
	
	local particle = {
		x = x, y = y, z = z,

		--Добавляем время старта и окончания
		ageLimit = effect.killOld.ageLimit,
		startTime = now,
		
		timer = 0,
		scale = 0
	}
	
	setmetatable ( particle, Particle )
	
	particle:initSourceVectors ( effect )
	
	return particle
end

function Particle:draw ( tpf )
	local now = getTickCount ( )
	
	--local elapsedTime = now - self.startTime
	local progress = self.timer / self.ageLimit
	
	--[[local sizeX, sizeY, sizeZ = self.sourceSize [ 1 ], self.sourceSize [ 2 ], self.sourceSize [ 3 ]
	if self.targetSize then
		sizeX, sizeY, sizeZ = interpolateBetween ( 
			self.sourceSize [ 1 ], self.sourceSize [ 2 ], self.sourceSize [ 3 ], 
			self.targetSize [ 1 ], self.targetSize [ 2 ], self.targetSize [ 3 ], progress, "Linear" 
		)
	end]]
	self.size = math.min ( self.size + 0.1, self.targetSize [ 1 ] )
	local sizeX, sizeY, sizeZ = self.size, self.size, self.size
	
				
	local r, g, b = interpolateBetween ( 
		self.sourceColor [ 1 ], self.sourceColor [ 2 ], self.sourceColor [ 3 ],
		self.targetColor [ 1 ], self.targetColor [ 2 ], self.targetColor [ 3 ], progress, "Linear" 
	)
	local a = math.slerp ( self.sourceColor [ 4 ], self.targetColor [ 4 ], progress )
					
	if self.sourceVelocity then
		local vx, vy, vz = self.sourceVelocity [ 1 ], self.sourceVelocity [ 2 ], self.sourceVelocity [ 3 ]
		if self.targetVelocity then
			vx, vy, vz = interpolateBetween ( vx, vy, vz, self.targetVelocity [ 1 ], self.targetVelocity [ 2 ], self.targetVelocity [ 3 ],
				progress, "Linear" )
		end
		
		if self.velocityScale then
			--vz = vz + self.velocityScale
		end
		
		--local acc = 0.0006 * tpf
		local acc = 0.009
			
		self.position [ 1 ] = self.position [ 1 ] + vx*acc
		self.position [ 2 ] = self.position [ 2 ] + vy*acc
		self.position [ 3 ] = self.position [ 3 ] + vz*acc
	end
	
	local rotation = math.slerp ( self.sourceRotation [ 1 ] / 360, self.targetRotate [ 1 ] / 360, progress )
	
	if self.faceToward then
		local lx1, ly1, lx2, ly2 = rotateLine ( 
			self.position [ 1 ], self.position [ 2 ],
							
			self.position [ 1 ] - sizeX/2, self.position [ 2 ],
			self.position [ 1 ] + sizeX/2, self.position [ 2 ],
			self.sourceRotation and self.sourceRotation [ 1 ] or 0
		)

		_dxDrawMaterialLine3D ( lx1, ly1, self.position [ 3 ], 
			lx2, ly2, self.position [ 3 ], 
			self.material, sizeX, tocolor ( r, g, b, a ),
			self.faceToward [ 1 ], self.faceToward [ 2 ], self.faceToward [ 3 ]
		)
	else
		dxDrawMaterialLine3D ( 
			self.position [ 1 ], self.position [ 2 ], self.position [ 3 ], 
			sizeX, sizeY, self.material, tocolor ( r, g, b, a ), rotation
		)
	end
end

function Particle:initSourceVectors ( effect )
	--Исходные значения
	self.position = Particle.getRandomVector ( self.x, self.y, self.z, effect.source.domain )
	self.sourceVelocity = Particle.getRandomVector ( 0, 0, 0, effect.source.velocity )
	self.sourceRotation = Particle.getRandomVector ( 0, 0, 0, effect.source.rotation )
	self.sourceSize = Particle.getRandomVector ( 0, 0, 0, effect.source.size )
	self.sourceColor = Particle.getRandomVector ( 0, 0, 0, effect.source.color ) --effect.source.color
	
	self.size = self.sourceSize [ 1 ]
	
	--Конечные значения
	if effect.targetVelocity then
		self.targetVelocity = effect.targetVelocity.velocity --TODO scale
	end
	self.targetColor = effect.targetColor.color --TODO scale
	self.targetSize = effect.targetSize.size --TODO scale
	if effect.targetRotate then
		self.targetRotate = effect.targetRotate.rotation --TODO scale
	end
	
	self.material = effect.sprite.texture
	
	--TEST
	self.faceToward = Particle.getRandomVector ( self.x, self.y, self.z, effect.source.faceToward )
end

function Particle.getRandomVector ( sx, sy, sz, position )
	if not position then
		return
	end

	if position.point then
		return { sx + position.point [ 1 ], sy + position.point [ 2 ], sz + position.point [ 3 ], position.point [ 4 ] }
	elseif position.line then
		--Получаем случайное линейное значение в пределеах от 0 до 1
		local theta = math.random ( 0, 100 ) / 100
	
		local x, y, z = interpolateBetween ( position.line [ 1 ], position.line [ 2 ], position.line [ 3 ], 
			position.line [ 4 ], position.line [ 5 ], position.line [ 6 ], theta, "Linear" )
		return { sx + x, sy + y, sz + z, position.line [ 4 ] }
	elseif position.disc then
		local radius = math.random ( position.disc.radiusInner, position.disc.radiusOuter )
		local angle = math.random ( 0, 360 )
		
		return { 
			sx + position.disc.center [ 1 ] + radius*math.cos ( angle ), 
			sy + position.disc.center [ 2 ] + radius*math.sin ( angle ), 
			sz + position.disc.center [ 3 ] 
		}
	elseif position.sphere then
		local radius = math.random ( position.sphere.radiusInner, position.sphere.radiusOuter )
	
		local r = math.random()*( radius - radius/10 ) + radius/10
		local phi = math.acos ( 1 - 2 * math.random() )
		local theta = math.random()*math.pi*2
		local x = r * math.cos ( theta ) * math.sin ( phi )
		local y = r * math.sin ( theta ) * math.sin ( phi )
		local z = r * math.cos ( phi )
		
		return { 
			sx + position.sphere.center [ 1 ] + x, 
			sy + position.sphere.center [ 2 ] + y, 
			sz + position.sphere.center [ 3 ] + z 
		}
	elseif position.box then
		
	end
end

-------------------------------------------
-- ParticleSystem
-- Система частиц, эмиттер
-------------------------------------------
ParticleSystem = { 
	collection = { }
}
ParticleSystem.__index = ParticleSystem

function ParticleSystem.create ( effect, x, y, z )
	local particleSystem = {
		effect = effect,
		x = x, y = y, z = z,
		particles = { },
		timeEmitt = getTickCount ( ),
		numEmitt = 0,
		lastEmitt = getTickCount ( ) --[[- effect.killOld.ageLimit]],
		
		emissionTimer = 0,
		
		
		lastUpdate = getTickCount ( )
	}
	
	table.insert ( ParticleSystem.collection, particleSystem )
	
	return setmetatable ( particleSystem, ParticleSystem )
end

function ParticleSystem:draw ( tpf )
	local now = getTickCount ( )
	
	for i, particle in ipairs ( self.particles ) do
		if particle.timer >= particle.ageLimit then
			--table.remove ( self.particles, i )
			particle.enabled = false
		else
			particle.timer = particle.timer + tpf
			particle:draw ( tpf )
		end
	end
end

function ParticleSystem:update2 ( tpf )
	local now = getTickCount ( )

	if self.lastUpdate > 1000 or self.numEmitt < self.effect.source.rate then
		if math.random ( 8 ) > 7 then
			self:emit ( )
			self.numEmitt = self.numEmitt + 1
		end
		
		if self.lastUpdate > 1000 then self.lastUpdate = now end;
	end
	
	

	--[[self.emissionTimer = self.emissionTimer + tpf
	
	local intervalMin = 1
	local intervalMax = self.effect.source.rate
	
	if self.emissionTimer < -intervalMax then
		self.emissionTimer = -intervalMax
	end
	
	local counter = 100
	
	while self.emissionTimer > 0 and counter > 0 do
		self.emissionTimer = self.emissionTimer - math.lerp ( intervalMin, intervalMax, math.random ( 0, 100 ) / 100 )
		if self:emit ( ) then
			counter = counter - 1
		else
			break
		end
	end]]
end

function ParticleSystem:emit ( )
	local index = self:getFreeParticle ( )
	if #self.particles < self.effect.maxParticles or index then
		if index then
			local particle = Particle.create ( self.effect, self.x, self.y, self.z )
			particle.enabled = true
			self.particles [ index ] = particle
		else
			local particle = Particle.create ( self.effect, self.x, self.y, self.z )
			particle.enabled = true
			table.insert ( self.particles, particle )
		end
		
		return true
	end
end

function ParticleSystem:getFreeParticle ( )
	for i, particle in ipairs ( self.particles ) do
		if particle.enabled ~= true then
			return i
		end
	end
end

addEventHandler ( "onClientPreRender", root,
	function ( tpf )
		--Stat
		local particlesNum = 0
	
		for _, ps in ipairs ( ParticleSystem.collection ) do
			ps:update2 ( tpf )
			ps:draw ( tpf )
			
			--Stat
			particlesNum = particlesNum + #ps.particles
		end
		
		--Stat
		statsManager.set ( "Частиц на экране", particlesNum )
	end
, false )