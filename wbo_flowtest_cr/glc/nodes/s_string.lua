--------------------------
-- String группа        --
-- Работа со строками   --
--------------------------

--[[
	String:Concat
]]
NodeRef "String:Concat" { 
	doConcat = function ( self )
		local vars = self.vars
		self:triggerOutput ( 1, tostring ( vars.String1 ) .. tostring ( vars.String2 ) )
	end,
	
	events = {
		inputs = {
			{ "doConcat", "any", "$arg0=(@String1..@String2); [@onResult=$arg0]" },
			{ "String1", "string" },
			{ "String2", "string" }
		},
		outputs = {
			{ "onResult", "string" }
		}
	}
}

--[[
	String:Equal
]]
NodeRef "String:Equal" {
	doCompare = function ( self )
		local vars = self.vars
		self:triggerOutput ( tostring ( vars.String1 ) == tostring ( vars.String2 ) and 1 or 2 )
	end,

	events = {
		inputs = {
			{ "doCompare", "any" },
			{ "String1", "string" },
			{ "String2", "string" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}