ClientTaskManager = { 
	collection = { }
}

function ClientTaskManager.start ( taskMt, ped, object, taskOrder, model )
	if ClientTaskManager.isActive ( ped ) then
		outputDebugString ( "Пед занят" )
	
		return
	end

	local task = taskMt.start ( ped, object, taskOrder, model )
	
	ClientTaskManager.collection [ ped ] = task
	
	return task
end

function ClientTaskManager.isActive ( ped )
	return ClientTaskManager.collection [ ped ] ~= nil
end

function ClientTaskManager.abort ( ped )
	ClientTaskManager.collection [ ped ]:aborted ( )
	ClientTaskManager.collection [ ped ] = nil
end

addEventHandler ( "onClientPreRender", root,
	function ( )
		for ped, task in pairs ( ClientTaskManager.collection ) do
			if task:isEnded ( ) then
				task:update ( )
			else
				ClientTaskManager.abort ( ped )
			end
		end
	end
)