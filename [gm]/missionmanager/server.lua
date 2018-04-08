addEvent ( "onMissionStop" )
addEvent ( "onMissionStart" )

function createMission ( name )
	local mission = createElement ( "mission" )
	setElementData ( mission, "name", name )
	
	setElementParent ( mission, getResourceDynamicElementRoot ( sourceResource ) )
	
	return mission
end

function setPlayerMission ( player, mission )
	if not mission then
		mission = getPlayerMission ( player )
		if mission then
			triggerEvent ( "onMissionStop", mission, player )
			triggerClientEvent ( player, "onClientMissionStop", mission )
	
			return removeElementData ( player, "mission" )
		end
		
		return false
	end
	
	triggerEvent ( "onMissionStart", mission, player )
	triggerClientEvent ( player, "onClientMissionStart", mission )
	
	return setElementData ( player, "mission", mission )
end

function getPlayerMission ( player )
	return getElementData ( player, "mission" )
end

function isPlayerMission ( player )
	return getPlayerMission ( player ) ~= false
end