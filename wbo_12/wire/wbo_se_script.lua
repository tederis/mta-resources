addEvent ( "onWBOComponentInput", false )
local DEBUG_SCRIPTS = true

Inline = {
	-- Коллекция всех выполненых скриптов
	collection = { }
}
Inline.__index = Inline

local fnDef = { }

function Inline.create ( element, str )
	if type ( str ) ~= "string" then
		return
	end
	
	local fn, err = loadstring ( str )
	
	if not fn then
		outputDebugString ( err )
		
		return false
	end
	
	local script = {
		fn = fn,
		env = { 
			this = element
		}
	}

	setfenv ( fn, script.env )

	setmetatable ( script.env, {
		__index = function ( t, v )
			return function ( ... ) return rawget ( fnDef, v ) ( t, ...  ) end
		end } )
		
	Inline.collection [ element ] = script
	
	return setmetatable ( script, Inline )
end

function Inline:execute ( )
	if type ( self.fn ) ~= "function" then
		outputDebugString ( "Для выполнения скрипта не найдена его функция", 1 )
	
		return
	end

	local ok, err = pcall ( self.fn )
	
	if DEBUG_SCRIPTS then
		outputDebugString ( tostring ( ok ) .. " : " .. tostring ( err ) )
	end
	
	return ok
end

--------------------------------------------------------------
-- Определение функций для работы с ними внутри скрипта
--------------------------------------------------------------
function fnDef:setPos ( x, y, z )
	if check ( "number", x, y, z ) then
		return setElementPosition ( self.this, x, y, z )
	end
	
	return false
end

function fnDef:getPos ( )
	return getElementPosition ( self.this )
end

function fnDef:setRot ( x, y, z )
	if check ( "number", x, y, z ) then
		return setElementRotation ( self.this, x, y, z )
	end
	
	return false
end

function fnDef:getRot ( )
	return getElementRotation ( self.this )
end

function fnDef:setFrozen ( freeze )
	if type ( freeze ) == "boolean" then
		return setElementFrozen ( self.this, freeze )
	end
	
	return false
end

function fnDef:setScale ( scale )
	if type ( scale ) == "number" then
		return setObjectScale ( self.this, scale )
	end
	
	return false
end

function fnDef:getScale ( )
	return getObjectScale ( self.this )
end

function fnDef:isFrozen ( )
	return isElementFrozen ( self.this )
end

function fnDef:moveTo ( time, x, y, z, rx, ry, rz )
	if check ( "number", time, x, y, z ) then
		return moveObject ( self.this, time, x, y, z, rx, ry, rz )
	end
	
	return false
end

function fnDef:stop ( )
	return stopObject ( self.this )
end

--Here it is necessary to add a your inline function

--[[function createEnv ( element )
	local env = { 
		element = getElementParent ( element ),
		script = element,
		caller = getPlayerFromName ( "XRAY" )
		
		--Your specific vars
		}
	
	return setmetatable ( env, {
		__index = function ( t, v )
			return function ( ... ) return rawget ( script, v ) ( t, ...  ) end
		end } )
end

function checkScript ( script )
	--TODO

	return true
end

function executeScript ( script, element )
	if type ( script ) ~= "string" and
	   isElement ( element ) ~= true then
		return
	end
	
	if checkScript ( script ) then
		local commandFunction = loadstring ( script )
		local newEnv = createEnv ( element )
	
		setfenv ( commandFunction, newEnv )
	
		local ok, err = pcall ( commandFunction )
		if DEBUG_SCRIPTS then
			outputDebugString ( tostring ( ok ) .. " : " .. tostring ( err ), 0 )
		end
	
		commandFunction, newEnv = nil, nil
	elseif DEBUG_SCRIPTS then
		outputDebugString ( "Loops is not allowed", 1 )
	end
end

function isScript ( element )
	return getElementTag ( element ) == "script"
end

addEventHandler ( "onObjectCreate", root,
	function ( )
		if isScript ( source ) then
			local scriptString = getElementData ( source, "insc" )
			
			executeScript ( scriptString, source )
			
			outputDebugString ( "Скрипт загружен" )
		end
	end
)]]