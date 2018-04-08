--[[
	PUBLIC FUNCTIONS
]]

function applyModelLookupType ( elementType )
	if type ( elementType ) == "string" and elementType:len ( ) >= 3 then
		g_ModelLookupTypes [ elementType ] = true
	end
end

function removeModelLookupType ( elementType )
	if type ( elementType ) == "string" and elementType:len ( ) >= 3 then
		g_ModelLookupTypes [ elementType ] = nil
	end
end