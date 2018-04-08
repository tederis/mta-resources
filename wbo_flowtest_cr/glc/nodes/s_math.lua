--------------------------
-- Math группа          --
-- Математика           --
--------------------------

--[[
	Math:Random
]]
NodeRef "Math:Random" { 
	doRandom = function ( self )
		local vars = self.vars
		self:triggerOutput ( 1, math.random ( vars.Min, vars.Max ) )
	end,
	
	events = {
		inputs = {
			{ "doRandom", "any", "arg0=math.random(Min,Max) [onResult=arg0]" },
			{ "Min", "number" },
			{ "Max", "number" }
		},
		outputs = {
			{ "onResult", "number" }
		}
	}
}

--[[
	Math:Less
]]
NodeRef "Math:Less" { 
	doMath = function ( self, value )
		local vars = self.vars
		
		local a = tonumber ( value )
		if a == nil then
			a = tonumber ( vars.A ) or 0
		end
		local b = tonumber ( vars.B ) or 0
		
		
		self:triggerOutput ( a < b and 1 or 2 )
	end,
	
	events = {
		inputs = {
			{ "doMath", "any", "if(A<B)then [onTrue] else [onFalse] end" },
			{ "A", "number" },
			{ "B", "number" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Math:Add
	Сложение
]]
NodeRef "Math:Add" { 
	doMath = function ( self, value )
		local vars = self.vars
		
		local op1 = tonumber ( value )
		if op1 == nil then
			op1 = tonumber ( vars.Op1 ) or 0
		end
		local op2 = tonumber ( vars.Op2 ) or 0
		
		self:triggerOutput ( 2, op1 + op2 )
		self:triggerOutput ( 1 )
	end,
	
	events = {
		inputs = {
			{ "doMath", "any" },
			{ "Op1", "number" },
			{ "Op2", "number" }
		},
		outputs = {
			{ "onMath", "any" },
			{ "Result", "number" }
		}
	}
}

--[[
	Math:Sub
]]
NodeRef "Math:Sub" { 
	doMath = function ( self, value )
		local vars = self.vars
		
		local op1 = tonumber ( value )
		if op1 == nil then
			op1 = tonumber ( vars.Op1 ) or 0
		end
		local op2 = tonumber ( vars.Op2 ) or 0
		
		self:triggerOutput ( 2, op1 - op2 )
		self:triggerOutput ( 1 )
	end,
	
	events = {
		inputs = {
			{ "doMath", "any" },
			{ "Op1", "number" },
			{ "Op2", "number" }
		},
		outputs = {
			{ "onMath", "any" },
			{ "Result", "number", "Op1+Op2" }
		}
	}
}

--[[
	Math:ToBoolean
	Выдача bool значения
]]
NodeRef "Math:ToBoolean" { 
	doTrue = function ( self )
		self:triggerOutput ( 1, true )
	end,
	doFalse = function ( self )
		self:triggerOutput ( 1, false )
	end,
	
	events = {
		inputs = {
			{ "doTrue", "any" },
			{ "doFalse", "any" }
		},
		outputs = {
			{ "onBool", "bool" }
		}
	}
}

--[[
	Math:FromBoolean
]]
NodeRef "Math:FromBoolean" { 
	Bool = function ( self, value )
		self:triggerOutput ( value == true and 1 or 2 )
	end,
	
	events = {
		inputs = {
			{ "Bool", "bool" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}