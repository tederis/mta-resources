ClientTaskMeal = { }
ClientTaskMeal.__index = ClientTaskMeal

function ClientTaskMeal.start ( ped, object, taskOrder, model )
	local mealTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		step = 0,
		progress = 0
	}

	if taskOrder == "TO_GRAB" then
		mealTask.stage = "TS_LIFTIN"
	elseif taskOrder == "TO_CHANGE" then
		mealTask.stage = "TS_RETURNS"
		mealTask.model = model
	elseif taskOrder == "TO_DROP" then
		mealTask.stage = "TS_RETURNS"
	end
	
	ClientTaskMeal.initAnim ( mealTask )
	
	return setmetatable ( mealTask, ClientTaskMeal )
end

function ClientTaskMeal:aborted ( )

end

function ClientTaskMeal:update ( )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	self.progress = math.min ( elapsedTime / duration, 1 )
	
	setPedAnimationProgress ( self.ped, self.anim, self.progress )
end

function ClientTaskMeal:isEnded ( )
	if self.progress < 1 then
		return true
	end
	
	self.progress = 0
	
	self.step = self.step + 1
	
	if self.order == "TO_GRAB" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 12, 0, 0, 0, 0, -90, 45 )
			
			self.stage = "TS_LIFT"
			
			ClientTaskMeal.initAnim ( self )
			
			return true
		elseif self.step == 2 then
			self.stage = "TS_LIFTEND"
			
			ClientTaskMeal.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_DROP" then
		if self.step == 1 then
			exports [ "bone_attach" ]:detachElementFromBone ( self.object )
			destroyElement ( self.object )
		
			self.stage = "TS_LIFTOUT"
		
			ClientTaskMeal.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_CHANGE" then
		if self.step == 1 then
			setElementModel ( self.object, self.model )
			
			self.stage = "TS_LIFT"
			
			ClientTaskMeal.initAnim ( self )
			
			return true
		end
	end
	
	return false
end

function ClientTaskMeal.initAnim ( self )
	if self.stage == "TS_LIFTIN" then
		self.anim = "SHP_Tray_Lift_In"
	elseif self.stage == "TS_LIFTOUT" then
		self.anim = "SHP_Tray_Lift_Out"
	elseif self.stage == "TS_LIFT" then
		self.anim = "SHP_Tray_Lift"
	elseif self.stage == "TS_LIFTEND" then
		self.anim = "SHP_TRAY_LIFT_LOOP"
	elseif self.stage == "TS_RETURN" then

	elseif self.stage == "TS_RETURNS" then
		self.anim = "SHP_Tray_Return"
	end
	
	self.startTime = getTickCount ( )
	self.endTime = self.startTime + 1000
	
	setPedAnimation ( self.ped, "FOOD", self.anim, -1, false, false )
end