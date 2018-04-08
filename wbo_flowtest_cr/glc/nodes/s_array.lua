------------------------
-- Array группа       --
-- Массивы            --
------------------------

--[[
	Array:Array
]]
NodeRef "Array:Array" {
	doAdd = function ( self, value )
		local custom = self.custom
		if not custom.array then custom.array = { } end;
		
		table.insert ( custom.array, value )
		
		--[[outputChatBox ( "trigger array: " )
		for _, val in ipairs ( custom.array ) do
			outputChatBox ( "	" .. tostring ( val ) )
		end	
		outputChatBox ( #custom.array )]]
		
		self:triggerOutput ( 1, custom.array )
	end,
	
	events = {
		inputs = {
			{ "doAdd", "any" },
			{ "Array", "array" }
		},
	}
}

--[[
	Array:Enum
]]
local nodeArrays = { }
function arrayEnum ( node, array, index )
	local item = array [ index ]
	if item then
		setTimer ( arrayEnum, 100, 1, node, array, index + 1 )
		
		node = nodeArrays [ node.id ]
		node:triggerOutput ( 3, item )
		node:triggerOutput ( 1, item )
	else
		node = nodeArrays [ node.id ]
		node:triggerOutput ( 2 )
		nodeArrays [ node.id ] = nil
	end
end

NodeRef "Array:Enum" {
	doEnum = function ( self, value )
		local vars = self.vars
		local array = vars.Array
		if type ( array ) == "table" then
			--nodeArrays [ self.id ] = self
			--arrayEnum ( self, array, 1 )
			for k, v in ipairs ( array ) do
				self:triggerOutput ( 3, v )
				self:triggerOutput ( 1, v )
			end
			self:triggerOutput ( 2, value )
		end
	end,

	events = {
		inputs = {
			{ "doEnum", "any" },
			{ "Array", "array" }
		},
		outputs = {
			{ "onItem", "any" },
			{ "onStop", "any" },
			{ "Item", "any" }
		}
	}
}

--[[
-- ArrayRW
local _readArray = function ( )
	if type ( self.target ) ~= "table" then
		return
	end
	
	EventManager.triggerEvent ( self.this, "arrrw", 1, self.target [ self.Index ], _readArray )
end

local arrrw = { 
	name = "ReadWrite",
	group = "Array",
	events = {
		target = "array",
		inputs = {
			{ "doRead", "any" },
			{ "Index", "number" }
		},
		outputs = {
			{ "onItem", "any" }
		}
	}
}]]

--[[
	Array:Length
]]
NodeRef "Array:Length" {
	doGet = function ( self, value )
		local vars = self.vars
		local array = vars.Array
		if type ( array ) == "table" then
			local len = #array
			self:triggerOutput ( 2, len )
			self:triggerOutput ( 1, len )
		end
	end,

	events = {
		inputs = {
			{ "doGet", "any" },
			{ "Array", "array" }
		},
		outputs = {
			{ "onLength", "number" },
			{ "Length", "number" }
		}
	}
}