ClientTaskWeapon = { }
ClientTaskWeapon.__index = ClientTaskWeapon

local modelAnimTypes = {
	[ 346 ] = 1,
	[ 347 ] = 1,
	[ 348 ] = 1,
	[ 342 ] = 1,
	[ 352 ] = 1,
	[ 353 ] = 1,
	[ 363 ] = 1,
	[ 372 ] = 1,
	[ 349 ] = 2,
	[ 351 ] = 2,
	[ 355 ] = 2,
	[ 356 ] = 2,
	[ 358 ] = 2,
	[ 357 ] = 2,
	[ 250 ] = 2,
	[ 350 ] = 2,
	[ 373 ] = 3
}

function ClientTaskWeapon.start ( ped, object, taskOrder, model )
	local weaponTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		step = 0,
		progress = 0
	}
	
	if taskOrder == "TO_GRAB" then
		weaponTask.stage = "TS_LIFTIN"
	elseif taskOrder == "TO_CHANGE" then
		weaponTask.stage = "TS_RETURNS"
		weaponTask.model = model
	elseif taskOrder == "TO_DROP" then
		weaponTask.stage = "TS_RETURNS"
	end
	
	ClientTaskWeapon.initAnim ( weaponTask )
	
	return setmetatable ( weaponTask, ClientTaskWeapon )
end

function ClientTaskWeapon:aborted ( )
	setPedAnimation ( self.ped, "WEAPONS", "SHP_Tray_Pose", -1, true, false )
end

function ClientTaskWeapon:update ( )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	self.progress = math.min ( elapsedTime / duration, 1 )
	
	setPedAnimationProgress ( self.ped, self.anim, self.progress )
end

function ClientTaskWeapon:isEnded ( )
	if self.progress < 1 then
		return true
	end
	
	self.progress = 0
	
	self.step = self.step + 1
	
	if self.order == "TO_GRAB" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 12, 0, 0, 0, 0, -90, 0 )
			
			self.stage = "TS_LIFT"
			
			ClientTaskWeapon.initAnim ( self )
			
			return true
		elseif self.step == 2 then
			self:putWeapon ( )
		
			self.stage = "TS_LIFTEND"
			
			ClientTaskWeapon.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_DROP" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 12, 0, 0, 0, 0, -90, 0 )
		
			self.stage = "TS_RETURN"
		
			ClientTaskWeapon.initAnim ( self )
			
			return true
		elseif self.step == 2 then
			destroyElement ( self.object )
		
			self.stage = "TS_LIFTOUT"
		
			ClientTaskWeapon.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_CHANGE" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 12, 0, 0, 0, 0, -90, 0 )
			
			self.stage = "TS_RETURN"
		
			ClientTaskWeapon.initAnim ( self )
			
			return true
		elseif self.step == 2 then
			setElementModel ( self.object, self.model )
			
			self.stage = "TS_LIFT"
			
			ClientTaskWeapon.initAnim ( self )
			
			return true
		elseif self.step == 3 then
			self:putWeapon ( )
		
			self.stage = "TS_LIFTEND"
			
			ClientTaskWeapon.initAnim ( self )
			
			return true
		end
	end
	
	return false
end

function ClientTaskWeapon.initAnim ( self )
	if self.stage == "TS_LIFTIN" then
		self.anim = "SHP_G_Lift_In"
	elseif self.stage == "TS_LIFTOUT" then
		self.anim = "SHP_G_Lift_Out"
	elseif self.stage == "TS_LIFT" then
		local model = getElementModel ( self.object )
	
		if modelAnimTypes [ model ] == 2 then
			self.anim = "SHP_2H_Lift"
		elseif modelAnimTypes [ model ] == 1 then
			self.anim = "SHP_1H_Lift"
		elseif modelAnimTypes [ model ] == 3 then
			self.anim = "SHP_Ar_Lift"
		end
	elseif self.stage == "TS_LIFTEND" then
		local model = getElementModel ( self.object )
	
		if modelAnimTypes [ model ] == 2 then
			self.anim = "SHP_2H_Lift_End"
		elseif modelAnimTypes [ model ] == 1 then
			self.anim = "SHP_1H_Lift_End"
		elseif modelAnimTypes [ model ] == 3 then
			self.anim = "SHP_Ar_Lift_End"
		end
	elseif self.stage == "TS_RETURN" then
		local model = getElementModel ( self.object )
		
		if modelAnimTypes [ model ] == 2 then
			self.anim = "SHP_2H_Ret"
		elseif modelAnimTypes [ model ] == 1 then
			self.anim = "SHP_1H_Ret"
		elseif modelAnimTypes [ model ] == 3 then
			self.anim = "SHP_Ar_Ret"
		end
	elseif self.stage == "TS_RETURNS" then
		local model = getElementModel ( self.object )
		
		if modelAnimTypes [ model ] == 2 then
			self.anim = "SHP_2H_Ret_S"
		elseif modelAnimTypes [ model ] == 1 then
			self.anim = "SHP_1H_Ret_S"
		elseif modelAnimTypes [ model ] == 3 then
			self.anim = "SHP_Ar_Ret_S"
		end
	end
	
	self.startTime = getTickCount ( )
	self.endTime = self.startTime + 1000
	
	setPedAnimation ( self.ped, "WEAPONS", self.anim, -1, false, false )
end

function ClientTaskWeapon:putWeapon ( )
	exports.bone_attach:detachElementFromBone ( self.object )
	local x, y, z = getElementPosition ( self.ped )
	local model = getElementModel ( self.object )
		
	if modelAnimTypes [ model ] == 1 then
		setElementPosition ( self.object, x + 0.108, y + 0.654, z + 0.053 )
	elseif modelAnimTypes [ model ] == 2 then
		setElementPosition ( self.object, x + 0.231, y + 0.636, z + 0.053 )
	elseif modelAnimTypes [ model ] == 3 then
		setElementPosition ( self.object, x + 0.175, y + 0.676, z + 0.5 )
	end
end