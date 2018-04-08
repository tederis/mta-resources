local navmesh
local ped

local nodeIndex
local nodesNum
local startTime
local duration = 2000

local function onUpdate ( )
	local nextIndex = nodeIndex + 1
	
	local startNode = getElementChild ( navmesh, nodeIndex )
	local sx, sy, sz = getElementPosition ( startNode )
	local endNode = getElementChild ( navmesh, nextIndex )
	local ex, ey, ez = getElementPosition ( endNode )
	
	local rot = ( 360 - math.deg ( math.atan2 ( ( ex - sx ), ( ey - sy ) ) ) ) % 360
	
	local rotFactor = getPedRotation ( ped ) - rot
	if rotFactor > 10 then
		setPedAnalogControlState ( ped, "left", 0.1 )
	elseif rotFactor > -10 then
		setPedAnalogControlState ( ped, "right", 0.1 )
	else
		setPedAnalogControlState ( ped, "forwards", 0.1 )
	end
	
	local now = getTickCount ( )
	local elapsedTime = now - startTime
	local progress = elapsedTime / duration
	
	if progress > 1 then
		startTime = now
		
		if nextIndex == nodesNum - 1 then
			nodeIndex = 0
		else
			nodeIndex = nodeIndex + 1
		end
	else
		x, y, z = interpolateBetween ( sx, sy, sz, ex, ey, ez, progress, "Linear" )
	
		--setElementPosition ( ped, x, y, z )
		--setElementRotation ( ped, 0, 0, rot, "default", true )
		
		--setPedAnalogControlState ( ped, "forwards", 0.1 )
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		navmesh = getElementByID ( "navmesh" )
		ped = getElementByID ( "testped" )
		
		--setPedAnimation ( ped, "ped", "run_old", 1, true, false, true, false )
		
		nodeIndex = 0
		nodesNum = getElementChildrenCount ( navmesh )
		outputChatBox ( nodesNum )
		startTime = getTickCount ( )
		
		addEventHandler ( "onClientPreRender", root, onUpdate, false )
	end
, false )