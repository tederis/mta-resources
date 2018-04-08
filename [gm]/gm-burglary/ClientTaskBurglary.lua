ClientTaskBurglary = { 
	collection = { }
}

function ClientTaskBurglary.start ( ped, object, taskOrder, taskStage )
	if ClientTaskBurglary.isWorking ( ped ) then
		outputDebugString ( "Пед занят" )
	
		return
	end

	local weaponShopTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		stage = taskStage,
		step = 0,
		progress = 0,
		min = 0,
		max = 0.5
	}
	
	ClientTaskBurglary.collection [ ped ] = weaponShopTask
	
	ClientTaskBurglary.initAnim ( weaponShopTask )
end

function ClientTaskBurglary.update ( self )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	self.progress = math.min ( elapsedTime / duration, 1 )
	
	local progress = math.slerp ( self.min, self.max, self.progress ) 
	
	setPedAnimationProgress ( self.ped, self.anim, progress )
end

function ClientTaskBurglary.isEnded ( self )
	if self.progress < 1 then
		return true
	end
	
	self.progress = 0
	
	self.step = self.step + 1

	if self.order == "TO_GRAB" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 2, 0, 0.65, 0.25, 0, 0, 0 )
			self.min = 0.5
			self.max = 1
			
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 500

			return true
		elseif self.step == 2 then
			self.stage = "TS_CARRY"
			ClientTaskBurglary.initAnim ( self )
		end
	elseif self.order == "TO_DROP" then
		if self.step == 1 then
			exports [ "bone_attach" ]:detachElementFromBone ( self.object )
			self.min = 0.5
			self.max = 1
			
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 500
			
			return true
		elseif self.step == 2 then
			setPedAnimation ( self.ped, "ped", "IDLE_stance", true, true )
			setTimer ( setPedAnimation, 50, 1, self.ped, false )
		end
	end
	
	return false
end

function ClientTaskBurglary.initAnim ( self )
	if self.stage == "TS_LIFTUP" then
		self.anim = "liftup"
	elseif self.stage == "TS_CARRY" then
		self.anim = "crry_prtial"
	elseif self.stage == "TS_PUTDOWN" then
		self.anim = "putdwn"
	end
	
	self.startTime = getTickCount ( )
	self.endTime = self.startTime + 500

	setPedAnimation ( self.ped, "CARRY", self.anim, 1, false )
end

function ClientTaskBurglary.isWorking ( ped )
	return ClientTaskBurglary.collection [ ped ] ~= nil
end

addEventHandler ( "onClientPreRender", root,
	function ( )
		for ped, task in pairs ( ClientTaskBurglary.collection ) do
			if ClientTaskBurglary.isEnded ( task ) then
				ClientTaskBurglary.update ( task )
			else
				ClientTaskBurglary.collection [ ped ] = nil
			end
		end
	end
)

addEvent ( "onClientPlayerPickupObject", true )
addEventHandler ( "onClientPlayerPickupObject", root,
	function ( object, order, stage )
		ClientTaskBurglary.start ( source, object, order, stage )
	end
)

local animPool = {

}

addEventHandler ( "onClientPreRender", root,
	function ( )
		local now = getTickCount ( )
		
		for ped, anim in pairs ( animPool ) do
			local elapsedTime = now - anim.startTime
			local duration = anim.endTime - anim.startTime
			local progress = elapsedTime / duration
			
			setPedAnimationProgress ( ped, anim.anim, progress )
			
			if progress > 1 then
				animPool [ ped ] = nil
			end
		end
	end
)

addEvent ( "oCAPA", true )
addEventHandler ( "oCAPA", root,
	function ( block, anim, time )
		if getPlayerName(localPlayer) ~= "opdis" then
			local ping = 60
			setTimer (test, ping, 1, block, anim, time)
			outputChatBox("задержка ".. ping)
			
			return
		end
	
		--setPedAnimation ( source, block, anim, 1, false )
	
		animPool [ source ] = {
			block = block,
			anim = anim,
			startTime = getTickCount ( )
		}
		animPool [ source ].endTime = animPool [ source ].startTime + time
	end
)

function test ( block, anim, time )
	--setPedAnimation ( source, block, anim, 1, false )
	
	animPool [ source ] = {
		block = block,
		anim = anim,
		startTime = getTickCount ( )
	}
	animPool [ source ].endTime = animPool [ source ].startTime + time
end

function math.slerp ( v1, v2, alpha )
	local beta = 1 - alpha
	
	return beta*v1 + alpha*v2
end