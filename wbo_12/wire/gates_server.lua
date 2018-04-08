Gate = { }

------------------------------
--Logic gates
------------------------------
Gate [ "Not" ] = {
	inputs = { "doOp1" },
	input = function ( gate, op1 )
		if op1 > 0 then
			return 0
		end
		
		return 1
	end 
}

Gate [ "Or" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		if op1 > 0 or op2 > 0 then
		
			return 1
		end
		
		return 0
	end 
}
 
Gate [ "And" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		if op1 > 0 and op2 > 0 then
		
			return 1
		end
		
		return 0
	end
}
 
Gate [ "Xor" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		return op1 ~= op2 and 1 or 0
	end 
}
 
Gate [ "Xnor" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		return op1 == op2 and 1 or 0
	end 
}
 
Gate [ "Nor" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		if op1 < 1 and op2 < 1 then
		
			return 1
		end
		
		return 0
	end 
}
 
Gate [ "Nand" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		if not ( op1 > 0 and op2 > 0 ) then
		
			return 1
		end
		
		return 0
	end
}

------------------------------
--Arithmetic gates
------------------------------
Gate [ "Sub" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		return math.floor ( op1 - op2 )
	end
}

Gate [ "Add" ] = {
	inputs = { "doOp1", "doOp2" },
	input = function ( gate, op1, op2 )
		return math.floor ( op1 + op2 )
	end
}