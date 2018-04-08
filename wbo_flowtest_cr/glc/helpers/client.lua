CheckpointControl = { }
local _checkpoints
local _currentCheckpoint
local _pathDimension

function CheckpointControl.create ( path )
	_checkpoints = { }
	
	local nodes = getElementChildren ( path, "path:node" )
	for i, node in ipairs ( nodes ) do
		local x = getElementData ( node, "posX", false )
		local y = getElementData ( node, "posY", false )
		local z = getElementData ( node, "posZ", false )
	
		_checkpoints [ i ] = {
			position = { x, y, z },
			size = 2
		}
	end
	
	_pathDimension = getElementDimension ( path )
	
	_currentCheckpoint = 0
	showNextCheckpoint ( )
end

function createCheckpoint(i)
	local checkpoint = _checkpoints[i]
	if checkpoint.marker then
		return
	end
	local pos = checkpoint.position
	local color = checkpoint.color or { 0, 0, 255 }
	checkpoint.marker = createMarker(pos[1], pos[2], pos[3], checkpoint.type or 'checkpoint', checkpoint.size, color[1], color[2], color[3])
	setElementDimension ( checkpoint.marker, _pathDimension )
	if (not checkpoint.type or checkpoint.type == 'checkpoint') and i == #_checkpoints then
		setMarkerIcon(checkpoint.marker, 'finish')
	end
	if checkpoint.type == 'ring' and i < #_checkpoints then
		setMarkerTarget(checkpoint.marker, unpack(_checkpoints[i+1].position))
	end
	checkpoint.blip = createBlip(pos[1], pos[2], pos[3], 0, isCurrent and 2 or 1, color[1], color[2], color[3])
	setElementDimension ( checkpoint.blip, _pathDimension )
	setBlipOrdering(checkpoint.blip, 1)
	return checkpoint.marker
end

function makeCheckpointCurrent(i,bOtherPlayer)
	local checkpoint = _checkpoints[i]
	local pos = checkpoint.position
	local color = checkpoint.color or { 255, 0, 0 }
	if not checkpoint.blip then
		checkpoint.blip = createBlip(pos[1], pos[2], pos[3], 0, 2, color[1], color[2], color[3])
		setElementDimension ( checkpoint.blip, _pathDimension )
		setBlipOrdering(checkpoint.blip, 1)
	else
		setBlipSize(checkpoint.blip, 2)
	end
	
	if not checkpoint.type or checkpoint.type == 'checkpoint' then
		checkpoint.colshape = createColCircle(pos[1], pos[2], checkpoint.size + 4)
	else
		checkpoint.colshape = createColSphere(pos[1], pos[2], pos[3], checkpoint.size + 4)
	end
	setElementDimension ( checkpoint.colshape, _pathDimension )
	if not bOtherPlayer then
		addEventHandler('onClientColShapeHit', checkpoint.colshape, checkpointReached)
	end
end

function destroyCheckpoint(i)
	local checkpoint = _checkpoints[i]
	if checkpoint and checkpoint.marker then
		destroyElement(checkpoint.marker)
		checkpoint.marker = nil
		destroyElement(checkpoint.blip)
		checkpoint.blip = nil
		if checkpoint.colshape then
			destroyElement(checkpoint.colshape)
			checkpoint.colshape = nil
		end
	end
end

function showNextCheckpoint(bOtherPlayer)
	_currentCheckpoint = _currentCheckpoint + 1
	local i = _currentCheckpoint
	--g_dxGUI.checkpoint:text((i - 1) .. ' / ' .. #g_Checkpoints)
	if i > 1 then
		destroyCheckpoint(i-1)
	else
		createCheckpoint(1)
	end
	makeCheckpointCurrent(i,bOtherPlayer)
	if i < #_checkpoints then
		local curCheckpoint = _checkpoints[i]
		local nextCheckpoint = _checkpoints[i+1]
		local nextMarker = createCheckpoint(i+1)
		setMarkerTarget(curCheckpoint.marker, unpack(nextCheckpoint.position))
	end
	--[[if not Spectate.active then
		setElementData(g_Me, 'race.checkpoint', i)
	end]]
end

function checkpointReached(elem)
	--[[if elem ~= g_Vehicle or isVehicleBlown(g_Vehicle) or getElementHealth(g_Me) == 0 or Spectate.active then
		return
	end]]
	
	--[[if _checkpoints[_currentCheckpoint].vehicle and _checkpoints[_currentCheckpoint].vehicle ~= getElementModel(g_Vehicle) then
		g_PrevVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(g_Vehicle)
		alignVehicleWithUp()
		setElementModel(g_Vehicle, g_Checkpoints[g_CurrentCheckpoint].vehicle)
		vehicleChanging(g_MapOptions.classicchangez, g_Checkpoints[g_CurrentCheckpoint].vehicle)
	end]]
	triggerServerEvent('onPlayerReachCheckpointInternal', resourceRoot, _currentCheckpoint)
	playSoundFrontEnd(43)
	if _currentCheckpoint < #_checkpoints then
		showNextCheckpoint()
	else
		--g_dxGUI.checkpoint:text(#g_Checkpoints .. ' / ' .. #g_Checkpoints)
		--[[if g_GUI.hurry then
			Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
			g_GUI.hurry = false
		end]]
		destroyCheckpoint(#_checkpoints)
       -- triggerEvent('onClientPlayerFinish', resourceRoot)
		--toggleAllControls(false, true, false)
	end
end

addEvent ( "doClientCreateCheckpoints", true )
addEventHandler ( "doClientCreateCheckpoints", resourceRoot,
	function ( )
		CheckpointControl.create ( source )
	end
)