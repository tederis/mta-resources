addEvent ( "onPlayerEntityUse", true )
addEvent ( "onPlayerEntityAccept", true )
addEvent ( "onEntityActionHit", true )
--addEvent ( "onElementUse" )

local usableModels = { }

function isUsable ( element )
	if getElementData ( element, "itms" ) or usableModels [ getElementModel ( element ) ] then
		return true
	end
	
	return false
end

function getElementUsable ( element )
	if getElementData ( element, "itms" ) ~= false then
		return g_usableEntity
	end
	
	return usableModels [ getElementModel ( element ) ]
end

addEventHandler ( "onPlayerEntityUse", resourceRoot,
	function ( entity, selectedAction, state )
		local usable = getElementUsable ( entity )
		if usable then
			if usable.onUsed then
				usable.onUsed ( client, entity, selectedAction, state )
			end
			--triggerEvent ( "onElementUse", entity, player, selectedAction, usable.name )
		end
	end 
, false )

--[[
	Приближение к объекту с действием
]]
addEventHandler ( "onEntityActionHit", root,
	function ( )
		local usable = usableModels [ getElementModel ( source ) ]
		if usable then
			if type ( usable.onActionHit ) == "function" then
				usable.onActionHit ( client, source )
			end
		end
	end
)

function makeUsable ( model, tbl )
	usableModels [ model ] = tbl
end

function isUsable ( model )
	if usableModels [ model ] then
		return true
	end
	
	return false
end

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		setupUsable ( )
	end
)

addEventHandler ( "onPlayerWasted", root,
	function ( )
		if isElementAttached ( source ) then
			detachElements ( source )
		end
		
		toggleControl ( source, "fire", true )
	end 
)