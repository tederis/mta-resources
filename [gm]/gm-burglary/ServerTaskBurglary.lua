ServerTaskBurglary = { 
	collection = { }
}

function ServerTaskBurglary.start ( ped, object, taskOrder, vehicle )
	if ServerTaskBurglary.isWorking ( ped ) then
		outputChatBox ( "Пед занят" )
	
		return
	end

	if taskOrder == "TO_AUTO" then
		if getElementData ( ped, "cargo" ) then
			taskOrder = "TO_DROP"
		else
			taskOrder = "TO_GRAB"
		end
	end

	local burglaryTask = {
		ped = ped,
		object = object,
		order = taskOrder,
		step = 0,
		vehicle = vehicle
	}	
	
	if taskOrder == "TO_GRAB" then
		burglaryTask.stage = "TS_LIFTUP"
	elseif taskOrder == "TO_DROP" then
		burglaryTask.stage = "TS_PUTDOWN"
	end
	
	ServerTaskBurglary.collection [ ped ] = burglaryTask
	
	ServerTaskBurglary.update ( burglaryTask )
end

function ServerTaskBurglary.update ( self )
	self.step = self.step + 1
	
	if self.order == "TO_GRAB" then
		if self.step == 1 then
			setPedAnimation ( self.ped, "CARRY", "liftup", 1, false )
			
			setTimer ( ServerTaskBurglary.update, 500, 1, self )
		elseif self.step == 2 then
			exports [ "bone_attach" ]:attachElementToBone ( self.object, self.ped, 2, 0, 0.65, 0.25, 0, 0, 0 )
			setElementData ( self.ped, "cargo", self.object )
			
			setTimer ( ServerTaskBurglary.update, 500, 1, self )
		elseif self.step == 3 then
			setPedAnimation ( self.ped, "CARRY", "crry_prtial", 1, false )
			
			ServerTaskBurglary.abort ( self )
		end
	elseif self.order == "TO_DROP" then
		if self.step == 1 then
			setPedAnimation ( self.ped, "CARRY", "putdwn", 1, false )
			
			setTimer ( ServerTaskBurglary.update, 500, 1, self )
		elseif self.step == 2 then
			exports [ "bone_attach" ]:detachElementFromBone ( self.object )
			removeElementData ( self.ped, "cargo" )
			
			setTimer ( ServerTaskBurglary.update, 500, 1, self )
		elseif self.step == 3 then
			if self.vehicle then
				destroyElement ( self.object )
				
				local bagCnt = getElementData ( self.ped, "bagCnt" ) or 0
				setElementData ( self.ped, "bagCnt", bagCnt + 1 )
			else
				local x, y, z = getPositionFrontOfPed ( self.ped, 0.6 )
				setElementPosition ( self.object, x, y, z - 0.8 )
			end
			
			stopPedAnimation ( self.ped )
		
			ServerTaskBurglary.abort ( self )
		end
	end
end

function ServerTaskBurglary.abort ( self )
	ServerTaskBurglary.collection [ self.ped ] = nil
end

function ServerTaskBurglary.isWorking ( ped )
	return ServerTaskBurglary.collection [ ped ] ~= nil
end

addEvent ( "onPlayerPickupObject", true )
addEventHandler ( "onPlayerPickupObject", root,
	function ( object, vehicle )
		if isElement ( object ) ~= true then
			return
		end
		
		ServerTaskBurglary.start ( client, object, "TO_AUTO", vehicle )
	end
)

function stopPedAnimation ( ped )
	setPedAnimation ( ped, "ped", "IDLE_stance", true, true )
	setTimer ( setPedAnimation, 50, 1, ped, false )
end

function getPositionFrontOfPed ( ped, offset )
	local rz = getPedRotation ( ped )
	local x, y, z = getElementPosition ( ped )
	x = x - math.sin ( math.rad ( rz ) ) * offset
	y = y + math.cos ( math.rad ( rz ) ) * offset
	
	return x, y, z
end