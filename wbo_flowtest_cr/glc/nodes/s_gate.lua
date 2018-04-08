--------------------------
-- Gate группа          --
-- Гейты                --
--------------------------

--[[
	Gate:Not
]]
NodeRef "Gate:Not" {
	doOp = function ( self )
		self:triggerOutput ( 1, not self.vars.doOp )
	end,
	
	events = {
		inputs = {
			{ "doOp", "bool" }
		},
		outputs = {
			{ "onResult", "bool" }
		}
	}
}

--[[
	Gate:And
]]
NodeRef "Gate:And" {
	doOperation = function ( self )
		local vars = self.vars
		local result = vars.Op1 == true and vars.Op2 == true
		self:triggerOutput ( result and 1 or 2 )
	end,
	
	events = {
		inputs = {
			{ "doOperation", "any" },
			{ "Op1", "bool" },
			{ "Op2", "bool" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}