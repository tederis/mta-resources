ServerTaskWeaponShop = { 
	collection = { }
}

function ServerTaskWeaponShop.start ( ped, object, taskOrder )
	local taskAnim

	if taskOrder == "LIFT" then
		taskAnim = "SHP_G_Lift_In"
	elseif taskOrder == "REPLACE" then
		taskAnim = "SHP_1H_Ret_S"
	end

	local weaponShopTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		anim = taskAnim,
		step = 0,
		progress = 0,
		startTime = getTickCount ( )
	}
	weaponShopTask.endTime = weaponShopTask.startTime + 1000
	
	ServerTaskWeaponShop.collection [ ped ] = weaponShopTask
	
	setPedAnimation ( ped, "WEAPONS", taskAnim, -1, false, false )
end

function ServerTaskWeaponShop.update ( self )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	self.progress = math.min ( elapsedTime / duration, 1 )
	
	setPedAnimationProgress ( self.ped, self.anim, self.progress )
end

function ServerTaskWeaponShop.isEnded ( self )
	if self.progress < 1 then
		return true
	end
	
	self.progress = 0
	
	self.step = self.step + 1
	
	if self.order == "LIFT" then
		if self.step == 1 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_1H_Lift", -1, false, false )
			self.anim = "SHP_1H_Lift"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		elseif self.step == 3 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_1H_Lift_End", -1, false, false )
			self.anim = "SHP_1H_Lift_End"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		end
	elseif self.order == "RETURN" then
		if self.step == 1 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_Ar_Ret", -1, false, false )
			self.anim = "SHP_Ar_Ret"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		elseif self.step == 2 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_G_Lift_Out", -1, false, false )
			self.anim = "SHP_G_Lift_Out"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		end
	elseif self.order == "REPLACE" then
		if self.step == 1 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_1H_Ret", -1, false, false )
			self.anim = "SHP_Ar_Ret"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		elseif self.step == 2 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_1H_Lift", -1, false, false )
			self.anim = "SHP_1H_Lift"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		elseif self.step == 3 then
			setPedAnimation ( self.ped, "WEAPONS", "SHP_1H_Lift_End", -1, false, false )
			self.anim = "SHP_1H_Lift_End"
		
			self.startTime = getTickCount ( )
			self.endTime = self.startTime + 1000
			
			return true
		end
	end
	
	return false
end

addEvent ( "onWeaponTraderChange", true )
addEventHandler ( "onWeaponTraderChange", resourceRoot,
	function ( model )
		
	end
)