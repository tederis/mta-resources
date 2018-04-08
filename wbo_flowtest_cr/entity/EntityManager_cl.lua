GameEntity = { }
GameEntity.__index = GameEntity

function GameEntity.create ( )
	return setmetatable ( {
		elements = { },
		refs = 0
	}, GameEntity )
end

function GameEntity:addElement ( element )
	if self.elements [ element ] == nil then
		self.elements [ element ] = true
		self.refs = self.refs + 1
	end
end

function GameEntity:removeElement ( element )
	if self.elements [ element ] then
		self.refs = self.refs - 1
	end
	self.elements [ element ] = nil
end

function GameEntity:isElement ( element )
	return self.elements [ element ] ~= nil
end

function GameEntity.getDimension ( element )
	return getElementDimension ( element )
end



local elementEnabledTo = { }
function isElementEnabled ( element )
	return elementEnabledTo [ element ] == true
end

addEvent ( "onClientElementEnabled", true )
addEventHandler ( "onClientElementEnabled", resourceRoot,
	function ( enabled )
		if enabled then
			elementEnabledTo [ source ] = true
		else
			elementEnabledTo [ source ] = nil
		end
	end
)