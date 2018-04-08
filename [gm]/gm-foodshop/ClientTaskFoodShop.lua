ClientTaskFoodShop = { 
	collection = { }
}

local anims = {
	[ 349 ] = 2,
	[ 351 ] = 2,
	[ 355 ] = 2,
	[ 356 ] = 2,
	[ 358 ] = 2,
	[ 357 ] = 2,
	[ 250 ] = 2,
	[ 350 ] = 2,
	[ 346 ] = 1,
	[ 347 ] = 1,
	[ 348 ] = 1,
	[ 342 ] = 1,
	[ 352 ] = 1,
	[ 353 ] = 1,
	[ 363 ] = 1,
	[ 372 ] = 1,
	[ 373 ] = 3
}

function ClientTaskFoodShop.start ( ped, object, taskOrder, model )
	local taskStage

	if taskOrder == "TO_GRAB" then
		taskStage = "TS_LIFTIN"
	elseif taskOrder == "TO_CHANGE" then
		taskStage = "TS_RETURNS"
	elseif taskOrder == "TO_DROP" then
		taskStage = "TS_RETURNS"
	end

	local weaponShopTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		stage = taskStage,
		step = 0,
		progress = 0,
		startTime = getTickCount ( ),
		model = model
	}
	
	ClientTaskFoodShop.initAnim ( weaponShopTask )
	
	ClientTaskFoodShop.collection [ ped ] = weaponShopTask
end

function ClientTaskFoodShop.update ( self )
	local now = getTickCount ( )
	local elapsedTime = now - self.startTime
	local duration = self.endTime - self.startTime
	self.progress = math.min ( elapsedTime / duration, 1 )
	
	setPedAnimationProgress ( self.ped, self.anim, self.progress )
end

function ClientTaskFoodShop.isEnded ( self )
	if self.progress < 1 then
		return true
	end
	
	self.progress = 0
	
	self.step = self.step + 1
	
	if self.order == "TO_GRAB" then
		if self.step == 1 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 12, 0, 0, 0, 0, -90, 45 )
			
			self.stage = "TS_LIFT"
			
			ClientTaskFoodShop.initAnim ( self )
			
			return true
		elseif self.step == 3 then
			self.stage = "TS_LIFTEND"
			
			ClientTaskFoodShop.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_DROP" then
		if self.step == 1 then
			exports [ "bone_attach" ]:detachElementFromBone ( self.object )
			destroyElement ( self.object )
		
			self.stage = "TS_LIFTOUT"
		
			ClientTaskFoodShop.initAnim ( self )
			
			return true
		end
	elseif self.order == "TO_CHANGE" then
		if self.step == 1 then
			setElementModel ( self.object, self.model )
			
			self.stage = "TS_LIFT"
			
			ClientTaskFoodShop.initAnim ( self )
			
			return true
		end
	end
	
	return false
end

function ClientTaskFoodShop.initAnim ( self )
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

addEventHandler ( "onClientPreRender", root,
	function ( )
		for ped, task in pairs ( ClientTaskFoodShop.collection ) do
			if ClientTaskFoodShop.isEnded ( task ) then
				ClientTaskFoodShop.update ( task )
			else
				ClientTaskFoodShop.collection [ ped ] = nil
			end
		end
	end
)