CheckpointControl = { }
local playerCheckpoint = { }

function CheckpointControl.create ( path, player )
	if playerCheckpoint [ player ] == nil then
		playerCheckpoint [ player ] = path
		triggerClientEvent ( player, "doClientCreateCheckpoints", path )
	end
end

function CheckpointControl.destroy ( player )
	playerCheckpoint [ player ] = nil
end

addEvent ( "onPlayerReachCheckpointInternal", true )
addEventHandler ( "onPlayerReachCheckpointInternal", resourceRoot,
	function ( checkpointIndex )
		local _playerCheckpoint = playerCheckpoint [ client ]
		if _playerCheckpoint then
			EventManager.triggerEvent ( _playerCheckpoint, "Checkpoint", 3, client )
			EventManager.triggerEvent ( _playerCheckpoint, "Checkpoint", 1, checkpointIndex )
			
			local nodesNum = #getElementChildren ( _playerCheckpoint, "path:node" )
			if checkpointIndex == nodesNum then
				EventManager.triggerEvent ( _playerCheckpoint, "Checkpoint", 2, client )
				CheckpointControl.destroy ( client )
			end
		end
	end
, false )